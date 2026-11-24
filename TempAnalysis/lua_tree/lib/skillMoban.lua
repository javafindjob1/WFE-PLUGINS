hskillMoban = {}

--赋予单位一个光环技能
function hskillMoban.guanghuan(whichUnit, skillID, radius, attr, isAlly, isPositive, description, event, action)
    if radius > 2000 then
        radius = 2000
    end
    if hcache.get(whichUnit, "GUANGHUAN_" .. skillID, nil) ~= nil then
        return
    end
    local timer =
        htime.setInterval(
            1,
            function(curTimer)
                if hunit.isDestroyed(whichUnit) == true or hskill.hasActiveAbility(whichUnit, skillID) == false then
                    curTimer.destroy()
                    return
                end
                if hunit.isAlive(whichUnit) == false then
                    return
                end
                local group =
                    hgroup.createByXY(
                        hunit.x(whichUnit),
                        hunit.y(whichUnit),
                        radius,
                        function(filterUnit)
                            if isAlly then
                                return hunit.isAlly(whichUnit, filterUnit)
                            else
                                return hunit.isAlly(whichUnit, filterUnit) == false
                            end
                        end
                    )
                for _, unit in ipairs(group) do
                    if hbuff.hasBuff(unit, skillID) == false then
                        hbuff.update(
                            0,
                            unit,
                            skillID,
                            isPositive,
                            function()
                                hattribute.caleAttribute(CONST_DAMAGE_SRC.skill, true, unit, attr, 1)
                                if event ~= nil and action ~= nil then
                                    hevent.register(unit, event, "guanghuan_jineng" .. skillID, action)
                                end
                            end,
                            function()
                                hattribute.caleAttribute(CONST_DAMAGE_SRC.skill, false, unit, attr, 1)
                                if event ~= nil and action ~= nil then
                                    hevent.unregister(unit, event, "guanghuan_jineng" .. skillID)
                                end
                            end,
                            hslk.i2v(skillID, "Art"),
                            description,
                            1,
                            1,
                            function(_)
                                local tmpGroup =
                                    hgroup.createByXY(
                                        hunit.x(unit),
                                        hunit.y(unit),
                                        radius,
                                        function(filterUnit)
                                            if
                                                hunit.isDestroyed(filterUnit) or
                                                hskill.hasActiveAbility(filterUnit, skillID) == false or
                                                hunit.isDead(filterUnit)
                                            then
                                                return false
                                            end
                                            if isAlly then
                                                return hunit.isAlly(unit, filterUnit)
                                            else
                                                return hunit.isAlly(unit, filterUnit) == false
                                            end
                                        end
                                    )
                                if #tmpGroup == 0 then
                                    hbuff.delete(unit, skillID)
                                end
                            end,
                            nil,
                            nil,
                            HBUFF_UPDATE_MODE.CREATE_ONLY
                        )
                    end
                end
            end
        )
    hcache.set(whichUnit, "GUANGHUAN_" .. skillID, timer)
end

--[[
    剃(前冲型直线攻击)
    options = {
        arrowAttachModel = nil, -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
        arrowUnit = nil, -- 前冲的单位不替换马甲模型（有就是自身冲击，没有就是马甲特效冲击）
        animation = nil, -- 单位动画
        sourceUnit, --伤害来源（必须有！不管有没有伤害）
        targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
        x, --冲击的x坐标（可选的，对点冲击，与某目标无关）
        y, --冲击的y坐标（可选的，对点冲击，与某目标无关）
        speed = 10, --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
        acceleration = 0, --冲击加速度（可选的，每个周期都会增加0.02秒一次)
        height = 0, --飞跃高度（可选的，默认0)
        shake = 0, --摇摆振幅角度[-90~+90|random]（可选的，默认0)
        filter = [function], --必须有
        tokenX, --强制设定token初始创建的x坐标（可选的，同时设定tokenY时才有效）
        tokenY, --强制设定token初始创建的y坐标（可选的，同时设定tokenX时才有效）
        tokenArrow = nil, --前冲的特效（arrowUnit=nil时认为必须！自身冲击就是bind，否则为马甲本身，如冲击波的波）
        tokenArrowScale = 1.00, --前冲的特效作为马甲冲击时的模型缩放
        tokenArrowOpacity = 1.00, --前冲的特效作为马甲冲击时的模型透明度[0-1]
        tokenArrowHeight = 0.00, --前冲的特效作为马甲冲击时的初始离地高度
        effectMovement = nil, --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
        animateMovement = "Walk", --移动过程 原始单位特效
        effectEnd = nil, --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
        damageMovement = 0, --移动过程中的伤害（可选的，默认为0）
        damageMovementRadius = 0, --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
        damageMovementRepeat = false, --移动过程中伤害是否可以重复造成（可选的，默认为不能）
        damageMovementDrag = false, --移动过程是否拖拽敌人（可选的，默认为不能）
        damageEnd = 0, --移动结束时对目标的伤害（可选的，默认为0）
        damageEndRadius = 0, --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
        damageSrc = CONST_DAMAGE_SRC, --伤害的种类（可选）
        damageEffect = nil, --伤害特效（可选）
        oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事）
        damageType = nil, --伤害类型（可选）
        damageSkill = nil, --伤害技能（可选）
        onEnding = [function], --结束时触发的动作
        extraInfluence = [function], --对选中的敌人的额外影响，会回调该敌人单位，可以对其做出自定义行为
        moveEffect = nil, --移动过程中callback
        moveEffectInterval = 0.02, --移动过程中callback间隔
        moveEffectDistance = 0, --移动过程中callback间隔距离
        endDistance = 0, 当距离小于endDistance的时候就停止
        ttl = 0, --持续时间 超过持续时间时间end
        leftAttach = nil,
        rightAttach = nil,
        unbindWhenEnd = false,
        damageElementType = nil,
        damageSpeedType = nil,
        otherAttach = nil,
        onStart = nil,
    }
]]
---@param options pilotLeap
function hskillMoban.leap(options)
    if (options.sourceUnit == nil) then
        err("leap: -sourceUnit")
        return
    end
    if (type(options.filter) ~= "function") then
        err("leap: -filter")
        return
    end
    if (options.arrowUnit == nil and options.tokenArrow == nil and options.arrowAttachModel == nil) then
        err("leap: -not arrow")
    end
    if (options.targetUnit == nil and options.x == nil and options.y == nil) then
        err("leap: -target")
        return
    end
    if (options.targetUnit ~= nil and hunit.isDestroyed(options.targetUnit)) then
        return
    end

    if (options.arrowUnit ~= nil and hcache.get(options.arrowUnit, "crackFlying", false)) then
        return
    end
    hcache.set(options.arrowUnit, "crackFlying", true)

    local rect = hcache.get(hunit.getOwner(options.sourceUnit), CONST_CACHE.UNIT_RECT)
    if rect == nil then
        rect = hunit.getRect(options.sourceUnit)
    end
    local frequency = 0.02
    local acceleration = options.acceleration or 0
    local height = options.height or 0
    local shake = options.shake or 0
    if (type(shake) == "number") then
        if (shake > 90) then
            shake = 90  -- 最大偏振角度
        elseif (shake < -90) then
            shake = -90 -- 最小偏振角度
        end
    end
    local speed = options.speed or 10
    if (speed > 150) then
        speed = 150 -- 最大速度
    elseif (speed <= 1) then
        speed = 1   -- 最小速度
    end
    local filter = options.filter
    local sourceUnit = options.sourceUnit
    local prevUnit = options.prevUnit or sourceUnit
    local damageMovement = options.damageMovement or 0
    local damageMovementRadius = options.damageMovementRadius or 0
    local damageMovementRepeat = options.damageMovementRepeat or false
    local damageMovementDrag = options.damageMovementDrag or false
    local damageEnd = options.damageEnd or 0
    local damageEndRadius = options.damageEndRadius or 0
    local extraInfluence = options.extraInfluence
    local arrowUnit = options.arrowUnit
    local tokenArrow = options.tokenArrow
    local tokenArrowScale = options.tokenArrowScale or 1.00
    local tokenArrowOpacity = options.tokenArrowOpacity or 1.00
    local tokenArrowHeight = options.tokenArrowHeight or 0
    local oneHitOnly = options.oneHitOnly or false
    local lastMovePointX = nil
    local lastMovePointY = nil
    local speedModifierWhenExtrImpact = options.speedModifierWhenExtrImpact
    local colorBuff
    local distanceOrigin
    --这里要注意：targetUnit比xy优先
    local leapType
    local initFacing = 0
    if (options.arrowUnit ~= nil) then
        leapType = "unit"
    else
        leapType = "point"
    end
    if (options.targetUnit ~= nil) then
        initFacing =
            math.angle(hunit.x(prevUnit), hunit.y(prevUnit), hunit.x(options.targetUnit), hunit.y(options.targetUnit))
        distanceOrigin =
            math.distance(
                hunit.x(prevUnit),
                hunit.y(prevUnit),
                hunit.x(options.targetUnit),
                hunit.y(options.targetUnit)
            )
    elseif (options.x ~= nil and options.y ~= nil) then
        initFacing = math.angle(hunit.x(prevUnit), hunit.y(prevUnit), options.x, options.y)
        distanceOrigin = math.distance(hunit.x(prevUnit), hunit.y(prevUnit), options.x, options.y)
    else
        err("leapType: -unknow")
        return
    end
    local repeatGroup
    if ((damageMovement > 0 or options.extraInfluence ~= nil) and damageMovementRepeat ~= true) then
        repeatGroup = {}
    end
    if (arrowUnit == nil) then
        local cx, cy
        if (options.tokenX and options.tokenY) then
            cx, cy = options.tokenX, options.tokenY
        else
            cx, cy = math.polarProjection(hunit.x(prevUnit), hunit.y(prevUnit), 100, initFacing)
        end
        arrowUnit =
            hunit.create(
                {
                    register = false,
                    whichPlayer = hunit.getOwner(sourceUnit),
                    id = HL_ID.unit_token_leap,
                    x = cx,
                    y = cy,
                    facing = initFacing,
                    modelScale = tokenArrowScale,
                    opacity = tokenArrowOpacity,
                    qty = 1
                }
            )
        if (tokenArrowHeight > 0) then
            hunit.setFlyHeight(arrowUnit, tokenArrowHeight, 9999)
        end
    end
    local heightOrigin = hunit.getFlyHeight(arrowUnit)
    hjapi.EXSetUnitFacing(arrowUnit, initFacing)
    --绑定一个无限的effect
    local tempEffectArrow
    if (tokenArrow ~= nil) then
        tempEffectArrow = heffect.attach(tokenArrow, arrowUnit, "origin", -1)
    end

    local leftAttach
    local rightAttach
    local otherAttach = {}

    if (options.arrowAttachModel ~= nil) then
        --tempEffectArrow = heffect.attach(tokenArrow, arrowUnit, "origin", -1)

        hjapi.DzSetUnitModel(arrowUnit, options.arrowAttachModel)
        if options.leftAttach ~= nil then
            leftAttach = heffect.attach(options.leftAttach, arrowUnit, "hand left", -1)
        end
        if options.rightAttach ~= nil then
            rightAttach = heffect.attach(options.rightAttach, arrowUnit, "hand right", -1)
        end
        if options.otherAttach ~= nil then
            for _, v in ipairs(options.otherAttach) do
                local attach = heffect.attach(v[1], arrowUnit, v[2], -1)
                table.insert(otherAttach, attach)
            end
        end
    end
    -- 无敌加无路径
    cj.SetUnitPathing(arrowUnit, false)
    if (leapType == "unit") then
        --hunit.setInvulnerable(arrowUnit, true)
        colorBuff = hunit.setRGBA(arrowUnit, nil, nil, nil, tokenArrowOpacity)
    end
    local timePassed = 0
    -- 结束！
    local ending = function(endX, endY, timePassed)
        if options.arrowUnit ~= nil then
            hcache.set(options.arrowUnit, "crackFlying", false)
        end
        if tempEffectArrow ~= nil then
            heffect.destroy(tempEffectArrow)
        end
        if otherAttach ~= nil then
            for _, v in ipairs(otherAttach) do
                heffect.destroy(v)
            end
        end
        if (options.arrowAttachModel ~= nil) then
            hjapi.DzSetUnitModel(arrowUnit, "hLua\\token.mdx")
        end
        if (leftAttach ~= nil) then
            heffect.destroy(leftAttach)
        end
        if (rightAttach ~= nil) then
            heffect.destroy(rightAttach)
        end
        if (repeatGroup ~= nil) then
            repeatGroup = nil
        end
        if (tokenArrowHeight > 0) then
            hunit.setFlyHeight(arrowUnit, tokenArrowHeight, 9999)
        else
            hunit.setFlyHeight(arrowUnit, heightOrigin, 9999)
        end
        if (hunit.isAlive(arrowUnit)) then
            if (options.effectEnd ~= nil) then
                heffect.xyz(options.effectEnd, endX, endY, nil, 0)
            end
            if (damageEndRadius == 0 and options.targetUnit ~= nil) then
                if (damageEnd > 0) then
                    hskill.damage(
                        {
                            sourceUnit = options.sourceUnit,
                            targetUnit = options.targetUnit,
                            damage = damageEnd,
                            damageSrc = options.damageSrc,
                            effect = options.damageEffect,
                            damageType = options.damageType,
                            triggerSkill = options.damageSkill,
                            damageSpeedType = options.damageSpeedType,
                            damageElementType = options.damageElementType,
                            shanghainame = options.shanghainame,
                            tmpAttr = options.tmpAttr
                        }
                    )
                end
                if (type(extraInfluence) == "function") then
                    extraInfluence(options.targetUnit)
                end
            elseif (damageEndRadius > 0) then
                local g = hgroup.createByUnit(arrowUnit, damageEndRadius, filter)
                hgroup.forEach(
                    g,
                    function(eu)
                        if (damageEnd > 0) then
                            hskill.damage(
                                {
                                    sourceUnit = options.sourceUnit,
                                    targetUnit = eu,
                                    damage = damageEnd,
                                    damageSrc = options.damageSrc,
                                    damageType = options.damageType,
                                    triggerSkill = options.damageSkill,
                                    damageSpeedType = options.damageSpeedType,
                                    damageElementType = options.damageElementType,
                                    shanghainame = options.shanghainame,
                                    tmpAttr = options.tmpAttr
                                }
                            )
                        end
                        if (type(extraInfluence) == "function") then
                            extraInfluence(eu, hunit.x(arrowUnit), hunit.y(arrowUnit), hunit.z(arrowUnit))
                        end
                    end
                )
                g = nil
            end
        end
        if (leapType == "unit") then
            hunit.setInvulnerable(arrowUnit, false)
            cj.SetUnitPathing(arrowUnit, true)
            if (colorBuff) then
                hunit.delRGBA(arrowUnit, colorBuff)
            end
            if (hunit.isAlive(arrowUnit)) then
                hunit.portal(arrowUnit, endX, endY)
            end
        else
            hunit.kill(arrowUnit, 0)
        end
        if (type(options.onEnding) == "function") then
            options.onEnding(endX, endY, timePassed)
        end
    end
    if options.animation ~= nil then
        hunit.animate(arrowUnit, options.animation)
    end
    if options.onStart ~= nil then
        options.onStart(arrowUnit)
    end
    --开始冲鸭
    htime.setInterval(
        frequency,
        function(t)
            timePassed = timePassed + frequency
            local ax = hunit.x(arrowUnit)
            local ay = hunit.y(arrowUnit)
            if (hunit.isDead(sourceUnit)) or (rect ~= nil and hrect.isInner(rect, ax, ay) == false) then
                t.destroy()
                ending(ax, ay, timePassed)
                return
            end
            if options.ttl ~= nil and timePassed >= options.ttl then
                t.destroy()
                ending(ax, ay, timePassed)
                return
            end
            local tx = 0
            local ty = 0
            if (options.targetUnit ~= nil) then
                tx = hunit.x(options.targetUnit)
                ty = hunit.y(options.targetUnit)
            else
                tx = options.x
                ty = options.y
            end
            local sh = 0
            if (shake ~= 0) then
                if (shake == "random") then
                    shake = math.random(-90, 90)
                end
                local d = math.distance(hunit.x(arrowUnit), hunit.y(arrowUnit), tx, ty)
                sh = shake * d / distanceOrigin
            end
            local fac = math.angle(ax, ay, tx, ty) + sh
            local px, py = math.polarProjection(ax, ay, speed, fac)
            if (acceleration ~= 0) then
                speed = speed + acceleration
            end
            if
                (hrect.isBorderPlayable(px, py) == false) and
                (options.skipPathCheck or cj.IsTerrainPathable(px, py, PATHING_TYPE_WALKABILITY) == false)
            then
                hunit.portal(arrowUnit, px, py)
                hunit.portal(arrowUnit, px, py)
                if options.moveEffectDistance ~= nil and options.moveEffectDistance > 0 and options.moveEffect ~= nil then
                    local triggerMove = false
                    if lastMovePointX == nil or lastMovePointY == nil then
                        lastMovePointX = hunit.x(arrowUnit)
                        lastMovePointY = hunit.y(arrowUnit)
                        triggerMove = true
                    else
                        local distanceLast =
                            math.distance(lastMovePointX, lastMovePointY, hunit.x(arrowUnit), hunit.y(arrowUnit))
                        if distanceLast >= options.moveEffectDistance then
                            lastMovePointX = hunit.x(arrowUnit)
                            lastMovePointY = hunit.y(arrowUnit)
                            triggerMove = true
                        end
                    end
                    if triggerMove then
                        options.moveEffect(arrowUnit)
                    end
                end
            else
                speed = 0
            end
            cj.SetUnitFacing(arrowUnit, fac)
            if (options.effectMovement ~= nil) then
                heffect.xyz(options.effectMovement, px, py, nil, 0)
            end
            if (options.animateMovement ~= nil) then
                hunit.animate(arrowUnit, options.animateMovement)
            end
            if (damageMovementRadius > 0) then
                local g =
                    hgroup.createByUnit(
                        arrowUnit,
                        damageMovementRadius,
                        function(filterUnit)
                            local flag = filter(filterUnit)
                            if (damageMovementRepeat ~= true and hgroup.includes(repeatGroup, filterUnit)) then
                                flag = false
                            end
                            return flag
                        end
                    )
                if (hgroup.count(g) > 0) then
                    if (oneHitOnly == true and leapType ~= "unit") then
                        hunit.kill(arrowUnit, 0)
                    end
                    hgroup.forEach(
                        g,
                        function(eu)
                            if (damageMovementRepeat ~= true and repeatGroup ~= nil) then
                                hgroup.addUnit(repeatGroup, eu)
                            end
                            if (damageMovement > 0) then
                                hskill.damage(
                                    {
                                        sourceUnit = sourceUnit,
                                        targetUnit = eu,
                                        damage = damageMovement,
                                        damageSrc = options.damageSrc,
                                        effect = options.damageEffect,
                                        damageType = options.damageType,
                                        triggerSkill = options.damageSkill,
                                        shanghainame = options.shanghainame,
                                        tmpAttr = options.tmpAttr
                                    }
                                )
                            end
                            if (damageMovementDrag == true) then
                                hunit.portal(eu, px, py)
                            end
                            if (type(extraInfluence) == "function") then
                                extraInfluence(eu, px, py, hunit.z(arrowUnit))
                            end
                            if (type(speedModifierWhenExtrImpact) == "function") then
                                speed = speedModifierWhenExtrImpact(eu, speed)
                            end
                        end
                    )
                    g = nil
                end
            end
            local distance = math.distance(hunit.x(arrowUnit), hunit.y(arrowUnit), tx, ty)
            if (height > 0 and distance < distanceOrigin) then
                local half = distanceOrigin / 2
                local distoHalf = math.abs(distance - half)
                local newHeight = height * ((half * half - (distoHalf * distoHalf)) / (half * half)) + heightOrigin
                hunit.setFlyHeight(arrowUnit, newHeight, 9999)
            end
            if
                (distance <= speed or (options.endDistance ~= nil and distance < options.endDistance) or speed <= 0 or
                    hunit.isDead(arrowUnit) == true)
            then
                t.destroy()
                ending(px, py, timePassed)
            end
        end
    )
end

--[[
    虚拟箭矢
    model = nil, --[可须]虚拟箭矢的特效
    effect = nil, --[可选]虚拟箭矢的已经创建的特效
    animateScale = 1.00, --虚拟箭矢的动画速度
    scale = 1.00, --虚拟箭矢的模型缩放
    hover = 0.00, --虚拟箭矢的初始离基点高度
    targetHover = 0.00, --虚拟箭矢的目标离基点高度
    target_face_dis = 0, --虚拟箭矢的初始沿触发单位方向的水平方向偏移,会覆盖start x和y
    target_face_left = 0, --虚拟箭矢的初始沿触发单位左手边的水平方向偏移,会覆盖start x和y
    speed = 500, --每秒冲击的距离（可选的，默认1秒500px)
    acceleration = 0, --冲击加速度（可选的，每个周期[0.02秒]都会增加一次)
    height = 0, --飞跃高度（可选的，默认0)
    hover = 0, -- 发射高度
    shake = 0, --摇摆振幅程度度[0.00~1.00|rand]（可选的，默认0)
    sourceUnit, --[必须]伤害来源
    targetUnit, --[可选]目标单位（有单位目标，那么冲击跟踪到单位就结束）
    targetX, --[可选]冲击的目标x坐标（对点冲击）比targetUnit优先级高
    targetY, --[可选]冲击的目标y坐标
    chauntouRate = 0, --穿透概率
    chuantouDistance = 0, --穿透距离
    maxChuantou = 0, --最大穿透次数
    ctssDistance = 0, --穿透后的间隔距离
    startX = [sourceUnit.x], --强制设定初始创建的x坐标（可选的，同时设定 startY 时才有效）
    startY = [sourceUnit.y], --强制设定初始创建的y坐标（可选的，同时设定 startX 时才有效）
    onMove = [function], --每周期移动回调,return false时可强行中止循环
    onEnd = [function], --结束回调
]]
---@alias noteAbilityMissileOnEvt fun(source:userdata,target:userdata,endX:number,endY:number):nil|boolean
---@alias noteAbilityMissileOptions {model:string,ctssDistance:number,maxChuantou:number,effect:userdata,chuantouDistance:number,chauntouRate:number,animateScale:number,scale:number,hover:number,target_face_dis:number, target_face_left:number, speed:number,acceleration:number,height:number,shake:number,sourceUnit:userdata,targetUnit:userdata,targetX:number,targetY:number,startX:number,startY:number,onMove:noteAbilityMissileOnEvt,onEnd:noteAbilityMissileOnEvt}
---@param options noteAbilityMissileOptions
function hskillMoban.missile(options)
    if (options.model == nil and options.effect == nil) then
        return err("model or effect")
    end
    local sourceUnit = options.sourceUnit
    local targetUnit = options.targetUnit
    if (sourceUnit == nil) then
        return err("sourceUnit")
    end
    local rect = hcache.get(hunit.getOwner(options.sourceUnit), CONST_CACHE.UNIT_RECT)
    if (options.targetX == nil or options.targetY == nil) then
        if (targetUnit == nil) then
            return err("targetUnit")
        end
    end
    local frequency = 0.02
    local speed = math.min(10000, math.max(50, options.speed or 500))
    local acceleration = options.acceleration or 0
    local height = options.height or 0
    local hover = options.hover or 0
    options.animateScale = options.animateScale or 1.00
    options.scale = options.scale or 1.00
    local fac0 = 0
    local dct0 = 0
    local sourceH = hover + hunit.z(sourceUnit)
    local targetH = 0
    if options.target_face_dis ~= nil or options.target_face_left ~= nil then
        options.target_face_dis = options.target_face_dis or 0
        options.target_face_left = options.target_face_left or 0
        local tmp_fac
        if (options.targetX ~= nil and options.targetY ~= nil) then
            tmp_fac = math.angle(hunit.x(sourceUnit), hunit.y(sourceUnit), options.targetX, options.targetY)
        else
            tmp_fac = math.angle(hunit.x(sourceUnit), hunit.y(sourceUnit), hunit.x(targetUnit), hunit.y(targetUnit))
        end
        options.startX =
            hunit.x(sourceUnit) + math.cos(tmp_fac / math_rad2deg) * options.target_face_dis +
            math.cos((tmp_fac + 90) / math_rad2deg) * options.target_face_left
        options.startY =
            hunit.y(sourceUnit) + math.sin(tmp_fac / math_rad2deg) * options.target_face_dis +
            math.sin((tmp_fac + 90) / math_rad2deg) * options.target_face_left
    end
    if (options.startX == nil or options.startY == nil) then
        options.startX, options.startY = math.polarProjection(hunit.x(sourceUnit), hunit.y(sourceUnit), 30, fac0)
        sourceH = sourceH + hunit.h(sourceUnit)
    end
    local targetHover = options.targetHover or hover
    if (options.targetX ~= nil and options.targetY ~= nil) then
        targetH = targetHover + hjapi.Z(options.targetX, options.targetY)
        fac0 = math.angle(hunit.x(sourceUnit), hunit.y(sourceUnit), options.targetX, options.targetY)
        dct0 = math.distance(hunit.x(sourceUnit), hunit.y(sourceUnit), options.targetX, options.targetY)
    else
        targetH = targetHover + hunit.h(targetUnit)
        fac0 = math.angle(hunit.x(sourceUnit), hunit.y(sourceUnit), hunit.x(targetUnit), hunit.y(targetUnit))
        dct0 = math.distance(hunit.x(sourceUnit), hunit.y(sourceUnit), hunit.x(targetUnit), hunit.y(targetUnit))
    end
    local arrowToken
    if options.model ~= nil then
        arrowToken = cj.AddSpecialEffect(options.model, options.startX, options.startY)
    else
        arrowToken = options.effect
    end
    hjapi.EXEffectMatRotateZ(arrowToken, fac0)
    hjapi.EXSetEffectSpeed(arrowToken, options.animateScale)
    hjapi.EXSetEffectSize(arrowToken, options.scale)
    local gsep = (dct0 / 2) / speed / frequency
    local midH
    local rotateY1 = 0
    local rotateY2 = 0
    local rotateY1i = 0
    local rotateY2i = 0
    local gravity1 = 0
    local gravity2 = 0
    local sd = (dct0 / speed / frequency / 2)
    local hd = (sourceH - targetH) / 2
    if (sourceH >= targetH) then
        midH = sourceH + height
    else
        midH = targetH + height
    end
    local chuantouRate = options.chauntouRate or 0
    local chuantouDistance = options.chuantouDistance or 0
    local postCTDistance = 0
    local maxChuantou = options.maxChuantou or 0
    local chuantouCount = 0
    local isChuantouing = false
    local ctssDistance = options.ctssDistance or 0
    rotateY1 = math_rad2deg * math.atan(midH - sourceH, dct0 / 2)
    rotateY1i = rotateY1 / sd
    rotateY2 = math_rad2deg * math.atan(midH - targetH, dct0 / 2)
    rotateY2i = rotateY2 / sd
    gravity1 = (midH - sourceH) / gsep
    gravity2 = (midH - targetH) / gsep
    local rotateY = -rotateY1
    if (fac0 > 90 and fac0 < 270) then
        rotateY = -rotateY
    end
    speed = frequency * speed
    hjapi.EXEffectMatRotateY(arrowToken, rotateY)
    hjapi.EXSetEffectZ(arrowToken, sourceH)
    local ending = function(endX, endY, isFinish)
        if (arrowToken ~= nil) then
            cj.DestroyEffect(arrowToken)
            arrowToken = nil
        end
        local res = isFinish
        if (res == true and type(options.onEnd) == "function") then
            res = options.onEnd(sourceUnit, targetUnit, endX, endY)
        end
    end
    local curH = sourceH
    local limit = 0
    local faraway = 0
    local prevDist
    local ax = hjapi.EXGetEffectX(arrowToken)
    local ay = hjapi.EXGetEffectY(arrowToken)
    local shake = options.shake
    local shakeDirect = 1
    if (shake == "rand") then
        shake = 0.01 * math.random(-100, 100)
    elseif (type(shake) == "number") then
        shake = math.min(1, math.max(0, shake))
    else
        shake = 0
    end
    if (math.random(1, 2) == 1) then
        shakeDirect = -1
    end
    htime.setInterval(
        frequency,
        function(curTimer)
            if
                (arrowToken == nil or hunit.isDestroyed(sourceUnit) or
                    (targetUnit ~= nil and hunit.isDestroyed(targetUnit)) or
                    (rect ~= nil and hrect.isInner(rect, ax, ay) == false))
            then
                curTimer.destroy()
                ending(ax, ay, false)
                return
            end
            local tx = 0
            local ty = 0
            local dct = 0
            if (options.targetX ~= nil and options.targetY ~= nil) then
                tx = options.targetX
                ty = options.targetY
                dct = dct0
            else
                tx = hunit.x(targetUnit)
                ty = hunit.y(targetUnit)
                dct = math.distance(options.startX, options.startY, hunit.x(targetUnit), hunit.y(targetUnit))
            end
            local fac
            if (shake ~= nil and shake ~= 0) then
                fac = math.angle(ax, ay, tx, ty) + shake * 75 * shakeDirect * math.distance(ax, ay, tx, ty) / dct
            else
                fac = math.angle(ax, ay, tx, ty)
            end
            local nx, ny = math.polarProjection(ax, ay, speed, fac)
            if (acceleration ~= 0) then
                speed = speed + acceleration
            end
            --if (hrect.isBorderCamera(nx, ny)) then
            --    curTimer.destroy()
            --    ending(ax, ay, false)
            --    return
            --end
            if (type(options.onMove) == "function") then
                local mRes = options.onMove(sourceUnit, targetUnit, nx, ny, arrowToken)
                if (mRes == false) then
                    curTimer.destroy()
                    ending(ax, ay, false)
                    return
                end
            end
            hjapi.EXSetEffectXY(arrowToken, nx, ny)
            hjapi.EXEffectMatRotateZ(arrowToken, fac - fac0)
            ax = nx
            ay = ny
            fac0 = fac
            local curD = math.distance(ax, ay, tx, ty)
            if (curD < dct) then
                local halfD = dct / 2
                local rot = 0
                local di = 2 * (math.disparity(curD, halfD) / halfD)
                local dg = di * (dct0 / dct)
                if (curD >= halfD) then
                    curH = curH + gravity1 * dg
                    rot = rotateY1i * (2 - di)
                else
                    curH = curH - gravity2 * dg
                    rot = rotateY2i * (2 - di)
                end
                if (fac0 > 90 and fac0 < 270) then
                    rot = -rot
                end
                hjapi.EXSetEffectZ(arrowToken, curH)
                hjapi.EXEffectMatRotateY(arrowToken, rot)
            end
            limit = limit + 1
            if (limit > 400 or sourceUnit == nil) then
                -- 超时消失
                curTimer.destroy()
                ending(nx, ny, false)
                return
            else
                -- 逃离消失
                if (prevDist ~= nil) then
                    if (prevDist < curD) then
                        faraway = faraway + 1
                        if (faraway > 50 or (curD - prevDist > speed * 10)) then
                            curTimer.destroy()
                            ending(nx, ny, false)
                            return
                        end
                    else
                        faraway = 0
                    end
                end
                prevDist = curD
            end
            if (curD <= speed or speed <= 0) then
                if isChuantouing == false and chuantouCount < maxChuantou and math.random(1, 100) <= chuantouRate then
                    if type(options.onEnd) == "function" then
                        options.onEnd(sourceUnit, targetUnit, ax, ay)
                    end
                    -- 穿透逻辑
                    chuantouCount = chuantouCount + 1
                    isChuantouing = true
                    postCTDistance = 0
                    -- 继续沿原方向飞行
                    options.targetX = ax + math.cos(fac0 * math.pi / 180) * chuantouDistance
                    options.targetY = ay + math.sin(fac0 * math.pi / 180) * chuantouDistance
                    targetUnit = nil
                    dct0 = chuantouDistance
                    -- 重置一些变量以便继续飞行
                    limit = 0
                    faraway = 0
                    prevDist = nil
                elseif isChuantouing then
                    -- 飞行完指定距离后寻找新目标
                    local newTarget = table.randomOne(hgroup.createEnermyGroupByXY(sourceUnit, ax, ay, ctssDistance, true))
                    if newTarget then
                        targetUnit = newTarget
                        options.targetX = nil
                        options.targetY = nil
                        dct0 = math.distance(ax, ay, hunit.x(targetUnit), hunit.y(targetUnit))
                        fac = math.angle(ax, ay, hunit.x(targetUnit), hunit.y(targetUnit))
                        hjapi.EXEffectMatRotateZ(arrowToken, fac - fac0)
                        fac0 = fac
                        -- 重置一些变量以便继续追踪
                        limit = 0
                        faraway = 0
                        prevDist = nil
                        isChuantouing = false -- 结束穿透状态
                    else
                        curTimer.destroy()
                        ending(ax, ay, true)
                    end
                else
                    curTimer.destroy()
                    ending(ax, ay, true)
                end
                if isChuantouing then
                    postCTDistance = postCTDistance + speed
                end
            end
        end
    )
end

--[[
    物理环绕
    model = nil, --[必须]环绕单位特效的特效
    animateScale = 1.00, --环绕单位的动画速度
    scale = 1.00, --环绕单位的模型缩放
    transparency = 1.00, --环绕单位的透明度
    dir = 1|2, -- 1顺时针还是2逆时针
    circleTime = 1.00, -- 环绕一次需要时间
    z = 0.00, --环绕单位的初始离基点高度
    dis = 0, -环绕单位的初始沿触发单位方向的水平方向偏移,会覆盖start x和y
    sourceUnit, --[必须]伤害来源
    startX = [sourceUnit.x], 强制设定初始创建的x坐标（可选的，同时设定 startY 时才有效）
    startY = [sourceUnit.y], 强制设定初始创建的y坐标（可选的，同时设定 startX 时才有效）
    onMove = [function], --每周期移动回调,return false时可强行中止循环
]]
---@alias noteAbilitywulihuanraoOnEvt fun(source:userdata,target:userdata,endX:number,endY:number):nil|boolean
---@alias noteAbilitywulihuanraoOptions {model:string,animateScale:number,zhaohuiDistance:number,transparency:number,scale:number,dir:number, circleTime:number, z:number,dis:number,sourceUnit:userdata,startX:number,startY:number,onMove:noteAbilitywulihuanraoOnEvt}
---@param options noteAbilitywulihuanraoOptions
function hskillMoban.wulihuanrao(options)
    if (options.model == nil) then
        return err("model is empty")
    end
    local sourceUnit = options.sourceUnit
    if (sourceUnit == nil) then
        return err("sourceUnit is empty")
    end
    local dir = 1
    if options.dir ~= nil and options.dir == 2 then
        dir = -1
    end
    local dis = options.dis
    if dis == nil then
        dis = 100
    end
    local x = hunit.x(sourceUnit)
    local y = hunit.y(sourceUnit)
    local z = options.z or hunit.z(sourceUnit)
    local face = hunit.getFacing(sourceUnit) + (dir * 90)
    local startx, starty = math.polarProjection(x, y, dis, hunit.getFacing(sourceUnit) - 180)

    local token = cj.AddSpecialEffect(options.model, startx, starty)
    hjapi.EXSetEffectSpeed(token, options.animateScale)
    hjapi.EXSetEffectSize(token, options.scale)
    hjapi.EXEffectMatRotateZ(token, face)
    hjapi.EXSetEffectZ(token, z)
    hjapi.DzSetEffectVertexAlpha(token, options.transparency * 255)

    local ending = function(endX, endY, isFinish)
        if (token ~= nil) then
            cj.DestroyEffect(token)
            token = nil
        end
        local res = isFinish
        if (res == true and type(options.onEnd) == "function") then
            res = options.onEnd(sourceUnit, endX, endY)
        end
    end
    local interval = 0.02
    local rotatePerInterval = 5 * 360 / options.circleTime * interval
    local disPerInterval = 2 * math_pi * dis / options.circleTime * interval

    local timer = htime.setInterval(
        interval,
        function(curTimer)
            local x = hjapi.EXGetEffectX(token)
            local y = hjapi.EXGetEffectY(token)

            local centerx = hunit.x(sourceUnit)
            local centery = hunit.y(sourceUnit)

            local cur_dis = math.distance(centerx, centery, x, y)
            if cur_dis >= (options.zhaohuiDistance or 800) then
                x, y = math.polarProjection(centerx, centery, dis, math.random(0, 360))
                hjapi.EXSetEffectXY(token, x, y)
            end
            if sourceUnit == nil or hunit.isAlive(sourceUnit) == false then
                curTimer.destroy()
                ending(sourceUnit, x, y)
                return
            end
            local cur_dis = math.distance(centerx, centery, x, y)
            local newAngel = math.angle(centerx, centery, x, y) - (dir * 90)
            if dis > cur_dis then
                if dir == 1 then
                    newAngel = newAngel + math_rad2deg * math.acos(cur_dis / dis)
                else
                    newAngel = newAngel - math_rad2deg * math.acos(cur_dis / dis)
                end
            else
                if dir == 1 then
                    newAngel = newAngel - math_rad2deg * math.acos(dis / cur_dis)
                else
                    newAngel = newAngel + math_rad2deg * math.acos(dis / cur_dis)
                end
            end
            if newAngel >= 360 then
                newAngel = newAngel - 360
            elseif newAngel < 0 then
                newAngel = newAngel + 360
            end
            if newAngel > face and newAngel - face <= 180 then
                if newAngel > face + rotatePerInterval then
                    newAngel = face + rotatePerInterval
                end
            elseif newAngel > face and newAngel - face > 180 then
                if face - rotatePerInterval < 0 and 360 + face - rotatePerInterval > newAngel then
                    newAngel = 360 + face - rotatePerInterval
                elseif face - rotatePerInterval >= 0 then
                    newAngel = face - rotatePerInterval
                end
            elseif newAngel < face and face - newAngel <= 180 then
                if newAngel < face - rotatePerInterval then
                    newAngel = face - rotatePerInterval
                end
            elseif newAngel < face and face - newAngel > 180 then
                if face + rotatePerInterval > 360 and face + rotatePerInterval - 360 < newAngel then
                    newAngel = face + rotatePerInterval - 360
                elseif face + rotatePerInterval <= 360 then
                    newAngel = face + rotatePerInterval
                end
            end
            local angelDiff = newAngel - face
            --echo("newAngel" .. newAngel .. "face" .. face .. "angelDiff" .. angelDiff)
            face = newAngel
            local finalx, finaly = math.polarProjection(x, y, disPerInterval, face)
            hjapi.EXSetEffectXY(token, finalx, finaly)
            hjapi.EXEffectMatRotateZ(token, angelDiff)
            hjapi.EXSetEffectZ(token, hunit.z(sourceUnit) + z)
            --echo(math.distance(finalx, finaly, centerx, centery))
        end
    )
    return token, timer
end

function hskillMoban.changfangxingFacingAOE(whichUnit, wide, length, damageFunc, skipSourceDeathCheck, impactWudi)
    if hunit.isDestroyed(whichUnit) then
        return
    end
    if (skipSourceDeathCheck ~= true and hunit.isDead(whichUnit)) then
        return
    end
    local farest = math.sqrt((wide / 2) ^ 2 + length ^ 2)
    local angle = hunit.getFacing(whichUnit)
    local group =
        hgroup.createByXY(
            hunit.x(whichUnit),
            hunit.y(whichUnit),
            farest,
            function(filterUnit)
                if
                    hunit.isAlly(whichUnit, filterUnit) or hunit.isDead(filterUnit) or hunit.isDestroyed(filterUnit) or
                    (impactWudi ~= true and hunit.isInvincible(filterUnit))
                then
                    return false
                else
                    local dx = hunit.x(filterUnit) - hunit.x(whichUnit)
                    local dy = hunit.y(filterUnit) - hunit.y(whichUnit)
                    local filterAngle = math.atan(dy, dx) * math_rad2deg
                    local angleDiff = math.abs(angle - filterAngle) % 360
                    local distance =
                        math.distance(hunit.x(whichUnit), hunit.y(whichUnit), hunit.x(filterUnit), hunit.y(filterUnit))
                    if angleDiff > 180 then
                        angleDiff = 360 - angleDiff
                    end

                    if angleDiff <= 90 then
                        local projectedDistance = distance * math.cos(angleDiff * math_deg2rad)

                        if
                            projectedDistance <= length and
                            math.abs(distance * math.sin(angleDiff * math_deg2rad)) <= wide / 2
                        then
                            return true
                        else
                            return false
                        end
                    else
                        return false
                    end
                end
            end
        )
    for _, target in ipairs(group) do
        damageFunc(target)
    end
end

---@private
local function _crackFlyEnding(isOK, options, point)
    if (options.effectAttach) then
        heffect.destroy(options.effectAttach)
    end
    local f0 = hcache.get(options.targetUnit, "crackFlyHeight0")
    hunit.setFlyHeight(options.targetUnit, f0, 1e4)
    cj.SetUnitPathing(options.targetUnit, true)
    local res = isOK
    if (res == true and type(options.onEnd) == "function") then
        res = options.onEnd(options.sourceUnit, options.targetUnit, point)
    end
    if (type(options.onEndAnyway) == "function") then
        res = options.onEndAnyway(options.sourceUnit, options.targetUnit, point)
    end
    hcache.set(options.targetUnit, "crackFlying", false)
    if (res == true and type(options.bounce) == "table") then
        local qty = options.bounce.qty or 0
        if (qty > 0) then
            local di = options.bounce.distance or 0.8
            local he = options.bounce.height or 0.8
            local du = options.bounce.duration or 0.8
            if (options.targetUnit ~= nil and hunit.isDestroyed(options.targetUnit) == false) then
                hskillMoban.crackFly(
                    {
                        sourceUnit = options.sourceUnit,
                        targetUnit = options.targetUnit,
                        model = options.model,
                        animate = options.animate,
                        animateScale = options.animateScale,
                        distance = options.distance * di,
                        height = options.height * he,
                        duration = options.duration * du,
                        bounce = { qty = qty - 1, distance = di, height = he, duration = du },
                        onMove = options.onMove,
                        onEnd = options.onEnd
                    }
                )
            end
        end
    end
end

--[[
    击飞
    sourceUnit = userdata, --[可选]伤害来源
    targetUnit = userdata, --[必须]目标单位
    model = nil, --[可选]目标单位飞行origin特效
    animate = "dead", --[可选]目标单位飞行动作或序号,默认无
    animateScale = 1.00, --[可选]目标单位飞行动画速度，默认1
    distance = 0, --[可选]击退距离，默认0
    height = 100, --[可选]飞跃高度，默认100
    duration = 0.5, --[必须]击飞过程持续时间，可选，默认0.5秒
    bounce = noteAbilityCrackFlyBounceParam, --[可选]弹跳参数，noteAbilityCrackFlyBounceParam
    onMove = noteAbilityCrackFlyOnEvt, --[可选]每周期回调,当return false时可强行中止循环
    onEnd = noteAbilityCrackFlyOnEvt, --[可选]结束回调,当return true时才会执行reflex
    onEndAnyway = noteAbilityCrackFlyOnEvt, --[可选]结束回调,无论是否成功都会执行
]]
---@alias noteAbilityCrackFlyBounceParam {qty:0, distance:0.8, height:0.8, duration:0.8} qty弹跳次数，后面三个为相对前1次的相乘变化率，默认0.8
---@alias noteAbilityCrackFlyOnEvt fun(sourceUnit:userdata,targetUnit:userdata,point:number[]):boolean
---@param options {sourceUnit:userdata,targetUnit:userdata,model:string,animate:number,animateScale:number,distance:number,height:number,bounce:noteAbilityCrackFlyBounceParam,duration:number,onMove:noteAbilityCrackFlyOnEvt,onEnd:noteAbilityCrackFlyOnEvt,onEndAnyway:noteAbilityCrackFlyOnEvt}
function hskillMoban.crackFly(options)
    local sourceUnit = options.sourceUnit
    local targetUnit = options.targetUnit
    if (targetUnit == nil or hunit.isDead(targetUnit)) then
        return
    end
    local distance = math.max(0, options.distance or 0)
    local height = options.height or 100
    local duration = options.duration or 0.5
    if (height <= 0 or duration < 0.1) then
        return
    end
    local ing = hcache.get(targetUnit, "crackFlying", false)
    if (ing == true) then
        if options.onEndAnyway then
            options.onEndAnyway(sourceUnit, targetUnit, { hunit.x(targetUnit), hunit.y(targetUnit) })
        end
        return
    end
    hcache.set(targetUnit, "crackFlying", true)
    hcache.set(targetUnit, "crackFlyHeight0", hunit.getFlyHeight(targetUnit))

    local frequency = 0.02
    if (options.animate) then
        hunit.animate(targetUnit, options.animate)
    end

    if (options.model) then
        options.effectAttach = heffect.attach(options.model, targetUnit, "origin", -1)
    end

    local fac0 = 0
    if (sourceUnit) then
        fac0 = math.angle(hunit.x(sourceUnit), hunit.y(sourceUnit), hunit.x(targetUnit), hunit.y(targetUnit))
    else
        fac0 = hunit.getFacing(targetUnit) - 180
    end
    local sPoint = { hunit.x(targetUnit), hunit.y(targetUnit), hunit.h(targetUnit) }
    local tx, ty = math.polarProjection(hunit.x(targetUnit), hunit.y(targetUnit), distance, fac0)
    local tPoint = { tx, ty, hunit.h(targetUnit) }

    local dtSpd = 1 / (duration / frequency)

    local mmid = math.distance(sPoint[1], sPoint[2], tPoint[1], tPoint[2])
    local mx, my = math.polarProjection(sPoint[1], sPoint[2], mmid, fac0)
    local mPoint = { mx, my, 1.5 * height }

    cj.SetUnitPathing(targetUnit, false)
    hunit.setCanFly(targetUnit)
    local dt = 0
    local cPoint
    htime.setInterval(
        frequency,
        function(curTimer)
            if (hunit.isDead(targetUnit)) then
                curTimer.destroy()
                _crackFlyEnding(false, options, cPoint or sPoint)
                return
            end
            dt = dt + dtSpd

            local nPoint = {
                sPoint[1] + 2 * (mPoint[1] - sPoint[1]) * dt + (tPoint[1] - 2 * mPoint[1] + sPoint[1]) * dt ^ 2,
                sPoint[2] + 2 * (mPoint[2] - sPoint[2]) * dt + (tPoint[2] - 2 * mPoint[2] + sPoint[2]) * dt ^ 2,
                sPoint[3] + 2 * (mPoint[3] - sPoint[3]) * dt + (tPoint[3] - 2 * mPoint[3] + sPoint[3]) * dt ^ 2
            }
            if
                (hrect.isBorderPlayable(nPoint[1], nPoint[2])) or
                cj.IsTerrainPathable(nPoint[1], nPoint[2], PATHING_TYPE_WALKABILITY)
            then
                curTimer.destroy()
                _crackFlyEnding(false, options, cPoint)
                return
            end
            if (type(options.onMove) == "function") then
                local mRes = options.onMove(sourceUnit, targetUnit, nPoint or sPoint)
                if (mRes == false) then
                    destroy(curTimer)
                    _crackFlyEnding(false, options, cPoint)
                    return
                end
            end
            cPoint = nPoint
            cj.SetUnitX(targetUnit, cPoint[1])
            cj.SetUnitY(targetUnit, cPoint[2])
            hunit.setFlyHeight(targetUnit, cPoint[3], 1e4)
            if (dt >= 1) then
                curTimer.destroy()
                _crackFlyEnding(true, options, tPoint)
            end
        end
    )
end

function hskillMoban.radiusAngleAOE(whichUnit, radius, angle, angleWide, damageFunc, considerCollision)
    local group =
        hgroup.createByAngleAndRadius(
            whichUnit,
            radius,
            angle,
            angleWide,
            function(filterUnit)
                if
                    hunit.isAlly(whichUnit, filterUnit) or hunit.isDead(filterUnit) or hunit.isDead(whichUnit) or
                    hunit.isDestroyed(filterUnit) or
                    hunit.isDestroyed(whichUnit)
                then
                    return false
                else
                    return true
                end
            end,
            considerCollision
        )
    for _, target in ipairs(group) do
        damageFunc(target)
    end
end

function hskillMoban.radiusAOE(x, y, whichUnit, radius, damageFunc, skipSourceDeathCheck, considerCollision)
    local group =
        hgroup.createByXY(
            x,
            y,
            radius,
            function(filterUnit)
                if
                    hunit.isAlly(whichUnit, filterUnit) or hunit.isDead(filterUnit) or
                    (skipSourceDeathCheck ~= true and hunit.isDead(whichUnit)) or
                    hunit.isDestroyed(filterUnit) or
                    hunit.isDestroyed(whichUnit)
                then
                    return false
                else
                    return true
                end
            end,
            considerCollision
        )
    for _, target in ipairs(group) do
        damageFunc(target)
    end
end

function hskillMoban.rectAOE(rect, whichUnit, damageFunc)
    local group =
        hgroup.createByRect(
            rect,
            function(filterUnit)
                if
                    hunit.isAlly(whichUnit, filterUnit) or hunit.isDead(filterUnit) or hunit.isDead(whichUnit) or
                    hunit.isDestroyed(filterUnit) or
                    hunit.isDestroyed(whichUnit)
                then
                    return false
                else
                    return true
                end
            end
        )
    for _, target in ipairs(group) do
        damageFunc(target)
    end
end

function hskillMoban.radiusWarning(x, y, z, radius, duration)
    local scale = radius / 100
    return heffect.xyz("war3mapImported\\AZ_U005_2.mdx", x, y, z, duration, 1, scale, scale, 1)
end

function hskillMoban.blastUnit(unit, height, gravity, finishEffect)
    if (hunit.isAlive(unit) == false) then
        return
    end

    if hcache.get(unit, "crackFlying", false) then
        finishEffect(unit)
        return
    end

    hcache.set(unit, "crackFlying", true)

    local startX = hunit.x(unit)
    local startY = hunit.y(unit)
    local startZ = hunit.z(unit)

    hunit.pause(unit)

    -- 计算上升和下降时间
    local upTime = math.sqrt(2 * height / gravity)
    local downTime = upTime

    local function onFinish()
        -- 落地瞬间
        hunit.portal(unit, startX, startY, hunit.getFacing(unit))
        hunit.setFlyHeight(unit, 0, 9999)
        hcache.set(unit, "crackFlying", false)

        -- 打断硬直状态
        hunit.resume(unit)

        -- 调用finishEffect函数
        if (type(finishEffect) == "function") then
            finishEffect(unit)
        end
    end

    -- 上升过程
    local upTimer = 0
    htime.setInterval(
        0.02,
        function(curTimer)
            local dt = 0.02
            upTimer = upTimer + dt
            if (upTimer >= upTime) or hunit.isAlive(unit) == false then
                curTimer.destroy()
                onFinish()
            else
                local progress = upTimer / upTime
                local curZ = startZ + height * progress - 0.5 * gravity * upTimer * upTimer
                hunit.setFlyHeight(unit, curZ, 9999)
            end
        end
    )
end
