hzhuangbeishouji = {}

--- call once globally
--- init attribute etc
--- @param config table
--- Example
--- {
---   {
---      name = "真鳞胸甲",
---      cundangStr = "zhuangbeishouji",
---      cunDangStartIndex = 1,
---      cunDangEndIndex = 1,
---      art = art,
---      isActive = false,
---      effectiveLevel = 30,
---      resourceCost = {
---        {type = HSHOP_COST_TYPE.gold, }
---      },
---      itemCost = {
---        {type = HSHOP_COST_TYPE.gold, }
---      }
---      activeEffect = {
---        {
---          type = CONST_EVENT.attr,
---          action = _attr()
---        },
---        {
---          type = CONST_EVENT.damage,
---          action = function(evtData)
---        }
---      }
---   }
---}

ZHUANGBEISHOUIJI_TYPE = {
    TEYOUSHOUJI   = 1,
    SANJIANSHOUJI = 2
}

hzhuangbeishouji.initFromConfig = function(config)
    if type(config) ~= "table" or #config == 0 then
        err("bad config type or empty config")
        return
    end
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hzhuangbeishouji[enumPlayer] = table.clone(config)
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end
            ACHIEVEMENT_DATA[enumPlayer]["装备收集"] = {}
            ACHIEVEMENT_DATA[enumPlayer]["装备收集"].categoryUIName = "BtnRootWindow_Category_Category9"
            local categoryData = {}
            for i, v in ipairs(config) do
                local tmpItem = {}
                tmpItem.name = v.name
                tmpItem.art = v.art
                tmpItem.callback = function()
                    hsync.send("clickzbsj", { v.name, hplayer.index(enumPlayer) })
                end
                tmpItem.tip = hzhuangbeishouji.getDescription(v)
                tmpItem.enable = false
                table.insert(categoryData, tmpItem)
            end
            ACHIEVEMENT_DATA[enumPlayer]["装备收集"].categoryData = categoryData
        end
    )
    hsync.onSend(
        "clickzbsj",
        function(syncData)
            local name = syncData.triggerData[1]
            local whichPlayer = syncData.triggerPlayer
            hzhuangbeishouji.tryJihuoShouji(name, whichPlayer)
        end
    )
end

hzhuangbeishouji.isActive = function(whichPlayer, name)
    if whichPlayer == nil or name == nil then
        return false
    end
    local config = hzhuangbeishouji[whichPlayer]
    if config == nil then
        return false
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        return false
    end
    local level = hunit.getLevel(hero)
    for _, shouji in ipairs(config) do
        if shouji.name == name then
            if shouji.effectiveLevel ~= nil and level < shouji.effectiveLevel then
                return false
            end
            return shouji.currentLevel > 0
        end
    end
    return false
end

function hzhuangbeishouji.getDescription(shouji)
    local msg = {}
    if shouji == nil then
        return "收集是空的"
    end

    local currentLevel = shouji.currentLevel or 0
    local maxLevel = #shouji.data
    local jihuo = currentLevel > 0 and "已激活" or "未激活"
    local titleColor = currentLevel > 0 and hcolor.green or hcolor.grey

    if maxLevel > 1 then
        table.insert(msg, titleColor(shouji.name .. " （" .. jihuo .. "，当前进度: " .. currentLevel .. "/" .. maxLevel .. "）"))
    else
        table.insert(msg, titleColor(shouji.name .. " （" .. jihuo .. "）"))
    end
    table.insert(msg, "")

    -- 显示升级所需资源和物品
    if currentLevel < maxLevel then
        local nextLevelData = shouji.data[currentLevel + 1]
        table.insert(msg, hcolor.yellow("升级所需："))
        table.insert(msg, hshop.getCostDesc(nextLevelData.resourceCost))
        for _, itemCost in ipairs(nextLevelData.itemCost) do
            local itemDesc = hitem.getDescriptionForSingleRequiredItem(itemCost)
            local collectedCount = itemCost.currentCount or 0
            local itemLine = "- " .. itemDesc .. " X " .. itemCost.count .. "个"
            itemLine = itemLine .. " 已收集（" .. collectedCount .. "个）"
            table.insert(msg, itemLine)
        end
        table.insert(msg, "")
    end

    table.insert(msg, "收集加成：")
    for level, levelData in ipairs(shouji.data) do
        local levelColor = level <= currentLevel and hcolor.green or hcolor.grey
        for _, effect in ipairs(levelData.activeEffect) do
            if effect.type == CONST_EVENT.attr then
                if maxLevel > 1 then
                    table.insert(msg, levelColor("进度 " .. level .. "：" .. description.attribute(effect.action, "，")))
                else
                    table.insert(msg, levelColor("- " .. description.attribute(effect.action, "|n- ")))
                end
            else
                if maxLevel > 1 then
                    table.insert(msg, levelColor("进度 " .. level .. "：" .. effect.description))
                else
                    table.insert(msg, levelColor("- " .. effect.description))
                end
            end
        end
    end

    table.insert(msg, "")
    table.insert(msg, "该存档所有职业" .. hcolor.yellow("共享"))
    table.insert(msg, hcolor.yellow("生效等级：") .. hcolor.green(tostring(shouji.effectiveLevel)))
    table.insert(msg, hcolor.yellow("注意："))
    table.insert(msg, "- 如果激活需求物品强化和精炼等级，实际物品强化精炼等级高于要求时也能激活")
    if shouji.shoujiType == ZHUANGBEISHOUIJI_TYPE.SANJIANSHOUJI then
        table.insert(msg, "- 收集英雄/史诗难度的装备有额外30%/50%概率增加一点收集进度")
    end

    return string.implode("|n", msg)
end

hzhuangbeishouji.initShoujiForUser = function(whichPlayer)
    if whichPlayer == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        return
    end
    hzhuangbeishouji.loadcundang(whichPlayer)
end

function hzhuangbeishouji.cundang(shouji, whichPlayer)
    local cundangKey       = shouji.cundangStr .. math.floor((shouji.cunDangStartIndex - 1) / 10)
    local startPos         = ((shouji.cunDangStartIndex - 1) % 10) * 6 + 1
    local collectionString = ""

    -- 保存当前级别的收集数量
    local nextLevelData    = shouji.data[shouji.currentLevel + 1]
    if nextLevelData then
        for i = 1, 6 do
            local count = nextLevelData.itemCost[i] and nextLevelData.itemCost[i].currentCount or 0
            collectionString = collectionString .. string.format("%X", math.min(count, 15))
        end
    else
        collectionString = string.rep("0", 6) -- 如果没有下一级，填充6个0
    end

    hplayer.dzCunDang[whichPlayer].saveCundang(
        cundangKey,
        false,
        startPos,
        startPos + 5,
        collectionString
    )

    -- 保存当前等级
    hplayer.dzCunDang[whichPlayer].saveCundang(
        shouji.cundangStr,
        false,
        shouji.cunDangStartIndex,
        shouji.cunDangEndIndex,
        tostring(shouji.currentLevel)
    )
end

function hzhuangbeishouji.jihuosuoyoushouji(whichPlayer)
    for i, shouji in ipairs(hzhuangbeishouji[whichPlayer]) do
        shouji.currentLevel = #shouji.data
        ui_enable_achievement_data_at_category_and_idx(whichPlayer, "装备收集", i)
        ui_update_text_achievement_data_at_category_and_idx(
            whichPlayer,
            "装备收集",
            i,
            hzhuangbeishouji.getDescription(shouji)
        )

        local hero = hplayer.getMainHero(whichPlayer)
        if shouji.effectiveLevel ~= nil and hunit.getLevel(hero) >= shouji.effectiveLevel then
            for _, levelData in ipairs(shouji.data) do
                for idx, effect in ipairs(levelData.activeEffect) do
                    if effect.type == CONST_EVENT.attr then
                        hattribute.set(hero, 0, effect.action)
                        sysecho("激活装备收集属性加成:" .. hcolor.green(description.attribute(effect.action, ",")), whichPlayer)
                    else
                        hevent.register(hero, effect.type, "zhuangbeishouji" .. shouji.name .. idx, effect.action)
                        sysecho("激活装备收集属性加成:" .. hcolor.green(effect.description), whichPlayer)
                    end
                end
            end
        end
    end
end

function hzhuangbeishouji.jihuoshouji(shoujiName, whichPlayer, cundang, level)
    for i, shouji in ipairs(hzhuangbeishouji[whichPlayer]) do
        if shouji.name == shoujiName then
            local oldLevel = shouji.currentLevel
            shouji.currentLevel = level or (shouji.currentLevel + 1)

            -- 重置下一级的 currentCount
            if cundang and shouji.currentLevel < #shouji.data then
                local nextLevelData = shouji.data[shouji.currentLevel + 1]
                for _, itemCost in ipairs(nextLevelData.itemCost) do
                    itemCost.currentCount = 0
                end
            end

            if shouji.currentLevel > 0 then
                ui_enable_achievement_data_at_category_and_idx(whichPlayer, "装备收集", i)
            end
            ui_update_text_achievement_data_at_category_and_idx(
                whichPlayer,
                "装备收集",
                i,
                hzhuangbeishouji.getDescription(shouji)
            )

            if cundang == true then
                sysecho("成功收集：" .. hcolor.green(shoujiName) .. " 进度: " .. shouji.currentLevel .. "/" .. #shouji.data,
                    whichPlayer)
                hzhuangbeishouji.cundang(shouji, whichPlayer)
            end

            local hero = hplayer.getMainHero(whichPlayer)
            if shouji.effectiveLevel ~= nil and hunit.getLevel(hero) >= shouji.effectiveLevel then
                for levelIdx = oldLevel + 1, shouji.currentLevel do
                    local levelData = shouji.data[levelIdx]
                    for idx, effect in ipairs(levelData.activeEffect) do
                        if effect.type == CONST_EVENT.attr then
                            hattribute.set(hero, 0, effect.action)
                            if cundang == true then
                                sysecho("激活装备收集属性加成:" .. hcolor.green(description.attribute(effect.action, ",")),
                                    whichPlayer)
                            end
                        else
                            hevent.register(hero, effect.type, "zhuangbeishouji" .. shoujiName .. levelIdx .. idx,
                                effect.action)
                            if cundang == true then
                                sysecho("激活装备收集属性加成:" .. hcolor.green(effect.description), whichPlayer)
                            end
                        end
                    end
                end
            end
        end
    end
end

function hzhuangbeishouji.loadcundang(whichPlayer)
    for _, shouji in ipairs(hzhuangbeishouji[whichPlayer]) do
        -- 首先加载当前等级
        local levelString = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(shouji.cundangStr, false)

        local currentLevel = tonumber(string.sub(levelString, shouji.cunDangStartIndex, shouji.cunDangEndIndex)) or 0

        -- 然后加载收集的物品数量
        local cundangKey = shouji.cundangStr .. math.floor((shouji.cunDangStartIndex - 1) / 10)
        local startPos = ((shouji.cunDangStartIndex - 1) % 10) * 6 + 1
        local collectionString = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(cundangKey, false)

        if collectionString and #collectionString >= startPos + 5 then
            local collectionData = string.sub(collectionString, startPos, startPos + 5)
            -- 确保 shouji.data[shouji.currentLevel + 1] 存在
            if shouji.data[currentLevel + 1] then
                for i = 1, 6 do
                    local count = tonumber(string.sub(collectionData, i, i), 16) or 0
                    if shouji.data[currentLevel + 1].itemCost[i] then
                        shouji.data[currentLevel + 1].itemCost[i].currentCount = count
                    end
                end
            end
        end
        hzhuangbeishouji.jihuoshouji(shouji.name, whichPlayer, false, currentLevel)
    end
end

function hzhuangbeishouji.tryJihuoShouji(shoujiName, whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        sysecho("英雄不存在，无法进行收集", whichPlayer)
        return
    end
    for i, shouji in ipairs(hzhuangbeishouji[whichPlayer]) do
        if shouji.name == shoujiName then
            local nextLevel = shouji.currentLevel + 1
            if nextLevel > #shouji.data then
                sysecho("该装备收集已全部完成", whichPlayer)
                return
            end
            local nextLevelData = shouji.data[nextLevel]

            local itemsUpdated = false
            local haveAllItems = true
            if shouji.shoujiType == ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI then
                for _, itemReq in ipairs(nextLevelData.itemCost) do
                    local removedCount = hplayer.dzCunDang[whichPlayer].removeAvailableItemFromBag(itemReq)
                    if removedCount > 0 then
                        itemsUpdated = true
                        itemReq.currentCount = (itemReq.currentCount or 0) + removedCount
                    end
                    if itemReq.currentCount < itemReq.count then
                        haveAllItems = false
                        echo(
                            hcolor.yellow("大背包缺少：") ..
                            hitem.getDescriptionForSingleRequiredItem(itemReq) ..
                            " X " .. (itemReq.count - itemReq.currentCount),
                            whichPlayer
                        )
                    end
                end
            elseif shouji.shoujiType == ZHUANGBEISHOUIJI_TYPE.SANJIANSHOUJI then
                for _, itemReq in ipairs(nextLevelData.itemCost) do
                    local _, bonusCount = hplayer.dzCunDang[whichPlayer].shoujiAvailableItemFromBag(itemReq)
                    if bonusCount > 0 then
                        itemsUpdated = true
                        itemReq.currentCount = (itemReq.currentCount or 0) + bonusCount
                    end
                    if itemReq.currentCount < itemReq.count then
                        haveAllItems = false
                        echo(
                            hcolor.yellow("大背包缺少：") ..
                            hitem.getDescriptionForSingleRequiredItem(itemReq) ..
                            " X " .. (itemReq.count - itemReq.currentCount),
                            whichPlayer
                        )
                    end
                end
            end
            if itemsUpdated then
                -- 更新收集进度
                hzhuangbeishouji.cundang(shouji, whichPlayer)
                ui_update_text_achievement_data_at_category_and_idx(whichPlayer, "装备收集", i,
                    hzhuangbeishouji.getDescription(shouji))
            end

            if haveAllItems == false then
                return
            end
            if hresource.checkHasAllResource(whichPlayer, nextLevelData.resourceCost, true) == false then
                return
            end
            hresource.changeAllResource(whichPlayer, nextLevelData.resourceCost, true)
            hzhuangbeishouji.jihuoshouji(shoujiName, whichPlayer, true)
            return
        end
    end
end

hzhuangbeishouji.jihuosuoyou = function(whichPlayer)
    for i, shouji in ipairs(hzhuangbeishouji[whichPlayer]) do
        hzhuangbeishouji.jihuoshouji(shouji.name, whichPlayer, false, #shouji.data)
    end
end
