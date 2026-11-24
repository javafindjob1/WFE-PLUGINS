namespace War3DeathSettlement.Core;

/// <summary>
/// 伤害事件页 / 双击弹窗共用的纯函数：地址格式化、玩家号格式化、分页切片、对端单位集合。
/// 全都不碰内存/界面，方便离线自检（自检用例直接调用这些函数验证口径）。
/// </summary>
public static class UnitEvents
{
    /// <summary>每页行数（伤害事件页 + 双击弹窗共用）。</summary>
    public const int PageSize = 500;

    /// <summary>单位内存地址显示：固定 8 位十六进制，如 0x0010586C。</summary>
    public static string FormatAddr(uint addr) => "0x" + addr.ToString("X8");

    /// <summary>玩家号显示：N 从 1 开始；拿不到（slot&lt;0）显示 ?。</summary>
    public static string FormatPlayer(int slot) => slot >= 0 ? $"Player {slot + 1}" : "?";

    /// <summary>总条数 → 页数（至少 1 页）。</summary>
    public static int PageCount(int total, int pageSize = PageSize)
    {
        if (pageSize <= 0) pageSize = PageSize;
        return Math.Max(1, (total + pageSize - 1) / pageSize);
    }

    /// <summary>
    /// 分页切片：输入是“最旧在前”的事件列表，输出当前页“最新在前”的窗口。
    /// 页号从 0 开始；越界时被夹到合法范围。空列表返回空。
    /// </summary>
    public static List<DamageHook.HookEvent> SlicePage(IReadOnlyList<DamageHook.HookEvent> ascending, int page, int pageSize = PageSize)
    {
        if (pageSize <= 0) pageSize = PageSize;
        int total = ascending.Count;
        int pages = Math.Max(1, (total + pageSize - 1) / pageSize);
        page = Math.Clamp(page, 0, pages - 1);
        int end = total - page * pageSize;              // 本页在“最旧在前”列表里的右边界（开区间）
        int start = Math.Max(0, end - pageSize);
        int count = end - start;
        var result = new List<DamageHook.HookEvent>(count);
        for (int i = start + count - 1; i >= start; i--) result.Add(ascending[i]);
        return result;
    }

    /// <summary>
    /// 与该单位相关（它打人 / 被打）的所有“对端单位”地址，去重、按地址升序。
    /// 用于双击弹窗里的“参与单位”筛选下拉：列出一只单位打过谁 / 被谁打。
    /// </summary>
    public static List<uint> CounterpartAddrs(IReadOnlyList<DamageHook.HookEvent> events, uint addr)
    {
        var set = new HashSet<uint>();
        foreach (var e in events)
        {
            if (e.Source == addr)
            {
                if (e.Victim != 0 && e.Victim != addr) set.Add(e.Victim);
            }
            if (e.Victim == addr)
            {
                if (e.Source != 0 && e.Source != addr) set.Add(e.Source);
            }
        }
        var list = set.ToList();
        list.Sort();
        return list;
    }
}
