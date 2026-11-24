htujian = {}

TUJIAN_EFFECT_LEVEL = { 1, 5, 20, 50, 99 }

--- call once globally
--- init attribute etc
--- @param config table
--- Example
--- {
---   {
---      name = "巨魔",
---      rate = 0.01,
---      attr = {
---        1 = _attr({}),
---        5 = _attr({}),
---        20 = _attr({}),
---      }
---   }
---}
htujian.initFromConfig = function(config)
    if type(config) ~= "table" or #config == 0 then
        err("bad config type or empty config")
        return
    end
    local reverseIndex = {}
    for i, v in ipairs(config) do
        local errors = {}
        if v["name"] == nil then
            table.insert(errors, "Missing 'name' field")
        elseif hslk.n2i(v["name"]) == nil then
            table.insert(errors, "Invalid 'name': " .. tostring(v["name"]) .. " (not found in hslk.n2i)")
        end

        if v["rate"] == nil then
            table.insert(errors, "Missing 'rate' field")
        elseif type(v["rate"]) ~= "number" then
            table.insert(errors, "Invalid 'rate': expected number, got " .. type(v["rate"]))
        end

        if v["attr"] == nil then
            table.insert(errors, "Missing 'attr' field")
        elseif type(v["attr"]) ~= "table" then
            table.insert(errors, "Invalid 'attr': expected table, got " .. type(v["attr"]))
        end

        if #errors > 0 then
            err("Bad config for i:" .. tostring(i))
            for _, error_msg in ipairs(errors) do
                err("  - " .. error_msg)
            end
            dump(v)
            return false
        end
        if reverseIndex[v.name] ~= nil then
            err("tujian has duplicate name: " .. v.name)
            return
        end
        reverseIndex[v.name] = i
    end
    hcache.alloc("TUJIAN_CONFIG")
    hcache.set("TUJIAN_CONFIG", "REVERSE_INDEX", reverseIndex)
    hcache.set("TUJIAN_CONFIG", "TUJIAN_CONFIG", config)

    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            htujian[enumPlayer] = table.clone(config)
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end
            ACHIEVEMENT_DATA[enumPlayer]["图鉴"] = {}
            ACHIEVEMENT_DATA[enumPlayer]["图鉴"].categoryUIName = "BtnRootWindow_Category_Category2"
            local categoryData = {}
            for i, v in ipairs(config) do
                local tmpItem = {}
                tmpItem.name = v.name
                tmpItem.art = hslk.n2v(v.name, "slk", "Art")
                if tmpItem.art == nil then
                    tmpItem.art = "ReplaceableTextures\\BTNzb71.blp"
                end
                tmpItem.callback = function()
                    echo("点击了图鉴系统的" .. v.name .. "按钮")
                end
                tmpItem.tip = htujian.getDescription(v)
                tmpItem.enable = false
                table.insert(categoryData, tmpItem)
            end
            ACHIEVEMENT_DATA[enumPlayer]["图鉴"].categoryData = categoryData
        end
    )
end

htujian.getDescription = function(tujian)
    local msg = {}
    if tujian == nil then
        return "图鉴是空的"
    end
    table.insert(msg, "击杀" .. tujian.name .. "获得图鉴，当前数量：" .. tostring(tujian.currentCount))
    table.insert(msg, "基础掉率：" .. hcolor.green(string.format("%.2f%%", tujian.rate / 100)))
    table.insert(msg, "")
    for _, requriedCount in ipairs(TUJIAN_EFFECT_LEVEL) do
        if tujian.currentCount >= requriedCount then
            table.insert(
                msg,
                hcolor.green("收集" .. tostring(requriedCount) .. "个: " .. description.attribute(tujian.attr, ", "))
            )
        else
            table.insert(
                msg,
                hcolor.grey("收集" .. tostring(requriedCount) .. "个: " .. description.attribute(tujian.attr, ", "))
            )
        end
    end
    table.insert(msg, "")
    if tujian.isPerHero == true then
        table.insert(msg, "该图鉴存档不同职业" .. hcolor.yellow("不共享"))
    else
        table.insert(msg, "该图鉴存档不同职业" .. hcolor.yellow("共享"))
    end
    table.insert(msg, "生效等级：" .. hcolor.green(tostring(tujian.effectiveLevel)))
    return string.implode("|n", msg)
end

htujian.getTujianConfig = function()
    local config = hcache.get("TUJIAN_CONFIG", "TUJIAN_CONFIG", nil)
    if config == nil then
        err("Get nil config")
        return nil
    end
    return config
end

htujian.initTujianForUser = function(whichPlayer)
    if whichPlayer == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        return
    end
    htujian.loadcundang(whichPlayer)

    -- 注册杀怪事件
    hevent.reaction(
        CONST_EVENT.kill,
        "tujian_shuaguai",
        function(evtData)
            local whichPlayer = hunit.getOwner(evtData.triggerUnit)
            if hplayer.dzCunDang[whichPlayer] == nil then
                return
            end
            local group = hgroup.createAllyGroupByUnit(evtData.triggerUnit, 1500)
            for _, unit in ipairs(group) do
                local targetPlayer = hunit.getOwner(unit)
                if hplayer.getMainHero(targetPlayer) == unit then
                    htujian.tryJihuotujian(hunit.getName(evtData.targetUnit), targetPlayer)
                end
            end
        end
    )
end

function htujian.cundang(tujian, whichPlayer)
    local currentCount = tujian.currentCount
    local countStr = tostring(currentCount)
    if string.len(countStr) == 0 then
        countStr = "00"
    elseif string.len(countStr) == 1 then
        countStr = "0" .. countStr
    elseif string.len(countStr) > 2 then
        countStr = "00"
    end
    hplayer.dzCunDang[whichPlayer].saveCundang(
        tujian.cundangStr,
        tujian.isPerHero,
        tujian.cunDangStartIndex,
        tujian.cunDangEndIndex,
        countStr
    )
end

function htujian.getTujianCount(tujianName, whichPlayer)
    for i, tujian in ipairs(htujian[whichPlayer]) do
        if tujian.name == tujianName then
            local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(tujian.cundangStr, tujian.isPerHero)
            return math.floor(tonumber(string.sub(cundang, tujian.cunDangStartIndex, tujian.cunDangEndIndex)) or 0)
        end
    end
    return nil
end

function htujian.jihuotujian(tujianName, whichPlayer, cundang)
    for i, tujian in ipairs(htujian[whichPlayer]) do
        if tujian.name == tujianName then
            tujian.currentCount = tujian.currentCount + 1
            ui_enable_achievement_data_at_category_and_idx(whichPlayer, "图鉴", i)
            ui_update_text_achievement_data_at_category_and_idx(whichPlayer, "图鉴", i, htujian.getDescription(tujian))
            ui_update_equip_achievement_data_at_category_and_idx(whichPlayer, "图鉴", i, false, tujian.currentCount >= 99)
            if cundang == true then
                echo(
                    "获得" ..
                    hcolor.yellow("图鉴") ..
                    "：" ..
                    tujianName ..
                    hcolor.green("1") .. "个，目前共有" .. hcolor.green(tostring(tujian.currentCount)) .. "个",
                    whichPlayer
                )
                htujian.cundang(tujian, whichPlayer)
            end
            local hero = hplayer.getMainHero(whichPlayer)
            if tujian.effectiveLevel ~= nil and hunit.getLevel(hero) >= tujian.effectiveLevel then
                for _, requriedCount in ipairs(TUJIAN_EFFECT_LEVEL) do
                    if requriedCount == tujian.currentCount then
                        hattribute.set(hplayer.getMainHero(whichPlayer), 0, tujian.attr)
                        if cundang == true then
                            echo("激活新的图鉴属性加成:" .. hcolor.green(description.attribute(tujian.attr, ",")), whichPlayer)
                        end
                    end
                end
            end
        end
    end
end

function htujian.loadcundang(whichPlayer)
    for i, tujian in ipairs(htujian[whichPlayer]) do
        local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(tujian.cundangStr, tujian.isPerHero)
        local currentCount =
            math.floor(tonumber(string.sub(cundang, tujian.cunDangStartIndex, tujian.cunDangEndIndex)) or 0)
        for j = 1, math.min(currentCount, 99), 1 do
            htujian.jihuotujian(tujian.name, whichPlayer, false)
        end
    end
end

function htujian.tryJihuotujian(tujianName, whichPlayer)
    if hplayer.getMainHero(whichPlayer) == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        return
    end
    local tujian_rate = hattribute.getWithLimit(hero, nil, "tujian_rate", 0)
    local rateMulti = 1 + tujian_rate / 100

    for i, tujian in ipairs(htujian[whichPlayer]) do
        if tujian.name == tujianName then
            local dropRate = tujian.rate * rateMulti
            if math.random(1, 10000) > dropRate then
                return
            end
            local currentCount = htujian.getTujianCount(tujianName, whichPlayer)
            if currentCount >= 99 then
                return
            end
            htujian.jihuotujian(tujianName, whichPlayer, true)
            return
        end
    end
end

htujian.jihuosuoyou = function(whichPlayer)
    for i, tujian in ipairs(htujian[whichPlayer]) do
        for j = 1, 99, 1 do
            htujian.jihuotujian(tujian.name, whichPlayer, false)
        end
    end
end

Tujian = function(config)
    this = {
        config = config
    }
    this.init = function(whichPlayer)
        -- load from Cundang
        -- add attribute
        -- setup trigger
    end
    return this
end
