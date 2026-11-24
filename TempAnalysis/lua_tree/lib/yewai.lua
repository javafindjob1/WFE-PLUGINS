hyewai = { chuansongdian = {} }

YEWAI_NANDU = {
    PUTONG = 1,
    YINGXIONG = 2,
    SHISHI = 3,
    CHUANQI = 4
}

YEWAI_NANDU_LABEL = {
    "普通",
    hcolor.sea("英雄"),
    hcolor.purple("史诗"),
    hcolor.yellow("传奇")
}

function hyewai.buildYewai(options)
    if hyewai[options.name] ~= nil then
        stack("Found duplicate yewai: " .. options.name)
        return
    end
    hyewai[options.name] = Yewai(options)
end

---@param options table
---@alias options {name:string, nandu:YEWAI_NANDU, rect: whichRect}
---@return Fuben
Yewai = function(options)
    ---validate options

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
        activeTimer = nil,
        minions = {},
        minionReborns = {},
        bosses = {},
        bossReborns = {},
        shijieboss = {},
        shijiebossReborns = {}
    }

    if options.blp == nil then
        err("should provide blp")
        return
    end
    hxiaoditu.addDitu(
        this.rect,
        options.blp,
        options.enterTitleTextBlp,
        "ReplaceableTextures\\xiaoditu\\UImap_show_bj1.blp"
    )

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
                hxiaoditu.addInfoToDitu(boss.name, boss.x, boss.y, "ReplaceableTextures\\xiaoditu\\UI_MAP_BOSS.blp")
            end
        end
    end

    if this.config.shijieboss ~= nil then
        for _, boss in ipairs(this.config.shijieboss) do
            if boss.diaoluoConfig ~= nil then
                boss.diaoluoConfig.registerItemSource(this.config.name)
                hxiaoditu.addInfoToDitu(boss.name, boss.x, boss.y, "ReplaceableTextures\\xiaoditu\\UI_MAP_BOSS.blp")
            end
        end
    end

    this._shuaguai = function(nandu)
        if this.config.minions ~= nil then
            this.numMinions = #(this.config.minions)
            for i, minion in ipairs(this.config.minions) do
                htime.setTimeout(
                    0.01 * i,
                    function()
                        if this.minions[i] == nil and this.minionReborns[i] == nil then
                            local tmpLevel = minion.level
                            local ai =
                                minion.ai or
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
                            local face = minion.face or math.random(1, 360)
                            local createX, createY = minion.x, minion.y
                            if minion.randomCreateDistance ~= nil then
                                createX = math.random(minion.x - minion.randomCreateDistance,
                                    minion.x + minion.randomCreateDistance)
                                createY = math.random(minion.y - minion.randomCreateDistance,
                                    minion.y + minion.randomCreateDistance)
                            end
                            this.minions[i] =
                                henemy.create(
                                    {
                                        id = hslk.n2i(minion.name),
                                        x = createX,
                                        y = createY,
                                        facing = face,
                                        attr = hunit.getAttributeBasedOnOptions(
                                            {
                                                level = tmpLevel,
                                                attackSpace = hslk.n2v(minion.name, "cool1"),
                                                guaiwuType = minion.guaiwuType or MONSTER_TYPE.YEWAI_XIAOGUAI
                                            }
                                        ),
                                        AI = table.clone(ai),
                                        diaoluoConfig = minion.diaoluoConfig,
                                        nandu = nandu,
                                        rect = this.rect,
                                        unitType = UNIT_TYPE.MONSTER,
                                        monsterType = minion.guaiwuType or MONSTER_TYPE.YEWAI_XIAOGUAI
                                    }
                                )
                            hskill.add(this.minions[i], hslk.n2i("AI技能模版"), 1, 0)
                            hevent.onDead(
                                this.minions[i],
                                function(evtData)
                                    local level = hunit.getLevel(this.minions[i])
                                    if minion.diaoluoConfig ~= nil then
                                        minion.diaoluoConfig.diaoLuo(
                                            this.minions[i],
                                            nandu,
                                            MONSTER_LEVEL_TO_ITEM_LEVEL[level],
                                            hunit.x(evtData.triggerUnit),
                                            hunit.y(evtData.triggerUnit)
                                        )
                                    end
                                    hunit.destroy(this.minions[i], 1)
                                    this.minions[i] = nil
                                    this.minionReborns[i] =
                                        htime.setTimeout(
                                            minion.reborn,
                                            function(curTimer)
                                                curTimer.destroy()
                                                this.minionReborns[i] = nil
                                            end
                                        )
                                end
                            )

                            if minion.passiveSkill ~= nil and minion.passiveSkill[nandu] ~= nil then
                                for index, skill in ipairs(minion.passiveSkill[nandu]) do
                                    if skill.attr_type == CONST_EVENT.attr then
                                        hattribute.set(this.minions[i], 0, skill.attr)
                                    else
                                        hevent.register(this.minions[i], skill.attr_type, "passiveSkill" .. index, skill
                                            .attr)
                                    end
                                    hbuff.update(
                                        nil,
                                        this.minions[i],
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
                        end
                    end
                )
            end
        end
        if this.config.bosses ~= nil then
            this.numBosses = #(this.config.bosses)
            for i, boss in ipairs(this.config.bosses) do
                if this.bosses[i] == nil and this.bossReborns[i] == nil then
                    local tmpLevel = boss.level
                    local ai =
                        boss.ai or
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
                    this.bosses[i] =
                        henemy.create(
                            {
                                id = hslk.n2i(boss.name),
                                x = boss.x,
                                y = boss.y,
                                facing = boss.face,
                                attr = hunit.getAttributeBasedOnOptions(
                                    {
                                        level = tmpLevel,
                                        attackSpace = hslk.n2v(boss.name, "cool1"),
                                        guaiwuType = MONSTER_TYPE.YEWAI_BOSS
                                    }
                                ),
                                AI = table.clone(ai),
                                diaoluoConfig = boss.diaoluoConfig,
                                nandu = nandu,
                                rect = this.rect,
                                unitType = UNIT_TYPE.MONSTER,
                                monsterType = MONSTER_TYPE.YEWAI_BOSS
                            }
                        )
                    hskill.add(this.bosses[i], hslk.n2i("AI技能模版"), 1, 0)
                    hevent.onDead(
                        this.bosses[i],
                        function(evtData)
                            local level = hunit.getLevel(this.bosses[i])
                            boss.diaoluoConfig.diaoLuo(
                                this.bosses[i],
                                nandu,
                                MONSTER_LEVEL_TO_ITEM_LEVEL[level],
                                hunit.x(evtData.triggerUnit),
                                hunit.y(evtData.triggerUnit)
                            )
                            hunit.destroy(this.bosses[i], 1)
                            this.bosses[i] = nil
                            this.bossReborns[i] =
                                htime.setTimeout(
                                    boss.reborn,
                                    function(curTimer)
                                        curTimer.destroy()
                                        this.bossReborns[i] = nil
                                    end
                                )
                        end
                    )
                    if boss.passiveSkill ~= nil and boss.passiveSkill[nandu] ~= nil then
                        for index, skill in ipairs(boss.passiveSkill[nandu]) do
                            hevent.register(this.bosses[i], skill.attr_type, "passiveSkill" .. index, skill.attr)
                            hbuff.update(
                                nil,
                                this.bosses[i],
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
                end
            end
        end
    end

    this._shuashijieboss = function(nandu)
        if this.config.shijieboss ~= nil then
            for i, shijieboss in ipairs(this.config.shijieboss) do
                if shijieboss.shuaxindelay ~= nil and this.shijieboss[i] == nil and this.shijiebossReborns[i] == nil then
                    local tmpLevel = shijieboss.level
                    local ai =
                        shijieboss.ai or
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
                    local tmpUnit =
                        henemy.create(
                            {
                                id = hslk.n2i(shijieboss.name),
                                x = shijieboss.x,
                                y = shijieboss.y,
                                facing = shijieboss.face,
                                attr = hunit.getAttributeBasedOnOptions(
                                    {
                                        level = tmpLevel,
                                        attackSpace = hslk.n2v(shijieboss.name, "cool1"),
                                        guaiwuType = MONSTER_TYPE.SHIJIE_BOSS
                                    }
                                ),
                                AI = table.clone(ai),
                                diaoluoConfig = shijieboss.diaoluoConfig,
                                nandu = FUBEN_NANDU.PUTONG,
                                rect = this.rect,
                                unitType = UNIT_TYPE.MONSTER,
                                monsterType = MONSTER_TYPE.SHIJIE_BOSS,
                                tuozhanshijian = shijieboss.tuozhanshijian or 60
                            }
                        )
                    -- TODO 暂时回滚
                    hunit.setUpBossXueTiaoForGuaiwu(tmpUnit)
                    this.shijieboss[i] = tmpUnit
                    hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)

                    if shijieboss.jiangli ~= nil then
                        local jianglimsg = {}
                        if shijieboss.jiangli.resource ~= nil then
                            table.insert(jianglimsg, description.resource(shijieboss.jiangli.resource, "|n", "- "))
                        end
                        local shengwang = shijieboss.jiangli.shengwang
                        if shengwang ~= nil then
                            for _, singleSW in ipairs(shengwang) do
                                table.insert(
                                    jianglimsg,
                                    "- " ..
                                    singleSW.shengwangname ..
                                    "声望：+" ..
                                    tostring(singleSW.value) ..
                                    " (需要声望不大于)" .. CONST_SHENGWANG_LABEL[singleSW.maxLevel]
                                )
                            end
                        end
                        hcache.set(tmpUnit, "jianglimsg", string.implode("|n", jianglimsg))
                    end
                    if shijieboss.passiveSkill ~= nil and shijieboss.passiveSkill[FUBEN_NANDU.PUTONG] ~= nil then
                        for index, skill in ipairs(shijieboss.passiveSkill[FUBEN_NANDU.PUTONG]) do
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
                    echo(shijieboss.name .. "已经刷新在" .. options.name)
                    hevent.onDead(
                        tmpUnit,
                        function(evtData)
                            local level = hunit.getLevel(tmpUnit)
                            shijieboss.diaoluoConfig.diaoLuo(
                                tmpUnit,
                                FUBEN_NANDU.PUTONG,
                                MONSTER_LEVEL_TO_ITEM_LEVEL[level],
                                hunit.x(evtData.triggerUnit),
                                hunit.y(evtData.triggerUnit)
                            )
                            hunit.destroy(tmpUnit, 1)
                            this.shijieboss[i] = nil
                            this.shijiebossReborns[i] =
                                htime.setTimeout(
                                    shijieboss.reborn,
                                    function(curTimer)
                                        curTimer.destroy()
                                        this.shijiebossReborns[i] = nil
                                    end
                                )
                            if shijieboss.jiangli ~= nil then
                                local group =
                                    hgroup.createPlayerGroupByXY(
                                        hunit.x(evtData.triggerUnit),
                                        hunit.y(evtData.triggerUnit),
                                        2000
                                    )
                                for _, enumPlayer in ipairs(group) do
                                    local resource = shijieboss.jiangli.resource
                                    if resource ~= nil then
                                        hresource.AddAllResource(enumPlayer, resource, true)
                                    end
                                    local shengwang = shijieboss.jiangli.shengwang
                                    if shengwang ~= nil then
                                        for _, singleSW in ipairs(shengwang) do
                                            if
                                                hshengwang.getShengWangLevel(singleSW.shengwangname, enumPlayer) <=
                                                singleSW.maxLevel
                                            then
                                                local shengwang_rate =
                                                    hattr.getWithLimit(
                                                        hplayer.getMainHero(enumPlayer),
                                                        nil,
                                                        "shengwang_rate",
                                                        0
                                                    )
                                                local finalSWValue =
                                                    math.floor(singleSW.value * (100 + shengwang_rate) / 100)
                                                hshengwang.huodeShengWang(
                                                    singleSW.shengwangname,
                                                    enumPlayer,
                                                    true,
                                                    finalSWValue
                                                )
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    )
                end
            end
        end
    end

    htime.setInterval(
        1,
        function(_)
            this._shuashijieboss(this.config.nandu)
            if
                hgroup.isEmpty(
                    hgroup.createByRect(
                        this.rect,
                        function(whichUnit)
                            if
                                hplayer.isUser(hunit.getOwner(whichUnit)) and
                                hplayer.isPlaying(hunit.getOwner(whichUnit))
                            then
                                return true
                            else
                                return false
                            end
                        end
                    )
                )
            then
                return
            else
                if this.activeTimer == nil then
                    this._shuaguai(this.config.nandu)
                    this.activeTimer =
                        htime.setTimeout(
                            this.config.clearTimeout,
                            function(curTimer)
                                this.activeTimer = nil
                                if this.config.minions ~= nil then
                                    for i, _ in ipairs(this.config.minions) do
                                        if this.minions[i] ~= nil then
                                            hunit.destroy(this.minions[i])
                                        end
                                        if this.minionReborns[i] ~= nil then
                                            this.minionReborns[i].destroy()
                                        end
                                    end
                                end
                                if this.config.bosses ~= nil then
                                    for i, _ in ipairs(this.config.bosses) do
                                        if this.bosses[i] ~= nil then
                                            hunit.destroy(this.bosses[i])
                                        end
                                        if this.bossReborns[i] ~= nil then
                                            this.bossReborns[i].destroy()
                                        end
                                    end
                                end
                                curTimer.destroy()
                                this.minionReborns = {}
                                this.bossReborns = {}
                                this.minions = {}
                                this.bosses = {}
                            end
                        )
                else
                    this._shuaguai(this.config.nandu)
                    this.activeTimer.remain(this.config.clearTimeout)
                end
            end
        end
    )

    --刷新NPC
    if this.config.NPCs ~= nil then
        for _, NPC in ipairs(this.config.NPCs) do
            local x = NPC.x
            local y = NPC.y
            if NPC.nowShowInXiaoditu ~= true then
                hxiaoditu.addInfoToDitu(NPC.name, x, y, "ReplaceableTextures\\xiaoditu\\UI_MAP_NPC.blp")
            end
            hunit.create(
                {
                    whichPlayer = cj.Player(PLAYER_NEUTRAL_PASSIVE),
                    id = hslk.n2i(NPC.name),
                    x = x,
                    y = y,
                    isInvulnerable = true,
                    isPause = false,
                    facing = NPC.face,
                    unitType = UNIT_TYPE.NPC
                }
            )
        end
    end

    if this.config.ZIYUAN ~= nil then
        for _, ziyuan in ipairs(this.config.ZIYUAN) do
            local x = ziyuan.x
            local y = ziyuan.y
            local blp
            if ziyuan.caijiResourceType == CAIJI_RESOURCE_TYPE.KUANGSHI then
                blp = "ReplaceableTextures\\xiaoditu\\UI_MAP_Pick.blp"
            elseif ziyuan.caijiResourceType == CAIJI_RESOURCE_TYPE.CAOYAO then
                blp = "ReplaceableTextures\\xiaoditu\\UI_MAP_flower.blp"
            elseif ziyuan.caijiResourceType == CAIJI_RESOURCE_TYPE.DIAOYUDIAN then
                blp = "ReplaceableTextures\\xiaoditu\\UI_MAP_diaoyudian2.blp"
            else
                err("unknown caijiResourceType")
                return
            end
            hxiaoditu.addInfoToDitu(ziyuan.caijiResourceType .. "：" .. ziyuan.name, x, y, blp)
            local tmp =
                hunit.create(
                    {
                        whichPlayer = cj.Player(PLAYER_NEUTRAL_PASSIVE),
                        id = hslk.n2i(ziyuan.name),
                        x = x,
                        y = y,
                        isInvulnerable = true,
                        isPause = false,
                        unittype = UNIT_TYPE.ZIYUAN
                    }
                )
            local refreshTime = hzhuanye.getRefreshTime(ziyuan.name)
            if refreshTime == nil then
                err("nil refreshTime")
                return
            end
            local tmpKecaiji = {}
            local tmpZiyuan_refresh_count = {}
            hplayer.forEach(
                function(enumPlayer, idx)
                    if tmpKecaiji[enumPlayer] == nil then
                        tmpKecaiji[enumPlayer] = 0
                    end
                    if tmpZiyuan_refresh_count[enumPlayer] == nil then
                        tmpZiyuan_refresh_count[enumPlayer] = refreshTime
                    end
                end
            )
            hcache.set(tmp, "ziyuan_count", tmpKecaiji)
            hcache.set(tmp, "ziyuan_refresh_count", tmpZiyuan_refresh_count)
            htime.setInterval(
                1,
                function(curTimer)
                    local kecaiji = hcache.get(tmp, "ziyuan_count")
                    local ziyuan_refresh_count = hcache.get(tmp, "ziyuan_refresh_count")
                    if kecaiji == nil then
                        err("nil kecaiji")
                    end
                    hplayer.forEach(
                        function(enumPlayer, idx)
                            if hplayer.isPlaying(enumPlayer) == false or hplayer.isUser(enumPlayer) == false then
                                return
                            end
                            local maxCount = hzhuanye.getMaxCaijiCount(ziyuan.name)
                            if hshangcheng.hasItem(enumPlayer, "荣誉会员") then
                                maxCount = maxCount + 8
                            end
                            if kecaiji[enumPlayer] >= maxCount then
                                return
                            end
                            if ziyuan_refresh_count[enumPlayer] > 1 then
                                ziyuan_refresh_count[enumPlayer] = ziyuan_refresh_count[enumPlayer] - 1
                                return
                            end
                            local finalRefreshTime = refreshTime
                            local hero = hplayer.getMainHero(enumPlayer)
                            if hero ~= nil then
                                local zaisheng_speed = hattribute.getWithLimit(hero, nil, "zaisheng_speed", 0)
                                finalRefreshTime = math.floor(finalRefreshTime * 100 / (zaisheng_speed + 100))
                            end
                            ziyuan_refresh_count[enumPlayer] = finalRefreshTime
                            kecaiji[enumPlayer] = kecaiji[enumPlayer] + 1
                        end
                    )
                end
            )
        end
    end
    if this.config.customLogic ~= nil then
        this.config.customLogic()
    end
    hevent.onEnterRect(
        this.rect,
        function(evtData)
            if
                evtData.triggerUnit ~= nil and
                evtData.triggerUnit == hplayer.getMainHero(hunit.getOwner(evtData.triggerUnit))
            then
                local whichPlayer = hunit.getOwner(evtData.triggerUnit)
                echo("进入" .. this.config.name, whichPlayer)
                hcamera.setCameraRegionForPlayer(whichPlayer, this.rect)
                hcamera.toUnit(whichPlayer, 0, evtData.triggerUnit)
                hcache.set(whichPlayer, CONST_CACHE.UNIT_RECT, this.rect)
                hxiaoditu.showXiaoditu(this.rect, whichPlayer)
                local bgm = this.config.bgm or "resource\\war3mapImported\\sound\\BGM_relax.mp3"
                hsound.bgm(bgm, whichPlayer)
            end
        end
    )

    --设置传送阵
    if this.config.chuansongdian ~= nil and #(this.config.chuansongdian) > 0 then
        for i, singleCSD in ipairs(this.config.chuansongdian) do
            table.insert(hyewai.chuansongdian, { csd = singleCSD, level = this.config.level })
            local tmpRect = hrect.create(singleCSD.x, singleCSD.y, 200, 200, singleCSD.name)
            hxiaoditu.addInfoToDitu(
                singleCSD.name .. "传送阵",
                singleCSD.x,
                singleCSD.y,
                "ReplaceableTextures\\xiaoditu\\UI_MAP__chuansongmen1.blp"
            )
            heffect.xyz(
                "war3mapImported\\AZ_CSM01.mdx",
                singleCSD.x,
                singleCSD.y,
                hjapi.Z(singleCSD.x, singleCSD.y),
                -1,
                1,
                1.3,
                1.3,
                1.3,
                0,
                0,
                singleCSD.face
            )
            hevent.onEnterRect(
                tmpRect,
                function(evtData)
                    if
                        evtData.triggerUnit ~= nil and
                        evtData.triggerUnit == hplayer.getMainHero(hunit.getOwner(evtData.triggerUnit)) and
                        htime.checkCoolDown(evtData.triggerUnit, CONST_CACHE.UNIT_USE_CHUANSONGDIAN) == true
                    then
                        if hbuff.hasBuff(evtData.triggerUnit, "自动战斗") then
                            sysecho("自动战斗状态下无法使用传送点", hunit.getOwner(evtData.triggerUnit))
                            return
                        end
                        local availableButton = {}
                        for i, csdData in ipairs(hyewai.chuansongdian) do
                            if csdData.csd.name ~= singleCSD.name then
                                table.insert(
                                    availableButton,
                                    {
                                        value = i,
                                        label = csdData.csd.name ..
                                            "(" .. tostring(csdData.level) .. "级) 费用：" .. csdData.csd.cost .. "金币"
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
                            hunit.getOwner(evtData.triggerUnit),
                            {
                                title = singleCSD.name .. "传送点",
                                buttons = availableButton
                            },
                            function(btnValue)
                                if btnValue == 0 then
                                    return
                                end
                                local hero = evtData.triggerUnit
                                if hunit.getLevel(hero) < hyewai.chuansongdian[btnValue].level then
                                    echo(
                                        "传送失败，冒险者等级不够，需要" .. tostring(hyewai.chuansongdian[btnValue].level) .. "级",
                                        hunit.getOwner(evtData.triggerUnit)
                                    )
                                    return
                                end
                                local cost = {
                                    { type = HSHOP_COST_TYPE.gold, value = hyewai.chuansongdian[btnValue].csd.cost }
                                }
                                if hshangcheng.hasItem(hunit.getOwner(hero), "荣誉会员") == false then
                                    if hresource.checkHasAllResource(hunit.getOwner(hero), cost, true) == false then
                                        return
                                    end
                                    hresource.changeAllResource(hunit.getOwner(hero), cost, true)
                                end
                                htime.setupAndCheckCoolDown(hero, CONST_CACHE.UNIT_USE_CHUANSONGDIAN, 1)
                                hunit.portal(
                                    hero,
                                    hyewai.chuansongdian[btnValue].csd.x,
                                    hyewai.chuansongdian[btnValue].csd.y,
                                    hunit.getFacing(hero)
                                )
                            end
                        )
                    end
                end
            )
        end
    end
    --设置传送门
    if this.config.portal ~= nil then
        for _, onePortal in ipairs(this.config.portal) do
            -- 制造传送门特效
            heffect.xyz("war3mapImported\\X019_AZ.mdl", onePortal.x, onePortal.y, hjapi.Z(onePortal.x, onePortal.y), -1)
            local entryRect = hrect.create(onePortal.x, onePortal.y, 100, 100, this.config.name .. "i")
            hxiaoditu.addInfoToDitu(
                "去往" .. onePortal.destination,
                onePortal.x,
                onePortal.y,
                "ReplaceableTextures\\xiaoditu\\UI_MAP__chuansongmen1.blp"
            )
            hevent.onEnterRect(
                entryRect,
                function(evtData)
                    if
                        evtData.triggerUnit ~= nil and
                        evtData.triggerUnit == hplayer.getMainHero(hunit.getOwner(evtData.triggerUnit))
                    then
                        if hbuff.hasBuff(evtData.triggerUnit, "自动战斗") then
                            sysecho("自动战斗状态下无法使用传送点", hunit.getOwner(evtData.triggerUnit))
                            return
                        end
                        if hunit.getLevel(evtData.triggerUnit) < this.config.level then
                            echo(
                                "传送失败，冒险者等级不够，需要" .. tostring(this.config.level) .. "级",
                                hunit.getOwner(evtData.triggerUnit)
                            )
                            return
                        end
                        hunit.portal(evtData.triggerUnit, onePortal.destX, onePortal.destY, 0)
                        hcamera.toXY(hunit.getOwner(evtData.triggerUnit), onePortal.destX, onePortal.destY)
                    end
                end
            )
        end
    end

    if this.config.shijieboss ~= nil then
        for i, shijieboss in ipairs(this.config.shijieboss) do
            if shijieboss.shuaxindelay ~= nil then
                this.shijiebossReborns[i] =
                    htime.setTimeout(
                        shijieboss.shuaxindelay,
                        function(curTimer)
                            this.shijiebossReborns[i] = nil
                            this._shuashijieboss(this.config.nandu)
                            curTimer.destroy()
                        end
                    )
            end
        end
    end

    return this
end
