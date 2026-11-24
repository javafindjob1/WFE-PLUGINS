local tianfu =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\lieren\\baibuchuanyang.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- 暴击率 设置为0
            DataA = 0,
            -- 说明
            Ubertip =
            "|cffffcc00百步穿杨|r：猎人的核心技能，猎人距离目标越远，造成的伤害越高，最低加成10%，最高加成20%，最大加成距离800，每10点精通可以提高1%最大伤害加成和0.5%最低伤害加成。持续伤害不会受到加成。",
            -- Name
            Name = "百步穿杨",
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
            Art = "ReplaceableTextures\\lieren\\jichusheji.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "基础射击",
            Tip = "基础射击",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00基础射击|r：猎人的基础攻击技能，每次击中敌人恢复1点能量|n",
            -- Tooltip - Turn Off
            Untip = "基础射击",
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
            Art = "ReplaceableTextures\\lieren\\miaozhunsheji.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "瞄准射击",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "4",
            Tip = "瞄准射击",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00瞄准射击|r：猎人的主要输出技能，瞄准敌人之后射出一只威力巨大的箭矢，造成基于200%攻击力和敏捷之和的物理伤害，该技能会自动释放，优先级高于基础射击和奥术射击。基础冷却时间6秒，技能不消耗能量。|n",
            -- Tooltip - Turn Off
            Untip = "瞄准射击",
            reqLevel = 15
        }
    )

local zhanshi_beidong3 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\PASBTNCehXVebpcbChsir.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "射击技巧",
            reqLevel = 15,
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "6",
            -- Tooltip - Normal
            Tip = "射击技巧",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00射击技巧|r：射击猎人学会了强大的群攻技巧，被多重射击影响的敌人会获得射击技巧状态，使得猎人下一次瞄准射击和奥术射击可以同时攻击该目标，该效果在触发额外的瞄准和奥术后会消失。|n",
            -- Tooltip - Turn Off
            Untip = "射击技巧"
        }
    )

local zhanshi_beidong4 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\lieren\\aoshusheji.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "奥术射击",
            Tip = "奥术射击",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "8",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00奥术射击|r：猎人射出一只带有奥术力量的魔力箭矢，对目标造成300%敏捷的魔法伤害。该技能优先级低于瞄准射击但是高于基础射击。该技能没有冷却时间，如果猎人的能量值高于60，则下次普通攻击会转化为奥术射击，并消耗40点能量值。|n",
            -- Tooltip - Turn Off
            Untip = "奥术射击",
            reqLevel = 15
        }
    )

local zhanshi_beidong5 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\lieren\\jisushejibeidong.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "急速射击",
            -- Tooltip - Normal
            Tip = "急速射击",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "9",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00急速射击|r：增强快速射击技能，降低0.5秒的施法时间并且增加一只箭矢|n",
            -- Tooltip - Turn Off
            Untip = "急速射击",
            reqLevel = 15
        }
    )

local zhanshi_beidong6 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\PASBTN_LR_T1.blp",
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
            Name = "高效瞄准",
            -- Tooltip - Normal
            Tip = "高效瞄准",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00高效瞄准|r：瞄准射击有15%的概率刷新快速射击的CD|n",
            -- Tooltip - Turn Off
            Untip = "高效瞄准",
            reqLevel = 15
        }
    )

local zhanshi_beidong7 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\lieren\\heqiangshidan.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "荷枪实弹",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "12",
            Tip = "荷枪实弹",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00荷枪实弹|r：猎人的基础射击有10%的概率触发准备就绪，刷新瞄准射击的冷却时间|n",
            -- Tooltip - Turn Off
            Untip = "荷枪实弹",
            reqLevel = 15
        }
    )

local zhanshi_beidong8 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\lieren\\qiangjiguanghuan.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "强击光环",
            Tip = "强击光环",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "14",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00强击光环|r：射击猎人的标志技能，可以提升周围2000码范围内所有友军7%的攻击力和3%的命中|n",
            -- Tooltip - Turn Off
            Untip = "强击光环",
            reqLevel = 15,
            _guanghuanAttr = {
                gongji_baifenbi = "+7",
                hit = "+3"
            }
        }
    )

local zhanshi_beidong9 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\PASBTN520272.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "风行者的馈赠",
            reqLevel = 15,
            -- Tooltip - Normal
            Tip = "风行者的馈赠",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00风行者的馈赠|r：射击猎人的终极技能。瞄准射击和奥术射击会触发两枚风行者之箭，另外攻击有25%概率触发一枚风行者之箭，造成33% * （攻击+敏捷）的伤害。能触发风行者的馈赠的技能包含瞄准射击，奥术射击和快速射击。风行者之箭在击中目标时会恢复1点能量值，并且会提高猎人0.5%的技能加速和1%的攻击速度，最多叠加20层。|n",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "15",
            -- Tooltip - Turn Off
            Untip = "风行者的馈赠"
        }
    )

local zhanshi_beidong10 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\lieren\\Spell_Hunter_AspectOfTheIronHawk.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- 暴击率 设置为0
            DataA = 0,
            -- Name
            Name = "兽神守护",
            reqLevel = 15,
            -- Tooltip - Normal
            Tip = "兽神守护",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00兽神守护|r：强化你的守护效果：灵龙守护，减少奥术射击3点蓝耗，同时增强奥术射击5%的伤害。猎豹守护，让你的快速射击多发射一支箭矢，并且快速射击伤害提高5%。雄鹰守护，瞄准射击的冷却降低0.5秒，伤害增加8%。|n",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "16",
            -- Tooltip - Turn Off
            Untip = "兽神守护"
        }
    )

local beidong =
    hslk_ability(
        {
            _parent = "Aspb",
            -- Icon - Normal
            Art = "ReplaceableTextures\\lieren\\jichusheji.blp",
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
            Name = "射击猎被动技能",
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
            Art = "ReplaceableTextures\\lieren\\Ability_Hunter_Quickshot.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 5.0,
            -- Mana Cost
            Cost = 10,
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
            EditorSuffix = "射击猎",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "Q",
            -- Name
            Name = "毒蛇钉刺",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "毒蛇钉刺",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00毒蛇钉刺|r：猎人射出一枚带有剧毒的箭矢，使目标中毒，降低20点移动速度，并且每2秒受到一次自然魔法伤害，数值为80%的敏捷，持续16秒。该技能可以被技能加速加成。|n",
            -- Tooltip - Turn Off
            Untip = "毒蛇钉刺",
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
            Art = "ReplaceableTextures\\lieren\\Spell_Fire_TwilightFlameBolt.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 15.0,
            -- Mana Cost
            Cost = 10,
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
            EditorSuffix = "射击猎",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "W",
            -- Name
            Name = "哀痛之箭",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "哀痛之箭",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00哀痛之箭|r：猎人射出一只附着黑暗之力的箭矢，轰击目标位置，对范围内所有单位造成50%攻击力的伤害并打断单位施法|n",
            -- Tooltip - Turn Off
            Untip = "哀痛之箭",
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
            Art = "ReplaceableTextures\\lieren\\Spell_Hunter_AspectOfTheIronHawk.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 1.0,
            -- Mana Cost
            Cost = 2,
            -- Follow Through Time
            DataA = 0.5,
            -- Target Type
            -- DataB = 2,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0.5,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[2],
            -- Editor Suffix
            EditorSuffix = "射击猎人",
            -- Effect
            EffectArt = "",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "11",
            -- Hotkey - Normal
            Hotkey = "D",
            -- Name
            Name = "守护",
            -- Cast Range
            Rng = 800.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "守护",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00守护|r猎人在多年的冒险生涯中学会了在多种状态中切换。守护可以切换成3种形态，雄鹰守护增加15%攻击力，猎豹守护增加30点移动速度和20%攻击速度，灵龙守护增加基础射击3点能量回复",
            -- Tooltip - Turn Off
            Untip = "守护",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human"
            -- Targets Allowed
        }
    )

local zhudong4 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\BTN_LR_kuangfengsheji.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 3,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 15.0,
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
            EditorSuffix = "射击猎",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "R",
            -- Name
            Name = "快速射击",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "快速射击",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00快速射击|r：猎人进入专注状态连续射出5支箭矢，每只箭矢造成100%敏捷+攻击力的物理伤害，需要持续施法3.5秒。该技能可以受到攻击速度和技能加速的双重加成|n",
            -- Tooltip - Turn Off
            Untip = "快速射击",
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
            Art = "ReplaceableTextures\\CommandButtons\\BTNUpgradeMoonGlaive.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Cooldown
            Cool = 2.0,
            -- Mana Cost
            Cost = 10,
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
            DataF = CONST_ABILITY_ORDER[6],
            -- Editor Suffix
            EditorSuffix = "射击猎",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "E",
            -- Name
            Name = "多重射击",
            -- Cast Range
            Rng = 800.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "多重射击",
            -- Tooltip - Normal - Extended
            Ubertip = "|cffffcc00多重射击|r：猎人对目标范围内所有单位进行一次攻击|n",
            -- Tooltip - Turn Off
            Untip = "多重射击",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "5",
            -- only enemy
            targs = "enemies",
            Area = 300
        }
    )

local zhudong6 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\BTN_YX_W1.blp",
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
            DataA = 0.3,
            -- Target Type
            --DataB = 1,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0.3,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[5],
            -- Editor Suffix
            EditorSuffix = "射击猎",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "T",
            -- Name
            Name = "百发百中",
            -- Cast Range
            Rng = 150.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "百发百中",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00百发百中|r：猎人的终极爆发技能，提高猎人主要技能的伤害和速度。提高猎人20%的技能加速和30%的攻击速度，同时立即恢复所有能量并刷新瞄准射击的CD并在持续时间内降低50%瞄准射击的CD和50%奥术射击的能量消耗，持续15秒。|n",
            -- Tooltip - Turn Off
            Untip = "百发百中",
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
        Art = "ReplaceableTextures\\BTN_LR.blp",
        -- Tooltip - Awaken
        Awakentip = "I05S",
        -- Hit Points Maximum (Base)
        HP = 100,
        -- Starting Intelligence
        INT = 1,
        -- Primary Attribute
        Primary = "AGI",
        -- Intelligence per Level
        INTplus = 0.0,
        -- Attack 1 - Projectile Arc
        Missilearc_1 = 0.1,
        -- Attack 1 - Projectile Art
        Missileart_1 = "war3mapImported\\DruidoftheTalonMissile.mdl",
        -- Attack 1 - Projectile Speed
        Missilespeed_1 = 1500,
        -- Name
        Name = "射击猎",
        -- Proper Names
        Propernames = "追风者",
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
        cool1 = 1.1,
        -- Death Time (seconds)
        death = 1.0,
        -- Defense Base
        def = 1,
        -- Attack 1 - Damage Base
        dmgplus1 = 1,
        -- Attack 1 - Animation Damage Point
        dmgpt1 = 0.1,
        -- Elevation - Sample Radius
        elevRad = 150.0,
        -- Model File
        file = "war3mapImported\\HighElfArcher.mdx",
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
        -- Attack 1 - Targets Allowed
        walk = 320,
        run = 320,
        targs1 = "debris,ground,structure,air,wall,ward",
        -- Turn Rate
        turnRate = 3.0,
        -- Unit Sound Set
        unitSound = "",
        collision = 24,
        weapType1 = "",
        zhiye_cundang_str = "shejilieren",
        _canZhiliao = false,
        _canTank = false,
        _canShuchu = true
    }
)
