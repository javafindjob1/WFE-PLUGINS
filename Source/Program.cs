using System.Text;
using War3DeathSettlement.Core;

namespace War3DeathSettlement;

internal static class Program
{
    [STAThread]
    private static int Main(string[] args)
    {
        Log.Init();
        var opt = CliOptions.Parse(args);

        // ---- 纯界面启动：默认就要管理员 ----
        // 伤害钩子要注入 ddh.dll，普通权限连魔兽进程都查询不了（OpenProcess err=5），
        // 与其"连上之后提示你点提权按钮"，不如启动时就把自己提起来。
        // 只对"纯 GUI 启动"生效：带 --probe/--selftest/--monitor 时保持原权限，
        // 免得脚本和离线自检被 UAC 打断（那些路径也不需要写权限）。
        if (IsGuiLaunch(opt) && !Integrity.IsSelfElevated && !HasElevatedFlag(args))
        {
            if (RelaunchElevated(args)) return 0;
            // 用户拒绝了 UAC：继续以普通权限跑（只读仍可用，界面上还有一键提权按钮）
        }

        // ---- 单实例（只限制图形界面）----
        // 自检/探针/无界面模式不受影响：脚本可以和已打开的窗口并存。
        if (IsGuiLaunch(opt))
        {
            _singleInstance = new Mutex(initiallyOwned: true, @"Local\War3DeathSettlement.SingleInstance", out bool createdNew);
            if (!createdNew)
            {
                try
                {
                    MessageBox.Show("War3DeathSettlement 已经在运行。\n\n请切到已打开的窗口。",
                        "War3DeathSettlement", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                catch { }
                return 0;
            }
        }

        if (opt.SelfTest) { EnsureConsole(); return SelfTest.Run(); }
        if (opt.Probe) { EnsureConsole(); return Probe.Run(opt); }
        if (opt.Headless) { EnsureConsole(); return HeadlessMonitor.Run(opt); }
        if (opt.Help) { EnsureConsole(); PrintHelp(); return 0; }

        // 默认：图形界面（和 War3Trainer 一样，双击就能用）
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        try { Native.SetProcessDPIAware(); } catch { }

        // ---- 稳定性兜底：别让 WinForms 未处理异常把整个程序判死 ----
        // ① UI 线程异常（真机的 “Collection was modified” 就是这类）：记日志 + 温和提示，消息循环继续跑。
        Application.SetUnhandledExceptionMode(UnhandledExceptionMode.CatchException);
        Application.ThreadException += (_, e) =>
        {
            try { Log.Error("界面线程未处理异常：" + e.Exception); } catch { }
            try
            {
                MessageBox.Show("界面发生一个错误，已记录到日志（logs\\dss-*.log），程序可继续使用。\n\n" + e.Exception.Message,
                    "War3DeathSettlement 提示", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
            catch { }
        };
        // ② 非界面线程（后台监视等）兜底：把完整栈写进日志，尽量不静默死。
        AppDomain.CurrentDomain.UnhandledException += (_, e) =>
        {
            try { Log.Error("未处理异常（后台线程）：" + (e.ExceptionObject as Exception)); } catch { }
            try
            {
                MessageBox.Show("后台发生一个错误，已记录到日志，程序会尝试继续运行。\n\n" + (e.ExceptionObject as Exception)?.Message,
                    "War3DeathSettlement 提示", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
            catch { }
        };

        try
        {
            Application.Run(new Ui.MainForm(opt));
        }
        catch (Exception ex)
        {
            Log.Error("界面崩溃：" + ex);
            MessageBox.Show(ex.ToString(), "War3DeathSettlement 崩溃", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 2;
        }
        try { _singleInstance?.ReleaseMutex(); } catch { }
        _singleInstance?.Dispose();
        return 0;
    }

    /// <summary>
    /// 提权重启时追加的标记：原进程用它告诉"提起来的新进程"别再自举一遍，避免死循环。
    /// 参数会被 <see cref="CliOptions.Parse"/> 忽略（未知参数不报错）。
    /// </summary>
    private const string ElevatedFlag = "--dss-elevated";

    /// <summary>单实例互斥体（GUI 只允许一个；进程退出时由系统释放）。</summary>
    private static Mutex? _singleInstance;

    /// <summary>没有任何子命令 = 纯界面启动。</summary>
    private static bool IsGuiLaunch(CliOptions opt) =>
        !opt.Probe && !opt.SelfTest && !opt.Help && !opt.Headless;

    private static bool HasElevatedFlag(string[] args) =>
        args.Any(a => string.Equals(a, ElevatedFlag, StringComparison.OrdinalIgnoreCase));

    /// <summary>
    /// 以管理员身份重新启动自己（ShellExecute + runas），成功返回 true（调用方随即退出）。
    /// 用户取消 UAC 会抛 Win32Exception(1223)，这里吞掉并返回 false —— 继续以普通权限运行。
    /// </summary>
    private static bool RelaunchElevated(string[] args)
    {
        try
        {
            string exe = Environment.ProcessPath ?? Application.ExecutablePath;
            var psi = new System.Diagnostics.ProcessStartInfo(exe)
            {
                UseShellExecute = true,
                Verb = "runas",
                WorkingDirectory = AppContext.BaseDirectory,
            };

            var forwarded = args
                .Where(a => !string.Equals(a, ElevatedFlag, StringComparison.OrdinalIgnoreCase))
                .ToList();
            forwarded.Add(ElevatedFlag);
            psi.Arguments = string.Join(" ", forwarded.Select(CliOptions.Quote));

            System.Diagnostics.Process.Start(psi);
            Log.Write("已请求以管理员身份重启（界面模式默认提权）");
            return true;
        }
        catch (Exception ex)
        {
            Log.Write("提权自举失败，继续以普通权限运行：" + ex.Message);
            return false;
        }
    }

    /// <summary>
    /// WinExe 默认没有控制台。命令行模式需要把它接回来：
    /// 先尝试挂到父进程的控制台（从 cmd/powershell 启动时），失败再自己开一个。
    /// </summary>
    private static void EnsureConsole()
    {
        try
        {
            if (!Native.AttachConsole(Native.ATTACH_PARENT_PROCESS)) Native.AllocConsole();
            var stdout = Console.OpenStandardOutput();
            var writer = new StreamWriter(stdout, new UTF8Encoding(false)) { AutoFlush = true };
            Console.SetOut(writer);
            Console.SetError(writer);
            Console.OutputEncoding = Encoding.UTF8;
        }
        catch { /* 控制台不可用时，报告仍会写进 logs\ */ }
    }

    private static void PrintHelp()
    {
        Console.WriteLine("""
            War3DeathSettlement —— 魔兽死亡结算（纯外部只读，不注入、不改游戏内存）

            用法：
              War3DeathSettlement.exe                     打开图形界面（默认，双击即可）
              War3DeathSettlement.exe --probe              实机诊断：把内存结构逐项打出来
              War3DeathSettlement.exe --monitor [--seconds 120]
                                                        无界面监视并输出结算日志
              War3DeathSettlement.exe --selftest           离线自检记账/结算逻辑（不需要游戏）
              War3DeathSettlement.exe --help               显示本帮助

            可选连接参数（平台的进程名/版本号不标准时用）：
              --pid <PID>              直接指定进程号
              --name <名字[,名字]>     额外的进程名
              --force-version <版本>   强制用某个版本的地址表，例如 1.27.0.52240

            报告与日志都在 exe 同目录的 logs\ 下：
              selftest.txt        自检报告
              probe-*.txt         实机诊断报告
              settlements.csv     每一条死亡结算
            """);
    }
}
