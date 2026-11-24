hfightzhuangtai = {
    tuozhanshijian = 10,
    zhandoudata = {},
    zhandoudata_idx = {},
    chouhendata = {},
    chouhendata_idx = {},
    chouhendata_detail_idx = {}
}

hfightzhuangtai.enable_fightzhuangtai = function()
    hevent.reaction(
        CONST_EVENT.damage,
        "fightdamage",
        function(evtData)
            local srcUnit = evtData.triggerUnit
            local tarUnit = evtData.targetUnit
            local damage = evtData.damage
            if hbuff.hasBuff(srcUnit, "守护者") or hbuff.hasBuff(srcUnit, "先锋") then
                damage = damage * 100
            end
            if
                hunit.isAlive(srcUnit) and hunit.isAlive(tarUnit) and hunit.isAlly(srcUnit, tarUnit) == false and
                    math.distance(hunit.x(srcUnit), hunit.y(srcUnit), hunit.x(tarUnit), hunit.y(tarUnit)) <= 3000
             then
                if hfightzhuangtai.isInFight(srcUnit) == false then
                    hevent.trigger(srcUnit, CONST_EVENT.enterFight, {triggerUnit = srcUnit})
                    if hplayer.isUser(hunit.getOwner(srcUnit)) == true then
                        heffect.xyz(
                            "war3mapImported\\zhangdouzhuangtaibuff - 2.mdx",
                            hunit.x(srcUnit),
                            hunit.y(srcUnit),
                            hunit.z(srcUnit) + 180
                        )
                    end
                end
                if hfightzhuangtai.zhandoudata[srcUnit] == nil then
                    table.insert(hfightzhuangtai.zhandoudata_idx, srcUnit)
                end
                local tuozhanshijian =
                    math.max(hunit.getTuozhanshijian(srcUnit), hunit.getTuozhanshijian(tarUnit)) * 100
                hfightzhuangtai.zhandoudata[srcUnit] = htime.inc + tuozhanshijian
                if hfightzhuangtai.isInFight(tarUnit) == false then
                    hevent.trigger(tarUnit, CONST_EVENT.enterFight, {triggerUnit = tarUnit})
                    if hplayer.isUser(hunit.getOwner(tarUnit)) == true then
                        heffect.xyz(
                            "war3mapImported\\zhangdouzhuangtaibuff - 2.mdx",
                            hunit.x(tarUnit),
                            hunit.y(tarUnit),
                            hunit.z(tarUnit) + 180
                        )
                    end
                end
                if hfightzhuangtai.zhandoudata[tarUnit] == nil then
                    table.insert(hfightzhuangtai.zhandoudata_idx, tarUnit)
                end
                hfightzhuangtai.zhandoudata[tarUnit] = htime.inc + tuozhanshijian

                if hfightzhuangtai.chouhendata[tarUnit] == nil then
                    hfightzhuangtai.chouhendata[tarUnit] = {}
                    hfightzhuangtai.chouhendata_detail_idx[tarUnit] = {}
                    table.insert(hfightzhuangtai.chouhendata_idx, tarUnit)
                end
                if hfightzhuangtai.chouhendata[tarUnit][srcUnit] == nil then
                    hfightzhuangtai.chouhendata[tarUnit][srcUnit] = 0
                    table.insert(hfightzhuangtai.chouhendata_detail_idx[tarUnit], srcUnit)
                end
                hfightzhuangtai.chouhendata[tarUnit][srcUnit] = hfightzhuangtai.chouhendata[tarUnit][srcUnit] + damage

                if hfightzhuangtai.chouhendata[srcUnit] == nil then
                    hfightzhuangtai.chouhendata[srcUnit] = {}
                    hfightzhuangtai.chouhendata_detail_idx[srcUnit] = {}
                    table.insert(hfightzhuangtai.chouhendata_idx, srcUnit)
                end
                if hfightzhuangtai.chouhendata[srcUnit][tarUnit] == nil then
                    hfightzhuangtai.chouhendata[srcUnit][tarUnit] = 0
                    table.insert(hfightzhuangtai.chouhendata_detail_idx[srcUnit], tarUnit)
                end
                hfightzhuangtai.chouhendata[srcUnit][tarUnit] = hfightzhuangtai.chouhendata[srcUnit][tarUnit] + 1
            end
        end
    )
    hevent.reaction(
        CONST_EVENT.dead,
        "fightdead",
        function(evtData)
            if hcache.exist(evtData.triggerUnit) then
                hevent.trigger(evtData.triggerUnit, CONST_EVENT.quitFight, {triggerUnit = evtData.triggerUnit})
            end
        end
    )
    hevent.reaction(
        CONST_EVENT.quitFight,
        "chouhenquitFight",
        function(evtData)
            local triggerUnit = evtData.triggerUnit
            if hplayer.isUser(hunit.getOwner(triggerUnit)) == true then
                heffect.xyz(
                    "war3mapImported\\zhangdouzhuangtaibuff - 1.mdx",
                    hunit.x(triggerUnit),
                    hunit.y(triggerUnit),
                    hunit.z(triggerUnit) + 180
                )
            end
            local unitToquitFight = {}
            for _, sourceUnit in ipairs(hfightzhuangtai.chouhendata_idx) do
                local data = hfightzhuangtai.chouhendata[sourceUnit]
                if data[triggerUnit] ~= nil then
                    data[triggerUnit] = nil
                    table.delete(hfightzhuangtai.chouhendata_detail_idx[sourceUnit], triggerUnit)
                    if table.empty(data) then
                        table.insert(unitToquitFight, sourceUnit)
                    end
                end
            end
            hfightzhuangtai.zhandoudata[triggerUnit] = nil
            table.delete(hfightzhuangtai.zhandoudata_idx, triggerUnit)
            hfightzhuangtai.chouhendata[triggerUnit] = nil
            hfightzhuangtai.chouhendata_detail_idx[triggerUnit] = nil
            table.delete(hfightzhuangtai.chouhendata_idx, triggerUnit)
            if hplayer.isComputer(hunit.getOwner(triggerUnit)) then
                cj.IssueImmediateOrder(triggerUnit, "stop")
                local bornX = hunit.getBornX(triggerUnit)
                local bornY = hunit.getBornY(triggerUnit)
                if bornX ~= nil and bornY ~= nil and hunit.isDead(triggerUnit) == false then
                    hunit.portal(triggerUnit, bornX, bornY, hunit.getFacing(triggerUnit))
                end
            end
            for _, unit in ipairs(unitToquitFight) do
                hevent.trigger(unit, CONST_EVENT.quitFight, {triggerUnit = unit})
            end
        end
    )
    htime.setInterval(
        0.1,
        function(_)
            for _, unit in ipairs(hfightzhuangtai.zhandoudata_idx) do
                local tuozhanshijian = hfightzhuangtai.zhandoudata[unit]
                if tuozhanshijian == nil then
                    dump(hfightzhuangtai)
                end
                if htime.inc > tuozhanshijian then
                    hevent.trigger(unit, CONST_EVENT.quitFight, {triggerUnit = unit})
                end
            end
        end
    )
end

hfightzhuangtai.getChouhengdiyi = function(whichUnit)
    if whichUnit == nil then
        return
    end
    if hfightzhuangtai.isInFight(whichUnit) == false then
        return
    end

    local largestValue = nil
    local largestKey = nil

    for _, key in ipairs(hfightzhuangtai.chouhendata_detail_idx[whichUnit]) do
        local value = hfightzhuangtai.chouhendata[whichUnit][key]
        if largestValue == nil or value > largestValue then
            largestValue = value
            largestKey = key
        elseif largestValue == value then
        end
    end

    return largestKey
end

hfightzhuangtai.getSuijiChouhengMubiao = function(whichUnit)
    if whichUnit == nil then
        return
    end
    if hfightzhuangtai.isInFight(whichUnit) == false then
        return
    end

    local units = {}
    for _, key in ipairs(hfightzhuangtai.chouhendata_detail_idx[whichUnit]) do
        table.insert(units, key)
    end
    if #units == 0 then
        echo("无法找到随机仇恨目标")
        return nil
    end
    return table.random(units, 1)
end

hfightzhuangtai.getFarestChouhengMubiao = function(whichUnit)
    if whichUnit == nil then
        return
    end
    if hfightzhuangtai.isInFight(whichUnit) == false then
        return
    end

    local units = {}
    for _, key in ipairs(hfightzhuangtai.chouhendata_detail_idx[whichUnit]) do
        table.insert(units, key)
    end
    if #units == 0 then
        echo("无法找到随机仇恨目标")
        return nil
    end
    return hgroup.getFarthest(units, hunit.x(whichUnit), hunit.y(whichUnit))
end

hfightzhuangtai.isInFight = function(whichUnit)
    return hfightzhuangtai.zhandoudata[whichUnit] ~= nil
end
