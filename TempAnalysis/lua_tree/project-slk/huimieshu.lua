local tianfu =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\PASHLNL.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- 暴击率 设置为0
            DataA = 0,
            -- 说明
            Ubertip =
            "|cffffcc00混乱能量|r：术士的核心天赋技能，增强其造成的法术伤害并在受到攻击时减少伤害。当术士造成伤害时，混乱能量有机会根据术士的精通属性增加伤害输出。同时，在术士承受伤害时，混乱能量会减少一定比例的受到伤害。|n|cffffcc00技能特点|r：在攻击和防御上都提供显著的增益，增强术士的生存能力和输出潜力。|n|cff00ff00伤害增强|r：提升造成伤害的|cff00ff000%-20%|r。|n|cff00ff00伤害减免|r：受到的伤害减少|cff00ff000%-10%|r。|n|cffffcc00精通加成|r：根据术士的精通属性，每10点精通提高一点最大增伤，每60点精通提高一点最大减伤。|n",
            -- Name
            Name = "混乱能量",
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
            Art = "ReplaceableTextures\\SHUSHI\\PASSJ.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "烧尽",
            Tip = "烧尽",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00烧尽|r：毁灭术士的核心攻击技能，作为其主要的伤害手段，替代普通攻击。对目标造成|cff0000ff魔法伤害|r，伤害值与术士的智力相关，并可能获得法术暴击伤害的加成。|n|cffffcc00技能特点|r：作为毁灭术士的主要伤害来源，适用于对付各类目标。|n|cffffcc00|cffffff00伤害公式|r：基础伤害为术士当前智力值的|cff00ff00130%|r。|cffffcc00混沌燃烧|r状态下，根据法术暴击率和暴击伤害进行伤害调整。|n|cff00ff00触发效果|r：在|cffffcc00混沌燃烧|r状态下，法术暴击率和暴击伤害对伤害值有显著影响。|n",
            -- Tooltip - Turn Off
            Untip = "烧尽",
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
            Art = "ReplaceableTextures\\SHUSHI\\Spell_Fire_Immolation.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "献祭",
            reqLevel = 15,
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "4",
            -- Tooltip - Normal
            Tip = "献祭",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00献祭|r：毁灭术士释放爆燃时对目标施加一个持续|cff00ff0015秒|r的燃烧效果，每秒造成等于|cff00ff0030%|r智力的魔法伤害。每次献祭造成伤害时，有|cff00ff0010%|r（暴击时为|cff00ff0020%|r）的几率产生|cffffcc00混乱之种|r。|n|cffffcc00技能特点|r：对单个目标造成持续伤害，并有机会增加混乱之种的数量，加强术士的连续战斗能力。|n|cff00ff00持续时间|r：|cff00ff0015秒|r|n|cff00ff00伤害数值|r：智力的|cff00ff0030%|r|n|cff00ff00混乱之种产生几率|r：|cff00ff0010%|r（暴击时|cff00ff0020%|r）|n|cffffcc00注意|r：献祭是术士的核心技能之一，适合在战斗中对关键目标施加持续压力，该技能受到技能加速加成，可以增加伤害频率。|n",
            -- Tooltip - Turn Off
            Untip = "献祭"
        }
    )

local zhanshi_beidong3 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\PASHDRS.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "混沌燃烧",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "6",
            Tip = "混沌燃烧",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00混沌燃烧|r：当毁灭术士的|cffffcc00烧尽|r技能造成伤害时，有|cff00ff0015%|r的几率激活|cffffcc00混沌燃烧|r状态。在接下来的|cff00ff005秒|r内，下一次的|cffffcc00烧尽|r技能必定造成暴击，且伤害提高，提升幅度与术士的法术暴击率相关。同时，激活混沌燃烧时，|cffffcc00烧尽|r的|cffffcc00混乱之种|r的出现几率翻倍。|n|cffffcc00技能特点|r：增强术士的输出能力，和混乱之种的生成速度。|n|cffffcc00触发几率|r：|cff00ff0015%|r|n|cffffcc00激活持续时间|r：|cff00ff005秒|r|n|cffffcc00注意|r：此技能在术士造成暴击时触发，为下一攻击提供巨大增益。|n",
            -- Tooltip - Turn Off
            Untip = "混沌燃烧",
            reqLevel = 15
        }
    )

local zhanshi_beidong4 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\PASXJ.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "大灾变",
            Tip = "大灾变",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "8",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00大灾变|r：毁灭术士的高级技能，当其对目标施放|cffffcc00献祭|r时，会同时对目标周围300码内的所有敌方单位施加相同的效果。这一技能使得|cffffcc00献祭|r变得更具毁灭性，能够在范围内造成广泛的持续伤害。|n|cffffcc00技能特点|r：显著扩大了|cffffcc00献祭|r的影响范围，使其能够对多个敌方单位造成影响。|n|cff00ff00影响范围|r：|cff00ff00300码|r。|n|cffffcc00注意|r：该技能能够在关键时刻对群体敌人造成伤害并快速收集混乱之种，特别适用于对抗密集的敌人。|n",
            -- Tooltip - Turn Off
            Untip = "大灾变",
            reqLevel = 15
        }
    )

local zhanshi_beidong5 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\PASHY.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "强化火雨",
            -- Tooltip - Normal
            Tip = "强化火雨",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "9",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00强化火雨|r：毁灭术士的进阶技能，增强了|cffffcc00火焰雨|r的效果。此技能使得|cffffcc00火焰雨|r的伤害提升|cff00ff0030%|r，并且每次攻击有|cff00ff0010%|r的几率获得|cffffcc00混乱之种|r。|n|cffffcc00技能特点|r：提升了火焰雨的伤害输出，同时增加了混乱之种的产生概率，增强了术士的持续伤害和资源生成能力。|n|cff00ff00伤害增强|r：|cff00ff0030%|r|n|cff00ff00触发几率|r：|cff00ff0010%|r|n|cffffcc00注意|r：此技能使火焰雨成为一个更强大的群体伤害技能，并辅助术士的资源管理。|n",
            -- Tooltip - Turn Off
            Untip = "强化火雨",
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
            Name = "灵魂导管",
            -- Tooltip - Normal
            Tip = "灵魂导管",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00灵魂导管|r：毁灭术士的高级被动技能。当使用|cffffcc00混乱之箭|r消耗混乱之种时，有|cff00ff0020%|r的几率返还消耗的混乱之种。这一技能提高了术士对混乱之种的利用效率，从而增强了其持续战斗的能力。|n|cffffcc00技能特点|r：提升了混乱之种的资源管理效率，增加了术士在战斗中维持输出的可能性。|n|cff00ff00返还几率|r：|cff00ff0020%|r。|n|cffffcc00注意|r：此技能对于资源管理至关重要，特别是在长时间的战斗中。|n",
            -- Tooltip - Turn Off
            Untip = "灵魂导管",
            reqLevel = 15
        }
    )

local zhanshi_beidong7 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\PASHAOJIE.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "浩劫复仇",
            Tip = "浩劫复仇",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "12",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00浩劫复仇|r：毁灭术士的进阶被动技能。当|cffffcc00浩劫|r技能激活时，其持续时间增加至|cff00ff0013秒|r，并且可以同时标记|cff00ff00两个|r目标。标记的目标受到来自术士的额外伤害，并且术士的单体技能会对这些目标产生额外效果。|n|cffffcc00技能特点|r：显著增强了|cffffcc00浩劫|r的效果，使术士能够在战场上同时控制多个关键目标。|n|cff00ff00持续时间增强|r：|cff00ff0013秒|r|n|cff00ff00目标数量|r：|cff00ff00两个|r|n|cffffcc00注意|r：此技能极大提升了术士的战术灵活性，适用于针对多目标的战术布局。|n",
            -- Tooltip - Turn Off
            Untip = "浩劫复仇",
            reqLevel = 15
        }
    )

local zhanshi_beidong8 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\PASLHS.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "灵魂石",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "14",
            Tip = "灵魂石",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00灵魂石|r：毁灭术士的被动治疗技能。当范围内的友军单位生命值降至|cff00ff0030%|r以下时，自动使用一颗灵魂石进行治疗，恢复目标|cffffff0030%|r的最大生命值。|n|cffffcc00技能特点|r：为毁灭术士提供关键时刻的辅助治疗能力，增强队伍的生存潜力。|n|cff00ff00触发范围|r：|cff00ff002000|r范围内的所有友方单位。|n|cff00ff00冷却时间|r：|cff00ff0060秒|r。|n|cffffcc00触发条件|r：友军单位生命值低于|cff00ff0030%|r。|n|cffffcc00注意|r：触发治疗效果后，同一目标在短时间内无法再次触发灵魂石效果。|n",
            -- Tooltip - Turn Off
            Untip = "灵魂石",
            reqLevel = 15
        }
    )

local zhanshi_beidong9 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\PASHLZZ.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "混乱主宰",
            reqLevel = 15,
            -- Tooltip - Normal
            Tip = "混乱主宰",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00混乱主宰|r：毁灭术士的顶级被动技能。能增加混乱之箭的伤害，同时此技能将混乱之种的上限增加至|cff00ff005|r。当混乱之种达到上限时，再次获得混乱之种会对周围随机敌方目标自动释放一个次级混乱之箭。|n|cffffcc00技能特点|r：极大地提升了混乱之种的潜在价值以及混乱之箭的伤害，增强了术士的伤害输出能力。|n|cff00ff00混乱之种上限|r：|cff00ff005|r|n|cff00ff00次级混乱之箭伤害|r：|cff00ff00120%智力|r|n此技能使得|cffffcc00混乱之箭|r的伤害提高|cff00ff00130%|r，但每次施放消耗|cff00ff00两个|r混乱之种。",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "15",
            -- Tooltip - Turn Off
            Untip = "混乱主宰"
        }
    )

local zhanshi_beidong10 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\zhuangbei\\INV_Misc_Book_07.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 3,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "牺牲魔典",
            -- Tooltip - Normal
            Tip = "牺牲魔典",
            -- Tooltip - Normal - Extended
            Ubertip = "使你的烧尽，混乱之箭和次级混乱箭有15%概率爆炸对300码范围内目标造成100%主属性的暗影伤害",
            -- Tooltip - Turn Off
            Untip = "牺牲魔典",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "16",
            reqLevel = 15
        }
    )

local zhanshi_beidong11 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\CommandButtons\\PASBTNJN_XX_V.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 3,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "根除",
            -- Requirements
            Tip = "根除",
            -- Tooltip - Normal - Extended
            Ubertip = "混乱之箭使得毁灭术士对目标伤害提高10%",
            -- Tooltip - Turn Off
            Untip = "根除",
            reqLevel = 15
        }
    )

local beidong =
    hslk_ability(
        {
            _parent = "Aspb",
            -- Icon - Normal
            Art = "ReplaceableTextures\\PASBTNTF_7.blp",
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
            Name = "毁灭术被动技能",
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
            Art = "ReplaceableTextures\\SHUSHI\\HDRS.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 8.0,
            -- Mana Cost
            Cost = 3,
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
            DataF = CONST_ABILITY_ORDER[1],
            -- Editor Suffix
            EditorSuffix = "毁灭术",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "Q",
            -- Name
            Name = "爆燃",
            -- Cast Range
            Rng = 800.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "爆燃",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00爆燃|r：毁灭术士的主动技能。施法者对目标施加爆燃，造成等于|cff00ff00150%|r智力的魔法伤害，并产生|cff00ff001|r枚|cffffcc00混乱之种|r。该技能会使得术士释放下一个|cffffcc00混乱之箭|r的时候读条时间缩短0.8秒|n",
            -- Tooltip - Turn Off
            Untip = "爆燃",
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
            Art = "ReplaceableTextures\\SHUSHI\\Spell_Shadow_RainOfFire.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 12.0,
            -- Mana Cost
            Cost = 5,
            -- Follow Through Time
            DataA = 0.25,
            -- Target Type
            DataB = 2,
            -- Options
            DataC = 3,
            -- Art Duration
            DataD = 0.25,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[3],
            -- Editor Suffix
            EditorSuffix = "毁灭术",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "W",
            -- Name
            Name = "火焰雨",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "火焰雨",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00火焰雨|r：毁灭术士的主动范围伤害技能。施法者召唤一场持续|cff00ff005秒|r的火焰雨，覆盖指定区域。每秒对区域内的敌人造成等于|cff00ff0030%|r智力的魔法伤害。若拥有|cffffcc00强化火雨|r技能，伤害增加|cff00ff0030%|r，并有|cff00ff0010%|r的几率产生|cffffcc00混乱之种|r。|n|cffffcc00技能特点|r：能够对多个敌人造成持续伤害，特别适合在群战中使用，对敌方阵地施加压力。|n|cff00ff00持续时间|r：|cff00ff0012秒|r|n|cff00ff00伤害数值|r：智力的|cff00ff0030%|r|n|cff00ff00混乱之种产生几率|r：|cff00ff0010%|r（仅限于|cffffcc00强化火雨|r）|n|cffffcc00注意|r：此技能在控制战场和收集混乱之种时非常有效。|n",
            -- Tooltip - Turn Off
            Untip = "火焰雨",
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
            targs = "enemies",
            Area = 300
        }
    )

local zhudong3 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\SHUSHI\\Spell_Shadow_Shadowfury.blp",
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
            EditorSuffix = "毁灭术",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "E",
            -- Name
            Name = "暗影之怒",
            -- Cast Range
            Rng = 800.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "暗影之怒",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00暗影之怒|r：毁灭术士的主动群体打断技能。施法者在指定区域释放黑暗能量，对范围内的敌人造成打断效果。这一技能能够立即中断敌人施法。|n|cff00ff00冷却时间|r：|cff00ff0020秒|r|n|cffffcc00注意|r：此技能在团队战或对抗多个敌人时极为有效，需谨慎选择释放时机和位置，以达到最佳效果。|n",
            -- Tooltip - Turn Off
            Untip = "暗影之怒",
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
            Art = "ReplaceableTextures\\SHUSHI\\Ability_Warlock_ChaosBolt.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 3,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 3,
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
            EditorSuffix = "毁灭术",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "R",
            -- Name
            Name = "混乱之箭",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "混乱之箭",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00混乱之箭|r：毁灭术士的核心单体伤害技能。施法者消耗一枚|cffffcc00混乱之种|r，对单个目标造成相当于|cff00ff00250%|r智力值的魔法伤害，并且必定暴击。暴击将根据术士的法术暴击率百分比增加该技能的伤害。|n|cffffcc00技能特点|r：高伤害单体技能，适用于集中火力消灭关键目标。|n|cff00ff00伤害数值|r：智力的|cff00ff00250%|r|n|cff00ff00施法时间|r：|cff00ff002秒|r|n|cff00ff00冷却时间|r：|cff00ff001秒|r|n|cff00ff00魔法消耗|r：|cff00ff007|r|n|cffffcc00注意|r：高效使用此技能需要精准的资源管理，以及对战局的敏锐洞察。|n",
            -- Tooltip - Turn Off
            Untip = "混乱之箭",
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
            Art = "ReplaceableTextures\\SHUSHI\\ability_warlock_baneofhavoc.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 30.0,
            -- Mana Cost
            Cost = 5,
            -- Follow Through Time
            DataA = 0.5,
            -- Target Type
            DataB = 1,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0.5,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[6],
            -- Editor Suffix
            EditorSuffix = "毁灭术",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "D",
            -- Name
            Name = "浩劫",
            -- Cast Range
            Rng = 800.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "浩劫",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00浩劫|r：毁灭术士的强力单体诅咒技能。施法者选择一个敌方目标并施加浩劫效果，持续|cff00ff0010秒|r。被标记的单位受到术士任何单体伤害技能的影响时，该技能会再次对目标区域内的另一个随机敌人施加相同效果（若该目标为当前目标，则不重复施放）。此外，被浩劫标记的单位受到术士的伤害增加|cff00ff0010%|r。技能冷却时间为|cff00ff0030秒|r。|n|cffffcc00技能特点|r：极大地增强术士针对单一或多个目标的伤害输出，特别适用于对付重要的敌方单位或在群体战斗中造成范围影响。|n|cff00ff00持续时间|r：|cff00ff0010秒|r|n|cff00ff00伤害增强|r：|cff00ff0010%|r|n|cff00ff00冷却时间|r：|cff00ff0030秒|r|n|cffffcc00注意|r：合理使用此技能可显著提高战场控制能力，应在关键时刻对重要目标使用以最大化效果。|n",
            -- Tooltip - Turn Off
            Untip = "浩劫",
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
            Art = "ReplaceableTextures\\SHUSHI\\ability_warlock_inferno.blp",
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
            EditorSuffix = "毁灭术",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "T",
            -- Name
            Name = "灵魂燃烧",
            -- Cast Range
            Rng = 150.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "灵魂燃烧",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00灵魂燃烧|r：毁灭术士的终极爆发技能。施法者立即获得|cff00ff005|r枚|cffffcc00混乱之种|r，并在接下来的|cff00ff0010秒|r内，所有|cffffcc00混乱能量|r技能触发最大效果。这意味着术士在这段时间内造成的伤害和受到的伤害都将达到最优状态。冷却时间为|cff00ff00100秒|r。|n|cffffcc00技能特点|r：为术士提供短暂的极端强化，使其在关键时刻能够发挥出惊人的输出或生存能力。|n|cff00ff00混乱之种获取|r：|cff00ff005|r枚|n|cff00ff00增强持续时间|r：|cff00ff0010秒|r|n|cff00ff00冷却时间|r：|cff00ff00100秒|r|n|cffffcc00注意|r：正确时机使用此技能对于战斗的影响至关重要，它能在关键时刻扭转战局或确保胜利。|n",
            -- Tooltip - Turn Off
            Untip = "灵魂燃烧",
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
        Name = "毁灭术",
        -- Proper Names
        Propernames = "古尔丹",
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
        file = "war3mapImported\\Dark_Highlord.mdx",
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
        collision = 24,
        walk = 350,
        run = 350,
        -- Attack 1 - Targets Allowed
        targs1 = "debris,ground,structure,air,wall,ward",
        -- Turn Rate
        turnRate = 3.0,
        -- Unit Sound Set
        unitSound = "",
        weapType1 = "",
        zhiye_cundang_str = "huimieshu",
        _canZhiliao = false,
        _canTank = false,
        _canShuchu = true
    }
)
