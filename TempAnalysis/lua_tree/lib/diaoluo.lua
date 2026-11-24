--- Control pinzhi of dropped item number is level up rate
--- example
--- {
---    FUBEN_NANDU.PUTTONG = {
---      PUTONG = 2000, (20%)
---      JINGLIANG = 2000, (20%)
---      SHISHI = 500, (5%)
---      CHUANQI = 0,
---      SHENHUA = 0
---    }
--- }
DIAOLUO_PINZHI_NANDU_CONFIG = {}

---@param options table
--- Example
--- options = {
---  {
---     list={"item1","item2","item3"},
---     drop_rate =  {
---        100, (1% PUTONG)
---        100, (1% YINGXIONG)
---        100, (1% SHISHI)
---        100 (1% CHUANQI)
---     }
---  }
---  {}
---}
-----

RENSHU_DIAOLUORATE_MULTI = 0.20

DiaoLuoConfig = function(options)
    local this = { options = options }
    this.singleDiaoLuo = function(units, rateMulti, nandu, level)
        for _, v in ipairs(this.options) do
            local drop_rate = v.drop_rate[nandu] * rateMulti
            if drop_rate ~= nil and drop_rate > 0 then
                while drop_rate > 0 do
                    if drop_rate >= math.random(1, 10000) then
                        local itemName = v.list[math.random(1, #v.list)]
                        local dynamicItem = DynamicItem(hslk.n2i(itemName))
                        -- init dynamicItem
                        if hslk.n2v(itemName, "hitem_type") == HITEM_TYPE.Zhuangbei then
                            local pinzhiConfig = DIAOLUO_PINZHI_NANDU_CONFIG[nandu]
                            local currentPinzhi = hslk.n2v(itemName, "min_pinzhi")
                            if currentPinzhi == nil then
                                currentPinzhi = ZHUANGBEI_PINZHI.PUTONG
                            end
                            local finalPinzhi = nil
                            while finalPinzhi == nil do
                                local upgradeRate = pinzhiConfig[currentPinzhi]
                                if upgradeRate ~= nil and upgradeRate >= math.random(1, 10000) then
                                    currentPinzhi = currentPinzhi + 1
                                else
                                    finalPinzhi = currentPinzhi
                                end
                            end
                            local finalLevel = level
                            dynamicItem.initBasedOnPinzhi(finalPinzhi, finalLevel, nil, nandu, units)
                        else
                            local itemPinzhi = hitem.getItemMinPinzhi(hslk.n2i(itemName))
                            dynamicItem.initBasedOnPinzhi(itemPinzhi, 1, nil, nil, units)
                        end
                        local players = {}
                        hgroup.forEach(
                            units,
                            function(enumUnit, _)
                                local enumPlayer = hunit.getOwner(enumUnit)
                                if
                                    hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false or
                                    hplayer.isComputer(enumPlayer) == true
                                then
                                    return
                                end
                                table.insert(players, enumPlayer)
                            end
                        )
                        hdiceloot.addItem(dynamicItem, players, x, y)
                    end
                    drop_rate = drop_rate - 10000
                end
            end
        end
    end
    this.diaoLuo = function(unit, nandu, level, x, y, heroes)
        if hunit.isNormalDead(unit) == false then
            return
        end
        local units = heroes
        if units == nil then
            units =
                hgroup.createByXY(
                    x,
                    y,
                    2000,
                    function(filterUnit)
                        local whichPlayer = hunit.getOwner(filterUnit)
                        if
                            hplayer.isUser(whichPlayer) and hplayer.isPlaying(whichPlayer) and
                            hplayer.isComputer(whichPlayer) == false and
                            hplayer.getMainHero(whichPlayer) == filterUnit
                        then
                            return true
                        else
                            return false
                        end
                    end
                )
        end
        local numberPlayer = #units
        local rateMulti = (numberPlayer - 1) * RENSHU_DIAOLUORATE_MULTI + 1
        this.singleDiaoLuo(units, rateMulti, nandu, level)
        local extra_drop_rate = 0
        for _, unit in ipairs(units) do
            extra_drop_rate = math.max(hattr.getWithLimit(unit, nil, "extra_drop_rate", 0), extra_drop_rate)
        end
        if extra_drop_rate > 0 and math.random(1, 100) <= extra_drop_rate then
            this.singleDiaoLuo(units, 1, nandu, level)
        end
    end

    -- validate input parameter
    -- return nil if no findings
    if options == nil or #options == 0 then
        stack("Empty options")
        return NK_TEXT_ALIGN_LEFT
    end
    for _, v in ipairs(this.options) do
        if v.list == nil or #v.list == 0 then
            stack("Empty list")
            return nil
        end
        for _, itemName in ipairs(v.list) do
            if hslk.n2i(itemName) == nil then
                stack(itemName .. " doesn't exist")
                return nil
            end
        end
        for nandu, drop_rate in ipairs(v.drop_rate) do
            if drop_rate > 100000 then
                stack("drop_rate larger than 100000")
                return nil
            end
        end
    end
    if table.empty(DIAOLUO_PINZHI_NANDU_CONFIG) then
        stack("DIAOLUO_PINZHI_NANDU_CONFIG NOT SET")
        return nil
    end

    --- 初始化掉落信息

    local lootInfoMap = {}
    for nandu, _ in ipairs(FUBEN_NANDU_LABEL) do
        local infoString = "掉落信息：|n"
        for _, v in ipairs(this.options) do
            local dropRate = v.drop_rate[nandu]
            if dropRate and dropRate > 0 then
                local dropRatePercentage = (dropRate / 10000) * 100
                infoString = infoString .. "- "
                if #(v.list) > 0 and v.list[1] == "戒指" then
                    infoString = infoString .. hcolor.green("基础装备掉落(不含武器)")
                elseif #(v.list) > 0 and v.list[1] == "单手剑" then
                    infoString = infoString .. hcolor.green("基础装备掉落(含武器)")
                else
                    -- body
                    for j, itemName in ipairs(v.list) do
                        local name = itemName
                        local pinzhi = hitem.getItemMinPinzhi(hslk.n2i(name))
                        if hslk.n2v(name, "hitem_type") == "装备" then
                            local zhuangbeitype = hslk.n2v(name, "equipment_type")
                            name = "[" .. zhuangbeitype .. "]" .. name
                        end
                        if hslk.i2v(this.basic_item_id, "taozhuang") ~= nil then
                            name = "[套装]" .. name
                        end
                        infoString = infoString .. ZHUANGBEI_PINZHI_DATA[pinzhi].color(name)
                        if j < #v.list then
                            infoString = infoString .. ", "     -- Add comma between items
                        end
                    end
                end
                infoString = infoString .. " （" .. string.format("%.2f%%", dropRatePercentage) .. "）|n"
            end
        end
        lootInfoMap[nandu] = infoString
    end

    this.lootInfoMap = lootInfoMap
    this.diaoLuoInfo = function(nandu)
        return this.lootInfoMap[nandu]
    end
    this.registerItemSource = function(source)
        for nandu, _ in ipairs(FUBEN_NANDU_LABEL) do
            for _, v in ipairs(this.options) do
                local dropRate = v.drop_rate[nandu]
                if dropRate and dropRate > 0 then
                    for _, itemName in ipairs(v.list) do
                        hitem.registerItemSource(itemName, source)
                    end
                end
            end
        end
    end
    return this
end
