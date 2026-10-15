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
            string baseDir = dir ?? System.IO.Path.Combine(AppContext.BaseDirectory, "logs");
            Directory.CreateDirectory(baseDir);
            _path = System.IO.Path.Combine(baseDir, $"dss-{DateTime.Now:yyyyMMdd-HHmmss}.log");
            Write("=== War3DeathSettlement 启动 " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ===");
        }
        catch { _path = ""; }
    }

    public static void Write(string message)
    {
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

    public static string[] Snapshot()
    {
        lock (Gate) return Tail.ToArray();
    }

    public static string SnapshotText()
    {
        lock (Gate) return string.Join(Environment.NewLine, Tail);
    }
}
