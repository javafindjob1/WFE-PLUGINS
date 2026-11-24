table.insert(
    FUBEN_LIST,
    {
        name = "火焰之心",
        setup = function()
            local nanduLevelConfig = {}
            nanduLevelConfig[FUBEN_NANDU.PUTONG] = 60
            nanduLevelConfig[FUBEN_NANDU.YINGXIONG] = 60
            nanduLevelConfig[FUBEN_NANDU.SHISHI] = 60
            nanduLevelConfig[FUBEN_NANDU.CHUANQI] = 70

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

            local yanjurendiaoluo =
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
                        },
                        {
                            list = { "火焰精华" }, --物品名字 需要在物编定义好
                            drop_rate = {
                                --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                0,
                                10,
                                20,
                                0
                            }
                        }
                    }
                )

            local ronghuahujia = {
                description = "融化护甲：火元素的攻击能够融化护甲",
                attr_type = CONST_EVENT.attack,
                attr = function(evtData)
                    local nandu = hunit.getNandu(evtData.triggerUnit) or FUBEN_NANDU.PUTONG
                    heffect.attach("war3mapImported\\AZ_Misslie06.MDX", evtData.targetUnit, "origin", 0)
                    hbuff.addStackAttrBuff(
                        CONST_DAMAGE_SRC.skill,
                        evtData.targetUnit,
                        "融化护甲",
                        _attr({ defend_green = "-" .. (5 * nandu) }),
                        20,
                        99,
                        "ReplaceableTextures\\zhanshi\\Ability_Warrior_Sunder.blp",
                        "破甲，每层降低" .. (5 * nandu) .. "点护甲",
                        false
                    )
                end
            }

            local shiyuansujiyun = {
                description = "重击，石元素的攻击有概率造成晕眩3秒",
                attr_type = CONST_EVENT.attack,
                attr = function(evtData)
                    local nandu = hunit.getNandu(evtData.triggerUnit) or FUBEN_NANDU.PUTONG
                    if math.random(1, 20) <= nandu then
                        hbuff.xuanyun(evtData.targetUnit, 3)
                    end
                end
            }

            local huoyuansuAI = function(level, nandu)
                return UnitAI(
                    {
                        {
                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                name = "火球术",
                                --castCountLimit = 1, -- cast only x times per battle
                                minNandu = FUBEN_NANDU.PUTONG,
                                castCD = 4, -- nil or <=1 means 1 second
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
                                                        damage = 2.5 * hattr.get(sourceUnit, "attack", 0),
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

            hfuben.buildFuben(
                {
                    name = "火焰之心", --副本名字
                    status = FUBEN_STATUS.JIANHUA,
                    blp = "ReplaceableTextures\\xiaoditu\\UI_map_14.blp",
                    enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_13.blp",
                    nanduLevelConfig = nanduLevelConfig,                                    -- 副本难度以及级别需求,
                    entryPosition = { x = -30938, y = -9010 },
                    startPosition = { x = -6742, y = -5812 },                               --英雄进副本后位置
                    rectParam = { minX = -15237, minY = -6397, maxX = -5932, maxY = 2821 }, -- 副本区域
                    minions = {
                        {
                            name = "精英石元素", -- 名字 需要在物编定义好
                            x = -6987, -- 小怪刷新x坐标
                            y = -5000, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英石元素", -- 名字 需要在物编定义好
                            x = -6483, -- 小怪刷新x坐标
                            y = -4063, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英火元素", -- 名字 需要在物编定义好
                            x = -7040, -- 小怪刷新x坐标
                            y = -3343, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { ronghuahujia }, { ronghuahujia }, { ronghuahujia }, { ronghuahujia } },
                            ai = ai
                        },
                        {
                            name = "精英火元素", -- 名字 需要在物编定义好
                            x = -7078, -- 小怪刷新x坐标
                            y = -1164, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { ronghuahujia }, { ronghuahujia }, { ronghuahujia }, { ronghuahujia } },
                            ai = huoyuansuAI
                        },
                        {
                            name = "精英炎巨人", -- 名字 需要在物编定义好
                            x = -7604, -- 小怪刷新x坐标
                            y = -2534, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = yanjurendiaoluo,
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英炎巨人", -- 名字 需要在物编定义好
                            x = -6889, -- 小怪刷新x坐标
                            y = -2534, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = yanjurendiaoluo,
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英石元素", -- 名字 需要在物编定义好
                            x = -9282, -- 小怪刷新x坐标
                            y = 1660, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英石元素", -- 名字 需要在物编定义好
                            x = -10443, -- 小怪刷新x坐标
                            y = 2034, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英炎巨人", -- 名字 需要在物编定义好
                            x = -12116, -- 小怪刷新x坐标
                            y = 1762, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = yanjurendiaoluo,
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英火元素", -- 名字 需要在物编定义好
                            x = -13548, -- 小怪刷新x坐标
                            y = 2121, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { ronghuahujia }, { ronghuahujia }, { ronghuahujia }, { ronghuahujia } },
                            ai = huoyuansuAI
                        },
                        {
                            name = "精英火元素", -- 名字 需要在物编定义好
                            x = -14383, -- 小怪刷新x坐标
                            y = 1781, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { ronghuahujia }, { ronghuahujia }, { ronghuahujia }, { ronghuahujia } },
                            ai = huoyuansuAI
                        },
                        {
                            name = "精英火元素", -- 名字 需要在物编定义好
                            x = -14400, -- 小怪刷新x坐标
                            y = 870, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { ronghuahujia }, { ronghuahujia }, { ronghuahujia }, { ronghuahujia } },
                            ai = huoyuansuAI
                        },
                        {
                            name = "精英火元素", -- 名字 需要在物编定义好
                            x = -13962, -- 小怪刷新x坐标
                            y = 480, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { ronghuahujia }, { ronghuahujia }, { ronghuahujia }, { ronghuahujia } },
                            ai = huoyuansuAI
                        },
                        {
                            name = "精英火元素", -- 名字 需要在物编定义好
                            x = -13200, -- 小怪刷新x坐标
                            y = 463, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { ronghuahujia }, { ronghuahujia }, { ronghuahujia }, { ronghuahujia } },
                            ai = huoyuansuAI
                        },
                        {
                            name = "精英火元素", -- 名字 需要在物编定义好
                            x = -12761, -- 小怪刷新x坐标
                            y = 879, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { ronghuahujia }, { ronghuahujia }, { ronghuahujia }, { ronghuahujia } },
                            ai = huoyuansuAI
                        },
                        {
                            name = "精英炎巨人", -- 名字 需要在物编定义好
                            x = -14104, -- 小怪刷新x坐标
                            y = -967, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = yanjurendiaoluo,
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英火元素", -- 名字 需要在物编定义好
                            x = -14104, -- 小怪刷新x坐标
                            y = -1267, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { ronghuahujia }, { ronghuahujia }, { ronghuahujia }, { ronghuahujia } },
                            ai = huoyuansuAI
                        },
                        {
                            name = "精英石元素", -- 名字 需要在物编定义好
                            x = -13584, -- 小怪刷新x坐标
                            y = -2137, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英火元素", -- 名字 需要在物编定义好
                            x = -13284, -- 小怪刷新x坐标
                            y = -2137, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { ronghuahujia }, { ronghuahujia }, { ronghuahujia }, { ronghuahujia } },
                            ai = huoyuansuAI
                        },
                        {
                            name = "精英炎巨人", -- 名字 需要在物编定义好
                            x = -11943, -- 小怪刷新x坐标
                            y = -652, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = yanjurendiaoluo,
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英炎巨人", -- 名字 需要在物编定义好
                            x = -11494, -- 小怪刷新x坐标
                            y = -1827, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = yanjurendiaoluo,
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英炎巨人", -- 名字 需要在物编定义好
                            x = -8894, -- 小怪刷新x坐标
                            y = -528, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = yanjurendiaoluo,
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英炎巨人", -- 名字 需要在物编定义好
                            x = -9377, -- 小怪刷新x坐标
                            y = -1935, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = yanjurendiaoluo,
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英石元素", -- 名字 需要在物编定义好
                            x = -8706, -- 小怪刷新x坐标
                            y = -3773, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "精英火元素", -- 名字 需要在物编定义好
                            x = -8366, -- 小怪刷新x坐标
                            y = -4408, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { { ronghuahujia }, { ronghuahujia }, { ronghuahujia }, { ronghuahujia } },
                            ai = huoyuansuAI
                        },
                        {
                            name = "精英炎巨人", -- 名字 需要在物编定义好
                            x = -8749, -- 小怪刷新x坐标
                            y = -5440, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = yanjurendiaoluo,
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        }
                    },
                    bosses = {
                        {
                            name = "嘉尔",
                            x = -7306,
                            y = 1377,
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
                                        list = { "逐风者禁锢之颅（右）" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            50,
                                            200,
                                            0
                                        }
                                    },
                                    {
                                        list = { "先驱勇士腿甲", "先驱斥候腿甲", "先驱法师腿甲" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            1000,
                                            0,
                                            0
                                        }
                                    },
                                    {
                                        list = { "远古先驱勇士腿甲", "远古先驱斥候腿甲", "远古先驱法师腿甲" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            0,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "速射强弓", "脊骨收割者", "黑手饰物", "迅击戒指" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "火焰精华" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2000,
                                            4000,
                                            10000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "埃提耶什的碎片" }, --物品名字 需要在物编定义好
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
                            ai = function(level, nandu, count, status, mijing)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                name = "召唤精英石元素", --技能1
                                                notInterruptable = true,
                                                healthBelowLimit = 100,
                                                castCountLimit = 1,
                                                castCD = 99,
                                                shifashijian = 3,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local whichUnit = evtData.triggerUnit
                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = level,
                                                                attackSpace = hslk.n2v("精英石元素", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_XIAOGUAI,
                                                                nandu = nandu,
                                                                count = count,
                                                                mijing = mijing
                                                            }
                                                        )
                                                    for i = 1, 8, 1 do
                                                        local tmpUnit =
                                                            henemy.create(
                                                                {
                                                                    id = hslk.n2i("精英石元素"),
                                                                    x = hunit.x(whichUnit) + math.random(-100, 100),
                                                                    y = hunit.y(whichUnit) + math.random(-100, 100),
                                                                    facing = 0,
                                                                    attr = tmpAttr,
                                                                    nandu = nandu,
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
                                                                    tuozhanshijian = 36000
                                                                }
                                                            )
                                                        hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                                                        hunit.setExpReward(tmpUnit, 0)
                                                        if nandu >= FUBEN_NANDU.SHISHI then
                                                            hevent.register(
                                                                tmpUnit,
                                                                CONST_EVENT.dead,
                                                                "死亡自爆",
                                                                function(evtData)
                                                                    local x = hunit.x(tmpUnit)
                                                                    local y = hunit.y(tmpUnit)
                                                                    local z = hunit.z(tmpUnit)
                                                                    hskillMoban.radiusWarning(x, y, z, 500, 3)
                                                                    htime.setTimeout(
                                                                        2,
                                                                        function(_)
                                                                            heffect.xyz(
                                                                                "[boss]zibao.mdx",
                                                                                x,
                                                                                y,
                                                                                z,
                                                                                0,
                                                                                1,
                                                                                1,
                                                                                1,
                                                                                1
                                                                            )
                                                                            hskillMoban.radiusAOE(
                                                                                x,
                                                                                y,
                                                                                whichUnit,
                                                                                500,
                                                                                function(unit)
                                                                                    hskill.damage(
                                                                                        {
                                                                                            sourceUnit = whichUnit,
                                                                                            targetUnit = unit,
                                                                                            damage = 1000 * nandu +
                                                                                                hunit.getMaxLife(unit) *
                                                                                                0.5,
                                                                                            damageSrc = CONST_DAMAGE_SRC
                                                                                                .skill,
                                                                                            damageType = DAMAGE_TYPE
                                                                                                .MOFA,
                                                                                            damageSpeedType =
                                                                                                CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                                                                            damageElementType = {
                                                                                                CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                                            },
                                                                                            triggerSkill = hslk.n2i(
                                                                                                "AI技能模版"
                                                                                            )
                                                                                        }
                                                                                    )
                                                                                    hskillMoban.crackFly(
                                                                                        {
                                                                                            sourceUnit = whichUnit,
                                                                                            targetUnit = unit,
                                                                                            model = nil,
                                                                                            animate = "dead",
                                                                                            animateScale = 1,
                                                                                            distance = 500,
                                                                                            height = 300,
                                                                                            duration = 2.5,
                                                                                            onEndAnyway = function(
                                                                                                sourceUnit,
                                                                                                targetUnit,
                                                                                                point)
                                                                                                hunit.setFlyHeight(
                                                                                                    targetUnit,
                                                                                                    0,
                                                                                                    9999
                                                                                                )
                                                                                            end
                                                                                        }
                                                                                    )
                                                                                end
                                                                            )
                                                                        end
                                                                    )
                                                                end
                                                            )
                                                        end
                                                    end
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "引爆", --技能1
                                                notInterruptable = true,
                                                healthBelowLimit = 50,
                                                castCountLimit = 1,
                                                castCD = 15,
                                                shifashijian = 2,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local triggerUnit = evtData.triggerUnit

                                                    local units = hgroup.createAllyGroupByUnit(triggerUnit, 1500)
                                                    for _, unit in ipairs(units) do
                                                        if hunit.getName(unit) == "精英石元素" then
                                                            hunit.kill(unit)
                                                        end
                                                    end
                                                    local attack = hattr.get(triggerUnit, "attack", 0)
                                                    hbuff.update(
                                                        -1,
                                                        triggerUnit,
                                                        "激怒",
                                                        true,
                                                        function()
                                                            hattribute.set(
                                                                triggerUnit,
                                                                0,
                                                                {
                                                                    attack = "+" .. tostring(attack * 0.5),
                                                                    attack_speed = "+50",
                                                                    move = "+200"
                                                                }
                                                            )
                                                        end,
                                                        function()
                                                            hattribute.set(
                                                                triggerUnit,
                                                                0,
                                                                {
                                                                    attack = "-" .. tostring(attack * 0.5),
                                                                    attack_speed = "-50",
                                                                    move = "-200"
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
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "群体减速", --技能1
                                                notInterruptable = true,
                                                healthBelowLimit = 80,
                                                --castCountLimit = 1,
                                                castCD = 15,
                                                shifashijian = 2,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local triggerUnit = evtData.triggerUnit
                                                    hskillMoban.radiusAOE(
                                                        hunit.x(triggerUnit),
                                                        hunit.y(triggerUnit),
                                                        triggerUnit,
                                                        1500,
                                                        function(unit)
                                                            hbuff.update(
                                                                8,
                                                                unit,
                                                                "加尔减速",
                                                                false,
                                                                function()
                                                                    hattr.set(unit, 0, _attr({ move = "-200" }))
                                                                end,
                                                                function()
                                                                    hattr.set(unit, 0, _attr({ move = "+200" }))
                                                                end,
                                                                "ReplaceableTextures\\CommandButtons\\BTNSlowOn.blp",
                                                                "降低200移动速度",
                                                                1,
                                                                nil,
                                                                nil,
                                                                nil,
                                                                nil,
                                                                HBUFF_UPDATE_MODE.OVERWRITE,
                                                                true
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
                            name = "嘉顿",
                            x = -13556,
                            y = 1226,
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
                                        list = { "先驱勇士头盔", "先驱斥候头盔", "先驱法师头盔" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            1000,
                                            0,
                                            0
                                        }
                                    },
                                    {
                                        list = { "远古先驱勇士头盔", "远古先驱斥候头盔", "远古先驱法师头盔" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            0,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "炎魔之指", "毁灭之刃", "烈焰勋章", "火焰符文魔典" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "火焰精华" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2000,
                                            4000,
                                            10000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "埃提耶什的碎片" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "逐风者禁锢之颅（左）" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            50,
                                            200,
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
                                                name = "地狱火",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                shifashijian = 1 + nandu * 3,
                                                castCD = 40, -- nil or <=1 means 1 second
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = true,
                                                healthBelowLimit = 80, -- only cast when health is < 65%
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
                                                    hskillMoban.radiusWarning(
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit),
                                                        hunit.z(evtData.triggerUnit),
                                                        900,
                                                        3
                                                    )
                                                end,
                                                interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                    local timePassed = curTimer.passedSec()
                                                    local aoeSize = 900
                                                    local scale = aoeSize / 500
                                                    heffect.xyz(
                                                        "[boss]zibao.mdx",
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit),
                                                        hunit.z(evtData.triggerUnit),
                                                        0,
                                                        1,
                                                        scale,
                                                        scale,
                                                        1
                                                    )
                                                    local attack =
                                                        hattr.getWithLimit(evtData.triggerUnit, nil, "attack", 1000)
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
                                                                    damage = attack * timePassed * nandu / 3,
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                    triggerSkill = hslk.n2i("AI技能模版")
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
                                                targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                                name = "火焰炸弹",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                castCD = 20, -- nil or <=1 means 1 second
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 90, -- only cast when health is < 65%
                                                startEffect = function(evtData)
                                                end,
                                                shifashijian = 0.5,
                                                notInterruptable = true,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                effect = function(evtData)
                                                    local whichUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local attack = hattr.getWithLimit(whichUnit, nil, "attack", 0)
                                                    local damagePs = attack * 0.5
                                                    local damageBlast = attack * 3
                                                    local damageFall = attack * 2
                                                    heffect.attach(
                                                        "Abilities\\Spells\\Other\\SoulBurn\\SoulBurnbuff.mdl",
                                                        targetUnit,
                                                        "head",
                                                        6
                                                    )
                                                    hbuff.update(
                                                        6,
                                                        targetUnit,
                                                        "火焰炸弹嘉顿",
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
                                                                            triggerSkill = hslk.n2i("AI技能模版")
                                                                        }
                                                                    )
                                                                end
                                                            )
                                                            heffect.xyz(
                                                                "[boss]jiadun.mdx",
                                                                hunit.x(targetUnit),
                                                                hunit.y(targetUnit),
                                                                hunit.z(targetUnit),
                                                                0,
                                                                1,
                                                                2,
                                                                2,
                                                                2
                                                            )
                                                            hskillMoban.blastUnit(
                                                                targetUnit,
                                                                3000,
                                                                1500,
                                                                function(unit)
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = whichUnit,
                                                                            targetUnit = targetUnit,
                                                                            damage = damageFall,
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.WULI,
                                                                            damageElementType = {
                                                                                CONST_DAMAGE_ELEMENT_TYPE.EARTH
                                                                            },
                                                                            triggerSkill = hslk.n2i("AI技能模版")
                                                                        }
                                                                    )
                                                                end
                                                            )
                                                        end,
                                                        "ReplaceableTextures\\CommandButtons\\BTNSoulBurn.blp",
                                                        "燃烧，每秒受到" ..
                                                        damagePs ..
                                                        "点火焰魔法伤害，倒计时结束后会爆炸。对周围500范围内的所有单位造成" ..
                                                        damageBlast ..
                                                        "点火焰魔法伤害，并把单位炸上天，掉落之后再受到" ..
                                                        damageFall .. "点物理伤害",
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
                                                                        CONST_DAMAGE_ELEMENT_TYPE.FIRE
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
                                                targetType = UNIT_AI_TARGET_TYPE.RANDOM_ENERMY_UNIT, --TODO  add random unit
                                                name = "魔法燃烧",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                castCD = 20, -- nil or <=1 means 1 second
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 2,
                                                notInterruptable = false,
                                                healthBelowLimit = 90, -- only cast when health is < 65%
                                                startEffect = function(evtData)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                effect = function(evtData)
                                                    local targetUnit = evtData.targetUnit
                                                    local duration = nandu + 4
                                                    hbuff.update(
                                                        duration,
                                                        targetUnit,
                                                        "魔法燃烧",
                                                        false,
                                                        function()
                                                        end,
                                                        function()
                                                        end,
                                                        "ReplaceableTextures\\CommandButtons\\BTNManaBurn.blp",
                                                        "魔法燃烧，每秒消耗单位30点能量，持续" .. duration .. "秒",
                                                        1,
                                                        1,
                                                        function(curTimer, buffHandle)
                                                            buffHandle.remainingTime =
                                                                buffHandle.remainingTime - buffHandle.interval
                                                            hunit.subCurMana(targetUnit, 30)
                                                            heffect.attach(
                                                                "Abilities\\Spells\\NightElf\\ManaBurn\\ManaBurnTarget.mdl",
                                                                targetUnit,
                                                                "chest",
                                                                0
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
                            name = "焚化者古曼",
                            x = -10378,
                            y = -907,
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
                                        list = { "先驱勇士护手", "先驱斥候护手", "先驱法师护手" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            1000,
                                            0,
                                            0
                                        }
                                    },
                                    {
                                        list = { "远古先驱勇士护手", "远古先驱斥候护手", "远古先驱法师护手" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            0,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "碧空之歌", "统御法杖", "迅击项链" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "萨弗隆铁锭" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            100,
                                            500,
                                            0
                                        }
                                    },
                                    {
                                        list = { "埃提耶什的碎片" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "远古石叶" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "火焰精华" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2000,
                                            4000,
                                            8000,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = function(level, nandu, count)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "召唤熔岩地狱犬", --技能1
                                                notInterruptable = true,
                                                --healthBelowLimit = 100,
                                                castCountLimit = 1,
                                                castDistance = 300,
                                                castCD = 99,
                                                shifashijian = 0.1,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local whichUnit = evtData.triggerUnit
                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = level,
                                                                attackSpace = hslk.n2v("古曼的地狱犬", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_JINGYING,
                                                                nandu = nandu,
                                                                count = count
                                                            }
                                                        )
                                                    for i = 1, 2, 1 do
                                                        local tmpUnit =
                                                            henemy.create(
                                                                {
                                                                    id = hslk.n2i("古曼的地狱犬"),
                                                                    x = hunit.x(whichUnit) + math.random(-100, 100),
                                                                    y = hunit.y(whichUnit) + math.random(-100, 100),
                                                                    facing = 0,
                                                                    attr = tmpAttr,
                                                                    nandu = nandu,
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
                                                                    tuozhanshijian = 36000
                                                                }
                                                            )
                                                        hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                                                        hunit.setExpReward(tmpUnit, 0)
                                                        if nandu >= FUBEN_NANDU.SHISHI then
                                                            hevent.register(
                                                                tmpUnit,
                                                                CONST_EVENT.damagingCustomTarget,
                                                                "地狱犬免伤",
                                                                function(evtData)
                                                                    if hunit.isAlive(whichUnit) then
                                                                        evtData.damage = 50
                                                                    end
                                                                end
                                                            )
                                                        end
                                                    end
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "地震",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                shifashijian = 10.1,
                                                castCD = 999, -- nil or <=1 means 1 second
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = true,
                                                healthBelowLimit = 20, -- only cast when health is < 65%
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
                                                    hskillMoban.radiusWarning(
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit),
                                                        hunit.z(evtData.triggerUnit),
                                                        500,
                                                        3
                                                    )
                                                end,
                                                interval = 0.5,
                                                periodEffect = function(evtData, curTimer)
                                                    local aoeSize = 500
                                                    heffect.xyz(
                                                        "[boss]diyuhuo.mdx",
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit),
                                                        hunit.z(evtData.triggerUnit),
                                                        0,
                                                        1,
                                                        1.7,
                                                        1.7,
                                                        1
                                                    )

                                                    local attack =
                                                        hattr.getWithLimit(evtData.triggerUnit, nil, "attack", 0)
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
                                                                    damage = attack * nandu,
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.WULI,
                                                                    damageElementType = {
                                                                        CONST_DAMAGE_ELEMENT_TYPE.EARTH
                                                                    },
                                                                    triggerSkill = hslk.n2i("AI技能模版")
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
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT, --TODO  add random unit
                                                name = "破甲",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                castCD = 10,            -- nil or <=1 means 1 second
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 100, -- only cast when health is < 65%
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "融化你门的护甲！!",
                                                        10,
                                                        "ff3300",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                end,
                                                shifashijian = 1,
                                                notInterruptable = true,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                effect = function(evtData)
                                                    local whichUnit = evtData.triggerUnit
                                                    hskillMoban.radiusAOE(
                                                        hunit.x(whichUnit),
                                                        hunit.y(whichUnit),
                                                        whichUnit,
                                                        2000,
                                                        function(target)
                                                            heffect.attach(
                                                                "war3mapImported\\Armor Penetration Orange.mdx",
                                                                target,
                                                                "chest",
                                                                1
                                                            )
                                                            hbuff.addStackAttrBuff(
                                                                CONST_DAMAGE_SRC.skill,
                                                                target,
                                                                "古曼破甲",
                                                                _attr({ defend_green = "-" .. (20 * nandu) }),
                                                                20,
                                                                99,
                                                                "ReplaceableTextures\\zhanshi\\Ability_Warrior_Sunder.blp",
                                                                "破甲，每层降低" .. (20 * nandu) .. "点护甲",
                                                                false
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
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                castCD = 30, -- nil or <=1 means 1 second
                                                --healthBelowLimit = 65, -- only cast when health is < 65%
                                                shifashijian = 2,
                                                notInterruptable = false,
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
                                                            scale = 1.5,
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
                                                                hbuff.update(
                                                                    16,
                                                                    targetUnit,
                                                                    "灼烧古曼",
                                                                    false,
                                                                    nil,
                                                                    nil,
                                                                    "ReplaceableTextures\\CommandButtons\\BTNFireBolt.blp",
                                                                    "灼烧效果，每层每秒受到火焰魔法伤害",
                                                                    1,
                                                                    1,
                                                                    function(curTimer, buffHandle)
                                                                        buffHandle.remainingTime =
                                                                            buffHandle.remainingTime -
                                                                            buffHandle.interval
                                                                        local attack =
                                                                            hattr.getWithLimit(
                                                                                sourceUnit,
                                                                                nil,
                                                                                "attack",
                                                                                0
                                                                            )
                                                                        local damagePs = attack * 0.5 * buffHandle.stack
                                                                        hskill.damage(
                                                                            {
                                                                                sourceUnit = evtData.triggerUnit,
                                                                                targetUnit = targetUnit,
                                                                                damage = damagePs,
                                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                                damageType = DAMAGE_TYPE.MOFA,
                                                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                    .DOT,
                                                                                damageElementType = {
                                                                                    CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                                },
                                                                                triggerSkill = hslk.n2i("AI技能模版")
                                                                            }
                                                                        )
                                                                    end,
                                                                    function(buffHandle)
                                                                        buffHandle.stack = buffHandle.stack + 1
                                                                        buffHandle.remainingTime = 16
                                                                    end,
                                                                    nil,
                                                                    HBUFF_UPDATE_MODE.UPDATE,
                                                                    true
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
                            passiveSkill = { {}, {}, {}, {} }
                        },
                        {
                            name = "炎魔之王",
                            x = -12454,
                            y = -4378,
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
                                        list = { "先驱勇士胸甲", "先驱斥候胸甲", "先驱法师胸甲" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            1000,
                                            0,
                                            0
                                        }
                                    },
                                    {
                                        list = { "远古先驱勇士胸甲", "远古先驱斥候胸甲", "远古先驱法师胸甲" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            0,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "削骨之刃", "冲击披风", "火焰之王的项圈", "毁灭王冠" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "炎魔之眼" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            50,
                                            200,
                                            0
                                        }
                                    },
                                    {
                                        list = { "埃提耶什的碎片" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "火焰之王的精华" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            50,
                                            300,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = function(level, nandu, count, status, mijing)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "融入岩浆",
                                                castCD = 27,
                                                --castCountLimit = 1,
                                                shifashijian = 25,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                healthBelowLimit = 50, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    if hcache.get(whichUnit, "消灭所有炎魔之子", false) then
                                                        return false
                                                    else
                                                        return true
                                                    end
                                                end,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 10)
                                                    hevent.register(
                                                        evtData.triggerUnit,
                                                        CONST_EVENT.damagingCustomTarget,
                                                        "炎魔无敌",
                                                        function(evtData)
                                                            evtData.damage = 0
                                                        end
                                                    )
                                                    hunit.setInvulnerable(evtData.triggerUnit, true)

                                                    local whichUnit = evtData.triggerUnit
                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = level,
                                                                attackSpace = hslk.n2v("炎魔之子", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_JINGYING,
                                                                nandu = nandu,
                                                                count = count,
                                                                mijing = mijing
                                                            }
                                                        )
                                                    for i = 1, 3, 1 do
                                                        local tmpUnit =
                                                            henemy.create(
                                                                {
                                                                    id = hslk.n2i("炎魔之子"),
                                                                    x = hunit.x(whichUnit) + math.random(-500, 500),
                                                                    y = hunit.y(whichUnit) + math.random(-500, 500),
                                                                    facing = 0,
                                                                    attr = tmpAttr,
                                                                    nandu = nandu,
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
                                                                    tuozhanshijian = 36000
                                                                }
                                                            )
                                                        hattribute.set(
                                                            tmpUnit,
                                                            0,
                                                            { life = "=" .. tostring(0.7 * hunit.getMaxLife(tmpUnit)) }
                                                        )
                                                        hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                                                        hunit.setExpReward(tmpUnit, 0)
                                                    end
                                                end,
                                                effect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 9)
                                                    local units =
                                                        hgroup.createAllyGroupByUnit(evtData.triggerUnit, 5000)
                                                    local hasYanmozhizi = false
                                                    for _, unit in ipairs(units) do
                                                        if hunit.isAlive(unit) and hunit.getName(unit) == "炎魔之子" then
                                                            hunit.kill(unit)
                                                            hasYanmozhizi = true
                                                        end
                                                    end
                                                    if hasYanmozhizi == false then
                                                        hcache.set(evtData.triggerUnit, "消灭所有炎魔之子", true)
                                                    end
                                                    hunit.animate(evtData.triggerUnit, 9)
                                                    htime.setTimeout(
                                                        2,
                                                        function(t)
                                                            hunit.setInvulnerable(evtData.triggerUnit, false)
                                                            hevent.unregister(
                                                                evtData.triggerUnit,
                                                                CONST_EVENT.damagingCustomTarget,
                                                                "炎魔无敌"
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
                                                name = "炎魔之怒",
                                                castCD = 25,
                                                shifashijian = 3,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = true,
                                                startEffect = function(evtData)
                                                    cj.SetUnitMoveSpeed(evtData.triggerUnit, 1)
                                                    hsound.voice2Unit(
                                                        hsound.voiceCreate(
                                                            "resource\\war3mapImported\\sound\\warning.wav",
                                                            1000,
                                                            true
                                                        ),
                                                        100,
                                                        evtData.triggerUnit
                                                    )
                                                    local x = hunit.x(evtData.triggerUnit)
                                                    local y = hunit.y(evtData.triggerUnit)
                                                    local z = hunit.z(evtData.triggerUnit)
                                                    hskillMoban.radiusWarning(x, y, z, 800, evtData.shifashijian)
                                                    hunit.setAnimateSpeed(
                                                        evtData.triggerUnit,
                                                        1.30 / evtData.shifashijian,
                                                        evtData.shifashijian
                                                    )
                                                    hunit.animate(evtData.triggerUnit, 2)
                                                end,
                                                effect = function(evtData)
                                                    local targetUnit = evtData.targetUnit
                                                    local sourceUnit = evtData.triggerUnit
                                                    local group = hgroup.createEnermyGroupByUnit(sourceUnit, 800)
                                                    local scale = 800 / 300
                                                    heffect.xyz(
                                                        "war3mapImported\\[Spell]_055.MDX",
                                                        hunit.x(sourceUnit),
                                                        hunit.y(sourceUnit),
                                                        hunit.z(sourceUnit),
                                                        0,
                                                        1,
                                                        scale,
                                                        scale,
                                                        scale
                                                    )
                                                    for _, _unit in ipairs(group) do
                                                        local attack = hattr.get(sourceUnit, "attack", 0)
                                                        hskill.damage(
                                                            {
                                                                sourceUnit = sourceUnit,
                                                                targetUnit = _unit,
                                                                damage = attack,
                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                damageType = DAMAGE_TYPE.WULI,
                                                                triggerSkill = hslk.n2i("AI技能模版"),
                                                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE }
                                                            }
                                                        )
                                                        hskillMoban.crackFly(
                                                            {
                                                                sourceUnit = sourceUnit,
                                                                targetUnit = _unit,
                                                                model = nil,
                                                                animate = "dead",
                                                                animateScale = 1,
                                                                distance = 1000,
                                                                height = 3000,
                                                                duration = 2.5,
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
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = sourceUnit,
                                                                            targetUnit = targetUnit,
                                                                            damage = 5000 * nandu,
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.WULI,
                                                                            tmpAttr = _attr({ hit = "+999" }),
                                                                            damageElementType = {
                                                                                CONST_DAMAGE_ELEMENT_TYPE.EARTH
                                                                            },
                                                                            triggerSkill = hslk.n2i("AI技能模版")
                                                                        }
                                                                    )
                                                                    hunit.setFlyHeight(targetUnit, 0, 9999)
                                                                end
                                                            }
                                                        )
                                                    end
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                                name = "火焰净化",
                                                castCD = 15,
                                                castDistance = 10000,
                                                shifashijian = 2,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local x = hunit.x(targetUnit)
                                                    local y = hunit.y(targetUnit)
                                                    local z = hunit.z(sourceUnit)
                                                    local e = hskillMoban.radiusWarning(x, y, z, 400, 2)
                                                    hskillMoban.missile(
                                                        {
                                                            model =
                                                            "Abilities\\Weapons\\RedDragonBreath\\RedDragonMissile.mdl",
                                                            scale = 2.0,
                                                            speed = 600,
                                                            hover = 50,
                                                            sourceUnit = sourceUnit,
                                                            targetX = x,
                                                            targetY = y,
                                                            target_face_dis = 10,
                                                            onEnd = function()
                                                                heffect.destroy(e)
                                                                hskillMoban.radiusAOE(
                                                                    x,
                                                                    y,
                                                                    sourceUnit,
                                                                    400,
                                                                    function(unit)
                                                                        local attack =
                                                                            hattr.get(sourceUnit, "attack", 0)
                                                                        hskill.damage(
                                                                            {
                                                                                sourceUnit = sourceUnit,
                                                                                targetUnit = targetUnit,
                                                                                damage = attack,
                                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                                damageType = DAMAGE_TYPE.MOFA,
                                                                                tmpAttr = _attr(
                                                                                    {
                                                                                        hit = "+999"
                                                                                    }
                                                                                ),
                                                                                damageElementType = {
                                                                                    CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                                },
                                                                                triggerSkill = hslk.n2i("AI技能模版")
                                                                            }
                                                                        )
                                                                        hskillMoban.crackFly(
                                                                            {
                                                                                sourceUnit = sourceUnit,
                                                                                targetUnit = unit,
                                                                                model = nil,
                                                                                distance = 500,
                                                                                height = 1000,
                                                                                duration = 1.5,
                                                                                onMove = function(
                                                                                    sourceUnit,
                                                                                    targetUnit,
                                                                                    point)
                                                                                end,
                                                                                onEndAnyway = function(
                                                                                    sourceUnit,
                                                                                    targetUnit,
                                                                                    point)
                                                                                    local attack =
                                                                                        hattr.get(
                                                                                            sourceUnit,
                                                                                            "attack",
                                                                                            0
                                                                                        )
                                                                                    hunit.setFlyHeight(
                                                                                        targetUnit,
                                                                                        0,
                                                                                        9999
                                                                                    )
                                                                                    hskill.damage(
                                                                                        {
                                                                                            sourceUnit = sourceUnit,
                                                                                            targetUnit = targetUnit,
                                                                                            damage = attack,
                                                                                            damageSrc = CONST_DAMAGE_SRC
                                                                                                .skill,
                                                                                            damageType = DAMAGE_TYPE
                                                                                                .WULI,
                                                                                            tmpAttr = _attr(
                                                                                                {
                                                                                                    hit = "+999"
                                                                                                }
                                                                                            ),
                                                                                            damageElementType = {
                                                                                                CONST_DAMAGE_ELEMENT_TYPE.EARTH
                                                                                            },
                                                                                            triggerSkill = hslk.n2i(
                                                                                                "AI技能模版"
                                                                                            )
                                                                                        }
                                                                                    )
                                                                                end
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
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "烈焰喷发",
                                                castCD = 10 - nandu,
                                                shifashijian = 0.5,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = true,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local originalX = hunit.x(sourceUnit)
                                                    local originalY = hunit.y(sourceUnit)
                                                    local angel = math.random(0, 360)
                                                    local distance = math.random(600, 1300)
                                                    local x, y =
                                                        math.polarProjection(originalX, originalY, distance, angel)
                                                    local size = 500
                                                    local scale = size / 400
                                                    local e =
                                                        hskillMoban.radiusWarning(x, y, hunit.z(sourceUnit), size, 2)
                                                    htime.setTimeout(
                                                        1,
                                                        function()
                                                            local e =
                                                                heffect.xyz(
                                                                    "[boss]yanjiang.mdx",
                                                                    x,
                                                                    y,
                                                                    hunit.z(sourceUnit),
                                                                    30,
                                                                    1,
                                                                    scale,
                                                                    scale,
                                                                    1
                                                                )

                                                            htime.setInterval(
                                                                1,
                                                                function(curTimer)
                                                                    if curTimer.passedSec() >= 30 then
                                                                        curTimer.destroy()
                                                                        heffect.destroy(e)
                                                                        return
                                                                    end
                                                                    local attack = hattr.get(sourceUnit, "attack", 0)
                                                                    hskillMoban.radiusAOE(
                                                                        x,
                                                                        y,
                                                                        sourceUnit,
                                                                        size,
                                                                        function(targetUnit)
                                                                            hskill.damage(
                                                                                {
                                                                                    sourceUnit = sourceUnit,
                                                                                    targetUnit = targetUnit,
                                                                                    damage = attack * 3,
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
                                                name = "火球术",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                castCD = 1, -- nil or <=1 means 1 second
                                                --healthBelowLimit = 65, -- only cast when health is < 65%
                                                notInterruptable = false,
                                                shifashijian = 2,
                                                customCondition = function(whichUnit)
                                                    local chouhendiyi = hfightzhuangtai.getChouhengdiyi(whichUnit)
                                                    if
                                                        math.distance(
                                                            hunit.x(whichUnit),
                                                            hunit.y(whichUnit),
                                                            hunit.x(chouhendiyi),
                                                            hunit.y(chouhendiyi)
                                                        ) > 800
                                                    then
                                                        return true
                                                    end
                                                end,
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
                                                            scale = 1.5,
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
                                                                hbuff.update(
                                                                    16,
                                                                    targetUnit,
                                                                    "炎魔之王灼烧",
                                                                    false,
                                                                    nil,
                                                                    nil,
                                                                    "ReplaceableTextures\\CommandButtons\\BTNFireBolt.blp",
                                                                    "灼烧效果，每层每秒受到火焰魔法伤害",
                                                                    1,
                                                                    1,
                                                                    function(curTimer, buffHandle)
                                                                        buffHandle.remainingTime =
                                                                            buffHandle.remainingTime -
                                                                            buffHandle.interval
                                                                        local attack =
                                                                            hattr.getWithLimit(
                                                                                sourceUnit,
                                                                                nil,
                                                                                "attack",
                                                                                0
                                                                            )
                                                                        local damagePs = attack * 0.5 * buffHandle.stack
                                                                        hskill.damage(
                                                                            {
                                                                                sourceUnit = evtData.triggerUnit,
                                                                                targetUnit = targetUnit,
                                                                                damage = damagePs,
                                                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                                                damageType = DAMAGE_TYPE.MOFA,
                                                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                    .DOT,
                                                                                damageElementType = {
                                                                                    CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                                },
                                                                                triggerSkill = hslk.n2i("AI技能模版")
                                                                            }
                                                                        )
                                                                    end,
                                                                    function(buffHandle)
                                                                        buffHandle.stack = buffHandle.stack + 1
                                                                        buffHandle.remainingTime = 16
                                                                    end,
                                                                    nil,
                                                                    HBUFF_UPDATE_MODE.UPDATE,
                                                                    true
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
                            passiveSkill = { {}, {}, {}, {} }
                        }
                    },
                    tongguanjiangli = {
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,           value = 1000 },
                                { type = HSHOP_COST_TYPE.yongqihuizhang, value = 2 }
                            },
                            shengwang = {
                                {
                                    value = 500,
                                    maxLevel = 2,
                                    shengwangname = "峡谷前哨站"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,           value = 1500 },
                                { type = HSHOP_COST_TYPE.yongqihuizhang, value = 4 },
                                { type = HSHOP_COST_TYPE.huoyanhuizhang, value = 1 }
                            },
                            shengwang = {
                                {
                                    value = 500,
                                    maxLevel = 3,
                                    shengwangname = "峡谷前哨站"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,           value = 2000 },
                                { type = HSHOP_COST_TYPE.yongqihuizhang, value = 6 },
                                { type = HSHOP_COST_TYPE.huoyanhuizhang, value = 3 }
                            },
                            shengwang = {
                                {
                                    value = 1000,
                                    maxLevel = 3,
                                    shengwangname = "峡谷前哨站"
                                },
                                {
                                    value = 200,
                                    maxLevel = 1,
                                    shengwangname = "冒险者工会"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience,     value = 5000 },
                                { type = HSHOP_COST_TYPE.gold,           value = 1500 },
                                { type = HSHOP_COST_TYPE.yongqihuizhang, value = 3 },
                                { type = HSHOP_COST_TYPE.huoyanhuizhang, value = 3 }
                            },
                            shengwang = {
                                {
                                    value = 500,
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
