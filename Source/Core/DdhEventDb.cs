using System.IO;

namespace War3DeathSettlement.Core;

/// <summary>
/// 读 ddh 自己写的伤害明细库（%LOCALAPPDATA%\War3DeathSettlement\ddh\ddh-events.db）。
/// ddh 用系统 winsqlite3.dll 写；这里用同一套 P/Invoke 包装读，不引入 NuGet。
/// 对局主键是游戏状态对象 ID（ctx + ThisGame），不是进程 PID。
/// 表 game_events / game_units 的列在 ddh_sqlite.inc 与这里必须一致。
/// </summary>
internal static class DdhEventDb
{
    public static string Folder
    {
        get
        {
            string p = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "War3DeathSettlement", "ddh");
            try { Directory.CreateDirectory(p); } catch { }
            return p;
        }
    }

    public static string FixedPath => Path.Combine(Folder, "ddh-events.db");

    public static bool Exists() => File.Exists(FixedPath);

    /// <summary>ddh 库从 user_version=4 起，units.illusion 才是独立的 IsUnitIllusion 位。</summary>
    internal const int IllusionTrustedDbVersion = 4;

    /// <summary>老库（v22/ user_version=3）的 illusion 与 LOCUST_CHECKED 同 bit，不能信。</summary>
    internal static bool TrustDbIllusion(int dbVersion) => dbVersion >= IllusionTrustedDbVersion;

    /// <summary>读取 ddh 写的单位属性表（只读）。表不存在/为空返回空列表。</summary>
    public static List<UnitAttrResponse> ReadUnits(string sessionId) => ReadUnits(sessionId, FixedPath);

    /// <summary>自检可指定临时库；生产路径固定读 ddh-events.db。</summary>
    internal static List<UnitAttrResponse> ReadUnits(string sessionId, string path)
    {
        var list = new List<UnitAttrResponse>();
        if (string.IsNullOrWhiteSpace(sessionId) || !File.Exists(path)) return list;

        SqliteConnection? conn = SqliteConnection.Open(path, out _);
        if (conn == null) return list;

        using (conn)
        {
            int dbVersion = 0;
            conn.Query("PRAGMA user_version;", null, r => dbVersion = r.GetInt32(0), out _);
            bool trustIllusion = TrustDbIllusion(dbVersion);

            bool hasLocust = false;
            bool hasAttackSpeed = false;
            conn.Query("PRAGMA table_info(game_units);", null, r =>
            {
                string column = r.GetString(1);
                if (string.Equals(column, "locust", StringComparison.OrdinalIgnoreCase))
                    hasLocust = true;
                if (string.Equals(column, "attack_speed", StringComparison.OrdinalIgnoreCase))
                    hasAttackSpeed = true;
            }, out _);

            using SqliteStatement? st = conn.Prepare(
                "SELECT addr,type_code,name,title,attack_range,damage_min,damage_max," +
                "attack_interval,armor,move_speed,sight_day,sight_night,acquire_range," +
                "strength,agility,intelligence,hero,illusion" +
                (hasLocust ? ",locust" : "") +
                (hasAttackSpeed ? ",attack_speed" : "") +
                ",owner_slot" +
                " FROM game_units WHERE session_id = ?1", out _);
            if (st == null) return list;
            if (!st.Bind(new object?[] { sessionId }, out _)) return list;

            while (true)
            {
                if (!st.Step(out bool row, out _) || !row) break;
                var r = st.Row;
                uint flags = UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName;
                if (r.GetDouble(4) > 0) flags |= UnitAttrWire.FlagAttackRange;
                if (r.GetDouble(6) > 0 || r.GetDouble(5) > 0) flags |= UnitAttrWire.FlagDamage;
                if (r.GetDouble(7) > 0) flags |= UnitAttrWire.FlagInterval;
                flags |= UnitAttrWire.FlagArmor;
                if (r.GetDouble(9) > 0) flags |= UnitAttrWire.FlagMoveSpeed;
                if (r.GetDouble(10) > 0) flags |= UnitAttrWire.FlagSightDay;
                if (r.GetDouble(11) > 0) flags |= UnitAttrWire.FlagSightNight;
                if (r.GetDouble(12) > 0) flags |= UnitAttrWire.FlagAcquire;
                if (r.GetDouble(13) > 0) flags |= UnitAttrWire.FlagStrength;
                if (r.GetDouble(14) > 0) flags |= UnitAttrWire.FlagAgility;
                if (r.GetDouble(15) > 0) flags |= UnitAttrWire.FlagIntelligence;
                if (r.GetString(3).Length > 0) flags |= UnitAttrWire.FlagTitle;
                flags |= UnitAttrWire.FlagHeroKnown;
                if (r.GetBool(16)) flags |= UnitAttrWire.FlagHero;
                if (trustIllusion)
                {
                    flags |= UnitAttrWire.FlagIllusionChecked;
                    if (r.GetBool(17)) flags |= UnitAttrWire.FlagIllusion;
                }
                if (hasLocust)
                {
                    flags |= UnitAttrWire.FlagLocustChecked;
                    if (r.GetBool(18)) flags |= UnitAttrWire.FlagLocust;
                }
                int attackSpeedIndex = hasLocust ? 19 : 18;
                float attackSpeed = hasAttackSpeed ? (float)r.GetDouble(attackSpeedIndex) : 0f;
                if (hasAttackSpeed && attackSpeed > 0f) flags |= UnitAttrWire.FlagAttackSpeed;
                int ownerSlotIndex = 18 + (hasLocust ? 1 : 0) + (hasAttackSpeed ? 1 : 0);

                list.Add(new UnitAttrResponse(
                    (uint)r.GetInt64(0), flags, r.GetString(1), r.GetString(2), r.GetString(3),
                    (float)r.GetDouble(4), (float)r.GetDouble(5), (float)r.GetDouble(6),
                    (float)r.GetDouble(7), (float)r.GetDouble(8), (float)r.GetDouble(9),
                    attackSpeed, (float)r.GetDouble(12), 0f,
                    (float)r.GetDouble(10), (float)r.GetDouble(11), 0,
                    (float)r.GetDouble(13), (float)r.GetDouble(14), (float)r.GetDouble(15), 0,
                    r.GetInt32(ownerSlotIndex)));
            }
        }
        return list;
    }

#if !DESKTOP_READONLY
    /// <summary>
    /// 读取 seq &gt; afterSeq 的事件，按 seq 升序，最多 limit 条。
    /// 返回空列表时 <paramref name="error"/> 为空表示“暂时没有新行”，非空表示读失败。
    /// </summary>
    public static List<DamageHook.HookEvent> ReadAfter(string sessionId, uint afterSeq, int limit,
                                                       out string error, long sinceWallMs = 0)
    {
        error = "";
        var list = new List<DamageHook.HookEvent>();
        if (string.IsNullOrWhiteSpace(sessionId) || !File.Exists(FixedPath)) return list;

        SqliteConnection? conn = SqliteConnection.Open(FixedPath, out error);
        if (conn == null) return list;

        using (conn)
        {
            using SqliteStatement? st = conn.Prepare(
                "SELECT seq,wall_ms,tick_ms,victim,victim_code,victim_name,victim_owner," +
                "source,source_code,source_name,source_owner," +
                "amount,engine,final,actual,hp_before,hp_after,hp_valid," +
                "attack_type,damage_mask,is_physical,flag,depth,final_flags,unit_flags " +
                "FROM game_events WHERE session_id = ?1 AND seq > ?2 AND wall_ms >= ?3 ORDER BY seq LIMIT ?4", out error);
            if (st == null) return list;
            if (!st.Bind(new object?[]
                {
                    sessionId,
                    (long)afterSeq,
                    sinceWallMs > 0 ? sinceWallMs : 0L,
                    (long)Math.Clamp(limit, 1, 4096)
                }, out error))
                return list;

            while (true)
            {
                if (!st.Step(out bool hasRow, out error)) return list;
                if (!hasRow) break;
                SqliteRow r = st.Row;

                long wallMs = r.GetInt64(1);
                DateTime at;
                try { at = DateTimeOffset.FromUnixTimeMilliseconds(wallMs).LocalDateTime; }
                catch { at = DateTime.Now; }

                uint seq = (uint)r.GetInt64(0);
                uint victim = (uint)r.GetInt64(3);
                string vcode = r.GetString(4);
                uint source = (uint)r.GetInt64(7);
                string scode = r.GetString(8);
                double amount = r.GetDouble(11);
                double engine = r.GetDouble(12);
                double final = r.GetDouble(13);
                double actual = r.GetDouble(14);
                double hpBefore = r.GetDouble(15);
                double hpAfter = r.GetDouble(16);
                bool hpValid = r.GetBool(17);
                int attackType = r.GetInt32(18);
                uint mask = (uint)r.GetInt64(19);
                bool physical = r.GetBool(20);
                uint flag = (uint)r.GetInt64(21);
                int depth = r.GetInt32(22);
                uint finalFlags = (uint)r.GetInt64(23);
                uint unitFlags = (uint)r.GetInt64(24);

                int dtype = -1;
                if (mask != 0)
                {
                    int bit = 0;
                    uint m = mask;
                    while ((m & 1u) == 0 && bit < 32) { m >>= 1; bit++; }
                    dtype = bit < 32 ? bit - 1 : -1;
                }

                list.Add(new DamageHook.HookEvent(
                    seq, at, victim, vcode, source, scode,
                    amount,
                    IsAttack: (flag & 0x100u) != 0,
                    IsRanged: (flag & 0x1u) != 0,
                    AttackType: attackType,
                    DamageType: dtype,
                    IsPhysical: physical,
                    VictimName: r.GetString(5),
                    SourceName: r.GetString(9),
                    DamageMask: mask,
                    WeaponType: 0,
                    HpBefore: hpBefore,
                    HpAfter: hpAfter,
                    Actual: actual,
                    HpValid: hpValid,
                    Depth: depth,
                    EngineDamage: engine,
                    EngineValid: engine > 0.005 && hpValid,
                    EngineLast: final,
                    EngineCalls: (int)finalFlags,
                    SetDamage: 0,
                    SetCalls: 0,
                    Flags: unitFlags,
                    VictimOwner: r.GetInt32(6),
                    SourceOwner: r.GetInt32(10),
                    IsV20: true));
            }
        }
        return list;
    }

    /// <summary>
    /// ddh 偶发“后血没读到/帧没配上”时 hp_valid=0，但下一笔同目标事件的 hp_before 已经掉下去了。
    /// 用下一笔的 hp_before 反推这一段净掉血，避免伤害明细里出现断档。
    /// </summary>
    private static void RepairMissingHp(List<DamageHook.HookEvent> list)
    {
        for (int i = 0; i < list.Count; i++)
        {
            var e = list[i];
            if (e.HpValid || e.HpBefore <= 0.005) continue;

            int last = Math.Min(list.Count - 1, i + 12);
            for (int j = i + 1; j <= last; j++)
            {
                var n = list[j];
                if (n.Victim != e.Victim || n.HpBefore <= 0.005) continue;
                double d = e.HpBefore - n.HpBefore;
                if (d <= 0.005 || d > e.HpBefore + 1.0) continue;
                list[i] = e with
                {
                    HpAfter = n.HpBefore,
                    Actual = d,
                    HpValid = true
                };
                break;
            }
        }
    }
#endif
}
