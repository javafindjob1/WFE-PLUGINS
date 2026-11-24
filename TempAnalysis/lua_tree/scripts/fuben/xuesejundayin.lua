table.insert(
    FUBEN_LIST,
    {
        name = "血色军大营",
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
            local nanduLevelConfig = {}
            nanduLevelConfig[FUBEN_NANDU.PUTONG] = 32
            nanduLevelConfig[FUBEN_NANDU.YINGXIONG] = 32
            nanduLevelConfig[FUBEN_NANDU.SHISHI] = 32
            nanduLevelConfig[FUBEN_NANDU.CHUANQI] = 60

            local shenlihuti = {
                description = "光明神力护佑，受到任何伤害降低至0，复活别人后失效",
                attr_type = CONST_EVENT.damagingCustomTarget,
                attr = function(evtData)
                    if hcache.get(evtData.targetUnit, "迈恩的光明神力护体失效", false) ~= true then
                        evtData.damage = 0
                    end
                end
            }
            local chengjiAI = {
                aiType = UNIT_AI_TYPE.CAST_SKILL,
                aiData = {
                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                    name = "惩击",
                    --healthBelowLimit = 100,
                    --notInterruptable = true,
                    minNandu = FUBEN_NANDU.PUTONG,
                    shifashijian = 3,
                    castCD = 1, -- nil or <=1 means 1 second
                    startEffect = function(evtData)
                    end,
                    periodEffect = function(evtData)
                    end,
                    effect = function(evtData)
                        local basicAttack = hattribute.get(evtData.triggerUnit, "attack", 100)
                        hskill.damage(
                            {
                                sourceUnit = evtData.triggerUnit,
                                targetUnit = evtData.targetUnit,
                                damage = 1.5 * basicAttack,
                                damageType = DAMAGE_TYPE.SHENSHENG,
                                effect = "[jineng]chengji.mdx",
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageElementType = CONST_DAMAGE_ELEMENT_TYPE.LIGHT,
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                            }
                        )
                    end
                }
            }

            local fashiAI =
                UnitAI(
                    {
                        chengjiAI,
                        {
                            aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                            }
                        }
                    }
                )

            local binsi = {
                description = "生命值降低到20%会免疫伤害并等待救援",
                attr_type = CONST_EVENT.damagingCustomTarget,
                attr = function(evtData)
                    if hbuff.hasBuff(evtData.targetUnit, "莫格莱尼濒死") then
                        evtData.damage = 0
                        return
                    end
                    if
                        (hunit.getCurLife(evtData.targetUnit) - evtData.damage) >
                        (0.2 * hunit.getMaxLife(evtData.targetUnit)) or
                        hcache.get(evtData.targetUnit, "莫格莱尼濒死", false) == true
                    then
                        return
                    end
                    evtData.damage = 0
                    hcache.set(evtData.targetUnit, "莫格莱尼濒死", true)
                    hbuff.update(
                        36000,
                        evtData.targetUnit,
                        "莫格莱尼濒死",
                        false,
                        nil,
                        nil,
                        nil,
                        nil,
                        nil,
                        nil,
                        nil,
                        nil,
                        nil,
                        HBUFF_UPDATE_MODE.CREATE_ONLY
                    )
                    hunit.setInvulnerable(evtData.targetUnit, true)
                    hunit.pause(evtData.targetUnit)
                    hunit.animate(evtData.targetUnit, 3)
                end
            }

            local kuangre = {
                description = "狂热：被击杀会鼓舞旁边500码范围内的血色十字军成员，使其攻击和法术速度提高(随难度提高而提高)，可无限叠加。",
                attr_type = CONST_EVENT.dead,
                attr = function(evtData)
                    local nandu = hunit.getNandu(evtData.triggerUnit)
                    htextTag.create2Unit(evtData.triggerUnit, "为了血色军！！！", 10, "eae30a", 1, 2, 150)
                    heffect.attach(
                        "Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl",
                        evtData.triggerUnit,
                        "head",
                        0
                    )
                    for _, unit in ipairs(hgroup.createAllyGroupByUnit(evtData.triggerUnit, 500)) do
                        if unit ~= evtData.triggerUnit then
                            hbuff.addStackAttrBuff(
                                CONST_DAMAGE_SRC.skill,
                                unit,
                                "血色十字军狂热",
                                { attack_speed = "+" .. tostring(nandu * 8), skill_speed = "+" .. tostring(nandu * 8) },
                                30,
                                99,
                                "ReplaceableTextures\\KUANGRE\\PASKUANGRE.blp",
                                "狂热：友军被击杀鼓舞了该单位，使其攻击和法术速度提高" .. tostring(nandu * 8) .. "%，可无限叠加。",
                                true
                            )
                        end
                    end
                end
            }

            local xiaoguaiDiaoluo =
                DiaoLuoConfig( --掉落配置
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
                        },
                        {
                            list = { "血色军战靴" }, --物品名字 需要在物编定义好
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

            hfuben.buildFuben(
                {
                    name = "血色军大营", --副本名字
                    status = FUBEN_STATUS.JIANHUA,
                    blp = "ReplaceableTextures\\xiaoditu\\UI_map_10.blp",
                    enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_05.blp",
                    nanduLevelConfig = nanduLevelConfig,                                   -- 副本难度以及级别需求,
                    entryPosition = { x = -24762, y = -13479 },
                    startPosition = { x = -11530, y = 4725 },                              --英雄进副本后位置
                    rectParam = { minX = -12064, minY = 4419, maxX = -5194, maxY = 7485 }, -- 副本区域
                    minions = {
                        {
                            name = "血色军卫士", -- 名字 需要在物编定义好
                            x = -11555, -- 小怪刷新x坐标
                            y = 5581, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaiDiaoluo,
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } }
                        },
                        {
                            name = "血色军卫士", -- 名字 需要在物编定义好
                            x = -11498, -- 小怪刷新x坐标
                            y = 6752, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaiDiaoluo,
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } }
                        },
                        {
                            name = "血色军卫士", -- 名字 需要在物编定义好
                            x = -10687, -- 小怪刷新x坐标
                            y = 6752, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaiDiaoluo,
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } }
                        },
                        {
                            name = "血色军卫士", -- 名字 需要在物编定义好
                            x = -10700, -- 小怪刷新x坐标
                            y = 4937, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaiDiaoluo,
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } }
                        },
                        {
                            name = "血色军剑士", -- 名字 需要在物编定义好
                            x = -10440, -- 小怪刷新x坐标
                            y = 4937, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaiDiaoluo,
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } }
                        },
                        {
                            name = "血色军法师", -- 名字 需要在物编定义好
                            x = -10200, -- 小怪刷新x坐标
                            y = 4937, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaiDiaoluo,
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } },
                            ai = fashiAI
                        },
                        {
                            name = "血色军卫士", -- 名字 需要在物编定义好
                            x = -9400, -- 小怪刷新x坐标
                            y = 6965, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaiDiaoluo,
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } }
                        },
                        {
                            name = "血色军剑士", -- 名字 需要在物编定义好
                            x = -9150, -- 小怪刷新x坐标
                            y = 6965, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaiDiaoluo,
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } }
                        },
                        {
                            name = "血色军法师", -- 名字 需要在物编定义好
                            x = -8900, -- 小怪刷新x坐标
                            y = 6965, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaiDiaoluo,
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } },
                            ai = fashiAI
                        },
                        {
                            name = "血色军卫士", -- 名字 需要在物编定义好
                            x = -7800, -- 小怪刷新x坐标
                            y = 6965, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaiDiaoluo,
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } }
                        },
                        {
                            name = "血色军法师", -- 名字 需要在物编定义好
                            x = -7550, -- 小怪刷新x坐标
                            y = 6965, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaiDiaoluo,
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } },
                            ai = fashiAI
                        },
                        {
                            name = "血色军卫士", -- 名字 需要在物编定义好
                            x = -7798, -- 小怪刷新x坐标
                            y = 5335, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaiDiaoluo,
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } }
                        },
                        {
                            name = "血色军剑士", -- 名字 需要在物编定义好
                            x = -7800, -- 小怪刷新x坐标
                            y = 5185, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaiDiaoluo,
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } }
                        },
                        {
                            name = "血色军法师", -- 名字 需要在物编定义好
                            x = -7800, -- 小怪刷新x坐标
                            y = 4935, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaiDiaoluo,
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } },
                            ai = fashiAI
                        }
                    },
                    bosses = {
                        {
                            name = "训犬大师杜兰",
                            x = -11170,
                            y = 6816,
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
                                        list = { "血色军护手", "杜兰的哨子", "血色制式长弓" }, --物品名字 需要在物编定义好
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
                                                name = "野兽狂化",
                                                healthBelowLimit = 50,
                                                notInterruptable = true,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 3,
                                                castCD = 30, -- nil or <=1 means 1 second
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local liequan =
                                                        hgroup.createByUnit(
                                                            evtData.triggerUnit,
                                                            500,
                                                            function(filterUnit)
                                                                if hunit.getName(filterUnit) == "杜兰的猎犬" then
                                                                    return true
                                                                end
                                                            end
                                                        )
                                                    if #liequan ~= 0 then
                                                        hgroup.forEach(
                                                            liequan,
                                                            function(enumUnit, idx)
                                                                local basicAttack =
                                                                    hattribute.get(enumUnit, "attack", 100)
                                                                hbuff.update(
                                                                    10,
                                                                    enumUnit,
                                                                    "杜兰强化猎犬",
                                                                    true,
                                                                    function()
                                                                        hunit.setRGBA(enumUnit, 255, 150, 255, 1.0)
                                                                        cj.SetUnitScale(enumUnit, 1.2, 1.2, 1.2)
                                                                        hattribute.set(
                                                                            evtData.triggerUnit,
                                                                            0,
                                                                            {
                                                                                attack_speed = "+30",
                                                                                attack = "+" ..
                                                                                    tostring(0.3 * basicAttack),
                                                                                move = "+30"
                                                                            }
                                                                        )
                                                                    end,
                                                                    function()
                                                                        hunit.setRGBA(enumUnit, 255, 255, 255, 1.0)
                                                                        cj.SetUnitScale(enumUnit, 1, 1, 1)
                                                                        hattribute.set(
                                                                            evtData.triggerUnit,
                                                                            0,
                                                                            {
                                                                                attack_speed = "-30",
                                                                                attack = "-" ..
                                                                                    tostring(0.3 * basicAttack),
                                                                                move = "-30"
                                                                            }
                                                                        )
                                                                    end,
                                                                    "ReplaceableTextures\\CommandButtons\\BTNBloodLust.blp",
                                                                    "杜兰激发了猎犬的嗜血欲望，猎犬的攻击和移动速度都增加了",
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
                                                    elseif nandu >= FUBEN_NANDU.YINGXIONG then
                                                        htextTag.create2Unit(
                                                            evtData.triggerUnit,
                                                            "杜兰发现爱犬全部牺牲，陷入了暴怒!",
                                                            10,
                                                            "ff3300",
                                                            1,
                                                            1,
                                                            50
                                                        )
                                                        local basicAttack =
                                                            hattribute.get(evtData.triggerUnit, "attack", 100)
                                                        hbuff.update(
                                                            10,
                                                            evtData.triggerUnit,
                                                            "杜兰暴怒",
                                                            true,
                                                            function()
                                                                hattribute.set(
                                                                    evtData.triggerUnit,
                                                                    0,
                                                                    {
                                                                        attack_speed = "+100",
                                                                        attack = "+" .. tostring(basicAttack),
                                                                        move = "+100"
                                                                    }
                                                                )
                                                            end,
                                                            function()
                                                                hattribute.set(
                                                                    evtData.triggerUnit,
                                                                    0,
                                                                    {
                                                                        attack_speed = "-100",
                                                                        attack = "-" .. tostring(basicAttack),
                                                                        move = "-100"
                                                                    }
                                                                )
                                                            end,
                                                            "ReplaceableTextures\\CommandButtons\\BTNBloodLust.blp",
                                                            "杜兰发现爱犬全部牺牲，陷入了暴怒，攻击力和攻击速度暴增100%，移动速度增加100",
                                                            1,
                                                            nil,
                                                            nil,
                                                            nil,
                                                            nil,
                                                            HBUFF_UPDATE_MODE.OVERWRITE,
                                                            true
                                                        )
                                                    end
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "召唤猎犬",
                                                healthBelowLimit = 99,
                                                --cast when life is below 50%
                                                castCD = 12, -- nil or <=1 means 1 second
                                                shifashijian = 1.5,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "杜兰：我的小可爱们，又有新鲜的食物了!",
                                                        10,
                                                        "eae30a",
                                                        1,
                                                        1,
                                                        50
                                                    )
                                                    local sourceUnit = evtData.triggerUnit
                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = hunit.getLevel(sourceUnit) - 2,
                                                                attackSpace = hslk.n2v("杜兰的猎犬", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_JINGYING,
                                                                nandu = nandu
                                                            }
                                                        )
                                                    local tmpUnit =
                                                        henemy.create(
                                                            {
                                                                id = hslk.n2i("杜兰的猎犬"),
                                                                x = hunit.x(evtData.triggerUnit) + math.random(-100, 100),
                                                                y = hunit.y(evtData.triggerUnit) + math.random(-100, 100),
                                                                facing = 0,
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
                                                                    }
                                                                ),
                                                                nandu = nandu,
                                                                tuozhanshijian = 36000
                                                            }
                                                        )
                                                    hunit.setExpReward(tmpUnit, 0)
                                                    hattribute.set(
                                                        tmpUnit,
                                                        0,
                                                        { life = "=" .. tostring(0.2 * hunit.getMaxLife(tmpUnit)) }
                                                    )
                                                    hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
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
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } }
                        },
                        {
                            name = "血色勇士赫罗德",
                            x = -9237,
                            y = 5662,
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
                                        list = { "血色军战盔", "破坏者" }, --物品名字 需要在物编定义好
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
                                                name = "狂暴旋风斩",
                                                healthBelowLimit = 90,
                                                notInterruptable = true,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 5.01,
                                                castCD = 30 - 3 * nandu, -- nil or <=1 means 1 second
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
                                                    hunit.animate(evtData.triggerUnit, 10)
                                                end,
                                                interval = 1,
                                                periodEffect = function(evtData)
                                                    hskillMoban.radiusAOE(
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit),
                                                        evtData.triggerUnit,
                                                        300,
                                                        function(unit)
                                                            local basicAttack =
                                                                hattribute.get(evtData.triggerUnit, "attack", 100)
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = evtData.triggerUnit,
                                                                    targetUnit = unit,
                                                                    damage = 3 * basicAttack,
                                                                    damageType = DAMAGE_TYPE.WULI,
                                                                    effect = "war3mapImported\\AZ_gelie.mdx",
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageElementType = CONST_DAMAGE_ELEMENT_TYPE.METAL,
                                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
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
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                            }
                                        }
                                    }
                                )
                            end,
                            passiveSkill = { { kuangre }, { kuangre }, { kuangre }, { kuangre } }
                        },
                        {
                            name = "血色军统帅莫格莱尼",
                            x = -6584,
                            y = 5826,
                            face = 180,
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
                                        list = { "堕落的灰烬之力" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "血色军锁甲" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            500,
                                            1000,
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
                                                name = "狂热一击",
                                                healthBelowLimit = 99,
                                                notInterruptable = true,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 0.7,
                                                castDistance = 300,
                                                castCD = 15 - nandu * 2, -- nil or <=1 means 1 second
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 8)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local basicAttack =
                                                        hattribute.get(evtData.triggerUnit, "attack", 100)
                                                    heffect.attach(
                                                        "war3mapImported\\AZ_hit1.mdx",
                                                        evtData.targetUnit,
                                                        "chest",
                                                        0
                                                    )
                                                    hbuff.addStackAttrBuff(
                                                        CONST_DAMAGE_SRC.skill,
                                                        evtData.triggerUnit,
                                                        "狂热一击增强",
                                                        {},
                                                        30,
                                                        99,
                                                        "ReplaceableTextures\\KUANGRE\\PASKUANGRE.blp",
                                                        "狂热一击使得狂热一击伤害增加10%，可无限叠加。",
                                                        true
                                                    )
                                                    local handle = hbuff.getBuffHandle(evtData.triggerUnit, "狂热一击增强")
                                                    local stack = handle.stack
                                                    hskill.damage(
                                                        {
                                                            sourceUnit = evtData.triggerUnit,
                                                            targetUnit = evtData.targetUnit,
                                                            damage = 2 * basicAttack * (1 + stack * 0.1),
                                                            damageType = DAMAGE_TYPE.WULI,
                                                            effect = "war3mapImported\\AZ_gelie.mdx",
                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                            damageElementType = CONST_DAMAGE_ELEMENT_TYPE.METAL,
                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
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
                            passiveSkill = { {}, {}, { binsi }, { binsi } }
                        },
                        {
                            name = "大检察官迈恩",
                            x = -5506,
                            y = 5826,
                            levelAdj = 0,
                            face = 180,
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
                                        list = { "血色军披风", "祭祀之杖" }, --物品名字 需要在物编定义好
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
                                                name = "高阶复活术",
                                                --healthBelowLimit = 50,
                                                castCountLimit = 99,
                                                notInterruptable = true,
                                                minNandu = FUBEN_NANDU.SHISHI,
                                                shifashijian = 5.0,
                                                castCD = 180, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    local units =
                                                        hgroup.findNearByUnitByName(whichUnit, 2000, "血色军统帅莫格莱尼")
                                                    if #units ~= 1 then
                                                        return false
                                                    end
                                                    return hbuff.hasBuff(units[1], "莫格莱尼濒死")
                                                end,
                                                startEffect = function(evtData)
                                                    htextTag.create2Unit(
                                                        evtData.triggerUnit,
                                                        "迈恩：复活吧，我的爱人！",
                                                        10,
                                                        "eae30a",
                                                        1,
                                                        5,
                                                        150
                                                    )
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    hcache.set(evtData.triggerUnit, "迈恩的光明神力护体失效", true)
                                                    local units =
                                                        hgroup.findNearByUnitByName(
                                                            evtData.triggerUnit,
                                                            2000,
                                                            "血色军统帅莫格莱尼"
                                                        )
                                                    if #units ~= 1 then
                                                        return
                                                    end
                                                    htextTag.create2Unit(
                                                        units[1],
                                                        "莫格莱尼：为你而战，我的女士！",
                                                        10,
                                                        "eae30a",
                                                        1,
                                                        5,
                                                        150
                                                    )
                                                    hbuff.delete(units[1], "莫格莱尼濒死")
                                                    hunit.setCurLifePercent(units[1], 100)
                                                    hunit.setInvulnerable(units[1], false)
                                                    hunit.resume(units[1])
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "高阶治疗术",
                                                --healthBelowLimit = 100,
                                                --notInterruptable = false,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                shifashijian = 3.0,
                                                castCD = 40 - 3 * nandu, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return hfightzhuangtai.isInFight(whichUnit)
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
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local target =
                                                        hgroup.getLowestHealth(
                                                            hgroup.createByUnit(
                                                                evtData.triggerUnit,
                                                                1000,
                                                                function(filterUnit)
                                                                    if
                                                                        hunit.isAlly(filterUnit, evtData.triggerUnit) ==
                                                                        true and
                                                                        hunit.isAlive(evtData.triggerUnit) == true
                                                                    then
                                                                        return true
                                                                    end
                                                                end
                                                            ),
                                                            hunit.x(evtData.triggerUnit),
                                                            hunit.y(evtData.triggerUnit)
                                                        )
                                                    if target ~= nil then
                                                        hskill.heal(
                                                            {
                                                                healer = evtData.triggerUnit,
                                                                healee = target,
                                                                heal = hunit.getMaxLife(target) * 0.1 * nandu,
                                                                healType = HEAL_TYPE.SKILL,
                                                                triggerSkill = hslk.n2i("AI技能模版")
                                                            }
                                                        )
                                                    end
                                                end
                                            }
                                        },
                                        chengjiAI,
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
                                { kuangre },
                                { kuangre },
                                { shenlihuti, kuangre },
                                { shenlihuti, kuangre }
                            }
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
                                    maxLevel = 1,
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
                                    maxLevel = 2,
                                    shengwangname = "王城"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience,        value = 4000 },
                                { type = HSHOP_COST_TYPE.gold,              value = 700 },
                                { type = HSHOP_COST_TYPE.gongzhenghuizhang, value = 2 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 3,
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
