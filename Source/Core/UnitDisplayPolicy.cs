namespace War3DeathSettlement.Core;

/// <summary>
/// 战场单位的可见性规则。引擎快照层和界面行生成层共用，避免只修一层仍被另一层过滤。
/// </summary>
internal static class UnitDisplayPolicy
{
    /// <summary>
    /// 普通蝗虫隐藏；镜像无论是否蝗虫都显示。
    /// 同类型存在镜像时，原单位也显示，避免 locust=1 的原单位被幻象行覆盖。
    /// </summary>
    public static bool ShouldDisplay(bool isLocust, bool isIllusion, bool hasIllusionSibling = false) =>
        isIllusion || hasIllusionSibling || !isLocust;
}
