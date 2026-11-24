namespace War3DeathSettlement.Core;

/// <summary>
/// 用一条**致命伤害事件**兜底补建死亡结算。
///
/// 场景：有些单位（召唤物、刚出生/刚进图、只在钩子里出现过的单位）扫描账本还没见过它，
/// 就被一击打到 0 血；等扫描发现时对象已经没了 —— DamageTracker 没有“上一帧血量”，
/// 不会生成结算，于是界面看起来“明明死了却没有死亡结算”。
/// 钩子事件本身带着 HP 前/后值和伤害来源，足够补一条：
///   · DiedAt = 事件时间；Kind = 死亡；总伤害 = 实际净掉血；
///   · 血量上限没读到，用“死前血量”代替（属性表会显示首次见到/上限，来源列有说明）；
///   · 来源/组合行由这一笔事件直接算；之后正常结算出现时会替换掉这条补建。
/// </summary>
public static class HookDeath
{
    /// <summary>从一条钩子事件补建死亡结算；不是“致命”（死前>0、死后>0）或信息不足时返回 null。</summary>
    public static Settlement? FromLethalEvent(DamageHook.HookEvent e, string fallbackName = "")
    {
        if (!e.HpValid) return null;                       // 没读到血，不能确认是死亡
        if (e.HpBefore <= 0.01f || e.HpAfter > 0.01f) return null;
        if (e.Victim == 0 || string.IsNullOrEmpty(e.VictimCode)) return null;

        double damage = e.Actual > 0.005 ? e.Actual
                      : Math.Max(0, e.HpBefore - e.HpAfter);
        if (damage <= 0.005 && e.Amount <= 0.005) return null;

        return new Settlement
        {
            Addr = e.Victim,
            TypeCode = e.VictimCode,
            UnitName = e.VictimName.Length > 0 ? e.VictimName : fallbackName,
            OwnerSlot = e.VictimOwner,
            Kind = "死亡",
            DiedAt = e.At,
            FirstSeen = e.At,                  // 之前没见过它，只能按“死前一瞬”算
            HitCount = 1,
            TotalDamage = damage,
            MaxHit = damage,
            MinHit = damage,
            Peak1s = damage,
            HpMax = e.HpBefore,                // 上限没读到：用死前血量占位
            HpAtFirstSeen = (float)e.HpBefore,
            HookDamageScale = 1.0,
            HookMatchNote = "由致命伤害事件补建（该单位没被扫描到，HP 上限未知）",
            SyntheticHookDeath = true,
        };
    }
}
