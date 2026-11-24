htianfu = { tianfuNameMap = {}, currentConfig = {} }

---
--- exampleConfig = {
---   "shejilie": {
---     {
---       tianfutype = "输出",
---       tianfu = {
---         {
---           {
---             name = "基础属性",
---             description = "增加主属性",
---             activePoints = 0,
---             cundangStr = "tianfu",
---             cundangIndex = "0"
---             effect = {
---               {
---                 description = "",
---                 action = CONST_EVENT.attr,
---                 effect = function(evtData) end
---               },
---               {
---                 description = "",
---                 action = CONST_EVENT.attr,
---                 effect = function(evtData) end
---               },
---               {
---                 description = "",
---                 action = CONST_EVENT.attr,
---                 effect = function(evtData) end
---               }
---             }
---           },
---           {},
---           {}
---         },
---         {{},{},{}}
---       }
---     },
---     {
---       tianfutype = "防御",
---       tianfu = {
---         {},
---         {}
---       }
---     },
---     {
---       tianfutype = "专精",
---       tianfu = {
---         {},
---         {}
---       }
---     },
---     {
---       tianfutype = "辅助",
---       tianfu = {
---         {},
---         {}
---       }
---     },
---   }
--- }
---

htianfu.init = function()
end
---  初始化天赋系统
---
htianfu.initPlayer = function(whichPlayer)
    htianfu.validateConfig(TIANFU_CONFIG)
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        err("玩家没有选择英雄")
        return
    end
    local hero_cundang_str = hslk.n2v(hunit.getName(hero), "zhiye_cundang_str")
    if hero_cundang_str == nil then
        err("没有zhiye_cundang_str")
        return
    end
    if TIANFU_CONFIG[hero_cundang_str] == nil then
        err("没有hero_cundang_str对应的config")
        return
    end
    htianfu[whichPlayer] = table.clone(TIANFU_CONFIG[hero_cundang_str])
    htianfu[whichPlayer].currentConfig = 1
    htianfu.initUI(htianfu[whichPlayer], whichPlayer)
    htianfu.loadcundang(whichPlayer)

    hsync.onSend(
        "tryjihuotianfu",
        function(syncData)
            local level1Idx = math.tointeger(syncData.triggerData[1])
            local level2Idx = math.tointeger(syncData.triggerData[2])
            local level3Idx = math.tointeger(syncData.triggerData[3])
            local whichPlayer = syncData.triggerPlayer
            htianfu.tryjihuotianfu(whichPlayer, level1Idx, level2Idx, level3Idx)
        end
    )
    hsync.onSend(
        "trydisabletianfu",
        function(syncData)
            local level1Idx = math.tointeger(syncData.triggerData[1])
            local level2Idx = math.tointeger(syncData.triggerData[2])
            local level3Idx = math.tointeger(syncData.triggerData[3])
            local whichPlayer = syncData.triggerPlayer
            htianfu.trydisabletianfu(whichPlayer, level1Idx, level2Idx, level3Idx)
        end
    )
    hsync.onSend(
        "switchTianfuConfig",
        function(syncData)
            local configNumber = math.tointeger(syncData.triggerData[1])
            local whichPlayer = syncData.triggerPlayer
            htianfu.switchTianfuConfig(whichPlayer, configNumber)
        end
    )

    hevent.register(
        hero,
        CONST_EVENT.customResourceChange,
        "dianfengjingyanhuoqutianfuinstruction",
        function(evtData)
            if evtData.type == HSHOP_COST_TYPE.dianfengjingyan then
                htianfu.updateTianfuInstructions(whichPlayer)
            end
        end
    )

    htianfu.tianfuNameMap[whichPlayer] = {}
    for level1Idx, tianfutypeConfig in ipairs(htianfu[whichPlayer]) do
        for level2Idx, tianfuRow in ipairs(tianfutypeConfig.tianfu) do
            for level3Idx, tianfu in ipairs(tianfuRow) do
                -- 检查是否已经存在同名天赋
                if htianfu.tianfuNameMap[whichPlayer][tianfu.name] then
                    error("错误: 存在重复的天赋名称 - " .. tianfu.name)
                else
                    -- 将tianfu对象添加到tianfuNameMap中
                    htianfu.tianfuNameMap[whichPlayer][tianfu.name] = tianfu
                end
            end
        end
    end
end

local function validateTianfuPreconditionsAfterRevoking(whichPlayer)
    -- 获取玩家的天赋配置
    local playerConfig = htianfu[whichPlayer]
    if not playerConfig then
        sysecho("错误：玩家没有初始化的天赋配置", whichPlayer)
        return false
    end

    local currentConfig = playerConfig
    local allPreconditionsMet = true

    -- 遍历所有天赋，验证前置条件
    for l1Idx, lv1Config in ipairs(currentConfig) do
        for l2Idx, lv2Config in ipairs(lv1Config.tianfu) do
            local pointsSpentInCurrentLevel2Before = 0
            local pointsSpentInOtherLevel2Before = 0

            -- 计算当前level2之前的天赋点数
            for i = 1, l2Idx - 1 do
                for _, preTianfu in ipairs(currentConfig[l1Idx].tianfu[i] or {}) do
                    pointsSpentInCurrentLevel2Before = pointsSpentInCurrentLevel2Before +
                        (preTianfu.activePoints[htianfu[whichPlayer].currentConfig] or 0)
                end
            end

            -- 计算其他level1Idx下，对应level2Idx之前的天赋点数
            for otherL1Idx, otherLv1Config in ipairs(currentConfig) do
                if otherL1Idx ~= l1Idx then
                    for i = 1, l2Idx - 1 do
                        for _, preTianfu in ipairs(otherLv1Config.tianfu[i] or {}) do
                            pointsSpentInOtherLevel2Before =
                                pointsSpentInOtherLevel2Before +
                                (preTianfu.activePoints[htianfu[whichPlayer].currentConfig] or 0)
                        end
                    end
                end
            end

            -- 验证每个天赋的前置条件，只验证有天赋点数的天赋
            for l3Idx, tianfu in ipairs(lv2Config) do
                if tianfu.activePoints and tianfu.activePoints[htianfu[whichPlayer].currentConfig] > 0 then
                    local requiredPointsForCurrentLevel2 = 5 * (l2Idx - 1)

                    if pointsSpentInCurrentLevel2Before < requiredPointsForCurrentLevel2 then
                        sysecho(string.format("天赋前置条件不满足: %d-%d-%d 在相同系列中。", l1Idx, l2Idx, l3Idx), whichPlayer)
                        allPreconditionsMet = false
                    end

                    if pointsSpentInOtherLevel2Before < requiredPointsForCurrentLevel2 then
                        sysecho(string.format("天赋前置条件不满足: %d-%d-%d 在其他系列中。", l1Idx, l2Idx, l3Idx), whichPlayer)
                        allPreconditionsMet = false
                    end
                end
            end
        end
    end

    return allPreconditionsMet
end

function htianfu.updateTianfuInstructions(whichPlayer)
    if UI_global_tianfuinstruction and whichPlayer == hplayer.loc() then
        hjapi.DzFrameSetText(UI_global_tianfuinstruction, htianfu.getTianfuInstructions(whichPlayer))
    end
end

function htianfu.getDianfengdengji(whichPlayer)
    local dianfengjingyan = hresource.getResource(whichPlayer, HSHOP_COST_TYPE.dianfengjingyan)
    local level = 0

    if dianfengjingyan >= 10000000 then
        level = 40 + math.floor((dianfengjingyan - 10000000) / 1000000)
    elseif dianfengjingyan >= 6000000 then
        level = 30 + math.floor((dianfengjingyan - 6000000) / 400000)
    elseif dianfengjingyan >= 3000000 then
        level = 20 + math.floor((dianfengjingyan - 3000000) / 300000)
    elseif dianfengjingyan >= 1000000 then
        level = 10 + math.floor((dianfengjingyan - 1000000) / 200000)
    else
        level = math.floor(dianfengjingyan / 100000)
    end

    return level
end

function htianfu.getDianfengjingyanAtCurrentLevel(whichPlayer)
    local dianfengjingyan = hresource.getResource(whichPlayer, HSHOP_COST_TYPE.dianfengjingyan)
    local currentExp = 0

    if dianfengjingyan >= 10000000 then
        currentExp = math.floor((dianfengjingyan - 6000000) % 1000000)
    elseif dianfengjingyan >= 6000000 then
        currentExp = math.floor((dianfengjingyan - 6000000) % 400000)
    elseif dianfengjingyan >= 3000000 then
        currentExp = math.floor((dianfengjingyan - 3000000) % 300000)
    elseif dianfengjingyan >= 1000000 then
        currentExp = math.floor((dianfengjingyan - 1000000) % 200000)
    else
        currentExp = math.floor(dianfengjingyan % 100000)
    end

    return currentExp
end

function htianfu.getTianfuInstructions(whichPlayer)
    local level = htianfu.getDianfengdengji(whichPlayer)
    local currentExp = htianfu.getDianfengjingyanAtCurrentLevel(whichPlayer)
    local levelUpExp = 0
    if level >= 40 then
        levelUpExp = 1000000
    elseif level >= 30 then
        levelUpExp = 400000
    elseif level >= 20 then
        levelUpExp = 300000
    elseif level >= 10 then
        levelUpExp = 200000
    else
        levelUpExp = 100000
    end
    local msg = "巅峰等级：" .. hcolor.green(tostring(level)) .. "（升级经验：" .. currentExp .. "/" .. levelUpExp .. "）|n"
    msg =
        msg .. "每一级巅峰等级获得一点巅峰天赋点数, 当前可用天赋点数：" .. hcolor.green(tostring(htianfu.getAvailableTianfu(whichPlayer))) .. "|n"
    msg = msg .. "巅峰经验可以通过杀怪，任务等途径获得。杀怪获得巅峰经验概率为5%。"
    return msg
end

function htianfu.getAvailableTianfu(whichPlayer)
    local level = htianfu.getDianfengdengji(whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    local additionDianfeng = hattr.get(hero, "extra_dianfeng", 0)
    return level + additionDianfeng - htianfu.getUsedTianfu(whichPlayer)
end

function htianfu.getUsedTianfu(whichPlayer)
    -- 获取玩家的天赋配置
    local playerConfig = htianfu[whichPlayer]
    if not playerConfig then
        sysecho("错误：玩家没有初始化的天赋配置", whichPlayer)
        return 0 -- 如果玩家配置不存在，返回0表示没有使用天赋点
    end

    local totalUsedPoints = 0

    -- 遍历所有天赋系列和层级
    for _, lv1Config in ipairs(playerConfig) do
        if lv1Config.tianfu then -- 确保天赋配置存在
            for _, lv2Config in ipairs(lv1Config.tianfu) do
                for _, tianfu in ipairs(lv2Config) do
                    if tianfu.activePoints then
                        totalUsedPoints = totalUsedPoints + tianfu.activePoints[htianfu[whichPlayer].currentConfig]
                    end
                end
            end
        end
    end

    return totalUsedPoints
end

function htianfu.resetTianfu(whichPlayer, skipCheck)
    if skipCheck ~= true and validateTianfuPreconditionsAfterRevoking(whichPlayer) ~= true then
        sysecho("当前天赋没有异常，重置失败。", whichPlayer)
        return
    end
    -- 获取玩家的天赋配置
    local playerConfig = htianfu[whichPlayer]
    if not playerConfig then
        sysecho("错误：玩家没有初始化的天赋配置", whichPlayer)
        return 0 -- 如果玩家配置不存在，返回0表示没有使用天赋点
    end

    -- 遍历所有天赋系列和层级
    for level1Idx, lv1Config in ipairs(playerConfig) do
        if lv1Config.tianfu then -- 确保天赋配置存在
            for level2Idx, lv2Config in ipairs(lv1Config.tianfu) do
                for level3Idx, tianfu in ipairs(lv2Config) do
                    if tianfu.activePoints and tianfu.activePoints[htianfu[whichPlayer].currentConfig] > 0 then
                        tianfu.activePoints[htianfu[whichPlayer].currentConfig] = 0
                        htianfu.updateUI(whichPlayer, tianfu, level1Idx, level2Idx, level3Idx)
                        htianfu.cundang(whichPlayer, tianfu)
                    end
                end
            end
        end
    end
    sysecho("当前天赋已重置", whichPlayer)
end

function htianfu.validateConfig(config)
    for hero_cundang_str, heroConfig --[[validated]] in pairs(config) do
        local indexCheck = {} -- 每个英雄的配置开始时重置检查器
        for _, levelconfig in ipairs(heroConfig) do
            for _, rowconfig in ipairs(levelconfig.tianfu) do
                for _, tianfu in ipairs(rowconfig) do
                    -- 验证参数类型
                    assert(type(tianfu.name) == "string", hero_cundang_str .. " 的 name 必须被设置且为字符串")
                    assert(type(tianfu.description) == "string", hero_cundang_str .. " 的 description 必须被设置且为字符串")
                    assert(type(tianfu.activePoints) == "table", hero_cundang_str .. " 的 activePoints 必须是一个表")
                    assert(type(tianfu.cundangStr) == "string", hero_cundang_str .. " 的 cundangStr 必须被设置且为字符串")
                    assert(
                        type(tianfu.cundangIndex) == "number" and tianfu.cundangIndex % 1 == 0,
                        hero_cundang_str .. " 的 cundangIndex 必须是整数"
                    )
                    assert(type(tianfu.art) == "string", "art 必须被设置且为字符串")

                    -- 在当前英雄的配置内部检查 cundangStr 和 cundangIndex 的组合是否唯一
                    local indexKey = tianfu.cundangStr .. "_" .. tianfu.cundangIndex
                    assert(not indexCheck[indexKey], hero_cundang_str .. " 中对于同一个cundangStr, cundangIndex 必须唯一")
                    indexCheck[indexKey] = true
                end
            end
        end
    end
end

function htianfu.initUI(config, whichPlayer)
    if hplayer.loc() == whichPlayer then
        local activeButton = nil
        UI_global_tianfu = hjapi.DzCreateFrameByTagName("FRAME", "tianfu", hjapi.DzGetGameUI(), "", 0)

        local tianfuinstructionsback =
            hjapi.DzCreateFrameByTagName("BACKDROP", "tianfuinstructionsback", UI_global_tianfu, "", 0)
        hjapi.DzFrameSetPoint(
            tianfuinstructionsback,
            FRAME_ALIGN_CENTER,
            hjapi.DzGetGameUI(),
            FRAME_ALIGN_CENTER,
            0,
            -0.13
        )
        hjapi.DzFrameSetSize(tianfuinstructionsback, 0.4, 0.05)
        hjapi.DzFrameSetTexture(tianfuinstructionsback, "UI\\ShopPage.tga")
        hjapi.DzFrameShow(tianfuinstructionsback, true)

        local tianfuinstructions =
            hjapi.DzCreateFrameByTagName("TEXT", "tianfuinstructions", tianfuinstructionsback, "", 0)
        hjapi.DzFrameSetFont(tianfuinstructions, "war3mapImported\\fonts.ttf", 0.013, 0)

        --hjapi.DzFrameSetTextAlignment(tianfuinstructions, FRAME_ALIGN_CENTER)
        --hjapi.DzFrameSetTextColor(tianfuinstructions, hjapi.DzGetColor(255, 255, 255, 255))
        --hjapi.DzFrameSetFont(tianfuinstructions, "Fonts\\DFHeiMd.ttf", 0.01, 0)
        hjapi.DzFrameSetPoint(
            tianfuinstructions,
            FRAME_ALIGN_LEFT_TOP,
            tianfuinstructionsback,
            FRAME_ALIGN_LEFT_TOP,
            0.005,
            -0.005
        )
        hjapi.DzFrameSetPoint(
            tianfuinstructions,
            FRAME_ALIGN_RIGHT_BOTTOM,
            tianfuinstructionsback,
            FRAME_ALIGN_RIGHT_BOTTOM,
            -0.005,
            0.005
        )

        hjapi.DzFrameSetText(tianfuinstructions, htianfu.getTianfuInstructions(whichPlayer))
        --hjapi.DzFrameSetTextColor(tianfuinstructions, hjapi.DzGetColor(255, 255, 255, 1))
        hjapi.DzFrameShow(tianfuinstructions, true)
        UI_global_tianfuinstruction = tianfuinstructions

        for level1Idx, tianfutypeConfig in ipairs(config) do
            local wide = 0.16
            local height = 0.33
            local widegap = 0.01
            local leftmargin = 0.065
            local topmargin = -0.07
            local tianfuback =
                hjapi.DzCreateFrameByTagName("BACKDROP", "tianfuback" .. level1Idx, UI_global_tianfu, "", 0)
            hjapi.DzFrameSetPoint(
                tianfuback,
                0,
                hjapi.DzGetGameUI(),
                0,
                leftmargin + (wide + widegap) * (level1Idx - 1),
                topmargin
            )
            hjapi.DzFrameSetSize(tianfuback, wide, height)
            hjapi.DzFrameSetTexture(tianfuback, "UI\\ShopPage.tga")
            hjapi.DzFrameShow(tianfuback, true)

            local tianfutype = hjapi.DzCreateFrameByTagName("TEXT", "tianfutype" .. level1Idx, tianfuback, "", 0)
            hjapi.DzFrameSetPoint(tianfutype, 1, tianfuback, 1, 0, -0.005)
            hjapi.DzFrameSetSize(tianfutype, 0.02, 0.03)
            hjapi.DzFrameSetText(tianfutype, tianfutypeConfig.tianfutype)
            hjapi.DzFrameSetTextColor(tianfutype, hjapi.DzGetColor(255, 255, 255, 255))
            hjapi.DzFrameShow(tianfutype, true)

            for level2Idx, tianfutype in ipairs(tianfutypeConfig.tianfu) do
                local numLevel3 = #(tianfutype)
                local startX = 0
                local singleTianfuWidth = 0.0210
                local singleTianfuHeight = 0.0280
                local widegaplevel3 = 0.008
                local heightgaplevel2 = 0.009
                if numLevel3 == 1 then
                    startX = wide / 2 - singleTianfuWidth / 2
                elseif numLevel3 == 2 then
                    startX = wide / 2 - widegaplevel3 / 2 - singleTianfuWidth
                elseif numLevel3 == 3 then
                    startX = wide / 2 - widegaplevel3 - singleTianfuWidth * 1.5
                end
                local startY = -0.03 - (level2Idx - 1) * (heightgaplevel2 + singleTianfuHeight)
                for level3Idx, tianfu in ipairs(tianfutype) do
                    --buff图标
                    local singleTianfuBack =
                        hjapi.DzCreateFrameByTagName(
                            "BACKDROP",
                            "singleTianfuBack" .. level1Idx .. "|" .. level2Idx .. "|" .. level3Idx,
                            tianfuback,
                            "",
                            0
                        )
                    hjapi.DzFrameSetPoint(
                        singleTianfuBack,
                        FRAME_ALIGN_LEFT_TOP,
                        tianfuback,
                        FRAME_ALIGN_LEFT_TOP,
                        startX + (singleTianfuWidth + widegaplevel3) * (level3Idx - 1),
                        startY
                    )
                    hjapi.DzFrameSetSize(singleTianfuBack, singleTianfuWidth, singleTianfuHeight)
                    hjapi.DzFrameSetTexture(singleTianfuBack, tianfu.art)
                    hjapi.DzFrameShow(singleTianfuBack, true)

                    --buff图标 MASK
                    local singleTianfuMask =
                        hjapi.DzCreateFrameByTagName(
                            "BACKDROP",
                            "singleTianfuMask" .. level1Idx .. "|" .. level2Idx .. "|" .. level3Idx,
                            singleTianfuBack,
                            "",
                            0
                        )
                    tianfu.ui_mask = singleTianfuMask
                    hjapi.DzFrameSetPoint(
                        singleTianfuMask,
                        FRAME_ALIGN_CENTER,
                        singleTianfuBack,
                        FRAME_ALIGN_CENTER,
                        0,
                        0
                    )
                    hjapi.DzFrameSetSize(singleTianfuMask, singleTianfuWidth, singleTianfuHeight)
                    hjapi.DzFrameSetTexture(singleTianfuMask, "UI\\AZAchieve\\mask.blp")
                    hjapi.DzFrameShow(singleTianfuMask, true)

                    --buff图标 MASK
                    local singleTianfuframe =
                        hjapi.DzCreateFrameByTagName(
                            "BACKDROP",
                            "singleTianfuframe" .. level1Idx .. "|" .. level2Idx .. "|" .. level3Idx,
                            singleTianfuBack,
                            "",
                            0
                        )
                    tianfu.singleTianfuframe = singleTianfuframe
                    hjapi.DzFrameSetPoint(
                        singleTianfuframe,
                        FRAME_ALIGN_CENTER,
                        singleTianfuBack,
                        FRAME_ALIGN_CENTER,
                        0,
                        0
                    )
                    hjapi.DzFrameSetSize(singleTianfuframe, singleTianfuWidth, singleTianfuHeight)
                    hjapi.DzFrameSetTexture(singleTianfuframe, "UI\\frame.tga")
                    hjapi.DzFrameShow(singleTianfuframe, true)

                    --天赋层数
                    local singleTianfuStack =
                        hjapi.DzCreateFrameByTagName(
                            "TEXT",
                            "singleTianfuStack" .. level1Idx .. "|" .. level2Idx .. "|" .. level3Idx,
                            singleTianfuBack,
                            "",
                            0
                        )
                    tianfu.ui_stack = singleTianfuStack
                    hjapi.DzFrameSetText(singleTianfuStack, "0/" .. #(tianfu.effect))
                    hjapi.DzFrameSetTextAlignment(singleTianfuStack, FRAME_ALIGN_CENTER)
                    hjapi.DzFrameSetTextColor(singleTianfuStack, hjapi.DzGetColor(255, 255, 255, 255))
                    hjapi.DzFrameSetFont(singleTianfuStack, "Fonts\\DFHeiMd.ttf", 0.009, 0)
                    hjapi.DzFrameSetPoint(
                        singleTianfuStack,
                        FRAME_ALIGN_TOP,
                        singleTianfuBack,
                        FRAME_ALIGN_BOTTOM,
                        0,
                        0
                    )
                    hjapi.DzFrameShow(singleTianfuStack, true)

                    --按钮
                    local singleTianfuButton =
                        hjapi.DzCreateFrameByTagName(
                            "BUTTON",
                            "singleTianfuButton" .. level1Idx .. "|" .. level2Idx .. "|" .. level3Idx,
                            singleTianfuBack,
                            "",
                            0
                        )
                    hjapi.DzFrameSetPoint(
                        singleTianfuButton,
                        FRAME_ALIGN_CENTER,
                        singleTianfuBack,
                        FRAME_ALIGN_CENTER,
                        0,
                        0
                    )
                    hjapi.DzFrameSetSize(singleTianfuButton, singleTianfuWidth, singleTianfuHeight)
                    hjapi.DzFrameShow(singleTianfuButton, true)

                    hjapi.DzFrameSetScriptByCode(
                        singleTianfuButton,
                        MOUSE_ORDER_ENTER,
                        function()
                            UI_GLOBAL_TIANFU_POSITION = { level1Idx, level2Idx, level3Idx }
                            local tip = htianfu.getDescription(tianfu, htianfu[hplayer.loc()].currentConfig)
                            local tipsBack = hjapi.DzFrameFindByName("TIANFU_Tips", 0)
                            local tipsText = hjapi.DzFrameFindByName("TIANFU_Tips_Desc", 0)
                            hjapi.DzFrameSetPriority(tipsBack, 0)
                            hjapi.DzFrameClearAllPoints(tipsText)
                            hjapi.DzFrameSetSize(tipsText, 0.1200, 0)
                            hjapi.DzFrameSetPoint(
                                tipsText,
                                FRAME_ALIGN_LEFT_TOP,
                                singleTianfuButton,
                                FRAME_ALIGN_RIGHT_BOTTOM,
                                0,
                                0
                            )
                            hjapi.DzFrameSetText(tipsText, tip)
                            hjapi.DzFrameShow(tipsBack, true)
                            activeButton = { level1Idx, level2Idx, level3Idx }
                        end,
                        false
                    )
                    hjapi.DzFrameSetScriptByCode(
                        singleTianfuButton,
                        MOUSE_ORDER_LEAVE,
                        function()
                            UI_GLOBAL_TIANFU_POSITION = nil
                            local tipsBack = hjapi.DzFrameFindByName("TIANFU_Tips", 0)
                            activeButton = nil
                            hjapi.DzFrameShow(tipsBack, false)
                        end,
                        false
                    )
                    hjapi.DzFrameSetScriptByCode(
                        singleTianfuButton,
                        MOUSE_ORDER_CLICK,
                        function()
                            hsync.send("tryjihuotianfu", { level1Idx, level2Idx, level3Idx })
                        end,
                        false
                    )
                end
            end
        end
        hjapi.DzFrameShow(UI_global_tianfu, false)
        hjapi.DzLoadToc("UI\\ui_tips.toc")
        local tipsFrame = hjapi.DzCreateFrame("TIANFU_Tips", hjapi.DzGetGameUI(), 0)
        local back = hjapi.DzFrameFindByName("TIANFU_Tips_Back", 0)
        local desc = hjapi.DzFrameFindByName("TIANFU_Tips_Desc", 0)
        hjapi.DzFrameSetPoint(back, 0, desc, 0, -0.009, 0.009)
        hjapi.DzFrameSetPoint(back, 8, desc, 8, 0.009, -0.009)
        hjapi.DzFrameShow(tipsFrame, false)

        hjapi.DzTriggerRegisterMouseEventByCode(
            nil,
            GAME_KEY_MOUSE_RIGHT,
            GAME_KEY_ACTION_RELEASE,
            false,
            function()
                if activeButton ~= nil then
                    hsync.send("trydisabletianfu", activeButton)
                end
            end
        )

        UI_global_tianfu_text = {}
        local function createTianfuButton(name, text, x, configNumber)
            local button = hjapi.FrameTag("BACKDROP", name, UI_global_tianfu)
            hjapi.DzFrameSetPoint(button, FRAME_ALIGN_TOP, hjapi.DzGetGameUI(), FRAME_ALIGN_TOP, x, -0.03)
            hjapi.DzFrameSetSize(button, 0.065, 0.032)
            hjapi.DzFrameSetTexture(button, "UI\\ShopPage.tga", 0)
            hjapi.DzFrameShow(button, true)

            local buttonText = hjapi.DzCreateFrameByTagName("TEXT", name .. "Text", button, "", 0)
            hjapi.DzFrameSetAllPoints(buttonText, button)
            hjapi.DzFrameSetText(buttonText, text)
            hjapi.DzFrameSetTextAlignment(buttonText, TEXT_ALIGN_CENTER)
            hjapi.DzFrameShow(buttonText, true)
            UI_global_tianfu_text[configNumber] = buttonText

            local buttonClickArea = hjapi.FrameTag("BUTTON", name .. "_button", button)
            hjapi.DzFrameSetAllPoints(buttonClickArea, button)
            hjapi.DzFrameShow(buttonClickArea, true)

            hjapi.DzFrameSetScriptByCode(
                buttonClickArea,
                MOUSE_ORDER_CLICK,
                function()
                    hsync.send("switchTianfuConfig", { configNumber })
                end,
                false
            )

            return buttonText
        end

        createTianfuButton("tianfuyi", "天赋一", -0.05, 1)
        createTianfuButton("tianfuer", "天赋二", 0.05, 2)
    end
end

htianfu.switchTianfuConfig    = function(whichPlayer, configNumber, skipCheck)
    sysecho("切换天赋配置", whichPlayer, configNumber)
    if configNumber ~= 1 and configNumber ~= 2 then
        sysecho("无效的天赋配置编号", whichPlayer)
        return
    end

    if skipCheck ~= true and htianfu[whichPlayer].currentConfig == configNumber then
        sysecho("已经是当前选择的天赋配置", whichPlayer)
        return
    end

    if skipCheck ~= true and hshangcheng.hasItem(whichPlayer, "双天赋") == false then
        sysecho("需要双天赋才能开启天赋切换", whichPlayer)
        return
    end

    -- 检查是否在战斗中
    local hero = hplayer.getMainHero(whichPlayer)
    if skipCheck ~= true and hfightzhuangtai.isInFight(hero) then
        sysecho("战斗中无法切换天赋配置", whichPlayer)
        return
    end

    if skipCheck ~= true and htime.setupAndCheckCoolDown(whichPlayer, "改变天赋配置CD", 10) ~= true then
        sysecho("天赋配置变动冷却中", whichPlayer)
        return
    end

    -- 重置所有天赋效果
    htianfu.resetAllTianfuEffects(whichPlayer)

    -- 切换配置
    htianfu[whichPlayer].currentConfig = configNumber

    if htianfu.getAvailableTianfu(whichPlayer) < 0 or validateTianfuPreconditionsAfterRevoking(whichPlayer) ~= true then
        sysecho("当前天赋点数异常，装载失败", whichPlayer)
        htianfu.resetTianfu(whichPlayer, true)
        return
    end

    -- 重新应用新配置的天赋效果
    htianfu.applyAllTianfuEffects(whichPlayer)

    if whichPlayer == hplayer.loc() then
        for i = 1, 10 do
            if UI_global_tianfu_text[i] ~= nil then
                if configNumber == i then
                    hjapi.DzFrameSetText(UI_global_tianfu_text[i], hcolor.green("天赋" .. i .. "（已激活）"))
                else
                    hjapi.DzFrameSetText(UI_global_tianfu_text[i], "天赋" .. i .. "（未激活）")
                end
            end
        end
    end

    sysecho("成功切换到天赋配置 " .. configNumber, whichPlayer)
end

-- 辅助函数：重置所有天赋效果
htianfu.resetAllTianfuEffects = function(whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    local playerConfig = htianfu[whichPlayer]
    for level1Idx, tianfutypeConfig in ipairs(playerConfig) do
        for level2Idx, tianfuRow in ipairs(tianfutypeConfig.tianfu) do
            for level3Idx, tianfu in ipairs(tianfuRow) do
                if tianfu.activePoints and tianfu.activePoints[htianfu[whichPlayer].currentConfig] > 0 then
                    for i = 1, tianfu.activePoints[htianfu[whichPlayer].currentConfig] do
                        local effect = tianfu.effect[i]
                        if effect.action == CONST_EVENT.attr then
                            hbuff.delete(
                                hero,
                                level1Idx .. "|" .. level2Idx .. "|" .. level3Idx .. "|" .. i
                            )
                        elseif effect.action ~= nil then
                            hevent.unregister(
                                hero,
                                effect.action,
                                level1Idx .. "|" .. level2Idx .. "|" .. level3Idx .. "|" .. i
                            )
                        end
                    end
                end
            end
        end
    end
end

-- 辅助函数：应用所有天赋效果
htianfu.applyAllTianfuEffects = function(whichPlayer)
    local config = htianfu[whichPlayer]
    local currentConfig = htianfu[whichPlayer].currentConfig
    for level1Idx, tianfutypeConfig in ipairs(config) do
        for level2Idx, tianfuRow in ipairs(tianfutypeConfig.tianfu) do
            for level3Idx, tianfu in ipairs(tianfuRow) do
                for i = 1, (tianfu.activePoints[currentConfig] or 0) do
                    local effect = tianfu.effect[i]
                    if effect.action == CONST_EVENT.attr then
                        hbuff.addAttribute(
                            CONST_DAMAGE_SRC.item,
                            hplayer.getMainHero(whichPlayer),
                            level1Idx .. "|" .. level2Idx .. "|" .. level3Idx .. "|" .. i,
                            effect.effect,
                            0
                        )
                    elseif effect.action ~= nil then
                        hevent.register(
                            hplayer.getMainHero(whichPlayer),
                            effect.action,
                            level1Idx .. "|" .. level2Idx .. "|" .. level3Idx .. "|" .. i,
                            effect.effect
                        )
                    end
                end
                htianfu.updateUI(whichPlayer, tianfu, level1Idx, level2Idx, level3Idx)
            end
        end
    end
end

htianfu.isTianfuAddable       = function(whichPlayer, level1Idx, level2Idx, level3Idx)
    -- 获取玩家英雄等级
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil or hunit.getLevel(hero) < 50 then
        return false
    end

    if htianfu.getAvailableTianfu(whichPlayer) <= 0 then
        return false
    end
    -- 获取玩家当前的天赋配置
    local currentConfig = htianfu[whichPlayer].currentConfig
    local playerConfig = htianfu[whichPlayer]
    if not playerConfig then
        return false
    end

    local tianfutypeConfig = playerConfig[level1Idx]
    if
        not tianfutypeConfig or not tianfutypeConfig.tianfu[level2Idx] or
        not tianfutypeConfig.tianfu[level2Idx][level3Idx]
    then
        return false
    end

    local tianfu = tianfutypeConfig.tianfu[level2Idx][level3Idx]
    if tianfu.effect == nil then
        return false
    end
    if tianfu.activePoints[currentConfig] >= #(tianfu.effect) then
        return false
    end

    local requiredPointsForCurrentLevel2 = 5 * (level2Idx - 1) -- 当前level2天赋的前置点数需求
    local pointsSpentInCurrentLevel2Before = 0                 -- 当前level2之前的天赋已消耗的点数
    local pointsSpentInOtherLevel2Before = 0                   -- 非当前level2之前的天赋已消耗的点数

    -- 遍历天赋计算已消耗的点数
    for l1Idx, lv1Config in ipairs(playerConfig) do
        for l2Idx, lv2Config in ipairs(lv1Config.tianfu) do
            for _, tianfu in ipairs(lv2Config) do
                if l1Idx == level1Idx and l2Idx < level2Idx then
                    -- 当前level1Idx下，当前level2Idx之前的天赋点数累加
                    pointsSpentInCurrentLevel2Before = pointsSpentInCurrentLevel2Before +
                        (tianfu.activePoints[currentConfig] or 0)
                elseif l2Idx < level2Idx then
                    -- 其他level1Idx下，当前level2Idx之前的天赋点数累加
                    pointsSpentInOtherLevel2Before = pointsSpentInOtherLevel2Before +
                        (tianfu.activePoints[currentConfig] or 0)
                end
            end
        end
    end

    -- 检查前置需求是否满足
    if pointsSpentInCurrentLevel2Before < requiredPointsForCurrentLevel2 then
        return false
    end

    if pointsSpentInOtherLevel2Before < requiredPointsForCurrentLevel2 then
        return false
    end
    return true
end

htianfu.tryjihuotianfu        = function(whichPlayer, level1Idx, level2Idx, level3Idx)
    if htime.setupAndCheckCoolDown(whichPlayer, "改变天赋CD", 1) ~= true then
        sysecho("天赋变动冷却中", whichPlayer)
        return false
    end
    -- 获取玩家英雄等级
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil or hunit.getLevel(hero) < 50 then
        sysecho("还没选择英雄或者等级不足50级，无法激活天赋", whichPlayer)
        return false
    end

    if htianfu.getAvailableTianfu(whichPlayer) <= 0 then
        sysecho("没有可用的巅峰点数", whichPlayer)
        return false
    end

    if hfightzhuangtai.isInFight(hero) then
        sysecho("战斗中无法激活天赋", whichPlayer)
        return false
    end

    -- 获取玩家当前的天赋配置
    local currentConfig = htianfu[whichPlayer].currentConfig
    local playerConfig = htianfu[whichPlayer]
    if not playerConfig then
        sysecho("错误：玩家没有初始化的天赋配置", whichPlayer)
        return false
    end

    local tianfutypeConfig = playerConfig[level1Idx]
    if
        not tianfutypeConfig or not tianfutypeConfig.tianfu[level2Idx] or
        not tianfutypeConfig.tianfu[level2Idx][level3Idx]
    then
        sysecho("天赋位置不存在", whichPlayer)
        return false
    end

    local tianfu = tianfutypeConfig.tianfu[level2Idx][level3Idx]
    if tianfu.effect == nil then
        sysecho("该天赋效果未定义，快去告诉作者！", whichPlayer)
        return false
    end
    if tianfu.activePoints[currentConfig] >= #(tianfu.effect) then
        sysecho("该天赋天赋点已满", whichPlayer)
        return false
    end

    local requiredPointsForCurrentLevel2 = 5 * (level2Idx - 1) -- 当前level2天赋的前置点数需求
    local pointsSpentInCurrentLevel2Before = 0                 -- 当前level2之前的天赋已消耗的点数
    local pointsSpentInOtherLevel2Before = 0                   -- 非当前level2之前的天赋已消耗的点数

    -- 遍历天赋计算已消耗的点数
    for l1Idx, lv1Config in ipairs(playerConfig) do
        for l2Idx, lv2Config in ipairs(lv1Config.tianfu) do
            for _, tianfu in ipairs(lv2Config) do
                if l1Idx == level1Idx and l2Idx < level2Idx then
                    -- 当前level1Idx下，当前level2Idx之前的天赋点数累加
                    pointsSpentInCurrentLevel2Before = pointsSpentInCurrentLevel2Before +
                        (tianfu.activePoints[currentConfig] or 0)
                elseif l2Idx < level2Idx then
                    -- 其他level1Idx下，当前level2Idx之前的天赋点数累加
                    pointsSpentInOtherLevel2Before = pointsSpentInOtherLevel2Before +
                        (tianfu.activePoints[currentConfig] or 0)
                end
            end
        end
    end

    -- 检查前置需求是否满足
    if pointsSpentInCurrentLevel2Before < requiredPointsForCurrentLevel2 then
        sysecho("激活此天赋前需要在当前系列的前置天赋中投入至少 " .. requiredPointsForCurrentLevel2 .. " 点天赋点。", whichPlayer)
        return false
    end

    if pointsSpentInOtherLevel2Before < requiredPointsForCurrentLevel2 then
        sysecho("激活此天赋前需要在非当前系列的相同层级天赋中投入至少 " .. requiredPointsForCurrentLevel2 .. " 点天赋点。", whichPlayer)
        return false
    end

    -- 如果所有条件满足，进行天赋激活操作
    htianfu.jihuotianfu(whichPlayer, level1Idx, level2Idx, level3Idx, true)
    return true
end

function htianfu.getActivatedTianfuPoints(whichPlayer, levelIdx1, levelIdx2, levelIdx3, name)
    -- 获取玩家的天赋配置
    local currentConfig = htianfu[whichPlayer].currentConfig
    local playerConfig = htianfu[whichPlayer]
    if not playerConfig then
        error("错误：玩家没有初始化的天赋配置")
    end

    local tianfutypeConfig = playerConfig[levelIdx1]
    if not tianfutypeConfig then
        error("错误：指定的levelIdx1天赋不存在")
    end

    local tianfuConfig = tianfutypeConfig.tianfu[levelIdx2]
    if not tianfuConfig then
        error("错误：指定的levelIdx2天赋不存在")
    end

    local tianfu = tianfuConfig[levelIdx3]
    if not tianfu then
        error("错误：指定的levelIdx3天赋不存在")
    end
    if tianfu.name ~= name then
        error("错误：指定的name天赋不存在" .. name)
        return 0
    end

    -- 如果天赋存在，返回当前激活的点数
    return tianfu.activePoints[currentConfig] or 0
end

htianfu.jihuotianfu = function(whichPlayer, level1Idx, level2Idx, level3Idx, cundang)
    -- 获取玩家当前的天赋配置
    local currentConfig = htianfu[whichPlayer].currentConfig
    local playerConfig = htianfu[whichPlayer]
    if not playerConfig then
        print("错误：玩家没有初始化的天赋配置")
        return
    end

    -- 根据索引获取具体的天赋
    local tianfutypeConfig = playerConfig[level1Idx]
    if not tianfutypeConfig then
        print("错误：无效的第一层索引", level1Idx)
        return
    end

    local tianfuConfig = tianfutypeConfig.tianfu[level2Idx]
    if not tianfuConfig then
        print("错误：无效的第二层索引", level2Idx)
        return
    end

    local tianfu = tianfuConfig[level3Idx]
    if not tianfu then
        print("错误：无效的第三层索引", level3Idx)
        return
    end
    if tianfu.activePoints[currentConfig] >= #(tianfu.effect) then
        sysecho(
            hcolor.green("天赋读取错误，天赋投入超过该天赋上限" .. tianfu.name .. tianfu.activePoints[currentConfig] .. #(tianfu.effect)),
            whichPlayer)
        return
    end
    tianfu.activePoints[currentConfig] = tianfu.activePoints[currentConfig] + 1
    local effect = tianfu.effect[tianfu.activePoints[currentConfig]]
    if effect.action == CONST_EVENT.attr then
        hbuff.addAttribute(
            CONST_DAMAGE_SRC.item,
            hplayer.getMainHero(whichPlayer),
            level1Idx .. "|" .. level2Idx .. "|" .. level3Idx .. "|" .. tianfu.activePoints[currentConfig],
            effect.effect,
            0
        )
    elseif effect.action ~= nil then
        hevent.register(
            hplayer.getMainHero(whichPlayer),
            effect.action,
            level1Idx .. "|" .. level2Idx .. "|" .. level3Idx .. "|" .. tianfu.activePoints[currentConfig],
            effect.effect
        )
    end
    htianfu.updateUI(whichPlayer, tianfu, level1Idx, level2Idx, level3Idx)
    if cundang then
        sysecho(
            hcolor.green("成功激活天赋：" .. tianfu.name .. " " .. tianfu.activePoints[currentConfig] .. "/" .. #(tianfu.effect)),
            whichPlayer
        )
        htianfu.cundang(whichPlayer, tianfu)
    end
end

htianfu.trydisabletianfu = function(whichPlayer, level1Idx, level2Idx, level3Idx)
    if htime.setupAndCheckCoolDown(whichPlayer, "改变天赋CD", 1) ~= true then
        sysecho("天赋变动冷却中", whichPlayer)
        return false
    end
    -- 获取玩家英雄等级和战斗状态
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil or hunit.getLevel(hero) < 50 then
        sysecho("还没选择英雄或者等级不足50级，无法撤销天赋", whichPlayer)
        return false
    end

    if hfightzhuangtai.isInFight(hero) then
        sysecho("战斗中无法撤销天赋", whichPlayer)
        return false
    end

    -- 获取玩家当前的天赋配置
    local currentConfig = htianfu[whichPlayer].currentConfig
    local playerConfig = htianfu[whichPlayer]
    if not playerConfig then
        sysecho("错误：玩家没有初始化的天赋配置", whichPlayer)
        return false
    end

    local tianfutypeConfig = playerConfig[level1Idx]
    if
        not tianfutypeConfig or not tianfutypeConfig.tianfu[level2Idx] or
        not tianfutypeConfig.tianfu[level2Idx][level3Idx]
    then
        sysecho("天赋位置不存在", whichPlayer)
        return false
    end

    local tianfu = tianfutypeConfig.tianfu[level2Idx][level3Idx]
    if (tianfu.activePoints[currentConfig] or 0) <= 0 then
        sysecho("该天赋没有激活的天赋点，无法撤销", whichPlayer)
        return false
    end

    -- 检查撤销后的前置条件是否依然满足
    -- 这需要实现一个辅助函数来检查所有天赋点满足前置条件
    -- 假设这个函数已经实现，我们在这里调用它
    -- 模拟撤销操作
    tianfu.activePoints[currentConfig] = tianfu.activePoints[currentConfig] - 1
    local passValidate = validateTianfuPreconditionsAfterRevoking(whichPlayer)
    tianfu.activePoints[currentConfig] = tianfu.activePoints[currentConfig] + 1

    if passValidate ~= true then
        sysecho("撤销此天赋点后将不满足其他天赋的前置条件", whichPlayer)
        return false
    end
    local goldCost = 2000
    if hshangcheng.hasItem(whichPlayer, "荣誉会员") then
        goldCost = goldCost * 0.75
    end
    if hresource.checkHasSingleResource(whichPlayer, HSHOP_COST_TYPE.gold, goldCost, true) then
        hresource.changeSingleResource(whichPlayer, HSHOP_COST_TYPE.gold, goldCost, true)
        htianfu.disabletianfu(whichPlayer, level1Idx, level2Idx, level3Idx)
        return true
    else
        sysecho("撤销天赋失败", whichPlayer)
        return false
    end
end

htianfu.disabletianfu = function(whichPlayer, level1Idx, level2Idx, level3Idx)
    -- 获取玩家当前的天赋配置
    local currentConfig = htianfu[whichPlayer].currentConfig
    local playerConfig = htianfu[whichPlayer]
    if not playerConfig then
        print("错误：玩家没有初始化的天赋配置")
        return
    end

    -- 根据索引获取具体的天赋
    local tianfutypeConfig = playerConfig[level1Idx]
    if not tianfutypeConfig then
        print("错误：无效的第一层索引", level1Idx)
        return
    end

    local tianfuConfig = tianfutypeConfig.tianfu[level2Idx]
    if not tianfuConfig then
        print("错误：无效的第二层索引", level2Idx)
        return
    end

    local tianfu = tianfuConfig[level3Idx]
    if not tianfu then
        print("错误：无效的第三层索引", level3Idx)
        return
    end
    if tianfu.activePoints[currentConfig] <= 0 then
        sysecho(
            hcolor.green("天赋取消错误，当前天赋没有任何投入" .. tianfu.name .. tianfu.activePoints[currentConfig] .. #(tianfu.effect)),
            whichPlayer)
        return
    end
    local effect = tianfu.effect[tianfu.activePoints[currentConfig]]
    if effect.action == CONST_EVENT.attr then
        hbuff.delete(
            hplayer.getMainHero(whichPlayer),
            level1Idx .. "|" .. level2Idx .. "|" .. level3Idx .. "|" .. tianfu.activePoints[currentConfig]
        )
    elseif effect.action ~= nil then
        hevent.unregister(
            hplayer.getMainHero(whichPlayer),
            effect.action,
            level1Idx .. "|" .. level2Idx .. "|" .. level3Idx .. "|" .. tianfu.activePoints[currentConfig]
        )
    end
    tianfu.activePoints[currentConfig] = tianfu.activePoints[currentConfig] - 1
    htianfu.updateUI(whichPlayer, tianfu, level1Idx, level2Idx, level3Idx)
    sysecho(
        hcolor.green("成功撤销天赋：" .. tianfu.name .. (tianfu.activePoints[currentConfig] + 1) .. "/" .. #(tianfu.effect)),
        whichPlayer)
    htianfu.cundang(whichPlayer, tianfu)
end

htianfu.updateUI = function(whichPlayer, tianfu, level1Idx, level2Idx, level3Idx)
    if whichPlayer ~= hplayer.loc() then
        return
    end
    local currentConfig = htianfu[whichPlayer].currentConfig
    local playerConfig = htianfu[whichPlayer]
    for l1Idx, lv1Config in ipairs(playerConfig) do
        for l2Idx, lv2Config in ipairs(lv1Config.tianfu) do
            for l3Idx, tmpTianfu in ipairs(lv2Config) do
                if htianfu.isTianfuAddable(whichPlayer, l1Idx, l2Idx, l3Idx) then
                    hjapi.DzFrameSetTexture(tmpTianfu.singleTianfuframe, "ReplaceableTextures\\xitong\\uikz3.tga")
                else
                    hjapi.DzFrameSetTexture(tmpTianfu.singleTianfuframe, "UI\\frame.tga")
                end
            end
        end
    end
    if whichPlayer == hplayer.loc() then
        local mask = tianfu.ui_mask
        if (tianfu.activePoints[currentConfig] or 0) > 0 then
            hjapi.DzFrameShow(mask, false)
        else
            hjapi.DzFrameShow(mask, true)
        end
        local stack = tianfu.ui_stack
        hjapi.DzFrameSetText(stack, tianfu.activePoints[currentConfig] .. "/" .. #(tianfu.effect))
        if
            UI_GLOBAL_TIANFU_POSITION and UI_GLOBAL_TIANFU_POSITION[1] == level1Idx and
            UI_GLOBAL_TIANFU_POSITION[2] == level2Idx and
            UI_GLOBAL_TIANFU_POSITION[3] == level3Idx
        then
            local tip = htianfu.getDescription(tianfu, currentConfig)
            local tipsText = hjapi.DzFrameFindByName("TIANFU_Tips_Desc", 0)
            hjapi.DzFrameSetText(tipsText, tip)
        end
        htianfu.updateTianfuInstructions(whichPlayer)
    end
end

htianfu.getDescription = function(tianfu, currentConfig)
    -- 初始化描述字符串
    local msg = hcolor.green(tianfu.name)
    local isActive = tianfu.activePoints[currentConfig] ~= nil and tianfu.activePoints[currentConfig] > 0

    -- 更新描述信息
    msg =
        msg ..
        (isActive and hcolor.green(" （已激活" .. tianfu.activePoints[currentConfig] .. "/" .. #(tianfu.effect) .. "）") or
            hcolor.grey(" （未激活）")) ..
        "|n"
    msg = msg .. "|n"
    msg = msg .. hcolor.yellow("天赋效果: ") .. hcolor.green(tianfu.description) .. "|n"
    for index, effect in ipairs(tianfu.effect) do
        local oneEffect = ""
        if effect.action == CONST_EVENT.attr then
            oneEffect = description.attribute(effect.effect, ",")
        elseif effect.description ~= nil then
            oneEffect = effect.description
        end
        if tianfu.activePoints[currentConfig] >= index then
            msg = msg .. "- " .. hcolor.green(oneEffect) .. "|n"
        else
            msg = msg .. "- " .. hcolor.grey(oneEffect) .. "|n"
        end
    end

    -- 计算前置要求
    if isActive == false then
        msg = msg .. "|n"
        msg = msg .. hcolor.yellow("激活天赋需要:|n")
        msg = msg .. "- 等级达到50级|n"
        msg = msg .. "- 在该系前置天赋中至少需要投入5*层数点天赋点。\n"
        msg = msg .. "- 在所有其它系天赋中需要投入至少5*层数点点天赋点。\n"
        msg = msg .. "- 左键点击激活天赋。\n"
        msg = msg .. "- 右键点击撤销天赋（需要消耗2000" .. HSHOP_COST_TYPE.gold .. "（荣誉会员可以降低消耗））。\n"
    end

    return msg
end

htianfu.cundang = function(whichPlayer, tianfu)
    -- 获取当前配置
    local currentConfig = htianfu[whichPlayer].currentConfig or 1
    local cundangStr = tianfu.cundangStr .. (currentConfig == 2 and "2" or "")
    local cdvalue = "0"
    if tianfu.activePoints[currentConfig] ~= nil and tianfu.activePoints[currentConfig] > 0 and tianfu.activePoints[currentConfig] < 10 then
        cdvalue = tostring(math.round(tianfu.activePoints[currentConfig], 0))
    end
    hplayer.dzCunDang[whichPlayer].saveCundang(
        cundangStr,
        true,
        tianfu.cundangIndex,
        tianfu.cundangIndex,
        cdvalue
    )
end

htianfu.loadcundang = function(whichPlayer)
    -- 获取玩家当前的天赋配置
    if whichPlayer == nil then
        err("没有玩家")
        return
    end
    local playerConfig = htianfu[whichPlayer]
    if not playerConfig then
        print("错误：玩家没有初始化的天赋配置")
        return
    end

    -- 遍历所有天赋类型
    for level1Idx, tianfutypeConfig in ipairs(playerConfig) do
        -- 遍历每个天赋类型中的所有天赋
        for level2Idx, tianfuRow in ipairs(tianfutypeConfig.tianfu) do
            for level3Idx, tianfu in ipairs(tianfuRow) do
                -- 确保天赋配置包含存档读取所需的所有信息
                if tianfu.cundangStr and tianfu.cundangIndex then
                    for configNumber = 1, 2 do
                        local suffix = ""
                        if configNumber == 2 then
                            suffix = "2"
                        end
                        -- 读取存档中的天赋状态
                        local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(tianfu.cundangStr .. suffix,
                            true)
                        local currentCount =
                            math.floor(tonumber(string.sub(cundang, tianfu.cundangIndex, tianfu.cundangIndex)) or 0) or 0
                        tianfu.activePoints[configNumber] = currentCount
                    end
                else
                    error("警告: 天赋配置缺少必要的存档信息")
                end
            end
        end
    end
    -- 调用switchTianfuConfig来激活其中一套配置
    htianfu.switchTianfuConfig(whichPlayer, 1, true) -- 假设默认激活第一套配置
end

htianfu.getActiveTianfuLevel = function(whichPlayer, tianfuname)
    if not htianfu[whichPlayer] or not htianfu.tianfuNameMap[whichPlayer] then
        return 0 -- Player doesn't have tianfu configuration
    end

    local currentConfig = htianfu[whichPlayer].currentConfig
    if not currentConfig then
        return 0 -- No current configuration
    end

    local tianfu = htianfu.tianfuNameMap[whichPlayer][tianfuname]
    if not tianfu then
        return 0 -- Tianfu with given name doesn't exist
    end

    return tianfu.activePoints[currentConfig] or 0
end
