using System.Text;
using War3DeathSettlement.Core;

namespace War3DeathSettlement;

internal static class Program
{
    [STAThread]
    private static int Main(string[] args)
    {
        Log.Init();

        if (HasArg(args, "--selftest")) { EnsureConsole(); return SelfTest.Run(); }
        if (HasArg(args, "--probe")) { EnsureConsole(); return Probe.Run(args); }
        if (HasArg(args, "--help") || HasArg(args, "-h") || HasArg(args, "/?")) { EnsureConsole(); PrintHelp(); return 0; }

        // 默认：图形界面（和 War3Trainer 一样，双击就能用）
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        try { Native.SetProcessDPIAware(); } catch { }
        try
        {
            Application.Run(new Ui.MainForm());
        }
        catch (Exception ex)
        {
            Log.Error("界面崩溃：" + ex);
            MessageBox.Show(ex.ToString(), "War3DeathSettlement 崩溃", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 2;
        }
        return 0;
    }

    private static bool HasArg(string[] args, string name) =>
        args.Any(a => string.Equals(a, name, StringComparison.OrdinalIgnoreCase));

    /// <summary>
    /// WinExe 默认没有控制台。命令行模式（--probe/--selftest）需要把它接回来：
    /// 先尝试挂到父进程的控制台（从 cmd/pwsh 启动时），失败再自己开一个。
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
              War3DeathSettlement.exe                打开图形界面（默认）
              War3DeathSettlement.exe --probe        实机诊断：连接 war3 并把内存结构逐项打出来
              War3DeathSettlement.exe --probe --deep 诊断时额外跑一次全堆深度扫描
              War3DeathSettlement.exe --selftest     离线自检记账/结算逻辑（不需要游戏）
              War3DeathSettlement.exe --help         显示本帮助

            报告与日志都在 exe 同目录的 logs\ 下：
              selftest.txt        自检报告
              probe-*.txt         实机诊断报告
              settlements.csv     每一条死亡结算（时间/单位/次数/总伤害/最大单次/最惨1秒/秒伤…）
            """);
    }
}
