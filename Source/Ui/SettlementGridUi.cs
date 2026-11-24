using War3DeathSettlement.Core;

namespace War3DeathSettlement.Ui;

/// <summary>
/// 【死亡结算】页和【历史】窗口共用的列定义 / 行渲染：
/// 列序、列宽、行单元格与主页完全一致；分组统计（Σ 来源 + 组合）也只在这里拼，避免两处走样。
/// </summary>
internal static class SettlementGridUi
{
    // 【死亡结算】表的列名/表头/单元格下标：主页与【历史】的表头搜索、过滤谓词共用，
    // 避免两处各写一份 "name"/"code"/1/2 后走样。
    public const string NameColumn = "name";
    public const string CodeColumn = "code";
    public const string NameHeader = "单位名称";
    public const string CodeHeader = "类型码";
    public const int NameCellIndex = 1;
    public const int CodeCellIndex = 2;

    /// <summary>死亡结算表：14 列（时间 / 单位名称 / 类型码 / 单位ID / 玩家 / 结局 / 实例 / 受击 / 总伤害 / 最大单次 / 最惨1秒 / 秒伤 / 存活s / 战斗s）。</summary>
    public static void AddColumns(Grid g)
    {
        // 时间只留够 12 个字符（16:15:16.827）的宽度；**不再让它单独 Fill** ——
        // 以前只有这一列 Fill，窗口一宽时间列就被拉成三五百像素，右边一片空白，很难看。
        g.AddText("时间", "t", 96);
        g.AddText(NameHeader, NameColumn, 110);
        // 110（而不是原来的 80）：类型码列也要放得下过滤指示 类型码（⌕ cp），
        // 否则 80px 会把右括号裁掉，看不出“这一列正在过滤”。
        g.AddText(CodeHeader, CodeColumn, 110);
        g.AddText("单位ID", "id", 110);
        g.AddText("玩家", "owner", 70);
        g.AddText("结局", "kind", 60);
        g.AddText("实例", "inst", 50);
        g.AddText("受击", "hits", 55);
        g.AddText("总伤害", "total", 90);
        g.AddText("最大单次", "max", 90);
        g.AddText("最惨1秒", "peak", 90);
        g.AddText("秒伤", "dps", 80);
        g.AddText("存活s", "life", 70);
        g.AddText("战斗s", "combat", 70);

        // 所有列按设计宽度等比例 Fill：窗口变宽时大家一起变宽，既不会把某一列拉得难看，
        // 也不会把最后一列挤出视口（分组统计表用同一套规则）。
        foreach (DataGridViewColumn col in g.Columns)
        {
            col.AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
            col.FillWeight = Math.Max(8, col.Width);
            col.MinimumWidth = 40;
        }
        g.Columns["t"]!.MinimumWidth = 88;
    }

    /// <summary>
    /// 表头搜索的单值谓词：不区分大小写的**模糊（按字符顺序）**匹配；空关键词 = 不过滤（全部通过）。
    /// 规则：关键词的每个字符都必须按顺序出现在单元格文本里，**不要求连续**。
    /// 例：<c>星</c> 命中 <c>星之真神</c>；<c>星神</c> 也命中 <c>星之真神</c>（星…神）；<c>神星</c> 不命中。
    /// 单元格值为 null 时，只有空关键词才算命中。
    /// </summary>
    public static bool MatchesCellValue(object? value, string? keyword)
    {
        if (string.IsNullOrEmpty(keyword)) return true;
        string? text = value?.ToString();
        if (string.IsNullOrEmpty(text)) return false;

        int matched = 0;
        foreach (char c in text)
        {
            if (char.ToUpperInvariant(c) == char.ToUpperInvariant(keyword[matched]))
            {
                matched++;
                if (matched == keyword.Length) return true;
            }
        }
        return false;
    }

    /// <summary>
    /// “名称类”列的单值谓词：**名字 或 称谓 任一命中就算命中**。
    /// 称谓（英雄 Propernames，ddh v12 属性响应的 Title）与名称合并显示：
    /// 死亡结算的「单位名称」、伤害事件的「触发单位 / 伤害来源」都用它；
    /// 称谓为空（非英雄 / 从没被属性请求覆盖过 / 老历史数据）时退化成纯名字匹配，不会误伤。
    /// 模糊规则与 <see cref="MatchesCellValue"/> 完全一致（不区分大小写、按字符顺序）。
    /// </summary>
    public static bool MatchesNameOrTitle(object? nameValue, string? title, string? keyword) =>
        MatchesCellValue(nameValue, keyword) || MatchesCellValue(title, keyword);

    /// <summary>
    /// 两列（单位名 / 类型码）同时过滤时的组合谓词：AND（任一列没命中就排除）。
    /// nameTitle = 单位名这一列额外参与搜索的称谓（可不填 = 纯名字；老库/没覆盖到单位时就是空）。
    /// </summary>
    public static bool MatchesRowValues(object? nameValue, object? codeValue,
                                        string? nameKeyword, string? codeKeyword,
                                        string? nameTitle = null) =>
        MatchesNameOrTitle(nameValue, nameTitle, nameKeyword) &&
        MatchesCellValue(codeValue, codeKeyword);

    /// <summary>表头文字 + 过滤指示：有过滤 → <c>单位名（⌕ abc）</c>，没有 → 原表头。</summary>
    public static string HeaderText(string baseHeader, string? keyword) =>
        string.IsNullOrEmpty(keyword) ? baseHeader : $"{baseHeader}（⌕ {keyword}）";

    /// <summary>分组统计表：12 列（单位 / 伤害来源 / 是否攻击 / 是否远程 / 攻击类型 / 伤害类型 / 笔数 / 原始 / 引擎 / 地图 / 净掉血 / 占比）。</summary>
    public static void AddBreakdownColumns(Grid g)
    {
        g.AddText("单位", "unit", 95);
        g.AddText("伤害来源", "src", 90);
        g.AddText("是否攻击", "atk", 66);
        g.AddText("是否远程", "rng", 66);
        g.AddText("攻击类型", "atype", 70);
        g.AddText("伤害类型", "dtype", 70);
        g.AddText("笔数", "count", 42);
        g.AddText("原始伤害", "raw", 68);
        g.AddText("引擎伤害", "eng", 68);
        g.AddText("地图伤害", "eff", 68);
        g.AddText("净掉血", "net", 68);
        g.AddText("占比", "pct", 45);

        // 列宽按设计宽度等比例 Fill（只让一列 Fill 会把最后一列挤出视口，见主页注释）。
        foreach (DataGridViewColumn col in g.Columns)
        {
            col.AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
            col.FillWeight = Math.Max(8, col.Width);
            col.MinimumWidth = 40;
        }
    }

    /// <summary>名称列统一格式：有称谓时“称谓 + 单位名”，否则单位名，再退类型码。</summary>
    public static string UnitDisplayName(string? name, string? title, string? code)
        => Wc3Text.UnitIdentity(name, title, code);

    public static string AppendMirrorSuffix(string text, bool illusion)
    {
        if (!illusion || text.Contains("（镜像）", StringComparison.Ordinal) ||
            text.Contains("(镜像)", StringComparison.Ordinal))
            return text;
        return text + "（镜像）";
    }

    /// <summary>实时结算行 → 14 格（列序与 AddColumns 一致）。</summary>
    public static object[] Cells(Settlement s, string? title = null, string? nameOverride = null,
                                 int? ownerSlotOverride = null) => new object[]
    {
        s.DiedAt.ToString("HH:mm:ss.fff"),
        UnitDisplayName(nameOverride is { Length: > 0 } ? nameOverride : s.UnitName, title, s.TypeCode),
        s.TypeCode,
        UnitEvents.FormatAddr(s.Addr),
        UnitEvents.FormatPlayer(ownerSlotOverride is >= 0 ? ownerSlotOverride.Value : s.OwnerSlot),
        s.Kind,
        s.InstanceIndex,
        s.HitCount,
        s.TotalDamage.ToString("0.00"),
        s.MaxHit.ToString("0.00"),
        s.Peak1s.ToString("0.00"),
        s.DpsCombat.ToString("0.00"),
        s.LifetimeSeconds.ToString("0.0"),
        s.CombatSeconds.ToString("0.0"),
    };

    /// <summary>历史结算（DTO）→ 同一套 14 格。</summary>
    public static object[] Cells(HistorySettlement s) => new object[]
    {
        s.DiedAt.ToString("HH:mm:ss.fff"),
        UnitDisplayName(s.UnitName, s.Title, s.TypeCode),
        s.TypeCode,
        UnitEvents.FormatAddr(s.Addr),
        UnitEvents.FormatPlayer(s.OwnerSlot),
        s.Kind,
        s.InstanceIndex,
        s.HitCount,
        s.TotalDamage.ToString("0.00"),
        s.MaxHit.ToString("0.00"),
        s.Peak1s.ToString("0.00"),
        s.Dps.ToString("0.00"),
        s.LifetimeSeconds.ToString("0.0"),
        s.CombatSeconds.ToString("0.0"),
    };

    /// <summary>
    /// 一条结算的分组统计行：① Σ 来源（金色，一行 = 一个来源）② 组合（浅绿）。
    /// 没有数据时返回空表 + message（界面显示一行提示）。
    /// 来源名里的 |cXXXXXX|r 样式码在这里再兜一次底（历史库里的旧数据也能显示干净）。
    /// </summary>
    public static List<(object[] Cells, Color Color)> BreakdownRows(string unit,
        IReadOnlyList<HookBreakdown.SourceRow>? sources,
        IReadOnlyList<HookBreakdown.Combination>? combos,
        out string message)
    {
        message = "";
        unit = Wc3Text.Clean(unit);
        var rows = new List<(object[], Color)>();

        if (sources is { Count: > 0 })
        {
            foreach (var sr in sources)
            {
                rows.Add((new object[]
                {
                    unit, "Σ " + Wc3Text.Clean(sr.Source), "汇总", "", "", "",
                    sr.Count, sr.Count > 0 ? sr.Damage.ToString("0.00") : "?",
                    sr.EngineValid ? sr.Engine.ToString("0.00") : "?",
                    sr.EffectiveValid ? sr.Effective.ToString("0.00") : "?",
                    sr.NetValid ? sr.NetDrop.ToString("0.00") : "?",
                    sr.Percent.ToString("0.0") + "%"
                }, Color.Gold));
            }
        }

        if (combos is { Count: > 0 })
        {
            foreach (var cb in combos)
            {
                rows.Add((new object[]
                {
                    unit, Wc3Text.Clean(cb.Source), cb.IsAttack, cb.IsRanged, cb.AttackType, cb.DamageType,
                    cb.Count, cb.Count > 0 ? cb.Damage.ToString("0.00") : "?",
                    cb.EngineValid ? cb.Engine.ToString("0.00") : "?",
                    cb.EffectiveValid ? cb.Effective.ToString("0.00") : "?",
                    cb.NetValid ? cb.NetDrop.ToString("0.00") : "?",
                    cb.Percent.ToString("0.0") + "%"
                }, Color.LightGreen));
            }
        }

        if (rows.Count == 0) message = "这条结算没有伤害分组数据";
        return rows;
    }
}
