hshengwang = {}

CONST_SHENGWANG_LEVEL = {
    ZHONGLI = 1,
    YOUSHAN = 2,
    ZUNJING = 3,
    CHONGJING = 4,
    CHONGBAI = 5
}

CONST_SHENGWANG_LABEL = {}
CONST_SHENGWANG_LABEL[0] = "|cffd5f2b1中立|r"
CONST_SHENGWANG_LABEL[1] = "|cff00ff00友善|r"
CONST_SHENGWANG_LABEL[2] = "|cff16db16尊敬|r"
CONST_SHENGWANG_LABEL[3] = "|cff029d02崇敬|r"
CONST_SHENGWANG_LABEL[4] = "|cff079907崇拜|r"

SHENGWANG_LEVEL_UP_EXP = {}
SHENGWANG_LEVEL_UP_EXP[0] = 3000
SHENGWANG_LEVEL_UP_EXP[1] = 6000
SHENGWANG_LEVEL_UP_EXP[2] = 12000
SHENGWANG_LEVEL_UP_EXP[3] = 21000
SHENGWANG_LEVEL_UP_EXP[4] = 1000

--- call once globally
--- init attribute etc
--- @param config table
--- Example
--- {
---   {
---      name = "新手村",
---      cundangStr = "shengwang",
---      isPerHero = true,
---      lvlCunDangStartIndex = 1,
---      lvlCunDangEndIndex = 1,
---      expCunDangStartIndex = 2,
---      expCunDangEndIndex = 6,
---      currentExp = 0,
---      currentLevel =0,
---      description = "一切开始的地方，提高声望可以获得不错的属性和便宜材料的购买权"
---      art="",
---      attr = {
---        _attr({}), --友善
---        _attr({}), --尊敬
---        _attr({}), --崇敬
---        _attr({}), --崇拜
---      }
---   }
---}
hshengwang.initFromConfig = function(config)
    if type(config) ~= "table" or #config == 0 then
        err("bad config type or empty config")
        return
    end
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hshengwang[enumPlayer] = table.clone(config)
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end
            ACHIEVEMENT_DATA[enumPlayer]["声望"] = {}
            ACHIEVEMENT_DATA[enumPlayer]["声望"].categoryUIName = "BtnRootWindow_Category_Category8"
            local categoryData = {}
            for i, v in ipairs(config) do
                local tmpItem = {}
                tmpItem.name = v.name
                tmpItem.art = v.art
                tmpItem.callback = function()
                end
                tmpItem.tip = hshengwang.getDescription(v)
                tmpItem.enable = true
                table.insert(categoryData, tmpItem)
            end
            ACHIEVEMENT_DATA[enumPlayer]["声望"].categoryData = categoryData
        end
    )
end

hshengwang.getDescription = function(shengwang)
    local msg = {}
    table.insert(
        msg,
        CONST_SHENGWANG_LABEL[shengwang.currentLevel] ..
        hcolor.yellow(shengwang.name) ..
        " (进度" ..
        hcolor.green(tostring(shengwang.currentExp)) ..
        "/" .. tostring(SHENGWANG_LEVEL_UP_EXP[shengwang.currentLevel]) .. "）"
    )
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("简介：") .. shengwang.description)
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("达到声望等级获得该势力的祝福："))
    for i = math.max(shengwang.currentLevel, 1), #(shengwang.attr), 1 do
        local color = hcolor.grey
        if shengwang.currentLevel >= i then
            color = hcolor.green
        end
        table.insert(msg, color(CONST_SHENGWANG_LABEL[i] .. " " .. description.attribute(shengwang.attr[i])))
    end
    return string.implode("|n", msg)
end

hshengwang.initTujianForUser = function(whichPlayer)
    if whichPlayer == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        return
    end
    hshengwang.loadcundang(whichPlayer)
end

function hshengwang.cundang(shengwang, whichPlayer)
    local currentExp = shengwang.currentExp
    local countStr = tostring(currentExp)
    if string.len(countStr) == 0 then
        countStr = "00000"
    elseif string.len(countStr) == 1 then
        countStr = "0000" .. countStr
    elseif string.len(countStr) == 2 then
        countStr = "000" .. countStr
    elseif string.len(countStr) == 3 then
        countStr = "00" .. countStr
    elseif string.len(countStr) == 4 then
        countStr = "0" .. countStr
    elseif string.len(countStr) == 5 then
        countStr = countStr
    elseif string.len(countStr) > 5 then
        countStr = "00000"
    end
    hplayer.dzCunDang[whichPlayer].saveCundang(
        shengwang.cundangStr,
        shengwang.isPerHero,
        shengwang.expCunDangStartIndex,
        shengwang.expCunDangEndIndex,
        countStr
    )
    local currentLevel = shengwang.currentLevel
    if currentLevel > 4 or currentLevel < 0 then
        return
    end
    local lvlCDStr = tostring(currentLevel)
    hplayer.dzCunDang[whichPlayer].saveCundang(
        shengwang.cundangStr,
        shengwang.isPerHero,
        shengwang.lvlCunDangStartIndex,
        shengwang.lvlCunDangEndIndex,
        lvlCDStr
    )
end

function hshengwang.getShengWangLevel(shengwangName, whichPlayer)
    for i, shengwang in ipairs(hshengwang[whichPlayer]) do
        if shengwang.name == shengwangName then
            return shengwang.currentLevel
        end
    end
    return 0
end

function hshengwang.huodeShengWang(shengwangName, whichPlayer, cundang, value)
    if value == 0 then
        return
    end
    if value > 300000 or value < 0 then
        err("too many shengwang or 0 shengwang")
        return
    end
    for i, shengwang in ipairs(hshengwang[whichPlayer]) do
        if shengwang.name == shengwangName then
            shengwang.currentExp = shengwang.currentExp + value
            local levelUP = false
            if shengwang.currentLevel < 4 and shengwang.currentExp > SHENGWANG_LEVEL_UP_EXP[shengwang.currentLevel] then
                shengwang.currentExp = 0
                shengwang.currentLevel = shengwang.currentLevel + 1
                levelUP = true
            end
            ui_update_text_achievement_data_at_category_and_idx(
                whichPlayer,
                "声望",
                i,
                hshengwang.getDescription(shengwang)
            )
            if cundang == true then
                echo("获得" .. tostring(value) .. "点" .. shengwangName .. "声望", whichPlayer)
                if levelUP == true then
                    echo(shengwangName .. "声望升级为" .. CONST_SHENGWANG_LABEL[shengwang.currentLevel], whichPlayer)
                end
                hshengwang.cundang(shengwang, whichPlayer)
            end
            if levelUP == true then
                hbuff.addAttribute(
                    CONST_DAMAGE_SRC.skill,
                    hplayer.getMainHero(whichPlayer),
                    shengwangName .. "声望加成",
                    shengwang.attr[shengwang.currentLevel],
                    0
                )
                if cundang == true then
                    echo(
                        "激活新的声望属性加成(会覆盖旧的加成):" ..
                        hcolor.green(description.attribute(shengwang.attr[shengwang.currentLevel], ",")),
                        whichPlayer
                    )
                end
            end
        end
    end
end

function hshengwang.loadcundang(whichPlayer)
    for i, shengwang in ipairs(hshengwang[whichPlayer]) do
        local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(shengwang.cundangStr, shengwang.isPerHero)
        local currentLvl =
            math.min(
                4,
                math.floor(tonumber(string.sub(cundang, shengwang.lvlCunDangStartIndex, shengwang.lvlCunDangEndIndex)) or
                    0)
            )
        local currentExp =
            math.floor(tonumber(string.sub(cundang, shengwang.expCunDangStartIndex, shengwang.expCunDangEndIndex)) or 0)
        for j = 1, currentLvl, 1 do
            hshengwang.huodeShengWang(shengwang.name, whichPlayer, false, 30000)
        end
        hshengwang.huodeShengWang(shengwang.name, whichPlayer, false, currentExp)
    end
end

function hshengwang.jihuosuoyouShengWang(whichPlayer)
    for i, shengwang in ipairs(hshengwang[whichPlayer]) do
        hshengwang.huodeShengWang(shengwang.name, whichPlayer, false, 30000)
        hshengwang.huodeShengWang(shengwang.name, whichPlayer, false, 30000)
        hshengwang.huodeShengWang(shengwang.name, whichPlayer, false, 30000)
        hshengwang.huodeShengWang(shengwang.name, whichPlayer, false, 30000)
        hshengwang.huodeShengWang(shengwang.name, whichPlayer, false, 30000)
        hshengwang.huodeShengWang(shengwang.name, whichPlayer, false, 30000)
    end
end
