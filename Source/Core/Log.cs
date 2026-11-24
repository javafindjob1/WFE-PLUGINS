using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>
/// 极简日志器：写文件 + 保留内存尾巴（给界面“诊断”页用）。
/// 文件放在 exe 同目录的 logs\ 下，UTF-8。
/// </summary>
public static class Log
{
    private static readonly object Gate = new();
    private static readonly Queue<string> Tail = new();
    private static string _path = "";
    private const int TailMax = 2000;

    public static string Path => _path;

    public static event Action<string>? LineWritten;

    public static void Init(string? dir = null)
    {
        try
        {
            /* 统一日志目录：%LOCALAPPDATA%\War3DeathSettlement\logs（ddh 插件也写这里）
               发布包默认关闭文件日志：exe 同目录没有 log.on 就只保留内存尾巴，不再写盘。 */
            string baseDir = dir ?? System.IO.Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "War3DeathSettlement", "logs");
            if (dir is null && !File.Exists(System.IO.Path.Combine(AppContext.BaseDirectory, "log.on")))
            {
                _path = "";
                return;
            }
            Directory.CreateDirectory(baseDir);
            CleanupOldLogs(baseDir, 2);
            _path = System.IO.Path.Combine(baseDir, $"dss-{DateTime.Now:yyyyMMdd-HHmmss}.log");
            Write("=== War3DeathSettlement 启动 " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ===");
            try
            {
                var asm = System.Reflection.Assembly.GetExecutingAssembly();
                string loc = asm.Location;
                // 日志里不放绝对路径：exe 目录前缀去掉，位置只显示相对 exe 的文件名。
                Write($"程序集 {asm.GetName().Version}　构建 {File.GetLastWriteTime(loc):yyyy-MM-dd HH:mm:ss}　位置 {Relative(loc)}");
            }
            catch { }
        }
        catch { _path = ""; }
    }

    public static void Write(string message)
    {
        // 统一兜底：日志里不要绝对路径（异常消息里夹带的也一起去掉）。
        // 控制台/诊断报告/错误提示不走这里，仍然保留绝对路径给用户复制。
        message = Relative(message);
        string line = $"[{DateTime.Now:HH:mm:ss.fff}] {message}";
        lock (Gate)
        {
            Tail.Enqueue(line);
            while (Tail.Count > TailMax) Tail.Dequeue();
            if (_path.Length > 0)
            {
                try { File.AppendAllText(_path, line + Environment.NewLine, Encoding.UTF8); } catch { }
            }
        }
        try { LineWritten?.Invoke(line); } catch { }
        System.Diagnostics.Debug.WriteLine(line);
    }

    public static void Warn(string message) => Write("W " + message);
    public static void Error(string message) => Write("E " + message);

    /// <summary>
    /// 清掉日志目录里超过 <paramref name="days"/> 天的日志（dss-*.log 与 ddh-*.log），
    /// 以及残留的 ddh 调试产物（*.seed.txt / *.unit.txt / *.uprobe.txt / *.udata.txt / *.txt）。
    /// </summary>
    private static void CleanupOldLogs(string dir, int days)
    {
        try
        {
            var cutoff = DateTime.Now.AddDays(-days);
            foreach (var f in Directory.EnumerateFiles(dir))
            {
                string name = System.IO.Path.GetFileName(f);
                bool isLog = name.StartsWith("dss-", StringComparison.OrdinalIgnoreCase) ||
                             name.StartsWith("ddh-", StringComparison.OrdinalIgnoreCase);
                bool isDebugArtifact =
                    name.EndsWith(".seed.txt", StringComparison.OrdinalIgnoreCase) ||
                    name.EndsWith(".unit.txt", StringComparison.OrdinalIgnoreCase) ||
                    name.EndsWith(".uprobe.txt", StringComparison.OrdinalIgnoreCase) ||
                    name.EndsWith(".udata.txt", StringComparison.OrdinalIgnoreCase);
                if (!isLog && !isDebugArtifact) continue;
                try
                {
                    if (File.GetLastWriteTime(f) < cutoff) File.Delete(f);
                }
                catch { }
            }
        }
        catch { }
    }

    /// <summary>
    /// 日志用的相对路径：把 exe 目录前缀替换成空（`history\x.json`、`logs\dss-1.log`），
    /// 其它路径原样保留。也处理“路径夹在一句话中间”的情况（异常消息等），
    /// 只替换带结尾分隔符的前缀，避免把 `publish_backup` 这类同名前缀误伤。
    /// </summary>
    public static string Relative(string? path)
    {
        if (string.IsNullOrEmpty(path)) return path ?? "";
        try
        {
            string baseDir = AppContext.BaseDirectory;
            if (!baseDir.EndsWith(System.IO.Path.DirectorySeparatorChar))
                baseDir += System.IO.Path.DirectorySeparatorChar;

            // 纯路径 / 文本开头：直接去掉前缀。
            if (path.StartsWith(baseDir, StringComparison.OrdinalIgnoreCase))
                return path.Substring(baseDir.Length);

            // 恰好就是 exe 目录本身。
            string root = baseDir.TrimEnd(System.IO.Path.DirectorySeparatorChar, System.IO.Path.AltDirectorySeparatorChar);
            if (string.Equals(path, root, StringComparison.OrdinalIgnoreCase)) return ".";

            // 夹在异常消息等文本中间：只替换带末尾分隔符的 exe 目录前缀。
            return path.Replace(baseDir, "", StringComparison.OrdinalIgnoreCase);
        }
        catch
        {
            return path;
        }
    }

    public static string[] Snapshot()
    {
        lock (Gate) return Tail.ToArray();
    }

    public static string SnapshotText()
    {
        lock (Gate) return string.Join(Environment.NewLine, Tail);
    }
}

