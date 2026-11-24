table.insert(
    FUBEN_LIST,
    {
        name = "黑龙王子的巢穴",
        setup = function()
            local nanduLevelConfig = {}
            nanduLevelConfig[FUBEN_NANDU.PUTONG] = 60
            nanduLevelConfig[FUBEN_NANDU.YINGXIONG] = 60
            nanduLevelConfig[FUBEN_NANDU.SHISHI] = 60
            nanduLevelConfig[FUBEN_NANDU.CHUANQI] = 70

            hfuben.buildFuben(
                {
                    name = "黑龙王子的巢穴", --副本名字
                    status = FUBEN_STATUS.JIANHUA,
                    blp = "ReplaceableTextures\\xiaoditu\\UI_map_13.blp",
                    enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_12.blp",
                    nanduLevelConfig = nanduLevelConfig,                                  -- 副本难度以及级别需求,
                    entryPosition = { x = -31081, y = -790 },
                    startPosition = { x = 4828, y = -9411 },                              --英雄进副本后位置
                    rectParam = { minX = 2559, minY = -9644, maxX = 6764, maxY = -6132 }, -- 副本区域
                    minions = {},
                    bosses = {
                        {
                            name = "黑龙王子",
                            x = 4757,
                            y = -7912,
                            levelAdj = 0,
                            huixuedistance = 5000,
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
                                        list = { "埃提耶什的杖尾" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            50,
                                            200,
                                            0
                                        }
                                    },
                                    {
                                        list = { "黑龙精华" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            0,
                                            500,
                                            0
                                        }
                                    },
                                    {
                                        list = { "成年黑龙的肌腱" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            300,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "暗影烈焰法杖", "黑曜石之刃", "多彩之剑", "龙牙饰物", "上古角石魔典", "奈萨里奥之泪" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1500,
                                            1500,
                                            1500,
                                            0
                                        }
                                    },
                                    {
                                        list = { "黑龙王子的徽记" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            500,
                                            1000,
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
                            ai = function(level, nandu, count, fubenstatus, mijing)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.SELF,
                                                name = "召唤龙蛋",
                                                castCD = 50,
                                                castCountLimit = 1,
                                                shifashijian = 1,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                --healthBelowLimit = 60, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local whichUnit = evtData.triggerUnit
                                                    local tmpAttr =
                                                        hunit.getAttributeBasedOnOptions(
                                                            {
                                                                level = level,
                                                                attackSpace = hslk.n2v("黑龙蛋", "cool1"),
                                                                guaiwuType = MONSTER_TYPE.FUBEN_XIAOGUAI,
                                                                nandu = nandu,
                                                                count = count,
                                                                mijing = mijing,
                                                            }
                                                        )
                                                    local numlongdan = 30
                                                    local anglePerDan = 360 / numlongdan
                                                    local startAngle = 0
                                                    local distance = 1200
                                                    for i = 1, numlongdan, 1 do
                                                        local angel = startAngle + anglePerDan * i
                                                        local x, y =
                                                            math.polarProjection(
                                                                hunit.x(whichUnit),
                                                                hunit.y(whichUnit),
                                                                distance + math.random(0, 300),
                                                                angel
                                                            )
                                                        local tmpUnit =
                                                            henemy.create(
                                                                {
                                                                    id = hslk.n2i("黑龙蛋"),
                                                                    x = x,
                                                                    y = y,
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
                                                        hjapi.DzUnitDisableAttack(tmpUnit, true) --禁止攻击
                                                        hunit.setExpReward(tmpUnit, 0)
                                                        hevent.onEnterUnitRange(
                                                            tmpUnit,
                                                            300,
                                                            function(evtData)
                                                                if
                                                                    hunit.isAlive(evtData.centerUnit) and
                                                                    hunit.isEnemy(
                                                                        evtData.centerUnit,
                                                                        evtData.triggerUnit
                                                                    )
                                                                then
                                                                    local tmpAttr =
                                                                        hunit.getAttributeBasedOnOptions(
                                                                            {
                                                                                level = level,
                                                                                attackSpace = hslk.n2v("黑龙幼崽", "cool1"),
                                                                                guaiwuType = MONSTER_TYPE.FUBEN_XIAOGUAI,
                                                                                nandu = nandu,
                                                                                count = count,
                                                                                status = fubenstatus or
                                                                                    FUBEN_STATUS.KAIHUANG,
                                                                                mijing = mijing
                                                                            }
                                                                        )
                                                                    local tmpUnit =
                                                                        henemy.create(
                                                                            {
                                                                                id = hslk.n2i("黑龙幼崽"),
                                                                                x = x,
                                                                                y = y,
                                                                                facing = 0,
                                                                                attr = tmpAttr,
                                                                                nandu = nandu,
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
                                                                                tuozhanshijian = 36000
                                                                            }
                                                                        )
                                                                    hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                                                                    hunit.setExpReward(tmpUnit, 0)
                                                                    hunit.kill(evtData.centerUnit)
                                                                end
                                                            end
                                                        )
                                                    end
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.LOWEST_HEALTH_UNIT,
                                                name = "深呼吸",
                                                castCD = 60,
                                                --castCountLimit = 1,
                                                shifashijian = 3.5,
                                                castDistance = 10000,
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                healthBelowLimit = 75, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    hunit.animate(evtData.triggerUnit, 10)
                                                    hevent.register(
                                                        evtData.triggerUnit,
                                                        CONST_EVENT.damagingCustomTarget,
                                                        "黑龙无敌",
                                                        function(evtData)
                                                            evtData.damage = 0
                                                        end
                                                    )
                                                    hjapi.DzUnitDisableAttack(evtData.triggerUnit, true)
                                                    hunit.setInvulnerable(evtData.triggerUnit, true)
                                                end,
                                                effect = function(evtData)
                                                    local duration = 2
                                                    if nandu >= FUBEN_NANDU.SHISHI then
                                                        duration = 6
                                                    end
                                                    hcache.set(evtData.triggerUnit, "AI_SKILL_EFFECT", true)
                                                    local damageMulti = 0.5
                                                    if nandu >= FUBEN_NANDU.SHISHI then
                                                        damageMulti = 3
                                                    end
                                                    local function getFarestPoint(x, y)
                                                        local minX = 2559
                                                        local minY = -9594
                                                        local maxX = 6764
                                                        local maxY = -6132
                                                        local maxDistancePoint = { x = x, y = y }
                                                        local maxDistance = 0
                                                        local pointA = { x = minX, y = minY }
                                                        local distanceA = math.distance(x, y, pointA.x, pointA.y)
                                                        if distanceA > maxDistance then
                                                            maxDistance = distanceA
                                                            maxDistancePoint = pointA
                                                        end
                                                        local pointB = { x = minX, y = maxY }
                                                        local distanceB = math.distance(x, y, pointB.x, pointB.y)
                                                        if distanceB > maxDistance then
                                                            maxDistance = distanceB
                                                            maxDistancePoint = pointB
                                                        end
                                                        local pointC = { x = maxX, y = minY }
                                                        local distanceC = math.distance(x, y, pointC.x, pointC.y)
                                                        if distanceC > maxDistance then
                                                            maxDistance = distanceC
                                                            maxDistancePoint = pointC
                                                        end
                                                        local pointD = { x = maxX, y = maxY }
                                                        local distanceD = math.distance(x, y, pointD.x, pointD.y)
                                                        if distanceD > maxDistance then
                                                            maxDistance = distanceD
                                                            maxDistancePoint = pointD
                                                        end
                                                        return maxDistancePoint.x, maxDistancePoint.y
                                                    end
                                                    local whichUnit = evtData.triggerUnit
                                                    local x, y = getFarestPoint(hunit.x(whichUnit), hunit.y(whichUnit))
                                                    local distance =
                                                        math.distance(hunit.x(whichUnit), hunit.y(whichUnit), x, y)
                                                    local speed = distance / 5 / 50
                                                    local function shenhuxi(whichUnit)
                                                        local angel = hunit.getFacing(whichUnit)
                                                        local x, y, z =
                                                            hunit.x(whichUnit),
                                                            hunit.y(whichUnit),
                                                            hunit.z(whichUnit)
                                                        local distance = 300
                                                        local totalKoushui = 3 + nandu * 2
                                                        local totalDistance = distance * (totalKoushui - 1)
                                                        local startX, startY =
                                                            math.polarProjection(x, y, totalDistance / 2, angel + 90)
                                                        local angel = angel - 90
                                                        for i = 1, totalKoushui, 1 do
                                                            local x = startX
                                                            local y = startY
                                                            heffect.xyz(
                                                                "war3mapImported\\[Spell]_115_2.MDX",
                                                                x,
                                                                y,
                                                                z,
                                                                duration,
                                                                1,
                                                                1.5,
                                                                1.5,
                                                                1.5
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
                                                                        whichUnit,
                                                                        450,
                                                                        function(target)
                                                                            hskill.damage(
                                                                                {
                                                                                    sourceUnit = whichUnit,
                                                                                    targetUnit = target,
                                                                                    damage = hattribute.getWithLimit(
                                                                                        whichUnit,
                                                                                        nil,
                                                                                        "attack",
                                                                                        0
                                                                                    ) * damageMulti,
                                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                                    damageElementType = {
                                                                                        CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                                    },
                                                                                    damageSpeedType =
                                                                                        CONST_DAMAGE_SPEED_TYPE.DOT
                                                                                }
                                                                            )
                                                                        end
                                                                    )
                                                                end
                                                            )
                                                            startX, startY =
                                                                math.polarProjection(startX, startY, distance, angel)
                                                        end
                                                    end
                                                    hskillMoban.leap(
                                                        {
                                                            arrowUnit = evtData.triggerUnit,  -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                                                            sourceUnit = evtData.triggerUnit, --伤害来源（必须有！不管有没有伤害）
                                                            --targetUnit = evtData.targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                                                            x = x,                            --冲击的x坐标（可选的，对点冲击，与某目标无关）
                                                            y = y,                            --冲击的y坐标（可选的，对点冲击，与某目标无关）
                                                            speed = speed,                    --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                                                            acceleration = 0,
                                                            shake = 0,                        --摇摆振幅角度[-90~+90|random]（可选的，默认0)
                                                            filter = function(enum)
                                                                return hunit.isEnemy(evtData.triggerUnit, enum) and
                                                                    hunit.isAlive(enum)
                                                            end,                      --必须有
                                                            tokenArrowScale = 1.00,   --前冲的特效作为马甲冲击时的模型缩放
                                                            tokenArrowOpacity = 1.00, --前冲的特效作为马甲冲击时的模型透明度[0-1]
                                                            tokenArrowHeight = 0.00,  --前冲的特效作为马甲冲击时的初始离地高度
                                                            effectMovement = nil,     --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                                            animateMovement = 13,
                                                            animation = 13,
                                                            effectEnd = nil,                                --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                                            damageMovement = nil,                           --移动过程中的伤害（可选的，默认为0）
                                                            damageMovementRadius = nil,                     --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
                                                            damageMovementRepeat = false,                   --移动过程中伤害是否可以重复造成（可选的，默认为不能）
                                                            damageMovementDrag = false,                     --移动过程是否拖拽敌人（可选的，默认为不能）
                                                            damageEndRadius = 0,                            --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
                                                            damageSrc = CONST_DAMAGE_SRC.skill,             --伤害的种类（可选）
                                                            damageEffect = "war3mapImported\\AZ_gelie.mdx", --伤害特效（可选）
                                                            damageType = DAMAGE_TYPE.WULI,
                                                            damageSkill = hslk.n2i("AI技能模版"),
                                                            oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
                                                            endDistance = 100,
                                                            moveEffectDistance = 300,
                                                            moveEffect = shenhuxi,
                                                            extraInfluence = function(whichUnit)
                                                            end, --对选中的敌人的额外影响，会回调该敌人单位，可以对其做出自定义行为
                                                            onEnding = function(xx, yy, timePassed)
                                                                local x, y =
                                                                    getFarestPoint(
                                                                        hunit.x(whichUnit),
                                                                        hunit.y(whichUnit)
                                                                    )
                                                                local distance =
                                                                    math.distance(
                                                                        hunit.x(whichUnit),
                                                                        hunit.y(whichUnit),
                                                                        x,
                                                                        y
                                                                    )
                                                                local speed = distance / 5 / 50
                                                                hskillMoban.leap(
                                                                    {
                                                                        arrowUnit = evtData.triggerUnit,  -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                                                                        sourceUnit = evtData.triggerUnit, --伤害来源（必须有！不管有没有伤害）
                                                                        --targetUnit = evtData.targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                                                                        x = x,                            --冲击的x坐标（可选的，对点冲击，与某目标无关）
                                                                        y = y,                            --冲击的y坐标（可选的，对点冲击，与某目标无关）
                                                                        speed = speed,                    --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                                                                        acceleration = 0,
                                                                        shake = 0,                        --摇摆振幅角度[-90~+90|random]（可选的，默认0)
                                                                        filter = function(enum)
                                                                            return hunit.isEnemy(
                                                                                evtData.triggerUnit,
                                                                                enum
                                                                            ) and hunit.isAlive(enum)
                                                                        end,                      --必须有
                                                                        tokenArrowScale = 1.00,   --前冲的特效作为马甲冲击时的模型缩放
                                                                        tokenArrowOpacity = 1.00, --前冲的特效作为马甲冲击时的模型透明度[0-1]
                                                                        tokenArrowHeight = 0.00,  --前冲的特效作为马甲冲击时的初始离地高度
                                                                        effectMovement = nil,     --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                                                        animateMovement = 13,
                                                                        animation = 13,
                                                                        effectEnd = nil,                                --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                                                        damageMovement = nil,                           --移动过程中的伤害（可选的，默认为0）
                                                                        damageMovementRadius = nil,                     --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
                                                                        damageMovementRepeat = false,                   --移动过程中伤害是否可以重复造成（可选的，默认为不能）
                                                                        damageMovementDrag = false,                     --移动过程是否拖拽敌人（可选的，默认为不能）
                                                                        damageEndRadius = 0,                            --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
                                                                        damageSrc = CONST_DAMAGE_SRC.skill,             --伤害的种类（可选）
                                                                        damageEffect = "war3mapImported\\AZ_gelie.mdx", --伤害特效（可选）
                                                                        damageType = DAMAGE_TYPE.WULI,
                                                                        damageSkill = hslk.n2i("AI技能模版"),
                                                                        oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
                                                                        endDistance = 100,
                                                                        moveEffectDistance = 300,
                                                                        moveEffect = shenhuxi,
                                                                        extraInfluence = function(whichUnit)
                                                                        end, --对选中的敌人的额外影响，会回调该敌人单位，可以对其做出自定义行为
                                                                        onEnding = function(xx, yy, timePassed)
                                                                            hevent.unregister(
                                                                                evtData.triggerUnit,
                                                                                CONST_EVENT.damagingCustomTarget,
                                                                                "黑龙无敌"
                                                                            )
                                                                            hunit.setInvulnerable(
                                                                                evtData.triggerUnit,
                                                                                false
                                                                            )
                                                                            hjapi.DzUnitDisableAttack(
                                                                                evtData.triggerUnit,
                                                                                false
                                                                            )
                                                                            hcache.set(
                                                                                evtData.triggerUnit,
                                                                                "AI_SKILL_EFFECT",
                                                                                false
                                                                            )
                                                                        end
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
                                                targetType = UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT,
                                                name = "陨石术",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                castCD = 10,           -- nil or <=1 means 1 second
                                                healthBelowLimit = 88, -- only cast when health is < 65%
                                                notInterruptable = true,
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
                                                    heffect.xyz("war3mapImported\\AZ_Kaer_D1.MDX", x, y, z, 1.25, 1)
                                                    local damage = hattribute.getWithLimit(whichUnit, nil, "attack", 0)
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
                                                                    hbuff.xuanyun(target, 2)
                                                                end
                                                            )
                                                            heffect.xyz(
                                                                "war3mapImported\\[Spell]_115_2.MDX",
                                                                x,
                                                                y,
                                                                z,
                                                                8,
                                                                1
                                                            )
                                                            local damageCount = 0
                                                            htime.setInterval(
                                                                1,
                                                                function(curTimer)
                                                                    if damageCount >= 6 then
                                                                        curTimer.destroy()
                                                                        return
                                                                    end
                                                                    damageCount = damageCount + 1
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
                                                                                        CONST_DAMAGE_ELEMENT_TYPE.FIRE
                                                                                    },
                                                                                    damageSpeedType =
                                                                                        CONST_DAMAGE_SPEED_TYPE.DOT
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
                                                name = "龙息术",
                                                castCD = 15,
                                                --castCountLimit = 1,
                                                shifashijian = 2,
                                                castDistance = 500,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 95, -- only cast when health is < 65%
                                                notInterruptable = false,
                                                --skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    hunit.setAnimateSpeed(
                                                        evtData.triggerUnit,
                                                        1 / evtData.shifashijian,
                                                        evtData.shifashijian
                                                    )
                                                    hunit.animate(evtData.triggerUnit, 4)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local damage =
                                                        hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * 3
                                                    local facing = hunit.getFacing(sourceUnit)
                                                    local group =
                                                        hgroup.createByAngleAndRadius(
                                                            sourceUnit,
                                                            1800,
                                                            facing,
                                                            70,
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
                                                        "war3mapImported\\AZ_HYHX.mdl",
                                                        hunit.x(sourceUnit),
                                                        hunit.y(sourceUnit),
                                                        hunit.z(sourceUnit),
                                                        0,
                                                        1,
                                                        2,
                                                        2,
                                                        2,
                                                        nil,
                                                        nil,
                                                        facing
                                                    )
                                                    for _, target in ipairs(group) do
                                                        local distance =
                                                            math.distance(
                                                                hunit.x(sourceUnit),
                                                                hunit.y(sourceUnit),
                                                                hunit.x(target),
                                                                hunit.y(target)
                                                            )
                                                        htime.setTimeout(
                                                            math.round(distance / 1600 / 2),
                                                            function(curTimer)
                                                                hskill.damage(
                                                                    {
                                                                        sourceUnit = sourceUnit,
                                                                        targetUnit = target,
                                                                        damage = damage,
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
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "挥打羽翼",
                                                castCD = 45,
                                                --castCountLimit = 1,
                                                shifashijian = 2,
                                                castDistance = 500,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                healthBelowLimit = 90, -- only cast when health is < 65%
                                                notInterruptable = true,
                                                --skip_skill_speed = true,
                                                customCondition = function(whichUnit)
                                                    return true
                                                end,
                                                startEffect = function(evtData)
                                                    hunit.setAnimateSpeed(
                                                        evtData.triggerUnit,
                                                        1.5 / evtData.shifashijian,
                                                        evtData.shifashijian
                                                    )
                                                    hunit.animate(evtData.triggerUnit, 8)
                                                    hskillMoban.radiusWarning(
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit),
                                                        hunit.z(evtData.triggerUnit),
                                                        600,
                                                        evtData.shifashijian
                                                    )
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local damage =
                                                        hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * 3
                                                    hskillMoban.radiusAOE(
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit),
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
                                                    hunit.animate(evtData.triggerUnit, 7)
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
                        }
                    },
                    tongguanjiangli = {
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold, value = 500 }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,           value = 750 },
                                { type = HSHOP_COST_TYPE.yongqihuizhang, value = 1 }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.gold,           value = 1500 },
                                { type = HSHOP_COST_TYPE.yongqihuizhang, value = 2 },
                                { type = HSHOP_COST_TYPE.huoyanhuizhang, value = 1 }
                            }
                        },
                        {}
                    }
                }
            )
        end
    }
)
