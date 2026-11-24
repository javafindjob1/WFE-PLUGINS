hlianjin = {}

---
--- config = {
---     {
---        reqLevel = 1,
---        req = {
---          {name = "银叶草"，count = 2},
---          {name = "瓶子"， count = 1}
---        },
---        successRate = 10000
---        output = {
---          name = "基础生命恢复药剂",
---          itemLevel = 10,
---          itemPinzhi = ZHUANGBEI_PINZHI.putong,
---          count = 1,
---          upgradeRate,
---        },
---     },
---     {}
---}

hlianjin.init = function(config)
    hzhuanye.initSingleZhuanye(config, "制作", "炼金", CONST_EVENT.lianjin, nil)
    hevent.reaction(
        CONST_EVENT.itemUsed,
        "lianjinyaojishiyong",
        function(evtData)
            if
                evtData.triggerSkill == nil or evtData.triggerItem == nil or evtData.triggerUnit == nil or
                    hplayer.getMainHero(hunit.getOwner(evtData.triggerUnit)) ~= evtData.triggerUnit
             then
                return
            end
            if hskill.getName(evtData.triggerSkill) == "药剂使用" then
                local yaoji = evtData.triggerItem
                local dynamicItem = hitem.getDynamicItem(yaoji)
                if dynamicItem == nil then
                    hitem.destroy(yaoji)
                    return
                end
                if dynamicItem.stack < 1 then
                    hitem.destroy(yaoji)
                    return
                end
                local itemId = hitem.getId(yaoji)
                local duration = hslk.i2v(itemId, "_duration")
                local useLevel = hslk.i2v(itemId, "_useLevel")
                local maxLevel = hslk.i2v(itemId, "_maxLevel") or 999
                local hitemType = hitem.getHitemType(itemId)
                if hitemType ~= HITEM_TYPE.Yaoji and hitemType ~= HITEM_TYPE.Yaoshui and hitemType ~= HITEM_TYPE.Heji then
                    return
                end
                useLevel = useLevel or 1
                if useLevel > hunit.getLevel(evtData.triggerUnit) then
                    echo(hitemType .. "等级过高，无法生效", hunit.getOwner(evtData.triggerUnit))
                    return
                end
                if hunit.getLevel(evtData.triggerUnit) > maxLevel then
                    echo("角色等级过高，当前药水无法生效", hunit.getOwner(evtData.triggerUnit))
                    return
                end
                if duration == nil then
                    err("Duration is nil")
                end
                duration = duration or 10
                local whichUnit = evtData.triggerUnit
                local durationMulti = hattribute.getWithLimit(whichUnit, nil, "yaoshui_shijian", 0) / 100
                duration = duration + duration * durationMulti
                local attrEffect = hslk.i2v(itemId, "_attrEffect")
                local skillEffect = hslk.i2v(itemId, "_skillEffect")
                local yaojiName = hslk.i2v(itemId, "Name")
                hlianjin.attachYaoBuff(duration, whichUnit, hitemType, attrEffect, skillEffect, itemId, yaojiName)
                if dynamicItem.stack == 1 then
                    hitem.destroy(yaoji)
                    return
                end
                hitem.setCharges(yaoji, dynamicItem.stack - 1)
            elseif hskill.getName(evtData.triggerSkill) == "速效治疗石使用" then
                local yaoji = evtData.triggerItem
                local itemId = hitem.getId(yaoji)
                local shiyongxiaoguo = hslk.i2v(itemId, "_shiyongxiaoguo")
                if shiyongxiaoguo ~= nil and type(shiyongxiaoguo) == "function" then
                    shiyongxiaoguo(evtData)
                end
            end
        end
    )
end

hlianjin.attachYaoBuff = function(duration, whichUnit, hitemType, attrEffect, skillEffect, itemId, yaojiName)
    local coloredName = hitem.getColoredNameBasedOnPinzhi(yaojiName)
    hbuff.update(
        duration,
        whichUnit,
        hitemType,
        true,
        function()
            if attrEffect ~= nil then
                hattribute.caleAttribute(CONST_DAMAGE_SRC.item, true, whichUnit, attrEffect, 1)
            end
            if skillEffect ~= nil then
                for i, v in ipairs(skillEffect) do
                    hevent.register(whichUnit, v.attr_type, hitemType .. "effect " .. yaojiName, v.attr)
                end
            end
        end,
        function()
            if attrEffect ~= nil then
                hattribute.caleAttribute(CONST_DAMAGE_SRC.item, false, whichUnit, attrEffect, 1)
            end
            if skillEffect ~= nil then
                for i, v in ipairs(skillEffect) do
                    hevent.unregister(whichUnit, v.attr_type, hitemType .. "effect " .. yaojiName)
                end
            end
        end,
        hslk.i2v(itemId, "Art"),
        coloredName .. "|n" .. hslk.i2v(itemId, "Description"),
        nil,
        nil,
        nil,
        nil,
        {yaojiid = itemId},
        HBUFF_UPDATE_MODE.OVERWRITE,
        false
    )
end

hlianjin.initPlayer = function(whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang("heji", true, false)
    local itemId = string.sub(cundang, 1, 4)
    local remainingTime = tonumber(string.sub(cundang, 5, 9)) or 0

    local defaultDuration = hslk.i2v(itemId, "_duration")
    defaultDuration = defaultDuration or 10
    local durationMulti = hattribute.getWithLimit(hero, nil, "yaoshui_shijian", 0) / 100
    defaultDuration = defaultDuration + defaultDuration * durationMulti
    if remainingTime > defaultDuration * 1.5 then
        return
    end
    if hitem.getHitemType(itemId) == HITEM_TYPE.Heji and remainingTime > 0 then
        local attrEffect = hslk.i2v(itemId, "_attrEffect")
        local skillEffect = hslk.i2v(itemId, "_skillEffect")
        local yaojiName = hslk.i2v(itemId, "Name")
        hlianjin.attachYaoBuff(remainingTime, hero, HITEM_TYPE.Heji, attrEffect, skillEffect, itemId, yaojiName)
    end

    htime.setInterval(
        10,
        function()
            if hplayer.isUser(whichPlayer) and hplayer.isPlaying(whichPlayer) then
                local hero = hplayer.getMainHero(whichPlayer)
                if hero ~= nil then
                    local buffTime = hbuff.getRemainingTime(hero, HITEM_TYPE.Heji)
                    if buffTime > 0 then
                        local buffHandle = hbuff.getBuffHandle(hero, HITEM_TYPE.Heji)
                        if
                            buffHandle ~= nil and buffHandle.extraBuffData ~= nil and
                                buffHandle.extraBuffData.yaojiid ~= nil
                         then
                            local itemId = buffHandle.extraBuffData.yaojiid
                            if buffTime < 0 or buffTime > 99999 then
                                error("Number must be between 1 and 99999")
                            end
                            local formattedString = string.format("%05d", math.ceil(buffTime))
                            hplayer.dzCunDang[whichPlayer].saveCundang("heji", true, 1, 9, itemId .. formattedString)
                        end
                    else
                        hplayer.dzCunDang[whichPlayer].saveCundang("heji", true, 1, 9, "000000000")
                    end
                end
            end
        end
    )
end
