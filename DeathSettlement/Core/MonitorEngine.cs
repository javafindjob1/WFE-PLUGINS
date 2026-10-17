using System.Diagnostics;
using System.Globalization;
using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>界面用的单位行（不可变快照）。</summary>
public sealed class UnitView
{
    public uint Addr { get; init; }
    public string TypeCode { get; init; } = "";
    /// <summary>单位名（来自插件日志的类型码→名字表；没有就是空）。</summary>
    public string Name { get; init; } = "";
    public string Owner { get; init; } = "?";
    public float Hp { get; init; }
    public float HpMax { get; init; }
    public float HpPercent { get; init; }
    public double Taken { get; init; }
    public int Hits { get; init; }
    public double Dps { get; init; }
    public string State { get; init; } = "";
    public float X { get; init; }
    public float Y { get; init; }
    public string Found { get; init; } = "";
}

/// <summary>一次扫描后的完整快照（引擎线程生产、界面线程消费，避免并发访问内部字典）。</summary>
public sealed class Snapshot
{
    public DateTime At { get; init; }
    public IReadOnlyList<UnitView> Units { get; init; } = Array.Empty<UnitView>();
    public IReadOnlyList<Settlement> Settlements { get; init; } = Array.Empty<Settlement>();
    public ScanStats Stats { get; init; } = new();
    public string Status { get; init; } = "";
    public bool Ready { get; init; }
}

/// <summary>
/// 后台监视引擎：一个线程循环“扫描 → 记账 → 出快照”，界面只读快照。
/// </summary>
public sealed class MonitorEngine : IDisposable
{
    private Thread? _thread;
    private volatile bool _stop;
    private readonly object _gate = new();
    private long _mapGeneration;
    private uint _lastGameMemory;
    private int _lastSettlementCount = -1;
    private IReadOnlyList<Settlement> _settlementSnapshot = Array.Empty<Settlement>();

    public Wc3Game? Game { get; private set; }
    public UnitScanner? Scanner { get; private set; }
    public DamageTracker Tracker { get; private set; } = new();
    public Snapshot Current { get; private set; } = new();
    public bool Running => _thread is { IsAlive: true };

    /// <summary>自动连接：后台每秒找一次 war3 进程，找到就自动挂上（不用点按钮）。</summary>
    public bool AutoAttach { get; set; } = true;
    /// <summary>连接参数（指定 PID / 额外进程名 / 强制版本）。</summary>
    public AttachOptions AttachOptions { get; set; } = new();
    public TimeSpan AutoAttachInterval { get; set; } = TimeSpan.FromSeconds(1.5);
    private DateTime _lastAutoAttach = DateTime.MinValue;
    private DateTime _lastAliveCheck = DateTime.MinValue;

    /// <summary>轮询间隔（毫秒）。越小越精确，代价是 CPU。</summary>
    public int IntervalMs { get; set; } = 50;
    /// <summary>深度扫描（发现新单位）的间隔；EnableDeepScan=false 时完全不跑。</summary>
    public TimeSpan DeepInterval { get; set; } = TimeSpan.FromSeconds(8);
    public bool EnableDeepScan { get; set; } = true;
    /// <summary>发现单位的三条路径开关（排障/自测用；默认全开）。</summary>
    public bool EnableHandleTable { get; set; } = true;
    public bool EnableSelection { get; set; } = true;
    public string SettlementCsvPath { get; private set; } = "";

    /// <summary>按“维度 × 分组”展开的伤害构成表（一行一个分组，方便直接做透视）。</summary>
    public string BreakdownCsvPath { get; private set; } = "";
    public long ScanCount { get; private set; }

    // ---- 可选的“游戏内插件日志”增强：补上伤害来源/攻击类型 ----
    /// <summary>是否读游戏内插件日志（插件在跑时才有意义）。</summary>
    public bool ReadPluginLog { get; set; } = true;
    /// <summary>插件日志路径（默认 WFE 的 Libraries 目录）。</summary>
    public string PluginLogPath { get; set; } =
        @"C:\3rd\wc3gamesearcher\WFE\Application\Libraries\UDamageWatcher.log";
    public PluginLogReader? PluginLog { get; private set; }
    /// <summary>已经出了结算、但还没从插件日志里补到来源的那些（等日志写出来再补）。</summary>
    private readonly List<Settlement> _awaitingAttribution = new();
    private DateTime _lastPluginPoll = DateTime.MinValue;
    private readonly List<string> _csvHistory = new();
    private bool _csvHistoryLoaded;
    private bool _csvDirty;
    private DateTime _lastCsvFlush = DateTime.MinValue;

    /// <summary>插件日志里累计解析出的结算条数（诊断用）。</summary>
    public int PluginSettlementsSeen => PluginLog?.ParsedTotal ?? 0;
    /// <summary>通过插件日志补上来源的外部结算条数。</summary>
    public int AttributedCount { get; private set; }

    public event Action? Changed;

    public MonitorEngine()
    {
        SettlementCsvPath = Path.Combine(AppContext.BaseDirectory, "logs", "settlements.csv");
        BreakdownCsvPath = Path.Combine(AppContext.BaseDirectory, "logs", "damage-breakdown.csv");
    }

    // ------------------------------------------------------------------
    /// <summary>手动连接一次（界面上【查找游戏】按钮）。</summary>
    public bool Attach(out string message)
    {
        Stop();
        bool ok = TryAttachOnce(out message);
        Start();
        return ok;
    }

    /// <summary>连接一次，不启停线程（供后台自动连接复用）。</summary>
    private bool TryAttachOnce(out string message)
    {
        var g = Wc3Game.Attach(AttachOptions);
        message = g.Message;
        if (!g.IsReady)
        {
            g.Dispose();
            lock (_gate)
            {
                if (Game == null) Current = new Snapshot { At = DateTime.Now, Status = message, Ready = false };
            }
            Changed?.Invoke();
            return false;
        }

        lock (_gate)
        {
            var history = Tracker.Settlements.ToArray();   // 换局不清历史（整场会话的结算都留着）
            Game?.Dispose();
            Game = g;
            Scanner = new UnitScanner(g)
            {
                DeepInterval = DeepInterval,
                EnableDeepScan = EnableDeepScan,
                EnableHandleTable = EnableHandleTable,
                EnableSelection = EnableSelection
            };
            Tracker = new DamageTracker(Scanner);
            if (history.Length > 0) Tracker.SeedHistory(history);
            Tracker.Settled += OnSettled;
            _lastGameMemory = 0;
            _lastSettlementCount = -1;
            _settlementSnapshot = Array.Empty<Settlement>();
            Current = new Snapshot { At = DateTime.Now, Status = "已连接，等待进入地图…", Ready = false };
        }
        Log.Write("连接成功：" + message);
        Changed?.Invoke();
        return true;
    }

    public void Start()
    {
        if (Running) return;
        _stop = false;
        _thread = new Thread(Loop) { IsBackground = true, Name = "dss-monitor" };
        _thread.Start();
    }

    public void Stop()
    {
        _stop = true;
        var t = _thread;
        if (t is { IsAlive: true }) t.Join(1500);
        _thread = null;
    }

    /// <summary>暂停/继续（暂停时不扫描，但仍保留已记录的账）。</summary>
    public bool Paused { get; set; }

    public void ClearAll()
    {
        lock (_gate)
        {
            Tracker.Clear();
            Scanner?.Reset();
            _lastSettlementCount = -1;
            _settlementSnapshot = Array.Empty<Settlement>();
        }
    }

    public void RequestDeepScan() => _deepRequested = true;
    private volatile bool _deepRequested;

    // ------------------------------------------------------------------
    private void Loop()
    {
        var sw = new Stopwatch();
        while (!_stop)
        {
            try
            {
                Wc3Game? g;
                UnitScanner? sc;
                lock (_gate) { g = Game; sc = Scanner; }

                if (g == null || sc == null)
                {
                    // 没连上 → 自动找游戏（默认开启，每 1.5 秒试一次）
                    if (AutoAttach && DateTime.UtcNow - _lastAutoAttach >= AutoAttachInterval)
                    {
                        _lastAutoAttach = DateTime.UtcNow;
                        if (TryAttachOnce(out string msg)) Log.Write("自动连接成功：" + msg);
                        lock (_gate) { g = Game; sc = Scanner; }
                    }
                    else if (!AutoAttach)
                    {
                        lock (_gate)
                        {
                            Current = new Snapshot { At = DateTime.Now, Status = "未连接（自动连接已关闭，点【查找游戏】）", Ready = false };
                        }
                    }

                    if (g == null || sc == null)
                    {
                        PumpPluginLog();   // 没连上游戏也照读插件日志：名字表/来源先备好，诊断里也看得见
                        Thread.Sleep(300);
                        continue;
                    }
                }

                if (Paused)
                {
                    Thread.Sleep(120);
                    continue;
                }

                // 进程是否还活着：每秒查一次就够；进程没了就直接断开，
                // 绝不在“读不到内存”的情况下生成结算（否则退游戏会刷一堆假的“消失”）。
                if (DateTime.UtcNow - _lastAliveCheck > TimeSpan.FromSeconds(1))
                {
                    _lastAliveCheck = DateTime.UtcNow;
                    if (!IsProcessAlive(g))
                    {
                        HandleGameGone("游戏进程已退出（这一局不产生结算）");
                        Thread.Sleep(400);
                        continue;
                    }
                }

                // 每次扫描前重读三个全局（换图/重开局后地址内容会变）
                g.Refresh();

                if (g.IsReady && g.GameMemory != _lastGameMemory)
                {
                    if (_lastGameMemory != 0)
                    {
                        _mapGeneration++;
                        Log.Write($"检测到地图重载/重开局（gameMemory 0x{_lastGameMemory:X8} → 0x{g.GameMemory:X8}），账本清零");
                        lock (_gate) { Tracker.Clear(); sc.Reset(); _lastSettlementCount = -1; _settlementSnapshot = Array.Empty<Settlement>(); }
                    }
                    _lastGameMemory = g.GameMemory;
                }

                sw.Restart();
                bool deep = _deepRequested;
                _deepRequested = false;
                sc.DeepInterval = DeepInterval;
                sc.EnableDeepScan = EnableDeepScan;
                sc.EnableHandleTable = EnableHandleTable;
                sc.EnableSelection = EnableSelection;
                var stats = sc.Scan(deep);
                Tracker.Update(sc.Known, DateTime.Now);
                sw.Stop();
                ScanCount++;
                stats.ElapsedMs = sw.ElapsedMilliseconds;

                PumpPluginLog();
                FlushCsv(force: false);   // 有变化就（最多每秒一次）把 CSV 重写成最新状态

                Publish(g, sc, stats);
            }
            catch (Exception ex)
            {
                Log.Error("监视循环异常：" + ex);
                Thread.Sleep(500);
            }

            int wait = Math.Clamp(IntervalMs, 10, 5000);
            int slept = 0;
            while (slept < wait && !_stop) { Thread.Sleep(5); slept += 5; }
        }
    }

    private static bool IsProcessAlive(Wc3Game g)
    {
        try { return !System.Diagnostics.Process.GetProcessById(g.Mem.Pid).HasExited; }
        catch { return false; }
    }

    private void HandleGameGone(string why)
    {
        lock (_gate)
        {
            if (Game == null) return;
            try { Game.Dispose(); } catch { }
            Game = null;
            Scanner = null;
            Current = new Snapshot { At = DateTime.Now, Status = why, Ready = false };
        }
        Log.Warn(why);
        Changed?.Invoke();
    }

    private void Publish(Wc3Game g, UnitScanner sc, ScanStats stats)
    {
        var units = new List<UnitView>(sc.Known.Count);
        foreach (var u in sc.Known.Values)
        {
            var t = Tracker.GetTrack(u.Addr);
            double dps = 0;
            if (t is { FirstHit: not null, LastHit: not null })
            {
                double sec = Math.Max(0.5, (DateTime.Now - t.FirstHit.Value).TotalSeconds);
                dps = t.TotalDamage / sec;
            }
            units.Add(new UnitView
            {
                Addr = u.Addr,
                TypeCode = u.TypeCode,
                Name = PluginLog?.NameOf(u.TypeCode) ?? "",
                Owner = u.OwnerSlot >= 0 ? "P" + (u.OwnerSlot + 1) : "?",
                Hp = u.Hp,
                HpMax = u.HpMax,
                HpPercent = u.HpPercent,
                Taken = t?.TotalDamage ?? 0,
                Hits = t?.Events.Count ?? 0,
                Dps = dps,
                State = u.Hp <= 0 ? "死亡" : "存活",
                X = u.X,
                Y = u.Y,
                Found = u.FoundBy,
            });
        }
        units.Sort((a, b) => b.Taken.CompareTo(a.Taken));

        lock (_gate)
        {
            if (Tracker.Settlements.Count != _lastSettlementCount)
            {
                _lastSettlementCount = Tracker.Settlements.Count;
                _settlementSnapshot = Tracker.Settlements.ToArray();
            }
            Current = new Snapshot
            {
                At = DateTime.Now,
                Units = units,
                Settlements = _settlementSnapshot,
                Stats = stats,
                Ready = true,
                Status = units.Count == 0
                    ? g.Message + "　（还没发现单位：确认已经进入地图；若一直为 0，请点【生成诊断报告】把报告发我）"
                    : g.Message,
            };
        }
        Changed?.Invoke();
    }

    private void OnSettled(Settlement s)
    {
        // 名字来自插件日志的「类型码 → 名字」表（插件没跑 / 没这个单位时是空）
        s.UnitName = PluginLog?.NameOf(s.TypeCode) ?? "";
        Log.Write("死亡结算：" + s.TitleLine().Trim());

        // 先挂到“等来源”队列：插件日志通常是同一瞬间写出来的，稍后补上
        if (ReadPluginLog) _awaitingAttribution.Add(s);

        // 立刻落一次盘（防崩）；等来源补上之后再整体重写一遍，把那一列填进同一行
        _csvDirty = true;
        FlushCsv(force: true);
    }

    /// <summary>
    /// 写 settlements.csv。策略：把“这次启动之前文件里已有的行”读进内存当历史，
    /// 每次重写 = 表头 + 历史 + 本次会话的全部结算。
    /// 这样既保住历史（换局/重启不丢），又能在“来源”补上来之后把同一行补全。
    /// </summary>
    private void FlushCsv(bool force)
    {
        if (!_csvDirty) return;
        if (!force && DateTime.UtcNow - _lastCsvFlush < TimeSpan.FromSeconds(1)) return;
        _lastCsvFlush = DateTime.UtcNow;
        _csvDirty = false;

        try
        {
            string dir = Path.GetDirectoryName(SettlementCsvPath)!;
            Directory.CreateDirectory(dir);

            if (!_csvHistoryLoaded)
            {
                _csvHistoryLoaded = true;
                try
                {
                    if (File.Exists(SettlementCsvPath))
                    {
                        foreach (var line in File.ReadLines(SettlementCsvPath, Encoding.UTF8).Skip(1))
                        {
                            if (line.Length == 0) continue;
                            _csvHistory.Add(line);
                            if (_csvHistory.Count >= 20000) break;   // 历史最多留 2 万行
                        }
                    }
                }
                catch { }
            }

            var sb = new StringBuilder();
            sb.AppendLine(Settlement.CsvHeader);
            foreach (var h in _csvHistory) sb.AppendLine(h);
            foreach (var s in Tracker.Settlements) sb.AppendLine(s.ToCsvRow());
            File.WriteAllText(SettlementCsvPath, sb.ToString(), new UTF8Encoding(true));

            // 伤害构成：一行 = 一条结算里的一个分组（维度/分组/笔数/伤害/占比）
            var list = Tracker.Settlements;
            var bb = new StringBuilder();
            bb.AppendLine("来源,时间,单位名,类型码,结局,维度,分组,笔数,原始伤害,结算后伤害,占比%");

            // ① 本软件自己统计（不需要插件）：整场汇总
            foreach (var r in SelfBreakdown.Build(list))
            {
                bb.AppendLine(string.Join(",",
                    "自己", "—", "（全部结算）", "", "", r.Dimension, r.Key.Replace(',', '，'),
                    r.Count.ToString(CultureInfo.InvariantCulture),
                    r.Damage.ToString("0.##", CultureInfo.InvariantCulture),
                    r.Damage.ToString("0.##", CultureInfo.InvariantCulture),
                    r.Percent.ToString("0.#", CultureInfo.InvariantCulture)));
            }

            // ② 每条结算内部的自统计（档位 / 受击秒）
            foreach (var s in list)
            {
                foreach (var r in SelfBreakdown.ForSettlement(s))
                {
                    bb.AppendLine(string.Join(",",
                        "自己", s.DiedAt.ToString("yyyy-MM-dd HH:mm:ss.fff", CultureInfo.InvariantCulture),
                        s.UnitName.Replace(',', '，'), s.TypeCode, s.Kind,
                        r.Dimension, r.Key.Replace(',', '，'),
                        r.Count.ToString(CultureInfo.InvariantCulture),
                        r.Damage.ToString("0.##", CultureInfo.InvariantCulture),
                        r.Damage.ToString("0.##", CultureInfo.InvariantCulture),
                        r.Percent.ToString("0.#", CultureInfo.InvariantCulture)));
                }
            }

            // ③ 附：插件日志口径（只有插件在跑、且写了"联合统计"才有）
            foreach (var s in list)
            {
                if (s.Attribution == null) continue;
                foreach (var g in s.Attribution.Groups)
                {
                    bb.AppendLine(string.Join(",",
                        "插件", s.DiedAt.ToString("yyyy-MM-dd HH:mm:ss.fff", CultureInfo.InvariantCulture),
                        s.UnitName.Replace(',', '，'), s.TypeCode, s.Kind,
                        g.Dimension, g.Key.Replace(',', '，'),
                        g.Count.ToString(CultureInfo.InvariantCulture),
                        g.Damage.ToString("0.##", CultureInfo.InvariantCulture),
                        g.DamageAfter.ToString("0.##", CultureInfo.InvariantCulture),
                        g.Percent.ToString("0.#", CultureInfo.InvariantCulture)));
                }
            }
            File.WriteAllText(BreakdownCsvPath, bb.ToString(), new UTF8Encoding(true));
        }
        catch (Exception ex) { Log.Warn("写 settlements.csv 失败：" + ex.Message); }
    }

    /// <summary>
    /// 每秒读一次游戏内插件日志，把新解析出来的结算“认领”给对应的外部结算
    /// （按类型码 + 时间就近匹配）。这样纯外部模式也能显示“谁打的、什么攻击类型”。
    /// </summary>
    private void PumpPluginLog()
    {
        if (!ReadPluginLog) return;
        if (DateTime.UtcNow - _lastPluginPoll < TimeSpan.FromSeconds(1)) return;
        _lastPluginPoll = DateTime.UtcNow;

        PluginLog ??= new PluginLogReader(PluginLogPath, fromStart: true);
        PluginLog.Poll();

        // 名字可能比结算晚一步才知道（日志后写出来）→ 回头把还没名字的补上
        if (PluginLog.CodeToName.Count > 0)
        {
            foreach (var s in Tracker.Settlements)
                if (s.UnitName.Length == 0) s.UnitName = PluginLog.NameOf(s.TypeCode);
        }

        if (_awaitingAttribution.Count == 0) return;

        var window = TimeSpan.FromSeconds(20);
        for (int i = _awaitingAttribution.Count - 1; i >= 0; i--)
        {
            var s = _awaitingAttribution[i];
            var m = PluginLog.Match(s.TypeCode, s.DiedAt, window);
            if (m != null)
            {
                s.Attribution = PluginAttribution.From(m);
                AttributedCount++;
                _awaitingAttribution.RemoveAt(i);
                _csvDirty = true;          // 来源补上了 → 稍后把 CSV 里那一行也补全
                FlushCsv(force: false);
                Log.Write($"结算补上来源：{s.TypeCode} ← 插件 {m.Name}({m.Code}) 来源 {m.Sources.Count} 个");
            }
            else if (DateTime.Now - s.DiedAt > TimeSpan.FromSeconds(60))
            {
                _awaitingAttribution.RemoveAt(i);   // 等太久了，放弃
            }
        }
    }

    public void Dispose() => Stop();
}





