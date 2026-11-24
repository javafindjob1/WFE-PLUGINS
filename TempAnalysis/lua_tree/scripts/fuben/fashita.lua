table.insert(
    FUBEN_LIST,
    {
        name = "法师塔",
        setup = function()
            local nanduLevelConfig                  = {}
            nanduLevelConfig[FUBEN_NANDU.PUTONG]    = 68
            nanduLevelConfig[FUBEN_NANDU.YINGXIONG] = 70
            nanduLevelConfig[FUBEN_NANDU.SHISHI]    = 70
            nanduLevelConfig[FUBEN_NANDU.CHUANQI]   = 71

            local status                            = FUBEN_STATUS.KAIHUANG

            local gangtiewaike                      = {
                description = "钢铁外壳：受到的伤害降低70%",
                attr_type = CONST_EVENT.attr,
                attr = _attr({ jianshang = "+70" })
            }

            local juxingshengwu                     = {
                description = "法师塔之主：生命最大值提高30%",
                attr_type = CONST_EVENT.attr,
                attr = _attr({ shengming_baifenbi = "+30" })
            }
            local ai                                = function(level, nandu)
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

            hfuben.buildFuben(
                {
                    name = "法师塔", --副本名字
                    status = status,
                    blp = "ReplaceableTextures\\xiaoditu\\UI_map_18.blp",
                    enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_15.blp",
                    nanduLevelConfig = nanduLevelConfig,                                        -- 副本难度以及级别需求,
                    entryPosition = { x = -15660, y = -9195 },
                    startPosition = { x = -18831, y = -30636 },                                 --英雄进副本后位置
                    rectParam = { minX = -19469, minY = -30964, maxX = -11266, maxY = -26210 }, -- 副本区域
                    minions = {
                        {
                            name = "法师塔精英卫士", -- 名字 需要在物编定义好
                            x = -18572, -- 小怪刷新x坐标
                            y = -28651, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英法师", -- 名字 需要在物编定义好
                            x = -18572, -- 小怪刷新x坐标
                            y = -28351, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英术士", -- 名字 需要在物编定义好
                            x = -18572, -- 小怪刷新x坐标
                            y = -28351, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英卫士", -- 名字 需要在物编定义好
                            x = -16790, -- 小怪刷新x坐标
                            y = -27241, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英法师", -- 名字 需要在物编定义好
                            x = -16537, -- 小怪刷新x坐标
                            y = -27288, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英术士", -- 名字 需要在物编定义好
                            x = -16537, -- 小怪刷新x坐标
                            y = -27288, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英卫士", -- 名字 需要在物编定义好
                            x = -16573, -- 小怪刷新x坐标
                            y = -28483, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英法师", -- 名字 需要在物编定义好
                            x = -17337, -- 小怪刷新x坐标
                            y = -28743, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英法师", -- 名字 需要在物编定义好
                            x = -15932, -- 小怪刷新x坐标
                            y = -28743, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英术士", -- 名字 需要在物编定义好
                            x = -17337, -- 小怪刷新x坐标
                            y = -30396, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英术士", -- 名字 需要在物编定义好
                            x = -15932, -- 小怪刷新x坐标
                            y = -30396, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英卫士", -- 名字 需要在物编定义好
                            x = -15039, -- 小怪刷新x坐标
                            y = -30280, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英法师", -- 名字 需要在物编定义好
                            x = -14673, -- 小怪刷新x坐标
                            y = -30280, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英术士", -- 名字 需要在物编定义好
                            x = -14673, -- 小怪刷新x坐标
                            y = -30280, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英卫士", -- 名字 需要在物编定义好
                            x = -12095, -- 小怪刷新x坐标
                            y = -28486, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英法师", -- 名字 需要在物编定义好
                            x = -12095, -- 小怪刷新x坐标
                            y = -27583, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        },
                        {
                            name = "法师塔精英术士", -- 名字 需要在物编定义好
                            x = -12095, -- 小怪刷新x坐标
                            y = -26823, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = ai
                        }
                    },
                    bosses = {
                        {
                            name = "莫罗",
                            x = -18529,
                            y = -27270,
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
                                            "莫罗的怀表",
                                            "翡翠撕裂者",
                                            "王权头饰",
                                            "贵族箭袋",
                                            "钢针面甲",
                                            "圣洁祝福手套"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1800,
                                            1800,
                                            1800,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "远征军战靴"
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
                                            "先锋远征军战靴"
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
                                            "守护者的宝石"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "卡拉赞的回响"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            100,
                                            300,
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
                                                name = "召唤护卫",
                                                castCD = 8,
                                                castCountLimit = 1,
                                                shifashijian = 0.2,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 95, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "我们有客人了",
                                                        10,
                                                        "eae30a",
                                                        1,
                                                        3,
                                                        50
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit

                                                    if nandu >= FUBEN_NANDU.SHISHI then
                                                        local tmpAttr =
                                                            hunit.getAttributeBasedOnOptions(
                                                                {
                                                                    level = level,
                                                                    attackSpace = hslk.n2v("凯特琳娜", "cool1"),
                                                                    guaiwuType = MONSTER_TYPE.FUBEN_JINGYING,
                                                                    nandu = nandu,
                                                                    count = count
                                                                }
                                                            )
                                                        local tmpUnit =
                                                            henemy.create(
                                                                {
                                                                    id = hslk.n2i("凯特琳娜"),
                                                                    x = hunit.x(evtData.triggerUnit) +
                                                                        math.random(-100, 100),
                                                                    y = hunit.y(evtData.triggerUnit) +
                                                                        math.random(-100, 100),
                                                                    facing = math.random(0, 360),
                                                                    attr = tmpAttr,
                                                                    AI = UnitAI(
                                                                        {
                                                                            {
                                                                                aiType = UNIT_AI_TYPE.CAST_SKILL,
                                                                                aiData = {
                                                                                    targetType = UNIT_AI_TARGET_TYPE
                                                                                        .HIGHEST_CHOUHENG_UNIT,
                                                                                    name = "治疗之环",
                                                                                    castCD = 15,
                                                                                    --castCountLimit = 1,
                                                                                    shifashijian = 3,
                                                                                    castDistance = 10000,
                                                                                    minNandu = FUBEN_NANDU.PUTONG,
                                                                                    healthBelowLimit = 100, -- only cast when health is < 65%
                                                                                    notInterruptable = false,
                                                                                    skip_skill_speed = false,
                                                                                    customCondition = function(whichUnit)
                                                                                        return true
                                                                                    end,
                                                                                    startEffect = function(evtData)
                                                                                        htextTag.create2Unit(
                                                                                            evtData.triggerUnit,
                                                                                            "让我来治疗你们",
                                                                                            10,
                                                                                            "eae30a",
                                                                                            1,
                                                                                            1,
                                                                                            50
                                                                                        )
                                                                                    end,
                                                                                    effect = function(evtData)
                                                                                        heffect.xyz(
                                                                                            "war3mapImported\\RingOfBright.mdx",
                                                                                            hunit.x(evtData.triggerUnit),
                                                                                            hunit.y(evtData.triggerUnit),
                                                                                            hunit.z(evtData.triggerUnit),
                                                                                            0, 1)

                                                                                        local group =
                                                                                            hgroup.createAllyGroupByUnit(
                                                                                                evtData.triggerUnit,
                                                                                                1000
                                                                                            )
                                                                                        for _, u in ipairs(group) do
                                                                                            hskill.heal(
                                                                                                {
                                                                                                    healee = u,
                                                                                                    healer = evtData
                                                                                                        .triggerUnit,
                                                                                                    heal = hunit
                                                                                                        .getMaxLife(
                                                                                                            u
                                                                                                        ) * 0.5
                                                                                                }
                                                                                            )
                                                                                        end
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
                                                        hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                                                        hunit.setExpReward(tmpUnit, 0)
                                                    end

                                                    if nandu >= FUBEN_NANDU.YINGXIONG then
                                                        local tmpAttr =
                                                            hunit.getAttributeBasedOnOptions(
                                                                {
                                                                    level = level,
                                                                    attackSpace = hslk.n2v("罗宾公爵", "cool1"),
                                                                    guaiwuType = MONSTER_TYPE.FUBEN_JINGYING,
                                                                    nandu = nandu,
                                                                    count = count
                                                                }
                                                            )
                                                        local tmpUnit =
                                                            henemy.create(
                                                                {
                                                                    id = hslk.n2i("罗宾公爵"),
                                                                    x = hunit.x(evtData.triggerUnit) +
                                                                        math.random(-100, 100),
                                                                    y = hunit.y(evtData.triggerUnit) +
                                                                        math.random(-100, 100),
                                                                    facing = math.random(0, 360),
                                                                    attr = tmpAttr,
                                                                    AI = UnitAI(
                                                                        {
                                                                            {
                                                                                aiType = UNIT_AI_TYPE.CAST_SKILL,
                                                                                aiData = {
                                                                                    targetType = UNIT_AI_TARGET_TYPE
                                                                                        .HIGHEST_CHOUHENG_UNIT,
                                                                                    name = "狂暴旋风斩",
                                                                                    healthBelowLimit = 50,
                                                                                    notInterruptable = true,
                                                                                    minNandu = FUBEN_NANDU.PUTONG,
                                                                                    shifashijian = 2,
                                                                                    castCD = 30, -- nil or <=1 means 1 second
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
                                                                                        hunit.animate(
                                                                                            evtData.triggerUnit,
                                                                                            10
                                                                                        )
                                                                                    end,
                                                                                    --interval = 1,
                                                                                    periodEffect = function(evtData)
                                                                                    end,
                                                                                    effect = function(evtData)
                                                                                        heffect.attach(
                                                                                            "war3mapImported\\JRFB_[AZ].MDX",
                                                                                            evtData.triggerUnit,
                                                                                            "origin",
                                                                                            5
                                                                                        )
                                                                                        htime.setInterval(
                                                                                            1,
                                                                                            function(timer)
                                                                                                if timer.passedSec() > 5 then
                                                                                                    timer.destroy()
                                                                                                    return
                                                                                                end
                                                                                                hskillMoban.radiusAOE(
                                                                                                    hunit.x(
                                                                                                        evtData.triggerUnit
                                                                                                    ),
                                                                                                    hunit.y(
                                                                                                        evtData.triggerUnit
                                                                                                    ),
                                                                                                    evtData.triggerUnit,
                                                                                                    300,
                                                                                                    function(unit)
                                                                                                        local basicAttack =
                                                                                                            hattribute.get(
                                                                                                                evtData.triggerUnit,
                                                                                                                "attack",
                                                                                                                100
                                                                                                            )
                                                                                                        hskill.damage(
                                                                                                            {
                                                                                                                sourceUnit =
                                                                                                                    evtData.triggerUnit,
                                                                                                                targetUnit =
                                                                                                                    unit,
                                                                                                                damage = 3 *
                                                                                                                    basicAttack,
                                                                                                                damageType =
                                                                                                                    DAMAGE_TYPE.WULI,
                                                                                                                effect =
                                                                                                                "war3mapImported\\AZ_gelie.mdx",
                                                                                                                damageSrc =
                                                                                                                    CONST_DAMAGE_SRC.skill,
                                                                                                                damageElementType =
                                                                                                                    CONST_DAMAGE_ELEMENT_TYPE.METAL,
                                                                                                                damageSpeedType =
                                                                                                                    CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
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
                                                                                    targetType = UNIT_AI_TARGET_TYPE
                                                                                        .HIGHEST_CHOUHENG_UNIT,
                                                                                    name = "致死打击",
                                                                                    castCD = 8,
                                                                                    --castCountLimit = 1,
                                                                                    shifashijian = 1,
                                                                                    castDistance = 300,
                                                                                    minNandu = FUBEN_NANDU.PUTONG,
                                                                                    --healthBelowLimit = 100, -- only cast when health is < 65%
                                                                                    notInterruptable = false,
                                                                                    skip_skill_speed = false,
                                                                                    customCondition = function(whichUnit)
                                                                                        return true
                                                                                    end,
                                                                                    startEffect = function(evtData)
                                                                                    end,
                                                                                    effect = function(evtData)
                                                                                        local sourceUnit =
                                                                                            evtData.triggerUnit
                                                                                        local targetUnit =
                                                                                            evtData.targetUnit
                                                                                        local angel =
                                                                                            math.angle(
                                                                                                hunit.x(sourceUnit),
                                                                                                hunit.y(sourceUnit),
                                                                                                hunit.x(targetUnit),
                                                                                                hunit.y(targetUnit)
                                                                                            )
                                                                                        heffect.xyz(
                                                                                            "war3mapImported\\AZ_XPDG.mdx",
                                                                                            hunit.x(sourceUnit),
                                                                                            hunit.y(sourceUnit),
                                                                                            hunit.z(sourceUnit),
                                                                                            0,
                                                                                            1,
                                                                                            nil,
                                                                                            nil,
                                                                                            nil,
                                                                                            nil,
                                                                                            nil,
                                                                                            angel
                                                                                        )
                                                                                        hskill.damage(
                                                                                            {
                                                                                                sourceUnit = sourceUnit,
                                                                                                targetUnit = targetUnit,
                                                                                                damage = 2 *
                                                                                                    hattribute.getWithLimit(
                                                                                                        sourceUnit,
                                                                                                        nil,
                                                                                                        "attack",
                                                                                                        0
                                                                                                    ),
                                                                                                damageSrc =
                                                                                                    CONST_DAMAGE_SRC.skill,
                                                                                                damageType = DAMAGE_TYPE
                                                                                                    .WULI,
                                                                                                triggerSkill = hslk.n2i(
                                                                                                    "AI技能模版"
                                                                                                ),
                                                                                                damageElementType = {
                                                                                                    CONST_DAMAGE_ELEMENT_TYPE.METAL
                                                                                                }
                                                                                            }
                                                                                        )
                                                                                        hbuff.update(
                                                                                            5,
                                                                                            targetUnit,
                                                                                            "罗宾公爵致死打击",
                                                                                            false,
                                                                                            function()
                                                                                                hattribute.set(
                                                                                                    evtData.triggerUnit,
                                                                                                    0,
                                                                                                    _attr(
                                                                                                        {
                                                                                                            healee_zengqiang =
                                                                                                            "-80"
                                                                                                        }
                                                                                                    )
                                                                                                )
                                                                                            end,
                                                                                            function()
                                                                                                hattribute.set(
                                                                                                    evtData.triggerUnit,
                                                                                                    0,
                                                                                                    _attr(
                                                                                                        {
                                                                                                            healee_zengqiang =
                                                                                                            "+80"
                                                                                                        }
                                                                                                    )
                                                                                                )
                                                                                            end,
                                                                                            hslk.n2v("致死打击", "Art"),
                                                                                            "致死打击|n治疗效果降低80%",
                                                                                            nil,
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
                                                    end
                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = level,
                                                                attackSpace = hslk.n2v("克利斯平公爵", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_JINGYING,
                                                                nandu = nandu,
                                                                count = count
                                                            }
                                                        )
                                                    local tmpUnit =
                                                        henemy.create(
                                                            {
                                                                id = hslk.n2i("克利斯平公爵"),
                                                                x = hunit.x(evtData.triggerUnit) + math.random(-100, 100),
                                                                y = hunit.y(evtData.triggerUnit) + math.random(-100, 100),
                                                                facing = math.random(0, 360),
                                                                attr = tmpAttr,
                                                                AI = UnitAI(
                                                                    {
                                                                        {
                                                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                                                            aiData = {
                                                                                targetType = UNIT_AI_TARGET_TYPE
                                                                                    .LOWEST_HEALTH_ALLY,
                                                                                onlyInFight = true,
                                                                                name = "守护",
                                                                                castCD = 10,
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
                                                                                    htextTag.create2Unit(
                                                                                        evtData.triggerUnit,
                                                                                        "别担心，我来保护你",
                                                                                        10,
                                                                                        "eae30a",
                                                                                        1,
                                                                                        1,
                                                                                        50
                                                                                    )
                                                                                end,
                                                                                effect = function(evtData)
                                                                                    local duntexiao = heffect.attach(
                                                                                        "war3mapImported\\AZ_Goods_DUN4.mdx",
                                                                                        evtData.targetUnit,
                                                                                        "origin",
                                                                                        5
                                                                                    )
                                                                                    hbuff.update(
                                                                                        5,
                                                                                        evtData.targetUnit,
                                                                                        "守护",
                                                                                        true,
                                                                                        function()
                                                                                            hattribute.set(
                                                                                                evtData.triggerUnit,
                                                                                                0,
                                                                                                _attr({ jianshang = "+70" })
                                                                                            )
                                                                                        end,
                                                                                        function()
                                                                                            heffect.destroy(duntexiao)
                                                                                            hattribute.set(
                                                                                                evtData.triggerUnit,
                                                                                                0,
                                                                                                _attr({ jianshang = "-70" })
                                                                                            )
                                                                                        end,
                                                                                        hslk.n2v("守护", "Art"),
                                                                                        "守护|n受到伤害降低70%",
                                                                                        nil,
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
                                                                                targetType = UNIT_AI_TARGET_TYPE
                                                                                    .HIGHEST_CHOUHENG_UNIT,
                                                                                name = "盾击",
                                                                                castCD = 10,
                                                                                --castCountLimit = 1,
                                                                                shifashijian = 3,
                                                                                castDistance = 300,
                                                                                minNandu = FUBEN_NANDU.PUTONG,
                                                                                --healthBelowLimit = 100, -- only cast when health is < 65%
                                                                                notInterruptable = false,
                                                                                skip_skill_speed = false,
                                                                                customCondition = function(whichUnit)
                                                                                    return true
                                                                                end,
                                                                                startEffect = function(evtData)
                                                                                end,
                                                                                effect = function(evtData)
                                                                                    hbuff.xuanyun(evtData.targetUnit, 2)
                                                                                    hskill.damage(
                                                                                        {
                                                                                            sourceUnit = evtData
                                                                                                .triggerUnit,
                                                                                            targetUnit = evtData
                                                                                                .targetUnit,
                                                                                            damage = hattr.get(
                                                                                                evtData.triggerUnit,
                                                                                                "attack",
                                                                                                10
                                                                                            ) * 2,
                                                                                            damageType = DAMAGE_TYPE
                                                                                                .WULI,
                                                                                            effect =
                                                                                            "war3mapImported\\AZ_gelie.mdx",
                                                                                            damageSrc = CONST_DAMAGE_SRC
                                                                                                .skill,
                                                                                            damageElementType = {
                                                                                                CONST_DAMAGE_ELEMENT_TYPE.METAL
                                                                                            },
                                                                                            damageSpeedType =
                                                                                                CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
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
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local attack =
                                                        hattribute.get(evtData.triggerUnit, "attack_white", 10)
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
                                                targetType = UNIT_AI_TARGET_TYPE.LOWEST_HEALTH_UNIT,
                                                name = "锁喉",
                                                healthBelowLimit = 90,
                                                --castCountLimit = 1,
                                                shifashijian = 1,
                                                notInterruptable = true,
                                                --cast when life is below 50%
                                                castCD = 15, -- nil or <=1 means 1 second
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    hunit.portal(
                                                        evtData.triggerUnit,
                                                        hunit.x(evtData.targetUnit),
                                                        hunit.y(evtData.targetUnit)
                                                    )
                                                    hunit.portal(
                                                        evtData.triggerUnit,
                                                        hunit.x(evtData.targetUnit),
                                                        hunit.y(evtData.targetUnit)
                                                    )
                                                    local damage = hattribute.get(sourceUnit, "attack", 10) * 0.5
                                                    hbuff.update(
                                                        15,
                                                        targetUnit,
                                                        "锁喉",
                                                        false,
                                                        nil,
                                                        nil,
                                                        hslk.n2v("割裂", "Art"),
                                                        "你被锁喉了，每秒受到" .. tostring(damage) .. "的的物理伤害，不叠加。",
                                                        1,
                                                        1,
                                                        function(curTimer, buffHandle)
                                                            buffHandle.remainingTime =
                                                                buffHandle.remainingTime - buffHandle.interval
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = sourceUnit,
                                                                    targetUnit = targetUnit,
                                                                    damage = damage,
                                                                    effect = "war3mapImported\\AZ_gelie.mdx",
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.WULI,
                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                    damageElementType = CONST_DAMAGE_ELEMENT_TYPE.WOOD,
                                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                                                                    shanghainame = "锁喉"
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
                            name = "图书馆馆长",
                            x = -16614,
                            y = -29495,
                            recoveryDistance = 3000,
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
                                            "缚光者胸甲",
                                            "石枝外套",
                                            "国王护卫大剑",
                                            "刀锋行者长靴",
                                            "战痕长靴",
                                            "救赎灵魂圣契"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1800,
                                            1800,
                                            1800,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "远征军护手"
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
                                            "先锋远征军护手"
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
                                            "守护者的宝石"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "卡拉赞的回响"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            100,
                                            300,
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
                                                name = "唤醒",
                                                castCD = 1,
                                                --castCountLimit = 1,
                                                shifashijian = 15,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 95, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    if hunit.getCurManaPercent(whichUnit) < 0.1 then
                                                        return true
                                                    else
                                                        return false
                                                    end
                                                end,
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "能量恢复中",
                                                        10,
                                                        "eae30a",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                    local t = htime.setInterval(
                                                        1,
                                                        function(curTimer)
                                                            heffect.attach("[jineng]huanxing.mdx", evtData.triggerUnit,
                                                                "origin",
                                                                0)
                                                        end
                                                    )
                                                    hbuff.update(
                                                        15,
                                                        evtData.triggerUnit,
                                                        "唤醒",
                                                        true,
                                                        function()
                                                            hevent.register(
                                                                evtData.triggerUnit,
                                                                CONST_EVENT.damagingCustomTarget,
                                                                "唤醒易伤",
                                                                function(evtData)
                                                                    evtData.damage = evtData.damage * 4
                                                                end
                                                            )
                                                        end,
                                                        function()
                                                            hevent.unregister(
                                                                evtData.triggerUnit,
                                                                CONST_EVENT.damagingCustomTarget,
                                                                "唤醒易伤"
                                                            )
                                                            t.destroy()
                                                        end,
                                                        hslk.n2v("复仇之怒", "Art"),
                                                        "唤醒|n结束后恢复所有魔法，持续时间内受到的伤害增加300%",
                                                        1,
                                                        nil,
                                                        nil,
                                                        nil,
                                                        nil,
                                                        HBUFF_UPDATE_MODE.OVERWRITE
                                                    )
                                                end,
                                                endEffect = function(evtData)
                                                    hbuff.delete(evtData.triggerUnit, "唤醒")
                                                end,
                                                effect = function(evtData)
                                                    heffect.attach("[jineng]huanxing.mdx", evtData.triggerUnit, "origin",
                                                        0)
                                                    hunit.setCurMana(evtData.triggerUnit, 100)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                                name = "过载",
                                                castCD = 20,
                                                --castCountLimit = 1,
                                                shifashijian = 2,
                                                onlyInFight = true,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                healthBelowLimit = 90, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    hbuff.update(
                                                        10,
                                                        evtData.targetUnit,
                                                        "过载",
                                                        false,
                                                        nil,
                                                        nil,
                                                        "ReplaceableTextures\\BTN_fs_R3.blp",
                                                        "过载|n持续时间内每秒爆炸，对目标及其周围的所有单位造成伤害，该伤害对星界闪电球有效，且会额外造成其10%生命值上限的伤害。",
                                                        1,
                                                        1,
                                                        function(curTimer, buffHandle)
                                                            buffHandle.remainingTime =
                                                                buffHandle.remainingTime - buffHandle.interval
                                                            -- TODO 加过载特效
                                                            heffect.xyz(
                                                                "war3mapImported\\AZ_leitingyiji.MDX",
                                                                hunit.x(evtData.targetUnit),
                                                                hunit.y(evtData.targetUnit),
                                                                hunit.z(evtData.targetUnit),
                                                                0,
                                                                1
                                                            )
                                                            local damage =
                                                                hattribute.getWithLimit(
                                                                    evtData.triggerUnit,
                                                                    nil,
                                                                    "attack",
                                                                    0
                                                                ) * 0.3
                                                            local group =
                                                                hgroup.createByXY(
                                                                    hunit.x(evtData.targetUnit),
                                                                    hunit.y(evtData.targetUnit),
                                                                    300,
                                                                    function(filterUnit)
                                                                        if
                                                                            (hunit.isAlly(evtData.triggerUnit, filterUnit) and
                                                                                hunit.getName(filterUnit) ~= "星界闪电球") or
                                                                            hunit.isDead(filterUnit) or
                                                                            hunit.isDead(evtData.triggerUnit) or
                                                                            hunit.isDestroyed(filterUnit) or
                                                                            hunit.isDestroyed(evtData.triggerUnit)
                                                                        then
                                                                            return false
                                                                        else
                                                                            return true
                                                                        end
                                                                    end
                                                                )

                                                            heffect.xyz("war3mapImported\\[Spell]_042.mdx",
                                                                hunit.x(evtData.targetUnit),
                                                                hunit.y(evtData.targetUnit), hunit.z(evtData.targetUnit),
                                                                1, 1, 1, 1, 1)
                                                            for _, target in ipairs(group) do
                                                                if hunit.getName(target) == "星界闪电球" then
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = evtData.targetUnit,
                                                                            targetUnit = target,
                                                                            damage = damage +
                                                                                0.15 * hunit.getMaxLife(target),
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.MOFA,
                                                                            triggerSkill = hslk.n2i("AI技能模版"),
                                                                            damageElementType = {
                                                                                CONST_DAMAGE_ELEMENT_TYPE.EARTH
                                                                            },
                                                                            shanghainame = "过载",
                                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                .DOT
                                                                        }
                                                                    )
                                                                else
                                                                    local finalDamage = damage
                                                                    if target ~= evtData.targetUnit then
                                                                        finalDamage = finalDamage * 5
                                                                    end
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = evtData.triggerUnit,
                                                                            targetUnit = target,
                                                                            damage = finalDamage,
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.MOFA,
                                                                            triggerSkill = hslk.n2i("AI技能模版"),
                                                                            damageElementType = {
                                                                                CONST_DAMAGE_ELEMENT_TYPE.EARTH
                                                                            },
                                                                            shanghainame = "过载",
                                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                .DOT
                                                                        }
                                                                    )
                                                                end
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
                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                name = "雷池",
                                                onlyInFight = true,
                                                castCD = 15,
                                                --castCountLimit = 1,
                                                shifashijian = 1,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                healthBelowLimit = 80, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    hunit.subCurMana(evtData.triggerUnit, 10)
                                                    local whichUnit = evtData.triggerUnit
                                                    local duration = 30
                                                    local x = evtData.targetX
                                                    local y = evtData.targetY
                                                    local z = hjapi.Z(x, y)
                                                    -- TODO 加雷池特效
                                                    heffect.xyz(
                                                        "war3mapImported\\AZ_F079.mdx",
                                                        x,
                                                        y,
                                                        z,
                                                        duration,
                                                        1, 0.7, 0.7, 0.7
                                                    )
                                                    hskillMoban.radiusWarning(
                                                        x,
                                                        y,
                                                        z,
                                                        300,
                                                        duration
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
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "召唤闪电球",
                                                castCD = 8,
                                                --castCountLimit = 1,
                                                shifashijian = 1,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 95, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    hunit.subCurMana(evtData.triggerUnit, 20)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = level,
                                                                attackSpace = hslk.n2v("星界闪电球", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_JINGYING,
                                                                nandu = nandu,
                                                                count = count
                                                            }
                                                        )
                                                    local x = hunit.x(evtData.triggerUnit) + math.random(-100, 100)
                                                    local y = hunit.y(evtData.triggerUnit) + math.random(-100, 100)
                                                    local tmpUnit =
                                                        henemy.create(
                                                            {
                                                                id = hslk.n2i("星界闪电球"),
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
                                                                                    .NEAREST_ENERMY_UNIT,
                                                                                name = "闪电箭",
                                                                                castCD = 1,
                                                                                --castCountLimit = 1,
                                                                                shifashijian = 3,
                                                                                skipTextTag = true,
                                                                                castDistance = 500,
                                                                                minNandu = FUBEN_NANDU.PUTONG,
                                                                                --healthBelowLimit = 100, -- only cast when health is < 65%
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
                                                                                            model =
                                                                                            "war3mapImported\\Lightning Bolt.mdl",
                                                                                            scale = 1,
                                                                                            speed = 800,
                                                                                            hover = 50,
                                                                                            sourceUnit = sourceUnit,
                                                                                            targetUnit = targetUnit,
                                                                                            target_face_dis = 50,
                                                                                            onEnd = function(_, _, endX,
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
                                                                                                                0) *
                                                                                                            0.7,
                                                                                                        damageSrc =
                                                                                                            CONST_DAMAGE_SRC.skill,
                                                                                                        damageType =
                                                                                                            DAMAGE_TYPE.MOFA,
                                                                                                        triggerSkill =
                                                                                                            hslk.n2i(
                                                                                                                "AI技能模版"),
                                                                                                        damageElementType = {
                                                                                                            CONST_DAMAGE_ELEMENT_TYPE.LIGHT
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
                                                    heffect.xyz(
                                                        "war3mapImported\\[spell]tpdoor2.mdx", x, y, hjapi.Z(x, y), 2, 1
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                                name = "奥术弹幕",
                                                castCD = 22 - nandu * 3,
                                                --castCountLimit = 1,
                                                shifashijian = 1.5,
                                                castDistance = 10000,
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
                                                    hunit.subCurMana(evtData.triggerUnit, 10)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    hskillMoban.missile(
                                                        {
                                                            model = "war3mapImported\\[fashi]aofa1.mdl",
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
                                                                        damage = hattr.get(sourceUnit, "attack", 0) * 2,
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
                            passiveSkill = { { gangtiewaike }, { gangtiewaike }, { gangtiewaike }, { gangtiewaike } }
                        },
                        {
                            name = "夜之魇",
                            x = -12357,
                            y = -29874,
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
                                            "永生长夜法杖",
                                            "红宝石靴子",
                                            "凤凰日怒长弓",
                                            "绝望",
                                            "蹂躏者手甲",
                                            "千印之戒"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1800,
                                            1800,
                                            1800,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "远征军战盔"
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
                                            "先锋远征军战盔"
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
                                            "守护者的宝石"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "卡拉赞的回响"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            100,
                                            300,
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
                                                name = "骨雨",
                                                castCD = 30,
                                                castCountLimit = 3,
                                                shifashijian = 5.01,
                                                castDistance = 400,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 95, -- only cast when health is < 65%
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
                                                interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local missleFunc = function(target)
                                                        hskillMoban.missile(
                                                            {
                                                                --model = "war3mapImported\\[SPELL]_115.mdl",
                                                                model =
                                                                "war3mapImported\\AZ_KingLeoric(SDWZ)_T1_Misslie_bon.mdx",
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
                                                                            ) * 0.4,
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

                                                                    local tmpAttr =
                                                                        hunit.getAttributeBasedOnOptions(
                                                                            {
                                                                                level = hunit.getLevel(sourceUnit) -
                                                                                    2,
                                                                                attackSpace = hslk.n2v("夜魇骷髅",
                                                                                    "cool1"),
                                                                                guaiwuType = MONSTER_TYPE
                                                                                    .FUBEN_XIAOGUAI,
                                                                                nandu = nandu
                                                                            }
                                                                        )
                                                                    local tmpUnit =
                                                                        henemy.create(
                                                                            {
                                                                                id = hslk.n2i("夜魇骷髅"),
                                                                                x = hunit.x(target) +
                                                                                    math.random(-100, 100),
                                                                                y = hunit.y(target) +
                                                                                    math.random(-100, 100),
                                                                                facing = math.random(0, 360),
                                                                                attr = tmpAttr,
                                                                                AI = UnitAI(
                                                                                    {
                                                                                        {
                                                                                            aiType = UNIT_AI_TYPE
                                                                                                .ATTACK_HIGEST_CHOUHENG,
                                                                                            aiData = {
                                                                                                targetType =
                                                                                                    UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                ),
                                                                                nandu = nandu,
                                                                                tuozhanshijian = 36000
                                                                            }
                                                                        )
                                                                    hunit.setExpReward(tmpUnit, 0)
                                                                    hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                                                                end
                                                            }
                                                        )
                                                    end

                                                    if nandu >= FUBEN_NANDU.SHISHI then
                                                        hskillMoban.rectAOE(
                                                            hunit.getRect(sourceUnit),
                                                            sourceUnit,
                                                            missleFunc
                                                        )
                                                    else
                                                        hskillMoban.radiusAOE(
                                                            hunit.x(sourceUnit),
                                                            hunit.y(sourceUnit),
                                                            sourceUnit,
                                                            1000,
                                                            missleFunc
                                                        )
                                                    end
                                                end,
                                                effect = function(evtData)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.RANDOM_ENERMY_UNIT,
                                                name = "邪焰炸弹",
                                                castCD = 16,
                                                --castCountLimit = 1,
                                                shifashijian = 1,
                                                castDistance = 10000,
                                                onlyInFight = true,
                                                minNandu = FUBEN_NANDU.SHISHI,
                                                healthBelowLimit = 95, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                --skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startWarning = true,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0)
                                                    hbuff.update(
                                                        5,
                                                        evtData.targetUnit,
                                                        "邪焰炸弹",
                                                        false,
                                                        function()
                                                        end,
                                                        function()
                                                            local duration = 20 + nandu * 20
                                                            local x = hunit.x(evtData.targetUnit)
                                                            local y = hunit.y(evtData.targetUnit)
                                                            local z = hjapi.Z(x, y)
                                                            -- TODO 加邪焰特效
                                                            heffect.xyz(
                                                                "war3mapImported\\AZ_SoulFire_orange.mdx",
                                                                x,
                                                                y,
                                                                z,
                                                                duration,
                                                                1,
                                                                0.75,
                                                                0.75,
                                                                0.75

                                                            )
                                                            hskillMoban.radiusWarning(
                                                                x,
                                                                y,
                                                                z,
                                                                300,
                                                                duration
                                                            )
                                                            htime.setInterval(
                                                                1,
                                                                function(curTimer)
                                                                    if curTimer.passedSec() > duration then
                                                                        curTimer.destroy()
                                                                        return
                                                                    end
                                                                    hskillMoban.radiusAOE(
                                                                        x,
                                                                        y,
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
                                                                                        CONST_DAMAGE_ELEMENT_TYPE.EARTH
                                                                                    },
                                                                                    damageSpeedType =
                                                                                        CONST_DAMAGE_SPEED_TYPE.DOT
                                                                                }
                                                                            )
                                                                        end
                                                                    )
                                                                end
                                                            )
                                                        end,
                                                        "ReplaceableTextures\\HUOTIZHADAN\\PASBTNHUOTIZHADAN.blp",
                                                        "3秒后爆炸，并在地上留下邪焰",
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
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "顺劈",
                                                castCD = 15,
                                                --castCountLimit = 1,
                                                shifashijian = 1,
                                                castDistance = 400,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 95, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                --skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startWarning = true,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    hunit.animate(sourceUnit, 9)
                                                    local damage =
                                                        hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * 3
                                                    local facing = hunit.getFacing(sourceUnit)
                                                    hskillMoban.radiusAngleAOE(
                                                        sourceUnit,
                                                        600,
                                                        facing,
                                                        120,
                                                        function(unit)
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = sourceUnit,
                                                                    targetUnit = unit,
                                                                    damage = damage,
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.WULI,
                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                    damageElementType = {
                                                                        CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                    },
                                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                                }
                                                            )
                                                        end
                                                    )
                                                    heffect.xyz(
                                                        "war3mapImported\\[zhanshi]Cleave_Cast_Base_Purple.mdx",
                                                        hunit.x(sourceUnit),
                                                        hunit.y(sourceUnit),
                                                        hunit.z(sourceUnit),
                                                        0,
                                                        1,
                                                        3,
                                                        3,
                                                        3,
                                                        nil,
                                                        nil,
                                                        facing
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "扫尾",
                                                castCD = 15,
                                                --castCountLimit = 1,
                                                shifashijian = 1.5,
                                                castDistance = 500,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 85, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                --skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                --interval = 0.9,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                startEffect = function(evtData)
                                                    hunit.setAnimateSpeed(
                                                        evtData.triggerUnit,
                                                        1.5 / evtData.shifashijian,
                                                        evtData.shifashijian
                                                    )
                                                    hunit.animate(evtData.triggerUnit, 10)
                                                    local x = hunit.x(evtData.triggerUnit)
                                                    local y = hunit.y(evtData.triggerUnit)
                                                    local facing = hunit.getFacing(evtData.triggerUnit)
                                                    x, y = math.polarProjection(x, y, 600, facing - 180)
                                                    hskillMoban.radiusWarning(
                                                        x,
                                                        y,
                                                        hunit.z(evtData.triggerUnit),
                                                        600,
                                                        evtData.shifashijian
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local damage =
                                                        hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * 8
                                                    local x = hunit.x(evtData.triggerUnit)
                                                    local y = hunit.y(evtData.triggerUnit)
                                                    local facing = hunit.getFacing(evtData.triggerUnit)
                                                    x, y = math.polarProjection(x, y, 600, facing - 180)
                                                    hskillMoban.radiusAOE(
                                                        x,
                                                        y,
                                                        sourceUnit,
                                                        600,
                                                        function(target)
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
                                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                                }
                                                            )
                                                            hskillMoban.crackFly(
                                                                {
                                                                    sourceUnit = sourceUnit,
                                                                    targetUnit = target,
                                                                    model = nil,
                                                                    animate = "dead",
                                                                    animateScale = 1,
                                                                    distance = 600,
                                                                    height = 500,
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
                            name = "大法师埃兰",
                            x = -14486,
                            y = -27648,
                            levelAdj = 0,
                            recoveryDistance = 1500,
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
                                            "埃兰的镇定宝石",
                                            "紫罗兰之眼",
                                            "达拉然暗影斗篷",
                                            "循环之戒",
                                            "乌瑞恩国王战甲",
                                            "豹爪护符"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1800,
                                            1800,
                                            1800,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "远征军战甲"
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
                                            "先锋远征军战甲"
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
                                            "守护者的宝石"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "卡拉赞的回响"
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
                                            "煞能精华"
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
                                            "埃兰的魔力精华"
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
                                            "永恒魔力精华"
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
                            ai = function(level, nandu, count, fubenstatus, mijing)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.RANDOM_ENERMY_UNIT,
                                                name = "烈焰花环",
                                                castCD = 1,
                                                --castCountLimit = 1,
                                                shifashijian = 3,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                --healthBelowLimit = 30, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    local huoyan = hbuff.getStack(whichUnit, "火焰魔力")
                                                    if huoyan >= 4 then
                                                        return true
                                                    else
                                                        return false
                                                    end
                                                end,
                                                startEffect = function(evtData)
                                                    hbuff.delete(evtData.triggerUnit, "火焰魔力")
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "让你们跑！！!",
                                                        10,
                                                        "eae30a",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local x, y = hunit.x(targetUnit), hunit.y(targetUnit)
                                                    local units = hgroup.createAllyGroupByUnit(targetUnit, 300)
                                                    local duration = nandu * 2 - 1
                                                    -- TODO AZ 烈焰花环爆炸特效
                                                    heffect.xyz(
                                                        "war3mapImported\\AZ_rongyandimian.mdX",
                                                        x,
                                                        y,
                                                        hjapi.Z(x, y),
                                                        duration,
                                                        1,
                                                        1,
                                                        1,
                                                        1
                                                    )
                                                    local baozha = function()
                                                        -- TODO AZ 烈焰花环爆炸特效
                                                        heffect.xyz(
                                                            "war3mapImported\\az_chongjibo2.mdx",
                                                            x,
                                                            y,
                                                            hjapi.Z(x, y),
                                                            0,
                                                            1,
                                                            1,
                                                            1,
                                                            1
                                                        )
                                                        hskillMoban.rectAOE(
                                                            hunit.getRect(sourceUnit),
                                                            sourceUnit,
                                                            function(damageUnit)
                                                                local damage = hunit.getMaxLife(damageUnit) * 0.8
                                                                if nandu > FUBEN_NANDU.YINGXIONG then
                                                                    damage = damage * 10
                                                                end
                                                                hskill.damage(
                                                                    {
                                                                        sourceUnit = sourceUnit,
                                                                        targetUnit = damageUnit,
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
                                                    htime.setInterval(
                                                        0.1,
                                                        function(curTimer)
                                                            if curTimer.passedSec() > duration then
                                                                curTimer.destroy()
                                                                return
                                                            end
                                                            if
                                                                hunit.isAlive(targetUnit) and
                                                                math.distance(
                                                                    hunit.x(targetUnit),
                                                                    hunit.y(targetUnit),
                                                                    x,
                                                                    y
                                                                ) > 300
                                                            then
                                                                curTimer.destroy()
                                                                baozha()
                                                                return
                                                            end
                                                            local newUnits =
                                                                hgroup.createAllyGroupByUnit(targetUnit, 300)
                                                            for _, unit in ipairs(newUnits) do
                                                                if not hgroup.includes(units, unit) then
                                                                    curTimer.destroy()
                                                                    baozha()
                                                                    return
                                                                end
                                                            end
                                                        end
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "魔爆术",
                                                castCD = 1,
                                                --castCountLimit = 1,
                                                shifashijian = 3.5,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 40, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    local huoyan = hbuff.getStack(whichUnit, "奥术魔力")
                                                    if huoyan >= 4 then
                                                        return true
                                                    else
                                                        return false
                                                    end
                                                end,
                                                startEffect = function(evtData)
                                                    hbuff.delete(evtData.triggerUnit, "奥术魔力")
                                                    local sourceUnit = evtData.triggerUnit
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(sourceUnit),
                                                        sourceUnit,
                                                        function(target)
                                                            hunit.portal(
                                                                target,
                                                                hunit.x(sourceUnit),
                                                                hunit.y(sourceUnit)
                                                            )
                                                            hunit.portal(
                                                                target,
                                                                hunit.x(sourceUnit),
                                                                hunit.y(sourceUnit)
                                                            )
                                                        end
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    heffect.xyz("war3mapImported\\[Spell]_042.mdx", hunit.x(sourceUnit),
                                                        hunit.y(sourceUnit), hunit.z(sourceUnit), 1, 1, 5, 5, 5)
                                                    hskillMoban.radiusAOE(
                                                        hunit.x(sourceUnit),
                                                        hunit.y(sourceUnit),
                                                        sourceUnit,
                                                        2000,
                                                        function(target)
                                                            local damage = hattr.get(sourceUnit, "attack", 10) * 7
                                                            local distance =
                                                                math.distance(
                                                                    hunit.x(sourceUnit),
                                                                    hunit.y(sourceUnit),
                                                                    hunit.x(target),
                                                                    hunit.y(target)
                                                                )
                                                            local finalDamage =
                                                                damage * math.max((1 - distance / 1000), 0.2)
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = sourceUnit,
                                                                    targetUnit = target,
                                                                    damage = finalDamage,
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                    damageElementType = {
                                                                        CONST_DAMAGE_ELEMENT_TYPE.EARTH
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
                                                name = "暴风雪",
                                                castCD = 1,
                                                --castCountLimit = 1,
                                                shifashijian = 2,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 50, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    local huoyan = hbuff.getStack(whichUnit, "冰霜魔力")
                                                    if huoyan >= 4 then
                                                        return true
                                                    else
                                                        return false
                                                    end
                                                end,
                                                startEffect = function(evtData)
                                                    hbuff.delete(evtData.triggerUnit, "冰霜魔力")
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local duration = 12
                                                    local centerX = -14462
                                                    local centerY = -27682
                                                    local angle = math.random(0, 360)
                                                    htime.setInterval(
                                                        1,
                                                        function(curTimer)
                                                            if curTimer.passedSec() > duration then
                                                                curTimer.destroy()
                                                                return
                                                            end
                                                            local chouhendiyi =
                                                                hfightzhuangtai.getChouhengdiyi(sourceUnit)
                                                            if chouhendiyi == nil then
                                                                return
                                                            end

                                                            angle = angle + 30
                                                            for m = 1, nandu, 1 do
                                                                local x, y =
                                                                    math.polarProjection(
                                                                        centerX,
                                                                        centerY,
                                                                        800,
                                                                        angle + (360 / nandu) * (m - 1)
                                                                    )
                                                                local z = hjapi.Z(x, y)
                                                                for i = 1, 8, 1 do
                                                                    -- TODO AZ 暴风雪特效
                                                                    heffect.xyz(
                                                                        "war3mapImported\\[fashi]bingfa3.mdx",
                                                                        x + math.random(-200, 200),
                                                                        y + math.random(-200, 200),
                                                                        z,
                                                                        0,
                                                                        1,
                                                                        1,
                                                                        1,
                                                                        1
                                                                    )
                                                                end
                                                                hsound.voice2Unit(
                                                                    hsound.voiceCreate(
                                                                        "resource\\war3mapImported\\sound\\huoyu.wav",
                                                                        1000,
                                                                        true
                                                                    ),
                                                                    100,
                                                                    sourceUnit
                                                                )
                                                                hskillMoban.radiusWarning(
                                                                    x,
                                                                    y,
                                                                    hunit.z(evtData.triggerUnit),
                                                                    300,
                                                                    0.7
                                                                )
                                                                htime.setTimeout(
                                                                    0.7,
                                                                    function(_)
                                                                        hskillMoban.radiusAOE(
                                                                            x,
                                                                            y,
                                                                            sourceUnit,
                                                                            300,
                                                                            function(unit)
                                                                                hskill.damage(
                                                                                    {
                                                                                        sourceUnit = sourceUnit,
                                                                                        targetUnit = unit,
                                                                                        damage = hattribute.getWithLimit(
                                                                                            sourceUnit,
                                                                                            nil,
                                                                                            "attack",
                                                                                            0
                                                                                        ) * 1,
                                                                                        damageSrc = CONST_DAMAGE_SRC
                                                                                            .skill,
                                                                                        damageType = DAMAGE_TYPE.MOFA,
                                                                                        triggerSkill = hslk.n2i("暴风雪"),
                                                                                        damageSpeedType =
                                                                                            CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                                                                        damageElementType = {
                                                                                            CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                                        },
                                                                                        shanghainame = "暴风雪"
                                                                                    }
                                                                                )
                                                                                hbuff.update(
                                                                                    3 + nandu,
                                                                                    unit,
                                                                                    "暴风雪",
                                                                                    false,
                                                                                    function()
                                                                                        hattribute.set(
                                                                                            unit,
                                                                                            0,
                                                                                            {
                                                                                                move = "-100",
                                                                                            }
                                                                                        )
                                                                                    end,
                                                                                    function()
                                                                                        hattribute.set(
                                                                                            unit,
                                                                                            0,
                                                                                            {
                                                                                                move = "+100",
                                                                                            }
                                                                                        )
                                                                                    end,
                                                                                    "ReplaceableTextures\\fashi\\BTN_FS_05.blp",
                                                                                    "暴风雪|n降低100的移动速度",
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
                                                                )
                                                            end
                                                        end
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "奥术飞弹",
                                                castCD = 6,
                                                --castCountLimit = 1,
                                                shifashijian = 2.01,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 80, -- only cast when health is < 65%
                                                notInterruptable = false,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                interval = 0.5,
                                                periodEffect = function(evtData, curTimer)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    hskillMoban.missile(
                                                        {
                                                            model = "war3mapImported\\[Spell]_039.mdx",
                                                            --model = "Abilities\\Weapons\\LichMissile\\LichMissile.mdl",
                                                            scale = 0.8,
                                                            speed = 1000,
                                                            hover = 50,
                                                            sourceUnit = sourceUnit,
                                                            targetUnit = targetUnit,
                                                            target_face_dis = 50,
                                                            onEnd = function(_, _, endX, endY)
                                                                hskill.damage(
                                                                    {
                                                                        sourceUnit = sourceUnit,
                                                                        targetUnit = targetUnit,
                                                                        damage = 0.5 *
                                                                            hattr.get(sourceUnit, "attack", 0),
                                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                                        damageType = DAMAGE_TYPE.MOFA,
                                                                        triggerSkill = hslk.n2i("AI技能模版"),
                                                                        damageElementType = CONST_DAMAGE_ELEMENT_TYPE
                                                                            .WATER,
                                                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                            .IMMEDIATE
                                                                    }
                                                                )
                                                            end
                                                        }
                                                    )
                                                end,
                                                startEffect = function(evtData)
                                                    hbuff.addStackAttrBuff(
                                                        CONST_DAMAGE_SRC.skill,
                                                        evtData.triggerUnit,
                                                        "奥术魔力",
                                                        {},
                                                        30,
                                                        4,
                                                        "ReplaceableTextures\\fashi\\BTN_AS_Q1.blp",
                                                        "奥术魔力|n" .. (4) .. "层后埃兰将会释放魔爆术",
                                                        true
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    hbuff.addStackAttrBuff(
                                                        CONST_DAMAGE_SRC.skill,
                                                        evtData.triggerUnit,
                                                        "奥术魔力",
                                                        {},
                                                        30,
                                                        4,
                                                        "ReplaceableTextures\\fashi\\BTN_AS_Q1.blp",
                                                        "奥术魔力|n" .. (4) .. "层后埃兰将会释放魔爆术",
                                                        true
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "火球术",
                                                castCD = 6,
                                                --castCountLimit = 1,
                                                shifashijian = 2,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 80, -- only cast when health is < 65%
                                                notInterruptable = false,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    hbuff.addStackAttrBuff(
                                                        CONST_DAMAGE_SRC.skill,
                                                        evtData.triggerUnit,
                                                        "火焰魔力",
                                                        {},
                                                        30,
                                                        4,
                                                        "ReplaceableTextures\\BTN_FS_03.blp",
                                                        "火焰魔力|n" .. (4) .. "层后埃兰将会释放烈焰火环",
                                                        true
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    hbuff.addStackAttrBuff(
                                                        CONST_DAMAGE_SRC.skill,
                                                        evtData.triggerUnit,
                                                        "火焰魔力",
                                                        {},
                                                        30,
                                                        4,
                                                        "ReplaceableTextures\\BTN_FS_03.blp",
                                                        "火焰魔力|n" .. (4) .. "层后埃兰将会释放烈焰火环",
                                                        true
                                                    )
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
                                                                        damage = hattr.get(sourceUnit, "attack", 0) * 2,
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
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "寒冰箭",
                                                castCD = 1,
                                                --castCountLimit = 1,
                                                shifashijian = 2,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 90, -- only cast when health is < 65%
                                                notInterruptable = false,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    hbuff.addStackAttrBuff(
                                                        CONST_DAMAGE_SRC.skill,
                                                        evtData.triggerUnit,
                                                        "冰霜魔力",
                                                        {},
                                                        30,
                                                        4,
                                                        "ReplaceableTextures\\BTN_FS_bingjiashu.blp",
                                                        "冰霜魔力|n" .. (4) .. "层后埃兰将会释放暴风雪",
                                                        true
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    hbuff.addStackAttrBuff(
                                                        CONST_DAMAGE_SRC.skill,
                                                        evtData.triggerUnit,
                                                        "冰霜魔力",
                                                        {},
                                                        30,
                                                        4,
                                                        "ReplaceableTextures\\BTN_FS_bingjiashu.blp",
                                                        "冰霜魔力|n" .. (4) .. "层后埃兰将会释放暴风雪",
                                                        true
                                                    )
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    hskillMoban.missile(
                                                        {
                                                            model = "war3mapImported\\[fashi][Spell]_145.mdl",
                                                            --model = "Abilities\\Weapons\\LichMissile\\LichMissile.mdl",
                                                            scale = 1.0,
                                                            speed = 1000,
                                                            hover = 50,
                                                            sourceUnit = sourceUnit,
                                                            targetUnit = targetUnit,
                                                            target_face_dis = 50,
                                                            onEnd = function(_, _, endX, endY)
                                                                hskill.damage(
                                                                    {
                                                                        sourceUnit = sourceUnit,
                                                                        targetUnit = targetUnit,
                                                                        damage = 1 * hattr.get(sourceUnit, "attack", 0),
                                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                                        damageType = DAMAGE_TYPE.MOFA,
                                                                        triggerSkill = hslk.n2i("AI技能模版"),
                                                                        damageElementType = CONST_DAMAGE_ELEMENT_TYPE
                                                                            .WATER,
                                                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                            .IMMEDIATE
                                                                    }
                                                                )
                                                                hbuff.update(
                                                                    5,
                                                                    targetUnit,
                                                                    "严寒",
                                                                    false,
                                                                    function()
                                                                        hattribute.set(
                                                                            targetUnit,
                                                                            0,
                                                                            {
                                                                                attack_speed = "-10",
                                                                                move = "-50",
                                                                                skill_speed = "-10"
                                                                            }
                                                                        )
                                                                    end,
                                                                    function()
                                                                        hattribute.set(
                                                                            targetUnit,
                                                                            0,
                                                                            {
                                                                                attack_speed = "+10",
                                                                                move = "+50",
                                                                                skill_speed = "+10"
                                                                            }
                                                                        )
                                                                    end,
                                                                    "ReplaceableTextures\\fashi\\BTN_ASdQ2.blp",
                                                                    "严寒：降低10%的攻击，技能和50的移动速度",
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
                            passiveSkill = { {}, {}, { juxingshengwu }, { juxingshengwu } }
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
                                    maxLevel = 0,
                                    shengwangname = "和平之城"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,            value = 4000 },
                                { type = HSHOP_COST_TYPE.zhengyihuizhang, value = 2 },
                                { type = HSHOP_COST_TYPE.experience,      value = 18000 },
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
                                { type = HSHOP_COST_TYPE.gold,            value = 5000 },
                                { type = HSHOP_COST_TYPE.zhengyihuizhang, value = 3 },
                                { type = HSHOP_COST_TYPE.zhixuhuizhang,   value = 1 },
                                { type = HSHOP_COST_TYPE.experience,      value = 20000 },
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
                                { type = HSHOP_COST_TYPE.gold,       value = 6000 },
                                { type = HSHOP_COST_TYPE.experience, value = 25000 },
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
