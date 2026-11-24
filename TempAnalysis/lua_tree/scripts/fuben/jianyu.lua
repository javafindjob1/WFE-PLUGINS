table.insert(
    FUBEN_LIST,
    {
        name = "王城监狱",
        setup = function()
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

            local touxiAI = {
                aiType = UNIT_AI_TYPE.CAST_SKILL,
                aiData = {
                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                    name = "搏击",
                    --castCountLimit = 1, -- cast only x times per battle
                    minNandu = FUBEN_NANDU.PUTONG,
                    castCD = 10,           -- nil or <=1 means 1 second
                    healthBelowLimit = 70, -- only cast when health is < 65%
                    startEffect = function(evtData)
                        hskillMoban.radiusWarning(
                            hunit.x(evtData.triggerUnit),
                            hunit.y(evtData.triggerUnit),
                            hunit.z(evtData.triggerUnit),
                            250,
                            1
                        )
                    end,
                    --interval = 1,
                    periodEffect = function(evtData, curTimer)
                    end,
                    effect = function(evtData)
                        local sourceUnit = evtData.triggerUnit
                        local targetUnit = evtData.targetUnit
                        local distance =
                            math.distance(
                                hunit.x(sourceUnit),
                                hunit.y(sourceUnit),
                                hunit.x(targetUnit),
                                hunit.y(targetUnit)
                            )
                        if distance <= 250 then
                            htextTag.create2Unit(sourceUnit, "成功击晕", 10, "ff3300", 1, 1, 50)
                            hbuff.xuanyun(targetUnit, hunit.getNandu(sourceUnit))
                            local attackSpeed = hunit.getNandu(sourceUnit) * 5 + 10
                            hskill.damage(
                                {
                                    sourceUnit = sourceUnit,
                                    targetUnit = targetUnit,
                                    damage = 2 * hattr.get(sourceUnit, "attack", 0),
                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                    damageType = DAMAGE_TYPE.WULI,
                                    triggerSkill = hslk.n2i("AI技能模版"),
                                    damageElementType = CONST_DAMAGE_ELEMENT_TYPE.METAL,
                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                }
                            )
                            hbuff.update(
                                5,
                                sourceUnit,
                                "成功击晕",
                                true,
                                function()
                                    hattribute.set(sourceUnit, 0, { attack_speed = "+" .. tostring(attackSpeed) })
                                end,
                                function()
                                    hattribute.set(sourceUnit, 0, { attack_speed = "-" .. tostring(attackSpeed) })
                                end,
                                "ReplaceableTextures\\CommandButtons\\BTNTemp.blp",
                                "乘胜追击，攻击速度增加了" .. tostring(attackSpeed) .. "%",
                                1,
                                nil,
                                nil,
                                nil,
                                nil,
                                HBUFF_UPDATE_MODE.OVERWRITE,
                                true
                            )
                        else
                            htextTag.create2Unit(sourceUnit, "搏击失败", 10, "ff3300", 1, 1, 50)
                            hbuff.update(
                                5,
                                sourceUnit,
                                "搏击失败",
                                true,
                                function()
                                    hattribute.set(sourceUnit, 0, { attack_speed = "-15" })
                                end,
                                function()
                                    hattribute.set(sourceUnit, 0, { attack_speed = "+15" })
                                end,
                                "ReplaceableTextures\\CommandButtons\\BTNTemp.blp",
                                "搏击失败所以攻击速度降低了15%",
                                1,
                                nil,
                                nil,
                                nil,
                                nil,
                                HBUFF_UPDATE_MODE.OVERWRITE,
                                true
                            )
                        end
                    end,
                    castDistance = 200,
                    shifashijian = 2
                }
            }
            local jinzhanAI =
                UnitAI(
                    {
                        touxiAI,
                        {
                            aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                            }
                        }
                    }
                )

            local cuduwuqi = {
                description = "所有攻击附加攻击力20%的毒性伤害",
                attr_type = CONST_EVENT.attack,
                attr = function(evtData)
                    local sourceUnit = evtData.triggerUnit
                    local targetUnit = evtData.targetUnit
                    heffect.attach("Abilities\\Weapons\\PoisonSting\\PoisonStingTarget.mdl", targetUnit, "chest", 0.1)
                    local damageScale = 0.2
                    local buffHandle = hbuff.getBuffHandle(targetUnit, "剧毒")
                    if buffHandle ~= nil then
                        damageScale = damageScale * (1 + buffHandle.stack * 0.2)
                    end
                    hskill.damage(
                        {
                            sourceUnit = sourceUnit,
                            targetUnit = targetUnit,
                            damage = damageScale * hattr.get(sourceUnit, "attack", 0),
                            damageSrc = CONST_DAMAGE_SRC.skill,
                            damageType = DAMAGE_TYPE.MOFA,
                            triggerSkill = hslk.n2i("AI技能模版"),
                            damageElementType = CONST_DAMAGE_ELEMENT_TYPE.WOOD,
                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                        }
                    )
                end
            }

            local nanduLevelConfig = {}
            nanduLevelConfig[FUBEN_NANDU.PUTONG] = 25
            nanduLevelConfig[FUBEN_NANDU.YINGXIONG] = 25
            nanduLevelConfig[FUBEN_NANDU.SHISHI] = 25
            nanduLevelConfig[FUBEN_NANDU.CHUANQI] = 60
            hfuben.buildFuben(
                {
                    name = "王城监狱", --副本名字
                    status = FUBEN_STATUS.JIANHUA,
                    blp = "ReplaceableTextures\\xiaoditu\\UI_map_06.blp",
                    enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_08.blp",
                    nanduLevelConfig = nanduLevelConfig,                                    -- 副本难度以及级别需求,
                    entryPosition = { x = -27851, y = -21476 },
                    startPosition = { x = -18101, y = 5128 },                               --英雄进副本后位置
                    rectParam = { minX = -18325, minY = 4550, maxX = -13128, maxY = 7852 }, -- 副本区域
                    minions = {
                        -- 小怪设定
                        {
                            name = "精英强盗", -- 名字 需要在物编定义好
                            x = -16755, -- 小怪刷新x坐标
                            y = 5110, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = jinzhanAI
                        },
                        {
                            name = "精英强盗", -- 名字 需要在物编定义好
                            x = -15834, -- 小怪刷新x坐标
                            y = 5110, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = jinzhanAI
                        },
                        {
                            name = "精英土匪", -- 名字 需要在物编定义好
                            x = -15534, -- 小怪刷新x坐标
                            y = 5110, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { cuduwuqi }, { cuduwuqi }, { cuduwuqi }, { cuduwuqi } }
                        },
                        {
                            name = "精英强盗", -- 名字 需要在物编定义好
                            x = -14476, -- 小怪刷新x坐标
                            y = 5110, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = jinzhanAI
                        },
                        {
                            name = "精英土匪", -- 名字 需要在物编定义好
                            x = -13406, -- 小怪刷新x坐标
                            y = 5380, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { cuduwuqi }, { cuduwuqi }, { cuduwuqi }, { cuduwuqi } }
                        },
                        {
                            name = "精英土匪", -- 名字 需要在物编定义好
                            x = -13406, -- 小怪刷新x坐标
                            y = 4800, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { cuduwuqi }, { cuduwuqi }, { cuduwuqi }, { cuduwuqi } }
                        },
                        {
                            name = "精英强盗", -- 名字 需要在物编定义好
                            x = -16347, -- 小怪刷新x坐标
                            y = 6646, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = jinzhanAI
                        },
                        {
                            name = "精英强盗", -- 名字 需要在物编定义好
                            x = -15047, -- 小怪刷新x坐标
                            y = 7426, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = jinzhanAI
                        },
                        {
                            name = "精英强盗", -- 名字 需要在物编定义好
                            x = -15020, -- 小怪刷新x坐标
                            y = 5895, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = jinzhanAI
                        },
                        {
                            name = "精英强盗", -- 名字 需要在物编定义好
                            x = -13948, -- 小怪刷新x坐标
                            y = 5918, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = jinzhanAI
                        },
                        {
                            name = "精英强盗", -- 名字 需要在物编定义好
                            x = -17400, -- 小怪刷新x坐标
                            y = 5928, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = jinzhanAI
                        },
                        {
                            name = "精英强盗", -- 名字 需要在物编定义好
                            x = -18039, -- 小怪刷新x坐标
                            y = 7400, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = jinzhanAI
                        },
                        {
                            name = "精英强盗", -- 名字 需要在物编定义好
                            x = -16888, -- 小怪刷新x坐标
                            y = 7400, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = jinzhanAI
                        }
                    },
                    bosses = {
                        {
                            name = "暴徒洛克",
                            x = -13546,
                            y = 5056,
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
                                        list = { "老旧战锤", "老旧的皮甲", "激怒护符" }, --物品名字 需要在物编定义好
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
                            ai = UnitAI(
                                {
                                    {
                                        aiType = UNIT_AI_TYPE.CAST_SKILL,
                                        aiData = {
                                            targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                            name = "激怒",
                                            healthBelowLimit = 50,
                                            --cast when life is below 50%
                                            castCD = 15, -- nil or <=1 means 1 second
                                            startEffect = function(evtData)
                                            end,
                                            periodEffect = function(evtData)
                                            end,
                                            effect = function(evtData)
                                                local attack = hattribute.get(evtData.triggerUnit, "attack_white", 10)
                                                hbuff.update(
                                                    5,
                                                    evtData.triggerUnit,
                                                    "激怒",
                                                    true,
                                                    function()
                                                        hattribute.set(
                                                            evtData.triggerUnit,
                                                            0,
                                                            {
                                                                attack = "+" .. tostring(attack * 0.5),
                                                                attack_speed = "+50"
                                                            }
                                                        )
                                                    end,
                                                    function()
                                                        hattribute.set(
                                                            evtData.triggerUnit,
                                                            0,
                                                            {
                                                                attack = "-" .. tostring(attack * 0.5),
                                                                attack_speed = "-50"
                                                            }
                                                        )
                                                    end,
                                                    "ReplaceableTextures\\PASBTN_KRDS_KBZX.blp",
                                                    "攻击力和攻击速度提高50%，持续5秒",
                                                    1,
                                                    nil,
                                                    nil,
                                                    nil,
                                                    nil,
                                                    HBUFF_UPDATE_MODE.OVERWRITE,
                                                    true
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
                            )
                        },
                        {
                            name = "屠杀者霍克",
                            x = -17536,
                            y = 7100,
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
                                        list = { "霍克的武器链", "精准打击手套", "带刺项圈" }, --物品名字 需要在物编定义好
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
                            ai = UnitAI(
                                {
                                    {
                                        aiType = UNIT_AI_TYPE.CAST_SKILL,
                                        aiData = {
                                            targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                            name = "蓄力暴击",
                                            healthBelowLimit = 30,
                                            --cast when life is below 50%
                                            castCD = 15, -- nil or <=1 means 1 second
                                            startEffect = function(evtData)
                                                hskillMoban.radiusWarning(
                                                    hunit.x(evtData.targetUnit),
                                                    hunit.y(evtData.targetUnit),
                                                    hunit.z(evtData.targetUnit),
                                                    100,
                                                    1
                                                )
                                            end,
                                            periodEffect = function(evtData)
                                            end,
                                            effect = function(evtData)
                                                local attack = hattribute.get(evtData.triggerUnit, "attack_white", 10)
                                                heffect.xyz(
                                                    "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl",
                                                    evtData.targetX,
                                                    evtData.targetY,
                                                    hunit.z(evtData.triggerUnit),
                                                    0,
                                                    0.8,
                                                    0.8,
                                                    1,
                                                    1,
                                                    nil,
                                                    nil,
                                                    nil
                                                )
                                                hskillMoban.radiusAOE(
                                                    evtData.targetX,
                                                    evtData.targetY,
                                                    evtData.triggerUnit,
                                                    100,
                                                    function(target)
                                                        hskill.damage(
                                                            {
                                                                sourceUnit = evtData.triggerUnit,
                                                                targetUnit = target,
                                                                damage = attack * 4,
                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                damageType = DAMAGE_TYPE.WULI,
                                                                triggerSkill = hslk.n2i("AI技能模版"),
                                                                damageElementType = CONST_DAMAGE_ELEMENT_TYPE.METAL,
                                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                            }
                                                        )
                                                        hbuff.xuanyun(target, 3)
                                                    end
                                                )
                                            end,
                                            shifashijian = 1.3,
                                            castDistance = 200
                                        }
                                    },
                                    {
                                        aiType = UNIT_AI_TYPE.CAST_SKILL,
                                        aiData = {
                                            targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                            name = "蓄力猛击",
                                            healthBelowLimit = 60,
                                            --cast when life is below 50%
                                            castCD = 15, -- nil or <=1 means 1 second
                                            startEffect = function(evtData)
                                                hskillMoban.radiusWarning(
                                                    hunit.x(evtData.targetUnit),
                                                    hunit.y(evtData.targetUnit),
                                                    hunit.z(evtData.targetUnit),
                                                    150,
                                                    1
                                                )
                                            end,
                                            periodEffect = function(evtData)
                                            end,
                                            effect = function(evtData)
                                                heffect.xyz(
                                                    "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl",
                                                    evtData.targetX,
                                                    evtData.targetY,
                                                    hunit.z(evtData.triggerUnit),
                                                    0,
                                                    0.9,
                                                    0.9,
                                                    1,
                                                    1,
                                                    nil,
                                                    nil,
                                                    nil
                                                )
                                                local attack = hattribute.get(evtData.triggerUnit, "attack_white", 10)
                                                hskillMoban.radiusAOE(
                                                    evtData.targetX,
                                                    evtData.targetY,
                                                    evtData.triggerUnit,
                                                    150,
                                                    function(target)
                                                        hskill.damage(
                                                            {
                                                                sourceUnit = evtData.triggerUnit,
                                                                targetUnit = target,
                                                                damage = attack * 4,
                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                damageType = DAMAGE_TYPE.WULI,
                                                                triggerSkill = hslk.n2i("AI技能模版"),
                                                                damageElementType = CONST_DAMAGE_ELEMENT_TYPE.METAL,
                                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                            }
                                                        )
                                                        hbuff.xuanyun(target, 2)
                                                    end
                                                )
                                            end,
                                            shifashijian = 1.3,
                                            castDistance = 200
                                        }
                                    },
                                    {
                                        aiType = UNIT_AI_TYPE.CAST_SKILL,
                                        aiData = {
                                            targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                            name = "蓄力一击",
                                            healthBelowLimit = 90,
                                            --cast when life is below 50%
                                            castCD = 15, -- nil or <=1 means 1 second
                                            startEffect = function(evtData)
                                                hskillMoban.radiusWarning(
                                                    hunit.x(evtData.targetUnit),
                                                    hunit.y(evtData.targetUnit),
                                                    hunit.z(evtData.targetUnit),
                                                    200,
                                                    1
                                                )
                                            end,
                                            periodEffect = function(evtData)
                                            end,
                                            effect = function(evtData)
                                                heffect.xyz(
                                                    "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl",
                                                    evtData.targetX,
                                                    evtData.targetY,
                                                    hunit.z(evtData.triggerUnit),
                                                    0,
                                                    1,
                                                    1,
                                                    1,
                                                    1,
                                                    nil,
                                                    nil,
                                                    nil
                                                )
                                                local attack = hattribute.get(evtData.triggerUnit, "attack_white", 10)
                                                hskillMoban.radiusAOE(
                                                    evtData.targetX,
                                                    evtData.targetY,
                                                    evtData.triggerUnit,
                                                    200,
                                                    function(target)
                                                        hskill.damage(
                                                            {
                                                                sourceUnit = evtData.triggerUnit,
                                                                targetUnit = target,
                                                                damage = attack * 3,
                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                damageType = DAMAGE_TYPE.WULI,
                                                                triggerSkill = hslk.n2i("AI技能模版"),
                                                                damageElementType = CONST_DAMAGE_ELEMENT_TYPE.METAL,
                                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                            }
                                                        )
                                                        hbuff.xuanyun(target, 1)
                                                    end
                                                )
                                            end,
                                            shifashijian = 1.3,
                                            castDistance = 200
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
                        },
                        {
                            name = "监狱之王范克瑞夫",
                            x = -13963,
                            y = 6700,
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
                                        list = { "古老的历史文献" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            1000,
                                            2000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "残酷倒钩", "灵敏披风", "灵动皮靴", "浸毒箭袋" }, --物品名字 需要在物编定义好
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
                            ai = UnitAI(
                                {
                                    {
                                        aiType = UNIT_AI_TYPE.CAST_SKILL,
                                        aiData = {
                                            targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                            name = "激怒",
                                            healthBelowLimit = 10,
                                            minNandu = FUBEN_NANDU.YINGXIONG,
                                            --cast when life is below 50%
                                            castCD = 300, -- nil or <=1 means 1 second
                                            startEffect = function(evtData)
                                            end,
                                            periodEffect = function(evtData)
                                            end,
                                            effect = function(evtData)
                                                local attack = hattribute.get(evtData.triggerUnit, "attack_white", 10)
                                                hbuff.update(
                                                    20,
                                                    evtData.triggerUnit,
                                                    "激怒",
                                                    true,
                                                    function()
                                                        hattribute.set(
                                                            evtData.triggerUnit,
                                                            0,
                                                            {
                                                                attack = "+" .. tostring(0.5 * attack),
                                                                attack_speed = "+50"
                                                            }
                                                        )
                                                    end,
                                                    function()
                                                        hattribute.set(
                                                            evtData.triggerUnit,
                                                            0,
                                                            {
                                                                attack = "-" .. tostring(0.5 * attack),
                                                                attack_speed = "-50"
                                                            }
                                                        )
                                                    end,
                                                    "ReplaceableTextures\\PASBTN_KRDS_KBZX.blp",
                                                    "攻击力和攻击速度提高50%，持续5秒",
                                                    1,
                                                    nil,
                                                    nil,
                                                    nil,
                                                    nil,
                                                    HBUFF_UPDATE_MODE.OVERWRITE,
                                                    true
                                                )
                                            end,
                                            shifashijian = 2
                                        }
                                    },
                                    {
                                        aiType = UNIT_AI_TYPE.CAST_SKILL,
                                        aiData = {
                                            targetType = UNIT_AI_TARGET_TYPE.LOWEST_HEALTH_UNIT,
                                            name = "冷箭",
                                            healthBelowLimit = 80,
                                            --cast when life is below 50%
                                            castCD = 8, -- nil or <=1 means 1 second
                                            startEffect = function(evtData)
                                            end,
                                            periodEffect = function(evtData)
                                            end,
                                            effect = function(evtData)
                                                local sourceUnit = evtData.triggerUnit
                                                local targetUnit = evtData.targetUnit
                                                local nandu = hunit.getNandu(sourceUnit)
                                                local dotDamage = hunit.getMaxLife(targetUnit) * 0.01 + 15 * nandu
                                                hskillMoban.missile(
                                                    {
                                                        --model = "war3mapImported\\[SPELL]_115.mdl",
                                                        model =
                                                        "war3mapImported\\[lieren]SylvanusWindrunnePFr_Attack.mdl",
                                                        scale = 1.0,
                                                        speed = 2000,
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
                                                                    damageType = DAMAGE_TYPE.WULI,
                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                    damageElementType = CONST_DAMAGE_ELEMENT_TYPE.METAL,
                                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                                }
                                                            )
                                                            hbuff.update(
                                                                15,
                                                                targetUnit,
                                                                "剧毒",
                                                                false,
                                                                nil,
                                                                nil,
                                                                "ReplaceableTextures\\CommandButtons\\BTNEnvenomedSpear.blp",
                                                                "范克瑞夫的特制毒药，每秒造成最大生命值1%+" ..
                                                                tostring(dotDamage) ..
                                                                "的的毒性伤害，不叠加。同时每层可以使目标受到淬毒武器伤害增加20%，可叠加",
                                                                1,
                                                                1,
                                                                function(curTimer, buffHandle)
                                                                    heffect.attach(
                                                                        "Abilities\\Weapons\\PoisonSting\\PoisonStingTarget.mdl",
                                                                        targetUnit,
                                                                        "chest",
                                                                        0.1
                                                                    )
                                                                    buffHandle.remainingTime =
                                                                        buffHandle.remainingTime - 1
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = sourceUnit,
                                                                            targetUnit = targetUnit,
                                                                            damage = dotDamage,
                                                                            effect = "effect",
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.WULI,
                                                                            triggerSkill = hslk.n2i("AI技能模版"),
                                                                            damageElementType = CONST_DAMAGE_ELEMENT_TYPE
                                                                                .WOOD,
                                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                .DOT,
                                                                            shanghainame = "冷箭毒药"
                                                                        }
                                                                    )
                                                                end,
                                                                function(buffHandle)
                                                                    buffHandle.remainingTime = 15
                                                                end,
                                                                nil,
                                                                HBUFF_UPDATE_MODE.UPDATE,
                                                                true
                                                            )
                                                        end
                                                    }
                                                )
                                            end,
                                            shifashijian = 1.5
                                        }
                                    },
                                    {
                                        aiType = UNIT_AI_TYPE.CAST_SKILL,
                                        aiData = {
                                            targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                            name = "搏击",
                                            --castCountLimit = 1, -- cast only x times per battle
                                            minNandu = FUBEN_NANDU.PUTONG,
                                            castCD = 10,           -- nil or <=1 means 1 second
                                            healthBelowLimit = 70, -- only cast when health is < 65%
                                            startEffect = function(evtData)
                                                hskillMoban.radiusWarning(
                                                    hunit.x(evtData.triggerUnit),
                                                    hunit.y(evtData.triggerUnit),
                                                    hunit.z(evtData.triggerUnit),
                                                    250,
                                                    1
                                                )
                                            end,
                                            --interval = 1,
                                            periodEffect = function(evtData, curTimer)
                                            end,
                                            effect = function(evtData)
                                                local sourceUnit = evtData.triggerUnit
                                                local targetUnit = evtData.targetUnit
                                                local distance =
                                                    math.distance(
                                                        hunit.x(sourceUnit),
                                                        hunit.y(sourceUnit),
                                                        hunit.x(targetUnit),
                                                        hunit.y(targetUnit)
                                                    )
                                                if distance <= 250 then
                                                    htextTag.create2Unit(sourceUnit, "成功击晕", 10, "ff3300", 1, 1, 50)
                                                    hbuff.xuanyun(targetUnit, hunit.getNandu(sourceUnit))
                                                    local attackSpeed = hunit.getNandu(sourceUnit) * 5 + 10
                                                    hskill.damage(
                                                        {
                                                            sourceUnit = sourceUnit,
                                                            targetUnit = targetUnit,
                                                            damage = 2 * hattr.get(sourceUnit, "attack", 0),
                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                            damageType = DAMAGE_TYPE.WULI,
                                                            triggerSkill = hslk.n2i("AI技能模版"),
                                                            damageElementType = CONST_DAMAGE_ELEMENT_TYPE.METAL,
                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                        }
                                                    )
                                                    hbuff.update(
                                                        5,
                                                        sourceUnit,
                                                        "成功击晕",
                                                        true,
                                                        function()
                                                            hattribute.set(
                                                                sourceUnit,
                                                                0,
                                                                { attack_speed = "+" .. tostring(attackSpeed) }
                                                            )
                                                        end,
                                                        function()
                                                            hattribute.set(
                                                                sourceUnit,
                                                                0,
                                                                { attack_speed = "-" .. tostring(attackSpeed) }
                                                            )
                                                        end,
                                                        "ReplaceableTextures\\CommandButtons\\BTNTemp.blp",
                                                        "乘胜追击，攻击速度增加了" .. tostring(attackSpeed) .. "%",
                                                        1,
                                                        nil,
                                                        nil,
                                                        nil,
                                                        nil,
                                                        HBUFF_UPDATE_MODE.OVERWRITE,
                                                        true
                                                    )
                                                else
                                                    htextTag.create2Unit(sourceUnit, "搏击失败", 10, "ff3300", 1, 1, 50)
                                                    hbuff.update(
                                                        5,
                                                        sourceUnit,
                                                        "搏击失败",
                                                        true,
                                                        function()
                                                            hattribute.set(sourceUnit, 0, { attack_speed = "-15" })
                                                        end,
                                                        function()
                                                            hattribute.set(sourceUnit, 0, { attack_speed = "+15" })
                                                        end,
                                                        "ReplaceableTextures\\CommandButtons\\BTNTemp.blp",
                                                        "搏击失败所以攻击速度降低了15%",
                                                        1,
                                                        nil,
                                                        nil,
                                                        nil,
                                                        nil,
                                                        HBUFF_UPDATE_MODE.OVERWRITE,
                                                        true
                                                    )
                                                end
                                            end,
                                            castDistance = 200,
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
                            ),
                            passiveSkill = { { cuduwuqi }, { cuduwuqi }, { cuduwuqi }, { cuduwuqi } }
                        }
                    },
                    tongguanjiangli = {
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience, value = 2000 },
                                { type = HSHOP_COST_TYPE.gold,       value = 400 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 0,
                                    shengwangname = "王城"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience,        value = 3000 },
                                { type = HSHOP_COST_TYPE.gold,              value = 500 },
                                { type = HSHOP_COST_TYPE.gongzhenghuizhang, value = 1 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 1,
                                    shengwangname = "王城"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience,        value = 4000 },
                                { type = HSHOP_COST_TYPE.gold,              value = 600 },
                                { type = HSHOP_COST_TYPE.gongzhenghuizhang, value = 2 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 2,
                                    shengwangname = "王城"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience,        value = 5000 },
                                { type = HSHOP_COST_TYPE.gold,              value = 500 },
                                { type = HSHOP_COST_TYPE.gongzhenghuizhang, value = 2 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 3,
                                    shengwangname = "王城"
                                }
                            }
                        }
                    }
                }
            )
        end
    }
)
