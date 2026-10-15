using System.Globalization;
using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>一次“掉血”记录（由两次轮询的生命差得到）。</summary>
public sealed class DamageEvent
{
    public DateTime Time { get; init; }
    public double Amount { get; init; }
    public double HpAfter { get; init; }
    public bool Fatal { get; init; }
}

/// <summary>一个单位实例的生命周期账本。</summary>
public sealed class UnitTrack
{
    public uint Addr { get; init; }
    public string TypeCode { get; set; } = "";
    public int OwnerSlot { get; set; } = -1;

    public DateTime FirstSeen { get; set; }
    public DateTime LastSeen { get; set; }
    public float LastHp { get; set; }
    public float LastHpMax { get; set; }
    public float StartHpMax { get; set; }
    public float X { get; set; }
    public float Y { get; set; }

    public readonly List<DamageEvent> Events = new();
    public double TotalDamage { get; set; }
    public double TotalHeal { get; set; }
    public double MaxHit { get; set; }
    public double MinHit { get; set; } = double.MaxValue;
    public DateTime? FirstHit { get; set; }
    public DateTime? LastHit { get; set; }
    public bool Dead { get; set; }
    public bool Gone { get; set; }
    public int InstanceIndex { get; set; } = 1;

    public TimeSpan CombatSpan => (FirstHit.HasValue && LastHit.HasValue) ? LastHit.Value - FirstHit.Value : TimeSpan.Zero;

    public void ResetForNewInstance(DateTime now, ScannedUnit u)
    {
        InstanceIndex++;
        TypeCode = u.TypeCode;
        OwnerSlot = u.OwnerSlot;
        FirstSeen = LastSeen = now;
        LastHp = u.Hp;
        LastHpMax = u.HpMax;
        StartHpMax = u.HpMax;
        Events.Clear();
        TotalDamage = TotalHeal = MaxHit = 0;
        MinHit = double.MaxValue;
        FirstHit = LastHit = null;
        Dead = Gone = false;
    }
}

/// <summary>
/// 死亡结算：一个单位死亡（或消失）时，把它这一条命的受伤账一次性算清。
/// 口径与游戏内插件 UDamageWatcher 的“死亡结算”一致：次数 + 总伤害 + 单次统计 + 每秒受伤。
/// 差别：纯外部只读拿不到“伤害来源单位 / 攻击类型 / 伤害类型”，那三样需要游戏内钩子。
/// </summary>
public sealed class Settlement
{
    public uint Addr { get; init; }
    public string TypeCode { get; init; } = "";
    public int OwnerSlot { get; init; } = -1;
    public int InstanceIndex { get; init; } = 1;
    public DateTime DiedAt { get; init; }
    public DateTime FirstSeen { get; init; }
    public DateTime? FirstHit { get; init; }
    public DateTime? LastHit { get; init; }
    public int HitCount { get; init; }
    public double TotalDamage { get; init; }
    public double TotalHeal { get; init; }
    public double MaxHit { get; init; }
    public double MinHit { get; init; }
    public double HpMax { get; init; }
    /// <summary>1 秒窗口内最大承伤（“最惨的一秒”）。</summary>
    public double Peak1s { get; init; }
    public float X { get; init; }
    public float Y { get; init; }
    /// <summary>死亡 = 血量归零；消失 = 单位被销毁/移出游戏（读不到生命）。</summary>
    public string Kind { get; init; } = "死亡";
    public IReadOnlyList<DamageEvent> Events { get; init; } = Array.Empty<DamageEvent>();

    public double LifetimeSeconds => Math.Max(0, (DiedAt - FirstSeen).TotalSeconds);
    public double CombatSeconds => (FirstHit.HasValue && LastHit.HasValue)
        ? Math.Max(0.001, (LastHit.Value - FirstHit.Value).TotalSeconds) : 0;
    public double AvgHit => HitCount > 0 ? TotalDamage / HitCount : 0;
    public double DpsCombat => CombatSeconds > 0 ? TotalDamage / CombatSeconds : 0;
    public double MinHitSafe => HitCount > 0 && MinHit < double.MaxValue ? MinHit : 0;

    public string OwnerText => OwnerSlot >= 0 ? $"玩家 {OwnerSlot + 1}" : "?";

    /// <summary>标题行：`[结算] 类型码 死亡结算 N 次 / 总伤害`（对齐游戏内插件的中文样式）。</summary>
    public string TitleLine() =>
        $"[结算] {TypeCode} ({OwnerText}) {Kind}结算 {HitCount} 次 / {TotalDamage:0.#}";

    public IEnumerable<string> DetailLines()
    {
        yield return $"  存活 {LifetimeSeconds:0.0} 秒（首次发现 → {Kind}）" +
                     (CombatSeconds > 0 ? $"，战斗 {CombatSeconds:0.0} 秒（首次受击 → 最后一次受击）" : "");
        yield return $"  最大生命 {HpMax:0.#}，秒伤(战斗期) {DpsCombat:0.#}";
        yield return $"  单次伤害：最大 {MaxHit:0.#} / 最小 {MinHitSafe:0.#} / 平均 {AvgHit:0.#}";
        yield return $"  最惨的 1 秒：{Peak1s:0.#}";
        yield return $"  受击 {HitCount} 次，期间治疗 {TotalHeal:0.#}";
        if (Math.Abs(X) > 0.01f || Math.Abs(Y) > 0.01f)
            yield return $"  结算坐标 ({X:0.#}, {Y:0.#})";
        yield return "  伤害来源：纯外部只读模式无法归因（需要游戏内钩子）；本结算按血量差累计。";
    }

    public string ToText()
    {
        var sb = new StringBuilder();
        sb.AppendLine(TitleLine());
        foreach (var l in DetailLines()) sb.AppendLine(l);
        if (Events.Count > 0)
        {
            sb.AppendLine("  明细（时间 / 伤害 / 剩余生命）：");
            foreach (var e in Events)
                sb.AppendLine($"    {e.Time:HH:mm:ss.fff}  -{e.Amount:0.#}  剩 {e.HpAfter:0.#}{(e.Fatal ? "  ← 致命" : "")}");
        }
        return sb.ToString();
    }

    public static string CsvHeader =>
        "时间,类型码,拥有者,结局,实例,受击次数,总伤害,最大单次,最小单次,平均单次,最惨1秒,最大生命,存活秒,战斗秒,秒伤,治疗量,X,Y";

    public string ToCsvRow()
    {
        var c = CultureInfo.InvariantCulture;
        return string.Join(",",
            DiedAt.ToString("yyyy-MM-dd HH:mm:ss.fff", c),
            TypeCode,
            OwnerSlot >= 0 ? (OwnerSlot + 1).ToString(c) : "",
            Kind,
            InstanceIndex.ToString(c),
            HitCount.ToString(c),
            TotalDamage.ToString("0.##", c),
            MaxHit.ToString("0.##", c),
            MinHitSafe.ToString("0.##", c),
            AvgHit.ToString("0.##", c),
            Peak1s.ToString("0.##", c),
            HpMax.ToString("0.##", c),
            LifetimeSeconds.ToString("0.0", c),
            CombatSeconds.ToString("0.0", c),
            DpsCombat.ToString("0.#", c),
            TotalHeal.ToString("0.##", c),
            X.ToString("0.#", c),
            Y.ToString("0.#", c));
    }
}
