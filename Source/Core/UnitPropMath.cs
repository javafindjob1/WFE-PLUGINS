namespace War3DeathSettlement.Core;

/// <summary>
/// ddh.cpp v15「属性内存直读」的 C# 镜像 —— **只用于离线自检 / 口径对齐，运行期不读游戏内存**。
///
/// 真机数据是 ddh 在 32 位游戏进程里读出来、经 <see cref="UnitAttrWire"/> 的共享内存交给界面的；
/// 这里把 ddh.cpp 里的偏移、攻击力公式、合理性边界按原样再写一遍，让 <c>--selftest</c> 能验证：
///   ① 攻击力公式 min = base + bonus + dice、max = base + bonus + dice * side（YDWE 口径）；
///   ② 合理性校验：NaN / ±Inf / 超范围一律无效；
///   ③ prop 指针不可读时，范围 / 攻击力 / 间隔 / 主动 这四个 flags 位不置（界面显示 <c>?</c>）。
/// 改动这里必须同步 ddh.cpp 的 <c>DDH_OFF_PROP_*</c> / <c>DDH_ATTR_*</c> 常量与
/// <c>DdhAttrFillMemory</c> 的判断顺序，否则自检就和真机行为脱节。
/// </summary>
public static class UnitPropMath
{
    /// <summary>CUnit -> unit_property*：1.27（&gt; 1.24c）是 CUnit + 0x1E8（YDWE 的 +0x1E4 + 4）。</summary>
    public const int OffsetUnitProp = 0x1E8;

    /// <summary>
    /// 护甲不在 unit_property 里：读 CUnit + 0xE0，**按 float 解释**。
    /// 依据 YDWE UnitState.cpp 的 UNIT_STATE_ARMOR：<c>return *(uint32_t*)(unit_object + 0xE0);</c>
    /// 但函数返回 JASS 的 real，且这里没有 <c>jass::to_real</c>（ARMOR_TYPE 才有）——
    /// 等于把 4 字节位模式透传，所以字段是 float。真机 E06V 的 0x430DADBB = 141.679；
    /// 按 int 读会得到 1124969915（越界）。int32 仅在 float 不像护甲时做兼容兜底。
    /// </summary>
    public const int OffsetUnitArmor = 0xE0;

    // unit_property 的类内偏移（YDWE UnitState.cpp，1.27 口径）
    public const int OffsetDamageDice = 0x88;
    public const int OffsetDamageSide = 0x94;
    public const int OffsetDamageBase = 0xA0;
    public const int OffsetDamageBonus = 0xAC;
    public const int OffsetAttackInterval = 0x158;
    /// <summary>YDWE UNIT_STATE_RATE_OF_FIRE (0x51/81)：unit_property + 0x1B0。</summary>
    public const int OffsetRateOfFire = 0x1B0;
    public const int OffsetAcquireRange = 0x244;
    public const int OffsetAttackRange = 0x258;

    // 合理性边界（与 ddh.cpp 的 DDH_ATTR_RANGE_MAX / _INTERVAL_* / _ARMOR_* / _DAMAGE_MAX 一致）
    public const float RangeMin = 0f;
    public const float RangeMax = 5000f;
    public const float IntervalMin = 0.05f;
    public const float IntervalMax = 10f;
    public const float RateOfFireMin = 0.0001f;
    public const float RateOfFireMax = 10000f;
    public const float ArmorMin = -100f;
    public const float ArmorMax = 1000f;
    public const float DamageMin = 0f;
    public const float DamageMax = 1_000_000f;
    public const int DiceMax = 1000;
    public const int DamageIntMax = 1_000_000;

    /// <summary>有限 + 落在 [lo, hi]（NaN / ±Inf 一律 false）。</summary>
    public static bool Fits(float v, float lo, float hi) =>
        !float.IsNaN(v) && !float.IsInfinity(v) && v >= lo && v <= hi;

    /// <summary>
    /// YDWE 攻击力公式：<c>min = base + bonus + dice</c>，<c>max = base + bonus + dice * side</c>。
    /// 64 位算防溢出；dice/side/base/bonus 离谱、min &lt; 0、max &lt; min、max &gt; 1e6 都返回 false
    /// （= ddh 认为读到了垃圾，字段无效）。
    /// </summary>
    public static bool TryDamage(int dice, int side, int baseDamage, int bonus,
                                 out float min, out float max)
    {
        min = max = 0f;
        if (dice < 0 || dice > DiceMax) return false;
        if (side < 0 || side > DiceMax) return false;
        if (baseDamage < -DamageIntMax || baseDamage > DamageIntMax) return false;
        if (bonus < -DamageIntMax || bonus > DamageIntMax) return false;

        long lo = (long)baseDamage + bonus + dice;
        long hi = (long)baseDamage + bonus + (long)dice * side;
        if (lo < 0 || hi < lo) return false;
        if (hi > (long)DamageMax) return false;
        min = lo;
        max = hi;
        return true;
    }

    /// <summary>
    /// ddh 一次内存直读会置哪些属性 flags（不含 typeCode / name / title / hero —— 那些不来自 prop）。
    /// <paramref name="propReadable"/> = false（CUnit+0x1E8 为 0 / 坏指针 / 未对齐）时，
    /// 范围 / 攻击力 / 间隔 / 主动 全部无效，只有护甲还有机会——它读的是 CUnit+0xE0，不依赖 prop。
    /// </summary>
    public static uint MemoryFlags(bool propReadable, float range, float interval, float acquire,
                                   int dice, int side, int baseDamage, int bonus, int armor,
                                   float rateOfFire = 0f)
    {
        uint flags = 0;
        if (propReadable)
        {
            if (Fits(range, RangeMin, RangeMax)) flags |= UnitAttrWire.FlagAttackRange;
            if (TryDamage(dice, side, baseDamage, bonus, out _, out _)) flags |= UnitAttrWire.FlagDamage;
            if (Fits(interval, IntervalMin, IntervalMax)) flags |= UnitAttrWire.FlagInterval;
            if (Fits(rateOfFire, RateOfFireMin, RateOfFireMax)) flags |= UnitAttrWire.FlagAttackSpeed;
            if (Fits(acquire, RangeMin, RangeMax)) flags |= UnitAttrWire.FlagAcquire;
        }
        if (Fits(armor, ArmorMin, ArmorMax)) flags |= UnitAttrWire.FlagArmor;
        return flags;
    }
}
