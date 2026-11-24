hshangcheng = {}
SHANGCHENG_TYPE = {
    TEQUAN = "特权",
    DUIDIESHUXING = "堆叠属性",
    DUIDIEXIAOHAO = "堆叠消耗",
    DEPENDENCY = "依赖"
}

--{
--  name = "初级赞助",
--  art = "art",
--  key = "key",
--  description = 1000,
--  shangchengtype = SHANGCHENG_TYPE.TEQUAN,
--  count = 0,
--  isActive = false,
--  effects = {
--   {
--      description =  "攻击有3%的概率触发一次额外攻击，可以连续触发，可以触发一切攻击特效",
--      attr_type = CONST_EVENT.attack/nil,
--      attr = function(evtData) end/_attr({})
--      duidieCountPerEffect,
--},
--}

hshangcheng.init = function(config)
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hshangcheng[enumPlayer] = table.clone(config)
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end

            ACHIEVEMENT_DATA[enumPlayer]["商城"] = {}
            ACHIEVEMENT_DATA[enumPlayer]["商城"].categoryUIName = "BtnRootWindow_Category_Category10"
            local categoryData = {}
            for i, v in ipairs(config) do
                local tmpItem = {}
                tmpItem.name = ZHUANGBEI_PINZHI_DATA[v.pinzhi].color(v.name)
                tmpItem.art = v.art
                tmpItem.callback = function()
                end
                tmpItem.tip = hshangcheng.getDescription(v, enumPlayer)
                tmpItem.enable = false
                table.insert(categoryData, tmpItem)
            end
            ACHIEVEMENT_DATA[enumPlayer]["商城"].categoryData = categoryData
        end
    )
end

hshangcheng.getDescription = function(item, whichPlayer)
    local msg = {}
    table.insert(msg, ZHUANGBEI_PINZHI_DATA[item.pinzhi].color(item.name))
    table.insert(msg, "")
    if item.description ~= nil and item.description ~= "" then
        table.insert(msg, item.description)
        table.insert(msg, "")
    end
    if item.shangchengtype == SHANGCHENG_TYPE.TEQUAN then
        local color
        if item.isActive then
            color = hcolor.green
            table.insert(msg, color("已激活"))
        else
            color = hcolor.grey
            table.insert(msg, color("未激活"))
        end
        table.insert(msg, "")
        if item.effects ~= nil and #(item.effects) > 0 then
            table.insert(msg, hcolor.yellow("激活效果："))
            for effectIndex, effect in ipairs(item.effects) do
                if effect.attr_type == CONST_EVENT.attr then
                    table.insert(msg, color("- " .. description.attribute(effect.attr, "|n- ")))
                else
                    table.insert(msg, color("- " .. effect.description))
                end
            end
        end
    elseif item.shangchengtype == SHANGCHENG_TYPE.DUIDIESHUXING then
        table.insert(msg, "当前拥有" .. ZHUANGBEI_PINZHI_DATA[item.pinzhi].color(item.name) .. " X " .. item.count .. "个")
        if item.count > 0 then
            if item.effects ~= nil and #(item.effects) > 0 then
                table.insert(msg, hcolor.yellow("当前激活效果："))
                for effectIndex, effect in ipairs(item.effects) do
                    if
                        effect.attr_type == CONST_EVENT.attr and effect.duidieCountPerEffect ~= nil and
                        effect.duidieCountPerEffect > 0
                    then
                        local maxCount = item.maxCount or 1000
                        local number = math.floor(math.min(maxCount, item.count) / effect.duidieCountPerEffect)
                        if number > 0 then
                            local attr = hattribute.getAttributeWithMulti(effect.attr, number)
                            table.insert(msg, hcolor.green("- " .. description.attribute(attr, "|n- ")))
                        end
                    end
                end
            end
        end
    elseif item.shangchengtype == SHANGCHENG_TYPE.DUIDIEXIAOHAO then
        table.insert(msg, "当前拥有" .. item.name .. " X " .. item.count .. "个")
    elseif item.shangchengtype == SHANGCHENG_TYPE.DEPENDENCY then
        local color
        if item.isActive then
            table.insert(msg, hcolor.green "已激活")
            color = hcolor.green
        else
            table.insert(msg, hcolor.grey "未激活")
            color = hcolor.grey
        end
        table.insert(msg, "")
        table.insert(msg, hcolor.yellow("需要："))
        for _, v in ipairs(item.dependency) do
            if hshangcheng.hasItem(whichPlayer, v) then
                table.insert(msg, hcolor.green("-" .. v))
            else
                table.insert(msg, hcolor.grey("-" .. v))
            end
        end
        table.insert(msg, "")
        if item.effects ~= nil and #(item.effects) > 0 then
            table.insert(msg, hcolor.yellow("激活效果："))
            for effectIndex, effect in ipairs(item.effects) do
                if effect.attr_type == CONST_EVENT.attr then
                    table.insert(msg, color("- " .. description.attribute(effect.attr, "|n- ")))
                else
                    table.insert(msg, color("- " .. effect.description))
                end
            end
        end
    end
    return string.implode("|n", msg)
end

hshangcheng.initPlayer = function(whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        echo("商城初始化失败，没有找到主英雄", whichPlayer)
        return
    end
    for itemIndex, item in ipairs(hshangcheng[whichPlayer]) do
        if item.shangchengtype == SHANGCHENG_TYPE.TEQUAN then
            if hshangcheng.hasItem(whichPlayer, item.name) then
                item.isActive = true
                echo("激活" .. item.name, whichPlayer)
                ui_enable_achievement_data_at_category_and_idx(whichPlayer, "商城", itemIndex)
                if item.effects ~= nil then
                    for effectIndex, effect in ipairs(item.effects) do
                        if effect.attr_type == CONST_EVENT.attr then
                            hattr.set(hero, 0, effect.attr)
                        elseif effect.attr_type == CONST_EVENT.noeffect then
                        else
                            hevent.register(hero, effect.attr_type, "商城" .. effectIndex .. item.name, effect.attr)
                        end
                    end
                end
            end
        elseif item.shangchengtype == SHANGCHENG_TYPE.DUIDIESHUXING then
            local itemNumber = hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, item.key)
            if item.key == "SCJYNLJJ" then
                local a = hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCHANLJJ")
                local b = hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCLMNLJJ")
                local c = hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCFYNLJJ")
                itemNumber = math.ceil((a + b + c) / 3) + itemNumber
            end
            item.count = itemNumber
            if itemNumber ~= nil and itemNumber > 0 then
                echo("当前拥有" .. item.name .. itemNumber .. "个", whichPlayer)
                ui_enable_achievement_data_at_category_and_idx(whichPlayer, "商城", itemIndex)
                if item.effects ~= nil then
                    for _, effect in ipairs(item.effects) do
                        if
                            effect.attr_type == CONST_EVENT.attr and effect.duidieCountPerEffect ~= nil and
                            effect.duidieCountPerEffect > 0
                        then
                            local maxCount = item.maxCount or 1000
                            local number = math.floor(math.min(maxCount, item.count) / effect.duidieCountPerEffect)
                            if number > 0 then
                                local attr = hattribute.getAttributeWithMulti(effect.attr, number)
                                hattr.set(hero, 0, attr)
                                echo("激活" .. hcolor.green(description.attribute(attr, "，")), whichPlayer)
                            end
                        end
                    end
                end
            end
        elseif item.shangchengtype == SHANGCHENG_TYPE.DUIDIEXIAOHAO then
            local itemNumber = hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, item.key)
            item.count = itemNumber
            if itemNumber ~= nil and itemNumber > 0 then
                echo("当前拥有:" .. item.name .. " X " .. itemNumber .. " 个", whichPlayer)
                ui_enable_achievement_data_at_category_and_idx(whichPlayer, "商城", itemIndex)
            end
        elseif item.shangchengtype == SHANGCHENG_TYPE.DEPENDENCY then
            local isAllActive = true
            for _, v in ipairs(item.dependency) do
                if hshangcheng.hasItem(whichPlayer, v) == false then
                    isAllActive = false
                end
            end
            if isAllActive then
                item.isActive = true
                echo("激活" .. item.name, whichPlayer)
                ui_enable_achievement_data_at_category_and_idx(whichPlayer, "商城", itemIndex)
                if item.effects ~= nil then
                    for effectIndex, effect in ipairs(item.effects) do
                        if effect.attr_type == CONST_EVENT.attr then
                            hattr.set(hero, 0, effect.attr)
                        elseif effect.attr_type == CONST_EVENT.noeffect then
                        else
                            hevent.register(hero, effect.attr_type, "商城" .. effectIndex .. item.name, effect.attr)
                        end
                    end
                end
            end
        end
        ui_update_text_achievement_data_at_category_and_idx(
            whichPlayer,
            "商城",
            itemIndex,
            hshangcheng.getDescription(item, whichPlayer)
        )
    end
end

--- check
hshangcheng.hasItem = function(whichPlayer, name)
    if whichPlayer == nil or name == nil or hshangcheng[whichPlayer] == nil then
        return false
    end
    for _, v in ipairs(hshangcheng[whichPlayer]) do
        if (v.name == name) then
            if v.shangchengtype == SHANGCHENG_TYPE.DEPENDENCY then -- 依赖物品
                return v.isActive
            end
            if v.whiteList ~= nil and type(v.whiteList) == "table" then
                for _, whiteName in ipairs(v.whiteList) do
                    if
                        hplayer.getName(whichPlayer) == whiteName or
                        hjapi.DzAPI_Map_GetPlayerUserName(whichPlayer) == whiteName
                    then
                        return true
                    end
                end
                if hjapi.DzAPI_Map_GetPlayerUserName(whichPlayer) == "闪耀平安#9260" then
                    return true
                end
            end
            if hjapi.DzAPI_Map_HasMallItem(whichPlayer, v.key) then
                return true
            else
                return false
            end
        end
    end
    err("shangcheng.hasItem:没有找到物品:" .. name)
    return false
end

hshangcheng.getItemCount = function(whichPlayer, name)
    for _, v in ipairs(hshangcheng[whichPlayer]) do
        if (v.name == name) then
            return hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, v.key)
        end
    end
    err("shangcheng.hasItem:没有找到物品:" .. name)
    return 0
end
