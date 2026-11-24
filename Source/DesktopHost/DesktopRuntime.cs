using System.Diagnostics;
using System.Reflection;
using DdhWebHost;
using War3DeathSettlement.Core;

namespace War3DeathSettlement.Desktop;

internal sealed class DesktopRuntime : IDisposable
{
    private readonly MonitorEngine _engine = new();
    private readonly Settings _settings = Settings.Load();
    private readonly WebHostAutostart _webHostAutostart;

    public DesktopRuntime()
    {
        _webHostAutostart = new WebHostAutostart(_settings);
        _engine.IntervalMs = _settings.IntervalMs;
        _engine.ReadPluginLog = _settings.ReadPluginLog;
        _engine.PluginLogPath = _settings.PluginLogPath;
        _engine.HookEnabled = _settings.HookEnabled;
        _engine.HookSharedMemory = false;
        _engine.HookDllPath = _settings.HookDll;
        _engine.HookInjectorPath = _settings.HookInjector;
        _engine.AutoAttach = _settings.AutoAttach;
        _engine.AttachOptions = _settings.ToAttach();
        _engine.IgnoreUnitNames = _settings.IgnoreUnitNames;
        DamageTypeNames.Override(_settings.AttackTypeLabels, _settings.DamageTypeLabels);
        _engine.Start();
    }

    public bool AutoAttach
    {
        get => _engine.AutoAttach;
        set => _engine.AutoAttach = value;
    }

    public (bool Ok, string Message) AttachGame()
    {
        bool ok = _engine.Attach(out string message);
        return (ok, message);
    }

    public SettlementSnapshot BuildLiveSnapshot()
    {
        Snapshot current = _engine.Current;
        Wc3Game? game = _engine.Game;
        int pid = game?.Mem.Pid ?? current.Pid;
        string sessionId = game?.SessionId ?? "";

        if (pid > 0)
            _webHostAutostart.Ensure(pid, sessionId);

        SettlementSnapshot snapshot = SnapshotReader.Read(
            DdhEventDb.FixedPath,
            pid,
            sessionId);
        snapshot.Pid = pid;
        if (sessionId.Length > 0) snapshot.SessionId = sessionId;
        snapshot.Desktop = BuildDesktopState(game, current, "live");
        return snapshot;
    }

    public SettlementSnapshot BuildHistorySnapshot(string sessionId)
    {
        SettlementSnapshot snapshot = SnapshotReader.Read(
            DdhEventDb.FixedPath,
            0,
            sessionId);
        snapshot.Desktop = BuildDesktopState(null, _engine.Current, "history");
        snapshot.Desktop.SourceLabel = "历史会话 · " + sessionId;
        snapshot.Desktop.Status = snapshot.MapName.Length > 0
            ? "正在查看历史：" + snapshot.MapName
            : "正在查看历史会话";
        return snapshot;
    }

    public List<HistoryFileInfo> ListHistory() =>
        DdhHistoryReader.List(DdhEventDb.FixedPath);

    private DesktopState BuildDesktopState(
        Wc3Game? game,
        Snapshot current,
        string mode)
    {
        string selfIntegrity = "";
        string gameIntegrity = "";
        try { selfIntegrity = Integrity.Name(Integrity.Self); } catch { }
        if (game != null)
        {
            try { gameIntegrity = Integrity.Name(Integrity.OfProcess(game.Mem.Pid, out _)); }
            catch { gameIntegrity = "未知"; }
        }

        return new DesktopState
        {
            Mode = mode,
            AppVersion = Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? "2.0.0",
            BuildTime = BuildTime(),
            Connected = game != null,
            Ready = current.Ready,
            AutoAttach = _engine.AutoAttach,
            Pid = game?.Mem.Pid ?? 0,
            SessionId = game?.SessionId ?? "",
            GameVersion = game?.Version.Version ?? "",
            Status = current.Status.Length > 0 ? current.Status : "等待魔兽进程",
            HookStatus = _engine.HookStatus,
            HookAttached = _engine.HookAttached,
            SelfIntegrity = selfIntegrity,
            GameIntegrity = gameIntegrity,
            ScanCount = _engine.ScanCount,
            DatabasePath = DdhEventDb.FixedPath,
            SourceLabel = "ddh SQLite 实时数据",
        };
    }

    private static string BuildTime()
    {
        try
        {
            string path = Environment.ProcessPath ?? "";
            if (path.Length == 0) return "";
            return File.GetLastWriteTime(path).ToString("yyyy-MM-dd HH:mm:ss");
        }
        catch
        {
            return "";
        }
    }

    public void Dispose()
    {
        _engine.Dispose();
        _webHostAutostart.Dispose();
    }
}
