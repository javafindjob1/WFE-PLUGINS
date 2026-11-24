using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>
/// 存活单位的实时详情文本（死亡结算页双击蓝字存活行后，只读详情窗口里的内容）。
/// 纯函数：吃一份 UnitView 快照 + 匹配到它的钩子事件（Victim == 该单位地址），吐一段等宽文本。
/// 放在 Core 里方便离线自检（不依赖 WinForms）。
/// </summary>
public static class LiveUnitDetail
{
    public static string Build(UnitView u, IReadOnlyList<DamageHook.HookEvent> allEvents, DateTime snapshotAt)
    {
        var events = allEvents.Where(e => e.Victim == u.Addr).ToList();
        var sb = new StringBuilder();

        string name = u.Name.Length > 0 ? u.Name : u.TypeCode;
        sb.AppendLine($"[存活] {name}（类型码 {u.TypeCode}） 0x{u.Addr:X8}　拥有者 {u.Owner}");
        sb.AppendLine($"  当前HP {u.Hp:0.#} / 上限 {u.HpMax:0.#}（{u.HpPercent * 100:0.#}%）");
        sb.AppendLine($"  累计受伤 {u.Taken:0.00}，受击 {u.Hits} 次，秒伤 {u.Dps:0.00}");
        sb.AppendLine($"  首次发现 {(u.FirstSeen != default ? u.FirstSeen.ToString("HH:mm:ss.fff") : "?")}，" +
                      $"最后受击 {(u.LastHit.HasValue ? u.LastHit.Value.ToString("HH:mm:ss.fff") : "?")}");
        sb.AppendLine($"  快照时间 {snapshotAt:HH:mm:ss}（本窗口不自动刷新）");
        sb.AppendLine();

        var srcs = HookBreakdown.Sources(events, 1.0, 20);
        sb.AppendLine($"按来源分组的伤害（钩子事件里 Victim == 0x{u.Addr:X8} 的 {events.Count} 笔）：");
        if (srcs.Count == 0)
        {
            sb.AppendLine("  （没有匹配到钩子事件）");
        }
        else
        {
            foreach (var r in srcs)
                sb.AppendLine("  " + r.ToString());
        }
        sb.AppendLine();

        sb.AppendLine("最近 20 笔事件明细（时间 / 来源 / 原始 / 引擎 / 地图 / 净掉血 / 前血→后血 / 攻击类型 / 伤害类型）：");
        var recent = events.TakeLast(20).ToList();
        if (recent.Count == 0) sb.AppendLine("  （无）");
        foreach (var e in recent)
        {
            sb.AppendLine($"  {e.At:HH:mm:ss.fff}  {e.SourceText}  原始 {e.Amount:0.00}  引擎 {e.EngineText}  " +
                          $"地图 {e.EffectiveText}  净掉血 {e.NetDropText}  血 {e.HpText}  攻{e.AttackType}  伤{e.DamageTypeText}");
        }
        return sb.ToString();
    }
}
