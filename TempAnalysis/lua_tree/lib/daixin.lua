hdaixin                 = { desc = {} }

--- config = {
---     fuben = {
---         {name = "副本名", nandu = { FUBEN_NANDU.SHISHI, FUBEN_NANDU.CHUANQI }},
---     },
---     jiangli = {
---         {jifen = 50, type = "zuoqi", name = "name"},
---         {jifen = 100, type = "zuoqi", name = "name"},
---         {jifen = 200, type = "zuoqi", name = "name"},
---         {jifen = 300, type = "zuoqi", name = "name"},
---         {jifen = 400, type = "zuoqi", name = "name"},
---     },
--- }
hdaixin.init            = function(config)
    hdaixin.config = config
    hevent.reaction(
        CONST_EVENT.customResourceChange,
        "initDaixinjifen",
        function(evtData)
            local whichPlayer = hunit.getOwner(evtData.triggerUnit)
            if evtData.type == HSHOP_COST_TYPE.daixinjifen then
                local sumTotal = hresource.getResourceSumTotal(whichPlayer, HSHOP_COST_TYPE.daixinjifen) or 0
                for _, v in ipairs(config.jiangli) do
                    if sumTotal >= v.jifen then
                        if v.type == "zuoqi" then
                            hzuoqi.jihuozuoqi(v.name, whichPlayer, evtData.showEffect)
                        elseif v.type == "huanhua" then
                            hhuanhua.jihuohuanhua(v.name, whichPlayer, evtData.showEffect)
                        end
                    end
                end
                hdaixin.desc[whichPlayer] = hdaixin.getDescription(whichPlayer)
            end
        end
    )
end

--- 加入带新积分兑换选项
hdaixin.addJifenDuihuan = function(cost, requirement, resourceName, resourceCount, itemName)

end

hdaixin.fubenjiesuan    = function(fubenName, nandu, heroes, rect)
    local validFuben = false
    for _, fuben in ipairs(hdaixin.config.fuben) do
        if fuben.name == fubenName then
            for _, validNandu in ipairs(fuben.nandu) do
                if validNandu == nandu then
                    validFuben = true
                    break
                end
            end
            if validFuben then break end
        end
    end
    if not validFuben then
        return
    end

    local dairenHeroes = {}
    for _, mainHero in ipairs(heroes) do
        local isLaoren = false
        local mainPlayer = hunit.getOwner(mainHero)
        local mainPlayerLevel = hjapi.DzAPI_Map_GetMapLevel(mainPlayer)
        local mainHeroX = hunit.x(mainHero)
        local mainHeroY = hunit.y(mainHero)

        if hrect.isInner(rect, mainHeroX, mainHeroY) and hunit.getLevel(mainHero) >= 65 then
            for _, beidaiHero in ipairs(heroes) do
                local beidaiPlayer = hunit.getOwner(beidaiHero)
                local beidaiHeroX = hunit.x(beidaiHero)
                local beidaiHeroY = hunit.y(beidaiHero)

                if beidaiHero ~= mainHero and hrect.isInner(rect, beidaiHeroX, beidaiHeroY) and
                    math.distance(beidaiHeroX, beidaiHeroY, mainHeroX, mainHeroY) <= 2000 then
                    local beidaiPlayerLevel = hjapi.DzAPI_Map_GetMapLevel(beidaiPlayer)
                    if mainPlayerLevel - 20 > beidaiPlayerLevel then
                        isLaoren = true
                        break
                    end
                end
            end
        end

        if isLaoren then
            table.insert(dairenHeroes, mainHero)
        end
    end

    for _, mainHero in ipairs(dairenHeroes) do
        local mainPlayer = hunit.getOwner(mainHero)
        hresource.addSingleResource(mainPlayer, HSHOP_COST_TYPE.daixinjifen, 1, true)
    end
end

--- 获得玩家图标说明
hdaixin.getDescription  = function(whichPlayer)
    if whichPlayer == nil then
        return
    end
    if hplayer.getMainHero(whichPlayer) == nil then
        return "请选择英雄"
    end
    local msg = {}
    table.insert(msg, hcolor.yellow("带新活动："))
    table.insert(msg, "")
    local sumValue = hresource.getResourceSumTotal(whichPlayer, HSHOP_COST_TYPE.daixinjifen)
    local currentValue = hresource.getResource(whichPlayer, HSHOP_COST_TYPE.daixinjifen)
    table.insert(msg, "带新人通关特定副本可以获得1点带新积分，带新积分可以用于兑换其它资源/材料（会消耗），累计带新积分会激活幻化/坐骑/永久属性奖励")
    table.insert(msg, hcolor.yellow("积分获得要求："))
    local tonguanstr = ""
    for i, v in ipairs(hdaixin.config.fuben) do
        tonguanstr = tonguanstr .. v.name .. "（"

        for j, nandu in ipairs(v.nandu) do
            tonguanstr = tonguanstr .. FUBEN_NANDU_LABEL[nandu]
            if j ~= #(v.nandu) then
                tonguanstr = tonguanstr .. ","
            end
        end
        tonguanstr = tonguanstr .. "）"
        if i ~= #(hdaixin.config.fuben) then
            tonguanstr = tonguanstr .. "，"
        end
    end
    table.insert(msg, "- 通关副本在以下列表内：" .. tonguanstr)
    table.insert(msg, "- 带新的玩家在副本结算时需要在副本内且2000码之内有新人玩家")
    table.insert(msg, "- 新人玩家地图等级小于带人玩家的地图等级20级以上（不计算商城道具附加的等级）")
    table.insert(msg, "- 累计积分每日获取上限为10")
    table.insert(msg, "- 带新玩家角色等级大于等于65级")
    table.insert(msg, "")
    table.insert(msg,
        hcolor.yellow("当前积分/累计积分：") .. hcolor.green(tostring(currentValue)) .. "/" .. hcolor.green(tostring(sumValue)))
    local dailyLimit =
        hresource.getResourceUsedTotalRemaining(whichPlayer, HSHOP_COST_TYPE.daixinjifen)
    table.insert(msg,
        hcolor.yellow("今日还可获取积分：") .. hcolor.green(tostring(dailyLimit)))
    table.insert(msg, "")
    table.insert(msg,
        hcolor.yellow("当前累计积分奖励："))
    for _, v in ipairs(hdaixin.config.jiangli) do
        if sumValue >= v.jifen then
            if v.type == "zuoqi" then
                table.insert(msg, hcolor.green("- " .. v.jifen .. "分，激活坐骑：" .. v.name))
            else
                table.insert(msg, hcolor.green("- " .. v.jifen .. "分，激活幻化：" .. v.name))
            end
        else
            if v.type == "zuoqi" then
                table.insert(msg, hcolor.grey("- " .. v.jifen .. "分，激活坐骑：" .. v.name))
            else
                table.insert(msg, hcolor.grey("- " .. v.jifen .. "分，激活幻化：" .. v.name))
            end
        end
    end
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("带新积分可以在各大主城带新商人处兑换资源与物品。（暂未实装）"))
    return string.implode("|n", msg)
end
