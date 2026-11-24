function buildYewai()
    -- 英雄选择

    local tuozhanhuixue = {
        description = "脱离战斗恢复所有生命值",
        attr_type = CONST_EVENT.quitFight,
        attr = function(evtData)
            if hunit.isDead(evtData.triggerUnit) then
                return
            end
            hunit.setCurLifePercent(evtData.triggerUnit, 100)
        end
    }
    hyewai.buildYewai(
        {
            name = "英雄选择区域",
            level = 1,
            blp = "ReplaceableTextures\\xiaoditu\\UI_map_01.blp",
            clearTimeout = 300,
            nandu = FUBEN_NANDU.PUTONG,
            rectParam = { minX = -31787, minY = -31665, maxX = -30000, maxY = -30500 }, -- 副本区域
            NPCs = {
                {
                    name = "火法",
                    x = -31488,
                    y = -30851
                },
                {
                    name = "星辰法师",
                    x = -31230,
                    y = -30851
                },
                {
                    name = "毁灭术",
                    x = -30975,
                    y = -30851
                },
                {
                    name = "痛苦术",
                    x = -30720,
                    y = -30851
                },
                {
                    name = "狂暴战",
                    x = -31488,
                    y = -31105
                },
                {
                    name = "武器战",
                    x = -31230,
                    y = -31105
                },
                {
                    name = "惩戒骑",
                    x = -30975,
                    y = -31105
                },
                {
                    name = "战斗贼",
                    x = -31488,
                    y = -31362
                },
                {
                    name = "射击猎",
                    x = -31230,
                    y = -31362
                },
                {
                    name = "恶魔猎手",
                    x = -30980,
                    y = -31362
                }
            },
            customLogic = function()
                local heroesOpenForSelection = {}
                heroesOpenForSelection["火法"] = 0
                heroesOpenForSelection["狂暴战"] = 0
                heroesOpenForSelection["武器战"] = 0
                heroesOpenForSelection["惩戒骑"] = 0
                heroesOpenForSelection["毁灭术"] = 0
                heroesOpenForSelection["战斗贼"] = 0
                heroesOpenForSelection["射击猎"] = 0
                heroesOpenForSelection["痛苦术"] = 0
                heroesOpenForSelection["星辰法师"] = 0
                heroesOpenForSelection["恶魔猎手"] = 0

                for i = 1, hplayer.qty_max, 1 do
                    hevent.onSelection(
                        hplayer.players[i],
                        2,
                        function(evtData)
                            local p = evtData.triggerPlayer
                            if hcache.get(p, "CAN_SELECT_HERO", false) ~= true then
                                return
                            end
                            local whichHero = evtData.triggerUnit
                            if hrect.isInner(hyewai["英雄选择区域"].rect, hunit.x(whichHero), hunit.y(whichHero)) == false then
                                return
                            end
                            if (hunit.getOwner(whichHero) ~= cj.Player(PLAYER_NEUTRAL_PASSIVE)) then
                                return
                            end
                            local pIndex = hplayer.index(p)
                            if (#hhero.player_heroes[pIndex] >= hhero.player_allow_qty[pIndex]) then
                                echo("|cffffff80请勿重复选择英雄|r", p)
                                return
                            end
                            if heroesOpenForSelection[hunit.getName(whichHero)] == nil then
                                echo("|cffffff80" .. hunit.getName(whichHero) .. "|r还在制作中，敬请期待", p)
                                return
                            end

                            SELECT_HERO(p, hunit.getName(whichHero))
                        end
                    )
                end
            end
        }
    )
    hyewai.buildYewai(
        {
            name = "新手村",
            level = 1,
            blp = "ReplaceableTextures\\xiaoditu\\UI_map_02.blp",
            clearTimeout = 300,
            enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_01.blp",
            nandu = FUBEN_NANDU.PUTONG,
            chuansongdian = {
                { x = -31726, y = -28666, name = "新手村内", cost = 50, face = 0 }
            },
            rectParam = { minX = -31891, minY = -29886, maxX = -29407, maxY = -27876 }, -- 副本区域
            NPCs = {
                {
                    name = "新手村村长",
                    x = -29835,
                    y = -28234,
                    face = 180
                },
                {
                    name = "铁匠哈特",
                    x = -29887,
                    y = -29210,
                    face = 180
                },
                {
                    name = "药剂学徒瑞克",
                    x = -31350,
                    y = -29321,
                    face = 45
                },
                {
                    name = "新手教官",
                    x = -31350,
                    y = -28052,
                    face = 315
                }
            },
            portal = { { x = -29437, y = -28618, destX = -28817, destY = -28414, destination = "新手村外" } }
        }
    )

    local diaoluoConfigForXSCW =
        DiaoLuoConfig( --掉落配置
            {
                {
                    list = {
                        "戒指",
                        "项链",
                        "披风",
                        "手套",
                        "衣服",
                        "头盔",
                        "鞋子",
                        "法器"
                    }, --物品名字 需要在物编定义好
                    drop_rate = {
                        --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                        10,
                        0,
                        0,
                        0
                    }
                }
            }
        )
    local diaoluoConfigForXSCWBoss = {
        list = {
            "单手剑",
            "戒指",
            "项链",
            "披风",
            "手套",
            "衣服",
            "头盔",
            "鞋子",
            "法器",
            "单手锤",
            "双手剑",
            "双手斧",
            "双手锤",
            "法杖",
            "饰品",
            "弓"
        }, --物品名字 需要在物编定义好
        drop_rate = {
            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
            200,
            0,
            0,
            0
        }
    }

    hyewai.buildYewai(
        {
            name = "新手村外",
            level = 1,
            blp = "ReplaceableTextures\\xiaoditu\\UI_map_03.blp",
            enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_02.blp",
            clearTimeout = 300,
            nandu = FUBEN_NANDU.PUTONG,
            rectParam = { minX = -29227, minY = -31850, maxX = -25200, maxY = -23106 }, -- 野外区域坐标
            portal = {
                { x = -28990, y = -28600, destX = -29600, destY = -28608, destination = "新手村" },
                { x = -25440, y = -23514, destX = -19442, destY = -20335, destination = "王城" }
            },
            minions = {
                {
                    name = "巨魔", -- 名字 需要在物编定义好
                    x = -28097, -- 小怪刷新x坐标
                    y = -27840, -- 小怪刷新y坐标
                    face = 180, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 1
                },
                {
                    name = "巨魔", -- 名字 需要在物编定义好
                    x = -27375, -- 小怪刷新x坐标
                    y = -27515, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 2
                },
                {
                    name = "巨魔", -- 名字 需要在物编定义好
                    x = -27727, -- 小怪刷新x坐标
                    y = -28243, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 3
                },
                {
                    name = "巨魔", -- 名字 需要在物编定义好
                    x = -27527, -- 小怪刷新x坐标
                    y = -28243, -- 小怪刷新y坐标
                    face = 180, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 3
                },
                {
                    name = "巨魔", -- 名字 需要在物编定义好
                    x = -26543, -- 小怪刷新x坐标
                    y = -27675, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 3
                },
                {
                    name = "巨魔", -- 名字 需要在物编定义好
                    x = -26543, -- 小怪刷新x坐标
                    y = -27825, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 3
                },
                {
                    name = "巨魔狂战士", -- 名字 需要在物编定义好
                    x = -26343, -- 小怪刷新x坐标
                    y = -27750, -- 小怪刷新y坐标
                    face = 180, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 4
                },
                -- 狗头人
                {
                    name = "狗头人", -- 名字 需要在物编定义好
                    x = -25761, -- 小怪刷新x坐标
                    y = -29272, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 6
                },
                {
                    name = "狗头人", -- 名字 需要在物编定义好
                    x = -25959, -- 小怪刷新x坐标
                    y = -29428, -- 小怪刷新y坐标
                    face = 180, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 6
                },
                {
                    name = "狗头人", -- 名字 需要在物编定义好
                    x = -26856, -- 小怪刷新x坐标
                    y = -29278, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 6
                },
                {
                    name = "狗头人战士", -- 名字 需要在物编定义好
                    x = -26772, -- 小怪刷新x坐标
                    y = -29396, -- 小怪刷新y坐标
                    face = 90, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 7
                },
                {
                    name = "狗头人", -- 名字 需要在物编定义好
                    x = -27714, -- 小怪刷新x坐标
                    y = -29473, -- 小怪刷新y坐标
                    face = 180, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 6
                },
                {
                    name = "狗头人", -- 名字 需要在物编定义好
                    x = -27797, -- 小怪刷新x坐标
                    y = -29641, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 6
                },
                {
                    name = "狗头人术士", -- 名字 需要在物编定义好
                    x = -27974, -- 小怪刷新x坐标
                    y = -29532, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 8
                },
                {
                    name = "熊怪", -- 名字 需要在物编定义好
                    x = -28830, -- 小怪刷新x坐标
                    y = -31049, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 8
                },
                {
                    name = "熊怪", -- 名字 需要在物编定义好
                    x = -28630, -- 小怪刷新x坐标
                    y = -31049, -- 小怪刷新y坐标
                    face = 0, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 8
                },
                {
                    name = "熊怪", -- 名字 需要在物编定义好
                    x = -28021, -- 小怪刷新x坐标
                    y = -31372, -- 小怪刷新y坐标
                    face = 0, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 9
                },
                {
                    name = "熊怪", -- 名字 需要在物编定义好
                    x = -28021, -- 小怪刷新x坐标
                    y = -31572, -- 小怪刷新y坐标
                    face = 0, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 9
                },
                {
                    name = "熊怪战士", -- 名字 需要在物编定义好
                    x = -28021, -- 小怪刷新x坐标
                    y = -31572, -- 小怪刷新y坐标
                    face = 0, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 10
                },
                {
                    name = "熊怪", -- 名字 需要在物编定义好
                    x = -26536, -- 小怪刷新x坐标
                    y = -31350, -- 小怪刷新y坐标
                    face = 0, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 10
                },
                {
                    name = "熊怪", -- 名字 需要在物编定义好
                    x = -26536, -- 小怪刷新x坐标
                    y = -31550, -- 小怪刷新y坐标
                    face = 0, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 10
                },
                {
                    name = "熊怪战士", -- 名字 需要在物编定义好
                    x = -26736, -- 小怪刷新x坐标
                    y = -31450, -- 小怪刷新y坐标
                    face = 0, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 11
                },
                {
                    name = "鱼人", -- 名字 需要在物编定义好
                    x = -27325, -- 小怪刷新x坐标
                    y = -25155, -- 小怪刷新y坐标
                    face = 0, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 15
                },
                {
                    name = "鱼人", -- 名字 需要在物编定义好
                    x = -27325, -- 小怪刷新x坐标
                    y = -25355, -- 小怪刷新y坐标
                    face = 180, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 15
                },
                {
                    name = "鱼人", -- 名字 需要在物编定义好
                    x = -28082, -- 小怪刷新x坐标
                    y = -24656, -- 小怪刷新y坐标
                    face = 180, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 15
                },
                {
                    name = "鱼人", -- 名字 需要在物编定义好
                    x = -28282, -- 小怪刷新x坐标
                    y = -24656, -- 小怪刷新y坐标
                    face = 0, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 15
                },
                {
                    name = "鱼人战士", -- 名字 需要在物编定义好
                    x = -28182, -- 小怪刷新x坐标
                    y = -24456, -- 小怪刷新y坐标
                    face = 0, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 16
                },
                {
                    name = "鱼人战士", -- 名字 需要在物编定义好
                    x = -28380, -- 小怪刷新x坐标
                    y = -25775, -- 小怪刷新y坐标
                    face = 180, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 16
                },
                {
                    name = "鱼人战士", -- 名字 需要在物编定义好
                    x = -28380, -- 小怪刷新x坐标
                    y = -25975, -- 小怪刷新y坐标
                    face = 0, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 16
                },
                {
                    name = "鱼人法师", -- 名字 需要在物编定义好
                    x = -28580, -- 小怪刷新x坐标
                    y = -25875, -- 小怪刷新y坐标
                    face = 0, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 17
                },
                {
                    name = "鱼人战士", -- 名字 需要在物编定义好
                    x = -29025, -- 小怪刷新x坐标
                    y = -24396, -- 小怪刷新y坐标
                    face = 180, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 16
                },
                {
                    name = "鱼人战士", -- 名字 需要在物编定义好
                    x = -29025, -- 小怪刷新x坐标
                    y = -24196, -- 小怪刷新y坐标
                    face = 0, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 16
                },
                {
                    name = "鱼人猎手", -- 名字 需要在物编定义好
                    x = -28925, -- 小怪刷新x坐标
                    y = -24296, -- 小怪刷新y坐标
                    face = 0, --  小怪朝向
                    reborn = 20,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 17
                }
            },
            bosses = {
                {
                    name = "巨魔领主", -- 名字 需要在物编定义好
                    x = -25748, -- 小怪刷新x坐标
                    y = -27760, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = DiaoLuoConfig(
                        {
                            diaoluoConfigForXSCWBoss,
                            {
                                list = { "饰品" }, --物品名字 需要在物编定义好
                                drop_rate = {
                                    --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                    2000,
                                    0,
                                    0,
                                    0
                                }
                            }
                        }
                    ),
                    level = 5
                },
                {
                    name = "狗头人领主", -- 名字 需要在物编定义好
                    x = -28683, -- 小怪刷新x坐标
                    y = -29983, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = DiaoLuoConfig({ diaoluoConfigForXSCWBoss }),
                    level = 9
                },
                {
                    name = "熊怪领主", -- 名字 需要在物编定义好
                    x = -26986, -- 小怪刷新x坐标
                    y = -30691, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = DiaoLuoConfig(
                        {
                            diaoluoConfigForXSCWBoss,
                            {
                                list = { "野蛮锁甲" }, --物品名字 需要在物编定义好
                                drop_rate = {
                                    --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                    5000,
                                    0,
                                    0,
                                    0
                                }
                            }
                        }
                    ),
                    level = 12
                },
                {
                    name = "鱼人领主", -- 名字 需要在物编定义好
                    x = -28701, -- 小怪刷新x坐标
                    y = -25272, -- 小怪刷新y坐标
                    face = 90, -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = DiaoLuoConfig(
                        {
                            diaoluoConfigForXSCWBoss
                        }
                    ),
                    level = 18
                }
            },
            NPCs = {
                {
                    name = "受伤的农夫",
                    x = -28606,
                    y = -28020
                },
                {
                    name = "猎人阿普",
                    x = -26111,
                    y = -30721
                },
                {
                    name = "克文",
                    x = -28041,
                    y = -24193,
                    face = 180
                }
            },
            ZIYUAN = {
                {
                    name = "铁矿",
                    x = -28822,
                    y = -31631,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.KUANGSHI
                },
                {
                    name = "铁矿",
                    x = -25809,
                    y = -25764,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.KUANGSHI
                },
                {
                    name = "铁矿",
                    x = -29001,
                    y = -26648,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.KUANGSHI
                },
                {
                    name = "基础草药",
                    x = -28262,
                    y = -27592,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.CAOYAO
                },
                {
                    name = "基础草药",
                    x = -25801,
                    y = -31596,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.CAOYAO
                },
                {
                    name = "基础草药",
                    x = -28897,
                    y = -26093,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.CAOYAO
                },
                {
                    name = "新手村钓鱼点",
                    x = -27709,
                    y = -23673,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.DIAOYUDIAN
                }
            }
        }
    )

    hyewai.buildYewai(
        {
            name = "王城",
            level = 20,
            blp = "ReplaceableTextures\\xiaoditu\\UI_map_05.blp",
            enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_03.blp",
            clearTimeout = 300,
            nandu = FUBEN_NANDU.PUTONG,
            rectParam = { minX = -32240, minY = -22116, maxX = -18906, maxY = -12248 }, -- 野外区域坐标
            chuansongdian = {
                { x = -27078, y = -18352, name = "王城主城区", cost = 50, face = 180 },
                { x = -24641, y = -15117, name = "王城郊外", cost = 200, face = 0 }
            },
            portal = {
                { x = -19091, y = -20350, destX = -25627, destY = -23800, destination = "新手村外" }
            },
            minions = {
                {
                    name = "挨打的木桩", -- 名字 需要在物编定义好
                    x = -28037, -- 小怪刷新x坐标
                    y = -17662, -- 小怪刷新y坐标
                    face = 90, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = DiaoLuoConfig( --掉落配置
                        {
                            {
                                list = { "白纸" }, --物品名字 需要在物编定义好
                                drop_rate = {
                                    --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                    10,
                                    0,
                                    0,
                                    0
                                }
                            }
                        }
                    ),
                    level = 45,
                    passiveSkill = {
                        {
                            {
                                description = "传说中的不死之身",
                                attr_type = CONST_EVENT.dying,
                                attr = function(evtData)
                                    hunit.setCurLifePercent(evtData.targetUnit, 100)
                                end
                            },
                            {
                                description = "专业木桩，拥有一百万生命值",
                                attr_type = CONST_EVENT.attr,
                                attr = _attr({ life = "=1000000", attack = "=0" })
                            }
                        },
                        {},
                        {},
                        {}
                    }
                },
                {
                    name = "豺狼人", -- 名字 需要在物编定义好
                    x = -20210, -- 小怪刷新x坐标
                    y = -18925, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 25,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 20
                },
                {
                    name = "豺狼人", -- 名字 需要在物编定义好
                    x = -19910, -- 小怪刷新x坐标
                    y = -18925, -- 小怪刷新y坐标
                    face = 180, -- 小怪朝向
                    reborn = 25,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 20
                },
                {
                    name = "豺狼人", -- 名字 需要在物编定义好
                    x = -20060, -- 小怪刷新x坐标
                    y = -19225, -- 小怪刷新y坐标
                    face = 90, -- 小怪朝向
                    reborn = 25,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 20
                },
                {
                    name = "豺狼人", -- 名字 需要在物编定义好
                    x = -19436, -- 小怪刷新x坐标
                    y = -21282, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 25,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 20
                },
                {
                    name = "豺狼人", -- 名字 需要在物编定义好
                    x = -19136, -- 小怪刷新x坐标
                    y = -21282, -- 小怪刷新y坐标
                    face = 180, -- 小怪朝向
                    reborn = 25,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 20
                },
                {
                    name = "豺狼战士", -- 名字 需要在物编定义好
                    x = -19286, -- 小怪刷新x坐标
                    y = -21582, -- 小怪刷新y坐标
                    face = 90, -- 小怪朝向
                    reborn = 25,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 22
                },
                {
                    name = "豺狼人", -- 名字 需要在物编定义好
                    x = -20793, -- 小怪刷新x坐标
                    y = -21282, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 25,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 21
                },
                {
                    name = "豺狼人", -- 名字 需要在物编定义好
                    x = -20493, -- 小怪刷新x坐标
                    y = -21282, -- 小怪刷新y坐标
                    face = 180, -- 小怪朝向
                    reborn = 25,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 21
                },
                {
                    name = "豺狼战士", -- 名字 需要在物编定义好
                    x = -20643, -- 小怪刷新x坐标
                    y = -21582, -- 小怪刷新y坐标
                    face = 90, -- 小怪朝向
                    reborn = 25,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 22
                },
                {
                    name = "豺狼战士", -- 名字 需要在物编定义好
                    x = -21757, -- 小怪刷新x坐标
                    y = -20090, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 25,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 22
                },
                {
                    name = "豺狼战士", -- 名字 需要在物编定义好
                    x = -21765, -- 小怪刷新x坐标
                    y = -20604, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 25,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 22
                },
                {
                    name = "土匪", -- 名字 需要在物编定义好
                    x = -23179, -- 小怪刷新x坐标
                    y = -21379, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 30,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 23
                },
                {
                    name = "强盗", -- 名字 需要在物编定义好
                    x = -22879, -- 小怪刷新x坐标
                    y = -21379, -- 小怪刷新y坐标
                    face = 180, -- 小怪朝向
                    reborn = 30,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 23
                },
                {
                    name = "土匪", -- 名字 需要在物编定义好
                    x = -24576, -- 小怪刷新x坐标
                    y = -21521, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 30,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 23
                },
                {
                    name = "强盗", -- 名字 需要在物编定义好
                    x = -24276, -- 小怪刷新x坐标
                    y = -21521, -- 小怪刷新y坐标
                    face = 180, -- 小怪朝向
                    reborn = 30,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 24
                },
                {
                    name = "土匪", -- 名字 需要在物编定义好
                    x = -24020, -- 小怪刷新x坐标
                    y = -19641, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 30,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 24
                },
                {
                    name = "强盗", -- 名字 需要在物编定义好
                    x = -23720, -- 小怪刷新x坐标
                    y = -19641, -- 小怪刷新y坐标
                    face = 180, -- 小怪朝向
                    reborn = 30,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 24
                },
                {
                    name = "刺客", -- 名字 需要在物编定义好
                    x = -25774, -- 小怪刷新x坐标
                    y = -19680, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 30,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 25
                },
                {
                    name = "刺客", -- 名字 需要在物编定义好
                    x = -25474, -- 小怪刷新x坐标
                    y = -19680, -- 小怪刷新y坐标
                    face = 180, -- 小怪朝向
                    reborn = 30,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 25
                },
                {
                    name = "游荡的血色军剑士", -- 名字 需要在物编定义好
                    x = -30140, -- 小怪刷新x坐标
                    y = -15428, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 26
                },
                {
                    name = "游荡的血色军卫士", -- 名字 需要在物编定义好
                    x = -31356, -- 小怪刷新x坐标
                    y = -14595, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 27
                },
                {
                    name = "游荡的血色军卫士", -- 名字 需要在物编定义好
                    x = -30508, -- 小怪刷新x坐标
                    y = -14554, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 27
                },
                {
                    name = "游荡的血色军法师", -- 名字 需要在物编定义好
                    x = -31375, -- 小怪刷新x坐标
                    y = -13405, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 28
                },
                {
                    name = "游荡的血色军法师", -- 名字 需要在物编定义好
                    x = -31075, -- 小怪刷新x坐标
                    y = -13305, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 28
                },
                {
                    name = "游荡的血色军卫士", -- 名字 需要在物编定义好
                    x = -30543, -- 小怪刷新x坐标
                    y = -12845, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 29
                },
                {
                    name = "游荡的血色军剑士", -- 名字 需要在物编定义好
                    x = -30243, -- 小怪刷新x坐标
                    y = -12945, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 29
                },
                {
                    name = "游荡的血色军卫士", -- 名字 需要在物编定义好
                    x = -26543, -- 小怪刷新x坐标
                    y = -13633, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 29
                },
                {
                    name = "游荡的血色军剑士", -- 名字 需要在物编定义好
                    x = -26243, -- 小怪刷新x坐标
                    y = -13933, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 29
                },
                {
                    name = "游荡的血色军法师", -- 名字 需要在物编定义好
                    x = -25943, -- 小怪刷新x坐标
                    y = -13933, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 30
                },
                {
                    name = "游荡的血色军剑士", -- 名字 需要在物编定义好
                    x = -25070, -- 小怪刷新x坐标
                    y = -14000, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 30
                },
                {
                    name = "游荡的血色军卫士", -- 名字 需要在物编定义好
                    x = -25270, -- 小怪刷新x坐标
                    y = -14000, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 30
                },
                {
                    name = "游荡的血色军法师", -- 名字 需要在物编定义好
                    x = -24870, -- 小怪刷新x坐标
                    y = -13800, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 30
                },
                {
                    name = "游荡的血色军剑士", -- 名字 需要在物编定义好
                    x = -26368, -- 小怪刷新x坐标
                    y = -14664, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 30
                },
                {
                    name = "游荡的血色军卫士", -- 名字 需要在物编定义好
                    x = -26168, -- 小怪刷新x坐标
                    y = -14664, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 30
                },
                {
                    name = "游荡的血色军法师", -- 名字 需要在物编定义好
                    x = -26368, -- 小怪刷新x坐标
                    y = -14864, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 40,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 30
                },
                {
                    name = "反叛军步卒", -- 名字 需要在物编定义好
                    x = -25688, -- 小怪刷新x坐标
                    y = -16511, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 33
                },
                {
                    name = "反叛军步卒", -- 名字 需要在物编定义好
                    x = -25588, -- 小怪刷新x坐标
                    y = -16611, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 33
                },
                {
                    name = "反叛军牧师", -- 名字 需要在物编定义好
                    x = -25488, -- 小怪刷新x坐标
                    y = -16411, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 34
                },
                {
                    name = "反叛军牧师", -- 名字 需要在物编定义好
                    x = -25488, -- 小怪刷新x坐标
                    y = -16615, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 34
                },
                {
                    name = "反叛军步卒", -- 名字 需要在物编定义好
                    x = -25598, -- 小怪刷新x坐标
                    y = -18216, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "反叛军步卒", -- 名字 需要在物编定义好
                    x = -25698, -- 小怪刷新x坐标
                    y = -18116, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "反叛军牧师", -- 名字 需要在物编定义好
                    x = -25798, -- 小怪刷新x坐标
                    y = -18166, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "反叛军牧师", -- 名字 需要在物编定义好
                    x = -25498, -- 小怪刷新x坐标
                    y = -18016, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "反叛军步卒", -- 名字 需要在物编定义好
                    x = -24551, -- 小怪刷新x坐标
                    y = -16839, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "反叛军步卒", -- 名字 需要在物编定义好
                    x = -24651, -- 小怪刷新x坐标
                    y = -16939, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "反叛军牧师", -- 名字 需要在物编定义好
                    x = -24751, -- 小怪刷新x坐标
                    y = -16859, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "反叛军牧师", -- 名字 需要在物编定义好
                    x = -24251, -- 小怪刷新x坐标
                    y = -16939, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "反叛军步卒", -- 名字 需要在物编定义好
                    x = -23849, -- 小怪刷新x坐标
                    y = -17867, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "反叛军步卒", -- 名字 需要在物编定义好
                    x = -23649, -- 小怪刷新x坐标
                    y = -17967, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "反叛军牧师", -- 名字 需要在物编定义好
                    x = -23549, -- 小怪刷新x坐标
                    y = -17967, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "反叛军牧师", -- 名字 需要在物编定义好
                    x = -23649, -- 小怪刷新x坐标
                    y = -17767, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "反叛军步卒", -- 名字 需要在物编定义好
                    x = -22849, -- 小怪刷新x坐标 (原始 -23849 + 1000)
                    y = -17367, -- 小怪刷新y坐标 (原始 -17867 + 500)
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "反叛军步卒", -- 名字 需要在物编定义好
                    x = -22649, -- 小怪刷新x坐标 (原始 -23649 + 1000)
                    y = -17467, -- 小怪刷新y坐标 (原始 -17967 + 500)
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "反叛军牧师", -- 名字 需要在物编定义好
                    x = -22549, -- 小怪刷新x坐标 (原始 -23549 + 1000)
                    y = -17467, -- 小怪刷新y坐标 (原始 -17967 + 500)
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "反叛军牧师", -- 名字 需要在物编定义好
                    x = -22649, -- 小怪刷新x坐标 (原始 -23649 + 1000)
                    y = -17267, -- 小怪刷新y坐标 (原始 -17767 + 500)
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 50,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 35
                },
                {
                    name = "低等缝合怪", -- 名字 需要在物编定义好
                    x = -22132, -- 小怪刷新x坐标
                    y = -14367, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 36
                },
                {
                    name = "低等缝合怪", -- 名字 需要在物编定义好
                    x = -20891, -- 小怪刷新x坐标
                    y = -14574, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 36
                },
                {
                    name = "低等缝合怪", -- 名字 需要在物编定义好
                    x = -20548, -- 小怪刷新x坐标
                    y = -15319, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 36
                },
                {
                    name = "低等缝合怪", -- 名字 需要在物编定义好
                    x = -19371, -- 小怪刷新x坐标
                    y = -15822, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 36
                },
                {
                    name = "低等缝合怪", -- 名字 需要在物编定义好
                    x = -21372, -- 小怪刷新x坐标
                    y = -15551, -- 小怪刷新y坐标
                    face = math.random(1, 360), -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 36
                }
            },
            bosses = {
                {
                    name = "豺狼领主", -- 名字 需要在物编定义好
                    x = -22011, -- 小怪刷新x坐标
                    y = -20353, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 30,
                    diaoluoConfig = DiaoLuoConfig({ diaoluoConfigForXSCWBoss }),
                    level = 23
                },
                {
                    name = "血色军下士", -- 名字 需要在物编定义好
                    x = -24127, -- 小怪刷新x坐标
                    y = -13675, -- 小怪刷新y坐标
                    face = 0, -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = DiaoLuoConfig({ diaoluoConfigForXSCWBoss }),
                    level = 32
                }
            },
            NPCs = {
                {
                    name = "历史学家埃尔文",
                    x = -31233,
                    y = -20932
                },
                {
                    name = "资深牧师萨缪尔",
                    x = -31910,
                    y = -17798,
                    face = 0
                },
                {
                    name = "城主约翰",
                    x = -31481,
                    y = -17335
                },
                {
                    name = "炼金师塞德里克",
                    x = -28605,
                    y = -19966
                },
                {
                    name = "资深铁匠加里克",
                    x = -28996,
                    y = -17930
                },
                {
                    name = "王牌卧底德尼尔",
                    x = -21869,
                    y = -14966
                },
                {
                    name = "附魔大师加夫里尔",
                    x = -28169,
                    y = -19966
                },
                {
                    name = "军需处长谭恩",
                    x = -31045,
                    y = -17787,
                    face = 180
                },
                {
                    name = "冒险者工会会长",
                    x = -31552,
                    y = -21110,
                    face = 0
                },
                {
                    name = "虚空商人",
                    x = -30692,
                    y = -20802,
                    face = 270
                },
                {
                    name = "王城总教头",
                    x = -29058,
                    y = -15413,
                    face = 90
                },
                {
                    name = "王城禁军",
                    x = -30566,
                    y = -16100,
                    face = 90,
                    nowShowInXiaoditu = true
                },
                {
                    name = "王城禁军",
                    x = -29763,
                    y = -16100,
                    face = 90,
                    nowShowInXiaoditu = true
                },
                {
                    name = "王城禁军",
                    x = -26581,
                    y = -20072,
                    face = 0,
                    nowShowInXiaoditu = true
                },
                {
                    name = "王城禁军",
                    x = -26581,
                    y = -20612,
                    face = 0,
                    nowShowInXiaoditu = true
                },
                {
                    name = "王城禁军",
                    x = -28070,
                    y = -21572,
                    face = 0,
                    nowShowInXiaoditu = true
                },
                {
                    name = "王城禁军",
                    x = -27650,
                    y = -21572,
                    face = 180,
                    nowShowInXiaoditu = true
                },
                {
                    name = "王城禁军",
                    x = -29244,
                    y = -15065,
                    face = 270,
                    nowShowInXiaoditu = true
                },
                {
                    name = "王城禁军",
                    x = -28918,
                    y = -15065,
                    face = 270,
                    nowShowInXiaoditu = true
                },
                {
                    name = "珠宝大师索恩",
                    x = -27705,
                    y = -19966,
                    face = 270
                },
                {
                    name = "裁缝大师马斯特",
                    x = -27265,
                    y = -19970,
                    face = 270
                },
                {
                    name = "制皮大师莱瑟",
                    x = -31168,
                    y = -21640,
                    face = 90
                },
                {
                    name = "竞技场大师凯德",
                    x = -27564,
                    y = -15153,
                    face = 180
                }
            },
            ZIYUAN = {
                {
                    name = "精铁矿",
                    x = -19120,
                    y = -13282,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.KUANGSHI
                },
                {
                    name = "精铁矿",
                    x = -25710,
                    y = -21510,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.KUANGSHI
                },
                {
                    name = "精铁矿",
                    x = -31250,
                    y = -13310,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.KUANGSHI
                },
                {
                    name = "金色草药",
                    x = -24196,
                    y = -13486,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.CAOYAO
                },
                {
                    name = "金色草药",
                    x = -19684,
                    y = -17600,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.CAOYAO
                },
                {
                    name = "金色草药",
                    x = -28000,
                    y = -15400,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.CAOYAO
                },
                {
                    name = "王城喷泉",
                    x = -30396,
                    y = -19746,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.DIAOYUDIAN
                }
            }
        }
    )
    hyewai.buildYewai(
        {
            name = "灼热山谷",
            level = 40,
            blp = "ReplaceableTextures\\xiaoditu\\UI_map_09.blp",
            enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_04.blp",
            clearTimeout = 300,
            nandu = FUBEN_NANDU.PUTONG,
            rectParam = { minX = -31718, minY = -9652, maxX = -16623, maxY = 2942 }, -- 野外区域坐标
            chuansongdian = {
                { x = -19527, y = -2180, name = "灼热山谷前哨站", cost = 100, face = 270 },
                { x = -23527, y = -3129, name = "灼热山谷深处", cost = 300, face = 270 }
            },
            portal = {
                { x = -17677, y = -8981, destX = -19670, destY = -12946, destination = "王城" },
                { x = -19150, y = -12511, destX = -17724, destY = -8532, destination = "灼热山谷" }
            },
            minions = {
                {
                    name = "挨打的木桩", -- 名字 需要在物编定义好
                    x = -17604, -- 小怪刷新x坐标
                    y = -4425, -- 小怪刷新y坐标
                    face = 180, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = DiaoLuoConfig( --掉落配置
                        {
                            {
                                list = { "白纸" }, --物品名字 需要在物编定义好
                                drop_rate = {
                                    --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                    10,
                                    0,
                                    0,
                                    0
                                }
                            }
                        }
                    ),
                    level = 55,
                    passiveSkill = {
                        {
                            {
                                description = "传说中的不死之身",
                                attr_type = CONST_EVENT.dying,
                                attr = function(evtData)
                                    hunit.setCurLifePercent(evtData.targetUnit, 100)
                                end
                            },
                            {
                                description = "专业木桩，拥有一百万生命值",
                                attr_type = CONST_EVENT.attr,
                                attr = _attr({ life = "=1000000", attack = "=0" })
                            }
                        },
                        {},
                        {},
                        {}
                    }
                },
                {
                    name = "挨打的木桩", -- 名字 需要在物编定义好
                    x = -17604, -- 小怪刷新x坐标
                    y = -5425, -- 小怪刷新y坐标
                    face = 180, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = DiaoLuoConfig( --掉落配置
                        {
                            {
                                list = { "白纸" }, --物品名字 需要在物编定义好
                                drop_rate = {
                                    --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                    10,
                                    0,
                                    0,
                                    0
                                }
                            }
                        }
                    ),
                    level = 60,
                    passiveSkill = {
                        {
                            {
                                description = "传说中的不死之身",
                                attr_type = CONST_EVENT.dying,
                                attr = function(evtData)
                                    hunit.setCurLifePercent(evtData.targetUnit, 100)
                                end
                            },
                            {
                                description = "专业木桩，拥有三百万生命值",
                                attr_type = CONST_EVENT.attr,
                                attr = _attr({ life = "=3000000", attack = "=0", defend_white = "=200", mojia = "=200" })
                            }
                        },
                        {},
                        {},
                        {}
                    }
                },
                {
                    name = "人马苦工", -- 名字 需要在物编定义好
                    x = -18176, -- 小怪刷新x坐标
                    y = -460, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 40
                },
                {
                    name = "人马苦工", -- 名字 需要在物编定义好
                    x = -17467, -- 小怪刷新x坐标
                    y = -302, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 40
                },
                {
                    name = "人马弓箭手", -- 名字 需要在物编定义好
                    x = -17937, -- 小怪刷新x坐标
                    y = 59, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 41
                },
                {
                    name = "人马弓箭手", -- 名字 需要在物编定义好
                    x = -18416, -- 小怪刷新x坐标
                    y = 2050, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 41
                },
                {
                    name = "人马苦工", -- 名字 需要在物编定义好
                    x = -19390, -- 小怪刷新x坐标
                    y = 1640, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 42
                },
                {
                    name = "人马刺客", -- 名字 需要在物编定义好
                    x = -19688, -- 小怪刷新x坐标
                    y = 1640, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 42
                },
                {
                    name = "人马先行者", -- 名字 需要在物编定义好
                    x = -21380, -- 小怪刷新x坐标
                    y = 1534, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 42
                },
                {
                    name = "人马先知", -- 名字 需要在物编定义好
                    x = -21892, -- 小怪刷新x坐标
                    y = 1327, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 42
                },
                {
                    name = "人马刺客", -- 名字 需要在物编定义好
                    x = -21166, -- 小怪刷新x坐标
                    y = 1941, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "人马先行者", -- 名字 需要在物编定义好
                    x = -21658, -- 小怪刷新x坐标
                    y = 395, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "人马刺客", -- 名字 需要在物编定义好
                    x = -21658, -- 小怪刷新x坐标
                    y = 295, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "人马刺客", -- 名字 需要在物编定义好
                    x = -20561, -- 小怪刷新x坐标
                    y = 600, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "人马先行者", -- 名字 需要在物编定义好
                    x = -19152, -- 小怪刷新x坐标
                    y = -218, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "人马先行者", -- 名字 需要在物编定义好
                    x = -19152, -- 小怪刷新x坐标
                    y = -418, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "人马刺客", -- 名字 需要在物编定义好
                    x = -20561, -- 小怪刷新x坐标
                    y = -972, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "人马先行者", -- 名字 需要在物编定义好
                    x = -20252, -- 小怪刷新x坐标
                    y = -400, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "人马先知", -- 名字 需要在物编定义好
                    x = -20872, -- 小怪刷新x坐标
                    y = -400, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 42
                },
                {
                    name = "人马先行者", -- 名字 需要在物编定义好
                    x = -21746, -- 小怪刷新x坐标
                    y = -475, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "人马先知", -- 名字 需要在物编定义好
                    x = -21994, -- 小怪刷新x坐标
                    y = -425, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 42
                },
                {
                    name = "人马先知", -- 名字 需要在物编定义好
                    x = -21994, -- 小怪刷新x坐标
                    y = -525, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 42
                },
                {
                    name = "鹰身女妖侦察者", -- 名字 需要在物编定义好
                    x = -21796, -- 小怪刷新x坐标
                    y = -2109, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "鹰身女妖侦察者", -- 名字 需要在物编定义好
                    x = -20675, -- 小怪刷新x坐标
                    y = -2178, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "鹰身女妖侦察者", -- 名字 需要在物编定义好
                    x = -21856, -- 小怪刷新x坐标
                    y = -2673, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "鹰身女妖侦察者", -- 名字 需要在物编定义好
                    x = -21075, -- 小怪刷新x坐标
                    y = -2432, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "鹰身女妖", -- 名字 需要在物编定义好
                    x = -21016, -- 小怪刷新x坐标
                    y = -3371, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "鹰身女妖", -- 名字 需要在物编定义好
                    x = -21979, -- 小怪刷新x坐标
                    y = -3950, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "鹰身女妖", -- 名字 需要在物编定义好
                    x = -21113, -- 小怪刷新x坐标
                    y = -3864, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 43
                },
                {
                    name = "鹰身女妖巫师", -- 名字 需要在物编定义好
                    x = -20400, -- 小怪刷新x坐标
                    y = -4578, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 44
                },
                {
                    name = "鹰身女妖巫师", -- 名字 需要在物编定义好
                    x = -22057, -- 小怪刷新x坐标
                    y = -5315, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 44
                },
                {
                    name = "鹰身女妖巫师", -- 名字 需要在物编定义好
                    x = -21156, -- 小怪刷新x坐标
                    y = -4951, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 44
                },
                {
                    name = "鹰身女妖巫师", -- 名字 需要在物编定义好
                    x = -20548, -- 小怪刷新x坐标
                    y = -5408, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 44
                },
                {
                    name = "鹰身女妖巫师", -- 名字 需要在物编定义好
                    x = -20568, -- 小怪刷新x坐标
                    y = -6554, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 44
                },
                {
                    name = "鹰身女妖巫师", -- 名字 需要在物编定义好
                    x = -19372, -- 小怪刷新x坐标
                    y = -6554, -- 小怪刷新y坐标
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 44
                },
                {
                    name = "人马先行者", -- 名字 需要在物编定义好
                    x = -20239, -- 小怪刷新x坐标
                    y = -7908, -- 小怪刷新y坐标
                    face = 90, -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 45
                },
                {
                    name = "人马先行者", -- 名字 需要在物编定义好
                    x = -19291, -- 小怪刷新x坐标
                    y = -7841, -- 小怪刷新y坐标
                    face = 90, -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 45
                },
                {
                    name = "人马先知", -- 名字 需要在物编定义好
                    x = -20848, -- 小怪刷新x坐标
                    y = -8481, -- 小怪刷新y坐标
                    face = 90, -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 45
                },
                {
                    name = "人马先知", -- 名字 需要在物编定义好
                    x = -20555, -- 小怪刷新x坐标
                    y = -8668, -- 小怪刷新y坐标
                    face = 90, -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 45
                },
                {
                    name = "人马弓箭手", -- 名字 需要在物编定义好
                    x = -19254, -- 小怪刷新x坐标
                    y = -8422, -- 小怪刷新y坐标
                    face = 90, -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 45
                },
                {
                    name = "人马弓箭手", -- 名字 需要在物编定义好
                    x = -19092, -- 小怪刷新x坐标
                    y = -8888, -- 小怪刷新y坐标
                    face = 90, -- 小怪朝向
                    reborn = 60,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 45
                },
                {
                    name = "黑铁矮人矿工", -- 名字 需要在物编定义好
                    x = -24840, -- 小怪刷新x坐标
                    y = -1849, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 47
                },
                {
                    name = "黑铁矮人矿工", -- 名字 需要在物编定义好
                    x = -24123, -- 小怪刷新x坐标
                    y = -992, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 47
                },
                {
                    name = "黑铁矮人矿工", -- 名字 需要在物编定义好
                    x = -27269, -- 小怪刷新x坐标
                    y = -922, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 47
                },
                {
                    name = "黑铁矮人矿工", -- 名字 需要在物编定义好
                    x = -26517, -- 小怪刷新x坐标
                    y = -590, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 47
                },
                {
                    name = "黑铁矮人守卫", -- 名字 需要在物编定义好
                    x = -26959, -- 小怪刷新x坐标
                    y = 240, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 49
                },
                {
                    name = "黑铁矮人守卫", -- 名字 需要在物编定义好
                    x = -24198, -- 小怪刷新x坐标
                    y = 1000, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 49
                },
                {
                    name = "黑铁矮人守卫", -- 名字 需要在物编定义好
                    x = -24584, -- 小怪刷新x坐标
                    y = -720, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 48
                },
                {
                    name = "黑铁矮人守卫", -- 名字 需要在物编定义好
                    x = -27182, -- 小怪刷新x坐标
                    y = -352, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 48
                },
                {
                    name = "黑铁矮人枪手", -- 名字 需要在物编定义好
                    x = -26997, -- 小怪刷新x坐标
                    y = 483, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 49
                },
                {
                    name = "黑铁矮人枪手", -- 名字 需要在物编定义好
                    x = -26687, -- 小怪刷新x坐标
                    y = 702, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 49
                },
                {
                    name = "黑铁矮人矿工", -- 名字 需要在物编定义好
                    x = -27500, -- 小怪刷新x坐标
                    y = 1515, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 50
                },
                {
                    name = "黑铁矮人矿工", -- 名字 需要在物编定义好
                    x = -27878, -- 小怪刷新x坐标
                    y = 1872, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 50
                },
                {
                    name = "黑铁矮人枪手", -- 名字 需要在物编定义好
                    x = -27540, -- 小怪刷新x坐标
                    y = 2000, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 50
                },
                {
                    name = "黑铁矮人守卫", -- 名字 需要在物编定义好
                    x = -27893, -- 小怪刷新x坐标
                    y = 1348, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 51
                },
                {
                    name = "黑铁矮人矿工", -- 名字 需要在物编定义好
                    x = -23301, -- 小怪刷新x坐标
                    y = 1866, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 51
                },
                {
                    name = "黑铁矮人枪手", -- 名字 需要在物编定义好
                    x = -23749, -- 小怪刷新x坐标
                    y = 1755, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 52
                },
                {
                    name = "黑铁矮人守卫", -- 名字 需要在物编定义好
                    x = -24250, -- 小怪刷新x坐标
                    y = 2000, -- 小怪刷新y坐标
                    reborn = 90,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 52
                },
                {
                    name = "火元素", -- 名字 需要在物编定义好
                    x = -26850, -- 小怪刷新x坐标
                    y = -4838, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 54
                },
                {
                    name = "火元素", -- 名字 需要在物编定义好
                    x = -29002, -- 小怪刷新x坐标
                    y = -5218, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 55
                },
                {
                    name = "火元素", -- 名字 需要在物编定义好
                    x = -28548, -- 小怪刷新x坐标
                    y = -6260, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 55
                },
                {
                    name = "火元素", -- 名字 需要在物编定义好
                    x = -26324, -- 小怪刷新x坐标
                    y = -5982, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 56
                },
                {
                    name = "火元素", -- 名字 需要在物编定义好
                    x = -26338, -- 小怪刷新x坐标
                    y = -7675, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 57
                },
                {
                    name = "火元素", -- 名字 需要在物编定义好
                    x = -27836, -- 小怪刷新x坐标
                    y = -8159, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 58
                },
                {
                    name = "石元素", -- 名字 需要在物编定义好
                    x = -30308, -- 小怪刷新x坐标
                    y = -4220, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 54
                },
                {
                    name = "石元素", -- 名字 需要在物编定义好
                    x = -29220, -- 小怪刷新x坐标
                    y = -6356, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 55
                },
                {
                    name = "石元素", -- 名字 需要在物编定义好
                    x = -27807, -- 小怪刷新x坐标
                    y = -6489, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 56
                },
                {
                    name = "石元素", -- 名字 需要在物编定义好
                    x = -27046, -- 小怪刷新x坐标
                    y = -7768, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 57
                },
                {
                    name = "石元素", -- 名字 需要在物编定义好
                    x = -28338, -- 小怪刷新x坐标
                    y = -8979, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 58
                },
                {
                    name = "炎巨人", -- 名字 需要在物编定义好
                    x = -30489, -- 小怪刷新x坐标
                    y = -6657, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 54
                },
                {
                    name = "炎巨人", -- 名字 需要在物编定义好
                    x = -28271, -- 小怪刷新x坐标
                    y = -6123, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 56
                },
                {
                    name = "炎巨人", -- 名字 需要在物编定义好
                    x = -26484, -- 小怪刷新x坐标
                    y = -7820, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 58
                },
                {
                    name = "炎巨人", -- 名字 需要在物编定义好
                    x = -30489, -- 小怪刷新x坐标
                    y = -8260, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 59
                }
            },
            bosses = {
                {
                    name = "人马领主", -- 名字 需要在物编定义好
                    x = -19854, -- 小怪刷新x坐标
                    y = -8445, -- 小怪刷新y坐标
                    face = 90, -- 小怪朝向
                    reborn = 180,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    level = 46
                }
            },
            shijieboss = {
                {
                    name = "风元素领主", -- 名字 需要在物编定义好
                    x = -23254, -- 小怪刷新x坐标
                    y = -8491, -- 小怪刷新y坐标
                    face = 90, -- 小怪朝向
                    reborn = 420,
                    level = 60,
                    shuaxindelay = 450,
                    diaoluoConfig = DiaoLuoConfig(
                        {
                            {
                                list = {
                                    "风吻之刃"
                                }, --物品名字 需要在物编定义好
                                drop_rate = {
                                    --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                    200,
                                    0,
                                    0,
                                    0
                                }
                            },
                            {
                                list = { "埃提耶什的杖头" }, --物品名字 需要在物编定义好
                                drop_rate = {
                                    --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                    200,
                                    0,
                                    0,
                                    0
                                }
                            }
                        }
                    ),
                    jiangli = {
                        resource = {
                            { type = HSHOP_COST_TYPE.gold,           value = 2000 },
                            { type = HSHOP_COST_TYPE.yongqihuizhang, value = 2 },
                            { type = HSHOP_COST_TYPE.huoyanhuizhang, value = 1 }
                        },
                        shengwang = {
                            {
                                value = 200,
                                maxLevel = 3,
                                shengwangname = "峡谷前哨站"
                            }
                        }
                    },
                    ai = UnitAI(
                        {
                            {
                                aiType = UNIT_AI_TYPE.CAST_SKILL,
                                aiData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                    name = "雷霆万钧",
                                    notInterruptable = true,
                                    healthBelowLimit = 100,
                                    castCD = 60,
                                    shifashijian = 10.1,
                                    startEffect = function(evtData)
                                        htextTag.create2Unit(evtData.triggerUnit, "感受雷电的愤怒吧!!!", 10, "e8da12", 1, 1, 50)
                                    end,
                                    interval = 0.1,
                                    periodEffect = function(evtData)
                                        local sourceUnit = evtData.triggerUnit
                                        local x = hunit.x(sourceUnit) + math.random(-2000, 2000)
                                        local y = hunit.y(sourceUnit) + math.random(-2000, 2000)

                                        local e = hskillMoban.radiusWarning(x, y, hunit.z(sourceUnit), 350, 10)
                                        heffect.xyz("[boss]fengyuansulingzhu1.mdx", x, y, hunit.z(sourceUnit), 0, 1)
                                        htime.setTimeout(
                                            2,
                                            function(t)
                                                heffect.destroy(e)
                                                heffect.xyz(
                                                    "[boss]fengyuansulingzhu1.mdx",
                                                    x,
                                                    y,
                                                    hunit.z(sourceUnit),
                                                    0,
                                                    1,
                                                    2,
                                                    2,
                                                    2
                                                )
                                                hskillMoban.radiusAOE(
                                                    x,
                                                    y,
                                                    sourceUnit,
                                                    350,
                                                    function(targetUnit)
                                                        hskill.damage(
                                                            {
                                                                sourceUnit = sourceUnit,
                                                                targetUnit = targetUnit,
                                                                damage = hattr.get(sourceUnit, "attack", 1) * 3,
                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                damageType = DAMAGE_TYPE.MOFA,
                                                                --effect = "Abilities\\Weapons\\RedDragonBreath\\RedDragonMissile.mdl",
                                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                                                damageElementType = {
                                                                    CONST_DAMAGE_ELEMENT_TYPE.METAL
                                                                }
                                                            }
                                                        )
                                                    end
                                                )
                                            end
                                        )
                                    end,
                                    effect = function(evtData)
                                    end
                                }
                            },
                            {
                                aiType = UNIT_AI_TYPE.CAST_SKILL,
                                aiData = {
                                    targetType = UNIT_AI_TARGET_TYPE.LOWEST_HEALTH_UNIT,
                                    name = "闪电之力",
                                    notInterruptable = false,
                                    healthBelowLimit = 100,
                                    castCD = 10,
                                    castDistance = 10000,
                                    shifashijian = 2,
                                    startEffect = function(evtData)
                                        htextTag.create2Unit(evtData.triggerUnit, "闪电之力", 10, "e8da12", 1, 1, 50)
                                    end,
                                    effect = function(evtData)
                                        local sourceUnit = evtData.triggerUnit
                                        local targetUnit = evtData.targetUnit
                                        local damage = hattr.getWithLimit(sourceUnit, nil, "attack", 10000) * 2
                                        if
                                            math.distance(
                                                hunit.x(sourceUnit),
                                                hunit.y(sourceUnit),
                                                hunit.x(targetUnit),
                                                hunit.y(targetUnit)
                                            ) > 2000
                                        then
                                            damage = damage * 100
                                            htextTag.create2Unit(
                                                targetUnit,
                                                "致死闪电之力（距离风元素领主超过2000）",
                                                10,
                                                "e81212",
                                                2,
                                                1,
                                                50
                                            )
                                        end
                                        hskill.damage(
                                            {
                                                sourceUnit = sourceUnit,
                                                targetUnit = targetUnit,
                                                damage = damage,
                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                damageType = DAMAGE_TYPE.MOFA,
                                                effect = "war3mapImported\\[Spell]_083.MDX",
                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
                                            }
                                        )
                                    end
                                }
                            },
                            {
                                aiType = UNIT_AI_TYPE.CAST_SKILL,
                                aiData = {
                                    targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                    name = "风雷之力",
                                    notInterruptable = true,
                                    healthBelowLimit = 100,
                                    castCD = 10,
                                    castDistance = 20000,
                                    shifashijian = 1,
                                    startEffect = function(evtData)
                                        htextTag.create2Unit(evtData.triggerUnit, "风雷之力", 10, "e8da12", 1, 1, 50)
                                    end,
                                    effect = function(evtData)
                                        local sourceUnit = evtData.triggerUnit
                                        local targetUnit = evtData.targetUnit
                                        local x = hunit.x(targetUnit)
                                        local y = hunit.y(targetUnit)
                                        local duration = 15
                                        heffect.xyz(
                                            "[boss]fengyuansulingzhu2.mdx",
                                            x,
                                            y,
                                            hunit.z(targetUnit),
                                            duration,
                                            1
                                        )
                                        local intervalTimer =
                                            htime.setInterval(
                                                1,
                                                function(t)
                                                    hskillMoban.radiusAOE(
                                                        x,
                                                        y,
                                                        sourceUnit,
                                                        480,
                                                        function(targetUnit)
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = sourceUnit,
                                                                    targetUnit = targetUnit,
                                                                    damage = hattr.get(sourceUnit, "attack", 1),
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                    effect = "[boss]fengyuansu.mdx",
                                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                                                    damageElementType = {
                                                                        CONST_DAMAGE_ELEMENT_TYPE.METAL
                                                                    }
                                                                }
                                                            )
                                                        end
                                                    )
                                                end
                                            )
                                        htime.setTimeout(
                                            duration,
                                            function(t)
                                                intervalTimer.destroy()
                                            end
                                        )
                                    end
                                }
                            },
                            {
                                aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                aiData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                }
                            }
                        }
                    ),
                    passiveSkill = { { tuozhanhuixue }, {}, {}, {} },
                    tuozhanshijian = 60
                }
            },
            NPCs = {
                {
                    name = "钓鱼大师派罗",
                    x = -23127,
                    y = -3491,
                    face = 270
                },
                {
                    name = "守备官斯通哈特",
                    x = -17745,
                    y = -2206,
                    face = 235
                },
                {
                    name = "传奇铁匠福吉菲尔",
                    x = -17589,
                    y = -3532,
                    face = 180
                },
                {
                    name = "老兵格雷戈",
                    x = -18889,
                    y = -2843,
                    face = 0
                },
            },
            ZIYUAN = {
                {
                    name = "秘银矿",
                    x = -26601,
                    y = 544,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.KUANGSHI
                },
                {
                    name = "秘银矿",
                    x = -20914,
                    y = -8514,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.KUANGSHI
                },
                {
                    name = "秘银矿",
                    x = -30881,
                    y = -6442,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.KUANGSHI
                },
                {
                    name = "沙漠草药",
                    x = -21352,
                    y = -7451,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.CAOYAO
                },
                {
                    name = "沙漠草药",
                    x = -18508,
                    y = -7214,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.CAOYAO
                },
                {
                    name = "沙漠草药",
                    x = -29098,
                    y = -9023,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.CAOYAO
                },
                {
                    name = "沙漠深井",
                    x = -23127,
                    y = -3831,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.DIAOYUDIAN
                }
            }
        }
    )

    hyewai.buildYewai(
        {
            name = "纷争之地",
            level = 60,
            blp = "ReplaceableTextures\\xiaoditu\\UI_map_16.blp",
            enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_16.blp",
            clearTimeout = 300,
            nandu = FUBEN_NANDU.PUTONG,
            rectParam = { minX = -16145, minY = -21722, maxX = -2042, maxY = -8580 }, -- 野外区域坐标
            chuansongdian = {
                { x = -10637, y = -14605, name = "和平之城", cost = 300, face = 270 }
            },
            portal = {
                { x = -15917, y = -14193, destX = -30768, destY = -3504, destination = "灼热山谷" },
                { x = -31064, y = -3504, destX = -15616, destY = -14193, destination = "纷争之地" }
            },
            minions = {
                {
                    name = "挨打的木桩", -- 名字 需要在物编定义好
                    x = -8599, -- 小怪刷新x坐标
                    y = -13583, -- 小怪刷新y坐标
                    face = 180, -- 小怪朝向
                    reborn = 20,
                    diaoluoConfig = DiaoLuoConfig( --掉落配置
                        {
                            {
                                list = { "白纸" }, --物品名字 需要在物编定义好
                                drop_rate = {
                                    --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                    10,
                                    0,
                                    0,
                                    0
                                }
                            }
                        }
                    ),
                    level = 70,
                    passiveSkill = {
                        {
                            {
                                description = "传说中的不死之身",
                                attr_type = CONST_EVENT.dying,
                                attr = function(evtData)
                                    hunit.setCurLifePercent(evtData.targetUnit, 100)
                                end
                            },
                            {
                                description = "专业木桩，拥有一千万生命值",
                                attr_type = CONST_EVENT.attr,
                                attr = _attr(
                                    {
                                        life = "=100000000",
                                        attack = "=0",
                                        defend_white = "=621",
                                        mojia = "=621",
                                        shanbi =
                                        "+10"
                                    }
                                )
                            }
                        },
                        {},
                        {},
                        {}
                    }
                },
                {
                    name = "野蛮卫兵", -- 名字 需要在物编定义好
                    x = -14848, -- 小怪刷新x坐标
                    y = -14022, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 61
                },
                {
                    name = "狂暴卫兵", -- 名字 需要在物编定义好
                    x = -14848, -- 小怪刷新x坐标
                    y = -14022, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 61
                },
                {
                    name = "射手卫兵", -- 名字 需要在物编定义好
                    x = -14848, -- 小怪刷新x坐标
                    y = -14022, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 61
                },

                {
                    name = "野蛮卫兵", -- 名字 需要在物编定义好
                    x = -13832, -- 小怪刷新x坐标
                    y = -14410, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 62
                },
                {
                    name = "狂暴卫兵", -- 名字 需要在物编定义好
                    x = -13832, -- 小怪刷新x坐标
                    y = -14410, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 62
                },
                {
                    name = "射手卫兵", -- 名字 需要在物编定义好
                    x = -13832, -- 小怪刷新x坐标
                    y = -14410, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 62
                },
                {
                    name = "野蛮卫兵", -- 名字 需要在物编定义好
                    x = -15458, -- 小怪刷新x坐标
                    y = -15718, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 63
                },
                {
                    name = "狂暴卫兵", -- 名字 需要在物编定义好
                    x = -15458, -- 小怪刷新x坐标
                    y = -15718, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 63
                },
                {
                    name = "射手卫兵", -- 名字 需要在物编定义好
                    x = -15458, -- 小怪刷新x坐标
                    y = -15718, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 63
                },
                {
                    name = "野蛮卫兵", -- 名字 需要在物编定义好
                    x = -14498, -- 小怪刷新x坐标
                    y = -16482, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 63
                },
                {
                    name = "狂暴卫兵", -- 名字 需要在物编定义好
                    x = -14498, -- 小怪刷新x坐标
                    y = -16482, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 63
                },
                {
                    name = "射手卫兵", -- 名字 需要在物编定义好
                    x = -14498, -- 小怪刷新x坐标
                    y = -16482, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 63
                },
                {
                    name = "野蛮卫兵", -- 名字 需要在物编定义好
                    x = -15093, -- 小怪刷新x坐标
                    y = -17837, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 64
                },
                {
                    name = "狂暴卫兵", -- 名字 需要在物编定义好
                    x = -15093, -- 小怪刷新x坐标
                    y = -17837, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 64
                },
                {
                    name = "射手卫兵", -- 名字 需要在物编定义好
                    x = -15093, -- 小怪刷新x坐标
                    y = -17837, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 64
                },
                {
                    name = "野蛮卫兵", -- 名字 需要在物编定义好
                    x = -12643, -- 小怪刷新x坐标
                    y = -18648, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 65
                },
                {
                    name = "狂暴卫兵", -- 名字 需要在物编定义好
                    x = -12643, -- 小怪刷新x坐标
                    y = -18648, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 65
                },
                {
                    name = "射手卫兵", -- 名字 需要在物编定义好
                    x = -12643, -- 小怪刷新x坐标
                    y = -18648, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 65
                },
                {
                    name = "野蛮卫兵", -- 名字 需要在物编定义好
                    x = -12631, -- 小怪刷新x坐标
                    y = -20975, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 65
                },
                {
                    name = "狂暴卫兵", -- 名字 需要在物编定义好
                    x = -12631, -- 小怪刷新x坐标
                    y = -20975, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 65
                },
                {
                    name = "射手卫兵", -- 名字 需要在物编定义好
                    x = -12631, -- 小怪刷新x坐标
                    y = -20975, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 65
                },
                {
                    name = "戈隆", -- 名字 需要在物编定义好
                    x = -15401, -- 小怪刷新x坐标
                    y = -19707, -- 小怪刷新y坐标
                    reborn = 120,
                    guaiwuType = MONSTER_TYPE.YEWAI_JINGYING,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 65
                },
                {
                    name = "戈隆", -- 名字 需要在物编定义好
                    x = -15005, -- 小怪刷新x坐标
                    y = -21096, -- 小怪刷新y坐标
                    reborn = 120,
                    guaiwuType = MONSTER_TYPE.YEWAI_JINGYING,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 65
                },
                {
                    name = "戈隆", -- 名字 需要在物编定义好
                    x = -13698, -- 小怪刷新x坐标
                    y = -20488, -- 小怪刷新y坐标
                    reborn = 120,
                    guaiwuType = MONSTER_TYPE.YEWAI_JINGYING,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 65
                },
                {
                    name = "戈隆", -- 名字 需要在物编定义好
                    x = -15389, -- 小怪刷新x坐标
                    y = -20673, -- 小怪刷新y坐标
                    reborn = 120,
                    guaiwuType = MONSTER_TYPE.YEWAI_JINGYING,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 65
                },
                {
                    name = "戈隆", -- 名字 需要在物编定义好
                    x = -13174, -- 小怪刷新x坐标
                    y = -21215, -- 小怪刷新y坐标
                    reborn = 120,
                    guaiwuType = MONSTER_TYPE.YEWAI_JINGYING,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 65
                },
                {
                    name = "戈隆", -- 名字 需要在物编定义好
                    x = -12974, -- 小怪刷新x坐标
                    y = -19994, -- 小怪刷新y坐标
                    reborn = 120,
                    guaiwuType = MONSTER_TYPE.YEWAI_JINGYING,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 65
                },
                {
                    name = "戈隆", -- 名字 需要在物编定义好
                    x = -15783, -- 小怪刷新x坐标
                    y = -18564, -- 小怪刷新y坐标
                    reborn = 120,
                    guaiwuType = MONSTER_TYPE.YEWAI_JINGYING,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 65
                },
                {
                    name = "法师塔法师", -- 名字 需要在物编定义好
                    x = -14381, -- 小怪刷新x坐标
                    y = -12587, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 66
                },
                {
                    name = "法师塔术士", -- 名字 需要在物编定义好
                    x = -14381, -- 小怪刷新x坐标
                    y = -12587, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 66
                },
                {
                    name = "法师塔卫士", -- 名字 需要在物编定义好
                    x = -14381, -- 小怪刷新x坐标
                    y = -12587, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 66
                },
                {
                    name = "法师塔法师", -- 名字 需要在物编定义好
                    x = -15593, -- 小怪刷新x坐标
                    y = -12543, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 66
                },
                {
                    name = "法师塔术士", -- 名字 需要在物编定义好
                    x = -15593, -- 小怪刷新x坐标
                    y = -12543, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 66
                },
                {
                    name = "法师塔卫士", -- 名字 需要在物编定义好
                    x = -15593, -- 小怪刷新x坐标
                    y = -12543, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 66
                },
                {
                    name = "法师塔法师", -- 名字 需要在物编定义好
                    x = -15705, -- 小怪刷新x坐标
                    y = -11184, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 67
                },
                {
                    name = "法师塔术士", -- 名字 需要在物编定义好
                    x = -15705, -- 小怪刷新x坐标
                    y = -11184, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 67
                },
                {
                    name = "法师塔卫士", -- 名字 需要在物编定义好
                    x = -15705, -- 小怪刷新x坐标
                    y = -11184, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 67
                },
                {
                    name = "法师塔法师", -- 名字 需要在物编定义好
                    x = -14556, -- 小怪刷新x坐标
                    y = -11340, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 67
                },
                {
                    name = "法师塔术士", -- 名字 需要在物编定义好
                    x = -14556, -- 小怪刷新x坐标
                    y = -11340, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 67
                },
                {
                    name = "法师塔卫士", -- 名字 需要在物编定义好
                    x = -14556, -- 小怪刷新x坐标
                    y = -11340, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 67
                },
                {
                    name = "法师塔法师", -- 名字 需要在物编定义好
                    x = -13134, -- 小怪刷新x坐标
                    y = -11400, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 67
                },
                {
                    name = "法师塔术士", -- 名字 需要在物编定义好
                    x = -13134, -- 小怪刷新x坐标
                    y = -11400, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 67
                },
                {
                    name = "法师塔卫士", -- 名字 需要在物编定义好
                    x = -13134, -- 小怪刷新x坐标
                    y = -11400, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 67
                },
                {
                    name = "法师塔法师", -- 名字 需要在物编定义好
                    x = -13500, -- 小怪刷新x坐标
                    y = -9990, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 68
                },
                {
                    name = "法师塔术士", -- 名字 需要在物编定义好
                    x = -13500, -- 小怪刷新x坐标
                    y = -9990, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 68
                },
                {
                    name = "法师塔卫士", -- 名字 需要在物编定义好
                    x = -13500, -- 小怪刷新x坐标
                    y = -9990, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 68
                },
                {
                    name = "法师塔法师", -- 名字 需要在物编定义好
                    x = -13312, -- 小怪刷新x坐标
                    y = -8947, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 68
                },
                {
                    name = "法师塔术士", -- 名字 需要在物编定义好
                    x = -13312, -- 小怪刷新x坐标
                    y = -8947, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 68
                },
                {
                    name = "法师塔卫士", -- 名字 需要在物编定义好
                    x = -13312, -- 小怪刷新x坐标
                    y = -8947, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 68
                },
                {
                    name = "法师塔法师", -- 名字 需要在物编定义好
                    x = -14732, -- 小怪刷新x坐标
                    y = -9833, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 68
                },
                {
                    name = "法师塔术士", -- 名字 需要在物编定义好
                    x = -14732, -- 小怪刷新x坐标
                    y = -9833, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 68
                },
                {
                    name = "法师塔卫士", -- 名字 需要在物编定义好
                    x = -14732, -- 小怪刷新x坐标
                    y = -9833, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 68
                },
                {
                    name = "要塞斥候", -- 名字 需要在物编定义好
                    x = -9830, -- 小怪刷新x坐标
                    y = -20777, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 71
                },
                {
                    name = "要塞护卫军士", -- 名字 需要在物编定义好
                    x = -8940, -- 小怪刷新x坐标
                    y = -20528, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 71
                },
                {
                    name = "要塞护卫军士", -- 名字 需要在物编定义好
                    x = -8790, -- 小怪刷新x坐标
                    y = -21083, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 71
                },
                {
                    name = "虚空占卜者", -- 名字 需要在物编定义好
                    x = -8584, -- 小怪刷新x坐标
                    y = -20434, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 71
                },
                {
                    name = "虚空占卜者", -- 名字 需要在物编定义好
                    x = -8534, -- 小怪刷新x坐标
                    y = -19676, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 71
                },
                {
                    name = "虚空占卜者", -- 名字 需要在物编定义好
                    x = -7909, -- 小怪刷新x坐标
                    y = -19676, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 71
                },
                {
                    name = "虚空占卜者", -- 名字 需要在物编定义好
                    x = -8201, -- 小怪刷新x坐标
                    y = -20622, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 71
                },
                {
                    name = "要塞护卫军士", -- 名字 需要在物编定义好
                    x = -8201, -- 小怪刷新x坐标
                    y = -20622, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 71
                },
                {
                    name = "要塞斥候", -- 名字 需要在物编定义好
                    x = -7124, -- 小怪刷新x坐标
                    y = -20784, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 200,
                    level = 71
                },
                {
                    name = "要塞护卫军士", -- 名字 需要在物编定义好
                    x = -4440, -- 小怪刷新x坐标
                    y = -20130, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1200,
                    level = 71
                },
                {
                    name = "要塞护卫军士", -- 名字 需要在物编定义好
                    x = -4440, -- 小怪刷新x坐标
                    y = -20130, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1200,
                    level = 71
                },
                {
                    name = "要塞护卫军士", -- 名字 需要在物编定义好
                    x = -4440, -- 小怪刷新x坐标
                    y = -20130, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1200,
                    level = 71
                },
                {
                    name = "要塞护卫军士", -- 名字 需要在物编定义好
                    x = -4440, -- 小怪刷新x坐标
                    y = -20130, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1200,
                    level = 71
                },
                {
                    name = "要塞斥候", -- 名字 需要在物编定义好
                    x = -4440, -- 小怪刷新x坐标
                    y = -20130, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1200,
                    level = 71
                },
                {
                    name = "要塞斥候", -- 名字 需要在物编定义好
                    x = -4440, -- 小怪刷新x坐标
                    y = -20130, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1200,
                    level = 71
                },
                {
                    name = "要塞斥候", -- 名字 需要在物编定义好
                    x = -4440, -- 小怪刷新x坐标
                    y = -20130, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1200,
                    level = 71
                },
                {
                    name = "要塞斥候", -- 名字 需要在物编定义好
                    x = -4440, -- 小怪刷新x坐标
                    y = -20130, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1200,
                    level = 71
                },
                {
                    name = "虚空占卜者", -- 名字 需要在物编定义好
                    x = -4440, -- 小怪刷新x坐标
                    y = -20130, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1200,
                    level = 71
                },
                {
                    name = "虚空占卜者", -- 名字 需要在物编定义好
                    x = -4440, -- 小怪刷新x坐标
                    y = -20130, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1200,
                    level = 71
                },
                {
                    name = "虚空占卜者", -- 名字 需要在物编定义好
                    x = -4440, -- 小怪刷新x坐标
                    y = -20130, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1200,
                    level = 71
                },
                {
                    name = "恶魔卫士", -- 名字 需要在物编定义好
                    x = -7441, -- 小怪刷新x坐标
                    y = -13838, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 300,
                    level = 72
                },
                {
                    name = "黑暗术士", -- 名字 需要在物编定义好
                    x = -7441, -- 小怪刷新x坐标
                    y = -13838, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 300,
                    level = 72
                },
                {
                    name = "恶魔女妖", -- 名字 需要在物编定义好
                    x = -7441, -- 小怪刷新x坐标
                    y = -13838, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 300,
                    level = 72
                },
                {
                    name = "恶魔卫士", -- 名字 需要在物编定义好
                    x = -6300, -- 小怪刷新x坐标
                    y = -18073, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 300,
                    level = 72
                },
                {
                    name = "黑暗术士", -- 名字 需要在物编定义好
                    x = -6300, -- 小怪刷新x坐标
                    y = -18073, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 300,
                    level = 72
                },
                {
                    name = "恶魔女妖", -- 名字 需要在物编定义好
                    x = -6300, -- 小怪刷新x坐标
                    y = -18073, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 300,
                    level = 72
                },
                {
                    name = "恶魔卫士", -- 名字 需要在物编定义好
                    x = -3336, -- 小怪刷新x坐标
                    y = -18230, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 300,
                    level = 72
                },
                {
                    name = "黑暗术士", -- 名字 需要在物编定义好
                    x = -3336, -- 小怪刷新x坐标
                    y = -18230, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 300,
                    level = 72
                },
                {
                    name = "恶魔女妖", -- 名字 需要在物编定义好
                    x = -3336, -- 小怪刷新x坐标
                    y = -18230, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 300,
                    level = 72
                },
                {
                    name = "恶魔卫士", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "黑暗术士", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "恶魔女妖", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "恶魔卫士", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "黑暗术士", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "恶魔女妖", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "恶魔卫士", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "黑暗术士", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "恶魔女妖", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "恶魔卫士", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "黑暗术士", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "恶魔女妖", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "恶魔卫士", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "黑暗术士", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "恶魔女妖", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "恶魔卫士", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "黑暗术士", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "恶魔女妖", -- 名字 需要在物编定义好
                    x = -4637, -- 小怪刷新x坐标
                    y = -15705, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 2000,
                    level = 72
                },
                {
                    name = "恶魔狂战士", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔地狱火", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "末日弓箭手", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔狂战士", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔地狱火", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "末日弓箭手", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "末日护卫", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔狂战士", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔地狱火", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "末日弓箭手", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔狂战士", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔地狱火", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "末日弓箭手", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "末日护卫", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔狂战士", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔地狱火", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "末日弓箭手", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔狂战士", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔地狱火", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "末日弓箭手", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "末日护卫", -- 名字 需要在物编定义好
                    x = -9151, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔狂战士", -- 名字 需要在物编定义好
                    x = -5700, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔地狱火", -- 名字 需要在物编定义好
                    x = -5700, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "末日弓箭手", -- 名字 需要在物编定义好
                    x = -5700, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔狂战士", -- 名字 需要在物编定义好
                    x = -5700, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔地狱火", -- 名字 需要在物编定义好
                    x = -5700, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "末日弓箭手", -- 名字 需要在物编定义好
                    x = -5700, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "末日护卫", -- 名字 需要在物编定义好
                    x = -5700, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔狂战士", -- 名字 需要在物编定义好
                    x = -5700, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔地狱火", -- 名字 需要在物编定义好
                    x = -5700, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "末日弓箭手", -- 名字 需要在物编定义好
                    x = -5700, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔狂战士", -- 名字 需要在物编定义好
                    x = -5700, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "恶魔地狱火", -- 名字 需要在物编定义好
                    x = -5700, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "末日弓箭手", -- 名字 需要在物编定义好
                    x = -5700, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                },
                {
                    name = "末日护卫", -- 名字 需要在物编定义好
                    x = -5700, -- 小怪刷新x坐标
                    y = -10851, -- 小怪刷新y坐标
                    reborn = 120,
                    diaoluoConfig = diaoluoConfigForXSCW,
                    randomCreateDistance = 1700,
                    level = 73
                }
            },
            bosses = { {
                name = "荣誉护卫木羽", -- 名字 需要在物编定义好
                x = -15173, -- 小怪刷新x坐标
                y = -9332, -- 小怪刷新y坐标
                face = 180, -- 小怪朝向
                reborn = 180,
                diaoluoConfig = diaoluoConfigForXSCW,
                level = 69
            }, {
                name = "要塞护卫军士长", -- 名字 需要在物编定义好
                x = -2691, -- 小怪刷新x坐标
                y = -21061, -- 小怪刷新y坐标
                face = 90, -- 小怪朝向
                reborn = 180,
                diaoluoConfig = diaoluoConfigForXSCW,
                level = 71
            } },
            NPCs = {
                {
                    name = "兽人老兵火刃",
                    x = -12260,
                    y = -19783,
                    face = 270
                },
                {
                    name = "纳鲁",
                    x = -10600,
                    y = -15435,
                    face = 270
                },
                {
                    name = "冒险者工会会长",
                    x = -8769,
                    y = -17520,
                    face = 180
                },
                {
                    name = "虚空商人",
                    x = -8769,
                    y = -17011,
                    face = 180
                },
                {
                    name = "正义军需官",
                    x = -11117,
                    y = -16658,
                    face = 270
                },
                {
                    name = "秩序军需官",
                    x = -10930,
                    y = -16658,
                    face = 270
                },
                {
                    name = "秘法军需官",
                    x = -10743,
                    y = -16658,
                    face = 270
                },
                {
                    name = "魔能军需官",
                    x = -10556,
                    y = -16658,
                    face = 270
                },
                {
                    name = "邪恶军需官",
                    x = -10369,
                    y = -16658,
                    face = 270
                },
                {
                    name = "恶魔军需官",
                    x = -10182,
                    y = -16658,
                    face = 270
                },
                {
                    name = "辉煌军需官",
                    x = -9552,
                    y = -16658,
                    face = 270
                },
                {
                    name = "凯旋军需官",
                    x = -9365,
                    y = -16658,
                    face = 270
                },
                {
                    name = "法师叛徒瑞斯",
                    x = -14521,
                    y = -8749,
                    face = 270
                },
                {
                    name = "受伤的小黑子",
                    x = -15835,
                    y = -14632,
                    face = 90
                },
                {
                    name = "和平之城守卫",
                    x = -12747,
                    y = -12788,
                    face = 180,
                    nowShowInXiaoditu = true
                },
                {
                    name = "和平之城守卫",
                    x = -12943,
                    y = -13043,
                    face = 160,
                    nowShowInXiaoditu = true
                },
                {
                    name = "和平之城守卫",
                    x = -13042,
                    y = -15665,
                    face = 270,
                    nowShowInXiaoditu = true
                },
                {
                    name = "和平之城守卫",
                    x = -12990,
                    y = -16265,
                    face = 90,
                    nowShowInXiaoditu = true
                },
                {
                    name = "和平之城守卫",
                    x = -10900,
                    y = -17165,
                    face = 270,
                    nowShowInXiaoditu = true
                },
                {
                    name = "和平之城守卫",
                    x = -10576,
                    y = -17165,
                    face = 270,
                    nowShowInXiaoditu = true
                },
                {
                    name = "和平之城守卫",
                    x = -10252,
                    y = -17165,
                    face = 270,
                    nowShowInXiaoditu = true
                },
                {
                    name = "护卫队长彼得",
                    x = -10576,
                    y = -17634,
                    face = 90
                },
                {
                    name = "铭文大师德拉里",
                    x = -12328,
                    y = -17560,
                    face = 0
                },
                {
                    name = "老法师奥利弗",
                    x = -11114,
                    y = -15860,
                    face = 90
                },
                {
                    name = "传说中的钓鱼佬",
                    x = -12198,
                    y = -20595,
                    face = 0
                },
                {
                    name = "阿卡玛",
                    x = 8080,
                    y = -22290,
                    face = 225
                },
                {
                    name = "温蕾萨·风行者",
                    x = -5853,
                    y = -11090,
                    face = 270
                },
                {
                    name = "奥蕾莉亚·风行者",
                    x = -3104,
                    y = -22886,
                    face = 225
                }
            },
            ZIYUAN = {
                {
                    name = "精金矿",
                    x = -13155,
                    y = -21567,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.KUANGSHI
                },
                {
                    name = "精金矿",
                    x = -15859,
                    y = -19749,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.KUANGSHI
                },
                {
                    name = "精金矿",
                    x = -13578,
                    y = -10166,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.KUANGSHI
                },
                {
                    name = "汲血草药",
                    x = -14573,
                    y = -8832,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.CAOYAO
                },
                {
                    name = "汲血草药",
                    x = -15831,
                    y = -10477,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.CAOYAO
                },
                {
                    name = "汲血草药",
                    x = -14415,
                    y = -16519,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.CAOYAO
                },
                {
                    name = "汲血草药",
                    x = -6701,
                    y = -19806,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.CAOYAO
                },
                {
                    name = "精金矿",
                    x = -3960,
                    y = -18249,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.KUANGSHI
                },
                {
                    name = "和平之城钓鱼点",
                    x = -11595,
                    y = -20599,
                    caijiResourceType = CAIJI_RESOURCE_TYPE.DIAOYUDIAN
                }
            }
        }
    )
end
