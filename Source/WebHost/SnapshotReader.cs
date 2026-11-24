using System.Globalization;
using System.Numerics;
using War3DeathSettlement.Core;

namespace DdhWebHost;

internal static class SnapshotReader
{
    private static readonly DateTime Epoch = DateTime.UnixEpoch;
    private const uint FlagVictimIllusion = 1u << 1;
    private const uint FlagSourceIllusion = 1u << 2;
    private const int MetricCacheCapacity = 4;

    private static readonly object MetricsGate = new();
    private static readonly Dictionary<string, MetricsCache> MetricCaches =
        new(StringComparer.Ordinal);

    private sealed class MetricsCache
    {
        public long LastSeq { get; set; }
        public Dictionary<uint, VictimMetrics> Victims { get; } = new();
    }

    private sealed class VictimMetrics
    {
        public List<MetricHit> Hits { get; } = new();
        private Dictionary<(long FirstTick, long LastTick), WindowMetrics> Windows { get; } = new();

        public void InvalidateWindows() => Windows.Clear();

        public WindowMetrics ForWindow(long firstTick, long lastTick)
        {
            var key = (firstTick, lastTick);
            if (Windows.TryGetValue(key, out WindowMetrics cached)) return cached;

            List<MetricHit> selected = firstTick > 0 && lastTick >= firstTick
                ? Hits.Where(x => x.TickMs >= firstTick && x.TickMs <= lastTick).ToList()
                : Hits;

            long firstWallMs = selected.Count > 0 ? selected[0].WallMs : long.MaxValue;
            double maxHit = 0;
            double peak = 0;
            double window = 0;
            int left = 0;
            for (int right = 0; right < selected.Count; right++)
            {
                MetricHit hit = selected[right];
                maxHit = Math.Max(maxHit, hit.Value);
                window += hit.Value;
                while ((hit.WallMs - selected[left].WallMs) / 1000.0 > 1.0)
                    window -= selected[left++].Value;
                peak = Math.Max(peak, window);
            }

            var result = new WindowMetrics(selected.Count, firstWallMs, maxHit, peak);
            Windows[key] = result;
            return result;
        }
    }

    private readonly record struct MetricHit(long WallMs, long TickMs, long Seq, double Value);
    private readonly record struct WindowMetrics(int HitCount, long FirstWallMs, double MaxHit, double Peak1s);

    public static SettlementSnapshot Read(
        string databasePath,
        int requestedPid,
        string requestedSessionId = "")
    {
        var snapshot = new SettlementSnapshot
        {
            GeneratedAt = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture),
            Pid = Math.Max(0, requestedPid),
            DatabasePath = databasePath,
        };

        if (!File.Exists(databasePath))
        {
            snapshot.Message = "SQLite 文件尚未生成";
            return snapshot;
        }
        if (!Sqlite.Available)
        {
            snapshot.Message = "winsqlite3.dll 不可用：" + Sqlite.Error;
            return snapshot;
        }

        using SqliteConnection? conn = SqliteConnection.Open(databasePath, out string error);
        if (conn == null)
        {
            snapshot.Message = "SQLite 打开失败：" + error;
            return snapshot;
        }

        string sessionId = requestedSessionId.Length > 0
            ? requestedSessionId
            : ReadLatestSession(conn);
        snapshot.SessionId = sessionId;
        snapshot.Pid = Math.Max(0, requestedPid);
        if (sessionId.Length == 0)
        {
            snapshot.Message = "SQLite 中还没有对局会话";
            return snapshot;
        }

        ReadSession(conn, snapshot, sessionId);
        ReadCounts(conn, snapshot, sessionId);
        ReadUnits(conn, snapshot, sessionId);
        ResolveIdentities(snapshot);
        snapshot.Message = snapshot.Counts.Events > 0 || snapshot.Counts.Settlements > 0 ||
                           snapshot.Counts.Units > 0
            ? "SQLite 实时数据"
            : requestedSessionId.Length > 0
                ? "等待本局写入单位或战斗事件"
                : "SQLite 已连接，等待战斗事件";
        return snapshot;
    }

    public static EventPage ReadEventPage(
        string databasePath,
        string requestedSessionId,
        string query,
        int requestedPage,
        int requestedPageSize,
        string victimCodeFilter,
        bool victimIllusionFilter,
        string sourceCodeFilter,
        bool sourceIllusionFilter,
        long requestId)
    {
        var result = new EventPage
        {
            RequestId = requestId,
            Page = Math.Max(0, requestedPage),
            PageSize = Math.Clamp(requestedPageSize, 50, 1000),
        };
        if (!File.Exists(databasePath))
        {
            result.Error = "SQLite 文件尚未生成";
            return result;
        }
        if (!Sqlite.Available)
        {
            result.Error = "winsqlite3.dll 不可用：" + Sqlite.Error;
            return result;
        }

        using SqliteConnection? conn = SqliteConnection.Open(databasePath, out string error);
        if (conn == null)
        {
            result.Error = "SQLite 打开失败：" + error;
            return result;
        }

        string sessionId = requestedSessionId.Length > 0
            ? requestedSessionId
            : ReadLatestSession(conn);
        result.SessionId = sessionId;
        if (sessionId.Length == 0)
        {
            result.Error = "SQLite 中还没有对局会话";
            return result;
        }

        (string where, object?[] filterArgs) = EventWhere(
            query,
            victimCodeFilter,
            victimIllusionFilter,
            sourceCodeFilter,
            sourceIllusionFilter);
        object?[] args = new object?[] { sessionId }.Concat(filterArgs).ToArray();
        conn.Query(
            "SELECT COUNT(*),COALESCE(MAX(seq),0) FROM game_events " + where + ";",
            args,
            row =>
            {
                result.Total = row.GetInt32(0);
                result.EventRevision = row.GetInt64(1);
            },
            out error);
        if (error.Length > 0)
        {
            result.Error = "读取事件总数失败：" + error;
            return result;
        }

        int maxPage = result.Total == 0
            ? 0
            : Math.Max(0, (result.Total - 1) / result.PageSize);
        result.Page = Math.Clamp(result.Page, 0, maxPage);
        long offset = (long)result.Page * result.PageSize;
        object?[] pageArgs = args.Concat(new object?[] { result.PageSize, offset }).ToArray();
        conn.Query(
            "SELECT seq,wall_ms,victim,victim_code,victim_name,victim_owner," +
            "source,source_code,source_name,source_owner,amount,engine,final,actual," +
            "hp_before,hp_after,hp_valid,attack_type,damage_mask,is_physical,flag,depth," +
            "final_flags,unit_flags FROM game_events " + where +
            " ORDER BY wall_ms DESC,seq DESC LIMIT ?" + (filterArgs.Length + 2) +
            " OFFSET ?" + (filterArgs.Length + 3) + ";",
            pageArgs,
            row => result.Rows.Add(ReadDamageEvent(row)),
            out error);
        if (error.Length > 0)
        {
            result.Rows.Clear();
            result.Error = "读取事件页失败：" + error;
            return result;
        }

        ResolveEventNames(conn, sessionId, result.Rows);
        return result;
    }

    public static SettlementPage ReadSettlementPage(
        string databasePath,
        string requestedSessionId,
        string query,
        int requestedPage,
        int requestedPageSize,
        string victimCodeFilter,
        long requestId)
    {
        var result = new SettlementPage
        {
            RequestId = requestId,
            Page = Math.Max(0, requestedPage),
            PageSize = Math.Clamp(requestedPageSize, 50, 500),
        };
        if (!File.Exists(databasePath))
        {
            result.Error = "SQLite 文件尚未生成";
            return result;
        }
        if (!Sqlite.Available)
        {
            result.Error = "winsqlite3.dll 不可用：" + Sqlite.Error;
            return result;
        }

        using SqliteConnection? conn = SqliteConnection.Open(databasePath, out string error);
        if (conn == null)
        {
            result.Error = "SQLite 打开失败：" + error;
            return result;
        }

        string sessionId = requestedSessionId.Length > 0
            ? requestedSessionId
            : ReadLatestSession(conn);
        result.SessionId = sessionId;
        if (sessionId.Length == 0)
        {
            result.Error = "SQLite 中还没有对局会话";
            return result;
        }

        (string where, object?[] filterArgs) = SettlementWhere(query, victimCodeFilter);
        object?[] args = new object?[] { sessionId }.Concat(filterArgs).ToArray();
        conn.Query(
            "SELECT COUNT(*) FROM game_settlements x " + where + ";",
            args,
            row => result.Total = row.GetInt32(0),
            out error);
        if (error.Length > 0)
        {
            result.Error = "读取死亡结算总数失败：" + error;
            return result;
        }

        int maxPage = result.Total == 0
            ? 0
            : Math.Max(0, (result.Total - 1) / result.PageSize);
        result.Page = Math.Clamp(result.Page, 0, maxPage);
        long offset = (long)result.Page * result.PageSize;
        object?[] pageArgs = args.Concat(new object?[] { result.PageSize, offset }).ToArray();
        int limitArg = filterArgs.Length + 2;
        int offsetArg = filterArgs.Length + 3;
        conn.Query(
            "SELECT x.seq,x.wall_ms,x.victim,x.victim_code,x.victim_name,x.victim_owner," +
            "x.total_damage,x.hits,x.max_hit,x.fatal_source,x.fatal_source_code,x.fatal_source_name," +
            "x.fatal_damage,x.first_tick,x.last_tick FROM game_settlements x " + where +
            " ORDER BY x.wall_ms DESC,x.seq DESC LIMIT ?" + limitArg + " OFFSET ?" + offsetArg + ";",
            pageArgs,
            row => result.Rows.Add(ReadSettlementRow(row, 0)),
            out error);
        if (error.Length > 0)
        {
            result.Rows.Clear();
            result.Error = "读取死亡结算页失败：" + error;
            return result;
        }

        long eventRevision = 0;
        conn.Query(
            "SELECT COALESCE(MAX(seq),0) FROM game_events WHERE session_id=?1;",
            new object?[] { sessionId },
            row => eventRevision = row.GetInt64(0),
            out _);

        var view = new SettlementSnapshot { EventRevision = eventRevision };
        ReadUnits(conn, view, sessionId);
        view.Settlements.AddRange(result.Rows);
        ResolveIdentities(view);
        ApplyCachedSettlementMetrics(conn, view, sessionId, databasePath);
        return result;
    }

    public static SettlementDetail ReadSettlementDetail(
        string databasePath,
        string requestedSessionId,
        long settlementSeq,
        long requestId)
    {
        var result = new SettlementDetail
        {
            RequestId = requestId,
            Seq = settlementSeq,
        };
        if (!File.Exists(databasePath))
        {
            result.Error = "SQLite 文件尚未生成";
            return result;
        }
        if (!Sqlite.Available)
        {
            result.Error = "winsqlite3.dll 不可用：" + Sqlite.Error;
            return result;
        }

        using SqliteConnection? conn = SqliteConnection.Open(databasePath, out string error);
        if (conn == null)
        {
            result.Error = "SQLite 打开失败：" + error;
            return result;
        }

        string sessionId = requestedSessionId.Length > 0
            ? requestedSessionId
            : ReadLatestSession(conn);
        result.SessionId = sessionId;
        if (sessionId.Length == 0)
        {
            result.Error = "SQLite 中还没有对局会话";
            return result;
        }

        bool found = false;
        double totalDamage = 0;
        long settlementWallMs = 0;
        long firstTick = 0;
        long lastTick = 0;
        conn.Query(
            "SELECT victim,total_damage,wall_ms,first_tick,last_tick " +
            "FROM game_settlements WHERE session_id=?1 AND seq=?2 LIMIT 1;",
            new object?[] { sessionId, settlementSeq },
            row =>
            {
                result.Victim = (uint)row.GetInt64(0);
                totalDamage = row.GetDouble(1);
                settlementWallMs = row.GetInt64(2);
                firstTick = row.GetInt64(3);
                lastTick = row.GetInt64(4);
                found = true;
            },
            out error);
        if (error.Length > 0)
        {
            result.Error = "读取死亡记录失败：" + error;
            return result;
        }
        if (!found)
        {
            result.Error = "找不到这条死亡记录";
            return result;
        }

        var events = new List<DamageEventRow>();
        string eventSql =
            "SELECT seq,wall_ms,victim,victim_code,victim_name,victim_owner," +
            "source,source_code,source_name,source_owner,amount,engine,final,actual," +
            "hp_before,hp_after,hp_valid,attack_type,damage_mask,is_physical,flag,depth," +
            "final_flags,unit_flags FROM game_events " +
            "WHERE session_id=?1 AND victim=?2 AND hp_valid=1 AND actual>0.005 ";
        object?[] eventArgs;
        if (firstTick > 0 && lastTick >= firstTick)
        {
            eventSql += "AND tick_ms>=?3 AND tick_ms<=?4 ORDER BY wall_ms,seq;";
            eventArgs = new object?[] { sessionId, (long)result.Victim, firstTick, lastTick };
        }
        else
        {
            // 老库没有 tick 边界时至少截到本次死亡时刻，避免把之后复用同一地址的事件算进来。
            eventSql += "AND wall_ms<=?3 ORDER BY wall_ms,seq;";
            eventArgs = new object?[] { sessionId, (long)result.Victim, settlementWallMs };
        }
        conn.Query(eventSql, eventArgs, row => events.Add(ReadDamageEvent(row)), out error);
        if (error.Length > 0)
        {
            result.Error = "读取死亡明细失败：" + error;
            return result;
        }

        ResolveEventNames(conn, sessionId, events);
        result.EventCount = events.Count;
        result.Rows = BuildBreakdown(events);
        if (totalDamage > 0.005 && events.Sum(NetValue) <= 0.005)
            result.Error = "这条死亡记录有总伤害，但没有匹配到有效的净掉血事件";
        return result;
    }

    private static string ReadLatestSession(SqliteConnection conn)
    {
        string sessionId = "";
        conn.Query(
            "SELECT session_id FROM game_sessions " +
            "WHERE EXISTS(SELECT 1 FROM game_events e WHERE e.session_id=game_sessions.session_id) " +
            "   OR EXISTS(SELECT 1 FROM game_units u WHERE u.session_id=game_sessions.session_id) " +
            "   OR EXISTS(SELECT 1 FROM game_settlements x WHERE x.session_id=game_sessions.session_id) " +
            "ORDER BY updated_ms DESC LIMIT 1;",
            null,
            row => sessionId = row.GetString(0),
            out _);
        return sessionId;
    }

    private static void ReadSession(
        SqliteConnection conn,
        SettlementSnapshot snapshot,
        string sessionId)
    {
        conn.Query(
            "SELECT map_name,updated_ms FROM game_sessions WHERE session_id=?1 LIMIT 1;",
            new object?[] { sessionId },
            row =>
            {
                snapshot.MapName = Wc3Text.Clean(row.GetString(0));
                long updated = row.GetInt64(1);
                snapshot.SessionRevision = updated;
                if (updated > 0)
                {
                    snapshot.SessionUpdatedAt = FromUnixMs(updated)
                        .ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture);
                }
            },
            out _);
    }

    private static void ReadCounts(
        SqliteConnection conn,
        SettlementSnapshot snapshot,
        string sessionId)
    {
        conn.Query(
            "SELECT (SELECT COUNT(*) FROM game_settlements WHERE session_id=?1)," +
            "(SELECT COUNT(*) FROM game_events WHERE session_id=?1)," +
            "(SELECT COUNT(*) FROM game_units WHERE session_id=?1)," +
            "(SELECT COALESCE(MAX(seq),0) FROM game_events WHERE session_id=?1);",
            new object?[] { sessionId },
            row =>
            {
                snapshot.Counts.Settlements = row.GetInt32(0);
                snapshot.Counts.Events = row.GetInt32(1);
                snapshot.Counts.Units = row.GetInt32(2);
                snapshot.EventRevision = row.GetInt64(3);
            },
            out _);
    }

    private static SettlementRow ReadSettlementRow(SqliteRow row, int pid)
    {
        long wall = row.GetInt64(1);
        return new SettlementRow
        {
            Pid = pid,
            Seq = row.GetInt64(0),
            WallMs = wall,
            DiedAt = wall > 0
                ? FromUnixMs(wall).ToString("HH:mm:ss.fff", CultureInfo.InvariantCulture)
                : "—",
            Victim = (uint)row.GetInt64(2),
            VictimCode = row.GetString(3),
            VictimName = Wc3Text.Clean(row.GetString(4)),
            VictimOwner = row.GetInt32(5),
            TotalDamage = row.GetDouble(6),
            Hits = row.GetInt32(7),
            MaxHit = row.GetDouble(8),
            FatalSource = (uint)row.GetInt64(9),
            FatalSourceCode = row.GetString(10),
            FatalSourceName = Wc3Text.Clean(row.GetString(11)),
            FatalDamage = row.GetDouble(12),
            FirstTick = row.GetInt64(13),
            LastTick = row.GetInt64(14),
        };
    }

    private static void ReadUnits(
        SqliteConnection conn,
        SettlementSnapshot snapshot,
        string sessionId)
    {
        conn.Query(
            "SELECT addr,type_code,name,title,owner_slot,attack_range,damage_min,damage_max," +
            "attack_interval,armor,move_speed,sight_day,sight_night,acquire_range," +
            "strength,agility,intelligence,hero,illusion,dead,locust,attack_speed " +
            "FROM game_units WHERE session_id=?1 ORDER BY dead,owner_slot,addr LIMIT 500;",
            new object?[] { sessionId },
            row =>
            {
                snapshot.Units.Add(new UnitRow
                {
                    Addr = (uint)row.GetInt64(0),
                    TypeCode = row.GetString(1),
                    Name = Wc3Text.Clean(row.GetString(2)),
                    Title = Wc3Text.Clean(row.GetString(3)),
                    OwnerSlot = row.GetInt32(4),
                    AttackRange = row.GetDouble(5),
                    DamageMin = row.GetDouble(6),
                    DamageMax = row.GetDouble(7),
                    AttackInterval = row.GetDouble(8),
                    Armor = row.GetDouble(9),
                    MoveSpeed = row.GetDouble(10),
                    SightDay = row.GetDouble(11),
                    SightNight = row.GetDouble(12),
                    AcquireRange = row.GetDouble(13),
                    Strength = row.GetDouble(14),
                    Agility = row.GetDouble(15),
                    Intelligence = row.GetDouble(16),
                    Hero = row.GetBool(17),
                    Illusion = row.GetBool(18),
                    Dead = row.GetBool(19),
                    Locust = row.GetBool(20),
                    AttackSpeed = row.GetDouble(21),
                });
            },
            out _);
    }

    private static void ApplyCachedSettlementMetrics(
        SqliteConnection conn,
        SettlementSnapshot snapshot,
        string sessionId,
        string databasePath)
    {
        string key = Path.GetFullPath(databasePath) + "\u0001" + sessionId;
        lock (MetricsGate)
        {
            if (!MetricCaches.TryGetValue(key, out MetricsCache? cache) ||
                snapshot.EventRevision < cache.LastSeq)
            {
                cache = new MetricsCache();
                MetricCaches[key] = cache;
            }

            if (cache.LastSeq < snapshot.EventRevision)
            {
                bool firstLoad = cache.LastSeq == 0;
                ReadMetricEvents(
                    conn,
                    cache,
                    sessionId,
                    cache.LastSeq,
                    firstLoad ? snapshot.Settlements.Select(x => x.Victim).ToHashSet() : null);
                cache.LastSeq = snapshot.EventRevision;
            }

            foreach (uint victim in snapshot.Settlements.Select(x => x.Victim).Distinct())
            {
                if (cache.Victims.ContainsKey(victim)) continue;
                ReadMetricEvents(conn, cache, sessionId, 0, new HashSet<uint> { victim });
            }

            foreach (SettlementRow settlement in snapshot.Settlements)
            {
                settlement.Kind = "死亡";
                settlement.InstanceIndex = 1;
                if (!cache.Victims.TryGetValue(settlement.Victim, out VictimMetrics? metrics))
                    continue;

                WindowMetrics window = metrics.ForWindow(settlement.FirstTick, settlement.LastTick);
                if (window.HitCount == 0 || window.FirstWallMs == long.MaxValue) continue;

                settlement.MaxHit = window.MaxHit;
                double combat = Math.Max(1.0, (settlement.WallMs - window.FirstWallMs) / 1000.0);
                settlement.LifetimeSeconds = combat;
                settlement.CombatSeconds = combat;
                settlement.Dps = settlement.TotalDamage / combat;
                settlement.Peak1s = window.Peak1s;
            }

            while (MetricCaches.Count > MetricCacheCapacity)
            {
                string? oldest = MetricCaches.Keys.FirstOrDefault(x => x != key);
                if (oldest == null) break;
                MetricCaches.Remove(oldest);
            }
        }
    }

    private static void ReadMetricEvents(
        SqliteConnection conn,
        MetricsCache cache,
        string sessionId,
        long afterSeq,
        HashSet<uint>? victims)
    {
        if (victims is { Count: 0 }) return;
        string sql =
            "SELECT seq,wall_ms,tick_ms,victim,actual FROM game_events " +
            "WHERE session_id=?1 AND seq>?2 AND hp_valid=1 AND actual>0.005";
        var args = new List<object?> { sessionId, afterSeq };
        if (victims is { Count: 1 })
        {
            sql += " AND victim=?3";
            args.Add((long)victims.First());
        }
        else if (victims is { Count: > 1 })
        {
            int firstArg = args.Count + 1;
            string[] placeholders = victims
                .Select((_, index) => "?" + (firstArg + index))
                .ToArray();
            sql += " AND victim IN (" + string.Join(",", placeholders) + ")";
            args.AddRange(victims.Select(victim => (object?)(long)victim));
        }
        sql += " ORDER BY wall_ms,seq;";

        var touched = new HashSet<uint>();
        conn.Query(
            sql,
            args.ToArray(),
            row =>
            {
                long wall = row.GetInt64(1);
                long tick = row.GetInt64(2);
                uint victim = (uint)row.GetInt64(3);
                if (!cache.Victims.TryGetValue(victim, out VictimMetrics? metrics))
                {
                    metrics = new VictimMetrics();
                    cache.Victims[victim] = metrics;
                }

                long seq = row.GetInt64(0);
                double actual = row.GetDouble(4);
                if (actual > 0.005)
                {
                    metrics.Hits.Add(new MetricHit(wall, tick, seq, actual));
                    touched.Add(victim);
                }
            },
            out _);

        foreach (uint victim in touched)
        {
            VictimMetrics metrics = cache.Victims[victim];
            metrics.Hits.Sort(static (a, b) =>
                a.WallMs != b.WallMs
                    ? a.WallMs.CompareTo(b.WallMs)
                    : a.Seq.CompareTo(b.Seq));
            metrics.InvalidateWindows();
        }
    }

    private static (string Where, object?[] Args) SettlementWhere(
        string query,
        string victimCodeFilter)
    {
        string term = (query ?? "").Trim();
        string victimCode = (victimCodeFilter ?? "").Trim();
        string where =
            "WHERE x.session_id=?1 " +
            "AND (?2='' OR instr(lower(COALESCE(x.victim_name,'')),lower(?2))>0 " +
            " OR instr(lower(COALESCE(x.victim_code,'')),lower(?2))>0 " +
            " OR instr(lower(COALESCE(x.fatal_source_name,'')),lower(?2))>0 " +
            " OR instr(lower(COALESCE(x.fatal_source_code,'')),lower(?2))>0 " +
            " OR instr(lower(printf('0x%08X',x.victim)),lower(?2))>0 " +
            " OR instr(lower(printf('0x%08X',x.fatal_source)),lower(?2))>0 " +
            " OR EXISTS(SELECT 1 FROM game_units u " +
            "            WHERE u.session_id=x.session_id " +
            "              AND lower(COALESCE(u.type_code,''))=lower(COALESCE(x.victim_code,'')) " +
            "              AND (instr(lower(COALESCE(u.name,'')),lower(?2))>0 " +
            "                OR instr(lower(COALESCE(u.title,'')),lower(?2))>0)) " +
            " OR EXISTS(SELECT 1 FROM game_units u " +
            "            WHERE u.session_id=x.session_id " +
            "              AND lower(COALESCE(u.type_code,''))=lower(COALESCE(x.fatal_source_code,'')) " +
            "              AND (instr(lower(COALESCE(u.name,'')),lower(?2))>0 " +
            "                OR instr(lower(COALESCE(u.title,'')),lower(?2))>0))) " +
            "AND (?3='' OR lower(COALESCE(x.victim_code,''))=lower(?3)) ";
        return (where, new object?[] { term, victimCode });
    }

    private static (string Where, object?[] Args) EventWhere(
        string query,
        string victimCodeFilter,
        bool victimIllusionFilter,
        string sourceCodeFilter,
        bool sourceIllusionFilter)
    {
        string term = (query ?? "").Trim();
        string victimCode = (victimCodeFilter ?? "").Trim();
        string sourceCode = (sourceCodeFilter ?? "").Trim();
        string where =
            "WHERE session_id=?1 " +
            "AND (?2='' OR instr(lower(COALESCE(victim_name,'')),lower(?2))>0 " +
            " OR instr(lower(COALESCE(victim_code,'')),lower(?2))>0 " +
            " OR instr(lower(COALESCE(source_name,'')),lower(?2))>0 " +
            " OR instr(lower(COALESCE(source_code,'')),lower(?2))>0 " +
            " OR instr(lower(printf('0x%08X',victim)),lower(?2))>0 " +
            " OR instr(lower(printf('0x%08X',source)),lower(?2))>0) " +
            "AND (?3='' OR (lower(COALESCE(victim_code,''))=lower(?3) " +
            "AND (CASE WHEN (unit_flags & 2)<>0 THEN 1 ELSE 0 END)=?4)) " +
            "AND (?5='' OR (lower(COALESCE(source_code,''))=lower(?5) " +
            "AND (CASE WHEN (unit_flags & 4)<>0 THEN 1 ELSE 0 END)=?6)) ";
        return (where, new object?[]
        {
            term,
            victimCode,
            victimIllusionFilter ? 1 : 0,
            sourceCode,
            sourceIllusionFilter ? 1 : 0,
        });
    }

    private static void ResolveEventNames(
        SqliteConnection conn,
        string sessionId,
        List<DamageEventRow> events)
    {
        if (events.Count == 0) return;
        var snapshot = new SettlementSnapshot();
        ReadUnits(conn, snapshot, sessionId);
        snapshot.Events.AddRange(events);
        ResolveIdentities(snapshot);
    }

    private static DamageEventRow ReadDamageEvent(SqliteRow row)
    {
        long wall = row.GetInt64(1);
        uint mask = (uint)row.GetInt64(18);
        long flag = row.GetInt64(20);
        uint finalFlags = (uint)row.GetInt64(22);
        double engine = row.GetDouble(11);
        double final = row.GetDouble(12);
        double actual = row.GetDouble(13);
        bool hpValid = row.GetBool(16);
        bool engineValid = engine > 0.005 && hpValid;
        bool finalValid = (finalFlags & 1u) != 0;
        double effective = finalValid ? final : actual;
        bool effectiveValid = finalValid || hpValid;
        uint unitFlags = (uint)row.GetInt64(23);
        return new DamageEventRow
        {
            Seq = row.GetInt64(0),
            WallMs = wall,
            Time = wall > 0
                ? FromUnixMs(wall).ToString("HH:mm:ss.fff", CultureInfo.InvariantCulture)
                : "—",
            Victim = (uint)row.GetInt64(2),
            VictimCode = row.GetString(3),
            VictimName = Wc3Text.Clean(row.GetString(4)),
            VictimOwner = row.GetInt32(5),
            Source = (uint)row.GetInt64(6),
            SourceCode = row.GetString(7),
            SourceName = Wc3Text.Clean(row.GetString(8)),
            SourceOwner = row.GetInt32(9),
            Amount = row.GetDouble(10),
            Engine = engine,
            Final = final,
            Actual = actual,
            EngineValid = engineValid,
            FinalFlags = finalFlags,
            FinalValid = finalValid,
            Effective = effective,
            EffectiveValid = effectiveValid,
            Rate = engineValid && finalValid ? effective / engine : 0,
            HpBefore = row.GetDouble(14),
            HpAfter = row.GetDouble(15),
            HpValid = hpValid,
            AttackType = row.GetInt32(17),
            DamageMask = mask,
            DamageType = mask == 0 ? -1 : 31 - BitOperations.LeadingZeroCount(mask),
            IsPhysical = row.GetBool(19),
            IsAttack = (flag & 0x100) != 0,
            IsRanged = (flag & 1) != 0,
            Depth = row.GetInt32(21),
            UnitFlags = unitFlags,
            VictimIllusion = (unitFlags & FlagVictimIllusion) != 0,
            SourceIllusion = (unitFlags & FlagSourceIllusion) != 0,
            VictimHero = (unitFlags & (1u << 3)) != 0,
            SourceHero = (unitFlags & (1u << 4)) != 0,
        };
    }

    private static void ResolveIdentities(SettlementSnapshot snapshot)
    {
        var byAddr = snapshot.Units
            .GroupBy(u => u.Addr)
            .ToDictionary(g => g.Key, g => g.First());
        var byIdentity = snapshot.Units
            .GroupBy(u => IdentityKey(u.TypeCode, u.Illusion), StringComparer.OrdinalIgnoreCase)
            .ToDictionary(g => g.Key, g => g.First(), StringComparer.OrdinalIgnoreCase);
        var byType = snapshot.Units
            .GroupBy(u => (u.TypeCode ?? "").Trim(), StringComparer.OrdinalIgnoreCase)
            .ToDictionary(g => g.Key, g => g.First(), StringComparer.OrdinalIgnoreCase);

        bool TryIdentity(string code, bool illusion, out UnitRow unit) =>
            byIdentity.TryGetValue(IdentityKey(code, illusion), out unit!);

        /* 事件里的 unit_flags 是伤害发生当时的镜像状态，必须保留为分组依据。
           若该类型缺少对应镜像状态的单位资料，只借用同类型名称显示；
           不修改事件镜像位，以免后续快照把本体/镜像重新归类。 */
        bool TryEventIdentity(string code, bool illusion, out UnitRow unit) =>
            TryIdentity(code, illusion, out unit) || TryIdentity(code, false, out unit) ||
            TryIdentity(code, true, out unit) ||
            byType.TryGetValue((code ?? "").Trim(), out unit!);

        bool TrySettlementIdentityByAddress(
            uint addr,
            string code,
            out UnitRow unit,
            out bool illusion)
        {
            if (byAddr.TryGetValue(addr, out UnitRow? atAddr) &&
                string.Equals(atAddr.TypeCode, code, StringComparison.OrdinalIgnoreCase))
            {
                unit = atAddr;
                illusion = atAddr.Illusion;
                return true;
            }

            if (TryIdentity(code, true, out unit))
            {
                illusion = true;
                return true;
            }
            illusion = false;
            return byType.TryGetValue((code ?? "").Trim(), out unit!);
        }

        static string Label(UnitRow unit, string code, bool illusion)
        {
            string text = Wc3Text.UnitIdentity(unit.Name, unit.Title, code);
            if (!illusion) return text;
            return text.Contains("（镜像）", StringComparison.Ordinal) ||
                   text.Contains("(镜像)", StringComparison.Ordinal)
                ? text
                : text + "（镜像）";
        }

        foreach (SettlementRow row in snapshot.Settlements)
        {
            if (TrySettlementIdentityByAddress(
                    row.Victim,
                    row.VictimCode,
                    out UnitRow victim,
                    out bool victimIllusion))
            {
                row.VictimName = Label(victim, row.VictimCode, victimIllusion);
                if (victim.OwnerSlot >= 0) row.VictimOwner = victim.OwnerSlot;
            }

            if (TrySettlementIdentityByAddress(
                    row.FatalSource,
                    row.FatalSourceCode,
                    out UnitRow source,
                    out bool sourceIllusion))
            {
                row.FatalSourceName = Label(source, row.FatalSourceCode, sourceIllusion);
            }
        }

        foreach (DamageEventRow row in snapshot.Events)
        {
            if (TryEventIdentity(row.VictimCode, row.VictimIllusion, out UnitRow victim))
            {
                row.VictimName = Label(victim, row.VictimCode, row.VictimIllusion);
                if (victim.OwnerSlot >= 0) row.VictimOwner = victim.OwnerSlot;
            }

            if (TryEventIdentity(row.SourceCode, row.SourceIllusion, out UnitRow source))
            {
                row.SourceName = Label(source, row.SourceCode, row.SourceIllusion);
                if (source.OwnerSlot >= 0) row.SourceOwner = source.OwnerSlot;
            }
        }
    }

    private static List<BreakdownRow> BuildBreakdown(List<DamageEventRow> events)
    {
        if (events.Count == 0) return new List<BreakdownRow>();
        double rawTotal = events.Sum(x => x.Amount);
        double netTotal = events.Sum(NetValue);
        double Percent(double net, double raw) =>
            netTotal > 0 ? net / netTotal * 100 : rawTotal > 0 ? raw / rawTotal * 100 : 0;

        var groups = new Dictionary<string, BreakdownRow>(StringComparer.Ordinal);
        foreach (DamageEventRow row in events
                     .OrderBy(x => x.WallMs)
                     .ThenBy(x => x.Seq))
        {
            string sourceIdentity = SourceIdentity(row);
            string source = SourceLabel(row);
            string damageType = row.DamageType >= 0
                ? row.DamageType.ToString(CultureInfo.InvariantCulture)
                : "0x" + row.DamageMask.ToString("X", CultureInfo.InvariantCulture);
            string key = string.Join(
                "\u0000",
                sourceIdentity,
                row.IsAttack ? "1" : "0",
                row.IsRanged ? "1" : "0",
                row.AttackType.ToString(CultureInfo.InvariantCulture),
                damageType);
            if (!groups.TryGetValue(key, out BreakdownRow? group))
            {
                group = new BreakdownRow
                {
                    Source = source,
                    IsAttack = row.IsAttack ? "1" : "0",
                    IsRanged = row.IsRanged ? "1" : "0",
                    AttackType = row.AttackType.ToString(CultureInfo.InvariantCulture),
                    DamageType = damageType,
                };
                groups[key] = group;
            }

            group.Count++;
            group.Raw += row.Amount;
            if (row.EngineValid)
            {
                group.Engine += row.Engine;
                group.EngineValid = true;
            }
            if (row.EffectiveValid)
            {
                group.Effective += row.Effective;
                group.EffectiveValid = true;
            }
            group.Net += NetValue(row);
            group.NetValid |= row.HpValid;
        }

        var visibleCombinations = groups.Values
            .OrderByDescending(x => x.Raw)
            .ToList();
        foreach (BreakdownRow row in visibleCombinations)
            row.Percent = Percent(row.Net, row.Raw);

        var sourceGroups = new Dictionary<string, BreakdownRow>(StringComparer.Ordinal);
        foreach ((string key, BreakdownRow group) in groups)
        {
            string sourceIdentity = key.Split('\u0000', 2)[0];
            if (!sourceGroups.TryGetValue(sourceIdentity, out BreakdownRow? target))
            {
                target = new BreakdownRow
                {
                    Source = "Σ " + group.Source,
                    IsAttack = "汇总",
                    Summary = true,
                };
                sourceGroups[sourceIdentity] = target;
            }
            target.Count += group.Count;
            target.Raw += group.Raw;
            target.Engine += group.Engine;
            target.EngineValid |= group.EngineValid;
            target.Effective += group.Effective;
            target.EffectiveValid |= group.EffectiveValid;
            target.Net += group.Net;
            target.NetValid |= group.NetValid;
        }

        var summaries = sourceGroups.Values
            .OrderByDescending(x => x.Raw)
            .ToList();
        foreach (BreakdownRow row in summaries)
            row.Percent = Percent(row.Net, row.Raw);

        var result = new List<BreakdownRow>(summaries.Count + visibleCombinations.Count);
        result.AddRange(summaries);
        result.AddRange(visibleCombinations);
        return result;
    }

    private static double NetValue(DamageEventRow row) =>
        row.HpValid ? row.Actual : row.Amount;

    private static string SourceIdentity(DamageEventRow row) =>
        (row.SourceCode ?? "").Trim().ToUpperInvariant() +
        (row.SourceIllusion ? "\u0001M" : "\u0001N");

    private static string SourceLabel(DamageEventRow row)
    {
        string label = row.SourceName.Length > 0
            ? row.SourceName
            : row.SourceCode.Length > 0
                ? row.SourceCode
                : row.Source.ToString(CultureInfo.InvariantCulture);
        if (row.SourceIllusion && !label.Contains("镜像", StringComparison.Ordinal))
            label += "（镜像）";
        return label;
    }

    private static string IdentityKey(string code, bool illusion) =>
        (code ?? "").Trim().ToUpperInvariant() + (illusion ? "\u0001M" : "\u0001N");

    private static DateTime FromUnixMs(long milliseconds)
    {
        try { return Epoch.AddMilliseconds(milliseconds).ToLocalTime(); }
        catch { return DateTime.Now; }
    }
}
