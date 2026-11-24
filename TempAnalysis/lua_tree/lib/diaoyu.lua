hdiaoyu = {}
DIAOYU_SHIJIAN = 10
DIAOYU_ZIDONG_INTERVAL = 1

---
---diaoyuConfig = {
---     {
---        name = "初级钓鱼点",
---        data = {
---          {
---            name = "青鱼",
---            count = 1,
---            rate=5000,
---          },
---          {
---            name = "鲫鱼"
---            count = 1,
---            rate=5000,
---          }
---        },
---
---     }
---}
---
---tujianConfig = {
---     name = "",
---     cundangStr = "diaoyuTujian",
---     art = "",
---     isPerHero = false,
---     cunDangStartIndex = 1,
---     cunDangEndIndex = 2,
---     currentCount = 0,
---     attr = {
---     {
---         requriedCount = 1,
---         attr = _attr(
---             {
---                 defend_white = "+3"
---             }
---         )
---     },
---     {
---         requriedCount = 5,
---         attr = _attr(
---             {
---                 defend_white = "+3"
---             }
---         )
---     },
---     {
---         requriedCount = 20,
---         attr = _attr(
---             {
---                 defend_white = "+3"
---             }
---         )
---     }
--- }
---

hdiaoyu.init = function(diaoyuConfig, tujianConfig)
    hzhuanye.initSingleZhuanye(nil, nil, nil, nil, nil, diaoyuConfig)
    hdiaoyu.initTujianConfig(tujianConfig)
end

hdiaoyu.initTujianConfig = function(config)
    if type(config) ~= "table" or #config == 0 then
        err("bad config type or empty config")
        return
    end
    for i, v in ipairs(config) do
        if v["name"] == nil or v["attr"] == nil or type(v["attr"]) ~= "table" or #(v["attr"]) == 0 then
            err("Bad config for i:" .. tostring(i))
            return
        end
    end

    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hdiaoyu[enumPlayer] = table.clone(config)

            if ZHUANYE_DATA[enumPlayer] == nil then
                ZHUANYE_DATA[enumPlayer] = {}
            end
            ZHUANYE_DATA[enumPlayer]["钓鱼"] = {}
            local zhuanyeData = {}
            for i, v in ipairs(config) do
                local tmpItem = {}
                tmpItem.name = v.name
                tmpItem.art = v.art
                tmpItem.callback = function()
                end
                tmpItem.tip = hdiaoyu.getDescription(v)
                tmpItem.enable = false
                table.insert(zhuanyeData, tmpItem)
            end
            ZHUANYE_DATA[enumPlayer]["钓鱼"].categoryData = zhuanyeData
        end
    )
end

hdiaoyu.getDescription = function(diaoyu)
    local msg = {}
    if diaoyu == nil then
        return "钓鱼图鉴是空的"
    end
    table.insert(msg, "根据钓鱼获得的数量获得图鉴, 当前数量：" .. tostring(diaoyu.currentCount))
    for _, oneAttr in ipairs(diaoyu.attr) do
        if diaoyu.currentCount >= oneAttr.requriedCount then
            table.insert(
                msg,
                hcolor.green(
                    "收获" .. tostring(oneAttr.requriedCount) .. "条: " .. description.attribute(oneAttr.attr, ", ")
                )
            )
        else
            table.insert(
                msg,
                hcolor.grey(
                    "收获" .. tostring(oneAttr.requriedCount) .. "条: " .. description.attribute(oneAttr.attr, ", ")
                )
            )
        end
    end
    table.insert(msg, "")
    table.insert(msg, diaoyu.description)
    table.insert(msg, "")
    table.insert(msg, "钓鱼收获存档全职业共享，但是钓鱼等级不共享")
    return string.implode("|n", msg)
end

hdiaoyu.initTujianForUser = function(whichPlayer)
    if whichPlayer == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        return
    end
    hdiaoyu.loadcundang(whichPlayer)
end

function hdiaoyu.cundang(tujian, whichPlayer)
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

function hdiaoyu.getTujianCount(tujianName, whichPlayer)
    for i, tujian in ipairs(hdiaoyu[whichPlayer]) do
        if tujian.name == tujianName then
            local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(tujian.cundangStr, tujian.isPerHero)
            return math.floor(tonumber(string.sub(cundang, tujian.cunDangStartIndex, tujian.cunDangEndIndex)))
        end
    end
    return nil
end

function hdiaoyu.jihuotujian(tujianName, whichPlayer, cundang)
    if hplayer.getMainHero(whichPlayer) == nil then
        return
    end
    for i, tujian in ipairs(hdiaoyu[whichPlayer]) do
        if tujian.name == tujianName then
            if tujian.currentCount >= 99 then
                return
            end
            tujian.currentCount = tujian.currentCount + 1
            ui_enable_zhuanye_data_at_category_and_idx(whichPlayer, "钓鱼", i)
            ui_update_text_zhuanye_data_at_category_and_idx(whichPlayer, "钓鱼", i, hdiaoyu.getDescription(tujian))
            if cundang == true then
                echo("收获：" .. tujianName .. "1条，目前共有" .. tostring(tujian.currentCount) .. "条", whichPlayer)
                hdiaoyu.cundang(tujian, whichPlayer)
            end
            for _, oneAttr in ipairs(tujian.attr) do
                if oneAttr.requriedCount == tujian.currentCount then
                    hattribute.set(hplayer.getMainHero(whichPlayer), 0, oneAttr.attr)
                    if cundang == true then
                        echo("激活新的钓鱼属性加成:" .. hcolor.green(description.attribute(oneAttr.attr, ",")), whichPlayer)
                    end
                end
            end
        end
    end
end

function hdiaoyu.loadcundang(whichPlayer)
    for i, tujian in ipairs(hdiaoyu[whichPlayer]) do
        local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(tujian.cundangStr, tujian.isPerHero)
        local currentCount =
            math.floor(tonumber(string.sub(cundang, tujian.cunDangStartIndex, tujian.cunDangEndIndex)) or 0)
        for j = 1, math.min(currentCount, 99), 1 do
            hdiaoyu.jihuotujian(tujian.name, whichPlayer, false)
        end
    end
end

hdiaoyu.shouhuo = function(whichPlayer, diaoyuData)
    hdiaoyu.jihuotujian(diaoyuData.name, whichPlayer, true)
end

hdiaoyu.jihuosuoyoudiaoyu = function(whichPlayer)
    for i, tujian in ipairs(hdiaoyu[whichPlayer]) do
        for j = 1, 99, 1 do
            hdiaoyu.jihuotujian(tujian.name, whichPlayer, false)
        end
    end
end
