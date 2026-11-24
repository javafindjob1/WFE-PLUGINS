namespace War3DeathSettlement.Core;

/// <summary>
/// 死亡结算列表的**唯一排序口径**：<c>DiedAt 降序</c>（新的在上面）→ <c>InstanceIndex 降序</c>
/// → <c>Addr 降序</c>；三个键完全相同时保持传入顺序（<see cref="Enumerable.OrderByDescending{TSource,TKey}(IEnumerable{TSource},Func{TSource,TKey})"/>
/// 是稳定排序）。
///
/// 以前“账本追加顺序 = 显示顺序（倒着画）”能凑合，是因为结算只在死亡那一刻追加；
/// 但“致命事件补建结算”（<see cref="MonitorEngine"/> 的 SynthesizeHookDeaths）和
/// “无来源结算补挂”会把 <see cref="Settlement.DiedAt"/> 比当前列表顶部更早的结算追加到末尾，
/// 界面再盲插顶部就会把旧时间顶到新行上面（用户截图里的 01:22:20 在 01:36:27 之上）。
///
/// 所以快照（MonitorEngine.Publish → Current.Settlements）、主页增量插入（MainForm）、
/// 历史窗口（HistoryForm）统一走这里，避免三处各写一份比较器走样。
/// </summary>
public static class SettlementOrder
{
    /// <summary>排序比较：a 应排在 b 前面（更“新”/更靠上）时返回负数，相等返回 0。</summary>
    public static int Compare(DateTime aDiedAt, int aInstanceIndex, uint aAddr,
                              DateTime bDiedAt, int bInstanceIndex, uint bAddr)
    {
        int c = bDiedAt.CompareTo(aDiedAt);          // 时间降序：新的在上
        if (c != 0) return c;
        c = bInstanceIndex.CompareTo(aInstanceIndex); // 同一毫秒：第几条命（实例号大的在前）
        if (c != 0) return c;
        return bAddr.CompareTo(aAddr);                // 再按地址，给同一毫秒的多条一个确定顺序
    }

    public static int Compare(Settlement a, Settlement b) =>
        Compare(a.DiedAt, a.InstanceIndex, a.Addr, b.DiedAt, b.InstanceIndex, b.Addr);

    public static int Compare(HistorySettlement a, HistorySettlement b) =>
        Compare(a.DiedAt, a.InstanceIndex, a.Addr, b.DiedAt, b.InstanceIndex, b.Addr);

    /// <summary>按唯一口径排好序的新列表（稳定的降序；完全同键的保持原顺序）。</summary>
    public static List<Settlement> SortDescending(IEnumerable<Settlement> items) =>
        items.OrderByDescending(s => s.DiedAt)
             .ThenByDescending(s => s.InstanceIndex)
             .ThenByDescending(s => s.Addr)
             .ToList();

    /// <summary>历史 DTO 的同一套降序（旧历史文件按时间正序存过，读出来显式排，不依赖库里顺序）。</summary>
    public static List<HistorySettlement> SortDescending(IEnumerable<HistorySettlement> items) =>
        items.OrderByDescending(s => s.DiedAt)
             .ThenByDescending(s => s.InstanceIndex)
             .ThenByDescending(s => s.Addr)
             .ToList();

    /// <summary>
    /// 二分查找插入点：rows 必须已按唯一口径排好序（降序）；返回新结算该插到的下标（0..rows.Count）。
    /// 与已有行三键完全相同时插在它们**后面**（和“追加”语义一致，也让同一毫秒的多条保持稳定）。
    /// </summary>
    public static int FindInsertIndex(IReadOnlyList<Settlement> rows, Settlement s)
    {
        int lo = 0, hi = rows.Count;
        while (lo < hi)
        {
            int mid = lo + ((hi - lo) >> 1);
            if (Compare(s, rows[mid]) < 0) hi = mid;   // s 应排在 mid 之前
            else lo = mid + 1;                          // s 排在 mid 之后（同键也插在后面）
        }
        return lo;
    }

    /// <summary>
    /// 第一个乱序点（该行比上一行更“新”，即时间序列不再非递增）；有序返回 -1。
    /// 主页增量插入前用它自检：一旦命中就记日志并退回整表重建，绝不把乱序留在表里。
    /// </summary>
    public static int FirstDisorderIndex(IReadOnlyList<Settlement> rows)
    {
        for (int i = 1; i < rows.Count; i++)
            if (Compare(rows[i - 1], rows[i]) > 0) return i;
        return -1;
    }

    /// <summary>整段是否已经按唯一口径降序（同键相等也算有序）。</summary>
    public static bool IsNonIncreasing(IReadOnlyList<Settlement> rows) => FirstDisorderIndex(rows) < 0;
}
