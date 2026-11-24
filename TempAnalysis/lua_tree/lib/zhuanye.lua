hzhuanye = { qianghuawupinConfig = {}, zhuanyeNameCDStrToQianghuawupinName = {}, shaguaiConfig = {} }
---
--- zhuanye config
---
---{
---  {
---    name: "锻造",
--     cundangStr = "zhuanye",
--     isPerHero = false,
--     lvlCunDangStartIndex = 1,
--     lvlCunDangEndIndex = 1,
--     expCunDangStartIndex = 2,
--     expCunDangEndIndex = 3,
--     art = "art",
--     maxLevel=6,
--     description = "训练说明",
--     currentLevel = 0,
--     currentExp = 0,
--     attributeLevel = {},
---  }
---}
---

ZHUANYE_LEVEL_TO_LABEL = {}
ZHUANYE_LEVEL_TO_LABEL[0] = "初级"
ZHUANYE_LEVEL_TO_LABEL[1] = "中级"
ZHUANYE_LEVEL_TO_LABEL[2] = "高级"
ZHUANYE_LEVEL_TO_LABEL[3] = "专家级"
ZHUANYE_LEVEL_TO_LABEL[4] = "大师级"
ZHUANYE_LEVEL_TO_LABEL[5] = "宗师级"
ZHUANYE_LEVEL_TO_LABEL[6] = "巨匠级"

CAIJI_RESOURCE_TYPE = {
    CAOYAO = "草药",
    KUANGSHI = "矿石",
    DIAOYUDIAN = "钓鱼点"
}

ZHUANYE_ZHUANGBEI_QIANGHUA_WUPIN_SHIYONG = {
    BAOSHIXIANGQIAN = "镶嵌宝石",
    SHIYONGFUMOJUANZHOU = "使用附魔卷轴",
    SHIYONGCIXIU = "使用刺绣",
    SHIYONGHUJIAPIAN = "使用护甲片"
}

function hzhuanye.init(config)
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hzhuanye[enumPlayer] = table.clone(config)
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end
            ACHIEVEMENT_DATA[enumPlayer]["专业"] = {}
            ACHIEVEMENT_DATA[enumPlayer]["专业"].categoryUIName = "BtnRootWindow_Category_Category4"
            local categoryData = {}
            for i, v in ipairs(config) do
                local tmpItem = {}
                tmpItem.name = v.name
                tmpItem.art = v.art
                tmpItem.callback = function()
                    -- 打开专业界面
                    if hjapi.DzFrameIsVisible(zhuanyeFrame) == false then
                        turnOnUI("专业")
                        update_zhuanye_UI_to_page(enumPlayer, v.name, 1)
                    else
                        turnOffUI("专业")
                    end
                end
                tmpItem.tip = hzhuanye.getDescription(v)
                tmpItem.enable = false
                table.insert(categoryData, tmpItem)
            end
            ACHIEVEMENT_DATA[enumPlayer]["专业"].categoryData = categoryData
        end
    )
    hzhuanye.setup_zhuanye_jineng()
    hzhuanye.setup_zhuanye_zhizao()
    hzhuanye.caijiDescription = {}
    hzhuanye.refreshTime = {}
    hzhuanye.maxCaijiCount = {}
end

function hzhuanye.getDescription(zhuanye)
    local msg = {}
    table.insert(
        msg,
        ZHUANYE_LEVEL_TO_LABEL[zhuanye.currentLevel] ..
        hcolor.yellow(zhuanye.name) ..
        " (经验" .. tostring(zhuanye.currentExp) .. "/100) " .. hcolor.yellow("(点击打开专业界面)")
    )
    table.insert(msg, "")
    table.insert(msg, zhuanye.description)
    table.insert(msg, "")
    table.insert(msg, "增加属性(非叠加)：")
    for i = math.max(zhuanye.currentLevel, 1), #(zhuanye.attributeLevel), 1 do
        local color = hcolor.grey
        if zhuanye.currentLevel >= i then
            color = hcolor.green
        end
        table.insert(msg, color(ZHUANYE_LEVEL_TO_LABEL[i] .. " " .. description.attribute(zhuanye.attributeLevel[i])))
    end
    table.insert(msg, "")
    table.insert(msg, "专业等级存档不同职业" .. hcolor.yellow("共享"))
    return string.implode("|n", msg)
end

function hzhuanye.cundangLevel(zhuanye, whichPlayer)
    local currentLevel = zhuanye.currentLevel
    local levelStr = tostring(currentLevel)
    if string.len(levelStr) == 0 or string.len(levelStr) > 1 then
        levelStr = "0"
    end
    hplayer.dzCunDang[whichPlayer].saveCundang(
        zhuanye.cundangStr,
        zhuanye.isPerHero,
        zhuanye.lvlCunDangStartIndex,
        zhuanye.lvlCunDangEndIndex,
        levelStr
    )
end

function hzhuanye.cundangExp(zhuanye, whichPlayer)
    local currentExp = zhuanye.currentExp
    local expStr = tostring(currentExp)
    if string.len(expStr) == 0 or string.len(expStr) > 2 then
        expStr = "00"
    elseif string.len(expStr) == 1 then
        expStr = "0" .. expStr
    end
    hplayer.dzCunDang[whichPlayer].saveCundang(
        zhuanye.cundangStr,
        zhuanye.isPerHero,
        zhuanye.expCunDangStartIndex,
        zhuanye.expCunDangEndIndex,
        expStr
    )
end

function hzhuanye.zengjiaExp(zhuanyeName, whichPlayer, cundang, expVal)
    if expVal <= 0 then
        return
    end
    for i, zhuanye in ipairs(hzhuanye[whichPlayer]) do
        if zhuanye.name == zhuanyeName then
            if zhuanye.maxLevel == nil then
                zhuanye.maxLevel = 999
            end
            if zhuanye.currentLevel < zhuanye.maxLevel then
                if zhuanye.currentExp + expVal >= 100 then
                    zhuanye.currentExp = 0
                    zhuanye.currentLevel = zhuanye.currentLevel + 1
                    hbuff.addAttribute(
                        CONST_DAMAGE_SRC.skill,
                        hplayer.getMainHero(whichPlayer),
                        zhuanyeName .. "加成",
                        zhuanye.attributeLevel[zhuanye.currentLevel],
                        0
                    )
                    ui_enable_achievement_data_at_category_and_idx(whichPlayer, "专业", i)
                    ui_update_text_achievement_data_at_category_and_idx(
                        whichPlayer,
                        "专业",
                        i,
                        hzhuanye.getDescription(zhuanye)
                    )
                    if cundang == true then
                        echo("获得" .. tostring(expVal) .. "点" .. zhuanyeName .. "经验, 专业技能获得升级！当前经验：0", whichPlayer)
                        hzhuanye.cundangLevel(zhuanye, whichPlayer)
                        hzhuanye.cundangExp(zhuanye, whichPlayer)
                    end
                else
                    zhuanye.currentExp = zhuanye.currentExp + expVal
                    ui_enable_achievement_data_at_category_and_idx(whichPlayer, "专业", i)
                    ui_update_text_achievement_data_at_category_and_idx(
                        whichPlayer,
                        "专业",
                        i,
                        hzhuanye.getDescription(zhuanye)
                    )
                    if cundang == true then
                        hzhuanye.cundangExp(zhuanye, whichPlayer)
                        echo(
                            "获得" ..
                            tostring(expVal) ..
                            "点" .. zhuanyeName .. "经验。当前经验：" .. tostring(zhuanye.currentExp) .. "/100",
                            whichPlayer
                        )
                    end
                end
            end
        end
    end
end

function hzhuanye.loadcundang(whichPlayer)
    for i, zhuanye in ipairs(hzhuanye[whichPlayer]) do
        local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(zhuanye.cundangStr, zhuanye.isPerHero)
        local currentLevel =
            math.floor(tonumber(string.sub(cundang, zhuanye.lvlCunDangStartIndex, zhuanye.lvlCunDangEndIndex)) or 0)
        if currentLevel > zhuanye.maxLevel then
            currentLevel = zhuanye.maxLevel
        end
        local currentExp =
            math.floor(tonumber(string.sub(cundang, zhuanye.expCunDangStartIndex, zhuanye.expCunDangEndIndex)) or 0)
        for j = 1, math.min(currentLevel, zhuanye.maxLevel), 1 do
            hzhuanye.zengjiaExp(zhuanye.name, whichPlayer, false, 100)
        end
        hzhuanye.zengjiaExp(zhuanye.name, whichPlayer, false, currentExp)
    end
end

---
---{
---  { name = "基础草药",
---    data = {
---     output = {
---      {
---        name = "银叶草",
---        count = 1,
---        rate = 10000
---      },
---      {
---        name = "金银草",
---        count = 1,
---        rate = 1000
---      }
---    },
---    requiredLevel = 0
---    requiredZhuanye = “采药”
---    caijishijian = 10，
---    event = CONST_EVENT.caiyao
---   }
---  }
---}
function hzhuanye.setup_zhuanye_jineng()
    hevent.reaction(
        CONST_EVENT.skillEffect,
        "zhuanye_caiji_trigger",
        function(evtData)
            if evtData.targetUnit == nil or evtData.targetUnit == nil or evtData.triggerSkill ~= hslk.n2i("采集资源") then
                return
            end
            htime.setTimeout(1, cj.IssueTargetOrder(evtData.triggerUnit, hslk.n2v("采集", "DataF"), evtData.targetUnit))
        end
    )

    hevent.reaction(
        CONST_EVENT.skillEffect,
        "zhuanye_caiji",
        function(evtData)
            if evtData.targetUnit == nil or evtData.triggerSkill ~= hslk.n2i("采集") then
                return
            end
            local hero = evtData.triggerUnit
            local whichPlayer = hunit.getOwner(hero)
            if hero ~= hplayer.getMainHero(whichPlayer) then
                return
            end
            local targetName = hunit.getName(evtData.targetUnit)
            local caijiData = hzhuanye.zhuanye_caiji_config[targetName]
            if caijiData == nil then
                echo("当前目标无法采集", whichPlayer)
                cj.IssueImmediateOrder(evtData.triggerUnit, "stop")
                return
            end
            local caijiLevel = hzhuanye.getZhuanyeLevel(caijiData.requiredZhuanye, whichPlayer)
            local requiredLevel = caijiData.requiredLevel
            if caijiLevel < requiredLevel then
                echo(
                    "当前" ..
                    caijiData.requiredZhuanye ..
                    "等级不够，当前" ..
                    ZHUANYE_LEVEL_TO_LABEL[caijiLevel] ..
                    "，需要" .. ZHUANYE_LEVEL_TO_LABEL[requiredLevel] .. "。",
                    whichPlayer
                )
                cj.IssueImmediateOrder(evtData.triggerUnit, "stop")
                return
            end
            local caijishijian = caijiData.caijishijian

            local caijijiasu = hattribute.getWithLimit(evtData.triggerUnit, nil, "caiji_speed", 0)
            caijishijian = math.round(caijishijian / (1 + caijijiasu / 100), 2)
            if hplayer.loc() == hunit.getOwner(hero) then
                ui_set_shifatiaovalue(caijiData.requiredZhuanye, 0, caijishijian)
            end
            local i = 1
            hcache.set(
                evtData.triggerUnit,
                "zhuanye_caiji_timer",
                htime.setInterval(
                    0.01,
                    function(curTimer)
                        if hplayer.loc() == hunit.getOwner(hero) then
                            ui_set_shifatiaovalue(caijiData.requiredZhuanye, i * 0.01, caijishijian)
                        end
                        i = i + 1
                        if i >= (caijishijian * 100) then
                            curTimer.destroy()
                        end
                    end
                )
            )
            hcache.set(evtData.triggerUnit, "zdjn_finish_sh_" .. evtData.triggerSkill, false)
            hcache.set(evtData.triggerUnit, CONST_CACHE.SKILL_EFFECT .. evtData.triggerSkill, evtData)
            hcache.set(
                evtData.triggerUnit,
                "zdjn_sfsj_timer_" .. evtData.triggerSkill,
                htime.setTimeout(
                    caijishijian,
                    function(_)
                        hcache.free(evtData.triggerUnit, "zdjn_sfsj_timer_" .. evtData.triggerSkill)
                        hcache.set(evtData.triggerUnit, "zdjn_finish_sh_" .. evtData.triggerSkill, true)
                        cj.IssueImmediateOrder(evtData.triggerUnit, "stop")
                    end
                )
            )
        end
    )

    hevent.reaction(
        CONST_EVENT.skillStop,
        "zhuanye_caiji",
        function(evtData)
            if evtData.triggerSkill ~= hslk.n2i("采集") then
                return
            end
            local triggerData = hcache.get(evtData.triggerUnit, CONST_CACHE.SKILL_EFFECT .. evtData.triggerSkill)
            if (triggerData == nil or triggerData.targetUnit == nil) then
                return
            end
            hcache.free(evtData.triggerUnit, CONST_CACHE.SKILL_EFFECT .. evtData.triggerSkill)
            if
                hcache.get(evtData.triggerUnit, "zdjn_finish_sh_" .. evtData.triggerSkill, nil) == true and
                hunit.isDestroyed(triggerData.targetUnit) == false
            then
                local ziyuan_count = hcache.get(triggerData.targetUnit, "ziyuan_count")
                if ziyuan_count[hunit.getOwner(evtData.triggerUnit)] > 0 then
                    local targetName = hunit.getName(triggerData.targetUnit)
                    local caijiData = hzhuanye.zhuanye_caiji_config[targetName]
                    local whichPlayer = hunit.getOwner(evtData.triggerUnit)
                    for ii, vv in ipairs(caijiData.output) do
                        local rate = vv.rate
                        if caijiData.requiredZhuanye == "钓鱼" then
                            rate =
                                rate * (1 + hattribute.getWithLimit(evtData.triggerUnit, nil, "diaoyu_rate", 0) / 100)
                        elseif caijiData.requiredZhuanye == "采药" then
                            rate =
                                rate * (1 + hattribute.getWithLimit(evtData.triggerUnit, nil, "caiyao_rate", 0) / 100)
                        elseif caijiData.requiredZhuanye == "采矿" then
                            rate =
                                rate * (1 + hattribute.getWithLimit(evtData.triggerUnit, nil, "caikuang_rate", 0) / 100)
                        end
                        if math.random(1, 10000) <= rate then
                            if vv.outputType == nil then
                                local id = hslk.n2i(vv.name)
                                if id == nil then
                                    err("不存在" .. vv.name)
                                    return
                                end
                                local dynamicItem = DynamicItem(id)
                                local pinzhi = hitem.getItemMinPinzhi(id)
                                dynamicItem.initBasedOnPinzhi(pinzhi, 1)
                                dynamicItem.setStack(vv.count)
                                dynamicItem.setOwner(whichPlayer)
                                if hplayer.dzCunDang[whichPlayer].saveItemInInventory(dynamicItem) == false then
                                    hitem.create(
                                        {
                                            id = id,
                                            whichUnit = triggerData.triggerUnit,
                                            dynamicItem = dynamicItem,
                                            charges = vv.count
                                        }
                                    )
                                end
                                local newTriggerData = {
                                    triggerUnit = triggerData.triggerUnit,
                                    NPC = triggerData.targetUnit,
                                    triggerName = vv.name
                                }
                                hevent.trigger(triggerData.triggerUnit, caijiData.event, newTriggerData)
                            elseif vv.outputType == "diaoyutujian" then
                                hdiaoyu.shouhuo(whichPlayer, vv)
                            end
                        end
                    end
                    ziyuan_count[hunit.getOwner(evtData.triggerUnit)] =
                        ziyuan_count[hunit.getOwner(evtData.triggerUnit)] - 1
                    local whichPlayer = hunit.getOwner(triggerData.triggerUnit)
                    local caijiLevel = hzhuanye.getZhuanyeLevel(caijiData.requiredZhuanye, whichPlayer)
                    local requiredLevel = caijiData.requiredLevel
                    if caijiLevel == requiredLevel then
                        hzhuanye.zengjiaExp(caijiData.requiredZhuanye, whichPlayer, true, 1)
                    end
                    local newTriggerData = {
                        triggerUnit = triggerData.triggerUnit,
                        NPC = triggerData.targetUnit
                    }
                    hevent.trigger(triggerData.triggerUnit, caijiData.event, newTriggerData)
                    if caijiData.destroyTarget == true then
                        hunit.kill(triggerData.targetUnit)
                    end
                end
                htime.setTimeout(
                    1,
                    function(_)
                        cj.IssueTargetOrder(triggerData.triggerUnit, hslk.n2v("采集", "DataF"), triggerData.targetUnit)
                    end
                )
            end
            local timer = hcache.get(evtData.triggerUnit, "zdjn_sfsj_timer_" .. evtData.triggerSkill)
            if timer ~= nil then
                timer.destroy()
            end
            -- 取消读条UI
            if hplayer.loc() == hunit.getOwner(evtData.triggerUnit) then
                ui_clear_shifatiao()
            end
            local shifatiaoTimer = hcache.get(evtData.triggerUnit, "zhuanye_caiji_timer", nil)
            if shifatiaoTimer ~= nil then
                shifatiaoTimer.destroy()
            end
            hcache.free(evtData.triggerUnit, "zhuanye_caiji_timer")
            hcache.free(evtData.triggerUnit, "zdjn_sfsj_timer_" .. evtData.triggerSkill)
        end
    )
end

function hzhuanye.setup_zhuanye_zhizao()
    hevent.reaction(
        CONST_EVENT.skillEffect,
        "zhuanye_zhizao",
        function(evtData)
            if evtData.targetUnit == nil or evtData.triggerSkill ~= hslk.n2i("制作") then
                return
            end
            local hero = evtData.triggerUnit
            local whichPlayer = hunit.getOwner(hero)
            if hero ~= hplayer.getMainHero(whichPlayer) then
                return
            end
            local zhuanyeData = hcache.get(evtData.triggerUnit, "zhuanye_zhizuo_data", nil)
            if zhuanyeData == nil then
                echo("制作物品错误", whichPlayer)
                cj.IssueImmediateOrder(evtData.triggerUnit, "stop")
                return
            end
            evtData.zhuanyeData = zhuanyeData
            local zhizuoData = zhuanyeData.zhizuoData
            local zhizuoName = zhuanyeData.zhizuoName
            local zhuanyeName = zhuanyeData.zhuanyeName
            local requiredNearByNPCName = zhuanyeData.requiredNearByNPCName
            local trggerEvent = zhuanyeData.trggerEvent
            local zhizuoshijian = zhizuoData.zhizuoshijian
            zhizuoshijian = zhizuoshijian or zhuanyeData.caijishijian
            zhizuoshijian = zhizuoshijian or 2

            if zhizuoData == nil or zhizuoName == nil then
                echo(zhizuoName .. "失败", whichPlayer)
                cj.IssueImmediateOrder(evtData.triggerUnit, "stop")
                return
            end
            local level = hzhuanye.getZhuanyeLevel(zhuanyeName, whichPlayer)
            if level < zhizuoData.reqLevel then
                echo(
                    zhuanyeName ..
                    "等级不足，需要" ..
                    ZHUANYE_LEVEL_TO_LABEL[zhizuoData.reqLevel] ..
                    ", 当前" .. ZHUANYE_LEVEL_TO_LABEL[level] .. "。",
                    whichPlayer
                )
                cj.IssueImmediateOrder(evtData.triggerUnit, "stop")
                return
            end
            local hero = hplayer.getMainHero(whichPlayer)
            if hero == nil then
                echo("需要选择英雄后才能" .. zhizuoName, whichPlayer)
                cj.IssueImmediateOrder(evtData.triggerUnit, "stop")
                return
            end
            if
                requiredNearByNPCName ~= nil and
                hgroup.isEmpty(
                    hgroup.createByUnit(
                        hero,
                        300,
                        function(filterUnit)
                            if hunit.getName(filterUnit) == requiredNearByNPCName then
                                return true
                            else
                                return false
                            end
                        end
                    )
                )
            then
                echo(zhizuoName .. "需要在" .. requiredNearByNPCName .. "附近。", whichPlayer)
                cj.IssueImmediateOrder(evtData.triggerUnit, "stop")
                return
            end
            if hitem.hasRequiredItems(zhizuoData.req, hero, true) == false then
                cj.IssueImmediateOrder(evtData.triggerUnit, "stop")
                return
            end

            if hplayer.loc() == hunit.getOwner(hero) then
                ui_set_shifatiaovalue(zhizuoName, 0, zhizuoshijian)
            end
            local i = 1
            hcache.set(
                evtData.triggerUnit,
                "zhuanye_zhizao_timer",
                htime.setInterval(
                    0.01,
                    function(curTimer)
                        if hplayer.loc() == hunit.getOwner(hero) then
                            ui_set_shifatiaovalue(zhizuoName, i * 0.01, zhizuoshijian)
                        end
                        i = i + 1
                        if i >= (zhizuoshijian * 100) then
                            curTimer.destroy()
                        end
                    end
                )
            )
            hcache.set(evtData.triggerUnit, "zdjn_finish_sh_" .. evtData.triggerSkill, false)
            hcache.set(evtData.triggerUnit, CONST_CACHE.SKILL_EFFECT .. evtData.triggerSkill, evtData)
            hcache.set(
                evtData.triggerUnit,
                "zdjn_sfsj_timer_" .. evtData.triggerSkill,
                htime.setTimeout(
                    zhizuoshijian,
                    function(_)
                        hcache.free(evtData.triggerUnit, "zdjn_sfsj_timer_" .. evtData.triggerSkill)
                        hcache.set(evtData.triggerUnit, "zdjn_finish_sh_" .. evtData.triggerSkill, true)
                        cj.IssueImmediateOrder(evtData.triggerUnit, "stop")
                    end
                )
            )
        end
    )

    hevent.reaction(
        CONST_EVENT.skillStop,
        "zhuanye_zhizao",
        function(evtData)
            if evtData.triggerSkill ~= hslk.n2i("制作") then
                return
            end
            local triggerData = hcache.get(evtData.triggerUnit, CONST_CACHE.SKILL_EFFECT .. evtData.triggerSkill)
            if (triggerData == nil or triggerData.targetUnit == nil) then
                return
            end
            hcache.free(evtData.triggerUnit, CONST_CACHE.SKILL_EFFECT .. evtData.triggerSkill)
            if
                hcache.get(evtData.triggerUnit, "zdjn_finish_sh_" .. evtData.triggerSkill, nil) == true and
                hunit.isDestroyed(triggerData.targetUnit) == false
            then
                local whichPlayer = triggerData.zhuanyeData.whichPlayer
                local zhizuoData = triggerData.zhuanyeData.zhizuoData
                local zhizuoName = triggerData.zhuanyeData.zhizuoName
                local zhuanyeName = triggerData.zhuanyeData.zhuanyeName
                local requiredNearByNPCName = triggerData.zhuanyeData.requiredNearByNPCName
                local trggerEvent = triggerData.zhuanyeData.trggerEvent
                hzhuanye.zhizuo(whichPlayer, zhizuoData, zhizuoName, zhuanyeName, requiredNearByNPCName, trggerEvent)
                if hcache.get(whichPlayer, "lianxuzhizao") then
                    htime.setTimeout(
                        1,
                        function(_)
                            local hero = hplayer.getMainHero(whichPlayer)
                            cj.IssueImmediateOrder(hero, CONST_ABILITY_ORDER[8])
                        end
                    )
                end
            end
            local timer = hcache.get(evtData.triggerUnit, "zdjn_sfsj_timer_" .. evtData.triggerSkill)
            if timer ~= nil then
                timer.destroy()
            end
            -- 取消读条UI
            if hplayer.loc() == hunit.getOwner(evtData.triggerUnit) then
                ui_clear_shifatiao()
            end
            local shifatiaoTimer = hcache.get(evtData.triggerUnit, "zhuanye_zhizao_timer", nil)
            if shifatiaoTimer ~= nil then
                shifatiaoTimer.destroy()
            end
            hcache.free(evtData.triggerUnit, "zhuanye_zhizao_timer")
            hcache.free(evtData.triggerUnit, "zdjn_sfsj_timer_" .. evtData.triggerSkill)
        end
    )
end

function hzhuanye.tryZengJiaExp(zhuanyeName, whichPlayer, expVal)
    if hplayer.getMainHero(whichPlayer) == nil or expVal <= 0 then
        return
    end
    for i, zhuanye in ipairs(hzhuanye[whichPlayer]) do
        if zhuanye.name == zhuanyeName then
            local current = zhuanye.currentLevel
            local currentExp = zhuanye.currentExp
            if current >= zhuanye.maxLevel and currentExp > 99 then
                return
            end
            hzhuanye.zengjiaExp(zhuanyeName, whichPlayer, true, expVal)
        end
    end
end

function hzhuanye.getZhuanyeLevel(zhuanyeName, whichPlayer)
    if hplayer.getMainHero(whichPlayer) == nil then
        return 0
    end
    for i, zhuanye in ipairs(hzhuanye[whichPlayer]) do
        if zhuanye.name == zhuanyeName then
            return zhuanye.currentLevel
        end
    end
end

hzhuanye.getSingleZhuanyeDescription = function(zhizuoData, zhizuoName, zhuanyeName)
    local msg = {}

    local outputPool = zhizuoData.outputPool or { zhizuoData.output }
    local firstItem = outputPool[1]
    local nanduStr = ""
    if firstItem.nandu ~= nil and firstItem.nandu ~= FUBEN_NANDU.PUTONG then
        nanduStr = "（" .. FUBEN_NANDU_LABEL_WO_COLOR[firstItem.nandu] .. "）"
    end
    local pinzhi = firstItem.itemPinzhi or hitem.getItemMinPinzhi(hslk.n2i(firstItem.name))

    table.insert(
        msg,
        hcolor.yellow(zhizuoName) ..
        "：" ..
        zhizuoName ..
        "：" ..
        ZHUANGBEI_PINZHI_DATA[pinzhi].color(firstItem.name .. nanduStr) ..
        "(需要" .. ZHUANYE_LEVEL_TO_LABEL[zhizuoData.reqLevel] .. zhuanyeName .. ")"
    )
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("需要材料:"))
    for i, singleReq in ipairs(zhizuoData.req) do
        local pinzhi = hitem.getItemMinPinzhi(hslk.n2i(singleReq.name))
        pinzhi = pinzhi or ZHUANGBEI_PINZHI.PUTONG
        local chuchu = hitem.queryItemSource(singleReq.name) or "其它"
        table.insert(msg,
            " - " ..
            hitem.getDescriptionForSingleRequiredItem(singleReq) .. " X " .. singleReq.count .. " (" .. chuchu .. ")")
    end
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("成功率:") .. tostring(zhizuoData.successRate / 100) .. "%")
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("制作成功获得经验：") .. hcolor.green(tostring(zhizuoData.zhizuoExp or 1) .. "点"))
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("可能获得："))

    if #outputPool < 10 then
        local totalWeight = 0
        for _, item in ipairs(outputPool) do
            totalWeight = totalWeight + (item.weight or 1)
        end

        for _, item in ipairs(outputPool) do
            local pinzhi = item.itemPinzhi or hitem.getItemMinPinzhi(hslk.n2i(item.name))
            local nanduStr = ""
            if item.nandu ~= nil and item.nandu ~= FUBEN_NANDU.PUTONG then
                nanduStr = "（" .. FUBEN_NANDU_LABEL_WO_COLOR[item.nandu] .. "）"
            end
            local probability = ((item.weight or 1) / totalWeight) * 100
            table.insert(
                msg,
                " - " .. ZHUANGBEI_PINZHI_DATA[pinzhi].color(item.name .. nanduStr) ..
                " X " .. item.count ..
                " (" .. string.format("%.2f", probability) .. "%)"
            )

            if item.upgradeRate then
                table.insert(msg, "   （有" .. tostring(item.upgradeRate / 100) .. "%的概率品质提升一级）")
            end
        end
    else
        local itemNames = {}
        for _, item in ipairs(outputPool) do
            local pinzhi = item.itemPinzhi or hitem.getItemMinPinzhi(hslk.n2i(item.name))
            local nanduStr = ""
            if item.nandu ~= nil and item.nandu ~= FUBEN_NANDU.PUTONG then
                nanduStr = "（" .. FUBEN_NANDU_LABEL_WO_COLOR[item.nandu] .. "）"
            end
            table.insert(itemNames, ZHUANGBEI_PINZHI_DATA[pinzhi].color(item.name .. nanduStr))
        end

        local itemListStr = table.concat(itemNames, "，")
        table.insert(msg, itemListStr)

        if firstItem.upgradeRate then
            table.insert(msg, "（有" .. tostring(firstItem.upgradeRate / 100) .. "%的概率品质提升一级）")
        end
    end

    table.insert(msg, "")
    local tmpItem = DynamicItem(hslk.n2i(firstItem.name))
    tmpItem.initBasedOnPinzhi(pinzhi, firstItem.itemLevel or 1, nil,
        firstItem.nandu or FUBEN_NANDU.PUTONG)
    local description = tmpItem.getDescription()
    table.insert(msg, description)

    return string.implode("|n", msg)
end

hzhuanye.zhizuo = function(whichPlayer, zhizuoData, zhizuoName, zhuanyeName, requiredNearByNPCName, trggerEvent)
    if zhizuoData == nil or zhizuoName == nil then
        dump(zhizuoName .. "失败")
        return
    end
    local level = hzhuanye.getZhuanyeLevel(zhuanyeName, whichPlayer)
    if level < zhizuoData.reqLevel then
        echo(
            zhuanyeName ..
            "等级不足，需要" ..
            ZHUANYE_LEVEL_TO_LABEL[zhizuoData.reqLevel] .. ", 当前" .. ZHUANYE_LEVEL_TO_LABEL[level] .. "。",
            whichPlayer
        )
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        echo("需要选择英雄后才能" .. zhizuoName, whichPlayer)
        return
    end
    if
        requiredNearByNPCName ~= nil and
        hgroup.isEmpty(
            hgroup.createByUnit(
                hero,
                300,
                function(filterUnit)
                    if hunit.getName(filterUnit) == requiredNearByNPCName then
                        return true
                    else
                        return false
                    end
                end
            )
        )
    then
        echo(zhizuoName .. "需要在" .. requiredNearByNPCName .. "附近。", whichPlayer)
        return
    end
    if hitem.hasRequiredItems(zhizuoData.req, hero, true) == false then
        return
    end
    hitem.removeItemFromBag(zhizuoData.req, hero)
    if math.random(1, 10000) <= zhizuoData.successRate then
        local outputPool = zhizuoData.outputPool or { zhizuoData.output }
        local totalWeight = 0
        for _, item in ipairs(outputPool) do
            totalWeight = totalWeight + (item.weight or 1)
        end

        local randomWeight = math.random(1, totalWeight)
        local selectedOutput = nil
        for _, item in ipairs(outputPool) do
            randomWeight = randomWeight - (item.weight or 1)
            if randomWeight <= 0 then
                selectedOutput = item
                break
            end
        end

        if selectedOutput then
            local id = hslk.n2i(selectedOutput.name)
            local pinzhi = selectedOutput.itemPinzhi or hitem.getItemMinPinzhi(id)
            local itemLevel = selectedOutput.itemLevel or 1
            if hslk.i2v(id, "hitem_type") == "装备" then
                if selectedOutput.upgradeRate ~= nil and math.random(1, 10000) <= selectedOutput.upgradeRate then
                    pinzhi = pinzhi + 1
                    echo("灵光一闪，本次" .. zhizuoName .. "品质提高！", whichPlayer)
                end
                local dynamicItem = DynamicItem(id)
                local nandu = selectedOutput.nandu
                dynamicItem.setOwner(whichPlayer)
                dynamicItem.initBasedOnPinzhi(pinzhi, itemLevel, nil, nandu, { hero })
                if hplayer.dzCunDang[whichPlayer].saveItemInInventory(dynamicItem) == false then
                    hitem.create({ id = id, whichUnit = hero, dynamicItem = dynamicItem })
                end
            else
                local dynamicItem = DynamicItem(id)
                dynamicItem.setOwner(whichPlayer)
                dynamicItem.initBasedOnPinzhi(pinzhi, itemLevel)
                dynamicItem.setStack(selectedOutput.count)
                if hplayer.dzCunDang[whichPlayer].saveItemInInventory(dynamicItem) == false then
                    hitem.create({ id = id, whichUnit = hero, dynamicItem = dynamicItem, charges = selectedOutput.count })
                end
            end
            echo(zhizuoName .. selectedOutput.name .. "成功！", whichPlayer)
            hevent.trigger(hero, trggerEvent, { triggerUnit = hero, triggerName = selectedOutput.name })
        else
            echo(zhizuoName .. "失败，未能选择输出物品！", whichPlayer)
        end
    else
        echo(zhizuoName .. "失败！", whichPlayer)
    end
    if level <= zhizuoData.reqLevel then
        local zhizuoExp = zhizuoData.zhizuoExp or 1
        hzhuanye.zengjiaExp(zhuanyeName, whichPlayer, true, zhizuoExp)
    end
end

hzhuanye.initSingleZhuanye = function(
    config,
    zhizuoName,
    zhuanyeName,
    zhuanyeEvent,
    requiredNearByNPCName,
    caijiconfig,
    shaguaiConfig,
    qianghuawupintype,
    qianghuawupinConfig)
    if qianghuawupinConfig ~= nil then
        for i, v in ipairs(qianghuawupinConfig) do
            if v.name == nil then
                err("empty name for qianghuawupinConfig")
                dump(v)
            end
            if v.itemCunDangStr == nil then
                err("empty itemCunDangStr for qianghuawupinConfig")
                dump(v)
            end
            if hzhuanye.qianghuawupinConfig[v.name] ~= nil then
                err("重复的强化物品name")
                dump(v)
            end
            hzhuanye.qianghuawupinConfig[v.name] = v

            local zhuanyeNameCDStr = zhuanyeName .. v.itemCunDangStr
            if hzhuanye.zhuanyeNameCDStrToQianghuawupinName[zhuanyeNameCDStr] ~= nil then
                err("重复的zhuanyeNameCDStr")
                dump(v)
            end
            hzhuanye.zhuanyeNameCDStrToQianghuawupinName[zhuanyeNameCDStr] = v.name
        end
    end
    if caijiconfig ~= nil then
        for _, item in ipairs(caijiconfig) do
            local caijiData = item.data
            local str = {}
            table.insert(str, hcolor.green("可以" .. caijiData.requiredZhuanye))
            table.insert(str, "- 需要" .. ZHUANYE_LEVEL_TO_LABEL[caijiData.requiredLevel] .. caijiData.requiredZhuanye)
            table.insert(str, "- 收获时间" .. hcolor.green(tostring(caijiData.caijishijian)) .. "秒")
            if caijiData.refreshTime ~= nil then
                table.insert(str, "- 资源重生时间" .. hcolor.green(tostring(caijiData.refreshTime)) .. "秒")
                hzhuanye.refreshTime[item.name] = caijiData.refreshTime
            end
            if caijiData.maxCaijiCount ~= nil then
                table.insert(str, "- 最大资源堆叠" .. hcolor.green(tostring(caijiData.maxCaijiCount)) .. "次")
                hzhuanye.maxCaijiCount[item.name] = caijiData.maxCaijiCount
            end
            table.insert(str, "产出：")
            for i = 1, math.min(8, #(caijiData.output)) do
                table.insert(
                    str,
                    "- " ..
                    hitem.getColoredNameBasedOnPinzhi(caijiData.output[i].name) ..
                    " (" .. string.format("%.2f%%", caijiData.output[i].rate / 100) .. ")"
                )
            end
            for _, singleOutput in ipairs(caijiData.output) do
                hitem.registerItemSource(singleOutput.name, "采集" .. item.name)
            end
            if #(caijiData.output) > 8 then
                table.insert(str, "- 更多收获已省略")
            end
            table.insert(str, "注：资源堆叠对每个玩家独立计算，不同玩家可以各自采集，不会互相影响。")
            hzhuanye.caijiDescription[item.name] = string.implode("|n", str)
        end
    end
    if config ~= nil then
        table.insert(ZHUANYE_NEED_UPDATE_ITEM_SOURCE, { zhuanyeName, zhizuoName })
        hplayer.forEach(
            function(enumPlayer, _)
                if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                    return
                end
                if ZHUANYE_DATA[enumPlayer] == nil then
                    ZHUANYE_DATA[enumPlayer] = {}
                end
                ZHUANYE_DATA[enumPlayer][zhuanyeName] = {}
                local zhuanyeData = {}
                for i, v in ipairs(config) do
                    local tmpItem = {}

                    local nanduStr = ""
                    local outputPool = v.outputPool or { v.output }
                    local firstItem = outputPool[1]
                    if firstItem ~= nil and firstItem.nandu ~= nil and firstItem.nandu ~= FUBEN_NANDU.PUTONG then
                        nanduStr = "（" .. FUBEN_NANDU_LABEL_WO_COLOR[firstItem.nandu] .. "）"
                    end
                    local pinzhi = firstItem.pinzhi or hitem.getItemMinPinzhi(hslk.n2i(firstItem.name))
                    tmpItem.name = zhizuoName .. "：" .. ZHUANGBEI_PINZHI_DATA[pinzhi].color(firstItem.name .. nanduStr)

                    tmpItem.art = hslk.n2v(firstItem.name, "Art")
                    tmpItem.rawConfig = v
                    tmpItem.callback = function()
                        hsync.send(zhuanyeName .. zhizuoName, { i })
                    end
                    tmpItem.tip = "装载中..."
                    tmpItem.enable = true
                    table.insert(zhuanyeData, tmpItem)
                    if v.output ~= nil then
                        hitem.registerItemSource(v.output.name, zhuanyeName .. zhizuoName)
                    end
                    if v.outputPool ~= nil then
                        for _, vv in ipairs(v.outputPool) do
                            hitem.registerItemSource(vv.name, zhuanyeName .. zhizuoName)
                        end
                    end
                end
                ZHUANYE_DATA[enumPlayer][zhuanyeName].categoryData = zhuanyeData
            end
        )

        hsync.onSend(
            zhuanyeName .. zhizuoName,
            function(syncData)
                local hero = hplayer.getMainHero(syncData.triggerPlayer)
                if hero == nil then
                    echo("英雄还没选择", syncData.triggerPlayer)
                    return
                end
                hcache.set(
                    hero,
                    "zhuanye_zhizuo_data",
                    {
                        whichPlayer = syncData.triggerPlayer,
                        zhizuoData = config[tonumber(syncData.triggerData[1])],
                        zhizuoName = zhizuoName,
                        zhuanyeName = zhuanyeName,
                        requiredNearByNPCName = requiredNearByNPCName,
                        trggerEvent = zhuanyeEvent
                    }
                )
                cj.IssueImmediateOrder(hero, CONST_ABILITY_ORDER[8])
            end
        )
    end
    if caijiconfig ~= nil then
        for _, v in ipairs(caijiconfig) do
            if v.name == nil then
                err("empty zhuanye caiji name")
            end
            if v.data == nil then
                err("empty zhuanye caiji data")
            end
            if hzhuanye.zhuanye_caiji_config == nil then
                hzhuanye.zhuanye_caiji_config = {}
            end
            if hzhuanye.zhuanye_caiji_config[v.name] ~= nil then
                err("duplicate zhuanye caiji name： " .. v.name)
            end
            hzhuanye.zhuanye_caiji_config[v.name] = v.data
        end
    end

    if shaguaiConfig ~= nil then
        hzhuanye.shaguaiConfig[zhuanyeName] = shaguaiConfig
        if type(shaguaiConfig) ~= "table" then
            err("错误的shaguaiConfig")
        end
        for i, v in ipairs(shaguaiConfig) do
            for ii, vv in ipairs(v.output) do
                hitem.registerItemSource(vv.name, zhuanyeName .. "杀怪")
            end
        end
        hevent.reaction(
            CONST_EVENT.kill,
            "zhuanyeshaguai" .. zhuanyeName,
            function(evtData)
                local killer = evtData.triggerUnit
                local killedUnit = evtData.targetUnit

                local group = hgroup.createAllyGroupByUnit(killedUnit, 1500)
                local units =
                    hgroup.createByXY(
                        hunit.x(killedUnit),
                        hunit.y(killedUnit),
                        1500,
                        function(filterUnit)
                            local owner = hunit.getOwner(filterUnit)
                            if
                                hunit.isAlive(filterUnit) and hplayer.isUser(owner) and hplayer.isPlaying(owner) and
                                hplayer.getMainHero(owner) == filterUnit
                            then
                                return true
                            else
                                return false
                            end
                        end
                    )
                if #units == 0 then
                    return
                end

                local whichUnit = table.random(units, 1)

                local whichPlayer = hunit.getOwner(whichUnit)
                local kebaopi = hslk.n2v(hunit.getName(killedUnit), "_canBOPI")
                local kezhibu = hslk.n2v(hunit.getName(killedUnit), "_canZHIBU")
                local level = hunit.getLevel(killedUnit)
                local name = hunit.getName(killedUnit)
                for i, v in ipairs(shaguaiConfig) do
                    if
                        (v.minUnitLevel == nil or v.minUnitLevel <= level) and
                        (v.maxUnitLevel == nil or v.maxUnitLevel >= level) and
                        (v.kebaopi == nil or kebaopi == true) and
                        (v.kezhibu == nil or kezhibu == true) and
                        (v.unitName == nil or v.unitName == name)
                    then
                        for ii, vv in ipairs(v.output) do
                            local rate = vv.rate
                            if zhuanyeName == "剥皮" then
                                rate =
                                    rate *
                                    (1 + hattribute.getWithLimit(evtData.triggerUnit, nil, "baopi_rate", 0) / 100)
                            elseif zhuanyeName == "制布" then
                                rate =
                                    rate *
                                    (1 + hattribute.getWithLimit(evtData.triggerUnit, nil, "zhibu_rate", 0) / 100)
                            end
                            if math.random(1, 10000) <= rate then
                                if vv.outputType == nil then
                                    local id = hslk.n2i(vv.name)
                                    if id == nil then
                                        err("不存在" .. vv.name)
                                        return
                                    end
                                    local dynamicItem = DynamicItem(id)
                                    local pinzhi = hitem.getItemMinPinzhi(id)
                                    dynamicItem.initBasedOnPinzhi(pinzhi, 1)
                                    dynamicItem.setStack(vv.count)
                                    dynamicItem.setOwner(whichPlayer)
                                    if hplayer.dzCunDang[whichPlayer].saveItemInInventory(dynamicItem) == false then
                                        hitem.create(
                                            {
                                                id = id,
                                                whichUnit = killer,
                                                dynamicItem = dynamicItem,
                                                charges = vv.count
                                            }
                                        )
                                    end
                                    hevent.trigger(killer, zhuanyeEvent, { triggerUnit = killer, triggerName = vv.name })
                                    hzhuanye.tryZengJiaExp(zhuanyeName, hunit.getOwner(killer), 1)
                                end
                            end
                        end
                    end
                end
            end
        )
    end

    if qianghuawupintype ~= nil then
        hevent.reaction(
            CONST_EVENT.itemUsed,
            "wupinqianghua" .. qianghuawupintype,
            function(evtData)
                if
                    evtData.triggerSkill ~= nil and hskill.getName(evtData.triggerSkill) == qianghuawupintype and
                    evtData.triggerItem ~= nil and
                    evtData.triggerUnit ~= nil and
                    hplayer.getMainHero(hunit.getOwner(evtData.triggerUnit)) == evtData.triggerUnit
                then
                    local qianghuaWupin = evtData.triggerItem
                    local qhwpdynamicItem = hitem.getDynamicItem(qianghuaWupin)
                    if qhwpdynamicItem == nil then
                        hitem.destroy(qianghuaWupin)
                        return
                    end
                    if qhwpdynamicItem.stack < 1 then
                        hitem.destroy(qianghuaWupin)
                        return
                    end
                    local QHWPName = hitem.getName(qianghuaWupin)
                    local whichPlayer = hunit.getOwner(evtData.triggerUnit)
                    local zhuangbeilandiyige = hitem.getItemAtSlot(evtData.triggerUnit, 0)
                    if zhuangbeilandiyige == nil then
                        echo("装备栏第一格为空，" .. qianghuawupintype .. hcolor.yellow("失败"), whichPlayer)
                        hitem.setCharges(qianghuaWupin, hitem.getCharges(qianghuaWupin) + 1)
                        return
                    end
                    if hitem.getHitemType(hitem.getId(zhuangbeilandiyige)) ~= HITEM_TYPE.Zhuangbei then
                        echo("装备栏第一格不是装备，" .. qianghuawupintype .. hcolor.yellow("失败"), whichPlayer)
                        hitem.setCharges(qianghuaWupin, hitem.getCharges(qianghuaWupin) + 1)
                        return
                    end
                    local dynamicItem = hitem.getDynamicItem(zhuangbeilandiyige)
                    if
                        dynamicItem.canUseQHWPForEquipmentType(
                            QHWPName,
                            hslk.i2v(dynamicItem.basic_item_id, "equipment_type")
                        ) ~= true
                    then
                        echo("装备栏第一格装备类型不符合要求，" .. qianghuawupintype .. hcolor.yellow("失败"), whichPlayer)
                        hitem.setCharges(qianghuaWupin, hitem.getCharges(qianghuaWupin) + 1)
                        return
                    end
                    if dynamicItem.canUseQianghuaWupin(qianghuawupintype) ~= true then
                        echo(
                            "装备栏第一格装备不符合强化条件，" ..
                            qianghuawupintype .. hcolor.yellow("失败") .. "。请检查装备是否有插槽（针对宝石），或者已经强化（针对附魔护甲片刺绣）。",
                            whichPlayer
                        )
                        hitem.setCharges(qianghuaWupin, hitem.getCharges(qianghuaWupin) + 1)
                        return
                    end
                    dynamicItem.useQianghuaWupin(qianghuawupintype, QHWPName)
                    echo(qianghuawupintype .. hcolor.green("成功！"), whichPlayer)
                    if qhwpdynamicItem.stack == 1 then
                        hitem.destroy(qianghuaWupin)
                        return
                    end
                    hitem.setCharges(qianghuaWupin, qhwpdynamicItem.stack - 1)
                end
            end
        )
    end
end

hzhuanye.getCaijiDescription = function(name)
    return hzhuanye.caijiDescription[name]
end

hzhuanye.getRefreshTime = function(name)
    return hzhuanye.refreshTime[name]
end

hzhuanye.getMaxCaijiCount = function(name)
    return hzhuanye.maxCaijiCount[name]
end

hzhuanye.getAttrFromQHWP = function(wupinName)
    local qianghuawupinConfig = hzhuanye.qianghuawupinConfig[wupinName]
    if qianghuawupinConfig == nil then
        return nil
    end
    return qianghuawupinConfig.attr
end

hzhuanye.getSkillFromQHWP = function(wupinName)
    local qianghuawupinConfig = hzhuanye.qianghuawupinConfig[wupinName]
    if qianghuawupinConfig == nil then
        return nil
    end
    return qianghuawupinConfig._skillEffect
end

hzhuanye.getCDStrFromQHWP = function(wupinName)
    local qianghuawupinConfig = hzhuanye.qianghuawupinConfig[wupinName]
    if qianghuawupinConfig == nil then
        return nil
    end
    return qianghuawupinConfig.itemCunDangStr
end

hzhuanye.getQHWPNameFromCDStr = function(zhuanyename, CDStr)
    if hzhuanye.zhuanyeNameCDStrToQianghuawupinName[zhuanyename .. CDStr] == nil then
        err("zhuanyename..CDStr not found: " .. zhuanyename .. CDStr)
        return "测试物品"
    end
    return hzhuanye.zhuanyeNameCDStrToQianghuawupinName[zhuanyename .. CDStr]
end

hzhuanye.getQHWPEffectDescription = function(wupinName)
    local qianghuawupinConfig = hzhuanye.qianghuawupinConfig[wupinName]
    if qianghuawupinConfig == nil then
        return ""
    end
    local msg = ""
    if qianghuawupinConfig.attr ~= nil and table.empty(qianghuawupinConfig.attr) == false then
        msg = msg .. hcolor.green("- 属性：" .. description.attribute(qianghuawupinConfig.attr, "；"))
    end
    if qianghuawupinConfig._skillEffect ~= nil then
        for i, v in ipairs(qianghuawupinConfig._skillEffect) do
            local space = "|n"
            if i == 1 then
                space = ""
            end
            msg = msg .. space .. hcolor.green("- 特效" .. tostring(i) .. "：" .. v.description)
        end
    end
    return msg
end

hzhuanye.getQHWPItemDescription = function(wupinName)
    local qianghuawupinConfig = hzhuanye.qianghuawupinConfig[wupinName]
    if qianghuawupinConfig == nil then
        return ""
    end
    local msg = ""
    if qianghuawupinConfig.zhuangbeiTypes ~= nil and #(qianghuawupinConfig.zhuangbeiTypes) >= 1 then
        msg = msg .. "可以对以下类型物品使用：" .. hcolor.green(string.implode("，", qianghuawupinConfig.zhuangbeiTypes))
    elseif qianghuawupinConfig.fitAllTypes == true then
        msg = msg .. "可以对" .. hcolor.green("所有装备") .. "使用"
    end
    return msg
end

hzhuanye.updateItemSourceDescription = function()
    for _, zhuanyeZhizuoNamePair in ipairs(ZHUANYE_NEED_UPDATE_ITEM_SOURCE) do
        local zhuanyeName = zhuanyeZhizuoNamePair[1]
        local zhizuoName = zhuanyeZhizuoNamePair[2]
        hplayer.forEach(
            function(enumPlayer, _)
                if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                    return
                end
                if ZHUANYE_DATA[enumPlayer] == nil or ZHUANYE_DATA[enumPlayer][zhuanyeName] == nil then
                    return
                end
                for i, v in ipairs(ZHUANYE_DATA[enumPlayer][zhuanyeName].categoryData) do
                    v.tip = hzhuanye.getSingleZhuanyeDescription(v.rawConfig, zhizuoName, zhuanyeName)
                end
            end
        )
    end
end

hzhuanye.getShaguaiDescription = function(unit, zhuanye)
    if unit == nil then
        return ""
    end
    if zhuanye == nil then
        return ""
    end
    local level = hunit.getLevel(unit)
    local name = hunit.getName(unit)
    local msg = {}
    for _, v in ipairs(hzhuanye.shaguaiConfig[zhuanye]) do
        if
            (v.unitName == name) or
            (v.minUnitLevel ~= nil and v.minUnitLevel <= level and v.maxUnitLevel ~= nil and v.maxUnitLevel >= level)
        then
            for _, vv in ipairs(v.output) do
                table.insert(
                    msg,
                    hitem.getColoredNameBasedOnPinzhi(vv.name) .. "（" .. tostring(vv.rate / 100) .. "%" .. "）"
                )
            end
            return "击杀有概率获得：" .. string.implode("，", msg)
        end
    end
    return ""
end

hzhuanye.jihuosuoyouzhuanye = function(whichPlayer)
    if hzhuanye[whichPlayer] == nil then
        return
    end
    for i, zhuanye in ipairs(hzhuanye[whichPlayer]) do
        for j = 1, 10, 1 do
            hzhuanye.zengjiaExp(zhuanye.name, whichPlayer, false, 200)
        end
    end
end
