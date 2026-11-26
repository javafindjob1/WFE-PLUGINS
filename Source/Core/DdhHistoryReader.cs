namespace War3DeathSettlement.Core;

/// <summary>
/// 只读 ddh 的当前库结构。会话键严格使用 game_sessions.session_id，
/// 不读取 PID 表、不读取 history.db、不读取 JSON、不创建或升级任何表。
/// </summary>
public static class DdhHistoryReader
{
    public const int EventLimit = 100000;
    public static string DatabasePath => DdhEventDb.FixedPath;
    public static string DefaultDirectory => DdhEventDb.Folder;

    private static bool LooksLikeMapName(string value)
    {
        if (string.IsNullOrWhiteSpace(value)) return false;
        value = value.Trim();
        if (value.Length is < 2 or > 80 || value.Contains('\uFFFD')) return false;
        if (value.EndsWith(".cpp", StringComparison.OrdinalIgnoreCase) ||
            value.EndsWith(".hpp", StringComparison.OrdinalIgnoreCase) ||
            value.EndsWith(".h", StringComparison.OrdinalIgnoreCase) ||
            value.EndsWith(".c", StringComparison.OrdinalIgnoreCase) ||
            value.EndsWith(".obj", StringComparison.OrdinalIgnoreCase))
            return false;
        return value.All(c => !char.IsControl(c));
    }

    public static List<HistoryFileInfo> List(string? databasePath = null)
    {
        var list = new List<HistoryFileInfo>();
        string path = databasePath ?? DatabasePath;
        if (!File.Exists(path)) return list;

        using SqliteConnection? conn = SqliteConnection.Open(path, out string error);
        if (conn == null)
        {
            Log.Warn("读取 ddh 会话列表失败：" + error);
            return list;
        }

        using SqliteStatement? st = conn.Prepare("""
            SELECT s.session_id,
                   s.map_name,
                   s.started_ms,
                   s.updated_ms,
                   COALESCE((SELECT SUM(total_damage) FROM game_settlements x WHERE x.session_id=s.session_id),0),
                   (SELECT COUNT(*) FROM game_settlements x WHERE x.session_id=s.session_id),
                   (SELECT COUNT(*) FROM game_events e WHERE e.session_id=s.session_id),
                   (SELECT COUNT(*) FROM game_units u WHERE u.session_id=s.session_id)
              FROM game_sessions s
             WHERE EXISTS(SELECT 1 FROM game_events e WHERE e.session_id=s.session_id)
                OR EXISTS(SELECT 1 FROM game_units u WHERE u.session_id=s.session_id)
                OR EXISTS(SELECT 1 FROM game_settlements x WHERE x.session_id=s.session_id)
             ORDER BY s.updated_ms DESC;
            """, out error);
        if (st == null)
        {
            Log.Warn("读取 ddh 会话列表失败：" + error);
            return list;
        }

        while (true)
        {
            if (!st.Step(out bool row, out error))
            {
                Log.Warn("读取 ddh 会话列表失败：" + error);
                break;
            }
            if (!row) break;

            string sessionId = st.Row.GetString(0);
            string mapName = st.Row.GetString(1);
            if (!LooksLikeMapName(mapName)) mapName = "";
            DateTimeOffset started = MsToTime(st.Row.GetInt64(2));
            DateTimeOffset ended = MsToTime(st.Row.GetInt64(3));
            list.Add(new HistoryFileInfo
            {
                SessionId = sessionId,
                Path = path + "#" + sessionId,
                FileName = "Session " + sessionId,
                StartedAt = started,
                EndedAt = ended,
                MapName = mapName,
                TotalDamage = st.Row.GetDouble(4),
                SettlementCount = st.Row.GetInt32(5),
                EventCount = st.Row.GetInt32(6),
                UnitCount = st.Row.GetInt32(7),
            });
        }
        return list;
    }

    public static HistoryDocument? Load(HistoryFileInfo info, out string error, string? databasePath = null)
    {
        if (string.IsNullOrWhiteSpace(info.SessionId))
        {
            error = "会话 ID 为空";
            return null;
        }
        return Load(info.SessionId, out error, databasePath);
    }

    public static HistoryDocument? Load(string sessionId, out string error, string? databasePath = null)
    {
        error = "";
        if (string.IsNullOrWhiteSpace(sessionId)) { error = "会话 ID 为空"; return null; }
        string path = databasePath ?? DatabasePath;
        if (!File.Exists(path)) { error = "ddh 明细库不存在"; return null; }

        using SqliteConnection? conn = SqliteConnection.Open(path, out error);
        if (conn == null) return null;

        var doc = new HistoryDocument { SessionId = sessionId };
        bool found = false;
        using (SqliteStatement? st = conn.Prepare(
            "SELECT map_name,started_ms,updated_ms FROM game_sessions WHERE session_id=?1;", out error))
        {
            if (st == null || !st.Bind(new object?[] { sessionId }, out error)) return null;
            if (st.Step(out bool row, out error) && row)
            {
                found = true;
                doc.MapName = st.Row.GetString(0);
                if (!LooksLikeMapName(doc.MapName)) doc.MapName = "";
                doc.StartedAt = MsToTime(st.Row.GetInt64(1));
                doc.EndedAt = MsToTime(st.Row.GetInt64(2));
            }
            else if (error.Length > 0) return null;
        }
        if (!found) { error = "会话不存在：" + sessionId; return null; }

        using (SqliteStatement? st = conn.Prepare("""
            SELECT wall_ms,victim,victim_code,victim_name,victim_owner,
                   total_damage,hits,max_hit,fatal_source,fatal_source_name,fatal_damage,
                   first_tick,last_tick
              FROM game_settlements WHERE session_id=?1 ORDER BY wall_ms;
            """, out error))
        {
            if (st == null || !st.Bind(new object?[] { sessionId }, out error)) return null;
            while (true)
            {
                if (!st.Step(out bool row, out error)) return null;
                if (!row) break;
                var r = st.Row;
                DateTime diedAt = MsToTime(r.GetInt64(0)).LocalDateTime;
                doc.Settlements.Add(new HistorySettlement
                {
                    DiedAt = diedAt,
                    FirstSeen = diedAt,
                    UnitName = r.GetString(3),
                    TypeCode = r.GetString(2),
                    Addr = (uint)r.GetInt64(1),
                    OwnerSlot = r.GetInt32(4),
                    TotalDamage = r.GetDouble(5),
                    HitCount = r.GetInt32(6),
                    MaxHit = r.GetDouble(7),
                    FirstTick = r.GetInt64(11),
                    LastTick = r.GetInt64(12),
                    Kind = "死亡",
                });
            }
        }

        using (SqliteStatement? st = conn.Prepare("""
            SELECT addr,type_code,name,title,owner_slot,attack_range,damage_min,damage_max,
                   attack_interval,armor,move_speed,sight_day,sight_night,acquire_range,
                   strength,agility,intelligence,illusion,dead,attack_speed
              FROM game_units WHERE session_id=?1 ORDER BY dead,owner_slot,addr;
            """, out error))
        {
            if (st == null || !st.Bind(new object?[] { sessionId }, out error)) return null;
            while (true)
            {
                if (!st.Step(out bool row, out error)) return null;
                if (!row) break;
                var r = st.Row;
                doc.Units.Add(new HistoryUnit
                {
                    Addr = (uint)r.GetInt64(0),
                    TypeCode = r.GetString(1),
                    Name = Wc3Text.Clean(r.GetString(2)),
                    Title = Wc3Text.Clean(r.GetString(3)),
                    OwnerSlot = r.GetInt32(4),
                    AttackRange = r.GetDouble(5),
                    DamageMin = r.GetDouble(6),
                    DamageMax = r.GetDouble(7),
                    AttackInterval = r.GetDouble(8),
                    Armor = r.GetDouble(9),
                    MoveSpeed = r.GetDouble(10),
                    SightDay = r.GetDouble(11),
                    SightNight = r.GetDouble(12),
                    AcquireRange = r.GetDouble(13),
                    Strength = r.GetDouble(14),
                    Agility = r.GetDouble(15),
                    Intelligence = r.GetDouble(16),
                    IsIllusion = r.GetBool(17),
                    Dead = r.GetBool(18),
                    AttackSpeed = r.GetDouble(19),
                });
            }
        }

        using (SqliteStatement? st = conn.Prepare("""
            SELECT seq,wall_ms,victim,victim_code,victim_name,source,source_code,source_name,
                   amount,actual,hp_before,hp_after,hp_valid,attack_type,damage_mask,is_physical,
                   flag,depth,engine,final,victim_owner,source_owner,final_flags,unit_flags,tick_ms
              FROM game_events WHERE session_id=?1 ORDER BY wall_ms,seq LIMIT ?2;
            """, out error))
        {
            if (st == null || !st.Bind(new object?[] { sessionId, (long)EventLimit + 1 }, out error)) return null;
            while (true)
            {
                if (!st.Step(out bool row, out error)) return null;
                if (!row) break;
                if (doc.Events.Count >= EventLimit) { doc.Truncated = true; break; }
                var r = st.Row;
                uint mask = (uint)r.GetInt64(14);
                int dtype = -1;
                if (mask != 0)
                {
                    int bit = 0;
                    uint m = mask;
                    while ((m & 1u) == 0 && bit < 32) { m >>= 1; bit++; }
                    dtype = bit < 32 ? bit - 1 : -1;
                }
                doc.Events.Add(new HistoryEvent
                {
                    Seq = (uint)r.GetInt64(0),
                    At = MsToTime(r.GetInt64(1)).LocalDateTime,
                    TickMs = r.GetInt64(24),
                    Victim = (uint)r.GetInt64(2),
                    VictimCode = r.GetString(3),
                    VictimName = r.GetString(4),
                    Source = (uint)r.GetInt64(5),
                    SourceCode = r.GetString(6),
                    SourceName = r.GetString(7),
                    Amount = r.GetDouble(8),
                    Actual = r.GetDouble(9),
                    HpBefore = r.GetDouble(10),
                    HpAfter = r.GetDouble(11),
                    HpValid = r.GetBool(12),
                    AttackType = r.GetInt32(13),
                    DamageMask = mask,
                    DamageType = dtype,
                    IsPhysical = r.GetBool(15),
                    IsAttack = (r.GetInt64(16) & 0x100) != 0,
                    IsRanged = (r.GetInt64(16) & 1) != 0,
                    Depth = r.GetInt32(17),
                    EngineDamage = r.GetDouble(18),
                    EngineValid = r.GetDouble(18) > 0.005 && r.GetBool(12),
                    EngineLast = r.GetDouble(19),
                    VictimOwner = r.GetInt32(20),
                    SourceOwner = r.GetInt32(21),
                    EngineCalls = r.GetInt32(22),
                    Flags = (uint)r.GetInt64(23),
                    IsV20 = true,
                });
            }
        }

        doc.EventsTotal = doc.Events.Count;
        doc.UnitCount = doc.Units.Count;
        ApplyTitles(doc);
        BuildBreakdowns(doc);
        return doc;
    }

    private static void ApplyTitles(HistoryDocument doc)
    {
        var byAddr = doc.Units.GroupBy(u => u.Addr).ToDictionary(g => g.Key, g => g.First());
        var byIdentity = doc.Units
            .GroupBy(u => IdentityKey(doc.SessionId, u.TypeCode, u.IsIllusion), StringComparer.OrdinalIgnoreCase)
            .ToDictionary(g => g.Key, g => g.First(), StringComparer.OrdinalIgnoreCase);

        bool TryIdentity(string code, bool illusion, out HistoryUnit unit) =>
            byIdentity.TryGetValue(IdentityKey(doc.SessionId, code, illusion), out unit!);

        bool TryIdentityByAddress(uint addr, string code, out HistoryUnit unit)
        {
            bool illusion = byAddr.TryGetValue(addr, out HistoryUnit? atAddr) && atAddr.IsIllusion;
            return TryIdentity(code, illusion, out unit);
        }

        foreach (var s in doc.Settlements)
        {
            if (TryIdentityByAddress(s.Addr, s.TypeCode, out HistoryUnit unit))
            {
                s.UnitName = unit.Name;
                s.Title = unit.Title;
            }
            else
            {
                s.UnitName = "";
                s.Title = "";
            }
        }
        foreach (var e in doc.Events)
        {
            if (TryIdentity(e.VictimCode, e.VictimIllusion, out HistoryUnit victim))
            {
                e.VictimName = victim.Name;
                e.VictimTitle = victim.Title;
            }
            else
            {
                e.VictimName = "";
                e.VictimTitle = "";
            }
            if (TryIdentity(e.SourceCode, e.SourceIllusion, out HistoryUnit source))
            {
                e.SourceName = source.Name;
                e.SourceTitle = source.Title;
            }
            else
            {
                e.SourceName = "";
                e.SourceTitle = "";
            }
        }
    }

    private static void BuildBreakdowns(HistoryDocument doc)
    {
        var unitsByIdentity = doc.Units
            .GroupBy(u => IdentityKey(doc.SessionId, u.TypeCode, u.IsIllusion), StringComparer.OrdinalIgnoreCase)
            .ToDictionary(g => g.Key, g => g.First(), StringComparer.OrdinalIgnoreCase);

        static string MirrorSuffix(string text) =>
            text.Contains("（镜像）", StringComparison.Ordinal) ||
            text.Contains("(镜像)", StringComparison.Ordinal)
                ? text
                : text + "（镜像）";
        string SourceIdentity(HistoryEvent e)
        {
            if (!unitsByIdentity.TryGetValue(IdentityKey(doc.SessionId, e.SourceCode, e.SourceIllusion),
                                             out HistoryUnit? unit))
                return e.SourceCode;
            string label = Wc3Text.UnitIdentity(unit.Name, unit.Title, e.SourceCode);
            return e.SourceIllusion ? MirrorSuffix(label) : label;
        }

        foreach (var s in doc.Settlements)
        {
            bool hasTickWindow = s.FirstTick > 0 && s.LastTick >= s.FirstTick;
            var events = doc.Events
                .Where(e => e.Victim == s.Addr &&
                            e.HpValid && e.Actual > 0.005 &&
                            (!hasTickWindow || (e.TickMs >= s.FirstTick && e.TickMs <= s.LastTick)))
                .ToList();
            if (events.Count == 0) continue;
            var hits = events
                .Select(e => (e.At, Value: e.Actual))
                .OrderBy(x => x.At)
                .ToList();
            if (hits.Count > 0)
            {
                s.FirstSeen = events.Min(e => e.At);
                s.MinHit = hits.Min(x => x.Value);
                s.MaxHit = hits.Max(x => x.Value);
                s.CombatSeconds = Math.Max(1, (s.DiedAt - s.FirstSeen).TotalSeconds);
                s.LifetimeSeconds = s.CombatSeconds;
                s.Dps = s.TotalDamage / Math.Max(1, s.CombatSeconds);

                double peak = 0, window = 0;
                int left = 0;
                for (int right = 0; right < hits.Count; right++)
                {
                    window += hits[right].Value;
                    while ((hits[right].At - hits[left].At).TotalSeconds > 1.0)
                        window -= hits[left++].Value;
                    peak = Math.Max(peak, window);
                }
                s.Peak1s = peak;
            }
            s.HpMax = Math.Max(s.HpMax, events.Max(e => e.HpBefore));
            double rawTotal = events.Sum(e => e.Amount);
            double netTotal = events.Sum(e => e.HpValid && e.Actual > 0.005 ? e.Actual : 0);
            foreach (var g in events.GroupBy(e => new
            {
                Source = SourceIdentity(e),
                e.IsAttack,
                e.IsRanged,
                e.AttackType,
                e.DamageType,
            }))
            {
                double damage = g.Sum(e => e.Amount);
                double net = g.Sum(e => e.HpValid && e.Actual > 0.005 ? e.Actual : 0);
                double engine = g.Sum(e => e.EngineDamage > 0.005 ? e.EngineDamage : 0);
                bool engineValid = g.Any(e => e.EngineDamage > 0.005);
                bool netValid = g.Any(e => e.HpValid);
                double percent = netTotal > 0
                    ? net / netTotal * 100.0
                    : rawTotal > 0 ? damage / rawTotal * 100.0 : 0;
                string source = g.Key.Source;
                s.Sources.Add(new HistorySource
                {
                    Source = source,
                    Count = g.Count(),
                    Damage = damage,
                    Engine = engine,
                    EngineValid = engineValid,
                    Effective = net,
                    EffectiveValid = netValid,
                    NetDrop = net,
                    NetValid = netValid,
                    Percent = percent,
                });
                s.Combos.Add(new HistoryCombo
                {
                    Source = source,
                    IsAttack = g.Key.IsAttack ? "1" : "0",
                    IsRanged = g.Key.IsRanged ? "1" : "0",
                    AttackType = g.Key.AttackType.ToString(),
                    DamageType = g.Key.DamageType.ToString(),
                    Count = g.Count(),
                    Damage = damage,
                    Engine = engine,
                    EngineValid = engineValid,
                    Effective = net,
                    EffectiveValid = netValid,
                    NetDrop = net,
                    NetValid = netValid,
                    Percent = percent,
                });
            }
        }
    }

    private static DateTimeOffset MsToTime(long ms) =>
        ms > 0 ? DateTimeOffset.FromUnixTimeMilliseconds(ms) : DateTimeOffset.Now;

    private static string IdentityKey(string sessionId, string code, bool illusion) =>
        sessionId + "|" + code + "|" + (illusion ? "I" : "0");
}
