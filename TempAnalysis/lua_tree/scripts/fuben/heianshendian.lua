---@diagnostic disable: missing-parameter
table.insert(
    FUBEN_LIST,
    {
        name = "黑暗神殿",
        setup = function()
            local nanduLevelConfig                  = {}
            nanduLevelConfig[FUBEN_NANDU.PUTONG]    = 72
            nanduLevelConfig[FUBEN_NANDU.YINGXIONG] = 72
            nanduLevelConfig[FUBEN_NANDU.SHISHI]    = 72
            --nanduLevelConfig[FUBEN_NANDU.CHUANQI] = 72

            local status                            = FUBEN_STATUS.KAIHUANG

            local juxingshengwu                     = {
                description = "纷争之王：生命最大值提高100%",
                attr_type = CONST_EVENT.attr,
                attr = _attr({ shengming_baifenbi = "+100" })
            }
            local emoxianfeng                       = {
                description = "恶魔先锋：攻击和攻击速度提高30%，移动速度提高到极限",
                attr_type = CONST_EVENT.attr,
                attr = _attr({ attack_speed = "+30", gongji_baifenbi = "+30", move = "+500" })
            }

            local gongjilijiangdi                   = {
                description = "生命链接|n黑暗议会成员可以平均分配生命值（英雄难度），代价就是个体攻击力降低50%，生命降低50%",
                attr_type = CONST_EVENT.attr,
                attr = _attr({ gongji_baifenbi = "-60", shengming_baifenbi = "-50" })
            }

            local shengminglianjie                  =
            {
                aiType = UNIT_AI_TYPE.CAST_SKILL,
                aiData = {
                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                    name = "生命链接",
                    --castCountLimit = 1, -- cast only x times per battle
                    minNandu = FUBEN_NANDU.YINGXIONG,
                    castCD = 10, -- nil or <=1 means 1 second
                    --healthBelowLimit = 65, -- only cast when health is < 65%
                    shifashijian = 0.5,
                    startEffect = function(evtData)
                    end,
                    --interval = 1,
                    periodEffect = function(evtData, curTimer)
                    end,
                    castDistance = 10000,
                    effect = function(evtData)
                        local sourceUnit = evtData.triggerUnit
                        local targetUnit = evtData.targetUnit
                        local group = hgroup.createByRect(
                            hunit.getRect(sourceUnit),
                            function(enumUnit)
                                if hunit.isAlly(sourceUnit, enumUnit) and hunit.isAlive(enumUnit)
                                    and (hunit.getName(enumUnit) == "维拉斯·黑暗之影" or
                                        hunit.getName(enumUnit) == "高阶虚空术士塞雷巴" or
                                        hunit.getName(enumUnit) == "粉碎者加西奥斯"
                                        or hunit.getName(enumUnit) == "玛兰德女士")
                                then
                                    return true
                                end
                            end
                        )
                        local averageHealthPercentage = function(group)
                            if group == nil or #group == 0 then
                                return
                            end

                            local totalPercentage = 0
                            local unitCount = 0

                            -- 计算总的生命值百分比和单位数量
                            for _, enumUnit in ipairs(group) do
                                local currentPercentage = hunit.getCurLifePercent(enumUnit)
                                totalPercentage = totalPercentage + currentPercentage
                                unitCount = unitCount + 1
                            end

                            -- 计算平均生命值百分比
                            local averagePercentage = totalPercentage / unitCount

                            -- 应用平均生命值百分比到每个单位
                            for _, enumUnit in ipairs(group) do
                                hunit.setCurLifePercent(enumUnit, averagePercentage)
                            end
                        end
                        averageHealthPercentage(group)
                        for _, enumUnit in ipairs(group) do
                            if hfightzhuangtai.isInFight(enumUnit) == false then
                                cj.IssueTargetOrder(enumUnit, "attack", targetUnit)
                            end
                        end
                    end
                }
            }

            local emojianqi                         = {
                description = "剑气纵横：攻击有30%概率触发剑气，对路径上的敌人造成额外伤害，有30%概率连发",
                attr_type = CONST_EVENT.attack,
                attr = function(evtData)
                    if math.random(1, 100) > 30 then return end
                    local sourceUnit = evtData.triggerUnit
                    local targetUnit = evtData.targetUnit
                    local width = 200
                    local speed = 1000
                    local scale = 1
                    local damage =
                        hattr.get(sourceUnit, "attack", 1)
                    local angel = hunit.getFacing(sourceUnit)
                    local x, y =
                        math.polarProjection(
                            hunit.x(sourceUnit),
                            hunit.y(sourceUnit),
                            1000,
                            angel
                        )
                    local fashe
                    fashe = function()
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
                                damageType = DAMAGE_TYPE.WULI,
                                damageSkill = hslk.n2i("AI技能模版"),
                                oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
                                endDistance = 0,
                                extraInfluence = function(whichUnit)
                                end, --对选中的敌人的额外影响，会回调该敌人单位，可以对其做出自定义行为
                                onEnding = function(_, _, timePassed)
                                end
                            }
                        )
                        if math.random(1, 100) <= 30 then
                            htime.setTimeout(
                                0.2,
                                function()
                                    fashe()
                                end
                            )
                        end
                    end
                    fashe()
                end
            }

            local hujiaxiaorong                     = {
                description = "护甲消融：攻击有30%概率融化目标护甲",
                attr_type = CONST_EVENT.attack,
                attr = function(evtData)
                    if math.random(1, 100) > 30 then return end
                    local targetUnit = evtData.targetUnit
                    heffect.attach("war3mapImported\\AZ_Misslie06.MDX", targetUnit, "origin", 0)
                    hbuff.addStackAttrBuff(
                        CONST_DAMAGE_SRC.skill,
                        targetUnit,
                        "护甲消融",
                        _attr({ defend_green = "-50" }),
                        30,
                        99,
                        "ReplaceableTextures\\zhanshi\\Ability_Warrior_Sunder.blp",
                        "护甲消融|n每层降低" .. 50 .. "点护甲",
                        false
                    )
                end
            }

            local zhimingduyao                      = {
                description = "致残毒药：攻击有30%概率给目标上毒，使目标受到额外的伤害，并降低移动速度和攻击速度，最多叠加三层",
                attr_type = CONST_EVENT.attack,
                attr = function(evtData)
                    if math.random(1, 100) > 30 then return end
                    local targetUnit = evtData.targetUnit
                    heffect.attach("war3mapImported\\AZ_Misslie06.MDX", targetUnit, "origin", 0)
                    hbuff.addStackAttrBuff(
                        CONST_DAMAGE_SRC.skill,
                        targetUnit,
                        "致残毒药",
                        _attr({ attack_speed = "-20", move = "-50", jianshang = "-5" }),
                        10,
                        3,
                        hslk.n2v("致命毒药", "Art"),
                        "致残毒药|n每层降低20点共计速度，50点移动速度和5%的减伤",
                        false
                    )
                end
            }
            local gaojizhimingduyao                 = {
                description = "高级致残毒药：攻击有30%概率给目标上毒，使目标受到额外的伤害，并降低移动速度和攻击速度，最多叠加5层",
                attr_type = CONST_EVENT.attack,
                attr = function(evtData)
                    if math.random(1, 100) > 30 then return end
                    local targetUnit = evtData.targetUnit
                    heffect.attach("war3mapImported\\AZ_Misslie06.MDX", targetUnit, "origin", 0)
                    hbuff.addStackAttrBuff(
                        CONST_DAMAGE_SRC.skill,
                        targetUnit,
                        "高级致残毒药",
                        _attr({ attack_speed = "-20", move = "-50", jianshang = "-5" }),
                        10,
                        5,
                        hslk.n2v("致命毒药", "Art"),
                        "高级致残毒药|n每层降低20点共计速度，50点移动速度和5%的减伤",
                        false
                    )
                end
            }



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
                        },
                        {
                            list = { "黑暗精华" }, --物品名字 需要在物编定义好
                            drop_rate = {
                                --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                10,
                                100,
                                200,
                                0
                            }
                        }
                    }
                )

            local jinzhanai       = function(level, nandu)
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
            local fashiai         = function(level, nandu)
                return UnitAI(
                    {
                        {
                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                name = "暗影箭",
                                --castCountLimit = 1, -- cast only x times per battle
                                minNandu = FUBEN_NANDU.PUTONG,
                                castCD = 0.1, -- nil or <=1 means 1 second
                                --healthBelowLimit = 65, -- only cast when health is < 65%
                                shifashijian = 2.5,
                                startEffect = function(evtData)
                                end,
                                --interval = 1,
                                periodEffect = function(evtData, curTimer)
                                end,
                                castDistance = 10000,
                                effect = function(evtData)
                                    local sourceUnit = evtData.triggerUnit
                                    local targetUnit = evtData.targetUnit
                                    hskillMoban.missile(
                                        {
                                            --model = "war3mapImported\\[SPELL]_115.mdl",
                                            model =
                                            "war3mapImported\\[Spell]_1111_new.mdl",
                                            scale = 1,
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
                                                        damage = hattr.get(
                                                            sourceUnit,
                                                            "attack",
                                                            0
                                                        ) * 1.5,
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

            local nvyaoai         = function(level, nandu)
                return UnitAI(
                    {
                        {
                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                name = "诅咒",
                                --castCountLimit = 1, -- cast only x times per battle
                                minNandu = FUBEN_NANDU.PUTONG,
                                castCD = 0.1, -- nil or <=1 means 1 second
                                --healthBelowLimit = 65, -- only cast when health is < 65%
                                shifashijian = 2.5,
                                startEffect = function(evtData)
                                end,
                                --interval = 1,
                                periodEffect = function(evtData, curTimer)
                                end,
                                castDistance = 10000,
                                effect = function(evtData)
                                    local sourceUnit = evtData.triggerUnit
                                    local targetUnit = evtData.targetUnit
                                    hbuff.addStackAttrBuff(
                                        CONST_DAMAGE_SRC.skill,
                                        targetUnit,
                                        "BT诅咒",
                                        { hit = "-10" },
                                        20,
                                        3,
                                        "ReplaceableTextures\\CommandButtons\\BTNCurseOn.blp",
                                        "命中降低10%，可叠加最多3层。",
                                        false
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

            local shinvai         = function(level, nandu)
                return UnitAI(
                    {
                        {
                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                name = "减速",
                                --castCountLimit = 1, -- cast only x times per battle
                                minNandu = FUBEN_NANDU.PUTONG,
                                castCD = 0.1, -- nil or <=1 means 1 second
                                --healthBelowLimit = 65, -- only cast when health is < 65%
                                shifashijian = 2.5,
                                startEffect = function(evtData)
                                end,
                                --interval = 1,
                                periodEffect = function(evtData, curTimer)
                                end,
                                castDistance = 10000,
                                effect = function(evtData)
                                    local sourceUnit = evtData.triggerUnit
                                    local targetUnit = evtData.targetUnit
                                    local e = heffect.attach("Abilities\\Spells\\Human\\Slow\\SlowCaster.mdl", targetUnit,
                                        "origin", 0)
                                    hbuff.addStackAttrBuff(
                                        CONST_DAMAGE_SRC.skill,
                                        targetUnit,
                                        "BT减速",
                                        { move = "-50", attack_speed = "-10", skill_speed = "-5" },
                                        30,
                                        3,
                                        "ReplaceableTextures\\CommandButtons\\BTNSlowOn.blp",
                                        "移动降低10%，攻击速度降低10%，施法速度降低5%，最多可叠加3层。",
                                        false,
                                        function()
                                            heffect.destroy(e)
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
            end

            hfuben.buildFuben(
                {
                    name = "黑暗神殿", --副本名字
                    status = status,
                    blp = "ReplaceableTextures\\xiaoditu\\UI_map_21.blp",
                    enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_21.blp",
                    nanduLevelConfig = nanduLevelConfig,                                    -- 副本难度以及级别需求,
                    entryPosition = { x = -2495.5, y = -13772 },
                    startPosition = { x = 7794, y = -24077 },                               --英雄进副本后位置
                    rectParam = { minX = 3806, minY = -24294, maxX = 8418, maxY = -17311 }, -- 副本区域
                    minions = {
                        {
                            name = "神殿恶魔卫士", -- 名字 需要在物编定义好
                            x = 7593, -- 小怪刷新x坐标
                            y = -22606, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = jinzhanai
                        },
                        {
                            name = "神殿恶魔卫士", -- 名字 需要在物编定义好
                            x = 6275, -- 小怪刷新x坐标
                            y = -23754, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            ai = jinzhanai
                        },
                        {
                            name = "神殿黑暗术士", -- 名字 需要在物编定义好
                            x = 6275, -- 小怪刷新x坐标
                            y = -23754, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 500,
                            ai = fashiai
                        },
                        {
                            name = "神殿恶魔卫士", -- 名字 需要在物编定义好
                            x = 5935, -- 小怪刷新x坐标
                            y = -22742, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 500,
                            ai = jinzhanai
                        },
                        {
                            name = "神殿黑暗术士", -- 名字 需要在物编定义好
                            x = 5935, -- 小怪刷新x坐标
                            y = -22742, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 500,
                            ai = fashiai
                        },
                        {
                            name = "神殿恶魔卫士", -- 名字 需要在物编定义好
                            x = 4913, -- 小怪刷新x坐标
                            y = -21027, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 500,
                            ai = jinzhanai
                        },
                        {
                            name = "神殿黑暗术士", -- 名字 需要在物编定义好
                            x = 4913, -- 小怪刷新x坐标
                            y = -21027, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 500,
                            ai = fashiai
                        },
                        {
                            name = "神殿恶魔卫士", -- 名字 需要在物编定义好
                            x = 6306, -- 小怪刷新x坐标
                            y = -20866, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 500,
                            ai = jinzhanai
                        },
                        {
                            name = "神殿黑暗术士", -- 名字 需要在物编定义好
                            x = 6306, -- 小怪刷新x坐标
                            y = -20866, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 500,
                            ai = fashiai
                        },
                        {
                            name = "神殿恶魔女妖", -- 名字 需要在物编定义好
                            x = 6306, -- 小怪刷新x坐标
                            y = -20866, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 500,
                            ai = nvyaoai
                        },
                        {
                            name = "神殿恶魔卫士", -- 名字 需要在物编定义好
                            x = 7500, -- 小怪刷新x坐标
                            y = -18349, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 500,
                            ai = jinzhanai
                        },
                        {
                            name = "神殿黑暗术士", -- 名字 需要在物编定义好
                            x = 7500, -- 小怪刷新x坐标
                            y = -18349, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 500,
                            ai = fashiai
                        },
                        {
                            name = "神殿黑暗侍女", -- 名字 需要在物编定义好
                            x = 7500, -- 小怪刷新x坐标
                            y = -18349, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            diaoluoConfig = xiaoguaidiaoluo,
                            passiveSkill = { {}, {}, {}, {} },
                            randomRadius = 500,
                            ai = shinvai
                        },
                    },
                    bosses = {
                        {
                            name = "主母赫拉姆斯",
                            x = 5042,
                            y = -22925,
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
                                            "欲望镣铐",
                                            "影月徽记",
                                            "上层精灵斗篷",
                                            "堕落欲望魔典",
                                            "背叛者的疯狂",
                                            "裂魂之斧",
                                            "黑暗意图箭袋"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2100,
                                            2100,
                                            2100,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "黑暗精华",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            300,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                }
                            ),
                            ai = function(level, nandu, count, fubenstatus)
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
                            end,
                            passiveSkill = { { emoxianfeng }, { emoxianfeng, emojianqi }, { emoxianfeng, emojianqi, hujiaxiaorong }, { emoxianfeng, emojianqi, hujiaxiaorong } }
                        },
                        {
                            name = "玛兰德女士",
                            x = 7794,
                            y = -20394,
                            face = 180,
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
                                }
                            ),
                            ai = function(level, nandu, count, fubenstatus, mijing)
                                return UnitAI(
                                    {
                                        shengminglianjie,
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE
                                                    .HIGHEST_CHOUHENG_UNIT,
                                                name = "治疗之环",
                                                castCD = 15,
                                                --castCountLimit = 1,
                                                shifashijian = 5,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.SHISHI,
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
                                                                    ) * 0.2 * nandu
                                                            }
                                                        )
                                                    end
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "惩击",
                                                --healthBelowLimit = 100,
                                                --notInterruptable = true,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 3,
                                                castCD = 0.1, -- nil or <=1 means 1 second
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
                                                            damage = 0.7 * basicAttack,
                                                            damageType = DAMAGE_TYPE.MOFA,
                                                            effect = "[jineng]chengji.mdx",
                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT },
                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                        }
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
                                )
                            end,
                            passiveSkill = { { gongjilijiangdi }, { gongjilijiangdi }, { gongjilijiangdi }, { gongjilijiangdi } }
                        },
                        {
                            name = "粉碎者加西奥斯",
                            x = 7794,
                            y = -20629,
                            face = 180,
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
                                            "血色珍珠披风",
                                            "鲁莽怒火战甲",
                                            "黑暗编年史",
                                            "神圣信仰胸甲",
                                            "静谧海岸外衣",
                                            "救赎灵魂披风",
                                            "光荣披风",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2100,
                                            2100,
                                            2100,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "黑暗意志披风",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            300,
                                            500,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "史诗黑暗意志披风",
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
                                            "黑暗精华",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            300,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                }
                            ),
                            ai = function(level, nandu, count, fubenstatus, mijing)
                                return UnitAI(
                                    {
                                        shengminglianjie,
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE
                                                    .HIGHEST_CHOUHENG_UNIT,
                                                name = "奉献",
                                                castCD = 12,
                                                --castCountLimit = 1,
                                                shifashijian = 1,
                                                castDistance = 300,
                                                minNandu = FUBEN_NANDU.SHISHI,
                                                --healthBelowLimit = 100, -- only cast when health is < 65%
                                                notInterruptable = false,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local x = hunit.x(sourceUnit)
                                                    local y = hunit.y(sourceUnit)
                                                    local z = hunit.z(sourceUnit)
                                                    heffect.xyz("war3mapImported\\[Spell]_147.mdx", x, y, z, 5, 1, 1, 1,
                                                        1)
                                                    local second = 1
                                                    htime.setInterval(
                                                        1,
                                                        function(curTimer)
                                                            if second > 5 then
                                                                curTimer.destroy()
                                                                return
                                                            end
                                                            second = second + 1
                                                            hskillMoban.radiusAOE(
                                                                x,
                                                                y,
                                                                sourceUnit,
                                                                500,
                                                                function(unit)
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = sourceUnit,
                                                                            targetUnit = unit,
                                                                            damage = hattr.getWithLimit(sourceUnit, nil,
                                                                                "attack", 0),
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.MOFA,
                                                                            triggerSkill = hslk.n2i("装备技能"),
                                                                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT },
                                                                            shanghainame = "奉献",
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
                                                targetType = UNIT_AI_TARGET_TYPE
                                                    .HIGHEST_CHOUHENG_UNIT,
                                                name = "制裁",
                                                castCD = 15,
                                                --castCountLimit = 1,
                                                shifashijian = 4,
                                                castDistance = 300,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                --healthBelowLimit = 100, -- only cast when health is < 65%
                                                notInterruptable = false,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    hbuff.xuanyun(evtData.targetUnit, 5)
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
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "狂热一击",
                                                healthBelowLimit = 90,
                                                notInterruptable = true,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 0.7,
                                                castDistance = 300,
                                                castCD = 5, -- nil or <=1 means 1 second
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
                                                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
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
                            passiveSkill = { { gongjilijiangdi }, { gongjilijiangdi }, { gongjilijiangdi }, { gongjilijiangdi } }
                        },
                        {
                            name = "高阶虚空术士塞雷巴",
                            x = 7794,
                            y = -20900,
                            face = 180,
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
                                }
                            ),
                            ai = function(level, nandu, count, fubenstatus, mijing)
                                return UnitAI(
                                    {
                                        shengminglianjie,
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.RANDOM_ENERMY_UNIT,
                                                name = "烈焰风暴",
                                                healthBelowLimit = 100,
                                                --healthAboveLimit = 35,
                                                castDistance = 10000,
                                                --castCountLimit = 1,
                                                shifashijian = 3,
                                                onlyInFight = true,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                notInterruptable = true,
                                                --cast when life is below 50%
                                                castCD = 15, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    hskillMoban.radiusWarning(
                                                        hunit.x(evtData.targetUnit),
                                                        hunit.y(evtData.targetUnit),
                                                        hunit.z(evtData.targetUnit),
                                                        300,
                                                        1
                                                    )
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    heffect.xyz("AZ_F034.mdx",
                                                        evtData.targetX,
                                                        evtData.targetY,
                                                        hjapi.Z(evtData.targetX,
                                                            evtData.targetY),
                                                        0,
                                                        1, 1.3, 1.3, 1.3)
                                                    hskillMoban.radiusAOE(
                                                        evtData.targetX,
                                                        evtData.targetY,
                                                        sourceUnit,
                                                        300,
                                                        function(target)
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = sourceUnit,
                                                                    targetUnit = target,
                                                                    damage = hattr.get(sourceUnit, "attack", 0) * 5,
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
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                                name = "奥术弹幕",
                                                castCD = 0.1,
                                                --castCountLimit = 1,
                                                shifashijian = 3,
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
                                                                        damage = hattr.get(sourceUnit, "attack", 0) * 0.7,
                                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                                        damageType = DAMAGE_TYPE.MOFA,
                                                                        triggerSkill = hslk.n2i("AI技能模版"),
                                                                        damageElementType = {
                                                                            CONST_DAMAGE_ELEMENT_TYPE.WOOD
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
                            passiveSkill = { { gongjilijiangdi }, { gongjilijiangdi }, { gongjilijiangdi }, { gongjilijiangdi } }
                        },
                        {
                            name = "维拉斯·黑暗之影",
                            x = 7794,
                            y = -21170,
                            face = 180,
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
                                }
                            ),
                            ai = function(level, nandu, count, fubenstatus, mijing)
                                return UnitAI(
                                    {
                                        shengminglianjie,
                                        {
                                            aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                            }
                                        }
                                    }
                                )
                            end,
                            passiveSkill = { { gongjilijiangdi }, { zhimingduyao, gongjilijiangdi }, { gaojizhimingduyao, gongjilijiangdi }, { gaojizhimingduyao, gongjilijiangdi } }
                        },
                        {
                            name = "背叛者",
                            x = 5320,
                            y = -18500,
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
                                            "女祭司的记忆",
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
                                            "原罪披风",
                                            "诅咒火炬",
                                            "玛维的执行镣铐",
                                            "古尔丹之颅",
                                            "扎尔杜姆·吞噬者的法杖",
                                            "背叛者的黑暗之弓",
                                            "光荣战盔",
                                            "萨格拉斯的诅咒视界",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2400,
                                            2400,
                                            2400,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "黑暗意志头盔",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            300,
                                            500,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "史诗黑暗意志头盔",
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
                                            "黑暗精华",
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            300,
                                            500,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "虚空陨铁"
                                        }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            300,
                                            500,
                                            0
                                        }
                                    },
                                    {
                                        list = {
                                            "破损的恶魔战刃（主手）", "破损的恶魔战刃（副手）"
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
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "落地",
                                                onlyInFight = true,
                                                castCD = 20,
                                                castCountLimit = 1,
                                                shifashijian = 2,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                healthBelowLimit = 100, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    local phase = hcache.get(whichUnit, "phase")
                                                    local group = hgroup.createByRect(
                                                        hunit.getRect(whichUnit),
                                                        function(u)
                                                            if hunit.getName(u) == "埃辛诺斯烈焰" and hunit.isAlive(u) then
                                                                return true
                                                            end
                                                        end
                                                    )
                                                    return phase == 2 and hgroup.isEmpty(group)
                                                end,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 3)
                                                end,
                                                effect = function(evtData)
                                                    hattr.set(evtData.triggerUnit, 0, _attr({ move = "+1000" }))
                                                    hunit.setInvulnerable(evtData.triggerUnit, false)
                                                    hjapi.DzUnitDisableAttack(evtData.triggerUnit,
                                                        false)
                                                    hcache.set(evtData.triggerUnit, "phase", 3)
                                                    cj.AddUnitAnimationProperties(evtData.triggerUnit, 'alternate', false)
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                name = "飞天",
                                                onlyInFight = true,
                                                castCD = 20,
                                                castCountLimit = 1,
                                                shifashijian = 2,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                healthBelowLimit = 65, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    local phase = hcache.get(whichUnit, "phase")
                                                    return phase ~= 2
                                                end,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 4)
                                                    hunit.setInvulnerable(evtData.triggerUnit, true)
                                                    hjapi.DzUnitDisableAttack(evtData.triggerUnit,
                                                        true)
                                                end,
                                                effect = function(evtData)
                                                    hcache.set(evtData.triggerUnit, "phase", 2)
                                                    cj.AddUnitAnimationProperties(evtData.triggerUnit, 'alternate', true)
                                                    hattr.set(evtData.triggerUnit, 0, _attr({ move = "-1000" }))
                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = hunit.getLevel(evtData.triggerUnit),
                                                                attackSpace = hslk.n2v("埃辛诺斯烈焰",
                                                                    "cool1"),
                                                                guaiwuType = MONSTER_TYPE
                                                                    .FUBEN_JINGYING,
                                                                nandu = nandu
                                                            }
                                                        )
                                                    local tmpUnit =
                                                        henemy.create(
                                                            {
                                                                id = hslk.n2i("埃辛诺斯烈焰"),
                                                                x = hunit.x(evtData.targetUnit) +
                                                                    math.random(-100, 100),
                                                                y = hunit.y(evtData.targetUnit) +
                                                                    math.random(-100, 100),
                                                                facing = math.random(0, 360),
                                                                attr = tmpAttr,
                                                                AI = UnitAI(
                                                                    {
                                                                        {
                                                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                                                            aiData = {
                                                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                                                name = "邪能烈焰",
                                                                                onlyInFight = true,
                                                                                castCD = 10,
                                                                                --castCountLimit = 1,
                                                                                shifashijian = 3,
                                                                                castDistance = 300,
                                                                                minNandu = FUBEN_NANDU.SHISHI,
                                                                                healthBelowLimit = 80, -- only cast when health is < 65%
                                                                                notInterruptable = false,
                                                                                skip_skill_speed = false,
                                                                                startEffect = function(evtData)
                                                                                end,
                                                                                effect = function(evtData)
                                                                                    local whichUnit = evtData
                                                                                        .triggerUnit
                                                                                    local duration = 30
                                                                                    local x = evtData.targetX
                                                                                    local y = evtData.targetY
                                                                                    local z = hjapi.Z(x, y)
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
                                                                                                hattribute.getWithLimit(
                                                                                                    whichUnit, nil,
                                                                                                    "attack",
                                                                                                    0)
                                                                                            hskillMoban.radiusAOE(
                                                                                                x,
                                                                                                y,
                                                                                                whichUnit,
                                                                                                300,
                                                                                                function(target)
                                                                                                    hskill.damage(
                                                                                                        {
                                                                                                            sourceUnit =
                                                                                                                whichUnit,
                                                                                                            targetUnit =
                                                                                                                target,
                                                                                                            damage =
                                                                                                                damage,
                                                                                                            damageSrc =
                                                                                                                CONST_DAMAGE_SRC.skill,
                                                                                                            damageType =
                                                                                                                DAMAGE_TYPE.MOFA,
                                                                                                            triggerSkill =
                                                                                                                hslk.n2i(
                                                                                                                    "AI技能模版"),
                                                                                                            damageElementType = {
                                                                                                                CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                                                            },
                                                                                                            damageSpeedType =
                                                                                                                CONST_DAMAGE_SPEED_TYPE
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
                                                    local tmpUnit =
                                                        henemy.create(
                                                            {
                                                                id = hslk.n2i("埃辛诺斯烈焰"),
                                                                x = hunit.x(evtData.targetUnit) +
                                                                    math.random(-100, 100),
                                                                y = hunit.y(evtData.targetUnit) +
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
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                name = "恶魔变形",
                                                onlyInFight = true,
                                                castCD = 20,
                                                castCountLimit = 1,
                                                shifashijian = 1.5,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.SHISHI,
                                                healthBelowLimit = 35, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    local phase = hcache.get(whichUnit, "phase")
                                                    return phase ~= 2
                                                end,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 9)
                                                end,
                                                effect = function(evtData)
                                                    hcache.set(evtData.triggerUnit, "phase", 4)
                                                    hbuff.update(-1,
                                                        evtData.triggerUnit,
                                                        "恶魔变形",
                                                        true,
                                                        function()
                                                            hattribute.set(evtData.triggerUnit, 0,
                                                                _attr({ quanju_zengshang = "+30" }))
                                                            hjapi.DzSetUnitModel(evtData.triggerUnit,
                                                                "Illidanevil_2.mdx")
                                                            heffect.attach("war3mapImported\\weapon_DSJ_19_L.mdx",
                                                                evtData.triggerUnit, "left", -1)
                                                            heffect.attach("war3mapImported\\weapon_DSJ_19_R.mdx",
                                                                evtData.triggerUnit, "right", -1)
                                                        end,
                                                        nil,
                                                        hslk.n2v("恶魔变形", "Art"),
                                                        "恶魔变形|n所有伤害增加30%",
                                                        1,
                                                        nil,
                                                        nil,
                                                        nil,
                                                        nil,
                                                        HBUFF_UPDATE_MODE.OVERWRITE
                                                    )
                                                    local damage = hattr.get(evtData.triggerUnit, "attack", 0) * 0.4
                                                    local interval = 1
                                                    local duration = -1
                                                    local e =
                                                        heffect.attach(
                                                            "Abilities\\Spells\\NightElf\\Immolation\\ImmolationTarget.mdl",
                                                            evtData.triggerUnit, "origin", -1)
                                                    hbuff.update(
                                                        duration,
                                                        evtData.triggerUnit,
                                                        "献祭",
                                                        true,
                                                        function()
                                                        end,
                                                        function()
                                                            heffect.destroy(e)
                                                        end,
                                                        hslk.n2v("献祭", "Art"),
                                                        "献祭：每" .. interval .. "秒对周围单位造成" .. damage .. "火焰魔法伤害",
                                                        1,
                                                        interval,
                                                        function(_, buffHandle)
                                                            buffHandle.remainingTime = buffHandle.remainingTime -
                                                                buffHandle.interval
                                                            hskillMoban.rectAOE(
                                                                hunit.getRect(evtData.triggerUnit),
                                                                evtData.triggerUnit,
                                                                function(u)
                                                                    heffect.attach(
                                                                        "Abilities\\Spells\\NightElf\\Immolation\\ImmolationDamage.mdl",
                                                                        u, "head", 0.1)
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = evtData.triggerUnit,
                                                                            targetUnit = u,
                                                                            damage = damage,
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageType = DAMAGE_TYPE.MOFA,
                                                                            triggerSkill = hslk.n2i("AI技能模版"),
                                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                .DOT,
                                                                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                                                            shanghainame = "献祭"
                                                                        }
                                                                    )
                                                                end
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
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "恶魔火球",
                                                --healthBelowLimit = 90,
                                                --healthAboveLimit = 35,
                                                castDistance = 10000,
                                                --castCountLimit = 1,
                                                shifashijian = 0.7,
                                                onlyInFight = true,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                notInterruptable = false,
                                                --cast when life is below 50%
                                                castCD = 3, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    local phase = hcache.get(whichUnit, "phase")
                                                    return phase == 2
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local targetX = evtData.targetX
                                                    local targetY = evtData.targetY
                                                    hskillMoban.radiusWarning(
                                                        targetX,
                                                        targetY,
                                                        hjapi.Z(targetX, targetY),
                                                        250,
                                                        1
                                                    )
                                                    hskillMoban.missile(
                                                        {
                                                            --model = "war3mapImported\\[SPELL]_115.mdl",
                                                            model =
                                                            "Abilities\\Weapons\\RedDragonBreath\\RedDragonMissile.mdl",
                                                            scale = 1,
                                                            speed = 600,
                                                            hover = 600,
                                                            targetHover = 50,
                                                            sourceUnit = sourceUnit,
                                                            targetX = targetX,
                                                            targetY = targetY,
                                                            target_face_dis = 50,
                                                            onEnd = function(_, _, endX, endY)
                                                                hskillMoban.radiusAOE(
                                                                    endX,
                                                                    endY,
                                                                    sourceUnit,
                                                                    250,
                                                                    function(target)
                                                                        hskill.damage(
                                                                            {
                                                                                sourceUnit = sourceUnit,
                                                                                targetUnit = targetUnit,
                                                                                damage = hattr.get(sourceUnit, "attack",
                                                                                    0) * 2,
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
                                                                    end)
                                                            end
                                                        }
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.RANDOM_ENERMY_UNIT,
                                                name = "寄生暗影魔",
                                                castCD = 20,
                                                --castCountLimit = 1,
                                                shifashijian = 1,
                                                castDistance = 10000,
                                                healthBelowLimit = 90,
                                                onlyInFight = true,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                notInterruptable = true,
                                                skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    local phase = hcache.get(whichUnit, "phase")
                                                    return phase ~= 2
                                                end,
                                                startWarning = false,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0)
                                                    hbuff.update(
                                                        5,
                                                        evtData.targetUnit,
                                                        "寄生暗影魔",
                                                        false,
                                                        function()
                                                        end,
                                                        function()
                                                            local tmpAttr =
                                                                hunit.getAttributeBasedOnOptions(
                                                                    {
                                                                        level = hunit.getLevel(sourceUnit),
                                                                        attackSpace = hslk.n2v("暗影魔",
                                                                            "cool1"),
                                                                        guaiwuType = MONSTER_TYPE
                                                                            .FUBEN_XIAOGUAI,
                                                                        nandu = nandu
                                                                    }
                                                                )
                                                            local tmpUnit =
                                                                henemy.create(
                                                                    {
                                                                        id = hslk.n2i("暗影魔"),
                                                                        x = hunit.x(evtData.targetUnit) +
                                                                            math.random(-100, 100),
                                                                        y = hunit.y(evtData.targetUnit) +
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
                                                        end,
                                                        "ReplaceableTextures\\HUOTIZHADAN\\PASBTNHUOTIZHADAN.blp",
                                                        "寄生暗影魔|n造成持续伤害，结束后会诞生一个暗影魔",
                                                        1,
                                                        1,
                                                        function(curTimer, buffHandle)
                                                            buffHandle.remainingTime = buffHandle.remainingTime -
                                                                buffHandle.interval
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = sourceUnit,
                                                                    targetUnit = evtData.targetUnit,
                                                                    damage = hattribute.getWithLimit(sourceUnit, nil,
                                                                        "attack", 0) * 0.2,
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK },
                                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT
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
                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                name = "邪能烈焰",
                                                onlyInFight = true,
                                                castCD = 20,
                                                --castCountLimit = 1,
                                                shifashijian = 2,
                                                castDistance = 300,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 85, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = false,
                                                customCondition = function(whichUnit)
                                                    local phase = hcache.get(whichUnit, "phase")
                                                    return phase ~= 2
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local whichUnit = evtData.triggerUnit
                                                    local duration = 30
                                                    local x = evtData.targetX
                                                    local y = evtData.targetY
                                                    local z = hjapi.Z(x, y)
                                                    heffect.xyz(
                                                        "war3mapImported\\AZ_SoulFire_orange.mdx",
                                                        x,
                                                        y,
                                                        z,
                                                        duration,
                                                        1,
                                                        1,
                                                        1,
                                                        1

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
                                                                400,
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
                                                                                CONST_DAMAGE_ELEMENT_TYPE.FIRE
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
                                                name = "吸取灵魂",
                                                castCD = 15,
                                                --castCountLimit = 1,
                                                shifashijian = 0.7,
                                                castDistance = 400,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 95, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    local phase = hcache.get(whichUnit, "phase")
                                                    return phase ~= 2
                                                end,
                                                startWarning = false,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 1)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local damage =
                                                        hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * 3
                                                    local facing = hunit.getFacing(sourceUnit)
                                                    hskillMoban.radiusAngleAOE(
                                                        sourceUnit,
                                                        600,
                                                        facing,
                                                        180,
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
                                                            hskill.heal(
                                                                {
                                                                    healee = sourceUnit,
                                                                    healer = sourceUnit,
                                                                    heal = hunit.getMaxLife(sourceUnit) * 0.03,
                                                                    healType = HEAL_TYPE.SKILL,
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
                                                        6,
                                                        6,
                                                        6,
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
                                                name = "剪切",
                                                healthBelowLimit = 98,
                                                notInterruptable = true,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 1.4,
                                                castDistance = 500,
                                                skip_skill_speed = true,
                                                castCD = 5, -- nil or <=1 means 1 second
                                                customCondition = function(whichUnit)
                                                    local phase = hcache.get(whichUnit, "phase")
                                                    return phase ~= 2 and phase ~= 4
                                                end,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 13)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local basicAttack =
                                                        hattribute.get(evtData.triggerUnit, "attack", 100)
                                                    hskill.damage(
                                                        {
                                                            sourceUnit = evtData.triggerUnit,
                                                            targetUnit = evtData.targetUnit,
                                                            damage = basicAttack * (2 + nandu * 0.5),
                                                            damageType = DAMAGE_TYPE.WULI,
                                                            effect = "war3mapImported\\AZ_gelie.mdx",
                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
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
                            passiveSkill = { { juxingshengwu }, { juxingshengwu }, { juxingshengwu }, { juxingshengwu } }
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
                                    maxLevel = 1,
                                    shengwangname = "和平之城"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,         value = 4000 },
                                { type = HSHOP_COST_TYPE.xieehuizhang, value = 1 },
                                { type = HSHOP_COST_TYPE.experience,   value = 18000 },
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
                                { type = HSHOP_COST_TYPE.gold,         value = 5000 },
                                { type = HSHOP_COST_TYPE.xieehuizhang, value = 1 },
                                { type = HSHOP_COST_TYPE.emohuizhang,  value = 1 },
                                { type = HSHOP_COST_TYPE.experience,   value = 20000 },
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
                                { type = HSHOP_COST_TYPE.gold,        value = 6000 },
                                { type = HSHOP_COST_TYPE.emohuizhang, value = 2 },
                                { type = HSHOP_COST_TYPE.experience,  value = 25000 },
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
