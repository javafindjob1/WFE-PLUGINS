local tianfu =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\PASHAOJIE.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- 暴击率 设置为0
            DataA = 0,
            -- 说明
            Ubertip = "|cffffcc00痛苦之源|r：术士的核心天赋技能，增强其造成的持续伤害。基础增强10%，每15点精通额外增强1%",
            -- Name
            Name = "痛苦之源",
            -- Requirements
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
            Art = "ReplaceableTextures\\SHUSHI\\anyingjian.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "暗影箭",
            Tip = "暗影箭",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00暗影箭|r：痛苦术士的核心攻击技能，作为其主要的伤害手段，替代普通攻击。对目标造成100%的魔法伤害，并有50%的概率获取一颗灵魂碎片,消耗2点魔法",
            -- Tooltip - Turn Off
            Untip = "暗影箭",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "1",
            reqLevel = 15
        }
    )

local zhanshi_beidong2 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\fushishu.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "腐蚀术",
            reqLevel = 15,
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "4",
            -- Tooltip - Normal
            Tip = "腐蚀术",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00腐蚀术|r：痛苦术士在释放痛苦诅咒的同时会给目标附加腐蚀术效果，腐蚀术每秒造成伤害并且可以引爆腐蚀之种。该技能不会消耗魔法。",
            -- Tooltip - Turn Off
            Untip = "腐蚀术"
        }
    )

local zhanshi_beidong3 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\PASXJ.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "痛苦献祭",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "6",
            Tip = "痛苦献祭",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00痛苦献祭|r：痛苦术士的痛苦无常技能会对敌人附加痛苦献祭效果，每秒造成40%主属性的伤害，该效果不会消耗魔法。",
            -- Tooltip - Turn Off
            Untip = "痛苦献祭",
            reqLevel = 15
        }
    )

local zhanshi_beidong4 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\CommandButtons\\BTNLifeDrain.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "生命虹吸",
            Tip = "生命虹吸",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "8",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00生命虹吸|r：痛苦术士的恢复技能，暗影箭会给敌人附加生命汲取的诅咒，如果目标和术士的单位距离在1000码内，诅咒造成伤害时每2秒会恢复术士2%的生命，诅咒持续10秒，CD30秒。",
            -- Tooltip - Turn Off
            Untip = "生命虹吸",
            reqLevel = 15
        }
    )

local zhanshi_beidong5 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\guiyingchanshen.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "鬼影缠身",
            -- Tooltip - Normal
            Tip = "鬼影缠身",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "9",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00鬼影缠身|r：痛苦术士的进阶技能，每层痛苦无常会使得目标受到所有术士的持续伤害增加2%",
            -- Tooltip - Turn Off
            Untip = "鬼影缠身",
            reqLevel = 15
        }
    )

local zhanshi_beidong6 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\PASLHDG.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- 暴击率 设置为0
            DataA = 0,
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "10",
            -- Name
            Name = "痛苦之魂",
            -- Tooltip - Normal
            Tip = "痛苦之魂",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00痛苦之魂|r：痛苦术士的高级被动技能。当消耗混乱之种时，有|cff00ff0015%|r的几率返还消耗的灵魂碎片。",
            -- Tooltip - Turn Off
            Untip = "痛苦之魂",
            reqLevel = 15
        }
    )

local zhanshi_beidong7 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\tongkuwuchang.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "无常永在",
            Tip = "无常永在",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "12",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00无常永在|r：提高痛苦无常8%的法术暴击概率和15%的法术爆伤",
            -- Tooltip - Turn Off
            Untip = "无常永在",
            reqLevel = 15
        }
    )

local zhanshi_beidong8 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\xiezhou.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "邪咒",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "14",
            Tip = "邪咒",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00邪咒|r：增加2000码范围内友军5%的技能加速",
            -- Tooltip - Turn Off
            Untip = "邪咒",
            reqLevel = 15,
            _guanghuanAttr = {
                skill_speed = "+5"
            }
        }
    )

local zhanshi_beidong9 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\nifengshougezhe.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "逆风收割者",
            reqLevel = 15,
            -- Tooltip - Normal
            Tip = "逆风收割者",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00逆风收割者|r：痛苦术士的顶级被动技能。无常永在效果提高100%，痛苦之魂概率提高10%。",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "15",
            -- Tooltip - Turn Off
            Untip = "逆风收割者"
        }
    )

local zhanshi_beidong10 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\zainankuanghuan.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "黑眼射线",
            reqLevel = 15,
            -- Tooltip - Normal
            Tip = "黑眼射线",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00黑眼射线|r：使你的灾难狂欢每秒会对目标造成20%主属性伤害，目标身上每一种痛苦术士的诅咒会增加5%基础伤害系数。",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "16",
            -- Tooltip - Turn Off
            Untip = "黑眼射线"
        }
    )

local beidong =
    hslk_ability(
        {
            _parent = "Aspb",
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\nifengshougezhe.blp",
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
            Name = "痛苦术被动技能",
            Ubertip = "点击打开被动技能列表"
        }
    )

local zhudong1 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\tongkuzuzhou.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 0.5,
            -- Mana Cost
            Cost = 3,
            -- Follow Through Time
            DataA = 0.25,
            -- Target Type
            DataB = 1,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0.25,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[1],
            -- Editor Suffix
            EditorSuffix = "痛苦术",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "Q",
            -- Name
            Name = "痛苦诅咒",
            -- Cast Range
            Rng = 800.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "痛苦诅咒",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00痛苦诅咒|r：痛苦术士的主动技能，对目标施加诅咒，每两秒造成基于智力的伤害。每次造成伤害会使得剩下时间内每次伤害提高10%，最多叠加8次。该技能造成伤害时有20%的概率获得一颗灵魂之种",
            -- Tooltip - Turn Off
            Untip = "痛苦诅咒",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1, -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "2",
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
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\tongkuwuchang.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 2,
            -- Mana Cost
            Cost = 0,
            -- Follow Through Time
            DataA = 10,
            -- Target Type
            DataB = 1,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 10,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[3],
            -- Editor Suffix
            EditorSuffix = "痛苦术",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "W",
            -- Name
            Name = "痛苦无常",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "痛苦无常",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00痛苦无常|r：痛苦术士的主要输出技能，消耗1枚灵魂碎片，给敌人附加一层痛苦无常状态，该状态每秒每层会造成20%智力的伤害，可以叠加，最多叠加5层。基础魔法消耗5点，基础施法时间1.5秒。",
            -- Tooltip - Turn Off
            Untip = "痛苦无常",
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
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\kongju.blp",
            Area = 400,
            -- Button Position - Normal (X)
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 20,
            -- Mana Cost
            Cost = 5,
            -- Follow Through Time
            DataA = 0.5,
            -- Target Type
            DataB = 2,
            -- Options
            DataC = 3,
            -- Art Duration
            DataD = 0.5,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[2],
            -- Editor Suffix
            EditorSuffix = "痛苦术",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "E",
            -- Name
            Name = "恐惧",
            -- Cast Range
            Rng = 800.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "恐惧",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00恐惧|r：痛苦术士的主动群体打断技能。施法者在指定区域释放令人恐惧的痛苦幻象，造成周围敌人造成打断效果。",
            -- Tooltip - Turn Off
            Untip = "恐惧",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "5",
            -- Race
            race = "human",
            -- Targets Allowed
            Area = 300
        }
    )

local zhudong4 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\fushizhizhong.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 3,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 2.5,
            -- Mana Cost
            Cost = 0,
            -- Follow Through Time
            DataA = 10,
            -- Target Type
            DataB = 1,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 10,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[4],
            -- Editor Suffix
            EditorSuffix = "痛苦术",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "R",
            -- Name
            Name = "腐蚀之种",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "腐蚀之种",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00腐蚀之种|r：痛苦术士的核心群体伤害技能。施法者消耗两枚|cffffcc00灵魂碎片|r，对目标单位以及该单位300范围内随机2个额外单位释放腐蚀之种。腐蚀之种会给敌人施加一层负面状态，拥有该状态的敌人在受到腐蚀术伤害的时候会引爆腐蚀之种。腐蚀之种的爆炸影响到的单位如果有腐蚀之种状态，也会被引爆。被爆炸影响到的单位会被附加一层腐蚀术。爆炸伤害为130%智力值。基础魔法消耗：7点。基础施法时间：2秒。",
            -- Tooltip - Turn Off
            Untip = "腐蚀之种",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "7",
            -- Targets Allowed
            targs = "enemies"
        }
    )

local zhudong5 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\zainankuanghuan.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 5,
            -- Mana Cost
            Cost = 0,
            -- Follow Through Time
            DataA = 30,
            -- Target Type
            DataB = 1,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 30,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[6],
            -- Editor Suffix
            EditorSuffix = "痛苦术",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "D",
            -- Name
            Name = "灾难狂欢",
            -- Cast Range
            Rng = 800.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "灾难狂欢",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00灾难狂欢|r：痛苦术士的强力单体伤害技能，消耗一枚灵魂碎片，每秒额外消耗一枚灵魂碎片。引导过程中目标受到的持续伤害提高60%（独立增伤）",
            -- Tooltip - Turn Off
            Untip = "灾难狂欢",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "11",
            -- only enemy
            targs = "enemies"
        }
    )

local zhudong6 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\HLZZ.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 100,
            -- Mana Cost
            Cost = 10,
            -- Follow Through Time
            DataA = 0.8,
            -- Target Type
            --DataB = 1,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0.8,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[5],
            -- Editor Suffix
            EditorSuffix = "无尽诅咒",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "T",
            -- Name
            Name = "无尽诅咒",
            -- Cast Range
            Rng = 150.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "无尽诅咒",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00无尽诅咒|r：痛苦术士的终极爆发技能。使得痛苦术士的痛苦诅咒，痛苦无常，痛苦献祭和腐蚀术的基础伤害间隔降低40%，这个效果独立于技能加速提供的间隔缩短，持续12秒",
            -- Tooltip - Turn Off
            Untip = "无尽诅咒",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "13",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human"
        }
    )

hslk_hero(
    {
        _parent = "Obla",
        -- Starting Agility
        AGI = 1,
        -- Agility per Level
        AGIplus = 0.0,
        -- Icon - Game Interface
        Art = "ReplaceableTextures\\classicon\\ClassIcon_Warlock.blp",
        -- Tooltip - Awaken
        Awakentip = "I05S",
        -- Hit Points Maximum (Base)
        HP = 100,
        -- Starting Intelligence
        INT = 10,
        -- Primary Attribute
        Primary = "INT",
        -- Intelligence per Level
        INTplus = 4.0,
        -- Attack 1 - Projectile Arc
        Missilearc_1 = 0.1,
        -- Attack 1 - Projectile Art
        Missileart_1 = "war3mapImported\\DruidoftheTalonMissile.mdl",
        -- Attack 1 - Projectile Speed
        Missilespeed_1 = 1500,
        -- Name
        Name = "痛苦术",
        -- Proper Names
        Propernames = "待定",
        -- Tooltip - Revive
        Revivetip = "afac",
        -- Starting Strength
        STR = 1,
        -- Strength per Level
        STRplus = 0.0,
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
        -- Acquisition Range
        acquire = 800.0,
        -- Attack 1 - Animation Backswing Point
        backSw1 = 0.25,
        -- Categorization - Campaign
        campaign = 0,
        -- Animation - Cast Backswing
        castbsw = 0.1,
        -- Animation - Cast Point
        castpt = 0.05,
        -- Attack 1 - Cooldown Time
        cool1 = 1.3,
        -- Death Time (seconds)
        death = 1.0,
        -- Defense Base
        def = 1,
        -- Attack 1 - Damage Base
        dmgplus1 = 1,
        -- Attack 1 - Animation Damage Point
        dmgpt1 = 0.2,
        -- Elevation - Sample Radius
        elevRad = 150.0,
        -- Model File
        file = "war3mapImported\\crilis.mdx",
        -- Hero
        heroAbilList = "",
        -- Projectile Launch - X
        launchX = 3.0,
        -- Projectile Launch - Y
        launchY = 100.0,
        -- Projectile Launch - Z
        launchZ = 150.0,
        -- Mana Initial Amount
        mana0 = 100,
        -- Mana Maximum
        manaN = 100,
        -- Maximum Pitch Angle (degrees)
        maxPitch = 0.0,
        -- Maximum Roll Angle (degrees)
        maxRoll = 0.0,
        -- Scaling Value
        modelScale = 1,
        scale = 1,
        -- Sight Radius (Night)
        nsight = 1800,
        -- Attack 1 - Range
        rangeN1 = 800,
        -- Hit Points Regeneration Rate
        regenHP = 1.0,
        -- Mana Regeneration
        regenMana = 0.5,
        -- Repair Time
        reptm = 10000,
        -- Shadow Image - Height
        shadowH = 100.0,
        -- Shadow Image - Width
        shadowW = 100.0,
        -- Shadow Image - Center X
        shadowX = 25.0,
        -- Shadow Image - Center Y
        shadowY = 25.0,
        -- Attack 1 - Damage Sides per Die
        sides1 = 2,
        -- Speed Base
        spd = 335,
        walk = 320,
        run = 320,
        -- Attack 1 - Targets Allowed
        targs1 = "debris,ground,structure,air,wall,ward",
        collision = 24,
        -- Turn Rate
        turnRate = 3.0,
        -- Unit Sound Set
        unitSound = "",
        weapType1 = "",
        zhiye_cundang_str = "tongkushu",
        _canZhiliao = false,
        _canTank = false,
        _canShuchu = true
    }
)
