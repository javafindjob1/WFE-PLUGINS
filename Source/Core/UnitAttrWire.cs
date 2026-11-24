using System.Globalization;
using static War3DeathSettlement.Core.UnitAttrWire;

namespace War3DeathSettlement.Core;

/// <summary>
/// ddh v14 的“单位属性请求 / 响应”协议（【战场单位】页的数据来源）。
///
/// 共享内存布局与 <c>ddh.cpp</c> 里的 <c>DdhAttrBlock</c> / <c>DdhUnitAttr</c> 严格一一对应：
/// <code>
/// DdhShared = DdhHeader(64) + DdhEvent ev[512] + DdhAttrBlock
/// DdhAttrBlock 起始 = 64 + 512 * 每条记录字节数（记录仍是 236 → 120896）
///   +0      uint32 requestSeq      C# 先把 96 个 unitAddr 写好后 +1
///   +4      uint32 doneSeq         ddh 处理完写 = requestSeq
///   +8      uint32 unitAddr[96]    请求槽（0 = 空槽）
///   +392    DdhUnitAttr attr[96]   响应槽（每个 208 字节，块长 20360）
///
/// DdhUnitAttr（pack(1)，208 字节）：
///   +0    uint32 addr       +4    uint32 flags
///   +8    char typeCode[5]  +13   char name[64]     +77  char title[64]
///   +141  float attackRange +145  float damageMin   +149 float damageMax
///   +153  float attackInterval  +157 float armor    +161 float moveSpeed
///   +165  float attackSpeed（v35：unit_property+0x1B0）
///   +169  float acquireRange
///   +173  float baseSpeed   +177  float sightDay（v14 = jass.slk sight，白天视野）
///   +181  float sightNight（v14 = jass.slk nsight，夜晚视野）
///   +185  int32 baseArmor   +189  uint8 pad[3]
///   +192  float strength    +196  float agility    +200 float intelligence
///   +204  int32 extraValue（协议仍解析；界面已不显示“单位附加值”列）
/// </code>
/// flags 每一位 = 一个字段“有效”；无效的字段在界面上显示 <c>?</c>，绝不用 0 冒充。
/// v11 在 v10 的 192 字节末尾追加力/敏/智/附加值 4 个字段（16 字节），前 192 字节偏移不变；
/// v12 只把请求/响应槽 64 → 96（块长 13576 → 20360），DdhUnitAttr 仍是 208 字节；
/// v13 把 +177 改成“当前有效视野”（单值）；v14 恢复白天/夜晚两列：
/// +177 = jass.slk 的 sight、+181 = jass.slk 的 nsight，两个字段各置各的位；
/// slk 取不到时 ddh 才用 Game.dll+0x3ADF0 的当前有效视野填 sightDay，sightNight 保持无效。
/// 173/185 仍是类型基础数据 spd / def（DzAPI_UnitType_GetUnitTypeData*）。
/// flags 0x00100000 = 该单位带 Aloc（蝗虫），C# 把它从【战场单位】列表过滤掉（镜像实例例外）。
/// flags 0x00200000 = IsUnitIllusion；v23 起 0x00400000 单独表示“执行过 Aloc 判定”。
/// v35 起 0x01000000 = 攻击速度有效；+165 原废弃视野槽改为 attackSpeed。
/// </summary>
public static class UnitAttrWire
{
    /// <summary>计算攻击频率时，攻击速度参与公式的上限。</summary>
    public const float AttackFrequencySpeedCap = 5f;

    /// <summary>请求/响应槽个数（与 ddh.cpp 的 DDH_ATTR_MAX 一致）。v12 起 96。</summary>
    public const int SlotCount = 96;

    /// <summary>
    /// ddh 侧每单位属性解析结果缓存 TTL（与 ddh.cpp 的 <c>DDH_ATTR_TTL_MS</c> 一致）。
    /// v12 从 1 秒放宽到 3 秒：轮询一轮要好几秒时，别让刚解析好的结果马上又被重算/覆盖。
    /// </summary>
    public const int DdhAttrCacheTtlMs = 3000;

    /// <summary>一个 DdhUnitAttr 的字节数（v11 起 192 + 力/敏/智/附加值 4×4 = 208）。</summary>
    public const int EntrySize = 208;

    /// <summary>块首两个 seq 的字节数。</summary>
    public const int SeqBytes = 8;

    /// <summary>请求槽在属性块内的偏移。</summary>
    public const int RequestOffset = SeqBytes;

    /// <summary>响应槽在属性块内的偏移。</summary>
    public const int ResponseOffset = SeqBytes + SlotCount * 4;

    /// <summary>整个属性块的字节数（ddh v12 真机日志：20360）。</summary>
    public const int BlockSize = ResponseOffset + SlotCount * EntrySize;

    /// <summary>
    /// 与 ddh 真机日志逐项对照的布局断言：
    /// <c>块偏移=120896，请求槽 96 个，响应槽偏移=392，单元 208 字节，块长 20360</c>。
    /// 任何一项对不上，界面就会整列 <c>?</c> —— 自检里固定跑这个断言，防止以后又改偏。
    /// 注意 ddh 的 <c>DDH_ATTR_BLOCK_OFFSET</c> 依赖事件记录长度，C# 的
    /// <c>_attrBlockOffset</c> 按 <see cref="DamageHook"/> 读到的版本算，两边都不写死。
    /// </summary>
    public static bool LayoutMatchesDdhLog =>
        SlotCount == 96 && EntrySize == 208 &&
        RequestOffset == 8 && ResponseOffset == 392 && BlockSize == 20360 &&
        OffsetAddr == 0 && OffsetFlags == 4 && OffsetTypeCode == 8 &&
        OffsetName == 13 && OffsetTitle == 77 &&
        OffsetAttackRange == 141 && OffsetDamageMin == 145 && OffsetDamageMax == 149 &&
        OffsetAttackInterval == 153 && OffsetArmor == 157 && OffsetMoveSpeed == 161 &&
        OffsetAttackSpeed == 165 && OffsetAcquireRange == 169 &&
        OffsetBaseSpeed == 173 && OffsetSightDay == 177 && OffsetSightNight == 181 &&
        OffsetBaseArmor == 185 &&
        OffsetStrength == 192 && OffsetAgility == 196 &&
        OffsetIntelligence == 200 && OffsetExtraValue == 204;

    // flags 位（与 ddh.cpp 的 DDH_AF_* 一一对应）
    public const uint FlagTypeCode = 0x00000001;
    public const uint FlagName = 0x00000002;
    public const uint FlagTitle = 0x00000004;
    public const uint FlagAttackRange = 0x00000008;
    public const uint FlagDamage = 0x00000010;
    public const uint FlagInterval = 0x00000020;
    public const uint FlagArmor = 0x00000040;
    public const uint FlagMoveSpeed = 0x00000080;
    public const uint FlagSight = 0x00000100;
    public const uint FlagAcquire = 0x00000200;
    public const uint FlagBaseSpeed = 0x00000400;
    /// <summary>协议 v14：白天视野（+177 sightDay = ddh 从 jass.slk sight 读出的值）。</summary>
    public const uint FlagSightDay = 0x00000800;
    /// <summary>协议 v14：夜晚视野（+181 sightNight = ddh 从 jass.slk nsight 读出的值）。</summary>
    public const uint FlagSightNight = 0x00001000;
    public const uint FlagBaseArmor = 0x00002000;
    public const uint FlagHeroKnown = 0x00004000;
    public const uint FlagHero = 0x00008000;
    // v11 追加字段：0x4000/0x8000 已被英雄位占用，所以从 0x10000 起（与 ddh.cpp 一一对应）
    public const uint FlagStrength = 0x00010000;
    public const uint FlagAgility = 0x00020000;
    public const uint FlagIntelligence = 0x00040000;
    public const uint FlagIllusion = 0x00200000;
    /// <summary>单位附加值（GetUnitUserData）；协议仍回传，界面已删除该列。</summary>
    public const uint FlagExtra = 0x00080000;
    /// <summary>协议 v14：该单位带 Aloc（蝗虫）→ 不进【战场单位】列表（镜像除外）。</summary>
    public const uint FlagLocust = 0x00100000;
    /// <summary>协议 v23：0x00400000 = 这次真的执行过 Aloc 判定（无论结果）；没有这一位说明“没查成”，不能把 False 当结论。
    /// v22 及更早把它和 <see cref="FlagIllusion"/> 都写成 0x00200000，C# 读旧 DLL 时必须丢弃镜像位。</summary>
    public const uint FlagLocustChecked = 0x00400000;
    /// <summary>0x00800000 = 这次真的执行过 IsUnitIllusion 判定（结果可为否）。</summary>
    public const uint FlagIllusionChecked = 0x00800000;
    /// <summary>v35：攻击速度有效（unit_property+0x1B0，对应 UnitState 81）。</summary>
    public const uint FlagAttackSpeed = 0x01000000;

    // 结构内字段偏移
    public const int OffsetAddr = 0;
    public const int OffsetFlags = 4;
    public const int OffsetTypeCode = 8;
    public const int OffsetName = 13;
    public const int OffsetTitle = 77;
    public const int OffsetAttackRange = 141;
    public const int OffsetDamageMin = 145;
    public const int OffsetDamageMax = 149;
    public const int OffsetAttackInterval = 153;
    public const int OffsetArmor = 157;
    public const int OffsetMoveSpeed = 161;
    /// <summary>v35：复用协议中已废弃的旧视野槽。</summary>
    public const int OffsetAttackSpeed = 165;
    public const int OffsetAcquireRange = 169;
    public const int OffsetBaseSpeed = 173;
    public const int OffsetSightDay = 177;
    public const int OffsetSightNight = 181;
    public const int OffsetBaseArmor = 185;
    public const int OffsetStrength = 192;
    public const int OffsetAgility = 196;
    public const int OffsetIntelligence = 200;
    public const int OffsetExtraValue = 204;

    /// <summary>结构里的两个字符串字段各 64 字节。</summary>
    public const int TextFieldSize = 64;

    /// <summary>
    /// 解析一个响应槽。返回 null 表示这个槽是空的（ddh 没填 addr）。
    /// 所有值都原样读出来，是否有效由 <see cref="UnitAttrResponse"/> 按 flags 判断。
    /// </summary>
    public static UnitAttrResponse? Decode(byte[] buffer, int offset)
    {
        if (buffer == null || offset < 0 || offset + EntrySize > buffer.Length) return null;
        uint addr = BitConverter.ToUInt32(buffer, offset + OffsetAddr);
        if (addr == 0) return null;

        uint flags = BitConverter.ToUInt32(buffer, offset + OffsetFlags);
        string typeCode = ReadAscii(buffer, offset + OffsetTypeCode, 4);
        string name = ReadText(buffer, offset + OffsetName);
        string title = ReadText(buffer, offset + OffsetTitle);

        return new UnitAttrResponse(
            addr, flags, typeCode, name, title,
            BitConverter.ToSingle(buffer, offset + OffsetAttackRange),
            BitConverter.ToSingle(buffer, offset + OffsetDamageMin),
            BitConverter.ToSingle(buffer, offset + OffsetDamageMax),
            BitConverter.ToSingle(buffer, offset + OffsetAttackInterval),
            BitConverter.ToSingle(buffer, offset + OffsetArmor),
            BitConverter.ToSingle(buffer, offset + OffsetMoveSpeed),
            BitConverter.ToSingle(buffer, offset + OffsetAttackSpeed),
            BitConverter.ToSingle(buffer, offset + OffsetAcquireRange),
            BitConverter.ToSingle(buffer, offset + OffsetBaseSpeed),
            BitConverter.ToSingle(buffer, offset + OffsetSightDay),
            BitConverter.ToSingle(buffer, offset + OffsetSightNight),
            BitConverter.ToInt32(buffer, offset + OffsetBaseArmor),
            BitConverter.ToSingle(buffer, offset + OffsetStrength),
            BitConverter.ToSingle(buffer, offset + OffsetAgility),
            BitConverter.ToSingle(buffer, offset + OffsetIntelligence),
            BitConverter.ToInt32(buffer, offset + OffsetExtraValue));
    }

    /// <summary>
    /// 这一轮 <c>doneSeq</c> 该不该被消费：非 0、比已消费的新、且不超过最后一次写出的
    /// <c>requestSeq</c>。<b>不能</b>要求 <c>done == 当前 requestSeq</c>：
    /// GUI 每轮先写新请求再轮询时，ddh 上一轮的 done 天然比当前 requestSeq 小 1，
    /// 旧逻辑（done != requestSeq 就丢弃）会永远收不到响应 —— 界面就整列 <c>?</c>。
    /// 用有符号差值比较，兼容 requestSeq 从 uint.MaxValue 回绕到 1。
    /// </summary>
    public static bool ShouldConsumeResponse(uint done, uint parsed, uint requested) =>
        done != 0 && done != parsed &&
        unchecked((int)(done - parsed)) > 0 &&
        unchecked((int)(requested - done)) >= 0;

    /// <summary>解析一整块响应区（96 槽），按槽顺序返回非空项。</summary>
    public static List<UnitAttrResponse> DecodeAll(byte[] buffer)
    {
        var list = new List<UnitAttrResponse>();
        if (buffer == null) return list;
        for (int i = 0; i < SlotCount; i++)
        {
            var r = Decode(buffer, i * EntrySize);
            if (r != null) list.Add(r);
        }
        return list;
    }

    /// <summary>固定长度、0 结尾的 ASCII（类型码 4 字符）。</summary>
    private static string ReadAscii(byte[] b, int off, int max)
    {
        var chars = new char[max];
        int n = 0;
        for (; n < max && off + n < b.Length && b[off + n] != 0; n++) chars[n] = (char)b[off + n];
        return n == 0 ? "" : new string(chars, 0, n);
    }

    /// <summary>固定长度、0 结尾的名字（引擎给的是 UTF-8；Gbk.DecodeName 会打分挑编码）。</summary>
    private static string ReadText(byte[] b, int off)
    {
        int n = 0;
        while (n < TextFieldSize && off + n < b.Length && b[off + n] != 0) n++;
        if (n == 0) return "";
        return Wc3Text.Clean(Gbk.DecodeName(b, off, n));
    }
}

/// <summary>
/// 一个单位的属性响应（ddh v14 共享内存里的一条），带“这个字段到底有没有测到”的判断。
/// 数值格式化规则见 <see cref="FormatNumber"/> / <see cref="DamageText"/> 等。
/// v14 起 <see cref="SightDayText"/> / <see cref="SightNightText"/> 是两列独立视野
/// （jass.slk 的 sight / nsight）；<see cref="IsLocust"/> 表示该单位带 Aloc，界面会过滤掉。
/// <see cref="ExtraText"/> 仅保留给协议诊断，【战场单位】已不显示“单位附加值”列。
/// </summary>
public sealed record UnitAttrResponse(
    uint Addr, uint Flags, string TypeCode, string Name, string Title,
    float AttackRange, float DamageMin, float DamageMax, float AttackInterval,
    float Armor, float MoveSpeed, float AttackSpeed, float AcquireRange,
    float BaseSpeed, float SightDay, float SightNight, int BaseArmor,
    float Strength, float Agility, float Intelligence, int ExtraValue,
    int OwnerSlot = -1)
{
    private static readonly CultureInfo Inv = CultureInfo.InvariantCulture;

    public bool Has(uint flag) => (Flags & flag) != 0;

    /// <summary>类型码有效（4 字符）。</summary>
    public bool HasTypeCode => Has(FlagTypeCode) && TypeCode.Length > 0;

    /// <summary>单位名有效。</summary>
    public bool HasName => Has(FlagName) && Name.Length > 0;

    /// <summary>英雄称谓有效（非英雄恒 false）。</summary>
    public bool HasTitle => Has(FlagTitle) && Title.Length > 0;

    /// <summary>英雄判定可信（false = 不知道是不是英雄）。</summary>
    public bool HeroKnown => Has(FlagHeroKnown);

    /// <summary>是英雄（只有 <see cref="HeroKnown"/> 为 true 时才有意义）。</summary>
    public bool IsHero => HeroKnown && Has(FlagHero);
    public bool IsIllusion => Has(FlagIllusion);
    /// <summary>这次真的执行过 IsUnitIllusion 判定；false = 没查成，不能把 false 当结论。</summary>
    public bool IllusionChecked => Has(FlagIllusionChecked);

    /// <summary>协议 v14：该单位带 Aloc（蝗虫）→ 不进【战场单位】列表（镜像实例仍显示）。</summary>
    public bool IsLocust => Has(FlagLocust);

    /// <summary>这次真的执行过 Aloc 判定（无论结果）。false = 没查成，不能把 IsLocust 的 false 当结论。</summary>
    public bool LocustChecked => Has(FlagLocustChecked);

    public string TypeCodeText => HasTypeCode ? TypeCode : "";
    public string NameText => HasName ? Name : "";
    public string TitleText => HasTitle ? Title : "";

    public string AttackRangeText => Has(FlagAttackRange) ? FormatNumber(AttackRange) : "?";

    /// <summary>攻击力：min~max；min==max 显示单值；没测到显示 ?。</summary>
    public string DamageText
    {
        get
        {
            if (!Has(FlagDamage)) return "?";
            if (Math.Abs(DamageMax - DamageMin) < 0.005f) return FormatNumber(DamageMin);
            return FormatNumber(DamageMin) + "~" + FormatNumber(DamageMax);
        }
    }

    /// <summary>攻击间隔：两位小数 + “秒”。</summary>
    public string AttackIntervalText =>
        Has(FlagInterval) ? AttackInterval.ToString("0.00", Inv) + "秒" : "?";

    /// <summary>攻击间隔数值：两位小数、**不带单位“秒”**（【战场单位】表用）。</summary>
    public string AttackIntervalValueText =>
        Has(FlagInterval) ? AttackInterval.ToString("0.00", Inv) : "?";

    public string ArmorText => Has(FlagArmor) ? FormatNumber(Armor) : "?";
    public string MoveSpeedText => Has(FlagMoveSpeed) ? FormatNumber(MoveSpeed) : "?";
    /// <summary>v35：unit_property+0x1B0 的原始攻击速度（UnitState 81）。</summary>
    public string AttackSpeedText => Has(FlagAttackSpeed) ? FormatNumber(AttackSpeed) : "?";
    /// <summary>攻击频率 = min(攻击速度, 5) / 攻击间隔。</summary>
    public string AttackFrequencyText =>
        Has(FlagAttackSpeed) && Has(FlagInterval) && AttackInterval > 0
            ? FormatNumber(Math.Min(AttackSpeed, AttackFrequencySpeedCap) / AttackInterval)
            : "?";
    public string AcquireRangeText => Has(FlagAcquire) ? FormatNumber(AcquireRange) : "?";

    /// <summary>
    /// 【移速】列：native 移速（GetUnitMoveSpeed）优先；没有（或 0/负数，视为没测到）就退回
    /// 单位类型数据 spd；两者都没有 → ?（不拿 0 冒充）。
    /// 真机日志：自动匹配挑到 GetGameSpeed 时返回 0，ddh 又置了“移速有效”位 → 界面显示 0。
    /// ddh 侧已改成 0 不置位；这里再兜一层“0 一律按无效处理”，两边都不许拿 0 冒充移速。
    /// </summary>
    public string MoveSpeedPreferredText
    {
        get
        {
            if (Has(FlagMoveSpeed) && IsPositiveMeasured(MoveSpeed)) return FormatNumber(MoveSpeed);
            if (Has(FlagBaseSpeed) && IsPositiveMeasured(BaseSpeed)) return FormatNumber(BaseSpeed);
            return "?";
        }
    }

    /// <summary>
    /// “测到了正数”：有限、&gt; 0、不超过 100000。
    /// 0 / 负数 / NaN / ∞ 一律当作“没测到”（移速、基础速度都适用）。
    /// </summary>
    private static bool IsPositiveMeasured(float v) =>
        v > 0f && v <= 100000f && !float.IsNaN(v) && !float.IsInfinity(v);

    /// <summary>单位类型基础速度（UnitBalance spd）；没测到 ?。</summary>
    public string BaseSpeedText => Has(FlagBaseSpeed) ? FormatNumber(BaseSpeed) : "?";

    /// <summary>
    /// 【白天视野】列（协议 v14）：+177 sightDay = ddh 从 jass.slk 的 sight 字段读出的值；
    /// slk 取不到时 ddh 会退回 Game.dll+0x3ADF0 的“当前有效视野”（并把这一位同样置上）。
    /// 没置位 → ?，不拿 0 冒充。
    /// </summary>
    public string SightDayText => Has(FlagSightDay) ? FormatNumber(SightDay) : "?";

    /// <summary>
    /// 【夜晚视野】列（协议 v14）：+181 sightNight = ddh 从 jass.slk 的 nsight 字段读出的值。
    /// slk 取不到 → 没置位 → ?（不像白天那样退回内存路）。
    /// </summary>
    public string SightNightText => Has(FlagSightNight) ? FormatNumber(SightNight) : "?";

    /// <summary>旧接口：等价于 <see cref="SightDayText"/>（协议 v13 的单列“视野”）。</summary>
    public string VisionText => SightDayText;

    /// <summary>单位类型基础护甲（UnitBalance def，整数）；没测到 ?（v11 界面已不显示此列）。</summary>
    public string BaseArmorText => Has(FlagBaseArmor) ? BaseArmor.ToString(Inv) : "?";

    /// <summary>力量：测到 → 数字；确定是非英雄 → —（不适用）；不知道 → ?。</summary>
    public string StrengthText => HeroStatText(FlagStrength, Strength);

    /// <summary>敏捷：测到 → 数字；确定是非英雄 → —（不适用）；不知道 → ?。</summary>
    public string AgilityText => HeroStatText(FlagAgility, Agility);

    /// <summary>智力：测到 → 数字；确定是非英雄 → —（不适用）；不知道 → ?。</summary>
    public string IntelligenceText => HeroStatText(FlagIntelligence, Intelligence);

    /// <summary>
    /// 单位附加值（GetUnitUserData）：有效就显示整数（0 也是有效值）。
    /// v14 起【战场单位】已删除该列（points 口径不准）；属性保留只为协议/诊断。
    /// </summary>
    public string ExtraText => Has(FlagExtra) ? ExtraValue.ToString(Inv) : "?";

    /// <summary>力/敏/智：测到 → 数字；确定是非英雄 → —（不适用）；不知道 → ?。</summary>
    private string HeroStatText(uint flag, float value)
    {
        if (Has(flag)) return FormatNumber(value);
        return HeroKnown && !Has(FlagHero) ? "—" : "?";
    }

    /// <summary>“整数或一位小数”的统一格式：128 → 128，2.5 → 2.5，0.05 → 0.1（不显示 128.0）。</summary>
    public static string FormatNumber(float v)
    {
        if (float.IsNaN(v) || float.IsInfinity(v)) return "?";
        return v.ToString("0.#", Inv);
    }
}
