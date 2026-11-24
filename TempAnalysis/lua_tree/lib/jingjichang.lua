hjingjichang = {}

---
--{
--  "攻击训练"：{
--               place: "荣誉竞技场"
--               preStartCheck = function() boolean
--               start = function() {}
--               isActive = boolean
--               finishCheck = function({}) boolean
--               finish = function({})
--               timeout = 30
--             }
--}
--area config = {
--  { name = "荣誉竞技场",
--   minX=1，
--   minY=2,
--   maxX=1,
--   maxY=2,
-- }
--}

hjingjichang.init = function(jingjichangConfig, areaConfig)
    hjingjichang.jingjichangConfig = jingjichangConfig
    hjingjichang.areaConfig = {}
    for _, v in ipairs(areaConfig) do
        hjingjichang.areaConfig[v.name] =
            hrect.create((v.minX + v.maxX) / 2, (v.minY + v.maxY) / 2, v.maxX - v.minX, v.maxY - v.minY, v.name)
        hxiaoditu.addDitu(
            hjingjichang.areaConfig[v.name],
            v.blp,
            v.titleArt,
            "ReplaceableTextures\\xiaoditu\\UImap_show_bj2.blp"
        )
        hevent.onEnterRect(
            hjingjichang.areaConfig[v.name],
            function(evtData)
                if
                    evtData.triggerUnit ~= nil and
                    evtData.triggerUnit == hplayer.getMainHero(hunit.getOwner(evtData.triggerUnit))
                then
                    local whichPlayer = hunit.getOwner(evtData.triggerUnit)
                    hcamera.setCameraRegionForPlayer(whichPlayer, hjingjichang.areaConfig[v.name])
                    hcamera.toUnit(whichPlayer, 0, evtData.triggerUnit)
                    hcache.set(whichPlayer, CONST_CACHE.UNIT_RECT, hjingjichang.areaConfig[v.name])
                    hxiaoditu.showXiaoditu(hjingjichang.areaConfig[v.name], whichPlayer)
                end
            end
        )
    end
    for _, v in ipairs(jingjichangConfig) do
        local k = v.name
        if hjingjichang.areaConfig[v.place] == nil then
            err("挑战位置出错: " .. v.place)
            return
        end
        hshop.addItem(
            v.npcName,
            k,
            v.art,
            v.cost,
            v.requirement,
            v.tips,
            function(whichPlayer)
                local place = hjingjichang.areaConfig[v.place]
                local unitsInPlace =
                    hgroup.createByRect(
                        place,
                        function(_)
                            return true
                        end
                    )
                if place == nil or hgroup.isEmpty(unitsInPlace) ~= true then
                    echo("当前有单位在" .. k .. "的区域，请稍后再来", whichPlayer)
                    return
                end
                hjingjichang.process(k, v)
            end
        )
    end
end

local function addJJCBuff(whichUnit)
    hbuff.update(
        nil,
        whichUnit,
        "竞技场",
        true,
        nil,
        nil,
        "ReplaceableTextures\\BTNAchievement_Arena_2v2_7.blp",
        "受到玩家的伤害降低95%，受到任意治疗效果降低80%",
        nil,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
end

hjingjichang.portalHero = function(groupA, groupAStartx, groupAStarty, groupB, groupBStartx, groupBStarty, rect)
    for _, whichUnit in ipairs(groupA) do
        hunit.portal(whichUnit, groupAStartx, groupAStarty, 315)
        addJJCBuff(whichUnit)
        hbuff.xuanyun(whichUnit, 5)
    end

    for _, whichUnit in ipairs(groupB) do
        hunit.portal(whichUnit, groupBStartx, groupBStarty, 135)
        addJJCBuff(whichUnit)
        hbuff.xuanyun(whichUnit, 5)
    end

    for _, whichUnitA in ipairs(groupA) do
        for _, whichUnitB in ipairs(groupB) do
            hjapi.setPlayerAlliance(hunit.getOwner(whichUnitA), hunit.getOwner(whichUnitB), false)
            hjapi.setPlayerAlliance(hunit.getOwner(whichUnitB), hunit.getOwner(whichUnitA), false)
        end
    end
end

hjingjichang.clearArea = function(rect)
    local group =
        hgroup.createByRect(
            rect,
            function(filterUnit)
                local owner = hunit.getOwner(filterUnit)
                if hplayer.isUser(owner) == true and hplayer.isPlaying(owner) == true and hplayer.isComputer(owner) == false then
                    return false
                else
                    return true
                end
            end
        )
    hgroup.clear(group, true)
end

local function hasJJCBuff(group) -- 是否有竞技场buff
    local hasBuff = false
    hgroup.forEach(
        group,
        function(u)
            if hbuff.hasBuff(u, "竞技场") then
                hasBuff = true
                return false
            end
        end
    )
    return hasBuff
end

hjingjichang.process = function(name, config)
    if name == nil or config == nil then
        return
    end
    if config.isActive == true then
        echo(name .. "还在进行中")
        return
    end
    local count = config.count
    local groupAx = config.groupAx
    local groupAy = config.groupAy
    local groupBx = config.groupBx
    local groupBy = config.groupBy

    local groupA = hgroup.createMainHeroGroupByXY(groupAx, groupAy, 300)
    local groupB = hgroup.createMainHeroGroupByXY(groupBx, groupBy, 300)
    if #groupA ~= count then
        echo(hcolor.yellow("系统：") .. "红色方人数不对，目前有" .. #groupB .. "人在区域内，实际需要" .. count .. "人。无法开启竞技场")
        return
    end
    if #groupB ~= count then
        echo(hcolor.yellow("系统:") .. "蓝色方人数不对，目前有" .. #groupB .. "人在区域内，实际需要" .. count .. "人。无法开启竞技场")
        return
    end
    local rect = hjingjichang.areaConfig[config.place]
    if rect == nil then
        err("rect is nil")
        return
    end
    config.isActive = true
    hjingjichang.portalHero(
        groupA,
        config.groupAStartx,
        config.groupAStarty,
        groupB,
        config.groupBStartx,
        config.groupBStarty,
        rect
    )
    local timeout = config.timeout or 60
    htime.setInterval(
        0.1,
        function(curTimer)
            if curTimer.passedSec() > timeout then
                echo("超时平局！")
                config.isActive = false
            elseif hasJJCBuff(groupA) == true and hasJJCBuff(groupB) == false then
                echo("红方获得了胜利！")
                config.isActive = false
            elseif hasJJCBuff(groupA) == false and hasJJCBuff(groupB) == true then
                echo("蓝方获得了胜利！")
                config.isActive = false
            elseif hasJJCBuff(groupA) == false and hasJJCBuff(groupB) == false then
                echo("双方同时阵亡，平局！")
                config.isActive = false
            end
            if config.isActive == false then
                curTimer.destroy()
                for _, whichUnitA in ipairs(groupA) do
                    for _, whichUnitB in ipairs(groupB) do
                        hjapi.setPlayerAlliance(hunit.getOwner(whichUnitA), hunit.getOwner(whichUnitB), true)
                        hjapi.setPlayerAlliance(hunit.getOwner(whichUnitB), hunit.getOwner(whichUnitA), true)
                    end
                end
                for _, whichUnit in ipairs(groupA) do
                    if hunit.isAlive(whichUnit) then
                        hbuff.delete(whichUnit, "竞技场")
                        hunit.portal(whichUnit, groupAx, groupAy, 0)
                    end
                end
                for _, whichUnit in ipairs(groupB) do
                    if hunit.isAlive(whichUnit) then
                        hbuff.delete(whichUnit, "竞技场")
                        hunit.portal(whichUnit, groupBx, groupBy, 0)
                    end
                end
                hjingjichang.clearArea(rect)
            end
        end
    )
end
