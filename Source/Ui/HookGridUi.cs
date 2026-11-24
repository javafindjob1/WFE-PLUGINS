using War3DeathSettlement.Core;

namespace War3DeathSettlement.Ui;

/// <summary>伤害事件表（主页 + 双击弹窗）共用的列定义与行渲染，保证两处列序/内容完全一致。</summary>
internal static class HookGridUi
{
    public readonly record struct UnitIdentity(string Name, string Title, int OwnerSlot);
    public static UnitIdentity Unknown => new("", "", -1);

    // 表头搜索（SettlementHeaderSearch.ForHookEvents）用的列名/表头：主页与弹窗共用，
    // 避免两处各写一份字符串后走样。
    public const string VictimColumn = "dstc";
    public const string SourceColumn = "srcc";
    public const string VictimHeader = "触发单位";
    public const string VictimPlayerColumn = "dstp";
    public const string SourcePlayerColumn = "srcp";
    public const string SourceHeader = "伤害来源";
    public const string VictimPlayerHeader = "触发玩家";
    public const string SourcePlayerHeader = "来源玩家";

    /// <summary>19 列；镜像状态只参与名称匹配，不占显示列。</summary>
    public static void AddColumns(Grid g)
    {
        g.AddText("时间", "t", 170);
        g.AddText(VictimHeader, VictimColumn, 110);
        g.AddText("实例ID", "dstid", 80);
        g.AddText(VictimPlayerHeader, VictimPlayerColumn, 70);
        g.AddText(SourceHeader, SourceColumn, 110);
        g.AddText("实例ID", "srcid", 80);
        g.AddText(SourcePlayerHeader, SourcePlayerColumn, 70);
        g.AddText("是否英雄", "srch", 55);
        g.AddText("层", "depth", 40);
        g.AddText("原始伤害", "raw", 85);
        g.AddText("引擎伤害", "eng", 85);
        g.AddText("地图伤害", "eff", 85);
        g.AddText("净掉血", "net", 85);
        g.AddText("倍数", "rate", 60);
        g.AddText("本层前血→后血", "hp", 130);
        g.AddText("攻击", "atk", 55);
        g.AddText("远程", "rng", 55);
        g.AddText("攻击类型", "atype", 65);
        g.AddText("伤害类型", "dtype", 65);

        // 等比例 Fill：最后一列不被挤掉。
        foreach (DataGridViewColumn col in g.Columns)
        {
            col.AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
            col.FillWeight = Math.Max(8, col.Width);
            col.MinimumWidth = 40;
        }
        // 单位ID 类列（0x + 8 位十六进制，10 字符）保底 100px，避免缩太窄被截断。
        g.Columns["dstid"]!.MinimumWidth = 70;
        g.Columns["srcid"]!.MinimumWidth = 70;
        // 末尾两列文字较长（攻击类型 / 伤害类型），单独给最小宽度和更高权重，避免被挤成“攻击类/伤害类”
        foreach (var (name, min, weight) in new[] { ("atype", 80, 88), ("dtype", 96, 100) })
        {
            var col = g.Columns[name];
            if (col == null) continue;
            col.MinimumWidth = min;
            col.FillWeight = weight;
        }
    }

    /// <summary>一条事件 → 一行单元格；单位列显示“称谓 + 单位名”，玩家列显示玩家。</summary>
    public static object[] RowCells(DamageHook.HookEvent e, Func<uint, string> playerText,
                                    Func<uint, string?, bool>? isIllusionOf = null,
                                    Func<string, bool, UnitIdentity>? identityOf = null)
    {
        bool victimMirror = e.VictimIllusion ||
                            (e.Victim != 0 && isIllusionOf?.Invoke(e.Victim, e.VictimCode) == true);
        bool sourceMirror = e.SourceIllusion ||
                            (e.Source != 0 && isIllusionOf?.Invoke(e.Source, e.SourceCode) == true);
        var victimIdentity = identityOf?.Invoke(e.VictimCode, victimMirror) ?? Unknown;
        var sourceIdentity = identityOf?.Invoke(e.SourceCode, sourceMirror) ?? Unknown;
        return new object[]
        {
            e.At.ToString("HH:mm:ss.fff"),
            DisplayName(e.VictimCode, victimMirror, victimIdentity),
            UnitEvents.FormatAddr(e.Victim), PlayerCell(victimIdentity.OwnerSlot),
            DisplayName(e.SourceCode, sourceMirror, sourceIdentity),
            UnitEvents.FormatAddr(e.Source), PlayerCell(sourceIdentity.OwnerSlot),
            e.SourceHero ? "是" : "否",
            e.DepthText,
            e.Amount.ToString("0.00"), e.EngineText, e.EffectiveText,
            e.NetDropText,
            e.MapRate > 0 ? e.MapRate.ToString("0.##") + "×" : "",
            e.HpText,
            e.IsAttack ? "1" : "0", e.IsRanged ? "1" : "0",
            e.AttackType,
            e.DamageType >= 0 ? e.DamageType.ToString() : "0x" + e.DamageMask.ToString("X"),
        };
    }

    /// <summary>
    /// 伤害事件表头搜索的 AND 谓词：触发单位 / 伤害来源两列都命中才保留；
    /// 单列关键词为空 = 该列不过滤；两列都空 = 全部通过。
    /// **每一列都是“名字 或 英雄称谓”命中即可**（显示为“称谓 + 单位名称”）：
    ///   · 实时事件：titleOf = (地址, 类型码) → 称谓（MonitorEngine 的索引；类型码用来防地址复用误匹配）；
    ///   · 历史事件：事件里自带 victim_title / source_title（老库没有 → 空串），此时 titleOf 传 null。
    /// 复用的模糊匹配规则与死亡结算表完全一致（<see cref="SettlementGridUi.MatchesNameOrTitle"/>）。
    /// </summary>
    public static bool MatchesSearch(DamageHook.HookEvent e, string? victimKeyword, string? sourceKeyword,
                                     Func<uint, string?, string>? titleOf = null,
                                     Func<uint, string?, bool>? isIllusionOf = null,
                                     Func<string, bool, UnitIdentity>? identityOf = null) =>
        MatchesSearch(e, victimKeyword, null, sourceKeyword, null, titleOf, isIllusionOf, identityOf);

    /// <summary>四列版本：触发单位 / 触发单位玩家 / 伤害来源 / 伤害来源玩家（空关键词 = 不过滤）。</summary>
    public static bool MatchesSearch(DamageHook.HookEvent e,
                                     string? victimKeyword, string? victimPlayerKeyword,
                                     string? sourceKeyword, string? sourcePlayerKeyword,
                                     Func<uint, string?, string>? titleOf = null,
                                     Func<uint, string?, bool>? isIllusionOf = null,
                                     Func<string, bool, UnitIdentity>? identityOf = null) =>
        SettlementGridUi.MatchesNameOrTitle(e.VictimText, TitleOf(e.Victim, e.VictimCode, e.VictimTitle, titleOf), victimKeyword) &&
        SettlementGridUi.MatchesNameOrTitle(PlayerCell(identityOf, e.VictimCode, e.Victim, e.VictimIllusion, isIllusionOf), "", victimPlayerKeyword) &&
        SettlementGridUi.MatchesNameOrTitle(e.SourceText, TitleOf(e.Source, e.SourceCode, e.SourceTitle, titleOf), sourceKeyword) &&
        SettlementGridUi.MatchesNameOrTitle(PlayerCell(identityOf, e.SourceCode, e.Source, e.SourceIllusion, isIllusionOf), "", sourcePlayerKeyword);

    private static string PlayerCell(Func<string, bool, UnitIdentity>? identityOf,
                                     string code, uint addr,
                                     bool eventMirror,
                                     Func<uint, string?, bool>? isIllusionOf)
    {
        if (identityOf == null) return "";
        bool mirror = eventMirror ||
                      (addr != 0 && isIllusionOf?.Invoke(addr, code) == true);
        var identity = identityOf(code, mirror);
        return PlayerCell(identity.OwnerSlot);
    }

    private static string PlayerCell(int owner) => owner >= 0 ? UnitEvents.FormatPlayer(owner) : "?";

    /// <summary>触发单位 / 伤害来源两列（右键【跟踪】只对这两列生效）。</summary>
    public static bool IsTrackColumn(string? columnName) =>
        string.Equals(columnName, VictimColumn, StringComparison.Ordinal) ||
        string.Equals(columnName, SourceColumn, StringComparison.Ordinal) ||
        string.Equals(columnName, VictimPlayerColumn, StringComparison.Ordinal) ||
        string.Equals(columnName, SourcePlayerColumn, StringComparison.Ordinal);

    /// <summary>
    /// 右键【跟踪】要写入搜索框的关键词：优先**纯单位名**（去掉 |c 颜色码 / |r 复位码），
    /// 没名字退回类型码，再没有退回表格里显示的地址。
    /// 用名字而不是整段 “名字(类型码)” 是因为需求就是“把单位名设置到搜索框”；
    /// 表头搜索本身还支持称谓和类型码，用户想收窄可以接着改。
    /// </summary>
    /// <summary>右键列名 → 该列要写入搜索框的关键词（玩家列给“Player N”）。</summary>
    public static string TrackName(DamageHook.HookEvent e, string columnName)
    {
        if (string.Equals(columnName, VictimPlayerColumn, StringComparison.Ordinal))
            return e.VictimOwner >= 0 ? UnitEvents.FormatPlayer(e.VictimOwner) : "";
        if (string.Equals(columnName, SourcePlayerColumn, StringComparison.Ordinal))
            return e.SourceOwner >= 0 ? UnitEvents.FormatPlayer(e.SourceOwner) : "";
        return TrackName(e, string.Equals(columnName, VictimColumn, StringComparison.Ordinal));
    }

    public static string TrackName(DamageHook.HookEvent e, bool victim)
    {
        string name = Wc3Text.Clean(victim ? e.VictimName : e.SourceName);
        if (name.Length > 0) return name;
        string code = victim ? e.VictimCode : e.SourceCode;
        if (code.Length > 0) return code;
        return victim ? e.VictimText : e.SourceText;
    }

    /// <summary>
    /// 取事件里某一方（触发单位/伤害来源）的称谓：优先按地址查实时索引（带类型码校验，地址复用了就不认），
    /// 查不到再退回事件自带的（历史库回放）；都没有就是空串 → 搜索只按名字。
    /// </summary>
    private static string TitleOf(uint addr, string typeCode, string storedTitle, Func<uint, string?, string>? titleOf)
    {
        if (titleOf != null && addr != 0)
        {
            string live = titleOf(addr, typeCode);
            if (live.Length > 0) return live;
        }
        return storedTitle ?? "";
    }

    private static string DisplayName(string code, bool mirror, UnitIdentity matched)
    {
        /* 唯一匹配键：当前会话的“类型码 + 镜像位”。
           不允许按地址、事件原名或事件自带称谓兜底；失败时直接显示类型码。 */
        if (string.IsNullOrEmpty(matched.Name))
            return code;
        string text = SettlementGridUi.UnitDisplayName(matched.Name, matched.Title, code);
        return SettlementGridUi.AppendMirrorSuffix(text, mirror);
    }

}
