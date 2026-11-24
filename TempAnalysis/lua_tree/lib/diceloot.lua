hdiceloot = {
    itemsArray = {},
    itemsDetail = {}
}
CONST_HDICELOOT_TIME_SEC = 30

RONGYUHUIYUAN_SKIP_ITEM = {}
RONGYUHUIYUAN_SKIP_ITEM["单手剑"] = true
RONGYUHUIYUAN_SKIP_ITEM["戒指"] = true
RONGYUHUIYUAN_SKIP_ITEM["项链"] = true
RONGYUHUIYUAN_SKIP_ITEM["披风"] = true
RONGYUHUIYUAN_SKIP_ITEM["手套"] = true
RONGYUHUIYUAN_SKIP_ITEM["衣服"] = true
RONGYUHUIYUAN_SKIP_ITEM["头盔"] = true
RONGYUHUIYUAN_SKIP_ITEM["鞋子"] = true
RONGYUHUIYUAN_SKIP_ITEM["法器"] = true
RONGYUHUIYUAN_SKIP_ITEM["单手锤"] = true
RONGYUHUIYUAN_SKIP_ITEM["双手剑"] = true
RONGYUHUIYUAN_SKIP_ITEM["双手斧"] = true
RONGYUHUIYUAN_SKIP_ITEM["双手锤"] = true
RONGYUHUIYUAN_SKIP_ITEM["法杖"] = true
RONGYUHUIYUAN_SKIP_ITEM["饰品"] = true
RONGYUHUIYUAN_SKIP_ITEM["弓"] = true

hdiceloot.addItem = function(dynamicItem, players, x, y)
    if dynamicItem == nil then
        return
    end
    if players == nil or type(players) ~= "table" or #players == 0 then
        -- create items directly
    end
    table.insert(hdiceloot.itemsArray, dynamicItem)
    if hdiceloot.itemsDetail[dynamicItem] ~= nil then
        err("Duplicate items added")
        return
    end
    hdiceloot.itemsDetail[dynamicItem] = {
        x = x,
        y = y,
        startTime = htime.inc,
        endTime = htime.inc + CONST_HDICELOOT_TIME_SEC * 100,
        playerRolls = {},
        playerFenjieRolls = {},
        playerSellRolls = {},
        playersRequired = players
    }
end

hdiceloot.setUpTriggers = function()
    htime.setInterval(
        0.1,
        function(curTimer)
            local playerUIDetail = {}
            local itemsToRemoveFromList = {}
            for index, item in ipairs(hdiceloot.itemsArray) do
                local detail = hdiceloot.itemsDetail[item]
                local maxRollPlayer = nil
                local maxFenjieRollPlayer = nil
                local maxSellRollPlayer = nil
                local playerRollFinished = true
                for _, player in ipairs(detail.playersRequired) do
                    if detail.playerRolls[player] ~= nil then
                        if
                            detail.playerRolls[player] >= 0 and
                            (maxRollPlayer == nil or detail.playerRolls[player] > detail.playerRolls[maxRollPlayer])
                        then
                            maxRollPlayer = player
                        end
                    elseif detail.playerFenjieRolls[player] ~= nil then
                        if
                            detail.playerFenjieRolls[player] >= 0 and
                            (maxFenjieRollPlayer == nil or
                                detail.playerFenjieRolls[player] > detail.playerFenjieRolls[maxFenjieRollPlayer])
                        then
                            maxFenjieRollPlayer = player
                        end
                    elseif detail.playerSellRolls[player] ~= nil then
                        if
                            detail.playerSellRolls[player] >= 0 and
                            (maxSellRollPlayer == nil or
                                detail.playerSellRolls[player] > detail.playerSellRolls[maxSellRollPlayer])
                        then
                            maxSellRollPlayer = player
                        end
                    else
                        if detail.endTime <= htime.inc then
                            if hcache.get(player, "zdxq") and item.pinzhi > 1 then
                                local itemName = hslk.i2v(item.basic_item_id, "Name")
                                if hshangcheng.hasItem(player, "荣誉会员") and RONGYUHUIYUAN_SKIP_ITEM[itemName] then
                                    hdiceloot.giveUp(player, index)
                                else
                                    hdiceloot.roll(player, index)
                                end
                            else
                                hdiceloot.giveUp(player, index)
                            end
                        end
                        playerRollFinished = false
                    end
                end
                if playerRollFinished == true then
                    -- 所有人掷色子结束
                    if maxRollPlayer ~= nil then
                        -- give item to maxRollPlayer
                        item.setOwner(maxRollPlayer)
                        if hplayer.dzCunDang[maxRollPlayer].saveItemInInventory(item) == false then
                            hitem.create(
                                {
                                    id = item.basic_item_id,
                                    whichUnit = hplayer.getMainHero(maxRollPlayer),
                                    dynamicItem = item
                                }
                            )
                        end
                        hplayer.getName(maxRollPlayer)
                        sysecho(
                            hcolor.yellow("玩家：") ..
                            hplayer.getName(maxRollPlayer) ..
                            "通过" ..
                            hcolor.yellow("需求") ..
                            "获得了" ..
                            ZHUANGBEI_PINZHI_DATA[item.pinzhi].color(
                                hitem.getName(item.basic_item_id) .. "。"
                            )
                        )
                    elseif maxFenjieRollPlayer ~= nil then
                        hfumo.fenjie(item, maxFenjieRollPlayer)
                        sysecho(
                            hcolor.yellow("玩家：") ..
                            hplayer.getName(maxFenjieRollPlayer) ..
                            "通过" ..
                            hcolor.yellow("分解") ..
                            "分解了" ..
                            ZHUANGBEI_PINZHI_DATA[item.pinzhi].color(
                                hitem.getName(item.basic_item_id) .. "。"
                            )
                        )
                    elseif maxSellRollPlayer ~= nil then
                        hitem.sellItem(maxSellRollPlayer, item)
                        sysecho(
                            hcolor.yellow("玩家：") ..
                            hplayer.getName(maxSellRollPlayer) ..
                            "通过" ..
                            hcolor.yellow("售卖（放弃）") ..
                            "卖掉了" ..
                            ZHUANGBEI_PINZHI_DATA[item.pinzhi].color(
                                hitem.getName(item.basic_item_id) .. "。"
                            )
                        )
                    else
                        sysecho("系统似乎遇到了什么问题。")
                    end
                    table.insert(itemsToRemoveFromList, index)
                else
                    -- 刷新UI
                    for _, player in ipairs(detail.playersRequired) do
                        if
                            detail.playerRolls[player] == nil and detail.playerFenjieRolls[player] == nil and
                            detail.playerSellRolls[player] == nil
                        then
                            if playerUIDetail[player] == nil then
                                playerUIDetail[player] = {}
                            end
                            table.insert(playerUIDetail[player], index)
                        end
                    end
                end
            end
            -- 刷新UI
            hplayer.forEach(
                function(enumPlayer, _)
                    if
                        hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false or
                        hplayer.isComputer(enumPlayer) == true
                    then
                        return
                    end
                    local diceFrame = hjapi.DzFrameFindByName("FrmDiceWindow", 0)
                    if playerUIDetail[enumPlayer] == nil then
                        if hplayer.loc() == enumPlayer then
                            hjapi.DzFrameShow(diceFrame, false)
                        end
                    else
                        for i = 1, 5, 1 do
                            local diceFrameItem = hjapi.DzFrameFindByName("FrmDiceWindow_Item" .. i, 0)
                            if playerUIDetail[enumPlayer][i] == nil then
                                if hplayer.loc() == enumPlayer then
                                    hjapi.DzFrameShow(diceFrameItem, false)
                                end
                            else
                                local tmpItem = hdiceloot.itemsArray[playerUIDetail[enumPlayer][i]]
                                local icon = hjapi.DzFrameFindByName("ImgDiceWindow_Item" .. i .. "_Icon", 0)
                                local name = hjapi.DzFrameFindByName("TxtDiceWindow_Item" .. i .. "_Desc", 0)
                                local bar = hjapi.DzFrameFindByName("ImgDiceWindow_Item" .. i .. "_Bar", 0)
                                local rollBtn = hjapi.DzFrameFindByName("BtnDiceWindow_Item" .. i .. "_Roll", 0)
                                local fenjieBtn = hjapi.DzFrameFindByName("BtnDiceWindow_Item" .. i .. "_Fenjie", 0)
                                local giveUpBtn = hjapi.DzFrameFindByName("BtnDiceWindow_Item" .. i .. "_Close", 0)
                                local description =
                                    hjapi.DzFrameFindByName("TxtDiceWindow_Item" .. i .. "_Tips_Desc", 0)
                                if hplayer.loc() == enumPlayer then
                                    -- set art
                                    hjapi.DzFrameSetTexture(icon, hitem.getArt(tmpItem.basic_item_id))
                                    -- set name
                                    hjapi.DzFrameSetText(
                                        name,
                                        ZHUANGBEI_PINZHI_DATA[tmpItem.pinzhi].color(
                                            hitem.getName(tmpItem.basic_item_id)
                                        )
                                    )
                                    -- set bar
                                    hjapi.DzFrameClearAllPoints(bar)
                                    local startTime = hdiceloot.itemsDetail[tmpItem].startTime
                                    local endTime = hdiceloot.itemsDetail[tmpItem].endTime
                                    local ratio = (endTime - htime.inc) / (endTime - startTime)
                                    if ratio < 0 then
                                        ratio = 0
                                    end
                                    local width = 0.0533 * ratio
                                    hjapi.DzFrameSetSize(bar, width, 0.0320)
                                    hjapi.DzFrameSetPoint(bar, 0, diceFrameItem, 0, 0.0533, -0.0180)
                                    -- description
                                    local msg = tmpItem.getDescription()
                                    hjapi.DzFrameClearAllPoints(description)
                                    hjapi.DzFrameSetPoint(description, 5, diceFrameItem, 3, 0, 0)
                                    hjapi.DzFrameSetSize(description, 0.1200, 0)
                                    hjapi.DzFrameSetText(description, msg)
                                    -- register action
                                    hjapi.DzFrameSetScriptByCode(
                                        rollBtn,
                                        MOUSE_ORDER_CLICK,
                                        function()
                                            hsync.send("hdicelootRoll", { playerUIDetail[enumPlayer][i] })
                                        end,
                                        false
                                    )
                                    -- register action
                                    hjapi.DzFrameSetScriptByCode(
                                        fenjieBtn,
                                        MOUSE_ORDER_CLICK,
                                        function()
                                            hsync.send("hdicelootFenjieRoll", { playerUIDetail[enumPlayer][i] })
                                        end,
                                        false
                                    )

                                    hjapi.DzFrameSetScriptByCode(
                                        giveUpBtn,
                                        MOUSE_ORDER_CLICK,
                                        function()
                                            hsync.send("hdicelootGiveUp", { playerUIDetail[enumPlayer][i] })
                                        end,
                                        false
                                    )
                                    -- make frame visible
                                    hjapi.DzFrameShow(diceFrameItem, true)
                                end
                            end
                        end
                        if hplayer.loc() == enumPlayer then
                            hjapi.DzFrameShow(diceFrame, true)
                        end
                    end
                end
            )
            table.sort(
                itemsToRemoveFromList,
                function(a, b)
                    return a > b
                end
            )
            for _, index in ipairs(itemsToRemoveFromList) do
                local removedItem = table.remove(hdiceloot.itemsArray, index)
                hdiceloot.itemsDetail[removedItem] = nil
            end
        end
    )
    hsync.onSend(
        "hdicelootRoll",
        function(syncData)
            hdiceloot.roll(syncData.triggerPlayer, tonumber(syncData.triggerData[1]))
        end
    )
    hsync.onSend(
        "hdicelootFenjieRoll",
        function(syncData)
            hdiceloot.fenjieRoll(syncData.triggerPlayer, tonumber(syncData.triggerData[1]))
        end
    )
    hsync.onSend(
        "hdicelootGiveUp",
        function(syncData)
            hdiceloot.giveUp(syncData.triggerPlayer, tonumber(syncData.triggerData[1]))
        end
    )
end

hdiceloot.roll = function(whichPlayer, index)
    local item = hdiceloot.itemsArray[index]
    if item then
        local detail = hdiceloot.itemsDetail[item]
        if detail and detail.playerRolls[whichPlayer] == nil then
            local rollValue = math.random(1, 100) -- Assuming a roll between 1 and 100
            detail.playerRolls[whichPlayer] = rollValue
            sysecho(
                ZHUANGBEI_PINZHI_DATA[item.pinzhi].color(hitem.getName(item.basic_item_id)) ..
                ": " .. hplayer.getName(whichPlayer) .. " 选择" .. hcolor.yellow("需求") .. "并且掷出" .. rollValue
            )
        end
    end
end

hdiceloot.fenjieRoll = function(whichPlayer, index)
    local item = hdiceloot.itemsArray[index]
    if item then
        local detail = hdiceloot.itemsDetail[item]
        if detail and detail.playerFenjieRolls[whichPlayer] == nil then
            local rollValue = math.random(1, 100) -- Assuming a roll between 1 and 100
            detail.playerFenjieRolls[whichPlayer] = rollValue
            sysecho(
                ZHUANGBEI_PINZHI_DATA[item.pinzhi].color(hitem.getName(item.basic_item_id)) ..
                ": " .. hplayer.getName(whichPlayer) .. " 选择" .. hcolor.sea("分解") .. "并且掷出" .. rollValue
            )
        end
    end
end

hdiceloot.giveUp = function(whichPlayer, index)
    local item = hdiceloot.itemsArray[index]
    if item then
        local detail = hdiceloot.itemsDetail[item]
        if detail and detail.playerSellRolls[whichPlayer] == nil then
            local rollValue = math.random(1, 100) -- Assuming a roll between 1 and 100
            detail.playerSellRolls[whichPlayer] = rollValue
            sysecho(
                ZHUANGBEI_PINZHI_DATA[item.pinzhi].color(hitem.getName(item.basic_item_id)) ..
                ": " .. hplayer.getName(whichPlayer) .. " 选择" .. hcolor.gold("出售") .. "并且掷出" .. rollValue
            )
        end
    end
end
