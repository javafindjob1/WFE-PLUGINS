hfuwen                    = {}

---{
---  name = "火焰旋风",
---  art = "ReplaceableTextures\\BTNzb127.blp",
---  expKey = "mjexphyxf",
---  fuwenKey = "mjfwhyxf",
---  description = function() return "增加自身移速50点，并持续对周围造成50%主属性伤害，持续5秒" end,
---  currentExp = 0,
---  isActive = false,
---  isEquipped = false,
---  attr_type = CONST_EVENT.attr,
---  attr = function(EvtData,fuwen) end,
---  fuwenStatus = {
---    {
---      description = function(pinzhi) return "增加自身移速50点，并持续对周围造成50%主属性伤害，持续5秒" end,
---      currentLevel = 0
---      diaoluoFuben = {},
---    },
---  },
---},
hfuwen.initFromConfig     = function(config, dropRateConfig)
    assert(type(config) == "table", "配置必须是一个表")
    assert(type(dropRateConfig) == "table", "掉落率配置必须是一个表")
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hfuwen[enumPlayer] = table.clone(config)
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end
            ACHIEVEMENT_DATA[enumPlayer]["秘技"] = {}
            ACHIEVEMENT_DATA[enumPlayer]["秘技"].categoryUIName = "BtnRootWindow_Category_Category13"
            local categoryData = {}
            for i, v in ipairs(config) do
                local tmpItem = {}
                tmpItem.name = v.name
                tmpItem.art = v.art
                tmpItem.callback = function()
                    hsync.send("equip_miji", { i })
                end
                tmpItem.tip = hfuwen.getDescription(v)
                tmpItem.enable = true
                tmpItem.equip = false
                table.insert(categoryData, tmpItem)
            end
            ACHIEVEMENT_DATA[enumPlayer]["秘技"].categoryData = categoryData
        end
    )

    hsync.onSend(
        "equip_miji",
        function(syncData)
            if htime.setupAndCheckCoolDown(syncData.triggerPlayer, "equip_miji", 10) then
                echo("秘技切换冷却中，请稍后再试", syncData.triggerPlayer)
                return
            end
            local hero = hplayer.getMainHero(syncData.triggerPlayer)
            if hero == nil then
                return
            end
            if hfightzhuangtai.isInFight(hero) then
                echo("战斗中无法装备秘技。", syncData.triggerPlayer)
                return
            end
            if syncData.triggerData[1] == nil then
                return
            end
            local index = tonumber(syncData.triggerData[1])
            if index == nil or index <= 0 or index > #hfuwen[syncData.triggerPlayer] then
                echo("无效的秘技索引。", syncData.triggerPlayer)
                return
            end

            local fuwen = hfuwen[syncData.triggerPlayer][index]
            if fuwen == nil then
                echo("未找到指定的秘技。", syncData.triggerPlayer)
                return
            end

            if fuwen.isEquipped then
                hfuwen.unEquipMiji(fuwen.name, true, syncData.triggerPlayer)
            else
                hfuwen.equipMiji(fuwen.name, true, syncData.triggerPlayer)
            end
        end
    )

    -- 爆率配置变量
    hfuwen.dropRateConfig = dropRateConfig
end

-- 计算符文等级
hfuwen.getMijilevel       = function(fuwen)
    local currentExp = fuwen.currentExp or 0
    local level = 0

    while currentExp >= hfuwen.getLevelExp(level) do
        currentExp = currentExp - hfuwen.getLevelExp(level)
        level = level + 1
    end

    return level
end

-- 计算某一等级所需的经验值
hfuwen.getLevelExp        = function(level)
    return math.floor(10 + 20 * (level) ^ 1.3)
end

-- 计算升级所需经验
hfuwen.getShengjiExp      = function(fuwen)
    local currentLevel = hfuwen.getMijilevel(fuwen)
    local totalExpForNextLevel = hfuwen.getLevelExp(currentLevel)
    local currentLevelExp = fuwen.currentExp - hfuwen.getTotalExpToLevel(currentLevel)
    return totalExpForNextLevel - currentLevelExp
end

-- 计算达到某一等级所需的总经验值
hfuwen.getTotalExpToLevel = function(level)
    local totalExp = 0
    for i = 0, level - 1, 1 do
        totalExp = totalExp + hfuwen.getLevelExp(i)
    end
    return totalExp
end

hfuwen.getDescription     = function(fuwen)
    local msg = {}
    local color
    if fuwen.isEquipped then
        color = hcolor.green
        table.insert(msg, color(fuwen.name) .. color("（已装备）"))
    else
        color = hcolor.grey
        table.insert(msg, color(fuwen.name) .. color("（未装备）"))
    end
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("等级：") .. hcolor.green(tostring(hfuwen.getMijilevel(fuwen))))
    table.insert(msg,
        hcolor.yellow("升级所需经验：") ..
        hcolor.green(tostring(hfuwen.getShengjiExp(fuwen))) ..
        "，今日还可获取：" .. hcolor.green(tostring(fuwen.maxExp - fuwen.currentExp))
    )
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("秘技效果：") .. fuwen.description(fuwen))
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("符文效果："))
    for fuwenIndex, singleFuwen in ipairs(fuwen.fuwenStatus) do
        if singleFuwen.currentLevel > 0 and singleFuwen.currentLevel < 6 then
            local pinzhiColor = ZHUANGBEI_PINZHI_DATA[singleFuwen.currentLevel].color
            table.insert(msg,
                hcolor.green("符文" .. fuwenIndex) ..
                ": " .. pinzhiColor(singleFuwen.description(singleFuwen.currentLevel)))
        else
            table.insert(msg,
                hcolor.grey("符文" .. fuwenIndex .. ": " .. singleFuwen.description(singleFuwen.currentLevel)))
        end
    end
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("说明："))
    table.insert(msg, "- 每个冒险者初始只能激活一个秘技，点击装备秘技")
    table.insert(msg, "- 每个秘技可以由符文进行升级，升级后效果更强")
    table.insert(msg, "- 符文由传奇秘境掉落")
    table.insert(msg, "- 符文有不同的品质，品质越高效果越强")
    table.insert(msg, "- 获得符文后，如果当前符文没激活，或者当前符文品质低于获得的符文，则会自动激活符文")
    table.insert(msg, "- 获得符文后，如果当前符文已激活或品质没有高于当前符文，则会转化为经验升级秘技等级，普通/精良/史诗/传奇符文分别提供1/2/10/50点经验")
    table.insert(msg, "- 秘技每日获取经验有限，6个技能总共上限为300点")
    table.insert(msg, "- 每次完成副本会掉落一个符文，每多一个玩家，符文掉落次数会加1")
    table.insert(msg, "- 所有传奇秘境有概率掉落所有符文")
    return string.implode("|n", msg)
end

hfuwen.initPlayer         = function(whichPlayer)
    if whichPlayer == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        return
    end
    hfuwen.loadcundang(whichPlayer)
end

function hfuwen.cundang(fuwen, whichPlayer)
    hplayer.dzCunDang[whichPlayer].saveCundangWihtoutIndx(fuwen.expKey, false, fuwen.currentExp, true)
    for j, singleFuwen in ipairs(fuwen.fuwenStatus) do
        if singleFuwen.currentLevel > 0 and singleFuwen.currentLevel < 6 then
            local cdStr = tostring(singleFuwen.currentLevel)
            hplayer.dzCunDang[whichPlayer].saveCundang(fuwen.fuwenKey, false, j, j, cdStr)
        end
    end
    if fuwen.isEquipped then
        hplayer.dzCunDang[whichPlayer].saveCundang(fuwen.fuwenKey, false, 63, 63, "1")
    else
        hplayer.dzCunDang[whichPlayer].saveCundang(fuwen.fuwenKey, false, 63, 63, "0")
    end
end

function hfuwen.equipMiji(fuwenName, cundang, whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    if hunit.getLevel(hero) < 61 then
        if cundang then
            echo(hcolor.yellow("英雄等级不足10级，无法装备秘技"), whichPlayer)
        end
        return
    end
    if hero == nil then return end
    -- 先卸下所有秘技
    for _, fuwen in ipairs(hfuwen[whichPlayer]) do
        if fuwen.isEquipped then
            hfuwen.unEquipMiji(fuwen.name, cundang, whichPlayer)
        end
    end

    -- 装备新的秘技
    for i, fuwen in ipairs(hfuwen[whichPlayer]) do
        if fuwen.name == fuwenName then
            fuwen.isEquipped = true
            ui_update_equip_achievement_data_at_category_and_idx(whichPlayer, "秘技", i, true)
            ui_update_text_achievement_data_at_category_and_idx(whichPlayer, "秘技", i, hfuwen.getDescription(fuwen))
            if cundang then
                hfuwen.cundang(fuwen, whichPlayer)
                echo(hcolor.green("已装备秘技：" .. fuwenName), whichPlayer)
            end
            hevent.register(hero, fuwen.attr_type, "miji" .. i, function(evtData)
                fuwen.attr(evtData, fuwen)
            end)
            return
        end
    end

    echo(hcolor.yellow("未找到指定的秘技：" .. fuwenName), whichPlayer)
end

function hfuwen.unEquipMiji(fuwenName, cundang, whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then return end
    for i, fuwen in ipairs(hfuwen[whichPlayer]) do
        if fuwen.name == fuwenName and fuwen.isEquipped then
            fuwen.isEquipped = false
            ui_update_equip_achievement_data_at_category_and_idx(whichPlayer, "秘技", i, false)
            ui_update_text_achievement_data_at_category_and_idx(whichPlayer, "秘技", i, hfuwen.getDescription(fuwen))
            if cundang then
                hfuwen.cundang(fuwen, whichPlayer)
                echo(hcolor.grey("已卸下秘技：" .. fuwenName), whichPlayer)
            end
            hevent.unregister(hero, fuwen.attr_type, "miji" .. i)
            return
        end
    end
    echo(hcolor.yellow("该秘技未装备，无需卸下"), whichPlayer)
end

function hfuwen.jihuofuwen(mijiname, fuwenIndex, cundang, whichPlayer, fuwenLevel)
    if fuwenLevel == nil or fuwenLevel > 5 then
        err("符文等级错误：" .. fuwenLevel)
        return
    end
    for i, fuwen in ipairs(hfuwen[whichPlayer]) do
        if fuwen.name == mijiname then
            if fuwen.fuwenStatus[fuwenIndex].currentLevel < fuwenLevel then
                fuwen.fuwenStatus[fuwenIndex].currentLevel = fuwenLevel

                ui_enable_achievement_data_at_category_and_idx(whichPlayer, "秘技", i)
                ui_update_text_achievement_data_at_category_and_idx(whichPlayer, "秘技", i, hfuwen.getDescription(fuwen))
                if cundang == true then
                    hfuwen.cundang(fuwen, whichPlayer)
                    local pinzhiColor = ZHUANGBEI_PINZHI_DATA[fuwen.fuwenStatus[fuwenIndex].currentLevel].color
                    local singleFuwenPinzhiText = pinzhiColor("符文" .. fuwenIndex .. "（" .. ZHUANGBEI_PINZHI_DATA
                        [fuwen.fuwenStatus[fuwenIndex].currentLevel].label .. "）")
                    echo(hcolor.green("恭喜！成功激活：" .. mijiname) .. singleFuwenPinzhiText, whichPlayer)
                end
            elseif cundang then
                local exp = 0
                if fuwenLevel == 1 then
                    exp = 1
                elseif fuwenLevel == 2 then
                    exp = 2
                elseif fuwenLevel == 3 then
                    exp = 10
                elseif fuwenLevel == 4 then
                    exp = 50
                end
                hfuwen.zengjiafuewnjingyan(mijiname, whichPlayer, cundang, exp)
            end
        end
    end
end

function hfuwen.diaoluoFuwen(fubenName, mijingLevel, whichPlayer, count)
    if whichPlayer == nil then
        err("玩家为空")
        return
    end
    if hplayer.isPlaying(whichPlayer) == false then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        return
    end
    if hditudengji.getDitudengji(whichPlayer) >= 45 then
        count = count + 1
    end
    for i = 1, count do
        -- 收集所有符合条件的符文
        local eligibleFuwens = {}
        for _, fuwen in ipairs(hfuwen[whichPlayer]) do
            for fuwenIndex, singleFuwen in ipairs(fuwen.fuwenStatus) do
                table.insert(eligibleFuwens, { fuwen = fuwen, index = fuwenIndex })
            end
        end

        local diaolv = hattr.getWithLimit(hero, nil, "fuwen_diaolv", 0)
        -- 如果有符合条件的符文，随机选择一个
        if #eligibleFuwens > 0 then
            local randomIndex = math.random(1, #eligibleFuwens)
            local selectedFuwen = eligibleFuwens[randomIndex]
            local fuwenLevel = hfuwen.getRandomFuwenLevel(fubenName, mijingLevel, diaolv)
            if fuwenLevel == 0 then
                echo(hcolor.yellow("符文掉落机会" .. i .. "：") .. hcolor.grey("未掉落符文"), whichPlayer)
            else
                local color = ZHUANGBEI_PINZHI_DATA[fuwenLevel].color
                echo(
                    hcolor.yellow("符文掉落机会" .. i .. "：") .. "恭喜，成功掉落符文" .. color(selectedFuwen.fuwen.name .. "符文" ..
                        selectedFuwen.index .. "（" .. ZHUANGBEI_PINZHI_DATA[fuwenLevel].label .. "）"), whichPlayer)
                hfuwen.jihuofuwen(selectedFuwen.fuwen.name, selectedFuwen.index, true, whichPlayer, fuwenLevel)
            end
        end
    end
end

function hfuwen.getRandomFuwenLevel(fubenName, mijingLevel, diaolv)
    if hfuwen.dropRateConfig == nil then
        err("符文掉落配置为空")
        return 0
    end
    if hfuwen.dropRateConfig[fubenName] == nil then
        err(fubenName .. "副本的符文掉落配置为空")
        return 0
    end
    local fuwen = hfuwen.dropRateConfig[fubenName]
    local dropRates = fuwen[mijingLevel] or fuwen[1]
    if mijingLevel > 30 then
        dropRates = fuwen[30]
    end

    -- 从最高级（5级）开始判断
    for level = 5, 1, -1 do
        local rate = dropRates[level]
        rate = rate * (1 + diaolv / 100)
        if rate > 0 then
            local randomNum = math.random(1, 10000)
            if randomNum <= rate then
                return level
            end
        end
    end

    return 0 -- 如果所有级别都没有掉落，默认返回0级符文
end

function hfuwen.zengjiafuewnjingyan(mijiname, whichPlayer, cundang, exp)
    for i, fuwen in ipairs(hfuwen[whichPlayer]) do
        if fuwen.name == mijiname then
            if fuwen.currentExp >= fuwen.maxExp then
                echo(hcolor.yellow(fuwen.name .. "经验获取已达到今日上限"), whichPlayer)
                return
            elseif fuwen.currentExp + exp >= fuwen.maxExp then
                exp = fuwen.maxExp - fuwen.currentExp
            end
            fuwen.currentExp = fuwen.currentExp + exp
            ui_enable_achievement_data_at_category_and_idx(whichPlayer, "秘技", i)
            ui_update_text_achievement_data_at_category_and_idx(whichPlayer, "秘技", i, hfuwen.getDescription(fuwen))
            if cundang == true then
                hfuwen.cundang(fuwen, whichPlayer)
                echo(hcolor.green(mijiname .. "获得经验：" .. exp), whichPlayer)
            end
        end
    end
end

function hfuwen.loadcundang(whichPlayer)
    for _, fuwen in ipairs(hfuwen[whichPlayer]) do
        local exp = tonumber(hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(fuwen.expKey, false, true, true)) or 0
        local limit = tonumber(hplayer.dzCunDang[whichPlayer].loadDailyLimitKey(fuwen.expKey, false)) or 0
        fuwen.maxExp = limit + exp
        hfuwen.zengjiafuewnjingyan(fuwen.name, whichPlayer, false, exp)
        local fuwenCudnang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(fuwen.fuwenKey, false, false, false)
        for j, _ in ipairs(fuwen.fuwenStatus) do
            local fuwenLevel = tonumber(string.sub(fuwenCudnang, j, j)) or 0
            if fuwenLevel > 0 then
                hfuwen.jihuofuwen(fuwen.name, j, false, whichPlayer, fuwenLevel)
            end
        end
        if string.sub(fuwenCudnang, 63, 63) == "1" then -- 装备
            hfuwen.equipMiji(fuwen.name, false, whichPlayer)
        end
    end
end

function hfuwen.upgradeAllFuwenByOne(whichPlayer)
    if whichPlayer == nil then
        err("玩家为空")
        return
    end

    for _, fuwen in ipairs(hfuwen[whichPlayer]) do
        for fuwenIndex, singleFuwen in ipairs(fuwen.fuwenStatus) do
            if singleFuwen.currentLevel < 5 then
                local newLevel = singleFuwen.currentLevel + 1
                hfuwen.jihuofuwen(fuwen.name, fuwenIndex, false, whichPlayer, newLevel)
            end
        end
    end

    echo(hcolor.green("所有已激活的符文等级已提升1级"), whichPlayer)
end
