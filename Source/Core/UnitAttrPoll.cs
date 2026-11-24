namespace War3DeathSettlement.Core;

/// <summary>
/// 【战场单位】ddh 属性请求的轮询调度 + 覆盖率统计（GUI 与无界面模式共用）。
///
/// 旧逻辑每轮都把“存活 + 最近受击”排在最前、只取前 64 个地址；单位一多，排在后面的
/// 永远轮不到 → 界面一直是 <c>?</c>（真机日志里根本没有那些地址的 <c>ATTR unit</c> 行）。
/// 现在改成：
///   · 全部**存活**单位按地址排成一个稳定的轮询队列（死亡对象不占槽位）；
///   · 游标从队列里连续取 <see cref="UnitAttrWire.SlotCount"/> 个，到尾回绕，
///     保证 ceil(M/96) 轮内每个单位都被请求过；
///   · 取出的这一批再按“存活优先 + 最近受击”排序，只决定写进请求槽的先后，不会饿死谁。
/// 另外每 <see cref="CoverageLogIntervalMs"/> 毫秒写一行覆盖率日志，便于确认真在轮询。
/// </summary>
public sealed class UnitAttrPoller
{
    /// <summary>覆盖率日志间隔（毫秒）；第一轮立即写一行（10 秒的冒烟也能看到）。</summary>
    public const int CoverageLogIntervalMs = 30_000;

    private readonly HashSet<uint> _requested = new();
    private readonly HashSet<uint> _answered = new();
    private int _cursor;
    private int _lastRoundCount;
    private int _rounds;
    private long _lastLogTick = long.MinValue;
    private int _lastLoggedTotal = -1;

    /// <summary>下一轮从稳定队列的哪个位置开始（自检/日志用）。</summary>
    public int Cursor => _cursor;

    /// <summary>已经真正写进 ddh 请求槽的轮数。</summary>
    public int Rounds => _rounds;

    /// <summary>本局累计请求过多少个不同地址（含已经不在场上的）。</summary>
    public int RequestedCount => _requested.Count;

    /// <summary>本局累计有多少个地址回过 flags 非 0 的属性。</summary>
    public int AnsweredCount => _answered.Count;

    /// <summary>最近一轮实际请求的地址个数（= 本轮日志里的“本轮 N 个”）。</summary>
    public int LastRoundCount => _lastRoundCount;

    /// <summary>换进程/重连时整体复位（地址会复用，旧的覆盖统计不能带过来）。</summary>
    public void Reset()
    {
        _cursor = 0;
        _lastRoundCount = 0;
        _rounds = 0;
        _lastLogTick = long.MinValue;
        _lastLoggedTotal = -1;
        _requested.Clear();
        _answered.Clear();
    }

    /// <summary>
    /// 本轮要写进 ddh 请求槽的地址：全部单位按地址排序后从游标连续取 max 个、循环回绕；
    /// 取出的这一批再按“存活优先 → 最近受击 → 累计承伤 → 地址”排序（只影响槽位顺序）。
    /// 单位数为 0 时返回空表且游标归零。
    /// </summary>
    public List<uint> PickRound(IReadOnlyList<UnitView> units, int max)
    {
        _lastRoundCount = 0;
        if (units == null || units.Count == 0 || max <= 0)
        {
            _cursor = 0;
            return new List<uint>();
        }

        // 稳定队列：按地址排序 + 去重（同一地址出现多行也只请求一次）。
        // 只请求**活着**的单位：Hp<=0 是已经死亡/正在销毁的对象，prop/句柄都可能是空的，
        // 请求了也只会回 flags=0（界面永远 ?），还白占槽位。单位页也只显示活着的。
        var all = units.Where(u => u.Addr != 0 && u.Hp > 0f)
                       .GroupBy(u => u.Addr)
                       .Select(g => g.First())
                       .OrderBy(u => u.Addr)
                       .ToList();
        if (all.Count == 0)
        {
            _cursor = 0;
            return new List<uint>();
        }

        if (_cursor < 0 || _cursor >= all.Count) _cursor = 0;
        int take = Math.Min(max, all.Count);
        var window = new List<UnitView>(take);
        for (int i = 0; i < take; i++) window.Add(all[(_cursor + i) % all.Count]);
        _cursor = (_cursor + take) % all.Count;

        var addrs = window.OrderByDescending(u => u.Hp > 0f ? 1 : 0)
                          .ThenByDescending(u => u.LastHit ?? DateTime.MinValue)
                          .ThenByDescending(u => u.Taken)
                          .ThenBy(u => u.Addr)
                          .Select(u => u.Addr)
                          .ToList();
        _lastRoundCount = addrs.Count;
        return addrs;
    }

    /// <summary>真正写进共享内存后才记账（RequestUnitAttrs 拒绝时不能算覆盖）。</summary>
    public void MarkRequested(IEnumerable<uint> addrs)
    {
        if (addrs == null) return;
        foreach (var a in addrs)
            if (a != 0) _requested.Add(a);
        _rounds++;
    }

    /// <summary>ddh 回写了 flags 非 0 的属性才算“拿到过属性”（flags=0 的槽仍是 ?）。</summary>
    public void MarkAnswered(IEnumerable<UnitAttrResponse> responses)
    {
        if (responses == null) return;
        foreach (var r in responses)
            if (r.Addr != 0 && r.Flags != 0) _answered.Add(r.Addr);
    }

    /// <summary>
    /// 该不该写覆盖率日志。规则：
    ///   · 第一次有单位时立即写一行（10 秒的冒烟也能看到）；
    ///   · 之后每 <see cref="CoverageLogIntervalMs"/> 毫秒写一行；
    ///   · 场上单位数比上次日志时多，且距上次日志 ≥2 秒，也补写一行 —— 开局扫描通常
    ///     先只看到 2~3 个单位，若死等 30 秒，日志会一直停在 “2/2”，看起来像没轮询。
    /// </summary>
    public bool ShouldLog(long nowMs, int liveCount)
    {
        if (_lastLogTick == long.MinValue)
        {
            _lastLogTick = nowMs;
            _lastLoggedTotal = liveCount;
            return true;
        }
        long elapsed = nowMs - _lastLogTick;
        bool interval = elapsed >= CoverageLogIntervalMs;
        bool growth = liveCount > _lastLoggedTotal && elapsed >= 2000;
        if (!interval && !growth) return false;
        _lastLogTick = nowMs;
        _lastLoggedTotal = liveCount;
        return true;
    }

    /// <summary>
    /// 覆盖率日志：<c>属性请求：本轮 96 个，累计已覆盖 N/M 个单位</c>。
    /// 只统计**当前还活着、还在场上**的地址，保证 N ≤ M；有单位回过 flags 非 0 的属性时
    /// 再追加 <c>（已回属性 K 个）</c>（K 小于 N 说明 ddh 还没解析出来/该单位字段全 invalid，
    /// 界面会显示 ?）。
    /// </summary>
    public string CoverageLine(IReadOnlyList<UnitView> units)
    {
        var live = new HashSet<uint>();
        if (units != null)
            foreach (var u in units)
                if (u.Addr != 0 && u.Hp > 0f) live.Add(u.Addr);

        int covered = _requested.Count(live.Contains);
        int answered = _answered.Count(live.Contains);
        string line = $"属性请求：本轮 {_lastRoundCount} 个，累计已覆盖 {covered}/{live.Count} 个单位";
        if (answered > 0) line += $"（已回属性 {answered} 个）";
        return line;
    }
}
