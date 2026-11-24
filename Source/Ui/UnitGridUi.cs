using War3DeathSettlement.Core;

namespace War3DeathSettlement.Ui;

/// <summary>
/// 【战场单位】页的列定义 / 行模型 / 表头搜索谓词（主页与自检共用）。
///
/// 当前保留 13 列：类型码、单位名称（称谓）、最小攻击力、最大攻击力、攻击范围、
/// 护甲、攻击速度、攻击间隔、攻击频率、蝗虫、镜像、玩家、地址。
///
/// “单位名称（称谓）”这一列是两行渲染：英雄第一行是称谓（小一号字、颜色与名称不同），
/// 第二行才是单位名；非英雄只显示单位名并垂直居中（绘制在 MainForm.OnUnitCellPainting）。
/// </summary>
internal static class UnitGridUi
{
    // 表头搜索（SettlementHeaderSearch.ForUnits）用的列名/表头：自检与界面共用，避免走样。
    public const string CodeColumn = "ucode";
    public const string NameColumn = "uname";
    public const string CodeHeader = "类型码";
    public const string NameHeader = "单位名称（称谓）";
    public const int CodeCellIndex = 0;
    public const int NameCellIndex = 1;
    public const int DamageMinCellIndex = 2;
    public const int DamageMaxCellIndex = 3;
    public const int AttackRangeCellIndex = 4;
    public const int ArmorCellIndex = 5;
    public const int AttackSpeedCellIndex = 6;
    public const int AttackIntervalCellIndex = 7;
    public const int AttackFrequencyCellIndex = 8;
    public const int LocustCellIndex = 9;
    public const int IllusionCellIndex = 10;
    public const int OwnerCellIndex = 11;
    public const int AddrCellIndex = 12;
    public const int ColumnCount = 13;

    /// <summary>13 列：类型码、名称、攻击属性、状态、玩家、地址。</summary>
    public static void AddColumns(Grid g)
    {
        g.AddText(CodeHeader, CodeColumn, 85);
        g.AddText(NameHeader, NameColumn, 360);
        g.AddText("最小攻击力", "udmgmin", 95);
        g.AddText("最大攻击力", "udmgmax", 95);
        g.AddText("攻击范围", "urange", 85);
        g.AddText("护甲", "uarmor", 70);
        g.AddText("攻击速度", "uatkspd", 90);
        g.AddText("攻击间隔", "uitv", 90);
        g.AddText("攻击频率", "uatkfreq", 90);
        g.AddText("蝗虫", "ulocust", 70);
        g.AddText("镜像", "uillusion", 70);
        g.AddText("玩家", "uowner", 120);
        g.AddText("地址", "uaddr", 110);

        foreach (DataGridViewColumn col in g.Columns)
        {
            col.AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
            col.FillWeight = Math.Max(8, col.Width);
            col.MinimumWidth = 45;
        }
        g.Columns[NameColumn]!.MinimumWidth = 130;   // 两行文字，太窄会把称谓/名字都截掉
    }

    /// <summary>
    /// 一行的展示模型：单位本身（类型码/名字/拥有者/地址来自快照）+ ddh 回来的属性（可能是 null）。
    /// 属性缺失时所有属性列都是 <c>?</c>（不是 0）。
    /// </summary>
    internal sealed class Row
    {
        public uint Addr { get; init; }
        /// <summary>同类型合并后的实例数（&gt;1 时地址列显示 ×N）。</summary>
        public int Count { get; init; } = 1;
        public string TypeCode { get; init; } = "";
        public string Name { get; init; } = "";
        /// <summary>英雄称谓（非英雄为空）。</summary>
        public string Title { get; init; } = "";
        /// <summary>这个实例带 Aloc（蝗虫/马甲）。</summary>
        public bool IsLocust { get; init; }
        public bool LocustKnown { get; init; }
        /// <summary>这个实例是不是镜像/幻象；只按实例生效。</summary>
        public bool IsIllusion { get; init; }
        public bool IllusionKnown { get; init; }
        public string Owner { get; init; } = "?";
        /// <summary>拥有者玩家号（-1 = 未知）。</summary>
        public int OwnerSlot { get; init; } = -1;
        /// <summary>阵营：0=盟友 1=敌人 2=未知。</summary>
        public int Faction { get; init; } = 2;
        public UnitAttrResponse? Attr { get; init; }

        /// <summary>
        /// 扫描器直读的 CUnit+0xE0（float）；NaN = 这次没测到。
        /// 护甲列只认它：ddh 的 attr.armor 仍随协议传，但界面不再采用（避免把
        /// “没测到”伪装成 0）；真实值必须由 C# 扫描器的 float 读法补上。
        /// </summary>
        public float ScannedArmor { get; init; } = float.NaN;

        /// <summary>英雄单位才有的称谓（非英雄为空）。</summary>
        public bool HasTitle => Title.Length > 0;

        /// <summary>
        /// 显示名：镜像实例追加“（镜像）”，原名称已有后缀时不重复添加。
        /// </summary>
        public string DisplayName
        {
            get
            {
                if (!IsIllusion ||
                    Name.Contains("（镜像）", StringComparison.Ordinal) ||
                    Name.Contains("(镜像)", StringComparison.Ordinal))
                    return Name;
                return Name + "（镜像）";
            }
        }

        public string LocustText => !LocustKnown ? "?" : IsLocust ? "是" : "否";
        public string IllusionText => !IllusionKnown ? "?" : IsIllusion ? "是" : "否";

        /// <summary>
        /// 名称列的值：英雄 = “称谓\n显示名”（自绘成两行），非英雄 = 显示名。
        /// 保留换行是为了无障碍/自动化读出来时两行都在（搜索用的是 Title/Name 两个字段）。
        /// </summary>
        public string NameCellText => HasTitle ? Title + "\n" + DisplayName : DisplayName;

        public string AttackRangeText => Attr?.AttackRangeText ?? "?";
        public string DamageMinText =>
            Attr != null && Attr.Has(UnitAttrWire.FlagDamage)
                ? UnitAttrResponse.FormatNumber(Attr.DamageMin)
                : "?";
        public string DamageMaxText =>
            Attr != null && Attr.Has(UnitAttrWire.FlagDamage)
                ? UnitAttrResponse.FormatNumber(Attr.DamageMax)
                : "?";
        /// <summary>state 81 的原始攻击速度。</summary>
        public string AttackSpeedText => Attr?.AttackSpeedText ?? "?";
        /// <summary>攻击间隔列只显示数值（两位小数，不带“秒”）；没测到显示 ?。</summary>
        public string AttackIntervalText => Attr?.AttackIntervalValueText ?? "?";
        /// <summary>攻击频率 = 攻击速度 / 攻击间隔。</summary>
        public string AttackFrequencyText => Attr?.AttackFrequencyText ?? "?";
        /// <summary>
        /// 护甲列：扫描器直读的 CUnit+0xE0（float）优先；扫描不到就显示 ?。
        /// 不退回 ddh 的 attr.armor —— 它只作协议字段，不能把“没测到”伪装成 0。
        /// </summary>
        public string ArmorText
        {
            get
            {
                if (!float.IsNaN(ScannedArmor) && !float.IsInfinity(ScannedArmor))
                    return UnitAttrResponse.FormatNumber(ScannedArmor);
                return Attr != null && Attr.Has(UnitAttrWire.FlagArmor)
                    ? UnitAttrResponse.FormatNumber(Attr.Armor)
                    : "?";
            }
        }
        /// <summary>移速列：native 移速优先，没有才退回类型数据 spd（见 UnitAttrWire.MoveSpeedPreferredText）。</summary>
        public string MoveSpeedText => Attr?.MoveSpeedPreferredText ?? "?";
        /// <summary>白天视野列（协议 v14）：jass.slk sight；slk 取不到时 ddh 退回 0x3ADF0。</summary>
        public string SightDayText => Attr?.SightDayText ?? "?";
        /// <summary>夜晚视野列（协议 v14）：jass.slk nsight；取不到 → ?。</summary>
        public string SightNightText => Attr?.SightNightText ?? "?";
        public string AcquireRangeText => Attr?.AcquireRangeText ?? "?";
        public string StrengthText => Attr?.StrengthText ?? "?";
        public string AgilityText => Attr?.AgilityText ?? "?";
        public string IntelligenceText => Attr?.IntelligenceText ?? "?";

        /// <summary>一行 13 格（列序与 <see cref="AddColumns"/> 一致）。</summary>
        public object[] Cells() => new object[]
        {
            TypeCode, NameCellText, DamageMinText, DamageMaxText, AttackRangeText,
            ArmorText, AttackSpeedText, AttackIntervalText, AttackFrequencyText,
            LocustText, IllusionText, Owner, "0x" + Addr.ToString("X8")
        };
    }

    /// <summary>快照里的一个单位 + ddh 属性 → 一行。</summary>
    /// <param name="isIllusion">实例级镜像位；null = 用属性响应里的 IsIllusion。</param>
    public static Row Build(UnitView u, UnitAttrResponse? attr, Func<uint, string> ownerText,
                            int localPid = -1, IReadOnlySet<int>? allySlots = null, uint allyMask = 0,
                            bool? isIllusion = null)
    {
        string code = attr != null && attr.HasTypeCode ? attr.TypeCode : u.TypeCode;
        string name = Wc3Text.Clean((attr != null && attr.HasName ? attr.Name : u.Name) ?? "");
        string title = Wc3Text.Clean(attr != null ? attr.TitleText : "");
        bool illusion = isIllusion ?? attr?.IsIllusion == true;
        bool illusionKnown = isIllusion.HasValue || attr?.IllusionChecked == true;
        bool locust = attr?.IsLocust == true;
        bool locustKnown = attr?.LocustChecked == true;
        // Propernames 现在由 ddh 从单位类型数据读取；极端情况下仍可能与单位名相同，
        // 相同就不画重复的第一行（不同则正常两行）。
        if (title.Length > 0 && string.Equals(title, name, StringComparison.Ordinal)) title = "";
        string owner = !string.IsNullOrWhiteSpace(u.Owner) && u.Owner != "?" ? u.Owner : ownerText(u.Addr);
        int faction = FactionOf(u.OwnerSlot, localPid, allySlots, allyMask);
        // 阵营已知时把“（盟友）/（敌人）”缀在拥有者后面 —— 不新增列，也不动既有列序。
        if (faction == Ally && !owner.Contains("盟友", StringComparison.Ordinal)) owner += "（盟友）";
        else if (faction == Enemy && !owner.Contains("敌人", StringComparison.Ordinal)) owner += "（敌人）";
        return new Row
        {
            Addr = u.Addr, TypeCode = code, Name = name, Title = title, Owner = owner, Attr = attr,
            OwnerSlot = u.OwnerSlot, Faction = faction,
            IsLocust = locust, LocustKnown = locustKnown,
            IsIllusion = illusion, IllusionKnown = illusionKnown,
            ScannedArmor = u.Armor, Count = u.Count
        };
    }

    /// <summary>
    /// ddh `units` 表只收录伤害事件 victim/source。中途启动 C# 时扫描器
    /// 可能已看不到这些单位，补入行必须显式标记 Participated。
    /// </summary>
    public static UnitView UnitFromDdhDb(uint addr, UnitAttrResponse attr) => new()
    {
        Addr = addr,
        TypeCode = attr.HasTypeCode ? attr.TypeCode : "",
        Name = attr.HasName ? attr.Name : "",
        Owner = attr.OwnerSlot >= 0 ? UnitEvents.FormatPlayer(attr.OwnerSlot) : "?",
        OwnerSlot = attr.OwnerSlot,
        Hp = 1f,
        State = "存活",
        IsIllusion = attr.IsIllusion,
        Participated = true,
    };

    public const int Ally = 0;
    public const int Enemy = 1;
    public const int UnknownFaction = 2;

    /// <summary>
    /// 战场单位显示规则：普通蝗虫隐藏；镜像无论是否蝗虫都显示。
    /// 同类型存在镜像时，原单位也显示，避免 locust=1 的原单位被幻象行覆盖。
    /// </summary>
    public static bool ShouldDisplay(bool isLocust, bool isIllusion, bool hasIllusionSibling = false) =>
        UnitDisplayPolicy.ShouldDisplay(isLocust, isIllusion, hasIllusionSibling);

    /// <summary>中立玩家：12~15（中立敌对/被动/额外/受害者）。</summary>
    public static bool IsNeutralSlot(int slot) => slot >= 12;

    /// <summary>玩家号 → 阵营（0=盟友 1=敌人 2=未知）。本地玩家自己恒为盟友。
    /// allyMask（ddh v21）非 0 时优先用它判定真实结盟；否则退回 本地玩家 + ini ally_slots。</summary>
    public static int FactionOf(int ownerSlot, int localPid, IReadOnlySet<int>? allySlots, uint allyMask = 0)
    {
        if (ownerSlot < 0 || IsNeutralSlot(ownerSlot)) return UnknownFaction;
        if (allyMask != 0) return ((allyMask >> ownerSlot) & 1u) != 0 ? Ally : Enemy;
        if (localPid >= 0 && ownerSlot == localPid) return Ally;
        if (allySlots != null && allySlots.Contains(ownerSlot)) return Ally;
        return localPid >= 0 || allySlots is { Count: > 0 } ? Enemy : UnknownFaction;
    }

    /// <summary>
    /// 排序 / 显示优先级：**还活着的优先**，然后按“最后一次受击时间”倒序（最近有伤害事件的最前），
    /// 再按累计受伤、地址兜底 —— 这只用于表格显示和**同一轮请求批内**的先后；
    /// 请求本身由 <see cref="UnitAttrPoller"/> 轮询全部单位，保证没有单位会被饿死。
    /// </summary>
    public static List<UnitView> SortForDisplay(IEnumerable<UnitView> units) =>
        units.OrderByDescending(u => u.Hp > 0f ? 1 : 0)
             .ThenByDescending(u => u.LastHit ?? DateTime.MinValue)
             .ThenByDescending(u => u.Taken)
             .ThenBy(u => u.Addr)
             .ToList();

    /// <summary>
    /// 【战场单位】显示顺序：中立玩家（12~15）直接剔除；其余按 盟友 → 敌人 → 未知，
    /// 二级按单位名称（不区分大小写），最后地址兜底。
    /// </summary>
    public static List<UnitView> SortForFaction(IEnumerable<UnitView> units, int localPid, IReadOnlySet<int>? allySlots, uint allyMask = 0) =>
        units.Where(u => !IsNeutralSlot(u.OwnerSlot))
             .OrderBy(u => FactionOf(u.OwnerSlot, localPid, allySlots, allyMask))
             .ThenBy(u => u.Name, StringComparer.OrdinalIgnoreCase)
             .ThenBy(u => u.Addr)
             .ToList();

    /// <summary>
    /// 旧接口：按显示优先序取前 max 个地址。界面/无界面模式已经改用
    /// <see cref="UnitAttrPoller.PickRound"/> 轮询（否则后面的单位永远轮不到、界面一直 ?）。
    /// 保留给自检和需要“只看最活跃单位”的场合。
    /// </summary>
    public static List<uint> PickRequestAddrs(IEnumerable<UnitView> units, int max) =>
        SortForDisplay(units).Take(Math.Max(0, max)).Select(u => u.Addr).ToList();

    /// <summary>
    /// 表头搜索的 AND 谓词：类型码列 + 单位名称列。
    /// **单位名称列同时匹配称谓和名称**（两行任意一行命中即可；空关键词 = 该列不过滤）。
    /// 与死亡结算/伤害事件表**共用同一个名称谓词** <see cref="SettlementGridUi.MatchesNameOrTitle"/>。
    /// </summary>
    public static bool MatchesSearch(Row row, string? codeKeyword, string? nameKeyword) =>
        SettlementGridUi.MatchesCellValue(row.TypeCode, codeKeyword) &&
        SettlementGridUi.MatchesNameOrTitle(row.DisplayName, row.Title, nameKeyword);
}
