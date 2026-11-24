hditudengji = {}

hditudengji.init_user = function(whichPlayer)
    local level = hditudengji.getDitudengji(whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    local msg = {}
    table.insert(msg, "当前地图等级: " .. hcolor.green(level))
    table.insert(msg, "")
    if level > 5 then
        local zhushuxing = level
        hattribute.set(hero, 0, _attr({ zhushuxing = "+" .. tostring(zhushuxing) }))
        table.insert(
            msg,
            "- 大于" .. hcolor.green(tostring(5)) .. "级，每级获得1点主属性，当前奖励：" .. hcolor.green(tostring(zhushuxing)) .. "点"
        )
    else
        table.insert(msg, hcolor.grey("- 大于5级，每级获得1点主属性"))
    end
    if level > 10 then
        hattribute.set(hero, 0, _attr({ exp_ratio = "+" .. tostring(level * 0.2) }))
        table.insert(
            msg,
            "- 大于" ..
            hcolor.green(tostring(10)) ..
            "级，每级获得0.2%经验获得率，当前奖励：" .. hcolor.green(tostring(math.max(0, level * 0.2)) .. "%")
        )
    else
        table.insert(msg, hcolor.grey("- 大于10级，每级获得0.2%经验获得率"))
    end
    if level > 10 then
        table.insert(
            msg,
            "- 大于" ..
            hcolor.green(tostring(10)) ..
            "级，之后每级获得5000点金币存储上限，当前上限增加：" .. hcolor.green(tostring(math.max(0, (level - 10) * 5000)))
        )
    else
        table.insert(msg, hcolor.grey("- 大于10级，每级获得5000金币存储上限"))
    end
    if level > 15 then
        hattribute.set(hero, 0, _attr({ gold_ratio = "+" .. tostring(level * 0.2) }))
        table.insert(
            msg,
            "- 大于" ..
            hcolor.green(tostring(15)) ..
            "级，每级获得0.2%金币获得率，当前奖励：" .. hcolor.green(tostring(math.max(0, level * 0.2)) .. "%")
        )
    else
        table.insert(msg, hcolor.grey("- 大于15级，每级获得0.2%金币获得率"))
    end
    if level > 15 then
        hattribute.set(hero, 0, _attr({ zaisheng_speed = "+" .. tostring(level * 0.2) }))
        table.insert(
            msg,
            "- 大于" ..
            hcolor.green(tostring(15)) ..
            "级，每级获得0.2%资源再生速率，当前奖励：" .. hcolor.green(tostring(math.max(0, level * 0.2)) .. "%")
        )
    else
        table.insert(msg, hcolor.grey("- 大于15级，每级获得0.2%资源再生速率"))
    end
    if level > 20 then
        hattribute.set(hero, 0, _attr({ diaoyu_rate = "+" .. tostring(level * 0.5) }))
        table.insert(
            msg,
            "- 大于" ..
            hcolor.green(tostring(20)) ..
            "级，每级获得0.5%钓鱼成功率，当前奖励：" .. hcolor.green(tostring(math.max(0, level * 0.5)) .. "%")
        )
    else
        table.insert(msg, hcolor.grey("- 大于20级，每级获得0.5%钓鱼成功率"))
    end
    if level > 20 then
        hattribute.set(hero, 0, _attr({ fuben_refresh_reduction = "+" .. tostring(level * 2) }))
        table.insert(
            msg,
            "- 大于" ..
            hcolor.green(tostring(20)) ..
            "级，每级降低副本自动刷新间隔2秒（基础间隔360秒，最低60秒）：当前奖励：" .. hcolor.green(tostring(math.max(0, level * 2)) .. "秒")
        )
    else
        table.insert(msg, hcolor.grey("- 大于20级，每级降低副本自动刷新间隔2秒（基础间隔360秒，最低60秒）"))
    end
    if level >= 25 then
        local count = math.floor((level) / 10)
        local addedAttr = hattribute.getAttributeWithMulti(_attr({ wu_bao = "+0.1", fa_bao = "+0.1" }), count)
        hattribute.set(hero, 0, addedAttr)
        table.insert(
            msg,
            "- 达到" ..
            hcolor.green(tostring(25)) ..
            "级，每10级获得" ..
            hcolor.green("0.1%的暴击概率") .. "加成。 当前加成：" .. hcolor.green(description.attribute(addedAttr, "，"))
        )
    else
        table.insert(msg, hcolor.grey("- 达到25级，每10级获得0.1%的暴击概率加成。"))
    end
    if level > 30 then
        local zhushuxing = level * 2
        hattribute.set(hero, 0, _attr({ zhushuxing = "+" .. tostring(zhushuxing) }))
        table.insert(
            msg,
            "- 大于" .. hcolor.green(tostring(30)) .. "级，每级额外获得2点主属性，当前奖励：" .. hcolor.green(tostring(zhushuxing)) .. "点"
        )
    else
        table.insert(msg, hcolor.grey("- 大于30级，每级额外获得1点主属性"))
    end
    if level > 35 then
        hattribute.set(hero, 0, _attr({ dianfeng_jingyan_ratio = "+" .. tostring(level * 0.2) }))
        table.insert(
            msg,
            "- 大于" ..
            hcolor.green(tostring(35)) ..
            "级，每级获得0.2%巅峰经验获取（可以加成任务奖励的巅峰经验），当前奖励：" .. hcolor.green(tostring(math.max(0, level * 0.2)) .. "%")
        )
    else
        table.insert(msg, hcolor.grey("- 大于35级，每级获得0.2%巅峰经验获取"))
    end
    if level >= 40 then
        table.insert(msg, "- 到达" .. hcolor.green(tostring(40)) .. "级，强化装备不会清零")
    else
        table.insert(msg, hcolor.grey("- 到达40级，强化装备不会清零"))
    end

    if level >= 45 then
        table.insert(msg, "- 到达" .. hcolor.green(tostring(45)) .. "级，秘境副本通关后符文获取机会+1")
    else
        table.insert(msg, hcolor.grey("- 到达45级，秘境副本通关后符文获取机会+1"))
    end
    if level >= 50 then
        table.insert(msg, "- 到达" .. hcolor.green(tostring(50)) .. "级，精炼装备不会清零")
    else
        table.insert(msg, hcolor.grey("- 到达50级，精炼装备不会清零"))
    end
    if level > 55 then
        hattribute.set(hero, 0, _attr({ sqnl_huoqu = "+" .. tostring(level * 0.2) }))
        table.insert(
            msg,
            "- 大于" ..
            hcolor.green(tostring(55)) ..
            "级，每级获得0.2%神器能量获取率，当前奖励：" .. hcolor.green(tostring(math.max(0, level * 0.2)) .. "%")
        )
    else
        table.insert(msg, hcolor.grey("- 大于55级，每级获得0.2%神器能量获取率"))
    end

    if level > 60 then
        hattribute.set(hero, 0, _attr({ extra_drop_rate = "+" .. tostring(level * 0.2) }))
        table.insert(
            msg,
            "- 大于" ..
            hcolor.green(tostring(60)) ..
            "级，每级获得0.2%怪物额外掉落率，当前奖励：" .. hcolor.green(tostring(math.max(0, level * 0.2)) .. "%")
        )
    else
        table.insert(msg, hcolor.grey("- 大于60级，每级获得0.2%怪物额外掉落率"))
    end
    if level > 65 then
        local zhushuxing = level * 5
        hattribute.set(hero, 0, _attr({ zhushuxing = "+" .. tostring(zhushuxing) }))
        table.insert(
            msg,
            "- 大于" .. hcolor.green(tostring(65)) .. "级，每级额外获得5点主属性，当前奖励：" .. hcolor.green(tostring(zhushuxing)) .. "点"
        )
    else
        table.insert(msg, hcolor.grey("- 大于65级，每级额外获得5点主属性"))
    end

    if level >= 70 then
        table.insert(
            msg,
            "- 到达" .. hcolor.green(tostring(70)) .. "级，大铭文槽数额外加一"
        )
    else
        table.insert(msg, hcolor.grey("- 到达70级，大铭文槽数额外加一"))
    end

    hcache.set(whichPlayer, "ditudengji_desc", string.implode("|n", msg))
end

hditudengji.getDitudengji = function(whichPlayer)
    local level = hjapi.DzAPI_Map_GetMapLevel(whichPlayer)
    if level == nil or type(level) ~= "number" or level < 1 or level > 300 then
        level = 1
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        err("hero not selected yet")
        return level
    end
    level = level + hattr.getWithLimit(hero, nil, "extra_ditudengji", 0)
    if DEBUGGING then
        level = level + 60
    end
    return level
end
