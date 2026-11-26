using System.Diagnostics;
using System.Reflection;
using DdhWebHost;
using War3DeathSettlement.Core;

namespace War3DeathSettlement.Desktop;

/// <summary>
/// Desktop data source is SQLite only. It never opens the game process,
/// requests CUnit attributes, injects code, or creates shared memory.
/// </summary>
internal sealed class DesktopRuntime : IDisposable
{
    private readonly Settings _settings = Settings.Load();
    private bool _autoAttach = true;

    public DesktopRuntime()
    {
        DamageTypeNames.Override(_settings.AttackTypeLabels, _settings.DamageTypeLabels);
    }

    public bool AutoAttach
    {
        get => _autoAttach;
        set => _autoAttach = value;
    }

    public (bool Ok, string Message) AttachGame()
    {
        if (!File.Exists(DdhEventDb.FixedPath))
            return (false, "尚未找到 WFE 写入的 SQLite 数据库");
        SettlementSnapshot snapshot = SnapshotReader.Read(DdhEventDb.FixedPath, 0, "");
        return snapshot.SessionId.Length > 0
            ? (true, "已连接 WFE SQLite 数据")
            : (false, "SQLite 中还没有可用会话");
    }

    public SettlementSnapshot BuildLiveSnapshot()
    {
        int pid = FindGamePid();
        SettlementSnapshot snapshot = SnapshotReader.Read(DdhEventDb.FixedPath, pid, "");
        snapshot.Pid = pid;
        snapshot.Desktop = BuildDesktopState(snapshot, pid, "live");
        return snapshot;
    }

    public SettlementSnapshot BuildHistorySnapshot(string sessionId)
    {
        SettlementSnapshot snapshot = SnapshotReader.Read(
            DdhEventDb.FixedPath,
            0,
            sessionId);
        snapshot.Desktop = BuildDesktopState(snapshot, 0, "history");
        snapshot.Desktop.SourceLabel = "历史会话 · " + sessionId;
        snapshot.Desktop.Status = snapshot.MapName.Length > 0
            ? "正在查看历史：" + snapshot.MapName
            : "正在查看历史会话";
        return snapshot;
    }

    public List<HistoryFileInfo> ListHistory() =>
        DdhHistoryReader.List(DdhEventDb.FixedPath);

    private static DesktopState BuildDesktopState(
        SettlementSnapshot snapshot,
        int pid,
        string mode)
    {
        bool hasSession = snapshot.SessionId.Length > 0;
        return new DesktopState
        {
            Mode = mode,
            AppVersion = Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? "2.0.0",
            BuildTime = BuildTime(),
            Connected = hasSession,
            Ready = hasSession,
            AutoAttach = true,
            Pid = pid,
            SessionId = snapshot.SessionId,
            Status = hasSession
                ? "WFE SQLite 已连接"
                : File.Exists(DdhEventDb.FixedPath)
                    ? "等待 WFE 写入当前对局"
                    : "等待 WFE 生成 SQLite",
            HookStatus = hasSession ? "WFE 采集数据" : "等待 WFE",
            HookAttached = hasSession,
            SelfIntegrity = "",
            GameIntegrity = "",
            ScanCount = 0,
            DatabasePath = DdhEventDb.FixedPath,
            SourceLabel = "WFE SQLite 数据",
        };
    }

    private static int FindGamePid()
    {
        try
        {
            return Process.GetProcessesByName("War3")
                .Select(x => x.Id)
                .FirstOrDefault();
        }
        catch
        {
            return 0;
        }
    }

    private static string BuildTime()
    {
        try
        {
            string path = Environment.ProcessPath ?? "";
            return path.Length > 0
                ? File.GetLastWriteTime(path).ToString("yyyy-MM-dd HH:mm:ss")
                : "";
        }
        catch
        {
            return "";
        }
    }

    public void Dispose()
    {
    }
}
