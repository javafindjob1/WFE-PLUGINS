local fashi_beidong1 =
    hslk_ability(
        {
            -- Icon - Normal
            Art = "ReplaceableTextures\\PASBTNSpell_Fire_FireBolt02.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Name
            Name = "火球术",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "1",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00火球术|r: 火法师的基础攻击技能。使用火球术时，将|cffffcc00替代普通攻击|r，向目标发射一枚火球，对其造成等同于火法师智力值|cff00ff00130%|r的|cff0000ff魔法伤害|r。每次施放消耗|cff00ff002点|r魔法值。|n伤害公式：智力值 × |cff00ff00130%|r|n魔法消耗：|cff00ff002点|r|n技能特点：火球术是火法师的核心攻击技能，会|cffffcc00替代普通攻击|r。对单个目标造成显著的|cff0000ff魔法伤害|r，特别适合针对特定敌人。智力越高，造成的伤害也越大。消耗少量魔法，适合频繁使用。", -- Tooltip - Turn Off
            Untip = "火球术",
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
            Art = "ReplaceableTextures\\PASBTNWS_HUOFENGHUANG.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Name
            Name = "火凤凰",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "4",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00火凤凰|r：当火法师执行普通攻击时，有机会释放一个烈焰凤凰。这个凤凰飞向目标并爆炸，对|cff00ff00200单位范围|r内所有敌人造成|cff0000ff魔法伤害|r。这种伤害必定暴击。|n|cffffcc00伤害公式|r：智力值的180%|n|cffffcc00伤害类型|r：|cff0000ff魔法伤害|r|n|cffffcc00技能特点|r：强大的|cff00ff00范围伤害|r能力，能同时击中多个敌人。在爆炸时必定触发暴击，造成高额伤害。特别适用于敌人密集的情况，以实现最大化伤害效果。|n|cffffcc00冷却时间|r：10秒",
            -- Tooltip - Turn Off
            Untip = "火凤凰",
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
            Art = "ReplaceableTextures\\PASBTN_FS_03.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Name
            Name = "烈焰之心",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "6",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00烈焰之心|r：当火法师造成的|cff0000ff魔法伤害|r暴击时，有|cff00ff0010%|r的几率激活|cffffcc00烈焰之心|r效果，使下一次法术暴击伤害提高|cff00ff0010%|r，可叠加最多|cff00ff003次|r，效果持续|cff00ff0010秒|r。同时，烈焰之心被动增加|cff00ff003%|r的法术暴击率。|n|cffffcc00技能特点|r：提升法术暴击的伤害效果。在连续暴击中获得更高的输出潜力。需要精准的暴击时机来最大化效益。被动提高法术暴击率，增强输出稳定性。|n|cffffcc00触发几率|r：|cff00ff0010%|r|n|cffffcc00注意|r：此技能在对抗高生命值目标时尤为有效，使得火法师在持续伤害输出方面更加出色。",
            -- Tooltip - Turn Off
            Untip = "烈焰之心",
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
            Art = "ReplaceableTextures\\CHIRELIANJI\\PASBTNCHIRELIANJI.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Name
            Name = "炽热连击",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "8",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00炽热连击|r：当火法师的火系法术（如火球术、炎爆术）连续两次造成暴击时，会触发|cffffcc00炽热连击|r状态。在此状态下，法师的下次普通攻击会自动释放一次|cffffcc00炎爆术|r，释放此炎爆术不用施法但是会消耗魔法。|n|cffffcc00技能特点|r：增强火法师的连续输出能力，尤其在连续造成暴击时。免费的炎爆术增加了火法师在战斗中的灵活性和爆发力。触发连击能显著增加火法师的整体伤害输出。|n|cffffcc00注意|r：炽热连击状态仅在下一次普通攻击时生效，之后将自动消失。",
            -- Tooltip - Turn Off
            Untip = "炽热连击",
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
            Art = "ReplaceableTextures\\HUOTIZHADAN\\PASBTNHUOTIZHADAN.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Name
            Name = "活体炸弹",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "9",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00活体炸弹|r：当火法师的火球术命中目标时，会给目标施加|cffffcc00活体炸弹|r效果。该效果每秒造成|cff00ff0020%智力值|r的|cff1313da魔法伤害|r，持续4秒。若目标在效果持续期间死亡，或效果结束时，目标会发生爆炸，对|cff00ff00200范围|r内的敌人造成相当于|cff00ff00150%智力值|r的魔法伤害，并将次级活体炸弹效果传染给受影响的敌人。次级活体炸弹不会再次传染。|n|cffffcc00技能特点|r：提供火法师持续的范围伤害能力。高效清理密集的敌人群体。在敌人群体中创造连锁反应，造成大量伤害。|n|cffffcc00冷却时间|r：|cff00ff0020秒|r",
            -- Tooltip - Turn Off
            Untip = "活体炸弹",
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
            Art = "ReplaceableTextures\\LIEYANFENGBAO\\PASBTNLIEYANFENGBAO.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Name
            Name = "烈焰风暴",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "10",
            -- Follow Through Time
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00烈焰风暴|r：火法的火球术能触发|cffffcc00烈焰风暴|r，对指定地点造成范围性爆炸，影响范围为|cff00ff00300码|r。烈焰风暴对范围内的敌人造成相当于|cff00ff00250%智力值|r的|cff0000ff魔法伤害|r。|n|cffffcc00技能特点|r：强力的范围控制技能。对密集的敌人群体造成巨大伤害。适合在战斗中改变局势。|n|cffffcc00冷却时间|r：|cff00ff00无|r|n|cffffcc00触发间隔|r：|cff00ff0012|r秒。",
            -- Tooltip - Turn Off
            Untip = "烈焰风暴",
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
            Art = "ReplaceableTextures\\LIEYANHUDUN\\PASBTNLIEYANZHIDUN.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Name
            Name = "烈焰护盾",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "12",
            -- Follow Through Time
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00烈焰护盾|r：当火法师受到致命伤害时，自动触发烈焰护盾，免疫该次伤害，并获得一个持续|cffffcc0015秒|r的护盾。这个护盾能吸收相当于法师|cffffcc0030%最大生命值|r的伤害。|n|cffffcc00技能特点|r：强效的防御技能，能在关键时刻保护法师免受致命攻击。护盾吸收伤害能力与法师的最大生命值挂钩，对抗高伤害输出时尤为有效。在护盾持续期间，法师能更加自信地面对敌人的攻击。|n|cffffcc00冷却时间|r：120秒|n|cffffcc00注意|r：护盾一旦被打破或时间结束，需要等待冷却时间后才能再次触发。",
            -- Tooltip - Turn Off
            Untip = "烈焰护盾",
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
            Art = "ReplaceableTextures\\QIANGHUACHIRELIANJI\\PASBTNQIANGHUACHIRELIANJI.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 3,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 0,
            -- Name
            Name = "强化炽热连击",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "14",
            -- Follow Through Time
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00强化炽热连击|r：当火法师的|cffffcc00炽热连击|r被激活时，有|cff00ff0010%|r的几率连续触发，可以连续发动多次。每次连续触发都会使下一次普通攻击释放炎爆术，为火法师提供连续的爆发伤害。|n|cffffcc00技能特点|r：显著增强火法师的连续输出能力。为火法师带来随机的高爆发伤害机会。适用于需要快速消灭敌人的战斗场景。|n|cffffcc00触发几率|r：|cff00ff0010%|r|n|cffffcc00注意|r：此技能依靠随机性，适合于喜欢依赖爆发伤害和激活连锁效果的玩家。",
            -- Tooltip - Turn Off
            Untip = "强化炽热连击",
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
            Art = "ReplaceableTextures\\PASBTNTF_1.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Name
            Name = "太阳之王的祝福",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "15",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00太阳之王的祝福|r：当火法师消耗|cffffcc00炽热连击|r时，有|cff00ff0015%|r的几率激活|cffffcc00太阳之王的祝福|r。使|cff00ff0030秒|r内下一个手动释放的炎爆术造成的伤害提高|cff00ff00240%|r。|n|cffffcc00技能特点|r：显著增强炎爆术的单次输出能力。提供短暂但极强的输出增益。适合对单一目标造成毁灭性打击。|n|cffffcc00触发几率|r：|cff00ff0015%|r|n|cffffcc00激活持续时间|r：|cff00ff0030秒|r|n|cffffcc00注意|r：这项技能适合用于关键时刻，以对敌人造成最大伤害。",
            -- Tooltip - Turn Off
            Untip = "太阳之王的祝福",
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
            Art = "ReplaceableTextures\\fashi\\INV_Elemental_Primal_Fire.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Name
            Name = "烈焰宝珠",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "16",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00烈焰宝珠|r：炎爆术有25%概率触发烈焰宝珠缓慢向前方移动1200距离（持续约4秒），每0.5秒对400码范围内释放次级火球术（不可触发炽热连击）造成80%主属性伤害，CD10秒。（太阳之王的赐福必定触发且不计入cd）。",
            -- Tooltip - Turn Off
            Untip = "烈焰宝珠",
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
            Art = "ReplaceableTextures\\DIANRAN\\PASBTNDIANRAN.blp",
            -- Button Position - Normal (X)
            _parent = "AOcr",
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Name
            Name = "点燃",
            -- Follow Through Time
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "1",
            DataA = 0,
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00点燃|r:火焰法师的核心技能，当直接魔法伤害暴击时，会在目标身上施加|cff00ff00点燃效果|r，对其造成持续的|cfff9d210真实伤害|r。这个持续伤害在|cff00ff006秒|r内总计为初始伤害的|cff00ff0015%|r，加上每20点精通增加的|cff00ff001%|r的额外伤害。|n持续时间：|cff00ff006秒|r|n持续伤害：基于技能造成的初始伤害的|cff00ff0015%|r，每20点精通增加|cff00ff001%|r伤害|n伤害类型：|cfff9d210真实伤害|r|n技能特点：这个技能是一个被动技能，无需玩家主动操作。适用于所有火系技能的暴击效果。极大提升火法师的持续伤害能力。", -- Tooltip - Turn Off
            Untip = "点燃",
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
            Art = "ReplaceableTextures\\PASBTNSpell_Fire_FireBolt02.blp",
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
            Name = "法师被动技能",
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
            Art = "ReplaceableTextures\\HUOYANCHONGJI\\BTNHUOYANCHONGJI.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 0,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Caster Attachments
            Casterattachcount = 1,
            -- Cooldown
            Cool = 10.0,
            -- Follow Through Time
            DataA = 0,
            -- Target Type
            DataB = 1,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0.5,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[1],
            -- Editor Suffix
            EditorSuffix = "火法",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "Q",
            -- Name
            Name = "火焰冲击",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "2",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "火焰冲击",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00火焰冲击|r：对一个目标释放强烈的火元素魔法，造成即时的|cff0000ff魔法伤害|r。伤害值等同于施法者当前智力值的|cff00ff00150%|r。技能具有立即效果，且在命中时附加额外的法术暴击伤害效果。|n|cffffcc00技能特点|r：必定暴击的单体技能，伤害数值与施法者智力值直接相关。|n|cffffcc00伤害数值|r：基础伤害为施法者当前智力值的|cff00ff00150%|r。|n|cffffcc00冷却时间|r：10秒。|n",
            -- Tooltip - Turn Off
            Untip = "火焰冲击",
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
            Art = "ReplaceableTextures\\LONGXISHU\\BTNLONGXISHU.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Caster Attachments
            Casterattachcount = 1,
            -- Cooldown
            Cool = 15.0,
            -- Follow Through Time
            DataA = 0.3,
            -- Target Type
            DataB = 2,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0.3,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[3],
            -- Editor Suffix
            EditorSuffix = "火法",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "W",
            -- Name
            Name = "龙息术",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "3",
            -- Cast Range
            Rng = 700.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "龙息术",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00龙息术|r：施法者向前方喷射强烈的火焰，对直线路径上的所有敌人造成|cff0000ff魔法伤害|r并打断施法。此技能造成的伤害与施法者的智力值成正比。|n|cffffcc00技能特点|r：面对一条直线上多个敌人时极为有效，特别适合群体控制和群体伤害。|n|cffffcc00伤害数值|r：基础伤害为施法者当前智力值的|cff00ff00250%|r。|n|cffffcc00冷却时间|r：15秒。|n",
            -- Tooltip - Turn Off
            Untip = "龙息术",
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
            Art = "ReplaceableTextures\\SHANXIAN\\BTNSHANXIAN.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 2,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Caster Attachments
            Casterattachcount = 1,
            -- Cooldown
            Cool = 10.0,
            -- Follow Through Time
            DataA = 0.01,
            -- Target Type
            DataB = 2,
            -- Options
            DataC = 1,
            -- Art Duration
            DataD = 0.01,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[2],
            -- Editor Suffix
            EditorSuffix = "火法",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "E",
            -- Name
            Name = "闪现",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "5",
            -- Cast Range
            Rng = 30000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "闪现",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00闪现|r：瞬间移动到指定位置，最大位移距离700，无法穿越地形，允许施法者快速脱离危险或重新定位。此技能不造成伤害，但在战术上极为重要，提供了极高的机动性。|n|cffffcc00技能特点|r：无伤害，高灵活性，瞬间位移。|n|cffffcc00冷却时间|r：|cff00ff0010秒|r。|n",
            -- Tooltip - Turn Off
            Untip = "闪现",
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

local zhudong4 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "spell",
            -- Icon - Normal
            Art = "ReplaceableTextures\\BTN_FS_01.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 3,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 2,
            -- Caster
            CasterArt = "",
            -- Caster Attachments
            Casterattachcount = 1,
            -- Cooldown
            Cool = 10.0,
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
            DataF = CONST_ABILITY_ORDER[4],
            -- Editor Suffix
            EditorSuffix = "火法",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "R",
            -- Name
            Name = "炎爆术",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "7",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "炎爆术(|cffffcc00E|r)",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00炎爆术|r：消耗7点魔法，向指定目标施放一颗强大的火球，造成巨额的|cff0000ff魔法伤害|r。伤害值基于施法者当前智力值，并可通过|cffffcc00太阳之王的祝福|r状态显著增加。|n|cffffcc00技能特点|r：极高单体伤害，适合对付高生命值的目标。|n|cffffcc00伤害公式|r：基础伤害为施法者当前智力值的|cff00ff00600%|r，若激活|cffffcc00太阳之王的祝福|r，伤害提高至|cff00ff002040%|r。|n|cffffcc00冷却时间|r：|cff00ff0010秒|r。|n",
            -- Tooltip - Turn Off
            Untip = "炎爆术(|cffffcc00E|r)",
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
            Art = "ReplaceableTextures\\BTN_FS_02.blp",
            -- Button Position - Normal (X)
            Buttonpos_1 = 1,
            -- Button Position - Normal (Y)
            Buttonpos_2 = 1,
            -- Caster
            CasterArt = "",
            -- Caster Attachments
            Casterattachcount = 1,
            -- Cooldown
            Cool = 45.0,
            -- Follow Through Time
            DataA = 10.0,
            -- Target Type
            DataB = 2,
            -- Options
            DataC = 3,
            -- Art Duration
            DataD = 10.0,
            -- Disable Other Abilities
            DataE = 0,
            -- Base Order ID
            DataF = CONST_ABILITY_ORDER[5],
            -- Editor Suffix
            EditorSuffix = "火法",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "D",
            -- Name
            Name = "陨石术",
            -- Requirements
            Requires = "R000",
            -- Requirements - Levels
            Requiresamount = "11",
            -- Cast Range
            Rng = 1000.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "陨石术",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00陨石术|r：召唤陨石轰击指定区域，对区域内的所有敌人造成|cff0000ff魔法伤害|r。伤害值基于施法者的智力值。初次撞击造成大量伤害，并打断单位的施法，随后持续造成较小的伤害。|n|cffffcc00技能特点|r：高伤害的群体技能，适合对付密集的敌方单位。|n|cffffcc00初始伤害数值|r：施法者当前智力值的|cff00ff00800%|r。|n|cffffcc00持续伤害数值|r：施法者当前智力值的|cff00ff00100%|r，持续6秒，每秒造成一次伤害。|n|cffffcc00冷却时间|r：45秒。|n",
            -- Tooltip - Turn Off
            Untip = "陨石术",
            -- Hero Ability
            hero = 0,
            -- Levels
            levels = 1,
            -- Race
            race = "human",
            -- Targets Allowed
            targs = "enemies",
            Area = 300
        }
    )

local zhudong6 =
    hslk_ability(
        {
            _parent = "ANcl",
            -- Animation Names
            Animnames = "",
            -- Icon - Normal
            Art = "ReplaceableTextures\\BTNzb172.blp",
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
            EditorSuffix = "火法",
            -- Effect
            EffectArt = "",
            -- Hotkey - Normal
            Hotkey = "T",
            -- Name
            Name = "燃烧",
            -- Cast Range
            Rng = 150.0,
            -- Target
            TargetArt = "",
            -- Tooltip - Normal
            Tip = "燃烧",
            -- Tooltip - Normal - Extended
            Ubertip =
            "|cffffcc00燃烧|r：法师激活其终极技能，将自身包裹在强大的燃烧光环中。在这种状态下，法师的法术暴击率增加至|cff00ff00100%|r，同时将所有原有的暴击率转化为相应的暴击伤害加成。这是一种极端的爆发技能，大幅提升法师的法术输出能力。|n|cffffcc00效果特点|r：极大提升法师自身的法术暴击能力，保证法术攻击在持续时间内几乎总是暴击，并显著增加额外的暴击伤害。|n|cffffcc00暴击率增加|r：增加至|cff00ff00100%|r。|n|cffffcc00暴击伤害加成|r：原有暴击率数值转化为相同的暴击伤害加成。|n|cffffcc00持续时间|r：|cff00ff0010秒|r。|n|cffffcc00冷却时间|r：|cff00ff00100秒|r。|n",
            -- Tooltip - Turn Off
            Untip = "燃烧",
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
        Name = "火法",
        -- Proper Names
        Propernames = "泪珠",
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
        dmgpt1 = 0.25,
        -- Elevation - Sample Radius
        elevRad = 150.0,
        -- Model File
        file = "pifu\\huofa2.mdx",
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
        zhiye_cundang_str = "huofa",
        _canZhiliao = false,
        _canTank = false,
        _canShuchu = true
    }
)
