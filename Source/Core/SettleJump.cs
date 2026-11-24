namespace War3DeathSettlement.Core;

/// <summary>
/// 死亡结算页双击 → 跳【伤害事件】页按地址过滤的辅助逻辑（纯函数，供界面与自检共用）。
/// </summary>
public static class SettleJump
{
    /// <summary>
    /// 地址过滤谓词：这条伤害事件是否“属于”该单位 —— 它是事件的来源（打人者）或触发/受害单位（挨打者）。
    /// </summary>
    public static bool MatchesAddr(DamageHook.HookEvent e, uint addr) =>
        e.Source == addr || e.Victim == addr;

    /// <summary>结算行的双击目标：地址 + 显示名（名字优先，空则退回类型码）。</summary>
    public static (uint Addr, string Name) FromSettlement(Settlement s) =>
        (s.Addr, s.UnitName.Length > 0 ? s.UnitName : s.TypeCode);

    /// <summary>存活行的双击目标：地址 + 显示名（名字优先，空则退回类型码）。</summary>
    public static (uint Addr, string Name) FromLiveUnit(uint addr, string typeCode, string name) =>
        (addr, name.Length > 0 ? name : typeCode);
}
