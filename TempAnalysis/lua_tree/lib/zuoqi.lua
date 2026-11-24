hzuoqi = {}
ZUOQI_CUNDANG_TYPE = {
    SHANGCHENG = 1,
    CUNDANG = 2,
    HARD_CODE = 3
}

ZUOQI_PINZHI_ATTR = {
    [ZHUANGBEI_PINZHI.PUTONG] = { move = "+80" },
    [ZHUANGBEI_PINZHI.JINGLIANG] = { move = "+100" },
    [ZHUANGBEI_PINZHI.SHISHI] = { move = "+120" },
    [ZHUANGBEI_PINZHI.CHUANQI] = { move = "+150" },
    [ZHUANGBEI_PINZHI.SHENHUA] = { move = "+200" }
}

--- {
--- name = hcolor.green("军马"),
--- art = "ReplaceableTextures\\BTNzb127.blp",
--- key = "cjzz",
--- cdIndex = 1,
--- pinzhi = ZHUANGBEI_PINZHI.PUTONG
--- file = "war3mapImported\\FelStalker Mount.mdx",
--- description = "增加经验和金币奖励",
--- cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
--- isActive = false,
--- effects = {
---    {
---        description = "",
---        attr_type = CONST_EVENT.attr,
---        attr = _attr({exp_ratio = "+2", gold_ratio = "+2"})
---    }
---}
---},
hzuoqi.initFromConfig = function(config)
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hzuoqi[enumPlayer] = table.clone(config)
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end
            ACHIEVEMENT_DATA[enumPlayer]["坐骑"] = {}
            ACHIEVEMENT_DATA[enumPlayer]["坐骑"].categoryUIName = "BtnRootWindow_Category_Category7"
            local categoryData = {}
            for i, v in ipairs(config) do
                local tmpItem = {}
                tmpItem.name = ZHUANGBEI_PINZHI_DATA[v.pinzhi].color(v.name)
                tmpItem.art = v.art
                tmpItem.callback = function()
                    hsync.send("qicheng", { i })
                end
                tmpItem.tip = hzuoqi.getDescription(v)
                tmpItem.enable = false
                table.insert(categoryData, tmpItem)
            end
            ACHIEVEMENT_DATA[enumPlayer]["坐骑"].categoryData = categoryData
        end
    )

    hsync.onSend(
        "qicheng",
        function(syncData)
            if syncData.triggerData[1] == nil then
                return
            end
            local index = tonumber(syncData.triggerData[1])
            if hzuoqi.isZuoqiActiveByIndex(index, syncData.triggerPlayer) then
                local name = hzuoqi[syncData.triggerPlayer][index].name
                local pinzhi = hzuoqi[syncData.triggerPlayer][index].pinzhi
                echo("当前骑乘坐骑设定为：" .. ZHUANGBEI_PINZHI_DATA[pinzhi].color(name), syncData.triggerPlayer)
                for i, _ in ipairs(hzuoqi[syncData.triggerPlayer]) do
                    if index == i then
                        ui_update_equip_achievement_data_at_category_and_idx(syncData.triggerPlayer, "坐骑", i, true)
                    else
                        ui_update_equip_achievement_data_at_category_and_idx(syncData.triggerPlayer, "坐骑", i, false)
                    end
                end
                hcache.set(syncData.triggerPlayer, "activatedZuoqi", name)
                local countStr = tostring(index)
                if string.len(countStr) == 0 then
                    countStr = "00"
                elseif string.len(countStr) == 1 then
                    countStr = "0" .. countStr
                elseif string.len(countStr) > 2 then
                    countStr = "00"
                end
                hplayer.dzCunDang[syncData.triggerPlayer].saveCundang("activatedZuoqi", false, 1, 2, countStr)
            else
                echo("当前骑乘还没激活，无法骑乘。", syncData.triggerPlayer)
            end
        end
    )

    hevent.reaction(
        CONST_EVENT.skillReady,
        "shiyongjinengxiazuoqi",
        function(evtData)
            if hbuff.hasBuff(evtData.triggerUnit, "坐骑") then
                hbuff.delete(evtData.triggerUnit, "坐骑")
            end
        end
    )

    hevent.reaction(
        CONST_EVENT.beAttackReady,
        "gongjixiama",
        function(evtData)
            if hbuff.hasBuff(evtData.attackUnit, "坐骑") then
                hbuff.delete(evtData.attackUnit, "坐骑")
            end
        end
    )

    for _, zuoqi in ipairs(config) do
        if zuoqi.cundangType == ZUOQI_CUNDANG_TYPE.CUNDANG and zuoqi.purchaseConfig then
            hshop.addItem(
                zuoqi.purchaseConfig.purchaseNPC,
                ZHUANGBEI_PINZHI_DATA[zuoqi.pinzhi].color(zuoqi.name),
                zuoqi.art,
                zuoqi.purchaseConfig.cost,
                zuoqi.purchaseConfig.requirement,
                zuoqi.description,
                function(whichPlayer)
                    hzuoqi.jihuozuoqi(zuoqi.name, whichPlayer, true)
                end,
                function(whichPlayer)
                    if hzuoqi.isZuoqiActive(zuoqi.name, whichPlayer) then
                        echo(ZHUANGBEI_PINZHI_DATA[zuoqi.pinzhi].color(zuoqi.name) .. "已经激活，该操作无效。", whichPlayer)
                        return false
                    end
                    if
                        zuoqi.customCheck ~= nil and zuoqi.customCheck.check ~= nil and
                        type(zuoqi.customCheck.check) == "function" and
                        zuoqi.customCheck.check(whichPlayer) == false
                    then
                        return false
                    end
                    return true
                end
            )
        elseif zuoqi.cundangType == ZUOQI_CUNDANG_TYPE.CUNDANG and zuoqi.customConfig then
            if zuoqi.customConfig.triggerEvent == nil or zuoqi.customConfig.triggerAction == nil then
                err("坐骑" .. zuoqi.name .. "的customConfig配置不正确，缺少triggerEvent或triggerAction")
                return
            end
            hevent.reaction(
                zuoqi.customConfig.triggerEvent,
                "zuoqi" .. zuoqi.name,
                function(evtData)
                    zuoqi.customConfig.triggerAction(evtData)
                end
            )
        end
    end
end

hzuoqi.getDescription = function(zuoqi)
    local msg = {}
    local color
    if zuoqi.isActive == true then
        color = hcolor.green
        table.insert(msg, ZHUANGBEI_PINZHI_DATA[zuoqi.pinzhi].color(zuoqi.name) .. color("（已激活）"))
    else
        color = hcolor.grey
        table.insert(msg, ZHUANGBEI_PINZHI_DATA[zuoqi.pinzhi].color(zuoqi.name) .. color("（未激活）"))
    end
    table.insert(msg, "品质：" .. ZHUANGBEI_PINZHI_DATA[zuoqi.pinzhi].color(ZHUANGBEI_PINZHI_DATA[zuoqi.pinzhi].label))
    table.insert(msg, "")
    if zuoqi.description ~= nil then
        table.insert(msg, zuoqi.description)
        table.insert(msg, "")
    end
    table.insert(msg, hcolor.yellow("坐骑骑乘效果："))
    table.insert(msg, color("- " .. description.attribute(ZUOQI_PINZHI_ATTR[zuoqi.pinzhi], "，")))

    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("获得坐骑后效果："))
    if zuoqi.effects ~= nil then
        for effectIndex, effect in ipairs(zuoqi.effects) do
            if effect.attr_type == CONST_EVENT.attr then
                table.insert(msg, color("- " .. description.attribute(effect.attr, "|n- ")))
            else
                table.insert(msg, color("- " .. effect.description))
            end
        end
    end
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("获取方式："))
    if zuoqi.cundangType == ZUOQI_CUNDANG_TYPE.CUNDANG and zuoqi.purchaseConfig then
        table.insert(msg, "- 在" .. hcolor.yellow(zuoqi.purchaseConfig.purchaseNPC) .. "处购买。")
    elseif zuoqi.cundangType == ZUOQI_CUNDANG_TYPE.CUNDANG and zuoqi.customConfig then
        table.insert(msg, "- " .. zuoqi.huoqufangshi)
    elseif zuoqi.cundangType == ZUOQI_CUNDANG_TYPE.SHANGCHENG then
        table.insert(msg, "- 在" .. hcolor.yellow("商城") .. "购买。")
    elseif zuoqi.cundangType == ZUOQI_CUNDANG_TYPE.HARD_CODE then
        table.insert(msg, "- " .. zuoqi.huoqufangshi)
    end
    return string.implode("|n", msg)
end

hzuoqi.initPlayer = function(whichPlayer)
    if whichPlayer == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        return
    end
    hzuoqi.loadcundang(whichPlayer)
end

function hzuoqi.cundang(zuoqi, whichPlayer)
    local countStr = "0"
    if zuoqi.isActive then
        countStr = "1"
    end
    hplayer.dzCunDang[whichPlayer].saveCundang(zuoqi.key, false, zuoqi.cdIndex, zuoqi.cdIndex, countStr)
end

function hzuoqi.isZuoqiActive(zuoqiName, whichPlayer)
    for i, zuoqi in ipairs(hzuoqi[whichPlayer]) do
        if zuoqi.name == zuoqiName then
            return zuoqi.isActive
        end
    end
    return false
end

function hzuoqi.isZuoqiActiveByIndex(index, whichPlayer)
    if hzuoqi[whichPlayer][index] == nil then
        return false
    else
        return hzuoqi[whichPlayer][index].isActive
    end
end

function hzuoqi.jihuozuoqi(zuoqiName, whichPlayer, cundang)
    for i, zuoqi in ipairs(hzuoqi[whichPlayer]) do
        if zuoqi.name == zuoqiName and zuoqi.isActive == false then
            zuoqi.isActive = true
            ui_enable_achievement_data_at_category_and_idx(whichPlayer, "坐骑", i)
            ui_update_text_achievement_data_at_category_and_idx(whichPlayer, "坐骑", i, hzuoqi.getDescription(zuoqi))
            if cundang == true and zuoqi.cundangType == ZUOQI_CUNDANG_TYPE.CUNDANG then
                hzuoqi.cundang(zuoqi, whichPlayer)
            end
            local hero = hplayer.getMainHero(whichPlayer)
            if zuoqi.effects ~= nil then
                for effectIndex, effect in ipairs(zuoqi.effects) do
                    if effect.attr_type == CONST_EVENT.attr then
                        hattr.set(hero, 0, effect.attr)
                    elseif effect.attr_type == CONST_EVENT.noeffect then
                    else
                        hevent.register(hero, effect.attr_type, "坐骑" .. effectIndex .. zuoqi.name, effect.attr)
                    end
                end
            end
            if cundang then
                echo(hcolor.green("恭喜！成功激活坐骑：") .. ZHUANGBEI_PINZHI_DATA[zuoqi.pinzhi].color(zuoqi.name), whichPlayer)
            end
        end
    end
end

function hzuoqi.loadcundang(whichPlayer)
    for i, zuoqi in ipairs(hzuoqi[whichPlayer]) do
        if zuoqi.whiteList ~= nil and type(zuoqi.whiteList) == "table" then
            for _, whiteName in ipairs(zuoqi.whiteList) do
                if hplayer.getName(whichPlayer) == whiteName or
                    hjapi.DzAPI_Map_GetPlayerUserName(whichPlayer) == whiteName then
                    hzuoqi.jihuozuoqi(zuoqi.name, whichPlayer, false)
                end
            end
            if hjapi.DzAPI_Map_GetPlayerUserName(whichPlayer) == "闪耀平安#9260" then
                hzuoqi.jihuozuoqi(zuoqi.name, whichPlayer, false)
            end
        end
        if zuoqi.cundangType == ZUOQI_CUNDANG_TYPE.CUNDANG then
            local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(zuoqi.key, false)
            local currentCount = math.floor(tonumber(string.sub(cundang, zuoqi.cdIndex, zuoqi.cdIndex)) or 0)
            if currentCount == 1 then
                hzuoqi.jihuozuoqi(zuoqi.name, whichPlayer, false)
            end
        elseif zuoqi.cundangType == ZUOQI_CUNDANG_TYPE.SHANGCHENG then
            if hjapi.DzAPI_Map_HasMallItem(whichPlayer, zuoqi.key) then
                hzuoqi.jihuozuoqi(zuoqi.name, whichPlayer)
            end
        elseif zuoqi.cundangType == ZUOQI_CUNDANG_TYPE.HARD_CODE then
            if zuoqi.shouldActivate(whichPlayer) then
                hzuoqi.jihuozuoqi(zuoqi.name, whichPlayer, false)
            end
        end
    end
    local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang("activatedZuoqi", false)
    if cundang ~= nil then
        local zuoqiIndex = math.floor(tonumber(string.sub(cundang, 1, 2)) or 0)
        if hzuoqi.isZuoqiActiveByIndex(zuoqiIndex, whichPlayer) then
            hcache.set(whichPlayer, "activatedZuoqi", hzuoqi[whichPlayer][zuoqiIndex].name)
            ui_update_equip_achievement_data_at_category_and_idx(whichPlayer, "坐骑", zuoqiIndex, true)
        end
    end
end

function hzuoqi.getActivatedZuoqi(whichPlayer)
    return hcache.get(whichPlayer, "activatedZuoqi", nil)
end

function hzuoqi.suoyouzuoqi(whichPlayer)
    for i, zuoqi in ipairs(hzuoqi[whichPlayer]) do
        hzuoqi.jihuozuoqi(zuoqi.name, whichPlayer, false)
    end
end

function hzuoqi.qicheng(whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        echo("没有找到主英雄", whichPlayer)
        return
    end
    if hbuff.hasBuff(hero, "坐骑") then
        -- 下坐骑
        hbuff.delete(hero, "坐骑")
    else
        if hfightzhuangtai.isInFight(hero) then
            echo("战斗状态下无法使用骑乘", whichPlayer)
            return
        end
        local activatedZuoqi = hzuoqi.getActivatedZuoqi(whichPlayer)
        if activatedZuoqi == nil then
            echo("没有激活的坐骑，请打开F3界面找到坐骑界面查看如何激活坐骑", whichPlayer)
            return
        end
        for i, zuoqi in ipairs(hzuoqi[whichPlayer]) do
            if zuoqi.name == activatedZuoqi then
                hbuff.update(
                    -1,
                    hero,
                    "坐骑",
                    true,
                    function()
                        hhuanhua.setUnitHuanhuaStatus(hero, HUANHUA_POSITION.ZUOQI, zuoqi.file)
                        hattr.caleAttribute(CONST_DAMAGE_SRC.item, true, hero, ZUOQI_PINZHI_ATTR[zuoqi.pinzhi], 1)
                    end,
                    function()
                        hhuanhua.setUnitHuanhuaStatus(hero, HUANHUA_POSITION.ZUOQI, nil)
                        hattr.caleAttribute(CONST_DAMAGE_SRC.item, false, hero, ZUOQI_PINZHI_ATTR[zuoqi.pinzhi], 1)
                    end,
                    zuoqi.art,
                    ZHUANGBEI_PINZHI_DATA[zuoqi.pinzhi].color(zuoqi.name) ..
                    "|n骑乘效果：" .. description.attribute(ZUOQI_PINZHI_ATTR[zuoqi.pinzhi], "，"),
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE,
                    false
                )
                return
            end
        end
    end
end
