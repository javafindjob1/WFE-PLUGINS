using System.Diagnostics;
using System.IO.MemoryMappedFiles;

namespace War3DeathSettlement.Core;

/// <summary>
/// Starts ddh_web from the desktop C# process, outside the game process Job.
/// The game-side ddh only publishes the DdhHtml mapping; this helper makes the
/// Vue host operational even when the launcher cannot create it from War3.
/// </summary>
internal sealed class WebHostAutostart : IDisposable
{
    internal const uint PanelMagic = 0x31484844u;
    private const int PanelWidth = 1200;
    private const int PanelHeight = 760;
    private readonly Settings _settings;
    private Process? _process;
    private int _pid;
    private string _sessionId = "";
    private DateTime _pidSeenAt = DateTime.MinValue;
    private DateTime _lastAttemptAt = DateTime.MinValue;
    private string _lastError = "";

    public WebHostAutostart(Settings settings) => _settings = settings;

    public static bool HasRenderedFrame(int pid)
    {
        if (pid <= 0) return false;
        try
        {
            using var map = MemoryMappedFile.OpenExisting(
                $"Local\\DdhHtml_{pid}", MemoryMappedFileRights.Read);
            using var view = map.CreateViewAccessor(0, 16, MemoryMappedFileAccess.Read);
            uint magic = view.ReadUInt32(0);
            int width = view.ReadInt32(4);
            int height = view.ReadInt32(8);
            int seq = view.ReadInt32(12);
            return magic == PanelMagic && width == PanelWidth &&
                   height == PanelHeight && seq > 0;
        }
        catch
        {
            return false;
        }
    }

    public void Ensure(int pid, string? sessionId)
    {
        if (!_settings.WebHostAutoStart || pid <= 0) return;
        sessionId ??= "";

        if (_pid != pid || !string.Equals(_sessionId, sessionId, StringComparison.Ordinal))
        {
            Process? previous = _process;
            _pid = pid;
            _sessionId = sessionId;
            _pidSeenAt = DateTime.Now;
            _lastAttemptAt = DateTime.MinValue;
            _lastError = "";
            if (previous is { HasExited: false })
            {
                try { previous.Kill(entireProcessTree: true); } catch { }
            }
            previous?.Dispose();
            _process = null;
        }

        if (HasRenderedFrame(pid)) return;
        if (_process is { HasExited: false }) return;
        if (_process != null)
        {
            _process.Dispose();
            _process = null;
        }

        // Give ddh's own launcher a short head start. If it succeeds, C# does nothing.
        if ((DateTime.Now - _pidSeenAt).TotalSeconds < 2) return;
        if ((DateTime.Now - _lastAttemptAt).TotalSeconds < 3) return;
        _lastAttemptAt = DateTime.Now;

        string exe = ResolveExe();
        string html = ResolveHtml();
        if (!File.Exists(exe))
        {
            LogOnce($"WebHost 自动启动失败：找不到 {exe}");
            return;
        }
        if (!File.Exists(html))
        {
            LogOnce($"WebHost 自动启动失败：找不到 {html}");
            return;
        }

        try
        {
            string log = Path.Combine(
                @"C:\Users\Public\Documents\War3DeathSettlement", "ddh-web.txt");
            Directory.CreateDirectory(Path.GetDirectoryName(log)!);

            var psi = new ProcessStartInfo(exe)
            {
                UseShellExecute = true,
                WorkingDirectory = Path.GetDirectoryName(exe)!,
                WindowStyle = ProcessWindowStyle.Hidden,
                Arguments =
                    $"--pid {pid} --html {Quote(html)} --w {PanelWidth} --h {PanelHeight}" +
                    (sessionId.Length > 0 ? $" --session {Quote(sessionId)}" : "") +
                    $" --log {Quote(log)}"
            };
            _process = Process.Start(psi);
            if (_process == null)
            {
                LogOnce("WebHost 自动启动失败：Process.Start 返回空");
                return;
            }
            _lastError = "";
            Log.Write($"WebHost 自动启动：pid={pid} host_pid={_process.Id} session={(sessionId.Length > 0 ? sessionId : "latest")}");
        }
        catch (Exception ex)
        {
            LogOnce("WebHost 自动启动失败：" + ex.Message);
        }
    }

    private string ResolveExe()
    {
        // Portable release layout:
        //   Desktop\War3DeathSettlement.exe
        //   Game\ddh_web\ddh_web.exe
        // Prefer the bundle so standalone operation does not depend on a prior
        // installation into C:\launch or any WFE directory.
        string bundled = Path.GetFullPath(Path.Combine(
            AppContext.BaseDirectory, "..", "Game", "ddh_web", "ddh_web.exe"));
        if (File.Exists(bundled)) return bundled;

        if (!string.IsNullOrWhiteSpace(_settings.WebHostExe) &&
            File.Exists(_settings.WebHostExe)) return _settings.WebHostExe;
        string preferred = @"C:\launch\ddh_web\ddh_web.exe";
        if (File.Exists(preferred)) return preferred;
        string local = Path.Combine(AppContext.BaseDirectory, "ddh_web", "ddh_web.exe");
        if (File.Exists(local)) return local;
        return Path.Combine(AppContext.BaseDirectory, "ddh_web.exe");
    }

    private string ResolveHtml()
    {
        string exe = ResolveExe();
        string alongsideExe = Path.Combine(Path.GetDirectoryName(exe) ?? "", "dss.html");
        if (File.Exists(alongsideExe)) return alongsideExe;
        if (!string.IsNullOrWhiteSpace(_settings.WebHostHtml) &&
            File.Exists(_settings.WebHostHtml)) return _settings.WebHostHtml;
        string preferred =
            @"C:\launch\ddh_web\dss.html";
        if (File.Exists(preferred)) return preferred;
        return Path.Combine(AppContext.BaseDirectory, "dss.html");
    }

    private void LogOnce(string message)
    {
        if (string.Equals(_lastError, message, StringComparison.Ordinal)) return;
        _lastError = message;
        Log.Warn(message);
    }

    private static string Quote(string value) =>
        "\"" + value.Replace("\"", "\\\"", StringComparison.Ordinal) + "\"";

    public void Dispose()
    {
        _process?.Dispose();
        _process = null;
    }
}
