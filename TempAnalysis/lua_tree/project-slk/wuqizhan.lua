local tianfu =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\PASBTNAbility_BackStab.png.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- 暴击率 设置为0
            DataA = 0,
            -- 说明
            Ubertip =
            "|cffffcc00重伤|r：当武器战士攻击或者技能暴击时，有|cff00ff00100%|r几率触发|cffffcc00重伤|r效果。重伤状态使目标每秒受到|cff00ff0060%攻击力|r点|cffff0000物理伤害|r，持续|cff00ff006秒|r。|n|cffffcc00伤害公式|r：基础攻击力 * （70% + 精通/600）|n|cffffcc00技能特点|r：该技能在初期伤害有限，但暴击和精通属性提高会显著提高该技能的伤害。|n|cffffcc00触发几率|r：|cff00ff00100%|r|n|cffffcc00持续时间|r：|cff00ff006秒|r",
            -- Name
            Name = "重伤",
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
            Art = "ReplaceableTextures\\zhanshi\\PASBTNzs_zhisidaji.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "致死打击",
            Ubertip =
            "|cffffcc00致死打击|r：武器战士使用|cffffcc00致死打击|r对目标造成强力一击，造成|cffff0000物理伤害|r。|n|cffffcc00伤害公式|r：基础攻击力 * 350%|n|cffffcc00怒气消耗|r：|cff00ff0025|r|n|cffffcc00冷却时间|r：3秒|n|cffffcc00注意|r：该技会在普通攻击时触发，释放优先级最高，但是只有当怒气高于80才会释放。当|cffffcc00战争领主|r效果激活时，致死打击不消耗怒气，并且伤害提高|cff00ff0030%|r。",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "",
            -- Requirements
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
            Art = "ReplaceableTextures\\MoreButtons\\YAZHI\\PASBTNYAZHI.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "压制",
            Ubertip =
            "|cffffcc00压制|r：武器战士对敌人施展无视闪避的的一击，造成|cffff0000物理伤害|r，并保证必定|cffff0000暴击|r。该技能具有12秒的冷却时间。|n|cffffcc00怒气恢复|r：技能成功命中时恢复|cff00ff005|r点怒气。|n|cffffcc00伤害公式|r：基础攻击力 * |cff00ff00120%|r（如果激活了|cffffcc00战争领主|r效果，伤害增加|cff00ff0050%|r）。|n|cffffcc00注意|r：该技能会在普通攻击时释放，释放优先级低于致死打击。另外，当|cffffcc00战争领主|r效果激活时，压制有|cff00ff0030%|r几率使|cffffcc00致死打击|r的冷却时间重置。",
            -- Requirements
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
            Art = "ReplaceableTextures\\zhanshi\\PASBTNzs_silie.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "撕裂",
            Ubertip =
            "|cffffcc00撕裂|r：武器战士的致死打击和斩会撕裂目标，每3秒造成100%攻击力的|cffff0000物理伤害|r，并在接下来的时间里持续造成伤害。|n|cffffcc00技能特点|r：持续伤害效果，并恢复怒气。|n|cffffcc00怒气恢复|r：技能造成伤害时恢复|cff00ff003|r点怒气。|n|cffffcc00伤害公式|r：每3秒造成攻击力的|cff00ff00100%|r伤害，持续12秒，施加新的撕裂会刷新持续时间，不会影响生效时间。|n|cffffcc00注意|r：技能加速可以增加技能伤害频率",
            -- Requirements
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
            Art = "ReplaceableTextures\\PASBTN_ZS_BD2.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "剑在人在",
            Ubertip =
            "|cffffcc00剑在人在|r：当武器战士的生命值降至极低时，自动触发技能，免疫一次即将到来的死亡，恢复一定生命至|cff00ff0030%|r并短暂提高自身的招架能力。|n|cffffcc00技能特点|r：绝境反击，提供关键时刻的生存机会。|n|cffffcc00触发条件|r：受到致死伤害时候触发。|n|cffffcc00效果持续时间|r：招架率提高|cff00ff00100%|r，效果持续|cff00ff005秒|r|n|cffffcc00冷却时间|r：技能冷却时间为|cff00ff00180秒|r。|n|cffffcc00注意|r：该技能仅在关键时刻自动触发，冷却时间较长。",
            -- Requirements
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
            Art = "ReplaceableTextures\\zhanshi\\PASBTNzs_mengji.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "猛击",
            Ubertip =
            "|cffffcc00猛击|r：武器战士挥舞武器对目标造成一次重创。|n|cffffcc00技能特点|r：强大的单体输出能力。|n|cffffcc00伤害值|r：造成|cff00ff00280%攻击力|r的|cffFF0000物理伤害|r|n|cffffcc00冷却时间|r：技能冷却时间为|cff00ff0012秒|r。|n|cffffcc00注意|r：该技能在普通攻击时释放，释放优先级低于致死打击的压制。",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "9",
            reqLevel = 15
        }
    )

local zhanshi_beidong6 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\MoreButtons\\WUQIDASHI\\PASBTNWUQIDASHI.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            Ubertip =
            "|cffffcc00战争领主|r：这个技能提升了压制和致死打击的威力。每当武器战士使用|cffffcc00压制|r技能时，有|cff00ff0030%|r的几率触发战争领主状态。|n|cffffcc00技能特点|r：在战争领主状态下，下一个|cffffcc00致死打击|r不消耗怒气，且造成的伤害提高|cff00ff0030%|r。|n|cffffcc00冷却时间|r：无额外冷却时间，但触发概率依赖于|cffffcc00压制|r技能的使用。",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "10",
            -- Name
            Name = "战争领主",
            reqLevel = 15
        }
    )
local zhanshi_beidong7 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\zhanshi\\PASBTNzs_sunpizhan.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "顺劈斩",
            Ubertip =
            "|cffffcc00顺劈斩|r：武器战士的一项核心技能，允许战士对周围敌人进行大范围的攻击。当使用时，武器战士对前方|cff00ff00400码|r内的所有敌人造成等同于攻击力|cff00ff00120%|r的|cffFF0000物理伤害|r|n|cffffcc00冷却时间|r：|cff00ff006秒|r。|n|cffffcc00注意|r：该技能不会占用普攻，可以随着普攻一起触发。",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "12",
            reqLevel = 15
        }
    )

local zhanshi_beidong8 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\zhanshi\\PASBTNzs_zhandounuhou.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "战斗怒吼",
            reqLevel = 15,
            Ubertip =
            "|cffffcc00战斗怒吼|r：武器战士的一个增益技能，激发战士及其周围友军的战斗潜力。学习后，武器战士及其周围|cff00ff002000码|r内的所有友军单位获得攻击力和生命值各增加|cff00ff0010%|r的效果。|n|cffffcc00技能特点|r：作为一个团队支援技能，它可以显著增强友军的攻击力和生存能力，尤其适用于团队战斗中。|n|cffffcc00光环范围|r：|cff00ff001000码|r。|n|cffffcc00注意|r：合理利用战斗怒吼可以在关键时刻改变战局，但需确保友军单位处于效果范围内。",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "14",
            _guanghuanAttr = {
                gongji_baifenbi = "+10",
                shengming_baifenbi = "+10"
            }
        }
    )

local zhanshi_beidong9 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\zhanshi\\BTNzs_cusi.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "15",
            -- Name
            Name = "猝死",
            Ubertip =
            "|cffffcc00猝死|r：武器战士的终极被动技能。当普通攻击时，有|cff00ff0010%|r的几率激活|cffffcc00猝死|r效果。激活后，武器战士的下一个|cffffcc00斩杀|r技能可以无视目标的生命百分比限制直接释放，同时斩杀技能的冷却时间被立即重置。此外，|cffffcc00致死打击|r技能会使目标受到的|cffffcc00斩杀|r伤害增加，每次叠加|cff00ff0010%|r伤害，最多可叠加|cff00ff003次|r。叠加的伤害在被斩杀后消失。|n|cffffcc00技能特点|r：猝死提供了对高生命值目标施放关键一击的机会，同时增强致死打击的后续效果，使武器战士在战斗中更具威胁。|n|cffffcc00触发几率|r：|cff00ff0010%|r。",
            reqLevel = 15
        }
    )

local zhanshi_beidong10 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\CommandButtons\\BTNAvatar.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "16",
            -- Name
            Name = "灭战者",
            Ubertip = "|cffffcc00灭战者|r：巨人打击会恢复10点怒气，且变为300码的范围技能，猛击的冷却时间降低6秒，天神下凡的冷却时间减少80秒。",
            reqLevel = 15
        }
    )

local beidong =
    hslk_ability(
        {
            _parent = "Aspb",
            -- Icon - Normal
            Art = "ReplaceableTextures\\PASBTNKT_007.blp",
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
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "",
            -- Name
            Name = "武器战士被动技能",
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
            Art = "ReplaceableTextures\\zhanshi\\BTNzs_chongfeng.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 15.0,
            -- Mana Cost
            Cost = 0,
            -- Follow Through Time
            DataA = 0,
            -- Target Type
            DataB = 1,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0.65,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[2],
            -- Editor Suffix
            EditorSuffix = "战士",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "Q",
            -- Name
            Name = "冲锋",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "冲锋",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00冲锋|r：武器战士的关键位移技能。武器战士向目标单位发起猛烈冲锋，造成基于攻击力|cffff0000物理伤害|r，并造成打断效果。冲锋的伤害与距离目标的远近成正比。冲锋到目标后会回复20点怒气值。|n|cffffcc00技能特点|r：冲锋是武器战士的主要接战手段，可以迅速缩短与敌人的距离并造成显著的初始伤害和控制效果。适合用于开战或追击逃跑的敌人。|n|cffffcc00伤害类型|r：|cffff0000物理伤害|r|n|冷却时间：|cff00ff0015秒|r|n|cffffcc00注意|r：冲锋的使用需要考虑战场位置和敌人的分布，以最大化其效果。",
            -- Tooltip - Turn Off
            Untip = "冲锋",
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
            targs = "enemies"
        }
    )

local zhudong2 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "",
            -- Icon - Normal
            Art = "ReplaceableTextures\\zhanshi\\BTNzs_jurendaji.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 12.0,
            -- Mana Cost
            Cost = 20,
            -- Follow Through Time
            DataA = 0.35,
            -- Target Type
            DataB = 1,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0.6,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[3],
            -- Editor Suffix
            EditorSuffix = "战士",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "W",
            -- Name
            Name = "巨人打击",
            -- Cast Range
            Rng = 150.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "巨人打击",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00巨人打击|r：武器战士的强力打击技能，可对目标造成|cff00ff00150%|r基础攻击力的物理伤害，并在|cff00ff005秒|r内使目标受到来自武器战的额外|cff00ff0030%|r伤害。|n|cffffcc00技能特点|r：巨人打击是对单一目标的高伤害技能，特别适合在持续战斗中对重要目标施加持续压力。|n|cffffcc00伤害类型|r：|cffff0000物理伤害|r|n|cffffcc00增伤效果时长|r：|cff00ff005秒|r|n|cffffcc00冷却时间|r：|cff00ff0012秒|r|n|cffffcc00注意|r：使用巨人打击后，迅速跟进更多伤害以充分利用其增伤效果，对敌人形成有效的打击。",
            -- Tooltip - Turn Off
            Untip = "巨人打击",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "3",
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

local zhudong3 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "",
            -- Icon - Normal
            Art = "ReplaceableTextures\\CommandButtons\\BTNThunderclap.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 10.0,
            -- Mana Cost
            Cost = 0,
            -- Follow Through Time
            DataA = 0.5,
            -- Target Type
            DataB = 0,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0.5,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[4],
            -- Editor Suffix
            EditorSuffix = "战士",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "E",
            -- Name
            Name = "雷霆一击",
            -- Cast Range
            Rng = 150.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "雷霆一击(|cffffcc00W|r)",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00雷霆一击|r：武器战士重击地面，对300范围内的所有敌人造成|cff00ff0080%|r攻击力的魔法伤害，并附加|cffffcc00重伤|r效果。|n|cffffcc00技能特点|r：雷霆一击是一种强力的群体控制技能，可以快速削弱多个敌人并在战场上造成混乱。|n|cffffcc00伤害类型|r：|cff0000ff魔法伤害|r|n|cffffcc00范围|r：|cff00ff00300|r|n|cffffcc00冷却时间|r：|cff00ff0010秒|r|n|cffffcc00注意|r：有效利用雷霆一击可以快速给多个敌人施加流血效果",
            -- Tooltip - Turn Off
            Untip = "雷霆一击(|cffffcc00W|r)",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "5",
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

local zhudong4 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "",
            -- Icon - Normal
            Art = "ReplaceableTextures\\CommandButtons\\BTNCleavingAttack.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 3,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 10,
            -- Mana Cost
            Cost = 25,
            -- Follow Through Time
            DataA = 0.35,
            -- Target Type
            DataB = 1,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0.6,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[1],
            -- Editor Suffix
            EditorSuffix = "战士",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "R",
            -- Name
            Name = "斩杀",
            -- Cast Range
            Rng = 150.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "斩杀(|cffffcc00R|r)",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00斩杀|r：武器战士的成名绝技，有经验的武器战士能靠此技能秒杀强敌。可以对敌人释放，造成200%攻击力和力量的伤害。当目标生命值低于|cff00ff0020%|r或武器战士获得|cffffcc00猝死|r特效时，斩杀会消耗所有怒气。对目标造成消耗怒气值/12 * （攻击+力量）的|cffff0000物理伤害|r。|n|cffffcc00伤害类型|r：|cffff0000物理伤害|r|n|cffffcc00触发额外伤害条件|r：目标生命低于|cff00ff0020%|r或武器战有|cffffcc00猝死|r特效|n|cffffcc00冷却时间|r：|cff00ff0010秒|r（对斩杀线以下的敌人攻击或使用该使用会使该技能冷却时间缩短至3秒）|n|cffffcc00注意|r：合理利用斩杀能够在战斗的关键时刻迅速结束战斗。",
            -- Tooltip - Turn Off
            Untip = "斩杀(|cffffcc00R|r)",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "7",
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
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\CommandButtons\\BTNWhirlwind.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Caster
            CasterArt = "",
            -- Caster Attachments
            Casterattachcount = 1,
            -- Cooldown
            Cool = 60.0,
            -- Mana Cost
            Cost = 0,
            -- Follow Through Time
            DataA = 0,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0.2,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[5],
            -- Editor Suffix
            EditorSuffix = "战士",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "D",
            -- Name
            Name = "利刃风暴",
            -- Cast Range
            Rng = 0.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "利刃风暴(|cffffcc00V|r)",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00利刃风暴|r：武器战士的范围伤害技能，可在5秒内对周围300码范围内的敌人造成持续伤害。每次攻击造成等于|cff00ff00150%|r基础攻击力的|cffff0000物理伤害|r，基础伤害间隔|cff00ff000.5|r秒。|n|cffffcc00技能特点|r：对多个敌人造成伤害，适合在敌人密集时使用。|n|cffffcc00伤害类型|r：|cffff0000物理伤害|r|n|cffffcc00持续时间|r：|cff00ff005秒|r|n|cffffcc00冷却时间|r：|cff00ff0060秒|r|n|cffffcc00注意|r：该技能的伤害频率会受到技能加速的加成。",
            -- Tooltip - Turn Off
            Untip = "利刃风暴(|cffffcc00V|r)",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "11",
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
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\CommandButtons\\BTNAvatar.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Caster
            CasterArt = "",
            -- Caster Attachments
            Casterattachcount = 1,
            -- Cooldown
            Cool = 180.0,
            -- Mana Cost
            Cost = 5,
            -- Follow Through Time
            DataA = 0.6,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0.6,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[6],
            -- Editor Suffix
            EditorSuffix = "战士",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "T",
            -- Name
            Name = "天神下凡",
            -- Cast Range
            Rng = 0.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "天神下凡(|cffffcc00V|r)",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00天神下凡|r：武器战士的终极爆发技能。激活后，增强战士的攻击力和防御力，使其在战场上如同天神降临一般。|n|cffffcc00技能特点|r：显著提升伤害输出和生存能力，使武器战士在短时间内变得异常强大。|n|cffffcc00效果|r：增加|cff00ff0050%|r全局伤害增益，生命值提升|cff00ff0050%|r，减伤增加|cff00ff0010%|r。|n|cffffcc00持续时间|r：|cff00ff0020秒|r|n|cffffcc00冷却时间|r：|cff00ff00180秒|r|n|cffffcc00注意|r：在关键时刻使用此技能可以扭转战局。",
            -- Tooltip - Turn Off
            Untip = "天神下凡(|cffffcc00V|r)",
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
        Art = "ReplaceableTextures\\BTNzb71.blp",
        -- Tooltip - Awaken
        Awakentip = "",
        -- Hit Points Maximum (Base)
        HP = 100,
        -- Starting Intelligence
        INT = 1,
        -- Intelligence per Level
        INTplus = 0.0,
        -- Name
        Name = "武器战",
        -- Primary Attribute
        Primary = "STR",
        -- Proper Names
        Propernames = "摩擦",
        -- Tooltip - Revive
        Revivetip = "ssil",
        -- Starting Strength
        STR = 10,
        -- Strength per Level
        STRplus = 4.0,
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
        backSw1 = 0.45,
        -- Animation - Cast Backswing
        castbsw = 0.07,
        -- Animation - Cast Point
        castpt = 0.07,
        -- Attack 1 - Cooldown Time
        cool1 = 1.4,
        -- Death Time (seconds)
        death = 1.0,
        modelScale = 1,
        -- Defense Base
        def = 1,
        -- Attack 1 - Damage Base
        dmgplus1 = 16,
        -- Attack 1 - Animation Damage Point
        dmgpt1 = 0.55,
        -- Model File
        file = "war3mapImported\\08.mdl",
        -- Food Cost
        fused = 0,
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
        collision = 24,
        -- Turn Rate
        turnRate = 3.0,
        -- Unit Sound Set
        unitSound = "",
        -- Attack 1 - Weapon Sound
        weapType1 = "MetalHeavySlice",
        zhiye_cundang_str = "wuqizhan",
        _canZhiliao = false,
        _canTank = true,
        _canShuchu = true
    }
)
