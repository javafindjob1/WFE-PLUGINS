using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>
/// 无界面监视模式：不弹窗口，直接在控制台里跑「扫描 → 记账 → 死亡结算」，
/// 每条结算都打印出来，同时照常写 logs\settlements.csv。
/// 用途：① 自动化/远程验证；② 不想开窗口时挂着跑；③ 排障时把结算流打给日志。
///
/// 用法：War3DeathSettlement.exe --monitor [--seconds 120] [--pid N] [--force-version X]
/// </summary>
public static class HeadlessMonitor
{
    public static int Run(CliOptions opt)
    {
        var engine = new MonitorEngine
        {
            // 无界面模式一律自动连接：进程还没起来就等着，起来了（或换局重开）就自动挂上
            AutoAttach = true,
            AttachOptions = opt.ToAttach(),
            EnableHandleTable = !opt.NoHandleTable,
            EnableSelection = !opt.NoSelection,
            ReadPluginLog = !opt.NoPluginLog
        };
        if (!string.IsNullOrWhiteSpace(opt.PluginLogPath)) engine.PluginLogPath = opt.PluginLogPath!;

        Console.WriteLine("=== 无界面监视模式 ===");
        Console.WriteLine($"时长 {opt.Seconds} 秒；CSV：{engine.SettlementCsvPath}");
        if (opt.Pid is int p) Console.WriteLine($"目标进程：PID {p}");
        if (opt.ForceVersion != null) Console.WriteLine($"强制版本：{opt.ForceVersion}");
        Console.WriteLine($"插件日志：{(engine.ReadPluginLog ? engine.PluginLogPath : "已关闭")}");

        if (engine.Attach(out string first)) Console.WriteLine("已连接：" + first);
        else Console.WriteLine("暂时没连上（会继续自动重试）：" + first);
        Console.WriteLine();

        engine.Start();

        int printed = 0;
        var deadline = DateTime.UtcNow.AddSeconds(opt.Seconds);
        int lastStatusSecond = -1;
        int lastAttributed = 0;

        while (DateTime.UtcNow < deadline)
        {
            Thread.Sleep(300);
            var snap = engine.Current;

            // 新结算 → 立刻打印
            if (snap.Settlements.Count > printed)
            {
                for (int i = printed; i < snap.Settlements.Count; i++)
                {
                    Console.WriteLine();
                    Console.Write(snap.Settlements[i].ToText());
                }
                printed = snap.Settlements.Count;
            }

            // 插件来源补上了 → 打一条，证明“来源”这条路真的通了
            if (snap.Settlements.Count > 0 && engine.AttributedCount > lastAttributed)
            {
                lastAttributed = engine.AttributedCount;
                var newest = snap.Settlements.LastOrDefault(s => s.Attribution != null);
                if (newest != null)
                    Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] 来源已补：{newest.TypeCode} ← " +
                                      $"{newest.Attribution!.Name}({newest.Attribution.Code}) " +
                                      $"{newest.Attribution.SourceSummary()}");
            }

            int sec = (int)(DateTime.UtcNow - (deadline.AddSeconds(-opt.Seconds))).TotalSeconds;
            if (sec != lastStatusSecond && sec % 10 == 0)
            {
                lastStatusSecond = sec;
                var st = snap.Stats;
                Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] t+{sec}s 状态={snap.Status}");
                Console.WriteLine($"            单位={snap.Units.Count} 结算={snap.Settlements.Count} " +
                                  $"模式={st.Mode} 用时={st.ElapsedMs}ms 深扫={st.DeepMb}MB");
                Console.WriteLine($"            插件日志：解析 {engine.PluginSettlementsSeen} 条，已补来源 {engine.AttributedCount} 条" +
                                  (engine.ReadPluginLog ? "" : "（已关闭）"));
                if (st.SigHits > 0)
                    Console.WriteLine($"            漏斗：特征 {st.SigHits} → 索引 {st.SigWithHpIndex} → " +
                                      $"状态可读 {st.SigStateReadable} → HP 像样 {st.SigPlausibleHp}");
            }
        }

        var final = engine.Current;
        Console.WriteLine();
        Console.WriteLine("=== 结束 ===");
        Console.WriteLine($"在场单位 {final.Units.Count} 个，结算 {final.Settlements.Count} 条，CSV：{engine.SettlementCsvPath}");
        engine.Dispose();
        return 0;
    }
}

