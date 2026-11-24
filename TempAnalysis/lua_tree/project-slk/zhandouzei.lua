local tianfu =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\daozei\\lianji.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- 暴击率 设置为0
        DataA = 0,
        -- 说明
        Ubertip = "|cffffcc00连击|r：战斗盗贼在造成物理攻击时有15%的概率触发|cffffcc00连击|r。连击会造成一次额外的普通攻击，该普通攻击可以触发任何普攻特效，包括连击。连续触发的连击概率会降低。连击的基础概率为15%，战斗盗贼的|cffffcc00精通属性|r可以进一步增强伤连击概率，每15点精通增加一点连击率。",
        -- Name
        Name = "连击",
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
        Art = "ReplaceableTextures\\daozei\\yingxi.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "影袭",
        Tip = "影袭",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00影袭|r：战斗盗贼的主要攻击技能。普攻时如果能量值高于60点则会发动|cffffcc00影袭|r攻击,消耗40点能量，对目标造成90%（攻击力+敏捷）的物理伤害，并获取一个连击点。连击点可以用于释放终极技能。",
        -- Tooltip - Turn Off
        Untip = "影袭",
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
        Art = "ReplaceableTextures\\daozei\\zhimingyaogao.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "致命毒药",
        -- Tooltip - Normal
        Tip = "致命毒药",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00致命毒药|r：战斗盗贼常年行走大陆，学会了制作毒药的技巧，涂抹在武器上后，普通攻击时18%概率触发|cffffcc00致命药膏|r状态。致命药膏可以造成持续的自然魔法伤害，并且可以叠加。叠加到5层时候如果继续触发，则会造成直接毒药伤害。该技能无法被技能加速增强。同时盗贼对带有中了致命毒药伤害的单位造成的伤害提高，每层提高1%",
        -- Tooltip - Turn Off
        Untip = "致命毒药",
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
        Art = "ReplaceableTextures\\daozei\\mofadoupeng.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "魔法斗篷",
        Tip = "魔法斗篷",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00魔法斗篷|r：强大的防御技能。盗贼精通各种闪避技巧，包括对魔法伤害的规避。盗贼释放疾影时会进入魔法斗篷状态，持续5秒，在魔法斗篷状态下盗贼可以降低50%受到的魔法伤害。CD60秒。",
        -- Tooltip - Turn Off
        Untip = "魔法斗篷",
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
        Art = "ReplaceableTextures\\daozei\\shanbi.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "闪避",
        -- Tooltip - Normal
        Tip = "闪避",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00闪避|r：战斗盗贼精通闪避技巧，学习技能时闪避提升5%，并且在闪避怪物的攻击时会对怪物造成反击，并获得一个练级点，伤害类型为物理伤害，cd为1秒。",
        -- Tooltip - Turn Off
        Untip = "闪避",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "8",
        _attr = _attr(
            {
                shanbi = "+5"
            }
        ),
        reqLevel = 15
    }
)

local zhanshi_beidong5 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\daozei\\zuozhanqianneng.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "作战潜能",
        reqLevel = 15,
        -- Tooltip - Normal
        Tip = "作战潜能",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00作战潜能|r：战斗盗贼的能量控制技巧登峰造极。其在释放消耗连击点的技能时，每个连击可以恢复|cff00ff005|r点能量。与此同时，盗贼在普通攻击的时候有15%概率恢复10点能量值。连击可以触发此效果。",
        -- Tooltip - Turn Off
        Untip = "作战潜能",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "9"
    }
)

local zhanshi_beidong6 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\daozei\\gelie.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "割裂",
        Tip = "割裂",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00割裂|r：战斗盗贼学会了高级刺杀技巧，在对目标造成破击伤害的时候会割裂目标，使其进入流血状态，每秒造成（20% + 10% * 消耗连击点）* 攻击力的伤害。该技能持续时间为3 + 消耗连击点秒。该技能会受到技能加速加成。",
        -- Tooltip - Turn Off
        Untip = "割裂",
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
        Art = "ReplaceableTextures\\MoreButtons\\MENGJI\\PASBTNMENGJI.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "欺凌弱小",
        -- Tooltip - Normal
        Tip = "欺凌弱小",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "12",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00欺凌弱小|r：盗贼对生命值低百分比低于自己的单位能造成额外伤害，数值为15%。",
        -- Tooltip - Turn Off
        Untip = "欺凌弱小",
        reqLevel = 15
    }
)

local zhanshi_beidong8 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\daozei\\daozeidezunyan.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "技艺精湛",
        Tip = "技艺精湛",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00技艺精湛|r：盗贼的精湛技艺激励了同伴，赋予半径2000范围内所有友方单位50精通的增幅。",
        -- Tooltip - Turn Off
        Untip = "技艺精湛",
        reqLevel = 15,
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "14",
        _guanghuanAttr = _attr({master = "+50"})
    }
)

local zhanshi_beidong9 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\daozei\\mingyunzhitou.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "命运之骰",
        Tip = "命运之骰",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "15",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00命运之骰|r：战斗盗贼的终极战斗技巧，具有逆转战局的力量。使用迅击技能将触发命运之骰，有概率触发6种不同的战斗增幅。触发增幅的个数取决于命运之骰，可能获得1，2，3，6种不同状态的加成，基础概率为60%，25%，10%，5%。",
        -- Tooltip - Turn Off
        Untip = "命运之骰",
        reqLevel = 15
    }
)

local zhanshi_beidong10 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\daozei\\mingyunzhitou.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 1,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "灌铅骰子",
        Tip = "灌铅骰子",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "16",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00灌铅骰子|r：盗贼的骰子技巧登峰造极，增加骰子获得更多增幅的概率，获得1/2/3/6种效果的概率为0%/60%/30%/10%。",
        -- Tooltip - Turn Off
        Untip = "灌铅骰子",
        reqLevel = 15
    }
)

local beidong =
    hslk_ability(
    {
        _parent = "Aspb",
        -- Icon - Normal
        Art = "ReplaceableTextures\\daozei\\daozeidezunyan.blp",
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
        Name = "战斗贼被动技能",
        Ubertip = "点击打开被动技能列表"
    }
)

local zhudong1 =
    hslk_ability(
    {
        _parent = "ANcl",
        -- Animation Names
        Animnames = "",
        -- Icon - Normal
        Art = "ReplaceableTextures\\daozei\\xunqie.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 0.5,
        -- Mana Cost
        Cost = 0,
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
        DataF = CONST_ABILITY_ORDER[1],
        -- Editor Suffix
        EditorSuffix = "盗贼",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "Q",
        -- Name
        Name = "迅切",
        -- Cast Range
        Rng = 700.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "迅切",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00迅切|r：战斗盗贼消耗所有连击点释放迅击技能，该技能能增强盗贼30%的攻击速度，其持续时间为消耗的连击点 * 12秒。",
        -- Tooltip - Turn Off
        Untip = "迅切",
        -- Hero Ability
        hero = 0,
        -- Levels
        levels = 1, -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "1",
        -- Race
        race = "human"
        -- Targets Allowed
        --targs = ""
    }
)

local zhudong2 =
    hslk_ability(
    {
        _parent = "ANcl",
        -- Animation Names
        Animnames = "attack slam",
        -- Icon - Normal
        Art = "ReplaceableTextures\\daozei\\Ability_Rogue_Sprint.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 1,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 30.0,
        -- Mana Cost
        Cost = 0,
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
        EditorSuffix = "盗贼",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "W",
        -- Name
        Name = "疾影",
        -- Cast Range
        Rng = 150.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "疾影",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00疾影|r：盗贼的看家本领，提升移动速度至极限，并且提高25%的闪避，持续8秒，冷却30秒。",
        -- Tooltip - Turn Off
        Untip = "疾影",
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
        Art = "ReplaceableTextures\\daozei\\jianrenluanwu.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 2,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 30.0,
        -- Mana Cost
        Cost = 20,
        -- Follow Through Time
        DataA = 0.2,
        -- Target Type
        -- DataB = 2,
        -- Options
        DataC = 3,
        -- Art Duration
        DataD = 0.2,
        -- Disable Other Abilities
        DataE = 0,
        -- Base Order ID
        DataF = CONST_ABILITY_ORDER[2],
        -- Editor Suffix
        EditorSuffix = "盗贼",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "E",
        -- Name
        Name = "剑刃飞舞", -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "5",
        -- Cast Range
        Rng = 800.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "剑刃飞舞",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00剑刃飞舞|r：盗贼不仅精通单体伤害，还拥有不俗的群体伤害能力。使用剑刃飞舞后，盗贼的普通攻击，影袭，破击和杀戮盛宴技能将同时伤害目标周围300码内的所有敌方单位，非主目标的伤害为50%。该技能持续10秒，基础冷却时间为30秒。",
        -- Tooltip - Turn Off
        Untip = "剑刃飞舞",
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

local zhudong4 =
    hslk_ability(
    {
        _parent = "ANcl",
        -- Animation Names
        Animnames = "attack slam",
        -- Icon - Normal
        Art = "ReplaceableTextures\\daozei\\cigu.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 3,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 1,
        -- Mana Cost
        Cost = 25,
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
        DataF = CONST_ABILITY_ORDER[4],
        -- Editor Suffix
        EditorSuffix = "盗贼",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "R",
        -- Name
        Name = "破击",
        -- Cast Range
        Rng = 150.0,
        -- Target
        TargetArt = "",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "7",
        -- Tooltip - Normal
        Tip = "破击",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00破击|r：战斗盗贼集中所有连击点，对单个目标发动猛烈攻击，造成连击点*65%*（攻击力+敏捷）点物理伤害，并打断目标。",
        -- Tooltip - Turn Off
        Untip = "破击",
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
        Art = "ReplaceableTextures\\daozei\\shalushengyan.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 1,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 45,
        -- Mana Cost
        Cost = 30,
        -- Follow Through Time
        DataA = 0,
        -- Target Type
        --DataB = 1,
        -- Options
        DataC = 1,
        -- Art Duration
        DataD = 0,
        -- Disable Other Abilities
        DataE = 0,
        -- Base Order ID
        DataF = CONST_ABILITY_ORDER[5],
        -- Editor Suffix
        EditorSuffix = "盗贼",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "D",
        -- Name
        Name = "杀戮盛宴",
        -- Cast Range
        Rng = 150.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "杀戮盛宴",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "11",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00杀戮盛宴|r：战斗盗贼最强大的伤害技能。使用该技能后，盗贼会化身影子穿梭于周围地方目标之间，进行五次穿梭，每次穿梭会出现在一名敌方单位周围并对其造成两次200%攻击力伤害，该伤害可以触发攻击特效。开启剑刃乱舞后，该伤害会伤害周围单位，但是对周围目标的伤害不会触发攻击特效。",
        -- Tooltip - Turn Off
        Untip = "杀戮盛宴",
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
        Art = "ReplaceableTextures\\daozei\\chongdong.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 2,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 120,
        -- Mana Cost
        Cost = 10,
        -- Follow Through Time
        DataA = 0.2,
        -- Target Type
        --DataB = 1,
        -- Options
        DataC = 1,
        -- Art Duration
        DataD = 0.2,
        -- Disable Other Abilities
        DataE = 0,
        -- Base Order ID
        DataF = CONST_ABILITY_ORDER[6],
        -- Editor Suffix
        EditorSuffix = "盗贼",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "T",
        -- Name
        Name = "冲动",
        -- Cast Range
        Rng = 150.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "冲动",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00冲动|r：战斗盗贼的爆发技能。使用后进入爆发状态，提升基础能量恢复速度和20%的攻击速度，并且影袭可以补满连击点，持续12秒。",
        -- Tooltip - Turn Off
        Untip = "冲动",
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
        AGI = 10,
        -- Agility per Level
        AGIplus = 4.0,
        -- Icon - Game Interface
        Art = "ReplaceableTextures\\classicon\\ClassIcon_Rogue.blp",
        -- Tooltip - Awaken
        Awakentip = "",
        -- Hit Points Maximum (Base)
        HP = 100,
        -- Starting Intelligence
        INT = 1,
        -- Intelligence per Level
        INTplus = 0.0,
        -- Name
        Name = "战斗贼",
        -- Primary Attribute
        Primary = "AGI",
        -- Proper Names
        Propernames = "闪耀",
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
        file = "war3mapImported\\wanglingshouwei.mdx",
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
        zhiye_cundang_str = "zhandouzei",
        _canZhiliao = false,
        _canTank = false,
        _canShuchu = true
    }
)
