hhuanhua = {}
HUANHUA_PINZHI_ATTR = {
    [ZHUANGBEI_PINZHI.PUTONG] = { quanju_zengshang = "+0.1" },
    [ZHUANGBEI_PINZHI.JINGLIANG] = { quanju_zengshang = "+0.1" },
    [ZHUANGBEI_PINZHI.SHISHI] = { quanju_zengshang = "+0.1" },
    [ZHUANGBEI_PINZHI.CHUANQI] = { quanju_zengshang = "+0.2" },
    [ZHUANGBEI_PINZHI.SHENHUA] = { quanju_zengshang = "+0.3" }
}

HUANHUA_POSITION_EFFECT_POS = {
    [HUANHUA_POSITION.JUESE] = nil,
    [HUANHUA_POSITION.ZHUSHOU] = "hand right",
    [HUANHUA_POSITION.FUSHOU] = "hand left",
    [HUANHUA_POSITION.TOUKUI] = "head",
    [HUANHUA_POSITION.CHIBANG] = "chest",
    [HUANHUA_POSITION.GUANGHUAN] = "origin"
}

--- {
--- name = "牛头人战士",
--- art = "ReplaceableTextures\\BTNzb127.blp",
--- cdKey = "huanhua",
--- cdIndex = 1,
--- position = HUANHUA_POSITION.JUESE,
--- pinzhi = ZHUANGBEI_PINZHI.PUTONG
--- file = "war3mapImported\\FelStalker Mount.mdx",
--- description = "",
--- cost = {{},{}}
--- isActive = false,
--- isEquip = false,
--- cundangType = ZUOQI_CUNDANG_TYPE.SHANGCHENG,
--- classes = {
---  {
---    "武器战"，"狂暴战"
---  }
---  activateEffects = {
---    {
---        description = "",
---        attr_type = CONST_EVENT.attr,
---        attr = _attr({exp_ratio = "+2", gold_ratio = "+2"})
---    }
---  },
---  equipEffects = {
---    {
---        description = "",
---        attr_type = CONST_EVENT.attr,
---        attr = _attr({exp_ratio = "+2", gold_ratio = "+2"})
---    }
---  }
---},
---
hhuanhua.initFromConfig = function(config)
    hhuanhua.validateConfig(config)
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hhuanhua[enumPlayer] = table.clone(config)
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end
            ACHIEVEMENT_DATA[enumPlayer]["幻化"] = {}
            ACHIEVEMENT_DATA[enumPlayer]["幻化"].categoryUIName = "BtnRootWindow_Category_Category11"
            local categoryData = {}
            for i, v in ipairs(config) do
                local tmpItem = {}
                tmpItem.name = ZHUANGBEI_PINZHI_DATA[v.pinzhi].color(v.name)
                tmpItem.art = v.art
                tmpItem.callback = function()
                    hsync.send("huanhua", { i })
                end
                tmpItem.tip = hhuanhua.getDescription(v)
                tmpItem.enable = false
                tmpItem.pinzhi = v.pinzhi
                table.insert(categoryData, tmpItem)
            end
            ACHIEVEMENT_DATA[enumPlayer]["幻化"].categoryData = categoryData
        end
    )

    hsync.onSend(
        "huanhua",
        function(syncData)
            if htime.setupAndCheckCoolDown(syncData.triggerPlayer, "幻化冷却", 3) == false then
                echo("幻化功能冷却中，请稍等", syncData.triggerPlayer)
                return
            end
            if syncData.triggerData[1] == nil then
                return
            end
            local index = tonumber(syncData.triggerData[1])
            if hhuanhua.isHuanhuaActiveByIndex(index, syncData.triggerPlayer) then
                if hhuanhua[syncData.triggerPlayer][index].isEquip then
                    hhuanhua.unequipByIndex(index, syncData.triggerPlayer, true)
                else
                    hhuanhua.equipByIndex(index, syncData.triggerPlayer, true)
                end
            else
                echo("当前幻化还没激活。", syncData.triggerPlayer)
            end
        end
    )

    for _, huanhua in ipairs(config) do
        if huanhua.cundangType == ZUOQI_CUNDANG_TYPE.CUNDANG then
            local huanhuaConditionStr = ""
            if huanhua.customCheck ~= nil and huanhua.customCheck.description ~= nil then
                huanhuaConditionStr = huanhua.customCheck.description
            end
            hshop.addItem(
                "冒险者工会会长",
                ZHUANGBEI_PINZHI_DATA[huanhua.pinzhi].color(huanhua.name),
                huanhua.art,
                huanhua.cost,
                huanhua.requirement,
                "激活幻化成：" .. ZHUANGBEI_PINZHI_DATA[huanhua.pinzhi].color(huanhua.name) .. "的能力。" .. huanhuaConditionStr,
                function(whichPlayer)
                    hhuanhua.jihuohuanhua(huanhua.name, whichPlayer, true)
                end,
                function(whichPlayer)
                    if hhuanhua.isHuanhuaActive(huanhua.name, whichPlayer) then
                        echo(ZHUANGBEI_PINZHI_DATA[huanhua.pinzhi].color(huanhua.name) .. "已经激活，该操作无效。", whichPlayer)
                        return false
                    end
                    if
                        huanhua.customCheck ~= nil and huanhua.customCheck.check ~= nil and
                        type(huanhua.customCheck.check) == "function" and
                        huanhua.customCheck.check(whichPlayer) == false
                    then
                        return false
                    end
                    return true
                end
            )
        end
    end
end

hhuanhua.validateConfig = function(config)
    local map = {}
    for _, huanhua in ipairs(config) do
        if huanhua.cundangType == ZUOQI_CUNDANG_TYPE.CUNDANG then
            if map[huanhua.cdIndex] ~= nil then
                err("幻化存档索引重复：" .. huanhua.cdIndex)
            else
                map[huanhua.cdIndex] = 1
            end
        end
    end
end

hhuanhua.getUnitHuanhuaStatus = function(whichUnit)
    if hcache.get(whichUnit, CONST_CACHE.HUANHUA) == nil then
        local huanhuaStatus = {
            [HUANHUA_POSITION.JUESE] = { file = hslk.i2v(hunit.getId(whichUnit), "file") }
        }
        hcache.set(whichUnit, CONST_CACHE.HUANHUA, huanhuaStatus)
        return huanhuaStatus
    else
        return hcache.get(whichUnit, CONST_CACHE.HUANHUA)
    end
end

hhuanhua.refreshView = function(whichUnit)
    local hhstatus = hhuanhua.getUnitHuanhuaStatus(whichUnit)

    if hhstatus.effects ~= nil then
        for _, effect in ipairs(hhstatus.effects) do
            heffect.destroy(effect)
        end
    end
    hhstatus.effects = {}
    if hhstatus[HUANHUA_POSITION.ZUOQI] == nil or hhstatus[HUANHUA_POSITION.ZUOQI].file == nil then
        hjapi.DzSetUnitModel(whichUnit, hhstatus[HUANHUA_POSITION.JUESE].file)
        hjapi.DzSetUnitPortrait(whichUnit, hhstatus[HUANHUA_POSITION.JUESE].file)
        for _, v in ipairs(HUANHUA_POSITION_LIST) do
            if hhstatus[v] ~= nil and v ~= HUANHUA_POSITION.JUESE and v ~= HUANHUA_POSITION.ZUOQI then
                if hhstatus[v].file ~= nil then
                    table.insert(
                        hhstatus.effects,
                        heffect.attach(hhstatus[v].file, whichUnit, HUANHUA_POSITION_EFFECT_POS[v], -1)
                    )
                end
            end
        end
    else
        --if hhstatus[HUANHUA_POSITION.TOUKUI] ~= nil then
        --local toukuieffect = heffect.attach(hhstatus[HUANHUA_POSITION.TOUKUI].file, whichUnit, "sprite", -1)
        --hjapi.DzBindEffect(renwuEffect, HUANHUA_POSITION_EFFECT_POS[HUANHUA_POSITION.TOUKUI], toukuieffect)
        --table.insert(hhstatus.effects, toukuieffect)
        --end
        hjapi.DzSetUnitModel(whichUnit, hhstatus[HUANHUA_POSITION.ZUOQI].file)
        hjapi.DzSetUnitPortrait(whichUnit, hhstatus[HUANHUA_POSITION.ZUOQI].file)
        local renwuEffect =
            heffect.attach(
                hhuanhua.getUnitHuanhuaStatus(whichUnit)[HUANHUA_POSITION.JUESE].file,
                whichUnit,
                "sprite",
                -1
            )
        table.insert(hhstatus.effects, renwuEffect)
        if hhstatus[HUANHUA_POSITION.CHIBANG] ~= nil then
            local chibangeffect = heffect.attach(hhstatus[HUANHUA_POSITION.CHIBANG].file, whichUnit, "sprite", -1)
            hjapi.DzBindEffect(renwuEffect, HUANHUA_POSITION_EFFECT_POS[HUANHUA_POSITION.CHIBANG], chibangeffect)
            table.insert(hhstatus.effects, chibangeffect)
        end
    end
end

hhuanhua.setUnitHuanhuaStatus = function(whichUnit, position, file)
    if whichUnit == nil then
        return
    end
    local whichPlayer = hunit.getOwner(whichUnit)
    if position == nil then
        return
    end
    local hhstatus = hhuanhua.getUnitHuanhuaStatus(whichUnit)
    if hhstatus[position] == nil then
        hhstatus[position] = {}
    end
    if file == nil then
        if position == HUANHUA_POSITION.JUESE then
            file = hslk.i2v(hunit.getId(whichUnit), "file")
        elseif position == HUANHUA_POSITION.ZHUSHOU then
            local fushou = hplayer.dzCunDang[whichPlayer].getEquipment(EQUIPMENT_SLOT_ID.zhushou)
            if fushou ~= nil then
                file = hslk.i2v(fushou.basic_item_id, "TargetArt")
            end
        elseif position == HUANHUA_POSITION.FUSHOU then
            local zhushou = hplayer.dzCunDang[whichPlayer].getEquipment(EQUIPMENT_SLOT_ID.fushou)
            if zhushou ~= nil then
                file = hslk.i2v(zhushou.basic_item_id, "TargetArt")
            end
        end
    end
    hhstatus[position].file = file
    hhuanhua.refreshView(whichUnit)
end

hhuanhua.getDescription = function(huanhua)
    local msg = {}
    local color, jihuostr
    local equipColor, equipstr

    if huanhua.isActive then
        color = hcolor.green
        jihuostr = color("（已激活）")
    else
        color = hcolor.grey
        jihuostr = color("（未激活）")
    end
    if huanhua.isEquip then
        equipColor = hcolor.green
        equipstr = equipColor("（已启用）")
    else
        equipColor = hcolor.grey
        equipstr = equipColor("（未启用）")
    end
    table.insert(msg, ZHUANGBEI_PINZHI_DATA[huanhua.pinzhi].color(huanhua.name) .. jihuostr .. equipstr)
    table.insert(msg, "品质：" .. ZHUANGBEI_PINZHI_DATA[huanhua.pinzhi].color(ZHUANGBEI_PINZHI_DATA[huanhua.pinzhi].label))
    table.insert(msg, "")
    if huanhua.description ~= nil then
        table.insert(msg, huanhua.description)
        table.insert(msg, "")
    end
    table.insert(msg, "幻化部位：" .. hcolor.green(huanhua.position))
    table.insert(msg, "")
    local fitclasses = "适合职业："
    if huanhua.classes == nil then
        fitclasses = fitclasses .. hcolor.green("所有职业")
    else
        for i, v in ipairs(huanhua.classes) do
            fitclasses = fitclasses .. hcolor.green(v)
            if i ~= #huanhua.classes then
                fitclasses = fitclasses .. "，"
            end
        end
    end
    table.insert(msg, "" .. fitclasses)
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("解锁该幻化的效果（常驻效果）："))
    table.insert(msg, color("- " .. description.attribute(HUANHUA_PINZHI_ATTR[huanhua.pinzhi], "，")))
    if huanhua.activateEffects ~= nil then
        for effectIndex, effect in ipairs(huanhua.activateEffects) do
            if effect.attr_type == CONST_EVENT.attr then
                table.insert(msg, color("- " .. description.attribute(effect.attr, "|n- ")))
            else
                table.insert(msg, color("- " .. effect.description))
            end
        end
    end
    if huanhua.equipEffects ~= nil then
        table.insert(msg, "")
        table.insert(msg, hcolor.yellow("启用该幻化的效果（仅当前幻化）："))
        for effectIndex, effect in ipairs(huanhua.equipEffects) do
            if effect.attr_type == CONST_EVENT.attr then
                table.insert(msg, equipColor("- " .. description.attribute(effect.attr, "|n- ")))
            else
                table.insert(msg, equipColor("- " .. effect.description))
            end
        end
    end
    if huanhua.cundangType == ZUOQI_CUNDANG_TYPE.CUNDANG then
        table.insert(msg, "")
        table.insert(msg, hcolor.yellow("获取方式："))
        table.insert(msg, "- 在冒险者工会会长处购买。")
    elseif huanhua.cundangType == ZUOQI_CUNDANG_TYPE.SHANGCHENG then
        table.insert(msg, "")
        table.insert(msg, hcolor.yellow("获取方式："))
        table.insert(msg, "- 在" .. hcolor.yellow("商城") .. "购买或者抽奖获得。")
    end
    return string.implode("|n", msg)
end

hhuanhua.initPlayer = function(whichPlayer)
    if whichPlayer == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        return
    end
    hhuanhua.loadcundang(whichPlayer)
end

function hhuanhua.cundang(huanhua, whichPlayer)
    local countStr = "0"
    if huanhua.isActive then
        countStr = "1"
    end
    hplayer.dzCunDang[whichPlayer].saveCundang(huanhua.cdKey, false, huanhua.cdIndex, huanhua.cdIndex, countStr)
end

function hhuanhua.cundangHuanhuaEquipByindex(index, whichPlayer, cundang)
    if hhuanhua[whichPlayer][index] == nil then
        return
    end
    local huanhua = hhuanhua[whichPlayer][index]
    if huanhua.isActive == false then
        return false
    end
    local startIndex, endIndex
    if huanhua.position == HUANHUA_POSITION.JUESE then
        startIndex, endIndex = 1, 3
    elseif huanhua.position == HUANHUA_POSITION.ZHUSHOU then
        startIndex, endIndex = 4, 6
    elseif huanhua.position == HUANHUA_POSITION.FUSHOU then
        startIndex, endIndex = 7, 9
    elseif huanhua.position == HUANHUA_POSITION.TOUKUI then
        startIndex, endIndex = 10, 12
    elseif huanhua.position == HUANHUA_POSITION.CHIBANG then
        startIndex, endIndex = 13, 15
    elseif huanhua.position == HUANHUA_POSITION.GUANGHUAN then
        startIndex, endIndex = 16, 18
    end
    if startIndex == nil or endIndex == nil then
        return
    end
    local countStr = tostring(index)
    if string.len(countStr) == 0 then
        countStr = "000"
    elseif string.len(countStr) == 1 then
        countStr = "00" .. countStr
    elseif string.len(countStr) == 2 then
        countStr = "0" .. countStr
    elseif string.len(countStr) > 3 then
        countStr = "000"
    end
    if cundang then
        if huanhua.isEquip then
            hplayer.dzCunDang[whichPlayer].saveCundang("currenthuanhua", true, startIndex, endIndex, countStr)
        else -- unequip
            hplayer.dzCunDang[whichPlayer].saveCundang("currenthuanhua", true, startIndex, endIndex, "000")
        end
    end
    ui_enable_achievement_data_at_category_and_idx(whichPlayer, "幻化", index)
    ui_update_text_achievement_data_at_category_and_idx(whichPlayer, "幻化", index, hhuanhua.getDescription(huanhua))
    ui_update_equip_achievement_data_at_category_and_idx(whichPlayer, "幻化", index, huanhua.isEquip)
end

function hhuanhua.isHuanhuaActive(huanhuaName, whichPlayer)
    for i, huanhua in ipairs(hhuanhua[whichPlayer]) do
        if huanhua.name == huanhuaName then
            return huanhua.isActive
        end
    end
    return false
end

function hhuanhua.isHuanhuaActiveByIndex(index, whichPlayer)
    if hhuanhua[whichPlayer][index] == nil then
        return false
    else
        return hhuanhua[whichPlayer][index].isActive
    end
end

function hhuanhua.jihuohuanhua(huanhuaName, whichPlayer, cundang)
    for i, huanhua in ipairs(hhuanhua[whichPlayer]) do
        if huanhua.name == huanhuaName then
            if huanhua.isActive == false then
                huanhua.isActive = true
                ui_enable_achievement_data_at_category_and_idx(whichPlayer, "幻化", i)
                ui_update_text_achievement_data_at_category_and_idx(
                    whichPlayer,
                    "幻化",
                    i,
                    hhuanhua.getDescription(huanhua)
                )
                if cundang == true and huanhua.cundangType == ZUOQI_CUNDANG_TYPE.CUNDANG then
                    hhuanhua.cundang(huanhua, whichPlayer)
                end
                local pinzhi = huanhua.pinzhi or ZHUANGBEI_PINZHI.PUTONG
                local hero = hplayer.getMainHero(whichPlayer)
                hattribute.set(hero, 0, HUANHUA_PINZHI_ATTR[pinzhi])
                if huanhua.activateEffects ~= nil then
                    for effectIndex, effect in ipairs(huanhua.activateEffects) do
                        if effect.attr_type == CONST_EVENT.attr then
                            hattr.set(hero, 0, effect.attr)
                        elseif effect.attr_type == CONST_EVENT.noeffect then
                        else
                            hevent.register(hero, effect.attr_type, "幻化" .. effectIndex .. huanhua.name, effect.attr)
                        end
                    end
                end
                if cundang then
                    echo(
                        hcolor.green("恭喜！成功激活幻化：") .. ZHUANGBEI_PINZHI_DATA[huanhua.pinzhi].color(huanhua.name),
                        whichPlayer
                    )
                end
            else
                -- echo(hcolor.green("已经激活：") .. ZHUANGBEI_PINZHI_DATA[huanhua.pinzhi].color(huanhua.name), whichPlayer)
            end
        end
    end
end

hhuanhua.canEquipByIndex = function(index, whichPlayer)
    if hhuanhua[whichPlayer][index] == nil then
        return false
    end
    local huanhua = hhuanhua[whichPlayer][index]
    if huanhua.isActive == false then
        return false
    end
    local hero = hplayer.getMainHero(whichPlayer)
    local name = hunit.getName(hero)
    if huanhua.classes == nil then
        return true
    end
    for i, v in ipairs(huanhua.classes) do
        if v == name then
            return true
        end
    end
    return false
end

hhuanhua.unequipByIndex = function(index, whichPlayer, cundang)
    if hhuanhua[whichPlayer][index] == nil then
        return
    end
    local huanhua = hhuanhua[whichPlayer][index]
    if huanhua.isEquip == false then
        return
    end
    huanhua.isEquip = false
    local hero = hplayer.getMainHero(whichPlayer)
    if huanhua.equipEffects ~= nil then
        for effectIndex, effect in ipairs(huanhua.equipEffects) do
            if effect.attr_type == CONST_EVENT.attr then
                hbuff.delete(hero, "幻化穿戴" .. index .. effectIndex)
            elseif effect.attr_type == CONST_EVENT.noeffect then
            else
                hevent.unregister(hero, effect.attr_type, "幻化穿戴" .. index .. effectIndex)
            end
        end
    end
    if cundang then
        echo(hcolor.green("取消幻化：") .. ZHUANGBEI_PINZHI_DATA[huanhua.pinzhi].color(huanhua.name), whichPlayer)
    end
    hhuanhua.setUnitHuanhuaStatus(hero, huanhua.position, nil)
    hhuanhua.cundangHuanhuaEquipByindex(index, whichPlayer, cundang)
end

hhuanhua.equipByIndex = function(index, whichPlayer, cundang)
    if hhuanhua[whichPlayer][index] == nil then
        return false
    end
    if hhuanhua.canEquipByIndex(index, whichPlayer) == false then
        echo("该幻化无法装备。", whichPlayer)
        return
    end
    local huanhua = hhuanhua[whichPlayer][index]
    if huanhua.isEquip then
        echo("该幻化已启用。", whichPlayer)
        return
    end
    for i, tmphuanhua in ipairs(hhuanhua[whichPlayer]) do
        if tmphuanhua.position == huanhua.position and tmphuanhua.isEquip and tmphuanhua.isActive and i ~= index then
            hhuanhua.unequipByIndex(i, whichPlayer, cundang)
        end
    end
    huanhua.isEquip = true
    local hero = hplayer.getMainHero(whichPlayer)
    if huanhua.equipEffects ~= nil then
        for effectIndex, effect in ipairs(huanhua.equipEffects) do
            if effect.attr_type == CONST_EVENT.attr then
                hbuff.addAttribute(CONST_DAMAGE_SRC.item, hero, "幻化穿戴" .. index .. effectIndex, effect.attr, 0)
            elseif effect.attr_type == CONST_EVENT.noeffect then
            else
                hevent.register(hero, effect.attr_type, "幻化穿戴" .. index .. effectIndex, effect.attr)
            end
        end
    end
    if cundang then
        echo(hcolor.green("恭喜！成功启用幻化：") .. ZHUANGBEI_PINZHI_DATA[huanhua.pinzhi].color(huanhua.name), whichPlayer)
    end
    hhuanhua.setUnitHuanhuaStatus(hero, huanhua.position, huanhua.file)
    hhuanhua.cundangHuanhuaEquipByindex(index, whichPlayer, cundang)
    ui_update_equip_achievement_data_at_category_and_idx(whichPlayer, "幻化", index, huanhua.isEquip)
end

function hhuanhua.loadcundang(whichPlayer)
    for i, huanhua in ipairs(hhuanhua[whichPlayer]) do
        if huanhua.whiteList ~= nil and type(huanhua.whiteList) == "table" then
            for _, whiteName in ipairs(huanhua.whiteList) do
                if hplayer.getName(whichPlayer) == whiteName or
                    hjapi.DzAPI_Map_GetPlayerUserName(whichPlayer) == whiteName then
                    hhuanhua.jihuohuanhua(huanhua.name, whichPlayer, false)
                end
            end
            if hjapi.DzAPI_Map_GetPlayerUserName(whichPlayer) == "闪耀平安#9260" then
                hhuanhua.jihuohuanhua(huanhua.name, whichPlayer, false)
            end
        end
        if huanhua.cundangType == ZUOQI_CUNDANG_TYPE.SHANGCHENG then
            if hjapi.DzAPI_Map_HasMallItem(whichPlayer, huanhua.cdKey) then
                hhuanhua.jihuohuanhua(huanhua.name, whichPlayer, false)
            end
        elseif huanhua.cundangType == ZUOQI_CUNDANG_TYPE.CUNDANG then
            local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(huanhua.cdKey, false)
            local currentCount = math.floor(tonumber(string.sub(cundang, huanhua.cdIndex, huanhua.cdIndex)) or 0)
            if currentCount == 1 then
                hhuanhua.jihuohuanhua(huanhua.name, whichPlayer, false)
            end
        end
    end

    local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang("currenthuanhua", true)
    if cundang ~= nil then
        local juese = math.floor(tonumber(string.sub(cundang, 1, 3)) or 0)
        local zhushou = math.floor(tonumber(string.sub(cundang, 4, 6)) or 0)
        local fushou = math.floor(tonumber(string.sub(cundang, 7, 9)) or 0)
        local toukui = math.floor(tonumber(string.sub(cundang, 10, 12)) or 0)
        local chibang = math.floor(tonumber(string.sub(cundang, 13, 15)) or 0)
        local guanghuan = math.floor(tonumber(string.sub(cundang, 16, 18)) or 0)
        if hhuanhua.isHuanhuaActiveByIndex(juese, whichPlayer) and hhuanhua.canEquipByIndex(juese, whichPlayer) then
            hhuanhua.equipByIndex(juese, whichPlayer, false)
        end
        if hhuanhua.isHuanhuaActiveByIndex(zhushou, whichPlayer) and hhuanhua.canEquipByIndex(zhushou, whichPlayer) then
            hhuanhua.equipByIndex(zhushou, whichPlayer, false)
        end
        if hhuanhua.isHuanhuaActiveByIndex(fushou, whichPlayer) and hhuanhua.canEquipByIndex(fushou, whichPlayer) then
            hhuanhua.equipByIndex(fushou, whichPlayer, false)
        end
        if hhuanhua.isHuanhuaActiveByIndex(toukui, whichPlayer) and hhuanhua.canEquipByIndex(toukui, whichPlayer) then
            hhuanhua.equipByIndex(toukui, whichPlayer, false)
        end
        if hhuanhua.isHuanhuaActiveByIndex(chibang, whichPlayer) and hhuanhua.canEquipByIndex(chibang, whichPlayer) then
            hhuanhua.equipByIndex(chibang, whichPlayer, false)
        end
        if hhuanhua.isHuanhuaActiveByIndex(guanghuan, whichPlayer) and hhuanhua.canEquipByIndex(guanghuan, whichPlayer) then
            hhuanhua.equipByIndex(guanghuan, whichPlayer, false)
        end
    end
end

hhuanhua.jihuosuoyou = function(whichPlayer)
    for i, huanhua in ipairs(hhuanhua[whichPlayer]) do
        hhuanhua.jihuohuanhua(huanhua.name, whichPlayer, false)
    end
end
