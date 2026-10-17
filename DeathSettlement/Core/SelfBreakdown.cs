namespace War3DeathSettlement.Core;

/// <summary>
/// **自己算**的伤害分组统计（完全不依赖游戏内插件日志）。
///
/// 为什么不用插件的口径：插件那四个维度（是否攻击/是否远程/攻击类型/伤害类型）
/// 只存在于**引擎的伤害事件**里 —— 插件是靠在 game.dll+0x67DC40 上挂钩子才拿到的。
/// 纯外部只读只能看到"血量变化"，拿不到那几个属性（这是原理上的限制，不是没写）。
///
/// 但"血量变化"本身信息量不小：每一笔掉血的时间、数值我们都记着（<see cref="Settlement.Events"/>），
/// 所以下面这些分组**完全由我们自己统计**，数据源只有我们观测到的事件：
///
///   * 单次伤害档位（"这一下多重"的分布）
///   * 单位类型（哪种单位在挨打、挨了多少）
///   * 拥有者（哪个玩家/阵营在挨打）
///   * 结算结局（死亡 / 消失）
///   * 受击秒（一次结算里第几秒挨了多少 —— 用来找爆发段）
/// </summary>
public static class SelfBreakdown
{
    public sealed record Row(string Dimension, string Key, int Count, double Damage, double Percent)
    {
        public override string ToString() => $"{Key}: {Count} 笔 / {Damage:0.#} ({Percent:0.#}%)";
    }

    /// <summary>单次伤害的档位（左闭右开）。</summary>
    private static readonly (string Label, double Lo, double Hi)[] Buckets =
    {
        ("0-50", 0, 50),
        ("50-200", 50, 200),
        ("200-500", 200, 500),
        ("500-1500", 500, 1500),
        ("1500-5000", 1500, 5000),
        ("5000-20000", 5000, 20000),
        ("20000+", 20000, double.MaxValue),
    };

    /// <summary>一条结算内部的档位分布（明细窗里用）。</summary>
    public static List<Row> ForSettlement(Settlement s)
    {
        var rows = new List<Row>();
        double total = s.Events.Sum(e => e.Amount);
        if (total <= 0 || s.Events.Count == 0) return rows;

        foreach (var b in Buckets)
        {
            var hits = s.Events.Where(e => e.Amount >= b.Lo && e.Amount < b.Hi).ToList();
            if (hits.Count == 0) continue;
            double dmg = hits.Sum(e => e.Amount);
            rows.Add(new Row("自己-单次伤害档位", b.Label, hits.Count, dmg, 100.0 * dmg / total));
        }

        // 受击秒：第几秒挨了多少（第一条事件的时刻算 0 秒）
        if (s.Events.Count > 1)
        {
            var t0 = s.Events[0].Time;
            foreach (var g in s.Events.GroupBy(e => (int)Math.Floor((e.Time - t0).TotalSeconds)).OrderBy(g => g.Key).Take(30))
            {
                double dmg = g.Sum(e => e.Amount);
                rows.Add(new Row("自己-受击秒", $"t+{g.Key}s", g.Count(), dmg, 100.0 * dmg / total));
            }
        }
        return rows;
    }

    /// <summary>跨结算的全局分组（伤害构成页 / CSV 用）。</summary>
    public static List<Row> Build(IReadOnlyList<Settlement> set)
    {
        var rows = new List<Row>();
        var all = set.Where(s => s.Events.Count > 0).ToList();
        if (all.Count == 0) return rows;

        double total = all.Sum(s => s.Events.Sum(e => e.Amount));
        if (total <= 0) return rows;

        // ① 单次伤害档位
        foreach (var b in Buckets)
        {
            int n = 0; double dmg = 0;
            foreach (var s in all)
                foreach (var e in s.Events)
                    if (e.Amount >= b.Lo && e.Amount < b.Hi) { n++; dmg += e.Amount; }
            if (n > 0) rows.Add(new Row("自己-单次伤害档位", b.Label, n, dmg, 100.0 * dmg / total));
        }

        // ② 单位类型（名字优先）
        foreach (var grp in all.GroupBy(s => s.UnitName.Length > 0 ? $"{s.UnitName}({s.TypeCode})" : s.TypeCode))
        {
            double dmg = grp.Sum(s => s.Events.Sum(e => e.Amount));
            rows.Add(new Row("自己-单位类型", grp.Key, grp.Sum(s => s.HitCount), dmg, 100.0 * dmg / total));
        }

        // ③ 拥有者
        foreach (var grp in all.GroupBy(s => s.OwnerSlot >= 0 ? $"P{s.OwnerSlot + 1}" : "未知"))
        {
            double dmg = grp.Sum(s => s.Events.Sum(e => e.Amount));
            rows.Add(new Row("自己-拥有者", grp.Key, grp.Sum(s => s.HitCount), dmg, 100.0 * dmg / total));
        }

        // ④ 结局（死亡 / 消失）
        foreach (var grp in all.GroupBy(s => s.Kind))
        {
            double dmg = grp.Sum(s => s.Events.Sum(e => e.Amount));
            rows.Add(new Row("自己-结局", grp.Key, grp.Sum(s => s.HitCount), dmg, 100.0 * dmg / total));
        }

        // ⑤ 每秒伤害档位（看"挨打有多密"）
        var perSec = new List<double>();
        foreach (var s in all)
        {
            if (s.Events.Count < 2) continue;
            var t0 = s.Events[0].Time;
            foreach (var g in s.Events.GroupBy(e => (int)Math.Floor((e.Time - t0).TotalSeconds)))
                perSec.Add(g.Sum(e => e.Amount));
        }
        if (perSec.Count > 0)
        {
            double secTotal = perSec.Sum();
            foreach (var b in Buckets)
            {
                var hits = perSec.Where(v => v >= b.Lo && v < b.Hi).ToList();
                if (hits.Count == 0) continue;
                double dmg = hits.Sum();
                rows.Add(new Row("自己-每秒伤害档位", b.Label, hits.Count, dmg, 100.0 * dmg / secTotal));
            }
        }

        return rows
            .OrderBy(r => DimensionOrder(r.Dimension))
            .ThenByDescending(r => r.Damage)
            .ToList();
    }

    private static int DimensionOrder(string d) => d switch
    {
        "自己-单次伤害档位" => 0,
        "自己-每秒伤害档位" => 1,
        "自己-单位类型" => 2,
        "自己-拥有者" => 3,
        "自己-结局" => 4,
        _ => 9
    };

    /// <summary>一行式摘要（CSV 用）：只放档位与拥有者，够用又不冗长。</summary>
    public static string Summary(IReadOnlyList<Settlement> set, int max = 12)
    {
        var rows = Build(set);
        if (rows.Count == 0) return "";
        return string.Join("；", rows.Take(max).Select(r => $"{r.Dimension.Replace("自己-", "")}/{r.Key}:{r.Damage:0.#}({r.Percent:0.#}%)"));
    }
}
