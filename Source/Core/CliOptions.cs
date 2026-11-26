namespace War3DeathSettlement.Core;

/// <summary>命令行参数（也是“连接参数”）。</summary>
public sealed class CliOptions
{
    public bool Probe;
    public bool SelfTest;
    public bool Help;
    public bool Headless;
    /// <summary>指定进程号（平台的魔兽进程名不是 war3 时用）。</summary>
    public int? Pid;
    /// <summary>额外的进程名（逗号分隔）。</summary>
    public string? Name;
    /// <summary>强制使用某个版本的地址表（平台改过 game.dll 版本号时用）。</summary>
    public string? ForceVersion;
    /// <summary>无界面监视多少秒后退出。</summary>
    public int Seconds = 60;
    /// <summary>游戏内插件日志路径（null = 用默认/设置里的路径）。</summary>
    public string? PluginLogPath;
    /// <summary>完全关闭插件日志读取。</summary>
    public bool NoPluginLog;
    /// <summary>关掉句柄表发现（排障用；选区链/钩子事件锚点仍然有效）。</summary>
    public bool NoHandleTable;
    /// <summary>关掉选区链发现（排障用；句柄表/钩子事件锚点仍然有效）。</summary>
    public bool NoSelection;

    public static CliOptions Parse(string[] args)
    {
        var o = new CliOptions();
        for (int i = 0; i < args.Length; i++)
        {
            string a = args[i];
            switch (a.ToLowerInvariant())
            {
                case "--probe": o.Probe = true; break;
                case "--selftest": o.SelfTest = true; break;
                case "--monitor": o.Headless = true; break;
                case "--no-handle": o.NoHandleTable = true; break;
                case "--no-selection": o.NoSelection = true; break;
                case "--help" or "-h" or "/?": o.Help = true; break;
                case "--pid":
                    if (i + 1 < args.Length && int.TryParse(args[++i], out int pid)) o.Pid = pid;
                    break;
                case "--name":
                    if (i + 1 < args.Length) o.Name = args[++i];
                    break;
                case "--force-version":
                    if (i + 1 < args.Length) o.ForceVersion = args[++i];
                    break;
                case "--plugin-log":
                    if (i + 1 < args.Length) o.PluginLogPath = args[++i];
                    break;
                case "--no-plugin-log": o.NoPluginLog = true; break;
                case "--seconds":
                    if (i + 1 < args.Length && int.TryParse(args[++i], out int sec)) o.Seconds = Math.Clamp(sec, 1, 24 * 3600);
                    break;
            }
        }
        return o;
    }

    public AttachOptions ToAttach() => new(Pid, Name, ForceVersion);

    /// <summary>
    /// 把一个参数还原成"可以直接拼进命令行"的形式（带空格/制表符/引号时加引号）。
    /// 提权重启（runas）要转发原始 argv，这里和 MainForm 共用同一份实现。
    /// </summary>
    public static string Quote(string a)
    {
        if (a.Length == 0) return "\"\"";
        if (a.IndexOfAny(new[] { ' ', '\t', '"' }) < 0) return a;
        return "\"" + a.Replace("\"", "\\\"") + "\"";
    }
}
