namespace War3DeathSettlement.Core;

/// <summary>
/// 单位“拥有者”解析的唯一实现。UnitScanner（单位跟踪 / 死亡结算）与
/// Ui.UnitOwnerResolver（伤害事件两列 / 双击弹窗）都调用它，保证各处显示同一结果。
///
/// 1.27 的 `GetOwningPlayer` 虚拟函数最终返回 `CUnit+0x58`，
/// `GetPlayerId` 返回的也是同一个 0 基玩家槽位。这里统一直读，不调用 JASS，
/// 也不使用 +0x1C、玩家对象指针匹配或启发式回退。
/// </summary>
public static class OwnerResolver
{
    public const int Unknown = -1;

    /// <summary>
    /// 解释 CUnit+0x58：0～23 是合法玩家槽位，其他值视为未知。
    /// 参数保留是为了兼容调用方；不再使用 players[] 做指针匹配。
    /// </summary>
    public static int Interpret(uint v, uint[] players, out string interpretation)
    {
        _ = players;
        if (v < 24)
        {
            interpretation = "直读";
            return (int)v;
        }
        interpretation = "未知";
        return Unknown;
    }

    /// <summary>
    /// 解析拥有者槽位（0 基；0 = 玩家 1），只读 CUnit+0x58。
    /// 读不到或值不在 0～23 时返回 Unknown，不做任何回退。
    /// `players` / `ownerOffset` 保留用于兼容旧调用。
    /// </summary>
    public static int Resolve(Wc3Game g, uint unitAddr, uint[] players, int ownerOffset,
        out uint raw, out string interpretation)
    {
        _ = ownerOffset;
        raw = 0;
        interpretation = "未知";
        if (unitAddr == 0) return Unknown;

        if (g.Mem.ReadU32((ulong)unitAddr + Wc3UnitOffset.Owner, out uint v))
        {
            raw = v;
            return Interpret(v, players, out interpretation);
        }
        return Unknown;
    }
}
