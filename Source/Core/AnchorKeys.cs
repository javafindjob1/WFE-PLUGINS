namespace War3DeathSettlement.Core;

/// <summary>
/// 表格“按内容锚定”用的身份键：界面重建表格前后用它找回“用户正在看的那一行”。
/// 键必须稳定且唯一（同一行前后两次重建算出同一个键；不同行键不同）。
/// </summary>
public static class AnchorKeys
{
    /// <summary>伤害事件行：用 Seq（共享内存环的单调递增序号，事件窗口内唯一且和时间同序）。</summary>
    public static string ForHook(DamageHook.HookEvent e) => e.Seq.ToString();

    /// <summary>死亡结算行：地址 + 死亡时间 + 实例号（同一地址可能复活/复用，实例号区分第几条命）。</summary>
    public static string ForSettlement(Settlement s) =>
        $"S:{s.Addr:X8}:{s.DiedAt.Ticks}:{s.InstanceIndex}";

    /// <summary>存活行（死亡结算页里的蓝字行）：地址 + 实例号。</summary>
    public static string ForLiveUnit(uint addr, int instanceIndex) =>
        $"L:{addr:X8}:{instanceIndex}";

    /// <summary>
    /// 【战场单位】行：单位地址。
    /// 同一局的单位地址唯一；表头过滤触发整表重建时靠它把用户正在看的那一行停在原处。
    /// </summary>
    public static string ForUnit(uint addr) => $"U:{addr:X8}";
}
