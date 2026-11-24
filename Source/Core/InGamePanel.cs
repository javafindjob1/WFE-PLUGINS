using System.Globalization;

namespace War3DeathSettlement.Core;

/// <summary>游戏内面板的显示参数（ini 的 in_game_panel_*，由 MonitorEngine 绑定到 ddh PanelBlock）。</summary>
public sealed class InGamePanelSettings
{
    public bool Enabled = true;
    /// <summary>显示多少毫秒后自动隐藏（C# 会主动发 hide；ddh 也有 TTL 兜底）。</summary>
    public int TtlMs = 20000;
    public string FontName = "MasterFont";
    public float FontHeight = 0.0135f;
    public float LineHeight = 0.0175f;
    /// <summary>屏幕比例坐标（相对 CGameUI 根帧；y 向下为负）。</summary>
    public float X = 0.60f;
    public float Y = -0.24f;
    /// <summary>WC3 锚点枚举：0=TOPLEFT, 2=TOPRIGHT, 4=CENTER…</summary>
    public uint Anchor = 0;
    /// <summary>只对“确认是英雄”的本地单位显示（默认开）。</summary>
    public bool HeroOnly = true;
    public int MaxLines = 18;
    /// <summary>v16：显示深色背景（默认开）。</summary>
    public bool Background = true;
    /// <summary>v16：死亡弹出时先收起（默认展开）。</summary>
    public bool StartCollapsed = false;
    /// <summary>v16：收起时显示前几行（默认 3）。</summary>
    public int CollapsedLines = 3;
    /// <summary>v17：伤害来源行左侧显示单位图标（默认开）。</summary>
    public bool Icons = true;

    public static InGamePanelSettings FromSettings(Settings s) => new()
    {
        Enabled = s.InGamePanel,
        TtlMs = Math.Clamp(s.InGamePanelTtlMs, 1000, 600000),
        FontName = string.IsNullOrWhiteSpace(s.InGamePanelFont) ? "MasterFont" : s.InGamePanelFont,
        FontHeight = Math.Clamp(s.InGamePanelFontHeight, 0.006f, 0.05f),
        LineHeight = Math.Clamp(s.InGamePanelLineHeight, 0.006f, 0.08f),
        X = Math.Clamp(s.InGamePanelX, -2f, 2f),
        Y = Math.Clamp(s.InGamePanelY, -2f, 2f),
        Anchor = s.InGamePanelAnchor > 8 ? 0u : s.InGamePanelAnchor,
        HeroOnly = s.InGamePanelHeroOnly,
        MaxLines = Math.Clamp(s.InGamePanelMaxLines, 6, InGamePanelWire.MaxLines),
        Background = s.InGamePanelBackground,
        StartCollapsed = s.InGamePanelCollapsed,
        CollapsedLines = Math.Clamp(s.InGamePanelCollapsedLines, 1, 3),
        Icons = s.InGamePanelIcons,
    };
}

/// <summary>
/// 把一条 <see cref="Settlement"/> 排成游戏内面板的行（纯函数，离线自检直接测）。
/// 行内不带 <c>|c</c> 样式码：每行一个颜色，由 ddh 的 SetTextColor 设置。
/// </summary>
public static class InGamePanel
{
    public sealed record PanelIcon(int LineIndex, uint RawCode, uint SourceAddr = 0);
    public sealed record PanelContent(IReadOnlyList<PanelLine> Lines, IReadOnlyList<PanelIcon> Icons);

    public const uint ColorGold = 0xFFFFCC66;
    public const uint ColorWhite = 0xFFFFFFFF;
    public const uint ColorDim = 0xFFB0B0B0;
    public const uint ColorRed = 0xFFFF6666;
    public const uint ColorGreen = 0xFF88DD88;

    /// <summary>是不是“本地玩家的死亡结算”（英雄判定另外做；消失结算不弹）。</summary>
    public static bool IsLocalDeath(Settlement s, int localPlayerIndex) =>
        s != null && s.Kind == "死亡" &&
        localPlayerIndex >= 0 && s.OwnerSlot == localPlayerIndex;

    /// <summary>同一次死亡 2 秒桶去重键（addr + 死亡时间桶）。</summary>
    public static string DedupeKey(Settlement s) =>
        $"{s.Addr:X8}:{s.DiedAt.Ticks / (TimeSpan.TicksPerSecond * 2)}";

    /// <summary>生成面板行。titleOf = (addr, typeCode) → 英雄称谓（没有返回空串）。</summary>
    public static IReadOnlyList<PanelLine> BuildLines(
        Settlement s, Func<uint, string, string>? titleOf, InGamePanelSettings cfg) =>
        BuildContent(s, titleOf, cfg).Lines;

    /// <summary>生成面板行 + 伤害来源头像行号/类型码（v17）。</summary>
    public static PanelContent BuildContent(
        Settlement s, Func<uint, string, string>? titleOf, InGamePanelSettings cfg)
    {
        ArgumentNullException.ThrowIfNull(s);
        cfg ??= new InGamePanelSettings();
        var lines = new List<PanelLine>(InGamePanelWire.MaxLines);
        var icons = new List<PanelIcon>(4);

        void Add(uint color, string text) => lines.Add(new PanelLine(color, text ?? ""));

        Add(ColorGold, "阵亡总结");

        string code = Wc3Text.Clean(s.TypeCode);
        string name = Wc3Text.Clean(s.UnitName);
        string title = "";
        if (titleOf != null)
        {
            try { title = Wc3Text.Clean(titleOf(s.Addr, s.TypeCode)); } catch { title = ""; }
        }
        string hero = title.Length > 0
            ? (name.Length > 0 && !string.Equals(name, title, StringComparison.Ordinal) ? $"{title}（{name}）" : title)
            : (name.Length > 0 ? name : (code.Length > 0 ? code : "?"));
        Add(ColorWhite, code.Length > 0 ? $"{hero} · {code}" : hero);

        string owner = s.OwnerSlot >= 0 ? $"玩家 {s.OwnerSlot + 1}" : "玩家 ?";
        Add(ColorDim, $"{owner} · 第 {Math.Max(1, s.InstanceIndex)} 条命 · 死亡 {s.DiedAt:HH:mm:ss}");

        Add(ColorWhite, $"承受伤害 {Num(s.TotalDamage)}");
        Add(ColorDim, $"{s.HitCount} 笔 · 最大 {Num(s.MaxHit)} · 最惨 1 秒 {Num(s.Peak1s)}");
        Add(ColorDim, $"战斗 {s.CombatSeconds:0.0} 秒 · 秒伤 {s.DpsCombat:0.0} · 治疗 {Num(s.TotalHeal)}");
        Add(ColorDim, $"最大生命 {Num(s.HpMax)} · 记录 {s.LifetimeSeconds:0.0} 秒");

        // ---- 致命一击（钩子事件；没有就写 ?）----
        var fatal = s.FatalHookEvent;
        if (fatal != null)
        {
            string fsrc = Wc3Text.Clean(fatal.SourceText);
            string kind = fatal.IsAttack ? "普攻" : "技能";
            string type = $"攻{fatal.AttackType}/伤{fatal.DamageTypeText}";
            Add(ColorRed, $"致命一击 {fsrc} {Num(fatal.EffectiveValid ? fatal.EffectiveDamage : fatal.Amount)}（{kind} · {type}）");
        }
        else
        {
            Add(ColorRed, "致命一击 ?（没采到致命钩子事件）");
        }

        // ---- 伤害来源 Top 4 ----
        var sources = (s.HookSources ?? Array.Empty<HookBreakdown.SourceRow>())
            .Where(r => r.NetDrop > 0.01 || r.Damage > 0.01)
            .OrderByDescending(r => r.Percent)
            .Take(4)
            .ToList();
        if (sources.Count > 0)
        {
            Add(ColorGold, "伤害来源");
            foreach (var r in sources)
            {
                string who = Wc3Text.Clean(r.Source);
                int lineIndex = lines.Count;
                Add(ColorWhite, $"{who} {r.Percent:0.0}%  {Num(r.NetDrop)}  {r.Count}笔");
                if (cfg.Icons && icons.Count < InGamePanelWire.MaxIcons &&
                    !string.IsNullOrWhiteSpace(r.SourceCode))
                {
                    uint raw = InGamePanelWire.ToJassRawCode(r.SourceCode);
                    if (raw != 0) icons.Add(new PanelIcon(lineIndex, raw, r.SourceAddr));
                }
            }
        }
        else
        {
            Add(ColorGold, "伤害来源");
            Add(ColorDim, "钩子数据未到（hook 未开 / 这段没采到事件）");
        }

        // ---- 构成（钩子分组；没有钩子行就跳过）----
        var rows = s.HookRows ?? Array.Empty<HookBreakdown.Row>();
        if (rows.Count > 0)
        {
            static double NetOf(HookBreakdown.Row r) => r.NetDrop > 0.01 ? r.NetDrop : r.Damage;

            double attack = rows.Where(r => r.Dimension == "钩子-是否攻击" && r.Key == "1").Sum(NetOf);
            double skill = rows.Where(r => r.Dimension == "钩子-是否攻击" && r.Key == "0").Sum(NetOf);
            if (attack > 0.01 || skill > 0.01)
                Add(ColorWhite, $"构成 普攻 {Num(attack)} / 技能 {Num(skill)}");

            double melee = rows.Where(r => r.Dimension == "钩子-是否远程" && r.Key == "0").Sum(NetOf);
            double ranged = rows.Where(r => r.Dimension == "钩子-是否远程" && r.Key == "1").Sum(NetOf);
            if (melee > 0.01 || ranged > 0.01)
                Add(ColorWhite, $"近战 {Num(melee)} / 远程 {Num(ranged)}");

            Add(ColorDim, TypeLine(rows, "钩子-攻击类型", "攻类型", NetOf));
            Add(ColorDim, TypeLine(rows, "钩子-伤害类型", "伤类型", NetOf));
        }

        Add(ColorDim, $"实例 {Math.Max(1, s.InstanceIndex)} · 0x{s.Addr:X8}");

        int max = Math.Clamp(cfg.MaxLines, 6, InGamePanelWire.MaxLines);
        if (lines.Count > max)
        {
            // 保住标题/英雄/玩家/致命，砍掉靠后的构成行和 footer。
            var keep = lines.Take(max - 1).ToList();
            keep.Add(new PanelLine(ColorDim, "…"));
            return new PanelContent(keep, icons);
        }
        return new PanelContent(lines, icons);
    }

    /// <summary>工具栏【游戏内预览】用的固定示例（结构与真实面板一致，便于调坐标/字体）。</summary>
    public static PanelContent PreviewContent(bool includeIcons = true)
    {
        var icons = new List<PanelIcon>();
        string? overrideCodes = Environment.GetEnvironmentVariable("DDH_PREVIEW_CODES");
        if (!string.IsNullOrWhiteSpace(overrideCodes))
        {
            foreach (string part in overrideCodes.Split(new[] { ',', ';', ' ' }, StringSplitOptions.RemoveEmptyEntries))
            {
                if (icons.Count >= 4) break;
                string code = part.Trim();
                if (code.Length == 4) icons.Add(new PanelIcon(9 + icons.Count, InGamePanelWire.ToJassRawCode(code)));
            }
        }
        if (icons.Count == 0)
        {
            icons.Add(new PanelIcon(9, InGamePanelWire.ToJassRawCode("Hmkg")));
            icons.Add(new PanelIcon(10, InGamePanelWire.ToJassRawCode("Hamg")));
            icons.Add(new PanelIcon(11, InGamePanelWire.ToJassRawCode("hrif")));
            icons.Add(new PanelIcon(12, InGamePanelWire.ToJassRawCode("hfoo")));
        }
        return new PanelContent(PreviewLines(), includeIcons ? icons : Array.Empty<PanelIcon>());
    }

    public static IReadOnlyList<PanelLine> PreviewLines()
    {
        var lines = new List<PanelLine>
        {
            new(ColorGold,  "阵亡总结（预览）"),
            new(ColorWhite, "剑圣（Hmkg） · Hmkg"),
            new(ColorDim,   "玩家 1 · 第 2 条命 · 死亡 12:34:56"),
            new(ColorWhite, "承受伤害 3,200"),
            new(ColorDim,   "18 笔 · 最大 812 · 最惨 1 秒 1,746"),
            new(ColorDim,   "战斗 10.0 秒 · 秒伤 320.0 · 治疗 120"),
            new(ColorDim,   "最大生命 3,200 · 记录 62.4 秒"),
            new(ColorRed,   "致命一击 山丘之王(Hmkg) 812（普攻 · 攻0/伤4）"),
            new(ColorGold,  "伤害来源"),
            new(ColorWhite, "山丘之王(Hmkg) 45.9%  1,468  6笔"),
            new(ColorWhite, "大法师(Hamg) 28.5%  912  5笔"),
            new(ColorWhite, "火枪手(hrif) 19.4%  620  4笔"),
            new(ColorWhite, "步兵(hfoo) 6.3%  200  3笔"),
            new(ColorWhite, "构成 普攻 2,606 / 技能 594"),
            new(ColorWhite, "近战 1,668 / 远程 1,532"),
            new(ColorDim,   "攻类型 0:1,876 1:700 2:424"),
            new(ColorDim,   "伤类型 4:1,900 5:1,100"),
            new(ColorDim,   "实例 2 · 0x0010586D"),
        };
        return lines;
    }

    private static string TypeLine(
        IReadOnlyList<HookBreakdown.Row> rows, string dimension, string label,
        Func<HookBreakdown.Row, double> netOf)
    {
        var grouped = rows.Where(r => r.Dimension == dimension)
            .GroupBy(r => r.Key)
            .Select(g => (Key: g.Key, Net: g.Sum(netOf)))
            .Where(x => x.Net > 0.01)
            .OrderByDescending(x => x.Net)
            .Take(3)
            .ToList();
        if (grouped.Count == 0) return $"{label} —";
        return label + " " + string.Join(" ", grouped.Select(x => $"{x.Key}:{Num(x.Net)}"));
    }

    private static string Num(double v)
    {
        if (double.IsNaN(v) || double.IsInfinity(v)) return "?";
        if (Math.Abs(v) >= 1000) return v.ToString("N0", CultureInfo.InvariantCulture);
        if (Math.Abs(v) >= 100) return v.ToString("0", CultureInfo.InvariantCulture);
        return v.ToString("0.##", CultureInfo.InvariantCulture);
    }
}
