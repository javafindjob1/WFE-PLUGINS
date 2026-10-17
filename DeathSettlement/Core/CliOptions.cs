namespace War3DeathSettlement.Core;

/// <summary>命令行参数（也是“连接参数”）。</summary>
public sealed class CliOptions
{
    public bool Probe;
    public bool SelfTest;
    public bool Help;
    public bool Headless;
    public bool Deep;
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
    /// <summary>只用深度扫描发现单位（关掉句柄表和选区链）——排障/自测用。</summary>
    public bool DeepOnly;
    public bool NoHandleTable;
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
                case "--deep": o.Deep = true; break;
                case "--deep-only": o.Deep = true; o.DeepOnly = true; break;
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
        if (o.DeepOnly) { o.NoHandleTable = true; o.NoSelection = true; }
        return o;
    }

    public AttachOptions ToAttach() => new(Pid, Name, ForceVersion);
}
