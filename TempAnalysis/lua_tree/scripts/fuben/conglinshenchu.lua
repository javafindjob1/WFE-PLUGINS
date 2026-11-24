table.insert(
    FUBEN_LIST,
    {
        name = "丛林深处",
        setup = function()
            local nanduLevelConfig = {}
            nanduLevelConfig[FUBEN_NANDU.PUTONG] = 15
            nanduLevelConfig[FUBEN_NANDU.YINGXIONG] = 15
            --nanduLevelConfig[FUBEN_NANDU.SHISHI] = 15
            nanduLevelConfig[FUBEN_NANDU.CHUANQI] = 60
            local xiaoguaiDiaoluoList = {
                "戒指",
                "项链",
                "披风",
                "手套",
                "衣服",
                "头盔",
                "鞋子",
                "法器"
            }
            local bossDiaoluoList = {
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
                "饰品"
            }

            local yelangsiyao = {
                description = "攻击有30%概率撕裂伤口，造成持续6秒的伤害加深效果，每层效果使得目标在受到伤害时额外受到5点伤害，可以叠加并刷新时间",
                attr_type = CONST_EVENT.attack,
                attr = function(evtData)
                    if math.random(1, 100) <= 30 then
                        hsound.voice2Unit(
                            hsound.voiceCreate("resource\\war3mapImported\\sound\\silie.wav", 1000, true),
                            100,
                            evtData.targetUnit
                        )
                        local damagePerStack = 5
                        hbuff.update(
                            6,
                            evtData.targetUnit,
                            "野狼撕咬",
                            false,
                            function()
                                hevent.register(
                                    evtData.targetUnit,
                                    CONST_EVENT.damagingCustomTarget,
                                    "野狼撕咬",
                                    function(anotherEvtdata)
                                        local buffhandle = hbuff.getBuffHandle(evtData.targetUnit, "野狼撕咬")
                                        if buffhandle == nil then
                                            return
                                        else
                                            local stack = buffhandle.stack or 0
                                            anotherEvtdata.damage = anotherEvtdata.damage + damagePerStack * stack
                                        end
                                    end
                                )
                            end,
                            function()
                                hevent.unregister(evtData.targetUnit, CONST_EVENT.damagingCustomTarget, "野狼撕咬")
                            end,
                            "ReplaceableTextures\\PASBTNKT_009.blp",
                            "野狼撕咬，每层会使得受到的任意伤害增加5点，或许等buff消了再上是个不错的注意。",
                            1,
                            1,
                            function(curTimer, buffHandle)
                                buffHandle.remainingTime = buffHandle.remainingTime - 1
                            end,
                            function(buffHandle)
                                buffHandle.remainingTime = 6
                                buffHandle.stack =
                                    buffHandle.stack + hcache.get(evtData.triggerUnit, CONST_CACHE.UNIT_NANDU, 1)
                            end,
                            nil,
                            HBUFF_UPDATE_MODE.UPDATE,
                            true
                        )
                    end
                end
            }
            local tielanghuixue = {
                description = "受到直接伤害有30%概率恢复1%+30最大生命值，最大恢复20000，CD5秒",
                attr_type = CONST_EVENT.beDamage,
                attr = function(evtData)
                    if
                        evtData.damageSpeedType == CONST_DAMAGE_SPEED_TYPE.IMMEDIATE and math.random(1, 100) <= 30 and
                        htime.setupAndCheckCoolDown(evtData.triggerUnit, "铁狼回血", 5)
                    then
                        local whichUnit = evtData.triggerUnit
                        hskill.heal(
                            {
                                healer = whichUnit,
                                healee = whichUnit,
                                heal = math.min(math.floor(hunit.getMaxLife(whichUnit) * 0.01) + 50, 20000),
                                healType = HEAL_TYPE.SKILL,
                                triggerSkill = hslk.n2i("AI技能模版")
                            }
                        )
                    end
                end
            }

            hfuben.buildFuben(
                {
                    name = "丛林深处", --副本名字
                    status = FUBEN_STATUS.JIANHUA,
                    blp = "ReplaceableTextures\\xiaoditu\\UI_map_04.blp",
                    enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_06.blp",
                    nanduLevelConfig = nanduLevelConfig,                                  -- 副本难度以及级别需求,
                    entryPosition = { x = -25396, y = -31243 },
                    startPosition = { x = -31272, y = 5514 },                             --英雄进副本后位置
                    rectParam = { minX = -31929, minY = 5000, maxX = -26548, maxY = 8100 }, -- 副本区域
                    minions = {
                        -- 小怪设定
                        {
                            name = "野狼", -- 名字 需要在物编定义好
                            x = -31379, -- 小怪刷新x坐标
                            y = 6455, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { {}, { yelangsiyao }, { yelangsiyao }, { yelangsiyao } }
                        },
                        {
                            name = "野狼", -- 名字 需要在物编定义好
                            x = -31110, -- 小怪刷新x坐标
                            y = 7504, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { {}, { yelangsiyao }, { yelangsiyao }, { yelangsiyao } }
                        },
                        {
                            name = "野狼", -- 名字 需要在物编定义好
                            x = -29791, -- 小怪刷新x坐标
                            y = 7490, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { {}, { yelangsiyao }, { yelangsiyao }, { yelangsiyao } }
                        },
                        {
                            name = "精英野狼", -- 名字 需要在物编定义好
                            x = -29791, -- 小怪刷新x坐标
                            y = 7490, -- 小怪刷新y坐标
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2000,
                                            2000,
                                            2000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { yelangsiyao }, { yelangsiyao }, { yelangsiyao }, { yelangsiyao } }
                        },
                        {
                            name = "野狼", -- 名字 需要在物编定义好
                            x = -28553, -- 小怪刷新x坐标
                            y = 5634, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { {}, { yelangsiyao }, { yelangsiyao }, { yelangsiyao } }
                        },
                        {
                            name = "精英野狼", -- 名字 需要在物编定义好
                            x = -28553, -- 小怪刷新x坐标
                            y = 5634, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2000,
                                            2000,
                                            2000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { yelangsiyao }, { yelangsiyao }, { yelangsiyao }, { yelangsiyao } }
                        },
                        {
                            name = "精英野狼", -- 名字 需要在物编定义好
                            x = -27231, -- 小怪刷新x坐标
                            y = 5745, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2000,
                                            2000,
                                            2000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { yelangsiyao }, { yelangsiyao }, { yelangsiyao }, { yelangsiyao } }
                        },
                        {
                            name = "巨狼", -- 名字 需要在物编定义好
                            x = -27231, -- 小怪刷新x坐标
                            y = 5745, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2000,
                                            2000,
                                            2000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { yelangsiyao }, { yelangsiyao }, { yelangsiyao }, { yelangsiyao } }
                        }
                    },
                    bosses = {
                        -- boss设定
                        {
                            name = "铁狼",
                            x = -29997,
                            y = 6212,
                            levelAdj = 0,
                            diaoluoConfig = DiaoLuoConfig(
                                {
                                    {
                                        list = bossDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            10000,
                                            10000,
                                            10000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "狼皮衣", "锋利巨斧", "森林长弓" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            3000,
                                            3000,
                                            3000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "魔物精魄" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            500,
                                            1000,
                                            2000,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = UnitAI(
                                {
                                    {
                                        aiType = UNIT_AI_TYPE.CAST_SKILL,
                                        aiData = {
                                            targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                            minNandu = FUBEN_NANDU.PUTONG,
                                            name = "猛扑",
                                            --castCountLimit = 1, -- cast only x times per battle
                                            castCD = 8, -- nil or <=1 means 1 second
                                            startEffect = function(evtData)
                                                hskillMoban.radiusWarning(
                                                    hunit.x(evtData.targetUnit),
                                                    hunit.y(evtData.targetUnit),
                                                    hunit.z(evtData.targetUnit),
                                                    200,
                                                    2
                                                )
                                            end,
                                            periodEffect = function(evtData)
                                            end,
                                            effect = function(evtData)
                                                hskillMoban.leap(
                                                    {
                                                        arrowUnit = evtData.triggerUnit,  -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                                                        sourceUnit = evtData.triggerUnit, --伤害来源（必须有！不管有没有伤害）
                                                        --  targetUnit = evtData.targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                                                        x = evtData.targetX,
                                                        y = evtData.targetY,
                                                        speed = 25, --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                                                        acceleration = 0,
                                                        height = 200,
                                                        shake = 0, --摇摆振幅角度[-90~+90|random]（可选的，默认0)
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
                                                        onEnding = function(endX, endY, timePassed)
                                                            hskillMoban.radiusAOE(
                                                                endX,
                                                                endY,
                                                                evtData.triggerUnit,
                                                                200,
                                                                function(target)
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = evtData.triggerUnit,
                                                                            targetUnit = target,
                                                                            damage = hattribute.getWithLimit(
                                                                                evtData.triggerUnit,
                                                                                nil,
                                                                                "attack",
                                                                                0
                                                                            ) * 3,
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.WULI,
                                                                            triggerSkill = hslk.n2i("AI技能模版")
                                                                        }
                                                                    )
                                                                    hbuff.xuanyun(target, 2)
                                                                end
                                                            )
                                                        end
                                                    }
                                                )
                                            end,
                                            shifashijian = 2
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
                            passiveSkill = {
                                {
                                    yelangsiyao,
                                    tielanghuixue
                                },
                                {
                                    yelangsiyao,
                                    tielanghuixue
                                },
                                {
                                    yelangsiyao,
                                    tielanghuixue
                                },
                                {
                                    yelangsiyao,
                                    tielanghuixue
                                }
                            }
                        },
                        {
                            name = "银月狼王",
                            x = -28549,
                            y = 7343,
                            levelAdj = 0,
                            diaoluoConfig = DiaoLuoConfig(
                                {
                                    {
                                        list = bossDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            10000,
                                            10000,
                                            10000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "染血利刃", "狼牙戒指", "银月之心" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            3000,
                                            3000,
                                            3000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "魔物精魄" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            2000,
                                            4000,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = function(level, nandu)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "银月之力",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                castCD = 15,           -- nil or <=1 means 1 second
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 65, -- only cast when health is < 65%
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
                                                end,
                                                interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                    local timePassed = curTimer.passedSec()
                                                    local aoeSize = 350 + (timePassed - 1) * 250
                                                    if timePassed <= 1 then
                                                        return
                                                    end
                                                    local scale = aoeSize / 350
                                                    heffect.xyz(
                                                        "war3mapImported\\[Spell]_032.mdx",
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit),
                                                        hunit.z(evtData.triggerUnit),
                                                        0,
                                                        1,
                                                        scale,
                                                        scale,
                                                        1
                                                    )
                                                    hskillMoban.radiusAOE(
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit),
                                                        evtData.triggerUnit,
                                                        aoeSize,
                                                        function(target)
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = evtData.triggerUnit,
                                                                    targetUnit = target,
                                                                    damage = hattribute.getWithLimit(
                                                                            evtData.triggerUnit,
                                                                            nil,
                                                                            "attack",
                                                                            0
                                                                        ) *
                                                                        nandu *
                                                                        1.5,
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                    triggerSkill = hslk.n2i("AI技能模版")
                                                                }
                                                            )
                                                            hbuff.xuanyun(target, 0.01)
                                                        end
                                                    )
                                                end,
                                                effect = function(evtData)
                                                end,
                                                shifashijian = 3.1
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "极速猛扑",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                castCD = 8, -- nil or <=1 means 1 second
                                                startEffect = function(evtData)
                                                    hskillMoban.radiusWarning(
                                                        hunit.x(evtData.targetUnit),
                                                        hunit.y(evtData.targetUnit),
                                                        hunit.z(evtData.targetUnit),
                                                        200,
                                                        2
                                                    )
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    hskillMoban.leap(
                                                        {
                                                            arrowUnit = evtData.triggerUnit,  -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                                                            sourceUnit = evtData.triggerUnit, --伤害来源（必须有！不管有没有伤害）
                                                            --  targetUnit = evtData.targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                                                            x = evtData.targetX,
                                                            y = evtData.targetY,
                                                            speed = 25, --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                                                            acceleration = 0,
                                                            height = 200,
                                                            shake = 0, --摇摆振幅角度[-90~+90|random]（可选的，默认0)
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
                                                            onEnding = function(endX, endY, timePassed)
                                                                hskillMoban.radiusAOE(
                                                                    endX,
                                                                    endY,
                                                                    evtData.triggerUnit,
                                                                    200,
                                                                    function(target)
                                                                        hskill.damage(
                                                                            {
                                                                                sourceUnit = evtData.triggerUnit,
                                                                                targetUnit = target,
                                                                                damage = hattribute.getWithLimit(
                                                                                    evtData.triggerUnit,
                                                                                    nil,
                                                                                    "attack",
                                                                                    0
                                                                                ) * 3,
                                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                                damageType = DAMAGE_TYPE.WULI,
                                                                                triggerSkill = hslk.n2i("AI技能模版")
                                                                            }
                                                                        )
                                                                        hbuff.xuanyun(target, 2)
                                                                    end
                                                                )
                                                            end
                                                        }
                                                    )
                                                end,
                                                shifashijian = 1.5
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
                            passiveSkill = { { yelangsiyao }, { yelangsiyao }, { yelangsiyao }, { yelangsiyao } }
                        }
                    },
                    tongguanjiangli = {
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience, value = 1000 },
                                { type = HSHOP_COST_TYPE.gold,       value = 150 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 0,
                                    shengwangname = "新手村"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience, value = 1500 },
                                { type = HSHOP_COST_TYPE.gold,       value = 180 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 1,
                                    shengwangname = "新手村"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience, value = 2000 },
                                { type = HSHOP_COST_TYPE.gold,       value = 210 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 2,
                                    shengwangname = "新手村"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience, value = 2500 },
                                { type = HSHOP_COST_TYPE.gold,       value = 500 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 3,
                                    shengwangname = "新手村"
                                }
                            }
                        }
                    }
                }
            )
        end
    }
)
