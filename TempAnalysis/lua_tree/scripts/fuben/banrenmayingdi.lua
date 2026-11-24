table.insert(
    FUBEN_LIST,
    {
        name = "半人马营地",
        setup = function()
            local nanduLevelConfig = {}
            nanduLevelConfig[FUBEN_NANDU.PUTONG] = 46
            nanduLevelConfig[FUBEN_NANDU.YINGXIONG] = 46
            nanduLevelConfig[FUBEN_NANDU.SHISHI] = 46
            nanduLevelConfig[FUBEN_NANDU.CHUANQI] = 60

            local xiaoguaidiaoluo =
                DiaoLuoConfig( --掉落配置
                    {
                        {
                            list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                            drop_rate = {
                                --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                100,
                                100,
                                100,
                                0
                            }
                        }
                    }
                )

            local lianshe = {
                description = "攻击有30%概率额外射出一只箭矢，造成150%攻击力的伤害",
                attr_type = CONST_EVENT.attack,
                attr = function(evtData)
                    if math.random(1, 100) <= 30 then
                        hskillMoban.missile(
                            {
                                model = "war3mapImported\\[lieren]SylvanusWindrunnePFr_Attack.mdl",
                                scale = 1.5,
                                speed = 800,
                                hover = 100,
                                sourceUnit = evtData.triggerUnit,
                                targetUnit = evtData.targetUnit,
                                height = 0,
                                target_face_dis = 10,
                                onEnd = function()
                                    hskill.damage(
                                        {
                                            sourceUnit = evtData.triggerUnit,
                                            targetUnit = evtData.targetUnit,
                                            damage = hattr.getWithLimit(evtData.triggerUnit, nil, "attack", 10) * 1.5,
                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                            damageType = DAMAGE_TYPE.WULI,
                                            triggerSkill = hslk.n2i("AI技能模版"),
                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                            shanghainame = "人马连射",
                                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK }
                                        }
                                    )
                                end
                            }
                        )
                    end
                end
            }

            local renmayongshiai = function(level, nandu)
                return UnitAI(
                    {
                        {
                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                name = "践踏",
                                healthBelowLimit = 50,
                                --castCountLimit = 1,
                                notInterruptable = false,
                                minNandu = FUBEN_NANDU.PUTONG,
                                shifashijian = 3.0,
                                castCD = 30, -- nil or <=1 means 1 second
                                customCondition = nil,
                                startEffect = function(evtData)
                                    hunit.setAnimateSpeed(evtData.triggerUnit, 0.4)
                                    hunit.animate(evtData.triggerUnit, "spell")
                                    hskillMoban.radiusWarning(
                                        hunit.x(evtData.triggerUnit),
                                        hunit.y(evtData.triggerUnit),
                                        hunit.z(evtData.triggerUnit),
                                        300,
                                        2
                                    )
                                end,
                                periodEffect = function(evtData)
                                end,
                                effect = function(evtData)
                                    local sourceUnit = evtData.triggerUnit
                                    --local targetUnit = evtData.targetUnit
                                    local damage = (2 + nandu) * hattr.get(sourceUnit, "attack", 0)

                                    local group =
                                        hgroup.createByUnit(
                                            sourceUnit,
                                            300,
                                            function(filterUnit)
                                                if
                                                    hunit.isAlly(sourceUnit, filterUnit) or hunit.isDead(filterUnit) or
                                                    hunit.isDead(sourceUnit) or
                                                    hunit.isDestroyed(filterUnit) or
                                                    hunit.isDestroyed(sourceUnit)
                                                then
                                                    return false
                                                else
                                                    return true
                                                end
                                            end
                                        )
                                    heffect.xyz(
                                        "war3mapImported\\[Spell]_055.MDX",
                                        hunit.x(sourceUnit),
                                        hunit.y(sourceUnit),
                                        hunit.z(sourceUnit),
                                        0,
                                        1
                                    )
                                    for _, target in ipairs(group) do
                                        hskill.damage(
                                            {
                                                sourceUnit = sourceUnit,
                                                targetUnit = target,
                                                damage = damage,
                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                damageType = DAMAGE_TYPE.MOFA,
                                                triggerSkill = hslk.n2i("AI技能模版")
                                            }
                                        )
                                        hbuff.xuanyun(target, 1 + nandu)
                                    end
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

            local renmaxianzhi = function(level, nandu)
                return UnitAI(
                    {
                        {
                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                name = "火球轰击",
                                healthBelowLimit = 100,
                                --castCountLimit = 1,
                                notInterruptable = false,
                                minNandu = FUBEN_NANDU.PUTONG,
                                shifashijian = 3.0,
                                castCD = 10, -- nil or <=1 means 1 second
                                customCondition = nil,
                                startEffect = function(evtData)
                                    hunit.setAnimateSpeed(evtData.triggerUnit, 0.4)
                                    hunit.animate(evtData.triggerUnit, "spell")
                                end,
                                periodEffect = function(evtData)
                                end,
                                effect = function(evtData)
                                    local sourceUnit = evtData.triggerUnit
                                    local targetUnit = evtData.targetUnit
                                    local damage = (2 + nandu) * hattr.getWithLimit(sourceUnit, nil, "attack", 0)
                                    hskill.damage(
                                        {
                                            sourceUnit = sourceUnit,
                                            targetUnit = targetUnit,
                                            damage = damage,
                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                            damageType = DAMAGE_TYPE.MOFA,
                                            triggerSkill = hslk.n2i("AI技能模版"),
                                            effect = "Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode.mdl"
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
                    name = "半人马营地", --副本名字
                    status = FUBEN_STATUS.JIANHUA,
                    blp = "ReplaceableTextures\\xiaoditu\\UI_map_08.blp",
                    enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_10.blp",
                    nanduLevelConfig = nanduLevelConfig,                                 -- 副本难度以及级别需求,
                    entryPosition = { x = -19795, y = -8924 },
                    startPosition = { x = 6802, y = -4876 },                             --英雄进副本后位置
                    rectParam = { minX = 2554, minY = -5230, maxX = 7229, maxY = 1675 }, -- 副本区域
                    minions = {
                        {
                            name = "人马精英勇士", -- 名字 需要在物编定义好
                            x = 5539, -- 小怪刷新x坐标
                            y = -4835, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmayongshiai
                        },
                        {
                            name = "人马精英勇士", -- 名字 需要在物编定义好
                            x = 4300, -- 小怪刷新x坐标
                            y = -4895, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmayongshiai
                        },
                        {
                            name = "人马精英弓箭手", -- 名字 需要在物编定义好
                            x = 4300, -- 小怪刷新x坐标
                            y = -4895, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { lianshe }, { lianshe }, { lianshe }, { lianshe } }
                        },
                        {
                            name = "人马精英勇士", -- 名字 需要在物编定义好
                            x = 3012, -- 小怪刷新x坐标
                            y = -3528, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmayongshiai
                        },
                        {
                            name = "人马精英弓箭手", -- 名字 需要在物编定义好
                            x = 3012, -- 小怪刷新x坐标
                            y = -3428, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { lianshe }, { lianshe }, { lianshe }, { lianshe } }
                        },
                        {
                            name = "人马精英勇士", -- 名字 需要在物编定义好
                            x = 3012, -- 小怪刷新x坐标
                            y = -1244, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmayongshiai
                        },
                        {
                            name = "人马精英弓箭手", -- 名字 需要在物编定义好
                            x = 3012, -- 小怪刷新x坐标
                            y = -1244, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { lianshe }, { lianshe }, { lianshe }, { lianshe } }
                        },
                        {
                            name = "人马精英勇士", -- 名字 需要在物编定义好
                            x = 3012, -- 小怪刷新x坐标
                            y = 890, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmayongshiai
                        },
                        {
                            name = "人马精英弓箭手", -- 名字 需要在物编定义好
                            x = 3012, -- 小怪刷新x坐标
                            y = 890, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { lianshe }, { lianshe }, { lianshe }, { lianshe } }
                        },
                        {
                            name = "人马精英先知", -- 名字 需要在物编定义好
                            x = 3012, -- 小怪刷新x坐标
                            y = 890, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmaxianzhi
                        },
                        {
                            name = "人马精英勇士", -- 名字 需要在物编定义好
                            x = 4954, -- 小怪刷新x坐标
                            y = 950, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmayongshiai
                        },
                        {
                            name = "人马精英弓箭手", -- 名字 需要在物编定义好
                            x = 4954, -- 小怪刷新x坐标
                            y = 950, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { lianshe }, { lianshe }, { lianshe }, { lianshe } }
                        },
                        {
                            name = "人马精英先知", -- 名字 需要在物编定义好
                            x = 4954, -- 小怪刷新x坐标
                            y = 950, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmaxianzhi
                        },
                        {
                            name = "人马精英勇士", -- 名字 需要在物编定义好
                            x = 4571, -- 小怪刷新x坐标
                            y = -746, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmayongshiai
                        },
                        {
                            name = "人马精英弓箭手", -- 名字 需要在物编定义好
                            x = 4571, -- 小怪刷新x坐标
                            y = -746, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { lianshe }, { lianshe }, { lianshe }, { lianshe } }
                        },
                        {
                            name = "人马精英先知", -- 名字 需要在物编定义好
                            x = 4571, -- 小怪刷新x坐标
                            y = -746, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmaxianzhi
                        },
                        {
                            name = "人马精英勇士", -- 名字 需要在物编定义好
                            x = 5769, -- 小怪刷新x坐标
                            y = -844, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmayongshiai
                        },
                        {
                            name = "人马精英弓箭手", -- 名字 需要在物编定义好
                            x = 5769, -- 小怪刷新x坐标
                            y = -844, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { lianshe }, { lianshe }, { lianshe }, { lianshe } }
                        },
                        {
                            name = "人马精英先知", -- 名字 需要在物编定义好
                            x = 5769, -- 小怪刷新x坐标
                            y = -844, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmaxianzhi
                        },
                        {
                            name = "人马精英勇士", -- 名字 需要在物编定义好
                            x = 4777, -- 小怪刷新x坐标
                            y = -2449, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmayongshiai
                        },
                        {
                            name = "人马精英弓箭手", -- 名字 需要在物编定义好
                            x = 4777, -- 小怪刷新x坐标
                            y = -2449, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { lianshe }, { lianshe }, { lianshe }, { lianshe } }
                        },
                        {
                            name = "人马精英先知", -- 名字 需要在物编定义好
                            x = 4777, -- 小怪刷新x坐标
                            y = -2449, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmaxianzhi
                        },
                        {
                            name = "人马精英勇士", -- 名字 需要在物编定义好
                            x = 5525, -- 小怪刷新x坐标
                            y = -3762, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmayongshiai
                        },
                        {
                            name = "人马精英弓箭手", -- 名字 需要在物编定义好
                            x = 5525, -- 小怪刷新x坐标
                            y = -3762, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { lianshe }, { lianshe }, { lianshe }, { lianshe } }
                        },
                        {
                            name = "人马精英先知", -- 名字 需要在物编定义好
                            x = 5525, -- 小怪刷新x坐标
                            y = -3762, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = renmaxianzhi
                        }
                    },
                    bosses = {
                        {
                            name = "快刀手迅蹄",
                            x = 3248,
                            y = -4547,
                            levelAdj = 0,
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
                                        list = { "人马勇士之戒", "野蛮斗士护手", "套马索" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1500,
                                            1500,
                                            1500,
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
                                                name = "撕裂冲锋",
                                                healthBelowLimit = 90,
                                                --castCountLimit = 1,
                                                notInterruptable = true,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 1.5,
                                                castCD = 12 - nandu, -- nil or <=1 means 1 second
                                                customCondition = nil,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local damage = (2 + nandu) * hattr.get(sourceUnit, "attack", 0)
                                                    local angel =
                                                        math.angle(
                                                            hunit.x(sourceUnit),
                                                            hunit.y(sourceUnit),
                                                            evtData.targetX,
                                                            evtData.targetY
                                                        )
                                                    local x, y =
                                                        math.polarProjection(
                                                            hunit.x(sourceUnit),
                                                            hunit.y(sourceUnit),
                                                            800,
                                                            angel
                                                        )
                                                    hskillMoban.leap(
                                                        {
                                                            arrowUnit = evtData.triggerUnit,  -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                                                            sourceUnit = evtData.triggerUnit, --伤害来源（必须有！不管有没有伤害）
                                                            --targetUnit = evtData.targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                                                            x = x,                            --冲击的x坐标（可选的，对点冲击，与某目标无关）
                                                            y = y,                            --冲击的y坐标（可选的，对点冲击，与某目标无关）
                                                            speed = 20 + 5 * nandu,           --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                                                            acceleration = 0,
                                                            shake = 0,                        --摇摆振幅角度[-90~+90|random]（可选的，默认0)
                                                            filter = function(enum)
                                                                return hunit.isEnemy(evtData.triggerUnit, enum) and
                                                                    hunit.isAlive(enum)
                                                            end,                                            --必须有
                                                            tokenArrowScale = 1.00,                         --前冲的特效作为马甲冲击时的模型缩放
                                                            tokenArrowOpacity = 1.00,                       --前冲的特效作为马甲冲击时的模型透明度[0-1]
                                                            tokenArrowHeight = 0.00,                        --前冲的特效作为马甲冲击时的初始离地高度
                                                            effectMovement = nil,                           --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                                            animateMovement = 1,
                                                            effectEnd = nil,                                --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                                            damageMovement = damage,                        --移动过程中的伤害（可选的，默认为0）
                                                            damageMovementRadius = 100,                     --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
                                                            damageMovementRepeat = false,                   --移动过程中伤害是否可以重复造成（可选的，默认为不能）
                                                            damageMovementDrag = false,                     --移动过程是否拖拽敌人（可选的，默认为不能）
                                                            damageEndRadius = 0,                            --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
                                                            damageSrc = CONST_DAMAGE_SRC.skill,             --伤害的种类（可选）
                                                            damageEffect = "war3mapImported\\AZ_gelie.mdx", --伤害特效（可选）
                                                            damageType = DAMAGE_TYPE.WULI,
                                                            damageSkill = hslk.n2i("AI技能模版"),
                                                            oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
                                                            endDistance = 0,
                                                            extraInfluence = function(whichUnit)
                                                                hbuff.update(
                                                                    30,
                                                                    whichUnit,
                                                                    "撕裂冲锋",
                                                                    false,
                                                                    nil,
                                                                    nil,
                                                                    "ReplaceableTextures\\BTN_KRDS_CF.blp",
                                                                    "冲锋撕裂目标，造成每秒" ..
                                                                    tostring(100 + nandu * 100) .. "点伤害，可以无限叠加",
                                                                    1,
                                                                    1,
                                                                    function(curTimer, buffHandle)
                                                                        buffHandle.remainingTime =
                                                                            buffHandle.remainingTime - 1
                                                                        hskill.damage(
                                                                            {
                                                                                sourceUnit = sourceUnit,
                                                                                targetUnit = whichUnit,
                                                                                damage = (100 + nandu * 100) *
                                                                                    buffHandle.stack,
                                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                                damageType = DAMAGE_TYPE.WULI,
                                                                                damageElementType = {
                                                                                    CONST_DAMAGE_ELEMENT_TYPE.METAL
                                                                                },
                                                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                    .DOT,
                                                                                shanghainame = "撕裂冲锋之撕裂"
                                                                            }
                                                                        )
                                                                    end,
                                                                    function(buffHandle)
                                                                        buffHandle.remainingTime = 30
                                                                        buffHandle.stack = buffHandle.stack + 1
                                                                    end,
                                                                    nil,
                                                                    HBUFF_UPDATE_MODE.UPDATE,
                                                                    true
                                                                )
                                                            end, --对选中的敌人的额外影响，会回调该敌人单位，可以对其做出自定义行为
                                                            onEnding = function(_, _, timePassed)
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
                            passiveSkill = { {}, {}, {}, {} }
                        },
                        {
                            name = "人马弓神布鲁斯",
                            x = 6599,
                            y = 855,
                            levelAdj = 0,
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
                                        list = { "射手箭袋", "专注之戒", "速射长弓" }, --物品名字 需要在物编定义好
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
                            ai = function(level, nandu)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "瞄准射击",
                                                healthBelowLimit = 50,
                                                --castCountLimit = 1,
                                                notInterruptable = false,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 3.0,
                                                castCD = 30, -- nil or <=1 means 1 second
                                                customCondition = nil,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, "attack")
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local damage = 2 * (2 + nandu) * hattr.get(sourceUnit, "attack", 0)
                                                    hskillMoban.missile(
                                                        {
                                                            model =
                                                            "war3mapImported\\[lieren]SylvanusWindrunnePFr_Attack.mdl",
                                                            scale = 2,
                                                            speed = 1500,
                                                            hover = 100,
                                                            sourceUnit = sourceUnit,
                                                            targetUnit = targetUnit,
                                                            target_face_dis = 10,
                                                            onEnd = function()
                                                                hskill.damage(
                                                                    {
                                                                        sourceUnit = sourceUnit,
                                                                        targetUnit = targetUnit,
                                                                        damage = damage,
                                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                                        damageType = DAMAGE_TYPE.WULI,
                                                                        damageElementType = {
                                                                            CONST_DAMAGE_ELEMENT_TYPE.METAL
                                                                        },
                                                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                            .IMMEDIATE,
                                                                        shanghainame = "瞄准射击"
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
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "涂毒",
                                                healthBelowLimit = 100,
                                                --castCountLimit = 1,
                                                notInterruptable = false,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 2.0,
                                                castCD = 30, -- nil or <=1 means 1 second
                                                customCondition = nil,
                                                --interval = 0.01,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local damage =
                                                        0.3 * (2 + nandu) * hattr.get(sourceUnit, "attack", 0)
                                                    hbuff.update(
                                                        7,
                                                        sourceUnit,
                                                        "人马boss淬毒",
                                                        true,
                                                        function()
                                                            hevent.register(
                                                                sourceUnit,
                                                                CONST_EVENT.attack,
                                                                "人马boss淬毒",
                                                                function(evtData)
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = sourceUnit,
                                                                            targetUnit = targetUnit,
                                                                            damage = damage,
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.WULI,
                                                                            damageElementType = {
                                                                                CONST_DAMAGE_ELEMENT_TYPE.METAL
                                                                            },
                                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                .IMMEDIATE,
                                                                            shanghainame = "瞄准射击"
                                                                        }
                                                                    )
                                                                end
                                                            )
                                                        end,
                                                        function()
                                                            hevent.unregister(
                                                                sourceUnit,
                                                                CONST_EVENT.attack,
                                                                "人马boss淬毒"
                                                            )
                                                        end,
                                                        "ReplaceableTextures\\lieren\\Ability_Hunter_Quickshot.blp",
                                                        "攻击造成额外" .. damage .. "点毒性伤害",
                                                        nil,
                                                        nil,
                                                        nil,
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
                                                name = "连射",
                                                healthBelowLimit = 75,
                                                --castCountLimit = 1,
                                                notInterruptable = false,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 5.0,
                                                castCD = 25, -- nil or <=1 means 1 second
                                                customCondition = nil,
                                                interval = 1,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, "attack")
                                                end,
                                                periodEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, "attack")
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local damage =
                                                        0.8 * (2 + nandu) * hattr.get(sourceUnit, "attack", 0)
                                                    local angel =
                                                        math.angle(
                                                            hunit.x(sourceUnit),
                                                            hunit.y(sourceUnit),
                                                            evtData.targetX, --冲击的x坐标（可选的，对点冲击，与某目标无关）
                                                            evtData.targetY
                                                        )
                                                    local x, y =
                                                        math.polarProjection(
                                                            hunit.x(sourceUnit),
                                                            hunit.y(sourceUnit),
                                                            1500,
                                                            angel
                                                        )
                                                    hskillMoban.leap(
                                                        {
                                                            arrowUnit = nil,                  -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                                                            sourceUnit = evtData.triggerUnit, --伤害来源（必须有！不管有没有伤害）
                                                            --targetUnit = evtData.targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                                                            x = x,                            --冲击的x坐标（可选的，对点冲击，与某目标无关）
                                                            y = y,                            --冲击的y坐标（可选的，对点冲击，与某目标无关）
                                                            speed = 25 + 5 * nandu,           --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                                                            acceleration = 0,
                                                            shake = 0,                        --摇摆振幅角度[-90~+90|random]（可选的，默认0)
                                                            filter = function(enum)
                                                                return hunit.isEnemy(evtData.triggerUnit, enum) and
                                                                    hunit.isAlive(enum)
                                                            end, --必须有
                                                            tokenArrow =
                                                            "war3mapImported\\[lieren]SylvanusWindrunnePFr_Attack.mdl",
                                                            tokenArrowScale = 1.50,             --前冲的特效作为马甲冲击时的模型缩放
                                                            tokenArrowOpacity = 1.00,           --前冲的特效作为马甲冲击时的模型透明度[0-1]
                                                            tokenArrowHeight = 100.00,          --前冲的特效作为马甲冲击时的初始离地高度
                                                            effectMovement = nil,               --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                                            animateMovement = 1,
                                                            effectEnd = nil,                    --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                                            damageMovement = damage,            --移动过程中的伤害（可选的，默认为0）
                                                            damageMovementRadius = 100,         --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
                                                            damageMovementRepeat = false,       --移动过程中伤害是否可以重复造成（可选的，默认为不能）
                                                            damageMovementDrag = false,         --移动过程是否拖拽敌人（可选的，默认为不能）
                                                            damageEndRadius = 0,                --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
                                                            damageSrc = CONST_DAMAGE_SRC.skill, --伤害的种类（可选）
                                                            damageEffect = nil,                 --伤害特效（可选）
                                                            damageType = DAMAGE_TYPE.WULI,
                                                            damageSkill = hslk.n2i("AI技能模版"),
                                                            oneHitOnly = true, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
                                                            endDistance = 0,
                                                            extraInfluence = function(whichUnit)
                                                            end, --对选中的敌人的额外影响，会回调该敌人单位，可以对其做出自定义行为
                                                            onEnding = function(_, _, timePassed)
                                                            end
                                                        }
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local damage =
                                                        0.3 * (2 + nandu) * hattr.get(sourceUnit, "attack", 0)
                                                    hbuff.update(
                                                        10,
                                                        sourceUnit,
                                                        "人马boss淬毒",
                                                        true,
                                                        function()
                                                            hevent.register(
                                                                sourceUnit,
                                                                CONST_EVENT.attack,
                                                                "人马boss淬毒",
                                                                function(evtData)
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = sourceUnit,
                                                                            targetUnit = targetUnit,
                                                                            damage = damage,
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.WULI,
                                                                            damageElementType = {
                                                                                CONST_DAMAGE_ELEMENT_TYPE.METAL
                                                                            },
                                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                .IMMEDIATE,
                                                                            shanghainame = "瞄准射击"
                                                                        }
                                                                    )
                                                                end
                                                            )
                                                        end,
                                                        function()
                                                            hevent.unregister(
                                                                sourceUnit,
                                                                CONST_EVENT.attack,
                                                                "人马boss淬毒"
                                                            )
                                                        end,
                                                        "ReplaceableTextures\\lieren\\Ability_Hunter_Quickshot.blp",
                                                        "攻击造成额外" .. damage .. "点毒性伤害",
                                                        nil,
                                                        nil,
                                                        nil,
                                                        nil,
                                                        nil,
                                                        HBUFF_UPDATE_MODE.OVERWRITE,
                                                        true
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
                            passiveSkill = { { lianshe }, { lianshe }, { lianshe }, { lianshe } }
                        },
                        {
                            name = "人马酋长战争之蹄",
                            x = 6332,
                            y = -3221,
                            levelAdj = 0,
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
                                        list = { "野蛮斗士战盔", "酋长大氅", "酋长吊坠", "勇气圣契" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2000,
                                            2000,
                                            2000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "人马图腾" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            0,
                                            500,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = function(level, nandu, count, fubenStatus, mijing)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "召唤护卫",
                                                healthBelowLimit = 50,
                                                --castCountLimit = 1,
                                                notInterruptable = true,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                shifashijian = 1.5,
                                                castCD = 45, -- nil or <=1 means 1 second
                                                customCondition = nil,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "快来保护我！！!",
                                                        10,
                                                        "eae30a",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = level,
                                                                attackSpace = hslk.n2v("人马精英勇士", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_XIAOGUAI,
                                                                nandu = nandu,
                                                                count = count,
                                                                status = fubenStatus,
                                                                mijing = mijing
                                                            }
                                                        )
                                                    for i = 1, nandu, 1 do
                                                        local tmpUnit =
                                                            henemy.create(
                                                                {
                                                                    id = hslk.n2i("人马精英勇士"),
                                                                    x = hunit.x(evtData.triggerUnit) +
                                                                        math.random(-100, 100),
                                                                    y = hunit.y(evtData.triggerUnit) +
                                                                        math.random(-100, 100),
                                                                    facing = 0,
                                                                    attr = tmpAttr,
                                                                    AI = renmayongshiai(level, nandu),
                                                                    nandu = nandu,
                                                                    tuozhanshijian = 36000
                                                                }
                                                            )
                                                        hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                                                        hskillMoban.guanghuan(
                                                            tmpUnit,
                                                            hslk.n2i("AI技能模版"),
                                                            1000,
                                                            _attr(
                                                                {
                                                                    jianshang = "+20"
                                                                }
                                                            ),
                                                            true,
                                                            true,
                                                            "精英护卫|n增加周围范围20%减伤"
                                                        )
                                                        hunit.setExpReward(tmpUnit, 0)
                                                    end
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "战争践踏",
                                                healthBelowLimit = 100,
                                                --castCountLimit = 1,
                                                notInterruptable = false,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 2.0,
                                                castCD = 12, -- nil or <=1 means 1 second
                                                customCondition = nil,
                                                startEffect = function(evtData)
                                                    hunit.setAnimateSpeed(evtData.triggerUnit, 0.4)
                                                    hunit.animate(evtData.triggerUnit, "spell")
                                                    hskillMoban.radiusWarning(
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit),
                                                        hunit.z(evtData.triggerUnit),
                                                        400,
                                                        2
                                                    )
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    --local targetUnit = evtData.targetUnit
                                                    local damage = (2 + nandu) * hattr.get(sourceUnit, "attack", 0)

                                                    local group =
                                                        hgroup.createByUnit(
                                                            sourceUnit,
                                                            400,
                                                            function(filterUnit)
                                                                if
                                                                    hunit.isAlly(sourceUnit, filterUnit) or
                                                                    hunit.isDead(filterUnit) or
                                                                    hunit.isDead(sourceUnit) or
                                                                    hunit.isDestroyed(filterUnit) or
                                                                    hunit.isDestroyed(sourceUnit)
                                                                then
                                                                    return false
                                                                else
                                                                    return true
                                                                end
                                                            end
                                                        )
                                                    heffect.xyz(
                                                        "war3mapImported\\[Spell]_055.MDX",
                                                        hunit.x(sourceUnit),
                                                        hunit.y(sourceUnit),
                                                        hunit.z(sourceUnit),
                                                        0,
                                                        1,
                                                        1.3,
                                                        1.3,
                                                        1.3
                                                    )
                                                    for _, target in ipairs(group) do
                                                        hskill.damage(
                                                            {
                                                                sourceUnit = sourceUnit,
                                                                targetUnit = target,
                                                                damage = damage,
                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                damageType = DAMAGE_TYPE.MOFA,
                                                                triggerSkill = hslk.n2i("AI技能模版")
                                                            }
                                                        )
                                                        hbuff.xuanyun(target, 3 + nandu * 0.5)
                                                    end
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
                        }
                    },
                    tongguanjiangli = {
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience, value = 5000 },
                                { type = HSHOP_COST_TYPE.gold,       value = 500 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 0,
                                    shengwangname = "峡谷前哨站"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience, value = 7000 },
                                { type = HSHOP_COST_TYPE.gold,       value = 750 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 1,
                                    shengwangname = "峡谷前哨站"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience,     value = 10000 },
                                { type = HSHOP_COST_TYPE.gold,           value = 1000 },
                                { type = HSHOP_COST_TYPE.yongqihuizhang, value = 1 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 2,
                                    shengwangname = "峡谷前哨站"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience,     value = 5000 },
                                { type = HSHOP_COST_TYPE.gold,           value = 1300 },
                                { type = HSHOP_COST_TYPE.yongqihuizhang, value = 2 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 3,
                                    shengwangname = "峡谷前哨站"
                                }
                            }
                        }
                    }
                }
            )
        end
    }
)
