table.insert(
    FUBEN_LIST,
    {
        name = "破碎大厅",
        setup = function()
            local nanduLevelConfig = {}
            nanduLevelConfig[FUBEN_NANDU.PUTONG] = 62
            nanduLevelConfig[FUBEN_NANDU.YINGXIONG] = 70
            nanduLevelConfig[FUBEN_NANDU.SHISHI] = 70
            nanduLevelConfig[FUBEN_NANDU.CHUANQI] = 71

            local status = FUBEN_STATUS.JIANHUA
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
            local lianji = {
                description = "双重攻击:卡加斯的攻击有20%概率额外造成一次攻击伤害,该技能可连续触发",
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

            local jinu = {
                {
                    aiType = UNIT_AI_TYPE.CAST_SKILL,
                    aiData = {
                        targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                        name = "激怒",
                        healthBelowLimit = 30,
                        castCountLimit = 1,
                        shifashijian = 1,
                        notInterruptable = true,
                        --cast when life is below 50%
                        castCD = 15, -- nil or <=1 means 1 second
                        startEffect = function(evtData)
                            htextTag.create2Unit(evtData.triggerUnit, "为了酋长!", 10, "e8da12", 1, 1, 50)
                        end,
                        periodEffect = function(evtData)
                        end,
                        effect = function(evtData)
                            local attack = hattribute.get(evtData.triggerUnit, "attack_white", 10)
                            hbuff.update(
                                60,
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
                                end,
                                "ReplaceableTextures\\PASBTN_KRDS_KBZX.blp",
                                "攻击力和攻击速度提高50%",
                                1,
                                nil,
                                nil,
                                nil,
                                nil,
                                HBUFF_UPDATE_MODE.OVERWRITE,
                                true
                            )
                        end
                    }
                }
            }

            hfuben.buildFuben(
                {
                    name = "破碎大厅", --副本名字
                    status = status,
                    blp = "ReplaceableTextures\\xiaoditu\\UI_map_15.blp",
                    enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_18.blp",
                    nanduLevelConfig = nanduLevelConfig,                                      -- 副本难度以及级别需求,
                    entryPosition = { x = -13934, y = -19193 },
                    startPosition = { x = -3707, y = -29710 },                                --英雄进副本后位置
                    rectParam = { minX = -9888, minY = -30321, maxX = -3470, maxY = -26359 }, -- 副本区域
                    minions = {
                        {
                            name = "精英野蛮卫兵", -- 名字 需要在物编定义好
                            x = -4812, -- 小怪刷新x坐标
                            y = -29741, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { jinu }, { jinu }, { jinu }, { jinu } },
                            ai = ai
                        },
                        {
                            name = "精英狂暴卫兵", -- 名字 需要在物编定义好
                            x = -5111, -- 小怪刷新x坐标
                            y = -29679, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { jinu }, { jinu }, { jinu }, { jinu } },
                            ai = ai
                        },
                        {
                            name = "精英射手卫兵", -- 名字 需要在物编定义好
                            x = -5928, -- 小怪刷新x坐标
                            y = -29446, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { jinu }, { jinu }, { jinu }, { jinu } },
                            ai = ai
                        },
                        {
                            name = "精英野蛮卫兵", -- 名字 需要在物编定义好
                            x = -9046, -- 小怪刷新x坐标
                            y = -29694, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { jinu }, { jinu }, { jinu }, { jinu } },
                            ai = ai
                        },
                        {
                            name = "精英狂暴卫兵", -- 名字 需要在物编定义好
                            x = -9046, -- 小怪刷新x坐标
                            y = -28965, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { jinu }, { jinu }, { jinu }, { jinu } },
                            ai = ai
                        },
                        {
                            name = "精英射手卫兵", -- 名字 需要在物编定义好
                            x = -9046, -- 小怪刷新x坐标
                            y = -28245, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { jinu }, { jinu }, { jinu }, { jinu } },
                            ai = ai
                        },
                        {
                            name = "精英野蛮卫兵", -- 名字 需要在物编定义好
                            x = -7713, -- 小怪刷新x坐标
                            y = -27276, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { jinu }, { jinu }, { jinu }, { jinu } },
                            ai = ai
                        },
                        {
                            name = "精英狂暴卫兵", -- 名字 需要在物编定义好
                            x = -7268, -- 小怪刷新x坐标
                            y = -27276, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { jinu }, { jinu }, { jinu }, { jinu } },
                            ai = ai
                        },
                        {
                            name = "精英射手卫兵", -- 名字 需要在物编定义好
                            x = -6474, -- 小怪刷新x坐标
                            y = -27276, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { jinu }, { jinu }, { jinu }, { jinu } },
                            ai = ai
                        },
                        {
                            name = "精英野蛮卫兵", -- 名字 需要在物编定义好
                            x = -5190, -- 小怪刷新x坐标
                            y = -26961, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { jinu }, { jinu }, { jinu }, { jinu } },
                            ai = ai
                        },
                        {
                            name = "精英狂暴卫兵", -- 名字 需要在物编定义好
                            x = -5190, -- 小怪刷新x坐标
                            y = -27884, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { jinu }, { jinu }, { jinu }, { jinu } },
                            ai = ai
                        },
                        {
                            name = "精英射手卫兵", -- 名字 需要在物编定义好
                            x = -4077, -- 小怪刷新x坐标
                            y = -27276, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { jinu }, { jinu }, { jinu }, { jinu } },
                            ai = ai
                        },
                        {
                            name = "精英射手卫兵", -- 名字 需要在物编定义好
                            x = -4077, -- 小怪刷新x坐标
                            y = -27893, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { jinu }, { jinu }, { jinu }, { jinu } },
                            ai = ai
                        },
                    },
                    bosses = {
                        {
                            name = "高阶术士",
                            x = -7030,
                            y = -29469,
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
                                            "纷争勇士战靴",
                                            "高阶术士魔典",
                                            "微光指环",
                                            "獠牙祭品"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1200,
                                            1200,
                                            1200,
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
                                                targetType = UNIT_AI_TARGET_TYPE.RANDOM_ENERMY_UNIT,
                                                name = "黑暗之脊",
                                                healthBelowLimit = 25,
                                                --castCountLimit = 1,
                                                shifashijian = 1.5,
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
                                                    local damage = hattribute.get(sourceUnit, "attack", 10) * 0.7
                                                    hbuff.addStackAttrBuff(
                                                        CONST_DAMAGE_SRC.skill,
                                                        sourceUnit,
                                                        "黑暗之脊吟唱",
                                                        { skill_speed = "+10" },
                                                        60,
                                                        20,
                                                        "ReplaceableTextures\\CommandButtons\\BTNFireBolt.blp",
                                                        "吟唱加速:每次施放黑暗之脊,会增加10%技能施法速度,可叠加20层",
                                                        true
                                                    )
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(sourceUnit),
                                                        sourceUnit,
                                                        function(targetUnit)
                                                            hskillMoban.missile(
                                                                {
                                                                    --model = "war3mapImported\\[SPELL]_115.mdl",
                                                                    model = "war3mapImported\\[Spell]_1111_new.mdl",
                                                                    scale = 1.2,
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
                                                                                damage = damage,
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
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.RANDOM_ENERMY_UNIT,
                                                name = "暗影凋零",
                                                healthBelowLimit = 90,
                                                --castCountLimit = 1,
                                                shifashijian = 2,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = true,
                                                castCD = 30, -- nil or <=1 means 1 second
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    hbuff.kongju(evtData.targetUnit, 5)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                                name = "次级暗影裂隙",
                                                healthBelowLimit = 90,
                                                --castCountLimit = 1,
                                                shifashijian = 2,
                                                notInterruptable = true,
                                                --cast when life is below 50%
                                                castCD = 15, -- nil or <=1 means 1 second
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local whichUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local duration = 20 + 5 * nandu
                                                    local x = hunit.x(targetUnit)
                                                    local y = hunit.y(targetUnit)
                                                    local z = hjapi.Z(x, y)
                                                    -- TODO 加雷池特效
                                                    heffect.xyz(
                                                        "war3mapImported\\ShadowWell.mdx",
                                                        x,
                                                        y,
                                                        z,
                                                        duration,
                                                        1, 1.2, 1.2, 1.2
                                                    )
                                                    htime.setInterval(
                                                        1,
                                                        function(curTimer)
                                                            if curTimer.passedSec() < 2 then
                                                                return
                                                            end
                                                            if curTimer.passedSec() > duration then
                                                                curTimer.destroy()
                                                                return
                                                            end
                                                            local damage =
                                                                hattribute.getWithLimit(whichUnit, nil, "attack", 0) *
                                                                0.5
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
                                                                                CONST_DAMAGE_ELEMENT_TYPE.DARK
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
                                                targetType = UNIT_AI_TARGET_TYPE.RANDOM_ENERMY_UNIT,
                                                name = "暗影顺劈",
                                                --healthBelowLimit = 90,
                                                --castCountLimit = 1,
                                                shifashijian = 2,
                                                notInterruptable = false,
                                                --cast when life is below 50%
                                                castCD = 8, -- nil or <=1 means 1 second
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local damage = hattribute.get(sourceUnit, "attack", 10)
                                                    heffect.xyz(
                                                        "war3mapImported\\[zhanshi]Cleave_Cast_Base_Purple.mdx",
                                                        hunit.x(targetUnit),
                                                        hunit.y(targetUnit),
                                                        hunit.z(targetUnit),
                                                        0,
                                                        1,
                                                        1.5,
                                                        1.5,
                                                        1.5,
                                                        nil,
                                                        nil,
                                                        hunit.getFacing(sourceUnit)
                                                    )
                                                    hskillMoban.radiusAOE(
                                                        hunit.x(targetUnit),
                                                        hunit.y(targetUnit),
                                                        sourceUnit,
                                                        300,
                                                        function(target)
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = sourceUnit,
                                                                    targetUnit = target,
                                                                    damage = damage,
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                    damageElementType = {
                                                                        CONST_DAMAGE_ELEMENT_TYPE.DARK
                                                                    },
                                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                                }
                                                            )
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
                            passiveSkill = { {}, {}, {}, {} }
                        },
                        {
                            name = "战争使者",
                            x = -8653,
                            y = -27344,
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
                                            "纷争勇士战盔",
                                            "鲜血指环",
                                            "荣耀的召唤",
                                            "冲突箭袋"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1200,
                                            1200,
                                            1200,
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
                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                name = "恐惧一击",
                                                onlyInFight = true,
                                                castCD = 30,
                                                --castCountLimit = 1,
                                                shifashijian = 2,
                                                castDistance = 400,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 90, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    hskillMoban.radiusWarning(
                                                        hunit.x(sourceUnit),
                                                        hunit.y(sourceUnit),
                                                        hjapi.Z(hunit.x(sourceUnit), hunit.y(sourceUnit)),
                                                        400,
                                                        evtData.shifashijian
                                                    )
                                                end,
                                                endEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    hskillMoban.radiusAOE(
                                                        hunit.x(sourceUnit),
                                                        hunit.y(sourceUnit),
                                                        sourceUnit,
                                                        400,
                                                        function(target)
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = sourceUnit,
                                                                    targetUnit = target,
                                                                    damage = hattribute.getWithLimit(
                                                                        sourceUnit,
                                                                        nil,
                                                                        "attack",
                                                                        0
                                                                    ) * 5,
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                    damageElementType = {
                                                                        CONST_DAMAGE_ELEMENT_TYPE.METAL
                                                                    }
                                                                }
                                                            )
                                                            hbuff.update(
                                                                10,
                                                                evtData.targetUnit,
                                                                "恐惧一击",
                                                                false,
                                                                function()
                                                                    hattr.set(
                                                                        evtData.targetUnit,
                                                                        0,
                                                                        { attack_speed = "-35", move = "-100" }
                                                                    )
                                                                end,
                                                                function()
                                                                    hattr.set(
                                                                        evtData.targetUnit,
                                                                        0,
                                                                        { attack_speed = "+35", move = "+100" }
                                                                    )
                                                                end,
                                                                "ReplaceableTextures\\SHUSHI\\kongju.blp",
                                                                "恐惧一击|n降低35%攻击速度和移动速度",
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
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.RANDOM_ENERMY_UNIT,
                                                name = "追击",
                                                onlyInFight = true,
                                                castCD = 30,
                                                --castCountLimit = 1,
                                                shifashijian = 2,
                                                castDistance = 400,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 50, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "你千万不要被我追上 哈哈哈哈！！!",
                                                        10,
                                                        "e8da12",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                end,
                                                endEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    hbuff.update(
                                                        10,
                                                        targetUnit,
                                                        "被盯上了",
                                                        false,
                                                        function()
                                                        end,
                                                        function()
                                                        end,
                                                        "ReplaceableTextures\\SHUSHI\\kongju.blp",
                                                        "被盯上了|n你被盯上了，快跑！",
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
                                                            hcache.set(sourceUnit, "AI_SKILL_EFFECT", true)
                                                            hattr.set(
                                                                sourceUnit,
                                                                0,
                                                                { attack_speed = "+30", move = "+120" }
                                                            )
                                                        end,
                                                        function()
                                                            hcache.set(sourceUnit, "AI_SKILL_EFFECT", false)
                                                            hattr.set(
                                                                sourceUnit,
                                                                0,
                                                                { attack_speed = "-30", move = "-120" }
                                                            )
                                                        end,
                                                        "ReplaceableTextures\\SHUSHI\\kongju.blp",
                                                        "追击|n战争使者会追击被盯上的人！",
                                                        1,
                                                        0.5,
                                                        function(curTimer, buffHandle)
                                                            buffHandle.remainingTime =
                                                                buffHandle.remainingTime - buffHandle.interval
                                                            if hbuff.hasBuff(targetUnit, "被盯上了") == false then
                                                                buffHandle.remainingTime = 0
                                                            else
                                                                cj.IssueTargetOrder(sourceUnit, "attack", targetUnit)
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
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "恐惧",
                                                castCD = 15,
                                                --castCountLimit = 1,
                                                shifashijian = 1,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 95, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(sourceUnit),
                                                        sourceUnit,
                                                        function(target)
                                                            hbuff.kongju(target, nandu)
                                                        end
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                                name = "燃烧之力",
                                                castCD = 20,
                                                --castCountLimit = 1,
                                                shifashijian = 2.5,
                                                castDistance = 300,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 100, -- only cast when health is < 65%
                                                notInterruptable = false,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    heffect.attach("AZ_fire_2024618.mdx", evtData.triggerUnit,
                                                        "right hand", 20)
                                                    hbuff.update(
                                                        20,
                                                        evtData.triggerUnit,
                                                        "燃烧之力",
                                                        true,
                                                        function()
                                                            hevent.register(
                                                                evtData.triggerUnit,
                                                                CONST_EVENT.attack,
                                                                "燃烧之力攻击",
                                                                function(evtData)
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = evtData.triggerUnit,
                                                                            targetUnit = evtData.targetUnit,
                                                                            damage = hattribute.getWithLimit(
                                                                                evtData.triggerUnit,
                                                                                nil,
                                                                                "attack",
                                                                                0
                                                                            ),
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.MOFA,
                                                                            triggerSkill = hslk.n2i("AI技能模版"),
                                                                            damageElementType = {
                                                                                CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                            }
                                                                        }
                                                                    )
                                                                end
                                                            )
                                                        end,
                                                        function()
                                                            hevent.unregister(
                                                                evtData.triggerUnit,
                                                                CONST_EVENT.attack,
                                                                "燃烧之力攻击"
                                                            )
                                                        end,
                                                        "ReplaceableTextures\\BTN_FS_03.blp",
                                                        "燃烧之力|n攻击附带攻击力的火焰魔法伤害",
                                                        1,
                                                        nil,
                                                        nil,
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
                                                targetType = UNIT_AI_TARGET_TYPE.LOWEST_HEALTH_UNIT,
                                                name = "冲击波",
                                                notInterruptable = true,
                                                healthBelowLimit = 100,
                                                castCD = 18,
                                                shifashijian = 1.5,
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "见识见识我的冲击波!",
                                                        10,
                                                        "e8da12",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local width = 200
                                                    local speed = 600
                                                    local scale = 1
                                                    local damage = hattr.get(sourceUnit, "attack", 1) * 3
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
                                                            tokenArrow =
                                                            "Abilities\\Spells\\Orc\\Shockwave\\ShockwaveMissile.mdl", -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                                                            sourceUnit = evtData.triggerUnit,                          --伤害来源（必须有！不管有没有伤害）
                                                            --targetUnit = evtData.targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                                                            x = x,                                                     --冲击的x坐标（可选的，对点冲击，与某目标无关）
                                                            y = y,                                                     --冲击的y坐标（可选的，对点冲击，与某目标无关）
                                                            speed = speed / 50,                                        --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                                                            acceleration = 0,
                                                            shake = 0,                                                 --摇摆振幅角度[-90~+90|random]（可选的，默认0)
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
                            passiveSkill = { {}, {}, {}, {} }
                        },
                        {
                            name = "酋长卡加斯·刃拳",
                            x = -4294,
                            y = -27343,
                            levelAdj = 0,
                            huixuedistance = 3000,
                            recoveryDistance = 2000,
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
                                            "纷争勇士护手",
                                            "纷争勇士战甲",
                                            "元首权利坠饰",
                                            "食人魔奴隶镣铐"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1200,
                                            1200,
                                            1200,
                                            0
                                        },

                                    },
                                    {
                                        list = {
                                            "残破的战斧",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            500,
                                            500,
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
                                                name = "激怒",
                                                healthBelowLimit = 30,
                                                castCountLimit = 1,
                                                shifashijian = 1,
                                                notInterruptable = true,
                                                --cast when life is below 50%
                                                castCD = 15, -- nil or <=1 means 1 second
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "你们惹怒我了!",
                                                        10,
                                                        "e8da12",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local attack =
                                                        hattribute.get(evtData.triggerUnit, "attack_white", 10)
                                                    hbuff.update(
                                                        60,
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
                                                        end,
                                                        "ReplaceableTextures\\PASBTN_KRDS_KBZX.blp",
                                                        "攻击力和攻击速度提高50%",
                                                        1,
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
                                                name = "刃舞",
                                                castCD = 30,
                                                --castCountLimit = 3,
                                                shifashijian = 2,
                                                castDistance = 500,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                healthBelowLimit = 80, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                --skip_skill_speed = true,
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
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    hbuff.update(
                                                        5,
                                                        sourceUnit,
                                                        "刃舞",
                                                        true,
                                                        function()
                                                            hcache.set(sourceUnit, "AI_SKILL_EFFECT", true)
                                                        end,
                                                        function()
                                                            hcache.set(sourceUnit, "AI_SKILL_EFFECT", false)
                                                        end,
                                                        "ReplaceableTextures\\SHUSHI\\kongju.blp",
                                                        "刃舞|n每秒会对距离最远的单位进行冲锋，冲锋距离越远伤害越高！",
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
                                                            local startPosition = {
                                                                x = hunit.x(sourceUnit),
                                                                y = hunit.y(sourceUnit)
                                                            }
                                                            hskillMoban.leap(
                                                                {
                                                                    arrowUnit = sourceUnit,  -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                                                                    sourceUnit = sourceUnit, --伤害来源（必须有！不管有没有伤害）
                                                                    targetUnit = targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                                                                    speed = 50,              --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                                                                    acceleration = 1,
                                                                    shake = 0,               --摇摆振幅角度[-90~+90|random]（可选的，默认0)
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
                                                                    endDistance = 150,
                                                                    onEnding = function(_, _, timePassed)
                                                                        local endPosition = {
                                                                            x = hunit.x(targetUnit),
                                                                            y = hunit.y(targetUnit)
                                                                        }
                                                                        local distance =
                                                                            math.distance(
                                                                                startPosition.x,
                                                                                startPosition.y,
                                                                                endPosition.x,
                                                                                endPosition.y
                                                                            )
                                                                        local damangeMultiplier =
                                                                            math.max(1, distance / 100)
                                                                        hskill.damage(
                                                                            {
                                                                                sourceUnit = sourceUnit,
                                                                                targetUnit = targetUnit,
                                                                                damage = 100 +
                                                                                    hattribute.getWithLimit(
                                                                                        evtData.triggerUnit,
                                                                                        nil,
                                                                                        "attack",
                                                                                        0
                                                                                    ) *
                                                                                    damangeMultiplier,
                                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                                damageType = DAMAGE_TYPE.WULI,
                                                                                triggerSkill = hslk.n2i("AI技能模版"),
                                                                                damageElementType = {
                                                                                    CONST_DAMAGE_ELEMENT_TYPE.METAL
                                                                                }
                                                                            }
                                                                        )
                                                                        heffect.attach(
                                                                            "war3mapImported\\AZ_chongfeng.mdx",
                                                                            targetUnit,
                                                                            "origin",
                                                                            0
                                                                        )
                                                                        hbuff.xuanyun(targetUnit, 0.5)
                                                                        cj.IssueTargetOrder(
                                                                            sourceUnit,
                                                                            "attack",
                                                                            targetUnit
                                                                        )
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
                                                name = "召唤卫兵",
                                                castCD = 60,
                                                --castCountLimit = 1,
                                                shifashijian = 1,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 70, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "卫兵，快来干掉这几只臭虫！",
                                                        10,
                                                        "eae30a",
                                                        1,
                                                        3,
                                                        50
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = level,
                                                                attackSpace = hslk.n2v("酋长的野蛮卫兵", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_XIAOGUAI,
                                                                nandu = nandu,
                                                                count = count,
                                                                mijing = mijing
                                                            }
                                                        )
                                                    local tmpUnit =
                                                        henemy.create(
                                                            {
                                                                id = hslk.n2i("酋长的野蛮卫兵"),
                                                                x = -4472,
                                                                y = -26574,
                                                                facing = math.random(0, 360),
                                                                attr = tmpAttr,
                                                                AI = UnitAI(
                                                                    {
                                                                        jinu,
                                                                        {
                                                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                                                            aiData = {
                                                                                targetType = UNIT_AI_TARGET_TYPE
                                                                                    .HIGHEST_CHOUHENG_UNIT,
                                                                                name = "践踏",
                                                                                healthBelowLimit = 50,
                                                                                --castCountLimit = 1,
                                                                                notInterruptable = false,
                                                                                minNandu = FUBEN_NANDU.PUTONG,
                                                                                shifashijian = 3.0,
                                                                                castCD = 30, -- nil or <=1 means 1 second
                                                                                customCondition = nil,
                                                                                startEffect = function(evtData)
                                                                                    hunit.setAnimateSpeed(
                                                                                        evtData.triggerUnit,
                                                                                        0.4
                                                                                    )
                                                                                    hunit.animate(
                                                                                        evtData.triggerUnit,
                                                                                        "spell"
                                                                                    )
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
                                                                                    local sourceUnit = evtData
                                                                                        .triggerUnit
                                                                                    --local targetUnit = evtData.targetUnit
                                                                                    local damage =
                                                                                        (2 + nandu) *
                                                                                        hattr.get(sourceUnit, "attack", 0)

                                                                                    local group =
                                                                                        hgroup.createByUnit(
                                                                                            sourceUnit,
                                                                                            300,
                                                                                            function(filterUnit)
                                                                                                if
                                                                                                    hunit.isAlly(
                                                                                                        sourceUnit,
                                                                                                        filterUnit
                                                                                                    ) or
                                                                                                    hunit.isDead(filterUnit) or
                                                                                                    hunit.isDead(sourceUnit) or
                                                                                                    hunit.isDestroyed(
                                                                                                        filterUnit
                                                                                                    ) or
                                                                                                    hunit.isDestroyed(
                                                                                                        sourceUnit
                                                                                                    )
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
                                                                                                damageSrc =
                                                                                                    CONST_DAMAGE_SRC.skill,
                                                                                                damageType = DAMAGE_TYPE
                                                                                                    .MOFA,
                                                                                                triggerSkill = hslk.n2i(
                                                                                                    "AI技能模版"
                                                                                                )
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
                                                                attackSpace = hslk.n2v("酋长的狂暴卫兵", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_XIAOGUAI,
                                                                nandu = nandu,
                                                                count = count
                                                            }
                                                        )
                                                    local tmpUnit =
                                                        henemy.create(
                                                            {
                                                                id = hslk.n2i("酋长的狂暴卫兵"),
                                                                x = -4375,
                                                                y = -28197,
                                                                facing = math.random(0, 360),
                                                                attr = tmpAttr,
                                                                AI = UnitAI(
                                                                    {
                                                                        jinu,
                                                                        {
                                                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                                                            aiData = {
                                                                                targetType = UNIT_AI_TARGET_TYPE
                                                                                    .HIGHEST_CHOUHENG_UNIT,
                                                                                name = "嗜血",
                                                                                healthBelowLimit = 80,
                                                                                notInterruptable = true,
                                                                                castDistance = 300,
                                                                                minNandu = FUBEN_NANDU.PUTONG,
                                                                                shifashijian = 5.01,
                                                                                castCD = 15, -- nil or <=1 means 1 second
                                                                                startEffect = function(evtData)
                                                                                end,
                                                                                interval = 0.5,
                                                                                periodEffect = function(evtData)
                                                                                    hunit.setAnimateSpeed(
                                                                                        evtData.triggerUnit,
                                                                                        2.5,
                                                                                        0.5
                                                                                    )
                                                                                    hunit.animate(
                                                                                        evtData.triggerUnit,
                                                                                        "attack"
                                                                                    )
                                                                                    hskillMoban.radiusAngleAOE(
                                                                                        evtData.triggerUnit,
                                                                                        400,
                                                                                        hunit.getFacing(evtData
                                                                                            .triggerUnit),
                                                                                        180,
                                                                                        function(unit)
                                                                                            local basicAttack =
                                                                                                hattribute.get(
                                                                                                    evtData.triggerUnit,
                                                                                                    "attack",
                                                                                                    100
                                                                                                )
                                                                                            hskill.damage(
                                                                                                {
                                                                                                    sourceUnit = evtData
                                                                                                        .triggerUnit,
                                                                                                    targetUnit = unit,
                                                                                                    damage = 3 *
                                                                                                        basicAttack,
                                                                                                    damageType =
                                                                                                        DAMAGE_TYPE.WULI,
                                                                                                    effect =
                                                                                                    "war3mapImported\\AZ_gelie.mdx",
                                                                                                    damageSrc =
                                                                                                        CONST_DAMAGE_SRC.skill,
                                                                                                    damageElementType = {
                                                                                                        CONST_DAMAGE_ELEMENT_TYPE.METAL
                                                                                                    },
                                                                                                    damageSpeedType =
                                                                                                        CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
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
                                                                            aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
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
                                                                attackSpace = hslk.n2v("酋长的射手卫兵", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_XIAOGUAI,
                                                                nandu = nandu,
                                                                count = count
                                                            }
                                                        )
                                                    local tmpUnit =
                                                        henemy.create(
                                                            {
                                                                id = hslk.n2i("酋长的射手卫兵"),
                                                                x = -3638,
                                                                y = -27341,
                                                                facing = math.random(0, 360),
                                                                attr = tmpAttr,
                                                                AI = UnitAI(
                                                                    {
                                                                        jinu,
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
                            passiveSkill = { { lianji }, { lianji }, { lianji }, {} }
                        }
                    },
                    tongguanjiangli = {
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,       value = 1500 },
                                { type = HSHOP_COST_TYPE.experience, value = 10000 },
                            },
                            shengwang = {
                                {
                                    value = 200,
                                    maxLevel = 0,
                                    shengwangname = "和平之城"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,            value = 2000 },
                                { type = HSHOP_COST_TYPE.zhengyihuizhang, value = 1 },
                                { type = HSHOP_COST_TYPE.experience,      value = 12000 },
                            },
                            shengwang = {
                                {
                                    value = 200,
                                    maxLevel = 1,
                                    shengwangname = "和平之城"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,            value = 3000 },
                                { type = HSHOP_COST_TYPE.zhengyihuizhang, value = 2 },
                                { type = HSHOP_COST_TYPE.experience,      value = 15000 },
                            },
                            shengwang = {
                                {
                                    value = 200,
                                    maxLevel = 2,
                                    shengwangname = "和平之城"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,       value = 4000 },
                                { type = HSHOP_COST_TYPE.experience, value = 20000 },
                            },
                            shengwang = {
                                {
                                    value = 200,
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
