initFuwen = function()
    local fuwenConfig = { {
        name = "火焰旋风",
        art = "ReplaceableTextures\\mijing\\huoyanxuanfeng.blp",
        expKey = "mjexphyxf",
        fuwenKey = "mjfwhyxf",
        description = function(fuwen)
            local level = hfuwen.getMijilevel(fuwen)
            return
                "攻击会召唤火焰旋风环绕自己，并持续每秒对周围造成" .. hcolor.green(tostring(100 + level * 3)) .. "%主属性火焰持续魔法伤害，持续5秒，技能基础冷却15秒"
        end,
        currentExp = 0,
        isActive = false,
        maxLevel = 30,
        maxExp = 9999,
        isEquipped = false,
        attr_type = CONST_EVENT.attack,
        attr = function(evtData, fuwen)
            local level = hfuwen.getMijilevel(fuwen)
            local fuwenLevel1 = fuwen.fuwenStatus[1].currentLevel
            local fuwenLevel2 = fuwen.fuwenStatus[2].currentLevel
            local fuwenLevel3 = fuwen.fuwenStatus[3].currentLevel
            local fuwenLevel4 = fuwen.fuwenStatus[4].currentLevel
            local fuwenLevel5 = fuwen.fuwenStatus[5].currentLevel
            local fuwenLevel6 = fuwen.fuwenStatus[6].currentLevel
            local fuwenLevel7 = fuwen.fuwenStatus[7].currentLevel

            local sourceUnit = evtData.triggerUnit
            local coolDown = 15
            if fuwenLevel1 > 0 then
                coolDown = coolDown - fuwenLevel1
            end
            if htime.setupAndCheckCoolDown(sourceUnit, "秘技火焰旋风", coolDown) then
                if fuwenLevel5 > 0 then
                    if math.random(1, 100) <= fuwenLevel5 * 2 then
                        htime.clearCoolDown(sourceUnit, "秘技火焰旋风")
                    end
                end

                local damage = hunit.getZhushuxing(sourceUnit)
                if fuwenLevel3 > 0 then
                    damage = damage * (1 + 0.1 * fuwenLevel3)
                end
                damage = damage * (1 + 0.03 * level)
                damage = math.round(damage)
                local interval = 1
                local duration = 5
                local e =
                    heffect.attach("war3mapImported\\Fire_shock75.mdx", sourceUnit, "origin",
                        -1)
                local tmpAttr
                if fuwenLevel6 > 0 then
                    tmpAttr = _attr({ fa_bao = "+" .. fuwenLevel6 * 5 })
                end
                hbuff.update(
                    duration,
                    sourceUnit,
                    "火焰旋风",
                    true,
                    function()
                        if fuwenLevel2 > 0 then
                            local extraSpeed = 5 * fuwenLevel2
                            hattr.set(sourceUnit, 0, _attr({ move = "+" .. extraSpeed }))
                        end
                        if fuwenLevel7 > 0 then
                            hattr.set(sourceUnit, 0, _attr({ shanbi = "+" .. fuwenLevel7 }))
                        end
                    end,
                    function()
                        if fuwenLevel2 > 0 then
                            local extraSpeed = 5 * fuwenLevel2
                            hattr.set(sourceUnit, 0, _attr({ move = "-" .. extraSpeed }))
                        end
                        if fuwenLevel7 > 0 then
                            hattr.set(sourceUnit, 0, _attr({ shanbi = "-" .. fuwenLevel7 }))
                        end
                        heffect.destroy(e)
                    end,
                    "ReplaceableTextures\\mijing\\huoyanxuanfeng.blp",
                    "火焰旋风：每" .. interval .. "秒对周围单位造成" .. damage .. "火焰魔法持续伤害",
                    1,
                    interval,
                    function(_, buffHandle)
                        buffHandle.remainingTime = buffHandle.remainingTime - buffHandle.interval
                        hskillMoban.radiusAOE(
                            hunit.x(sourceUnit),
                            hunit.y(sourceUnit),
                            sourceUnit,
                            400,
                            function(u)
                                local finalDamage = damage
                                if fuwenLevel4 > 0 then
                                    if math.random(1, 100) <= fuwenLevel4 * 5 then
                                        finalDamage = finalDamage * 2
                                    end
                                end
                                hskill.damage(
                                    {
                                        sourceUnit = sourceUnit,
                                        targetUnit = u,
                                        damage = finalDamage,
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.MOFA,
                                        triggerSkill = hslk.n2i("装备技能"),
                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                        shanghainame = "火焰旋风",
                                        tmpAttr = tmpAttr
                                    }
                                )
                            end,
                            false,
                            true
                        )
                    end,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE,
                    true
                )
            end
        end,
        fuwenStatus = {
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "降低技能CD" .. level .. "秒"
                end,
                currentLevel = 0,
                diaoluoFuben = { "丛林深处", "火焰之心" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "触发时额外增加移动速度" .. (5 * level) .. "点"
                end,
                currentLevel = 0,
                diaoluoFuben = { "月亮湖", "黑龙王子的巢穴" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "技能造成的伤害提高" .. (10 * level) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "王城监狱" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "技能有概率伤害翻倍，概率为" .. (5 * level) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "血色军大营" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "该技能触发有概率不进入冷却，概率为" .. (level * 2) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "圣光大教堂" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "提高技能伤害额外暴击概率，概率为" .. (level * 5) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "半人马营地" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "触发技能后获得额外" .. (level) .. "%闪避"
                end,
                currentLevel = 0,
                diaoluoFuben = { "矮人地下城" },
            },
        },
    }, {
        name = "神圣之盾",
        art = "ReplaceableTextures\\mijing\\shenshengzhidun.blp",
        expKey = "mjexpsszd",
        fuwenKey = "mjfwsszd",
        description = function(fuwen)
            local level = hfuwen.getMijilevel(fuwen)
            return "攻击会召唤神圣之盾向前方冲去，达到400距离后返回，并对路径上的200范围内敌人造成" ..
                hcolor.green(tostring(150 + level * 4.5)) .. "%主属性的光明魔法伤害，cd15秒"
        end,
        currentExp = 0,
        maxLevel = 30,
        maxExp = 9999,
        isActive = false,
        isEquipped = false,
        attr_type = CONST_EVENT.attack,
        attr = function(evtData, fuwen)
            local level = hfuwen.getMijilevel(fuwen)
            local fuwenLevel1 = fuwen.fuwenStatus[1].currentLevel
            local fuwenLevel2 = fuwen.fuwenStatus[2].currentLevel
            local fuwenLevel3 = fuwen.fuwenStatus[3].currentLevel
            local fuwenLevel4 = fuwen.fuwenStatus[4].currentLevel
            local fuwenLevel5 = fuwen.fuwenStatus[5].currentLevel
            local fuwenLevel6 = fuwen.fuwenStatus[6].currentLevel
            local fuwenLevel7 = fuwen.fuwenStatus[7].currentLevel

            local sourceUnit = evtData.triggerUnit
            local coolDown = 15
            if fuwenLevel1 > 0 then
                coolDown = coolDown - fuwenLevel1
            end
            if htime.setupAndCheckCoolDown(sourceUnit, "秘技神圣之盾", coolDown) then
                if fuwenLevel5 > 0 then
                    if math.random(1, 100) <= fuwenLevel5 * 2 then
                        htime.clearCoolDown(sourceUnit, "秘技神圣之盾")
                    end
                end
                local damage = hunit.getZhushuxing(sourceUnit) * 1.5
                if fuwenLevel3 > 0 then
                    damage = damage * (1 + 0.1 * fuwenLevel3)
                end
                damage = damage * (1 + 0.03 * level)
                local tmpAttr
                if fuwenLevel6 > 0 then
                    tmpAttr = _attr({ fa_bao = "+" .. fuwenLevel6 * 5 })
                end
                local basicDistance = 400
                local startX, startY = hunit.x(sourceUnit), hunit.y(sourceUnit)
                local facing = hunit.getFacing(sourceUnit)
                local endX, endY = math.polarProjection(startX, startY, basicDistance, facing)

                if fuwenLevel7 > 0 then
                    hbuff.addStackAttrBuff(
                        CONST_DAMAGE_SRC.skill,
                        sourceUnit,
                        "神圣之盾",
                        _attr({ gedang = "+" .. fuwenLevel7 * 3 }),
                        5,
                        1,
                        "ReplaceableTextures\\mijing\\shenshengzhidun.blp",
                        "神圣之盾|n获得" .. fuwenLevel7 * 3 .. "%的格挡，持续5秒",
                        true
                    )
                end

                local fashe = function()
                    hskillMoban.leap(
                        {
                            arrowAttachModel = "war3mapImported\\[Spell]_146.mdx",
                            --arrowUnit = sourceUnit, -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                            sourceUnit = sourceUnit, --伤害来源（必须有！不管有没有伤害）
                            --targetUnit = evtData.targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                            tokenX = startX,         --冲击开始x坐标（可选的，对点冲击，与某目标无关）
                            tokenY = startY,         --冲击开始y坐标（可选的，对点冲击，与某目标无关）
                            x = endX,                --冲击的x坐标（可选的，对点冲击，与某目标无关）
                            y = endY,                --冲击的y坐标（可选的，对点冲击，与某目标无关）
                            speed = 15,              --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                            acceleration = 0,
                            shake = 0,               --摇摆振幅角度[-90~+90|random]（可选的，默认0)
                            filter = function(enum)
                                return hunit.isEnemy(sourceUnit, enum) and hunit.isAlive(enum)
                            end,                      --必须有
                            tokenArrowScale = 1.00,   --前冲的特效作为马甲冲击时的模型缩放
                            tokenArrowOpacity = 1.00, --前冲的特效作为马甲冲击时的模型透明度[0-1]
                            tokenArrowHeight = 0.00,  --前冲的特效作为马甲冲击时的初始离地高度
                            effectMovement = nil,     --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                            --animateMovement = "attack",
                            --animation = "attack",
                            effectEnd = nil,                    --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                            damageMovement = damage,            --移动过程中的伤害（可选的，默认为0）
                            damageMovementRadius = 200,         --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
                            damageMovementRepeat = false,       --移动过程中伤害是否可以重复造成（可选的，默认为不能）
                            damageMovementDrag = false,         --移动过程是否拖拽敌人（可选的，默认为不能）
                            damageEndRadius = 0,                --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
                            damageSrc = CONST_DAMAGE_SRC.skill, --伤害的种类（可选）
                            --damageEffect = "war3mapImported\\AZ_gelie.mdx", --伤害特效（可选）
                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT },
                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                            damageType = DAMAGE_TYPE.WULI,
                            tmpAttr = tmpAttr,
                            ttl = 4,
                            shanghainame = "神圣之盾",
                            oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
                            endDistance = 0,
                            skipPathCheck = true,
                            extraInfluence = function(whichUnit)
                            end, --对选中的敌人的额外影响，会回调该敌人单位，可以对其做出自定义行为
                            onEnding = function(endX, endY, timePassed)
                                hskillMoban.leap(
                                    {
                                        arrowAttachModel = "war3mapImported\\[Spell]_146.mdx",
                                        --arrowUnit = sourceUnit, -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                                        sourceUnit = sourceUnit, --伤害来源（必须有！不管有没有伤害）
                                        --targetUnit = evtData.targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                                        tokenX = endX,           --冲击开始x坐标（可选的，对点冲击，与某目标无关）
                                        tokenY = endY,           --冲击开始y坐标（可选的，对点冲击，与某目标无关）
                                        targetUnit = sourceUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                                        --x = endX,                --冲击的x坐标（可选的，对点冲击，与某目标无关）
                                        --y = endY,                --冲击的y坐标（可选的，对点冲击，与某目标无关）
                                        speed = 15, --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                                        acceleration = 0,
                                        ttl = 6,
                                        shake = 0, --摇摆振幅角度[-90~+90|random]（可选的，默认0)
                                        filter = function(enum)
                                            return hunit.isEnemy(sourceUnit, enum) and hunit.isAlive(enum)
                                        end,                      --必须有
                                        tokenArrowScale = 1.00,   --前冲的特效作为马甲冲击时的模型缩放
                                        tokenArrowOpacity = 1.00, --前冲的特效作为马甲冲击时的模型透明度[0-1]
                                        tokenArrowHeight = 0.00,  --前冲的特效作为马甲冲击时的初始离地高度
                                        effectMovement = nil,     --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                        --animateMovement = "attack",
                                        --animation = "attack",
                                        effectEnd = nil,                    --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                                        damageMovement = damage,            --移动过程中的伤害（可选的，默认为0）
                                        damageMovementRadius = 200,         --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
                                        damageMovementRepeat = false,       --移动过程中伤害是否可以重复造成（可选的，默认为不能）
                                        damageMovementDrag = false,         --移动过程是否拖拽敌人（可选的，默认为不能）
                                        damageEndRadius = 0,                --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
                                        damageSrc = CONST_DAMAGE_SRC.skill, --伤害的种类（可选）
                                        --damageEffect = "war3mapImported\\AZ_gelie.mdx", --伤害特效（可选）
                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT },
                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                        damageType = DAMAGE_TYPE.WULI,
                                        shanghainame = "神圣之盾",
                                        tmpAttr = tmpAttr,
                                        oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
                                        endDistance = 0,
                                        skipPathCheck = true,
                                        extraInfluence = function(whichUnit)
                                        end, --对选中的敌人的额外影响，会回调该敌人单位，可以对其做出自定义行为
                                        onEnding = function(_, _, timePassed)
                                            if fuwenLevel2 > 0 then
                                                hskill.heal(
                                                    {
                                                        healer = sourceUnit,
                                                        healee = sourceUnit,
                                                        heal = math.floor(hunit.getMaxLife(sourceUnit) * fuwenLevel2 * 2 /
                                                            100),
                                                        healType = HEAL_TYPE.SKILL
                                                    }
                                                )
                                            end
                                        end
                                    })
                            end
                        })
                end
                fashe()
                if fuwenLevel4 > 0 and math.random(1, 100) < fuwenLevel4 * 5 then
                    htime.setTimeout(
                        0.1,
                        function(t)
                            fashe()
                        end
                    )
                end
            end
        end,
        fuwenStatus = {
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "降低技能CD" .. level .. "秒"
                end,
                currentLevel = 0,
                diaoluoFuben = { "丛林深处", "火焰之心" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "回收盾牌会恢复" .. (2 * level) .. "%最大生命值"
                end,
                currentLevel = 0,
                diaoluoFuben = { "月亮湖", "黑龙王子的巢穴" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "技能造成的伤害提高" .. (10 * level) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "王城监狱" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "技能有概率触发两次，概率为" .. (5 * level) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "血色军大营" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "该技能触发有概率不进入冷却，概率为" .. (level * 2) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "圣光大教堂" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "提高技能伤害额外暴击概率，概率为" .. (level * 5) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "半人马营地" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "触发技能后获得额外" .. (level * 3) .. "%的格挡，持续5秒"
                end,
                currentLevel = 0,
                diaoluoFuben = { "矮人地下城" },
            },
        },
    }, {
        name = "雾凇之箭",
        art = "ReplaceableTextures\\mijing\\wusongzhijian.blp",
        expKey = "mjexpwszj",
        fuwenKey = "mjfwwszj",
        description = function(fuwen)
            local level = hfuwen.getMijilevel(fuwen)
            return "魔法伤害有20%概率召唤雾凇之箭攻击敌人，对敌人造成" ..
                hcolor.green(tostring(100 + level * 3)) .. "%主属性的水系魔法伤害，cd2秒。触发最大距离为800"
        end,
        currentExp = 0,
        maxLevel = 30,
        maxExp = 9999,
        isActive = false,
        isEquipped = false,
        attr_type = CONST_EVENT.damage,
        attr = function(evtData, fuwen)
            if evtData.damageType ~= DAMAGE_TYPE.MOFA then
                return
            end
            local level = hfuwen.getMijilevel(fuwen)
            local fuwenLevel1 = fuwen.fuwenStatus[1].currentLevel
            local fuwenLevel2 = fuwen.fuwenStatus[2].currentLevel
            local fuwenLevel3 = fuwen.fuwenStatus[3].currentLevel
            local fuwenLevel4 = fuwen.fuwenStatus[4].currentLevel
            local fuwenLevel5 = fuwen.fuwenStatus[5].currentLevel
            local fuwenLevel6 = fuwen.fuwenStatus[6].currentLevel
            local fuwenLevel7 = fuwen.fuwenStatus[7].currentLevel

            local sourceUnit = evtData.triggerUnit
            local targetUnit = evtData.targetUnit

            if math.distance(hunit.x(sourceUnit), hunit.y(sourceUnit), hunit.x(targetUnit), hunit.y(targetUnit)) > 1200 then
                return
            end

            local coolDown = 2
            if fuwenLevel1 > 0 then
                coolDown = coolDown - fuwenLevel1 * 0.2
            end
            local rate = 20
            if fuwenLevel6 > 0 then
                rate = math.floor((100 + (fuwenLevel6 * 10)) / 100 * rate)
            end
            if math.random(1, 100) <= rate and htime.setupAndCheckCoolDown(sourceUnit, "秘技雾凇之箭", coolDown) then
                if fuwenLevel5 > 0 then
                    if math.random(1, 100) <= fuwenLevel5 * 2 then
                        htime.clearCoolDown(sourceUnit, "秘技雾凇之箭")
                    end
                end

                local damage = hunit.getZhushuxing(sourceUnit)
                if fuwenLevel3 > 0 then
                    damage = damage * (1 + 0.1 * fuwenLevel3)
                end
                damage = damage * (1 + 0.03 * level)
                if fuwenLevel2 > 0 then
                    hbuff.addStackAttrBuff(
                        CONST_DAMAGE_SRC.skill,
                        sourceUnit,
                        "雾凇之箭",
                        _attr({ skill_speed = "+" .. fuwenLevel2 * 0.5 }),
                        5,
                        3,
                        "ReplaceableTextures\\mijing\\wusongzhijian.blp",
                        "雾凇之箭|n获得" .. fuwenLevel2 * 0.5 .. "%的技能加速，持续5秒",
                        true
                    )
                end

                local fashe = function()
                    hskillMoban.missile({
                        model = "war3mapImported\\[Spell]_030.mdx",
                        scale = 1.0,
                        speed = 1000,
                        hover = 50,
                        sourceUnit = sourceUnit,
                        targetUnit = targetUnit,
                        target_face_dis = 50,
                        onEnd = function(_, _, endX, endY)
                            local finalDamage = damage
                            hskill.damage({
                                sourceUnit = sourceUnit,
                                targetUnit = targetUnit,
                                damage = finalDamage,
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.MOFA,
                                triggerSkill = hslk.n2i("AI技能模版"),
                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WATER },
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                shanghainame = "雾凇之箭"
                            })
                            if fuwenLevel7 > 0 then
                                hskill.heal(
                                    {
                                        healer = sourceUnit,
                                        healee = sourceUnit,
                                        heal = math.floor(hunit.getMaxLife(sourceUnit) * fuwenLevel7 * 0.2 /
                                            100),
                                        healType = HEAL_TYPE.SKILL
                                    }
                                )
                            end
                        end
                    })
                end
                fashe()
                if fuwenLevel4 > 0 and math.random(1, 100) < fuwenLevel4 * 5 then
                    htime.setTimeout(
                        0.1,
                        function(t)
                            fashe()
                        end
                    )
                end
            end
        end,
        fuwenStatus = {
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "降低技能CD" .. level * 0.2 .. "秒"
                end,
                currentLevel = 0,
                diaoluoFuben = { "丛林深处", "火焰之心" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "触发时额外增加技能加速" .. (0.5 * level) .. "%，最多叠加3层"
                end,
                currentLevel = 0,
                diaoluoFuben = { "月亮湖", "黑龙王子的巢穴" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "技能造成的伤害提高" .. (10 * level) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "王城监狱" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "技能有概率触发两次，概率为" .. (5 * level) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "血色军大营" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "该技能触发有概率不进入冷却，概率为" .. (level * 2) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "圣光大教堂" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "提高技能的触发概率为" .. math.floor((100 + (level * 10)) / 100 * 20) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "半人马营地" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "触发技能后恢复" .. (0.2 * level) .. "%的生命最大值"
                end,
                currentLevel = 0,
                diaoluoFuben = { "矮人地下城" },
            },
        },
    }, {
        name = "星辰炸弹",
        art = "ReplaceableTextures\\mijing\\xingchenzhadan.blp",
        expKey = "mjexpxczd",
        fuwenKey = "mjfwxczd",
        description = function(fuwen)
            local level = hfuwen.getMijilevel(fuwen)
            return "魔法伤害有概率对目标位置触发星辰炸弹，1秒后对其周围300码范围内的敌人造成" ..
                hcolor.green(tostring(100 + level * 9)) .. "%主属性的木系魔法伤害，CD15秒"
        end,
        currentExp = 0,
        maxLevel = 30,
        maxExp = 9999,
        isActive = false,
        isEquipped = false,
        attr_type = CONST_EVENT.damage,
        attr = function(evtData, fuwen)
            if evtData.damageType ~= DAMAGE_TYPE.MOFA then
                return
            end
            local level = hfuwen.getMijilevel(fuwen)
            local fuwenLevel1 = fuwen.fuwenStatus[1].currentLevel
            local fuwenLevel2 = fuwen.fuwenStatus[2].currentLevel
            local fuwenLevel3 = fuwen.fuwenStatus[3].currentLevel
            local fuwenLevel4 = fuwen.fuwenStatus[4].currentLevel
            local fuwenLevel5 = fuwen.fuwenStatus[5].currentLevel
            local fuwenLevel6 = fuwen.fuwenStatus[6].currentLevel
            local fuwenLevel7 = fuwen.fuwenStatus[7].currentLevel

            local sourceUnit = evtData.triggerUnit
            local targetUnit = evtData.targetUnit
            local coolDown = 15
            if fuwenLevel1 > 0 then
                coolDown = coolDown - fuwenLevel1
            end
            if htime.setupAndCheckCoolDown(sourceUnit, "秘技星辰炸弹", coolDown) then
                if fuwenLevel5 > 0 then
                    if math.random(1, 100) <= fuwenLevel5 * 2 then
                        htime.clearCoolDown(sourceUnit, "秘技星辰炸弹")
                    end
                end

                local damage = hunit.getZhushuxing(sourceUnit) * 3
                if fuwenLevel3 > 0 then
                    damage = damage * (1 + 0.1 * fuwenLevel3)
                end
                damage = damage * (1 + 0.03 * level)
                local tmpAttr
                if fuwenLevel6 > 0 then
                    tmpAttr = _attr({ fa_bao = "+" .. fuwenLevel6 * 5 })
                end
                local x, y = hunit.x(targetUnit), hunit.y(sourceUnit)

                if fuwenLevel2 > 0 then
                    hbuff.addStackAttrBuff(
                        CONST_DAMAGE_SRC.skill,
                        sourceUnit,
                        "星辰炸弹",
                        _attr({ fa_chuan = "+" .. fuwenLevel2 * 1.5 }),
                        5,
                        1,
                        "ReplaceableTextures\\mijing\\xingchenzhadan.blp",
                        "星辰炸弹|n获得" .. fuwenLevel2 * 1.5 .. "%的法术穿透，持续5秒",
                        true
                    )
                end

                local fashe = function()
                    heffect.xyz("war3mapImported\\Star bomb_stand.mdx", hunit.x(targetUnit), hunit.y(targetUnit),
                        hunit.z(targetUnit), 1, 1, 1, 1, 1)
                    if fuwenLevel7 > 0 then
                        hskill.heal(
                            {
                                healer = sourceUnit,
                                healee = sourceUnit,
                                heal = math.floor(hunit.getMaxLife(sourceUnit) * fuwenLevel7 /
                                    100),
                                healType = HEAL_TYPE.SKILL
                            }
                        )
                    end
                    htime.setTimeout(
                        1,
                        function(t)
                            heffect.xyz("war3mapImported\\Star bomb_death.mdx", hunit.x(targetUnit), hunit.y(targetUnit),
                                hunit.z(targetUnit), 0, 1, 1, 1, 1)
                            hskillMoban.radiusAOE(
                                x,
                                y,
                                sourceUnit,
                                300,
                                function(filterUnit)
                                    local finalDamage = damage
                                    hskill.damage({
                                        sourceUnit = sourceUnit,
                                        targetUnit = filterUnit,
                                        damage = finalDamage,
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.MOFA,
                                        triggerSkill = hslk.n2i("AI技能模版"),
                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                        shanghainame = "星辰炸弹",
                                        tmpAttr = tmpAttr
                                    })
                                end,
                                false,
                                true
                            )
                        end
                    )
                end
                fashe()
                if fuwenLevel4 > 0 and math.random(1, 100) < fuwenLevel4 * 5 then
                    htime.setTimeout(
                        0.1,
                        function(t)
                            fashe()
                        end
                    )
                end
            end
        end,
        fuwenStatus = {
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "降低技能CD" .. level .. "秒"
                end,
                currentLevel = 0,
                diaoluoFuben = { "丛林深处", "火焰之心" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "触发后增加" .. (1.5 * level) .. "%的法术穿透，持续5秒"
                end,
                currentLevel = 0,
                diaoluoFuben = { "月亮湖", "黑龙王子的巢穴" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "技能造成的伤害提高" .. (10 * level) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "王城监狱" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "技能有概率触发两次，概率为" .. (5 * level) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "血色军大营" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "该技能触发有概率不进入冷却，概率为" .. (level * 2) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "圣光大教堂" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "提高技能伤害额外暴击概率，概率为" .. (level * 5) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "半人马营地" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "触发技能后恢复" .. (level) .. "%的生命最大值"
                end,
                currentLevel = 0,
                diaoluoFuben = { "矮人地下城" },
            },
        },
    }, {
        name = "碎地猛击",
        art = "ReplaceableTextures\\mijing\\suidimengji.blp",
        expKey = "mjexpsdmj",
        fuwenKey = "mjfwsdmj",
        description = function(fuwen)
            local level = hfuwen.getMijilevel(fuwen)
            return "攻击有概率震击地面，对周围300吗范围内的敌人造成" .. hcolor.green(tostring(100 + level * 9)) .. "%攻击力的土系物理伤害，CD15秒"
        end,
        currentExp = 0,
        maxLevel = 30,
        maxExp = 9999,
        isActive = false,
        isEquipped = false,
        attr_type = CONST_EVENT.attack,
        attr = function(evtData, fuwen)
            local level = hfuwen.getMijilevel(fuwen)
            local fuwenLevel1 = fuwen.fuwenStatus[1].currentLevel
            local fuwenLevel2 = fuwen.fuwenStatus[2].currentLevel
            local fuwenLevel3 = fuwen.fuwenStatus[3].currentLevel
            local fuwenLevel4 = fuwen.fuwenStatus[4].currentLevel
            local fuwenLevel5 = fuwen.fuwenStatus[5].currentLevel
            local fuwenLevel6 = fuwen.fuwenStatus[6].currentLevel
            local fuwenLevel7 = fuwen.fuwenStatus[7].currentLevel

            local sourceUnit = evtData.triggerUnit
            local targetUnit = evtData.targetUnit
            local coolDown = 15
            if fuwenLevel1 > 0 then
                coolDown = coolDown - fuwenLevel1
            end
            if htime.setupAndCheckCoolDown(sourceUnit, "秘技碎地猛击", coolDown) then
                if fuwenLevel5 > 0 then
                    if math.random(1, 100) <= fuwenLevel5 * 2 then
                        htime.clearCoolDown(sourceUnit, "秘技碎地猛击")
                    end
                end


                local damage = hattr.getWithLimit(sourceUnit, nil, "attack", 100) * 3
                if fuwenLevel3 > 0 then
                    damage = damage * (1 + 0.1 * fuwenLevel3)
                end
                damage = damage * (1 + 0.03 * level)
                local tmpAttr
                if fuwenLevel6 > 0 then
                    tmpAttr = _attr({ fa_bao = "+" .. fuwenLevel6 * 5 })
                end
                local x, y = hunit.x(targetUnit), hunit.y(sourceUnit)

                if fuwenLevel2 > 0 then
                    hbuff.addStackAttrBuff(
                        CONST_DAMAGE_SRC.skill,
                        sourceUnit,
                        "碎地猛击",
                        _attr({ wu_chuan = "+" .. fuwenLevel2 * 1.5 }),
                        5,
                        1,
                        "ReplaceableTextures\\mijing\\suidimengji.blp",
                        "碎地猛击|n获得" .. fuwenLevel2 * 1.5 .. "%的物理穿透，持续5秒",
                        true
                    )
                end

                local fashe = function()
                    htime.setTimeout(
                        1,
                        function(t)
                            if fuwenLevel7 > 0 then
                                hskill.heal(
                                    {
                                        healer = sourceUnit,
                                        healee = sourceUnit,
                                        heal = math.floor(hunit.getMaxLife(sourceUnit) * fuwenLevel7 /
                                            100),
                                        healType = HEAL_TYPE.SKILL
                                    }
                                )
                            end
                            heffect.xyz(
                                "war3mapImported\\[zhanshi]jianta.MDX",
                                hunit.x(sourceUnit),
                                hunit.y(sourceUnit),
                                hunit.z(sourceUnit),
                                0,
                                1
                            )
                            hsound.voice2Unit(
                                hsound.voiceCreate("resource\\war3mapImported\\sound\\3349.mp3", 1000, true),
                                80,
                                sourceUnit
                            )
                            hskillMoban.radiusAOE(
                                x,
                                y,
                                sourceUnit,
                                300,
                                function(filterUnit)
                                    local finalDamage = damage
                                    hskill.damage({
                                        sourceUnit = sourceUnit,
                                        targetUnit = filterUnit,
                                        damage = finalDamage,
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.WULI,
                                        triggerSkill = hslk.n2i("AI技能模版"),
                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                        shanghainame = "碎地猛击",
                                        tmpAttr = tmpAttr
                                    })
                                end,
                                false,
                                true
                            )
                        end
                    )
                end
                fashe()
                if fuwenLevel4 > 0 and math.random(1, 100) < fuwenLevel4 * 5 then
                    htime.setTimeout(
                        0.1,
                        function(t)
                            fashe()
                        end
                    )
                end
            end
        end,
        fuwenStatus = {
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "降低技能CD" .. level .. "秒"
                end,
                currentLevel = 0,
                diaoluoFuben = { "丛林深处", "火焰之心" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "触发后增加" .. (1.5 * level) .. "%的物理穿透，持续5秒"
                end,
                currentLevel = 0,
                diaoluoFuben = { "月亮湖", "黑龙王子的巢穴" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "技能造成的伤害提高" .. (10 * level) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "王城监狱" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "技能有概率触发两次，概率为" .. (5 * level) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "血色军大营" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "该技能触发有概率不进入冷却，概率为" .. (level * 2) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "圣光大教堂" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "提高技能伤害额外暴击概率，概率为" .. (level * 5) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "半人马营地" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "触发技能后恢复" .. (level) .. "%的生命最大值"
                end,
                currentLevel = 0,
                diaoluoFuben = { "矮人地下城" },
            },
        },
    }, {
        name = "刺骨剑气",
        art = "ReplaceableTextures\\mijing\\cigujianqi.blp",
        expKey = "mjexpcgjq",
        fuwenKey = "mjfwcgjq",
        description = function(fuwen)
            local level = hfuwen.getMijilevel(fuwen)
            return "攻击时若敌方单位距离冒险者400码范围以内，则有概率发射剑气攻击目标，对敌人造成" ..
                hcolor.green(tostring(100 + level * 3)) .. "%攻击力的金系物理伤害，CD2秒"
        end,
        currentExp = 0,
        maxLevel = 30,
        maxExp = 9999,
        isActive = false,
        isEquipped = false,
        attr_type = CONST_EVENT.attack,
        attr = function(evtData, fuwen)
            local level = hfuwen.getMijilevel(fuwen)
            local fuwenLevel1 = fuwen.fuwenStatus[1].currentLevel
            local fuwenLevel2 = fuwen.fuwenStatus[2].currentLevel
            local fuwenLevel3 = fuwen.fuwenStatus[3].currentLevel
            local fuwenLevel4 = fuwen.fuwenStatus[4].currentLevel
            local fuwenLevel5 = fuwen.fuwenStatus[5].currentLevel
            local fuwenLevel6 = fuwen.fuwenStatus[6].currentLevel
            local fuwenLevel7 = fuwen.fuwenStatus[7].currentLevel

            local sourceUnit = evtData.triggerUnit
            local targetUnit = evtData.targetUnit
            if hunit.isAlive(targetUnit) == false then
                return
            end
            if hunit.isAlive(sourceUnit) == false then
                return
            end
            if math.distance(hunit.x(sourceUnit), hunit.y(sourceUnit), hunit.x(targetUnit), hunit.y(targetUnit)) > 400 then
                return
            end
            local coolDown = 2
            if fuwenLevel1 > 0 then
                coolDown = coolDown - fuwenLevel1 * 0.2
            end
            local rate = 20
            if fuwenLevel6 > 0 then
                rate = math.floor((100 + (fuwenLevel6 * 10)) / 100 * rate)
            end
            if math.random(1, 100) <= rate and htime.setupAndCheckCoolDown(sourceUnit, "秘技刺骨剑气", coolDown) then
                if fuwenLevel5 > 0 then
                    if math.random(1, 100) <= fuwenLevel5 * 2 then
                        htime.clearCoolDown(sourceUnit, "秘技刺骨剑气")
                    end
                end

                local damage = hattr.getWithLimit(sourceUnit, nil, "attack", 100) * 1
                if fuwenLevel3 > 0 then
                    damage = damage * (1 + 0.1 * fuwenLevel3)
                end
                damage = damage * (1 + 0.03 * level)
                if fuwenLevel2 > 0 then
                    hbuff.addStackAttrBuff(
                        CONST_DAMAGE_SRC.skill,
                        sourceUnit,
                        "刺骨剑气",
                        _attr({ attack_speed = "+" .. fuwenLevel2 }),
                        5,
                        3,
                        "ReplaceableTextures\\mijing\\cigujianqi.blp",
                        "刺骨剑气|n获得" .. fuwenLevel2 .. "%的攻击加速，持续5秒",
                        true
                    )
                end

                local fashe = function()
                    heffect.xyz(
                        "war3mapImported\\[Spell]_002.mdx",
                        hunit.x(sourceUnit),
                        hunit.y(sourceUnit),
                        hunit.z(sourceUnit),
                        0,
                        1,
                        0.7,
                        0.7,
                        0.7,
                        nil,
                        nil,
                        math.angle(
                            hunit.x(sourceUnit), hunit.y(sourceUnit),
                            hunit.x(targetUnit), hunit.y(targetUnit)
                        )
                    )
                    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\lianji.wav", 1000, true),
                        80, sourceUnit)
                    local finalDamage = damage
                    hskill.damage({
                        sourceUnit = sourceUnit,
                        targetUnit = targetUnit,
                        damage = finalDamage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.WULI,
                        triggerSkill = hslk.n2i("AI技能模版"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                        shanghainame = "刺骨剑气"
                    })
                    if fuwenLevel7 > 0 then
                        hskill.heal(
                            {
                                healer = sourceUnit,
                                healee = sourceUnit,
                                heal = math.floor(hunit.getMaxLife(sourceUnit) * fuwenLevel7 * 0.2 /
                                    100),
                                healType = HEAL_TYPE.SKILL
                            }
                        )
                    end
                end
                fashe()
                if fuwenLevel4 > 0 and math.random(1, 100) < fuwenLevel4 * 5 then
                    htime.setTimeout(
                        0.1,
                        function(t)
                            fashe()
                        end
                    )
                end
            end
        end,
        fuwenStatus = {
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "降低技能CD" .. level * 0.2 .. "秒"
                end,
                currentLevel = 0,
                diaoluoFuben = { "丛林深处", "火焰之心" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "触发时额外增加攻击加速" .. (level) .. "%，最多叠加3层"
                end,
                currentLevel = 0,
                diaoluoFuben = { "月亮湖", "黑龙王子的巢穴" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "技能造成的伤害提高" .. (10 * level) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "王城监狱" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "技能有概率触发两次，概率为" .. (5 * level) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "血色军大营" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "该技能触发有概率不进入冷却，概率为" .. (level * 2) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "圣光大教堂" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "提高技能的触发概率为" .. math.floor((100 + (level * 10)) / 100 * 20) .. "%"
                end,
                currentLevel = 0,
                diaoluoFuben = { "半人马营地" },
            },
            {
                description = function(fuwenLevel)
                    local level = math.max(1, fuwenLevel)
                    return "触发技能后恢复" .. (0.2 * level) .. "%的生命最大值"
                end,
                currentLevel = 0,
                diaoluoFuben = { "矮人地下城" },
            },
        },
    } }
    local dropConfig = {}
    local LevelOneDropRate = {
        [1] = { [1] = 1000, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [2] = { [1] = 1100, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [3] = { [1] = 1200, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [4] = { [1] = 1300, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [5] = { [1] = 1400, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [6] = { [1] = 1600, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [7] = { [1] = 1800, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [8] = { [1] = 2000, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [9] = { [1] = 2200, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [10] = { [1] = 2400, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },

        -- 11到20级：爆等级1到2的符文
        [11] = { [1] = 2600, [2] = 260, [3] = 0, [4] = 0, [5] = 0 },
        [12] = { [1] = 2800, [2] = 280, [3] = 0, [4] = 0, [5] = 0 },
        [13] = { [1] = 3000, [2] = 300, [3] = 0, [4] = 0, [5] = 0 },
        [14] = { [1] = 3200, [2] = 320, [3] = 0, [4] = 0, [5] = 0 },
        [15] = { [1] = 3400, [2] = 340, [3] = 0, [4] = 0, [5] = 0 },
        [16] = { [1] = 3700, [2] = 370, [3] = 0, [4] = 0, [5] = 0 },
        [17] = { [1] = 4000, [2] = 400, [3] = 0, [4] = 0, [5] = 0 },
        [18] = { [1] = 4300, [2] = 430, [3] = 0, [4] = 0, [5] = 0 },
        [19] = { [1] = 4600, [2] = 460, [3] = 0, [4] = 0, [5] = 0 },
        [20] = { [1] = 4900, [2] = 490, [3] = 0, [4] = 0, [5] = 0 },

        -- 21到30级：爆等级1到3的符文
        [21] = { [1] = 5200, [2] = 520, [3] = 30, [4] = 0, [5] = 0 },
        [22] = { [1] = 5500, [2] = 550, [3] = 31, [4] = 0, [5] = 0 },
        [23] = { [1] = 5800, [2] = 580, [3] = 32, [4] = 0, [5] = 0 },
        [24] = { [1] = 6100, [2] = 610, [3] = 33, [4] = 0, [5] = 0 },
        [25] = { [1] = 6400, [2] = 640, [3] = 34, [4] = 0, [5] = 0 },
        [26] = { [1] = 6900, [2] = 690, [3] = 35, [4] = 0, [5] = 0 },
        [27] = { [1] = 7400, [2] = 740, [3] = 36, [4] = 0, [5] = 0 },
        [28] = { [1] = 7900, [2] = 790, [3] = 37, [4] = 0, [5] = 0 },
        [29] = { [1] = 8400, [2] = 840, [3] = 38, [4] = 0, [5] = 0 },
        [30] = { [1] = 8900, [2] = 890, [3] = 39, [4] = 0, [5] = 0 },
    }
    dropConfig["丛林深处"] = LevelOneDropRate
    dropConfig["月亮湖"] = LevelOneDropRate
    dropConfig["王城监狱"] = LevelOneDropRate
    dropConfig["血色军大营"] = LevelOneDropRate
    dropConfig["圣光大教堂"] = LevelOneDropRate
    dropConfig["半人马营地"] = LevelOneDropRate
    dropConfig["矮人地下城"] = LevelOneDropRate
    local LevelTwoDropRate = {
        [1] = { [1] = 1000, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [2] = { [1] = 1100, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [3] = { [1] = 1200, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [4] = { [1] = 1300, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [5] = { [1] = 1400, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [6] = { [1] = 1600, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [7] = { [1] = 1800, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [8] = { [1] = 2000, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [9] = { [1] = 2200, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [10] = { [1] = 2400, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },

        -- 11到20级：爆等级1到2的符文
        [11] = { [1] = 2600, [2] = 520, [3] = 102, [4] = 0, [5] = 0 },
        [12] = { [1] = 2800, [2] = 560, [3] = 112, [4] = 0, [5] = 0 },
        [13] = { [1] = 3000, [2] = 600, [3] = 120, [4] = 0, [5] = 0 },
        [14] = { [1] = 3200, [2] = 640, [3] = 128, [4] = 0, [5] = 0 },
        [15] = { [1] = 3400, [2] = 680, [3] = 136, [4] = 0, [5] = 0 },
        [16] = { [1] = 3700, [2] = 740, [3] = 178, [4] = 0, [5] = 0 },
        [17] = { [1] = 4000, [2] = 800, [3] = 160, [4] = 0, [5] = 0 },
        [18] = { [1] = 4300, [2] = 860, [3] = 172, [4] = 0, [5] = 0 },
        [19] = { [1] = 4600, [2] = 920, [3] = 184, [4] = 0, [5] = 0 },
        [20] = { [1] = 4900, [2] = 980, [3] = 196, [4] = 0, [5] = 0 },

        -- 21到30级：爆等级1到3的符文
        [21] = { [1] = 5200, [2] = 1040, [3] = 208, [4] = 30, [5] = 0 },
        [22] = { [1] = 5500, [2] = 1100, [3] = 220, [4] = 32, [5] = 0 },
        [23] = { [1] = 5800, [2] = 1160, [3] = 232, [4] = 34, [5] = 0 },
        [24] = { [1] = 6100, [2] = 1220, [3] = 244, [4] = 36, [5] = 0 },
        [25] = { [1] = 6400, [2] = 1280, [3] = 256, [4] = 38, [5] = 0 },
        [26] = { [1] = 6900, [2] = 1380, [3] = 276, [4] = 40, [5] = 0 },
        [27] = { [1] = 7400, [2] = 1480, [3] = 296, [4] = 42, [5] = 0 },
        [28] = { [1] = 7900, [2] = 1580, [3] = 316, [4] = 44, [5] = 0 },
        [29] = { [1] = 8400, [2] = 1680, [3] = 336, [4] = 46, [5] = 0 },
        [30] = { [1] = 8900, [2] = 1780, [3] = 356, [4] = 50, [5] = 0 },
    }
    dropConfig["火焰之心"] = LevelTwoDropRate
    dropConfig["黑龙王子的巢穴"] = LevelTwoDropRate
    dropConfig["法师塔"] = LevelTwoDropRate
    dropConfig["屠龙者的巢穴"] = LevelTwoDropRate
    dropConfig["破碎大厅"] = LevelTwoDropRate
    local LevelThreeDropRate = {
        [1] = { [1] = 1000, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [2] = { [1] = 1100, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [3] = { [1] = 1200, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [4] = { [1] = 1300, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [5] = { [1] = 1400, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [6] = { [1] = 1600, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [7] = { [1] = 1800, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [8] = { [1] = 2000, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [9] = { [1] = 2200, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        [10] = { [1] = 2400, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },

        -- 11到20级：爆等级1到2的符文
        [11] = { [1] = 2600, [2] = 1040, [3] = 208, [4] = 30, [5] = 0 },
        [12] = { [1] = 2800, [2] = 1100, [3] = 220, [4] = 31, [5] = 0 },
        [13] = { [1] = 3000, [2] = 1160, [3] = 232, [4] = 32, [5] = 0 },
        [14] = { [1] = 3200, [2] = 1220, [3] = 244, [4] = 33, [5] = 0 },
        [15] = { [1] = 3400, [2] = 1280, [3] = 256, [4] = 34, [5] = 0 },
        [16] = { [1] = 3700, [2] = 1380, [3] = 276, [4] = 35, [5] = 0 },
        [17] = { [1] = 4000, [2] = 1480, [3] = 296, [4] = 36, [5] = 0 },
        [18] = { [1] = 4300, [2] = 1580, [3] = 316, [4] = 37, [5] = 0 },
        [19] = { [1] = 4600, [2] = 1780, [3] = 336, [4] = 38, [5] = 0 },
        [20] = { [1] = 4900, [2] = 1880, [3] = 356, [4] = 39, [5] = 0 },

        -- 21到30级：爆等级1到3的符文
        [21] = { [1] = 5200, [2] = 1940, [3] = 392, [4] = 40, [5] = 1 },
        [22] = { [1] = 5500, [2] = 2000, [3] = 412, [4] = 41, [5] = 2 },
        [23] = { [1] = 5800, [2] = 2060, [3] = 432, [4] = 42, [5] = 3 },
        [24] = { [1] = 6100, [2] = 2120, [3] = 452, [4] = 43, [5] = 4 },
        [25] = { [1] = 6400, [2] = 2180, [3] = 472, [4] = 44, [5] = 5 },
        [26] = { [1] = 6900, [2] = 2280, [3] = 492, [4] = 45, [5] = 6 },
        [27] = { [1] = 7400, [2] = 2380, [3] = 512, [4] = 46, [5] = 7 },
        [28] = { [1] = 7900, [2] = 2480, [3] = 532, [4] = 47, [5] = 8 },
        [29] = { [1] = 8400, [2] = 2580, [3] = 552, [4] = 48, [5] = 9 },
        [30] = { [1] = 8900, [2] = 2680, [3] = 572, [4] = 49, [5] = 10 },
    }
    dropConfig["风暴要塞"] = LevelThreeDropRate
    hfuwen.initFromConfig(fuwenConfig, dropConfig)
end
