namespace War3DeathSettlement.Core;

/// <summary>
/// 把钩子事件**匹配到某一条死亡结算**上。
///
/// 主判据是按"受害单位对象指针"精确匹配（最可靠）；
/// 但实机里有两个坑，所以准备了兜底：
///   ① 单位对象可能在两次采样之间被重建（地址变了）——按指针就漏；
///   ② 观战/平台会话里内存抖动，扫描到的地址和钩子里报的可能短暂不一致。
/// 兜底：同一**类型码** + 在时间窗口内 + 且这些事件确实在掉血 —— 用来把来源补上，
/// 但会打上"按类型码匹配"的标记，界面上能看出来不是精确匹配。
/// </summary>
public static class HookMatcher
{
    public sealed record Result(List<DamageHook.HookEvent> Events, bool Exact, string Note);

    public static Result Select(IReadOnlyList<DamageHook.HookEvent> all, uint addr, string typeCode,
                                DateTime from, DateTime to)
    {
        if (all.Count == 0) return new Result(new List<DamageHook.HookEvent>(), false, "没有钩子事件");

        if (addr != 0)
        {
            var exact = all.Where(e => e.Victim == addr && e.At >= from && e.At <= to).ToList();
            if (exact.Count > 0) return new Result(exact, true, "按对象指针精确匹配");
        }

        if (!string.IsNullOrEmpty(typeCode))
        {
            var byCode = all.Where(e => string.Equals(e.VictimCode, typeCode, StringComparison.OrdinalIgnoreCase)
                                        && e.At >= from && e.At <= to).ToList();
            if (byCode.Count > 0)
                return new Result(byCode, false, $"按类型码 {typeCode} 兜底匹配（单位对象地址变了，来源可能含同种单位的其它个体）");
        }

        return new Result(new List<DamageHook.HookEvent>(), false, "这个单位没有钩子事件");
    }
}
