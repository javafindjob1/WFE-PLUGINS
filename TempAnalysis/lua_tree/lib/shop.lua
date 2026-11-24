hshop = { detail = {}, shopData = {} }
HSHOP_REQUIREMENT_TYPE = {
    shengwang = hcolor.sea("声望"),
    zhuanyedengji = hcolor.yellow("专业"),
    level = hcolor.yellow("等级")
}

HSHOP_COST_SOURCE = {
    SHANGCHENG = "商城",
    CUNDANG = "存档",
    FANGZUOBI_CUNDANG = "防作弊存档"
}

hshop.init = function()
    hevent.reaction(
        CONST_EVENT.itemSell,
        "shop",
        function(evtData)
            if hitem.getName(evtData.soldItem) ~= "交易" then
                return
            end
            hshop.openShopUI(evtData.buyingUnit, evtData.triggerUnit)
        end
    )
    htime.setInterval(
        3,
        function(curTimer)
            hplayer.forEach(
                function(enumPlayer, _)
                    if
                        hplayer.isUser(enumPlayer) == false or
                        hplayer.isPlaying(enumPlayer) == false and hplayer.getMainHero(enumPlayer) ~= nil
                    then
                        return
                    end
                    if
                        hshop.shopData[enumPlayer] ~= nil and hshop.shopData[enumPlayer].currentNPC ~= nil and
                        math.distance(
                            hunit.x(hplayer.getMainHero(enumPlayer)),
                            hunit.y(hplayer.getMainHero(enumPlayer)),
                            hunit.x(hshop.shopData[enumPlayer].currentNPC),
                            hunit.y(hshop.shopData[enumPlayer].currentNPC)
                        ) > 500
                    then
                        if hplayer.loc() == enumPlayer then
                            turnOffUI("商店")
                        end
                    end
                end
            )
        end
    )
    hsync.onSend(
        "shop",
        function(syncData)
            local whichPlayer = syncData.triggerPlayer
            local npcName = syncData.triggerData[1]
            local index = tonumber(syncData.triggerData[2])
            local hero = hplayer.getMainHero(whichPlayer)
            if hshop.detail[npcName] == nil then
                err("empty hshop.detail[npcName]")
                return
            end
            local v = hshop.detail[npcName][index]
            if v.requirement ~= nil then
                for _, req in ipairs(v.requirement) do
                    if req.type == HSHOP_REQUIREMENT_TYPE.shengwang then
                        if req.shengwangname == nil then
                            err("nil shengwangname")
                            return
                        else
                            local shengwangLevel = hshengwang.getShengWangLevel(req.shengwangname, whichPlayer)
                            if shengwangLevel < req.value then
                                echo(req.shengwangname .. "声望等级不够", whichPlayer)
                                return
                            end
                        end
                    elseif req.type == HSHOP_REQUIREMENT_TYPE.level then
                        local level = hunit.getLevel(hplayer.getMainHero(whichPlayer))
                        if level < req.value then
                            echo("英雄" .. HSHOP_REQUIREMENT_TYPE.level .. "不够", whichPlayer)
                            return
                        end
                    elseif req.type == HSHOP_REQUIREMENT_TYPE.zhuanyedengji then
                        if req.zhuanyeName == nil then
                            err("nil zhuanyeName")
                            return
                        end
                        local zhuanyeLevel = hzhuanye.getZhuanyeLevel(req.zhuanyeName, whichPlayer)
                        if zhuanyeLevel < req.value then
                            echo(req.zhuanyeName .. "等级不够", whichPlayer)
                            return
                        end
                    end
                end
            end
            if v.precheck ~= nil and type(v.precheck) == "function" then
                if v.precheck(whichPlayer) == false then
                    echo("购买失败，条件未满足。", whichPlayer)
                    return
                end
            end

            if v.cost ~= nil and hresource.checkHasAllResource(whichPlayer, v.cost, true) == false then
                return
            end
            if v.itemCost ~= nil and hitem.hasRequiredItems(v.itemCost, hero, true) == false then
                return
            end
            if v.cost ~= nil then
                hresource.changeAllResource(whichPlayer, v.cost, true)
            end
            if v.itemCost ~= nil then
                hitem.removeItemFromBag(v.itemCost, hero)
            end
            if v.clickFunction ~= nil then
                v.clickFunction(whichPlayer)
                hplayer.dzCunDang[whichPlayer].saveHeroBagToCundangServer()
            end
        end
    )
end

hshop.addResourceItem = function(npcName, resourceType, resourceCost, cost, itemCost, requirement)
    local resourceFongi = hresource.getSingleResourceConfig(resourceType)
    hshop.addItem(
        npcName,
        resourceType,
        resourceFongi.art,
        cost,
        requirement,
        "",
        function(whichPlayer)
            hresource.addSingleResource(whichPlayer, resourceType, resourceCost, true)
        end,
        nil, itemCost
    )
end

---@param
---@param
---@param cost table {{type = HSHOP_REQUIREMENT_TYPE.gold, value = x}, {name = shengwang, value = 1,shengwangname='xinshoucun'},}
---@param requirement table {{name = "shengwang", value = x}, {name = "level", value = y}, {name = "custom", value = function(whichUnit)}}
hshop.addItem = function(npcName, itemName, art, cost, requirement, tips, clickFunction, precheck, itemCost, itemJiangli)
    if npcName == nil then
        err(npcName .. " is nil ")
        return
    end
    if hshop.detail[npcName] == nil then
        hshop.detail[npcName] = {}
    end
    local index = #(hshop.detail[npcName]) + 1
    table.insert(
        hshop.detail[npcName],
        {
            name = itemName,
            art = art,
            cost = cost,
            itemCost = itemCost,
            tips = hshop.getDescription(itemName, requirement, cost, tips, itemCost, itemJiangli),
            requirement = requirement,
            precheck = precheck,
            callback = function()
                hsync.send("shop", { npcName, index })
            end,
            clickFunction = clickFunction
        }
    )
    hitem.registerItemSource(itemName, npcName)
end

hshop.addNormalItem = function(npcName, itemName, cost, requirement)
    if npcName == nil then
        err(npcName .. " is nil ")
        return
    end
    if hshop.detail[npcName] == nil then
        hshop.detail[npcName] = {}
    end
    local tmpItem = DynamicItem(hslk.n2i(itemName))
    tmpItem.initBasedOnPinzhi(hitem.getItemMinPinzhi(hslk.n2i(itemName)), 1, 0, FUBEN_NANDU.PUTONG)
    hshop.addItem(
        npcName,
        itemName,
        hslk.n2v(itemName, "Art"),
        cost,
        requirement,
        tmpItem.getDescription(),
        function(whichPlayer)
            local dynamicItem = DynamicItem(hslk.n2i(itemName))
            local pinzhi = hitem.getItemMinPinzhi(hslk.n2i(itemName))
            dynamicItem.pinzhi = pinzhi
            dynamicItem.setOwner(whichPlayer)
            dynamicItem.setStack(1)
            hitem.create(
                {
                    id = hslk.n2i(itemName),
                    charges = 1,
                    whichUnit = hplayer.getMainHero(whichPlayer),
                    dynamicItem = dynamicItem
                }
            )
            echo("获得：" .. hitem.getColoredNameBasedOnPinzhi(itemName), whichPlayer)
        end
    )
end

hshop.addFullItem = function(npcName, itemName, art, cost, requirement, itemJiangli)
    if npcName == nil then
        err(npcName .. " is nil ")
        return
    end
    if hshop.detail[npcName] == nil then
        hshop.detail[npcName] = {}
    end
    hshop.addItem(
        npcName,
        itemName,
        art,
        cost,
        requirement,
        "",
        function(whichPlayer)
            for _, v in ipairs(itemJiangli) do
                hitem.createSingleItemFromSingleItemReq(
                    v,
                    hplayer.getMainHero(whichPlayer)
                )
            end
        end, nil, nil, itemJiangli
    )
end

hshop.getDescription = function(itemName, requirement, cost, tips, itemCost, itemJiangli)
    local msg = {}
    table.insert(msg, "获得 " .. hitem.getColoredNameBasedOnPinzhi(itemName))
    table.insert(msg, "")
    if itemJiangli ~= nil then
        for _, v in ipairs(itemJiangli) do
            table.insert(msg, "获得: " .. hitem.getDescriptionForSingleRequiredItem(v, true))
        end
    end
    table.insert(msg, "")
    if cost ~= nil and #(cost) > 0 then
        table.insert(msg, hshop.getCostDesc(cost))
    end
    if itemCost ~= nil and #(itemCost) > 0 then
        table.insert(msg, hitem.getDescriptionForRequiredItems(itemCost))
    end
    table.insert(msg, "")
    if requirement ~= nil and #(requirement) > 0 then
        table.insert(msg, hshop.getRequirementDesc(requirement))
        table.insert(msg, "")
    end
    table.insert(msg, tips)
    return string.implode("|n", msg)
end

hshop.getRequirementDesc = function(requirement)
    local msg = {}
    if requirement ~= nil and #(requirement) > 0 then
        table.insert(msg, "需要：")
        for _, req in ipairs(requirement) do
            if req.type == HSHOP_REQUIREMENT_TYPE.shengwang then
                table.insert(msg, "- " .. req.shengwangname .. "声望等级达到" .. CONST_SHENGWANG_LABEL[req.value])
            elseif req.type == HSHOP_REQUIREMENT_TYPE.level then
                table.insert(msg, "- 英雄等级达到" .. req.value)
            elseif req.type == HSHOP_REQUIREMENT_TYPE.zhuanyedengji then
                table.insert(msg, "- " .. req.zhuanyeName .. "专业等级达到" .. ZHUANYE_LEVEL_TO_LABEL[req.value])
            end
        end
    end
    return string.implode("|n", msg)
end

hshop.getCostDesc = function(cost)
    local msg = {}
    if cost ~= nil and #(cost) > 0 then
        table.insert(msg, "消耗：")
        for _, req in ipairs(cost) do
            table.insert(msg, "- " .. tostring(req.type) .. " X " .. tostring(req.value))
        end
    end
    return string.implode("|n", msg)
end

hshop.openShopUI = function(whichUnit, NPC)
    local npcName = hunit.getName(NPC)
    if hshop.detail[npcName] == nil then
        echo(npcName .. "表示没有什么可以交易的")
        return
    end
    update_shop_UI_to_page(hunit.getOwner(whichUnit), NPC, 1)
end
