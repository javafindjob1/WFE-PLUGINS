namespace War3DeathSettlement.Core;

/// <summary>单位属性表的一行：属性名 / 显示值 / 数据来源（表格第 3 列，避免用户把“实测值”当成游戏面板原值）。</summary>
public sealed record UnitStatLine(string Name, string Value, string Source);

/// <summary>
/// 【死亡结算】右键"查看详情"用的**单位属性表**（表格数据构建，放 Core 里方便离线自检）：
///   血量 / 攻击力 / 攻击间隔 / 护甲 / 技能。
///
/// 数据来源（外部只读模式，不注入、不调游戏 native）：
///   · 血量：扫描快照（CUnit 生命链）。结算行用死前最后一次快照。
///   · 攻击力：钩子事件里"本单位作为伤害来源 + IsAttack=1"的单次伤害，显示 最小~最大/均值。
///            这是**实际打出的伤害**（已经过护甲/减伤），不是面板攻击力。
///   · 攻击间隔：上面这些攻击事件相邻时间差的中位数（0.05~5 秒内才算；避免读条/移动的长间隔）。
///   · 护甲：CUnit + 0xE0，**按 float 读**（YDWE UnitState.cpp 的 UNIT_STATE_ARMOR 把
///           4 字节原样返回给 JASS 的 real，没有 to_real；真机 E06V 的 0x430DADBB
///           = 141.679；War3Trainer 反编译的类内偏移 1.22~1.27 通用）。死亡单位读不到。
///   · 技能：钩子 Flags bit0 只能确认 Aloc（蝗虫/马甲）；其它技能外部模式看不到，显示 —。
///
/// 读不到的一律显示 "?"，绝不编数字。
/// </summary>
public static class UnitStats
{
    /// <summary>存活单位（扫描快照 + 本局钩子事件）。</summary>
    public static List<UnitStatLine> ForLive(UnitView u, IReadOnlyList<DamageHook.HookEvent>? events)
    {
        var (power, interval) = AttackMetrics(u.Addr, events);
        var list = new List<UnitStatLine>
        {
            new("血量", $"{u.Hp:0.#} / {u.HpMax:0.#}（{u.HpPercent * 100:0.#}%）",
                "扫描快照（CUnit 生命链）"),
            new("攻击力", power, "钩子事件：本单位作为伤害来源、IsAttack=1 的单次伤害"),
            new("攻击间隔", interval, "钩子事件：上述攻击事件相邻时间差的中位数"),
            new("护甲", ArmorText(u.Armor), "CUnit+0xE0（float，YDWE 位透传）"),
            new("技能", SkillText(u.Addr, events), "钩子 Flags bit0（外部模式只能识别 Aloc/蝗虫）"),
        };
        return list;
    }

    /// <summary>
    /// 已结算（死亡/消失）单位：血量用死前快照；护甲/普攻/技能用**战斗中提前记录**的值
    /// （<see cref="Settlement"/> 上的字段，由 MonitorEngine 在扫描/伤害事件到达时累积）。
    /// 老结算没有这些字段时退回本局钩子事件重算；再没有就是 ?/—。
    /// </summary>
    public static List<UnitStatLine> ForSettlement(Settlement s, IReadOnlyList<DamageHook.HookEvent>? events)
    {
        var (power, interval) = AttackMetrics(s.Addr, events);
        if (s.AttackHits > 0)
            power = $"{s.AttackMin:0.##} ~ {s.AttackMax:0.##}（{s.AttackHits} 次，均值 {s.AttackSum / s.AttackHits:0.##}）";
        if (s.AttackInterval > 0)
            interval = $"约 {s.AttackInterval:0.##} 秒（战斗中记录）";
        string skills = s.Skills.Length > 0 ? s.Skills : "—";
        var list = new List<UnitStatLine>
        {
            new("血量", $"{s.HpAtFirstSeen:0.#} / {s.HpMax:0.#}（首次见到 / 上限）",
                "结算快照（单位已死亡，实时 HP 不可读）"),
            new("攻击力", power, "战斗中记录：本单位作为伤害来源、IsAttack=1 的单次伤害"),
            new("攻击间隔", interval, "战斗中记录：上述攻击事件相邻时间差的中位数"),
            new("护甲", ArmorText(s.Armor), "战斗中记录：CUnit+0xE0（float）最后可信值"),
            new("技能", skills, "战斗中记录：钩子 Flags bit0（外部模式只能识别 Aloc/蝗虫）"),
        };
        return list;
    }

    /// <summary>
    /// 历史窗口的已结算单位（HistorySettlement DTO）：属性优先用历史库里“战斗中记录”的列；
    /// 老库没有这些列（Armor=NaN / AttackHits=0）时，用本局保存的伤害事件重算攻击力/间隔。
    /// </summary>
    public static List<UnitStatLine> ForSettlement(HistorySettlement s, IReadOnlyList<DamageHook.HookEvent>? events)
    {
        var (power, interval) = AttackMetrics(s.Addr, events);
        if (s.AttackHits > 0)
            power = $"{s.AttackMin:0.##} ~ {s.AttackMax:0.##}（{s.AttackHits} 次，均值 {s.AttackSum / s.AttackHits:0.##}）";
        if (s.AttackInterval > 0)
            interval = $"约 {s.AttackInterval:0.##} 秒（战斗中记录）";
        string skills = s.Skills.Length > 0 ? s.Skills : "—";
        return new List<UnitStatLine>
        {
            new("血量", $"{s.HpAtFirstSeen:0.#} / {s.HpMax:0.#}（首次见到 / 上限）",
                "历史结算快照（单位已死亡）"),
            new("攻击力", power, "战斗中记录：本单位作为伤害来源、IsAttack=1 的单次伤害"),
            new("攻击间隔", interval, "战斗中记录：上述攻击事件相邻时间差的中位数"),
            new("护甲", ArmorText(s.Armor), "战斗中记录：CUnit+0xE0（float）最后可信值"),
            new("技能", skills, "战斗中记录：钩子 Flags bit0（外部模式只能识别 Aloc/蝗虫）"),
        };
    }

    /// <summary>
    /// 由本局钩子事件算"实测攻击力 / 攻击间隔"。
    /// 只统计 <c>Source == unit &amp;&amp; IsAttack</c> 的伤害事件；不够 2 个间隔时攻击间隔返回 "?"。
    /// </summary>
    public static (string Power, string Interval) AttackMetrics(uint unit, IReadOnlyList<DamageHook.HookEvent>? events)
    {
        if (unit == 0 || events == null || events.Count == 0) return ("?", "?");

        var hits = new List<DamageHook.HookEvent>();
        foreach (var e in events)
        {
            if (e.Source != unit || !e.IsAttack) continue;
            if (double.IsNaN(e.Amount) || double.IsInfinity(e.Amount) || e.Amount <= 0.005) continue;
            hits.Add(e);
        }
        if (hits.Count == 0) return ("?", "?");
        hits.Sort((a, b) => a.At.CompareTo(b.At));

        double min = double.MaxValue, max = 0, sum = 0;
        foreach (var e in hits)
        {
            if (e.Amount < min) min = e.Amount;
            if (e.Amount > max) max = e.Amount;
            sum += e.Amount;
        }
        string power = $"{min:0.##} ~ {max:0.##}（{hits.Count} 次，均值 {sum / hits.Count:0.##}）";

        // 相邻攻击事件的时间差：0.05~5 秒才算“一次普攻的间隔”，更长的多半是走位/读条/停手。
        var gaps = new List<double>();
        for (int i = 1; i < hits.Count; i++)
        {
            double dt = (hits[i].At - hits[i - 1].At).TotalSeconds;
            if (dt >= 0.05 && dt <= 5.0) gaps.Add(dt);
        }
        if (gaps.Count < 2) return (power, "?");
        gaps.Sort();
        double median = gaps[gaps.Count / 2];
        return (power, $"约 {median:0.##} 秒（{gaps.Count} 个间隔）");
    }

    /// <summary>护甲显示：NaN/无穷/离谱值一律 "?"（CUnit+0xE0 在非单位内存上会读出垃圾）。</summary>
    public static string ArmorText(float armor)
    {
        if (float.IsNaN(armor) || float.IsInfinity(armor)) return "?";
        if (Math.Abs(armor) > 100000f) return "?";
        return armor.ToString("0.##");
    }

    /// <summary>技能：目前唯一能从外部确认的是 Aloc（钩子 Flags bit0，被标记为蝗虫/马甲）。</summary>
    public static string SkillText(uint unit, IReadOnlyList<DamageHook.HookEvent>? events)
    {
        if (unit == 0 || events == null) return "—";
        foreach (var e in events)
            if (e.Victim == unit && e.VictimLocust) return "Aloc（蝗虫/马甲）";
        return "—";
    }
}
