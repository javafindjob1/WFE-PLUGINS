initZuoqi = function()
    local config = {
        {
            name = "骑乘用马",
            art = "ReplaceableTextures\\zuoqi\\Ability_Mount_RidingHorse.blp",
            key = "zuoqi",
            cdIndex = 1,
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            file = "war3mapImported\\[Horse]026.mdx",
            description = "最常用的马儿。",
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            purchaseConfig = {
                purchaseNPC = "新手村村长",
                cost = { { type = HSHOP_COST_TYPE.gold, value = 10000 } },
                requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 2, shengwangname = "新手村" } }
            },
            --guaiwujisha = {
            --guaiwuName = "新手村村长",
            --rate = 1 -- 1 in 10000
            --},
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1", zhushuxing = "+3" })
                }
            }
        },
        {
            name = "精良骑乘用马",
            art = "ReplaceableTextures\\zuoqi\\Ability_Mount_RidingHorse.blp",
            key = "zuoqi",
            cdIndex = 2,
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            file = "war3mapImported\\[Horse]026.mdx",
            description = "最常用的马儿，可以在新手村村长处购买",
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            purchaseConfig = {
                purchaseNPC = "新手村村长",
                cost = { { type = HSHOP_COST_TYPE.gold, value = 30000 } },
                requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 4, shengwangname = "新手村" } }
            },
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1", zhushuxing = "+5" })
                }
            }
        },
        {
            name = "荣誉军马",
            art = "ReplaceableTextures\\zuoqi\\Ability_Mount_RidingHorse.blp",
            key = "zuoqi",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            cdIndex = 3,
            file = "war3mapImported\\[Horse]001.mdx",
            description = "王城近卫军的坐骑，荣誉的代表，高级将领专用。",
            purchaseConfig = {
                purchaseNPC = "军需处长谭恩",
                cost = { { type = HSHOP_COST_TYPE.gold, value = 30000 } },
                requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 2, shengwangname = "王城" } }
            },
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1", master = "+5" })
                }
            }
        },
        {
            name = "蓝色虫族作战坦克",
            art = "ReplaceableTextures\\zuoqi\\Ability_Mount_OnyxPanther_Blue.blp",
            key = "zuoqi",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cdIndex = 4,
            file = "war3mapImported\\[Horse]017.mdx",
            description = "奖励那些热爱冒险者的玩家们。",
            purchaseConfig = {
                purchaseNPC = "新手村村长",
                cost = { { type = HSHOP_COST_TYPE.gold, value = 1 } },
                requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 0, shengwangname = "新手村" } }
            },
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_bao = "+1", fa_bao = "+1" })
                }
            }
        },
        {
            name = "大海龟",
            art = "ReplaceableTextures\\CommandButtons\\BTNSeaTurtleGreen.blp",
            key = "zuoqi",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            cdIndex = 5,
            file = "zuoqi\\SeaTurtle.mdx",
            description = "一只大海龟，竟然可以骑乘。",
            customConfig = {
                triggerEvent = CONST_EVENT.diaoyu,
                triggerAction = function(evtData)
                    if math.random(1, 20000) <= 1 then
                        hzuoqi.jihuozuoqi("大海龟", hunit.getOwner(evtData.triggerUnit), true)
                    end
                end
            },
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            huoqufangshi = "任意钓鱼点钓鱼有小概率获得",
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ defend_white = "+3", exp_ratio = "+1" })
                }
            }
        },
        {
            name = "龙龟",
            art = "ReplaceableTextures\\CommandButtons\\BTNSeaTurtleRed.blp",
            key = "zuoqi",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cdIndex = 6,
            file = "zuoqi\\DragonTurtleepic.mdx",
            description = "非常稀有的龙龟，不仅速度快而且还能加精通，缺点是比较难钓。",
            customConfig = {
                triggerEvent = CONST_EVENT.diaoyu,
                triggerAction = function(evtData)
                    if math.random(1, 200000) <= 1 then
                        hzuoqi.jihuozuoqi("龙龟", hunit.getOwner(evtData.triggerUnit), true)
                    end
                end
            },
            huoqufangshi = "任意钓鱼点钓鱼有极小概率获得",
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ master = "+5", exp_ratio = "+1" })
                }
            }
        },
        {
            name = "蜜蜂",
            art = "ReplaceableTextures\\BTN_ZQ_00000006.blp",
            key = "zuoqi",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cdIndex = 7,
            file = "war3mapImported\\beemount.mdx",
            description = "一只体型硕大的蜜蜂。",
            customConfig = {
                triggerEvent = CONST_EVENT.caiyao,
                triggerAction = function(evtData)
                    if math.random(1, 20000) <= 1 then
                        hzuoqi.jihuozuoqi("蜜蜂", hunit.getOwner(evtData.triggerUnit), true)
                    end
                end
            },
            huoqufangshi = "采集任意草药有极小概率获得",
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ fa_bao = "+0.2", exp_ratio = "+1" })
                }
            }
        },
        {
            name = "化石迅猛龙",
            art = "ReplaceableTextures\\BTN_ZQ_00000002.blp",
            key = "zuoqi",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cdIndex = 8,
            file = "war3mapImported\\[Horse]002.mdx",
            description = "挖矿挖出来的骨头堆，竟然还能骑。",
            customConfig = {
                triggerEvent = CONST_EVENT.caikuang,
                triggerAction = function(evtData)
                    if math.random(1, 20000) <= 1 then
                        hzuoqi.jihuozuoqi("化石迅猛龙", hunit.getOwner(evtData.triggerUnit), true)
                    end
                end
            },
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            huoqufangshi = "对任意矿石挖矿有极小概率获得。",
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_bao = "+0.2", exp_ratio = "+1" })
                }
            }
        },
        {
            name = "座狼",
            art = hslk.n2v("铁狼", "slk", "Art"),
            key = "zuoqi",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cdIndex = 9,
            file = "war3mapImported\\[Horse]009.mdx",
            description = "一只可以骑乘的狼。",
            customConfig = {
                triggerEvent = CONST_EVENT.baopi,
                triggerAction = function(evtData)
                    if math.random(1, 50000) <= 1 then
                        hzuoqi.jihuozuoqi("座狼", hunit.getOwner(evtData.triggerUnit), true)
                    end
                end
            },
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            huoqufangshi = "剥皮有极小概率获得。",
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_baoshang = "+3", exp_ratio = "+1" })
                }
            }
        },
        {
            name = "月兔",
            art = "ReplaceableTextures\\CommandButtons\\BTNCritterRabbit.blp",
            key = "zuoqi",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cdIndex = 10,
            file = "war3mapImported\\[horse]yuetu.mdx",
            description = "一只巨大的兔子，出没于中秋节附近，但是也可以通过制布获得。",
            customConfig = {
                triggerEvent = CONST_EVENT.zhibu,
                triggerAction = function(evtData)
                    if math.random(1, 50000) <= 1 then
                        hzuoqi.jihuozuoqi("月兔", hunit.getOwner(evtData.triggerUnit), true)
                    end
                end
            },
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            huoqufangshi = "制布有极小概率获得。",
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ fa_baoshang = "+3", exp_ratio = "+1" })
                }
            }
        },
        {
            name = "狮鹫",
            art = "ReplaceableTextures\\CommandButtons\\BTNGryphonRider.blp",
            key = "zuoqi",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cdIndex = 11,
            file = "war3mapImported\\[Horse]012_GW.mdx",
            description = "王城近卫军高级将领的坐骑，荣誉的代表。",
            purchaseConfig = {
                purchaseNPC = "军需处长谭恩",
                cost = { { type = HSHOP_COST_TYPE.gold, value = 100000 } },
                requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 4, shengwangname = "王城" } }
            },
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing_baifenbi = "+0.2", exp_ratio = "+1" })
                }
            }
        },
        {
            name = "疾行蝎",
            art = "ReplaceableTextures\\BTN_ZQ_00000007.blp",
            key = "zuoqi",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cdIndex = 12,
            file = "war3mapImported\\[Horse]014.mdx",
            description = "沙漠中常用的坐骑，价格不菲。",
            purchaseConfig = {
                purchaseNPC = "守备官斯通哈特",
                cost = { { type = HSHOP_COST_TYPE.gold, value = 100000 } },
                requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 4, shengwangname = "峡谷前哨站" } }
            },
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ gongji_baifenbi = "+0.2", exp_ratio = "+1" })
                }
            }
        },
        {
            name = "皇家战马",
            art = "ReplaceableTextures\\zuoqi\\BTNinv_horsekultiran.blp",
            key = "SCZQHJZM",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            file = "zuoqi\\anduinhorse.mdx",
            description = "豪华的战马",
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10", quanju_zengshang = "+0.2" })
                }
            }
        },
        {
            name = "狐狸",
            art = "ReplaceableTextures\\zuoqi\\foxmounticon.blp",
            key = "SCZQHULI",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            file = "zuoqi\\foxmount.mdx",
            description = "一只可以骑乘的狐狸",
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10", quanju_zengshang = "+0.2" })
                }
            }
        },
        {
            name = "九头蛇",
            art = hslk.n2v("银鳞", "slk", "Art"),
            key = "SCZQJTS",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            file = "war3mapImported\\[Horse]003.mdx",
            description = "深海中的魔物，驯化难度极高。",
            cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10", quanju_zengshang = "+0.2" })
                }
            }
        },
        {
            name = "恐惧战马",
            art = "ReplaceableTextures\\zuoqi\\Ability_Mount_RidingHorse.blp",
            key = "zuoqi",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            cdIndex = 13,
            file = "war3mapImported\\Nightmare.mdx",
            description = "一匹黑色的战马，脚踏烈焰，拉风无比。击杀黑铁矮人索瑞森大帝有概率获得。",
            customConfig = {
                triggerEvent = CONST_EVENT.kill,
                triggerAction = function(evtData)
                    if hunit.getName(evtData.targetUnit) ~= "黑铁矮人索瑞森大帝" then
                        return
                    end
                    local fubennandu = hunit.getNandu(evtData.targetUnit) or FUBEN_NANDU.PUTONG
                    local group =
                        hgroup.createPlayerGroupByXY(hunit.x(evtData.targetUnit), hunit.y(evtData.targetUnit), 1000)
                    local rate = 10
                    if fubennandu == FUBEN_NANDU.YINGXIONG then
                        rate = 20
                    elseif fubennandu == FUBEN_NANDU.SHISHI then
                        rate = 50
                    elseif fubennandu == FUBEN_NANDU.CHUANQI then
                        rate = 100
                    end
                    if math.random(1, 10000) <= rate then
                        for _, player in ipairs(group) do
                            hzuoqi.jihuozuoqi("恐惧战马", player, true)
                        end
                    end
                end
            },
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            isActive = false,
            huoqufangshi = "黑铁矮人索瑞森大帝被击杀时候周围1000范围内单位有0.1%/0.2%/0.5%/1%（普通/英雄/史诗/传奇）的概率获得。",
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ move = "+1", exp_ratio = "+1" })
                }
            }
        },
        {
            name = "重装战马",
            art = "ReplaceableTextures\\zuoqi\\Ability_Mount_RidingHorse.blp",
            key = "zuoqi",
            cdIndex = 14,
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            file = "war3mapImported\\[Horse]006.mdx",
            description = "稀有的坐骑，可以用正义徽章在军需处长谭恩处购买",
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            purchaseConfig = {
                purchaseNPC = "军需处长谭恩",
                cost = { { type = HSHOP_COST_TYPE.gongzhenghuizhang, value = 600 } },
                requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 4, shengwangname = "王城" } }
            },
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1", zhushuxing = "+5" })
                }
            }
        },
        {
            name = "烈焰座狼",
            art = "zuoqi\\lieyanzuolang.blp",
            key = "zuoqi",
            cdIndex = 15,
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            file = "war3mapImported\\[Horse]029.mdx",
            description = "稀有的坐骑，可以用勇气徽章在守备官斯通哈特处购买",
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            purchaseConfig = {
                purchaseNPC = "守备官斯通哈特",
                cost = { { type = HSHOP_COST_TYPE.yongqihuizhang, value = 600 } },
                requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 4, shengwangname = "峡谷前哨站" } }
            },
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1", zhushuxing = "+5" })
                }
            }
        },
        {
            name = "作战科多兽",
            art = "zuoqi\\Ability_Mount_Kodo_03.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            file = "war3mapImported\\[Horse]004.mdx",
            description = "可以骑乘的科多兽。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            huoqufangshi = "热心玩家的奖励。",
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "魔力扫帚",
            art = "zuoqi\\saozhou.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            file = "war3mapImported\\[horse]BroomMount.mdx",
            description = "来自魔法世界的扫帚。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            huoqufangshi = "热心玩家的奖励。",
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "夜刃豹",
            art = "zuoqi\\Ability_Mount_BlackPanther.blp",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            file = "war3mapImported\\[Horse]Saber2Mount.mdx",
            description = "迅捷的夜刃豹。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            huoqufangshi = "热心玩家的奖励。",
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "战争三角龙",
            art = "zuoqi\\sanjiaolongred.blp",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            file = "war3mapImported\\[Horse]027.mdx",
            description = "远古的战争三角龙。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            huoqufangshi = "热心玩家的奖励。",
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "踏星",
            art = "zuoqi\\xingya.blp",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            file = "war3mapImported\\[Horse]030.mdx",
            description = "星空生物，华丽而优雅。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            huoqufangshi = "热心玩家的奖励。",
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "黄金巨龙",
            art = "zuoqi\\jinsejulong.blp",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            file = "war3mapImported\\[Horse]008.mdx",
            description = "神秘巨龙，通体金黄。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            huoqufangshi = "热心玩家的奖励。",
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "幽灵虎",
            art = "zuoqi\\Ability_Mount_SpectralTiger.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHENHUA,
            file = "war3mapImported\\[horse]SpectralTigerEpic.mdx",
            description = "传说中的生物，可遇而不可求。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            huoqufangshi = "热心玩家的奖励。",
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "灰烬之龙",
            art = "ReplaceableTextures\\BTN_ZQ_00000007.blp",
            key = "zuoqi",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cdIndex = 16,
            file = "war3mapImported\\[Horse]005.mdx",
            description = "强大的骨龙。",
            customConfig = {
                triggerEvent = CONST_EVENT.kill,
                triggerAction = function(evtData)
                    if hunit.getName(evtData.targetUnit) ~= "夜之魇" then
                        return
                    end
                    local fubennandu = hunit.getNandu(evtData.targetUnit) or FUBEN_NANDU.PUTONG
                    local group =
                        hgroup.createPlayerGroupByXY(hunit.x(evtData.targetUnit), hunit.y(evtData.targetUnit), 1000)
                    local rate = 2
                    if fubennandu == FUBEN_NANDU.YINGXIONG then
                        rate = 4
                    elseif fubennandu == FUBEN_NANDU.SHISHI then
                        rate = 8
                    elseif fubennandu == FUBEN_NANDU.CHUANQI then
                        rate = 16
                    end
                    if math.random(1, 10000) <= rate then
                        for _, player in ipairs(group) do
                            hzuoqi.jihuozuoqi("夜之魇", player, true)
                        end
                    end
                end
            },
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            isActive = false,
            huoqufangshi = "夜之魇被击杀时候周围1000范围内单位有较小的概率获得，难度越高概率越高。",
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ move = "+1", exp_ratio = "+1" })
                }
            },
            whiteList = { "覆盖江#4191" }
        },
        {
            name = "迅捷猎豹",
            art = "ReplaceableTextures\\zuoqi\\Ability_Mount_WhiteTiger.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            file = "war3mapImported\\[Horse]010.mdx",
            description = "可骑乘的猎豹",
            shouldActivate = function(whichPlayer)
                return false
            end,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            huoqufangshi = "奖励那些帮助新冒险者的玩家。",
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "星光麋鹿",
            art = "ReplaceableTextures\\zuoqi\\xingguangmilu.blp",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            file = "war3mapImported\\[Horse]016.mdx",
            description = "星光环绕的麋鹿。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            huoqufangshi = "奖励那些帮助新冒险者的玩家。",
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1", caiji_speed = "+20" })
                }
            }
        },
        {
            name = "凿孔蟹",
            art = "zuoqi\\BTNinv_crabmount.BLP",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            file = "zuoqi\\crabmount.mdx",
            description = "横着走的也能骑？",
            huoqufangshi = "带新奖励",
            shouldActivate = function(whichPlayer)
                return false
            end,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            }
        },
        {
            name = "小戈隆",
            art = "zuoqi\\BTNinv_lessergronnmount_red.BLP",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            file = "zuoqi\\fellessergronnmount.mdx",
            description = "戈隆的后代。",
            huoqufangshi = "宠物探险奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+10" })
                }
            }
        },
        {
            name = "恶魔猎犬",
            art = "zuoqi\\inv_felstalker_pet.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            file = "zuoqi\\FelStalkerMountred.mdx",
            description = "邪恶的猎犬。",
            huoqufangshi = "宠物探险奖励。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+5" })
                }
            }
        },
        {
            name = "奥",
            art = "zuoqi\\Inv_Misc_SummerFest_BrazierOrange.blp",
            key = "zuoqi",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            cdIndex = 17,
            file = "war3mapImported\\[Horse]033.mdx",
            description = "奥的灰烬，涅槃重生。",
            customConfig = {
                triggerEvent = CONST_EVENT.kill,
                triggerAction = function(evtData)
                    if hunit.getName(evtData.targetUnit) ~= "凯尔萨斯·逐日者" then
                        return
                    end
                    local fubennandu = hunit.getNandu(evtData.targetUnit) or FUBEN_NANDU.PUTONG
                    local group =
                        hgroup.createPlayerGroupByXY(hunit.x(evtData.targetUnit), hunit.y(evtData.targetUnit), 1000)
                    local rate = 1
                    if fubennandu == FUBEN_NANDU.YINGXIONG then
                        rate = 2
                    elseif fubennandu == FUBEN_NANDU.SHISHI then
                        rate = 3
                    elseif fubennandu == FUBEN_NANDU.CHUANQI then
                        rate = 4
                    end
                    if math.random(1, 10000) <= rate then
                        for _, player in ipairs(group) do
                            hzuoqi.jihuozuoqi("奥", player, true)
                        end
                    end
                end
            },
            cundangType = ZUOQI_CUNDANG_TYPE.CUNDANG,
            isActive = false,
            huoqufangshi = "凯尔萨斯·逐日者被击杀时候周围1000范围内单位有较小的概率获得，难度越高概率越高。",
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ move = "+1", exp_ratio = "+1" })
                }
            }
        },
        {
            name = "光铸机甲",
            art = "zuoqi\\guangzhujijia.blp",
            pinzhi = ZHUANGBEI_PINZHI.SHENHUA,
            file = "war3mapImported\\horse-1.mdx",
            description = "神圣之力覆盖的机甲，华丽无比。",
            shouldActivate = function(whichPlayer)
                return false
            end,
            cundangType = ZUOQI_CUNDANG_TYPE.HARD_CODE,
            huoqufangshi = "热心玩家的奖励。",
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
    }

    hzuoqi.initFromConfig(config)
end
