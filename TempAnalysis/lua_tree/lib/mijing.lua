hmijing = {}

--- {
---   fubenname = "",
---   schedule = {1,0,0,0,0,0,0}
---   art = "",
---   key = "damijing",
---   cdStartIndex = 1,
---   cdEndIndex = 3,
---   isActive = false,
---   currentLevel = 1,
---   maxLevel = 15,
---   cizhuiconfig = {
---     {
---         startLevel = 5,
---           cizhui = {
---             {
---       name = "激励",
---       attr_type = CONST_EVENT.attr,
---       attr = function(evtData) end,
---       startLevel = 1,
---     },
---     {
---       name = "激励",
---       attr_type = CONST_EVENT.attr,
---       attr = function(evtData) end,
---       startLevel = 1,
---     }
---           }
---     }
---   }
--- }

hmijing.initFromConfig = function(config, nanduConfig)
    hmijing.nanduconfig = nanduConfig
    hmijing.config = table.clone(config)
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hmijing[enumPlayer] = table.clone(config)
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end
            ACHIEVEMENT_DATA[enumPlayer]["秘境"] = {}
            ACHIEVEMENT_DATA[enumPlayer]["秘境"].categoryUIName = "BtnRootWindow_Category_Category12"
            local categoryData = {}
            for i, v in ipairs(config) do
                local tmpItem = {}
                tmpItem.name = v.name
                tmpItem.art = v.art
                tmpItem.callback = function()
                end
                tmpItem.tip = hmijing.getDescription(v)
                tmpItem.enable = false
                table.insert(categoryData, tmpItem)
            end
            ACHIEVEMENT_DATA[enumPlayer]["秘境"].categoryData = categoryData
        end
    )
end

hmijing.getNextTiaozhanLevel = function(fubenname, whichPlayer)
    for _, v in ipairs(hmijing[whichPlayer]) do
        if v.name == fubenname then
            return math.min(v.currentLevel + 1, v.maxLevel)
        end
    end
    return 1
end

hmijing.isCurrentMijingOpen = function(fubenname)
    return true
end

hmijing.getCitiaoForMijing = function(fubenname, mijing)
    local finalCitiao = {}
    local currentYDay = os.date("!*t", hjapi.DzAPI_Map_GetGameStartTime() + 28800).yday
    for index, v in ipairs(hmijing.config) do
        if v.name == fubenname then
            for _, cizhui in ipairs(v.cizhuiconfig) do
                if cizhui.startLevel <= mijing and cizhui.cizhui ~= nil and #(cizhui.cizhui) > 0 then
                    table.insert(finalCitiao, cizhui.cizhui[(currentYDay + index) % #(cizhui.cizhui) + 1])
                end
            end
        end
    end
    return finalCitiao
end

hmijing.processMijingAttr = function()
    return hmijing.nanduconfig
end

hmijing.getMijingPassTime = function(fubenname)
    for _, v in ipairs(hmijing.config) do
        if v.name == fubenname then
            return v.timeRequirement[1]
        end
    end
    return 100
end

hmijing.getMijingTwoStarTime = function(fubenname)
    for _, v in ipairs(hmijing.config) do
        if v.name == fubenname then
            return v.timeRequirement[2]
        end
    end
    return 100
end

hmijing.getMijingThreeStarTime = function(fubenname)
    for _, v in ipairs(hmijing.config) do
        if v.name == fubenname then
            return v.timeRequirement[3]
        end
    end
    return 100
end

hmijing.getDescription = function(singleMijing)
    local msg = {}

    table.insert(msg, singleMijing.name)
    table.insert(msg, "")

    table.insert(msg, hcolor.yellow("当前通关层数：") .. hcolor.green(singleMijing.currentLevel) .. hcolor.yellow("（每周一重置）"))
    table.insert(msg, hcolor.yellow("下一次挑战层级：") .. hcolor.green(singleMijing.currentLevel + 1) .. "，该层数额外强化：")
    local citiao = hmijing.getCitiaoForMijing(singleMijing.name, singleMijing.currentLevel + 1)
    if #citiao > 0 then
        for _, v in ipairs(citiao) do
            if v.attr_type == CONST_EVENT.attr then
                table.insert(msg, "- " .. hcolor.red(v.name) .. "：" .. description.attribute(v.attr, "|n- "))
            else
                table.insert(msg, "- " .. hcolor.red(v.name) .. "：" .. v.description)
            end
        end
    else
        table.insert(msg, "- " .. hcolor.grey("无额外强化"))
    end
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("历史最高通关层数：") .. hcolor.green(singleMijing.maxHistoryLevel))
    table.insert(msg, "")
    if singleMijing.jiangliConfig ~= nil then
        table.insert(
            msg,
            hcolor.yellow("最高通关层数奖励：") .. "(等级达到" .. hcolor.green(tostring(singleMijing.effectiveLevel)) .. "级后生效)"
        )
        for _, v in ipairs(singleMijing.jiangliConfig) do
            local color = hcolor.grey
            if singleMijing.maxHistoryLevel >= v.startLevel then
                color = hcolor.green
            end
            table.insert(
                msg,
                color("- 层数大于等于" .. v.startLevel .. "层，之后每层获得属性奖励：" .. description.attribute(v.attrPerLevel, "，"))
            )
        end
        table.insert(msg, "")
    end
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("层数进阶：") .. "在规定时间内完成秘境可以提高秘境层级，具体为：")
    table.insert(msg, "- 在" .. singleMijing.timeRequirement[3] .. "秒内通关会使得秘境层数+3")
    table.insert(msg, "- 在" .. singleMijing.timeRequirement[2] .. "秒内通关会使得秘境层数+2")
    table.insert(msg, "- 在" .. singleMijing.timeRequirement[1] .. "秒内通关会使得秘境层数+1")
    table.insert(msg, "- 在" .. singleMijing.timeRequirement[1] .. "秒后通关或没有通关不会改变秘境层数")

    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("注意："))
    table.insert(msg, "- 可以通过开启传奇难度副本来挑战秘境")
    table.insert(msg, "- 开启的秘境层数由副本开启者决定，开启难度为副本开启者的难度+1，当前秘境层数上限为30")
    table.insert(msg, "- 每层秘境会增加怪物的血量的攻击，并且在第5/10/15层，秘境里的魔物会获得额外的技能，每个副本的额外技能每天都不一样")
    table.insert(msg, "- 秘境里的魔物不会直接掉落物品")
    table.insert(msg, "- 秘境通关属性奖励最多为33层，超过33层后不再增加奖励")

    return string.implode("|n", msg)
end

hmijing.jihuosuoyoumijing = function(whichPlayer)
    for i, singleMijing in ipairs(hmijing[whichPlayer]) do
        hmijing.jihuomijing(singleMijing.name, whichPlayer, singleMijing.maxLevel, false)
    end
end

hmijing.initPlayer = function(whichPlayer)
    if whichPlayer == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        return
    end
    hmijing.loadcundang(whichPlayer)
    hevent.register(
        hero,
        CONST_EVENT.finishFUBEN,
        "秘境完成",
        function(evtData)
            if hplayer.isPlaying(whichPlayer) == false or hplayer.isUser(whichPlayer) == false then
                return
            end
            if
                evtData.nandu == FUBEN_NANDU.CHUANQI and evtData.fubenName ~= nil and evtData.mijing ~= nil and
                evtData.haoshi <= hmijing.getMijingPassTime(evtData.fubenName)
            then
                local addCount = 1
                if evtData.haoshi <= hmijing.getMijingTwoStarTime(evtData.fubenName) then
                    addCount = addCount + 1
                elseif evtData.haoshi <= hmijing.getMijingThreeStarTime(evtData.fubenName) then
                    addCount = addCount + 1
                end
                hmijing.jihuomijing(evtData.fubenName, whichPlayer, evtData.mijing + addCount, true)
                hfuwen.diaoluoFuwen(evtData.fubenName, evtData.mijing, whichPlayer,
                    evtData.numUsers)
            end
        end
    )
end

function hmijing.loadcundang(whichPlayer)
    for i, singleMijing in ipairs(hmijing[whichPlayer]) do
        local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(singleMijing.maxKey, false)
        local maxHistoryLevel =
            math.floor(tonumber(string.sub(cundang, singleMijing.maxCdStartIndex, singleMijing.maxCdEndIndex)) or 0)
        singleMijing.maxHistoryLevel = maxHistoryLevel

        local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(singleMijing.curKey, false)
        local currentLevel =
            math.floor(tonumber(string.sub(cundang, singleMijing.curCdStartIndex, singleMijing.curCdEndIndex)) or 0)
        hmijing.jihuomijing(singleMijing.name, whichPlayer, currentLevel, false)
    end
end

function hmijing.cundang(singleMijing, whichPlayer)
    local currentLevel = singleMijing.currentLevel
    local countStr = tostring(currentLevel)
    if string.len(countStr) == 0 then
        countStr = "00"
    elseif string.len(countStr) == 1 then
        countStr = "0" .. countStr
    elseif string.len(countStr) > 2 then
        countStr = "00"
    end
    hplayer.dzCunDang[whichPlayer].saveCundang(
        singleMijing.curKey,
        false,
        singleMijing.curCdStartIndex,
        singleMijing.curCdEndIndex,
        countStr
    )
    local maxHistoryLevel = singleMijing.maxHistoryLevel
    local countStr = tostring(maxHistoryLevel)
    if string.len(countStr) == 0 then
        countStr = "00"
    elseif string.len(countStr) == 1 then
        countStr = "0" .. countStr
    elseif string.len(countStr) > 2 then
        countStr = "00"
    end
    hplayer.dzCunDang[whichPlayer].saveCundang(
        singleMijing.maxKey,
        false,
        singleMijing.maxCdStartIndex,
        singleMijing.maxCdEndIndex,
        countStr
    )
end

function hmijing.jihuomijing(fubenName, whichPlayer, mijing, cundang)
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        err("未选取英雄")
        return
    end
    for i, singleMijing in ipairs(hmijing[whichPlayer]) do
        if singleMijing.name == fubenName then
            if singleMijing.currentLevel > mijing then
                return
            end
            singleMijing.currentLevel = mijing

            if singleMijing.currentLevel > singleMijing.maxHistoryLevel then
                singleMijing.maxHistoryLevel = singleMijing.currentLevel
            end
            if singleMijing.jiangliConfig ~= nil then
                for idx, v in ipairs(singleMijing.jiangliConfig) do
                    if
                        singleMijing.maxHistoryLevel >= v.startLevel and
                        hunit.getLevel(hero) >= singleMijing.effectiveLevel
                    then
                        local calcLevel = math.min(singleMijing.maxHistoryLevel, 33)
                        hbuff.addAttribute(
                            CONST_DAMAGE_SRC.skill,
                            hplayer.getMainHero(whichPlayer),
                            "damijin" .. singleMijing.name .. "attr" .. idx,
                            hattribute.getAttributeWithMulti(
                                v.attrPerLevel,
                                calcLevel - v.startLevel + 1
                            )
                        )
                    end
                end
            end
            ui_enable_achievement_data_at_category_and_idx(whichPlayer, "秘境", i)
            ui_update_text_achievement_data_at_category_and_idx(
                whichPlayer,
                "秘境",
                i,
                hmijing.getDescription(singleMijing)
            )
            if cundang then
                hmijing.cundang(singleMijing, whichPlayer)
                echo(hcolor.green("恭喜！") .. singleMijing.name .. "挑战层数到达新高！", whichPlayer)
            end
        end
    end
end
