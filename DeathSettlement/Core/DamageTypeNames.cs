namespace War3DeathSettlement.Core;

/// <summary>
/// 攻击类型 / 伤害类型的显示名。
///
/// ⚠ 重要说明：插件日志里这两列是**原始数字**（插件自己的口径就是"中文字段名 + 原始数字"，
/// 见 `伤害监视说明.md`：`来源 魔狼人 是否攻击:1 是否远程:1 攻击类型:2 伤害类型:4 伤害:154.7`）。
/// 所以本软件**始终把原始数字显示出来**，名字只是"顺带的注解"，而且可以在 ini 里改：
///
///     atype_labels=1=普通,2=近战,3=穿刺,4=攻城,5=魔法,6=混乱,7=英雄
///     dtype_labels=4=普通,5=强化,8=火焰,9=冰霜,10=闪电,11=毒,12=疾病,13=神圣,14=魔法,18=死亡
///
/// 默认值取本仓库文档里那两组枚举的顺序（`DAMAGETIP_NORMAL/MELEE/PIERCE/SIEGE/MAGIC/CHAOS/HERO`
/// 与 `DAMAGE_*`），**只是"按顺序翻译"，未在你的地图上实测过**；数字永远是对的。
/// </summary>
public static class DamageTypeNames
{
    private static Dictionary<int, string> _attack = new()
    {
        [0] = "未知",
        [1] = "普通",
        [2] = "近战",
        [3] = "穿刺",
        [4] = "攻城",
        [5] = "魔法",
        [6] = "混乱",
        [7] = "英雄",
    };

    private static Dictionary<int, string> _damage = new()
    {
        [0] = "未知",
        [1] = "未知1",
        [2] = "未知2",
        [3] = "未知3",
        [4] = "普通",
        [5] = "强化",
        [6] = "未知6",
        [7] = "未知7",
        [8] = "火焰",
        [9] = "冰霜",
        [10] = "闪电",
        [11] = "毒",
        [12] = "疾病",
        [13] = "神圣",
        [14] = "魔法",
        [15] = "音波",
        [16] = "酸",
        [17] = "力场",
        [18] = "死亡",
        [19] = "精神",
        [20] = "自然",
        [21] = "防御",
        [22] = "爆破",
        [23] = "缓慢毒",
        [24] = "灵魂链",
        [25] = "暗影突袭",
        [26] = "通用",
    };

    /// <summary>攻击类型 → “3-穿刺”这种写法；没名字就只写数字。</summary>
    public static string Attack(int id) =>
        _attack.TryGetValue(id, out var n) && n.Length > 0 ? $"{id}-{n}" : id.ToString();

    /// <summary>伤害类型 → “4-普通”这种写法；没名字就只写数字。</summary>
    public static string Damage(int id) =>
        _damage.TryGetValue(id, out var n) && n.Length > 0 ? $"{id}-{n}" : id.ToString();

    /// <summary>从 ini 的 `1=普通,2=近战` 这种字符串覆盖默认表（用户觉得名不对时改这个）。</summary>
    public static void Override(string? attackSpec, string? damageSpec)
    {
        var a = Parse(attackSpec);
        if (a.Count > 0) _attack = a;
        var d = Parse(damageSpec);
        if (d.Count > 0) _damage = d;
    }

    private static Dictionary<int, string> Parse(string? spec)
    {
        var map = new Dictionary<int, string>();
        if (string.IsNullOrWhiteSpace(spec)) return map;
        foreach (var part in spec.Split(new[] { ',', ';', '|' }, StringSplitOptions.RemoveEmptyEntries))
        {
            int eq = part.IndexOf('=');
            if (eq <= 0) continue;
            if (int.TryParse(part[..eq].Trim(), out int id))
                map[id] = part[(eq + 1)..].Trim();
        }
        return map;
    }
}
