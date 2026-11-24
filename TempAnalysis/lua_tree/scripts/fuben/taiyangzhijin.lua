---@diagnostic disable: missing-parameter
table.insert(
    FUBEN_LIST,
    {
        name = "太阳之井",
        setup = function()
            local nanduLevelConfig                  = {}
            nanduLevelConfig[FUBEN_NANDU.PUTONG]    = 73
            nanduLevelConfig[FUBEN_NANDU.YINGXIONG] = 73
            nanduLevelConfig[FUBEN_NANDU.SHISHI]    = 73
            --nanduLevelConfig[FUBEN_NANDU.CHUANQI] = 73

            local status                            = FUBEN_STATUS.KAIHUANG

            local juxingshengwu                     = {
                description = "最终Boss：生命最大值提高100%",
                attr_type = CONST_EVENT.attr,
                attr = _attr({ shengming_baifenbi = "+100" })
            }

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

            local jinu                              = {
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

            local jinzhanai                         = function(level, nandu)
                return UnitAI(
                    {
                        jinu,
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
                    name = "太阳之井", --副本名字
                    status = status,
                    blp = "ReplaceableTextures\\xiaoditu\\UI_map_22.blp",
                    enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\UImap_show_22.blp",
                    nanduLevelConfig = nanduLevelConfig,                                       -- 副本难度以及级别需求,
                    entryPosition = { x = -6333, y = -9042 },
                    startPosition = { x = -11667, y = -24341 },                                --英雄进副本后位置
                    rectParam = { minX = -11870, minY = -25834, maxX = -2843, maxY = -22416 }, -- 副本区域
                    minions = {
                        {
                            name = "精英恶魔狂战士", -- 名字 需要在物编定义好
                            x = -9533, -- 小怪刷新x坐标
                            y = -24352, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            randomRadius = 1000,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = jinzhanai
                        },
                        {
                            name = "精英恶魔地狱火", -- 名字 需要在物编定义好
                            x = -9533, -- 小怪刷新x坐标
                            y = -24352, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 1000,
                            ai = jinzhanai
                        },
                        {
                            name = "精英末日弓箭手", -- 名字 需要在物编定义好
                            x = -9533, -- 小怪刷新x坐标
                            y = -24352, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 1000,
                            ai = jinzhanai
                        },
                        {
                            name = "精英末日护卫", -- 名字 需要在物编定义好
                            x = -9533, -- 小怪刷新x坐标
                            y = -24352, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 1000,
                            ai = jinzhanai
                        },
                        {
                            name = "精英恶魔狂战士", -- 名字 需要在物编定义好
                            x = -7306, -- 小怪刷新x坐标
                            y = -24352, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            randomRadius = 1000,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = jinzhanai
                        },
                        {
                            name = "精英恶魔地狱火", -- 名字 需要在物编定义好
                            x = -7306, -- 小怪刷新x坐标
                            y = -24352, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            randomRadius = 1000,
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = jinzhanai
                        },
                        {
                            name = "精英末日弓箭手", -- 名字 需要在物编定义好
                            x = -7306, -- 小怪刷新x坐标
                            y = -24352, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 1000,
                            ai = jinzhanai
                        },
                        {
                            name = "精英末日护卫", -- 名字 需要在物编定义好
                            x = -7306, -- 小怪刷新x坐标
                            y = -24352, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 1000,
                            ai = jinzhanai
                        },
                    },
                    bosses = {
                        {
                            name = "军团恶魔领主布胖",
                            x = -9552,
                            y = -24385,
                            face = 180,
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
                                            "光棱指环",
                                            "灾难长靴",
                                            "止战马靴",
                                            "神圣信仰战靴",
                                            "胜利指环",
                                            "灾难指环"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1200,
                                            1200,
                                            1200,
                                            0
                                        }
                                    },
                                }
                            ),
                            ai = function(level, nandu, count, fubenstatus)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                name = "召唤魔能灌注法师",
                                                castCD = 8,
                                                onlyInFight = true,
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 65, -- only cast when health is < 65%
                                                shifashijian = 1,
                                                startEffect = function(evtData)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                castDistance = 10000,
                                                effect = function(evtData)
                                                    local sourceX, sourceY = hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit)
                                                    local angle = math.random() * 2 * math.pi
                                                    local distance = 500 + math.random() * 400
                                                    local x = sourceX + distance * math.cos(angle)
                                                    local y = sourceY + distance * math.sin(angle)
                                                    local tmpAttr = hunit.getAttributeBasedOnOptions({
                                                        level = level,
                                                        attackSpace = hslk.n2v("魔能灌注法师", "cool1"),
                                                        guaiwuType = MONSTER_TYPE.FUBEN_XIAOGUAI,
                                                        nandu = nandu,
                                                        count = count
                                                    })
                                                    local demonChild = henemy.create({
                                                        id = hslk.n2i("魔能灌注法师"),
                                                        x = x,
                                                        y = y,
                                                        facing = math.random(0, 360),
                                                        attr = tmpAttr,
                                                        AI = UnitAI(
                                                            {
                                                                {
                                                                    aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                                                    aiData = {
                                                                        targetType = UNIT_AI_TARGET_TYPE
                                                                            .HIGHEST_CHOUHENG_UNIT
                                                                    }
                                                                }
                                                            }),
                                                        nandu = nandu,
                                                        tuozhanshijian = 36000
                                                    })
                                                    hskill.add(demonChild, hslk.n2i("AI技能模版"), 1, 0)
                                                    hunit.setExpReward(demonChild, 0)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                name = "烈焰猛击",
                                                castCD = 10,
                                                onlyInFight = true,
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                --castCountLimit = 1, -- cast only x times per battle
                                                --healthBelowLimit = 65, -- only cast when health is < 65%
                                                shifashijian = 1.8,
                                                notInterruptable = true,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                skip_skill_speed = true,
                                                startEffect = function(evtData)
                                                    hunit.setAnimateSpeed(evtData.triggerUnit, 0.5, 1.8)
                                                    hunit.animate(evtData.triggerUnit, 13)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local sourceX, sourceY = hunit.x(sourceUnit), hunit.y(sourceUnit)
                                                    local facingAngle = math.angle(
                                                        sourceX,
                                                        sourceY,
                                                        hunit.x(evtData.targetUnit),
                                                        hunit.y(evtData.targetUnit)
                                                    )

                                                    local targets = hgroup.createByAngleAndRadius(
                                                        sourceUnit,
                                                        3000,
                                                        facingAngle,
                                                        120,
                                                        function(u)
                                                            return hunit.isAlive(u) and
                                                                ((hunit.isEnemy(sourceUnit, u) and hunit.isHero(u)) or hunit.getName(u) == "魔能灌注法师")
                                                        end
                                                    )

                                                    local count = hgroup.count(targets)
                                                    local damagePercent = { 60, 30, 20, 15, 12, 10 }
                                                    if nandu >= FUBEN_NANDU.SHISHI then
                                                        damagePercent = { 200, 30, 20, 15, 12, 10 }
                                                    end
                                                    local damage = damagePercent[math.min(count, 6)] / 100
                                                    heffect.xyz(
                                                        "AZ_hqn5_W.mdx",
                                                        hunit.x(sourceUnit),
                                                        hunit.y(sourceUnit),
                                                        hunit.z(sourceUnit),
                                                        1, 1, 1, 1, 1, 0, 0, facingAngle
                                                    )

                                                    hgroup.forEach(targets, function(u)
                                                        if hunit.getName(u) == "魔能灌注法师" then
                                                            hunit.kill(u)
                                                        else
                                                            local maxHealth = hunit.getMaxLife(u)
                                                            hskill.damage({
                                                                sourceUnit = sourceUnit,
                                                                targetUnit = u,
                                                                damage = maxHealth * damage,
                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                damageType = DAMAGE_TYPE.MOFA,
                                                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK }
                                                            })
                                                        end
                                                    end)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                name = "践踏",
                                                castCD = 15,
                                                onlyInFight = true,
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                --castCountLimit = 1, -- cast only x times per battle
                                                --healthBelowLimit = 65, -- only cast when health is < 65%
                                                shifashijian = 1.1,
                                                notInterruptable = false,
                                                skip_skill_speed = true,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 1)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                effect = function(evtData)
                                                    local targets = hgroup.createByRect(
                                                        hunit.getRect(evtData.triggerUnit, 500), function(u)
                                                            return hunit.isAlive(u) and
                                                                hunit.isEnemy(evtData.triggerUnit, u)
                                                        end)
                                                    heffect.xyz(
                                                        "war3mapImported\\AZ_leitingyiji.MDX",
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit),
                                                        hunit.z(evtData.triggerUnit),
                                                        0,
                                                        1,
                                                        3, 3, 3
                                                    )
                                                    hsound.voice2Unit(
                                                        hsound.voiceCreate("resource\\war3mapImported\\sound\\3349.mp3",
                                                            1000, true),
                                                        80,
                                                        evtData.triggerUnit
                                                    )
                                                    hgroup.forEach(targets, function(u)
                                                        hskill.damage({
                                                            sourceUnit = evtData.triggerUnit,
                                                            targetUnit = u,
                                                            damage = hattribute.get(evtData.triggerUnit, "attack", 0) * 3,
                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                            damageType = DAMAGE_TYPE.WULI
                                                        })
                                                        if nandu >= FUBEN_NANDU.SHISHI then
                                                            hbuff.addStackAttrBuff(
                                                                CONST_DAMAGE_SRC.skill,
                                                                u,
                                                                "恶魔践踏",
                                                                _attr({ defend_baifenbi = "-200" }),
                                                                10,
                                                                20,
                                                                "ReplaceableTextures\\BTN_ZS_JN14.blp",
                                                                "恶魔践踏|n每层降低200点防御",
                                                                false
                                                            )
                                                        end
                                                    end)
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
                            passiveSkill = {
                                {
                                    {
                                        description = "深渊领主之速",
                                        attr_type = CONST_EVENT.attr,
                                        attr = _attr({ move = "+500" })
                                    }
                                },
                                {
                                    {
                                        description = "深渊领主之速",
                                        attr_type = CONST_EVENT.attr,
                                        attr = _attr({ move = "+500" })
                                    }
                                },
                                {
                                    {
                                        description = "深渊领主之速",
                                        attr_type = CONST_EVENT.attr,
                                        attr = _attr({ move = "+500" })
                                    }
                                },
                                {
                                    {
                                        description = "深渊领主之速",
                                        attr_type = CONST_EVENT.attr,
                                        attr = _attr({ move = "+500" })
                                    }
                                }
                            }
                        },
                        {
                            name = "虚空生物穆鲁",
                            x = -7296,
                            y = -24328,
                            face = 270,
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
                                            "堡垒护手",
                                            "诸界亵渎护手",
                                            "萨拉斯将军护手",
                                            "纯净的纳鲁薄片",
                                            "灰暗的纳鲁薄片",
                                            "变幻的纳鲁薄片"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1200,
                                            1200,
                                            1200,
                                            0
                                        }
                                    },
                                }
                            ),
                            ai = function(level, nandu, count, fubenstatus, mijing)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                name = "战斗开始",
                                                castCD = 1,
                                                onlyInFight = true,
                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                castCountLimit = 1,     -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 100, -- only cast when health is < 65%
                                                shifashijian = 1,
                                                notInterruptable = true,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                castDistance = 10000,
                                                effect = function(evtData)
                                                    hcache.set(evtData.triggerUnit, "phase", 1)
                                                    hattribute.set(evtData.triggerUnit, 0, _attr({ move = "-500" }))
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "负能量爆发",
                                                healthBelowLimit = 50,
                                                --healthAboveLimit = 50,
                                                castDistance = 10000,
                                                castCountLimit = 1,
                                                shifashijian = 3,
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
                                                    hcache.set(sourceUnit, "phase", 2)
                                                    hjapi.DzSetUnitModel(sourceUnit,
                                                        "war3mapImported\\[boss]SY_BOSS_003.mdx")
                                                    hjapi.DzSetUnitPortrait(sourceUnit,
                                                        "war3mapImported\\[boss]SY_BOSS_003.mdx")
                                                    hattribute.set(sourceUnit, 0,
                                                        _attr({ move = "+1000", attack_speed = "+" .. (30 * nandu) }))
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                name = "召唤恶魔卫士",
                                                castCD = 10,
                                                onlyInFight = true,
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 65, -- only cast when health is < 65%
                                                shifashijian = 1,
                                                notInterruptable = false,
                                                startEffect = function(evtData)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                castDistance = 10000,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local x, y = hunit.x(sourceUnit), hunit.y(sourceUnit)
                                                    -- 召唤狂战士
                                                    for i = 1, 2 do
                                                        local spawnX = -7230
                                                        local spawnY = -22680
                                                        local tmpAttr = hunit.getAttributeBasedOnOptions({
                                                            level = level,
                                                            attackSpace = hslk.n2v("魔能灌注卫士", "cool1"),
                                                            guaiwuType = MONSTER_TYPE.FUBEN_XIAOGUAI,
                                                            nandu = nandu,
                                                            count = count
                                                        })
                                                        henemy.create({
                                                            id = hslk.n2i("魔能灌注卫士"),
                                                            x = spawnX,
                                                            y = spawnY,
                                                            facing = 180,
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
                                                                            minNandu = FUBEN_NANDU.YINGXIONG,
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
                                                        })
                                                    end
                                                    -- 召唤法师
                                                    local tmpAttr = hunit.getAttributeBasedOnOptions({
                                                        level = level,
                                                        attackSpace = hslk.n2v("魔能灌注法师", "cool1"),
                                                        guaiwuType = MONSTER_TYPE.FUBEN_XIAOGUAI,
                                                        nandu = nandu,
                                                        count = count
                                                    })
                                                    local demonChild = henemy.create({
                                                        id = hslk.n2i("魔能灌注法师"),
                                                        x = -7262,
                                                        y = -25668,
                                                        facing = 0,
                                                        attr = tmpAttr,
                                                        AI = UnitAI({
                                                            {
                                                                aiType = UNIT_AI_TYPE.CAST_SKILL,
                                                                aiData = {
                                                                    targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                                                    name = "陨石术",
                                                                    --castCountLimit = 1, -- cast only x times per battle
                                                                    minNandu = FUBEN_NANDU.YINGXIONG,
                                                                    castCD = 10, -- nil or <=1 means 1 second
                                                                    --healthBelowLimit = 88, -- only cast when health is < 65%
                                                                    notInterruptable = false,
                                                                    castDistance = 10000,
                                                                    shifashijian = 1,
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
                                                                        heffect.xyz("war3mapImported\\AZ_Kaer_D1.MDX", x,
                                                                            y, z, 1.25, 1)
                                                                        local damage = hattribute.getWithLimit(whichUnit,
                                                                            nil, "attack", 0)
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
                                                                                                damageSrc =
                                                                                                    CONST_DAMAGE_SRC.skill,
                                                                                                damageType = DAMAGE_TYPE
                                                                                                    .MOFA,
                                                                                                triggerSkill = hslk.n2i(
                                                                                                    "AI技能模版"),
                                                                                                damageElementType = {
                                                                                                    CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                                                },
                                                                                                damageSpeedType =
                                                                                                    CONST_DAMAGE_SPEED_TYPE
                                                                                                    .IMMEDIATE
                                                                                            }
                                                                                        )
                                                                                        hbuff.xuanyun(target, 2)
                                                                                    end
                                                                                )
                                                                            end
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
                                                        }),
                                                        nandu = nandu,
                                                        tuozhanshijian = 36000
                                                    })
                                                    hskill.add(demonChild, hslk.n2i("AI技能模版"), 1, 0)
                                                    hunit.setExpReward(demonChild, 0)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                name = "负面能量",
                                                castCD = 1,
                                                onlyInFight = true,
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 100, -- only cast when health is < 65%
                                                shifashijian = 5,
                                                customCondition = function(whichUnit)
                                                    local phase = hcache.get(whichUnit, "phase")
                                                    return phase == 1
                                                end,
                                                notInterruptable = true,
                                                startEffect = function(evtData)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                castDistance = 10000,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local phase = hcache.get(sourceUnit, "phase")

                                                    local x, y = hunit.x(targetUnit), hunit.y(targetUnit)
                                                    local damage = hattribute.get(sourceUnit, "attack", 0)

                                                    hskillMoban.radiusAOE(x, y, sourceUnit, 300, function(u)
                                                        hskill.damage(
                                                            {
                                                                sourceUnit = sourceUnit,
                                                                targetUnit = u,
                                                                damage = damage,
                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                damageType = DAMAGE_TYPE.MOFA,
                                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                    .IMMEDIATE,
                                                                damageElementType = {
                                                                    CONST_DAMAGE_ELEMENT_TYPE.DARK
                                                                }
                                                            }
                                                        )
                                                    end)
                                                    heffect.xyz("war3mapImported\\AYZN_[AZ].mdx", x, y,
                                                        hunit.z(sourceUnit), 0, 1, 1, 1, 1)
                                                    hsound.voice2Unit(
                                                        hsound.voiceCreate(
                                                            "resource\\war3mapImported\\sound\\shadowfury_impact_base.mp3",
                                                            1000, true),
                                                        80,
                                                        sourceUnit
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                name = "高级负面能量",
                                                castCD = 4,
                                                onlyInFight = true,
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 100, -- only cast when health is < 65%
                                                shifashijian = 1,
                                                notInterruptable = false,
                                                customCondition = function(whichUnit)
                                                    local phase = hcache.get(whichUnit, "phase")
                                                    return phase == 2
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                castDistance = 10000,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local phase = hcache.get(sourceUnit, "phase")

                                                    local x, y = hunit.x(targetUnit), hunit.y(targetUnit)
                                                    local damage = hattribute.get(sourceUnit, "attack", 0)

                                                    hskillMoban.radiusAOE(x, y, sourceUnit, 300, function(u)
                                                        hskill.damage(
                                                            {
                                                                sourceUnit = sourceUnit,
                                                                targetUnit = u,
                                                                damage = damage,
                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                damageType = DAMAGE_TYPE.MOFA,
                                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                    .IMMEDIATE,
                                                                damageElementType = {
                                                                    CONST_DAMAGE_ELEMENT_TYPE.DARK
                                                                }
                                                            }
                                                        )
                                                    end)
                                                    heffect.xyz("war3mapImported\\AYZN_[AZ].mdx", x, y,
                                                        hunit.z(sourceUnit), 0, 1, 1, 1, 1)
                                                    hsound.voice2Unit(
                                                        hsound.voiceCreate(
                                                            "resource\\war3mapImported\\sound\\shadowfury_impact_base.mp3",
                                                            1000, true),
                                                        80,
                                                        sourceUnit
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
                            name = "基尔加丹",
                            x = -4296,
                            y = -24295,
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
                                            "村正",
                                            "奥博莱恩·裂魂之剑",
                                            "日灸",
                                            "天启",
                                            "光荣战甲",
                                            "大魔导师的洪流法杖",
                                            "奥博莱恩·碎魂之剑"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1400,
                                            1400,
                                            1400,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "欺诈者之眼"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            100,
                                            300,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "黑暗意志胸甲"
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
                                            "史诗黑暗意志胸甲"
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
                                            "太阳之井的精华"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            300,
                                            500,
                                            0
                                        }
                                    },
                                }
                            ),
                            ai = function(level, nandu, count, fubenstatus, mijing)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                name = "召唤祭祀",
                                                castCD = 1,
                                                --onlyInFight = false,
                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 100, -- only cast when health is < 65%
                                                shifashijian = 0.1,
                                                notInterruptable = true,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                castDistance = 10000,
                                                effect = function(evtData)
                                                    local originalSourceUnit = evtData.triggerUnit
                                                    hunit.hide(evtData.triggerUnit)
                                                    hunit.setInvulnerable(evtData.triggerUnit, true)
                                                    local sourceX, sourceY = hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit)
                                                    for i = 1, 3, 1 do
                                                        local angle = 90 * i
                                                        local distance = 500
                                                        local x = sourceX + distance * math.cos(angle)
                                                        local y = sourceY + distance * math.sin(angle)
                                                        local tmpAttr = hunit.getAttributeBasedOnOptions({
                                                            level = level,
                                                            attackSpace = hslk.n2v("欺诈者之手", "cool1"),
                                                            guaiwuType = MONSTER_TYPE.FUBEN_JINGYING,
                                                            nandu = nandu,
                                                            count = count
                                                        })
                                                        local demonChild = henemy.create({
                                                            id = hslk.n2i("欺诈者之手"),
                                                            x = x,
                                                            y = y,
                                                            facing = math.random(0, 360),
                                                            attr = tmpAttr,
                                                            AI = UnitAI(
                                                                {
                                                                    {
                                                                        aiType = UNIT_AI_TYPE.CAST_SKILL,
                                                                        aiData = {
                                                                            targetType = UNIT_AI_TARGET_TYPE
                                                                                .HIGHEST_CHOUHENG_UNIT,
                                                                            name = "群体暗影箭",
                                                                            --healthBelowLimit = 100,
                                                                            --healthAboveLimit = 50,
                                                                            castDistance = 10000,
                                                                            --castCountLimit = 1,
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
                                                                                            onEnd = function(_, _, endX,
                                                                                                             endY)
                                                                                                hskill.damage(
                                                                                                    {
                                                                                                        sourceUnit =
                                                                                                            sourceUnit,
                                                                                                        targetUnit =
                                                                                                            target,
                                                                                                        damage = hattr
                                                                                                            .get(
                                                                                                                sourceUnit,
                                                                                                                "attack",
                                                                                                                0
                                                                                                            ),
                                                                                                        damageSrc =
                                                                                                            CONST_DAMAGE_SRC.skill,
                                                                                                        damageType =
                                                                                                            DAMAGE_TYPE
                                                                                                            .MOFA,
                                                                                                        triggerSkill =
                                                                                                            hslk
                                                                                                            .n2i(
                                                                                                                "AI技能模版"),
                                                                                                        damageElementType = {
                                                                                                            CONST_DAMAGE_ELEMENT_TYPE.DARK
                                                                                                        },
                                                                                                        damageSpeedType =
                                                                                                            CONST_DAMAGE_SPEED_TYPE
                                                                                                            .IMMEDIATE
                                                                                                    }
                                                                                                )
                                                                                            end
                                                                                        }
                                                                                    )
                                                                                end
                                                                                hskillMoban.rectAOE(
                                                                                    hunit.getRect(originalSourceUnit),
                                                                                    sourceUnit,
                                                                                    missleFunc
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
                                                                }),
                                                            nandu = nandu,
                                                            tuozhanshijian = 36000
                                                        })
                                                        hskill.add(demonChild, hslk.n2i("AI技能模版"), 1, 0)
                                                        hunit.setExpReward(demonChild, 0)
                                                    end
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                name = "降临",
                                                castCD = 1,
                                                --onlyInFight = true,
                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 100, -- only cast when health is < 65%
                                                shifashijian = 10,
                                                skip_skill_speed = true,
                                                notInterruptable = true,
                                                customCondition = function(whichUnit)
                                                    local groups = hgroup.createByRect(hunit.getRect(whichUnit),
                                                        function(unit)
                                                            if hunit.getName(unit) == "欺诈者之手" and hunit.isAlive(unit) then
                                                                return true
                                                            else
                                                                return false
                                                            end
                                                        end)
                                                    if hgroup.isEmpty(groups) then
                                                        hunit.animate(whichUnit, 14)
                                                        hunit.show(whichUnit)
                                                        hunit.setInvulnerable(whichUnit, false)
                                                        return true
                                                    else
                                                        return false
                                                    end
                                                end,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 14)
                                                    hattribute.set(evtData.triggerUnit, 0, { jianshang = "+70" })
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                castDistance = 10000,
                                                effect = function(evtData)
                                                    hattribute.set(evtData.triggerUnit, 0, { move = "-100" })
                                                    hattribute.set(evtData.triggerUnit, 0, { jianshang = "-70" })
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "万魂之暗",
                                                castCD = 1,
                                                --castCountLimit = 1,
                                                shifashijian = 5,
                                                castDistance = 10000,
                                                onlyInFight = true,
                                                startWarning = true,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 50, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    local chouhengdiyi = hfightzhuangtai.getChouhengdiyi(whichUnit)
                                                    if chouhengdiyi == nil then
                                                        return true
                                                    end
                                                    if math.distance(hunit.x(whichUnit), hunit.y(whichUnit),
                                                            hunit.x(chouhengdiyi), hunit.y(chouhengdiyi)) > 1000 then
                                                        return true
                                                    else
                                                        return false
                                                    end
                                                end,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 5)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    heffect.xyz("war3mapImported\\[Spell]_042.mdx", hunit.x(sourceUnit),
                                                        hunit.y(sourceUnit), hunit.z(sourceUnit), 1, 1, 5, 5, 5)
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(sourceUnit),
                                                        sourceUnit,
                                                        function(target)
                                                            local finalDamage = hunit.getMaxLife(target) * 10
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = sourceUnit,
                                                                    targetUnit = target,
                                                                    damage = finalDamage,
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
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "灭绝",
                                                notInterruptable = true,
                                                healthBelowLimit = 40,
                                                castCD = 60,
                                                shifashijian = 10.1,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 5)
                                                    htextTag.create2Unit(evtData.triggerUnit, "毁灭吧!!!", 10, "e8da12",
                                                        1, 1, 50)
                                                end,
                                                interval = 0.1,
                                                periodEffect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local x = hunit.x(sourceUnit) + math.random(-1000, 1000)
                                                    local y = hunit.y(sourceUnit) + math.random(-1000, 1000)
                                                    local z = hjapi.Z(x, y)

                                                    hskillMoban.radiusWarning(x, y, z, 200, 1.25)
                                                    heffect.xyz("war3mapImported\\AZ_Kaer_D1.MDX", x,
                                                        y, z, 1.25, 1)
                                                    local damage = hattribute.getWithLimit(sourceUnit,
                                                        nil, "attack", 0)
                                                    htime.setTimeout(
                                                        1.25,
                                                        function(curTimer)
                                                            hskillMoban.radiusAOE(
                                                                x,
                                                                y,
                                                                sourceUnit,
                                                                200,
                                                                function(target)
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = sourceUnit,
                                                                            targetUnit = target,
                                                                            damage = damage * 3,
                                                                            damageSrc =
                                                                                CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE
                                                                                .MOFA,
                                                                            triggerSkill = hslk.n2i(
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
                                                name = "千魂之暗",
                                                castCD = 30,
                                                --castCountLimit = 1,
                                                shifashijian = 5,
                                                castDistance = 10000,
                                                startWarning = true,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                healthBelowLimit = 50, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 5)
                                                    local sourceX, sourceY = hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit)
                                                    local angle = math.random() * 2 * math.pi
                                                    local distance = 500 + math.random() * 200
                                                    local x = sourceX + distance * math.cos(angle)
                                                    local y = sourceY + distance * math.sin(angle)
                                                    heffect.xyz(
                                                        "war3mapImported\\AZ_MagicShield_b.MDX",
                                                        x,
                                                        y,
                                                        hjapi.Z(x, y),
                                                        5,
                                                        1,
                                                        1,
                                                        1,
                                                        1
                                                    )
                                                    htime.setInterval(
                                                        0.1,
                                                        function(curTimer)
                                                            if curTimer.passedSec() > 5 then
                                                                curTimer.destroy()
                                                                return
                                                            end
                                                            hskillMoban.radiusAOE(
                                                                x,
                                                                y,
                                                                evtData.triggerUnit,
                                                                300,
                                                                function(target)
                                                                    hbuff.addStackAttrBuff(
                                                                        CONST_DAMAGE_SRC.skill,
                                                                        target,
                                                                        "纳鲁的守护",
                                                                        _attr({ mokang = "+60" }),
                                                                        2,
                                                                        1,
                                                                        "ReplaceableTextures\\CommandButtons\\BTNThunderclap.blp",
                                                                        "纳鲁的守护|n收到千魂之暗的伤害降低80%",
                                                                        true
                                                                    )
                                                                end
                                                            )
                                                        end
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    heffect.xyz("war3mapImported\\[Spell]_042.mdx", hunit.x(sourceUnit),
                                                        hunit.y(sourceUnit), hunit.z(sourceUnit), 1, 1, 5, 5, 5)
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(sourceUnit),
                                                        sourceUnit,
                                                        function(target)
                                                            local finalDamage = hunit.getMaxLife(target) * 1.5
                                                            if hbuff.hasBuff(target, "纳鲁的守护") then
                                                                finalDamage = finalDamage * 0.2
                                                            end
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = sourceUnit,
                                                                    targetUnit = target,
                                                                    damage = finalDamage,
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
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                name = "冲压",
                                                castCD = 0.1,
                                                onlyInFight = true,
                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                shifashijian = 0.9,
                                                healthBelowLimit = 20, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = true,
                                                castDistance = 10000,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 0)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(sourceUnit), sourceUnit,
                                                        function(targetUnit)
                                                            local attack = hattr.getWithLimit(sourceUnit, nil, "attack",
                                                                0)
                                                            local damageBlast = attack * 3
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = evtData.triggerUnit,
                                                                    targetUnit = targetUnit,
                                                                    damage = damageBlast,
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.WULI,
                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                    damageElementType = {
                                                                        CONST_DAMAGE_ELEMENT_TYPE.DARK
                                                                    },
                                                                }
                                                            )
                                                            heffect.attach("war3mapImported\\[zhanshi]jianta.mdx",
                                                                targetUnit, "origin", 0)
                                                        end)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "恶魔壁垒",
                                                castCD = 30,
                                                --castCountLimit = 1,
                                                shifashijian = 5,
                                                castDistance = 10000,
                                                startWarning = false,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                healthBelowLimit = 70, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 2)
                                                    local sourceUnit = evtData.triggerUnit
                                                    hevent.register(
                                                        sourceUnit,
                                                        CONST_EVENT.beDamage,
                                                        "恶魔壁垒",
                                                        function(evtData)
                                                            if evtData.damageSpeedType == CONST_DAMAGE_SPEED_TYPE.IMMEDIATE then
                                                                htime.setTimeout(
                                                                    0.01,
                                                                    function(curTimer)
                                                                        hskill.damage(
                                                                            {
                                                                                sourceUnit = sourceUnit,
                                                                                targetUnit = evtData.sourceUnit,
                                                                                damage = evtData.damage * 0.03,
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
                                                                )
                                                            end
                                                        end
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    hevent.unregister(
                                                        evtData.triggerUnit,
                                                        CONST_EVENT.beDamage,
                                                        "恶魔壁垒"
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "能量吸取",
                                                castCD = 16,
                                                --castCountLimit = 1,
                                                shifashijian = 2,
                                                castDistance = 10000,
                                                startWarning = false,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                healthBelowLimit = 80, -- only cast when health is < 65%
                                                notInterruptable = false,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 1)
                                                end,
                                                effect = function(evtData)
                                                    hbuff.addStackAttrBuff(CONST_DAMAGE_SRC.skill, evtData.triggerUnit,
                                                        "能量吸取", _attr({ quanju_zengshang = "+30" }), 30, 10,
                                                        "ReplaceableTextures\\BTNAbility_Paladin_BlindingLight2.blp",
                                                        "能量吸取|n吸收太阳之井的能量，造成的所有伤害提高30%", true)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                name = "恶魔镜像",
                                                castCD = 30,
                                                onlyInFight = true,
                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                minNandu = FUBEN_NANDU.SHISHI,
                                                shifashijian = 2,
                                                healthBelowLimit = 60, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                castDistance = 10000,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 1)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(sourceUnit), sourceUnit,
                                                        function(targetUnit)
                                                            local x = hunit.x(targetUnit)
                                                            local y = hunit.y(targetUnit)
                                                            local tmpAttr = hunit.getAttributeBasedOnOptions({
                                                                level = level,
                                                                attackSpace = hslk.n2v("恶魔镜像", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_JINGYING,
                                                                nandu = nandu,
                                                                count = count
                                                            })
                                                            local demonChild = henemy.create({
                                                                id = hslk.n2i("恶魔镜像"),
                                                                x = x,
                                                                y = y,
                                                                facing = math.random(0, 360),
                                                                attr = tmpAttr,
                                                                AI = UnitAI(
                                                                    {
                                                                        {
                                                                            aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                                                            aiData = {
                                                                                targetType = UNIT_AI_TARGET_TYPE
                                                                                    .HIGHEST_CHOUHENG_UNIT
                                                                            }
                                                                        }
                                                                    }),
                                                                nandu = nandu,
                                                                tuozhanshijian = 36000
                                                            })
                                                            hskill.add(demonChild, hslk.n2i("AI技能模版"), 1, 0)
                                                            local hhstatus = hhuanhua.getUnitHuanhuaStatus(targetUnit)
                                                            if hhstatus ~= nil and hhstatus[HUANHUA_POSITION.JUESE] ~= nil and hhstatus[HUANHUA_POSITION.JUESE].file ~= nil then
                                                                hjapi.DzSetUnitModel(demonChild,
                                                                    hhstatus[HUANHUA_POSITION.JUESE].file)
                                                            end
                                                            hunit.setExpReward(demonChild, 0)
                                                        end)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                name = "灭绝诅咒",
                                                castCD = 15,
                                                onlyInFight = true,
                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 2,
                                                healthBelowLimit = 90, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                castDistance = 10000,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 1)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(sourceUnit), sourceUnit,
                                                        function(targetUnit)
                                                            local attack = hattr.getWithLimit(sourceUnit, nil, "attack",
                                                                0)
                                                            local damageBlast = attack * 3
                                                            heffect.attach(
                                                                "Abilities\\Spells\\Other\\SoulBurn\\SoulBurnbuff.mdl",
                                                                targetUnit,
                                                                "head",
                                                                3
                                                            )
                                                            hbuff.update(
                                                                3,
                                                                targetUnit,
                                                                "灭绝诅咒",
                                                                false,
                                                                function()
                                                                end,
                                                                function()
                                                                    hskillMoban.radiusAOE(
                                                                        hunit.x(targetUnit),
                                                                        hunit.y(targetUnit),
                                                                        sourceUnit,
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
                                                                "灭绝诅咒，倒计时结束后会爆炸。对周围500范围内的所有单位造成" ..
                                                                damageBlast ..
                                                                "点暗影魔法伤害",
                                                                1,
                                                                nil,
                                                                nil,
                                                                nil,
                                                                nil,
                                                                HBUFF_UPDATE_MODE.OVERWRITE,
                                                                true
                                                            )
                                                        end)
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
                                { type = HSHOP_COST_TYPE.gold,       value = 5000 },
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
                                { type = HSHOP_COST_TYPE.gold,             value = 6000 },
                                { type = HSHOP_COST_TYPE.experience,       value = 18000 },
                                { type = HSHOP_COST_TYPE.huihuanghuizhang, value = 1 },
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
                                { type = HSHOP_COST_TYPE.gold,            value = 8000 },
                                { type = HSHOP_COST_TYPE.experience,      value = 20000 },
                                { type = HSHOP_COST_TYPE.kaixuanhuizhang, value = 1 },
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
                                { type = HSHOP_COST_TYPE.gold,       value = 10000 },
                                { type = HSHOP_COST_TYPE.experience, value = 25000 },
                            },
                            shengwang = {
                                {
                                    value = 500,
                                    maxLevel = 3,
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
