local tianfu =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\MoreButtons\\KUANGBAO\\PASBTNKUANGBAO.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- 暴击率 设置为0
        DataA = 0,
        -- 说明
        Ubertip = "|cffffcc00激怒|r：狂暴战士在造成物理攻击暴击或使用某些技能时激活|cffffcc00激怒|r状态。在此状态下，狂暴战士的所有伤害输出增加，同时提高移动速度。狂暴战士的|cffffcc00精通属性|r可以进一步增强伤害加成效果。|n|cffffcc00技能特点|r：这项技能极大地增强了狂暴战士的综合战斗能力，使其在战场上更为致命。|n|cff00ff00增加的伤害|r：基础|cff00ff00+15%|r，随精通属性增长|n|cff00ff00增加的移动速度|r：|cff00ff00+40|r|n|cffffcc00持续时间|r：|cff00ff004秒|r",
        -- Name
        Name = "激怒",
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
        Art = "ReplaceableTextures\\MoreButtons\\SHIXUE\\PASBTNSHIXUE.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "嗜血",
        Tip = "嗜血",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00嗜血|r：狂暴战士在攻击时有机会触发|cffffcc00嗜血|r，对目标造成额外物理伤害，同时回复自身一定比例的生命值，并有一定几率激活|cffffcc00激怒|r状态。|n|cffffcc00技能特点|r：这项技能提供了额外的伤害输出和自我治疗，使狂暴战士在战斗中更持久。|n|cffffcc00伤害公式|r：|cff00ff0070%|r的攻击力|n|cffffcc00治疗效果|r：|cff00ff007%|r的最大生命值|n|cffffcc00激怒触发几率|r：|cff00ff0030%|r|n|cffffcc00冷却时间|r：|cff00ff0010秒|r|n|cffffcc00注意|r：合理利用嗜血可以在关键时刻回复生命值，维持战斗状态。|n",
        -- Tooltip - Turn Off
        Untip = "嗜血",
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
        Art = "ReplaceableTextures\\MoreButtons\\LUANWU\\PASBTNLUANWU.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "乱舞",
        -- Tooltip - Normal
        Tip = "乱舞",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00乱舞|r：当狂暴战士的攻击或技能造成暴击时，有机会触发|cffffcc00乱舞|r状态。|n|cffffcc00技能特点|r：在|cffffcc00乱舞|r状态下，狂暴战士的攻击速度显著提升，并且|cffffcc00暴怒|r技能的攻击次数增加一次，增强了狂暴战士的连续输出能力。|n|cffffcc00攻击速度增加|r：|cff00ff0030%|r|n|cffffcc00持续时间|r：|cff00ff006秒|r或3次攻击|n|cffffcc00触发几率|r：取决于暴击几率|n|cffffcc00冷却时间|r：无，但受限于暴击发生",
        -- Tooltip - Turn Off
        Untip = "乱舞",
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
        Art = "ReplaceableTextures\\PASBTNKT_009.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "狂暴战重伤",
        Tip = "狂暴战重伤",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00狂暴战重伤|r：当狂暴战士的攻击或技能造成暴击时，将触发|cffffcc00狂暴战重伤|r效果，对敌人造成持续伤害。|n|cffffcc00技能特点|r：|cffffcc00狂暴战重伤|r给敌人造成深度创伤，使其在6秒内持续流血，受到额外伤害。|n|cffffcc00伤害类型|r：|cffff0000物理伤害|r|n|cffffcc00伤害数值|r：攻击力的48%，分6秒造成|n|cffffcc00持续时间|r：|cff00ff006秒|r|n|cffffcc00触发几率|r：取决于暴击几率",
        -- Tooltip - Turn Off
        Untip = "狂暴战重伤",
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
        Art = "ReplaceableTextures\\MoreButtons\\XUANFENGZHAN\\PASBTNXUANFENGZHAN.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "旋风斩",
        -- Tooltip - Normal
        Tip = "旋风斩",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00旋风斩|r：狂暴战士快速旋转，对周围敌人造成伤害并获得临时增益效果。|n|cffffcc00技能特点|r：旋风斩能够对周围300范围内的敌人造成|cff00ff0080%|r的攻击力伤害，并且使狂暴战士获得临时增益，增强其单体伤害技能的范围效果。|n|cffffcc00伤害类型|r：|cff00ff00物理伤害|r|n|cffffcc00伤害数值|r：攻击力的|cff00ff0080%|r|n|cffffcc00范围效果|r：300范围内的敌人|n|cffffcc00增益效果|r：接下来|cff00ff002|r次单体伤害技能能额外伤害周围所有单位|n|cffffcc00增益持续时间|r：|cff00ff0010秒|r|n|cffffcc00注意|r：此技能适用于快速清理大量敌人。在面对群体敌人时尤其有效。|n",
        -- Tooltip - Turn Off
        Untip = "旋风斩",
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
        Art = "ReplaceableTextures\\MoreButtons\\KUANGBAOZITAI\\PASBTNKUANGBAOZITAI.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "狂暴姿态",
        reqLevel = 15,
        -- Tooltip - Normal
        Tip = "暴击提高3%,力量提高10%",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00狂暴姿态|r：狂暴战士采取更加激进的战斗姿态，增强攻击能力而牺牲部分防御。|n|cffffcc00技能特点|r：学习狂暴姿态后，增加物理暴击率和暴击伤害。|n|cffffcc00效果|r：增加|cff00ff003%物理暴击率|r和|cff00ff0010%暴击伤害|r。|n|cffffcc00持续时间|r：永久。|n|cffffcc00注意|r：狂暴战士是伤害的制造者。|n",
        -- Tooltip - Turn Off
        Untip = "暴击提高3%,力量提高10%",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "9",
        _attr = _attr(
            {
                wu_bao = "+3",
                wu_baoshang = "+10"
            }
        )
    }
)

local zhanshi_beidong6 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\MoreButtons\\KUANGBAOHUIFU\\PASBTNKUANGBAOHUIFU.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "无尽狂怒",
        Tip = "无尽狂怒",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00无尽狂怒|r：狂暴战士在战斗中触发深藏内心的无尽狂怒，极大地增强了怒气值获取的能力。|n|cffffcc00技能特点|r：此技能显著提高怒气获取速度。|n|cffffcc00效果|r：增加|cff00ff0025%|r普通攻击获得的怒气。|n|cffffcc00效果|r：增加|cff00ff005|r点英勇打击暴击时的获得的怒气。",
        -- Tooltip - Turn Off
        Untip = "无尽狂怒",
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
        Art = "ReplaceableTextures\\MoreButtons\\KUAISUPIKAN\\PASBTNKUAISUPIKAN.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "狂暴劈砍",
        -- Tooltip - Normal
        Tip = "狂暴劈砍",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "12",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00狂暴劈砍|r：狂暴战士挥舞武器进行强力的劈砍，对目标造成伤害的同时，激发战士的攻击速度。|n|cffffcc00技能特点|r：此技能结合了攻击和加速效果，可以叠加多次。|n|cffffcc00伤害公式|r：造成|cff00ff00攻击力的100%|r的|cffff0000物理伤害|r。|n|cffffcc00攻击速度增益|r：每次使用后，增加|cff00ff00攻击速度5%|r，最多叠加3层，持续15秒。|n|cffffcc00冷却时间|r：5秒。|n|cffffcc00注意|r：此技能在普攻攻击中有概率触发。|n",
        -- Tooltip - Turn Off
        Untip = "狂暴劈砍",
        reqLevel = 15
    }
)

local zhanshi_beidong8 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\MoreButtons\\KUANGBAOZHIXIN\\PASBTNKUANGBAOZHIXIN.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "狂暴之心",
        Tip = "狂暴之心",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00狂暴之心|r：狂暴战士的战斗激情激励着周围的队友，使他们的攻击更加致命。|n|cffffcc00技能特点|r：为周围2000范围内的队友提供光环效果，增加暴击率。|n|cffffcc00光环效果|r：光环范围内的队友暴击率增加|cff00ff003%|r。|n|cffffcc00注意|r：此技能对团队攻击力的提升非常关键。|n",
        -- Tooltip - Turn Off
        Untip = "狂暴之心",
        reqLevel = 15,
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "14",
        _guanghuanAttr = _attr({fa_bao = "+3", wu_bao = "+3"})
    }
)

local zhanshi_beidong9 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\MoreButtons\\TAITANZHIWO\\PASBTNTAITANZHIWO.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "泰坦之握",
        Tip = "泰坦之握",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "15",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00泰坦之握|r：狂暴战士掌握了古老的泰坦战技，能够同时装备并自如地挥舞两把双手武器。这种技巧使他们在战斗中更加致命且灵活。|n|cffffcc00技能特点|r：狂暴战士可以同时装备两把双手武器，并且可以获得两把武器的所有加成。|n|cffffcc00注意|r：此技能赋予狂暴战士前所未有的战斗优势，使他们在战场上如同泰坦般的存在，敌人难以抵挡他们的强大攻势。|n",
        -- Tooltip - Turn Off
        Untip = "泰坦之握",
        reqLevel = 15
    }
)

local zhanshi_beidong10 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\BTN_ZS_JN07.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "巨龙怒吼",
        Tip = "巨龙怒吼",
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "16",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00巨龙怒吼|r：释放暴怒时会对300码范围发出巨龙般的怒吼，造成400%攻击力的范围伤害，巨龙怒吼必定暴击。 冷却20秒",
        -- Tooltip - Turn Off
        Untip = "巨龙怒吼",
        reqLevel = 15
    }
)

local beidong =
    hslk_ability(
    {
        _parent = "Aspb",
        -- Icon - Normal
        Art = "ReplaceableTextures\\PASBTN_KRDS_KBZX.blp",
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
        Name = "狂暴战被动技能",
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
        Art = "ReplaceableTextures\\BTN_ZS_Q1.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 5.0,
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
        EditorSuffix = "战士",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "Q",
        -- Name
        Name = "英勇打击",
        -- Cast Range
        Rng = 700.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "英勇打击",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00英勇打击|r：狂暴战士通过切换战斗姿态，将普通攻击转化为强力的英勇打击。|n|cffffcc00技能特点|r：激活状态下，当怒气大于70时，每次普通攻击消耗|cff00ff0020|r点怒气，造成相当于|cff00ff00120%|r的基础攻击力的物理伤害。|n|cffffcc00伤害类型|r：|cffff0000物理伤害|r|n|cffffcc00怒气返还|r：如果英勇打击造成暴击，将返还|cff00ff0010|r点怒气。|n|cffffcc00冷却信息|r：技能可以通过点击切换状态，无固定冷却时间。|n|cffffcc00注意|r：此技能在正确的时机激活可以极大提升狂暴战士的输出能力，但同时需要谨慎管理怒气以保证持续的战斗效率。|n",
        -- Tooltip - Turn Off
        Untip = "英勇打击",
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
        Art = "ReplaceableTextures\\MoreButtons\\NUJI\\BTNNUJI.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 1,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 10.0,
        -- Mana Cost
        Cost = 0,
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
        DataF = CONST_ABILITY_ORDER[3],
        -- Editor Suffix
        EditorSuffix = "战士",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "W",
        -- Name
        Name = "怒击",
        -- Cast Range
        Rng = 150.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "怒击",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00怒击|r：狂暴战士用两把武器对单个目标发起猛烈攻击，造成大量伤害。|n|cffffcc00技能特点|r：对选定目标造成两次相当于|cff00ff00100%|r的基础攻击力的物理伤害。|n|cffffcc00伤害类型|r：|cffff0000物理伤害|r。|n|cffffcc00触发条件|r：如果狂暴战士处于|cffffcc00旋风斩增益|r状态下，怒击将额外对周围敌人造成相同的伤害。|n|cffffcc00冷却信息|r：技能冷却时间为|cff00ff0010秒|r，但有|cff00ff0015%|r的几率在命中时重置冷却时间。",
        -- Tooltip - Turn Off
        Untip = "怒击",
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
        Art = "ReplaceableTextures\\MoreButtons\\YINGYONGTIAOYUE\\BTNYINGYONGTIAOYUE.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 2,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 15.0,
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
        DataE = 1,
        -- Base Order ID
        DataF = CONST_ABILITY_ORDER[2],
        -- Editor Suffix
        EditorSuffix = "战士",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "E",
        -- Name
        Name = "英勇跳跃", -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "5",
        -- Cast Range
        Rng = 800.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "英勇跳跃",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00英勇跳跃|r：狂暴战士进行一次英勇的跳跃，向指定位置快速移动。|n|cffffcc00技能特点|r：在到达目的地时，对周围300码范围内的敌人造成|cff00ff0050%|r基础攻击力的|cffff0000物理伤害|r，并打断施法。|n|cffffcc00冷却信息|r：技能冷却时间为|cff00ff0015秒|r。|n|cffffcc00注意|r：跳跃距离不能小于200码，过近将无法使用。此技能适合快速接近敌人或逃离危险，同时提供良好的控制能力。|n",
        -- Tooltip - Turn Off
        Untip = "英勇跳跃",
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
        Art = "ReplaceableTextures\\MoreButtons\\BAONU\\BTNBAONU.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 3,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 10,
        -- Mana Cost
        Cost = 50,
        -- Follow Through Time
        DataA = 0.7,
        -- Target Type
        DataB = 1,
        -- Options
        DataC = 1,
        -- Art Duration
        DataD = 0.7,
        -- Disable Other Abilities
        DataE = 0,
        -- Base Order ID
        DataF = CONST_ABILITY_ORDER[4],
        -- Editor Suffix
        EditorSuffix = "战士",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "R",
        -- Name
        Name = "暴怒",
        -- Cast Range
        Rng = 150.0,
        -- Target
        TargetArt = "",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "7",
        -- Tooltip - Normal
        Tip = "暴怒",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00暴怒|r：狂暴战士集中怒气，对单个目标发动连续的猛烈攻击。|n|cffffcc00技能特点|r：对单个目标连续攻击|cff00ff003|r次，每次攻击造成|cff00ff00150%|r基础攻击力的|cffff0000物理伤害|r。如果激活|cffffcc00乱舞|r状态，攻击次数增加一次。|n|cffffcc00冷却信息|r：技能冷却时间为|cff00ff0010秒|r。|n|cffffcc00注意|r：此技能非常适合对付单个强大的敌人，尤其在乱舞状态下可以造成巨大的单体伤害。|n",
        -- Tooltip - Turn Off
        Untip = "暴怒",
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
        Art = "ReplaceableTextures\\MoreButtons\\KUANGBAOHUIFU\\BTNKUANGBAOHUIFU.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 1,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 15,
        -- Mana Cost
        Cost = 30,
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
        EditorSuffix = "战士",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "D",
        -- Name
        Name = "狂暴恢复",
        -- Cast Range
        Rng = 150.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "狂暴恢复",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "11",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00狂暴恢复|r：狂暴战士激发内在的生命力，瞬间恢复大量生命值。|n|cffffcc00技能特点|r：立即恢复狂暴战士|cff00ff0012%|r的最大生命值。如果激活了|cffffcc00激怒|r状态，则会消耗激怒状态，且恢复量提高到|cff00ff0020%|r。|n|cffffcc00冷却信息|r：技能冷却时间为|cff00ff0015秒|r。|n|cffffcc00注意|r：这是一个关键时刻的生存技能，可以在生命危急时迅速回血。|n",
        -- Tooltip - Turn Off
        Untip = "狂暴恢复",
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
        Art = "ReplaceableTextures\\BTN_spell09.blp",
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
        DataF = CONST_ABILITY_ORDER[6],
        -- Editor Suffix
        EditorSuffix = "战士",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "T",
        -- Name
        Name = "死亡之愿",
        -- Cast Range
        Rng = 150.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "死亡之愿",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00死亡之愿|r：狂暴战士激发内心的绝望，大幅提升自身的战斗能力。|n|cffffcc00技能特点|r：增加狂暴战士|cff00ff0030%|r的全局伤害增益，|cff00ff0020%|r的物理暴击率和暴击伤害。|n|cffffcc00冷却信息|r：技能冷却时间为|cff00ff00100秒|r。|n|cffffcc00激活持续时间|r：|cff00ff0015秒|r。|n|cffffcc00注意|r：这项技能提供了巨大的输出提升。适合用于战斗中的关键时刻，以实现最大的杀伤力。|n",
        -- Tooltip - Turn Off
        Untip = "死亡之愿",
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
        Name = "狂暴战",
        -- Primary Attribute
        Primary = "STR",
        -- Proper Names
        Propernames = "奎蒙",
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
        file = "war3mapImported\\Warsong_Assasin_by_Aeonux.mdl",
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
        collision = 24,
        -- Animation - Run Speed
        run = 335.0,
        -- Selection Scale
        scale = 1,
        -- Attack 1 - Damage Sides per Die
        sides1 = 2,
        -- Speed Base
        spd = 335,
        -- Scaling Value
        modelScale = 1,
        -- Attack 1 - Targets Allowed
        targs1 = "debris,ground,structure,air,wall,ward",
        -- Turn Rate
        turnRate = 3.0,
        -- Unit Sound Set
        unitSound = "",
        -- Attack 1 - Weapon Sound
        weapType1 = "MetalHeavySlice",
        zhiye_cundang_str = "kuangbaozhan",
        _canZhiliao = false,
        _canTank = true,
        _canShuchu = true
    }
)
