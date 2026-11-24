using War3DeathSettlement.Core;

namespace War3DeathSettlement.Desktop;

internal static class Program
{
    private static Mutex? _singleInstance;

    [STAThread]
    private static void Main(string[] args)
    {
        Log.Init(Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "War3DeathSettlement",
            "logs"));
        ApplicationConfiguration.Initialize();

        _singleInstance = new Mutex(
            true,
            @"Local\War3DeathSettlement.VueDesktop.SingleInstance",
            out bool createdNew);
        if (!createdNew)
        {
            MessageBox.Show(
                "魔兽死亡结算已经在运行。\n\n请切换到已打开的窗口。",
                "War3DeathSettlement",
                MessageBoxButtons.OK,
                MessageBoxIcon.Information);
            return;
        }

        Application.SetUnhandledExceptionMode(UnhandledExceptionMode.CatchException);
        Application.ThreadException += (_, e) =>
        {
            Log.Error("Vue 桌面壳界面异常：" + e.Exception);
            MessageBox.Show(
                "界面发生错误，详情已写入日志。\n\n" + e.Exception.Message,
                "War3DeathSettlement",
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning);
        };

        try
        {
            Application.Run(new DesktopWindow());
        }
        catch (Exception ex)
        {
            Log.Error("Vue 桌面壳启动失败：" + ex);
            MessageBox.Show(ex.ToString(), "War3DeathSettlement 启动失败",
                MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        finally
        {
            try { _singleInstance.ReleaseMutex(); } catch { }
            _singleInstance.Dispose();
        }
    }
}
