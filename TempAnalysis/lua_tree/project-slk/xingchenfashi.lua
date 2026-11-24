local fashi_beidong1 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\fennu.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Name
            Name = "愤怒",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "1",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00愤怒|r: 星辰法师的基础攻击技能，消耗2点魔法，对目标造成130%智力的自然魔法伤害。", -- Tooltip - Turn Off
            Untip = "愤怒",
            Cool = 10,
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human"
        }
    )

local fashi_beidong2 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\rishi.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Name
            Name = "日蚀",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "4",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00日蚀|r：每次使用星火术会使提高日蚀能量，最多叠加到6层，满6层后触发日蚀状态，在该状态下，攻击速度提高20%，愤怒的伤害提高40%，持续时间8秒。",
            -- Tooltip - Turn Off
            Untip = "日蚀",
            Cool = 10,
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human"
        }
    )

local fashi_beidong3 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\yueshi.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Name
            Name = "月蚀",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "6",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00月蚀|r：每次使用愤怒会使提高月蚀能量，最多叠加到6层，满6层后触发月蚀状态，在该状态下，星火术的施法时间降低1秒，同时星火术的暴击以及暴击伤害提高20%，持续时间8秒。",
            -- Tooltip - Turn Off
            Untip = "月蚀",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human",
            -- 学习后附加的属性
            _attr = _attr(
                {
                    fa_bao = "+3"
                }
            )
        }
    )

local fashi_beidong4 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\yangyanshu.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Name
            Name = "阳炎术",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "8",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00阳炎术|r：愤怒会灼烧目标，给目标施加阳炎术，造成持续自然魔法伤害，持续12秒，CD12秒。",
            -- Tooltip - Turn Off
            Untip = "阳炎术",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human"
        }
    )

local fashi_beidong5 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\zhuixing.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Name
            Name = "坠星",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "9",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00坠星|r：月火术和阳炎术的持续伤害有20%概率召唤坠星，对目标造成自然魔法伤害。同时坠星会恢复3点魔法。",
            -- Tooltip - Turn Off
            Untip = "坠星",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human"
            -- 学习后附加的属性
        }
    )

local fashi_beidong6 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\zhiri.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Name
            Name = "至日",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "10",
            -- Follow Through Time
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00至日|r：每次激活日蚀和月蚀的加成，坠星的触发概率提高100%，持续5秒。",
            -- Tooltip - Turn Off
            Untip = "至日",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human"
        }
    )

local fashi_beidong7 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\yuehuoshu.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Name
            Name = "星辰漂移",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "12",
            -- Follow Through Time
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00星辰漂移|r：群星坠落持续期间内，星涌术不会消耗额外的魔法。除此之外，学会此技能后使用星涌术会使英雄获得星涌状态，使得下一个星火术的伤害提高20%，并且会使星火术对目标造成持续伤害，总伤害数值为星火术的伤害。",
            -- Tooltip - Turn Off
            Untip = "星辰漂移",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human"
        }
    )

local fashi_beidong8 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\xingchenguanghuan.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 3,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Name
            Name = "星辰光环",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "14",
            -- Follow Through Time
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00星辰光环|r：每次法术暴击都有20%的几率给周围2000码内友军增加1%的法术暴击增幅，最多叠加四次。",
            -- Tooltip - Turn Off
            Untip = "星辰光环",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human"
        }
    )

local fashi_beidong9 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\xingchenlingzhu.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Name
            Name = "星辰领主",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "15",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00星辰领主|r：星涌术会提供3%的攻击和施法速度，最多叠加6次，持续15秒。",
            -- Tooltip - Turn Off
            Untip = "星辰领主",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human"
            -- 学习后附加的属性
        }
    )

local fashi_beidong10 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\chaofanzhimeng.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Name
            Name = "万灵之召",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "16",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00万灵之召|r：主动和被动开启的超凡之盟会持续释放4个法术（70%愤怒，30%星火），间隔为0.5秒。",
            -- Tooltip - Turn Off
            Untip = "万灵之召",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human"
            -- 学习后附加的属性
        }
    )

local tianfu =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\quanshi.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Name
            Name = "全蚀",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "1",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00全蚀|r:星辰法师的核心技能，可以增强日蚀和月蚀的效果。精通可以加强该技能的效果，每15点精通可以加强日蚀状态下1%攻击速度和2%的愤怒伤害，月蚀状态下1%的星火术暴击率和暴击伤害。", -- Tooltip - Turn Off
            Untip = "全蚀",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human"
        }
    )

local beidong =
    hslk_ability(
        {
            _parent = "Aspb",
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\zhuixing.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 3,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Spell List
            DataA = fashi_beidong1._id ..
                "," ..
                fashi_beidong2._id ..
                "," ..
                fashi_beidong3._id ..
                "," ..
                fashi_beidong4._id ..
                "," ..
                fashi_beidong5._id ..
                "," ..
                fashi_beidong6._id ..
                "," ..
                fashi_beidong7._id ..
                "," ..
                fashi_beidong8._id ..
                "," ..
                fashi_beidong9._id .. "," .. fashi_beidong10._id,
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
            Name = "星辰法师被动技能",
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
            Art = "ReplaceableTextures\\xingchenfashi\\yuehuoshu.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Caster Attachments
            Casterattachcount = 1,
            -- Cooldown
            Cool = 6,
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
            Cost = 3,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[1],
            -- Editor Suffix
            EditorSuffix = "星辰法师",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "Q",
            -- Name
            Name = "月火术",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "2",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "月火术",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00月火术|r：对目标释放强烈的月之能量，给目标附加月火术状态。该状态会对目标造成持续伤害，伤害间隔为2秒，持续时间为12秒。",
            -- Tooltip - Turn Off
            Untip = "月火术",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human",
            -- Targets Allowed
            targs = "enemy"
        }
    )

local zhudong2 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\qunxingzhuiluo.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Caster Attachments
            Casterattachcount = 1,
            Cost = 5,
            -- Cooldown
            Cool = 2.5,
            -- Follow Through Time
            DataA = 10.0,
            -- Target Type
            DataB = 1,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 10.0,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[3],
            -- Editor Suffix
            EditorSuffix = "星辰法师",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "W",
            -- Name
            Name = "星火术",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "3",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "星火术",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00星火术|r：星辰法师的主要伤害技能，咏唱2.5秒后对目标释放一道强烈的星辰之力，伤害主要目标并对其周围300码范围内的目标造成33%的伤害，伤害类型为自然魔法伤害。",
            -- Tooltip - Turn Off
            Untip = "星火术",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human",
            -- Targets Allowed
            targs = "enemy"
        }
    )

local zhudong3 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\taifeng.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            Cost = 10,
            -- Caster Attachments
            Casterattachcount = 1,
            -- Cooldown
            Cool = 20.0,
            -- Follow Through Time
            DataA = 0.01,
            -- Target Type
            DataB = 2,
            -- Options
            DataC = 3,
            -- Art Duration
            DataD = 0.01,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[2],
            -- Editor Suffix
            EditorSuffix = "星辰法师",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "E",
            -- Name
            Name = "台风",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "5",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "台风",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00台风|r：星辰法师引动星辰之力，在目标地点释放一阵强烈的台风席卷大地，打断范围内所有敌人的施法并造成150%主属性的的土系魔法直接伤害。之后台风会持续5秒，每秒对受影响区域内的目标造成50%主属性的持续伤害，该效果不具有打断效果。",
            -- Tooltip - Turn Off
            Untip = "台风",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human",
            -- Targets Allowed
            targs = "enemy",
            Area = 400
        }
    )

local zhudong4 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\xingyongshu.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 3,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Caster Attachments
            Casterattachcount = 1,
            -- Cooldown
            Cool = 0.2,
            -- Follow Through Time
            DataA = 0.07,
            -- Target Type
            DataB = 1,
            Cost = 0,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0.5,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[4],
            -- Editor Suffix
            EditorSuffix = "星辰法师",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "R",
            -- Name
            Name = "星涌术",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "7",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "星涌术(|cffffcc00E|r)",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00星涌术|r：星辰法师消耗大量魔法对目标爆发巨大的星辰之力，对目标造成大量自然魔法伤害，对目标周围单位造成33%的溅射伤害。使用该技能后，星辰法师会进入星辰之力过载状态，持续5秒。持续时间内星涌术会额外消耗100%的魔法并造成额外50%的伤害。该状态最多叠加两层。该技能基础蓝耗为20。",
            -- Tooltip - Turn Off
            Untip = "星涌术(|cffffcc00E|r)",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human",
            -- Targets Allowed
            targs = "enemy"
        }
    )

local zhudong5 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\zhiri.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Caster
            CasterArt = "",
            -- Caster Attachments
            Casterattachcount = 1,
            Cost = 10,
            -- Cooldown
            Cool = 45.0,
            -- Follow Through Time
            DataA = 0.0,
            -- Target Type
            -- DataB = 2,
            -- Options
            DataC = 3,
            -- Art Duration
            DataD = 0.0,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[5],
            -- Editor Suffix
            EditorSuffix = "星辰法师",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "D",
            -- Name
            Name = "群星坠落",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "11",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "群星坠落",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00群星坠落|r：星辰法师利用自身对星辰的亲和，召唤群星坠落，对周围敌人造成伤害。该技能为瞬发技能，释放后星辰法师会获得群星坠落状态，每隔0.5秒对800码范围内的随机2个敌人释放坠星，造成自然魔法伤害，持续5秒。",
            -- Tooltip - Turn Off
            Untip = "群星坠落",
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

local zhudong6 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "",
            -- Icon - Normal
            Art = "ReplaceableTextures\\xingchenfashi\\chaofanzhimeng.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 100,
            -- Mana Cost
            Cost = 20,
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
            EditorSuffix = "星辰法师",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "T",
            -- Name
            Name = "超凡之盟",
            -- Cast Range
            Rng = 150.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "超凡之盟",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00超凡之盟|r：瞬间激活日蚀和月蚀，并且使得月蚀和日蚀的伤害加成对愤怒，星火术，和星涌术都生效，持续15秒",
            -- Tooltip - Turn Off
            Untip = "超凡之盟",
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
        Art = "ReplaceableTextures\\BTNzb127.blp",
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
        Name = "星辰法师",
        -- Proper Names
        Propernames = "流浪星光",
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
        backSw1 = 0.07,
        -- Categorization - Campaign
        campaign = 0,
        -- Animation - Cast Backswing
        castbsw = 0.07,
        -- Animation - Cast Point
        castpt = 0.07,
        -- Attack 1 - Cooldown Time
        cool1 = 1.3,
        -- Death Time (seconds)
        death = 1.0,
        -- Defense Base
        def = 1,
        -- Attack 1 - Damage Base
        dmgplus1 = 1,
        -- Attack 1 - Animation Damage Point
        dmgpt1 = 0.25,
        -- Elevation - Sample Radius
        elevRad = 150.0,
        -- Model File
        file = "war3mapImported\\BloodElfFemaleMST6.mdx",
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
        walk = 320,
        run = 320,
        -- Attack 1 - Targets Allowed
        targs1 = "debris,ground,structure,air,wall,ward",
        -- Turn Rate
        turnRate = 3.0,
        -- Unit Sound Set
        unitSound = "",
        weapType1 = "",
        zhiye_cundang_str = "xingchenfashi",
        _canZhiliao = false,
        _canTank = false,
        _canShuchu = true
    }
)
