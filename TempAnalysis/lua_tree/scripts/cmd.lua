function setup_cmd()
    setup_normal_cmd()
    if DEBUGGING == true then
        setup_testing_cmd()
    end
end

function setup_normal_cmd()
    -- 视角
    hcmd(
        "+",
        function(evtData)
            hcamera.changeDistance(evtData.triggerPlayer, 100)
        end
    )
    hcmd(
        "-",
        function(evtData)
            hcamera.changeDistance(evtData.triggerPlayer, -100)
        end
    )
    -- 清空存档
    hcmd(
        "qkcdwozhendeyaoqkcdle",
        function(evtData)
            hcache.set(evtData.triggerPlayer, "disablebeibaosave", true)
            hdzcundang.clearNonJueseCunDang(evtData.triggerPlayer)
        end
    )

    -- 清空存档
    hcmd(
        "qingkongdangqianjuesecundang",
        function(evtData)
            hcache.set(evtData.triggerPlayer, "disablebeibaosave", true)
            hdzcundang.clearJueseCunDang(evtData.triggerPlayer)
        end
    )

    -- 重置天赋
    hcmd(
        "resettianfu",
        function(evtData)
            htianfu.resetTianfu(evtData.triggerPlayer)
        end
    )

    hcmd(
        "enableshanyaoceshimingling",
        function(evtData)
            if hjapi.DzAPI_Map_IsAuthor(evtData.triggerPlayer) or
                hjapi.DzAPI_Map_GetPlayerUserName(evtData.triggerPlayer) == "呮茵伱呔媄#4613" or
                hjapi.DzAPI_Map_GetPlayerUserName(evtData.triggerPlayer) == "毁灭利刃#9142" then
                JassRuntime = require "jass.runtime"
                JassRuntime.console = true
                JassRuntime.sleep = false
                JassRuntime.debugger = 4279
                JassRuntime.error_handle = function(msg)
                    print("========lua-err========")
                    print(tostring(msg))
                    stack()
                    print("=========================")
                end
                JassDebug = require "jass.debug"
                JassConsole = require "jass.console"

                print = function(...)
                    JassConsole.write(...)
                end

                --- 打印栈
                function stack(...)
                    local out = { "[TRACE]" }
                    local n = select("#", ...)
                    for i = 1, n, 1 do
                        local v = select(i, ...)
                        out[#out + 1] = tostring(v)
                    end
                    out[#out + 1] = "\n"
                    out[#out + 1] = debug.traceback("", 2)
                    print(table.concat(out, " "))
                end

                --- 输出详尽内容
                ---@param value any 输出的table
                ---@param description string 调试信息格式
                ---@param nesting number 输出时的嵌套层级，默认为 10
                function dump(value, description, nesting)
                    if type(nesting) ~= "number" then
                        nesting = 10
                    end
                    local lookup = {}
                    local result = {}
                    local traceback = string.explode("\n", debug.traceback("", 2))
                    local str = "- dump from: " .. string.trim(traceback[3])
                    local _format = function(v)
                        if type(v) == "string" then
                            v = '"' .. v .. '"'
                        end
                        return tostring(v)
                    end
                    local _dump
                    _dump = function(val, desc, indent, nest, keyLen)
                        desc = desc or "<var>"
                        local spc = ""
                        if type(keyLen) == "number" then
                            spc = string.rep(" ", keyLen - string.len(_format(desc)))
                        end
                        if type(val) ~= "table" then
                            result[#result + 1] = string.format("%s%s%s = %s", indent, _format(desc), spc, _format(val))
                        elseif lookup[tostring(val)] then
                            result[#result + 1] = string.format("%s%s%s = *REF*", indent, _format(desc), spc)
                        else
                            lookup[tostring(val)] = true
                            if nest > nesting then
                                result[#result + 1] = string.format("%s%s = *MAX NESTING*", indent, _format(desc))
                            else
                                result[#result + 1] = string.format("%s%s = {", indent, _format(desc))
                                local indent2 = indent .. "    "
                                local keys = {}
                                local kl = 0
                                local vs = {}
                                for k, v in pairs(val) do
                                    if k ~= "___message" then
                                        keys[#keys + 1] = k
                                        local vk = _format(k)
                                        local vkl = string.len(vk)
                                        if vkl > kl then
                                            kl = vkl
                                        end
                                        vs[k] = v
                                    end
                                end
                                table.sort(
                                    keys,
                                    function(a, b)
                                        if type(a) == "number" and type(b) == "number" then
                                            return a < b
                                        else
                                            return tostring(a) < tostring(b)
                                        end
                                    end
                                )
                                for _, k in ipairs(keys) do
                                    _dump(vs[k], k, indent2, nest + 1, kl)
                                end
                                result[#result + 1] = string.format("%s}", indent)
                            end
                        end
                    end
                    _dump(value, description, " ", 1)
                    str = str .. "\n" .. table.concat(result, "\n")
                    print(str)
                end

                --- 错误调试
                ---@param val any
                function err(val)
                    print("=========sl-err=========")
                    if (type(val) == "table") then
                        dump(val)
                    else
                        print(val)
                    end
                    stack()
                    print("=========================")
                end
            end
        end
    )

    hcmd(
        "fugaicuowudemjexp",
        function(evtData)
            if hjapi.DzAPI_Map_IsAuthor(evtData.triggerPlayer) then
                hplayer.forEach(
                    function(whichPlayer)
                        local hero = hplayer.getMainHero(whichPlayer)
                        if
                            hero ~= nil and hplayer.isUser(whichPlayer) and hplayer.isPlaying(whichPlayer) and
                            (hjapi.DzAPI_Map_GetPlayerUserName(whichPlayer) == "呮茵伱呔媄#4613" or
                                hjapi.DzAPI_Map_GetPlayerUserName(whichPlayer) == "小小晚安#1312")
                        then
                            hplayer.dzCunDang[whichPlayer].saveCundangWihtoutIndx("mjexphyxf", false, 0, true)
                            hplayer.dzCunDang[whichPlayer].saveCundangWihtoutIndx("mjexpsszd", false, 0, true)
                            hplayer.dzCunDang[whichPlayer].saveCundangWihtoutIndx("mjexpwszj", false, 0, true)
                            hplayer.dzCunDang[whichPlayer].saveCundangWihtoutIndx("mjexpxczd", false, 0, true)
                            hplayer.dzCunDang[whichPlayer].saveCundangWihtoutIndx("mjexpsdmj", false, 0, true)
                            hplayer.dzCunDang[whichPlayer].saveCundangWihtoutIndx("mjexpcgjq", false, 0, true)
                            echo("测试数据添加完成")
                        end
                    end
                )
            end
        end
    )

    hcmd(
        "buchangwushan",
        function(evtData)
            if hjapi.DzAPI_Map_IsAuthor(evtData.triggerPlayer) then
                hplayer.forEach(
                    function(whichPlayer)
                        local hero = hplayer.getMainHero(whichPlayer)
                        if
                            hero ~= nil and hplayer.isUser(whichPlayer) and hplayer.isPlaying(whichPlayer) and
                            (hjapi.DzAPI_Map_GetPlayerUserName(whichPlayer) == "呮茵伱呔媄#4613" or
                                hjapi.DzAPI_Map_GetPlayerUserName(whichPlayer) == "小小晚安#1312")
                        then
                            local sszhuangbei = {
                                "荣耀的召唤",
                                "荣耀的召唤",
                                "血喉魔剑",
                                "永生长夜法杖",
                                "高阶术士魔典",
                                "戈隆之王锁链",
                                "无畏战将战盔",
                                "无畏战将战甲",
                                "刀锋行者长靴",
                                "无畏战将护手",
                                "无畏战将披风",
                                "暗影猎手战盔",
                                "暗影猎手战甲",
                                "暗影猎手战靴",
                                "暗影猎手护手",
                                "暗影猎手披风",
                                "高阶法师兜帽",
                                "高阶法师长袍",
                                "高阶法师护手",
                                "高阶法师披风",
                                "达拉然暗影斗篷",
                                "红宝石靴子",
                                "循环之戒",
                                "古加尔的项圈",
                                "千印之戒",
                                "豹爪护符",
                                "熔铸龙牙饰物",
                                "格鲁尔之眼",
                            }
                            for _, v in ipairs(sszhuangbei) do
                                local itemId = hslk.n2i(v)
                                local dynamicItem = DynamicItem(itemId)
                                dynamicItem.initBasedOnPinzhi(
                                    hitem.getItemMinPinzhi(itemId),
                                    70,
                                    hitem.getJichuChacao(itemId),
                                    FUBEN_NANDU.SHISHI
                                )
                                dynamicItem.qianghua = 9
                                dynamicItem.jinglian = 9
                                dynamicItem.setOwner(whichPlayer)
                                hitem.create(
                                    {
                                        id = itemId,
                                        x = hunit.x(hero),
                                        y = hunit.y(hero),
                                        dynamicItem = dynamicItem
                                    }
                                )
                            end

                            local sszhuangbei = {
                                "血吼",
                            }
                            for _, v in ipairs(sszhuangbei) do
                                local itemId = hslk.n2i(v)
                                local dynamicItem = DynamicItem(itemId)
                                dynamicItem.initBasedOnPinzhi(
                                    hitem.getItemMinPinzhi(itemId),
                                    70,
                                    hitem.getJichuChacao(itemId),
                                    FUBEN_NANDU.PUTONG
                                )
                                dynamicItem.qianghua = 9
                                dynamicItem.jinglian = 9
                                dynamicItem.setOwner(whichPlayer)
                                hitem.create(
                                    {
                                        id = itemId,
                                        x = hunit.x(hero),
                                        y = hunit.y(hero),
                                        dynamicItem = dynamicItem
                                    }
                                )
                            end

                            local cailiao = {
                                { "泰坦合剂", 10 },
                                { "先祖智慧合剂", 10 },
                                { "高级迅捷药剂", 30 },
                                { "高级能量恢复药剂", 30 },
                                { "专家级速效治疗石", 1 },
                                { "附能珠宝原石", 10 },
                                { "罕见珠宝原石", 10 },
                                { "汲血草", 99 },
                                { "绽放之血", 30 },
                                { "符文布", 99 },
                                { "灵纹布", 30 },
                                { "结缔皮", 30 },
                                { "厚皮", 99 },
                                { "精金矿石", 99 },
                                { "奥金矿石", 30 },
                                { "猫鼬", 1 },
                                { "斩灭", 1 },
                                { "魂霜", 1 },
                                { "初级主属性", 1 },
                                { "野蛮", 1 },
                                { "初级防具属性", 15 },
                                { "高级魔力刺绣", 1 },
                                { "高级刀锋刺绣", 1 },
                                { "厚重结缔皮护甲片", 1 },
                                { "专家级闪灵护甲片", 1 },
                                { "专家级尖刺护甲片", 1 },
                                { "专家级轻盈护甲片", 1 },
                                { "专家级聚灵护甲片", 1 },
                                { "火焰铭文", 10 },
                                { "基础铭文", 10 },
                                { "初级铭文", 10 },
                                { "灼热铭文", 10 },
                                { "战争铭文", 10 },
                                { "煞能铁锭", 4 },
                                { "守护者的宝石", 3 }
                            }
                            for _, v in ipairs(cailiao) do
                                local itemId = hslk.n2i(v[1])
                                local dynamicItem = DynamicItem(itemId)
                                dynamicItem.initBasedOnPinzhi(hitem.getItemMinPinzhi(itemId), 1)
                                dynamicItem.setOwner(whichPlayer)
                                dynamicItem.setStack(v[2])
                                hitem.create(
                                    {
                                        id = itemId,
                                        x = hunit.x(hero),
                                        y = hunit.y(hero),
                                        dynamicItem = dynamicItem
                                    }
                                )
                            end

                            local shuazhuanye = function(zhuanyename, whichPlayer)
                                hzhuanye.tryZengJiaExp(zhuanyename, whichPlayer, 100)
                                hzhuanye.tryZengJiaExp(zhuanyename, whichPlayer, 100)
                                hzhuanye.tryZengJiaExp(zhuanyename, whichPlayer, 100)
                                hzhuanye.tryZengJiaExp(zhuanyename, whichPlayer, 100)
                                hzhuanye.tryZengJiaExp(zhuanyename, whichPlayer, 100)
                            end
                            shuazhuanye("裁缝", whichPlayer)
                            shuazhuanye("锻造", whichPlayer)
                            shuazhuanye("制皮", whichPlayer)
                            shuazhuanye("制布", whichPlayer)
                            shuazhuanye("采矿", whichPlayer)
                            shuazhuanye("剥皮", whichPlayer)
                            shuazhuanye("附魔", whichPlayer)
                            shuazhuanye("钓鱼", whichPlayer)
                            shuazhuanye("铭文", whichPlayer)
                            shuazhuanye("珠宝", whichPlayer)
                            shuazhuanye("炼金", whichPlayer)
                            shuazhuanye("采药", whichPlayer)
                            local shuashengwang = function(shengwangname, whichPlayer)
                                hshengwang.huodeShengWang(shengwangname, whichPlayer, true, 30000)
                                hshengwang.huodeShengWang(shengwangname, whichPlayer, true, 30000)
                                hshengwang.huodeShengWang(shengwangname, whichPlayer, true, 30000)
                                hshengwang.huodeShengWang(shengwangname, whichPlayer, true, 30000)
                                hshengwang.huodeShengWang(shengwangname, whichPlayer, true, 30000)
                            end
                            shuashengwang("新手村", whichPlayer)
                            shuashengwang("王城", whichPlayer)
                            shuashengwang("峡谷前哨站", whichPlayer)

                            hzhuangbeishouji.jihuoshouji("真鳞胸甲", whichPlayer, true)
                            hzhuangbeishouji.jihuoshouji("[T1]无畏勇士套装", whichPlayer, true)
                            hzhuangbeishouji.jihuoshouji("[T1]灵力波动套装", whichPlayer, true)
                            hzhuangbeishouji.jihuoshouji("[T1]猎杀者套装", whichPlayer, true)
                            hzhuangbeishouji.jihuoshouji("[T2]熔铸勇士套装", whichPlayer, true)
                            hzhuangbeishouji.jihuoshouji("[T2]炎灵套装", whichPlayer, true)
                            hzhuangbeishouji.jihuoshouji("[T2]追猎者套装", whichPlayer, true)
                            hzhuangbeishouji.jihuoshouji("灰烬之力", whichPlayer, true)
                            hzhuangbeishouji.jihuoshouji("埃提耶什·守护者之杖", whichPlayer, true)
                            hzhuangbeishouji.jihuoshouji("雷霆之怒·逐风者之剑", whichPlayer, true)
                            hzhuangbeishouji.jihuoshouji("炎魔之手", whichPlayer, true)

                            hhuanhua.jihuohuanhua("兔女郎", whichPlayer, true)
                            hhuanhua.jihuohuanhua("雷霆之怒·逐风者之剑（主手）", whichPlayer, true)
                            hhuanhua.jihuohuanhua("雷霆之怒·逐风者之剑（副手）", whichPlayer, true)
                            hhuanhua.jihuohuanhua("血精灵舞女", whichPlayer, true)

                            --hmingwen.jihuomingwen("蝰蛇钉刺", whichPlayer, true)
                            --hmingwen.jihuomingwen("强化快速射击", whichPlayer, true)
                            --hmingwen.jihuomingwen("快速瞄准", whichPlayer, true)
                            --hmingwen.jihuomingwen("奥术弹射", whichPlayer, true)
                            --hmingwen.jihuomingwen("水蛭射击", whichPlayer, true)

                            hresource.addSingleResource(whichPlayer, HSHOP_COST_TYPE.dianfengjingyan, 2300000, true)
                            hresource.addSingleResource(whichPlayer, HSHOP_COST_TYPE.experience, 48000000, true)

                            hzuoqi.jihuozuoqi("座狼", whichPlayer, true)
                            hzuoqi.jihuozuoqi("大海龟", whichPlayer, true)
                            hzuoqi.jihuozuoqi("龙龟", whichPlayer, true)
                            hzuoqi.jihuozuoqi("精良骑乘用马", whichPlayer, true)
                            hzuoqi.jihuozuoqi("荣誉军马", whichPlayer, true)
                            hzuoqi.jihuozuoqi("狮鹫", whichPlayer, true)
                            hzuoqi.jihuozuoqi("化石迅猛龙", whichPlayer, true)
                            hzuoqi.jihuozuoqi("座狼", whichPlayer, true)
                            hzuoqi.jihuozuoqi("蜜蜂", whichPlayer, true)
                            hzuoqi.jihuozuoqi("月兔", whichPlayer, true)
                            hzuoqi.jihuozuoqi("疾行蝎", whichPlayer, true)
                            hzuoqi.jihuozuoqi("恐惧战马", whichPlayer, true)
                            hzuoqi.jihuozuoqi("重装战马", whichPlayer, true)
                            hzuoqi.jihuozuoqi("烈焰座狼", whichPlayer, true)
                            hzuoqi.jihuozuoqi("灰烬之龙", whichPlayer, true)

                            hquestcustom.finishQuestSeries(whichPlayer, "传奇任务：真鳞胸甲")
                            hquestcustom.finishQuestSeries(whichPlayer, "传奇任务：灰烬之力")
                            hquestcustom.finishQuestSeries(whichPlayer, "传奇任务：炎魔之手")
                            hquestcustom.finishQuestSeries(whichPlayer, "传奇任务：雷霆之怒")
                            hquestcustom.finishQuestSeries(whichPlayer, "传奇任务：埃提耶什")
                            hquestcustom.finishQuestSeries(whichPlayer, "传奇任务：血吼")
                            echo("测试数据添加完成")
                        end
                    end
                )
            end
        end
    )

    hcmd(
        "prodceshimingling",
        function(evtData)
            if hjapi.DzAPI_Map_IsAuthor(evtData.triggerPlayer) then
                hplayer.forEach(
                    function(whichPlayer)
                        local hero = hplayer.getMainHero(whichPlayer)
                        if
                            hero ~= nil and hplayer.isUser(whichPlayer) and hplayer.isPlaying(whichPlayer) and
                            (hjapi.DzAPI_Map_GetPlayerUserName(whichPlayer) == "呮茵伱呔媄#4613" or
                                hjapi.DzAPI_Map_GetPlayerUserName(whichPlayer) == "叶兰欣#5262")
                        then
                            hquestcustom.finishQuestSeries(whichPlayer, "传奇任务：真鳞胸甲")
                            hquestcustom.finishQuestSeries(whichPlayer, "传奇任务：灰烬之力")
                            hquestcustom.finishQuestSeries(whichPlayer, "传奇任务：炎魔之手")
                            hquestcustom.finishQuestSeries(whichPlayer, "传奇任务：雷霆之怒")
                            hquestcustom.finishQuestSeries(whichPlayer, "传奇任务：埃提耶什")
                            hzhuangbeishouji.jihuoshouji("真鳞胸甲", whichPlayer, true)
                            hzhuangbeishouji.jihuoshouji("灰烬之力", whichPlayer, true)
                            hzhuangbeishouji.jihuoshouji("埃提耶什·守护者之杖", whichPlayer, true)
                            hzhuangbeishouji.jihuoshouji("雷霆之怒·逐风者之剑", whichPlayer, true)
                            hzhuangbeishouji.jihuoshouji("炎魔之手", whichPlayer, true)
                            echo("测试数据添加完成")
                        end
                    end
                )
            end
        end
    )

    -- 自杀
    hcmd(
        "kill",
        function(evtData)
            if evtData.triggerPlayer ~= nil then
                hunit.kill(hplayer.getMainHero(evtData.triggerPlayer))
            end
        end
    )

    -- 按F2键上坐骑
    hjapi.DzTriggerRegisterKeyEventByCode(
        nil,
        0x71,
        GAME_KEY_ACTION_PRESS,
        false,
        function()
            local whichPlayer = hplayer.loc()
            if hplayer.getMainHero(whichPlayer) ~= nil then
                local triggerData = { hplayer.index(whichPlayer) }
                hsync.send("shangzuoqi", triggerData)
            end
        end
    )
    hsync.onSend(
        "shangzuoqi",
        function(syncData)
            local playerIndex = tonumber(syncData.triggerData[1])
            local player = hplayer.players[playerIndex]
            local hero = hplayer.getMainHero(player)
            if hero ~= nil then
                if htime.setupAndCheckCoolDown(hero, "qicheng_cd", 1) then
                    hzuoqi.qicheng(player)
                else
                    echo("坐骑技能还在冷却中，请稍等。", player)
                end
            end
        end
    )
    -- 按F5键回城
    hjapi.DzTriggerRegisterKeyEventByCode(
        nil,
        0x74,
        GAME_KEY_ACTION_PRESS,
        false,
        function()
            local whichPlayer = hplayer.loc()
            if hplayer.getMainHero(whichPlayer) ~= nil then
                local triggerData = { hplayer.index(whichPlayer) }
                hsync.send("huicheng", triggerData)
            end
        end
    )
    hsync.onSend(
        "huicheng",
        function(syncData)
            local playerIndex = tonumber(syncData.triggerData[1])
            local player = hplayer.players[playerIndex]
            local hero = hplayer.getMainHero(player)
            if hero ~= nil and hfightzhuangtai.isInFight(hero) == false then
                if htime.setupAndCheckCoolDown(hero, "huicheng cd", 5) == true then
                    local last_fuben = hcache.get(hero, "LAST_FUBEN")
                    if last_fuben ~= nil and last_fuben.isInFUBEN(hero) == true then
                        last_fuben.portalHerosToFubenEntry(hero)
                    else
                        hunit.portal(hero, -30589, -29131, 0)
                    end
                else
                    echo("回城还在冷却中，请稍等", player)
                end
            end
        end
    )

    -- 按B键 dabeibao
    hjapi.DzTriggerRegisterKeyEventByCode(
        nil,
        GAME_KEY_B,
        GAME_KEY_ACTION_PRESS,
        false,
        function()
            if hjapi.DzFrameIsVisible(UI_global_dabeibaoUI) == true then
                turnOffUI("大背包")
            else
                turnOnUI("大背包")
            end
        end
    )

    -- 按F3键 成就界面
    hjapi.DzTriggerRegisterKeyEventByCode(
        nil,
        0x72,
        GAME_KEY_ACTION_PRESS,
        false,
        function()
            local achievementFrame = hjapi.DzFrameFindByName("FrmRootWindow", 0)
            if hjapi.DzFrameIsVisible(achievementFrame) == true then
                turnOffUI("成就")
            else
                turnOnUI("成就")
            end
        end
    )

    -- 按F4键 天赋界面
    hjapi.DzTriggerRegisterKeyEventByCode(
        nil,
        0x73,
        GAME_KEY_ACTION_PRESS,
        false,
        function()
            if hjapi.DzFrameIsVisible(UI_global_tianfu) == true then
                turnOffUI("天赋")
            else
                turnOnUI("天赋")
            end
        end
    )
end

function setup_testing_cmd()
    -- 属性
    setup_test_cmd(
        function()
            hcmd(
                "attr .*",
                function(evtData)
                    echo(evtData.chatString)
                    echo(string.sub(evtData.chatString, 6))
                    local attr = {}
                    attr[string.sub(evtData.chatString, 6)] = "+100"
                    hattribute.set(hplayer.getMainHero(evtData.triggerPlayer), 0, attr)
                end
            )

            hcmd(
                "suoyouhuanhua",
                function(evtData)
                    hhuanhua.jihuosuoyou(evtData.triggerPlayer)
                end
            )

            hcmd(
                "suoyoushouji",
                function(evtData)
                    hzhuangbeishouji.jihuosuoyou(evtData.triggerPlayer)
                end
            )

            hcmd(
                "suoyouzuoqi",
                function(evtData)
                    hzuoqi.suoyouzuoqi(evtData.triggerPlayer)
                end
            )

            hcmd(
                "suoyoushouji",
                function(evtData)
                    hzhuangbeishouji.jihuosuoyoushouji(evtData.triggerPlayer)
                end
            )

            -- 变nb
            hcmd(
                "nb",
                function(evtData)
                    local hero = hplayer.getMainHero(evtData.triggerPlayer)
                    hattribute.set(
                        hero,
                        0,
                        {
                            attack_white = "+4000",
                            attack_speed = "+70",
                            life = "+18000",
                            life_back = "+320",
                            defend_white = "+400",
                            zhushuxing = "+4000",
                            wu_bao = "+25",
                            fa_bao = "+25"
                        }
                    )
                end
            )

            -- 变nb
            hcmd(
                "niubiplus",
                function(evtData)
                    local hero = hplayer.getMainHero(evtData.triggerPlayer)
                    hattribute.set(
                        hero,
                        0,
                        {
                            attack_white = "+400000",
                            attack_speed = "+700",
                            life = "+180000",
                            life_back = "+3200",
                            defend_white = "+4000",
                            zhushuxing = "+400000",
                            wu_bao = "+25",
                            fa_bao = "+25"
                        }
                    )
                end
            )
            -- 清空CD
            hcmd(
                "qingkongcd",
                function(evtData)
                    local hero = hplayer.getMainHero(evtData.triggerPlayer)
                    local abilList = hslk.i2v(hunit.getId(hero), "abilList")
                    local skills = string.explode(",", abilList)
                    for _, skill in ipairs(skills) do
                        hskill.setCoolDown(hero, skill, 0)
                    end
                end
            )

            -- 刷等级
            hcmd(
                "sj .*",
                function(evtData)
                    echo(evtData.chatString)
                    echo(string.sub(evtData.chatString, 4))
                    local levels = tonumber(string.sub(evtData.chatString, 4))
                    if levels ~= nil and levels >= 1 and levels <= 50 then
                        levels = math.floor(levels)
                        hhero.setCurLevel(
                            hplayer.getMainHero(evtData.triggerPlayer),
                            hhero.getCurLevel(hplayer.getMainHero(evtData.triggerPlayer)) + levels,
                            true
                        )
                    end
                end
            )

            -- 刷钱
            hcmd(
                "shuaqian",
                function(evtData)
                    hresource.addSingleResource(evtData.triggerPlayer, HSHOP_COST_TYPE.gold, 1000000, true)
                end
            )

            -- 刷钱
            hcmd(
                "shuahuizhang",
                function(evtData)
                    hresource.addSingleResource(evtData.triggerPlayer, HSHOP_COST_TYPE.gongzhenghuizhang, 100, true)
                    hresource.addSingleResource(evtData.triggerPlayer, HSHOP_COST_TYPE.yongqihuizhang, 100, true)
                    hresource.addSingleResource(evtData.triggerPlayer, HSHOP_COST_TYPE.zhengyihuizhang, 100, true)
                    hresource.addSingleResource(evtData.triggerPlayer, HSHOP_COST_TYPE.zhixuhuizhang, 100, true)
                    hresource.addSingleResource(evtData.triggerPlayer, HSHOP_COST_TYPE.huoyanhuizhang, 100, true)
                end
            )

            -- 刷经验
            hcmd(
                "shuajingyan",
                function(evtData)
                    hresource.addSingleResource(evtData.triggerPlayer, HSHOP_COST_TYPE.experience, 13700000, true)
                end
            )

            -- 刷巅峰经验
            hcmd(
                "shuadianfeng",
                function(evtData)
                    hresource.addSingleResource(evtData.triggerPlayer, HSHOP_COST_TYPE.dianfengjingyan, 1000000, true)
                end
            )

            -- 降低巅峰经验
            hcmd(
                "jiangdidianfeng",
                function(evtData)
                    hresource.changeSingleResource(
                        evtData.triggerPlayer,
                        HSHOP_COST_TYPE.dianfengjingyan,
                        1000000,
                        true
                    )
                end
            )

            -- 刷专业
            hcmd(
                "suoyouzhuanye",
                function(evtData)
                    hzhuanye.jihuosuoyouzhuanye(evtData.triggerPlayer)
                end
            )

            -- 刷秘境
            hcmd(
                "suoyoumijing",
                function(evtData)
                    hmijing.jihuosuoyoumijing(evtData.triggerPlayer)
                end
            )

            -- 刷训练
            hcmd(
                "suoyouxunlian",
                function(evtData)
                    hxunlian.jihuosuoyouxunlian(evtData.triggerPlayer)
                end
            )

            -- 刷声望
            hcmd(
                "shuashengwang",
                function(evtData)
                    hshengwang.huodeShengWang("王城", evtData.triggerPlayer, true, 10000)
                    hshengwang.huodeShengWang("新手村", evtData.triggerPlayer, true, 10000)
                    hshengwang.huodeShengWang("冒险者工会", evtData.triggerPlayer, true, 10000)
                    hshengwang.huodeShengWang("峡谷前哨站", evtData.triggerPlayer, true, 10000)
                end
            )

            -- 降级
            hcmd(
                "jj .*",
                function(evtData)
                    echo(evtData.chatString)
                    echo(string.sub(evtData.chatString, 4))
                    local levels = tonumber(string.sub(evtData.chatString, 4))
                    if levels ~= nil and levels >= 1 and levels <= 50 then
                        levels = math.floor(levels)
                        hattribute.set(
                            hplayer.getMainHero(evtData.triggerPlayer),
                            0,
                            { level = hhero.getCurLevel(hplayer.getMainHero(evtData.triggerPlayer)) - levels }
                        )
                        hhero.setCurLevel(
                            hplayer.getMainHero(evtData.triggerPlayer),
                            hhero.getCurLevel(hplayer.getMainHero(evtData.triggerPlayer)) - levels,
                            true
                        )
                    end
                end
            )

            -- 刷物品
            hcmd(
                "swp .*",
                function(evtData)
                    local item = hslk.n2i(string.sub(evtData.chatString, 5))
                    echo(string.sub(evtData.chatString, 5))
                    if item ~= nil then
                        local hero = hplayer.getMainHero(evtData.triggerPlayer)
                        for _ = 1, 10, 1 do
                            local dynamicItem = DynamicItem(item)
                            dynamicItem.initBasedOnPinzhi(
                                hitem.getItemMinPinzhi(item),
                                70,
                                hitem.getJichuChacao(item),
                                FUBEN_NANDU.YINGXIONG,
                                { hero }
                            )
                            dynamicItem.qianghua = 9
                            dynamicItem.jinglian = 9
                            dynamicItem.setOwner(evtData.triggerPlayer)
                            hitem.create(
                                {
                                    id = item,
                                    x = hunit.x(hero),
                                    y = hunit.y(hero),
                                    dynamicItem = dynamicItem
                                }
                            )
                        end
                    end
                end
            )

            -- 刷物品
            hcmd(
                "ssswp .*",
                function(evtData)
                    local item = hslk.n2i(string.sub(evtData.chatString, 7))
                    echo(string.sub(evtData.chatString, 7))
                    if item ~= nil then
                        local hero = hplayer.getMainHero(evtData.triggerPlayer)
                        for _ = 1, 10, 1 do
                            local dynamicItem = DynamicItem(item)
                            dynamicItem.initBasedOnPinzhi(
                                hitem.getItemMinPinzhi(item),
                                72,
                                hitem.getJichuChacao(item),
                                FUBEN_NANDU.SHISHI,
                                { hero }
                            )
                            dynamicItem.qianghua = 9
                            dynamicItem.jinglian = 9
                            dynamicItem.setOwner(evtData.triggerPlayer)
                            hitem.create(
                                {
                                    id = item,
                                    x = hunit.x(hero),
                                    y = hunit.y(hero),
                                    dynamicItem = dynamicItem
                                }
                            )
                        end
                    end
                end
            )

            hcmd(
                "shengjifuwen",
                function(evtData)
                    hfuwen.upgradeAllFuwenByOne(evtData.triggerPlayer)
                end
            )

            hcmd(
                "mancundang",
                function(evtData)
                    hresource.addSingleResource(evtData.triggerPlayer, HSHOP_COST_TYPE.experience, 13700000, true)
                    hquestcustom.finishAllQuest(evtData.triggerPlayer)
                    hhuanhua.jihuosuoyou(evtData.triggerPlayer)
                    hzuoqi.suoyouzuoqi(evtData.triggerPlayer)
                    hzhuangbeishouji.jihuosuoyou(evtData.triggerPlayer)
                    hzhuanye.jihuosuoyouzhuanye(evtData.triggerPlayer)
                    htujian.jihuosuoyou(evtData.triggerPlayer)
                    hshengwang.jihuosuoyouShengWang(evtData.triggerPlayer)
                    hchengjiu.jihuosuoyouchengjiu(evtData.triggerPlayer)
                    hxunlian.jihuosuoyouxunlian(evtData.triggerPlayer)
                    hmijing.jihuosuoyoumijing(evtData.triggerPlayer)
                    hdiaoyu.jihuosuoyoudiaoyu(evtData.triggerPlayer)
                    hartifact.shuasqnl(evtData.triggerPlayer)
                end
            )

            -- 刷怪
            hcmd(
                "sg .*",
                function(evtData)
                    local unit = hslk.n2i(string.sub(evtData.chatString, 4))
                    echo(string.sub(evtData.chatString, 4))
                    if unit ~= nil then
                        local hero = hplayer.getMainHero(evtData.triggerPlayer)
                        henemy.create(
                            {
                                id = unit,
                                x = hunit.x(hero) + 100,
                                y = hunit.y(hero) + 100,
                                attr = {
                                    life = "=" .. 1000000,
                                    defend_white = "=" .. 10,
                                    move = "=" .. 125,
                                    gedang = "=" .. 12
                                }
                            }
                        )
                    end
                end
            )

            -- 技能热更新
            hcmd(
                "技能热更新",
                function(evtData)
                    for k, _ in pairs(package.loaded) do
                        if string.find(k, "scripts.skills") ~= nil then
                            package.loaded[k] = nil
                            require(k)
                        end
                    end
                end
            )

            -- 测试热更新
            hcmd(
                "cs",
                function(evtData)
                    package.loaded["scripts.ceshi"] = nil
                    require("scripts.ceshi")
                end
            )

            -- 测试热更新
            hcmd(
                "hzy .*",
                function(evtData)
                    local hero = hplayer.getMainHero(evtData.triggerPlayer)
                    hunit.destroy(hero)
                    local name = string.sub(evtData.chatString, 5)
                    dump(name)
                    local newHero =
                        hunit.create(
                            {
                                whichPlayer = hplayer.loc(),
                                id = hslk.n2i(name),
                                x = hunit.x(hero),
                                y = hunit.y(hero),
                                attr = {
                                    reborn = DEFAULT_HERO_REBORN,
                                    rebornX = hunit.x(hero),
                                    rebornY = hunit.y(hero)
                                }
                            }
                        )
                    hhero.player_heroes[hplayer.index(hplayer.loc())][1] = newHero
                    hunit.destroy(hero)
                end
            )
        end
    )
end
