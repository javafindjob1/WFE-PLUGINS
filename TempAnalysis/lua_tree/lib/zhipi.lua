-- 护甲片
-- 装备

hzhipi = {}

hzhipi.init = function(config, hujiapianConfig)
    hzhuanye.initSingleZhuanye(
        config,
        "制作",
        "制皮",
        CONST_EVENT.zhipi,
        nil,
        nil,
        nil,
        ZHUANYE_ZHUANGBEI_QIANGHUA_WUPIN_SHIYONG.SHIYONGHUJIAPIAN,
        hujiapianConfig
    )
    hevent.reaction(
        CONST_EVENT.itemUsed,
        "zhipishiyongzhangu",
        function(evtData)
            if
                evtData.triggerSkill ~= nil and hskill.getName(evtData.triggerSkill) == "战鼓使用" and
                    evtData.triggerItem ~= nil and
                    evtData.triggerUnit ~= nil and
                    hplayer.getMainHero(hunit.getOwner(evtData.triggerUnit)) == evtData.triggerUnit
             then
                local zhangu = evtData.triggerItem
                local dynamicItem = hitem.getDynamicItem(zhangu)
                if dynamicItem == nil then
                    hitem.destroy(zhangu)
                    return
                end
                if dynamicItem.stack < 1 then
                    hitem.destroy(zhangu)
                    return
                end
                local itemId = hitem.getId(zhangu)
                local effect = hslk.i2v(itemId, "_effect")
                effect(evtData.triggerUnit)
                if dynamicItem.stack == 1 then
                    hitem.destroy(zhangu)
                    return
                end
                hitem.setCharges(zhangu, dynamicItem.stack - 1)
            end
        end
    )
end
