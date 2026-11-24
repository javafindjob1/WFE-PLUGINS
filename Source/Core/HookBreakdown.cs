namespace War3DeathSettlement.Core;

/// <summary>
/// 用**侵入式钩子**采到的引擎伤害事件做分组统计（这条路径不需要插件日志）。
///
/// 一条事件里有三种伤害（顺序固定），另加一个净掉血：
///   原始伤害 = 引擎伤害结构体 +0x10（伤害函数入口抄的，地图/引擎都还没动）
///   引擎伤害 = GetEventDamage 的**首值**（第一次返回值，地图还没改）
///   地图伤害 = 生效值（含末值；地图 SetEventDamage 改过用改后，否则用引擎末值，抓不到退回血差）
///   净掉血 = 血差（本层净值，嵌套扣内层）
/// 这四个维度一律用**数字**分组：是否攻击 0/1、是否远程 0/1、攻击类型、伤害类型。
/// </summary>
public static class HookBreakdown
{
    /// <summary>一个维度分组（Dimension 是维度名，Key 是数字/名字）。</summary>
    public sealed record Row(string Dimension, string Key, int Count,
                             double Damage, double Engine, bool EngineValid,
                             double Effective, bool EffectiveValid,
                             double NetDrop, bool NetValid, double Percent)
    {
        public override string ToString() =>
            $"{Key}: {Count} 笔 / 原始 {Damage:0.00}" +
            (EngineValid ? $" / 引擎 {Engine:0.00}" : "") +
            (EffectiveValid ? $" / 地图 {Effective:0.00}" : "") +
            (NetValid ? $" / 净掉血 {NetDrop:0.00}" : "") +
            $" ({Percent:0.0}%)";
    }

    /// <summary>来源汇总行：**一行 = 一个伤害来源**。</summary>
    public sealed record SourceRow(string Source, int Count, double Damage,
                                   double Engine, bool EngineValid,
                                   double Effective, bool EffectiveValid,
                                   double NetDrop, bool NetValid, double Percent)
    {
        /// <summary>该来源的单位类型码（JASS 4 字符，用于游戏内头像解析）；空表示未知。</summary>
        public string SourceCode { get; init; } = "";

        /// <summary>该来源最近一次钩子事件的 CUnit 地址；0 表示未知。</summary>
        public uint SourceAddr { get; init; }

        public override string ToString() =>
            $"{Source}: {Count} 笔 / 原始 {Damage:0.00}" +
            (EngineValid ? $" / 引擎 {Engine:0.00}" : "") +
            (EffectiveValid ? $" / 地图 {Effective:0.00}" : "") +
            (NetValid ? $" / 净掉血 {NetDrop:0.00}" : "") +
            $" ({Percent:0.0}%)";
    }

    /// <summary>
    /// 组合行：**一行 = 一个（来源 × 是否攻击 × 是否远程 × 攻击类型 × 伤害类型）组合**。
    /// 四维全部是数字（0/1、类型号），不再转成中文/带名字的标签。
    /// </summary>
    public sealed record Combination(
        string Source, string IsAttack, string IsRanged, string AttackType, string DamageType,
        int Count, double Damage, double Engine, bool EngineValid,
        double Effective, bool EffectiveValid,
        double NetDrop, bool NetValid, double Percent)
    {
        public string SourceCode { get; init; } = "";
        public uint SourceAddr { get; init; }

        public override string ToString() =>
            $"{Source}/攻击{IsAttack}/远程{IsRanged}/攻类型{AttackType}/伤类型{DamageType}: " +
            $"{Count} 笔 / 原始 {Damage:0.00}" +
            (EngineValid ? $" / 引擎 {Engine:0.00}" : "") +
            (EffectiveValid ? $" / 地图 {Effective:0.00}" : "") +
            (NetValid ? $" / 净掉血 {NetDrop:0.00}" : "");
    }

    // ------------------------------------------------------------------
    /// <summary>一个分组里的求和：引擎(首值)/地图(生效值)/净掉血 都用**每笔事件**的真值，没有就退回 dmg×scale。</summary>
    private static (double Engine, bool EngValid, double Effective, bool EffValid, double NetDrop, bool NetValid) Sum5(
        IEnumerable<DamageHook.HookEvent> group, double dmg, double scale)
    {
        double eng = 0, eff = 0, net = 0;
        bool engOk = false, effOk = false, netOk = false;
        foreach (var e in group)
        {
            if (e.EngineValueValid) { eng += e.EngineValue; engOk = true; }
            if (e.EffectiveValid) { eff += e.EffectiveDamage; effOk = true; }
            // 净掉血同样**逐笔**取真值：读不到血的那笔按 dmg×scale 估。
            // 逐笔（而不是整组）退回，才能保证不管怎么分组，Σ行的净掉血都等于整条结算的 Σ净掉血。
            net += EventNet(e, scale);
            if (e.HpValid) netOk = true;
        }
        if (!effOk) eff = dmg * scale;
        return (eng, engOk, eff, effOk, net, netOk);
    }

    /// <summary>一笔事件的净掉血：有血差用血差，读不到就按 原始伤害×折算系数 估。</summary>
    private static double EventNet(DamageHook.HookEvent e, double scale) =>
        e.HpValid ? e.Actual : e.Amount * scale;

    /// <summary>
    /// 整条结算的 **Σ净掉血**。逐笔累加、与怎么分组无关 ——
    /// Σ 来源行和组合行共用这一个分母，两边的百分比都能加回 100%。
    /// </summary>
    private static double NetTotal(IReadOnlyList<DamageHook.HookEvent> evs, double scale)
    {
        double sum = 0;
        foreach (var e in evs) sum += EventNet(e, scale);
        return sum;
    }

    /// <summary>
    /// 占比口径（用户要求）：**占比 = 该行净掉血 ÷ 整条结算的 Σ净掉血**。
    /// 原始伤害只在该结算 Σ净掉血 &lt;= 0（整条都没有可信血量）时兜底，避免整表全 0%。
    /// </summary>
    private static double PercentOf(double net, double raw, double netTotal, double rawTotal)
    {
        if (netTotal > 0) return 100.0 * net / netTotal;
        return rawTotal > 0 ? 100.0 * raw / rawTotal : 0.0;
    }

    private static double ClampScale(double scale)
    {
        if (double.IsNaN(scale) || double.IsInfinity(scale) || scale <= 0) return 1.0;
        return Math.Clamp(scale, 0.2, 5.0);
    }

    private static bool SourceIsIllusion(DamageHook.HookEvent e,
                                         Func<uint, string?, bool>? isIllusionOf) =>
        e.SourceIllusion ||
        (e.Source != 0 && isIllusionOf?.Invoke(e.Source, e.SourceCode) == true);

    private static string SourceLabel(string text, bool illusion)
    {
        text = Wc3Text.Clean(text);
        if (!illusion || text.Contains("（镜像）", StringComparison.Ordinal) ||
            text.Contains("(镜像)", StringComparison.Ordinal))
            return text;
        return text + "（镜像）";
    }

    private static string SourceTextOf(DamageHook.HookEvent e,
                                       Func<DamageHook.HookEvent, string>? sourceLabelOf) =>
        sourceLabelOf?.Invoke(e) ?? e.SourceText;

    /// <summary>按**伤害来源**单独汇总。</summary>
    public static List<SourceRow> Sources(IReadOnlyList<DamageHook.HookEvent> evs, double scale = 1.0, int max = 20,
                                          Func<uint, string?, bool>? isIllusionOf = null,
                                          Func<DamageHook.HookEvent, string>? sourceLabelOf = null)
    {
        var list = new List<SourceRow>();
        if (evs == null || evs.Count == 0) return list;
        scale = ClampScale(scale);

        double total = evs.Sum(e => e.Amount);
        double netTotal = NetTotal(evs, scale);

        foreach (var g in evs.GroupBy(e => new
                 {
                     SourceText = SourceTextOf(e, sourceLabelOf),
                     Illusion = SourceIsIllusion(e, isIllusionOf)
                 }).OrderByDescending(g => g.Sum(e => e.Amount)).Take(max))
        {
            double dmg = g.Sum(e => e.Amount);
            var (eng, engOk, eff, effOk, net, netOk) = Sum5(g, dmg, scale);
            string code = g.Select(e => e.SourceCode).FirstOrDefault(c => !string.IsNullOrEmpty(c)) ?? "";
            uint sourceAddr = g.Select(e => e.Source).FirstOrDefault(a => a != 0);
            list.Add(new SourceRow(SourceLabel(g.Key.SourceText, g.Key.Illusion),
                                   g.Count(), dmg, eng, engOk, eff, effOk, net, netOk,
                                   PercentOf(net, dmg, netTotal, total))
                     { SourceCode = code, SourceAddr = sourceAddr });
        }
        return list;
    }

    /// <summary>生成组合行（四维用数字）。</summary>
    public static List<Combination> Combinations(IReadOnlyList<DamageHook.HookEvent> evs,
                                                Func<string, string>? nameOf = null,
                                                double scale = 1.0, int max = 40,
                                                Func<uint, string?, bool>? isIllusionOf = null,
                                                Func<DamageHook.HookEvent, string>? sourceLabelOf = null)
    {
        var list = new List<Combination>();
        if (evs == null || evs.Count == 0) return list;
        scale = ClampScale(scale);

        double total = evs.Sum(e => e.Amount);
        double netTotal = NetTotal(evs, scale);

        var groups = evs.GroupBy(e => new
        {
            Source = SourceTextOf(e, sourceLabelOf),
            Illusion = SourceIsIllusion(e, isIllusionOf),
            Attack = e.IsAttack ? "1" : "0",
            Ranged = e.IsRanged ? "1" : "0",
            AT = e.AttackType.ToString(),
            DT = e.DamageType >= 0 ? e.DamageType.ToString() : "0x" + e.DamageMask.ToString("X")
        }).OrderByDescending(g => g.Sum(e => e.Amount)).Take(max);

        foreach (var g in groups)
        {
            double dmg = g.Sum(e => e.Amount);
            var (eng, engOk, eff, effOk, net, netOk) = Sum5(g, dmg, scale);
            string code = g.Select(e => e.SourceCode).FirstOrDefault(c => !string.IsNullOrEmpty(c)) ?? "";
            uint sourceAddr = g.Select(e => e.Source).FirstOrDefault(a => a != 0);
            list.Add(new Combination(SourceLabel(g.Key.Source, g.Key.Illusion),
                                     g.Key.Attack, g.Key.Ranged, g.Key.AT, g.Key.DT,
                                     g.Count(), dmg, eng, engOk, eff, effOk, net, netOk,
                                     PercentOf(net, dmg, netTotal, total))
                     { SourceCode = code, SourceAddr = sourceAddr });
        }
        return list;
    }

    /// <summary>把一批事件按 5 个维度 + 组合分出组来（百分比按净掉血算，四维用数字）。</summary>
    public static List<Row> Build(IReadOnlyList<DamageHook.HookEvent> evs,
                                  Func<string, string>? nameOf = null, int comboMax = 12, double scale = 1.0,
                                  Func<uint, string?, bool>? isIllusionOf = null,
                                  Func<DamageHook.HookEvent, string>? sourceLabelOf = null)
    {
        var rows = new List<Row>();
        if (evs == null || evs.Count == 0) return rows;
        scale = ClampScale(scale);

        double total = evs.Sum(e => e.Amount);
        double netTotal = NetTotal(evs, scale);

        void Add(string dim, Func<DamageHook.HookEvent, string> keyOf, int max = 999)
        {
            foreach (var g in evs.GroupBy(keyOf).OrderByDescending(g => g.Sum(e => e.Amount)).Take(max))
            {
                double dmg = g.Sum(e => e.Amount);
                var (eng, engOk, eff, effOk, net, netOk) = Sum5(g, dmg, scale);
                rows.Add(new Row(dim, g.Key, g.Count(), dmg, eng, engOk, eff, effOk, net, netOk,
                                 PercentOf(net, dmg, netTotal, total)));
            }
        }

        string Dt(DamageHook.HookEvent e) =>
            e.DamageType >= 0 ? e.DamageType.ToString() : "0x" + e.DamageMask.ToString("X");

        Add("钩子-来源", e => SourceLabel(SourceTextOf(e, sourceLabelOf), SourceIsIllusion(e, isIllusionOf)));
        Add("钩子-是否攻击", e => e.IsAttack ? "1" : "0");
        Add("钩子-是否远程", e => e.IsRanged ? "1" : "0");
        Add("钩子-攻击类型", e => e.AttackType.ToString());
        Add("钩子-伤害类型", e => Dt(e));
        // 组合明细：**来源 × 攻击类型 × 伤害类型 × 是否攻击 × 是否远程**
        Add("钩子-组合", e => $"{SourceLabel(SourceTextOf(e, sourceLabelOf), SourceIsIllusion(e, isIllusionOf))}/{e.AttackType}/{Dt(e)}/{(e.IsAttack ? "1" : "0")}/{(e.IsRanged ? "1" : "0")}", comboMax);

        return rows;
    }

    /// <summary>一行式摘要。</summary>
    public static string Summary(IReadOnlyList<HookBreakdown.Row> rows, int max = 10)
    {
        if (rows == null || rows.Count == 0) return "";
        return string.Join("；", rows.Take(max).Select(r =>
            $"{r.Dimension.Replace("钩子-", "")}/{r.Key}:{r.Damage:0.00}({r.Percent:0.#}%)"));
    }
}
