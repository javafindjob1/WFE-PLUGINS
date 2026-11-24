hresource                               = { description = {} }

---
--- config = {
---   {type = HSHOP_COST_TYPE, cdKey = "jinbi", isPerHero = bool, max=1000}
--- }
---
hresource.init                          = function(config)
    hresource.config = config
    for _, singleConfig in ipairs(config) do
        if (singleConfig.resourceSource == HSHOP_COST_SOURCE.SHANGCHENG or singleConfig.resourceSource == HSHOP_COST_SOURCE.CUNDANG) and (
                singleConfig.type == nil or singleConfig.cdKey == nil or singleConfig.isPerHero == nil or
                singleConfig.max == nil or
                type(singleConfig.max) ~= "function")
        then
            err("bad resource config, something is nil")
            return
        end
        if (singleConfig.resourceSource == HSHOP_COST_SOURCE.FANGZUOBI_CUNDANG) and (
                singleConfig.type == nil or singleConfig.sumCDKey == nil or singleConfig.usedCDKey == nil or singleConfig.isPerHero == nil)
        then
            err("bad resource config, something is nil")
            return
        end
    end
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hresource[enumPlayer] = {}
            for _, sigConfig in ipairs(hresource.config) do
                hresource[enumPlayer][sigConfig.type] = {
                    currentValue      = 0,
                    gameStartValue    = 0,
                    usedValue         = 0,
                    addedValue        = 0,
                    lastSavedValue    = 0,
                    sumTotal          = 0,
                    usedTotal         = 0,
                    sumTotalRemaining = 0,
                }
            end
        end
    )
    hevent.reaction(
        CONST_EVENT.customResourceChange,
        "expResourceToHero",
        function(evtData)
            if evtData.type == HSHOP_COST_TYPE.experience and evtData.addedValue > 0 then
                hunit.addExp(evtData.triggerUnit, evtData.addedValue, evtData.showEffect)
            end
        end
    )
    hevent.reaction(
        CONST_EVENT.customResourceChange,
        "goldtoUI",
        function(evtData)
            if evtData.type == HSHOP_COST_TYPE.gold then
                hplayer.setGold(hunit.getOwner(evtData.triggerUnit), evtData.totalValue, evtData.triggerUnit, false)
            end
        end
    )
end

hresource.getDescription                = function(whichPlayer)
    if whichPlayer == nil then
        return "未知用户"
    end
    if hplayer.getMainHero(whichPlayer) == nil then
        return "请先选择英雄"
    end
    return hresource.description[whichPlayer] or "未知错误"
end

hresource.updateDescription             = function(whichPlayer)
    if whichPlayer == nil then
        return
    end
    if hplayer.getMainHero(whichPlayer) == nil then
        return
    end
    local msg = {}
    table.insert(msg, "当前资源：")
    table.insert(msg, "")
    local config = hresource.config
    for _, singleConfig in ipairs(config) do
        local type = singleConfig.type
        if singleConfig.resourceSource == HSHOP_COST_SOURCE.FANGZUOBI_CUNDANG then
            local sumValue     = hresource[whichPlayer][type].sumTotal or 0
            local usedValue    = hresource[whichPlayer][type].usedTotal or 0
            local currentValue = sumValue - usedValue
            if currentValue < 0 then
                err("资源数据异常，请联系作者：" .. type .. " " .. sumValue .. " " .. usedValue)
            end
            table.insert(msg, type .. "：" .. currentValue)
        else
            local currentValue = hresource[whichPlayer][type].currentValue or 0
            local limit = singleConfig.max(whichPlayer) or 1
            table.insert(msg, type .. "：" .. currentValue .. "/" .. limit)
        end
    end
    hresource.description[whichPlayer] = string.implode("|n", msg)
end

--- check if we have enough resources
---@param cost table a table contains cost, each item in the table is a type of cost with its value
---@return boolean
hresource.checkHasAllResource           = function(whichPlayer, cost, print)
    if cost == nil or #cost < 1 then
        return true
    end
    for _, singCost in ipairs(cost) do
        if hresource.checkHasSingleResource(whichPlayer, singCost.type, singCost.value, print) ~= true then
            return false
        end
    end
    return true
end

hresource.changeAllResource             = function(whichPlayer, cost, print)
    if cost == nil or #cost < 1 then
        return
    end
    for _, singCost in ipairs(cost) do
        hresource.changeSingleResource(whichPlayer, singCost.type, singCost.value, print)
    end
    return true
end

hresource.AddAllResource                = function(whichPlayer, resource, print)
    if resource == nil or #resource < 1 then
        return
    end
    for _, singCost in ipairs(resource) do
        hresource.addSingleResource(whichPlayer, singCost.type, singCost.value, print)
    end
    return true
end

hresource.getSingleResourceConfig       = function(type)
    for _, sigConfig in ipairs(hresource.config) do
        if sigConfig.type == type then
            return sigConfig
        end
    end
end

--- check if we have single resources
---@return boolean
hresource.checkHasSingleResource        = function(whichPlayer, type, value, print)
    local resourceData = hresource[whichPlayer][type]
    if resourceData == nil then
        err("bad type " .. type)
        return false
    end
    local singleConfig = hresource.getSingleResourceConfig(type)
    local currentValue = 0
    if singleConfig.resourceSource == HSHOP_COST_SOURCE.CUNDANG then
        currentValue = resourceData.currentValue
    elseif singleConfig.resourceSource == HSHOP_COST_SOURCE.SHANGCHENG then
        currentValue = hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, singleConfig.cdKey)
        resourceData.currentValue = currentValue
    elseif singleConfig.resourceSource == HSHOP_COST_SOURCE.FANGZUOBI_CUNDANG then
        local sumValue  = resourceData.currentValue or 0
        local usedValue = resourceData.usedValue or 0
        currentValue    = sumValue - usedValue
    end
    if currentValue >= value then
        return true
    else
        if print == true then
            echo(type .. "不足，当前拥有：" .. tostring(currentValue) .. "，需要：" .. value .. "。", whichPlayer)
        end
        return false
    end
end

hresource.addSingleResource             = function(whichPlayer, type, value, print)
    if value < 0 then
        err("value must be positive")
        return
    end
    hresource.changeSingleResource(whichPlayer, type, -value, print)
end

hresource.removeSingleResource          = function(whichPlayer, type, value, print)
    if value < 0 then
        err("value must be positive")
        return
    end
    hresource.changeSingleResource(whichPlayer, type, value, print)
end

--- when value is negative, it is add
hresource.changeSingleResource          = function(whichPlayer, costType, value, print)
    if costType == HSHOP_COST_TYPE.shengwang then
        return
    end
    if type(value) ~= "number" then
        err("bad costtype: " .. value)
        return
    end
    if value == 0 then return end
    local resourceData = hresource[whichPlayer][costType]
    if resourceData == nil then
        err("bad type " .. costType)
        return false
    end
    local singleConfig = hresource.getSingleResourceConfig(costType)
    if singleConfig == nil then
        err("single config nil for " .. costType)
        return false
    end

    if singleConfig.resourceSource == HSHOP_COST_SOURCE.FANGZUOBI_CUNDANG then
        local sumTotal = resourceData.sumTotal or 0
        local usedTotal = resourceData.usedTotal or 0
        local addedValue = math.max(-value, 0)
        if value < 0 then
            local dailyLimit = resourceData.sumTotalRemaining
            addedValue = math.min(-value, dailyLimit)
            local overflow = math.max(-value - dailyLimit, 0)
            local overflowStr = ""
            if overflow > 0 then
                overflowStr = "（超出每日上限：" .. overflow .. "）"
            end
            if print == true then
                echo("获得" .. costType .. "：" .. tostring(addedValue) .. overflowStr, whichPlayer)
            end
            resourceData.sumTotal = sumTotal + addedValue
            resourceData.sumTotalRemaining = dailyLimit - addedValue
        else
            if print == true then
                echo("消耗" .. costType .. "：" .. tostring(value), whichPlayer)
            end
            resourceData.usedTotal = usedTotal + value
        end
        hresource.saveCunDang(whichPlayer, costType)
        local usedValue = math.max(value, 0)
        hevent.trigger(
            hplayer.getMainHero(whichPlayer),
            CONST_EVENT.customResourceChange,
            {
                triggerUnit = hplayer.getMainHero(whichPlayer),
                type = costType,
                addedValue = addedValue,
                usedValue = usedValue,
                totalValue = resourceData.sumTotal - resourceData.usedTotal,
                showEffect = true
            }
        )
    else
        local maxLimit = singleConfig.max(whichPlayer)
        if singleConfig.resourceSource == HSHOP_COST_SOURCE.SHANGCHENG then
            resourceData.currentValue = hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, singleConfig.cdKey)
        end
        if resourceData.currentValue >= value then
            local newValue = math.min(resourceData.currentValue - value, maxLimit)
            local addedValue = math.max(newValue - resourceData.currentValue, 0)
            if addedValue > 0 and print == true then
                echo("获得" .. costType .. "：" .. tostring(addedValue), whichPlayer)
            end
            local usedValue = math.max(resourceData.currentValue - newValue, 0)
            if usedValue > 0 and print == true then
                echo("消耗" .. costType .. "：" .. tostring(usedValue), whichPlayer)
            end
            resourceData.addedValue = resourceData.addedValue + addedValue
            resourceData.usedValue = resourceData.usedValue + usedValue
            resourceData.currentValue = newValue
            if singleConfig.resourceSource == HSHOP_COST_SOURCE.CUNDANG then
                hresource.saveCunDang(whichPlayer, costType, newValue)
            elseif singleConfig.resourceSource == HSHOP_COST_SOURCE.SHANGCHENG then
                hjapi.DzAPI_Map_ConsumeMallItem(whichPlayer, singleConfig.cdKey, value)
            end
            hevent.trigger(
                hplayer.getMainHero(whichPlayer),
                CONST_EVENT.customResourceChange,
                {
                    triggerUnit = hplayer.getMainHero(whichPlayer),
                    type = costType,
                    addedValue = addedValue,
                    usedValue = usedValue,
                    totalValue = resourceData.currentValue,
                    showEffect = true
                }
            )
        else
            echo("资源消耗错误，请联系作者！")
        end
    end
    hresource.updateDescription(whichPlayer)
end

hresource.loadCunDang                   = function(whichPlayer)
    for _, sigConfig in ipairs(hresource.config) do
        local loadedValue
        if sigConfig.resourceSource == HSHOP_COST_SOURCE.SHANGCHENG then
            loadedValue = hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, sigConfig.cdKey)
            hresource[whichPlayer][sigConfig.type].currentValue = loadedValue
            hresource[whichPlayer][sigConfig.type].gameStartValue = loadedValue
        elseif sigConfig.resourceSource == HSHOP_COST_SOURCE.CUNDANG then
            loadedValue = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(sigConfig.cdKey, sigConfig.isPerHero, true)
            if type(loadedValue) ~= "number" then
                loadedValue = tonumber(loadedValue)
            end
            if loadedValue == nil then
                loadedValue = 0
            end
            if loadedValue > sigConfig.max(whichPlayer) then
                err("检测到存档数据异常，自动修复")
                dump(sigConfig)
                loadedValue = sigConfig.max(whichPlayer)
            end
            hresource[whichPlayer][sigConfig.type].currentValue = loadedValue
            hresource[whichPlayer][sigConfig.type].gameStartValue = loadedValue
        elseif sigConfig.resourceSource == HSHOP_COST_SOURCE.FANGZUOBI_CUNDANG then
            local loadedSum = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(sigConfig.sumCDKey, sigConfig.isPerHero,
                true, true)
            if type(loadedSum) ~= "number" then
                loadedSum = tonumber(loadedSum)
            end
            if loadedSum == nil then
                loadedSum = 0
            end
            local loadedUsed = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(sigConfig.usedCDKey, sigConfig
                .isPerHero, true,
                true)
            if type(loadedUsed) ~= "number" then
                loadedUsed = tonumber(loadedUsed)
            end
            if loadedUsed == nil then
                loadedUsed = 0
            end
            hresource[whichPlayer][sigConfig.type].sumTotal          = loadedSum
            hresource[whichPlayer][sigConfig.type].usedTotal         = loadedUsed
            hresource[whichPlayer][sigConfig.type].sumTotalRemaining = hplayer.dzCunDang[whichPlayer].loadDailyLimitKey(
                sigConfig.sumCDKey,
                sigConfig.isPerHero)
            loadedValue                                              = loadedSum - loadedUsed
        else
            err("未知资源来源")
        end

        hevent.trigger(
            hplayer.getMainHero(whichPlayer),
            CONST_EVENT.customResourceChange,
            {
                triggerUnit = hplayer.getMainHero(whichPlayer),
                type = sigConfig.type,
                addedValue = loadedValue,
                usedValue = 0,
                totalValue = loadedValue,
                showEffect = false
            }
        )
    end
    hresource.updateDescription(whichPlayer)
end

hresource.saveCunDang                   = function(whichPlayer, costType, value)
    local singleConfig = hresource.getSingleResourceConfig(costType)
    if singleConfig ~= nil then
        if singleConfig.resourceSource == HSHOP_COST_SOURCE.FANGZUOBI_CUNDANG then
            hplayer.dzCunDang[whichPlayer].saveCundangWihtoutIndx(
                singleConfig.sumCDKey,
                singleConfig.isPerHero,
                hresource[whichPlayer][costType].sumTotal, true
            )
            hplayer.dzCunDang[whichPlayer].saveCundangWihtoutIndx(
                singleConfig.usedCDKey,
                singleConfig.isPerHero,
                hresource[whichPlayer][costType].usedTotal, true
            )
        else
            if type(value) ~= "number" then
                err("存档数字异常 " .. value)
                return
            end
            hplayer.dzCunDang[whichPlayer].saveCundangWihtoutIndx(
                singleConfig.cdKey,
                singleConfig.isPerHero,
                math.floor(value)
            )
            hresource[whichPlayer][costType].lastSavedValue = value
        end
    end
end

hresource.getResource                   = function(whichPlayer, costType)
    local singleConfig = hresource.getSingleResourceConfig(costType)
    if singleConfig ~= nil then
        if singleConfig.resourceSource == HSHOP_COST_SOURCE.FANGZUOBI_CUNDANG then
            return hresource[whichPlayer][costType].sumTotal - hresource[whichPlayer][costType].usedTotal
        else
            return hresource[whichPlayer][costType].currentValue
        end
    end
    return 0
end

hresource.getResourceSumTotal           = function(whichPlayer, costType)
    local singleConfig = hresource.getSingleResourceConfig(costType)
    if singleConfig ~= nil then
        if singleConfig.resourceSource == HSHOP_COST_SOURCE.FANGZUOBI_CUNDANG then
            return hresource[whichPlayer][costType].sumTotal
        end
    end
    return 0
end

hresource.getResourceUsedTotalRemaining = function(whichPlayer, costType)
    local singleConfig = hresource.getSingleResourceConfig(costType)
    if singleConfig ~= nil then
        if singleConfig.resourceSource == HSHOP_COST_SOURCE.FANGZUOBI_CUNDANG then
            return hresource[whichPlayer][costType].sumTotalRemaining
        end
    end
    return 0
end
