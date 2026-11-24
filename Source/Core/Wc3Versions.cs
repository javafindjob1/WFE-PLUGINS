namespace War3DeathSettlement.Core;

/// <summary>某个游戏版本的关键全局地址（都是相对 game.dll 基址的 RVA）。</summary>
public sealed record Wc3VersionInfo(
    string Version,
    uint ThisGameRva,
    uint UnitListRva,
    uint MoveSpeedRva,
    uint AttackAttributesOffset,
    uint HeroAttributesOffset);

/// <summary>
/// CUnit 内部的字段偏移。
/// 依据：反编译 War3Trainer.exe —— OneSelectedUnitNode::CreateChildren 的 IL（逐条立即数）：
///   * 单位名称(4 字符类型码)  = CUnit + 0x30
///   * HP 索引                = *(CUnit + 0xA0)   → 游戏内存表[索引] + 0x78 = 当前HP, +0x84 = 最大HP
///   * MP 索引                = *(CUnit + 0xC0)   → 同一张表 + 0x78 / +0x84
///   * HP 回复率              = CUnit + 0xB0
///   * MP 回复率              = CUnit + 0xD4
///   * 盔甲数量/种类          = CUnit + 0xE0（float）/ +0xE4（int32）
///                             （YDWE UnitState.cpp：UNIT_STATE_ARMOR 位透传 real / UNIT_STATE_ARMOR_TYPE）
///   * 坐标索引               = *(CUnit + 0x16C)  → 表[索引] + 0x78 = X, +0x7C = Y
/// War3Trainer 对 1.22~1.27 只换全局地址、类内偏移不变（见 选区内存定位2.md §1.2）。
/// </summary>
public static class Wc3UnitOffset
{
    public const uint TypeCode = 0x30;
    /// <summary>
    /// 拥有者槽位：CUnit+0x58（0 基）。原生 GetOwningPlayer 的虚拟函数
    /// 同样只是返回该 dword，GetPlayerId 再取到的也是同一个槽位。
    /// </summary>
    public const uint Owner = 0x58;
    public const uint HpIndex = 0xA0;
    public const uint MpIndex = 0xC0;
    public const uint HpRegen = 0xB0;
    public const uint MpRegen = 0xD4;
    /// <summary>
    /// 护甲值：CUnit+0xE0 的 **float**（不是 int32）。
    /// 依据 YDWE <c>yd_jass_api/UnitState.cpp</c> 的 UNIT_STATE_ARMOR：
    /// <c>return *(uint32_t*)(unit_object + 0xE0);</c> 是位透传给 JASS 的 real 返回值。
    /// 真机 E06V 原始位模式 0x430DADBB = 141.679；按 int 读是 1124969915（越界）。
    /// </summary>
    public const uint ArmorAmount = 0xE0;
    /// <summary>护甲类型：CUnit+0xE4 的 int32（YDWE UNIT_STATE_ARMOR_TYPE）。</summary>
    public const uint ArmorType = 0xE4;
    public const uint PositionIndex = 0x16C;

    /// <summary>游戏内存表里：当前 HP 相对表项对象；最大 HP 在 +0x84。</summary>
    public const uint StateMax = 0x84;
    public const uint StateCur = 0x78;   // = 0x84 - 12
    public const uint PosX = 0x78;
    public const uint PosY = 0x7C;
}

public static class Wc3Versions
{
    /// <summary>读不到 game.dll 版本号时退回的默认版本（本机游戏 / War3Trainer 默认）。</summary>
    public const string DefaultVersion = "1.27.0.52240";

    private static readonly Dictionary<string, Wc3VersionInfo> Map = Build();

    private static Dictionary<string, Wc3VersionInfo> Build()
    {
        var d = new Dictionary<string, Wc3VersionInfo>(StringComparer.OrdinalIgnoreCase);
        foreach (var r in Wc3VersionTable.Rows)
            d[r.Version] = new Wc3VersionInfo(r.Version, r.ThisGame, r.UnitList, r.MoveSpeed, r.AttackOff, r.HeroOff);
        return d;
    }

    public static IReadOnlyCollection<string> SupportedVersions => Map.Keys;

    public static bool TryGet(string? version, out Wc3VersionInfo info)
    {
        info = null!;
        if (string.IsNullOrWhiteSpace(version)) return false;

        string norm = Normalize(version);
        if (Map.TryGetValue(norm, out var v)) { info = v; return true; }
        return false;
    }

    /// <summary>
    /// 版本串归一化：
    ///   "1.27.0.52240 (f7ba2a3)" → "1.27.0.52240"
    ///   "1, 27, 0, 52240"        → "1.27.0.52240"   （FileVersionInfo.FileVersion 常见形态）
    /// </summary>
    public static string Normalize(string version)
    {
        var sb = new System.Text.StringBuilder(version.Length);
        foreach (char c in version)
        {
            if (c == '(') break;
            if (char.IsWhiteSpace(c)) continue;
            sb.Append(c == ',' ? '.' : c);
        }
        string s = sb.ToString().TrimEnd('.');
        // 只保留 数字 + 点
        var sb2 = new System.Text.StringBuilder(s.Length);
        foreach (char c in s)
            if (char.IsDigit(c) || c == '.') sb2.Append(c);
        return sb2.ToString().Trim('.');
    }

    public static Wc3VersionInfo Require(string version) =>
        TryGet(version, out var v) ? v : throw new NotSupportedException("不支持的魔兽版本：" + version);
}
