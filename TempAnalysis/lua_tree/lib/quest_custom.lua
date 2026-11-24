---@class hquestcustom 任务配置
hquestcustom = { dialog = {} }

---@enum QUEST_TYPE
QUEST_TYPE = {
    ONCE_LIFETIME = "once_lifetime",
    LIMIT_PER_CYCLE = "limit_per_cycle",
    INFINITE = "infinite",
    LIMIT_PER_GAME = "limit_per_game"
}

---@enum QUEST_CUSTOM_FINISH_TYPE
QUEST_CUSTOM_FINISH_TYPE = {
    immediately = "immediately",
    nearNPC = "nearNPC",
    talkToNPC = "talkToNPC"
}

---@enum QUEST_CUSTOM_EXECUTE_TYPE
QUEST_CUSTOM_EXECUTE_TYPE = {
    KILL = "kill",
    HAS_ITEM_IN_BAG = "hasItemInBag",
    CASTSKILL = "castSkill",
    QIANGHUA = "qianghua",
    JINGLIAN = "jinglian",
    CAIKUANG = "caikuang",
    DUANZAO = "duanzao",
    ZHIBU = "zhibu",
    CAIFENG = "caifeng",
    BAOPI = "baopi",
    ZHIPI = "zhipi",
    FUMO = "fumo",
    DIAOYU = "diaoyu",
    CAIYAO = "caiyao",
    LIANJIN = "lianjin",
    ZHUBAO = "zhubao",
    MINGWEN = "mingwen",
    GET_ITEM_FROM_KILL = "getItemFromKill",
    FINISH_FUBEN = "finishFUBEN"
}

---@enum QUEST_JIANGLI_SCALE_TYPE
QUEST_JIANGLI_SCALE_TYPE = {
    TINY = "tiny",
    SMALL = "small",
    MEDIUM = "medium",
    LARGE = "large",
    HUGE = "huge"
}

QUEST_STATUS = {
    INSUFFICIENT_LEVEL = 1,
    IN_PROGRESS = 2,
    CAN_FINISH = 3
}

QUEST_STATUS_EFFECT = {}
QUEST_STATUS_EFFECT[QUEST_STATUS.INSUFFICIENT_LEVEL] =
"war3mapImported\\QuestionMark\\ExcMark_Grey_UnavailableQuest.mdx"
QUEST_STATUS_EFFECT[QUEST_STATUS.IN_PROGRESS] = "war3mapImported\\QuestionMark\\Completed_Quest_NOT.mdx"
QUEST_STATUS_EFFECT[QUEST_STATUS.CAN_FINISH] =
"war3mapImported\\QuestionMark\\Completed_Quest.mdx" --"war3mapImported\\QuestionMark\\Completed_Quest_Daily.mdx"

---@param quest_series_name string
---@param data table
---@param storage_key string
---@param quest_type string global or hero level
---@return void
function hquestcustom.validateQuestConfig(config)
    for _, querySeries in ipairs(config) do
        if querySeries.name == nil then
            dump("quest name is nil")
        end
        if querySeries.data == nil or #(querySeries.data) < 1 then
            dump("data is nil or does't have data in it for " .. querySeries.name)
        end
        if querySeries.isPerHero == nil and querySeries.questType == QUEST_TYPE.ONCE_LIFETIME then
            dump("isPerHero is nil")
        end
        for k, v in ipairs(querySeries.data) do
            -- 检测index匹配
            if v.index == nil then
                dump(v)
            end
            if k ~= v.index then
                dump("Quest series: " .. querySeries.name .. " has unmatch index. Expect: " .. k .. " got: " .. v.index)
            end
            -- 检查任务完成类型是否设置
            if v.finish == nil then
                dump("Quest index: " .. k .. " missing finish")
            end
            -- 检测任务完成类型是否设置npc名字
            if
                (v.finish == QUEST_CUSTOM_FINISH_TYPE.nearNPC or v.finish == QUEST_CUSTOM_FINISH_TYPE.talkToNPC) and
                (v.finishNPC == nil or hslk.n2i(v.finishNPC) == nil)
            then
                dump("Quest index: " .. k .. " have finish: " .. v.finish .. " but has no valid finish_NPC")
            end
            if v.req == nil then
                dump("Quest index: " .. k .. " have nil req. Req should not be nil")
            end
            if #(v.req) > 3 then
                stack("Too many quest req for index: " .. k .. ". Max is 3")
            end
            if v.level == nil or v.level < 1 then
                stack("missing level info for this quest")
            end
            if v.attr ~= nil then
                for _, vv in ipairs(v.attr) do
                    if type(vv) ~= "table" or #vv ~= 2 or (vv[1] ~= "quanshuxing" and vv[1] ~= "diaoyurate") then
                        dump("Quest index: " .. k .. " have bad attr")
                        dump(v.attr)
                    end
                end
            end
            if v.resources ~= nil then
                for _, vv in ipairs(v.resources) do
                    if
                        type(vv) ~= "table" or #vv < 2 or #vv > 3 or
                        (vv[1] ~= HSHOP_COST_TYPE.gold and vv[1] ~= HSHOP_COST_TYPE.experience and
                            vv[1] ~= HSHOP_COST_TYPE.gongzhenghuizhang and
                            vv[1] ~= HSHOP_COST_TYPE.yongqihuizhang and
                            vv[1] ~= HSHOP_COST_TYPE.dianfengjingyan and
                            vv[1] ~= HSHOP_COST_TYPE.chujixilianshi and
                            vv[1] ~= HSHOP_COST_TYPE.huoyanhuizhang
                            and
                            vv[1] ~= HSHOP_COST_TYPE.zhengyihuizhang and
                            vv[1] ~= HSHOP_COST_TYPE.zhixuhuizhang)
                    then
                        dump("Quest index: " .. k .. " have bad resources")
                        dump(v.resources)
                    end
                end
            end
            -- 检测任务任务要求格式
            if v.req ~= nil then
                for _, vv in ipairs(v.req) do
                    if type(vv) ~= "table" then
                        dump("Quest index: " .. k .. " have bad req. Req content should be {kill:{{},{}}}")
                    end
                    if vv.type == QUEST_CUSTOM_EXECUTE_TYPE.KILL and hslk.n2i(vv.name) == nil then
                        err("quest type is kill unit but don't find object in slk")
                        dump(vv)
                    end
                end
            end
        end
    end
end

---@return boolean
function hquestcustom.canFinish(whichPlayer, quest_series_name, talkingNPC, printInfo)
    for idx, questSeries in ipairs(hquestcustom[whichPlayer]) do
        if questSeries.name == quest_series_name then
            local singleQuest = questSeries.data[questSeries.currentIndex]
            if singleQuest == nil then
                return false
            end
            local finish_type = singleQuest.finish
            local finishNPC = singleQuest.finishNPC
            if finish_type == QUEST_CUSTOM_FINISH_TYPE.talkToNPC and finishNPC ~= talkingNPC then
                return false
            end

            local hero = hplayer.getMainHero(whichPlayer)
            -- check conditions
            for i, v in ipairs(singleQuest.req) do
                if v.type == QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG then
                    if hitem.hasSingleRequiredItems(v, hero, printInfo) == false then
                        return false
                    end
                else
                    if v.current == nil or v.current < v.number then
                        return false
                    end
                end
            end
            -- check finish mode
            if
                finish_type == QUEST_CUSTOM_FINISH_TYPE.nearNPC and
                table.empty(
                    hgroup.createByXY(
                        hunit.x(hero),
                        hunit.y(hero),
                        300,
                        function(filterUnit)
                            return hunit.getName(filterUnit) == finishNPC and
                                hunit.getOwner(filterUnit) ~= henemy.getPlayer()
                        end
                    )
                )
            then
                return false
            elseif finish_type == QUEST_CUSTOM_FINISH_TYPE.talkToNPC then
                if finishNPC == talkingNPC then
                    if hhero.getCurLevel(hero) < singleQuest.level then
                        if printInfo == true then
                            echo(
                                "当前等级不足以完成任务: " .. quest_series_name .. " 需要" .. tostring(singleQuest.level) .. "级",
                                whichPlayer
                            )
                        end
                        return false
                    end
                    return true
                else
                    return false
                end
            end
            if hhero.getCurLevel(hero) < singleQuest.level then
                if printInfo == true and finish_type ~= QUEST_CUSTOM_FINISH_TYPE.immediately then
                    echo(
                        "当前等级不足以完成任务: " .. quest_series_name .. " 需要" .. tostring(singleQuest.level) .. "级",
                        whichPlayer
                    )
                end
                return false
            end
            return true
        end
    end
    return false
end

hquestcustom.getDescription = function(whichPlayer, singleQuest, questType, isPerHero, dailyLimit)
    if singleQuest == nil then
        return "|cffffff00该任务线已经完成|r"
    end

    local tipt = {}
    table.insert(
        tipt,
        "[" ..
        tostring(singleQuest.index) ..
        "]" .. hcolor.yellow(singleQuest.title) .. " (需求等级：" .. tostring(singleQuest.level) .. ")"
    )
    table.insert(tipt, "")
    table.insert(tipt, "|cffffff00介绍|r：" .. singleQuest.text)
    table.insert(tipt, "")
    if singleQuest.req ~= nil and #(singleQuest.req) >= 1 then
        table.insert(tipt, "|cffffff00任务需求|r:")
        for _, singleReq in ipairs(singleQuest.req) do
            local current = 0
            if singleReq.current ~= nil then
                current = singleReq.current
            end
            local color = hcolor.white
            if current >= singleReq.number then
                color = hcolor.green
            end
            if singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.KILL then
                table.insert(tipt, color("击杀 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG then
                local pinzhi = singleReq.pinzhi
                local name = singleReq.name
                if pinzhi == nil then
                    pinzhi = hitem.getItemMinPinzhi(hslk.n2i(name))
                end
                if pinzhi ~= nil then
                    name = ZHUANGBEI_PINZHI_DATA[pinzhi].color(name)
                end
                table.insert(tipt, color("收集" .. name .. " X " .. singleReq.number .. "个"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.CASTSKILL then
                table.insert(tipt, color("释放 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN then
                table.insert(tipt, color("通关" .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.QIANGHUA then
                table.insert(tipt, color("强化 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.JINGLIAN then
                table.insert(tipt, color("精炼 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.ZHIBU then
                table.insert(
                    tipt,
                    color("击杀人形怪获取布料 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次")
                )
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.CAIFENG then
                table.insert(tipt, color("裁缝制作 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.CAIYAO then
                table.insert(tipt, color("采药获得 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.LIANJIN then
                table.insert(tipt, color("炼金获得 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.CAIKUANG then
                table.insert(tipt, color("采矿获得 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.DUANZAO then
                table.insert(tipt, color("锻造 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.BAOPI then
                table.insert(
                    tipt,
                    color("击杀可剥皮怪获取 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次")
                )
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.ZHIPI then
                table.insert(tipt, color("制皮制造 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.FUMO then
                table.insert(
                    tipt,
                    color("制造附魔物品 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次")
                )
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.ZHUBAO then
                table.insert(
                    tipt,
                    color("制造珠宝专业物品 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次")
                )
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.MINGWEN then
                table.insert(tipt, color("制造铭文 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.DIAOYU then
                table.insert(tipt, color("钓鱼 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            end
        end
        table.insert(tipt, "")
    end

    if singleQuest.finish == QUEST_CUSTOM_FINISH_TYPE.immediately then
        table.insert(tipt, "自动完成")
    elseif singleQuest.finish == QUEST_CUSTOM_FINISH_TYPE.nearNPC then
        table.insert(tipt, "完成后靠近: " .. hcolor.yellow(singleQuest.finishNPC) .. " 提交")
    elseif singleQuest.finish == QUEST_CUSTOM_FINISH_TYPE.talkToNPC then
        table.insert(tipt, "完成后与: " .. hcolor.yellow(singleQuest.finishNPC) .. " 对话")
    end
    table.insert(tipt, "")
    table.insert(tipt, "|cffffff00奖励|r：")
    if singleQuest.attr ~= nil then
        for _, v in ipairs(singleQuest.attr) do
            table.insert(
                tipt,
                "- " ..
                hcolor.green(
                    description.attribute(hquestcustom.attrJiangliConfig[v[1]][v[2]](singleQuest.level), "|n- ")
                )
            )
        end
    end
    if singleQuest.resources ~= nil then
        for _, v in ipairs(singleQuest.resources) do
            if hquestcustom.jiangliConfig[v[1]] and hquestcustom.jiangliConfig[v[1]][v[2]] then
                if v[3] ~= nil then
                    table.insert(
                        tipt,
                        "- " ..
                        v[1] ..
                        hcolor.green(
                            "+" ..
                            hquestcustom.jiangliConfig[v[1]][v[2]](singleQuest.level) ..
                            " （超过" .. v[3] .. "无效）"
                        )
                    )
                else
                    table.insert(
                        tipt,
                        "- " .. v[1] .. hcolor.green("+" .. hquestcustom.jiangliConfig[v[1]][v[2]](singleQuest.level))
                    )
                end
            else
                table.insert(tipt, "- " .. v[1] .. hcolor.green("+" .. tostring(v[2])))
            end
        end
    end
    if singleQuest.items ~= nil then
        for i, item in ipairs(singleQuest.items) do
            local countStr = ""
            if item.count > 1 then
                countStr = " X" .. tostring(item.count)
            end
            local levelStr = ""
            if item.itemLevel ~= nil then
                levelStr = "(" .. tostring(item.itemLevel) .. ")级"
            end
            local pinzhi = item.itemPinzhi
            if pinzhi == nil then
                pinzhi = hitem.getItemMinPinzhi(hslk.n2i(item.itemName))
            end
            local color = ZHUANGBEI_PINZHI_DATA[pinzhi].color
            local itemjiangliReq = ""
            if item.requirementDesc ~= nil then
                itemjiangliReq = "（" .. item.requirementDesc .. "）"
            end
            if item.fitAllClass == true then
                table.insert(tipt, "- " .. color(item.itemName .. levelStr) .. countStr .. itemjiangliReq)
            else
                local hero = hplayer.getMainHero(whichPlayer)
                if hero ~= nil then
                    local name = hunit.getName(hero)
                    for _, className in ipairs(item.fitClass) do
                        if name == className then
                            table.insert(tipt, "- " .. color(item.itemName .. levelStr) .. countStr .. itemjiangliReq)
                        end
                    end
                end
            end
        end
    end
    if singleQuest.shengwang ~= nil then
        for _, v in ipairs(singleQuest.shengwang) do
            local shangxian = ""
            if v.maxLevel ~= nil then
                shangxian = "(上限" .. CONST_SHENGWANG_LABEL[v.maxLevel] .. ")"
            end
            table.insert(tipt, "- " .. hcolor.green(tostring(v.value) .. "点" .. v.shengwangname .. "声望" .. shangxian))
        end
    end
    table.insert(tipt, "")
    table.insert(tipt, "|cffffff00注：|r")
    table.insert(tipt, "1.点击任务图标可以显示/关闭任务追踪（屏幕右边任务追踪面板）")

    if questType == QUEST_TYPE.INFINITE then
        table.insert(tipt, "2.该任务为循环任务，|cffffff00可以重复完成|r")
    elseif questType == QUEST_TYPE.ONCE_LIFETIME then
        table.insert(tipt, "2.该任务为一次性任务，|cffffff00只可以完成一次|r")
    elseif questType == QUEST_TYPE.LIMIT_PER_CYCLE then
        table.insert(tipt, "2.该任务日常任务，|cffffff00每日可以完成" .. dailyLimit .. "次|r")
    end
    if isPerHero == true then
        table.insert(tipt, "3.该任务进度|cffffff00存档|r，但不同职业|cffffff00不共享|r")
    elseif isPerHero == false then
        table.insert(tipt, "3.该任务进度|cffffff00存档|r，且不同职业|cffffff00可以共享（任务的属性奖励也会共享，不用担心一个角色做了任务属性奖励只加给完成任务的角色）|r")
    else
        table.insert(tipt, "3.该任务进度|cffffff00不存档|r，请在当局完成")
    end

    return string.implode("|n", tipt)
end

hquestcustom.hasEnoughLevel = function(whichPlayer, quest_series_name)
    local hero = hplayer.getMainHero(whichPlayer)
    for idx, questSeries in ipairs(hquestcustom[whichPlayer]) do
        if questSeries.name == quest_series_name then
            local singleQuest = questSeries.data[questSeries.currentIndex]
            if singleQuest == nil then
                return false
            end
            if hhero.getCurLevel(hero) >= singleQuest.level then
                return true
            else
                return false
            end
        end
    end
end

hquestcustom.getSimpleDescription = function(querySeriesName, singleQuest)
    if singleQuest == nil then
        return querySeriesName .. ": 已完成"
    end

    local tipt = {}
    table.insert(
        tipt,
        querySeriesName ..
        "[" ..
        tostring(singleQuest.index) ..
        "]" .. hcolor.yellow(singleQuest.title) .. " (需求等级：" .. tostring(singleQuest.level) .. ")"
    )
    if singleQuest.req ~= nil and #(singleQuest.req) >= 1 then
        for _, singleReq in ipairs(singleQuest.req) do
            local current = 0
            if singleReq.current ~= nil then
                current = singleReq.current
            end
            local color = hcolor.white
            if current >= singleReq.number then
                color = hcolor.green
            end
            if singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.KILL then
                table.insert(tipt, color("·击杀 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG then
                local pinzhi = singleReq.pinzhi
                local name = singleReq.name
                if pinzhi == nil then
                    pinzhi = hitem.getItemMinPinzhi(hslk.n2i(name))
                end
                if pinzhi ~= nil then
                    name = ZHUANGBEI_PINZHI_DATA[pinzhi].color(name)
                end
                table.insert(tipt, color("·收集" .. name .. " X " .. singleReq.number .. "个"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.CASTSKILL then
                table.insert(tipt, color("·释放 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.QIANGHUA then
                table.insert(tipt, color("·强化 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.JINGLIAN then
                table.insert(tipt, color("·精炼 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN then
                table.insert(tipt, color("·通关" .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.ZHIBU then
                table.insert(
                    tipt,
                    color("·击杀人形怪获取布料 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次")
                )
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.CAIFENG then
                table.insert(
                    tipt,
                    color("·裁缝制作 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次")
                )
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.CAIYAO then
                table.insert(
                    tipt,
                    color("·采药获得 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次")
                )
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.LIANJIN then
                table.insert(
                    tipt,
                    color("·炼金获得 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次")
                )
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.CAIKUANG then
                table.insert(
                    tipt,
                    color("·采矿获得 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次")
                )
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.DUANZAO then
                table.insert(tipt, color("·锻造 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次"))
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.BAOPI then
                table.insert(
                    tipt,
                    color("·击杀可剥皮怪获取 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次")
                )
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.ZHIPI then
                table.insert(
                    tipt,
                    color("·制皮制造 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次")
                )
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.FUMO then
                table.insert(
                    tipt,
                    color("·制造附魔物品 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次")
                )
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.ZHUBAO then
                table.insert(
                    tipt,
                    color("·制造珠宝专业物品 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次")
                )
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.MINGWEN then
                table.insert(
                    tipt,
                    color("·制造铭文 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次")
                )
            elseif singleReq.type == QUEST_CUSTOM_EXECUTE_TYPE.DIAOYU then
                table.insert(
                    tipt,
                    color("·钓鱼 " .. singleReq.name .. " " .. current .. "/" .. singleReq.number .. "次")
                )
            end
        end
    end

    if singleQuest.finish == QUEST_CUSTOM_FINISH_TYPE.immediately then
        table.insert(tipt, "·自动完成")
    elseif singleQuest.finish == QUEST_CUSTOM_FINISH_TYPE.nearNPC then
        table.insert(tipt, "·完成后靠近: " .. hcolor.yellow(singleQuest.finishNPC) .. " 提交")
    elseif singleQuest.finish == QUEST_CUSTOM_FINISH_TYPE.talkToNPC then
        table.insert(tipt, "·完成后与: " .. hcolor.yellow(singleQuest.finishNPC) .. " 对话")
    end
    return string.implode("|n", tipt)
end

function hquestcustom.setUpQuestTrigger(whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    -- set up kill trigger
    hevent.register(
        hero,
        CONST_EVENT.kill,
        "quest_kill",
        function(evtData)
            local group = hgroup.createAllyGroupByUnit(hero, 1500)
            for _, unit in ipairs(group) do
                local targetPlayer = hunit.getOwner(unit)
                if hplayer.getMainHero(targetPlayer) == unit then
                    hquestcustom.addEventCount(targetPlayer, CONST_EVENT.kill, hunit.getName(evtData.targetUnit))
                end
            end
        end
    )
    hevent.register(
        hero,
        CONST_EVENT.skillCast,
        "quest_skll_cast",
        function(evtData)
            hquestcustom.addEventCount(whichPlayer, CONST_EVENT.skillCast, hskill.getName(evtData.triggerSkill))
        end
    )
    hevent.register(
        hero,
        CONST_EVENT.qianghua,
        "quest_custom_qianghua",
        function(evtData)
            hquestcustom.addEventCount(whichPlayer, CONST_EVENT.qianghua, evtData.triggerName)
        end
    )
    hevent.register(
        hero,
        CONST_EVENT.jinglian,
        "quest_custom_jinglian",
        function(evtData)
            hquestcustom.addEventCount(whichPlayer, CONST_EVENT.jinglian, evtData.triggerName)
        end
    )
    hevent.register(
        hero,
        CONST_EVENT.duanzao,
        "quest_custom_duanzao",
        function(evtData)
            hquestcustom.addEventCount(whichPlayer, CONST_EVENT.duanzao, evtData.triggerName)
        end
    )
    hevent.register(
        hero,
        CONST_EVENT.caiyao,
        "quest_custom_caiyao",
        function(evtData)
            hquestcustom.addEventCount(whichPlayer, CONST_EVENT.caiyao, evtData.triggerName)
        end
    )
    hevent.register(
        hero,
        CONST_EVENT.caikuang,
        "quest_custom_caikuang",
        function(evtData)
            hquestcustom.addEventCount(whichPlayer, CONST_EVENT.caikuang, evtData.triggerName)
        end
    )
    hevent.register(
        hero,
        CONST_EVENT.baopi,
        "quest_custom_baopi",
        function(evtData)
            hquestcustom.addEventCount(whichPlayer, CONST_EVENT.baopi, evtData.triggerName)
        end
    )
    hevent.register(
        hero,
        CONST_EVENT.zhibu,
        "quest_custom_zhibu",
        function(evtData)
            hquestcustom.addEventCount(whichPlayer, CONST_EVENT.zhibu, evtData.triggerName)
        end
    )
    hevent.register(
        hero,
        CONST_EVENT.fumo,
        "quest_custom_fumo",
        function(evtData)
            hquestcustom.addEventCount(whichPlayer, CONST_EVENT.fumo, evtData.triggerName)
        end
    )
    hevent.register(
        hero,
        CONST_EVENT.caifeng,
        "quest_custom_caifeng",
        function(evtData)
            hquestcustom.addEventCount(whichPlayer, CONST_EVENT.caifeng, evtData.triggerName)
        end
    )
    hevent.register(
        hero,
        CONST_EVENT.zhipi,
        "quest_custom_zhipi",
        function(evtData)
            hquestcustom.addEventCount(whichPlayer, CONST_EVENT.zhipi, evtData.triggerName)
        end
    )
    hevent.register(
        hero,
        CONST_EVENT.lianjin,
        "quest_custom_lianjin",
        function(evtData)
            hquestcustom.addEventCount(whichPlayer, CONST_EVENT.lianjin, evtData.triggerName)
        end
    )
    hevent.register(
        hero,
        CONST_EVENT.diaoyu,
        "quest_custom_diaoyu",
        function(evtData)
            hquestcustom.addEventCount(whichPlayer, CONST_EVENT.diaoyu, hunit.getName(evtData.NPC))
        end
    )
    hevent.register(
        hero,
        CONST_EVENT.finishFUBEN,
        "quest_custom_finishFUBEN",
        function(evtData)
            hquestcustom.addEventCount(
                whichPlayer,
                QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                FUBEN_NANDU_LABEL[evtData.nandu] .. evtData.fubenName
            )

            if evtData.nandu == FUBEN_NANDU.CHUANQI then
                hquestcustom.addEventCount(whichPlayer, QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN, "任意副本的传奇难度")
            end
        end
    )
    hevent.register(
        hero,
        CONST_EVENT.duihuaNPC,
        "quest_custom_duihua",
        function(evtData)
            -- check if quest can be finished
            for _, querySeries in ipairs(hquestcustom[whichPlayer]) do
                if hquestcustom.canFinish(whichPlayer, querySeries.name, hunit.getName(evtData.NPC), true) then
                    hquestcustom.finish(whichPlayer, querySeries.name, true, evtData.NPC)
                end
            end
        end
    )
    htime.setInterval(
        3,
        function(_)
            -- check if quest can be finished
            for _, querySeries in ipairs(hquestcustom[whichPlayer]) do
                if hquestcustom.canFinish(whichPlayer, querySeries.name, nil, false) then
                    hquestcustom.finish(whichPlayer, querySeries.name, true, nil)
                end
            end
        end
    )
end

function hquestcustom.finish(whichPlayer, quest_series_name, cundang, NPC)
    for idx, questSeries in ipairs(hquestcustom[whichPlayer]) do
        if questSeries.name == quest_series_name then
            local currentIndex = questSeries.currentIndex or 1
            local singleQuest = questSeries.data[currentIndex]
            if singleQuest == nil then
                err("bad quest")
                return
            end
            local nextQuest = questSeries.data[currentIndex + 1]
            local hero = hplayer.getMainHero(whichPlayer)
            -- trigger effect that finish request
            if cundang == true then
                echo("完成 " .. quest_series_name .. " : " .. singleQuest.title .. ".", whichPlayer)
                local hero = hplayer.getMainHero(whichPlayer)
                if hbuff.hasBuff(hero, "坐骑") then
                    heffect.xyz(
                        "war3mapImported\\[Spell]_065.mdx",
                        hunit.x(hero),
                        hunit.y(hero),
                        hunit.z(hero) + 150,
                        1,
                        1,
                        1,
                        1,
                        1
                    )
                else
                    heffect.attach("war3mapImported\\[Spell]_065.mdx", hero, "over head", 0)
                end
                for _, v in ipairs(singleQuest.req) do
                    if v.type == QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG then
                        hitem.removeSingleItemReqFromBag(v, hero)
                    end
                end
                if
                    singleQuest.finishText ~= nil and singleQuest.finish == QUEST_CUSTOM_FINISH_TYPE.talkToNPC or
                    singleQuest.finish == QUEST_CUSTOM_FINISH_TYPE.nearNPC
                then
                    hquestcustom.enqueue_dialog(whichPlayer, hunit.getName(NPC), singleQuest.finishText)
                end
                if singleQuest.finishEffect ~= nil then
                    singleQuest.finishEffect(whichPlayer)
                end
                local nextQuest = questSeries.data[currentIndex + 1]
                if nextQuest ~= nil then
                    echo("获得 " .. quest_series_name .. " : " .. nextQuest.title .. ".", whichPlayer)
                    if singleQuest.finish == QUEST_CUSTOM_FINISH_TYPE.talkToNPC then
                        hquestcustom.enqueue_dialog(whichPlayer, hunit.getName(NPC), nextQuest.text)
                    end
                else
                    -- refresh UI to show quest series has finished
                    echo("恭喜完成任务线：" .. quest_series_name .. ".", whichPlayer)
                end
            end
            questSeries.currentIndex = currentIndex + 1
            if nextQuest == nil then
                if questSeries.questType == QUEST_TYPE.INFINITE then
                    questSeries.currentIndex = 1
                    nextQuest = questSeries.data[1]
                elseif questSeries.questType == QUEST_TYPE.LIMIT_PER_CYCLE then
                    local currentValue =
                        tonumber(
                            string.sub(
                                hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(
                                    questSeries.cycleCundangStr,
                                    questSeries.isPerHero,
                                    false
                                ),
                                questSeries.cycleCheckPointIndex,
                                questSeries.cycleCheckPointIndex
                            )
                        )
                    if currentValue < questSeries.dailyLimit then
                        hplayer.dzCunDang[whichPlayer].saveCundang(
                            questSeries.cycleCundangStr,
                            questSeries.isPerHero,
                            questSeries.cycleCheckPointIndex,
                            questSeries.cycleCheckPointIndex,
                            tostring(math.min(currentValue + 1, 9))
                        )
                        questSeries.currentIndex = 1
                        nextQuest = questSeries.data[1]
                        if nextQuest.req ~= nil and #(nextQuest.req) > 0 then
                            for _, req in ipairs(nextQuest.req) do
                                if req.current ~= nil then
                                    req.current = 0
                                end
                            end
                        end
                        hquestcustom.cundang(questSeries, whichPlayer)
                        local left = questSeries.dailyLimit - currentValue - 1
                        echo("已刷新" .. questSeries.name .. "，今日剩余刷新次数：" .. tostring(left), whichPlayer)
                    end
                end
            end
            if nextQuest ~= nil then
                for _, singleReq in ipairs(nextQuest.req) do
                    singleReq.current = 0
                end
            end
            if cundang == true then
                hquestcustom.cundang(questSeries, whichPlayer)
                -- 资源
                if singleQuest.resources ~= nil then
                    for _, v in ipairs(singleQuest.resources) do
                        local jiangliType = v[1]
                        local jianglicount = 0
                        if hquestcustom.jiangliConfig[v[1]] ~= nil then
                            jianglicount = hquestcustom.jiangliConfig[v[1]][v[2]](singleQuest.level)
                            if jiangliType == HSHOP_COST_TYPE.dianfengjingyan then
                                local dianfengExpRatio = hattribute.getWithLimit(hero, nil, "dianfeng_jingyan_ratio", 0)
                                jianglicount = math.floor(jianglicount * (dianfengExpRatio + 100) / 100)
                            end
                        else
                            jianglicount = v[2]
                        end
                        if v[3] ~= nil and hresource.checkHasSingleResource(whichPlayer, v[1], v[3], false) then
                            echo(hcolor.yellow("系统：") .. v[1] .. "超过该任务奖励上限（" .. v[3] .. "，无法获取。")
                        else
                            hresource.addSingleResource(whichPlayer, jiangliType, jianglicount, true)
                        end
                    end
                end
                -- 物品
                local items = singleQuest.items
                if items ~= nil then
                    for _, item in ipairs(items) do
                        local id = hslk.n2i(item.itemName)
                        if id ~= nil and (item.requirement == nil or item.requirement(whichPlayer) == true) then
                            local pinzhi = item.itemPinzhi
                            if pinzhi == nil then
                                pinzhi = hitem.getItemMinPinzhi(id)
                            end
                            local itemLevel = item.itemLevel
                            if itemLevel == nil then
                                itemLevel = 1
                            end
                            if item.fitAllClass == true then
                                for _ = 1, item.count, 1 do
                                    local dynamicItem = DynamicItem(id)
                                    dynamicItem.initBasedOnPinzhi(pinzhi, itemLevel)
                                    dynamicItem.setOwner(whichPlayer)
                                    if hplayer.dzCunDang[whichPlayer].saveItemInInventory(dynamicItem) == false then
                                        hitem.create({ id = id, dynamicItem = dynamicItem, whichUnit = hero })
                                    end
                                end
                            else
                                local name = hunit.getName(hero)
                                for _, className in ipairs(item.fitClass) do
                                    if name == className then
                                        for j = 1, item.count, 1 do
                                            local dynamicItem = DynamicItem(id)
                                            dynamicItem.initBasedOnPinzhi(pinzhi, itemLevel)
                                            dynamicItem.setOwner(whichPlayer)

                                            if hplayer.dzCunDang[whichPlayer].saveItemInInventory(dynamicItem) == false then
                                                hitem.create({ id = id, dynamicItem = dynamicItem, whichUnit = hero })
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                local shengwang = singleQuest.shengwang
                if shengwang ~= nil then
                    for _, v in ipairs(shengwang) do
                        local shengwang_rate = hattr.getWithLimit(hero, nil, "shengwang_rate", 0)
                        local finalSWValue = math.floor(v.value * (100 + shengwang_rate) / 100)
                        hshengwang.huodeShengWang(v.shengwangname, whichPlayer, cundang, finalSWValue)
                    end
                end
            end
            -- 属性
            if singleQuest.attr ~= nil and hunit.getLevel(hero) >= singleQuest.level then
                for _, v in ipairs(singleQuest.attr) do
                    hattr.set(hero, 0, hquestcustom.attrJiangliConfig[v[1]][v[2]](singleQuest.level))
                    if cundang == true then
                        echo(
                            "获得：" ..
                            hcolor.green(
                                description.attribute(
                                    hquestcustom.attrJiangliConfig[v[1]][v[2]](singleQuest.level),
                                    "，"
                                )
                            )
                        )
                    end
                end
            end
            hquestcustom.updateUI(
                whichPlayer,
                idx,
                nextQuest,
                questSeries.questType,
                questSeries.isPerHero,
                questSeries.dailyLimit
            )
        end
    end
end

function hquestcustom.isQuestFinished(whichPlayer, quest_series_name)
    for idx, questSeries in ipairs(hquestcustom[whichPlayer]) do
        if questSeries.name == quest_series_name then
            local singleQuest = questSeries.data[questSeries.currentIndex]
            if singleQuest == nil then
                return true
            end
            return false
        end
    end
end

function hquestcustom.addEventCount(whichPlayer, query_custom_event, triggerName, val)
    val = val or 1
    for idx, questSeries in ipairs(hquestcustom[whichPlayer]) do
        local singleQuest = questSeries.data[questSeries.currentIndex]
        if singleQuest ~= nil then
            for ii, vv in ipairs(singleQuest.req) do
                if
                    vv.type == query_custom_event and (vv.name == triggerName or vv.name == "任意目标") and
                    (vv.current ~= nil or vv.current < vv.number)
                then
                    vv.current = vv.current or 0
                    vv.current = vv.current + val
                    if query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.KILL then
                        echo(("已击杀 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG then
                        echo(("已收集 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.CASTSKILL then
                        echo(("已释放 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.QIANGHUA then
                        echo(("已强化 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.JINGLIAN then
                        echo(("已精炼 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.ZHIBU then
                        echo(("已击杀人形怪获取布料 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.CAIFENG then
                        echo(("裁缝已制作 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.CAIKUANG then
                        echo(("采矿已获得 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN then
                        echo(("通关 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.DUANZAO then
                        echo(("已锻造 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.CAIYAO then
                        echo(("已采集 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.LIANJIN then
                        echo(("已制作 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.BAOPI then
                        echo(("击杀可剥皮怪已获取 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.ZHIPI then
                        echo(("制皮已制造 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.FUMO then
                        echo(("已制造附魔物品 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.ZHUBAO then
                        echo(("已制造珠宝专业物品 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.MINGWEN then
                        echo(("已制造铭文 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    elseif query_custom_event == QUEST_CUSTOM_EXECUTE_TYPE.DIAOYU then
                        echo(("钓鱼 " .. vv.name .. " " .. vv.current .. "/" .. vv.number .. "次"), whichPlayer)
                    end
                    hquestcustom.cundang(questSeries, whichPlayer)
                    hquestcustom.updateUI(
                        whichPlayer,
                        idx,
                        singleQuest,
                        questSeries.questType,
                        questSeries.isPerHero,
                        questSeries.dailyLimit
                    )
                end
            end
        end
    end
end

function hquestcustom.updateUI(whichPlayer, idx, singleQuest, questType, isPerHero, dailyLimit)
    local str = hquestcustom.getDescription(whichPlayer, singleQuest, questType, isPerHero, dailyLimit)
    if singleQuest == nil then
        ui_enable_achievement_data_at_category_and_idx(whichPlayer, "任务", idx)
        ui_update_text_achievement_data_at_category_and_idx(whichPlayer, "任务", idx, "任务线已完成")
        ui_update_equip_achievement_data_at_category_and_idx(whichPlayer, "任务", idx, false, true)
    else
        if singleQuest.index > 1 then
            ui_enable_achievement_data_at_category_and_idx(whichPlayer, "任务", idx)
        end
        ui_update_art_achievement_data_at_category_and_idx(whichPlayer, "任务", idx, singleQuest.art)
        ui_update_text_achievement_data_at_category_and_idx(whichPlayer, "任务", idx, str)
        ui_update_equip_achievement_data_at_category_and_idx(whichPlayer, "任务", idx, false, false)
    end
end

function hquestcustom.init(config, jiangliConfig, attrJiangliConfig)
    hquestcustom.validateQuestConfig(config)
    hevent.reaction(
        CONST_EVENT.itemSell,
        "quest_custom_duihua",
        function(evtData)
            if hitem.getName(evtData.soldItem) ~= "对话" then
                return
            end
            local triggerData = {
                triggerUnit = evtData.buyingUnit,
                NPC = evtData.triggerUnit
            }
            hevent.trigger(evtData.buyingUnit, CONST_EVENT.duihuaNPC, triggerData)
        end
    )
    hquestcustom.jiangliConfig = jiangliConfig
    hquestcustom.attrJiangliConfig = attrJiangliConfig
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hquestcustom[enumPlayer] = table.clone(config)
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end
            ACHIEVEMENT_DATA[enumPlayer]["任务"] = {}
            ACHIEVEMENT_DATA[enumPlayer]["任务"].categoryUIName = "BtnRootWindow_Category_Achieve"
            local categoryData = {}
            for _, v in ipairs(hquestcustom[enumPlayer]) do
                local tmpItem = {}
                tmpItem.name = v.name
                local currentIndex = 1
                local currentQuest = v.data[currentIndex]
                tmpItem.art = currentQuest.art
                if v.name == "主线任务" or v.name == "历练任务" or v.name == "日常任务" or v.name == "灼热峡谷日常" then
                    v.tracking = true
                else
                end
                tmpItem.callback = function()
                    if v.tracking == false then
                        v.tracking = true
                    else
                        v.tracking = false
                    end
                end
                tmpItem.tip =
                    hquestcustom.getDescription(enumPlayer, currentQuest, v.questType, v.isPerHero, v.dailyLimit)
                tmpItem.enable = false
                table.insert(categoryData, tmpItem)
            end
            ACHIEVEMENT_DATA[enumPlayer]["任务"].categoryData = categoryData
        end
    )

    -- setup dialog UI
    hjapi.DzLoadToc("UI\\shanghaitongji.toc")
    local backdrop = hjapi.DzCreateFrameByTagName("BACKDROP", "hquest_dialog", hjapi.DzGetGameUI(), "shanghaitongji", 0)
    local text = hjapi.DzCreateFrameByTagName("TEXT", "hquest_dialog_text", backdrop, "", 0)
    hjapi.DzFrameSetSize(text, 0.25, 0.08)
    hjapi.DzFrameSetPoint(backdrop, 0, text, 0, -0.005, 0.005)
    hjapi.DzFrameSetPoint(backdrop, 8, text, 8, 0.005, -0.005)
    hjapi.DzFrameSetPoint(text, 4, hjapi.DzGetGameUI(), 4, 0, -0.05)
    hjapi.DzFrameShow(backdrop, false)
    hjapi.DzFrameShow(text, true)
    hjapi.DzFrameSetEnable(text, false)

    htime.setInterval(
        0.05,
        function(curTimer)
            for whichPlayer, data --[[validated]] in pairs(hquestcustom.dialog) do
                if data.currentIndex > #(data.content) then
                    data.currentCharIndex = 1
                elseif data.currentCharIndex < (#(data.content[data.currentIndex].text) + 20) then
                    if whichPlayer == hplayer.loc() then
                        hjapi.DzFrameSetText(
                            text,
                            data.content[data.currentIndex].name ..
                            "|n" ..
                            string.sub(
                                data.content[data.currentIndex].text,
                                1,
                                math.min(#(data.content[data.currentIndex].text), data.currentCharIndex)
                            )
                        )
                        hjapi.DzFrameShow(backdrop, true)
                    end
                    data.currentCharIndex = data.currentCharIndex + 1
                else
                    data.currentCharIndex = 1
                    data.currentIndex = data.currentIndex + 1
                    if whichPlayer == hplayer.loc() then
                        hjapi.DzFrameSetText(text, "")
                        hjapi.DzFrameShow(backdrop, false)
                    end
                end
            end
        end
    )

    htime.setInterval(
        1,
        function(curTimer)
            local perNPCQuestStatus = {}
            hplayer.forEach(
                function(enumPlayer, _)
                    if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                        return
                    end
                    local perNPCQuestInfo = {}
                    for i, querySeries in ipairs(hquestcustom[enumPlayer]) do
                        local currentIndex = querySeries.currentIndex
                        local quest = querySeries.data[currentIndex]
                        if quest ~= nil and quest.finishNPC ~= nil then
                            if perNPCQuestInfo[quest.finishNPC] == nil then
                                perNPCQuestInfo[quest.finishNPC] = {}
                            end
                            local hero = hplayer.getMainHero(enumPlayer)
                            local heroLevel = 1
                            if hero ~= nil then
                                heroLevel = hunit.getLevel(hero)
                            end
                            local levelStr = tostring(quest.level) .. "级"
                            levelStr = hcolor.set_level_str_with_color(levelStr, heroLevel, quest.level)
                            local hasEnoughLevel = hquestcustom.hasEnoughLevel(enumPlayer, querySeries.name)
                            local canFinish = hquestcustom.canFinish(enumPlayer, querySeries.name, quest.finishNPC)
                            local questStatus = QUEST_STATUS.INSUFFICIENT_LEVEL
                            local qsStr = ""
                            if hasEnoughLevel == false then
                                questStatus = QUEST_STATUS.INSUFFICIENT_LEVEL
                                qsStr = hcolor.yellow("（等级不够）")
                            elseif hasEnoughLevel == true and canFinish == false then
                                questStatus = QUEST_STATUS.IN_PROGRESS
                                qsStr = hcolor.yellow("（进行中）")
                            else
                                questStatus = QUEST_STATUS.CAN_FINISH
                                qsStr = hcolor.green("（可完成）")
                            end

                            if
                                querySeries.questType ~= QUEST_TYPE.INFINITE and
                                (perNPCQuestStatus[quest.finishNPC] == nil or
                                    perNPCQuestStatus[quest.finishNPC] < questStatus)
                            then
                                perNPCQuestStatus[quest.finishNPC] = questStatus
                            end
                            table.insert(
                                perNPCQuestInfo[quest.finishNPC],
                                "-" .. qsStr .. querySeries.name .. ":" .. quest.title .. "(" .. levelStr .. ")"
                            )
                        end
                    end
                    local mergedPerNPCQuestInfo = {}
                    for k, v --[[validated]] in pairs(perNPCQuestInfo) do
                        mergedPerNPCQuestInfo[k] = string.implode("|n", v)
                    end
                    hcache.set(enumPlayer, "per_NPC_quest_info", mergedPerNPCQuestInfo)
                end
            )
            hgroup.forEachInALL(
                function(enumUnit, idx)
                    local questStatus = perNPCQuestStatus[hunit.getName(enumUnit)]
                    local existing = hcache.get(enumUnit, "quest_status")
                    if questStatus ~= nil then
                        if existing == nil then
                            hcache.set(enumUnit, "quest_status", questStatus)
                            hcache.set(
                                enumUnit,
                                "quest_status_effect",
                                heffect.attach(QUEST_STATUS_EFFECT[questStatus], enumUnit, "over head", -1)
                            )
                        elseif existing ~= nil and questStatus ~= existing then
                            heffect.destroy(hcache.get(enumUnit, "quest_status_effect"))
                            hcache.set(enumUnit, "quest_status", questStatus)
                            hcache.set(
                                enumUnit,
                                "quest_status_effect",
                                heffect.attach(QUEST_STATUS_EFFECT[questStatus], enumUnit, "over head", -1)
                            )
                        end
                    elseif existing ~= nil then
                        heffect.destroy(hcache.get(enumUnit, "quest_status_effect"))
                        hcache.free(enumUnit, "quest_status")
                        hcache.free(enumUnit, "quest_status_effect")
                    end
                end
            )
        end
    )
end

hquestcustom.getQuestUIContent = function(whichPlayer)
    local tipt = {}
    table.insert(tipt, "|cffffff00任务追踪|r: （奖励等请在|cffffff00F3|r查看）")
    for _, questSeries in ipairs(hquestcustom[whichPlayer]) do
        if questSeries.tracking == true then
            table.insert(tipt, "")
            table.insert(
                tipt,
                hquestcustom.getSimpleDescription(questSeries.name, questSeries.data[questSeries.currentIndex])
            )
        end
    end
    return string.implode("|n", tipt)
end

hquestcustom.enqueue_dialog = function(whichPlayer, dialogName, text)
    if hquestcustom.dialog[whichPlayer] == nil then
        hquestcustom.dialog[whichPlayer] = {}
        hquestcustom.dialog[whichPlayer].currentIndex = 1
        hquestcustom.dialog[whichPlayer].currentCharIndex = 1
        hquestcustom.dialog[whichPlayer].content = {}
    end
    table.insert(hquestcustom.dialog[whichPlayer].content, { name = hcolor.yellow(dialogName), text = text })
end

function hquestcustom.cundang(questSeries, whichPlayer)
    if questSeries.questType == QUEST_TYPE.INFINITE then
        return
    end
    local idxStr = tostring(questSeries.currentIndex)
    local quest = questSeries.data[questSeries.currentIndex]
    while string.len(idxStr) < 3 do
        idxStr = "0" .. idxStr
    end
    local cundangStr = idxStr
    if quest == nil then
        cundangStr = cundangStr .. "000000000000"
    else
        for i = 1, 3, 1 do
            local singleReq = quest.req[i]
            local cdStr = "0000"
            if singleReq ~= nil then
                cdStr = tostring(singleReq.current) or "0"
                while string.len(cdStr) < 4 do
                    cdStr = "0" .. cdStr
                end
            end
            cundangStr = cundangStr .. cdStr
        end
    end

    hplayer.dzCunDang[whichPlayer].saveCundang(questSeries.cundangStr, questSeries.isPerHero, 1, 15, cundangStr)
end

function hquestcustom.testFullQuest(whichPlayer)
    for _, questSeries in ipairs(hquestcustom[whichPlayer]) do
        questSeries.currentIndex = #(questSeries.data)
        hquestcustom.cundang(questSeries, whichPlayer)
    end
end

function hquestcustom.resetQuest(whichPlayer)
    for _, questSeries in ipairs(hquestcustom[whichPlayer]) do
        questSeries.currentIndex = 1
        hquestcustom.cundang(questSeries, whichPlayer)
    end
end

function hquestcustom.loadcundang(whichPlayer)
    for i, querySeries in ipairs(hquestcustom[whichPlayer]) do
        if querySeries.questType == QUEST_TYPE.ONCE_LIFETIME or querySeries.questType == QUEST_TYPE.LIMIT_PER_CYCLE then
            local cundang =
                hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(querySeries.cundangStr, querySeries.isPerHero)
            local currentIndex = math.floor(tonumber(string.sub(cundang, 1, 3)) or 1)
            local currentReq1 = math.floor(tonumber(string.sub(cundang, 4, 7)) or 0)
            local currentReq2 = math.floor(tonumber(string.sub(cundang, 8, 11)) or 0)
            local currentReq3 = math.floor(tonumber(string.sub(cundang, 12, 15)) or 0)
            for j = 1, math.min(currentIndex - 1, #(querySeries.data)), 1 do
                hquestcustom.finish(whichPlayer, querySeries.name, false, nil)
            end

            if
                querySeries.data[querySeries.currentIndex] ~= nil and
                querySeries.data[querySeries.currentIndex].req[1] ~= nil
            then
                querySeries.data[querySeries.currentIndex].req[1].current = currentReq1
            end
            if
                querySeries.data[querySeries.currentIndex] ~= nil and
                querySeries.data[querySeries.currentIndex].req[2] ~= nil
            then
                querySeries.data[querySeries.currentIndex].req[2].current = currentReq2
            end
            if
                querySeries.data[querySeries.currentIndex] ~= nil and
                querySeries.data[querySeries.currentIndex].req[3] ~= nil
            then
                querySeries.data[querySeries.currentIndex].req[3].current = currentReq3
            end
            hquestcustom.updateUI(
                whichPlayer,
                i,
                querySeries.data[querySeries.currentIndex],
                querySeries.questType,
                querySeries.isPerHero,
                querySeries.dailyLimit
            )
        end
    end
end

function hquestcustom.finishAllQuest(whichPlayer)
    for i, querySeries in ipairs(hquestcustom[whichPlayer]) do
        for j, singleQuest in ipairs(querySeries.data) do
            hquestcustom.finish(whichPlayer, querySeries.name, false, nil)
        end
    end
end

function hquestcustom.finishQuestSeries(whichPlayer, questSeriesName)
    for i, querySeries in ipairs(hquestcustom[whichPlayer]) do
        if querySeries.name == questSeriesName then
            querySeries.currentIndex = #(querySeries.data) + 1
            hquestcustom.cundang(querySeries, whichPlayer)
            hquestcustom.updateUI(
                whichPlayer,
                i,
                nil,
                querySeries.questType,
                querySeries.isPerHero,
                querySeries.dailyLimit
            )
            break
        end
    end
end

-- TODO 日常模块化，加入日常boss掉率奖励限制次数，日常经验获取限制等
hquestcustom.updateDailyQuest = function(whichPlayer)
    local currentYDay = os.date("!*t", hjapi.DzAPI_Map_GetGameStartTime() + 28800).yday
    local lastGameYDay = tonumber(hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang("lastgameyday", false, true))
    if currentYDay ~= lastGameYDay then
        hplayer.dzCunDang[whichPlayer].saveCundangWihtoutIndx("lastgameyday", false, currentYDay)
        hplayer.dzCunDang[whichPlayer].saveCundang(
            "richang",
            false,
            1,
            63,
            "000000000000000000000000000000000000000000000000000000000000000"
        )
        if os.date("!*t", hjapi.DzAPI_Map_GetGameStartTime() + 28800).wday == 1 then
            hplayer.dzCunDang[whichPlayer].saveCundang(
                "damijingcur",
                false,
                1,
                63,
                "000000000000000000000000000000000000000000000000000000000000000"
            )
        end
    end
end
