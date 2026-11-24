namespace War3DeathSettlement.Core;

/// <summary>
/// 按单位名忽略（**用户自定义**，默认空）的匹配规则：名字**包含**任一关键字即命中，不区分大小写。
/// 关键字来自 ini 的 ignore_unit_names（逗号/分号分隔，空 = 不过滤）或环境变量 DSS_IGNORE_UNIT_NAMES。
/// 注意：这不是“马甲判定”；马甲只看 ddh 实测的 Aloc 技能（GetUnitAbilityLevel(...) &gt; 0）。
/// 放在 Core 里是为了 --selftest 能直接覆盖它（不需要游戏进程）。
/// </summary>
public static class UnitNameFilter
{
    /// <summary>逗号/分号分隔；全角逗号/分号也认（用户从中文输入法里打的）。</summary>
    private static readonly char[] Separators = { ',', ';', '，', '；' };

    /// <summary>拆分关键字：Trim 首尾空白、丢掉空项和重复项；空/纯空白配置返回空数组（= 不过滤）。</summary>
    public static string[] Parse(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return Array.Empty<string>();
        return raw.Split(Separators, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                  .Where(k => k.Length > 0)
                  .Distinct(StringComparer.OrdinalIgnoreCase)
                  .ToArray();
    }

    /// <summary>
    /// 名字是否命中任一关键字：名字与关键字都先 Trim，按不区分大小写的“包含”比较。
    /// 名字为空/纯空白 = 不命中；关键字为空/纯空白 = 跳过；配置为空 = 不命中。
    /// </summary>
    public static bool Hits(string? name, IReadOnlyList<string>? keywords)
    {
        if (keywords == null || keywords.Count == 0) return false;
        if (string.IsNullOrWhiteSpace(name)) return false;
        string n = name.Trim();
        if (n.Length == 0) return false;
        foreach (var raw in keywords)
        {
            if (string.IsNullOrWhiteSpace(raw)) continue;
            if (n.Contains(raw.Trim(), StringComparison.OrdinalIgnoreCase)) return true;
        }
        return false;
    }

    /// <summary>按原始配置串匹配（内部先 <see cref="Parse"/>；空配置 = 不命中）。</summary>
    public static bool Hits(string? name, string? rawKeywords) => Hits(name, Parse(rawKeywords));
}
