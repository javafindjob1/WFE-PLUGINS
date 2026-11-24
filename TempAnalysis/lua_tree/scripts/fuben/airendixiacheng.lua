table.insert(
    FUBEN_LIST,
    {
        name = "矮人地下城",
        setup = function()
            local nanduLevelConfig = {}
            nanduLevelConfig[FUBEN_NANDU.PUTONG] = 53
            nanduLevelConfig[FUBEN_NANDU.YINGXIONG] = 53
            nanduLevelConfig[FUBEN_NANDU.SHISHI] = 53
            nanduLevelConfig[FUBEN_NANDU.CHUANQI] = 60

            local ai = function(level, nandu)
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
            local xiaoguaidiaoluo =
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

            local hudunfantan = {
                description = "护盾反弹伤害，受到伤害有10%概率会反击施加伤害的单位，伤害为30%倍攻击力，最短触发间隔3秒。",
                attr_type = CONST_EVENT.beDamage,
                attr = function(evtData)
                    if hunit.isDestroyed(evtData.sourceUnit) or hunit.isDestroyed(evtData.triggerUnit) then
                        return
                    end
                    local reflectPercent = 0.3
                    if math.random(1, 100) <= 10 then
                        if
                            htime.setupAndCheckCoolDown(
                                evtData.sourceUnit,
                                "duonier_fantan" .. tostring(evtData.triggerUnit),
                                3
                            )
                        then
                            local damage = hattr.get(evtData.triggerUnit, "attack", 1) * reflectPercent
                            htextTag.create2Unit(evtData.sourceUnit, "反击", 10, "eae30a", 1, 1, 50)
                            hskill.damage(
                                {
                                    sourceUnit = evtData.triggerUnit,
                                    targetUnit = evtData.sourceUnit,
                                    damage = damage,
                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                    damageType = DAMAGE_TYPE.WULI,
                                    effect = "war3mapImported\\AZ_hit1.mdx",
                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
                                }
                            )
                        end
                    end
                end
            }

            local attackzuijiu = {
                description = "火枪手攻击醉酒单位会引发爆燃，额外造成2倍攻击力的伤害",
                attr_type = CONST_EVENT.attack,
                attr = function(evtData)
                    local targetUnit = evtData.targetUnit
                    local sourceUnit = evtData.triggerUnit
                    if hbuff.hasBuff(targetUnit, "zuijiudebuff") then
                        local damage = hattr.get(sourceUnit, "attack", 0) * 2
                        hskill.damage(
                            {
                                sourceUnit = sourceUnit,
                                targetUnit = targetUnit,
                                damage = damage,
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.MOFA,
                                effect = "Abilities\\Spells\\Other\\Incinerate\\IncinerateBuff.mdl",
                                damageElemetType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                            }
                        )
                    end
                end
            }

            local shifajiasu = {
                description = "吟唱加速:格洛格每次施放火球系技能,会增加2%技能加速,可叠加20层",
                attr_type = CONST_EVENT.skillCast,
                attr = function(evtData)
                    local sourceUnit = evtData.triggerUnit
                    hbuff.addStackAttrBuff(
                        CONST_DAMAGE_SRC.skill,
                        sourceUnit,
                        "格洛格吟唱",
                        { skill_speed = "+2" },
                        -1,
                        20,
                        "ReplaceableTextures\\CommandButtons\\BTNFireBolt.blp",
                        "吟唱加速:每次施放火球系技能,会增加2%技能施法速度,可叠加20层",
                        true
                    )
                end
            }

            local lianji = {
                description = "强化攻击:索瑞森大帝攻击有20%概率额外造成一次攻击伤害,该技能可连续触发",
                attr_type = CONST_EVENT.attack,
                attr = function(evtData)
                    local triggerUnit = evtData.triggerUnit
                    local targetUnit = evtData.targetUnit
                    if math.random(1, 100) <= 20 then
                        htime.setTimeout(
                            0.2,
                            function(curTimer)
                                heffect.xyz(
                                    "[boss]suoruisen3.mdx",
                                    hunit.x(evtData.triggerUnit),
                                    hunit.y(evtData.triggerUnit),
                                    hunit.z(evtData.triggerUnit),
                                    0,
                                    1,
                                    2,
                                    2,
                                    2,
                                    nil,
                                    nil,
                                    math.angle(
                                        hunit.x(evtData.triggerUnit),
                                        hunit.y(evtData.triggerUnit),
                                        hunit.x(evtData.targetUnit),
                                        hunit.y(evtData.targetUnit)
                                    )
                                )
                                hsound.voice2Unit(
                                    hsound.voiceCreate("resource\\war3mapImported\\sound\\lianji.wav", 1000, true),
                                    80,
                                    triggerUnit
                                )
                                heffect.attach("war3mapImported\\AZ_hit1.mdx", evtData.targetUnit, "chest", 0)
                                hskill.damage(
                                    {
                                        sourceUnit = triggerUnit,
                                        targetUnit = targetUnit,
                                        damage = hattr.get(triggerUnit, "attack", 1),
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.WULI,
                                        effect = "Abilities\\Weapons\\Axe\\AxeMissile.mdl",
                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                    }
                                )
                            end
                        )
                    end
                end
            }
            hfuben.buildFuben(
                {
                    name = "矮人地下城", --副本名字
                    status = FUBEN_STATUS.JIANHUA,
                    blp = "ReplaceableTextures\\xiaoditu\\UI_map_001.blp",
                    enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_11.blp",
                    nanduLevelConfig = nanduLevelConfig,                                  -- 副本难度以及级别需求,
                    entryPosition = { x = -25573, y = 2105 },
                    startPosition = { x = -3355, y = -5433 },                             --英雄进副本后位置
                    rectParam = { minX = -4110, minY = -5750, maxX = 1135, maxY = 1295 }, -- 副本区域
                    minions = {
                        {
                            name = "精英黑铁矮人矿工", -- 名字 需要在物编定义好
                            x = -3692, -- 小怪刷新x坐标
                            y = -4685, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人守卫", -- 名字 需要在物编定义好
                            x = -3018, -- 小怪刷新x坐标
                            y = -4408, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人矿工", -- 名字 需要在物编定义好
                            x = -3768, -- 小怪刷新x坐标
                            y = -3305, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人守卫", -- 名字 需要在物编定义好
                            x = -3320, -- 小怪刷新x坐标
                            y = -3805, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人枪手", -- 名字 需要在物编定义好
                            x = -2922, -- 小怪刷新x坐标
                            y = -2922, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人守卫", -- 名字 需要在物编定义好
                            x = -3022, -- 小怪刷新x坐标
                            y = -3022, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { attackzuijiu }, { attackzuijiu }, { attackzuijiu }, { attackzuijiu } },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人枪手", -- 名字 需要在物编定义好
                            x = -3360, -- 小怪刷新x坐标
                            y = -1470, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { attackzuijiu }, { attackzuijiu }, { attackzuijiu }, { attackzuijiu } },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人守卫", -- 名字 需要在物编定义好
                            x = -3360, -- 小怪刷新x坐标
                            y = -1470, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人矿工", -- 名字 需要在物编定义好
                            x = -3000, -- 小怪刷新x坐标
                            y = 825, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人矿工", -- 名字 需要在物编定义好
                            x = -455, -- 小怪刷新x坐标
                            y = 800, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人矿工", -- 名字 需要在物编定义好
                            x = -455, -- 小怪刷新x坐标
                            y = -114, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人枪手", -- 名字 需要在物编定义好
                            x = 635, -- 小怪刷新x坐标
                            y = 729, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { attackzuijiu }, { attackzuijiu }, { attackzuijiu }, { attackzuijiu } },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人守卫", -- 名字 需要在物编定义好
                            x = 535, -- 小怪刷新x坐标
                            y = 679, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人枪手", -- 名字 需要在物编定义好
                            x = -1826, -- 小怪刷新x坐标
                            y = -300, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { attackzuijiu }, { attackzuijiu }, { attackzuijiu }, { attackzuijiu } },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人守卫", -- 名字 需要在物编定义好
                            x = -1626, -- 小怪刷新x坐标
                            y = -200, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人枪手", -- 名字 需要在物编定义好
                            x = -1551, -- 小怪刷新x坐标
                            y = -1921, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { attackzuijiu }, { attackzuijiu }, { attackzuijiu }, { attackzuijiu } },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人守卫", -- 名字 需要在物编定义好
                            x = -1551, -- 小怪刷新x坐标
                            y = -1721, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人矿工", -- 名字 需要在物编定义好
                            x = -2126, -- 小怪刷新x坐标
                            y = -2358, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人矿工", -- 名字 需要在物编定义好
                            x = 436, -- 小怪刷新x坐标
                            y = -2113, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人守卫", -- 名字 需要在物编定义好
                            x = 199, -- 小怪刷新x坐标
                            y = -644, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人枪手", -- 名字 需要在物编定义好
                            x = 199, -- 小怪刷新x坐标
                            y = -644, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { attackzuijiu }, { attackzuijiu }, { attackzuijiu }, { attackzuijiu } },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人守卫", -- 名字 需要在物编定义好
                            x = -800, -- 小怪刷新x坐标
                            y = -2999, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人枪手", -- 名字 需要在物编定义好
                            x = -800, -- 小怪刷新x坐标
                            y = -2999, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { attackzuijiu }, { attackzuijiu }, { attackzuijiu }, { attackzuijiu } },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人守卫", -- 名字 需要在物编定义好
                            x = -1622, -- 小怪刷新x坐标
                            y = -4094, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人枪手", -- 名字 需要在物编定义好
                            x = -1622, -- 小怪刷新x坐标
                            y = -4094, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { attackzuijiu }, { attackzuijiu }, { attackzuijiu }, { attackzuijiu } },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人守卫", -- 名字 需要在物编定义好
                            x = 400, -- 小怪刷新x坐标
                            y = -4017, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英黑铁矮人枪手", -- 名字 需要在物编定义好
                            x = 400, -- 小怪刷新x坐标
                            y = -4017, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { attackzuijiu }, { attackzuijiu }, { attackzuijiu }, { attackzuijiu } },
                            ai = ai
                        }
                    },
                    bosses = {
                        {
                            name = "矮人守卫队长杜尼尔",
                            x = -3315,
                            y = 190,
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
                                        list = { "斗士披风", "野蛮斗士战靴", "反对者" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1500,
                                            1500,
                                            1500,
                                            0
                                        }
                                    },
                                    {
                                        list = { "源质矿石" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            300,
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
                                                targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                                name = "投掷酒桶",
                                                notInterruptable = true,
                                                healthBelowLimit = 80,
                                                castCD = 15,
                                                shifashijian = 0.5,
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "尝尝我酿的酒",
                                                        10,
                                                        "ebc959",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetX = evtData.targetX
                                                    local targetY = evtData.targetY
                                                    local damage = hattr.get(sourceUnit, "attack", 0) * nandu
                                                    hskillMoban.radiusWarning(
                                                        targetX,
                                                        targetY,
                                                        hunit.z(sourceUnit),
                                                        350,
                                                        3
                                                    )
                                                    local distance =
                                                        math.distance(
                                                            targetX,
                                                            targetY,
                                                            hunit.x(sourceUnit),
                                                            hunit.y(sourceUnit)
                                                        )
                                                    local speed = distance / (2.2 - nandu * 0.3)
                                                    hskillMoban.missile(
                                                        {
                                                            model = "[boss]jiutong.mdx",
                                                            scale = 1.5,
                                                            hover = 100,
                                                            sourceUnit = sourceUnit,
                                                            speed = speed,
                                                            height = 500,
                                                            targetX = targetX,
                                                            targetY = targetY,
                                                            onEnd = function(sourceUnit, targetUnit, endX, endY)
                                                                heffect.xyz(
                                                                    "[boss]niangjiu.mdx",
                                                                    endX,
                                                                    endY,
                                                                    hunit.z(sourceUnit),
                                                                    0.1,
                                                                    1,
                                                                    1.2,
                                                                    1.2,
                                                                    1.2
                                                                )
                                                                hskillMoban.radiusAOE(
                                                                    endX,
                                                                    endY,
                                                                    sourceUnit,
                                                                    350,
                                                                    function(unit)
                                                                        hskill.damage(
                                                                            {
                                                                                sourceUnit = sourceUnit,
                                                                                targetUnit = unit,
                                                                                damage = damage,
                                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                                damageType = DAMAGE_TYPE.MOFA,
                                                                                effect =
                                                                                "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl",
                                                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                    .IMMEDIATE,
                                                                                damageElementType = {
                                                                                    CONST_DAMAGE_ELEMENT_TYPE.WOOD
                                                                                }
                                                                            }
                                                                        )
                                                                        hbuff.update(
                                                                            10,
                                                                            unit,
                                                                            "zuijiudebuff",
                                                                            false,
                                                                            function()
                                                                                -- 降低单位命中率
                                                                                hattribute.set(
                                                                                    unit,
                                                                                    0,
                                                                                    { hit = "-" .. 10 * nandu }
                                                                                )
                                                                            end,
                                                                            function()
                                                                                -- 移除命中率降低效果
                                                                                hattribute.set(
                                                                                    unit,
                                                                                    0,
                                                                                    { hit = "+" .. 10 * nandu }
                                                                                )
                                                                            end,
                                                                            "ReplaceableTextures\\CommandButtons\\BTNBarrel.blp", -- 图标
                                                                            "醉酒中,命中率降低" .. tostring(10 * nandu) .. "%", -- 说明
                                                                            1,
                                                                            nil,
                                                                            nil,
                                                                            nil,
                                                                            nil,
                                                                            HBUFF_UPDATE_MODE.OVERWRITE
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
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "召唤火枪手", --技能1
                                                notInterruptable = true,
                                                healthBelowLimit = 90,
                                                castCD = 20,
                                                shifashijian = 2,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = level,
                                                                attackSpace = hslk.n2v("精英黑铁矮人枪手", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_XIAOGUAI,
                                                                nandu = nandu,
                                                                count = count,
                                                                status = fubenStatus,
                                                                mijing = mijing
                                                            }
                                                        )
                                                    for i = 2, nandu + 1, 1 do
                                                        local tmpUnit =
                                                            henemy.create(
                                                                {
                                                                    id = hslk.n2i("精英黑铁矮人枪手"),
                                                                    x = hunit.x(evtData.triggerUnit) +
                                                                        math.random(-100, 100),
                                                                    y = hunit.y(evtData.triggerUnit) +
                                                                        math.random(-100, 100),
                                                                    facing = 0,
                                                                    attr = tmpAttr,
                                                                    nandu = nandu,
                                                                    tuozhanshijian = 36000
                                                                }
                                                            )
                                                        hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)

                                                        hevent.register(
                                                            tmpUnit,
                                                            attackzuijiu.attr_type,
                                                            "passiveSkillzuijiu",
                                                            attackzuijiu.attr
                                                        )

                                                        hbuff.update(
                                                            nil,
                                                            tmpUnit,
                                                            "被动技能说明",
                                                            true,
                                                            nil,
                                                            nil,
                                                            "ReplaceableTextures\\BTNPriest_icon_Chakra_blue.blp",
                                                            attackzuijiu.description,
                                                            1,
                                                            nil,
                                                            nil,
                                                            nil,
                                                            nil,
                                                            HBUFF_UPDATE_MODE.OVERWRITE,
                                                            false
                                                        )
                                                        hunit.setExpReward(tmpUnit, 0)
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
                            passiveSkill = { { hudunfantan }, { hudunfantan }, { hudunfantan }, { hudunfantan } }
                        },
                        {
                            name = "嗜血的格洛格",
                            x = -802,
                            y = -1449,
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
                                        list = { "狂暴火焰护符", "石楠之环", "黑暗魔法书", "乔丹法杖" },
                                        drop_rate = {
                                            2000,
                                            2000,
                                            2000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "源质矿石" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            300,
                                            500,
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
                                                name = "火焰风暴",
                                                notInterruptable = true,
                                                healthBelowLimit = 100,
                                                castCD = 60,
                                                shifashijian = 10,
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "让火焰淹没一切!",
                                                        10,
                                                        "ff3300",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                end,
                                                interval = 1,
                                                periodEffect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local x = hunit.x(sourceUnit)
                                                    local y = hunit.y(sourceUnit)
                                                    hskillMoban.radiusAOE(
                                                        x,
                                                        y,
                                                        sourceUnit,
                                                        1000,
                                                        function(unit)
                                                            local e =
                                                                hskillMoban.radiusWarning(
                                                                    hunit.x(unit),
                                                                    hunit.y(unit),
                                                                    hunit.z(unit),
                                                                    200,
                                                                    10
                                                                )
                                                            hskillMoban.missile(
                                                                {
                                                                    model =
                                                                    "Abilities\\Weapons\\RedDragonBreath\\RedDragonMissile.mdl",
                                                                    scale = 1.0,
                                                                    speed = 200,
                                                                    height = 500,
                                                                    hover = 150,
                                                                    sourceUnit = sourceUnit,
                                                                    targetX = hunit.x(unit),
                                                                    targetY = hunit.y(unit),
                                                                    onEnd = function(sourceUnit, targetUnit, x, y)
                                                                        heffect.destroy(e)
                                                                        hskillMoban.radiusAOE(
                                                                            x,
                                                                            y,
                                                                            sourceUnit,
                                                                            200,
                                                                            function(targetUnit)
                                                                                hskill.damage(
                                                                                    {
                                                                                        sourceUnit = sourceUnit,
                                                                                        targetUnit = targetUnit,
                                                                                        damage = hattr.get(
                                                                                                sourceUnit,
                                                                                                "attack",
                                                                                                1
                                                                                            ) *
                                                                                            (3 + nandu),
                                                                                        damageSrc = CONST_DAMAGE_SRC
                                                                                            .skill,
                                                                                        damageType = DAMAGE_TYPE.MOFA,
                                                                                        effect =
                                                                                        "Abilities\\Weapons\\RedDragonBreath\\RedDragonMissile.mdl",
                                                                                        damageSpeedType =
                                                                                            CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                                                                        damageElementType = {
                                                                                            CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                                        }
                                                                                    }
                                                                                )
                                                                            end
                                                                        )
                                                                    end
                                                                }
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
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "火球连射",
                                                notInterruptable = false,
                                                healthBelowLimit = 100,
                                                castCD = 20,
                                                shifashijian = 5,
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "尝尝我的火球吧!",
                                                        10,
                                                        "ff3300",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                end,
                                                interval = 1,
                                                periodEffect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local damage =
                                                        hattr.get(sourceUnit, "attack", 1) * (1 + nandu * 0.2)
                                                    hskillMoban.missile(
                                                        {
                                                            model =
                                                            "Abilities\\Weapons\\RedDragonBreath\\RedDragonMissile.mdl",
                                                            scale = 1.2,
                                                            speed = 800,
                                                            height = 100,
                                                            hover = 150,
                                                            sourceUnit = sourceUnit,
                                                            targetUnit = targetUnit,
                                                            onEnd = function(sourceUnit, targetUnit, x, y)
                                                                hskill.damage(
                                                                    {
                                                                        sourceUnit = sourceUnit,
                                                                        targetUnit = targetUnit,
                                                                        damage = damage,
                                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                                        damageType = DAMAGE_TYPE.MOFA,
                                                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                            .IMMEDIATE,
                                                                        damageElementType = {
                                                                            CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                        }
                                                                    }
                                                                )
                                                            end
                                                        }
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
                                                name = "追踪火球",
                                                notInterruptable = true,
                                                healthBelowLimit = 80,
                                                castCD = 30,
                                                shifashijian = 3,
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "跑的越远死的越快!",
                                                        10,
                                                        "ff3300",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local damage =
                                                        hattr.get(sourceUnit, "attack", 1) * (1.5 + nandu * 0.5)
                                                    htime.setTimeout(
                                                        10,
                                                        function(curTimer)
                                                        end
                                                    )
                                                    local scale = 1
                                                    hskillMoban.missile(
                                                        {
                                                            model =
                                                            "Abilities\\Weapons\\RedDragonBreath\\RedDragonMissile.mdl",
                                                            scale = scale,
                                                            speed = 50,
                                                            height = 100,
                                                            hover = 150,
                                                            acceleration = 0.1,
                                                            sourceUnit = sourceUnit,
                                                            targetUnit = targetUnit,
                                                            onMove = function(sourceUnit, targetUnit, x, y, missileUnit)
                                                                scale = scale + 0.005
                                                                hjapi.EXSetEffectSize(missileUnit, scale)
                                                            end,
                                                            onEnd = function(sourceUnit, targetUnit, x, y)
                                                                hskill.damage(
                                                                    {
                                                                        sourceUnit = sourceUnit,
                                                                        targetUnit = targetUnit,
                                                                        damage = damage * scale,
                                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                                        damageType = DAMAGE_TYPE.MOFA,
                                                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                            .IMMEDIATE,
                                                                        damageElementType = {
                                                                            CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                        }
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
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    hskillMoban.missile(
                                                        {
                                                            --model = "war3mapImported\\[SPELL]_115.mdl",
                                                            model =
                                                            "Abilities\\Weapons\\RedDragonBreath\\RedDragonMissile.mdl",
                                                            scale = 1.0,
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
                                                                        damage = hattr.get(sourceUnit, "attack", 0),
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
                            passiveSkill = { { shifajiasu }, { shifajiasu }, { shifajiasu }, { shifajiasu } }
                        },
                        {
                            name = "黑铁矮人索瑞森大帝",
                            x = -755,
                            y = -5128,
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
                                        list = { "野蛮斗士战甲", "沙赫拉姆黑剑", "正义之手", "有坚不催之力" },
                                        drop_rate = {
                                            2000,
                                            2000,
                                            2000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "冠军之证" },
                                        drop_rate = {
                                            0,
                                            0,
                                            500,
                                            0
                                        }
                                    },
                                    {
                                        list = { "源质矿石" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "炎魔之手锻造手札" }, --物品名字 需要在物编定义好
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
                            ai = function(level, nandu)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "邪恶之火",
                                                notInterruptable = true,
                                                healthBelowLimit = 80,
                                                castCD = 10,
                                                shifashijian = 1,
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "让你们见识见识火焰的力量!",
                                                        10,
                                                        "ff3300",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local angel = math.random(0, 360)
                                                    local x, y =
                                                        math.polarProjection(
                                                            hunit.x(sourceUnit),
                                                            hunit.y(sourceUnit),
                                                            800,
                                                            angel
                                                        )
                                                    local damage =
                                                        hattr.get(sourceUnit, "attack", 1) * (1 + 0.3 * nandu)
                                                    hskillMoban.leap(
                                                        {
                                                            tokenArrow = "[boss]suoruisen.mdx", -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                                                            sourceUnit = evtData.triggerUnit,   --伤害来源（必须有！不管有没有伤害）
                                                            targetUnit = evtData.triggerUnit,   --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                                                            --x = x, --冲击的x坐标（可选的，对点冲击，与某目标无关）
                                                            -- y = y, --冲击的y坐标（可选的，对点冲击，与某目标无关）
                                                            tokenX = x,
                                                            tokenY = y,
                                                            speed = 8, --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                                                            acceleration = 0,
                                                            shake = 0, --摇摆振幅角度[-90~+90|random]（可选的，默认0)
                                                            filter = function(enum)
                                                                return hunit.isAlive(enum) and
                                                                    hunit.isAlly(enum, sourceUnit) == false
                                                            end,                                            --必须有
                                                            tokenArrowScale = 1,                            --前冲的特效作为马甲冲击时的模型缩放
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
                                                            damageType = DAMAGE_TYPE.MOFA,
                                                            damageSkill = hslk.n2i("AI技能模版"),
                                                            oneHitOnly = true, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
                                                            endDistance = 100,
                                                            extraInfluence = function(whichUnit)
                                                                if hunit.isAlive(whichUnit) == false then
                                                                    return
                                                                end
                                                                if whichUnit == sourceUnit then
                                                                    htextTag.create2Unit(
                                                                        whichUnit,
                                                                        "吸收力量!",
                                                                        10,
                                                                        "ffff00",
                                                                        1,
                                                                        1,
                                                                        50
                                                                    )
                                                                    hbuff.addStackAttrBuff(
                                                                        CONST_DAMAGE_SRC.skill,
                                                                        whichUnit,
                                                                        "力量宝珠Buff",
                                                                        {
                                                                            attack_speed = "+30",
                                                                            skill_speed = "+30",
                                                                            wu_zengshang = "+30",
                                                                            move = "+20"
                                                                        },
                                                                        30,
                                                                        10,
                                                                        "ReplaceableTextures\\CommandButtons\\BTNOrbOfCorruption.blp",
                                                                        "吸收力量宝珠,获得30%攻速、技能加速和物理伤害和20点移动速度加成,持续30秒,可叠加"
                                                                    )
                                                                else
                                                                    hbuff.addStackAttrBuff(
                                                                        CONST_DAMAGE_SRC.skill,
                                                                        whichUnit,
                                                                        "力量宝珠Buff",
                                                                        {
                                                                            attack_speed = "+10",
                                                                            skill_speed = "+10",
                                                                            wu_zengshang = "+10",
                                                                            jianshang = "-20"
                                                                        },
                                                                        30,
                                                                        10,
                                                                        "ReplaceableTextures\\CommandButtons\\BTNOrbOfCorruption.blp",
                                                                        "吸收力量宝珠,获得10%攻速、技能加速和物理伤害加成,同时由于体量过于狂暴，受到所有伤害增加20%,持续30秒,可叠加"
                                                                    )
                                                                end
                                                            end, --对选中的敌人的额外影响，会回调该敌人单位，可以对其做出自定义行为
                                                            onEnding = function(_, _, timePassed)
                                                            end
                                                        }
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.LOWEST_HEALTH_UNIT,
                                                name = "邪恶冲击波",
                                                notInterruptable = false,
                                                healthBelowLimit = 100,
                                                castCD = 15,
                                                shifashijian = 2,
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "感受邪恶之力的冲击吧!",
                                                        10,
                                                        "e8da12",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local buffHandle = hbuff.getBuffHandle(sourceUnit, "力量宝珠Buff")
                                                    local buffCount = 0
                                                    if buffHandle ~= nil then
                                                        buffCount = buffHandle.stack or 1
                                                    end
                                                    local width = 200 + buffCount * 50
                                                    local speed = 600 + buffCount * 150
                                                    local scale = width / 200
                                                    local damage =
                                                        hattr.get(sourceUnit, "attack", 1) * (2 + 0.5 * buffCount) *
                                                        (0.8 + 0.2 * nandu)
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
                                                            1000,
                                                            angel
                                                        )
                                                    hskillMoban.leap(
                                                        {
                                                            tokenArrow = "[boss]suoruisen (2).mdx", -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                                                            sourceUnit = evtData.triggerUnit,       --伤害来源（必须有！不管有没有伤害）
                                                            --targetUnit = evtData.targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                                                            x = x,                                  --冲击的x坐标（可选的，对点冲击，与某目标无关）
                                                            y = y,                                  --冲击的y坐标（可选的，对点冲击，与某目标无关）
                                                            speed = speed / 50,                     --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                                                            acceleration = 0,
                                                            shake = 0,                              --摇摆振幅角度[-90~+90|random]（可选的，默认0)
                                                            filter = function(enum)
                                                                return hunit.isEnemy(evtData.triggerUnit, enum) and
                                                                    hunit.isAlive(enum)
                                                            end,                                            --必须有
                                                            tokenArrowScale = scale,                        --前冲的特效作为马甲冲击时的模型缩放
                                                            tokenArrowOpacity = 1.00,                       --前冲的特效作为马甲冲击时的模型透明度[0-1]
                                                            tokenArrowHeight = 0.00,                        --前冲的特效作为马甲冲击时的初始离地高度
                                                            effectMovement = nil,                           --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                                            animateMovement = 1,
                                                            effectEnd = nil,                                --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                                            damageMovement = damage,                        --移动过程中的伤害（可选的，默认为0）
                                                            damageMovementRadius = width,                   --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
                                                            damageMovementRepeat = false,                   --移动过程中伤害是否可以重复造成（可选的，默认为不能）
                                                            damageMovementDrag = false,                     --移动过程是否拖拽敌人（可选的，默认为不能）
                                                            damageEndRadius = 0,                            --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
                                                            damageSrc = CONST_DAMAGE_SRC.skill,             --伤害的种类（可选）
                                                            damageEffect = "war3mapImported\\AZ_gelie.mdx", --伤害特效（可选）
                                                            damageType = DAMAGE_TYPE.MOFA,
                                                            damageSkill = hslk.n2i("AI技能模版"),
                                                            oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
                                                            endDistance = 0,
                                                            extraInfluence = function(whichUnit)
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
                            passiveSkill = { { lianji }, { lianji }, { lianji }, { lianji } }
                        }
                    },
                    tongguanjiangli = {
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience, value = 7000 },
                                { type = HSHOP_COST_TYPE.gold,       value = 600 }
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
                                { type = HSHOP_COST_TYPE.experience,     value = 10000 },
                                { type = HSHOP_COST_TYPE.gold,           value = 800 },
                                { type = HSHOP_COST_TYPE.yongqihuizhang, value = 1 }
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
                                { type = HSHOP_COST_TYPE.experience,     value = 15000 },
                                { type = HSHOP_COST_TYPE.gold,           value = 1200 },
                                { type = HSHOP_COST_TYPE.yongqihuizhang, value = 2 }
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
                                { type = HSHOP_COST_TYPE.gold,           value = 1500 },
                                { type = HSHOP_COST_TYPE.yongqihuizhang, value = 3 }
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
