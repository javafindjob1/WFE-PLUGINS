---@diagnostic disable: missing-parameter
table.insert(
    FUBEN_LIST,
    {
        name = "风暴要塞",
        setup = function()
            local nanduLevelConfig                  = {}
            nanduLevelConfig[FUBEN_NANDU.PUTONG]    = 71
            nanduLevelConfig[FUBEN_NANDU.YINGXIONG] = 71
            nanduLevelConfig[FUBEN_NANDU.SHISHI]    = 71
            nanduLevelConfig[FUBEN_NANDU.CHUANQI]   = 71

            local status                            = FUBEN_STATUS.KAIHUANG
            local juxingshengwu                     = {
                description = "要塞之主：生命最大值提高50%",
                attr_type = CONST_EVENT.attr,
                attr = _attr({ shengming_baifenbi = "+50" })
            }
            local emozhili                          = {
                description = "恶魔之力：生命最大值提高30%",
                attr_type = CONST_EVENT.attr,
                attr = _attr({ shengming_baifenbi = "+30" })
            }

            local huofenghuangAI                    = function(level, nandu)
                return UnitAI(
                    {
                        {
                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                name = "火球术",
                                --castCountLimit = 1, -- cast only x times per battle
                                minNandu = FUBEN_NANDU.PUTONG,
                                castCD = 0.1, -- nil or <=1 means 1 second
                                --healthBelowLimit = 65, -- only cast when health is < 65%
                                shifashijian = 2,
                                startEffect = function(evtData)
                                end,
                                --interval = 1,
                                periodEffect = function(evtData, curTimer)
                                end,
                                castDistance = 10000,
                                effect = function(evtData)
                                    local sourceUnit = evtData.triggerUnit
                                    local targetUnit = evtData.targetUnit
                                    hskillMoban.missile(
                                        {
                                            --model = "war3mapImported\\[SPELL]_115.mdl",
                                            model = "Abilities\\Weapons\\RedDragonBreath\\RedDragonMissile.mdl",
                                            scale = 1.0,
                                            speed = 900,
                                            hover = 50,
                                            sourceUnit = sourceUnit,
                                            targetUnit = targetUnit,
                                            target_face_dis = 50,
                                            onEnd = function(_, _, endX, endY)
                                                hskill.damage(
                                                    {
                                                        sourceUnit = sourceUnit,
                                                        targetUnit = targetUnit,
                                                        damage = 2 * hattr.get(sourceUnit, "attack", 0),
                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                        damageType = DAMAGE_TYPE.MOFA,
                                                        triggerSkill = hslk.n2i("AI技能模版"),
                                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                    }
                                                )
                                            end
                                        }
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
                )
            end

            local xiaoguaidiaoluo                   =
                DiaoLuoConfig(
                    {
                        {
                            list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                            drop_rate = {
                                --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                50,
                                50,
                                50,
                                0
                            }
                        }
                    }
                )

            local jinzhanai                         = function(level, nandu)
                return UnitAI(
                    {
                        {
                            aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                            }
                        }
                    }
                )
            end
            local chihouai                          = function(level, nandu)
                return UnitAI(
                    {
                        {
                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE
                                    .LOWEST_HEALTH_UNIT,
                                onlyInFight = true,
                                name = "驱散射击",
                                castCD = 15,
                                --castCountLimit = 1,
                                shifashijian = 2,
                                castDistance = 1000,
                                minNandu = FUBEN_NANDU.PUTONG,
                                --healthBelowLimit = 95, -- only cast when health is < 65%
                                notInterruptable = false,
                                skip_skill_speed = false,
                                customCondition = function(whichUnit)
                                    return true
                                end,
                                startEffect = function(evtData)
                                end,
                                effect = function(evtData)
                                    local sourceUnit = evtData
                                        .triggerUnit
                                    local targetUnit = evtData
                                        .targetUnit
                                    hskillMoban.missile(
                                        {
                                            --model = "war3mapImported\\[SPELL]_115.mdl",
                                            model =
                                            "BonefireArrow1.mdx",
                                            scale = 1.2,
                                            speed = 900,
                                            hover = 50,
                                            sourceUnit = sourceUnit,
                                            targetUnit = targetUnit,
                                            target_face_dis = 50,
                                            onEnd = function(
                                                _,
                                                _,
                                                endX,
                                                endY)
                                                hskill.damage(
                                                    {
                                                        sourceUnit =
                                                            sourceUnit,
                                                        targetUnit =
                                                            targetUnit,
                                                        damage = hattr
                                                            .get(
                                                                sourceUnit,
                                                                "attack",
                                                                0
                                                            ) * 3,
                                                        damageSrc =
                                                            CONST_DAMAGE_SRC.skill,
                                                        damageType =
                                                            DAMAGE_TYPE.WULI,
                                                        triggerSkill =
                                                            hslk.n2i(
                                                                "AI技能模版"
                                                            ),
                                                        damageElementType = {
                                                            CONST_DAMAGE_ELEMENT_TYPE.METAL
                                                        },
                                                        damageSpeedType =
                                                            CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                    }
                                                )
                                                hbuff.kongju(
                                                    evtData.targetUnit, 3)
                                            end
                                        }
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
                )
            end
            local fashiai                           = function(level, nandu)
                return UnitAI(
                    {
                        {
                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                name = "暗影箭",
                                --castCountLimit = 1, -- cast only x times per battle
                                minNandu = FUBEN_NANDU.PUTONG,
                                castCD = 0.1, -- nil or <=1 means 1 second
                                --healthBelowLimit = 65, -- only cast when health is < 65%
                                shifashijian = 2.5,
                                startEffect = function(evtData)
                                end,
                                --interval = 1,
                                periodEffect = function(evtData, curTimer)
                                end,
                                castDistance = 600,
                                effect = function(evtData)
                                    local sourceUnit = evtData.triggerUnit
                                    local targetUnit = evtData.targetUnit
                                    hskillMoban.missile(
                                        {
                                            --model = "war3mapImported\\[SPELL]_115.mdl",
                                            model =
                                            "war3mapImported\\[Spell]_1111_new.mdl",
                                            scale = 1,
                                            speed = 1200,
                                            hover = 50,
                                            sourceUnit = sourceUnit,
                                            targetUnit = targetUnit,
                                            target_face_dis = 50,
                                            onEnd = function(_, _, endX, endY)
                                                hskill.damage(
                                                    {
                                                        sourceUnit = sourceUnit,
                                                        targetUnit = targetUnit,
                                                        damage = hattr.get(
                                                            sourceUnit,
                                                            "attack",
                                                            0
                                                        ) * 1.5,
                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                        damageType = DAMAGE_TYPE.MOFA,
                                                        triggerSkill = hslk.n2i("AI技能模版"),
                                                        damageElementType = {
                                                            CONST_DAMAGE_ELEMENT_TYPE.DARK
                                                        },
                                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                            .IMMEDIATE
                                                    }
                                                )
                                            end
                                        }
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
                )
            end

            hfuben.buildFuben(
                {
                    name = "风暴要塞", --副本名字
                    status = status,
                    blp = "ReplaceableTextures\\xiaoditu\\UI_map_20.blp",
                    enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_20.blp",
                    nanduLevelConfig = nanduLevelConfig,                                     -- 副本难度以及级别需求,
                    entryPosition = { x = -2352, y = -21052 },
                    startPosition = { x = -72, y = -25319 },                                 --英雄进副本后位置
                    rectParam = { minX = -2300, minY = -30453, maxX = 7540, maxY = -24957 }, -- 副本区域
                    minions = {
                        {
                            name = "精英要塞护卫军士", -- 名字 需要在物编定义好
                            x = 64, -- 小怪刷新x坐标
                            y = -26174, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = jinzhanai
                        },
                        {
                            name = "精英虚空占卜者", -- 名字 需要在物编定义好
                            x = 64, -- 小怪刷新x坐标
                            y = -26474, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = fashiai
                        },
                        {
                            name = "精英要塞斥候", -- 名字 需要在物编定义好
                            x = 64, -- 小怪刷新x坐标
                            y = -26474, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = chihouai
                        },
                        {
                            name = "精英要塞护卫军士", -- 名字 需要在物编定义好
                            x = -1500, -- 小怪刷新x坐标
                            y = -27224, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = jinzhanai
                        },
                        {
                            name = "精英虚空占卜者", -- 名字 需要在物编定义好
                            x = -1500, -- 小怪刷新x坐标
                            y = -27224, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = fashiai
                        },
                        {
                            name = "精英要塞斥候", -- 名字 需要在物编定义好
                            x = -1500, -- 小怪刷新x坐标
                            y = -27224, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = chihouai
                        },
                        {
                            name = "精英要塞护卫军士", -- 名字 需要在物编定义好
                            x = 1673, -- 小怪刷新x坐标
                            y = -27130, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = jinzhanai
                        },
                        {
                            name = "精英虚空占卜者", -- 名字 需要在物编定义好
                            x = 1673, -- 小怪刷新x坐标
                            y = -27130, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = fashiai
                        },
                        {
                            name = "精英要塞斥候", -- 名字 需要在物编定义好
                            x = 1673, -- 小怪刷新x坐标
                            y = -27130, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = chihouai
                        },
                        {
                            name = "精英要塞护卫军士", -- 名字 需要在物编定义好
                            x = 9, -- 小怪刷新x坐标
                            y = -29691, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = jinzhanai
                        },
                        {
                            name = "精英虚空占卜者", -- 名字 需要在物编定义好
                            x = 9, -- 小怪刷新x坐标
                            y = -29691, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = fashiai
                        },
                        {
                            name = "精英要塞斥候", -- 名字 需要在物编定义好
                            x = -9, -- 小怪刷新x坐标
                            y = -29691, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = chihouai
                        },
                        {
                            name = "精英要塞护卫军士", -- 名字 需要在物编定义好
                            x = 2964, -- 小怪刷新x坐标
                            y = -28602, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = jinzhanai
                        },
                        {
                            name = "精英要塞斥候", -- 名字 需要在物编定义好
                            x = 3047, -- 小怪刷新x坐标
                            y = -27111, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = chihouai
                        },
                        {
                            name = "精英虚空占卜者", -- 名字 需要在物编定义好
                            x = 3047, -- 小怪刷新x坐标
                            y = -25907, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = fashiai
                        },
                        {
                            name = "精英要塞护卫军士", -- 名字 需要在物编定义好
                            x = 6430, -- 小怪刷新x坐标
                            y = -27765, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = jinzhanai
                        },
                        {
                            name = "精英要塞斥候", -- 名字 需要在物编定义好
                            x = 7073, -- 小怪刷新x坐标
                            y = -27765, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = chihouai
                        },
                        {
                            name = "精英虚空占卜者", -- 名字 需要在物编定义好
                            x = 5718, -- 小怪刷新x坐标
                            y = -27765, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = fashiai
                        },
                        {
                            name = "精英要塞护卫军士", -- 名字 需要在物编定义好
                            x = 4720, -- 小怪刷新x坐标
                            y = -28268, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = jinzhanai
                        },
                        {
                            name = "精英要塞斥候", -- 名字 需要在物编定义好
                            x = 4360, -- 小怪刷新x坐标
                            y = -27923, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = chihouai
                        },
                        {
                            name = "精英虚空占卜者", -- 名字 需要在物编定义好
                            x = 4360, -- 小怪刷新x坐标
                            y = -27923, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = fashiai
                        },
                    },
                    bosses = {
                        {
                            name = "奥",
                            x = 66,
                            y = -28269,
                            levelAdj = 0,
                            huixuedistance = 6000,
                            diaoluoConfig = DiaoLuoConfig(
                                {
                                    {
                                        list = BOSS_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            3000,
                                            3000,
                                            3000,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "炽热救赎圣典",
                                            "浴火指环",
                                            "凤凰指环",
                                            "虚空梦魇",
                                            "星界螺旋",
                                            "奥之爪",
                                            "燃烧的正义"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2100,
                                            2100,
                                            2100,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "烈日精华",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            200,
                                            500,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = function(level, nandu, count, fubenstatus)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "烈焰打击",
                                                healthBelowLimit = 100,
                                                healthAboveLimit = 50,
                                                skip_skill_speed = false,
                                                castDistance = 10000,
                                                --castCountLimit = 1,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 20,
                                                notInterruptable = false,
                                                --cast when life is below 50%
                                                castCD = 0.5, -- nil or <=1 means 1 second
                                                startEffect = function(evtData)
                                                    hbuff.addStackAttrBuff(CONST_DAMAGE_SRC.skill, evtData.triggerUnit,
                                                        "烈焰打击减伤", _attr({ jianshang = "+70" }), 30, 1,
                                                        "ReplaceableTextures\\CommandButtons\\BTNWallOfFire.blp",
                                                        "烈焰打击|n受到的伤害降低70%", true)
                                                end,
                                                endEffect = function(evtData)
                                                    hbuff.delete(evtData.triggerUnit, "烈焰打击减伤")
                                                end,
                                                interval = 1,
                                                customCondition = function(whichUnit)
                                                    if hgroup.isEmpty(hgroup.createEnermyGroupByUnit(whichUnit, 400)) then
                                                        return true
                                                    else
                                                        return false
                                                    end
                                                end,
                                                periodEffect = function(evtData)
                                                    heffect.xyz("war3mapImported\\[SPELL]_127.mdl",
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit), hunit.z(evtData.triggerUnit), 0, 1,
                                                        10, 10, 1)
                                                    hskillMoban.rectAOE(hunit.getRect(evtData.triggerUnit),
                                                        evtData.triggerUnit,
                                                        function(filterUnit)
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = evtData.triggerUnit,
                                                                    targetUnit = filterUnit,
                                                                    damage = hattribute.get(evtData.triggerUnit, "attack",
                                                                        10) * 0.3,
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                                                    shanghainame = "烈焰打击"
                                                                }
                                                            )
                                                            if nandu >= FUBEN_NANDU.YINGXIONG then
                                                                hbuff.addStackAttrBuff(CONST_DAMAGE_SRC.skill, filterUnit,
                                                                    "凤凰燃烧", _attr({ fire_yishang = "+3" }), 30, 99,
                                                                    "ReplaceableTextures\\CommandButtons\\BTNWallOfFire.blp",
                                                                    "凤凰燃烧|n每层使玩家受到火焰伤害提高3%", false)
                                                            end
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
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "飞舞",
                                                healthBelowLimit = 90,
                                                healthAboveLimit = 50,
                                                castDistance = 10000,
                                                --castCountLimit = 3,
                                                shifashijian = 2,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = true,
                                                --cast when life is below 50%
                                                castCD = 20, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local points = {
                                                        { x = -1071, y = -27608 },
                                                        { x = 1129,  y = -27608 },
                                                        { x = 12,    y = -29243 },
                                                    }
                                                    local function findRandomPointExceptNearest(xx, yy, points)
                                                        -- 计算每个点到(xx, yy)的距离，并存储在一个新的表中
                                                        local distancePoints = {}
                                                        for i, point in ipairs(points) do
                                                            local dx = point.x - xx
                                                            local dy = point.y - yy
                                                            local distance = math.sqrt(dx * dx + dy * dy)
                                                            table.insert(distancePoints,
                                                                { index = i, distance = distance })
                                                        end

                                                        -- 按距离排序
                                                        table.sort(distancePoints,
                                                            function(a, b) return a.distance < b.distance end)

                                                        -- 随机选择一个不是最近的点
                                                        local randomIndex = math.random(2, #distancePoints)
                                                        local selectedPointIndex = distancePoints[randomIndex].index

                                                        return points[selectedPointIndex]
                                                    end
                                                    local targetPoint = findRandomPointExceptNearest(
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit), points)
                                                    hcache.set(evtData.triggerUnit, "AI_SKILL_CASTING", true)
                                                    hskillMoban.leap(
                                                        {
                                                            skipPathCheck = true,
                                                            arrowUnit = evtData.triggerUnit,  -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                                                            sourceUnit = evtData.triggerUnit, --伤害来源（必须有！不管有没有伤害）
                                                            --targetUnit = targetUnit,         --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                                                            x = targetPoint.x,
                                                            y = targetPoint.y, --冲击的目标点（可选的，有目标点，那么冲击到点就结束）
                                                            speed = 20,        --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                                                            acceleration = 1,
                                                            shake = 0,         --摇摆振幅角度[-90~+90|random]（可选的，默认0)
                                                            filter = function(enum)
                                                                return hunit.isEnemy(evtData.triggerUnit, enum) and
                                                                    hunit.isAlive(enum)
                                                            end,                                --必须有
                                                            tokenArrowScale = 1.00,             --前冲的特效作为马甲冲击时的模型缩放
                                                            tokenArrowOpacity = 1.00,           --前冲的特效作为马甲冲击时的模型透明度[0-1]
                                                            tokenArrowHeight = 0.00,            --前冲的特效作为马甲冲击时的初始离地高度
                                                            effectMovement = nil,               --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                                            animateMovement = 1,
                                                            effectEnd = nil,                    --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                                            damageMovement = 0,                 --移动过程中的伤害（可选的，默认为0）
                                                            damageMovementRadius = 0,           --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
                                                            damageMovementRepeat = false,       --移动过程中伤害是否可以重复造成（可选的，默认为不能）
                                                            damageMovementDrag = false,         --移动过程是否拖拽敌人（可选的，默认为不能）
                                                            damageEndRadius = 0,                --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
                                                            damageSrc = CONST_DAMAGE_SRC.skill, --伤害的种类（可选）
                                                            damageEffect = nil,                 --伤害特效（可选）
                                                            damageType = DAMAGE_TYPE.WULI,
                                                            damageSkill = hslk.n2i("AI技能模版"),
                                                            oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
                                                            endDistance = 0,
                                                            onEnding = function(_, _, timePassed)
                                                                hcache.set(evtData.triggerUnit, "AI_SKILL_CASTING", false)
                                                            end
                                                        }
                                                    )
                                                    if nandu >= FUBEN_NANDU.SHISHI then
                                                        local tmpAttr =
                                                            hunit.getAttributeBasedOnOptions(
                                                                {
                                                                    level = level,
                                                                    attackSpace = hslk.n2v("奥的子嗣", "cool1"),
                                                                    guaiwuType = MONSTER_TYPE.FUBEN_XIAOGUAI,
                                                                    nandu = nandu,
                                                                    count = count
                                                                }
                                                            )
                                                        local tmpUnit =
                                                            henemy.create(
                                                                {
                                                                    id = hslk.n2i("奥的子嗣"),
                                                                    x = hunit.x(evtData.triggerUnit) +
                                                                        math.random(-100, 100),
                                                                    y = hunit.y(evtData.triggerUnit) +
                                                                        math.random(-100, 100),
                                                                    facing = math.random(0, 360),
                                                                    attr = tmpAttr,
                                                                    AI = huofenghuangAI(level, nandu),
                                                                    nandu = nandu,
                                                                    tuozhanshijian = 36000
                                                                }
                                                            )
                                                        hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                                                        hunit.setExpReward(tmpUnit, 0)
                                                    end
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "火之羽毛",
                                                castCD = 30,
                                                healthBelowLimit = 85,
                                                healthAboveLimit = 50,
                                                --castCountLimit = 1,
                                                shifashijian = 5,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = true,
                                                --skip_skill_speed = true,
                                                interval = 1,
                                                periodEffect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local missleFunc = function(target)
                                                        hskillMoban.missile(
                                                            {
                                                                --model = "war3mapImported\\[SPELL]_115.mdl",
                                                                model =
                                                                "war3mapImported\\Deadly Plumage HD Gold.mdx",
                                                                scale = 1.5,
                                                                speed = 800,
                                                                hover = 50,
                                                                sourceUnit = sourceUnit,
                                                                targetUnit = target,
                                                                target_face_dis = 50,
                                                                onEnd = function(_, _, endX, endY)
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = sourceUnit,
                                                                            targetUnit = target,
                                                                            damage = hattr.get(
                                                                                sourceUnit,
                                                                                "attack",
                                                                                0
                                                                            ) * 0.3,
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.MOFA,
                                                                            triggerSkill = hslk.n2i("AI技能模版"),
                                                                            damageElementType = {
                                                                                CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                            },
                                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                .IMMEDIATE
                                                                        }
                                                                    )
                                                                end
                                                            }
                                                        )
                                                    end
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(sourceUnit),
                                                        sourceUnit,
                                                        missleFunc
                                                    )
                                                end,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.RANDOM_ENERMY_UNIT,
                                                name = "流星陨石",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                castCD = 20,           -- nil or <=1 means 1 second
                                                healthBelowLimit = 40, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                castDistance = 10000,
                                                shifashijian = 2,
                                                startEffect = function(evtData)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                effect = function(evtData)
                                                    local whichUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local x = hunit.x(targetUnit)
                                                    local y = hunit.y(targetUnit)
                                                    local z = hunit.z(targetUnit)
                                                    hskillMoban.radiusWarning(x, y, z, 300, 1.25)
                                                    heffect.xyz("war3mapImported\\AZ_Kaer_D1.MDX", x, y, z, 1.25, 1)
                                                    local damage = hattribute.getWithLimit(whichUnit, nil, "attack", 0)
                                                    htime.setTimeout(
                                                        1.25,
                                                        function(curTimer)
                                                            hskillMoban.radiusAOE(
                                                                x,
                                                                y,
                                                                whichUnit,
                                                                300,
                                                                function(target)
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = whichUnit,
                                                                            targetUnit = target,
                                                                            damage = damage * 3,
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.MOFA,
                                                                            triggerSkill = hslk.n2i("AI技能模版"),
                                                                            damageElementType = {
                                                                                CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                            },
                                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                .IMMEDIATE
                                                                        }
                                                                    )
                                                                    hbuff.xuanyun(target, 2)
                                                                end
                                                            )
                                                            heffect.xyz(
                                                                "war3mapImported\\[Spell]_115_2.MDX",
                                                                x,
                                                                y,
                                                                z,
                                                                8,
                                                                1
                                                            )
                                                            local damageCount = 0
                                                            htime.setInterval(
                                                                1,
                                                                function(curTimer)
                                                                    if damageCount >= 6 then
                                                                        curTimer.destroy()
                                                                        return
                                                                    end
                                                                    damageCount = damageCount + 1
                                                                    hskillMoban.radiusAOE(
                                                                        x,
                                                                        y,
                                                                        whichUnit,
                                                                        300,
                                                                        function(target)
                                                                            hskill.damage(
                                                                                {
                                                                                    sourceUnit = whichUnit,
                                                                                    targetUnit = target,
                                                                                    damage = damage,
                                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                                    damageElementType = {
                                                                                        CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                                    },
                                                                                    damageSpeedType =
                                                                                        CONST_DAMAGE_SPEED_TYPE.DOT
                                                                                }
                                                                            )
                                                                        end
                                                                    )
                                                                end
                                                            )
                                                        end
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "烈焰冲锋",
                                                healthBelowLimit = 40,
                                                --healthAboveLimit = 50,
                                                castCountLimit = 1,
                                                shifashijian = 1,
                                                castDistance = 10000,
                                                notInterruptable = true,
                                                --cast when life is below 50%
                                                castCD = 15, -- nil or <=1 means 1 second
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    hbuff.update(
                                                        3 + nandu,
                                                        sourceUnit,
                                                        "烈焰冲锋",
                                                        true,
                                                        function()
                                                            hcache.set(sourceUnit, "AI_SKILL_EFFECT", true)
                                                        end,
                                                        function()
                                                            hcache.set(sourceUnit, "AI_SKILL_EFFECT", false)
                                                        end,
                                                        "ReplaceableTextures\\SHUSHI\\kongju.blp",
                                                        "烈焰冲锋|n每秒会对距离最远的单位进行冲锋，冲锋造成固定伤害，冲锋路径也会造成伤害！",
                                                        1,
                                                        1,
                                                        function(curTimer, buffHandle)
                                                            buffHandle.remainingTime =
                                                                buffHandle.remainingTime - buffHandle.interval
                                                            local targetUnit =
                                                                hfightzhuangtai.getFarestChouhengMubiao(sourceUnit)
                                                            if targetUnit == nil then
                                                                return
                                                            end
                                                            hunit.setAnimateSpeed(sourceUnit, 2.5, 0.5)
                                                            local e =
                                                                heffect.attach(
                                                                    "war3mapImported\\[Spell]_056.mdx",
                                                                    sourceUnit,
                                                                    "origin",
                                                                    0.8
                                                                )
                                                            hsound.voice2Unit(
                                                                hsound.voiceCreate(
                                                                    "resource\\war3mapImported\\sound\\chongfeng.wav",
                                                                    1000,
                                                                    true
                                                                ),
                                                                100,
                                                                sourceUnit
                                                            )
                                                            local damage = hattribute.getWithLimit(
                                                                evtData.triggerUnit,
                                                                nil,
                                                                "attack",
                                                                0
                                                            ) * 0.5
                                                            hskillMoban.leap(
                                                                {
                                                                    skipPathCheck = true,
                                                                    arrowUnit = sourceUnit,  -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                                                                    sourceUnit = sourceUnit, --伤害来源（必须有！不管有没有伤害）
                                                                    targetUnit = targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                                                                    speed = 25,              --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                                                                    acceleration = 1,
                                                                    shake = 0,               --摇摆振幅角度[-90~+90|random]（可选的，默认0)
                                                                    filter = function(enum)
                                                                        return hunit.isEnemy(evtData.triggerUnit,
                                                                                enum) and
                                                                            hunit.isAlive(enum)
                                                                    end,                                --必须有
                                                                    tokenArrowScale = 1.00,             --前冲的特效作为马甲冲击时的模型缩放
                                                                    tokenArrowOpacity = 1.00,           --前冲的特效作为马甲冲击时的模型透明度[0-1]
                                                                    tokenArrowHeight = 0.00,            --前冲的特效作为马甲冲击时的初始离地高度
                                                                    effectMovement = nil,               --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                                                    animateMovement = 1,
                                                                    effectEnd = nil,                    --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                                                    damageMovement = damage,            --移动过程中的伤害（可选的，默认为0）
                                                                    damageMovementRadius = 400,         --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
                                                                    damageMovementRepeat = false,       --移动过程中伤害是否可以重复造成（可选的，默认为不能）
                                                                    damageMovementDrag = false,         --移动过程是否拖拽敌人（可选的，默认为不能）
                                                                    damageEndRadius = 0,                --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
                                                                    damageSrc = CONST_DAMAGE_SRC.skill, --伤害的种类（可选）
                                                                    damageEffect = nil,                 --伤害特效（可选）
                                                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                    damageSkill = hslk.n2i("AI技能模版"),
                                                                    oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
                                                                    endDistance = 100,
                                                                    onEnding = function(_, _, timePassed)
                                                                    end
                                                                }
                                                            )
                                                        end,
                                                        nil,
                                                        nil,
                                                        HBUFF_UPDATE_MODE.OVERWRITE
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "烈焰打击",
                                                healthBelowLimit = 48,
                                                skip_skill_speed = false,
                                                castDistance = 10000,
                                                --castCountLimit = 1,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 20,
                                                notInterruptable = false,
                                                --cast when life is below 50%
                                                castCD = 20, -- nil or <=1 means 1 second
                                                startEffect = function(evtData)
                                                    hbuff.addStackAttrBuff(CONST_DAMAGE_SRC.skill, evtData.triggerUnit,
                                                        "烈焰打击减伤", _attr({ jianshang = "+70" }), 30, 1,
                                                        "ReplaceableTextures\\CommandButtons\\BTNWallOfFire.blp",
                                                        "烈焰打击|n受到的伤害降低70%", true)
                                                end,
                                                endEffect = function(evtData)
                                                    hbuff.delete(evtData.triggerUnit, "烈焰打击减伤")
                                                end,
                                                interval = 1,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                periodEffect = function(evtData)
                                                    heffect.xyz("war3mapImported\\[SPELL]_127.mdl",
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit), hunit.z(evtData.triggerUnit), 0, 1,
                                                        10, 10, 1)
                                                    hskillMoban.rectAOE(hunit.getRect(evtData.triggerUnit),
                                                        evtData.triggerUnit,
                                                        function(filterUnit)
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = evtData.triggerUnit,
                                                                    targetUnit = filterUnit,
                                                                    damage = hattribute.get(evtData.triggerUnit, "attack",
                                                                        10) * 0.3,
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                                                    shanghainame = "烈焰打击"
                                                                }
                                                            )
                                                            if nandu >= FUBEN_NANDU.YINGXIONG then
                                                                hbuff.addStackAttrBuff(CONST_DAMAGE_SRC.skill, filterUnit,
                                                                    "凤凰燃烧", _attr({ fire_yishang = "+3" }), 30, 99,
                                                                    "ReplaceableTextures\\CommandButtons\\BTNWallOfFire.blp",
                                                                    "凤凰燃烧|n每层使玩家受到火焰伤害提高3%", false)
                                                            end
                                                        end
                                                    )
                                                end,
                                                effect = function(evtData)
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
                                )
                            end,
                            passiveSkill = { {}, {}, {}, {} }
                        },
                        {
                            name = "大星术师",
                            x = 6409,
                            y = -26176,
                            recoveryDistance = 2000,
                            levelAdj = 0,
                            huixuedistance = 3000,
                            diaoluoConfig = DiaoLuoConfig(
                                {
                                    {
                                        list = BOSS_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            3000,
                                            3000,
                                            3000,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "终结锁链",
                                            "虚空之星",
                                            "黑暗咒术之环",
                                            "狡诈之盔",
                                            "光荣长靴",
                                            "星术士的蓝宝石",
                                            "星月坠饰",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2100,
                                            2100,
                                            2100,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "黑暗意志长靴",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            300,
                                            500,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "史诗黑暗意志长靴",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            0,
                                            300,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = function(level, nandu, count, fubenstatus, mijing)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "虚空解放",
                                                healthBelowLimit = 35,
                                                --healthAboveLimit = 50,
                                                castDistance = 10000,
                                                castCountLimit = 1,
                                                shifashijian = 1,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                notInterruptable = true,
                                                --cast when life is below 50%
                                                castCD = 20, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    hjapi.DzSetUnitModel(sourceUnit,
                                                        "war3mapImported\\VoidLord_big.mdx")
                                                    hjapi.DzSetUnitPortrait(sourceUnit,
                                                        "war3mapImported\\VoidLord_big.mdx")
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "群体暗影箭",
                                                healthBelowLimit = 35,
                                                --healthAboveLimit = 50,
                                                castDistance = 10000,
                                                --castCountLimit = 1,
                                                shifashijian = 2,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                notInterruptable = true,
                                                --cast when life is below 50%
                                                castCD = 0.1, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local missleFunc = function(target)
                                                        hskillMoban.missile(
                                                            {
                                                                --model = "war3mapImported\\[SPELL]_115.mdl",
                                                                model =
                                                                "war3mapImported\\[Spell]_1111_new.mdl",
                                                                scale = 1,
                                                                speed = 1200,
                                                                hover = 50,
                                                                sourceUnit = sourceUnit,
                                                                targetUnit = target,
                                                                target_face_dis = 50,
                                                                onEnd = function(_, _, endX, endY)
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = sourceUnit,
                                                                            targetUnit = target,
                                                                            damage = hattr.get(
                                                                                sourceUnit,
                                                                                "attack",
                                                                                0
                                                                            ),
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.MOFA,
                                                                            triggerSkill = hslk.n2i("AI技能模版"),
                                                                            damageElementType = {
                                                                                CONST_DAMAGE_ELEMENT_TYPE.DARK
                                                                            },
                                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                .IMMEDIATE
                                                                        }
                                                                    )
                                                                end
                                                            }
                                                        )
                                                    end
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(sourceUnit),
                                                        sourceUnit,
                                                        missleFunc
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "虚空传送门",
                                                --healthBelowLimit = 90,
                                                healthAboveLimit = 35,
                                                castDistance = 10000,
                                                --castCountLimit = 3,
                                                shifashijian = 2,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = true,
                                                --cast when life is below 50%
                                                castCD = 30, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local duration = 2 + nandu * 2
                                                    heffect.xyz(
                                                        "war3mapImported\\[AZ]chuansongmen.mdx", 6408,
                                                        -25274, hjapi.Z(6408, -25274), duration, 1)
                                                    heffect.xyz(
                                                        "war3mapImported\\[AZ]chuansongmen.mdx", 7368,
                                                        -26152, hjapi.Z(7368, -26152), duration, 1)
                                                    htime.setInterval(2, function(curTimer)
                                                        if curTimer.passedSec() >= (2 + nandu * 2) or hunit.isDestroyed(evtData.triggerUnit) then
                                                            curTimer.destroy()
                                                            return
                                                        end
                                                        local tmpAttr =
                                                            hunit.getAttributeBasedOnOptions(
                                                                {
                                                                    level = level,
                                                                    attackSpace = hslk.n2v("高阶护卫军士", "cool1"),
                                                                    guaiwuType = MONSTER_TYPE.FUBEN_XIAOGUAI,
                                                                    nandu = nandu,
                                                                    count = count,
                                                                    mijing = mijing
                                                                }
                                                            )
                                                        local tmpUnit =
                                                            henemy.create(
                                                                {
                                                                    id = hslk.n2i("高阶护卫军士"),
                                                                    x = 6408,
                                                                    y = -25274,
                                                                    facing = math.random(0, 360),
                                                                    attr = tmpAttr,
                                                                    AI = UnitAI(
                                                                        {
                                                                            {
                                                                                aiType = UNIT_AI_TYPE
                                                                                    .ATTACK_HIGEST_CHOUHENG,
                                                                                aiData = {
                                                                                    targetType = UNIT_AI_TARGET_TYPE
                                                                                        .HIGHEST_CHOUHENG_UNIT
                                                                                }
                                                                            }
                                                                        }
                                                                    ),
                                                                    nandu = nandu,
                                                                    tuozhanshijian = 36000
                                                                }
                                                            )
                                                        hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                                                        hunit.setExpReward(tmpUnit, 0)

                                                        local tmpAttr =
                                                            hunit.getAttributeBasedOnOptions(
                                                                {
                                                                    level = level,
                                                                    attackSpace = hslk.n2v("高阶虚空占卜者", "cool1"),
                                                                    guaiwuType = MONSTER_TYPE.FUBEN_XIAOGUAI,
                                                                    nandu = nandu,
                                                                    count = count
                                                                }
                                                            )
                                                        local tmpUnit =
                                                            henemy.create(
                                                                {
                                                                    id = hslk.n2i("高阶虚空占卜者"),
                                                                    x = 7368,
                                                                    y = -26152,
                                                                    facing = math.random(0, 360),
                                                                    attr = tmpAttr,
                                                                    AI = UnitAI(
                                                                        {
                                                                            {
                                                                                aiType = UNIT_AI_TYPE
                                                                                    .ATTACK_HIGEST_CHOUHENG,
                                                                                aiData = {
                                                                                    targetType = UNIT_AI_TARGET_TYPE
                                                                                        .HIGHEST_CHOUHENG_UNIT
                                                                                }
                                                                            }
                                                                        }
                                                                    ),
                                                                    nandu = nandu,
                                                                    tuozhanshijian = 36000
                                                                }
                                                            )
                                                        hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                                                        hunit.setExpReward(tmpUnit, 0)
                                                    end)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "星术师印记",
                                                --healthBelowLimit = 90,
                                                healthAboveLimit = 35,
                                                castDistance = 10000,
                                                --castCountLimit = 3,
                                                shifashijian = 0.5,
                                                minNandu = FUBEN_NANDU.SHISHI,
                                                notInterruptable = false,
                                                --cast when life is below 50%
                                                castCD = 3, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(evtData.triggerUnit),
                                                        evtData.triggerUnit,
                                                        function(filterUnit)
                                                            hbuff.addStackAttrBuff(CONST_DAMAGE_SRC.skill, filterUnit,
                                                                "星术师印记", _attr({ dark_yishang = "+5" }), 30, 99,
                                                                "ReplaceableTextures\\CommandButtons\\BTNWallOfFire.blp",
                                                                "星术师印记|n每层使玩家受到暗影伤害提高5%", false)
                                                        end
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                                name = "星术师的愤怒",
                                                --healthBelowLimit = 25,
                                                healthAboveLimit = 35,
                                                castDistance = 10000,
                                                --castCountLimit = 3,
                                                shifashijian = 2,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = true,
                                                --cast when life is below 50%
                                                castCD = 20, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local whichUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local attack = hattr.getWithLimit(whichUnit, nil, "attack", 0)
                                                    local damagePs = attack * 0.2
                                                    local damageBlast = attack * 0.8
                                                    heffect.attach(
                                                        "Abilities\\Spells\\Other\\SoulBurn\\SoulBurnbuff.mdl",
                                                        targetUnit,
                                                        "head",
                                                        6
                                                    )
                                                    hbuff.update(
                                                        6,
                                                        targetUnit,
                                                        "星术师的愤怒",
                                                        false,
                                                        function()
                                                        end,
                                                        function()
                                                            hskillMoban.radiusAOE(
                                                                hunit.x(targetUnit),
                                                                hunit.y(targetUnit),
                                                                whichUnit,
                                                                500,
                                                                function(target)
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = evtData.triggerUnit,
                                                                            targetUnit = target,
                                                                            damage = damageBlast,
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.MOFA,
                                                                            triggerSkill = hslk.n2i("AI技能模版"),
                                                                            damageElementType = {
                                                                                CONST_DAMAGE_ELEMENT_TYPE.DARK
                                                                            },
                                                                        }
                                                                    )
                                                                end
                                                            )
                                                            heffect.xyz(
                                                                "war3mapImported\\Slam.mdx",
                                                                hunit.x(targetUnit),
                                                                hunit.y(targetUnit),
                                                                hunit.z(targetUnit),
                                                                0,
                                                                1,
                                                                1.5,
                                                                1.5,
                                                                1.5
                                                            )
                                                        end,
                                                        "ReplaceableTextures\\CommandButtons\\BTNSoulBurn.blp",
                                                        "星术师的愤怒，每秒受到" ..
                                                        damagePs ..
                                                        "点暗影魔法伤害，倒计时结束后会爆炸。对周围500范围内的所有单位造成" ..
                                                        damageBlast ..
                                                        "点暗影魔法伤害",
                                                        1,
                                                        1,
                                                        function(curTimer, buffHandle)
                                                            buffHandle.remainingTime =
                                                                buffHandle.remainingTime - buffHandle.interval
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = evtData.triggerUnit,
                                                                    targetUnit = targetUnit,
                                                                    damage = damagePs,
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                                                                    damageElementType = {
                                                                        CONST_DAMAGE_ELEMENT_TYPE.DARK
                                                                    },
                                                                    triggerSkill = hslk.n2i("AI技能模版")
                                                                }
                                                            )
                                                        end,
                                                        nil,
                                                        nil,
                                                        HBUFF_UPDATE_MODE.OVERWRITE,
                                                        true
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "暗影箭",
                                                --healthBelowLimit = 90,
                                                healthAboveLimit = 35,
                                                castDistance = 10000,
                                                --castCountLimit = 3,
                                                shifashijian = 2,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = false,
                                                --cast when life is below 50%
                                                castCD = 0.1, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    hskillMoban.missile(
                                                        {
                                                            --model = "war3mapImported\\[SPELL]_115.mdl",
                                                            model =
                                                            "war3mapImported\\[Spell]_1111_new.mdl",
                                                            scale = 1,
                                                            speed = 1200,
                                                            hover = 50,
                                                            sourceUnit = sourceUnit,
                                                            targetUnit = targetUnit,
                                                            target_face_dis = 50,
                                                            onEnd = function(_, _, endX, endY)
                                                                hskill.damage(
                                                                    {
                                                                        sourceUnit = sourceUnit,
                                                                        targetUnit = targetUnit,
                                                                        damage = hattr.get(
                                                                            sourceUnit,
                                                                            "attack",
                                                                            0
                                                                        ) * 0.5,
                                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                                        damageType = DAMAGE_TYPE.MOFA,
                                                                        triggerSkill = hslk.n2i("AI技能模版"),
                                                                        damageElementType = {
                                                                            CONST_DAMAGE_ELEMENT_TYPE.DARK
                                                                        },
                                                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                            .IMMEDIATE
                                                                    }
                                                                )
                                                            end
                                                        }
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
                                )
                            end,
                            passiveSkill = { {}, {}, { emozhili }, { emozhili } }
                        },
                        {
                            name = "凯尔萨斯·逐日者",
                            x = 5565,
                            y = -29381,
                            levelAdj = 0,
                            recoveryDistance = 2000,
                            huixuedistance = 3000,
                            diaoluoConfig = DiaoLuoConfig(
                                {
                                    {
                                        list = BOSS_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            3000,
                                            3000,
                                            3000,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "凤凰双刃",
                                            "亵渎者护符",
                                            "欺诈指环",
                                            "游侠将军指环",
                                            "太阳王的权柄",
                                            "辛多雷金弓",
                                            "奎尔萨拉斯坠饰",
                                            "光荣护手",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2400,
                                            2400,
                                            2400,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "黑暗意志手套",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            300,
                                            500,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "史诗黑暗意志手套",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            0,
                                            300,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "翠绿魔珠",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "烈日精华",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "残破的烈焰之击",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "狂暴烈焰精华",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            500,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = function(level, nandu, count, fubenstatus, mijing)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                name = "召唤顾问",
                                                --healthBelowLimit = 90,
                                                --healthAboveLimit = 35,
                                                castDistance = 10000,
                                                onlyInFight = true,
                                                castCountLimit = 1,
                                                shifashijian = 0.1,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = true,
                                                --cast when life is below 50%
                                                castCD = 0.1, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = level,
                                                                attackSpace = hslk.n2v("首席技师泰隆尼卡斯", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_JINGYING,
                                                                nandu = nandu,
                                                                count = count,
                                                                mijing = mijing
                                                            }
                                                        )
                                                    local zhadannan =
                                                        henemy.create(
                                                            {
                                                                id = hslk.n2i("首席技师泰隆尼卡斯"),
                                                                x = 5101,
                                                                y = -29051,
                                                                facing = math.random(0, 360),
                                                                attr = tmpAttr,
                                                                AI = UnitAI(
                                                                    {
                                                                        {
                                                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                                                            aiData = {
                                                                                targetType = UNIT_AI_TARGET_TYPE
                                                                                    .HIGHEST_CHOUHENG_UNIT,
                                                                                name = "投掷炸弹",
                                                                                --healthBelowLimit = 90,
                                                                                --healthAboveLimit = 35,
                                                                                castDistance = 10000,
                                                                                --castCountLimit = 3,
                                                                                shifashijian = 1,
                                                                                minNandu = FUBEN_NANDU.PUTONG,
                                                                                notInterruptable = true,
                                                                                --cast when life is below 50%
                                                                                castCD = 0.1, -- nil or <=1 means 1 second
                                                                                customCondition = function(whichUnit)
                                                                                    return true
                                                                                end,
                                                                                startEffect = function(evtData)
                                                                                end,
                                                                                periodEffect = function(evtData)
                                                                                end,
                                                                                effect = function(evtData)
                                                                                    local sourceUnit = evtData
                                                                                        .triggerUnit
                                                                                    local targetUnit = evtData
                                                                                        .targetUnit
                                                                                    local x, y = hunit.x(targetUnit),
                                                                                        hunit.y(targetUnit)
                                                                                    local z = hunit.z(targetUnit)
                                                                                    hskillMoban.radiusWarning(
                                                                                        x,
                                                                                        y,
                                                                                        z,
                                                                                        300,
                                                                                        1
                                                                                    )
                                                                                    local distance = math.distance(x, y,
                                                                                        hunit.x(sourceUnit),
                                                                                        hunit.y(sourceUnit))
                                                                                    local speed = distance / 2
                                                                                    hskillMoban.missile(
                                                                                        {
                                                                                            --model = "war3mapImported\\[SPELL]_115.mdl",
                                                                                            model =
                                                                                            "war3mapImported\\hordebomb01_misslie.mdx",
                                                                                            scale = 1,
                                                                                            speed = speed,
                                                                                            hover = 50,
                                                                                            height = 300,
                                                                                            sourceUnit = sourceUnit,
                                                                                            targetX = x,
                                                                                            targetY = y,
                                                                                            target_face_dis = 50,
                                                                                            onEnd = function(_, _, endX,
                                                                                                             endY)
                                                                                                heffect.xyz(
                                                                                                    "[boss]zibao.mdx",
                                                                                                    endX,
                                                                                                    endY,
                                                                                                    hjapi.Z(endX, endY),
                                                                                                    0,
                                                                                                    1,
                                                                                                    0.6,
                                                                                                    0.6,
                                                                                                    0.6
                                                                                                )
                                                                                                hskillMoban.radiusAOE(
                                                                                                    endX, endY,
                                                                                                    sourceUnit, 300,
                                                                                                    function(target)
                                                                                                        hskill.damage(
                                                                                                            {
                                                                                                                sourceUnit =
                                                                                                                    sourceUnit,
                                                                                                                targetUnit =
                                                                                                                    target,
                                                                                                                damage =
                                                                                                                    hattr
                                                                                                                    .get(
                                                                                                                        sourceUnit,
                                                                                                                        "attack",
                                                                                                                        0
                                                                                                                    ) *
                                                                                                                    4,
                                                                                                                damageSrc =
                                                                                                                    CONST_DAMAGE_SRC.skill,
                                                                                                                damageType =
                                                                                                                    DAMAGE_TYPE.MOFA,
                                                                                                                triggerSkill =
                                                                                                                    hslk.n2i(
                                                                                                                        "AI技能模版"),
                                                                                                                damageElementType = {
                                                                                                                    CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                                                                },
                                                                                                                damageSpeedType =
                                                                                                                    CONST_DAMAGE_SPEED_TYPE
                                                                                                                    .IMMEDIATE
                                                                                                            }
                                                                                                        )
                                                                                                    end
                                                                                                )
                                                                                            end
                                                                                        }
                                                                                    )
                                                                                end
                                                                            }
                                                                        },
                                                                        {
                                                                            aiType = UNIT_AI_TYPE
                                                                                .ATTACK_HIGEST_CHOUHENG,
                                                                            aiData = {
                                                                                targetType = UNIT_AI_TARGET_TYPE
                                                                                    .HIGHEST_CHOUHENG_UNIT
                                                                            }
                                                                        }
                                                                    }
                                                                ),
                                                                nandu = nandu,
                                                                tuozhanshijian = 36000
                                                            }
                                                        )
                                                    hskill.add(zhadannan, hslk.n2i("AI技能模版"), 1, 0)
                                                    hunit.setExpReward(zhadannan, 0)

                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = level,
                                                                attackSpace = hslk.n2v("扭曲预言家萨拉瑞德", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_JINGYING,
                                                                nandu = nandu,
                                                                count = count
                                                            }
                                                        )
                                                    local ningshinan =
                                                        henemy.create(
                                                            {
                                                                id = hslk.n2i("扭曲预言家萨拉瑞德"),
                                                                x = 6390,
                                                                y = -29051,
                                                                facing = math.random(0, 360),
                                                                attr = tmpAttr,
                                                                AI = UnitAI(
                                                                    {
                                                                        {
                                                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                                                            aiData = {
                                                                                targetType = UNIT_AI_TARGET_TYPE
                                                                                    .RANDOM_ENERMY_UNIT,
                                                                                onlyInFight = true,
                                                                                name = "凝视",
                                                                                castCD = 10,
                                                                                --castCountLimit = 1,
                                                                                shifashijian = 2,
                                                                                castDistance = 1000,
                                                                                minNandu = FUBEN_NANDU.PUTONG,
                                                                                --healthBelowLimit = 95, -- only cast when health is < 65%
                                                                                notInterruptable = true,
                                                                                skip_skill_speed = true,
                                                                                customCondition = function(whichUnit)
                                                                                    return true
                                                                                end,
                                                                                startEffect = function(evtData)
                                                                                end,
                                                                                effect = function(evtData)
                                                                                    local sourceUnit = evtData
                                                                                        .triggerUnit
                                                                                    local targetUnit = evtData
                                                                                        .targetUnit
                                                                                    if nandu >= FUBEN_NANDU.SHISHI then
                                                                                        hevent.register(
                                                                                            sourceUnit,
                                                                                            CONST_EVENT.damagingCustomSource,
                                                                                            "伤害增强",
                                                                                            function(evtData)
                                                                                                evtData.damage =
                                                                                                    evtData.damage *
                                                                                                    20
                                                                                            end
                                                                                        )
                                                                                    end
                                                                                    hbuff.update(
                                                                                        10,
                                                                                        targetUnit,
                                                                                        "被凝视",
                                                                                        false,
                                                                                        function()
                                                                                        end,
                                                                                        function()
                                                                                        end,
                                                                                        "ReplaceableTextures\\SHUSHI\\kongju.blp",
                                                                                        "被凝视|n你被扭曲预言家萨拉瑞德盯上了，快跑！",
                                                                                        1,
                                                                                        nil,
                                                                                        nil,
                                                                                        nil,
                                                                                        nil,
                                                                                        HBUFF_UPDATE_MODE.OVERWRITE
                                                                                    )
                                                                                    hbuff.update(
                                                                                        10,
                                                                                        sourceUnit,
                                                                                        "追击",
                                                                                        true,
                                                                                        function()
                                                                                            hunitAI.disableAI(sourceUnit)
                                                                                        end,
                                                                                        function()
                                                                                            hunitAI.enableAI(sourceUnit)
                                                                                        end,
                                                                                        "ReplaceableTextures\\SHUSHI\\kongju.blp",
                                                                                        "追击|n萨拉瑞德会追击被凝视的人，并且造成的伤害提高！！！快跑！",
                                                                                        1,
                                                                                        0.5,
                                                                                        function(curTimer, buffHandle)
                                                                                            buffHandle.remainingTime =
                                                                                                buffHandle.remainingTime -
                                                                                                buffHandle.interval
                                                                                            if hbuff.hasBuff(targetUnit, "被凝视了") == false then
                                                                                                buffHandle.remainingTime = 0
                                                                                            else
                                                                                                cj.IssueTargetOrder(
                                                                                                    sourceUnit, "attack",
                                                                                                    targetUnit)
                                                                                            end
                                                                                        end,
                                                                                        nil,
                                                                                        nil,
                                                                                        HBUFF_UPDATE_MODE.OVERWRITE
                                                                                    )
                                                                                end
                                                                            }
                                                                        },
                                                                        {
                                                                            aiType = UNIT_AI_TYPE
                                                                                .ATTACK_HIGEST_CHOUHENG,
                                                                            aiData = {
                                                                                targetType = UNIT_AI_TARGET_TYPE
                                                                                    .HIGHEST_CHOUHENG_UNIT
                                                                            }
                                                                        }
                                                                    }
                                                                ),
                                                                nandu = nandu,
                                                                tuozhanshijian = 36000
                                                            }
                                                        )
                                                    hunitAI.disableAI(ningshinan)
                                                    hjapi.DzUnitDisableAttack(ningshinan,
                                                        true)
                                                    hunit.setInvulnerable(ningshinan,
                                                        true)
                                                    hattr.set(ningshinan, 0,
                                                        _attr({ move = "=0" }))
                                                    hskill.add(ningshinan, hslk.n2i("AI技能模版"), 1, 0)
                                                    hunit.setExpReward(ningshinan, 0)
                                                    -- cancel AI
                                                    local sourceUnit = evtData.triggerUnit
                                                    hunitAI.disableAI(sourceUnit)
                                                    hunit.setInvulnerable(sourceUnit, true)
                                                    hjapi.DzUnitDisableAttack(sourceUnit, true)
                                                    hattr.set(sourceUnit, 0, _attr({ move = "-600" }))
                                                    htime.setTimeout(20, function(t)
                                                        if hunit.isAlive(sourceUnit) == false then
                                                            return
                                                        end
                                                        if hunit.isAlive(ningshinan) then
                                                            hunitAI.enableAI(ningshinan)
                                                            hunit.setInvulnerable(ningshinan, false)
                                                            hjapi.DzUnitDisableAttack(ningshinan, false)
                                                            hattr.set(ningshinan, 0,
                                                                _attr({ move = "=400" }))
                                                        end
                                                    end)
                                                    htime.setTimeout(40, function(t)
                                                        if hunit.isAlive(sourceUnit) then
                                                            hunitAI.enableAI(sourceUnit)
                                                            hunit.setInvulnerable(sourceUnit, false)
                                                            hjapi.DzUnitDisableAttack(sourceUnit, false)
                                                            hattr.set(sourceUnit, 0, _attr({ move = "+600" }))
                                                        end
                                                    end)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                name = "复活顾问",
                                                healthBelowLimit = 35,
                                                --healthAboveLimit = 35,
                                                castDistance = 10000,
                                                onlyInFight = true,
                                                castCountLimit = 1,
                                                shifashijian = 2,
                                                minNandu = FUBEN_NANDU.SHISHI,
                                                notInterruptable = true,
                                                --cast when life is below 50%
                                                castCD = 0.1, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = level,
                                                                attackSpace = hslk.n2v("首席技师泰隆尼卡斯", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_JINGYING,
                                                                nandu = nandu,
                                                                count = count,
                                                                mijing = mijing
                                                            }
                                                        )
                                                    local zhadannan =
                                                        henemy.create(
                                                            {
                                                                id = hslk.n2i("首席技师泰隆尼卡斯"),
                                                                x = 5101,
                                                                y = -29051,
                                                                facing = math.random(0, 360),
                                                                attr = tmpAttr,
                                                                AI = UnitAI(
                                                                    {
                                                                        {
                                                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                                                            aiData = {
                                                                                targetType = UNIT_AI_TARGET_TYPE
                                                                                    .HIGHEST_CHOUHENG_UNIT,
                                                                                name = "投掷炸弹",
                                                                                --healthBelowLimit = 90,
                                                                                --healthAboveLimit = 35,
                                                                                castDistance = 10000,
                                                                                --castCountLimit = 3,
                                                                                shifashijian = 3,
                                                                                minNandu = FUBEN_NANDU.PUTONG,
                                                                                notInterruptable = true,
                                                                                --cast when life is below 50%
                                                                                castCD = 0.1, -- nil or <=1 means 1 second
                                                                                customCondition = function(whichUnit)
                                                                                    return true
                                                                                end,
                                                                                startEffect = function(evtData)
                                                                                end,
                                                                                periodEffect = function(evtData)
                                                                                end,
                                                                                effect = function(evtData)
                                                                                    local sourceUnit = evtData
                                                                                        .triggerUnit
                                                                                    local targetUnit = evtData
                                                                                        .targetUnit
                                                                                    local x, y = hunit.x(targetUnit),
                                                                                        hunit.y(targetUnit)
                                                                                    local z = hunit.z(targetUnit)
                                                                                    hskillMoban.radiusWarning(
                                                                                        x,
                                                                                        y,
                                                                                        z,
                                                                                        300,
                                                                                        1
                                                                                    )
                                                                                    local distance = math.distance(x, y,
                                                                                        hunit.x(sourceUnit),
                                                                                        hunit.y(sourceUnit))
                                                                                    local speed = distance / 2
                                                                                    hskillMoban.missile(
                                                                                        {
                                                                                            --model = "war3mapImported\\[SPELL]_115.mdl",
                                                                                            model =
                                                                                            "war3mapImported\\hordebomb01_misslie.mdx",
                                                                                            scale = 1,
                                                                                            speed = speed,
                                                                                            hover = 50,
                                                                                            height = 300,
                                                                                            sourceUnit = sourceUnit,
                                                                                            targetX = x,
                                                                                            targetY = y,
                                                                                            target_face_dis = 50,
                                                                                            onEnd = function(_, _, endX,
                                                                                                             endY)
                                                                                                heffect.xyz(
                                                                                                    "[boss]zibao.mdx",
                                                                                                    endX,
                                                                                                    endY,
                                                                                                    hjapi.Z(endX, endY),
                                                                                                    0,
                                                                                                    1,
                                                                                                    0.6,
                                                                                                    0.6,
                                                                                                    0.6
                                                                                                )
                                                                                                hskillMoban.radiusAOE(
                                                                                                    endX, endY,
                                                                                                    sourceUnit, 300,
                                                                                                    function(target)
                                                                                                        hskill.damage(
                                                                                                            {
                                                                                                                sourceUnit =
                                                                                                                    sourceUnit,
                                                                                                                targetUnit =
                                                                                                                    target,
                                                                                                                damage =
                                                                                                                    hattr
                                                                                                                    .get(
                                                                                                                        sourceUnit,
                                                                                                                        "attack",
                                                                                                                        0
                                                                                                                    ) *
                                                                                                                    3,
                                                                                                                damageSrc =
                                                                                                                    CONST_DAMAGE_SRC.skill,
                                                                                                                damageType =
                                                                                                                    DAMAGE_TYPE.MOFA,
                                                                                                                triggerSkill =
                                                                                                                    hslk.n2i(
                                                                                                                        "AI技能模版"),
                                                                                                                damageElementType = {
                                                                                                                    CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                                                                },
                                                                                                                damageSpeedType =
                                                                                                                    CONST_DAMAGE_SPEED_TYPE
                                                                                                                    .IMMEDIATE
                                                                                                            }
                                                                                                        )
                                                                                                    end
                                                                                                )
                                                                                            end
                                                                                        }
                                                                                    )
                                                                                end
                                                                            }
                                                                        },
                                                                        {
                                                                            aiType = UNIT_AI_TYPE
                                                                                .ATTACK_HIGEST_CHOUHENG,
                                                                            aiData = {
                                                                                targetType = UNIT_AI_TARGET_TYPE
                                                                                    .HIGHEST_CHOUHENG_UNIT
                                                                            }
                                                                        }
                                                                    }
                                                                ),
                                                                nandu = nandu,
                                                                tuozhanshijian = 36000
                                                            }
                                                        )
                                                    hskill.add(zhadannan, hslk.n2i("AI技能模版"), 1, 0)
                                                    hunit.setExpReward(zhadannan, 0)

                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = level,
                                                                attackSpace = hslk.n2v("扭曲预言家萨拉瑞德", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_JINGYING,
                                                                nandu = nandu,
                                                                count = count
                                                            }
                                                        )
                                                    local ningshinan =
                                                        henemy.create(
                                                            {
                                                                id = hslk.n2i("扭曲预言家萨拉瑞德"),
                                                                x = 6390,
                                                                y = -29051,
                                                                facing = math.random(0, 360),
                                                                attr = tmpAttr,
                                                                AI = UnitAI(
                                                                    {
                                                                        {
                                                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                                                            aiData = {
                                                                                targetType = UNIT_AI_TARGET_TYPE
                                                                                    .RANDOM_ENERMY_UNIT,
                                                                                onlyInFight = true,
                                                                                name = "凝视",
                                                                                castCD = 10,
                                                                                --castCountLimit = 1,
                                                                                shifashijian = 2,
                                                                                castDistance = 1000,
                                                                                minNandu = FUBEN_NANDU.PUTONG,
                                                                                --healthBelowLimit = 95, -- only cast when health is < 65%
                                                                                notInterruptable = true,
                                                                                skip_skill_speed = true,
                                                                                customCondition = function(whichUnit)
                                                                                    return true
                                                                                end,
                                                                                startEffect = function(evtData)
                                                                                end,
                                                                                effect = function(evtData)
                                                                                    local sourceUnit = evtData
                                                                                        .triggerUnit
                                                                                    local targetUnit = evtData
                                                                                        .targetUnit
                                                                                    if nandu >= FUBEN_NANDU.SHISHI then
                                                                                        hevent.register(
                                                                                            sourceUnit,
                                                                                            CONST_EVENT.damagingCustomSource,
                                                                                            "伤害增强",
                                                                                            function(evtData)
                                                                                                evtData.damage =
                                                                                                    evtData.damage *
                                                                                                    20
                                                                                            end
                                                                                        )
                                                                                    end
                                                                                    hbuff.update(
                                                                                        10,
                                                                                        targetUnit,
                                                                                        "被凝视",
                                                                                        false,
                                                                                        function()
                                                                                        end,
                                                                                        function()
                                                                                        end,
                                                                                        "ReplaceableTextures\\SHUSHI\\kongju.blp",
                                                                                        "被凝视|n你被扭曲预言家萨拉瑞德盯上了，快跑！",
                                                                                        1,
                                                                                        nil,
                                                                                        nil,
                                                                                        nil,
                                                                                        nil,
                                                                                        HBUFF_UPDATE_MODE.OVERWRITE
                                                                                    )
                                                                                    hbuff.update(
                                                                                        10,
                                                                                        sourceUnit,
                                                                                        "追击",
                                                                                        true,
                                                                                        function()
                                                                                            hunitAI.disableAI(sourceUnit)
                                                                                        end,
                                                                                        function()
                                                                                            hunitAI.enableAI(sourceUnit)
                                                                                        end,
                                                                                        "ReplaceableTextures\\SHUSHI\\kongju.blp",
                                                                                        "追击|n萨拉瑞德会追击被凝视的人，并且攻击力提高500%！！！快跑！",
                                                                                        1,
                                                                                        0.5,
                                                                                        function(curTimer, buffHandle)
                                                                                            buffHandle.remainingTime =
                                                                                                buffHandle.remainingTime -
                                                                                                buffHandle.interval
                                                                                            if hbuff.hasBuff(targetUnit, "被凝视了") == false then
                                                                                                buffHandle.remainingTime = 0
                                                                                            else
                                                                                                cj.IssueTargetOrder(
                                                                                                    sourceUnit, "attack",
                                                                                                    targetUnit)
                                                                                            end
                                                                                        end,
                                                                                        nil,
                                                                                        nil,
                                                                                        HBUFF_UPDATE_MODE.OVERWRITE
                                                                                    )
                                                                                end
                                                                            }
                                                                        },
                                                                        {
                                                                            aiType = UNIT_AI_TYPE
                                                                                .ATTACK_HIGEST_CHOUHENG,
                                                                            aiData = {
                                                                                targetType = UNIT_AI_TARGET_TYPE
                                                                                    .HIGHEST_CHOUHENG_UNIT
                                                                            }
                                                                        }
                                                                    }
                                                                ),
                                                                nandu = nandu,
                                                                tuozhanshijian = 36000
                                                            }
                                                        )
                                                    hskill.add(ningshinan, hslk.n2i("AI技能模版"), 1, 0)
                                                    hunit.setExpReward(ningshinan, 0)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "召唤奥的子嗣",
                                                healthBelowLimit = 50,
                                                --healthAboveLimit = 50,
                                                castDistance = 10000,
                                                castCountLimit = 1,
                                                shifashijian = 2,
                                                onlyInFight = true,
                                                minNandu = FUBEN_NANDU.SHISHI,
                                                notInterruptable = true,
                                                --cast when life is below 50%
                                                castCD = 1, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = level,
                                                                attackSpace = hslk.n2v("奥的子嗣", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_JINGYING,
                                                                nandu = nandu,
                                                                count = count
                                                            }
                                                        )
                                                    local fenghuang =
                                                        henemy.create(
                                                            {
                                                                id = hslk.n2i("奥的子嗣"),
                                                                x = 5655,
                                                                y = -29085,
                                                                facing = math.random(0, 360),
                                                                attr = tmpAttr,
                                                                AI = UnitAI(
                                                                    {
                                                                        {
                                                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                                                            aiData = {
                                                                                targetType = UNIT_AI_TARGET_TYPE
                                                                                    .HIGHEST_CHOUHENG_UNIT,
                                                                                name = "烈焰爆发",
                                                                                --healthBelowLimit = 90,
                                                                                --healthAboveLimit = 35,
                                                                                castDistance = 10000,
                                                                                --castCountLimit = 1,
                                                                                shifashijian = 3,
                                                                                minNandu = FUBEN_NANDU.PUTONG,
                                                                                notInterruptable = true,
                                                                                --cast when life is below 50%
                                                                                castCD = 5, -- nil or <=1 means 1 second
                                                                                customCondition = function(whichUnit)
                                                                                    return true
                                                                                end,
                                                                                startEffect = function(evtData)
                                                                                    hskillMoban.radiusWarning(
                                                                                        hunit.x(evtData.triggerUnit),
                                                                                        hunit.y(evtData.triggerUnit),
                                                                                        hunit.z(evtData.triggerUnit),
                                                                                        300,
                                                                                        3
                                                                                    )
                                                                                end,
                                                                                periodEffect = function(evtData)
                                                                                end,
                                                                                effect = function(evtData)
                                                                                    local radius = 300
                                                                                    if hbuff.hasBuff(sourceUnit, "魔力失控") then
                                                                                        heffect.xyz("[Spell]_127.mdx",
                                                                                            hunit.x(evtData.triggerUnit),
                                                                                            hunit.y(evtData.triggerUnit),
                                                                                            hunit.z(evtData.triggerUnit),
                                                                                            0, 1,
                                                                                            10, 10, 1)
                                                                                        radius = 2000
                                                                                    else
                                                                                        heffect.xyz("[Spell]_127.mdx",
                                                                                            hunit.x(evtData.triggerUnit),
                                                                                            hunit.y(evtData.triggerUnit),
                                                                                            hunit.z(evtData.triggerUnit),
                                                                                            0, 1,
                                                                                            1, 1, 1)
                                                                                    end
                                                                                    hskillMoban.radiusAOE(
                                                                                        hunit.x(evtData.triggerUnit),
                                                                                        hunit.y(evtData.triggerUnit),
                                                                                        evtData.triggerUnit,
                                                                                        radius,
                                                                                        function(target)
                                                                                            hskill.damage(
                                                                                                {
                                                                                                    sourceUnit =
                                                                                                        sourceUnit,
                                                                                                    targetUnit = target,
                                                                                                    damage = hattr
                                                                                                        .get(
                                                                                                            sourceUnit,
                                                                                                            "attack",
                                                                                                            0
                                                                                                        ) * 10,
                                                                                                    damageSrc =
                                                                                                        CONST_DAMAGE_SRC.skill,
                                                                                                    damageType =
                                                                                                        DAMAGE_TYPE.MOFA,
                                                                                                    damageElementType = {
                                                                                                        CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                                                    },
                                                                                                    triggerSkill = hslk
                                                                                                        .n2i(
                                                                                                            "AI技能模版"
                                                                                                        ),
                                                                                                    damageSpeedType =
                                                                                                        CONST_DAMAGE_SPEED_TYPE
                                                                                                        .IMMEDIATE
                                                                                                })
                                                                                        end
                                                                                    )
                                                                                end
                                                                            }
                                                                        },
                                                                        {
                                                                            aiType = UNIT_AI_TYPE
                                                                                .ATTACK_HIGEST_CHOUHENG,
                                                                            aiData = {
                                                                                targetType = UNIT_AI_TARGET_TYPE
                                                                                    .HIGHEST_CHOUHENG_UNIT
                                                                            }
                                                                        }
                                                                    }
                                                                ),
                                                                nandu = nandu,
                                                                tuozhanshijian = 36000
                                                            }
                                                        )
                                                    hskill.add(fenghuang, hslk.n2i("AI技能模版"), 1, 0)
                                                    hunit.setExpReward(fenghuang, 0)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "火焰气息",
                                                healthBelowLimit = 40,
                                                --healthAboveLimit = 35,
                                                castDistance = 10000,
                                                castCountLimit = 1,
                                                shifashijian = 2,
                                                onlyInFight = true,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = false,
                                                --cast when life is below 50%
                                                castCD = 0.1, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    hbuff.update(
                                                        -1,
                                                        sourceUnit,
                                                        "火焰气息",
                                                        true,
                                                        function()
                                                        end,
                                                        function()
                                                        end,
                                                        "ReplaceableTextures\\CommandButtons\\BTNSleep.blp",
                                                        "火焰气息|n火焰气息每秒对周围所有敌人造成火系魔法持续伤害",
                                                        1,
                                                        1,
                                                        function(curTimer, buffHandle)
                                                            buffHandle.remainingTime = buffHandle.remainingTime -
                                                                buffHandle.interval
                                                            heffect.attach(
                                                                "Abilities\\Spells\\Other\\Incinerate\\IncinerateBuff.mdl",
                                                                filterUnit, "head", 0.1)
                                                            hskillMoban.rectAOE(
                                                                hunit.getRect(sourceUnit),
                                                                sourceUnit,
                                                                function(filterUnit)
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = sourceUnit,
                                                                            targetUnit = filterUnit,
                                                                            damage = 600 + nandu * 200,
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.MOFA,
                                                                            triggerSkill = hslk.n2i("AI技能模版"),
                                                                            damageElementType = {
                                                                                CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                            },
                                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                .DOT
                                                                        }
                                                                    )
                                                                end)
                                                        end,
                                                        nil,
                                                        nil,
                                                        HBUFF_UPDATE_MODE.OVERWRITE
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType       = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name             = "魔力失控",
                                                healthBelowLimit = 30,
                                                --healthAboveLimit = 30,
                                                castDistance     = 10000,
                                                castCountLimit   = 1,
                                                shifashijian     = 10,
                                                onlyInFight      = true,
                                                minNandu         = FUBEN_NANDU.PUTONG,
                                                notInterruptable = true,
                                                skip_skill_speed = true,
                                                --cast when life is below 50%
                                                castCD           = 30, -- nil or <=1 means 1 second
                                                customCondition  = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect      = function(evtData)
                                                    local e = heffect.attach("war3mapImported\\redchakra.MDX",
                                                        evtData.triggerUnit, "origin", -1)
                                                    hbuff.update(
                                                        -1,
                                                        evtData.triggerUnit,
                                                        "魔力失控",
                                                        false,
                                                        function()
                                                            hevent.register(
                                                                evtData.triggerUnit,
                                                                CONST_EVENT.damagingCustomTarget,
                                                                "魔力失控",
                                                                function(evtData)
                                                                    evtData.damage = evtData.damage * 1.5
                                                                end
                                                            )
                                                        end,
                                                        function()
                                                            hevent.unregister(
                                                                evtData.triggerUnit,
                                                                CONST_EVENT.damagingCustomTarget,
                                                                "魔力失控"
                                                            )
                                                            heffect.destroy(e)
                                                        end,
                                                        "ReplaceableTextures\\BTN_FS_06.blp",
                                                        "魔力失控|n魔力失控使得单位受到的所有伤害提高50%，同时溢出的能量会刺激奥的子嗣，使得其烈焰爆发技能效果变为全屏高额伤害",
                                                        1,
                                                        nil, nil, nil, nil, HBUFF_UPDATE_MODE.OVERWRITE
                                                    )
                                                    hcache.set(evtData.triggerUnit, "魔力失控", true)
                                                end,
                                                endEffect        = function(evtData)
                                                    hbuff.delete(evtData.triggerUnit, "魔力失控")
                                                end,
                                                periodEffect     = function(evtData)
                                                end,
                                                effect           = function(evtData)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "炎爆术",
                                                healthBelowLimit = 80,
                                                --healthAboveLimit = 35,
                                                castDistance = 10000,
                                                --castCountLimit = 1,
                                                shifashijian = 10,
                                                skip_skill_speed = false,
                                                onlyInFight = true,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = false,
                                                --cast when life is below 50%
                                                castCD = 20, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    local whichUnit = evtData.triggerUnit
                                                    local huduneffect = heffect.attach(
                                                        "war3mapImported\\AZ_MagicShield_Gold.mdl", whichUnit, "origin",
                                                        -1)
                                                    hbuff.update(
                                                        15,
                                                        whichUnit,
                                                        "烈焰护盾",
                                                        true,
                                                        nil,
                                                        function()
                                                            heffect.destroy(huduneffect)
                                                        end,
                                                        hslk.i2v(hslk.n2i("烈焰护盾"), "Art"),
                                                        "吸收5%最大生命值的伤害",
                                                        1,
                                                        nil,
                                                        nil,
                                                        nil,
                                                        nil,
                                                        HBUFF_UPDATE_MODE.CREATE_ONLY,
                                                        true,
                                                        hunit.getMaxLife(whichUnit) * 0.05
                                                    )
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    hskillMoban.missile(
                                                        {
                                                            model = "war3mapImported\\[SPELL]_115.mdl",
                                                            scale = 1,
                                                            speed = 900,
                                                            hover = 50,
                                                            sourceUnit = sourceUnit,
                                                            targetUnit = targetUnit,
                                                            target_face_dis = 50,
                                                            onEnd = function(_, _, endX, endY)
                                                                hskill.damage(
                                                                    {
                                                                        sourceUnit = sourceUnit,
                                                                        targetUnit = targetUnit,
                                                                        damage = hattr.get(sourceUnit, "attack", 0) * 30,
                                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                                        damageType = DAMAGE_TYPE.MOFA,
                                                                        triggerSkill = hslk.n2i("AI技能模版"),
                                                                        damageElementType = {
                                                                            CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                        },
                                                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                            .IMMEDIATE
                                                                    }
                                                                )
                                                            end
                                                        }
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.RANDOM_ENERMY_UNIT,
                                                name = "烈焰风暴",
                                                healthBelowLimit = 90,
                                                --healthAboveLimit = 35,
                                                castDistance = 10000,
                                                --castCountLimit = 1,
                                                shifashijian = 3,
                                                onlyInFight = true,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = true,
                                                --cast when life is below 50%
                                                castCD = 15, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    hskillMoban.radiusWarning(
                                                        hunit.x(evtData.targetUnit),
                                                        hunit.y(evtData.targetUnit),
                                                        hunit.z(evtData.targetUnit),
                                                        300,
                                                        1
                                                    )
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    heffect.xyz("AZ_F034.mdx",
                                                        evtData.targetX,
                                                        evtData.targetY,
                                                        hjapi.Z(evtData.targetX,
                                                            evtData.targetY),
                                                        0,
                                                        1, 1.3, 1.3, 1.3)
                                                    hskillMoban.radiusAOE(
                                                        evtData.targetX,
                                                        evtData.targetY,
                                                        sourceUnit,
                                                        300,
                                                        function(target)
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = sourceUnit,
                                                                    targetUnit = target,
                                                                    damage = hattr.get(sourceUnit, "attack", 0) * 5,
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                    damageElementType = {
                                                                        CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                    },
                                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                        .IMMEDIATE
                                                                }
                                                            )
                                                        end
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "火球术",
                                                --healthBelowLimit = 90,
                                                --healthAboveLimit = 35,
                                                castDistance = 10000,
                                                --castCountLimit = 1,
                                                shifashijian = 2,
                                                onlyInFight = true,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = false,
                                                --cast when life is below 50%
                                                castCD = 0.1, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    hskillMoban.missile(
                                                        {
                                                            --model = "war3mapImported\\[SPELL]_115.mdl",
                                                            model =
                                                            "Abilities\\Weapons\\RedDragonBreath\\RedDragonMissile.mdl",
                                                            scale = 1,
                                                            speed = 800,
                                                            hover = 50,
                                                            sourceUnit = sourceUnit,
                                                            targetUnit = targetUnit,
                                                            target_face_dis = 50,
                                                            onEnd = function(_, _, endX, endY)
                                                                hskill.damage(
                                                                    {
                                                                        sourceUnit = sourceUnit,
                                                                        targetUnit = targetUnit,
                                                                        damage = hattr.get(sourceUnit, "attack", 0) * 1,
                                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                                        damageType = DAMAGE_TYPE.MOFA,
                                                                        triggerSkill = hslk.n2i("AI技能模版"),
                                                                        damageElementType = {
                                                                            CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                        },
                                                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                            .IMMEDIATE
                                                                    }
                                                                )
                                                            end
                                                        }
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
                                )
                            end,
                            passiveSkill = { { juxingshengwu }, { juxingshengwu }, { juxingshengwu }, { juxingshengwu } }
                        }
                    },
                    tongguanjiangli = {
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,       value = 3000 },
                                { type = HSHOP_COST_TYPE.experience, value = 15000 },
                            },
                            shengwang = {
                                {
                                    value = 500,
                                    maxLevel = 1,
                                    shengwangname = "和平之城"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,         value = 4000 },
                                { type = HSHOP_COST_TYPE.mifahuizhang, value = 1 },
                                { type = HSHOP_COST_TYPE.experience,   value = 18000 },
                            },
                            shengwang = {
                                {
                                    value = 500,
                                    maxLevel = 2,
                                    shengwangname = "和平之城"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,           value = 5000 },
                                { type = HSHOP_COST_TYPE.mifahuizhang,   value = 1 },
                                { type = HSHOP_COST_TYPE.monenghuizhang, value = 1 },
                                { type = HSHOP_COST_TYPE.experience,     value = 20000 },
                            },
                            shengwang = {
                                {
                                    value = 500,
                                    maxLevel = 3,
                                    shengwangname = "和平之城"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,           value = 6000 },
                                { type = HSHOP_COST_TYPE.monenghuizhang, value = 2 },
                                { type = HSHOP_COST_TYPE.experience,     value = 25000 },
                            },
                            shengwang = {
                                {
                                    value = 500,
                                    maxLevel = 2,
                                    shengwangname = "和平之城"
                                }
                            }
                        }
                    }
                }
            )
        end
    }
)
