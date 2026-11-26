using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>
/// 无界面监视模式：不弹窗口，直接在控制台里跑「扫描 → 记账 → 死亡结算」，
/// 每条结算都打印出来（不再落 CSV，只打在控制台/日志）。
/// 用途：① 自动化/远程验证；② 不想开窗口时挂着跑；③ 排障时把结算流打给日志。
///
/// 用法：War3DeathSettlement.exe --monitor [--seconds 120] [--pid N] [--force-version X]
/// </summary>
public static class HeadlessMonitor
{
    public static int Run(CliOptions opt)
    {
        var settings = Settings.Load();
        var engine = new MonitorEngine
        {
            // 无界面模式一律自动连接：进程还没起来就等着，起来了（或换局重开）就自动挂上
            AutoAttach = true,
            AttachOptions = opt.ToAttach(),
            EnableHandleTable = !opt.NoHandleTable,
            EnableSelection = !opt.NoSelection,
            ReadPluginLog = !opt.NoPluginLog,
            // 侵入式钩子：命令行 --hook / --no-hook 优先，否则跟随 ini
            HookEnabled = opt.Hook ?? settings.HookEnabled,
            HookDllPath = opt.HookDll ?? settings.HookDll,
            HookInjectorPath = settings.HookInjector,
            // 用户自定义的名字忽略名单（可选，默认空）；马甲单位由 ddh 的 Aloc 技能判定自动过滤
            IgnoreUnitNames = settings.IgnoreUnitNames
        };
        if (!string.IsNullOrWhiteSpace(opt.PluginLogPath)) engine.PluginLogPath = opt.PluginLogPath!;

        Console.WriteLine("=== 无界面监视模式 ===");
        Console.WriteLine($"时长 {opt.Seconds} 秒（不落 CSV，只打在控制台/日志）");
        if (opt.Pid is int p) Console.WriteLine($"目标进程：PID {p}");
        if (opt.ForceVersion != null) Console.WriteLine($"强制版本：{opt.ForceVersion}");
        Console.WriteLine($"插件日志：{(engine.ReadPluginLog ? engine.PluginLogPath : "已关闭")}");

        if (engine.Attach(out string first)) Console.WriteLine("已连接：" + first);
        else Console.WriteLine("暂时没连上（会继续自动重试）：" + first);
        Console.WriteLine();

        engine.Start();

        // 已经打印过的结算：按对象身份记，不靠“条数增量” —— 快照是按 DiedAt 降序排好的，
        // 补建/补挂的结算可能落在中间甚至末尾，用下标增量会漏打或重复打。
        var printed = new HashSet<Settlement>();
        var deadline = DateTime.UtcNow.AddSeconds(opt.Seconds);
        var attrStarted = DateTime.UtcNow;
        int lastAttrSecond = -1;
        int lastStatusSecond = -1;
        int lastAttributed = 0;
        // 和 GUI 完全同一套轮询：从全部单位里连续取 96 个（循环），不是只取前 96 个。
        var unitPoll = new UnitAttrPoller();
        int unitPollPid = -1;
        while (DateTime.UtcNow < deadline)
        {
            Thread.Sleep(300);
            var snap = engine.Current;

            // 无界面模式也驱动 ddh v12 的属性请求/回读（每秒一轮）：
            // 这样 `--monitor --hook` 也能产出 ddh 的 ATTR dump/自动匹配日志，
            // 以及 C# 的“属性回读”诊断行（GUI 里由【战场单位】页驱动）。
            if (FeatureFlags.BattlefieldUnitsEnabled && engine.HookAttrSupported)
            {
                int attrPid = engine.Game?.Mem.Pid ?? 0;
                if (attrPid != unitPollPid)
                {
                    unitPollPid = attrPid;
                    unitPoll.Reset();
                }

                int attrSec = (int)(DateTime.UtcNow - attrStarted).TotalSeconds;
                if (attrSec != lastAttrSecond)
                {
                    lastAttrSecond = attrSec;
                    // 和 GUI 的 UpdateUnitsPage 完全同序：先收上一轮，再发下一轮。
                    // 反过来（先发再收）会让上一轮 doneSeq 永远比新 requestSeq 小 1，收不到。
                    var got = engine.PollUnitAttrs();
                    unitPoll.MarkAnswered(got);

                    // 轮询全部**存活**单位：游标连续取 96 个、到尾回绕；受击只决定批内顺序。
                    // 必须用 RawUnits（未按类型/镜像合并）：否则同类型镜像拿不到镜像位，永远被当 Aloc 隐藏。
                    var living = (snap.RawUnits.Count > 0 ? snap.RawUnits : snap.Units)
                        .Where(u => u.Hp > 0f).ToList();
                    var addrs = unitPoll.PickRound(living, UnitAttrWire.SlotCount);
                    if (addrs.Count > 0 && engine.RequestUnitAttrs(addrs)) unitPoll.MarkRequested(addrs);

                    // 场上还没单位时不要先写一条 0/0 占掉首行；等真有单位再开始 30 秒计时。
                    if (living.Count > 0 &&
                        unitPoll.ShouldLog(Environment.TickCount64, living.Count))
                    {
                        string line = unitPoll.CoverageLine(living);
                        Log.Write(line);
                        Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] {line}");
                    }
                }
            }

            // 新结算 → 立刻打印（快照新的在前；这里按时间正序打，和以前追加顺序的输出一致）
            var fresh = new List<Settlement>();
            foreach (var s in snap.Settlements)
                if (!printed.Contains(s)) fresh.Add(s);
            if (fresh.Count > 0)
            {
                printed.UnionWith(fresh);
                for (int i = fresh.Count - 1; i >= 0; i--)
                {
                    Console.WriteLine();
                    Console.Write(fresh[i].ToText());
                }
            }

            // 插件来源补上了 → 打一条，证明“来源”这条路真的通了（快照降序 → 第一条 = 最新的）
            if (snap.Settlements.Count > 0 && engine.AttributedCount > lastAttributed)
            {
                lastAttributed = engine.AttributedCount;
                var newest = snap.Settlements.FirstOrDefault(s => s.Attribution != null);
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
                                  $"模式={st.Mode} 用时={st.ElapsedMs}ms");
                Console.WriteLine($"            插件日志：解析 {engine.PluginSettlementsSeen} 条，已补来源 {engine.AttributedCount} 条" +
                                  (engine.ReadPluginLog ? "" : "（已关闭）"));
            }
        }

        var final = engine.Current;
        Console.WriteLine();
        Console.WriteLine("=== 结束 ===");
        Console.WriteLine($"在场单位 {final.Units.Count} 个，结算 {final.Settlements.Count} 条");
        engine.Dispose();
        return 0;
    }
}

