local caiji =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "attack",
            -- Icon - Normal
            Art = "ReplaceableTextures\\caikuang\\CAIKUANG.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 3,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 1.0,
            -- Mana Cost
            Cost = 0,
            -- Follow Through Time
            DataA = 100,
            -- Target Type
            DataB = 1,
            -- Options
            DataC = 0,
            -- Art Duration
            DataD = 100,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[7],
            -- Editor Suffix
            EditorSuffix = "通用",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "",
            -- Name
            Name = "采集",
            -- Cast Range
            Rng = 200.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "采集",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00采集|r技能可以用来采集不同的资源。|n- 对|cffffcc00矿石|r使用可以采集矿石等资源并增加采矿专业的经验。|n- 对|cffffcc00草药|r使用可以采集草药并增加采药专业的经验。|n- 对|cffffcc00钓鱼|r点使用可以获取各种鱼，鱼可以增加属性。|n- 注意，采集不会消耗资源点，并且|cffffcc00系统会自动继续采集|r，但是采集会消耗堆叠的资源，如果次数消耗，则要等资源再生。|n|n |cffffcc00注意|r可以进入|cffffcc00存档（快捷键F3）|r界面查看专业技能等级和加成。",
            -- Tooltip - Turn Off
            Untip = "采集",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "1",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human",
            -- Targets Allowed
            targs = "invulnerable"
        }
    )

local zhizuo =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\caikuang\\CAIKUANG.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 3,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 1.0,
            -- Mana Cost
            Cost = 0,
            -- Follow Through Time
            DataA = 100,
            -- Target Type
            -- DataB = 1,
            -- Options
            DataC = 0,
            -- Art Duration
            DataD = 100,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[8],
            -- Editor Suffix
            EditorSuffix = "通用",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "",
            -- Name
            Name = "制作",
            -- Cast Range
            Rng = 200.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "制作",
            -- Tooltip - Normal - Extended
            Ubertip = "可以制作物品",
            -- Tooltip - Turn Off
            Untip = "制作",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "1",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human"
        }
    )

local caijicopy =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "attack",
            -- Icon - Normal
            Art = "ReplaceableTextures\\caikuang\\CAIKUANG.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 3,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 1.0,
            -- Mana Cost
            Cost = 0,
            -- Follow Through Time
            DataA = 0,
            -- Target Type
            DataB = 1,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = "roar",
            -- Editor Suffix
            EditorSuffix = "通用",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "C",
            -- Name
            Name = "采集资源",
            -- Cast Range
            Rng = 200.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "采集资源",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00采集|r技能可以用来采集不同的资源。|n- 对|cffffcc00矿石|r使用可以采集矿石等资源并增加采矿专业的经验。|n- 对|cffffcc00草药|r使用可以采集草药并增加菜肴专业的经验。|n- 对|cffffcc00钓鱼|r点使用可以获取各种鱼，鱼可以增加属性。|n- 注意，采集不会消耗资源点，并且|cffffcc00系统会自动继续采集|r，但是采集会消耗堆叠的资源，如果次数消耗，则要等资源再生。|n|n |cffffcc00注意|r可以进入|cffffcc00存档（快捷键F3）|r界面查看专业技能等级和加成。",
            -- Tooltip - Turn Off
            Untip = "采集资源",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "1",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human",
            -- Targets Allowed
            targs = "invulnerable"
        }
    )

local fenjie =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "stand,channel",
            -- Icon - Normal
            Art = "ReplaceableTextures\\fumo\\INV_Enchant_Disenchant.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 1,
            -- Mana Cost
            Cost = 0,
            -- Follow Through Time
            DataA = 0,
            -- Target Type
            DataB = 1,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = "renewon",
            -- Editor Suffix
            EditorSuffix = "",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "F",
            -- Name
            Name = "分解物品",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "分解物品",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00分解物品|r：分解物品，可以获得附魔材料|n",
            -- Tooltip - Turn Off
            Untip = "分解物品",
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
            targs = "item"
        }
    )

local fenjiedimian =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\fumo\\INV_Enchant_Disenchant.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 5,
            -- Mana Cost
            Cost = 0,
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
            DataF = "renew",
            -- Editor Suffix
            EditorSuffix = "",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "G",
            -- Name
            Name = "批量分解",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "批量分解",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00批量分解|r：分解范围内的装备，上限10个。|n",
            -- Tooltip - Turn Off
            Untip = "批量分解",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "1",
            -- Targets Allowed
            targs = "enemies",
            Area = 300
        }
    )

local shouhuzhe =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "stand,channel",
            -- Icon - Normal
            Art = "ReplaceableTextures\\PASBTN_ZS_JN11.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 1,
            -- Mana Cost
            Cost = 0,
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
            DataF = "flamestrike",
            -- Editor Suffix
            EditorSuffix = "",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "H",
            -- Name
            Name = "守护者",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "守护者",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00守护者|r：可以让冒险者进入守护者状态。守护者可以获得60%的最终伤害减免，但是造成的所有伤害降低90%，同时获取的仇恨值提高100倍。近战力量职业以及恶魔猎手可以获得守护者和先锋角色|n",
            -- Tooltip - Turn Off
            Untip = "守护者",
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
            targs = "item"
        }
    )

local xianfeng =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "stand,channel",
            -- Icon - Normal
            Art = "ReplaceableTextures\\BTN_ZS_JN03.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 1,
            -- Mana Cost
            Cost = 0,
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
            DataF = "flamingarrows",
            -- Editor Suffix
            EditorSuffix = "",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "Y",
            -- Name
            Name = "先锋",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "先锋",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00先锋|r：可以让冒险者进入先锋状态。先锋造成的所有伤害提高2%，同时仇恨获取提高10倍。近战力量职业以及恶魔猎手可以获得先锋角色。|n",
            -- Tooltip - Turn Off
            Untip = "先锋",
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
            targs = "item"
        }
    )

local jingongshou =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "stand,channel",
            -- Icon - Normal
            Art = "ReplaceableTextures\\PASBTN_KRDS_SPZ.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 1,
            -- Mana Cost
            Cost = 0,
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
            DataF = "forceofnature",
            -- Editor Suffix
            EditorSuffix = "",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "N",
            -- Name
            Name = "进攻手",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "进攻手",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00进攻手|r：可以让冒险者进入进攻手状态。进攻手造成的所有伤害提高2%。所有职业可以获得进攻手角色|n",
            -- Tooltip - Turn Off
            Untip = "进攻手",
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
            targs = "item"
        }
    )

local sell =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "stand,channel",
            -- Icon - Normal
            Art = "ReplaceableTextures\\INV_Misc_Coin_02.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 3,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 1,
            -- Mana Cost
            Cost = 0,
            -- Follow Through Time
            DataA = 0,
            -- Target Type
            DataB = 1,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = "renewoff",
            -- Editor Suffix
            EditorSuffix = "",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "S",
            -- Name
            Name = "售卖",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "售卖",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00售卖|r：售卖物品，获得金币|n",
            -- Tooltip - Turn Off
            Untip = "售卖",
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
            targs = "item"
        }
    )

local selldimian =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\INV_Misc_Coin_02.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 5,
            -- Mana Cost
            Cost = 0,
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
            DataF = "repair",
            -- Editor Suffix
            EditorSuffix = "",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "D",
            -- Name
            Name = "批量售卖",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "批量售卖",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00批量售卖|r：售卖范围内的物品，上限10个。|n",
            -- Tooltip - Turn Off
            Untip = "批量售卖",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "1",
            -- Targets Allowed
            targs = "enemies",
            Area = 300
        }
    )

hslk_ability(
    {
        _parent = "Aspb",
        -- Icon - Normal
        --Art = "ReplaceableTextures\\PASBTN_QS_07.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 3,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- Spell List
        DataA = caijicopy._id ..
            "," ..
            fenjie._id ..
            "," ..
            fenjiedimian._id ..
            "," ..
            sell._id ..
            "," ..
            selldimian._id ..
            "," .. shouhuzhe._id .. "," .. jingongshou._id .. "," .. xianfeng._id,
        -- Shared Spell Cooldown
        DataB = 0,
        -- Minimum Spells
        DataC = 12,
        -- Maximum Spells
        DataD = 12,
        -- Base Order ID
        DataE = "innerfire",
        Hotkey = "Z",
        -- Name
        Name = "功能合集",
        Ubertip =
        "采集，分解，售卖，团队角色转换等功能|n |cffffcc00常用指令|r：|n- kill 自杀，用于卡副本不能脱离 |n- qingkongdangqianjuesecundang |cffff0000清空当前角色存档|r，使用后会清空当前角色的等级，装备物品栏，声望等，并退出游戏，重新进入游戏可以重新选择角色。"
    }
)

hslk_ability(
    {
        _parent = "ANcl",
        -- Animation Names
        Animnames = "spell",
        -- Icon - Normal
        Art = "ReplaceableTextures\\BTNPriest_icon_Chakra_blue.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 1,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 0,
        -- Mana Cost
        Cost = 0,
        -- Follow Through Time
        DataA = 25,
        -- Target Type
        DataB = 3,
        -- Options
        DataC = 1,
        -- Art Duration
        DataD = 28,
        -- Disable Other Abilities
        DataE = 0,
        -- Base Order ID
        DataF = "thunderbolt",
        -- Editor Suffix
        EditorSuffix = "",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "",
        -- Name
        Name = "AI技能模版",
        -- Cast Range
        Rng = 10000.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "",
        -- Tooltip - Normal - Extended
        Ubertip = "",
        -- Tooltip - Turn Off
        Untip = "",
        -- Hero Ability
        hero = 0,
        -- Levels
        levels = 1,
        -- Race
        race = "human"
        -- Targets Allowed
        -- targs = "allies,enemies"
    }
)
