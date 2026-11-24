--- buff系统
---buff是一种状态，可被创建和删除
---当buff被删除时，将会
hbuff = {}
BUFF_KEY = "c-buff"

HBUFF_UPDATE_MODE = {
    CREATE_ONLY = 1,
    OVERWRITE = 2,
    UPDATE = 3
}

hevent.reaction(
    CONST_EVENT.dead,
    "buff clean up",
    function(evtData)
        local whichUnit = evtData.triggerUnit
        local buffHandles = hcache.get(whichUnit, BUFF_KEY, { _idx = {} })
        local buffKeysToDelete = {}
        for _, key in ipairs(buffHandles._idx) do
            if buffHandles[key].deleteOnDead == true then
                table.insert(buffKeysToDelete, key)
            end
        end
        for _, key in ipairs(buffKeysToDelete) do
            hbuff.delete(whichUnit, key)
        end
    end
)

hbuff.getStack = function(targetUnit, key)
    local buffHandle = hbuff.getBuffHandle(targetUnit, key)
    if buffHandle == nil then
        return 0
    end
    return buffHandle.stack or 1
end

---whether has buff
---@param targetUnit userdata
---@param key string
---@stack key number|nil 等于指定层数
---@return bool
hbuff.hasBuff = function(targetUnit, key, stack)
    local buffHandle = hbuff.getBuffHandle(targetUnit, key)
    if buffHandle == nil then
        return false
    end
    if stack == nil then
        return true
    end
    if buffHandle.stack ~= stack then
        return false
    end
    return true
end
---whether buff is from caster
---@param targetUnit userdata
---@param key string
---@param caster userdata
hbuff.isBuffFromCaster = function(targetUnit, key, caster)
    local buffHandle = hbuff.getBuffHandle(targetUnit, key)
    if buffHandle == nil then
        return false
    end
    if buffHandle.buffCaster == caster then
        return true
    end
    return false
end

---remove stack of a buff
--- won't change remaining time
---@param targetUnit userdata
---@param key string
---@stack key number|nil 等于指定层数
---@return bool
hbuff.removeStack = function(targetUnit, key, stacksToRemove)
    if stacksToRemove == nil or stacksToRemove <= 0 then
        return
    end
    local buffHandle = hbuff.getBuffHandle(targetUnit, key)
    if buffHandle == nil then
        return
    end
    stacksToRemove = math.floor(stacksToRemove)
    if buffHandle.stack > stacksToRemove then
        buffHandle.stack = buffHandle.stack - stacksToRemove
    else
        hbuff.delete(targetUnit, key)
    end
end

--- 统计group buff的个数
---@private
hbuff.count = function(handleUnit, key)
    if (handleUnit == nil) then
        return 0
    end
    if (handleUnit == nil or key == nil) then
        return 0
    end
    if (hunit.isDestroyed(handleUnit)) then
        return 0
    end
    if (false == hcache.exist(handleUnit)) then
        return 0
    end
    local buffHandle = hcache.get(handleUnit, BUFF_KEY, {})
    if (buffHandle._idx == nil) then
        return 0
    end
    return #buffHandle._idx
end

hbuff.getRemainingTime = function(handleUnit, key)
    if (handleUnit == nil) then
        return 0
    end
    if (key == nil) then
        return 0
    end
    if hbuff.hasBuff(handleUnit, key) == false then
        return 0
    end

    local buffHandle = hbuff.getBuffHandle(handleUnit, key)
    if buffHandle == nil then
        return 0
    end
    if buffHandle.interval == nil then
        return buffHandle.timer.remain()
    else
        return buffHandle.remainingTime
    end
end

--- 获取buff data
hbuff.getBuffHandle = function(handleUnit, key)
    if (handleUnit == nil) then
        return nil
    end
    if (key == nil) then
        return nil
    end
    if (hunit.isDestroyed(handleUnit)) then
        return nil
    end
    if (false == hcache.exist(handleUnit)) then
        return nil
    end
    local buffHandle = hcache.get(handleUnit, BUFF_KEY, {})
    if (buffHandle[key] == nil) then
        return nil
    end
    return buffHandle[key]
end

hbuff.hasBuffThatLastLongerthan = function(whichUnit, key, duration)
    if hbuff.hasBuff(whichUnit, key) and hbuff.getBuffHandle(whichUnit, key).remainingTime > duration then
        return true
    else
        return false
    end
end

--- 尝试更新一个buff概念物
--- 如果没有key 则创建一个新的
--- 成功创建时会返回一个key，用于删除buff
---@param during number > 0
---@param handleUnit userdata
---@param key string buffkey
---@param positive boolean 是否是正向buff
---@param purpose function 目的期望的操作
---@param rollback function 回到原来状态的操作
---@param art string|nil 图标 nil时认为不用显示图标
---@param description string|nil 说明,鼠标放上去显示技能说明
---@param stack number 层数
---@param interval number|nil 单位为秒, 如果不为nil, 则周期性的purpose
---@param intervalPurpose function 周期性的操作
---@param updateFunction function 如果purpose是 update, 那么对buffhandle 进行操作
---@param mode HBUFF_UPDATE_MODE
---@param extraBuffData table|nil  额外的buff参数 只有在创建时才有效 updateFunction被调用时无效
---@param deleteOnDead bool 是否在死亡后删除buff
---@param hudunzhi number 护盾值
---@param buffCaster userdata buff施加者
---@return nil
hbuff.update = function(
    during,
    handleUnit,
    key,
    positive,
    purpose,
    rollback,
    art,
    description,
    stack,
    interval,
    intervalPurpose,
    updateFunction,
    extraBuffData,
    mode,
    deleteOnDead,
    hudunzhi,
    buffCaster)
    if (handleUnit == nil) then
        return
    end
    if interval ~= nil and intervalPurpose == nil then
        err("inteval is not nil but purpose is nil。need interval purpose to modify time remaining")
        return
    end
    purpose = purpose or function()
    end
    rollback = rollback or function()
    end
    intervalPurpose = intervalPurpose or function()
    end
    updateFunction = updateFunction or function()
    end
    during = during or 0
    if (during <= 0) then
        during = -1
    end
    stack = stack or 1
    if stack < 1 then
        stack = 1
        err("bad stack input: " .. tostring(stack))
    end
    if (hunit.isDestroyed(handleUnit)) then
        return
    end
    if (false == hcache.exist(handleUnit)) then
        return
    end
    if key == nil then
        err("Null key got in hbuff")
        return
    end
    if hbuff.hasBuff(handleUnit, key) then
        if mode == HBUFF_UPDATE_MODE.OVERWRITE then
            hbuff.delete(handleUnit, key)
        elseif mode == HBUFF_UPDATE_MODE.CREATE_ONLY then
            return
        elseif mode == HBUFF_UPDATE_MODE.UPDATE then
            local buffHandle = hcache.get(handleUnit, BUFF_KEY)
            updateFunction(buffHandle[key])
            return
        else
            err("bad mode in buff update: " .. mode)
            return
        end
    end
    purpose()
    local buffHandle = hcache.get(handleUnit, BUFF_KEY)
    if (buffHandle == nil) then
        buffHandle = {}
        hcache.set(handleUnit, BUFF_KEY, buffHandle)
    end
    if (buffHandle._idx == nil) then
        buffHandle._idx = {}
    end
    local remainingTime = during
    if remainingTime <= 0 then
        remainingTime = 72000
    end
    buffHandle[key] = {
        purpose = purpose,
        rollback = rollback,
        positive = positive,
        art = art,
        description = description,
        stack = stack,
        timer = nil,
        interval = interval,
        remainingTime = remainingTime,
        extraBuffData = extraBuffData,
        deleteOnDead = deleteOnDead,
        hudunzhi = hudunzhi,
        buffCaster = buffCaster
    }
    table.insert(buffHandle._idx, key)
    if (during > 0 and interval == nil) then
        buffHandle[key].timer =
            htime.setTimeout(
                during,
                function(curTimer)
                    curTimer.destroy()
                    if (hunit.isDestroyed(handleUnit)) then
                        return
                    end
                    if (buffHandle ~= nil) then
                        if (buffHandle._idx ~= nil) then
                            table.delete(buffHandle._idx, key)
                        end
                        if (buffHandle[key] ~= nil) then
                            rollback(buffHandle[key])
                            buffHandle[key] = nil
                        end
                    end
                end
            )
    elseif interval ~= nil then
        buffHandle[key].timer =
            htime.setInterval(
                interval,
                function(curTimer)
                    if (hunit.isDestroyed(handleUnit)) then
                        curTimer.destroy()
                        return
                    end
                    intervalPurpose(curTimer, buffHandle[key])
                    if buffHandle == nil or buffHandle[key] == nil or buffHandle[key].remainingTime <= 0 then
                        curTimer.destroy()
                        if (buffHandle ~= nil) then
                            if (buffHandle._idx ~= nil) then
                                table.delete(buffHandle._idx, key)
                            end
                            if (buffHandle[key] ~= nil) then
                                rollback(buffHandle[key])
                                buffHandle[key] = nil
                            end
                        end
                    elseif curTimer.__PROPERTIES__.period ~= buffHandle[key].interval and buffHandle[key].interval >= 0.01 then
                        curTimer.period(buffHandle[key].interval - curTimer.__PROPERTIES__.period)
                    end
                end
            )
    end
end

--- 删除一个buff
--- buff被删除时会回到原来的状态
---@param handleUnit userdata
---@param key string
hbuff.delete = function(handleUnit, key)
    if (handleUnit == nil or key == nil) then
        return
    end
    if (hunit.isDestroyed(handleUnit)) then
        return
    end
    if (false == hcache.exist(handleUnit)) then
        return
    end
    if (key == nil) then
        return
    end
    local buffHandle = hcache.get(handleUnit, BUFF_KEY, {})
    if (buffHandle._idx ~= nil) then
        if (buffHandle[key] ~= nil) then
            buffHandle[key].rollback(buffHandle[key]) --rollback
            if buffHandle[key].timer ~= nil then
                buffHandle[key].timer.destroy()
            end
        end
        buffHandle[key] = nil
        table.delete(buffHandle._idx, key)
    end
end

hbuff.wengu = function(time, unit)
    hbuff.update(
        time,
        unit,
        "稳固",
        true,
        nil,
        nil,
        "ReplaceableTextures\\BTN_QS_08.blp",
        "处于稳固状态，无法被打断",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
end

--- hbuff 形式附加属性
--- 具有以下特征
--- 可以用key来保证不重复
--- 可以覆盖，覆盖不会导致属性重复叠加
---@param handleUnit userdata
---@param key string
---@param attr attribute
---@param duration duration
hbuff.addAttribute = function(src, handleUnit, key, attr, duration)
    hbuff.update(
        duration,
        handleUnit,
        key,
        true,
        function()
            hattribute.caleAttribute(src, true, handleUnit, attr, 1)
        end,
        function()
            hattribute.caleAttribute(src, false, handleUnit, attr, 1)
        end,
        nil,
        nil,
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE
    )
end

hbuff.xiaochuhudun = function(whichUnit, xiaochuzhi)
    local buffHandle = hcache.get(whichUnit, BUFF_KEY)
    if (buffHandle == nil) then
        return xiaochuzhi
    end
    if (buffHandle._idx == nil) then
        return xiaochuzhi
    end
    local buffToDel = {}
    for k, v in ipairs(buffHandle._idx) do
        if buffHandle[v].hudunzhi ~= nil and buffHandle[v].hudunzhi > 0 then
            if buffHandle[v].hudunzhi > xiaochuzhi then
                buffHandle[v].hudunzhi = buffHandle[v].hudunzhi - xiaochuzhi
                xiaochuzhi = 0
            else
                xiaochuzhi = xiaochuzhi - buffHandle[v].hudunzhi
                buffHandle[v].hudunzhi = 0
                table.insert(buffToDel, v)
            end
        end
    end
    for k, v in ipairs(buffToDel) do
        hbuff.delete(whichUnit, v)
    end
    return xiaochuzhi
end

hbuff.hashudun = function(whichUnit)
    local buffHandle = hcache.get(whichUnit, BUFF_KEY)
    if (buffHandle == nil) then
        return false
    end
    if (buffHandle._idx == nil) then
        return false
    end
    local buffToDel = {}
    for k, v in ipairs(buffHandle._idx) do
        if buffHandle[v].hudunzhi ~= nil and buffHandle[v].hudunzhi > 0 then
            return true
        end
    end
    return false
end

--- 眩晕buff
hbuff.xuanyun = function(whichUnit, duration)
    if whichUnit == nil then
        return
    end
    if duration < 0 then
        return
    end
    if hbuff.hashudun(whichUnit) then
        echo("眩晕失败，目标拥有护盾", hunit.getOwner(whichUnit))
        return
    end
    if hbuff.hasBuff(whichUnit, "稳固") == true then
        if hplayer.isUser(hunit.getOwner(whichUnit)) == false then
            echo("眩晕失败，目标处于稳固状态", hunit.getOwner(whichUnit))
        end
        return
    end
    if hplayer.isNeutral(hunit.getOwner(whichUnit)) == false and hplayer.isUser(hunit.getOwner(whichUnit)) == false then
        -- 对敌方单位只造成打断
        cj.IssueImmediateOrder(whichUnit, "stop")
        return
    end
    local xuanyun_kangxing = hattr.getWithLimit(whichUnit, nil, "xuanyun_kangxing", 0)
    local finalDuration = math.round(duration * (100 - xuanyun_kangxing) / 100)
    local buff = hbuff.getBuffHandle(whichUnit, "xuanyun")
    if buff == nil or (buff.timer ~= nil and buff.timer.remain() < finalDuration) then
        local xuanyunEffect =
            heffect.attach(
                "Abilities\\Spells\\Human\\Thunderclap\\ThunderclapTarget.mdl",
                whichUnit,
                "overhead",
                finalDuration
            )
        hbuff.update(
            finalDuration,
            whichUnit,
            "xuanyun",
            false,
            function()
                --hunit.pause(whichUnit)
                hjapi.UnitAddSwim(whichUnit)
            end,
            function()
                --hunit.resume(whichUnit)
                hjapi.UnitRemoveSwim(whichUnit)
                heffect.destroy(xuanyunEffect)
            end,
            "ReplaceableTextures\\status\\Spell_Frost_Stun.blp",
            "眩晕中",
            1,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE
        )
    end
end


hbuff.kongju = function(whichUnit, duration)
    if whichUnit == nil then
        return
    end
    if duration < 0 then
        return
    end
    if hbuff.hasBuff(whichUnit, "稳固") == true then
        if hplayer.isUser(hunit.getOwner(whichUnit)) == false then
            echo("恐惧失败，目标处于稳固状态", hunit.getOwner(whichUnit))
        end
        return
    end
    local finalDuration = duration
    local buff = hbuff.getBuffHandle(whichUnit, "kongju")
    if buff == nil or (buff.timer ~= nil and buff.timer.remain() < finalDuration) then
        local kongjuEffect =
            heffect.attach(
                "war3mapImported\\Fear.mdx",
                whichUnit,
                "overhead",
                finalDuration
            )
        hbuff.update(
            finalDuration,
            whichUnit,
            "xuanyun",
            false,
            function()
                hjapi.DzUnitDisableAttack(whichUnit, true)
                hjapi.DzUnitSilence(whichUnit, true)
            end,
            function()
                hjapi.DzUnitDisableAttack(whichUnit, false)
                hjapi.DzUnitSilence(whichUnit, false)
                heffect.destroy(kongjuEffect)
            end,
            "ReplaceableTextures\\Spell_Shadow_Possession.blp",
            "恐惧|n持续时间内无法攻击和施法",
            1,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE
        )
    end
end

--- 增加buff 可以设置最大层数
--- 注意 该模式会先删除已有层数再加新的层数
hbuff.addStackAttrBuff = function(src, handleUnit, key, attrPerStack, duration, maxStack, art, description, isPositive,
                                  finishFunction)
    local buffData = hbuff.getBuffHandle(handleUnit, key)
    local stack = 1
    if buffData ~= nil then
        stack = math.min(maxStack, buffData.stack + 1)
    end
    local isPositiveTmp = true
    if isPositive ~= nil then
        isPositiveTmp = isPositive
    end
    hbuff.update(
        duration,
        handleUnit,
        key,
        isPositiveTmp,
        function()
            hattribute.caleAttribute(src, true, handleUnit, attrPerStack, stack)
        end,
        function()
            hattribute.caleAttribute(src, false, handleUnit, attrPerStack, stack)
            if finishFunction ~= nil then
                finishFunction()
            end
        end,
        art,
        description,
        stack,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE
    )
end
