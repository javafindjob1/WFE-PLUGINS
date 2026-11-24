local tianfu =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\CHENGJIEZHILI\\PASCHENGJIEZHILI.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- 暴击率 设置为0
        DataA = 0,
        -- 说明
        Ubertip = "|cffffcc00神圣惩戒|r：这是惩戒圣骑士专精中的核心技能，为圣骑士提供了战斗中不可或缺的神圣力量增益。掌握此技能后，圣骑士将在战斗中造成更高的光明伤害，其光明伤害提高了|cff00ff0015%|r。这一增益可以通过精通进一步强化。|n|n|cffffcc00技能参数|r：|n- 光明伤害增益：增加15%光明伤害（每14点精通额外提高1%）|n|n神圣惩戒使得圣骑士在对抗邪恶和不洁之物时更加高效，是他们守护信仰和正义的重要支柱。通过增强他们的光明系攻击，圣骑士能在战斗中发挥更大的影响力，成为正义的坚定捍卫者。",
        -- Name
        Name = "神圣惩戒",
        reqLevel = 15
    }
)

local zhanshi_beidong2 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\GONGZHENGZHIJIAN\\PASGONGZHENGZHIJIAN.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "公正之剑",
        Tip = "公正之剑",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "2",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00公正之剑|r：这项技能允许惩戒圣骑士在自动攻击时发动，对目标造成|cff00ff00180%|r的攻击力的光明物理伤害。当圣骑士拥有|cffffcc00战争艺术|r技能时，公正之剑的伤害提升至|cff00ff00120%|r，并且有|cff00ff0010%|r概率额外获得一层|cffffcc00神圣能量|r。公正之剑的使用受到冷却时间的限制，冷却时间为|cff00ff0010秒|r。|n|n|cffffcc00技能参数|r：|n- 基础伤害：|cff00ff00110%|r攻击力|n- 战争艺术加成：伤害提高至|cff00ff00120%|r，额外获得神圣能量的概率为|cff00ff0010%|r|n- 冷却时间：|cff00ff0010秒|r|n|n公正之剑不仅是一次普通的攻击，它代表着圣骑士对邪恶势力的不屈斗争和对公正的坚持。每一次挥舞都是对正义的宣誓，让敌人感受到圣骑士的威严与力量。",
        -- Tooltip - Turn Off
        Untip = "公正之剑",
        reqLevel = 15
    }
)

local zhanshi_beidong3 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\KUANGRE\\PASKUANGRE.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 1,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "狂热",
        Tip = "狂热",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "4",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00狂热|r：这个技能显现了惩戒圣骑士在战斗中的热情和专注。当圣骑士使用|cffffcc00审判|r技能时，会激发出狂热状态，暂时提升圣骑士的战斗能力。在狂热状态下，圣骑士的攻击速度提高|cff00ff0030%|r，持续4秒。此外，在这段时间内，圣骑士的每次普通攻击都会额外造成相当于攻击力|cff00ff0010%|r的光明魔法伤害。|n|n|cffffcc00技能参数|r：|n- 触发条件：使用|cffffcc00审判|r技能|n- 攻击速度增加：|cff00ff0030%|r|n- 额外伤害：基础攻击力的|cff00ff0010%|r|n- 持续时间：4秒|n|n通过这种方式，狂热技能不仅提升了圣骑士的攻击速度，而且还使他们的每次攻击都附加了额外的伤害，使得圣骑士在短时间内能对敌人造成显著的伤害。这使得圣骑士在关键时刻可以发挥出更强的战斗力。",
        -- Tooltip - Turn Off
        Untip = "狂热",
        reqLevel = 15
    }
)

local zhanshi_beidong4 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\SHIZIJUNDAJI\\SHIZIJUNDAJI.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 2,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "十字军打击",
        Tip = "十字军打击",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "6",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00十字军打击|r是惩戒圣骑士的核心技能之一。当圣骑士对敌人攻击时触发，会造成100%自身攻击力与100%力量的|cffff0000光明物理伤害|r。每次成功的十字军打击还可以为圣骑士增加一层|cffffcc00神圣之怒|r。|n若圣骑士拥有|cffffcc00苍穹之力|r技能，十字军打击有20%的几率使他们的下一个|cffffcc00神圣风暴|r不消耗资源，并且造成额外的50%伤害。|n|cffffcc00伤害公式：（攻击力 + 力量） × 100%|r|n|cffffcc00冷却时间：6秒|r",
        -- Tooltip - Turn Off
        Untip = "十字军打击",
        reqLevel = 15
    }
)

local zhanshi_beidong5 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\ZHANZHENGYISHU\\PASZHANZHENGYISHU.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 3,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "战争艺术",
        Tip = "战争艺术",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "8",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00战争艺术|r：战争艺术是惩戒圣骑士对战斗技巧的精湛体现，将战斗中的每一次攻击都视为艺术的创作。这项技能使圣骑士在战斗中更加致命。每次自动攻击有|cff00ff0012%|r的概率重置|cffffcc00公正之剑|r技能的冷却时间，使得圣骑士能更频繁地释放其强大的攻击。此外，|cffffcc00公正之剑|r的伤害提高|cff00ff0020%|r，并且每次使用时有|cff00ff0010%|r的概率额外获得一层|cffffcc00神圣能量|r。|n|n|cffffcc00技能参数|r：|n- 自动攻击重置概率：|cff00ff0012%|r|n- 公正之剑额外伤害：|cff00ff0020%|r|n- 额外神圣能量获得概率：|cff00ff0010%|r|n|n战争艺术的运用不仅增强了圣骑士的攻击能力，还赋予了他们在战斗中更高的战术灵活性。圣骑士能够在关键时刻更加频繁地施展强大的技能，从而在战场上取得优势。",
        -- Tooltip - Turn Off
        Untip = "战争艺术",
        reqLevel = 15
    }
)

local zhanshi_beidong6 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\PASBTNTF_3.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "正义之火",
        Tip = "正义之火",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "9",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00正义之火|r：当惩戒圣骑士获得这项技能后，他们的|cffffcc00审判|r获得额外的力量，能够打断目标施法。与此同时，圣骑士释放审判还有20%概率激活|cffffcc00正义之火|r状态，该效果可以使下一个神圣裁决不消耗|cffffcc00神圣能量|r。|n|cffffcc00技能参数|r：|n正义之火代表着圣骑士对邪恶势力的无情打击。每次挥动武器不仅是对抗敌人，也是对正义之火的传扬。这火焰不灭，正义永存。",
        -- Tooltip - Turn Off
        Untip = "正义之火",
        reqLevel = 15
    }
)

local zhanshi_beidong7 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\WANGZHEZHUFU\\PASWANGZHEZHUFU.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 1,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "王者祝福",
        Tip = "王者祝福",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "10",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00王者祝福|r：惩戒圣骑士释放神圣的光环，为周围|cff00ff002000单位范围|r内的所有友军提供强大的加护。在这个光环的庇护下，受影响的单位获得|cff00ff0010%|r的全属性增益。|n|n|cffffcc00技能参数|r：|n- 光环范围：|cff00ff001000单位|r|n- 属性增加：|cff00ff0010%|r全属性|n|n王者祝福体现了惩戒圣骑士作为领袖的角色，他们的存在激励着盟友，使他们变得更加强大和坚韧。这种祝福是战场上的关键力量，能够在关键时刻扭转战局。",
        -- Tooltip - Turn Off
        Untip = "王者祝福",
        reqLevel = 15,
        _guanghuanAttr = {
            zhushuxing_baifenbi = "+10"
        }
    }
)
local zhanshi_beidong8 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\SHIZIJUNDAJI\\PASSHIZIJUNDAJI.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 2,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "苍穹之力",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "12",
        -- Tooltip - Normal
        Tip = "苍穹之力",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00苍穹之力|r：惩戒圣骑士在战斗中使用十字军打击时有机会获得苍穹的祝福。此特殊状态下，圣骑士的下一个|cffffcc00神圣风暴|r技能不仅无需消耗魔法，而且还能造成额外|cff00ff0050%|r的伤害。这种力量的激活需要通过|cffffcc00十字军打击|r技能触发。|n|n|cffffcc00技能参数|r：|n- 附加伤害：|cff00ff0050%|r|n- 触发方式：十字军打击|n|n苍穹之力的激活是随机的，但在关键时刻这种力量的觉醒往往能带来意想不到的转机。它象征着圣骑士与天界的深厚联系，以及他们在战场上不懈追求正义的决心。",
        -- Tooltip - Turn Off
        Untip = "苍穹之力",
        reqLevel = 15
    }
)
local zhanshi_beidong9 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\CHENGJIEDASHI\\PASCHENGJIEDASHI.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 3,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "惩戒大师",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "14",
        reqLevel = 15,
        -- Tooltip - Normal
        Tip = "惩戒大师",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00惩戒大师|r：这是一项精通惩戒圣骑士战斗艺术的高级技能。掌握此技能的圣骑士能够更有效地操纵和利用神圣能量。通过这种技能，圣骑士能在战斗中自动获得|cffffcc00神圣愤怒|r的层数，每|cff00ff0012秒|r获得一层。此外，|cffffcc00惩戒大师|r还提高了神圣愤怒的最大层数，从原来的3层增加到4层。|n|n|cffffcc00技能参数|r：|n- 神圣愤怒自动增加：每12秒自动获得1层|n- 神圣愤怒最大层数：增加至4层|n|n惩戒大师的掌握标志着圣骑士在其职业道路上的深度修炼和提升，使他们能够更加频繁地释放强大的神圣技能，同时也体现了他们对于正义事业的坚定承诺和专注。",
        -- Tooltip - Turn Off
        Untip = "惩戒大师"
    }
)

local zhanshi_beidong11 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\SHENSHENGCAIJUE\\PASSHENSHENGCAIJUE.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 1,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "正义裁决",
        -- Tooltip - Normal
        Tip = "正义裁决",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "15",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00正义裁决|r：这是惩戒圣骑士的一项关键技能，赋予他们在战斗中积累的神圣能量以形成猛烈一击。每次使用|cffffcc00神圣裁决|r时，如果圣骑士已经掌握了|cffffcc00正义裁决|r技能，那么每次施放都将增强其威力，使下一次的神圣裁决伤害提高|cff00ff006%|r,持续12秒，最多叠加5次。此外，每次施放还有|cff00ff0020%|r的几率触发连续的第二次攻击，造成|cff00ff00125%|r的伤害。|n|n|cffffcc00技能参数|r：|n- 伤害增强：每次使用增加5%伤害|n- 连击几率：20%|n- 连击伤害：125%|n|n正义裁决是圣骑士在多次战斗中积累经验和力量的象征，每一次裁决都是对邪恶的更强烈打击，展现了圣骑士不断增长的力量和对正义的坚定承诺。",
        -- Tooltip - Turn Off
        Untip = "正义裁决",
        reqLevel = 15
    }
)

local zhanshi_beidong12 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\CommandButtons\\PASBTNJN_XX_V.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 3,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "终极复仇",
        reqLevel = 15,
        -- Tooltip - Normal
        Tip = "终极复仇",
        -- Tooltip - Normal - Extended
        Ubertip = "复仇之怒 内每消耗一层神圣愤怒会叠加 1% 全局增伤，上限为50%",
        -- Tooltip - Turn Off
        Untip = "终极复仇"
    }
)

local zhanshi_beidong12 =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\MoreButtons\\KUANGBAO\\BTNKUANGBAO.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 1,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- 暴击率 设置为0
        DataA = 0,
        -- Name
        Name = "众神赐福",
        -- Tooltip - Normal
        Tip = "众神赐福",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "16",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00众神赐福|r：众神的赐福强化了圣印效果：光明圣印开启时，圣佑术期间可以免疫一次致死攻击并恢复30%生命值，该效果有180秒cd；命令圣印开启时，神圣风暴有30%概率连续释放两次；智慧圣印开启时，十字军打击的基础CD降低1秒；殉难圣印开启时，你的圣殿骑士裁决和殉难圣印造成伤害提升10%。",
        -- Tooltip - Turn Off
        Untip = "众神赐福",
        reqLevel = 15
    }
)

local beidong =
    hslk_ability(
    {
        _parent = "Aspb",
        -- Icon - Normal
        Art = "ReplaceableTextures\\PASBTN_QS_07.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 3,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- Spell List
        DataA = zhanshi_beidong2._id ..
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
                                                                    "," ..
                                                                        zhanshi_beidong11._id ..
                                                                            "," .. zhanshi_beidong12._id,
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
        Name = "惩戒骑被动技能",
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
        Art = "ReplaceableTextures\\SHENPAN\\SHENPAN.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 8.0,
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
        DataF = CONST_ABILITY_ORDER[1],
        -- Editor Suffix
        EditorSuffix = "惩戒骑",
        -- Effect
        EffectArt = "",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "1",
        -- Hotkey - Normal
        Hotkey = "Q",
        -- Name
        Name = "审判",
        -- Cast Range
        Rng = 700.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "审判",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00审判|r是圣骑士的主要技能，对目标施加一次神圣审判，基础伤害为圣骑士攻击力的|cff00ff00120%|r。如果圣骑士已经学习了|cffffcc00狂热|r技能，审判的伤害提高|cff00ff0025%|r，并且攻击速度增加|cff00ff0030%|r，在接下来的几秒内，普通攻击还会造成额外的神圣伤害。根据圣骑士当前激活的|cffffcc00圣印|r类型，审判还会有额外的效果：|cffffcc00命令审判|r：被审判的目标在接下来|cff00ff006秒|r内受到普通攻击时，会受到额外的圣骑士|cff00ff008%|r攻击力的光明魔法伤害。|cffffcc00光明审判|r：审判使圣骑士额外恢复一定比例的生命值。|cffffcc00智慧审判|r：审判使圣骑士额外恢复一定数量的魔法值。|cffffcc00殉难审判|r：审判造成的伤害翻倍，但圣骑士自身也会受到一定比例的生命值伤害。|n |cffffcc00伤害公式：攻击力 × 150% (狂热状态下 × 1.25)|r|n |cffffcc00冷却时间：8秒|r",
        -- Tooltip - Turn Off
        Untip = "审判",
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
        Animnames = "attack slam",
        -- Icon - Normal
        Art = "ReplaceableTextures\\BTN_QS_R1.blp",
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
        DataA = 0.3,
        -- Target Type
        -- DataB = 1,
        -- Options
        DataC = 1,
        -- Art Duration
        DataD = 0.3,
        -- Disable Other Abilities
        DataE = 0,
        -- Base Order ID
        DataF = CONST_ABILITY_ORDER[3],
        -- Editor Suffix
        EditorSuffix = "骑士",
        -- Effect
        EffectArt = "",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "3",
        -- Hotkey - Normal
        Hotkey = "W",
        -- Name
        Name = "神圣风暴",
        -- Cast Range
        Rng = 150.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "神圣风暴",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00神圣风暴|r是惩戒圣骑士的强大群伤技能。使用该技能会召唤出带有神圣愤怒的狂暴能量，对 |cff00ff00350码单位范围|r 内的所有敌人造成 |cffffcc00强大的光明物理伤害|r。基础伤害为圣骑士攻击力的 |cff00ff00400%|r。若圣骑士处于 |cffffcc00苍穹之力|r 状态下，伤害提高 |cff00ff0050%|r。使用此技能会为圣骑士增加一层 |cffffcc00神圣之怒|r。|n|cffffcc00伤害公式：基础攻击力 × 400% (苍穹之力状态下 × 150%)|r|n|cffffcc00冷却时间：10秒|r",
        -- Tooltip - Turn Off
        Untip = "神圣风暴",
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
        Animnames = "spell",
        -- Icon - Normal
        Art = "ReplaceableTextures\\MoreButtons\\KUANGBAO\\BTNKUANGBAO.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 2,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 0.2,
        -- Mana Cost
        Cost = 0,
        -- Follow Through Time
        DataA = 0.1,
        -- Target Type
        -- DataB = 2,
        -- Options
        DataC = 1,
        -- Art Duration
        DataD = 0.1,
        -- Disable Other Abilities
        DataE = 0,
        -- Base Order ID
        DataF = CONST_ABILITY_ORDER[2],
        -- Editor Suffix
        EditorSuffix = "惩戒骑",
        -- Effect
        EffectArt = "",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "5",
        -- Hotkey - Normal
        Hotkey = "E",
        -- Name
        Name = "圣印",
        -- Cast Range
        Rng = 800.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "圣印",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00圣印|r是一项独特的惩戒圣骑士技能，允许圣骑士在不同的战术状态之间切换，每种状态都有其独特的效果。圣骑士可以根据战斗情况选择不同的圣印以适应不同的战术需求。|n|cffffcc00命令圣印|r：提供30%的概率在攻击时造成额外的50%攻击力的|cffffcc00光明魔法伤害|r。|n|cffffcc00光明圣印|r：每次攻击100%概率恢复1%的最大生命值。|n|cffffcc00智慧圣印|r：每次攻击100%概率恢复2点魔法值。|n|cffffcc00殉难圣印|r：每次攻击100%概率造成额外的50%攻击力的|cffffcc00光明魔法伤害|r，但圣骑士自身会受到相当于1%最大生命值的伤害。|n圣骑士可以根据需要在这些圣印之间切换，以适应不断变化的战场环境。这种灵活性使得圣骑士在战斗中能够发挥出最大的潜力。",
        -- Tooltip - Turn Off
        Untip = "圣印",
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
        Animnames = "attack slam",
        -- Icon - Normal
        Art = "ReplaceableTextures\\SHENSHENGCAIJUE\\SHENSHENGCAIJUE.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 3,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 1.0,
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
        DataF = CONST_ABILITY_ORDER[4],
        -- Editor Suffix
        EditorSuffix = "惩戒骑",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "R",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "7",
        -- Name
        Name = "神圣裁决",
        -- Cast Range
        Rng = 150.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "神圣裁决",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00神圣裁决|r是惩戒圣骑士的关键技能，也是唯一消耗|cffffcc00神圣之怒|r的技能。当圣骑士积累足够的神圣之怒时，他们可以释放这个强力的单体攻击技能。基础伤害为圣骑士攻击力的|cff00ff00500%|r。伤害类型为光明魔法伤害。如果圣骑士已经学习了|cffffcc00正义裁决|r技能，神圣裁决的伤害会随着正义裁决状态的层数增加而提高，每层增加5%的伤害。此外，若圣骑士处于|cffffcc00正义之火|r状态下，神圣裁决的能量需求减少，消耗的神圣之怒层数更少。不仅如此，在学习了|cffffcc00正义裁决|r技能后，神圣裁决更有一定几率触发连击，造成更多伤害。|n|cffffcc00伤害公式：基础攻击力 × 5 (每层正义裁决状态下增加 5%)|r|n|cffffcc00冷却时间：无（由神圣之怒层数控制）|r",
        -- Tooltip - Turn Off
        Untip = "神圣裁决",
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
        Art = "ReplaceableTextures\\SHENGYOUSHU\\SHENGYOUSHU.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 1,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 15.0,
        -- Mana Cost
        Cost = 5,
        -- Follow Through Time
        DataA = 0.2,
        -- Target Type
        -- DataB = 2,
        -- Options
        DataC = 1,
        -- Art Duration
        DataD = 0.2,
        -- Disable Other Abilities
        DataE = 0,
        -- Base Order ID
        DataF = CONST_ABILITY_ORDER[6],
        -- Editor Suffix
        EditorSuffix = "惩戒骑",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "D",
        -- Name
        Name = "圣佑术",
        -- Cast Range
        Rng = 800.0,
        -- Target
        TargetArt = "",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "11",
        -- Tooltip - Normal
        Tip = "圣佑术",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00圣佑术|r是惩戒圣骑士的一项防御性技能，为他们提供了短暂的保护和增强。当使用此技能时，圣骑士会被神圣的光环所包围，大幅度提升他们的防御能力和移动速度。具体来说，圣佑术能降低圣骑士受到的伤害|cff00ff0030%|r，并且提高他们的移动速度|cff00ff00100|r点，持续6秒。这使得圣骑士在面对强大的敌人攻击或需要快速调整战场位置时，能够获得关键的优势。|n |cffffcc00冷却时间：15秒|r",
        -- Tooltip - Turn Off
        Untip = "圣佑术",
        -- Hero Ability
        hero = 0,
        -- Levels
        levels = 1,
        -- Race
        race = "human"
        -- Targets Allowed
    }
)

local zhudong6 =
    hslk_ability(
    {
        _parent = "ANcl",
        -- Animation Names
        Animnames = "",
        -- Icon - Normal
        Art = "ReplaceableTextures\\FUCHOUZHINU\\FUCHOUZHINU.blp",
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
        EditorSuffix = "惩戒骑",
        -- Effect
        EffectArt = "",
        -- Requirements
        Requires = "R000",
        -- Requirements - Levels
        Requiresamount = "13",
        -- Hotkey - Normal
        Hotkey = "T",
        -- Name
        Name = "复仇之怒",
        -- Cast Range
        Rng = 150.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "复仇之怒",
        -- Tooltip - Normal - Extended
        Ubertip = "|cffffcc00复仇之怒|r是惩戒圣骑士的终极技能，一旦激活，它将极大地增强圣骑士的攻击力。在技能持续的20秒内，圣骑士将获得|cff00ff0030%|r的伤害加成，并且十字军打击冷却时间减半，无论面对怎样强大的敌人，都能施以致命一击。这项技能的激活象征着圣骑士对邪恶的终极裁决，是他们不可动摇的信仰和不屈意志的体现。|n |cffffcc00冷却时间：100秒|r",
        -- Tooltip - Turn Off
        Untip = "复仇之怒",
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
        Art = "ReplaceableTextures\\classicon\\ClassIcon_Paladin.blp",
        -- Tooltip - Awaken
        Awakentip = "",
        -- Hit Points Maximum (Base)
        HP = 100,
        -- Starting Intelligence
        INT = 1,
        -- Intelligence per Level
        INTplus = 0.0,
        -- Name
        Name = "惩戒骑",
        -- Primary Attribute
        Primary = "STR",
        -- Proper Names
        Propernames = "莱恩",
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
        -- Defense Base
        def = 1,
        -- Attack 1 - Damage Base
        dmgplus1 = 16,
        -- Attack 1 - Animation Damage Point
        dmgpt1 = 0.55,
        -- Scaling Value
        modelScale = 1,
        -- Model File
        file = "war3mapImported\\HumanMaleWarriorHeavy.mdx",
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
        collision = 24,
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
        -- Turn Rate
        turnRate = 3.0,
        -- Unit Sound Set
        unitSound = "",
        -- Attack 1 - Weapon Sound
        weapType1 = "MetalHeavySlice",
        zhiye_cundang_str = "chengjieqi",
        _canZhiliao = false,
        _canTank = true,
        _canShuchu = true
    }
)
