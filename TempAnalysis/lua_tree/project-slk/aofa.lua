--[[
-- 奥法被动技能
local aofa_beidong1 =
    hslk_ability(
    {
        Art = "ReplaceableTextures\\PassiveButtons\\PASBTNThorns.blp",
        Name = "专注魔法",
        Ubertip = "|cffffcc00专注魔法|r: 你的普通攻击将没有伤害,但是体内有强烈的魔法能量溢出。战斗状态下,每隔1.5秒会产生一个小飞弹对目标造成100%主属性魔法伤害。",
        _parent = "AOcr",
        Buttonpos_1 = 0,
        Buttonpos_2 = 0,
        DataA = 0,
        Untip = "专注魔法",
        hero = 0,
        levels = 1,
        race = "human"
    }
)

local aofa_beidong2 =
    hslk_ability(
    {
        Art = "ReplaceableTextures\\PassiveButtons\\PASBTNTrueShot.blp",
        Name = "奥术充能",
        Ubertip = "|cffffcc00奥术充能|r: 使用奥术冲击Q时会获得1层奥术充能,上限4层,持续15秒。奥术充能会使奥法的技能获得加强。|nQ奥术冲击：每层使奥术冲击的伤害提高50%,并且法力消耗提高12点。|nW奥术弹幕：每层使奥术弹幕的伤害提高50%,并且每层充能会使奥术弹幕能够攻击范围内额外一个目标。|nR奥术飞弹：每层使奥术飞弹的伤害提高50%。|nD唤醒：每层使唤醒的所需的引导时间降低0.5秒。",
        _parent = "AOcr",
        Buttonpos_1 = 1,
        Buttonpos_2 = 0,
        DataA = 0,
        Untip = "奥术充能",
        hero = 0,
        levels = 1,
        race = "human"
    }
)

local aofa_beidong3 =
    hslk_ability(
    {
        Art = "ReplaceableTextures\\PassiveButtons\\PASBTNMagicalAttack.blp",
        Name = "节能施法",
        Ubertip = "|cffffcc00节能施法|r: 造成的所有魔法伤害有10%使下一次技能不再消耗蓝量。",
        _parent = "AOcr",
        Buttonpos_1 = 0,
        Buttonpos_2 = 1,
        DataA = 0,
        Untip = "节能施法",
        hero = 0,
        levels = 1,
        race = "human"
    }
)

local aofa_beidong4 =
    hslk_ability(
    {
        Art = "ReplaceableTextures\\PassiveButtons\\PASBTNElunesBlessing.blp",
        Name = "奥术心智",
        Ubertip = "|cffffcc00奥术心智|r: 当你穿上4件布甲,你的智力提高10%,魔法值上限提高50点,并且魔法值每秒回复+1。",
        _parent = "AOcr",
        Buttonpos_1 = 1,
        Buttonpos_2 = 1,
        DataA = 0,
        Untip = "奥术心智",
        hero = 0,
        levels = 1,
        race = "human"
    }
)

local aofa_beidong5 =
    hslk_ability(
    {
        Art = "ReplaceableTextures\\PassiveButtons\\PASBTNImprovedBash.blp",
        Name = "飞弹速射",
        Ubertip = "|cffffcc00飞弹速射|r: 奥术冲击Q有20%概率强化你的奥术飞弹,使其引导时间缩短1秒。",
        _parent = "AOcr",
        Buttonpos_1 = 2,
        Buttonpos_2 = 0,
        DataA = 0,
        Untip = "飞弹速射",
        hero = 0,
        levels = 1,
        race = "human"
    }
)

local aofa_beidong6 =
    hslk_ability(
    {
        Art = "ReplaceableTextures\\PassiveButtons\\PASBTNEvasion.blp",
        Name = "最后一搏",
        Ubertip = "|cffffcc00最后一搏|r: 使用闪现会获得一个相当于最大生命值30%的护盾,持续30秒,冷却30秒。",
        _parent = "AOcr",
        Buttonpos_1 = 2,
        Buttonpos_2 = 1,
        DataA = 0,
        Untip = "最后一搏",
        hero = 0,
        levels = 1,
        race = "human"
    }
)

local aofa_beidong7 =
    hslk_ability(
    {
        Art = "ReplaceableTextures\\PassiveButtons\\PASBTNCriticalStrike.blp",
        Name = "奥术潜能",
        Ubertip = "|cffffcc00奥术潜能|r: 消耗节能施法会使该技能暴击提高30%。",
        _parent = "AOcr",
        Buttonpos_1 = 3,
        Buttonpos_2 = 0,
        DataA = 0,
        Untip = "奥术潜能",
        hero = 0,
        levels = 1,
        race = "human"
    }
)

local aofa_beidong8 =
    hslk_ability(
    {
        Art = "ReplaceableTextures\\PassiveButtons\\PASBTNThorns.blp",
        Name = "气流",
        Ubertip = "|cffffcc00气流|r: 每10秒获得一层气流状态,该状态下法师的下个技能可以在移动中施法和引导,上限2层。",
        _parent = "AOcr",
        Buttonpos_1 = 3,
        Buttonpos_2 = 1,
        DataA = 0,
        Untip = "气流",
        hero = 0,
        levels = 1,
        race = "human"
    }
)

local aofa_beidong9 =
    hslk_ability(
    {
        Art = "ReplaceableTextures\\PassiveButtons\\PASBTNAdeptTraining.blp",
        Name = "时间扭曲",
        Ubertip = "|cffffcc00时间扭曲|r: 使用奥术强化T时会使团队1000码内所有友军的技能急速和攻速提高35%。",
        _parent = "AOcr",
        Buttonpos_1 = 4,
        Buttonpos_2 = 0,
        DataA = 0,
        Untip = "时间扭曲",
        hero = 0,
        levels = 1,
        race = "human"
    }
)

local aofa_beidong = {
    _parent = "Aspb",
    Art = "ReplaceableTextures\\CommandButtons\\BTNAcolyte.blp",
    Name = "奥法被动",
    Hotkey = "V",
    Buttonpos_1 = 3,
    Buttonpos_2 = 1,
    Ubertip = "点击查看所有被动技能",
    DataA = aofa_beidong1._id ..
        "," ..
            aofa_beidong2._id ..
                "," ..
                    aofa_beidong3._id ..
                        "," ..
                            aofa_beidong4._id ..
                                "," ..
                                    aofa_beidong5._id ..
                                        "," ..
                                            aofa_beidong6._id ..
                                                "," ..
                                                    aofa_beidong7._id ..
                                                        "," .. aofa_beidong8._id .. "," .. aofa_beidong9._id,
    DataB = 0,
    DataC = 9,
    DataD = 9,
    DataE = "ancestralspirittarget"
}

-- 奥法主动技能
hslk_ability(
    {
        _parent = "Aspb",
        Art = "ReplaceableTextures\\CommandButtons\\BTNBlizzard.blp",
        Name = "奥术冲击",啦啦啦
        Hotkey = "Q",
        Rng = 800,
        DataA = 0.1,
        DataB = 1,
        DataC = 1,
        DataD = 0.1,
        DataE = 0,
        DataF = CONST_ABILITY_ORDER[1],
        EditorSuffix = "aofa",
        Ubertip = "|cffffcc00奥术冲击|r: 释放奥术能量冲击目标,对其造成主属性100%的魔法伤害。|n伤害公式:智力值 × 100%|n法力消耗:8点|n冷却时间:1秒|n|cffffcc00奥术充能|r效果:每层使伤害提高50%,法力消耗提高12点。",
        Cool = 1,
        Cost = 8,
        levels = 1,
        race = "human",
        targs = "enemy",
        Area = 0,
        CasterArt = "",
        CasterAttachCount = 0,
        TargetArt = "",
        Missileart = "Abilities\\Weapons\\FrostWyrmMissile\\FrostWyrmMissile.mdl",
        MissileSpeed = 1000,
        MissileHoming = 1
    }
)

hslk_ability(
    {
        _parent = "Aspb",
        Art = "ReplaceableTextures\\CommandButtons\\BTNFaerieDragonMissile.blp",
        Name = "奥术弹幕",
        Hotkey = "W",
        Rng = 600,
        DataA = 0,
        DataB = 3,
        DataC = 1,
        DataD = 0,
        DataE = 0,
        DataF = CONST_ABILITY_ORDER[2],
        EditorSuffix = "aofa",
        Ubertip = "|cffffcc00奥术弹幕|r: 向范围内目标发射3枚飞弹,造成主属性100%的魔法伤害,晕眩目标1秒,并且清除掉自身的所有的奥术充能状态。|n伤害公式:智力值 × 100% × 飞弹数|n法力消耗:10点|n冷却时间:5秒|n|cffffcc00奥术充能|r效果:每层使伤害提高50%,额外攻击1个目标。",
        Cool = 5,
        Cost = 10,
        levels = 1,
        race = "human",
        targs = "enemies",
        Area = 300,
        CasterArt = "",
        CasterAttachCount = 0,
        TargetArt = "",
        Missileart = "",
        MissileSpeed = 0,
        MissileHoming = 0
    }
)

hslk_ability(
    {
        _parent = "Aspb",
        Art = "ReplaceableTextures\\CommandButtons\\BTNBlink.blp",
        Name = "闪现术",
        Hotkey = "E",
        Rng = 1000,
        DataA = 0,
        DataB = 2,
        DataC = 0,
        DataD = 0,
        DataE = 0,
        DataF = CONST_ABILITY_ORDER[3],
        EditorSuffix = "aofa",
        Ubertip = "|cffffcc00闪现术|r: 瞬间移动到目标地点。",
        Cool = 10,
        Cost = 0,
        levels = 1,
        race = "human",
        targs = "ground",
        Area = 0,
        CasterArt = "",
        CasterAttachCount = 0,
        TargetArt = "",
        Missileart = "",
        MissileSpeed = 0,
        MissileHoming = 0
    }
)

hslk_ability(
    {
        _parent = "Aspb",
        Art = "ReplaceableTextures\\CommandButtons\\BTNPhoenixMissile.blp",
        Name = "奥术飞弹",
        Hotkey = "R",
        Rng = 800,
        DataA = 2,
        DataB = 1,
        DataC = 1,
        DataD = 2,
        DataE = 0,
        DataF = CONST_ABILITY_ORDER[4],
        EditorSuffix = "aofa",
        Ubertip = "|cffffcc00奥术飞弹|r: 使用连续的4枚飞弹攻击目标,每枚飞弹造成主属性25%的魔法伤害。|n伤害公式:智力值 × 25% × 4|n法力消耗:10点|n引导时间:2秒|n冷却时间:10秒|n|cffffcc00奥术充能|r效果:每层使伤害提高50%。",
        Cool = 10,
        Cost = 10,
        levels = 1,
        race = "human",
        targs = "enemy",
        Area = 0,
        CasterArt = "",
        CasterAttachCount = 0,
        TargetArt = "",
        Missileart = "Abilities\\Weapons\\FireBallMissile\\FireBallMissile.mdl",
        MissileSpeed = 1500,
        MissileHoming = 1
    }
)

hslk_ability(
    {
        _parent = "Aspb",
        Art = "ReplaceableTextures\\CommandButtons\\BTNManaFlare.blp",
        Name = "唤醒",
        Hotkey = "D",
        Rng = 99999,
        DataA = 3,
        DataB = 0,
        DataC = 1,
        DataD = 3,
        DataE = 0,
        DataF = CONST_ABILITY_ORDER[5],
        EditorSuffix = "aofa",
        Ubertip = "|cffffcc00唤醒|r: 唤起法力的风暴,为自身回复90%魔法值。|n法力回复:90% (每秒30%)|n引导时间:3秒|n冷却时间:60秒|n|cffffcc00奥术充能|r效果:每层使引导时间减少0.5秒。",
        Cool = 60,
        Cost = 0,
        levels = 1,
        race = "human",
        targs = "none",
        Area = 0,
        CasterArt = "",
        CasterAttachCount = 0,
        TargetArt = "",
        Missileart = "",
        MissileSpeed = 0,
        MissileHoming = 0
    }
)

hslk_ability(
    {
        _parent = "Aspb",
        Art = "ReplaceableTextures\\CommandButtons\\BTNRunedBracers.blp",
        Name = "奥术强化",
        Hotkey = "T",
        Rng = 99999,
        DataA = 0,
        DataB = 0,
        DataC = 1,
        DataD = 0,
        DataE = 0,
        DataF = CONST_ABILITY_ORDER[6],
        EditorSuffix = "aofa",
        Ubertip = "|cffffcc00奥术强化|r: 你的全局伤害提高20%,技能消耗降低30%,持续15秒。|n冷却时间:90秒",
        Cool = 90,
        Cost = 0,
        levels = 1,
        race = "human",
        targs = "none",
        Area = 0,
        CasterArt = "",
        CasterAttachCount = 0,
        TargetArt = "",
        Missileart = "",
        MissileSpeed = 0,
        MissileHoming = 0
    }
)
]]
