local tianfu =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\ability_warlock_demonicpower.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- 暴击率 设置为0
        DataA = 0,
        -- 说明
        Ubertip = "|cffffcc00恶魔形态|r：恶魔天生精通混乱伤害，每15点精通提升你1%的混乱伤害，初始为15%。",
        -- Name
        Name = "恶魔形态",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "1",
        reqLevel = 15
    }
)

local zhanshi_beidong1 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\inv_weapon_shortblade_92.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "恶魔之刃",
        Tip = "恶魔之刃",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00恶魔之刃|r：你的普通攻击将触发恶魔之刃，造成100%（攻击+敏捷）的混乱物理伤害，并回复20点恶魔能量，冷却时间为3秒。",
        -- Tooltip - Turn Off
        Untip = "恶魔之刃",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "2",
        reqLevel = 15
    }
)

local zhanshi_beidong2 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\ability_demonhunter_hatefulstrike.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "裂魂",
        -- Tooltip - Normal
        Tip = "裂魂",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00裂魂|r：投掷利刃会对目标造成每秒造成80%敏捷的混乱物理伤害，持续6秒。",
        -- Tooltip - Turn Off
        Untip = "裂魂",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "4",
        reqLevel = 15
    }
)

local zhanshi_beidong3 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\ability_foundryraid_demolition.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "势如破竹",
        Tip = "势如破竹",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00势如破竹|r：邪能冲撞会让你获得10%的伤害提升效果（独立增伤），持续5秒。",
        -- Tooltip - Turn Off
        Untip = "势如破竹",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "6",
        reqLevel = 15
    }
)

local zhanshi_beidong4 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\inv_glaive_1h_artifactaldrochi_d_03dual.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "混沌理论",
        -- Tooltip - Normal
        Tip = "混沌理论",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00混沌理论|r：刃舞使你的下一个混乱打击暴击几率提高30%，且伤害提高10%。",
        -- Tooltip - Turn Off
        Untip = "混沌理论",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "8",
        reqLevel = 15
    }
)

local zhanshi_beidong5 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\ability_demonhunter_soulcleave2.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "无情强攻",
        reqLevel = 15,
        -- Tooltip - Normal
        Tip = "无情强攻",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00无情强攻|r：恶魔猎手的混乱打击有15%的几率触发第二次混乱打击。",
        -- Tooltip - Turn Off
        Untip = "无情强攻",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "9"
    }
)

local zhanshi_beidong6 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\sha_spell_warlock_demonsoul_nightmare.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "绝望本能",
        Tip = "绝望本能",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00绝望本能|r：受到致命伤害时免疫当前伤害，并恢复生命值至30%最大生命值，并让你获得50%闪避和移速，持续5秒，技能CD180秒。",
        -- Tooltip - Turn Off
        Untip = "绝望本能",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "10",
        reqLevel = 15
    }
)

local zhanshi_beidong7 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\ability_demonhunter_eyeofleotheras.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "致命眼神",
        -- Tooltip - Normal
        Tip = "致命眼神",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "12",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00致命眼神|r：眼棱的伤害必定暴击。",
        -- Tooltip - Turn Off
        Untip = "致命眼神",
        reqLevel = 15
    }
)

local zhanshi_beidong8 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\inv_glaive_1h_artifactaldorchi_d_06.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "恶魔气息",
        Tip = "恶魔气息",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00恶魔气息|r：恶魔的气息鼓舞着友军，增加周围单位8%攻击速度。",
        -- Tooltip - Turn Off
        Untip = "恶魔气息",
        reqLevel = 15,
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "14",
        _guanghuanAttr = _attr({attack_speed = "+8"})
    }
)

local zhanshi_beidong9 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\spell_shadow_demonform.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "魔化",
        Tip = "魔化",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "15",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00魔化|r：释放眼棱会使你进入恶魔形态，持续10秒，如果恶魔猎手已经处于变身状态，则会增加持续时间，恶魔变形的剩余持续时间不会长于30秒。",
        -- Tooltip - Turn Off
        Untip = "魔化",
        reqLevel = 15
    }
)

local zhanshi_beidong10 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\ability_demonhunter_throwglaive.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "战刃艺术",
        Tip = "战刃艺术",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "16",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00战刃艺术|r：使你的投掷战刃造成伤害提高30%并变为混乱伤害，同时强化你的下一次混乱打击和刃舞。混乱打击触发无情强攻概率翻倍，刃舞伤害增加1段。",
        -- Tooltip - Turn Off
        Untip = "战刃艺术",
        reqLevel = 15
    }
)

local beidong =
    hslk_ability(
    {
        _parent = "Aspb",
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\spell_shadow_demonform.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 3,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- Spell List
        DataA = zhanshi_beidong1._id ..
            "," ..
                zhanshi_beidong2._id ..
                    "," ..
                        zhanshi_beidong3._id ..
                            "," ..
                                zhanshi_beidong4._id ..
                                    "," ..
                                        zhanshi_beidong5._id ..
                                            "," ..
                                                zhanshi_beidong6._id ..
                                                    "," ..
                                                        zhanshi_beidong7._id ..
                                                            "," ..
                                                                zhanshi_beidong8._id ..
                                                                    "," ..
                                                                        zhanshi_beidong9._id ..
                                                                            "," .. zhanshi_beidong10._id,
        -- Shared Spell Cooldown
        DataB = 0,
        -- Minimum Spells
        DataC = 12,
        -- Maximum Spells
        DataD = 12,
        -- Base Order ID
        DataE = "ancestralspirittarget",
        Hotkey = "V",
        -- Name
        Name = "恶魔猎手被动技能",
        Ubertip = "点击打开被动技能列表"
    }
)

local zhudong1 =
    hslk_ability(
    {
        _parent = "ANcl",
        -- Animation Names
        Animnames = "attack",
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\ability_demonhunter_throwglaive.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 8.0,
        -- Mana Cost
        Cost = 0,
        -- Follow Through Time
        DataA = 0.2,
        -- Target Type
        DataB = 1,
        -- Options
        DataC = 1,
        -- Art Duration
        DataD = 0.2,
        -- Disable Other Abilities
        DataE = 0,
        -- Base Order ID
        DataF = CONST_ABILITY_ORDER[1],
        -- Editor Suffix
        EditorSuffix = "恶魔猎手",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "Q",
        -- Name
        Name = "投掷利刃",
        -- Cast Range
        Rng = 700.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "投掷利刃",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00投掷利刃|r：向目标投掷恶魔战刃，造成100%（攻击+敏捷）金系物理伤害并打断目标施法。该技能会弹射附近两个单位，每击中一个目标回复5点恶魔能量。",
        -- Tooltip - Turn Off
        Untip = "投掷利刃",
        -- Hero Ability
        hero = 0,
        -- Levels
        levels = 1, -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "1",
        -- Race
        race = "human",
        -- Targets Allowed
        targs = "enemies"
    }
)

local zhudong2 =
    hslk_ability(
    {
        _parent = "ANcl",
        -- Animation Names
        Animnames = "attack slam",
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\ability_demonhunter_bladedance.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 1,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 8,
        -- Mana Cost
        Cost = 30,
        -- Follow Through Time
        DataA = 0,
        -- Target Type
        -- DataB = 1,
        -- Options
        DataC = 1,
        -- Art Duration
        DataD = 0,
        -- Disable Other Abilities
        DataE = 0,
        -- Base Order ID
        DataF = CONST_ABILITY_ORDER[3],
        -- Editor Suffix
        EditorSuffix = "恶魔猎手",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "W",
        -- Name
        Name = "刃舞",
        -- Cast Range
        Rng = 150.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "刃舞",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00刃舞|r：恶魔猎手召唤持刃幻影快速穿梭攻击路径上的敌人3次，每次造成120%（攻击+敏捷）金系物理伤害。",
        -- Tooltip - Turn Off
        Untip = "刃舞",
        -- Hero Ability
        hero = 0,
        -- Levels
        levels = 1,
        -- Race
        race = "human",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "3",
        -- Targets Allowed
        targs = "enemies"
    }
)

local zhudong3 =
    hslk_ability(
    {
        _parent = "ANcl",
        -- Animation Names
        Animnames = "",
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\ability_demonhunter_felrush.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 2,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 20.0,
        -- Mana Cost
        Cost = 0,
        -- Follow Through Time
        DataA = 0,
        -- Target Type
        DataB = 2,
        -- Options
        DataC = 1,
        -- Art Duration
        DataD = 0,
        -- Disable Other Abilities
        DataE = 0,
        -- Base Order ID
        DataF = CONST_ABILITY_ORDER[2],
        -- Editor Suffix
        EditorSuffix = "邪能冲撞",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "E",
        -- Name
        Name = "邪能冲撞", -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "5",
        -- Cast Range
        Rng = 9000.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "邪能冲撞",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00邪能冲撞|r：对目标地点冲锋，对路径上敌人造成150%（攻击+敏捷）金系物理伤害，击中敌人回复30点能量，同时可以打断敌人施法，冲撞最大距离为700。",
        -- Tooltip - Turn Off
        Untip = "邪能冲撞",
        -- Hero Ability
        hero = 0,
        -- Levels
        levels = 1,
        -- Race
        race = "human",
        -- Targets Allowed
        targs = "enemy"
        -- Area = 300
    }
)

local zhudong4 =
    hslk_ability(
    {
        _parent = "ANcl",
        -- Animation Names
        Animnames = "Attack",
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\ability_demonhunter_chaosstrike.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 3,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 0.1,
        -- Mana Cost
        Cost = 40,
        -- Follow Through Time
        DataA = 0.1,
        -- Target Type
        DataB = 1,
        -- Options
        DataC = 1,
        -- Art Duration
        DataD = 0.1,
        -- Disable Other Abilities
        DataE = 0,
        -- Base Order ID
        DataF = CONST_ABILITY_ORDER[4],
        -- Editor Suffix
        EditorSuffix = "恶魔猎手",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "R",
        -- Name
        Name = "混乱打击",
        -- Cast Range
        Rng = 200.0,
        -- Target
        TargetArt = "",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "7",
        -- Tooltip - Normal
        Tip = "混乱打击",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00混乱打击|r：挥舞双刃，消耗大量恶魔能量对目标进行一次强力的混乱打击，造成两次150%（攻击+敏捷）的金系物理伤害，两次伤害的暴击均会恢复恶魔猎手10点恶魔能量。",
        -- Tooltip - Turn Off
        Untip = "混乱打击",
        -- Hero Ability
        hero = 0,
        -- Levels
        levels = 1,
        -- Race
        race = "human",
        -- Targets Allowed
        targs = "enemies"
    }
)

local zhudong5 =
    hslk_ability(
    {
        _parent = "ANcl",
        -- Animation Names
        Animnames = "",
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\ability_demonhunter_eyebeam.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 1,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 45,
        -- Mana Cost
        Cost = 0,
        -- Follow Through Time
        DataA = 5,
        -- Target Type
        DataB = 2,
        -- Options
        DataC = 1,
        -- Art Duration
        DataD = 5,
        -- Disable Other Abilities
        DataE = 0,
        -- Base Order ID
        DataF = CONST_ABILITY_ORDER[5],
        -- Editor Suffix
        EditorSuffix = "恶魔猎手",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "D",
        -- Name
        Name = "眼棱",
        -- Cast Range
        Rng = 500.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "眼棱",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "11",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00眼棱|r：用恶魔之眼持续向前方发射恶魔能量，引导3秒，每0.3秒对正前方单位造成150%敏捷的混乱魔法伤害。该技能需要引导。技能加速会加速伤害频率并降低施法时间，伤害次数保持不变。",
        -- Tooltip - Turn Off
        Untip = "眼棱",
        -- Hero Ability
        hero = 0,
        -- Levels
        levels = 1,
        -- Race
        race = "human"
    }
)

local zhudong6 =
    hslk_ability(
    {
        _parent = "ANcl",
        -- Animation Names
        Animnames = "",
        -- Icon - Normal
        Art = "ReplaceableTextures\\DH\\ability_demonhunter_metamorphasisdps.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 2,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 180,
        -- Mana Cost
        Cost = 10,
        -- Follow Through Time
        DataA = 0,
        -- Target Type
        DataB = 2,
        -- Options
        DataC = 3,
        -- Art Duration
        DataD = 0,
        -- Disable Other Abilities
        DataE = 0,
        -- Base Order ID
        DataF = CONST_ABILITY_ORDER[6],
        -- Editor Suffix
        EditorSuffix = "恶魔猎手",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "T",
        -- Name
        Name = "恶魔变形",
        -- Cast Range
        Rng = 800.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "恶魔变形",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00恶魔变形|r：向目标区域跳跃并在落地时变身为恶魔形态，同时对300码范围冲击造成150%（攻击+敏捷）混乱魔法伤害。该技能会重置你眼棱和刃舞的冷却时间。同时，该技能会强化你的刃舞和混乱打击，使刃舞和混乱打击伤害类型变成混乱伤害，同时提高你的攻击速度30%和整体10%混乱伤害（独立增伤），持续20秒。",
        -- Tooltip - Turn Off
        Untip = "恶魔变形",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "13",
        -- Hero Ability
        hero = 0,
        -- Levels
        levels = 1,
        -- Race
        race = "human",
        -- Targets Allowed
        Area = 300
    }
)

hslk_hero(
    {
        _parent = "Obla",
        -- Starting Agility
        AGI = 10,
        -- Agility per Level
        AGIplus = 4.0,
        -- Icon - Game Interface
        Art = "ReplaceableTextures\\DH\\classicon_demonhunter.blp",
        -- Tooltip - Awaken
        Awakentip = "",
        -- Hit Points Maximum (Base)
        HP = 100,
        -- Starting Intelligence
        INT = 1,
        -- Intelligence per Level
        INTplus = 0.0,
        -- Name
        Name = "恶魔猎手",
        -- Primary Attribute
        Primary = "AGI",
        -- Proper Names
        Propernames = "毁灭之刃",
        -- Tooltip - Revive
        Revivetip = "ssil",
        -- Starting Strength
        STR = 1,
        -- Strength per Level
        STRplus = 0.0,
        -- Tooltip - Basic
        Tip = "cosl",
        -- Normal
        abilList = "AInv," ..
            zhudong1._id ..
                "," ..
                    zhudong2._id ..
                        "," ..
                            zhudong3._id ..
                                "," ..
                                    zhudong4._id ..
                                        "," ..
                                            zhudong5._id ..
                                                "," .. zhudong6._id .. "," .. beidong._id .. "," .. tianfu._id,
        -- Armor Type
        armor = "Metal",
        -- Attack 1 - Animation Backswing Point
        backSw1 = 0.1,
        -- Animation - Cast Backswing
        castbsw = 0.07,
        -- Animation - Cast Point
        castpt = 0.07,
        -- Attack 1 - Cooldown Time
        cool1 = 0.9,
        -- Death Time (seconds)
        death = 1.0,
        -- Defense Base
        def = 1,
        -- Attack 1 - Damage Base
        dmgplus1 = 16,
        -- Attack 1 - Animation Damage Point
        dmgpt1 = 0.52,
        -- Model File
        file = "pifu\\[PF]DH01.mdx",
        -- Food Cost
        fused = 0,
        -- Scaling Value
        modelScale = 1,
        -- Hero
        heroAbilList = "",
        -- Hero - Hide Hero Death Message
        hideHeroDeathMsg = 1,
        -- Hero - Hide Hero Minimap Display
        hideHeroMinimap = 1,
        -- Mana Maximum
        manaN = 100,
        -- Maximum Pitch Angle (degrees)
        maxPitch = 0.0,
        -- Maximum Roll Angle (degrees)
        maxRoll = 0.0,
        -- Sight Radius (Night)
        nsight = 1800,
        -- Race
        race = "human",
        -- Attack 1 - Range
        rangeN1 = 135,
        -- Hit Points Regeneration Rate
        regenHP = 1.0,
        -- Mana Regeneration
        regenMana = 0.0,
        collision = 24,
        -- Repair Time
        reptm = 10000,
        -- Animation - Run Speed
        run = 400.0,
        -- Selection Scale
        scale = 1,
        -- Attack 1 - Damage Sides per Die
        sides1 = 2,
        -- Speed Base
        spd = 335,
        -- Attack 1 - Targets Allowed
        targs1 = "debris,ground,structure,air,wall,ward",
        -- Turn Rate
        turnRate = 3.0,
        -- Unit Sound Set
        unitSound = "",
        -- Attack 1 - Weapon Sound
        weapType1 = "MetalHeavySlice",
        zhiye_cundang_str = "emolieshou",
        _canZhiliao = false,
        _canTank = true,
        _canShuchu = true
    }
)
