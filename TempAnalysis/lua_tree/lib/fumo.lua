-- 分解装备 提升技能
-- 附魔图纸在身伤 点击激活
-- 激活后给装备第一格附魔

hfumo = {}

hfumo.init = function(config, fumoConfig, fenjieConfig, wupinQianghuaConfig)
    hzhuanye.initSingleZhuanye(
        config,
        "制作",
        "附魔",
        CONST_EVENT.fumo,
        nil,
        nil,
        nil,
        ZHUANYE_ZHUANGBEI_QIANGHUA_WUPIN_SHIYONG.SHIYONGFUMOJUANZHOU,
        fumoConfig
    )
    hfumo.fenjieConfig = fenjieConfig
    for _, pinzhi --[[Validated]] in pairs(ZHUANGBEI_PINZHI) do
        if hfumo.fenjieConfig[pinzhi] ~= nil then
            for i, v in ipairs(hfumo.fenjieConfig[pinzhi]) do
                for ii, vv in ipairs(v.output) do
                    hitem.registerItemSource(vv.name, "附魔分解")
                end
            end
        end
    end
end

hfumo.fenjie = function(dynamicItem, whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        return
    end
    local level = dynamicItem.level
    local pinzhi = dynamicItem.pinzhi
    local pinzhiConfig = hfumo.fenjieConfig[pinzhi]
    if pinzhiConfig == nil then
        err("no fenjie config found for pinzhi of item: " .. dynamicItem)
        return
    end
    for _, v in ipairs(pinzhiConfig) do
        if level >= v.minItemLevel and level <= v.maxItemLevel then
            local winItemName = table.dropItemFromPool(v.output)
            if winItemName ~= nil then
                local dynamicItem = DynamicItem(hslk.n2i(winItemName))
                local pinzhi = hitem.getItemMinPinzhi(hslk.n2i(winItemName))
                dynamicItem.setOwner(whichPlayer)
                dynamicItem.initBasedOnPinzhi(pinzhi, 1, nil, nil, { hero })
                dynamicItem.setStack(1)
                if hplayer.dzCunDang[whichPlayer].saveItemInInventory(dynamicItem) == false then
                    hitem.create({ id = hslk.n2i(winItemName), charges = 1, whichUnit = hero, dynamicItem = dynamicItem })
                end
                local zhuanyeLevel = hzhuanye.getZhuanyeLevel("附魔", whichPlayer)
                if zhuanyeLevel <= v.zhuanyeLevel and math.random(1, 10000) <= v.zhuanyeExpRate then
                    hzhuanye.tryZengJiaExp("附魔", whichPlayer, 1)
                end
            end
        end
    end
end
