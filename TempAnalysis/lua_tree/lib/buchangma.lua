hbuchangma = {}

---
--- Example
--- {
---   {
---      name = "加群福利",
---      buchangma = "mxzdgs666",
---      cdKey = "123456",
---      effectiveLevel = 1,
---      art = "ReplaceableTextures\\CommandButtons\\BTNResurrection.blp",
---      description = "加入QQ群获取指令，输入指令即可获得福利",
---      cdIndex = 1,
---      isActive = false,
---      effects = {
---        {
---          attr_type = CONST_EVENT.attr,
---          attr = _attr({})
---        }
---      }
---   }
---}
hbuchangma.initFromConfig = function(config)
    if type(config) ~= "table" or #config == 0 then
        err("bad config type or empty config")
        return
    end
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hbuchangma[enumPlayer] = table.clone(config)
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end
            ACHIEVEMENT_DATA[enumPlayer]["其它"] = {}
            ACHIEVEMENT_DATA[enumPlayer]["其它"].categoryUIName = "BtnRootWindow_Category_Category14"
            local categoryData = {}
            for i, v in ipairs(hbuchangma[enumPlayer]) do
                if v.effects ~= nil then
                    for _, effect in ipairs(v.effects) do
                        if effect.attr_type == CONST_EVENT.attr and type(effect.attr) == "function" then
                            effect.attr = effect.attr(enumPlayer)
                        end
                    end
                end
                local tmpItem = {}
                tmpItem.name = v.name
                tmpItem.art = v.art
                if tmpItem.art == nil then
                    tmpItem.art = "ReplaceableTextures\\BTNzb71.blp"
                end
                tmpItem.callback = function()
                end
                tmpItem.tip = hbuchangma.getDescription(v)
                tmpItem.enable = false
                table.insert(categoryData, tmpItem)
            end
            ACHIEVEMENT_DATA[enumPlayer]["其它"].categoryData = categoryData
        end
    )

    for i, buchangma in ipairs(config) do
        if buchangma.buchangma ~= nil then
            hcmd(
                buchangma.buchangma,
                function(evtData)
                    hsync.send("shurubuchangma", {i})
                end
            )
        end
    end
    hsync.onSend(
        "shurubuchangma",
        function(syncData)
            local whichPlayer = syncData.triggerPlayer
            local index = tonumber(syncData.triggerData[1])
            if hbuchangma[whichPlayer] == nil then
                return
            end
            if hbuchangma[whichPlayer][index] == nil then
                return
            end
            hbuchangma.jihuobuchangma(index, whichPlayer, true)
        end
    )
end

hbuchangma.getDescription = function(buchangma)
    local msg = {}
    local color
    if buchangma.isActive == true then
        color = hcolor.green
        table.insert(msg, buchangma.name .. color("（已激活）"))
    else
        color = hcolor.grey
        table.insert(msg, buchangma.name .. color("（未激活）"))
    end
    table.insert(msg, "")
    if buchangma.description ~= nil then
        table.insert(msg, buchangma.description)
        table.insert(msg, "")
    end
    table.insert(msg, hcolor.yellow("效果："))
    if buchangma.effects ~= nil then
        for effectIndex, effect in ipairs(buchangma.effects) do
            if effect.attr_type == CONST_EVENT.attr then
                table.insert(msg, color("- " .. description.attribute(effect.attr, "|n- ")))
            else
                table.insert(msg, color("- " .. effect.description))
            end
        end
    end
    return string.implode("|n", msg)
end

hbuchangma.initPlayer = function(whichPlayer)
    if whichPlayer == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        return
    end
    hbuchangma.loadcundang(whichPlayer)
end

function hbuchangma.cundang(buchangma, whichPlayer)
    local isActive = buchangma.isActive
    local countStr
    if isActive then
        countStr = "1"
    else
        countStr = "0"
    end
    hplayer.dzCunDang[whichPlayer].saveCundang(buchangma.cdKey, false, buchangma.cdIndex, buchangma.cdIndex, countStr)
end

function hbuchangma.isActive(buchangmaName, whichPlayer)
    for i, buchangma in ipairs(hbuchangma[whichPlayer]) do
        if buchangma.name == buchangmaName then
            return buchangma.isActive
        end
    end
    return false
end

function hbuchangma.jihuobuchangma(idx, whichPlayer, cundang)
    local buchangma = hbuchangma[whichPlayer][idx]
    if buchangma.isActive then
        echo(hcolor.green(buchangma.name) .. "已经激活", whichPlayer)
        return
    end
    buchangma.isActive = true
    ui_enable_achievement_data_at_category_and_idx(whichPlayer, "其它", idx)
    ui_update_text_achievement_data_at_category_and_idx(whichPlayer, "其它", idx, hbuchangma.getDescription(buchangma))
    if cundang == true then
        echo("成功激活：" .. hcolor.green(buchangma.name), whichPlayer)
        hbuchangma.cundang(buchangma, whichPlayer)
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if buchangma.effectiveLevel ~= nil and hunit.getLevel(hero) >= buchangma.effectiveLevel then
        if buchangma.effects ~= nil then
            for effectIndex, effect in ipairs(buchangma.effects) do
                if effect.attr_type == CONST_EVENT.attr then
                    hattr.set(hero, 0, effect.attr)
                elseif effect.attr_type == CONST_EVENT.noeffect then
                else
                    hevent.register(hero, effect.attr_type, "其它" .. effectIndex .. buchangma.name, effect.attr)
                end
            end
        end
    end
end

function hbuchangma.loadcundang(whichPlayer)
    for i, buchangma in ipairs(hbuchangma[whichPlayer]) do
        if buchangma.cundangType == ZUOQI_CUNDANG_TYPE.CUNDANG then
            local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(buchangma.cdKey, false)
            local currentCount = math.floor(tonumber(string.sub(cundang, buchangma.cdIndex, buchangma.cdIndex)) or 0)
            if currentCount == 1 then
                hbuchangma.jihuobuchangma(i, whichPlayer, false)
            end
        elseif buchangma.cundangType == ZUOQI_CUNDANG_TYPE.HARD_CODE then
            if buchangma.shouldActivate ~= nil and type(buchangma.shouldActivate) == "function" then
                if buchangma.shouldActivate(whichPlayer) then
                    hbuchangma.jihuobuchangma(i, whichPlayer, false)
                end
            end
        end
    end
end
