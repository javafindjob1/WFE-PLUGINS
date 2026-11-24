hfuben = {}

FUBEN_NANDU = {
    PUTONG = 1,
    YINGXIONG = 2,
    SHISHI = 3,
    CHUANQI = 4
}

FUBEN_STATUS = {
    KAIHUANG = 1,
    JIANHUA = 2,
    CLOSED = 3
}

FUBEN_NANDU_LABEL = {
    "普通",
    hcolor.sea("英雄"),
    hcolor.purple("史诗"),
    hcolor.yellow("传奇")
}
FUBEN_NANDU_LABEL_WO_COLOR = {
    "普通",
    "英雄",
    "史诗",
    "传奇"
}

FUBEN_NANDU_ITEM_FIXED_ATTR_MULTI = { 1, 1.1, 1.25, 1.45, 1.6 }

SHUAGUAIMOSHI = {
    SHUASUOYOU = 0,       -- 所有怪一起刷
    ANBOSHU_GUDING = 1,   -- 按波数刷怪，固定间隔
    ANBOSHU_QINGKONG = 2, -- 按波数刷怪，清空才刷下一波
    FLEXIBLE = 3          -- 根据配置 每个怪可以指定刷怪条件
}

function hfuben.buildFuben(options)
    if hfuben[options.name] ~= nil then
        stack("Found duplicate fuben: " .. options.name)
        return
    end
    hfuben[options.name] = Fuben(options)
end

---@param options table
---@alias options {name:string, nandu:FUBEN_NANDU, rect: whichRect}
---@return Fuben
Fuben = function(options)
    ---validate options
    if options.status == FUBEN_STATUS.CLOSED then
        return
    end

    ---@class Fuben
    local this = {
        config = options,
        rect = hrect.createShangBy4P(
            options.rectParam.minX,
            options.rectParam.minY,
            options.rectParam.maxX,
            options.rectParam.maxY,
            options.name
        ),
        finishRect = hrect.createShangBy4P(
            options.rectParam.minX - 100,
            options.rectParam.minY - 100,
            options.rectParam.maxX + 100,
            options.rectParam.maxY + 100,
            options.name .. "finishRect"
        ),
        current = { occupied = false, startTime = 0 },
        entryRect = hrect.create(options.entryPosition.x, options.entryPosition.y, 200, 200, options.name .. "入口"),
        autoRefreshTimer = nil
    }
    hxiaoditu.addDitu(
        this.rect,
        options.blp,
        options.enterTitleTextBlp,
        "ReplaceableTextures\\xiaoditu\\UImap_show_bj2.blp"
    )

    this.chuansongmen =
        hunit.create(
            {
                whichPlayer = cj.Player(PLAYER_NEUTRAL_PASSIVE),
                id = hslk.n2i("副本传送门"),
                x = options.entryPosition.x,
                y = options.entryPosition.y,
                isInvulnerable = true,
                isPause = false
            }
        )
    hxiaoditu.addInfoToDitu(
        "副本：" .. options.name,
        options.entryPosition.x,
        options.entryPosition.y,
        "ReplaceableTextures\\xiaoditu\\UI_MAP__chuansongmen2.blp"
    )

    local msg = {}
    table.insert(msg, hcolor.yellow("副本信息：" .. this.config.name))
    table.insert(msg, "")
    for nandu = 1, 4, 1 do
        if this.config.nanduLevelConfig[nandu] ~= nil then
            table.insert(
                msg,
                FUBEN_NANDU_LABEL[nandu] .. "难度 （" .. hcolor.green(this.config.nanduLevelConfig[nandu]) .. "级）"
            )
            table.insert(msg, hcolor.yellow("通关奖励："))
            if this.config.tongguanjiangli ~= nil then
                local resource = this.config.tongguanjiangli[nandu].resource
                if resource ~= nil then
                    table.insert(msg, description.resource(resource, "|n", "- "))
                end
                local shengwang = this.config.tongguanjiangli[nandu].shengwang
                if shengwang ~= nil then
                    for _, singleSW in ipairs(shengwang) do
                        table.insert(
                            msg,
                            "- " ..
                            singleSW.shengwangname ..
                            "声望：+" ..
                            tostring(singleSW.value) ..
                            " (需要声望不大于)" .. CONST_SHENGWANG_LABEL[singleSW.maxLevel]
                        )
                    end
                end
            end
        end
        table.insert(msg, "")
    end
    if hartifact.isDoubleDiaoluo(this.config.name) then
        table.insert(msg, hcolor.yellow("当前副本掉落的神器能量在今日翻倍！"))
    end
    hcache.set(this.chuansongmen, "chuansongmen_info", string.implode("|n", msg))

    if this.config.minions ~= nil then
        for _, minion in ipairs(this.config.minions) do
            if minion.diaoluoConfig ~= nil then
                minion.diaoluoConfig.registerItemSource(this.config.name)
            end
        end
    end
    if this.config.bosses ~= nil then
        for _, boss in ipairs(this.config.bosses) do
            if boss.diaoluoConfig ~= nil then
                boss.diaoluoConfig.registerItemSource(this.config.name)
            end
            hxiaoditu.addInfoToDitu(boss.name, boss.x, boss.y, "ReplaceableTextures\\xiaoditu\\UI_MAP_BOSS.blp")
        end
    end

    --- start fuben
    ---@return bool
    this.tryStartFuben = function(heroes, nandu, mijing, skipOccupyCheck)
        if skipOccupyCheck ~= true and this._canStartFuben(heroes, nandu, mijing) == false then
            return false
        end
        this.current.startTime = htime.inc
        if this.autoRefreshTimer ~= nil then
            this.autoRefreshTimer.destroy()
            this.autoRefreshTimer = nil
        end
        this._portalHerosToFuben(heroes)
        this._showFubenInfo(heroes, nandu, mijing)
        this._shuaguai(heroes, nandu, mijing)
        this._setUpFinishChecker(heroes, nandu, mijing)
        return true
    end
    this._canStartFuben = function(heroes, nandu, mijing)
        if this.current.occupied then
            return false
        end
        local tmpLevel = this.config.nanduLevelConfig[nandu]
        if tmpLevel == nil then
            err("tmpLevel nil")
        end
        for _, hero in ipairs(heroes) do
            if not DEBUGGING and hhero.getCurLevel(hero) < tmpLevel - 5 then
                sysecho("有玩家等级低于副本要求，需求：" .. tostring(tmpLevel - 5))
                return false
            end
            if hfightzhuangtai.isInFight(hero) then
                sysecho("有玩家处于战斗中，不能进入副本")
                return false
            end
        end
    end

    this.portalHerosToFubenEntry = function(hero)
        hunit.portal(hero, this.config.entryPosition.x, this.config.entryPosition.y, 0)
    end
    this.isInFUBEN = function(hero)
        if hero == nil then
            return false
        end
        return hrect.isInner(this.rect, hunit.x(hero), hunit.y(hero))
    end
    this._portalHerosToFuben = function(heroes)
        this.current.occupied = true
        for _, hero in ipairs(heroes) do
            hunit.portal(hero, this.config.startPosition.x, this.config.startPosition.y, 0)
            hcache.set(hero, "LAST_FUBEN", this)
        end
    end
    this._showFubenInfo = function(heroes, nandu, mijing)
        local finalmessage =
            "进入副本：" .. this.config.name .. "，难度：" .. FUBEN_NANDU_LABEL[nandu] .. "，人数：" .. tostring(#heroes)
        if nandu == FUBEN_NANDU.CHUANQI and mijing ~= nil then
            finalmessage = finalmessage .. "，层数：" .. mijing
        end
        for _, hero in ipairs(heroes) do
            sysecho(finalmessage, hunit.getOwner(hero))
        end
    end
    this._shuaguai = function(heroes, nandu, mijing)
        local basicLevel = this.config.nanduLevelConfig[nandu]
        for iindex, minion in ipairs(this.config.minions) do
            htime.setTimeout(
                0.01 * iindex,
                function()
                    local number = minion.number or 1
                    local tmpLevel = basicLevel
                    if minion.levelAdj ~= nil then
                        tmpLevel = tmpLevel + minion.levelAdj
                    end
                    local ai =
                        UnitAI(
                            {
                                {
                                    aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                    aiData = {
                                        targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                    }
                                }
                            }
                        )
                    if minion.ai ~= nil then
                        if type(minion.ai) == "table" then
                            ai = minion.ai
                        elseif type(minion.ai) == "function" then
                            ai = minion.ai(tmpLevel, nandu, #heroes, options.status, mijing)
                        else
                            err("not supported ai type" .. type(minion.ai))
                        end
                    end
                    local monsterType = minion.monsterType or MONSTER_TYPE.FUBEN_XIAOGUAI
                    local citiao
                    local minionAttrCount
                    if nandu == FUBEN_NANDU.CHUANQI and mijing ~= nil then
                        citiao = hmijing.getCitiaoForMijing(this.config.name, mijing)
                        for _, v in ipairs(citiao) do
                            if v.name == "繁盛" then
                                number = number * 2
                            end
                        end
                        minionAttrCount = #heroes
                    end
                    for _ = 1, number, 1 do
                        local tmpAttr =
                            hunit.getAttributeBasedOnOptions(
                                {
                                    level = tmpLevel,
                                    attackSpace = hslk.n2v(minion.name, "cool1"),
                                    guaiwuType = monsterType,
                                    nandu = nandu,
                                    mijing = mijing,
                                    count = minionAttrCount,
                                }
                            )
                        local randomRadius = minion.randomRadius or 100
                        local tmpUnit =
                            henemy.create(
                                {
                                    id = hslk.n2i(minion.name),
                                    x = minion.x + math.random(-randomRadius, randomRadius),
                                    y = minion.y + math.random(-randomRadius, randomRadius),
                                    facing = math.random(0, 360),
                                    attr = tmpAttr,
                                    AI = table.clone(ai),
                                    diaoluoConfig = minion.diaoluoConfig,
                                    nandu = nandu,
                                    rect = this.rect,
                                    tuozhanshijian = 36000,
                                    monsterType = monsterType
                                }
                            )
                        hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)

                        -- 秘境不直接掉落物品
                        hevent.onDead(
                            tmpUnit,
                            function(evtData)
                                minion.diaoluoConfig.diaoLuo(
                                    tmpUnit,
                                    nandu,
                                    MONSTER_LEVEL_TO_ITEM_LEVEL[hunit.getLevel(tmpUnit)],
                                    hunit.x(evtData.triggerUnit),
                                    hunit.y(evtData.triggerUnit),
                                    heroes
                                )
                            end
                        )

                        if minion.passiveSkill ~= nil and minion.passiveSkill[nandu] ~= nil then
                            for index, skill in ipairs(minion.passiveSkill[nandu]) do
                                if skill.attr_type == CONST_EVENT.attr then
                                    hattribute.set(tmpUnit, 0, skill.attr)
                                else
                                    hevent.register(tmpUnit, skill.attr_type, "passiveSkill" .. index, skill.attr)
                                end
                                hbuff.update(
                                    nil,
                                    tmpUnit,
                                    "被动技能说明" .. index,
                                    true,
                                    nil,
                                    nil,
                                    "ReplaceableTextures\\BTNPriest_icon_Chakra_blue.blp",
                                    skill.description,
                                    1,
                                    nil,
                                    nil,
                                    nil,
                                    nil,
                                    HBUFF_UPDATE_MODE.OVERWRITE,
                                    false
                                )
                            end
                        end

                        if citiao ~= nil then
                            if #citiao > 0 then
                                for index, v in ipairs(citiao) do
                                    local tmpDesc = ""
                                    if v.attr_type == CONST_EVENT.attr then
                                        hattribute.set(tmpUnit, 0, v.attr)
                                        tmpDesc = description.attribute(v.attr, "，")
                                    else
                                        hevent.register(tmpUnit, v.attr_type, "damijingpassiveSkill" .. index, v.attr)
                                        tmpDesc = v.description
                                    end
                                    hbuff.update(
                                        nil,
                                        tmpUnit,
                                        "damijingpassiveSkill" .. index,
                                        true,
                                        nil,
                                        nil,
                                        v.art or "ReplaceableTextures\\BTNPriest_icon_Chakra_blue.blp",
                                        hcolor.green(v.name) .. "|n" .. tmpDesc,
                                        1,
                                        nil,
                                        nil,
                                        nil,
                                        nil,
                                        HBUFF_UPDATE_MODE.OVERWRITE,
                                        false
                                    )
                                end
                            end
                        end
                    end
                end)
        end
        for _, boss in ipairs(this.config.bosses) do
            local tmpLevel = basicLevel
            if boss.levelAdj ~= nil then
                tmpLevel = tmpLevel + boss.levelAdj
            end
            local tmpAttr =
                hunit.getAttributeBasedOnOptions(
                    {
                        level = tmpLevel,
                        attackSpace = hslk.n2v(boss.name, "cool1"),
                        guaiwuType = MONSTER_TYPE.FUBEN_BOSS,
                        nandu = nandu,
                        count = #heroes,
                        status = this.config.status,
                        mijing = mijing
                    }
                )
            local ai =
                UnitAI(
                    {
                        {
                            aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                            }
                        }
                    }
                )
            if boss.ai ~= nil then
                if type(boss.ai) == "table" then
                    ai = boss.ai
                elseif type(boss.ai) == "function" then
                    ai = boss.ai(tmpLevel, nandu, #heroes, options.status, mijing)
                else
                    err("not supported ai type" .. type(boss.ai))
                end
            end
            local tmpUnit =
                henemy.create(
                    {
                        id = hslk.n2i(boss.name),
                        x = boss.x,
                        y = boss.y,
                        facing = boss.face,
                        attr = tmpAttr,
                        AI = table.clone(ai),
                        diaoluoConfig = boss.diaoluoConfig,
                        nandu = nandu,
                        rect = this.rect,
                        tuozhanshijian = 36000,
                        monsterType = MONSTER_TYPE.FUBEN_BOSS,
                        unitType = UNIT_TYPE.MONSTER
                    }
                )
            hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
            -- TODO 暂时回滚
            hunit.setUpBossXueTiaoForGuaiwu(tmpUnit)
            hevent.onDead(
                tmpUnit,
                function(evtData)
                    boss.diaoluoConfig.diaoLuo(
                        tmpUnit,
                        nandu,
                        MONSTER_LEVEL_TO_ITEM_LEVEL[hunit.getLevel(tmpUnit)],
                        hunit.x(evtData.triggerUnit),
                        hunit.y(evtData.triggerUnit),
                        heroes
                    )
                end
            )
            htime.setInterval(
                1,
                function(curTimer)
                    if hunit.isAlive(tmpUnit) == false or hunit.isDestroyed(tmpUnit) then
                        curTimer.destroy()
                        return
                    end

                    if hfightzhuangtai.isInFight(tmpUnit) and boss.recoveryDistance ~= nil and math.distance(hunit.x(tmpUnit), hunit.y(tmpUnit), boss.x, boss.y) > boss.recoveryDistance then
                        hskill.heal(
                            {
                                healer = tmpUnit,
                                healee = tmpUnit,
                                heal = hunit.getMaxLife(tmpUnit) * 0.2,
                                healType = HEAL_TYPE.SKILL,
                                triggerSkill = hslk.n2i("AI技能模版")
                            }
                        )
                        sysecho(hunit.getName(tmpUnit) .. "距离出生点距离过远，超过" .. boss.recoveryDistance .. "，每秒恢复20%生命值")
                    end

                    -- checkdistance with chouhen diyi
                    local whichUnit = hfightzhuangtai.getChouhengdiyi(tmpUnit)
                    local hpbDistance = 1500
                    if boss.huixuedistance ~= nil then
                        hpbDistance = boss.huixuedistance
                    end
                    if
                        whichUnit ~= nil and hunit.isAlive(whichUnit) and
                        math.distance(hunit.x(whichUnit), hunit.y(whichUnit), hunit.x(tmpUnit), hunit.y(tmpUnit)) >
                        hpbDistance
                    then
                        hskill.heal(
                            {
                                healer = tmpUnit,
                                healee = tmpUnit,
                                heal = hunit.getMaxLife(tmpUnit) * 0.05,
                                healType = HEAL_TYPE.SKILL,
                                triggerSkill = hslk.n2i("AI技能模版")
                            }
                        )
                        sysecho(hunit.getName(tmpUnit) .. "距离仇恨最高单位距离过远（" .. hpbDistance .. "），恢复5%生命值")
                    end
                end
            )
            if boss.passiveSkill ~= nil and boss.passiveSkill[nandu] ~= nil then
                for index, skill in ipairs(boss.passiveSkill[nandu]) do
                    if skill.attr_type == CONST_EVENT.attr then
                        hattribute.set(tmpUnit, 0, skill.attr)
                    else
                        hevent.register(tmpUnit, skill.attr_type, "passiveSkill" .. index, skill.attr)
                    end
                    hbuff.update(
                        nil,
                        tmpUnit,
                        "被动技能说明" .. index,
                        true,
                        nil,
                        nil,
                        "ReplaceableTextures\\BTNPriest_icon_Chakra_blue.blp",
                        skill.description,
                        1,
                        nil,
                        nil,
                        nil,
                        nil,
                        HBUFF_UPDATE_MODE.OVERWRITE,
                        false
                    )
                end
            end
            if nandu == FUBEN_NANDU.CHUANQI and mijing ~= nil then
                local citiao = hmijing.getCitiaoForMijing(this.config.name, mijing)
                if #citiao > 0 then
                    for index, v in ipairs(citiao) do
                        local tmpDesc = ""
                        if v.attr_type == CONST_EVENT.attr then
                            hattribute.set(tmpUnit, 0, v.attr)
                            tmpDesc = description.attribute(v.attr, "，")
                        else
                            hevent.register(tmpUnit, v.attr_type, "damijingpassiveSkill" .. index, v.attr)
                            tmpDesc = v.description
                        end
                        hbuff.update(
                            nil,
                            tmpUnit,
                            "damijingpassiveSkill" .. index,
                            true,
                            nil,
                            nil,
                            v.art or "ReplaceableTextures\\BTNPriest_icon_Chakra_blue.blp",
                            hcolor.green(v.name) .. "|n" .. tmpDesc,
                            1,
                            nil,
                            nil,
                            nil,
                            nil,
                            HBUFF_UPDATE_MODE.OVERWRITE,
                            false
                        )
                        if v.name == "统领" then
                            hattribute.set(tmpUnit, 0, _attr({ shengming_baifenbi = "+100" }))
                        end
                    end
                end
            end
        end
    end
    this._setUpFinishChecker = function(heroes, nandu, mijing)
        local reenterTimer = htime.setInterval(
            2,
            function(t)
                if
                    hgroup.isEmpty(
                        hgroup.createByRect(
                            this.finishRect,
                            function(whichUnit)
                                if hplayer.isNeutral(hunit.getOwner(whichUnit)) then
                                    return false
                                else
                                    return true
                                end
                            end
                        )
                    )
                then
                    this.current.occupied = false
                    sysecho("副本" .. this.config.name .. "已经可以重新进入")
                    t.destroy()
                end
            end
        )
        htime.setInterval(
            0.5,
            function(t)
                local finish = false
                local enermyGroup =
                    hgroup.createByRect(
                        this.finishRect,
                        function(whichUnit)
                            if hplayer.isUser(hunit.getOwner(whichUnit)) or hplayer.isNeutral(hunit.getOwner(whichUnit)) then
                                return false
                            else
                                return true
                            end
                        end
                    )
                local playerGroup =
                    hgroup.createByRect(
                        this.finishRect,
                        function(whichUnit)
                            if hplayer.isUser(hunit.getOwner(whichUnit)) then
                                return true
                            else
                                return false
                            end
                        end
                    )
                local mijingStr = ""

                if mijing ~= nil then
                    mijingStr = "（" .. mijing .. "层）"
                end
                if hgroup.isEmpty(enermyGroup) then
                    local haoshi = (htime.inc - this.current.startTime) / 100

                    local msg =
                        "通关副本: " ..
                        this.config.name ..
                        "(" .. FUBEN_NANDU_LABEL[nandu] .. mijingStr .. ") 完成。耗时：" .. tostring(haoshi) .. "秒"
                    for _, hero in ipairs(heroes) do
                        sysecho(msg, hunit.getOwner(hero))
                        hevent.trigger(
                            hero,
                            CONST_EVENT.finishFUBEN,
                            {
                                triggerUnit = hero,
                                nandu = nandu,
                                fubenName = this.config.name,
                                numUsers = #heroes,
                                haoshi = haoshi,
                                mijing = mijing
                            }
                        )
                        if this.config.tongguanjiangli ~= nil and this.config.tongguanjiangli[nandu] ~= nil then
                            local resource = this.config.tongguanjiangli[nandu].resource
                            if resource ~= nil then
                                hresource.AddAllResource(hunit.getOwner(hero), resource, true)
                            end
                            local shengwang = this.config.tongguanjiangli[nandu].shengwang
                            if shengwang ~= nil then
                                for _, singleSW in ipairs(shengwang) do
                                    if
                                        hshengwang.getShengWangLevel(singleSW.shengwangname, hunit.getOwner(hero)) <=
                                        singleSW.maxLevel
                                    then
                                        local shengwang_rate = hattr.getWithLimit(hero, nil, "shengwang_rate", 0)
                                        local finalSWValue = math.floor(singleSW.value * (100 + shengwang_rate) / 100)
                                        hshengwang.huodeShengWang(
                                            singleSW.shengwangname,
                                            hunit.getOwner(hero),
                                            true,
                                            finalSWValue
                                        )
                                    end
                                end
                            end
                        end
                    end
                    finish = true
                    hdaixin.fubenjiesuan(this.config.name, nandu, heroes, this.rect)
                elseif hgroup.isEmpty(playerGroup) then
                    hgroup.clear(enermyGroup, true)
                    local msg =
                        "通关副本: " ..
                        this.config.name ..
                        "(" ..
                        FUBEN_NANDU_LABEL[nandu] ..
                        mijingStr ..
                        ") 失败。耗时：" .. tostring((htime.inc - this.current.startTime) / 100) .. "秒"
                    for _, hero in ipairs(heroes) do
                        sysecho(msg, hunit.getOwner(hero))
                    end
                    finish = true
                end

                if finish then
                    local refreshReduction = 0
                    for _, hero in ipairs(heroes) do
                        local timerFrame = hjapi.DzFrameFindByName("FUBEN_TIMER", 0)
                        hjapi.DzFrameShow(timerFrame, false)
                        if refreshReduction < hattr.getWithLimit(hero, nil, "fuben_refresh_reduction", 0) then
                            refreshReduction = hattr.getWithLimit(hero, nil, "fuben_refresh_reduction", 0)
                        end
                    end
                    t.destroy()
                    if this.autoRefreshTimer ~= nil then
                        this.autoRefreshTimer.destroy()
                    end
                    local fubenCD = math.max(60, 360 - refreshReduction)
                    this.autoRefreshTimer = htime.setTimeout(fubenCD, function(curTimer)
                        local enermyGroup =
                            hgroup.createByRect(
                                this.finishRect,
                                function(whichUnit)
                                    if hplayer.isUser(hunit.getOwner(whichUnit)) or hplayer.isNeutral(hunit.getOwner(whichUnit)) then
                                        return false
                                    else
                                        return true
                                    end
                                end
                            )
                        local remainingHeroes = hgroup.createByRect(
                            this.finishRect,
                            function(filterUnit)
                                return filterUnit == hplayer.getMainHero(hunit.getOwner(filterUnit))
                            end
                        )
                        if hgroup.isEmpty(enermyGroup) and not hgroup.isEmpty(remainingHeroes) then
                            reenterTimer.destroy()
                            this.tryStartFuben(remainingHeroes, nandu, mijing, true)
                        end
                    end)
                else
                    local timePassed = t.passedSec()
                    local desc = hjapi.DzFrameFindByName("FUBEN_TIMER_Desc", 0)
                    local nanduStr = FUBEN_NANDU_LABEL[nandu]
                    if nandu == FUBEN_NANDU.CHUANQI and mijing ~= nil then
                        nanduStr = nanduStr .. mijing .. "层"
                    end
                    for _, hero in ipairs(heroes) do
                        local timerFrame = hjapi.DzFrameFindByName("FUBEN_TIMER", 0)
                        if hplayer.loc() == hunit.getOwner(hero) then
                            hjapi.DzFrameSetText(
                                desc,
                                this.config.name .. "(" .. nanduStr .. "，" .. #heroes .. "人，当前耗时" .. timePassed .. "秒）"
                            )
                            hjapi.DzFrameShow(timerFrame, true)
                        end
                    end
                end
            end
        )
    end

    this._onfinish = function(heroes)
    end

    -- setup entry portal
    hevent.onEnterRect(
        this.entryRect,
        function(evtData)
            local player = hunit.getOwner(evtData.triggerUnit)
            if
                hplayer.isPlaying(player) and hplayer.isUser(player) and
                evtData.triggerUnit == hplayer.getMainHero(player)
            then
                if hbuff.hasBuff(evtData.triggerUnit, "自动战斗") then
                    sysecho("自动战斗状态下无法使用传送点", hunit.getOwner(evtData.triggerUnit))
                    return
                end
                if this.current.occupied == true then
                    sysecho("当前副本有人，请稍后再来。", player)
                    return
                end
                local availableButton = {}
                for nandu, level in pairs(options.nanduLevelConfig) do
                    if nandu ~= FUBEN_NANDU.CHUANQI or hmijing.isCurrentMijingOpen(options.name) then
                        table.insert(
                            availableButton,
                            {
                                value = nandu,
                                label = FUBEN_NANDU_LABEL[nandu] .. "(" .. tostring(level) .. "级)"
                            }
                        )
                    end
                end
                table.insert(
                    availableButton,
                    {
                        value = 0,
                        label = "只是路过"
                    }
                )
                hdialog.create(
                    player,
                    {
                        title = "副本：" .. options.name,
                        buttons = availableButton
                    },
                    function(btnValue)
                        if btnValue == 0 then
                            return
                        end
                        if btnValue == FUBEN_NANDU.CHUANQI then
                            local availableButton = {}
                            local mijing = hmijing.getNextTiaozhanLevel(options.name, player)
                            local preSetLevel = { 1, 9, 14, 22, 30 }
                            for _, i in ipairs(preSetLevel) do
                                if i < mijing then
                                    table.insert(
                                        availableButton,
                                        {
                                            value = i,
                                            label = FUBEN_NANDU_LABEL[FUBEN_NANDU.CHUANQI] .. "(" .. tostring(i) .. "级)"
                                        }
                                    )
                                else
                                    break
                                end
                            end
                            table.insert(
                                availableButton,
                                {
                                    value = mijing,
                                    label = FUBEN_NANDU_LABEL[FUBEN_NANDU.CHUANQI] .. "(" .. tostring(mijing) .. "级)"
                                }
                            )
                            table.insert(
                                availableButton,
                                {
                                    value = 0,
                                    label = "只是路过"
                                }
                            )
                            hdialog.create(
                                player,
                                {
                                    title = "传奇秘境：" .. options.name,
                                    buttons = availableButton
                                },
                                function(btnValue)
                                    if btnValue == 0 then
                                        return
                                    end
                                    local heroes =
                                        hgroup.createByUnit(
                                            this.chuansongmen,
                                            700,
                                            function(filterUnit)
                                                local tmpPlayer = hunit.getOwner(filterUnit)
                                                return hplayer.isPlaying(tmpPlayer)
                                                    and hplayer.isUser(tmpPlayer)
                                                    and filterUnit == hplayer.getMainHero(tmpPlayer)
                                            end
                                        )
                                    this.tryStartFuben(heroes, FUBEN_NANDU.CHUANQI, btnValue)
                                end
                            )
                        else
                            local heroes =
                                hgroup.createByUnit(
                                    this.chuansongmen,
                                    700,
                                    function(filterUnit)
                                        local tmpPlayer = hunit.getOwner(filterUnit)
                                        return hplayer.isPlaying(tmpPlayer) and hplayer.isUser(tmpPlayer) and
                                            filterUnit == hplayer.getMainHero(tmpPlayer)
                                    end
                                )
                            local mijing = nil
                            if btnValue == FUBEN_NANDU.CHUANQI then
                                mijing = hmijing.getNextTiaozhanLevel(options.name, player)
                            end
                            this.tryStartFuben(heroes, btnValue, mijing)
                            hgroup.clear(heroes, false)
                        end
                    end
                )
            end
        end
    )
    hevent.onEnterRect(
        this.rect,
        function(evtData)
            if
                evtData.triggerUnit ~= nil and
                evtData.triggerUnit == hplayer.getMainHero(hunit.getOwner(evtData.triggerUnit))
            then
                local whichPlayer = hunit.getOwner(evtData.triggerUnit)
                hcamera.setCameraRegionForPlayer(whichPlayer, this.rect)
                hcamera.toUnit(whichPlayer, 0, evtData.triggerUnit)
                hcache.set(whichPlayer, CONST_CACHE.UNIT_RECT, this.rect)
                hxiaoditu.showXiaoditu(this.rect, whichPlayer)
                local bgm = this.config.bgm or "resource\\war3mapImported\\sound\\BMG_attack.mp3"
                hsound.bgm(bgm, whichPlayer)
            end
        end
    )
    return this
end

hfuben.bossHanhua = function(whichUnit, msg)
    htextTag.create2Unit(whichUnit, msg, 10, "eae30a", 1, 5, 150)
end
