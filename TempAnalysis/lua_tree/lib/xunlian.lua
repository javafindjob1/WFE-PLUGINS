hxunlian = {}

--- 初始化训练
--- @param config table
--- config 例子

--local exampleConfig = {
--    {
--       name="攻击训练",
--       cundangStr = "str",
--       isPerHero = false,
--       cunDangStartIndex = 1,
--       cunDangEndIndex = 3,
--       art = "art",
--       description = "训练说明",
--       currentLevel = 0,
--       attributePerLevel = _attr({attack_white=10}),
--       maxLevel = 10,
--    }
--}

function hxunlian.init(config)
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hxunlian[enumPlayer] = table.clone(config)
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end
            ACHIEVEMENT_DATA[enumPlayer]["训练"] = {}
            ACHIEVEMENT_DATA[enumPlayer]["训练"].categoryUIName = "BtnRootWindow_Category_Category3"
            local categoryData = {}
            for i, v in ipairs(config) do
                local tmpItem = {}
                tmpItem.name = v.name
                tmpItem.art = v.art
                tmpItem.callback = function()
                    echo("点击了训练系统的" .. v.name .. "按钮", enumPlayer)
                end
                tmpItem.tip = hxunlian.getDescription(v)
                tmpItem.enable = false
                table.insert(categoryData, tmpItem)
            end
            ACHIEVEMENT_DATA[enumPlayer]["训练"].categoryData = categoryData
        end
    )
end

function hxunlian.getDescription(xunlian)
    local msg = {}
    table.insert(msg, xunlian.name)
    table.insert(msg, xunlian.description)
    table.insert(msg, "当前进度：" .. tostring(xunlian.currentLevel) .. "/" .. tostring(xunlian.maxLevel))
    table.insert(
        msg,
        "累计增幅：" ..
        hcolor.green(
            description.attribute(hattribute.getAttributeWithMulti(xunlian.attributePerLevel, xunlian.currentLevel))
        )
    )
    table.insert(msg, "")
    table.insert(msg, "训练等级不同职业" .. hcolor.yellow("不共享"))
    return string.implode("|n", msg)
end

function hxunlian.cundang(cundang, whichPlayer)
    local currentLevel = cundang.currentLevel
    local levelStr = tostring(currentLevel)
    if string.len(levelStr) == 0 then
        levelStr = "000"
    elseif string.len(levelStr) == 1 then
        levelStr = "00" .. levelStr
    elseif string.len(levelStr) == 2 then
        levelStr = "0" .. levelStr
    elseif string.len(levelStr) == 3 then
    elseif string.len(levelStr) > 3 then
        levelStr = "000"
    end
    hplayer.dzCunDang[whichPlayer].saveCundang(
        cundang.cundangStr,
        cundang.isPerHero,
        cundang.cunDangStartIndex,
        cundang.cunDangEndIndex,
        levelStr
    )
end

function hxunlian.jihuoxunlian(xunlianName, whichPlayer, cundang)
    for i, xunlian in ipairs(hxunlian[whichPlayer]) do
        if xunlian.name == xunlianName then
            xunlian.currentLevel = xunlian.currentLevel + 1
            hattribute.set(hplayer.getMainHero(whichPlayer), 0, xunlian.attributePerLevel)
            ui_enable_achievement_data_at_category_and_idx(whichPlayer, "训练", i)
            ui_update_text_achievement_data_at_category_and_idx(whichPlayer, "训练", i, hxunlian.getDescription(xunlian))
            ui_update_equip_achievement_data_at_category_and_idx(whichPlayer, "训练", i, false,
                xunlian.currentLevel >= xunlian.maxLevel)
            if cundang == true then
                hxunlian.cundang(xunlian, whichPlayer)
                echo(xunlian.name .. "等级提升，获得" .. description.attribute(xunlian.attributePerLevel, ","), whichPlayer)
            end
        end
    end
end

function hxunlian.jihuosuoyouxunlian(whichPlayer)
    for i, xunlian in ipairs(hxunlian[whichPlayer]) do
        for j = 1, xunlian.maxLevel, 1 do
            hxunlian.jihuoxunlian(xunlian.name, whichPlayer, false)
        end
    end
end

function hxunlian.loadcundang(whichPlayer)
    for i, xunlian in ipairs(hxunlian[whichPlayer]) do
        local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(xunlian.cundangStr, xunlian.isPerHero)
        local currentLevel =
            math.floor(tonumber(string.sub(cundang, xunlian.cunDangStartIndex, xunlian.cunDangEndIndex)) or 0)
        for j = 1, math.min(currentLevel, xunlian.maxLevel), 1 do
            hxunlian.jihuoxunlian(xunlian.name, whichPlayer, false)
        end
    end
end

function hxunlian.tryShengji(xunlianName, whichPlayer)
    if hplayer.getMainHero(whichPlayer) == nil then
        return
    end
    for i, xunlian in ipairs(hxunlian[whichPlayer]) do
        if xunlian.name == xunlianName then
            local current = xunlian.currentLevel
            if current >= xunlian.maxLevel then
                echo("升级失败，" .. xunlian.name .. "已经达到最大等级", whichPlayer)
                return
            end
            hxunlian.jihuoxunlian(xunlianName, whichPlayer, true)
        end
    end
end

function hxunlian.getXunlianLevel(xunlianName, whichPlayer)
    if hplayer.getMainHero(whichPlayer) == nil then
        return
    end
    for i, xunlian in ipairs(hxunlian[whichPlayer]) do
        if xunlian.name == xunlianName then
            return math.min(xunlian.maxLevel, xunlian.currentLevel)
        end
    end
end
