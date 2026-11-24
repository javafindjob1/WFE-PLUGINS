initHuanhua = function()
    local config = {
        {
            name = "人类斥候",
            art = "pifu\\renleichihou.blp",
            cdKey = "huanhua",
            cdIndex = 1,
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            file = "war3mapImported\\[Hero]_016.mdx",
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 8 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 0, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战",
                "战斗贼",
                "恶魔猎手"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ attack_speed = "+0.1" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ attack_speed = "+1" })
                }
            }
        },
        {
            name = "暗夜杀手",
            art = "pifu\\anyeshashou.blp",
            cdKey = "huanhua",
            cdIndex = 24,
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            file = "pifu\\[HZ]ANYESHASHOU.mdx",
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 12 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战",
                "战斗贼",
                "恶魔猎手"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ attack_speed = "+0.1" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ attack_speed = "+1.5" })
                }
            }
        },
        {
            name = "女性兽人战士",
            art = "pifu\\shourennvzhanshi.blp",
            cdKey = "huanhua",
            cdIndex = 2,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            file = "war3mapImported\\[Hero]_009.mdx",
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 12 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "武器战",
                "惩戒骑"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ attack_white = "+2" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ attack_white = "+5" })
                }
            }
        },
        {
            name = "荒野骑士",
            art = "pifu\\huangyeqishi.blp",
            cdKey = "huanhua",
            cdIndex = 3,
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = "war3mapImported\\[pifu]Hadagan_Palladin.mdx",
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 12 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "武器战",
                "惩戒骑"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+2" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+5" })
                }
            }
        },
        {
            name = "兔女郎",
            art = "pifu\\tunvlang.blp",
            cdKey = "huanhua",
            cdIndex = 4,
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = "war3mapImported\\[pifu]S0.mdx",
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 18 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "武器战",
                "惩戒骑"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+3" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+6" })
                }
            }
        },
        {
            name = "矮人大叔",
            art = "pifu\\airendashu.blp",
            cdKey = "huanhua",
            cdIndex = 5,
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = "war3mapImported\\[pifu]S3.mdx",
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 8 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 0, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "武器战",
                "惩戒骑"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+2" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+5" })
                }
            }
        },
        {
            name = "矮人骑士",
            art = "pifu\\airenqishi.blp",
            cdKey = "huanhua",
            cdIndex = 6,
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = "war3mapImported\\[pifu]S1.mdx",
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 18 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "武器战",
                "惩戒骑"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_zengshang = "+0.1", fa_zengshang = "+0.1" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_zengshang = "+0.3", fa_zengshang = "+0.3" })
                }
            }
        },
        {
            name = "血精灵女战士",
            art = "pifu\\xuejinglingnvzhanshi.blp",
            cdKey = "huanhua",
            cdIndex = 7,
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = "war3mapImported\\[pifu]S2.mdx",
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 8 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 0, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "武器战",
                "惩戒骑"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_chuan = "+0.1" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_chuan = "+1" })
                }
            }
        },
        {
            name = "血色武装",
            art = "pifu\\xuesewuzhuang.blp",
            cdKey = "huanhua",
            cdIndex = 8,
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = "war3mapImported\\[Hero]_006_jd.mdx",
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 8 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 0, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "武器战",
                "惩戒骑"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ attack_white = "+2" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ attack_white = "+5" })
                }
            }
        },
        {
            name = "武装女精灵",
            art = "pifu\\wuzhuangnvjingling.blp",
            cdKey = "huanhua",
            cdIndex = 9,
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = "war3mapImported\\[pifu]zhanshiD2.mdx",
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 12 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "武器战",
                "惩戒骑"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_baoshang = "+1" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_baoshang = "+5" })
                }
            }
        },
        {
            name = "咕咕",
            art = "pifu\\gugu.blp",
            cdKey = "huanhua",
            cdIndex = 23,
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            file = "pifu\\DruidOwlBearTauren.mdx",
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 3 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 0, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "星辰法师"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ skill_speed = "+0.1" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ skill_speed = "+1" })
                }
            }
        },
        {
            name = "白发法师",
            art = "pifu\\baifafashi.blp",
            cdKey = "huanhua",
            cdIndex = 10,
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = "war3mapImported\\[pifu]F1.mdx",
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 12 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ master = "+2" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ master = "+5" })
                }
            }
        },
        {
            name = "红龙女王",
            art = "pifu\\honglongnvwang.blp",
            cdKey = "huanhua",
            cdIndex = 11,
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = "war3mapImported\\[pifu]F2.mdx",
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 18 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+3" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+6" })
                }
            }
        },
        {
            name = "血精灵舞女",
            art = "pifu\\xuejinglingwunv.blp",
            cdKey = "huanhua",
            cdIndex = 12,
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = "war3mapImported\\[pifu]M2.mdx",
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 25 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 2, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ master = "+5" })
                }
            },
            equipEffects = {
                {
                    description = "火凤凰，痛苦诅咒，献祭，星火术伤害提高5%",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if
                            evtData.triggerSkill == hslk.n2i("火凤凰") or evtData.triggerSkill == hslk.n2i("痛苦诅咒") or
                            evtData.triggerSkill == hslk.n2i("献祭") or
                            evtData.triggerSkill == hslk.n2i("星火术")
                        then
                            evtData.damage = evtData.damage * 1.05
                        end
                    end
                }
            },
            whiteList = { "Nestea#8782", "麻辣小鲨鱼#1190" }
        },
        {
            name = "维库人猎手",
            art = "pifu\\weikurenlieshou.blp",
            cdKey = "huanhua",
            cdIndex = 13,
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = "war3mapImported\\[pifu]Y6.mdx",
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 8 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 0, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "射击猎"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ attack_white = "+2" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ attack_white = "+5" })
                }
            }
        },
        {
            name = "夜之子猎手",
            art = "pifu\\yezhizilieshou.blp",
            cdKey = "huanhua",
            cdIndex = 14,
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = "war3mapImported\\[pifu]Y4.mdx",
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 12 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "射击猎"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ attack_speed = "+0.5" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ attack_speed = "+2" })
                }
            }
        },
        {
            name = "人类猎手",
            art = "pifu\\renleilieshou.blp",
            cdKey = "huanhua",
            cdIndex = 15,
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = "war3mapImported\\[pifu]Y7.mdx",
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 18 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 2, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "射击猎"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_bao = "+0.1" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_bao = "+0.5" })
                }
            },
            whiteList = { "柠檬#1382" }
        },
        {
            name = "武装战姬十河",
            art = "pifu\\wuzhuangzhanji.blp",
            cdKey = "huanhua",
            cdIndex = 25,
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = "pifu\\[PIFU]ZS_04.mdx",
            description = "可以改变角色的外观，可以在冒险者工会会长处购买。",
            position = HUANHUA_POSITION.JUESE,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 18 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 2, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "惩戒骑",
                "武器战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
        },
        {
            name = "雷霆之怒·逐风者之剑（主手）",
            art = hslk.n2v("雷霆之怒·逐风者之剑", "Art"),
            cdKey = "huanhua",
            cdIndex = 16,
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = hslk.n2v("雷霆之怒·逐风者之剑", "TargetArt"),
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.ZHUSHOU,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 8 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 2, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "战斗贼",
                "恶魔猎手",
                "狂暴战"
            },
            activateEffects = {},
            equipEffects = {},
            customCheck = {
                description = "需要完成雷霆之怒任务线并且在装备收集界面激活雷霆之怒·逐风者之剑",
                check = function(whichPlayer)
                    if
                        hquestcustom.isQuestFinished(whichPlayer, "传奇任务：雷霆之怒") and
                        hzhuangbeishouji.isActive(whichPlayer, "雷霆之怒·逐风者之剑")
                    then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "雷霆之怒·逐风者之剑（副手）",
            art = hslk.n2v("雷霆之怒·逐风者之剑", "Art"),
            cdKey = "huanhua",
            cdIndex = 17,
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = hslk.n2v("雷霆之怒·逐风者之剑", "TargetArt"),
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.FUSHOU,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 8 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 2, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "战斗贼",
                "恶魔猎手",
                "狂暴战"
            },
            activateEffects = {},
            equipEffects = {},
            customCheck = {
                description = "需要完成雷霆之怒任务线并且在装备收集界面激活雷霆之怒·逐风者之剑",
                check = function(whichPlayer)
                    if
                        hquestcustom.isQuestFinished(whichPlayer, "传奇任务：雷霆之怒") and
                        hzhuangbeishouji.isActive(whichPlayer, "雷霆之怒·逐风者之剑")
                    then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "炎魔之手（副手）",
            art = hslk.n2v("炎魔之手", "Art"),
            cdKey = "huanhua",
            cdIndex = 18,
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = hslk.n2v("炎魔之手", "TargetArt"),
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.FUSHOU,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 8 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 2, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战"
            },
            activateEffects = {},
            equipEffects = {},
            customCheck = {
                description = "需要完成炎魔之手务线并且在装备收集界面激活炎魔之手",
                check = function(whichPlayer)
                    if
                        hquestcustom.isQuestFinished(whichPlayer, "传奇任务：炎魔之手") and
                        hzhuangbeishouji.isActive(whichPlayer, "炎魔之手")
                    then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "炎魔之手（主手）",
            art = hslk.n2v("炎魔之手", "Art"),
            cdKey = "huanhua",
            cdIndex = 19,
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = hslk.n2v("炎魔之手", "TargetArt"),
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.ZHUSHOU,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 8 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 2, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "武器战",
                "狂暴战",
                "惩戒骑"
            },
            activateEffects = {},
            equipEffects = {},
            customCheck = {
                description = "需要完成炎魔之手务线并且在装备收集界面激活炎魔之手",
                check = function(whichPlayer)
                    if
                        hquestcustom.isQuestFinished(whichPlayer, "传奇任务：炎魔之手") and
                        hzhuangbeishouji.isActive(whichPlayer, "炎魔之手")
                    then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "埃提耶什·守护者之杖",
            art = hslk.n2v("埃提耶什·守护者之杖", "Art"),
            cdKey = "huanhua",
            cdIndex = 20,
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = hslk.n2v("埃提耶什·守护者之杖", "TargetArt"),
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.ZHUSHOU,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 8 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 2, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            activateEffects = {},
            equipEffects = {},
            customCheck = {
                description = "需要完成传奇任务任务线并且在装备收集界面激活埃提耶什·守护者之杖",
                check = function(whichPlayer)
                    if
                        hquestcustom.isQuestFinished(whichPlayer, "传奇任务：埃提耶什") and
                        hzhuangbeishouji.isActive(whichPlayer, "埃提耶什·守护者之杖")
                    then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "灰烬之力",
            art = hslk.n2v("灰烬之力", "Art"),
            cdKey = "huanhua",
            cdIndex = 21,
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = hslk.n2v("灰烬之力", "TargetArt"),
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.ZHUSHOU,
            cost = { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 8 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "武器战",
                "狂暴战",
                "惩戒骑"
            },
            activateEffects = {},
            equipEffects = {},
            customCheck = {
                description = "需要完成灰烬之力任务线并且在装备收集界面激活灰烬之力",
                check = function(whichPlayer)
                    if
                        hquestcustom.isQuestFinished(whichPlayer, "传奇任务：灰烬之力") and
                        hzhuangbeishouji.isActive(whichPlayer, "灰烬之力")
                    then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "灰烬之力(副手)",
            art = hslk.n2v("灰烬之力", "Art"),
            cdKey = "huanhua",
            cdIndex = 22,
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            file = hslk.n2v("灰烬之力", "TargetArt"),
            description = "可以改变角色的外观。",
            position = HUANHUA_POSITION.FUSHOU,
            cost = { { type = HSHOP_COST_TYPE.gold, value = 50000 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "冒险者工会" } },
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战"
            },
            activateEffects = {},
            equipEffects = {},
            customCheck = {
                description = "需要完成灰烬之力任务线并且在装备收集界面激活灰烬之力",
                check = function(whichPlayer)
                    if
                        hquestcustom.isQuestFinished(whichPlayer, "传奇任务：灰烬之力") and
                        hzhuangbeishouji.isActive(whichPlayer, "灰烬之力")
                    then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "小法师",
            art = "pifu\\xiaofashi.blp",
            cdKey = "SCPFXFS",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\[pifu]F0.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ skill_speed = "+3" })
                }
            }
        },
        {
            name = "斩服少女",
            art = "pifu\\zhanfushaonv.blp",
            cdKey = "SCPFZFSN",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "pifu\\DZ_SKIN_03.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战",
                "战斗贼",
                "恶魔猎手"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "破击和暴怒造成的伤害提高2%",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.triggerSkill == hslk.n2i("破击") or evtData.triggerSkill == hslk.n2i("暴怒") then
                            evtData.damage = evtData.damage * 1.05
                        end
                    end
                }
            }
        },
        {
            name = "小音",
            art = "pifu\\xiaoyin.blp",
            cdKey = "SCPFXY",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "pifu\\unit_ssj.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "惩戒骑",
                "武器战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "暴击：造成的物理伤害有5%的概率暴击，伤害提升为原来的120%",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.damageType == DAMAGE_TYPE.WULI then
                            if math.random(1, 100) <= 5 then
                                evtData.damage = evtData.damage * 1.2
                            end
                        end
                    end
                }
            }
        },
        {
            name = "追风少女",
            art = "pifu\\zhuifengzhe.blp",
            cdKey = "SCPFZFESN",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\[pifu]Y0.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "射击猎"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "风行者的馈赠伤害增加5%",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.triggerSkill == hslk.n2i("风行者的馈赠") then
                            evtData.damage = evtData.damage * 1.05
                        end
                    end
                }
            }
        },
        {
            name = "清风光环",
            art = "pifu\\qingfengguanghuan.blp",
            cdKey = "SCGHQFGF",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\AZ_G003.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.GUANGHUAN,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                },
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ move = "+10" })
                }
            }
        },
        {
            name = "神官",
            art = "pifu\\shenguan.blp",
            cdKey = "SCPFSHENG",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "pifu\\[PIFU]FS_02.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ fa_zengshang = "+1" })
                }
            }
        },
        {
            name = "小蝶（正手持剑）",
            art = "pifu\\xiaodie.blp",
            cdKey = "SCPFXIAOD",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "pifu\\[PIFU]DZ_02_1.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战",
                "战斗贼",
                "恶魔猎手"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+5" })
                }
            },
            equipEffects = {
                {
                    description = "英勇打击和连击的伤害提高2%",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.triggerSkill == hslk.n2i("连击") or evtData.triggerSkill == hslk.n2i("英勇打击") then
                            evtData.damage = evtData.damage * 1.02
                        end
                    end
                }
            }
        },
        {
            name = "小蝶（反手持剑）",
            art = "pifu\\xiaodie.blp",
            cdKey = "SCPFXIAOD",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "pifu\\[PIFU]DZ_02.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战",
                "战斗贼",
                "恶魔猎手"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+5" })
                }
            },
            equipEffects = {
                {
                    description = "英勇打击和连击的伤害提高2%",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.triggerSkill == hslk.n2i("连击") or evtData.triggerSkill == hslk.n2i("英勇打击") then
                            evtData.damage = evtData.damage * 1.02
                        end
                    end
                }
            }
        },
        {
            name = "兔兔",
            art = "pifu\\tutu.blp",
            cdKey = "SCPFTUTU",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "pifu\\[PIFU]ZS_02.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "惩戒骑",
                "武器战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ pojia = "+3" })
                }
            }
        },
        {
            name = "森精灵",
            art = "pifu\\senjingling.blp",
            cdKey = "SCPFSENJL",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\[PIFU]Y3.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "射击猎"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ attack_speed = "+3" })
                }
            }
        },
        {
            name = "叶月",
            art = "pifu\\FS03.blp",
            cdKey = "SCPFYEYUE",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "pifu\\[PIFU]FS_03.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ fa_zengshang = "+1" })
                }
            },
            whiteList = { "毁灭利刃" }
        },
        {
            name = "法师之杖",
            art = "wuqihuanhua\\FSWQ.blp",
            cdKey = "SCPFWQFSZZ",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "wuqihuanhua\\[PIFU]FS_03_weapon.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            }
        },
        {
            name = "灵魂湮灭（主手）",
            art = "wuqihuanhua\\DZWQ.blp",
            cdKey = "SCPFWQLHYM",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "wuqihuanhua\\[PIFU]DZ_03_weapon.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "战斗贼",
                "恶魔猎手",
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+5" })
                }
            }
        },
        {
            name = "灵魂湮灭（副手）",
            art = "wuqihuanhua\\DZWQ.blp",
            cdKey = "SCPFWQLHYM",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "wuqihuanhua\\[PIFU]DZ_03_weapon.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.FUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "战斗贼",
                "恶魔猎手",
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+5" })
                }
            }
        },
        {
            name = "天使之弓",
            art = "wuqihuanhua\\LRWQ.blp",
            cdKey = "SCPFWQTSZG",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "wuqihuanhua\\[PIFU]LR_03_weapon.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "射击猎"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            }
        },
        {
            name = "光能巨剑（主手）",
            art = "wuqihuanhua\\ZSWQ.blp",
            cdKey = "SCPFWQGNJJ",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "wuqihuanhua\\[PIFU]ZS_03_weapon.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "惩戒骑",
                "武器战",
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+5" })
                }
            }
        },
        {
            name = "光能巨剑（副手）",
            art = "wuqihuanhua\\ZSWQ.blp",
            cdKey = "SCPFWQGNJJ",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "wuqihuanhua\\[PIFU]ZS_03_weapon.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.FUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+5" })
                }
            }
        },
        {
            name = "奈奈",
            art = "pifu\\DZ03.blp",
            cdKey = "SCPFNAINAI",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "pifu\\[PIFU]DZ_03.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战",
                "战斗贼",
                "恶魔猎手"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "暴怒和破击的伤害提高2%",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.triggerSkill == hslk.n2i("暴怒") or evtData.triggerSkill == hslk.n2i("破击") then
                            evtData.damage = evtData.damage * 1.02
                        end
                    end
                }
            }
        },
        {
            name = "樱井",
            art = "pifu\\ZS03.blp",
            cdKey = "SCPFYINGJI",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "pifu\\[PIFU]ZS_03.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "惩戒骑",
                "武器战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_zengshang = "+1" })
                }
            }
        },
        {
            name = "麻衣",
            art = "pifu\\LR03.blp",
            cdKey = "SCPFMAYI",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "pifu\\[PIFU]LR_03.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "射击猎"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ master = "+5" })
                }
            }
        },
        {
            name = "噬魂扇",
            art = "wuqihuanhua\\shihunshan.blp",
            cdKey = "SCPFSHS",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "wuqihuanhua\\[PIFU]FS_04_weapon.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            }
        },
        {
            name = "恶魔之牙（主手）",
            art = "wuqihuanhua\\emozhiya.blp",
            cdKey = "SCPFEMZY",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "wuqihuanhua\\[PIFU]DZ_04_weapon.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "战斗贼",
                "恶魔猎手",
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+5" })
                }
            }
        },
        {
            name = "恶魔之牙（副手）",
            art = "wuqihuanhua\\emozhiya.blp",
            cdKey = "SCPFEMZY",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "wuqihuanhua\\[PIFU]DZ_04_weapon.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.FUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "战斗贼",
                "恶魔猎手",
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+5" })
                }
            }
        },
        {
            name = "泉美的战弓",
            art = "wuqihuanhua\\quanmeidezhangong.blp",
            cdKey = "SCPFQMDZG",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "wuqihuanhua\\[PIFU]LR_04_weapon.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "射击猎"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            }
        },
        {
            name = "无名妖刀（主手）",
            art = "wuqihuanhua\\wumingyaodao.blp",
            cdKey = "SCPFWMYD",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "wuqihuanhua\\[PIFU]ZS_04_weapon.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "惩戒骑",
                "武器战",
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+5" })
                }
            }
        },
        {
            name = "无名妖刀（副手）",
            art = "wuqihuanhua\\wumingyaodao.blp",
            cdKey = "SCPFWMYD",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "wuqihuanhua\\[PIFU]ZS_04_weapon.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.FUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+5" })
                }
            }
        },
        {
            name = "魔女伊织",
            art = "pifu\\monvyizhi.blp",
            cdKey = "SCPFMNYZ",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "pifu\\[PIFU]FS_04.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ fa_zengshang = "+1" })
                }
            }
        },
        {
            name = "恶魔加纳",
            art = "pifu\\emojiana.blp",
            cdKey = "SCPFEMJN",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "pifu\\[PIFU]DZ_04.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战",
                "战斗贼",
                "恶魔猎手"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_zengshang = "+1" })
                }
            }
        },
        {
            name = "射手泉美",
            art = "pifu\\sheshouquanmei.blp",
            cdKey = "SCPFSSQM",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "pifu\\[PIFU]LR_04.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "射击猎"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_chuan = "+1", fa_chuan = "+1" })
                }
            }
        },
        {
            name = "魔力结界",
            art = "wuqihuanhua\\molijiejie.blp",
            cdKey = "SCGHMLJJ",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "wuqihuanhua\\AZ_origin_Rune520_pink_small[close].mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.GUANGHUAN,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                },
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ mana_back = "+0.1" })
                }
            }
        },
        {
            name = "炎魔的宝珠",
            art = "ReplaceableTextures\\shangcheng\\炎魔之角.blp",
            cdKey = "SCTKYMZJ",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "shangcheng\\yanmobaozhu.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.TOUKUI,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            }
        },
        {
            name = "圣灵御剑火",
            art = "ReplaceableTextures\\shangcheng\\圣灵御剑火.blp",
            cdKey = "SCGHSJYJH",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "shangcheng\\AZ_G007.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.GUANGHUAN,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            }
        },
        {
            name = "先知之眼",
            art = "ReplaceableTextures\\shangcheng\\先知之眼.blp",
            cdKey = "SCGHSZZY",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "shangcheng\\crows.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.GUANGHUAN,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            }
        },
        {
            name = "风火山林",
            art = "ReplaceableTextures\\shangcheng\\风火山林.blp",
            cdKey = "SCGHFHSL",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "shangcheng\\fenghuoshanlin.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.CHIBANG,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            }
        },
        {
            name = "辉光宝珠",
            art = "ReplaceableTextures\\shangcheng\\辉光宝珠.blp",
            cdKey = "SCGHHGBZ",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "shangcheng\\[SSR]_04.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.CHIBANG,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            }
        },
        {
            name = "神龙之威",
            art = "ReplaceableTextures\\BTNinv_pandarenserpentgodmount_gold.blp",
            cdKey = "SCGHSZZY",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "shangcheng\\longhuanraoAZ.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            position = HUANHUA_POSITION.GUANGHUAN,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "至日流光之刃（主手）",
            art = "ReplaceableTextures\\inv_sword_2h_nazmirraid_d_01.BLP",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "wuqihuanhua\\Voror,GleamingBladeoftheStalwart.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "惩戒骑",
                "武器战",
                "狂暴战"
            },
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "至日流光之刃（副手）",
            art = "ReplaceableTextures\\inv_sword_2h_nazmirraid_d_01.BLP",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "wuqihuanhua\\Voror,GleamingBladeoftheStalwart.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "狂暴战"
            },
            position = HUANHUA_POSITION.FUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "金色流光（主手）",
            art = "ReplaceableTextures\\BTNinv_sword_1h_broker2boss_d_01_yellow.blp",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "wuqihuanhua\\jelly-sword.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "狂暴战",
                "战斗贼",
                "恶魔猎手"
            },
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "金色流光（副手）",
            art = "ReplaceableTextures\\BTNinv_sword_1h_broker2boss_d_01_yellow.blp",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "wuqihuanhua\\jelly-sword.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "狂暴战",
                "战斗贼",
                "恶魔猎手"
            },
            position = HUANHUA_POSITION.FUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "灵魂之羽",
            art = "ReplaceableTextures\\BTN_Zb_028.blp",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "war3mapImported\\weapon_Bow17.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "射击猎"
            },
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "湮灭之杖",
            art = "ReplaceableTextures\\BTNinv_stave_2h_firelandsraid_d_03_stage2.blp",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "wuqihuanhua\\stave_2h_firelandsraid_d_03.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "永恒之光",
            art = "ReplaceableTextures\\BTNyonghengzhiguang.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHENHUA,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "war3mapImported\\[Equip]Wing02.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            position = HUANHUA_POSITION.CHIBANG,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "龙爪巨斧（主手）",
            art = "ReplaceableTextures\\zhuangbei\\INV_Axe_76.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "war3mapImported\\Weapon_Axe_010.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "惩戒骑",
                "武器战",
                "狂暴战"
            },
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "龙爪巨斧（副手）",
            art = "ReplaceableTextures\\zhuangbei\\INV_Axe_76.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "war3mapImported\\Weapon_Axe_010.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "狂暴战"
            },
            position = HUANHUA_POSITION.FUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "阿而坎迪·兄弟会之剑（主手）",
            art = "ReplaceableTextures\\zhuangbei\\INV_Sword_50.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "war3mapImported\\weapon_ssj_024.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "惩戒骑",
                "武器战",
                "狂暴战"
            },
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "阿而坎迪·兄弟会之剑（副手）",
            art = "ReplaceableTextures\\zhuangbei\\INV_Sword_50.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "war3mapImported\\weapon_ssj_024.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "狂暴战"
            },
            position = HUANHUA_POSITION.FUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "鲜红之剑（主手）",
            art = "ReplaceableTextures\\zhuangbei\\INV_Sword_53.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "war3mapImported\\weapon_DSJ_08.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "狂暴战",
                "战斗贼",
                "恶魔猎手"
            },
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "鲜红之剑（副手）",
            art = "ReplaceableTextures\\zhuangbei\\INV_Sword_53.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "war3mapImported\\weapon_DSJ_08.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "狂暴战",
                "战斗贼",
                "恶魔猎手"
            },
            position = HUANHUA_POSITION.FUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "混乱之刃（主手）",
            art = "ReplaceableTextures\\zhuangbei\\INV_Axe_12.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "war3mapImported\\Weapon_DSF_03.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "狂暴战",
                "战斗贼",
                "恶魔猎手"
            },
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "混乱之刃（副手）",
            art = "ReplaceableTextures\\zhuangbei\\INV_Axe_12.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "war3mapImported\\Weapon_DSF_03.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "狂暴战",
                "战斗贼",
                "恶魔猎手"
            },
            position = HUANHUA_POSITION.FUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "血红之弓",
            art = "ReplaceableTextures\\zhuangbei\\INV_Weapon_Bow_28.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "war3mapImported\\Weapon_Bow05.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "射击猎"
            },
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "上古守护者的长弓",
            art = "ReplaceableTextures\\zhuangbei\\INV_Weapon_Bow_01.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "war3mapImported\\weapon_Bow07.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "射击猎"
            },
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "灵魂燃烧之杖",
            art = "ReplaceableTextures\\zhuangbei\\INV_Staff_2H_PandariaTradeskill_C_05.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "war3mapImported\\Weapon_FZ06.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "地狱烈焰法杖",
            art = "ReplaceableTextures\\zhuangbei\\inv_staff_06.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "war3mapImported\\Weapon_FZ10.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "小香风",
            art = "pifu\\xiaoxiangfeng.blp",
            cdKey = "SCPFXXF",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\[pifu]F3.MDX",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ fa_zengshang = "+1" })
                }
            }
        },
        {
            name = "小恶魔提里昂",
            art = "pifu\\xiaoemo.blp",
            cdKey = "SCPFXEM",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\10.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战",
                "战斗贼",
                "恶魔猎手"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_zengshang = "+1" })
                }
            }
        },
        {
            name = "杀手莱叶",
            art = "pifu\\shashoucaiye.blp",
            cdKey = "SCPFSSCY",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\DZ4.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战",
                "战斗贼",
                "恶魔猎手"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_zengshang = "+1" })
                }
            }
        },
        {
            name = "薪炎律者",
            art = "pifu\\xinyanlvzhe.blp",
            cdKey = "SCPFXYLZ",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\[pifu]JS4.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "惩戒骑",
                "武器战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_zengshang = "+1" })
                }
            }
        },
        {
            name = "修罗骑士",
            art = "pifu\\xiuluoqishi.blp",
            cdKey = "SCPFXLQS",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\[pifu]JS1.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "惩戒骑",
                "武器战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_zengshang = "+1" })
                }
            }
        },
        {
            name = "嗜血剑魂",
            art = "pifu\\shixuejianhun.blp",
            cdKey = "SCPFSXJH",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\[pifu]J4.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "惩戒骑",
                "武器战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_zengshang = "+1" })
                }
            }
        },
        {
            name = "闪夜少女",
            art = "pifu\\shanyeshaonv.blp",
            cdKey = "SCPFSYSN",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\[PIFU]Y5.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.JUESE,
            isActive = false,
            isEquip = false,
            classes = {
                "射击猎"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            },
            equipEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_chuan = "+1", fa_chuan = "+1" })
                }
            }
        },
        {
            name = "十河的巨剑（主手）",
            art = "wuqihuanhua\\shihedejujian.blp",
            cdKey = "SCPFSHDJJ",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "wuqihuanhua\\[PIFU]ZS_04_weapon2.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "惩戒骑",
                "武器战",
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+5" })
                }
            }
        },
        {
            name = "十河的巨剑（副手）",
            art = "wuqihuanhua\\shihedejujian.blp",
            cdKey = "SCPFSHDJJ",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "wuqihuanhua\\[PIFU]ZS_04_weapon2.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.FUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+5" })
                }
            }
        },
        {
            name = "狂野之弓",
            art = "wuqihuanhua\\狂野之弓.blp",
            cdKey = "SCPFKYZG",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\weapon_Bow12.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "射击猎"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+30", zhushuxing_baifenbi = "+1" })
                }
            }
        },
        {
            name = "虚空之斧（主手）",
            art = "wuqihuanhua\\虚空之斧.blp",
            cdKey = "SCPFXKZF",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\Weapon_Axe_015_2.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "战斗贼",
                "恶魔猎手",
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+30", wu_zengshang = "+1" })
                }
            }
        },
        {
            name = "虚空之斧（副手）",
            art = "wuqihuanhua\\虚空之斧.blp",
            cdKey = "SCPFXKZF",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\Weapon_Axe_015_2.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.FUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "战斗贼",
                "恶魔猎手",
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            }
        },
        {
            name = "魔能巨斧（主手）",
            art = "wuqihuanhua\\魔能巨斧.blp",
            cdKey = "SCPFMNJF",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\Weapon_Axe_016.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "惩戒骑",
                "武器战",
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+30", wu_bao = "+1" })
                }
            }
        },
        {
            name = "魔能巨斧（副手）",
            art = "wuqihuanhua\\魔能巨斧.blp",
            cdKey = "SCPFMNJF",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\Weapon_Axe_016.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.FUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            }
        },
        {
            name = "黑暗魔能之杖",
            art = "wuqihuanhua\\黑暗魔能之杖.blp",
            cdKey = "SCPFHAMNZZ",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\Weapon_FZ17.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+30", fa_zengshang = "+1" })
                }
            }
        },
        {
            name = "秘法师之杖",
            art = "wuqihuanhua\\秘法师之杖.blp",
            cdKey = "SCPFMFSZZ",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\Weapon_FZ21.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "火法",
                "痛苦术",
                "毁灭术",
                "星辰法师"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+30", fa_bao = "+1" })
                }
            }
        },
        {
            name = "雷霆巨剑（主手）",
            art = "wuqihuanhua\\雷霆巨剑.blp",
            cdKey = "SCPFLTJJ",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\weapon_JuJian06.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.ZHUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "惩戒骑",
                "武器战",
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+30", wu_chuan = "+1", fa_chuan = "+1" })
                }
            }
        },
        {
            name = "雷霆巨剑（副手）",
            art = "wuqihuanhua\\雷霆巨剑.blp",
            cdKey = "SCPFLTJJ",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "war3mapImported\\weapon_JuJian06.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.FUSHOU,
            isActive = false,
            isEquip = false,
            classes = {
                "狂暴战"
            },
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            }
        },
        {
            name = "炽炎之翼",
            art = "ReplaceableTextures\\shangcheng\\炽炎之翼.blp",
            cdKey = "SCCBCYZY",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            file = "shangcheng\\CB_01_az.mdx",
            description = "可以改变角色的外观，可以通过抽奖获得。",
            position = HUANHUA_POSITION.CHIBANG,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+30", master = "+10", jianshang = "+1" })
                }
            }
        },
    }

    local tmp = {
        {
            name = "轮回",
            art = "ReplaceableTextures\\lunhui.blp",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            file = "war3mapImported\\chest_magec_gh_orange.mdx",
            description = "可以改变角色的外观，热心玩家奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            position = HUANHUA_POSITION.CHIBANG,
            isActive = false,
            isEquip = false,
            activateEffects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        }
    }

    hhuanhua.initFromConfig(config)
end
