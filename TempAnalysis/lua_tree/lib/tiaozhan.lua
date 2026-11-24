htiaozhan = {}

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

htiaozhan.init = function(tiaozhanConfig, areaConfig)
    htiaozhan.tiaozanConfig = tiaozhanConfig
    htiaozhan.areaConfig = {}
    for _, v in ipairs(areaConfig) do
        htiaozhan.areaConfig[v.name] =
            hrect.create((v.minX + v.maxX) / 2, (v.minY + v.maxY) / 2, v.maxX - v.minX, v.maxY - v.minY, v.name)
        hxiaoditu.addDitu(
            htiaozhan.areaConfig[v.name],
            v.blp,
            "ReplaceableTextures\\xitong\\ui_map_show_14.blp",
            "ReplaceableTextures\\xiaoditu\\UImap_show_bj2.blp"
        )
        hevent.onEnterRect(
            htiaozhan.areaConfig[v.name],
            function(evtData)
                if
                    evtData.triggerUnit ~= nil and
                        evtData.triggerUnit == hplayer.getMainHero(hunit.getOwner(evtData.triggerUnit))
                 then
                    local whichPlayer = hunit.getOwner(evtData.triggerUnit)
                    hcamera.setCameraRegionForPlayer(whichPlayer, htiaozhan.areaConfig[v.name])
                    hcamera.toUnit(whichPlayer, 0, evtData.triggerUnit)
                    hcache.set(whichPlayer, CONST_CACHE.UNIT_RECT, htiaozhan.areaConfig[v.name])
                    hxiaoditu.showXiaoditu(htiaozhan.areaConfig[v.name], whichPlayer)
                end
            end
        )
    end
    for _, v in ipairs(tiaozhanConfig) do
        local k = v.name
        if htiaozhan.areaConfig[v.place] == nil then
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
                local place = htiaozhan.areaConfig[v.place]
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
                htiaozhan.process(k, v, hplayer.getMainHero(whichPlayer))
            end
        )
    end
end

htiaozhan.portalHero = function(whichUnit, rect)
    hunit.portal(whichUnit, hrect.getX(rect) - 400, hrect.getY(rect), 0)
end

htiaozhan.clearArea = function(rect)
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

htiaozhan.process = function(name, config, whichUnit)
    if name == nil or config == nil or whichUnit == nil then
        return
    end
    if config.isActive == true then
        echo(name .. "还在进行中", hunit.getOwner(whichUnit))
        return
    end
    if config.preStartCheck ~= nil and config.preStartCheck(whichUnit) == false then
        return
    end
    local rect = htiaozhan.areaConfig[config.place]
    if rect == nil then
        err("rect is nil")
        return
    end
    config.isActive = true
    local x = hunit.x(whichUnit)
    local y = hunit.y(whichUnit)
    htiaozhan.portalHero(whichUnit, rect)
    local requiredData = config.start(whichUnit, rect)
    local timeout = config.timeout or 600
    htime.setInterval(
        0.1,
        function(curTimer)
            if curTimer.passedSec() > timeout then
                if config.timeoutAction ~= nil then
                    config.timeoutAction(requiredData, whichUnit)
                end
                config.isActive = false
            elseif hrect.hasUserUnit(rect) == false then
                if config.failAction ~= nil then
                    config.failAction(requiredData, whichUnit)
                end
                config.isActive = false
            elseif config.finishCheck(requiredData, whichUnit) == true then
                config.finish(requiredData, whichUnit)
                config.isActive = false
            end
            if config.isActive == false then
                curTimer.destroy()
                if hunit.isAlive(whichUnit) then
                    hunit.portal(whichUnit, x, y, 0)
                end
                htiaozhan.clearArea(rect)
            end
        end
    )
end
