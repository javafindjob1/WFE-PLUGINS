using System.Diagnostics;
using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>界面用的单位行（不可变快照）。</summary>
public sealed class UnitView
{
    public uint Addr { get; init; }
    public string TypeCode { get; init; } = "";
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
    public TimeSpan AutoAttachInterval { get; set; } = TimeSpan.FromSeconds(1.5);
    private DateTime _lastAutoAttach = DateTime.MinValue;

    /// <summary>轮询间隔（毫秒）。越小越精确，代价是 CPU。</summary>
    public int IntervalMs { get; set; } = 50;
    public string SettlementCsvPath { get; private set; } = "";
    public long ScanCount { get; private set; }

    public event Action? Changed;

    public MonitorEngine()
    {
        SettlementCsvPath = Path.Combine(AppContext.BaseDirectory, "logs", "settlements.csv");
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
        var g = Wc3Game.Attach();
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
            Game?.Dispose();
            Game = g;
            Scanner = new UnitScanner(g);
            Tracker = new DamageTracker(Scanner);
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

                    if (g == null || sc == null) { Thread.Sleep(300); continue; }
                }

                if (Paused)
                {
                    Thread.Sleep(120);
                    continue;
                }

                if (!IsProcessAlive(g))
                {
                    HandleGameGone("游戏进程已退出");
                    Thread.Sleep(500);
                    continue;
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
                var stats = sc.Scan(deep);
                Tracker.Update(sc.Known, DateTime.Now);
                sw.Stop();
                ScanCount++;
                stats.ElapsedMs = sw.ElapsedMilliseconds;

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
                Status = g.Message,
            };
        }
        Changed?.Invoke();
    }

    private void OnSettled(Settlement s)
    {
        Log.Write("死亡结算：" + s.TitleLine().Trim());
        try
        {
            string dir = Path.GetDirectoryName(SettlementCsvPath)!;
            Directory.CreateDirectory(dir);
            if (!File.Exists(SettlementCsvPath))
                File.WriteAllText(SettlementCsvPath, Settlement.CsvHeader + Environment.NewLine, new UTF8Encoding(true));
            File.AppendAllText(SettlementCsvPath, s.ToCsvRow() + Environment.NewLine, new UTF8Encoding(true));
        }
        catch (Exception ex) { Log.Warn("写 settlements.csv 失败：" + ex.Message); }
    }

    public void Dispose() => Stop();
}
