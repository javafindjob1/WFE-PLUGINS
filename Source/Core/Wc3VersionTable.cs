namespace War3DeathSettlement.Core;

/// <summary>
/// War3Trainer 内置的 13 个版本地址表（版本串 → 各全局的 RVA）。
/// 数据来源：反编译 War3Trainer.exe（GameContext::GetGameAddress / GetGameOffset 的 IL 立即数）。
///
/// 本表由工具脚本从 IL 里抠出；若某个版本行缺失，只会影响该版本能否连接，
/// 不影响 1.27.0.52240（当前游戏）的使用。
/// </summary>
internal static class Wc3VersionTable
{
    /// <summary>(版本串, ThisGame RVA, UnitList/ctx RVA, MoveSpeed RVA, 战斗属性偏移, 英雄属性偏移)</summary>
    internal static readonly (string Version, uint ThisGame, uint UnitList, uint MoveSpeed, uint AttackOff, uint HeroOff)[] Rows =
    {
        // 行序 = IL 里 Dictionary<版本串,int> 的索引序（GetGameAddress / GetGameOffset 各有一份，完全一致）。
        // 前 3 列来自 GameContext::GetGameAddress 的 switch(13)；后 2 列来自 GameContext::GetGameOffset 的 switch(13)。
        ("1.20.4.6074", 0x0087C744u, 0x008722BCu, 0x0055BDF0u, 0x000001E4u, 0x000001ECu),
        ("1.21.0.6263", 0x0087D7BCu, 0x00873334u, 0x0055FE80u, 0x000001E4u, 0x000001ECu),
        ("1.21.1.6300", 0x0087D7BCu, 0x00873334u, 0x0055FEA0u, 0x000001E4u, 0x000001ECu),
        ("1.22.0.6328", 0x00AA4178u, 0x00AA2FFCu, 0x00201190u, 0x000001E4u, 0x000001ECu),
        ("1.23.0.6352", 0x00ABCFC8u, 0x00ABBE4Cu, 0x002026D0u, 0x000001E4u, 0x000001ECu),
        ("1.24.0.6372", 0x00ACE5E0u, 0x00ACD44Cu, 0x00202780u, 0x000001E4u, 0x000001ECu),
        ("1.24.1.6374", 0x00ACE5E0u, 0x00ACD44Cu, 0x00202780u, 0x000001E4u, 0x000001ECu),
        ("1.24.2.6378", 0x00ACE5E0u, 0x00ACD44Cu, 0x00202780u, 0x000001E4u, 0x000001ECu),
        ("1.24.3.6384", 0x00ACE5E0u, 0x00ACD44Cu, 0x00202780u, 0x000001E8u, 0x000001F0u),
        ("1.24.4.6387", 0x00ACE5E0u, 0x00ACD44Cu, 0x002027E0u, 0x000001E8u, 0x000001F0u),
        ("1.25.1.6397", 0x00AB7788u, 0x00AB65F4u, 0x00201AA0u, 0x000001E8u, 0x000001F0u),
        ("1.26.0.6401", 0x00AB7788u, 0x00AB65F4u, 0x00201CD0u, 0x000001E8u, 0x000001F0u),
        // ---- 这一行是保底：1.27.0.52240（本机游戏）已由 选区内存定位2.md §1.2 与 War3Trainer IL 双重确证。
        ("1.27.0.52240", 0x00BE40A8u, 0x00BE4238u, 0x005DF420u, 0x000001E8u, 0x000001F0u),
    };
}
