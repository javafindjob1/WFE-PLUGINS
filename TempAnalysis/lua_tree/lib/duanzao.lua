hduanzao = {}

---
--- config = {
---     {
---        reqLevel = 1,
---        req = {
---          {name = "铁矿"，count = 2},
---          {name = "野蛮锁甲"， count = 1}
---        },
---        successRate = 10000
---        output = {
---          name = "银鳞胸甲",
---          itemLevel = 10,
---          itemPinzhi = ZHUANGBEI_PINZHI.putong,
---          count = 1,
---          upgradeRate,
---        },
---     },
---     {}
---}

hduanzao.init = function(config)
    hzhuanye.initSingleZhuanye(config, "锻造", "锻造", CONST_EVENT.duanzao)
    hevent.reaction(
        CONST_EVENT.itemUsed,
        "modaoshishiyong",
        function(evtData)
            if
                evtData.triggerSkill ~= nil and hskill.getName(evtData.triggerSkill) == "磨刀石使用" and
                    evtData.triggerItem ~= nil and
                    evtData.triggerUnit ~= nil and
                    hplayer.getMainHero(hunit.getOwner(evtData.triggerUnit)) == evtData.triggerUnit
             then
                local modaoshi = evtData.triggerItem
                local dynamicItem = hitem.getDynamicItem(modaoshi)
                if dynamicItem == nil then
                    hitem.destroy(modaoshi)
                    return
                end
                if dynamicItem.stack < 1 then
                    hitem.destroy(modaoshi)
                    return
                end
                local itemId = hitem.getId(modaoshi)
                local duration = hslk.i2v(itemId, "_duration")
                local useLevel = hslk.i2v(itemId, "_useLevel")
                useLevel = useLevel or 1
                if useLevel > hunit.getLevel(evtData.triggerUnit) then
                    echo("磨刀石等级过高，无法生效，已经浪费掉了", hunit.getOwner(evtData.triggerUnit))
                    return
                end
                if duration == nil then
                    err("Duration is nil")
                end
                duration = duration or 10
                local whichUnit = evtData.triggerUnit
                local attrEffect = hslk.i2v(itemId, "_attrEffect")
                local skillEffect = hslk.i2v(itemId, "_skillEffect")
                local modaoshiName = hslk.i2v(itemId, "Name")
                hbuff.update(
                    duration,
                    whichUnit,
                    "磨刀石",
                    true,
                    function()
                        if attrEffect ~= nil then
                            hattribute.caleAttribute(CONST_DAMAGE_SRC.item, true, whichUnit, attrEffect, 1)
                        end
                        if skillEffect ~= nil then
                            for i, v in ipairs(skillEffect) do
                                hevent.register(whichUnit, v.attr_type, "磨刀石effect " .. modaoshiName, v.attr)
                            end
                        end
                    end,
                    function()
                        if attrEffect ~= nil then
                            hattribute.caleAttribute(CONST_DAMAGE_SRC.item, false, whichUnit, attrEffect, 1)
                        end
                        if skillEffect ~= nil then
                            for i, v in ipairs(skillEffect) do
                                hevent.unregister(whichUnit, v.attr_type, "药剂effect " .. modaoshiName)
                            end
                        end
                    end,
                    hslk.i2v(itemId, "Art"),
                    hslk.i2v(itemId, "Description"),
                    nil,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE,
                    false
                )
                if dynamicItem.stack == 1 then
                    hitem.destroy(modaoshi)
                    return
                end
                hitem.setCharges(modaoshi, dynamicItem.stack - 1)
            end
        end
    )
end
