using System.Globalization;

namespace War3DeathSettlement.Core;

/// <summary>
/// 一只单位在**战斗过程中**持续累积的属性（不是等死亡/右键时再去读一次内存）：
///   · 护甲：每次扫描快照从 CUnit+0xE0 读到的最后一个可信值（float，YDWE UNIT_STATE_ARMOR 位透传）；
///   · 攻击力 / 攻击间隔：它作为伤害来源、IsAttack=1 的钩子事件在到达时就地累计；
///   · 技能：钩子 Flags bit0 确认过 Aloc（蝗虫/马甲）。
/// 单位死亡后内存读不到，但这些值已经存在这里，结算时拷进 <see cref="Settlement"/>，
/// 右键“单位属性”表照样显示；重启程序/换局才清空。
/// </summary>
public sealed class UnitCombatStats
{
    private const int MaxGaps = 32;
    private readonly List<double> _gaps = new(MaxGaps);
    private DateTime _lastAttackAt = DateTime.MinValue;

    /// <summary>最后一次观测到的护甲；从没读到过 = NaN。</summary>
    public float Armor { get; private set; } = float.NaN;

    public int AttackHits { get; private set; }
    public double AttackMin { get; private set; }
    public double AttackMax { get; private set; }
    public double AttackSum { get; private set; }

    /// <summary>普攻间隔中位数（秒）；不足 2 个有效间隔 = 0。</summary>
    public double AttackInterval { get; private set; }

    /// <summary>这个地址上观测到过 Aloc（蝗虫/马甲）。</summary>
    public bool Locust { get; private set; }

    public bool HasArmor => !float.IsNaN(Armor) && !float.IsInfinity(Armor);
    public bool HasAttacks => AttackHits > 0;
    public int GapCount => _gaps.Count;

    /// <summary>护甲：只接受有限、幅度合理的值（CUnit+0xE0 在非单位内存上会读出垃圾）。</summary>
    public void ObserveArmor(float armor)
    {
        if (float.IsNaN(armor) || float.IsInfinity(armor)) return;
        if (Math.Abs(armor) > 100000f) return;
        Armor = armor;
    }

    /// <summary>处理一条钩子事件（只在它是该单位的普攻来源时累计）。</summary>
    public void ObserveAttack(DamageHook.HookEvent e)
    {
        if (!e.IsAttack) return;
        if (double.IsNaN(e.Amount) || double.IsInfinity(e.Amount) || e.Amount <= 0.005) return;

        if (AttackHits == 0)
        {
            AttackMin = e.Amount;
            AttackMax = e.Amount;
        }
        else
        {
            if (e.Amount < AttackMin) AttackMin = e.Amount;
            if (e.Amount > AttackMax) AttackMax = e.Amount;
        }
        AttackSum += e.Amount;
        AttackHits++;

        // 相邻两次普攻的间隔：只收 0.05~5 秒（走位/读条/停手的长间隔不算）。
        if (_lastAttackAt != DateTime.MinValue)
        {
            double gap = (e.At - _lastAttackAt).TotalSeconds;
            if (gap >= 0.05 && gap <= 5.0)
            {
                _gaps.Add(gap);
                if (_gaps.Count > MaxGaps) _gaps.RemoveAt(0);
                AttackInterval = Median(_gaps);
            }
        }
        _lastAttackAt = e.At;
    }

    /// <summary>记录 Aloc（只增不减：技能是永久属性，换局由缓存整体清空）。</summary>
    public void ObserveLocust(bool locust)
    {
        if (locust) Locust = true;
    }

    /// <summary>把累计值拷进结算（有值才覆盖，避免把已有记录清成空）。</summary>
    public void ApplyTo(Settlement s)
    {
        if (HasArmor) s.Armor = Armor;
        if (HasAttacks)
        {
            s.AttackHits = AttackHits;
            s.AttackMin = AttackMin;
            s.AttackMax = AttackMax;
            s.AttackSum = AttackSum;
        }
        if (AttackInterval > 0) s.AttackInterval = AttackInterval;
        if (Locust && s.Skills.Length == 0) s.Skills = "Aloc（蝗虫/马甲）";
    }

    /// <summary>属性表里的攻击力文本；没观测到普攻时返回空串。</summary>
    public string AttackPowerText()
    {
        if (!HasAttacks) return "";
        double avg = AttackSum / AttackHits;
        return $"{AttackMin:0.##} ~ {AttackMax:0.##}（{AttackHits} 次，均值 {avg:0.##}）";
    }

    /// <summary>属性表里的攻击间隔文本；间隔不足时返回空串。</summary>
    public string AttackIntervalText() =>
        AttackInterval > 0
            ? string.Create(CultureInfo.InvariantCulture, $"约 {AttackInterval:0.##} 秒（{_gaps.Count} 个间隔）")
            : "";

    private static double Median(List<double> values)
    {
        if (values.Count == 0) return 0;
        var copy = new List<double>(values);
        copy.Sort();
        return copy[copy.Count / 2];
    }
}

/// <summary>
/// 地址 → 战斗属性缓存（监视线程写，界面线程只在“清空会话”时读/清）。
/// 缓存按 CUnit 对象地址索引；同一地址被新单位复用、或换局时整体清空。
/// </summary>
public sealed class UnitCombatStatsCache
{
    private readonly Dictionary<uint, UnitCombatStats> _map = new();
    private readonly object _gate = new();

    public int Count
    {
        get { lock (_gate) return _map.Count; }
    }

    public UnitCombatStats GetOrCreate(uint addr)
    {
        lock (_gate)
        {
            if (!_map.TryGetValue(addr, out var stats))
            {
                stats = new UnitCombatStats();
                _map[addr] = stats;
            }
            return stats;
        }
    }

    public bool TryGet(uint addr, out UnitCombatStats stats)
    {
        lock (_gate)
        {
            if (_map.TryGetValue(addr, out var found))
            {
                stats = found;
                return true;
            }
        }
        stats = null!;
        return false;
    }

    /// <summary>换局/清空历史时整体清掉（地址复用后旧属性不能串到新单位）。</summary>
    public void Clear()
    {
        lock (_gate) _map.Clear();
    }
}
