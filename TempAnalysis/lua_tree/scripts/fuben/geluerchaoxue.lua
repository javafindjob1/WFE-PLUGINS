table.insert(
    FUBEN_LIST,
    {
        name = "屠龙者的巢穴",
        setup = function()
            local nanduLevelConfig                  = {}
            nanduLevelConfig[FUBEN_NANDU.PUTONG]    = 65
            nanduLevelConfig[FUBEN_NANDU.YINGXIONG] = 70
            nanduLevelConfig[FUBEN_NANDU.SHISHI]    = 70
            nanduLevelConfig[FUBEN_NANDU.CHUANQI]   = 71

            local juxingshengwu                     = {
                description = "巨型生物：生命最大值提高100%",
                attr_type = CONST_EVENT.attr,
                attr = _attr({ shengming_baifenbi = "+100" })
            }

            local status                            = FUBEN_STATUS.JIANHUA

            hfuben.buildFuben(
                {
                    name = "屠龙者的巢穴", --副本名字
                    status = status,
                    blp = "ReplaceableTextures\\xiaoditu\\UI_map_17.blp",
                    enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_17.blp",
                    nanduLevelConfig = nanduLevelConfig,                                    -- 副本难度以及级别需求,
                    entryPosition = { x = -15839, y = -21487 },
                    startPosition = { x = 892, y = -18970 },                                --英雄进副本后位置
                    rectParam = { minX = -566, minY = -19196, maxX = 2236, maxY = -16482 }, -- 副本区域
                    minions = {},
                    bosses = {
                        {
                            name = "屠龙者格鲁",
                            x = 836,
                            y = -17496,
                            levelAdj = 0,
                            huixuedistance = 3000,
                            diaoluoConfig = DiaoLuoConfig(
                                {
                                    {
                                        list = BOSS_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            0,
                                            0,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "龙脊奖章",
                                            "格鲁尔之眼",
                                            "刀塔作战手套",
                                            "古加尔的项圈",
                                            "食人魔法师野蛮披风",
                                            "莫加尔战盔",
                                            "戈隆之王锁链",
                                            "血喉魔剑",
                                            "纳鲁之锤",
                                            "纷争勇士披风"
                                        }, --物品名字 需要在物编定义好
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
                                            "远征军斗篷"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            300,
                                            0,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "先锋远征军斗篷"
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
                                            "屠龙者之血"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            200,
                                            500,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "屠龙者的心脏"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            200,
                                            500,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "远古巨龙之筋"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            0,
                                            0,
                                            500
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
                                                name = "成长",
                                                castCD = 10,
                                                --castCountLimit = 1,
                                                shifashijian = 0.5,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 95, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "我要变得更强！！!",
                                                        10,
                                                        "eae30a",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    local whichUnit = evtData.triggerUnit
                                                    hbuff.addStackAttrBuff(
                                                        CONST_DAMAGE_SRC.skill,
                                                        whichUnit,
                                                        "成长",
                                                        _attr({ quanju_zengshang = "+5" }),
                                                        120,
                                                        30,
                                                        hslk.n2v("天神下凡", "Art"),
                                                        "成长，每层提高5%所有伤害，最大叠加30次",
                                                        true
                                                    )
                                                    local stack = hbuff.getStack(whichUnit, "成长")
                                                    local scale = 1 + 0.05 * stack
                                                    cj.SetUnitScale(whichUnit, scale, scale, scale)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                                name = "落石术",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                castCD = 10,           -- nil or <=1 means 1 second
                                                healthBelowLimit = 90, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                castDistance = 10000,
                                                shifashijian = 1,
                                                customCondition = function(whichUnit)
                                                    local canCastLuoshi = true
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(whichUnit),
                                                        whichUnit,
                                                        function(target)
                                                            if hbuff.getStack(target, "巨人领主的扣握") >= 1 then
                                                                canCastLuoshi = false
                                                            end
                                                        end
                                                    )
                                                    return canCastLuoshi
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                effect = function(evtData)
                                                    local whichUnit = evtData.triggerUnit
                                                    local duration = 30
                                                    if nandu >= FUBEN_NANDU.SHISHI then
                                                        duration = duration + 50
                                                    end
                                                    local x = evtData.targetX
                                                    local y = evtData.targetY
                                                    local z = hjapi.Z(x, y)
                                                    local warningEffect = hskillMoban.radiusWarning(x, y, z, 300,
                                                        duration)
                                                    htime.setInterval(
                                                        1,
                                                        function(curTimer)
                                                            if curTimer.passedSec() == 1 then
                                                                heffect.xyz(
                                                                    "war3mapImported\\Rock_2024618.mdx",
                                                                    x,
                                                                    y,
                                                                    z,
                                                                    0,
                                                                    1
                                                                )
                                                                return
                                                            end
                                                            if curTimer.passedSec() > duration or hunit.isAlive(whichUnit) == false then
                                                                curTimer.destroy()
                                                                heffect.destroy(warningEffect)
                                                                return
                                                            end
                                                            if curTimer.passedSec() < duration then
                                                                heffect.xyz(
                                                                    "war3mapImported\\Rock_2024618.mdx",
                                                                    x,
                                                                    y,
                                                                    z,
                                                                    0,
                                                                    1
                                                                )
                                                            end

                                                            local damage =
                                                                hattribute.getWithLimit(whichUnit, nil, "attack", 0)
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
                                                                                CONST_DAMAGE_ELEMENT_TYPE.EARTH
                                                                            },
                                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                .DOT
                                                                        }
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
                                                targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                                name = "粉碎",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                castCD = 10,           -- nil or <=1 means 1 second
                                                healthBelowLimit = 90, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                castDistance = 10000,
                                                shifashijian = 4,
                                                customCondition = function(whichUnit)
                                                    local canCastFensui = false
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(whichUnit),
                                                        whichUnit,
                                                        function(target)
                                                            if hbuff.getStack(target, "巨人领主的扣握") >= 1 then
                                                                canCastFensui = true
                                                            end
                                                        end
                                                    )
                                                    return canCastFensui
                                                end,
                                                startEffect = function(evtData)
                                                    hsound.voice2Unit(
                                                        hsound.voiceCreate(
                                                            "resource\\war3mapImported\\sound\\warning.wav",
                                                            1000,
                                                            true
                                                        ),
                                                        100,
                                                        evtData.triggerUnit
                                                    )
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "粉碎！！！",
                                                        10,
                                                        "eae30a",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                    --[[hskillMoban.rectAOE(
                                                        hunit.getRect(evtData.triggerUnit),
                                                        evtData.triggerUnit,
                                                        function(target)
                                                            hskillMoban.radiusWarning(
                                                                hunit.x(target),
                                                                hunit.y(target),
                                                                hunit.z(target),
                                                                500,
                                                                evtData.shifashijian
                                                            )
                                                        end
                                                    )]]
                                                    hunit.setAnimateSpeed(
                                                        evtData.triggerUnit,
                                                        2 / evtData.shifashijian,
                                                        evtData.shifashijian
                                                    )
                                                    hunit.animate(evtData.triggerUnit, 9)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                effect = function(evtData)
                                                    local whichUnit = evtData.triggerUnit
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(whichUnit),
                                                        whichUnit,
                                                        function(target)
                                                            hbuff.delete(target, "巨人领主的扣握")
                                                            heffect.xyz(
                                                                "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl",
                                                                hunit.x(target),
                                                                hunit.y(target),
                                                                hunit.z(target),
                                                                0,
                                                                1,
                                                                nil,
                                                                nil,
                                                                nil,
                                                                nil,
                                                                nil,
                                                                nil
                                                            )
                                                            hskillMoban.radiusAOE(
                                                                hunit.x(target),
                                                                hunit.y(target),
                                                                whichUnit,
                                                                500,
                                                                function(finalTarget)
                                                                    local damage = hunit.getMaxLife(finalTarget) * 0.3
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = whichUnit,
                                                                            targetUnit = finalTarget,
                                                                            damage = damage,
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.MOFA,
                                                                            triggerSkill = hslk.n2i("AI技能模版"),
                                                                            damageElementType = {
                                                                                CONST_DAMAGE_ELEMENT_TYPE.EARTH
                                                                            },
                                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                .IMMEDIATE
                                                                        }
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
                                                targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                                name = "猛击",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                castCD = 30,           -- nil or <=1 means 1 second
                                                healthBelowLimit = 90, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                castDistance = 10000,
                                                shifashijian = 1,
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "真是一堆烦人的虫子",
                                                        10,
                                                        "eae30a",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                    hunit.setAnimateSpeed(
                                                        evtData.triggerUnit,
                                                        3 / evtData.shifashijian,
                                                        evtData.shifashijian
                                                    )
                                                    hunit.animate(evtData.triggerUnit, 4)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                effect = function(evtData)
                                                    local whichUnit = evtData.triggerUnit
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(whichUnit),
                                                        whichUnit,
                                                        function(target)
                                                            local damage =
                                                                hattribute.getWithLimit(whichUnit, nil, "attack", 0)
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = whichUnit,
                                                                    targetUnit = target,
                                                                    damage = damage,
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.WULI,
                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                    damageElementType = {
                                                                        CONST_DAMAGE_ELEMENT_TYPE.EARTH
                                                                    },
                                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                                }
                                                            )
                                                            heffect.xyz(
                                                                "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl",
                                                                hunit.x(target),
                                                                hunit.y(target),
                                                                hunit.z(target),
                                                                0,
                                                                1,
                                                                nil,
                                                                nil,
                                                                nil,
                                                                nil,
                                                                nil,
                                                                nil
                                                            )
                                                            htime.setInterval(
                                                                0.3,
                                                                function(curTimer)
                                                                    if (curTimer.passedSec() > 3) then
                                                                        curTimer.destroy()
                                                                        return
                                                                    end
                                                                    if hunit.isAlive(target) then
                                                                        hbuff.addStackAttrBuff(
                                                                            CONST_DAMAGE_SRC.skill,
                                                                            target,
                                                                            "巨人领主的扣握",
                                                                            _attr({ move = "-30" }),
                                                                            10,
                                                                            10,
                                                                            "ReplaceableTextures\\CommandButtons\\BTNThunderclap.blp",
                                                                            "巨人领主的扣握，每0.3秒叠加一层，每层降低30移动速度，最大叠加10次。受到粉碎的伤害会移除此效果",
                                                                            false
                                                                        )
                                                                    end
                                                                end
                                                            )
                                                            hskillMoban.crackFly(
                                                                {
                                                                    sourceUnit = whichUnit,
                                                                    targetUnit = target,
                                                                    model = nil,
                                                                    animate = "dead",
                                                                    animateScale = 1,
                                                                    distance = 600,
                                                                    height = 400,
                                                                    duration = 1.5,
                                                                    onEndAnyway = function(sourceUnit, targetUnit, point)
                                                                        heffect.xyz(
                                                                            "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl",
                                                                            hunit.x(targetUnit),
                                                                            hunit.y(targetUnit),
                                                                            hunit.z(targetUnit),
                                                                            0,
                                                                            1,
                                                                            nil,
                                                                            nil,
                                                                            nil,
                                                                            nil,
                                                                            nil,
                                                                            nil
                                                                        )
                                                                        local damage =
                                                                            hattribute.getWithLimit(
                                                                                whichUnit,
                                                                                nil,
                                                                                "attack",
                                                                                0
                                                                            )
                                                                        hskill.damage(
                                                                            {
                                                                                sourceUnit = sourceUnit,
                                                                                targetUnit = target,
                                                                                damage = damage,
                                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                                damageType = DAMAGE_TYPE.WULI,
                                                                                triggerSkill = hslk.n2i("AI技能模版"),
                                                                                damageElementType = {
                                                                                    CONST_DAMAGE_ELEMENT_TYPE.EARTH
                                                                                },
                                                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                    .IMMEDIATE
                                                                            }
                                                                        )
                                                                        hunit.setFlyHeight(targetUnit, 0, 9999)
                                                                    end
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
                                                targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                                name = "回响",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                castCD = 30,           -- nil or <=1 means 1 second
                                                healthBelowLimit = 60, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                castDistance = 10000,
                                                shifashijian = 2,
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "我最讨厌读条的虫子了",
                                                        10,
                                                        "eae30a",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                    hunit.setAnimateSpeed(
                                                        evtData.triggerUnit,
                                                        2 / evtData.shifashijian,
                                                        evtData.shifashijian
                                                    )
                                                    hunit.animate(evtData.triggerUnit, 9)
                                                    hsound.voice2Unit(
                                                        hsound.voiceCreate(
                                                            "resource\\war3mapImported\\sound\\warning.wav",
                                                            1000,
                                                            true
                                                        ),
                                                        100,
                                                        evtData.triggerUnit
                                                    )
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                effect = function(evtData)
                                                    local whichUnit = evtData.triggerUnit
                                                    heffect.xyz(
                                                        "war3mapImported\\[Spell]_032.mdx",
                                                        hunit.x(whichUnit),
                                                        hunit.y(whichUnit),
                                                        hunit.z(whichUnit),
                                                        0,
                                                        1,
                                                        5,
                                                        5,
                                                        1
                                                    )
                                                    local damage =
                                                        hattribute.getWithLimit(whichUnit, nil, "attack", 0) * 10
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(whichUnit),
                                                        whichUnit,
                                                        function(target)
                                                            if hskill.isUnitCasting(target) then
                                                                hbuff.xuanyun(target, 5)
                                                                hskill.damage(
                                                                    {
                                                                        sourceUnit = whichUnit,
                                                                        targetUnit = target,
                                                                        damage = damage,
                                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                                        damageType = DAMAGE_TYPE.WULI,
                                                                        triggerSkill = hslk.n2i("AI技能模版"),
                                                                        damageElementType = {
                                                                            CONST_DAMAGE_ELEMENT_TYPE.EARTH
                                                                        },
                                                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                            .IMMEDIATE
                                                                    }
                                                                )
                                                            end
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
                                )
                            end,
                            passiveSkill = { { juxingshengwu }, { juxingshengwu }, { juxingshengwu }, { juxingshengwu } }
                        }
                    },
                    tongguanjiangli = {
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold, value = 1000 }
                            },
                            shengwang = {
                                {
                                    value = 500,
                                    maxLevel = 0,
                                    shengwangname = "和平之城"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,            value = 1500 },
                                { type = HSHOP_COST_TYPE.zhengyihuizhang, value = 1 }
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
                                { type = HSHOP_COST_TYPE.gold,            value = 3000 },
                                { type = HSHOP_COST_TYPE.zhengyihuizhang, value = 1 }
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
                                { type = HSHOP_COST_TYPE.gold, value = 4000 }
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
