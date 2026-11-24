--hjapi.DzEnableWideScreen(true)
--hjapi.DzFrameHideInterface()
--hjapi.DzFrameEditBlackBorders(0, 0)

UI_components = {}
UI_components["select"] = {}
ACHIEVEMENT_DATA = {}
ZHUANYE_DATA = {}

function ui_clear_shifatiao()
    hjapi.DzFrameShow(hjapi.DzFrameFindByName("shifatiao", 0), false)
    hjapi.DzFrameSetText(hjapi.DzFrameFindByName("shifatiao_text", 0), "")
end

local function getSelectedPlayer(whichPlayer)
    local selected_unit = hplayer.getSelection(whichPlayer)
    local targetPlayer = whichPlayer
    if
        selected_unit ~= nil and hunit.getOwner(selected_unit) ~= whichPlayer and
        hplayer.isUser(hunit.getOwner(selected_unit)) and
        hplayer.isPlaying(hunit.getOwner(selected_unit))
    then
        targetPlayer = hunit.getOwner(selected_unit)
    end
    return targetPlayer
end

function ui_set_shifatiaovalue(name, currentProgress, max, increase)
    if currentProgress < 0 or max < 0 or currentProgress > max then
        return
    end
    if increase == nil then
        increase = true
    end
    local shifatiao = hjapi.DzFrameFindByName("shifatiao", 0)
    local bar = hjapi.DzFrameFindByName("shifatiao_bar", 0)
    local text = hjapi.DzFrameFindByName("shifatiao_text", 0)

    hjapi.DzFrameClearAllPoints(bar)
    if increase == true then
        hjapi.DzFrameSetSize(bar, 0.1 * currentProgress / max, 0.033)
        hjapi.DzFrameSetPoint(bar, 3, shifatiao, 3, 0.001, 0.00)
        hjapi.DzFrameSetText(
            text,
            name .. " " .. string.format("%.2f", currentProgress) .. "/" .. string.format("%.2f", max)
        )
    else
        hjapi.DzFrameSetSize(bar, 0.1 * (1 - currentProgress / max), 0.033)
        hjapi.DzFrameSetPoint(bar, 5, shifatiao, 5, -0.001, 0.00)
        hjapi.DzFrameSetText(
            text,
            name .. " " .. string.format("%.2f", max - currentProgress) .. "/" .. string.format("%.2f", max)
        )
    end
    hjapi.DzFrameShow(shifatiao, true)
end

function ui_set_direnshifatiaovalue(name, currentProgress, max, increase)
    if currentProgress < 0 or max < 0 or currentProgress > max then
        return
    end
    if increase == nil then
        increase = true
    end
    local shifatiao = hjapi.DzFrameFindByName("direnshifatiao", 0)
    local bar = hjapi.DzFrameFindByName("direnshifatiao_bar", 0)
    local text = hjapi.DzFrameFindByName("direnshifatiao_text", 0)

    hjapi.DzFrameClearAllPoints(bar)
    if increase == true then
        hjapi.DzFrameSetSize(bar, 0.1 * currentProgress / max, 0.033)
        hjapi.DzFrameSetPoint(bar, 3, shifatiao, 3, 0.001, 0.00)
        hjapi.DzFrameSetText(
            text,
            name .. " " .. string.format("%.2f", currentProgress) .. "/" .. string.format("%.2f", max)
        )
    else
        hjapi.DzFrameSetSize(bar, 0.1 * (1 - currentProgress / max), 0.033)
        hjapi.DzFrameSetPoint(bar, 5, shifatiao, 5, -0.001, 0.00)
        hjapi.DzFrameSetText(
            text,
            name .. " " .. string.format("%.2f", max - currentProgress) .. "/" .. string.format("%.2f", max)
        )
    end
    hjapi.DzFrameShow(shifatiao, true)
end

local function disable_compare_view(framePrefix)
    local tipsBack = hjapi.DzFrameFindByName(framePrefix .. "_COMPAREA", 0)
    hjapi.DzFrameShow(tipsBack, false)
    local tipsBack = hjapi.DzFrameFindByName(framePrefix .. "_COMPAREB", 0)
    hjapi.DzFrameShow(tipsBack, false)
end

local function try_show_compare_view(whichPlayer, dynamicItem, originalTipsFrame, framePrefix)
    if whichPlayer == nil or dynamicItem == nil or originalTipsFrame == nil then
        return
    end
    disable_compare_view(framePrefix)
    local item = hslk.i2v(dynamicItem.basic_item_id, "equipment_type")
    if EQUIPMENT_TYPE_TO_SLOT[item] ~= nil then
        local hero = hplayer.getMainHero(whichPlayer)
        if hero ~= nil then
            local hero_cundang_str = hslk.n2v(hunit.getName(hero), "zhiye_cundang_str")
            local slot = EQUIPMENT_TYPE_TO_SLOT[item][hero_cundang_str]
            if slot == nil then
                return
            end
            if #slot >= 1 then
                local equipItem1 = hplayer.dzCunDang[whichPlayer].getEquipment(slot[1])
                local previousFrame = originalTipsFrame
                if equipItem1 ~= nil then
                    local tipsBackA = hjapi.DzFrameFindByName(framePrefix .. "_COMPAREA", 0)
                    local tipsTextA = hjapi.DzFrameFindByName(framePrefix .. "_COMPAREA_Desc", 0)
                    local msg =
                        hcolor.green("[已装备][" .. EQUIPMENT_SLOT_ID_TO_SLOT_NAME[slot[1]] .. "]|n|n") ..
                        equipItem1.getDescription()
                    hjapi.DzFrameClearAllPoints(tipsTextA)
                    hjapi.DzFrameSetPoint(tipsTextA, 2, previousFrame, 0, -0.02, 0)
                    hjapi.DzFrameSetSize(tipsTextA, 0.1000, 0)
                    hjapi.DzFrameSetText(tipsTextA, msg)
                    hjapi.DzFrameShow(tipsBackA, true)
                    previousFrame = tipsTextA
                end
                if #slot >= 2 then
                    local equipItem2 = hplayer.dzCunDang[whichPlayer].getEquipment(slot[2])
                    if equipItem2 ~= nil then
                        local tipsBackB = hjapi.DzFrameFindByName(framePrefix .. "_COMPAREB", 0)
                        local tipsTextB = hjapi.DzFrameFindByName(framePrefix .. "_COMPAREB_Desc", 0)
                        local msg =
                            hcolor.green("[已装备][" .. EQUIPMENT_SLOT_ID_TO_SLOT_NAME[slot[2]] .. "]|n|n") ..
                            equipItem2.getDescription()
                        hjapi.DzFrameClearAllPoints(tipsTextB)
                        hjapi.DzFrameSetPoint(tipsTextB, 2, previousFrame, 0, -0.02, 0)
                        hjapi.DzFrameSetSize(tipsTextB, 0.1000, 0)
                        hjapi.DzFrameSetText(tipsTextB, msg)
                        hjapi.DzFrameShow(tipsBackB, true)
                    end
                end
            end
        end
    end
end

local function init_shifatiao_UI()
    hjapi.DzLoadToc("UI\\template.toc")
    local shifatiao = hjapi.DzCreateFrame("shifatiao", hjapi.DzGetGameUI(), 0)
    hjapi.DzFrameSetAbsolutePoint(shifatiao, 4, 0.4, 0.22)
    hjapi.DzFrameShow(shifatiao, false)
end
local function init_zhuangbei_dabeibao_UI(parentFrame)
    ZHUANGBEIBEIBAO_PLAYER_TO_CURRENT_PAGE = {}
    ZHUANGBEIBEIBAO_PLAYER_TO_CURRENT_PAGE[hplayer.loc()] = 1

    local function getCurrentPage(whichPlayer)
        return ZHUANGBEIBEIBAO_PLAYER_TO_CURRENT_PAGE[whichPlayer]
    end
    local function SetCurrentPage(whichPlayer, page)
        ZHUANGBEIBEIBAO_PLAYER_TO_CURRENT_PAGE[whichPlayer] = page
    end
    local function getMaxPage(whichPlayer)
        return math.floor((hdzcundang.getMaxZhuangbeiBeibaoCount(whichPlayer) - 1) / CONST_MAX_ZHUANGBEIDABEIBAO_PER_PAGE) +
            1
    end
    local dabeibaoUI = parentFrame
    local bagRx = 0.024
    local bagRy = 0.032
    local backdrop = {}
    local frameBackDrop = {}
    local stack = {}
    local button = {}
    for i = 1, CONST_MAX_ZHUANGBEIDABEIBAO_PER_PAGE do
        local x = ((i - 1) % 10) * bagRx
        local y = math.floor((i - 1) / 10) * bagRy

        backdrop[i] = hjapi.FrameTag("BACKDROP", "zhuangbei_dabeibao_backdrop_" .. i, dabeibaoUI, "")
        hjapi.DzFrameSetPoint(backdrop[i], 0, dabeibaoUI, 0, x + 0.01, -y - 0.03)
        hjapi.DzFrameSetSize(backdrop[i], bagRx, bagRy)
        hjapi.DzFrameSetTexture(backdrop[i], "war3mapImported\\[ZT]A3.tga")
        hjapi.DzFrameShow(backdrop[i], true)

        stack[i] = hjapi.FrameTag("TEXT", "zhuangbei_dabeibao_stack_" .. i, backdrop[i])
        hjapi.DzFrameSetText(stack[i], "")
        hjapi.DzFrameSetFont(stack[i], "war3mapImported\\fonts.ttf", 0.013, 0)
        hjapi.DzFrameSetPoint(stack[i], 8, backdrop[i], 8, -0.005, 0.005)
        hjapi.DzFrameShow(stack[i], true)

        button[i] = hjapi.FrameTag("BUTTON", "zhuangbei_dabeibao_button_" .. i, backdrop[i], nil)
        hjapi.DzFrameSetPoint(button[i], 4, backdrop[i], 4, 0, 0)
        hjapi.DzFrameSetSize(button[i], bagRx, bagRy)
        hjapi.DzFrameShow(button[i], true)

        frameBackDrop[i] = hjapi.FrameTag("BACKDROP", "frame_zhuangbei_dabeibao_backdrop_" .. i, backdrop[i], "")
        hjapi.DzFrameSetPoint(frameBackDrop[i], 0, dabeibaoUI, 0, x + 0.01, -y - 0.03)
        hjapi.DzFrameSetSize(frameBackDrop[i], bagRx, bagRy)
        hjapi.DzFrameSetTexture(frameBackDrop[i], ZHUANGBEI_PINZHI_DATA[ZHUANGBEI_PINZHI.PUTONG].frameArt)
        hjapi.DzFrameShow(frameBackDrop[i], false)

        hjapi.DzFrameSetScriptByCode(
            button[i],
            MOUSE_ORDER_ENTER,
            function()
                local dynamicItem = hplayer.dzCunDang[hplayer.loc()].getDynamicItemFromZhuangbeiDaBeibaobyUIIndex(
                    i + (getCurrentPage(hplayer.loc()) - 1) * CONST_MAX_ZHUANGBEIDABEIBAO_PER_PAGE
                )
                local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
                local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
                if dynamicItem ~= nil then
                    local msg = dynamicItem.getDescription()
                    hjapi.DzFrameClearAllPoints(tipsText)
                    hjapi.DzFrameSetPoint(tipsText, 2, dabeibaoUI, 0, -0.02, 0)
                    hjapi.DzFrameSetSize(tipsText, 0.1000, 0)
                    hjapi.DzFrameSetText(tipsText, msg)
                    hjapi.DzFrameShow(tipsBack, true)
                    try_show_compare_view(hplayer.loc(), dynamicItem, tipsText, "ALL_Tips")
                else
                    hjapi.DzFrameShow(tipsBack, false)
                end
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            button[i],
            MOUSE_ORDER_LEAVE,
            function()
                local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
                hjapi.DzFrameShow(tipsBack, false)
                disable_compare_view("ALL_Tips")
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            button[i],
            MOUSE_ORDER_CLICK,
            function()
                local dynamicItem = hplayer.dzCunDang[hplayer.loc()].getDynamicItemFromZhuangbeiDaBeibaobyUIIndex(
                    i + (getCurrentPage(hplayer.loc()) - 1) * CONST_MAX_ZHUANGBEIDABEIBAO_PER_PAGE
                )
                if dynamicItem == nil then
                    return
                end
                hsync.send(
                    "moveItemFromZhuangbeiInventoryToBag",
                    { hplayer.dzCunDang[hplayer.loc()].getZhuangbeiDaBeibaoIndexbyUIIndex(
                        i + (getCurrentPage(hplayer.loc()) - 1) * CONST_MAX_ZHUANGBEIDABEIBAO_PER_PAGE
                    ) }
                )
            end,
            false
        )
    end

    hsync.onSend(
        "moveItemFromZhuangbeiInventoryToBag",
        function(syncData)
            hplayer.dzCunDang[syncData.triggerPlayer].getItemFromZhuangbeiInventoryToBag(
                tonumber(syncData.triggerData[1])
            )
        end
    )

    hevent.register(
        hplayer.loc(),
        CONST_EVENT.zhuangbeidabeibao,
        "UI",
        function(evtData)
            local index = evtData.index
            if index == nil then
                err("index is nil")
                return
            end
            if index > hdzcundang.getMaxZhuangbeiBeibaoCount(hplayer.loc()) then
                local UIPage = math.floor((index - 1) / CONST_MAX_ZHUANGBEIDABEIBAO_PER_PAGE) + 1
                local UIIndex = index % CONST_MAX_ZHUANGBEIDABEIBAO_PER_PAGE
                if UIIndex == 0 then
                    UIIndex = CONST_MAX_ZHUANGBEIDABEIBAO_PER_PAGE
                end
                if UIPage == getCurrentPage(hplayer.loc()) then
                    hjapi.DzFrameShow(backdrop[UIIndex], false)
                    return
                end
            end
            local dynamicItem = hplayer.dzCunDang[hplayer.loc()].zhuangbeiIventory[index]
            local UIAllIndex = hplayer.dzCunDang[hplayer.loc()].getUIIndexbyZhuangbeiDabeibaoIndex(index)
            if UIAllIndex == nil then
                dump(index)
                dump(UIAllIndex)
                return
            end
            local UIPage = math.floor((UIAllIndex - 1) / CONST_MAX_ZHUANGBEIDABEIBAO_PER_PAGE) + 1
            if UIPage ~= getCurrentPage(hplayer.loc()) then
                return
            end
            UIIndex = UIAllIndex % CONST_MAX_ZHUANGBEIDABEIBAO_PER_PAGE
            if UIIndex == 0 then
                UIIndex = CONST_MAX_ZHUANGBEIDABEIBAO_PER_PAGE
            end
            hjapi.DzFrameShow(backdrop[UIIndex], true)
            if dynamicItem == nil then
                hjapi.DzFrameSetTexture(backdrop[UIIndex], "war3mapImported\\[ZT]A3.tga")
                hjapi.DzFrameSetText(stack[UIIndex], "")
                hjapi.DzFrameShow(frameBackDrop[UIIndex], false)
            else
                if dynamicItem.stack > 1 then
                    hjapi.DzFrameSetText(stack[UIIndex], dynamicItem.stack)
                else
                    hjapi.DzFrameSetText(stack[UIIndex], "")
                end
                hjapi.DzFrameSetTexture(backdrop[UIIndex], hslk.i2v(dynamicItem.basic_item_id, "Art"))
                hjapi.DzFrameSetTexture(frameBackDrop[UIIndex], ZHUANGBEI_PINZHI_DATA[dynamicItem.pinzhi].frameArt)
                hjapi.DzFrameShow(frameBackDrop[UIIndex], true)
            end
        end
    )

    local dangqianyemian = hjapi.FrameTag("TEXT", "zhuangbeidabeibao_dangqianyemian", dabeibaoUI)
    hjapi.DzFrameSetText(dangqianyemian, getCurrentPage(hplayer.loc()) .. "/" .. getMaxPage(hplayer.loc()))
    hjapi.DzFrameSetFont(dangqianyemian, "war3mapImported\\fonts.ttf", 0.010, 0)
    hjapi.DzFrameSetPoint(dangqianyemian, FRAME_ALIGN_TOP, dabeibaoUI, FRAME_ALIGN_TOP, 0.002, -0.0080)
    hjapi.DzFrameShow(dangqianyemian, true)

    local function refreshZhuangbeibeibao(whichPlayer)
        local startIndex = (getCurrentPage(whichPlayer) - 1) * CONST_MAX_ZHUANGBEIDABEIBAO_PER_PAGE + 1
        local endIndex = getCurrentPage(whichPlayer) * CONST_MAX_ZHUANGBEIDABEIBAO_PER_PAGE
        for i = startIndex, endIndex, 1 do
            local dabeibaoIndex = hplayer.dzCunDang[hplayer.loc()].getZhuangbeiDaBeibaoIndexbyUIIndex(i) or i
            hevent.trigger(
                hplayer.loc(),
                CONST_EVENT.zhuangbeidabeibao,
                {
                    index = dabeibaoIndex
                }
            )
        end
        hjapi.DzFrameSetText(dangqianyemian, getCurrentPage(whichPlayer) .. "/" .. getMaxPage(whichPlayer))
    end

    local prev_page_back = hjapi.FrameTag("BACKDROP", "prev_page_back", dabeibaoUI)
    hjapi.DzFrameSetPoint(prev_page_back, FRAME_ALIGN_TOP, dabeibaoUI, FRAME_ALIGN_TOP, -0.0150, -0.0030)
    hjapi.DzFrameSetSize(prev_page_back, 0.015, 0.020)
    hjapi.DzFrameSetTexture(prev_page_back, "UI\\AZAchieve\\ui-spellbookicon-prevpage-up.blp")
    hjapi.DzFrameShow(prev_page_back, true)

    local prev_page_button = hjapi.FrameTag("BUTTON", "prev_page_button", prev_page_back)
    hjapi.DzFrameSetPoint(prev_page_button, 4, prev_page_back, 4, 0, 0)
    hjapi.DzFrameSetSize(prev_page_button, 0.015, 0.020)
    hjapi.DzFrameShow(prev_page_button, true)
    hjapi.DzFrameSetScriptByCode(
        prev_page_button,
        MOUSE_ORDER_CLICK,
        function()
            if getCurrentPage(hplayer.loc()) > 1 then
                SetCurrentPage(hplayer.loc(), getCurrentPage(hplayer.loc()) - 1)
                refreshZhuangbeibeibao(hplayer.loc())
            end
        end,
        false
    )

    local next_page_back = hjapi.FrameTag("BACKDROP", "nexk_page_back", dabeibaoUI)
    hjapi.DzFrameSetPoint(next_page_back, FRAME_ALIGN_TOP, dabeibaoUI, FRAME_ALIGN_TOP, 0.015, -0.0030)
    hjapi.DzFrameSetSize(next_page_back, 0.015, 0.020)
    hjapi.DzFrameSetTexture(next_page_back, "UI\\AZAchieve\\ui-spellbookicon-nextpage-up.blp")
    hjapi.DzFrameShow(next_page_back, true)

    local next_page_button = hjapi.FrameTag("BUTTON", "next_page_button", next_page_back)
    hjapi.DzFrameSetPoint(next_page_button, 4, next_page_back, 4, 0, 0)
    hjapi.DzFrameSetSize(next_page_button, 0.015, 0.020)
    hjapi.DzFrameShow(next_page_button, true)
    hjapi.DzFrameSetScriptByCode(
        next_page_button,
        MOUSE_ORDER_CLICK,
        function()
            if getCurrentPage(hplayer.loc()) < getMaxPage(hplayer.loc()) then
                SetCurrentPage(hplayer.loc(), getCurrentPage(hplayer.loc()) + 1)
                refreshZhuangbeibeibao(hplayer.loc())
            end
        end,
        false
    )
end

local function init_cailiao_dabeibao_UI(parentFrame)
    CAILIAOBEIBAO_PLAYER_TO_CURRENT_PAGE = {}
    CAILIAOBEIBAO_PLAYER_TO_CURRENT_PAGE[hplayer.loc()] = 1

    local function getCurrentPage(whichPlayer)
        return CAILIAOBEIBAO_PLAYER_TO_CURRENT_PAGE[whichPlayer]
    end
    local function SetCurrentPage(whichPlayer, page)
        CAILIAOBEIBAO_PLAYER_TO_CURRENT_PAGE[whichPlayer] = page
    end
    local function getMaxPage(whichPlayer)
        return math.floor((hdzcundang.getMaxCailiaoBeibaoCount(whichPlayer) - 1) / CONST_MAX_DABEIBAO_PER_PAGE) + 1
    end
    local dabeibaoUI = parentFrame
    local bagRx = 0.024
    local bagRy = 0.032
    local backdrop = {}
    local frameBackDrop = {}
    local stack = {}
    local button = {}
    for i = 1, CONST_MAX_DABEIBAO_PER_PAGE do
        local x = ((i - 1) % 10) * bagRx
        local y = math.floor((i - 1) / 10) * bagRy

        --buff图标
        backdrop[i] = hjapi.FrameTag("BACKDROP", "dabeibao_backdrop_" .. i, dabeibaoUI, "")
        hjapi.DzFrameSetPoint(backdrop[i], 0, dabeibaoUI, 0, x + 0.01, -y - 0.19)
        hjapi.DzFrameSetSize(backdrop[i], bagRx, bagRy)
        hjapi.DzFrameSetTexture(backdrop[i], "war3mapImported\\[ZT]A3.tga")
        hjapi.DzFrameShow(backdrop[i], true)

        --叠加层数文本
        stack[i] = hjapi.FrameTag("TEXT", "dabeibao_stack_" .. i, backdrop[i])
        hjapi.DzFrameSetText(stack[i], "")
        hjapi.DzFrameSetFont(stack[i], "war3mapImported\\fonts.ttf", 0.013, 0)
        hjapi.DzFrameSetPoint(stack[i], 8, backdrop[i], 8, -0.005, 0.005)
        hjapi.DzFrameShow(stack[i], true)

        --按钮
        button[i] = hjapi.FrameTag("BUTTON", "dabeibao_button_" .. i, backdrop[i], nil)
        hjapi.DzFrameSetPoint(button[i], 4, backdrop[i], 4, 0, 0)
        hjapi.DzFrameSetSize(button[i], bagRx, bagRy)
        hjapi.DzFrameShow(button[i], true)

        --frame  图标
        frameBackDrop[i] = hjapi.FrameTag("BACKDROP", "frame_dabeibao_backdrop_" .. i, backdrop[i])
        hjapi.DzFrameSetPoint(frameBackDrop[i], 4, backdrop[i], 4, 0, 0)
        hjapi.DzFrameSetSize(frameBackDrop[i], bagRx, bagRy)
        hjapi.DzFrameSetTexture(frameBackDrop[i], ZHUANGBEI_PINZHI_DATA[ZHUANGBEI_PINZHI.PUTONG].frameArt)
        hjapi.DzFrameShow(frameBackDrop[i], false)

        hjapi.DzFrameSetScriptByCode(
            button[i],
            MOUSE_ORDER_ENTER,
            function()
                local dynamicItem =
                    hplayer.dzCunDang[hplayer.loc()].getDynamicItemFromDaBeibaobyUIIndex(
                        i + (getCurrentPage(hplayer.loc()) - 1) * CONST_MAX_DABEIBAO_PER_PAGE
                    )
                local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
                local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
                if dynamicItem ~= nil then
                    local msg = dynamicItem.getDescription()
                    hjapi.DzFrameClearAllPoints(tipsText)
                    hjapi.DzFrameSetPoint(tipsText, 2, dabeibaoUI, 0, -0.02, 0)
                    hjapi.DzFrameSetSize(tipsText, 0.1000, 0)
                    hjapi.DzFrameSetText(tipsText, msg)
                    hjapi.DzFrameShow(tipsBack, true)
                    try_show_compare_view(hplayer.loc(), dynamicItem, tipsText, "ALL_Tips")
                else
                    hjapi.DzFrameShow(tipsBack, false)
                end
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            button[i],
            MOUSE_ORDER_LEAVE,
            function()
                local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
                hjapi.DzFrameShow(tipsBack, false)
                disable_compare_view("ALL_Tips")
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            button[i],
            MOUSE_ORDER_CLICK,
            function()
                local dynamicItem =
                    hplayer.dzCunDang[hplayer.loc()].getDynamicItemFromDaBeibaobyUIIndex(
                        i + (getCurrentPage(hplayer.loc()) - 1) * CONST_MAX_DABEIBAO_PER_PAGE
                    )
                if dynamicItem == nil then
                    return
                end
                hsync.send(
                    "moveItemFromInventoryToBag",
                    {
                        hplayer.dzCunDang[hplayer.loc()].getDaBeibaoIndexbyUIIndex(
                            i + (getCurrentPage(hplayer.loc()) - 1) * CONST_MAX_DABEIBAO_PER_PAGE
                        )
                    }
                )
            end,
            false
        )
    end

    hsync.onSend(
        "moveItemFromInventoryToBag",
        function(syncData)
            hplayer.dzCunDang[syncData.triggerPlayer].getItemFromInventoryToBag(tonumber(syncData.triggerData[1]))
        end
    )

    hevent.register(
        hplayer.loc(),
        CONST_EVENT.dabeibao,
        "UI",
        function(evtData)
            local index = evtData.index
            if index == nil then
                err("index is nil")
                return
            end
            if index > hdzcundang.getMaxCailiaoBeibaoCount(hplayer.loc()) then
                local UIPage = math.floor((index - 1) / CONST_MAX_DABEIBAO_PER_PAGE) + 1
                local UIIndex = index % CONST_MAX_DABEIBAO_PER_PAGE
                if UIIndex == 0 then
                    UIIndex = CONST_MAX_DABEIBAO_PER_PAGE
                end
                if UIPage == getCurrentPage(hplayer.loc()) then
                    hjapi.DzFrameShow(backdrop[UIIndex], false)
                    return
                end
            end
            local dynamicItem = hplayer.dzCunDang[hplayer.loc()].inventory[index]
            local UIAllIndex = hplayer.dzCunDang[hplayer.loc()].getUIIndexbyDabeibaoIndex(index)
            if UIAllIndex == nil then
                dump(index)
                dump(UIAllIndex)
                return
            end
            local UIPage = math.floor((UIAllIndex - 1) / CONST_MAX_DABEIBAO_PER_PAGE) + 1
            if UIPage ~= getCurrentPage(hplayer.loc()) then
                return
            end
            UIIndex = UIAllIndex % CONST_MAX_DABEIBAO_PER_PAGE
            if UIIndex == 0 then
                UIIndex = CONST_MAX_DABEIBAO_PER_PAGE
            end
            hjapi.DzFrameShow(backdrop[UIIndex], true)
            if dynamicItem == nil then
                hjapi.DzFrameSetTexture(backdrop[UIIndex], "war3mapImported\\[ZT]A3.tga")
                hjapi.DzFrameSetText(stack[UIIndex], "")
                hjapi.DzFrameShow(frameBackDrop[UIIndex], false)
            else
                if dynamicItem.stack > 1 then
                    hjapi.DzFrameSetText(stack[UIIndex], dynamicItem.stack)
                else
                    hjapi.DzFrameSetText(stack[UIIndex], "")
                end
                hjapi.DzFrameSetTexture(backdrop[UIIndex], hslk.i2v(dynamicItem.basic_item_id, "Art"))
                hjapi.DzFrameSetTexture(frameBackDrop[UIIndex], ZHUANGBEI_PINZHI_DATA[dynamicItem.pinzhi].frameArt)
                hjapi.DzFrameShow(frameBackDrop[UIIndex], true)
            end
        end
    )

    --当前页面文本
    local dangqianyemian = hjapi.FrameTag("TEXT", "dabeibao_dangqianyemian", dabeibaoUI)
    hjapi.DzFrameSetText(dangqianyemian, getCurrentPage(hplayer.loc()) .. "/" .. getMaxPage())
    hjapi.DzFrameSetFont(dangqianyemian, "war3mapImported\\fonts.ttf", 0.010, 0)
    hjapi.DzFrameSetPoint(dangqianyemian, FRAME_ALIGN_BOTTOM, dabeibaoUI, FRAME_ALIGN_BOTTOM, 0.002, 0.0080)
    hjapi.DzFrameShow(dangqianyemian, true)

    local function refreshCailiaobeibao(whichPlayer)
        local startIndex = (getCurrentPage(whichPlayer) - 1) * CONST_MAX_DABEIBAO_PER_PAGE + 1
        local endIndex = getCurrentPage(whichPlayer) * CONST_MAX_DABEIBAO_PER_PAGE
        for i = startIndex, endIndex, 1 do
            local dabeibaoIndex = hplayer.dzCunDang[hplayer.loc()].getDaBeibaoIndexbyUIIndex(i) or i
            hevent.trigger(
                hplayer.loc(),
                CONST_EVENT.dabeibao,
                {
                    index = dabeibaoIndex
                }
            )
        end
        hjapi.DzFrameSetText(dangqianyemian, getCurrentPage(whichPlayer) .. "/" .. getMaxPage(whichPlayer))
    end

    --翻页图标
    local prev_page_back = hjapi.FrameTag("BACKDROP", "prev_page_back", dabeibaoUI)
    hjapi.DzFrameSetPoint(prev_page_back, FRAME_ALIGN_BOTTOM, dabeibaoUI, FRAME_ALIGN_BOTTOM, -0.0150, 0.0030)
    hjapi.DzFrameSetSize(prev_page_back, 0.015, 0.020)
    hjapi.DzFrameSetTexture(prev_page_back, "UI\\AZAchieve\\ui-spellbookicon-prevpage-up.blp")
    hjapi.DzFrameShow(prev_page_back, true)

    --翻页按钮
    local prev_page_button = hjapi.FrameTag("BUTTON", "prev_page_button", prev_page_back)
    hjapi.DzFrameSetPoint(prev_page_button, 4, prev_page_back, 4, 0, 0)
    hjapi.DzFrameSetSize(prev_page_button, 0.015, 0.020)
    hjapi.DzFrameShow(prev_page_button, true)
    hjapi.DzFrameSetScriptByCode(
        prev_page_button,
        MOUSE_ORDER_CLICK,
        function()
            if getCurrentPage(hplayer.loc()) > 1 then
                SetCurrentPage(hplayer.loc(), getCurrentPage(hplayer.loc()) - 1)
                refreshCailiaobeibao(hplayer.loc())
            end
        end,
        false
    )

    --翻页图标
    local next_page_back = hjapi.FrameTag("BACKDROP", "nexk_page_back", dabeibaoUI)
    hjapi.DzFrameSetPoint(next_page_back, FRAME_ALIGN_BOTTOM, dabeibaoUI, FRAME_ALIGN_BOTTOM, 0.015, 0.0030)
    hjapi.DzFrameSetSize(next_page_back, 0.015, 0.020)
    hjapi.DzFrameSetTexture(next_page_back, "UI\\AZAchieve\\ui-spellbookicon-nextpage-up.blp")
    hjapi.DzFrameShow(next_page_back, true)

    --翻页按钮
    local next_page_button = hjapi.FrameTag("BUTTON", "next_page_button", next_page_back)
    hjapi.DzFrameSetPoint(next_page_button, 4, next_page_back, 4, 0, 0)
    hjapi.DzFrameSetSize(next_page_button, 0.015, 0.020)
    hjapi.DzFrameShow(next_page_button, true)
    hjapi.DzFrameSetScriptByCode(
        next_page_button,
        MOUSE_ORDER_CLICK,
        function()
            if getCurrentPage(hplayer.loc()) < getMaxPage(hplayer.loc()) then
                SetCurrentPage(hplayer.loc(), getCurrentPage(hplayer.loc()) + 1)
                refreshCailiaobeibao(hplayer.loc())
            end
        end,
        false
    )
end

local function init_dabeibao_UI()
    local dabeibaoUI = hjapi.FrameTag("BACKDROP", "dabeibeiUI", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetSize(dabeibaoUI, 0.259, 0.375)
    hjapi.DzFrameSetPoint(dabeibaoUI, 0, hjapi.DzGetGameUI(), 0, 0.41, -0.06)
    hjapi.DzFrameSetTexture(dabeibaoUI, "UI\\ShopPage.blp")
    hjapi.DzFrameShow(dabeibaoUI, false)
    UI_global_dabeibaoUI = dabeibaoUI
    local bagRx = 0.040
    local bagRy = 0.018
    --整理背包图标
    local zhenglibeibao_back = hjapi.FrameTag("BACKDROP", "zhuangbei_zhenglibeibao_back", dabeibaoUI, "")
    hjapi.DzFrameSetPoint(zhenglibeibao_back, 0, dabeibaoUI, 0, 0.19, -0.0010)
    hjapi.DzFrameSetSize(zhenglibeibao_back, bagRx, bagRy)
    hjapi.DzFrameSetTexture(zhenglibeibao_back, "ReplaceableTextures\\xitong\\ui_zhenlibeibao.blp")
    hjapi.DzFrameShow(zhenglibeibao_back, true)

    --整理背包文本
    local zhenglibeibao_txt = hjapi.FrameTag("TEXT", "zhuangbei_zhenglibeibao_txt", zhenglibeibao_back)
    hjapi.DzFrameSetPoint(zhenglibeibao_txt, 4, zhenglibeibao_back, 4, 0, 0.0020)
    hjapi.DzFrameShow(zhenglibeibao_txt, true)
    hjapi.DzFrameSetText(zhenglibeibao_txt, "整理背包")
    --按钮
    local zhenglibeibao_button = hjapi.FrameTag("BUTTON", "zhuangbei_zhenglibeibao_button", zhenglibeibao_back, nil)
    hjapi.DzFrameSetPoint(zhenglibeibao_button, 4, zhenglibeibao_back, 4, 0, 0)
    hjapi.DzFrameSetSize(zhenglibeibao_button, bagRx, bagRy)
    hjapi.DzFrameShow(zhenglibeibao_button, true)
    hjapi.DzFrameSetScriptByCode(
        zhenglibeibao_button,
        MOUSE_ORDER_CLICK,
        function()
            hsync.send("zhenglizhuangbeibeibao", {})
        end,
        false
    )

    --关闭图标
    local guanbi_back = hjapi.FrameTag("BACKDROP", "beibao_guanbi", dabeibaoUI, "")
    hjapi.DzFrameSetPoint(guanbi_back, 2, dabeibaoUI, 2, -0.0020, -0.0050)
    hjapi.DzFrameSetSize(guanbi_back, 0.015, 0.020)
    hjapi.DzFrameSetTexture(guanbi_back, "ReplaceableTextures\\xitong\\ui_guanbianniu.blp")
    hjapi.DzFrameShow(guanbi_back, true)

    --按钮
    local guanbi_button = hjapi.FrameTag("BUTTON", "guanbi_button", guanbi_back, nil)
    hjapi.DzFrameSetPoint(guanbi_button, 4, guanbi_back, 4, 0, 0)
    hjapi.DzFrameSetSize(guanbi_button, 0.015, 0.020)
    hjapi.DzFrameShow(guanbi_button, true)
    hjapi.DzFrameSetScriptByCode(
        guanbi_button,
        MOUSE_ORDER_CLICK,
        function()
            turnOffUI("大背包")
        end,
        false
    )

    --装备背包图标
    local zhuangbeibiaoqian = hjapi.FrameTag("BACKDROP", "zhuangbeibeibaotag", dabeibaoUI, "")
    hjapi.DzFrameSetPoint(zhuangbeibiaoqian, 0, dabeibaoUI, 0, 0, -0.0050)
    hjapi.DzFrameSetSize(zhuangbeibiaoqian, bagRx, bagRy)
    hjapi.DzFrameSetTexture(zhuangbeibiaoqian, "ReplaceableTextures\\xitong\\ui_zhuangbbiaoqian.blp")
    hjapi.DzFrameShow(zhuangbeibiaoqian, true)

    --材料背包图标
    local cailiaobiaoqian = hjapi.FrameTag("BACKDROP", "cailiaobeibaotag", dabeibaoUI, "")
    hjapi.DzFrameSetPoint(cailiaobiaoqian, 0, dabeibaoUI, 0, 0, -0.1650)
    hjapi.DzFrameSetSize(cailiaobiaoqian, bagRx, bagRy)
    hjapi.DzFrameSetTexture(cailiaobiaoqian, "ReplaceableTextures\\xitong\\ui_cailiaobiaoqian.blp")
    hjapi.DzFrameShow(cailiaobiaoqian, true)

    hsync.onSend(
        "zhenglizhuangbeibeibao",
        function(syncData)
            if hplayer.getMainHero(syncData.triggerPlayer) == nil then
                echo("请先选择英雄", syncData.triggerPlayer)
                return
            end
            if htime.setupAndCheckCoolDown(syncData.triggerPlayer, "zhenglibeibao", 5) == false then
                echo("整理背包冷却中（5秒）", syncData.triggerPlayer)
                return
            end
            hplayer.dzCunDang[syncData.triggerPlayer].updateSortedInventoryIdx()
            for i = 1, hdzcundang.getMaxCailiaoBeibaoCount(hplayer.loc()) do
                hevent.trigger(syncData.triggerPlayer, CONST_EVENT.dabeibao, { index = i })
            end
            hplayer.dzCunDang[syncData.triggerPlayer].updateSortedZhuangbeiInventoryIdx()
            for i = 1, hdzcundang.getMaxZhuangbeiBeibaoCount(syncData.triggerPlayer) do
                hevent.trigger(syncData.triggerPlayer, CONST_EVENT.zhuangbeidabeibao, { index = i })
            end
        end
    )
    init_cailiao_dabeibao_UI(dabeibaoUI)
    init_zhuangbei_dabeibao_UI(dabeibaoUI)
end

local function init_shanghaitongji_UI()
    hjapi.DzLoadToc("UI\\shanghaitongji.toc")

    local main = hjapi.DzCreateFrame("SHANGHAITONGJI", hjapi.DzGetGameUI(), 0)
    local detailback = hjapi.DzFrameFindByName("SHANGHAITONGJI_DETAIL_Back", 0)
    hjapi.DzFrameSetAlpha(detailback, 150)
    hjapi.DzFrameSetAbsolutePoint(main, 2, 0.8, 0.30)

    htime.setInterval(
        1,
        function(curTimer)
            hplayer.forEach(
                function(enumPlayer, _)
                    if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                        return
                    end
                    local damage_data = hcache.get(enumPlayer, CONST_CACHE.SKILL_EFFECT .. "shanghaitongji_damage")
                    if damage_data == nil then
                        damage_data = {}
                        damage_data.overallDamage = 0
                        damage_data.globalView = {}
                        damage_data.detail = {}
                        damage_data.count_detail = {}
                        damage_data.timePassed = 1
                        hcache.set(enumPlayer, CONST_CACHE.SKILL_EFFECT .. "shanghaitongji_damage", damage_data)
                    end
                    if
                        hfightzhuangtai.isInFight(hplayer.getMainHero(enumPlayer)) == true or
                        htime.inc - hcache.get(enumPlayer, CONST_CACHE.LAST_DAMAGE_TIME, 0) <= 100
                    then
                        damage_data.timePassed = damage_data.timePassed + 1
                    end
                    local msg = {}
                    if damage_data.overallDamage > 0 then
                        table.insert(
                            msg,
                            hcolor.yellow("秒伤DPS") ..
                            ": " .. tostring(math.floor(damage_data.overallDamage / damage_data.timePassed))
                        )
                        table.insert(msg, hcolor.yellow("总伤害: ") .. tostring(math.floor(damage_data.overallDamage)))
                        table.insert(msg, hcolor.yellow("战斗时间: ") .. tostring(damage_data.timePassed))
                        table.insert(msg, "")
                        table.insert(msg, hcolor.yellow("技能详情: （占比/次数）"))
                        local damage_arrary = {}
                        for key in pairs(damage_data.detail) do
                            table.insert(damage_arrary, key)
                        end
                        table.sort(
                            damage_arrary,
                            function(k1, k2)
                                return damage_data.detail[k1] > damage_data.detail[k2]
                            end
                        )
                        for i, key in ipairs(damage_arrary) do
                            if i <= 8 then
                                table.insert(
                                    msg,
                                    i ..
                                    " " ..
                                    key ..
                                    ": " ..
                                    string.floatToPctStr(
                                        damage_data.detail[key] / damage_data.overallDamage
                                    ) ..
                                    "（" .. damage_data.count_detail[key] .. "）"
                                )
                            end
                        end
                    end

                    local globalMsg = {}
                    local global_damage_arrary = {}
                    local totalDamage = 0
                    for key in pairs(damage_data.globalView) do
                        table.insert(global_damage_arrary, key)
                        totalDamage = damage_data.globalView[key] + totalDamage
                    end
                    table.sort(
                        global_damage_arrary,
                        function(k1, k2)
                            return damage_data.globalView[k1] > damage_data.globalView[k2]
                        end
                    )
                    for i, key in ipairs(global_damage_arrary) do
                        local playerName = hplayer.getName(key)
                        if playerName == "" then
                            playerName = "无名"
                        end
                        if i <= 8 then
                            table.insert(
                                globalMsg,
                                i ..
                                " " ..
                                hplayer.getName(key) ..
                                ": " ..
                                tostring(math.floor(damage_data.globalView[key])) ..
                                "(" ..
                                string.floatToPctStr(damage_data.globalView[key] / totalDamage) ..
                                ")"
                            )
                        end
                    end
                    local moshi = hcache.get(hplayer.loc(), "SHANGHAITONGJI_MOSHI")
                    if enumPlayer == hplayer.loc() then
                        if moshi == nil or moshi == false then
                            hjapi.DzFrameSetText(
                                hjapi.DzFrameFindByName("SHANGHAITONGJI_DETAIL_Desc", 0),
                                string.implode("|n", msg)
                            )
                        else
                            hjapi.DzFrameSetText(
                                hjapi.DzFrameFindByName("SHANGHAITONGJI_DETAIL_Desc", 0),
                                string.implode("|n", globalMsg)
                            )
                        end
                    end
                end
            )
        end
    )

    hjapi.DzFrameSetScriptByCode(
        hjapi.DzFrameFindByName("SHANGHAITONGJI_CLOSE", 0),
        MOUSE_ORDER_CLICK,
        function()
            local close = hcache.get(hplayer.loc(), "SHANGHAITONGJI_CLOSE")
            if close == nil or close == false then
                close = true
            else
                close = false
            end
            hcache.set(hplayer.loc(), "SHANGHAITONGJI_CLOSE", close)
            if close == true then
                hjapi.DzFrameShow(hjapi.DzFrameFindByName("SHANGHAITONGJI_CONTROL_REFRESH", 0), true)
                hjapi.DzFrameShow(hjapi.DzFrameFindByName("SHANGHAITONGJI_CONTROL_MOSHI", 0), true)
                hjapi.DzFrameShow(hjapi.DzFrameFindByName("SHANGHAITONGJI_DETAIL", 0), true)
                hjapi.DzFrameSetText(hjapi.DzFrameFindByName("SHANGHAITONGJI_CLOSE_Desc", 0), "关闭")
            else
                hjapi.DzFrameShow(hjapi.DzFrameFindByName("SHANGHAITONGJI_CONTROL_REFRESH", 0), false)
                hjapi.DzFrameShow(hjapi.DzFrameFindByName("SHANGHAITONGJI_CONTROL_MOSHI", 0), false)
                hjapi.DzFrameShow(hjapi.DzFrameFindByName("SHANGHAITONGJI_DETAIL", 0), false)
                hjapi.DzFrameSetText(hjapi.DzFrameFindByName("SHANGHAITONGJI_CLOSE_Desc", 0), "开启")
            end
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        hjapi.DzFrameFindByName("SHANGHAITONGJI_MOSHI", 0),
        MOUSE_ORDER_CLICK,
        function()
            local moshi = hcache.get(hplayer.loc(), "SHANGHAITONGJI_MOSHI")
            if moshi == nil or moshi == false then
                moshi = true
            else
                moshi = false
            end
            hcache.set(hplayer.loc(), "SHANGHAITONGJI_MOSHI", moshi)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        hjapi.DzFrameFindByName("SHANGHAITONGJI_REFRESH", 0),
        MOUSE_ORDER_CLICK,
        function()
            hsync.send("RefreshShanghaitongji", { hplayer.index(hplayer.loc()) })
        end,
        false
    )
    hsync.onSend(
        "RefreshShanghaitongji",
        function(syncData)
            local whichPlayer = hplayer.players[tonumber(syncData.triggerData[1])]
            if whichPlayer == nil then
                err("bad user")
            end
            hcache.free(whichPlayer, CONST_CACHE.SKILL_EFFECT .. "shanghaitongji_damage")
        end
    )
end

local function formatDuration(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    local result = ""

    if hours > 0 then
        result = hours .. "h"
    end

    if minutes > 0 or hours > 0 then
        result = result .. minutes .. "m"
    elseif secs < 60 then
        result = string.format("%.1f", secs)
    else
        result = result .. secs .. "s"
    end

    return result
end
local function init_buff_UI()
    hjapi.DzLoadToc("UI\\frame.toc")
    hjapi.DzLoadToc("UI\\shanghaitongji.toc")
    local ui_max_positive = 16 --最大正面buff数,偶数
    local ui_max_negative = 12 --最大负面buff数,偶数
    local bagRx = 0.016
    local bagRy = bagRx * (8 / 6)

    local _buffBtns = {}
    local _buffTxt = {}
    local _buffStack = {}
    local _buffExts = {}
    local _buffBorders = {}
    local _buffToolTipsBG = {}
    local _buffToolTipsText = {}
    local _buffBtnsNegative = {}
    local _buffTxtNegative = {}
    local _buffStackNegative = {}
    local _buffExtsNegative = {}
    local _buffBordersNegative = {}
    local _buffToolTipsBGNegative = {}
    local _buffToolTipsTextNegative = {}

    for i = 1, ui_max_positive do
        local x = -0.116 + bagRx * (i - 1)
        local y = 0.145 + bagRy
        local half = ui_max_positive / 2
        if (i > half) then
            x = -0.116 + bagRx * (i - half - 1)
            y = y + bagRy * (3 / 2)
        end

        --buff图标
        _buffExts[i] = hjapi.FrameTag("BACKDROP", "sdk_buff->ext->" .. i, hjapi.DzGetGameUI(), "")
        hjapi.DzFrameSetPoint(_buffExts[i], 7, hjapi.DzGetGameUI(), 7, x, y)
        hjapi.DzFrameSetSize(_buffExts[i], bagRx, bagRy)
        hjapi.DzFrameShow(_buffExts[i], false)

        --三角图标
        _buffBorders[i] = hjapi.FrameTag("BACKDROP", "sdk_buff->border->" .. i, _buffExts[i], "")
        hjapi.DzFrameSetPoint(_buffBorders[i], 4, _buffExts[i], 4, 0, 0)
        hjapi.DzFrameSetSize(_buffBorders[i], bagRx, bagRy)
        hjapi.DzFrameShow(_buffBorders[i], true)

        --时间文本
        _buffTxt[i] = hjapi.FrameTag("TEXT", "T666", _buffExts[i])
        hjapi.DzFrameSetFont(_buffTxt[i], "war3mapImported\\fonts.ttf", 0.010, 0)
        hjapi.DzFrameSetText(_buffTxt[i], "")
        hjapi.DzFrameSetPoint(_buffTxt[i], 4, _buffExts[i], 4, 0, -bagRy * (2.0 / 3))
        hjapi.DzFrameShow(_buffTxt[i], true)

        --叠加层数文本
        _buffStack[i] = hjapi.FrameTag("TEXT", "stack", _buffExts[i])
        hjapi.DzFrameSetFont(_buffStack[i], "war3mapImported\\fonts.ttf", 0.010, 0)
        hjapi.DzFrameSetText(_buffStack[i], "")
        hjapi.DzFrameSetPoint(_buffStack[i], 4, _buffExts[i], 4, 0, 0)
        hjapi.DzFrameShow(_buffStack[i], true)

        --按钮
        _buffBtns[i] = hjapi.FrameTag("BUTTON", "sdk_buff->btn->" .. i, _buffExts[i], nil)
        hjapi.DzFrameSetPoint(_buffBtns[i], 4, _buffExts[i], 4, 0, 0)
        hjapi.DzFrameSetSize(_buffBtns[i], bagRx, bagRy)
        hjapi.DzFrameShow(_buffBtns[i], true)

        --说明文本
        _buffToolTipsBG[i] =
            hjapi.DzCreateFrameByTagName(
                "BACKDROP",
                "_buffToolTipsBG" .. tostring(i),
                hjapi.DzGetGameUI(),
                "shanghaitongji",
                0
            )

        _buffToolTipsText[i] =
            hjapi.DzCreateFrameByTagName("TEXT", "_buffToolTipsText" .. tostring(i), _buffToolTipsBG[i], "", 0)
        hjapi.DzFrameSetFont(_buffToolTipsText[i], "war3mapImported\\fonts.ttf", 0.010, 0)
        hjapi.DzFrameSetSize(_buffToolTipsText[i], 0.15, 0.0)
        hjapi.DzFrameSetPoint(_buffToolTipsBG[i], 0, _buffToolTipsText[i], 0, -0.005, 0.005)
        hjapi.DzFrameSetPoint(_buffToolTipsBG[i], 8, _buffToolTipsText[i], 8, 0.005, -0.005)
        hjapi.DzFrameSetPoint(_buffToolTipsText[i], 6, _buffBtns[i], 2, 0.01, 0.01)
        hjapi.DzFrameShow(_buffToolTipsBG[i], false)
        hjapi.DzFrameShow(_buffToolTipsText[i], true)
        hjapi.DzFrameSetEnable(_buffToolTipsText[i], false)
        --hjapi.DzFrameSetTooltip(_buffBtns[i], _buffToolTipsBG[i])

        hjapi.DzFrameSetScriptByCode(
            _buffBtns[i],
            MOUSE_ORDER_ENTER,
            function()
                hjapi.DzFrameShow(_buffToolTipsBG[i], true)
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            _buffBtns[i],
            MOUSE_ORDER_LEAVE,
            function()
                hjapi.DzFrameShow(_buffToolTipsBG[i], false)
            end,
            false
        )
    end

    for i = 1, ui_max_negative do
        local x = 0.1 - bagRx * (i - 1)
        local y = 0.145 + bagRy
        local half = ui_max_negative / 2
        if (i > half) then
            x = 0.1 - bagRx * (i - half - 1)
            y = y + bagRy * (3 / 2)
        end

        --buff图标
        _buffExtsNegative[i] = hjapi.FrameTag("BACKDROP", "sdk_buff->ext->" .. i, hjapi.DzGetGameUI(), "")
        hjapi.DzFrameSetPoint(_buffExtsNegative[i], 7, hjapi.DzGetGameUI(), 7, x, y)
        hjapi.DzFrameSetSize(_buffExtsNegative[i], bagRx, bagRy)
        hjapi.DzFrameShow(_buffExtsNegative[i], false)

        --三角图标
        _buffBordersNegative[i] = hjapi.FrameTag("BACKDROP", "sdk_buff->border->" .. i, _buffExtsNegative[i], "")
        hjapi.DzFrameSetPoint(_buffBordersNegative[i], 4, _buffExtsNegative[i], 4, 0, 0)
        hjapi.DzFrameSetSize(_buffBordersNegative[i], bagRx, bagRy)
        hjapi.DzFrameShow(_buffBordersNegative[i], true)

        --时间文本
        _buffTxtNegative[i] = hjapi.FrameTag("TEXT", "T666", _buffExtsNegative[i])
        hjapi.DzFrameSetFont(_buffTxtNegative[i], "war3mapImported\\fonts.ttf", 0.010, 0)
        hjapi.DzFrameSetText(_buffTxtNegative[i], "")
        hjapi.DzFrameSetPoint(_buffTxtNegative[i], 4, _buffExtsNegative[i], 4, 0, -bagRy * (2.0 / 3))
        hjapi.DzFrameShow(_buffTxtNegative[i], true)

        --叠加层数文本
        _buffStackNegative[i] = hjapi.FrameTag("TEXT", "stack", _buffExtsNegative[i])
        hjapi.DzFrameSetFont(_buffStackNegative[i], "war3mapImported\\fonts.ttf", 0.010, 0)
        hjapi.DzFrameSetText(_buffStackNegative[i], "")
        hjapi.DzFrameSetPoint(_buffStackNegative[i], 4, _buffExtsNegative[i], 4, 0, 0)
        hjapi.DzFrameShow(_buffStackNegative[i], true)

        --按钮
        _buffBtnsNegative[i] = hjapi.FrameTag("BUTTON", "sdk_buff->btn->" .. i, _buffExtsNegative[i], nil)
        hjapi.DzFrameSetPoint(_buffBtnsNegative[i], 4, _buffExtsNegative[i], 4, 0, 0)
        hjapi.DzFrameSetSize(_buffBtnsNegative[i], bagRx, bagRy)
        hjapi.DzFrameShow(_buffBtnsNegative[i], true)

        --说明文本
        _buffToolTipsBGNegative[i] =
            hjapi.DzCreateFrameByTagName(
                "BACKDROP",
                "_buffToolTipsBGNegative" .. tostring(i),
                hjapi.DzGetGameUI(),
                "shanghaitongji",
                0
            )
        _buffToolTipsTextNegative[i] =
            hjapi.DzCreateFrameByTagName(
                "TEXT",
                "_buffToolTipsTextNegative" .. tostring(i),
                _buffToolTipsBGNegative[i],
                "",
                0
            )
        hjapi.DzFrameSetFont(_buffToolTipsTextNegative[i], "war3mapImported\\fonts.ttf", 0.010, 0)
        hjapi.DzFrameSetSize(_buffToolTipsTextNegative[i], 0.15, 0.0)
        hjapi.DzFrameSetPoint(_buffToolTipsBGNegative[i], 0, _buffToolTipsTextNegative[i], 0, -0.005, 0.005)
        hjapi.DzFrameSetPoint(_buffToolTipsBGNegative[i], 8, _buffToolTipsTextNegative[i], 8, 0.005, -0.005)
        hjapi.DzFrameSetPoint(_buffToolTipsTextNegative[i], 6, _buffBtnsNegative[i], 2, 0.01, 0.01)
        hjapi.DzFrameShow(_buffToolTipsBGNegative[i], false)
        hjapi.DzFrameShow(_buffToolTipsTextNegative[i], true)
        hjapi.DzFrameSetEnable(_buffToolTipsTextNegative[i], false)
        --hjapi.DzFrameSetTooltip(_buffBtnsNegative[i], _buffToolTipsBGNegative[i])
        hjapi.DzFrameSetScriptByCode(
            _buffBtnsNegative[i],
            MOUSE_ORDER_ENTER,
            function()
                hjapi.DzFrameShow(_buffToolTipsBGNegative[i], true)
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            _buffBtnsNegative[i],
            MOUSE_ORDER_LEAVE,
            function()
                hjapi.DzFrameShow(_buffToolTipsBGNegative[i], false)
            end,
            false
        )
    end

    htime.setInterval(
        0.1,
        function(_)
            for _, player in ipairs(hplayer.players) do
                if hplayer.isPlaying(player) then
                    local selection = hplayer.getSelection(player)
                    local show = false
                    local positiveShowIdx = {}
                    local negativeShowIdx = {}
                    if (selection ~= nil) then
                        if (hunit.isAlive(selection)) then
                            local buffHandle = hcache.get(selection, BUFF_KEY)
                            if (buffHandle ~= nil) then
                                show = true
                                local positiveBuff = {}
                                local negativeBuff = {}
                                if (type(buffHandle) == "table") and buffHandle._idx ~= nil then
                                    for _, bidx in ipairs(buffHandle._idx) do
                                        local curBuff = buffHandle[bidx]
                                        local positive = curBuff.positive
                                        local description = curBuff.description
                                        local art = curBuff.art
                                        local stack = curBuff.stack
                                        local signal = ""
                                        if (positive) then
                                            signal = "buffIcon\\up.tga"
                                        else
                                            signal = "buffIcon\\down.tga"
                                        end
                                        local remain = nil
                                        if curBuff.timer ~= nil then
                                            remain = math.round(curBuff.timer.remain(), 1)
                                            if curBuff.interval ~= nil and curBuff.remainingTime ~= nil then
                                                remain = remain + curBuff.remainingTime - curBuff.interval
                                                if remain >= 36000 then
                                                    remain = "常驻"
                                                end
                                            end
                                        else
                                            remain = "常驻"
                                        end
                                        local s = {
                                            signal = signal,
                                            description = description,
                                            art = art,
                                            stack = stack,
                                            remain = remain
                                        }
                                        if art ~= nil then
                                            if positive then
                                                table.insert(positiveBuff, s)
                                            else
                                                table.insert(negativeBuff, s)
                                            end
                                        end
                                    end
                                end
                                if show and player == hplayer.loc() then
                                    for idxs, v in ipairs(positiveBuff) do
                                        if (idxs <= ui_max_positive) then
                                            positiveShowIdx[idxs] = true
                                            local t = v.remain
                                            hjapi.DzFrameSetTexture(_buffBorders[idxs], v.signal, false)
                                            if type(t) == "number" then
                                                hjapi.DzFrameSetText(_buffTxt[idxs], formatDuration(t))
                                            else
                                                hjapi.DzFrameSetText(_buffTxt[idxs], t)
                                            end
                                            hjapi.DzFrameSetTexture(_buffExts[idxs], v.art, false)
                                            hjapi.DzFrameSetText(_buffToolTipsText[idxs], v.description)
                                            if v.stack > 1 then
                                                hjapi.DzFrameSetText(_buffStack[idxs], v.stack)
                                            else
                                                hjapi.DzFrameSetText(_buffStack[idxs], "")
                                            end
                                            if (type(t) == "number" and t <= 3) then
                                                local transparency = 50 + 255 * t / 3
                                                hjapi.DzFrameSetAlpha(_buffTxt[idxs], transparency)
                                                hjapi.DzFrameSetAlpha(_buffExts[idxs], transparency)
                                                hjapi.DzFrameSetAlpha(_buffBorders[idxs], transparency)
                                            else
                                                hjapi.DzFrameSetAlpha(_buffTxt[idxs], 255)
                                                hjapi.DzFrameSetAlpha(_buffExts[idxs], 255)
                                                hjapi.DzFrameSetAlpha(_buffBorders[idxs], 255)
                                            end
                                        end
                                    end
                                    for idxs, v in ipairs(negativeBuff) do
                                        if (idxs <= ui_max_negative) then
                                            negativeShowIdx[idxs] = true
                                            local t = v.remain
                                            hjapi.DzFrameSetTexture(_buffBordersNegative[idxs], v.signal, false)
                                            if type(t) == "number" then
                                                hjapi.DzFrameSetText(_buffTxtNegative[idxs], formatDuration(t))
                                            else
                                                hjapi.DzFrameSetText(_buffTxtNegative[idxs], t)
                                            end
                                            hjapi.DzFrameSetTexture(_buffExtsNegative[idxs], v.art, false)
                                            hjapi.DzFrameSetText(_buffToolTipsTextNegative[idxs], v.description)
                                            if v.stack > 1 then
                                                hjapi.DzFrameSetText(_buffStackNegative[idxs], v.stack)
                                            else
                                                hjapi.DzFrameSetText(_buffStackNegative[idxs], "")
                                            end
                                            if (type(t) == "number" and t <= 3) then
                                                local transparency = 50 + 255 * t / 3
                                                hjapi.DzFrameSetAlpha(_buffTxtNegative[idxs], transparency)
                                                hjapi.DzFrameSetAlpha(_buffExtsNegative[idxs], transparency)
                                                hjapi.DzFrameSetAlpha(_buffBordersNegative[idxs], transparency)
                                            else
                                                hjapi.DzFrameSetAlpha(_buffTxtNegative[idxs], 255)
                                                hjapi.DzFrameSetAlpha(_buffExtsNegative[idxs], 255)
                                                hjapi.DzFrameSetAlpha(_buffBordersNegative[idxs], 255)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if player == hplayer.loc() then
                            for k, _ in ipairs(_buffBtns) do
                                if (show and positiveShowIdx[k] == true) then
                                    hjapi.DzFrameShow(_buffExts[k], true)
                                else
                                    hjapi.DzFrameShow(_buffExts[k], false)
                                end
                            end
                            for k, _ in ipairs(_buffBtnsNegative) do
                                if (show and negativeShowIdx[k] == true) then
                                    hjapi.DzFrameShow(_buffExtsNegative[k], true)
                                else
                                    hjapi.DzFrameShow(_buffExtsNegative[k], false)
                                end
                            end
                        end
                    end
                end
            end
        end
    )
end

local function init_zhuangbeitishi_UI()
    hjapi.DzLoadToc("UI\\ui_tips.toc")
    local tipsFrame = hjapi.DzCreateFrame("ALL_Tips", hjapi.DzGetGameUI(), 0)
    local back = hjapi.DzFrameFindByName("ALL_Tips_Back", 0)
    local desc = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
    hjapi.DzFrameSetPoint(back, 0, desc, 0, -0.009, 0.009)
    hjapi.DzFrameSetPoint(back, 8, desc, 8, 0.009, -0.009)
    hjapi.DzFrameShow(tipsFrame, false)
    local tipsFrame = hjapi.DzCreateFrame("ALL_Tips_COMPAREA", hjapi.DzGetGameUI(), 0)
    local back = hjapi.DzFrameFindByName("ALL_Tips_COMPAREA_Back", 0)
    local desc = hjapi.DzFrameFindByName("ALL_Tips_COMPAREA_Desc", 0)
    hjapi.DzFrameSetPoint(back, 0, desc, 0, -0.009, 0.009)
    hjapi.DzFrameSetPoint(back, 8, desc, 8, 0.009, -0.009)
    hjapi.DzFrameShow(tipsFrame, false)
    local tipsFrame = hjapi.DzCreateFrame("ALL_Tips_COMPAREB", hjapi.DzGetGameUI(), 0)
    local back = hjapi.DzFrameFindByName("ALL_Tips_COMPAREB_Back", 0)
    local desc = hjapi.DzFrameFindByName("ALL_Tips_COMPAREB_Desc", 0)
    hjapi.DzFrameSetPoint(back, 0, desc, 0, -0.009, 0.009)
    hjapi.DzFrameSetPoint(back, 8, desc, 8, 0.009, -0.009)
    hjapi.DzFrameShow(tipsFrame, false)
    hjapi.DzCreateFrame("DiMian_Tips", hjapi.DzGetGameUI(), 0)
    local back = hjapi.DzFrameFindByName("DiMian_Tips_Back", 0)
    local desc = hjapi.DzFrameFindByName("DiMian_Tips_Desc", 0)
    hjapi.DzFrameSetPoint(back, 0, desc, 0, -0.009, 0.009)
    hjapi.DzFrameSetPoint(back, 8, desc, 8, 0.009, -0.009)
    hjapi.DzCreateFrame("DiMian_Tips_COMPAREA", hjapi.DzGetGameUI(), 0)
    local back = hjapi.DzFrameFindByName("DiMian_Tips_COMPAREA_Back", 0)
    local desc = hjapi.DzFrameFindByName("DiMian_Tips_COMPAREA_Desc", 0)
    hjapi.DzFrameSetPoint(back, 0, desc, 0, -0.009, 0.009)
    hjapi.DzFrameSetPoint(back, 8, desc, 8, 0.009, -0.009)
    hjapi.DzCreateFrame("DiMian_Tips_COMPAREB", hjapi.DzGetGameUI(), 0)
    local back = hjapi.DzFrameFindByName("DiMian_Tips_COMPAREB_Back", 0)
    local desc = hjapi.DzFrameFindByName("DiMian_Tips_COMPAREB_Desc", 0)
    hjapi.DzFrameSetPoint(back, 0, desc, 0, -0.009, 0.009)
    hjapi.DzFrameSetPoint(back, 8, desc, 8, 0.009, -0.009)

    local gameTimerPanel = hjapi.DzCreateFrame("GAME_TIMER", hjapi.DzGetGameUI(), 0)
    local back = hjapi.DzFrameFindByName("GAME_TIMER_Back", 0)
    local desc = hjapi.DzFrameFindByName("GAME_TIMER_Desc", 0)
    hjapi.DzFrameSetPoint(back, 0, desc, 0, -0.009, 0.009)
    hjapi.DzFrameSetPoint(back, 8, desc, 8, 0.009, -0.009)
    hjapi.DzFrameSetPoint(desc, 2, hjapi.DzGetGameUI(), 2, 0, -0.03)
    hjapi.DzFrameSetSize(desc, 0.15, 0)
    hjapi.DzFrameShow(gameTimerPanel, true)
    hjapi.DzFrameSetText(desc, "游戏初始化中……")

    local fubenTimerPanel = hjapi.DzCreateFrame("FUBEN_TIMER", hjapi.DzGetGameUI(), 0)
    local back = hjapi.DzFrameFindByName("FUBEN_TIMER_Back", 0)
    local newdesc = hjapi.DzFrameFindByName("FUBEN_TIMER_Desc", 0)
    hjapi.DzFrameSetPoint(back, 0, newdesc, 0, -0.009, 0.009)
    hjapi.DzFrameSetPoint(back, 8, newdesc, 8, 0.009, -0.009)
    hjapi.DzFrameSetPoint(newdesc, FRAME_ALIGN_RIGHT, desc, FRAME_ALIGN_LEFT, -0.05, 0)
    hjapi.DzFrameSetSize(newdesc, 0.15, 0)
    hjapi.DzFrameShow(fubenTimerPanel, false)
    hjapi.DzFrameSetText(newdesc, "副本未开始")

    --[[local modelTips = hjapi.DzCreateFrame("Tips_Model", hjapi.DzGetGameUI(), 0)
    local back = hjapi.DzFrameFindByName("Tips_Model_Back", 0)
    local model = hjapi.DzFrameFindByName("Tips_Model_Model", 0)
    hjapi.DzFrameSetPoint(back, 0, model, 0, -0.009, 0.009)
    hjapi.DzFrameSetPoint(back, 8, model, 8, 0.009, -0.009)
    hjapi.DzFrameSetPoint(model, 2, hjapi.DzGetGameUI(), 2, -0.3, -0.13)
    hjapi.DzFrameSetSize(model, 0.1, 0.1)
    hjapi.DzFrameSetModel(model, "war3mapImported\\[pifu]M2.mdx", 0, 0)
    hjapi.DzFrameShow(modelTips, true)]]
end

local function init_attribute_UI()
    hjapi.DzLoadToc("UI\\ui_attribute.toc")
    local attribute = hjapi.DzCreateFrame("ALL_Attribute", hjapi.DzGetGameUI(), 0)
    hjapi.DzFrameShow(attribute, false)
end

local function init_quest_UI()
    hjapi.DzLoadToc("UI\\ui_quest.toc")
    local back = hjapi.DzCreateFrame("QUEST_SIMPLE", hjapi.DzGetGameUI(), 0)
    local backback = hjapi.DzFrameFindByName("QUEST_SIMPLE_Back", 0)
    hjapi.DzFrameSetAlpha(backback, 150)
    hjapi.DzFrameSetAbsolutePoint(back, 2, 0.8, 0.5)
    htime.setInterval(
        0.5,
        function(curTimer)
            hplayer.forEach(
                function(enumPlayer, _)
                    if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                        return
                    end
                    local msg = hquestcustom.getQuestUIContent(enumPlayer)
                    local height = string.calculateUIHeight(msg, 0.1200, 0.0029, 0.005)
                    if enumPlayer == hplayer.loc() then
                        hjapi.DzFrameSetSize(back, 0.1200, height)
                        hjapi.DzFrameSetText(hjapi.DzFrameFindByName("QUEST_SIMPLE_Desc", 0), msg)
                    end
                end
            )
        end
    )
end

local function init_bag_trigger_and_tooltip()
    local currentButtonPosition = -1
    local lastClickPosition = -1
    local lastClickTime = -1
    --注册按钮点击事件
    --同步
    hsync.onSend(
        "moveItemToInventory",
        function(syncData)
            hplayer.dzCunDang[syncData.triggerPlayer].moveItemFromBagToInventory(
                hplayer.getMainHero(syncData.triggerPlayer),
                tonumber(syncData.triggerData[1])
            )
        end
    )

    for i = 0, 5 do
        local button = hjapi.DzFrameGetItemBarButton(i)
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_ENTER,
            function()
                local player = hplayer.loc()
                currentButtonPosition = i
                local selected_unit = hplayer.getSelection(player)
                if selected_unit ~= nil then
                    local item = cj.UnitItemInSlot(selected_unit, i)
                    local dynamicItem = hitem.getDynamicItem(item)
                    if dynamicItem == nil then
                        hjapi.DzFrameShow(back, false)
                    else
                        local msg = dynamicItem.getDescription()
                        local back = hjapi.DzFrameFindByName("ALL_Tips", 0)
                        local text = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
                        hjapi.DzFrameClearAllPoints(text)
                        hjapi.DzFrameSetAbsolutePoint(text, 6, 0.585, 0.165)
                        --local height = math.max(string.calculateUIHeight(msg, 0.225), 0.15)
                        hjapi.DzFrameSetSize(text, 0.225, 0)
                        hjapi.DzFrameSetText(text, msg)
                        hjapi.DzFrameShow(back, true)
                        try_show_compare_view(player, dynamicItem, text, "ALL_Tips")
                    end
                end
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_LEAVE,
            function()
                local back = hjapi.DzFrameFindByName("ALL_Tips", 0)
                hjapi.DzFrameShow(back, false)
                currentButtonPosition = -1
                disable_compare_view("ALL_Tips")
            end,
            false
        )
    end

    -- move item from bag to inventory
    hjapi.DzTriggerRegisterMouseEventByCode(
        nil,
        GAME_KEY_MOUSE_RIGHT,
        GAME_KEY_ACTION_RELEASE,
        false,
        function()
            local slotId = currentButtonPosition
            if slotId ~= -1 then
                --check if an item is owned by a unit
                local selected_unit = hplayer.getSelection(hplayer.loc())
                if selected_unit ~= hplayer.getMainHero(hplayer.loc()) then
                    return
                end
                local item = cj.UnitItemInSlot(selected_unit, slotId)
                if item == nil then
                    return
                end

                if lastClickPosition == slotId and htime.inc - lastClickTime < 55 then
                    hsync.send("moveItemToInventory", { slotId })
                end
                lastClickPosition = slotId
                lastClickTime = htime.inc
            end
        end
    )
end

local function update_achievement_UI_to_page(whichPlayer, targetCategory, targetPage)
    local targetPlayer = getSelectedPlayer(whichPlayer)
    local categoryData = ACHIEVEMENT_DATA[targetPlayer][targetCategory].categoryData
    local totalPageCount = math.max(math.ceil(#categoryData / 18), 1)
    if targetPage == nil or targetPage > totalPageCount or targetPage < 1 then
        return
    end
    ACHIEVEMENT_DATA[whichPlayer].currentCategory = targetCategory
    ACHIEVEMENT_DATA[whichPlayer].currentPage = targetPage
    local pageText = tostring(targetPage) .. "/" .. tostring(totalPageCount)
    hjapi.DzFrameSetText(hjapi.DzFrameFindByName("TxtRootWindow_PageNum", 0), pageText)
    for i = 18 * (targetPage - 1) + 1, 18 * targetPage, 1 do
        local UI_index = i - 18 * (targetPage - 1)
        if i <= #categoryData then
            local UI_index = i - 18 * (targetPage - 1)
            hjapi.DzFrameSetText(
                hjapi.DzFrameFindByName("TxtRootWindow_Item" .. tostring(UI_index) .. "_Name", 0),
                categoryData[i].name
            )
            hjapi.DzFrameSetTexture(
                hjapi.DzFrameFindByName("ImgRootWindow_Item" .. tostring(UI_index) .. "_Icon", 0),
                categoryData[i].art
            )
            if categoryData[i].enable == true then
                hjapi.DzFrameShow(
                    hjapi.DzFrameFindByName("ImgRootWindow_Item" .. tostring(UI_index) .. "_Mask", 0),
                    false
                )
            else
                hjapi.DzFrameShow(
                    hjapi.DzFrameFindByName("ImgRootWindow_Item" .. tostring(UI_index) .. "_Mask", 0),
                    true
                )
            end
            if categoryData[i].equip then
                hjapi.DzFrameShow(
                    hjapi.DzFrameFindByName("ImgRootWindow_Item" .. tostring(UI_index) .. "_ACTIVE", 0),
                    true
                )
            else
                hjapi.DzFrameShow(
                    hjapi.DzFrameFindByName("ImgRootWindow_Item" .. tostring(UI_index) .. "_ACTIVE", 0),
                    false
                )
            end
            if categoryData[i].clear then
                hjapi.DzFrameShow(
                    hjapi.DzFrameFindByName("ImgRootWindow_Item" .. tostring(UI_index) .. "_CLEAR", 0),
                    true
                )
            else
                hjapi.DzFrameShow(
                    hjapi.DzFrameFindByName("ImgRootWindow_Item" .. tostring(UI_index) .. "_CLEAR", 0),
                    false
                )
            end
            hjapi.DzFrameShow(hjapi.DzFrameFindByName("FrmRootWindow_Item" .. tostring(UI_index), 0), true)
        else
            hjapi.DzFrameShow(hjapi.DzFrameFindByName("FrmRootWindow_Item" .. tostring(UI_index), 0), false)
        end
    end
end

local function update_achievement_UI(whichPlayer, targetCategory)
    local selected_unit = hplayer.getSelection(whichPlayer)
    local targetPlayer = getSelectedPlayer(whichPlayer)

    ACHIEVEMENT_DATA[whichPlayer].currentCategory = targetCategory
    ACHIEVEMENT_DATA[whichPlayer].currentPage = 1
    local targetCategoryRightFrame =
        hjapi.DzFrameFindByName(ACHIEVEMENT_DATA[whichPlayer][targetCategory].categoryUIName, 0)
    hjapi.DzFrameSetText(
        hjapi.DzFrameFindByName("TxtRootWindow_Title", 0),
        targetCategory .. " (" .. hjapi.DzAPI_Map_GetPlayerUserName(targetPlayer) .. ")"
    )
    local selectedFrame = hjapi.DzFrameFindByName("ImgRootWindow_Category_Selected", 0)
    hjapi.DzFrameClearAllPoints(selectedFrame)
    hjapi.DzFrameSetSize(selectedFrame, 0.03, 0.032)
    hjapi.DzFrameSetPoint(selectedFrame, 4, targetCategoryRightFrame, 4, 0, 0)
    hjapi.DzFrameShow(selectedFrame, true)
    update_achievement_UI_to_page(whichPlayer, targetCategory, 1)
end
--- ACHIEVEMENT_DATA
--- {
---   whichPlayer: {
---     currentCategory: category string
---     currentPage: int
---     category: {
---       categoryUIName: string
---       categoryData: {
---         {
---           name: string
---           art: path to blp
---           callback: function call when clicked
---           tip: string
---           enable: bool
---         },
---       }
---     }
---   }
--- }
-- init achievement UI

local function build_achievement_data()
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end
            ACHIEVEMENT_DATA[enumPlayer].currentCategory = "任务"
            ACHIEVEMENT_DATA[enumPlayer].currentPage = 1
        end
    )

    -- category to ui category mapping
    local mapping = {}

    mapping["BtnRootWindow_Category_Achieve"] = "任务"
    mapping["BtnRootWindow_Category_Category2"] = "图鉴"
    mapping["BtnRootWindow_Category_Category3"] = "训练"
    mapping["BtnRootWindow_Category_Category4"] = "专业"
    mapping["BtnRootWindow_Category_Category5"] = "成就"
    mapping["BtnRootWindow_Category_Category6"] = "铭文"
    mapping["BtnRootWindow_Category_Category7"] = "坐骑"
    mapping["BtnRootWindow_Category_Category8"] = "声望"
    mapping["BtnRootWindow_Category_Category9"] = "装备收集"
    mapping["BtnRootWindow_Category_Category10"] = "商城"
    mapping["BtnRootWindow_Category_Category11"] = "幻化"
    mapping["BtnRootWindow_Category_Category12"] = "秘境"
    mapping["BtnRootWindow_Category_Category13"] = "秘技"
    mapping["BtnRootWindow_Category_Category14"] = "其它"
    mapping["BtnRootWindow_Category_Category15"] = "神器"

    ACHIEVEMENT_DATA.UITabNameToCategory = mapping
end

function ui_enable_achievement_data_at_category_and_idx(whichPlayer, targetCategory, idx)
    local achievementData = ACHIEVEMENT_DATA[whichPlayer]
    if
        achievementData ~= nil and achievementData[targetCategory] ~= nil and
        achievementData[targetCategory].categoryData ~= nil and
        achievementData[targetCategory].categoryData[idx] ~= nil
    then
        achievementData[targetCategory].categoryData[idx].enable = true
        if
            achievementData.currentCategory == targetCategory and idx <= 18 * achievementData.currentPage and
            idx > 18 * (achievementData.currentPage - 1)
        then
            if whichPlayer == hplayer.loc() then
                hjapi.DzFrameShow(
                    hjapi.DzFrameFindByName(
                        "ImgRootWindow_Item" .. tostring(idx - 18 * (achievementData.currentPage - 1)) .. "_Mask",
                        0
                    ),
                    false
                )
            end
        end
    end
end

function ui_update_art_achievement_data_at_category_and_idx(whichPlayer, targetCategory, idx, art)
    local achievementData = ACHIEVEMENT_DATA[whichPlayer]
    if
        achievementData ~= nil and achievementData[targetCategory] ~= nil and
        achievementData[targetCategory].categoryData ~= nil and
        achievementData[targetCategory].categoryData[idx] ~= nil
    then
        achievementData[targetCategory].categoryData[idx].art = art
        if
            achievementData.currentCategory == targetCategory and idx <= 18 * achievementData.currentPage and
            idx > 18 * (achievementData.currentPage - 1)
        then
            if whichPlayer == hplayer.loc() then
                hjapi.DzFrameSetTexture(
                    hjapi.DzFrameFindByName(
                        "ImgRootWindow_Item" .. tostring(idx - 18 * (achievementData.currentPage - 1)) .. "_Icon",
                        0
                    ),
                    art
                )
            end
        end
    end
end

function ui_update_name_achievement_data_at_category_and_idx(whichPlayer, targetCategory, idx, name)
    local achievementData = ACHIEVEMENT_DATA[whichPlayer]
    if
        achievementData ~= nil and achievementData[targetCategory] ~= nil and
        achievementData[targetCategory].categoryData ~= nil and
        achievementData[targetCategory].categoryData[idx] ~= nil
    then
        achievementData[targetCategory].categoryData[idx].name = name
        if
            achievementData.currentCategory == targetCategory and idx <= 18 * achievementData.currentPage and
            idx > 18 * (achievementData.currentPage - 1)
        then
            if whichPlayer == hplayer.loc() then
                hjapi.DzFrameSetTexture(
                    hjapi.DzFrameFindByName(
                        "TxtRootWindow_Item" .. tostring(idx - 18 * (achievementData.currentPage - 1)) .. "_Name",
                        0
                    ),
                    name
                )
            end
        end
    end
end

function ui_update_equip_achievement_data_at_category_and_idx(whichPlayer, targetCategory, idx, equip, clear)
    equip = equip or false
    clear = clear or false
    local achievementData = ACHIEVEMENT_DATA[whichPlayer]
    if
        achievementData ~= nil and achievementData[targetCategory] ~= nil and
        achievementData[targetCategory].categoryData ~= nil and
        achievementData[targetCategory].categoryData[idx] ~= nil
    then
        achievementData[targetCategory].categoryData[idx].equip = equip
        achievementData[targetCategory].categoryData[idx].clear = clear
        if
            achievementData.currentCategory == targetCategory and idx <= 18 * achievementData.currentPage and
            idx > 18 * (achievementData.currentPage - 1)
        then
            if whichPlayer == hplayer.loc() then
                hjapi.DzFrameShow(
                    hjapi.DzFrameFindByName(
                        "ImgRootWindow_Item" .. tostring(idx - 18 * (achievementData.currentPage - 1)) .. "_ACTIVE",
                        0
                    ),
                    equip
                )
                hjapi.DzFrameShow(
                    hjapi.DzFrameFindByName(
                        "ImgRootWindow_Item" .. tostring(idx - 18 * (achievementData.currentPage - 1)) .. "_CLEAR",
                        0
                    ),
                    clear
                )
            end
        end
    end
end

function ui_update_text_achievement_data_at_category_and_idx(whichPlayer, targetCategory, idx, text)
    local achievementData = ACHIEVEMENT_DATA[whichPlayer]
    if
        achievementData ~= nil and achievementData[targetCategory] ~= nil and
        achievementData[targetCategory].categoryData ~= nil and
        achievementData[targetCategory].categoryData[idx] ~= nil
    then
        achievementData[targetCategory].categoryData[idx].tip = text
        if whichPlayer == hplayer.loc() then
            if CURRENT_TIP == targetCategory .. tostring(idx - 18 * (achievementData.currentPage - 1)) then
                hjapi.DzFrameSetText(hjapi.DzFrameFindByName("ALL_Tips_Desc", 0), text)
            end
        end
    end
end

local function init_achievement_UI()
    build_achievement_data()
    -- Validation to make sure achievement data is good
    if ACHIEVEMENT_DATA.UITabNameToCategory == nil then
        err("Fail to load Achievement UI")
        return
    end
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                err("Fail to load Achievement UI")
                return
            end
            if ACHIEVEMENT_DATA[enumPlayer].currentCategory == nil or ACHIEVEMENT_DATA[enumPlayer].currentPage == nil then
                err("Fail to load Achievement UI, no currentCategory nor currentPage")
                return
            end
            for k, v in pairs(ACHIEVEMENT_DATA[enumPlayer]) do
                if type(v) == "table" then
                    if v.categoryUIName == nil or v.categoryData == nil or type(v.categoryData) ~= "table" then
                        err("Fail to load Achievement UI, no categoryUIName or categoryData set for category " .. k)
                        return
                    end
                    for i, vv in pairs(v.categoryData) do
                        if
                            vv.name == nil or type(vv.name) ~= "string" or vv.art == nil or type(vv.art) ~= "string" or
                            vv.tip == nil or
                            type(vv.tip) ~= "string" or
                            vv.enable == nil or
                            type(vv.enable) ~= "boolean"
                        then
                            dump(vv)
                            err(
                                "Fail to load Achievement UI, no name or art or tip or enable set for idx " ..
                                tostring(i)
                            )
                            return
                        end
                    end
                end
            end
        end
    )

    hjapi.DzLoadToc("UI\\ui_achieve.toc")
    local tmp = hjapi.DzCreateFrame("FrmRootWindow", hjapi.DzGetGameUI(), 0)
    hjapi.DzFrameSetAbsolutePoint(tmp, 3, 0, 0.343)
    hjapi.DzFrameShow(tmp, false)
    hjapi.DzFrameShow(hjapi.DzFrameFindByName("FrmRootWindow_Tips", 0), false)
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            if enumPlayer == hplayer.loc() then
                update_achievement_UI(enumPlayer, ACHIEVEMENT_DATA[enumPlayer].currentCategory)
            end
        end
    )

    -- 右上角关闭界面
    hjapi.DzFrameSetScriptByCode(
        hjapi.DzFrameFindByName("BtnRootWindow_Close", 0),
        MOUSE_ORDER_CLICK,
        function()
            ui_opened = false
            hjapi.DzFrameShow(tmp, false)
        end,
        false
    )
    -- 前一页
    hjapi.DzFrameSetScriptByCode(
        hjapi.DzFrameFindByName("BtnRootWindow_PrePage", 0),
        MOUSE_ORDER_CLICK,
        function()
            local whichPlayer = hplayer.loc()
            local achievementData = ACHIEVEMENT_DATA[whichPlayer]
            update_achievement_UI_to_page(whichPlayer, achievementData.currentCategory, achievementData.currentPage - 1)
        end,
        false
    )
    -- 后一页
    hjapi.DzFrameSetScriptByCode(
        hjapi.DzFrameFindByName("BtnRootWindow_NextPage", 0),
        MOUSE_ORDER_CLICK,
        function()
            local whichPlayer = hplayer.loc()
            local achievementData = ACHIEVEMENT_DATA[whichPlayer]
            update_achievement_UI_to_page(whichPlayer, achievementData.currentCategory, achievementData.currentPage + 1)
        end,
        false
    )
    -- 鼠标放上面的提示 以及按钮事件
    for i = 1, 18, 1 do
        local button = hjapi.DzFrameFindByName("BtnRootWindow_Item" .. tostring(i) .. "_Button", 0)
        local tipsFrame = hjapi.DzFrameFindByName("FrmRootWindow_Tips", 0)
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_ENTER,
            function()
                local whichPlayer = hplayer.loc()
                local targetPlayer = getSelectedPlayer(whichPlayer)
                local currentCategory = ACHIEVEMENT_DATA[whichPlayer].currentCategory
                local currentPage = ACHIEVEMENT_DATA[whichPlayer].currentPage
                local achievementData = ACHIEVEMENT_DATA[targetPlayer]
                local tip = achievementData[currentCategory].categoryData[18 * (currentPage - 1) + i].tip
                CURRENT_TIP = currentCategory .. tostring(18 * (currentPage - 1) + i)
                local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
                local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
                hjapi.DzFrameClearAllPoints(tipsText)
                hjapi.DzFrameSetSize(tipsText, 0.1400, 0)
                hjapi.DzFrameSetPoint(tipsText, 0, button, 8, 0, 0)
                hjapi.DzFrameSetText(tipsText, tip)
                hjapi.DzFrameShow(tipsBack, true)
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_LEAVE,
            function()
                local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
                hjapi.DzFrameShow(tipsBack, false)
                CURRENT_TIP = nil
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_CLICK,
            function()
                local whichPlayer = hplayer.loc()
                local currentCategory = ACHIEVEMENT_DATA[whichPlayer].currentCategory
                local currentPage = ACHIEVEMENT_DATA[whichPlayer].currentPage
                local index = 18 * (currentPage - 1) + i
                ACHIEVEMENT_DATA[whichPlayer][currentCategory].categoryData[index].callback()
            end,
            false
        )
    end

    -- 设置大页面跳转
    for i = 1, 15, 1 do
        local buttonName = "BtnRootWindow_Category_Category" .. tostring(i)
        if i == 1 then
            buttonName = "BtnRootWindow_Category_Achieve"
        end
        hjapi.DzFrameSetScriptByCode(
            hjapi.DzFrameFindByName(buttonName, 0),
            MOUSE_ORDER_CLICK,
            function()
                local whichPlayer = hplayer.loc()
                local achievementData = ACHIEVEMENT_DATA[whichPlayer]
                if achievementData[achievementData.currentCategory].categoryUIName ~= buttonName then
                    update_achievement_UI(whichPlayer, ACHIEVEMENT_DATA.UITabNameToCategory[buttonName])
                end
            end,
            false
        )
    end

    -- 目标选择事件
    hevent.reaction(
        CONST_EVENT.selection .. "#1",
        "achievement_UI_selection",
        function(evtData)
            local unitOnwerPlayer = hunit.getOwner(evtData.triggerUnit)
            if hplayer.isUser(unitOnwerPlayer) == false or hplayer.isPlaying(unitOnwerPlayer) == false then
                return
            end
            if evtData.triggerPlayer == hplayer.loc() then
                update_achievement_UI(unitOnwerPlayer, ACHIEVEMENT_DATA[evtData.triggerPlayer].currentCategory)
            end
        end
    )
end

local function build_zhunaye_data()
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            if ZHUANYE_DATA[enumPlayer] == nil then
                ZHUANYE_DATA[enumPlayer] = {}
            end

            ZHUANYE_DATA[enumPlayer].currentZhuanye = "锻造"
            ZHUANYE_DATA[enumPlayer].currentPage = 1
        end
    )
end

function ui_enable_zhuanye_data_at_category_and_idx(whichPlayer, zhuanyeName, idx)
    local zhuanyeData = ZHUANYE_DATA[whichPlayer]
    if
        zhuanyeData ~= nil and zhuanyeData[zhuanyeName] ~= nil and zhuanyeData[zhuanyeName].categoryData ~= nil and
        zhuanyeData[zhuanyeName].categoryData[idx] ~= nil
    then
        zhuanyeData[zhuanyeName].categoryData[idx].enable = true
        if
            zhuanyeData.currentZhuanye == zhuanyeName and idx <= 20 * zhuanyeData.currentPage and
            idx > 20 * (zhuanyeData.currentPage - 1)
        then
            if whichPlayer == hplayer.loc() then
                hjapi.DzFrameShow(
                    hjapi.DzFrameFindByName(
                        "ZhuanyeImgRootWindow_Item" .. tostring(idx - 20 * (zhuanyeData.currentPage - 1)) .. "_Mask",
                        0
                    ),
                    false
                )
            end
        end
    end
end

function ui_update_art_zhuanye_data_at_category_and_idx(whichPlayer, zhuanyeName, idx, art)
    local zhuanyeData = ZHUANYE_DATA[whichPlayer]
    if
        zhuanyeData ~= nil and zhuanyeData[zhuanyeName] ~= nil and zhuanyeData[zhuanyeName].categoryData ~= nil and
        zhuanyeData[zhuanyeName].categoryData[idx] ~= nil
    then
        zhuanyeData[zhuanyeName].categoryData[idx].art = art
        if
            zhuanyeData.currentZhuanye == zhuanyeName and idx <= 20 * zhuanyeData.currentPage and
            idx > 20 * (zhuanyeData.currentPage - 1)
        then
            if whichPlayer == hplayer.loc() then
                hjapi.DzFrameSetTexture(
                    hjapi.DzFrameFindByName("ZhuanyeImgRootWindow_Item" .. tostring(idx) .. "_Icon", 0),
                    art
                )
            end
        end
    end
end

function ui_update_text_zhuanye_data_at_category_and_idx(whichPlayer, zhuanyeName, idx, text)
    local zhuanyeData = ZHUANYE_DATA[whichPlayer]
    if
        zhuanyeData ~= nil and zhuanyeData[zhuanyeName] ~= nil and zhuanyeData[zhuanyeName].categoryData ~= nil and
        zhuanyeData[zhuanyeName].categoryData[idx] ~= nil
    then
        zhuanyeData[zhuanyeName].categoryData[idx].tip = text
    end
end

function update_zhuanye_UI_to_page(whichPlayer, zhuanyeName, targetPage)
    local categoryData = ZHUANYE_DATA[whichPlayer][zhuanyeName].categoryData
    local totalPageCount = math.max(math.ceil(#categoryData / 20), 1)
    if targetPage == nil or targetPage > totalPageCount or targetPage < 1 then
        return
    end
    ZHUANYE_DATA[whichPlayer].currentZhuanye = zhuanyeName
    ZHUANYE_DATA[whichPlayer].currentPage = targetPage
    hjapi.DzFrameSetText(hjapi.DzFrameFindByName("ZhuanyeTxtRootWindow_Title", 0), zhuanyeName)
    local pageText = tostring(targetPage) .. "/" .. tostring(totalPageCount)
    hjapi.DzFrameSetText(hjapi.DzFrameFindByName("ZhuanyeTxtRootWindow_PageNum", 0), pageText)
    for i = 20 * (targetPage - 1) + 1, 20 * targetPage, 1 do
        local UI_index = i - 20 * (targetPage - 1)
        if i <= #categoryData then
            local UI_index = i - 20 * (targetPage - 1)
            hjapi.DzFrameSetText(
                hjapi.DzFrameFindByName("ZhuanyeTxtRootWindow_Item" .. tostring(UI_index) .. "_Name", 0),
                categoryData[i].name
            )
            hjapi.DzFrameSetTexture(
                hjapi.DzFrameFindByName("ZhuanyeImgRootWindow_Item" .. tostring(UI_index) .. "_Icon", 0),
                categoryData[i].art
            )
            if categoryData[i].enable == true then
                hjapi.DzFrameShow(
                    hjapi.DzFrameFindByName("ZhuanyeImgRootWindow_Item" .. tostring(UI_index) .. "_Mask", 0),
                    false
                )
            else
                hjapi.DzFrameShow(
                    hjapi.DzFrameFindByName("ZhuanyeImgRootWindow_Item" .. tostring(UI_index) .. "_Mask", 0),
                    true
                )
            end
            hjapi.DzFrameShow(hjapi.DzFrameFindByName("ZhuanyeFrmRootWindow_Item" .. tostring(UI_index), 0), true)
        else
            hjapi.DzFrameShow(hjapi.DzFrameFindByName("ZhuanyeFrmRootWindow_Item" .. tostring(UI_index), 0), false)
        end
    end
end

local function init_zhuanye_UI()
    build_zhunaye_data()
    -- Validation to make sure achievement data is good
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            if ZHUANYE_DATA[enumPlayer] == nil then
                err("Fail to load ZHUANYE UI")
                return
            end
            if ZHUANYE_DATA[enumPlayer].currentZhuanye == nil or ZHUANYE_DATA[enumPlayer].currentPage == nil then
                err("Fail to load ZHUANYE UI, no ZHUANYE nor currentPage")
                return
            end
            for k, v in pairs(ZHUANYE_DATA[enumPlayer]) do
                if type(v) == "table" then
                    if v.categoryData == nil or type(v.categoryData) ~= "table" then
                        err("Fail to load ZHUANYE UI, bad categoryData set for category " .. k)
                        return
                    end
                    for i, vv in pairs(v.categoryData) do
                        if
                            vv.name == nil or type(vv.name) ~= "string" or vv.art == nil or type(vv.art) ~= "string" or
                            vv.tip == nil or
                            type(vv.tip) ~= "string" or
                            vv.enable == nil or
                            type(vv.enable) ~= "boolean"
                        then
                            dump(ZHUANYE_DATA[enumPlayer])
                            err(
                                "Fail to load ZHUANYE_DATA UI, no name or art or tip or enable set for idx " ..
                                tostring(i) .. " name " .. vv.name
                            )
                            return
                        end
                    end
                end
            end
        end
    )

    hjapi.DzLoadToc("UI\\ui_zhuanye.toc")
    local tmp = hjapi.DzCreateFrame("ZhuanyeFrmRootWindow", hjapi.DzGetGameUI(), 0)
    hjapi.DzFrameSetAbsolutePoint(tmp, 4, 0.4, 0.35)
    hjapi.DzFrameShow(tmp, false)
    local tipsFrame = hjapi.DzFrameFindByName("ZhuanyeFrmRootWindow_Tips", 0)
    hjapi.DzFrameShow(tipsFrame, false)

    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            if enumPlayer == hplayer.loc() then
                update_zhuanye_UI_to_page(enumPlayer, ZHUANYE_DATA[enumPlayer].currentZhuanye, 1)
            end
        end
    )

    -- 右上角关闭界面
    hjapi.DzFrameSetScriptByCode(
        hjapi.DzFrameFindByName("ZhuanyeBtnRootWindow_Close", 0),
        MOUSE_ORDER_CLICK,
        function()
            hjapi.DzFrameShow(tmp, false)
        end,
        false
    )
    -- 前一页
    hjapi.DzFrameSetScriptByCode(
        hjapi.DzFrameFindByName("ZhuanyeBtnRootWindow_PrePage", 0),
        MOUSE_ORDER_CLICK,
        function()
            local whichPlayer = hplayer.loc()
            local zhuanyeData = ZHUANYE_DATA[whichPlayer]
            update_zhuanye_UI_to_page(whichPlayer, zhuanyeData.currentZhuanye, zhuanyeData.currentPage - 1)
        end,
        false
    )
    -- 后一页
    hjapi.DzFrameSetScriptByCode(
        hjapi.DzFrameFindByName("ZhuanyeBtnRootWindow_NextPage", 0),
        MOUSE_ORDER_CLICK,
        function()
            local whichPlayer = hplayer.loc()
            local zhuanyeData = ZHUANYE_DATA[whichPlayer]
            update_zhuanye_UI_to_page(whichPlayer, zhuanyeData.currentZhuanye, zhuanyeData.currentPage + 1)
        end,
        false
    )
    -- 鼠标放上面的提示 以及按钮事件
    for i = 1, 20, 1 do
        local button = hjapi.DzFrameFindByName("ZhuanyeBtnRootWindow_Item" .. tostring(i) .. "_Button", 0)
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_ENTER,
            function()
                local whichPlayer = hplayer.loc()
                local zhuanyeData = ZHUANYE_DATA[whichPlayer]
                local tip =
                    zhuanyeData[zhuanyeData.currentZhuanye].categoryData[20 * (zhuanyeData.currentPage - 1) + i].tip
                local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
                local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
                hjapi.DzFrameClearAllPoints(tipsText)
                hjapi.DzFrameSetSize(tipsText, 0.1200, 0)
                hjapi.DzFrameSetPoint(tipsText, FRAMEPOINT_RIGHT, tmp, FRAMEPOINT_LEFT, -0.05, 0)
                hjapi.DzFrameSetText(tipsText, tip)
                hjapi.DzFrameShow(tipsBack, true)
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_LEAVE,
            function()
                local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
                hjapi.DzFrameShow(tipsBack, false)
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_CLICK,
            function()
                local whichPlayer = hplayer.loc()
                local currentZhuanye = ZHUANYE_DATA[whichPlayer].currentZhuanye
                local currentPage = ZHUANYE_DATA[whichPlayer].currentPage
                local index = 20 * (currentPage - 1) + i
                ZHUANYE_DATA[whichPlayer][currentZhuanye].categoryData[index].callback()
            end,
            false
        )
    end
end

-- setup trigger to show item description when referred
local function init_dimian_wupin_trigger()
    htime.setInterval(
        0.1,
        function(_)
            for _, player in pairs(hplayer.players) do
                if hplayer.isUser(player) and hplayer.isPlaying(player) then
                    ----- show toop tip for items in ground
                    local item = hjapi.DzGetUnitUnderMouse()
                    local dynamicItem = hitem.getDynamicItem(item)
                    if dynamicItem ~= nil then
                        local msg = dynamicItem.getDescription()
                        if hplayer.loc() == player then
                            local back = hjapi.DzFrameFindByName("DiMian_Tips", 0)
                            local text = hjapi.DzFrameFindByName("DiMian_Tips_Desc", 0)
                            hjapi.DzFrameClearAllPoints(text)
                            hjapi.DzFrameSetAbsolutePoint(text, 0, 0.58, 0.23)
                            hjapi.DzFrameSetSize(text, 0.1000, 0)
                            hjapi.DzFrameSetText(text, msg)
                            hjapi.DzFrameShow(back, true)
                            try_show_compare_view(player, dynamicItem, text, "DiMian_Tips")
                        end
                    elseif hunit.isAlive(item) == true and hplayer.isUser(hunit.getOwner(item)) ~= true then
                        if hplayer.isNeutral(hunit.getOwner(item)) ~= true then
                            local name = hunit.getName(item)
                            local canBopi = hslk.n2v(name, "_canBOPI")
                            local canZhibu = hslk.n2v(name, "_canZHIBU")
                            local level = hunit.getLevel(item)
                            local hero = hplayer.getMainHero(hplayer.loc())
                            local heroLevel = hunit.getLevel(hero)
                            local levelStr = tostring(level) .. "级"
                            levelStr = hcolor.set_level_str_with_color(levelStr, heroLevel, level)
                            name = name .. "|n" .. levelStr
                            if canBopi == true then
                                name =
                                    name ..
                                    "|n|n" .. hcolor.green("可剥皮") .. "|n" .. hzhuanye.getShaguaiDescription(item, "剥皮")
                            end
                            if canZhibu == true then
                                name =
                                    name ..
                                    "|n|n" .. hcolor.green("可制布") .. "|n" .. hzhuanye.getShaguaiDescription(item, "制布")
                            end
                            local diaoluoInfo = hunit.getDiaoLuoInfo(item)
                            name = name .. "|n|n" .. diaoluoInfo

                            local jianglimsg = hcache.get(item, "jianglimsg")
                            if jianglimsg ~= nil then
                                name = name .. "|n击杀奖励|n" .. jianglimsg
                            end
                            if hplayer.loc() == player then
                                local back = hjapi.DzFrameFindByName("DiMian_Tips", 0)
                                local text = hjapi.DzFrameFindByName("DiMian_Tips_Desc", 0)
                                hjapi.DzFrameClearAllPoints(text)
                                hjapi.DzFrameSetAbsolutePoint(text, 0, 0.58, 0.23)
                                hjapi.DzFrameSetSize(text, 0.1500, 0)
                                hjapi.DzFrameSetText(text, name)
                                hjapi.DzFrameShow(back, true)
                            end
                        else
                            local name = hunit.getName(item)
                            local mergedPerNPCQuestInfo = hcache.get(player, "per_NPC_quest_info", "")
                            local otherNPCInfo = hcache.get(item, "chuansongmen_info")
                            local msg = name .. "|n|n"
                            if otherNPCInfo ~= nil then
                                msg = msg .. otherNPCInfo
                            end
                            if mergedPerNPCQuestInfo[name] ~= nil then
                                msg = msg .. hcolor.yellow("任务相关：|n") .. mergedPerNPCQuestInfo[name]
                            end
                            local caijiDescription = hzhuanye.getCaijiDescription(name)
                            if caijiDescription ~= nil then
                                local kecaijiCount = hcache.get(item, "ziyuan_count")[player]
                                local ziyuan_refresh_count = hcache.get(item, "ziyuan_refresh_count")[player]
                                msg =
                                    msg ..
                                    "当前可采集：" ..
                                    hcolor.green(kecaijiCount) ..
                                    "次 (" .. hcolor.green(ziyuan_refresh_count) .. "秒后再生)|n" .. caijiDescription
                            end
                            if hplayer.loc() == player then
                                local back = hjapi.DzFrameFindByName("DiMian_Tips", 0)
                                local text = hjapi.DzFrameFindByName("DiMian_Tips_Desc", 0)
                                hjapi.DzFrameClearAllPoints(text)
                                hjapi.DzFrameSetAbsolutePoint(text, 6, 0.58, 0.14)
                                hjapi.DzFrameSetSize(text, 0.1500, 0)
                                hjapi.DzFrameSetText(text, msg)
                                hjapi.DzFrameShow(back, true)
                            end
                        end
                    else
                        if hplayer.loc() == player then
                            local back = hjapi.DzFrameFindByName("DiMian_Tips", 0)
                            hjapi.DzFrameShow(back, false)
                            disable_compare_view("DiMian_Tips")
                        end
                    end
                end
            end
        end
    )
end

-- 9格装备界面
local function init_equipment_UI()
    hjapi.DzLoadToc("UI\\backpack.toc")
    local tmp = hjapi.DzCreateFrame("UI_ZT", hjapi.DzGetGameUI(), 0)
    hjapi.DzFrameSetAbsolutePoint(tmp, 4, 0.41, 0.09)
    hjapi.DzFrameShow(tmp, true)
    --注册按钮点击事件
    --同步
    hsync.onSend(
        "unEquipItem",
        function(syncData)
            local equipment_type = tonumber(syncData.triggerData[1])
            if hfightzhuangtai.isInFight(hplayer.getMainHero(syncData.triggerPlayer)) then
                echo("战斗状态中不能更换装备", syncData.triggerPlayer)
                return
            end
            hplayer.unEquipItem(syncData.triggerPlayer, equipment_type)
        end
    )

    --鼠标点击
    for i = 1, NUM_EQUIPMENT_SLOT do
        hjapi.DzFrameSetScriptByCode(
            hjapi.DzFrameFindByName("BGZ" .. i, 0),
            MOUSE_ORDER_CLICK,
            function()
                local selected_unit = hplayer.getSelection(hplayer.loc())
                if selected_unit ~= nil and hunit.getOwner(selected_unit) ~= hplayer.loc() then
                    return
                end
                if hplayer.dzCunDang[hplayer.loc()].getEquipment(i) == nil then
                    return
                end
                local triggerData = { i }
                hsync.send("unEquipItem", triggerData)
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            hjapi.DzFrameFindByName("BGZ" .. i, 0),
            MOUSE_ORDER_ENTER,
            function()
                local msg = nil
                local player = UI_components["select"][hplayer.loc()]
                player = player or hplayer.loc()
                if hplayer.dzCunDang[player].getEquipment(i) == nil then
                    msg = "点击物品栏装备即可穿戴装备"
                else
                    msg = hplayer.dzCunDang[player].getEquipment(i).getDescription()
                end
                local back = hjapi.DzFrameFindByName("ALL_Tips", 0)
                local text = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
                hjapi.DzFrameClearAllPoints(text)
                hjapi.DzFrameSetPoint(text, 6, hjapi.DzFrameFindByName("BGZ" .. i, 0), 2, 0, 0)
                hjapi.DzFrameSetSize(text, 0.1000, 0)
                hjapi.DzFrameSetText(text, msg)
                hjapi.DzFrameShow(back, true)
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            hjapi.DzFrameFindByName("BGZ" .. i, 0),
            MOUSE_ORDER_LEAVE,
            function()
                local back = hjapi.DzFrameFindByName("ALL_Tips", 0)
                hjapi.DzFrameShow(back, false)
            end,
            false
        )
    end

    hevent.reaction(
        CONST_EVENT.equipmentChange,
        "UI",
        function(evtData)
            local dynamicItem = evtData.dynamicItem
            if dynamicItem == nil then
                return
            end
            if evtData.isAdd then
                if (evtData.whichPlayer == hplayer.loc()) then
                    hjapi.DzFrameSetTexture(
                        hjapi.DzFrameFindByName("BGZ" .. evtData.equipmentSlot .. "UP", 0),
                        hitem.getArt(dynamicItem.basic_item_id),
                        0
                    )
                    local pinzhi = dynamicItem.pinzhi or ZHUANGBEI_PINZHI.PUTONG
                    hjapi.DzFrameSetTexture(
                        hjapi.DzFrameFindByName("BGFRAME" .. evtData.equipmentSlot, 0),
                        ZHUANGBEI_PINZHI_DATA[pinzhi].frameArt,
                        0
                    )
                    hjapi.DzFrameShow(hjapi.DzFrameFindByName("BGFRAME" .. evtData.equipmentSlot, 0), true)
                end
            else
                if (evtData.whichPlayer == hplayer.loc()) then
                    hjapi.DzFrameSetTexture(
                        hjapi.DzFrameFindByName("BGZ" .. evtData.equipmentSlot .. "UP", 0),
                        "ReplaceableTextures\\xitong\\ui_zhuangbeigezi.blp",
                        0
                    )
                    hjapi.DzFrameShow(hjapi.DzFrameFindByName("BGFRAME" .. evtData.equipmentSlot, 0), false)
                end
            end
        end
    )

    -- 目标选择事件
    hevent.reaction(
        CONST_EVENT.selection .. "#1",
        "zhuangbei_UI",
        function(evtData)
            local unitOnwerPlayer = hunit.getOwner(evtData.triggerUnit)
            if hplayer.isUser(unitOnwerPlayer) == false or hplayer.isPlaying(unitOnwerPlayer) == false then
                return
            end
            if UI_components["select"][evtData.triggerPlayer] == unitOnwerPlayer then
                return
            end
            UI_components["select"][evtData.triggerPlayer] = unitOnwerPlayer
            for i = 1, NUM_EQUIPMENT_SLOT do
                if hplayer.dzCunDang[unitOnwerPlayer].getEquipment(i) == nil then
                    if (evtData.triggerPlayer == hplayer.loc()) then
                        hjapi.DzFrameSetTexture(
                            hjapi.DzFrameFindByName("BGZ" .. i .. "UP", 0),
                            "war3mapImported\\[ZT]A2.tga",
                            0
                        )
                        hjapi.DzFrameShow(hjapi.DzFrameFindByName("BGFRAME" .. i, 0), false)
                    end
                else
                    local dynamicItem = hplayer.dzCunDang[unitOnwerPlayer].getEquipment(i)
                    if (evtData.triggerPlayer == hplayer.loc()) then
                        hjapi.DzFrameSetTexture(
                            hjapi.DzFrameFindByName("BGZ" .. i .. "UP", 0),
                            hitem.getArt(dynamicItem.basic_item_id),
                            0
                        )
                        hjapi.DzFrameSetTexture(
                            hjapi.DzFrameFindByName("BGFRAME" .. i, 0),
                            ZHUANGBEI_PINZHI_DATA[dynamicItem.pinzhi].frameArt,
                            0
                        )
                        hjapi.DzFrameShow(hjapi.DzFrameFindByName("BGFRAME" .. i, 0), true)
                    end
                end
            end
            local gearScore = hitem.getGearScore(unitOnwerPlayer)
            if hplayer.loc() == evtData.triggerPlayer then
                hjapi.DzFrameSetText(hjapi.DzFrameFindByName("gearScore_text", 0), "装备评分：" .. gearScore)
            end
        end
    )

    -- 设置套装状态Ui
    local taozhuangzhuangtaibackdrop = hjapi.FrameTag("BACKDROP", "taozhuangzhuangtaibd", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(taozhuangzhuangtaibackdrop, 3, hjapi.DzFrameFindByName("BGZBK10", 0), 5, 0.0015, 0)
    hjapi.DzFrameSetSize(taozhuangzhuangtaibackdrop, 0.005, 0.015)
    hjapi.DzFrameSetTexture(taozhuangzhuangtaibackdrop, "ReplaceableTextures\\xitong\\ui_!.blp", 0)
    hjapi.DzFrameShow(taozhuangzhuangtaibackdrop, true)

    local taozhuangzhuangtaibutton =
        hjapi.FrameTag("BUTTON", "taozhuangzhuangtaibutton", taozhuangzhuangtaibackdrop, nil)
    hjapi.DzFrameSetPoint(taozhuangzhuangtaibutton, 4, taozhuangzhuangtaibackdrop, 4, 0, 0)
    hjapi.DzFrameSetSize(taozhuangzhuangtaibutton, 0.0113, 0.015)
    hjapi.DzFrameShow(taozhuangzhuangtaibutton, true)

    hjapi.DzFrameSetScriptByCode(
        taozhuangzhuangtaibutton,
        MOUSE_ORDER_ENTER,
        function()
            local back = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local text = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(text)
            hjapi.DzFrameSetPoint(text, 6, taozhuangzhuangtaibutton, 2, 0, 0)
            hjapi.DzFrameSetSize(text, 0.1400, 0)
            hjapi.DzFrameSetText(text, hcache.get(hplayer.loc(), CONST_CACHE.ZHUANGBEI_TAOZHUANG, "显示套装品质/强化/精炼套装属性"))
            hjapi.DzFrameShow(back, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        taozhuangzhuangtaibutton,
        MOUSE_ORDER_LEAVE,
        function()
            local back = hjapi.DzFrameFindByName("ALL_Tips", 0)

            hjapi.DzFrameShow(back, false)
        end,
        false
    )
end

local function init_energy_point()
    hjapi.DzLoadToc("UI\\lianjidian.toc")
    local lianjidian = hjapi.DzCreateFrame("LIANJIDIAN", hjapi.DzGetGameUI(), 0)
    hjapi.DzFrameSetPoint(lianjidian, 7, hjapi.DzGetGameUI(), 7, 0, 0.19)
    hjapi.DzFrameShow(lianjidian, false)
end

function set_energy_point(player, point, maxPoint, color)
    if
        point > maxPoint or point < 0 or maxPoint < 0 or
        (color ~= "huangse" and color ~= "lvse" and color ~= "hongse" and color ~= "zise")
    then
        err("bad parameter for set_energy_point")
        return
    end
    local hero = hplayer.getMainHero(player)
    if hero == nil then
        return
    end
    if hcache.get(hero, "cache-energy-point") == nil then
        hcache.set(hero, "cache-energy-point", true)
        hevent.register(
            hero,
            CONST_EVENT.enterFight,
            "fight show point",
            function(evtData)
                if hplayer.loc() == player then
                    hjapi.DzFrameShow(hjapi.DzFrameFindByName("LIANJIDIAN", 0), true)
                end
                local clearTimer = hcache.get(hero, "clear-e-point-timer")
                if clearTimer ~= nil then
                    clearTimer.destroy()
                end
            end
        )
        hevent.register(
            hero,
            CONST_EVENT.quitFight,
            "fight hide point",
            function(evtData)
                local clearTimer = hcache.get(hero, "clear-e-point-timer")
                if clearTimer ~= nil then
                    clearTimer.destroy()
                end
                hcache.set(
                    hero,
                    "clear-e-point-timer",
                    htime.setTimeout(
                        3,
                        function(_)
                            if hplayer.loc() == player then
                                hjapi.DzFrameShow(hjapi.DzFrameFindByName("LIANJIDIAN", 0), false)
                            end
                        end
                    )
                )
            end
        )
    end
    if hplayer.loc() == player then
        hjapi.DzFrameShow(hjapi.DzFrameFindByName("LIANJIDIAN", 0), true)
        for i = 1, 6 do
            local frame = hjapi.DzFrameFindByName("LIANJIDIAN" .. i, 0)
            local huangse = hjapi.DzFrameFindByName("LIANJIDIAN" .. i .. "_HUANGSE", 0)
            local lvse = hjapi.DzFrameFindByName("LIANJIDIAN" .. i .. "_LVSE", 0)
            local hongse = hjapi.DzFrameFindByName("LIANJIDIAN" .. i .. "_HONGSE", 0)
            local zise = hjapi.DzFrameFindByName("LIANJIDIAN" .. i .. "_ZISE", 0)
            if i <= maxPoint then
                hjapi.DzFrameShow(frame, true)
                if i <= point then
                    if color == "huangse" then
                        hjapi.DzFrameShow(huangse, true)
                        hjapi.DzFrameShow(lvse, false)
                        hjapi.DzFrameShow(hongse, false)
                        hjapi.DzFrameShow(zise, false)
                    elseif color == "lvse" then
                        hjapi.DzFrameShow(huangse, false)
                        hjapi.DzFrameShow(lvse, true)
                        hjapi.DzFrameShow(hongse, false)
                        hjapi.DzFrameShow(zise, false)
                    elseif color == "hongse" then
                        hjapi.DzFrameShow(huangse, false)
                        hjapi.DzFrameShow(lvse, false)
                        hjapi.DzFrameShow(hongse, true)
                        hjapi.DzFrameShow(zise, false)
                    elseif color == "zise" then
                        hjapi.DzFrameShow(huangse, false)
                        hjapi.DzFrameShow(lvse, false)
                        hjapi.DzFrameShow(hongse, false)
                        hjapi.DzFrameShow(zise, true)
                    end
                else
                    hjapi.DzFrameShow(huangse, false)
                    hjapi.DzFrameShow(lvse, false)
                    hjapi.DzFrameShow(hongse, false)
                    hjapi.DzFrameShow(zise, false)
                end
            else
                hjapi.DzFrameShow(frame, false)
            end
        end
    end
end

local function init_dice_UI()
    hjapi.DzLoadToc("UI\\ui_achieve.toc")
    local tmp = hjapi.DzCreateFrame("FrmDiceWindow", hjapi.DzGetGameUI(), 0)
    hjapi.DzFrameSetPoint(tmp, 4, hjapi.DzGetGameUI(), 4, 0)
    hjapi.DzFrameShow(tmp, false)

    for i = 1, 5, 1 do
        local button = hjapi.DzFrameFindByName("BtnDiceWindow_Item" .. i .. "_Hover", 0)
        local text = hjapi.DzFrameFindByName("FrmDiceWindow_Item" .. i .. "_Tips", 0)
        local tipsBack = hjapi.DzFrameFindByName("ImgDiceWindow_Item" .. i .. "_Tips_Back", 0)
        local tipsText = hjapi.DzFrameFindByName("TxtDiceWindow_Item" .. i .. "_Tips_Desc", 0)
        hjapi.DzFrameClearAllPoints(tipsBack)
        hjapi.DzFrameSetPoint(tipsBack, 0, tipsText, 0, -0.009, 0.009)
        hjapi.DzFrameSetPoint(tipsBack, 8, tipsText, 8, 0.009, -0.009)
        hjapi.DzFrameShow(text, false)
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_ENTER,
            function()
                try_show_compare_view(hplayer.loc(), hcache.get(hplayer.loc(), "cache-loot-di" .. i), text, "ALL_Tips")
                hjapi.DzFrameShow(text, true)
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_LEAVE,
            function()
                disable_compare_view("ALL_Tips")
                hjapi.DzFrameShow(text, false)
            end,
            false
        )
    end

    hdiceloot.setUpTriggers()
end

local function init_direnxuetiao_UI()
    hjapi.DzLoadToc("UI\\ui_achieve.toc")
    local tmp = hjapi.DzCreateFrame("direnzhuangtai", hjapi.DzGetGameUI(), 0)
    hjapi.DzFrameSetPoint(tmp, 4, hjapi.DzGetGameUI(), 4, 0, 0.23)
    hjapi.DzFrameShow(tmp, false)
    hjapi.DzFrameShow(hjapi.DzFrameFindByName("direnbufflan", 0), false)
    hjapi.DzFrameSetAlpha(hjapi.DzFrameFindByName("direnxuetiao_bar_slow", 0), 100)

    local back = hjapi.DzFrameFindByName("direnbufflan_Tips_Back", 0)
    local desc = hjapi.DzFrameFindByName("direnbufflan_Tips_Desc", 0)
    hjapi.DzFrameSetPoint(back, 0, desc, 0, -0.009, 0.009)
    hjapi.DzFrameSetPoint(back, 8, desc, 8, 0.009, -0.009)

    local positiveBuffDescription = {}
    local negativeBuffDescription = {}
    for _, player in ipairs(hplayer.players) do
        if hplayer.isPlaying(player) and hplayer.isUser(player) then
            positiveBuffDescription[player] = {}
            negativeBuffDescription[player] = {}
        end
    end
    local lastSelected = nil
    local hpslow = 100.0
    htime.setInterval(
        0.05,
        function(_)
            for _, player in ipairs(hplayer.players) do
                if hplayer.isPlaying(player) and hplayer.isUser(player) then
                    local unit = GLOBAL_LAST_DAMAGED_BOSS[player]
                    if unit ~= nil and hunit.isAlive(unit) then
                        local hp = hunit.getCurLifePercent(unit)
                        if hp == nil or type(hp) ~= "number" or hp < 0 or hp > 100 then
                            hp = 100
                        end
                        local currentHp = math.floor(hunit.getCurLife(unit))
                        if currentHp == nil or type(currentHp) ~= "number" or currentHp < 0 or currentHp > 9999999999 then
                            currentHp = 666
                        end
                        local maxHp = math.floor(hunit.getMaxLife(unit))
                        if maxHp == nil or type(maxHp) ~= "number" or maxHp < 0 or maxHp > 9999999999 then
                            maxHp = 666
                        end
                        if unit == lastSelected then
                            hpslow = math.max(hp, hpslow - 0.5)
                        else
                            hpslow = hp
                        end
                        lastSelected = unit
                        local xuetiao = hjapi.DzFrameFindByName("direnxuetiao_bar", 0)
                        local xuetiao_slow = hjapi.DzFrameFindByName("direnxuetiao_bar_slow", 0)
                        local text = hjapi.DzFrameFindByName("direnxuetiao_text", 0)
                        local casting = hcache.get(unit, "AI_SKILL_CASTING", false)
                        local maxProgress = hcache.get(unit, "AI_SKILL_CASTING_SHIFATIAO_MAX", 100)
                        local current = hcache.get(unit, "AI_SKILL_CASTING_SHIFATIAO_CURRENT", 1)
                        local shifaname = hcache.get(unit, "AI_SKILL_CASTING_NAME", "")
                        if hplayer.loc() == player then
                            hjapi.DzFrameClearAllPoints(xuetiao)
                            hjapi.DzFrameSetPoint(xuetiao, 0, tmp, 0, 0.0030, -0.0030)
                            hjapi.DzFrameSetSize(xuetiao, 0.3240 * hp / 100, 0.0210)
                            hjapi.DzFrameClearAllPoints(xuetiao_slow)
                            hjapi.DzFrameSetPoint(xuetiao_slow, 0, tmp, 0, 0.0030, -0.0030)
                            hjapi.DzFrameSetSize(xuetiao_slow, 0.3240 * hpslow / 100, 0.0210)
                            hjapi.DzFrameSetText(
                                text,
                                hunit.getName(unit) ..
                                " " .. tostring(currentHp) .. "/" .. tostring(maxHp) .. " (" .. tostring(hp) .. "%)"
                            )
                            if casting then
                                ui_set_direnshifatiaovalue(shifaname, current, maxProgress, true)
                            else
                                local shifatiao = hjapi.DzFrameFindByName("direnshifatiao", 0)
                                hjapi.DzFrameShow(shifatiao, false)
                            end
                            hjapi.DzFrameShow(tmp, true)
                        end
                    else
                        if hplayer.loc() == player then
                            hjapi.DzFrameShow(tmp, false)
                        end
                    end
                end
            end
        end
    )
    htime.setInterval(
        0.1,
        function(_)
            for _, player in ipairs(hplayer.players) do
                if hplayer.isPlaying(player) and hplayer.isUser(player) then
                    local unit = GLOBAL_LAST_DAMAGED_BOSS[player]
                    if unit ~= nil and hunit.isAlive(unit) then
                        local buffHandle = hcache.get(unit, BUFF_KEY)
                        if (buffHandle ~= nil) then
                            if (type(buffHandle) == "table") and buffHandle._idx ~= nil then
                                local positiveIndex = 1
                                local negativeIndex = 1
                                for _, bidx in ipairs(buffHandle._idx) do
                                    local curBuff = buffHandle[bidx]
                                    local positive = curBuff.positive
                                    local description = curBuff.description
                                    local art = curBuff.art
                                    local stack = curBuff.stack
                                    local remain = nil
                                    if curBuff.timer ~= nil then
                                        remain = math.round(curBuff.timer.remain(), 1)
                                        if curBuff.interval ~= nil and curBuff.remainingTime ~= nil then
                                            remain = remain + curBuff.remainingTime - curBuff.interval
                                            if remain >= 36000 then
                                                remain = ""
                                            else
                                                remain = string.format("%.1f", remain)
                                            end
                                        end
                                    else
                                        remain = ""
                                    end
                                    if art ~= nil then
                                        if positive then
                                            positiveBuffDescription[player][positiveIndex] = description
                                            if player == hplayer.loc() then
                                                hjapi.DzFrameShow(
                                                    hjapi.DzFrameFindByName("positivebuff" .. positiveIndex, 0),
                                                    true
                                                )
                                                hjapi.DzFrameSetTexture(
                                                    hjapi.DzFrameFindByName("positivebuff" .. positiveIndex, 0),
                                                    art
                                                )
                                                if stack > 1 then
                                                    hjapi.DzFrameSetText(
                                                        hjapi.DzFrameFindByName(
                                                            "positivebuff" .. positiveIndex .. "_Stack",
                                                            0
                                                        ),
                                                        stack
                                                    )
                                                else
                                                    hjapi.DzFrameSetText(
                                                        hjapi.DzFrameFindByName(
                                                            "positivebuff" .. positiveIndex .. "_Stack",
                                                            0
                                                        ),
                                                        ""
                                                    )
                                                end
                                                hjapi.DzFrameSetText(
                                                    hjapi.DzFrameFindByName(
                                                        "positivebuff" .. positiveIndex .. "_Duration",
                                                        0
                                                    ),
                                                    remain
                                                )
                                            end
                                            positiveIndex = positiveIndex + 1
                                        else
                                            negativeBuffDescription[player][negativeIndex] = description
                                            if player == hplayer.loc() then
                                                hjapi.DzFrameShow(
                                                    hjapi.DzFrameFindByName("negativebuff" .. negativeIndex, 0),
                                                    true
                                                )
                                                hjapi.DzFrameSetTexture(
                                                    hjapi.DzFrameFindByName("negativebuff" .. negativeIndex, 0),
                                                    art
                                                )
                                                if stack > 1 then
                                                    hjapi.DzFrameSetText(
                                                        hjapi.DzFrameFindByName(
                                                            "negativebuff" .. negativeIndex .. "_Stack",
                                                            0
                                                        ),
                                                        stack
                                                    )
                                                else
                                                    hjapi.DzFrameSetText(
                                                        hjapi.DzFrameFindByName(
                                                            "negativebuff" .. negativeIndex .. "_Stack",
                                                            0
                                                        ),
                                                        ""
                                                    )
                                                end
                                                hjapi.DzFrameSetText(
                                                    hjapi.DzFrameFindByName(
                                                        "negativebuff" .. negativeIndex .. "_Duration",
                                                        0
                                                    ),
                                                    remain
                                                )
                                            end
                                            negativeIndex = negativeIndex + 1
                                        end
                                    end
                                end
                                for i = positiveIndex, 9, 1 do
                                    if player == hplayer.loc() then
                                        hjapi.DzFrameShow(hjapi.DzFrameFindByName("positivebuff" .. i, 0), false)
                                    end
                                end
                                for i = negativeIndex, 9, 1 do
                                    if player == hplayer.loc() then
                                        hjapi.DzFrameShow(hjapi.DzFrameFindByName("negativebuff" .. i, 0), false)
                                    end
                                end
                            end
                            if player == hplayer.loc() then
                                hjapi.DzFrameShow(hjapi.DzFrameFindByName("direnbufflan", 0), true)
                            end
                        else
                            if player == hplayer.loc() then
                                hjapi.DzFrameShow(hjapi.DzFrameFindByName("direnbufflan", 0), false)
                            end
                        end
                    end
                end
            end
        end
    )
    local tipsFrame = hjapi.DzFrameFindByName("direnbufflan_Tips", 0)
    local descriptionFrame = hjapi.DzFrameFindByName("direnbufflan_Tips_Desc", 0)
    hjapi.DzFrameShow(tipsFrame, false)
    for i = 1, 9, 1 do
        local button = hjapi.DzFrameFindByName("positivebuff" .. i .. "_Button", 0)
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_ENTER,
            function()
                local whichPlayer = hplayer.loc()
                local tip = positiveBuffDescription[whichPlayer][i]
                hjapi.DzFrameClearAllPoints(tipsFrame)
                hjapi.DzFrameSetPoint(tipsFrame, 0, button, 8, 0, 0)
                hjapi.DzFrameSetText(descriptionFrame, tip)
                hjapi.DzFrameShow(tipsFrame, true)
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_LEAVE,
            function()
                hjapi.DzFrameShow(tipsFrame, false)
            end,
            false
        )
    end
    for i = 1, 9, 1 do
        local button = hjapi.DzFrameFindByName("negativebuff" .. i .. "_Button", 0)
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_ENTER,
            function()
                local whichPlayer = hplayer.loc()
                local tip = negativeBuffDescription[whichPlayer][i]
                tip = tip or ""
                hjapi.DzFrameClearAllPoints(tipsFrame)
                hjapi.DzFrameSetPoint(tipsFrame, 0, button, 8, 0, 0)
                hjapi.DzFrameSetText(descriptionFrame, tip)
                hjapi.DzFrameShow(tipsFrame, true)
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_LEAVE,
            function()
                hjapi.DzFrameShow(tipsFrame, false)
            end,
            false
        )
    end
end

function init_mainscene()
    local qicheng = hjapi.FrameTag("BACKDROP", "qicheng", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(qicheng, 0, hjapi.DzGetGameUI(), 0, 0.05, -0.0275)
    hjapi.DzFrameSetSize(qicheng, 0.0225, 0.03)
    hjapi.DzFrameSetTexture(qicheng, "ReplaceableTextures\\xitong\\UI_flag_1.blp", 0)
    hjapi.DzFrameShow(qicheng, true)
    local qichengWord = hjapi.FrameTag("BACKDROP", "qichengWord", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(qichengWord, 0, hjapi.DzGetGameUI(), 0, 0.05, -0.03)
    hjapi.DzFrameSetSize(qichengWord, 0.0225, 0.03)
    hjapi.DzFrameSetTexture(qichengWord, "ReplaceableTextures\\xitong\\qicheng.blp", 0)
    hjapi.DzFrameShow(qichengWord, true)
    local cundang = hjapi.FrameTag("BACKDROP", "cundang", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(cundang, 0, qicheng, 0, 0.03, 0)
    hjapi.DzFrameSetSize(cundang, 0.0225, 0.03)
    hjapi.DzFrameSetTexture(cundang, "ReplaceableTextures\\xitong\\UI_flag_2.blp", 0)
    hjapi.DzFrameShow(cundang, true)
    local cundangWord = hjapi.FrameTag("BACKDROP", "cundangWord", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(cundangWord, 0, qicheng, 0, 0.03, -0.0025)
    hjapi.DzFrameSetSize(cundangWord, 0.0225, 0.03)
    hjapi.DzFrameSetTexture(cundangWord, "ReplaceableTextures\\xitong\\cundang.blp", 0)
    hjapi.DzFrameShow(cundangWord, true)
    local tianfu = hjapi.FrameTag("BACKDROP", "tianfutubiao", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(tianfu, 0, cundang, 0, 0.03, 0)
    hjapi.DzFrameSetSize(tianfu, 0.0225, 0.03)
    hjapi.DzFrameSetTexture(tianfu, "ReplaceableTextures\\xitong\\UI_flag_3.blp", 0)
    hjapi.DzFrameShow(tianfu, true)
    local tianfuWord = hjapi.FrameTag("BACKDROP", "tianfuWord", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(tianfuWord, 0, cundang, 0, 0.03, -0.0025)
    hjapi.DzFrameSetSize(tianfuWord, 0.0225, 0.03)
    hjapi.DzFrameSetTexture(tianfuWord, "ReplaceableTextures\\xitong\\tianfu.blp", 0)
    hjapi.DzFrameShow(tianfuWord, true)
    local huicheng = hjapi.FrameTag("BACKDROP", "huicheng", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(huicheng, 0, tianfu, 0, 0.03, 0)
    hjapi.DzFrameSetSize(huicheng, 0.0225, 0.03)
    hjapi.DzFrameSetTexture(huicheng, "ReplaceableTextures\\xitong\\UI_flag_4.blp", 0)
    hjapi.DzFrameShow(huicheng, true)
    local huichengWord = hjapi.FrameTag("BACKDROP", "huichengWord", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(huichengWord, 0, tianfu, 0, 0.03, -0.0025)
    hjapi.DzFrameSetSize(huichengWord, 0.0225, 0.03)
    hjapi.DzFrameSetTexture(huichengWord, "ReplaceableTextures\\xitong\\huicheng.blp", 0)
    hjapi.DzFrameShow(huichengWord, true)
    local beibao = hjapi.FrameTag("BACKDROP", "beibao", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(beibao, 0, huicheng, 0, 0.03, 0)
    hjapi.DzFrameSetSize(beibao, 0.0225, 0.03)
    hjapi.DzFrameSetTexture(beibao, "ReplaceableTextures\\xitong\\UI_flag_5.blp", 0)
    hjapi.DzFrameShow(beibao, true)
    local beibaoWord = hjapi.FrameTag("BACKDROP", "beibaoWord", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(beibaoWord, 0, huicheng, 0, 0.03, -0.0025)
    hjapi.DzFrameSetSize(beibaoWord, 0.0225, 0.03)
    hjapi.DzFrameSetTexture(beibaoWord, "ReplaceableTextures\\xitong\\beibao.blp", 0)
    hjapi.DzFrameShow(beibaoWord, true)
end

local function init_general_icon()
    local qqlogo = hjapi.FrameTag("BACKDROP", "qqqunkklogo", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(qqlogo, 3, hjapi.DzGetGameUI(), 3, 0.005, -0.115)
    hjapi.DzFrameSetSize(qqlogo, 0.024, 0.032)
    hjapi.DzFrameSetTexture(qqlogo, "ReplaceableTextures\\xitong\\ui_dianjijiaqun.blp", 0)
    hjapi.DzFrameShow(qqlogo, true)
    local qqButton = hjapi.FrameTag("BUTTON", "qqqun_button", qqlogo)
    hjapi.DzFrameSetPoint(qqButton, 4, qqlogo, 4, 0, 0)
    hjapi.DzFrameSetSize(qqButton, 0.024, 0.032)
    hjapi.DzFrameShow(qqButton, true)
    local lastQQUrl = -1
    hjapi.DzFrameSetScriptByCode(
        qqButton,
        MOUSE_ORDER_CLICK,
        function()
            if lastQQUrl == -1 or htime.inc - lastQQUrl > 12000 then
                lastQQUrl = htime.inc
                hjapi.DzOpenQQGroupUrl("https://qm.qq.com/q/uxZXRzLHLq")
            else
                echo("加群功能冷却中（2分钟），请稍后再试", hplayer.loc())
            end
        end,
        false
    )

    local shuxing = hjapi.FrameTag("BACKDROP", "shuxing", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(shuxing, 3, qqlogo, 5, 0.005, 0)
    hjapi.DzFrameSetSize(shuxing, 0.024, 0.032)
    hjapi.DzFrameSetTexture(shuxing, "ReplaceableTextures\\xitong\\ui_shuxingxiangqing.blp", 0)
    local sxButton = hjapi.FrameTag("BUTTON", "shuxing_button", shuxing)
    hjapi.DzFrameSetPoint(sxButton, 4, shuxing, 4, 0, 0)
    hjapi.DzFrameSetSize(sxButton, 0.024, 0.032)
    hjapi.DzFrameShow(sxButton, true)
    hjapi.DzFrameSetScriptByCode(
        sxButton,
        MOUSE_ORDER_ENTER,
        function()
            local attrDesc = hcache.get(hplayer.loc(), "ATTR_DESCRIPTION", "")
            local attrBack = hjapi.DzFrameFindByName("ALL_Attribute", 0)
            local wuli = hjapi.DzFrameFindByName("ALL_Attribute_WULI_Desc", 0)
            local wuliback = hjapi.DzFrameFindByName("ALL_Attribute_WULI_Back", 0)
            local mofa = hjapi.DzFrameFindByName("ALL_Attribute_MOFA_Desc", 0)
            local tongyong = hjapi.DzFrameFindByName("ALL_Attribute_TONGYONG_Desc", 0)
            local fangyu = hjapi.DzFrameFindByName("ALL_Attribute_FANGYU_Desc", 0)
            local zhuanye = hjapi.DzFrameFindByName("ALL_Attribute_ZHUANYE_Desc", 0)
            local qita = hjapi.DzFrameFindByName("ALL_Attribute_QITA_Desc", 0)
            hjapi.DzFrameSetText(wuli, attrDesc[CONST_ATTR_SHOW_TYPE.WULI])
            hjapi.DzFrameSetText(mofa, attrDesc[CONST_ATTR_SHOW_TYPE.MOFA])
            hjapi.DzFrameSetText(tongyong, attrDesc[CONST_ATTR_SHOW_TYPE.TONGYONG])
            hjapi.DzFrameSetText(fangyu, attrDesc[CONST_ATTR_SHOW_TYPE.FANGYU])
            hjapi.DzFrameSetText(zhuanye, attrDesc[CONST_ATTR_SHOW_TYPE.ZHUANYE])
            hjapi.DzFrameSetText(qita, attrDesc[CONST_ATTR_SHOW_TYPE.QITA])
            hjapi.DzFrameSetPoint(wuliback, 6, shuxing, 2, 0.005, 0.165)
            hjapi.DzFrameShow(attrBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        sxButton,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Attribute", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )
    hjapi.DzFrameShow(shuxing, true)
    htime.setInterval(
        1,
        function(curTimer)
            hplayer.forEach(
                function(enumPlayer, _)
                    if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                        return
                    end
                    hcache.set(enumPlayer, "ATTR_DESCRIPTION", hattribute.getAttrDescpritionForView(enumPlayer))
                end
            )
        end
    )

    local ditudengji = hjapi.FrameTag("BACKDROP", "ditudengji", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(ditudengji, 3, shuxing, 5, 0.005, 0)
    hjapi.DzFrameSetSize(ditudengji, 0.024, 0.032)
    hjapi.DzFrameSetTexture(ditudengji, "ReplaceableTextures\\xitong\\ui_ditudengji.blp", 0)
    local ditudengjiButton = hjapi.FrameTag("BUTTON", "ditudengji_button", ditudengji)
    hjapi.DzFrameSetPoint(ditudengjiButton, 4, ditudengji, 4, 0, 0)
    hjapi.DzFrameSetSize(ditudengjiButton, 0.024, 0.032)
    hjapi.DzFrameShow(ditudengjiButton, true)
    hjapi.DzFrameSetScriptByCode(
        ditudengjiButton,
        MOUSE_ORDER_ENTER,
        function()
            local tip = hcache.get(hplayer.loc(), "ditudengji_desc", "请先选择英雄")
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.2300, 0)
            hjapi.DzFrameSetPoint(tipsText, 6, ditudengjiButton, 2, 0, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        ditudengjiButton,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )
    hjapi.DzFrameShow(ditudengji, true)

    local mingwen = hjapi.FrameTag("BACKDROP", "mingwen", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(mingwen, 3, ditudengji, 5, 0.005, 0)
    hjapi.DzFrameSetSize(mingwen, 0.024, 0.032)
    hjapi.DzFrameSetTexture(mingwen, "ReplaceableTextures\\xitong\\ui_mingwenzhuangtai.blp", 0)
    local mingwenButton = hjapi.FrameTag("BUTTON", "mingwen_button", mingwen)
    hjapi.DzFrameSetPoint(mingwenButton, 4, mingwen, 4, 0, 0)
    hjapi.DzFrameSetSize(mingwenButton, 0.024, 0.032)
    hjapi.DzFrameShow(mingwenButton, true)
    hjapi.DzFrameSetScriptByCode(
        mingwenButton,
        MOUSE_ORDER_ENTER,
        function()
            local tip = hmingwen.descriptions[hplayer.loc()] or "请先选择英雄"
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.2300, 0)
            hjapi.DzFrameSetPoint(tipsText, 6, mingwenButton, 2, 0, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        mingwenButton,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )
    hjapi.DzFrameShow(mingwen, true)

    local ziyuan = hjapi.FrameTag("BACKDROP", "ziyuan", hjapi.DzGetGameUI(), "")
    hjapi.DzFrameSetPoint(ziyuan, 3, mingwen, 5, 0.005, 0)
    hjapi.DzFrameSetSize(ziyuan, 0.024, 0.032)
    hjapi.DzFrameSetTexture(ziyuan, "ReplaceableTextures\\xitong\\ui_ziyuanzhaungtai.blp", 0)
    local ziyuanButton = hjapi.FrameTag("BUTTON", "ziyuan_button", ziyuan)
    hjapi.DzFrameSetPoint(ziyuanButton, 4, ziyuan, 4, 0, 0)
    hjapi.DzFrameSetSize(ziyuanButton, 0.024, 0.032)
    hjapi.DzFrameShow(ziyuanButton, true)
    hjapi.DzFrameSetScriptByCode(
        ziyuanButton,
        MOUSE_ORDER_ENTER,
        function()
            local tip = hresource.getDescription(hplayer.loc())
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.2300, 0)
            hjapi.DzFrameSetPoint(tipsText, 6, ziyuanButton, 2, 0, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        ziyuanButton,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )
    hjapi.DzFrameShow(ziyuan, true)

    local rexinwanjia = hjapi.FrameTag("BACKDROP", "rexinwanjia", hjapi.DzGetGameUI())
    hjapi.DzFrameSetPoint(rexinwanjia, 3, ziyuan, 5, 0.005, 0)
    hjapi.DzFrameSetSize(rexinwanjia, 0.024, 0.032)
    hjapi.DzFrameSetTexture(rexinwanjia, "ReplaceableTextures\\xitong\\ui_rexinjifeng.blp", 0)
    local rexinwanjiaButton = hjapi.FrameTag("BUTTON", "ziyuan_button", rexinwanjia)
    hjapi.DzFrameSetPoint(rexinwanjiaButton, 4, rexinwanjia, 4, 0, 0)
    hjapi.DzFrameSetSize(rexinwanjiaButton, 0.024, 0.032)
    hjapi.DzFrameShow(rexinwanjiaButton, true)
    hjapi.DzFrameSetScriptByCode(
        rexinwanjiaButton,
        MOUSE_ORDER_ENTER,
        function()
            local tip = hcache.get(hplayer.loc(), "REXINWANJIA_MIAOSHU", "装载中")
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.2300, 0)
            hjapi.DzFrameSetPoint(tipsText, 6, rexinwanjiaButton, 2, 0, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        rexinwanjiaButton,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )
    hjapi.DzFrameShow(rexinwanjia, true)

    local daixinjifen = hjapi.FrameTag("BACKDROP", "daixinjifen", hjapi.DzGetGameUI())
    hjapi.DzFrameSetPoint(daixinjifen, 3, rexinwanjia, 5, 0.005, 0)
    hjapi.DzFrameSetSize(daixinjifen, 0.024, 0.032)
    hjapi.DzFrameSetTexture(daixinjifen, "ReplaceableTextures\\xitong\\daixinjifen.blp", 0)
    local daixinjifenButton = hjapi.FrameTag("BUTTON", "ziyuan_button", daixinjifen)
    hjapi.DzFrameSetPoint(daixinjifenButton, 4, daixinjifen, 4, 0, 0)
    hjapi.DzFrameSetSize(daixinjifenButton, 0.024, 0.032)
    hjapi.DzFrameShow(daixinjifenButton, true)
    hjapi.DzFrameSetScriptByCode(
        daixinjifenButton,
        MOUSE_ORDER_ENTER,
        function()
            local tip = hdaixin.desc[hplayer.loc()] or "初始化中"
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.3000, 0)
            hjapi.DzFrameSetPoint(tipsText, 6, daixinjifenButton, 2, 0, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        daixinjifenButton,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )
    hjapi.DzFrameShow(daixinjifen, true)


    local huodongjieshao = hjapi.FrameTag("BACKDROP", "huodongjieshao", hjapi.DzGetGameUI())
    hjapi.DzFrameSetPoint(huodongjieshao, FRAME_ALIGN_BOTTOM, qqlogo, FRAME_ALIGN_TOP, 0, 0.005)
    hjapi.DzFrameSetSize(huodongjieshao, 0.024, 0.032)
    hjapi.DzFrameSetTexture(huodongjieshao, "huodong\\UI_huodongjieshao.blp", 0)
    local huodongButton = hjapi.FrameTag("BUTTON", "huodongButton", huodongjieshao)
    hjapi.DzFrameSetPoint(huodongButton, 4, huodongjieshao, 4, 0, 0)
    hjapi.DzFrameSetSize(huodongButton, 0.024, 0.032)
    hjapi.DzFrameShow(huodongButton, true)
    hjapi.DzFrameSetScriptByCode(
        huodongButton,
        MOUSE_ORDER_ENTER,
        function()
            local tip = GLOBAL_HUODONG_JIESHAO or "初始化中"
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.3000, 0)
            hjapi.DzFrameSetPoint(tipsText, 6, huodongButton, 2, 0.05, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        huodongButton,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )
    hjapi.DzFrameShow(huodongjieshao, true)

    local chongwutanxian = hjapi.FrameTag("BACKDROP", "chongwutanxian", hjapi.DzGetGameUI())
    hjapi.DzFrameSetPoint(chongwutanxian, 3, huodongjieshao, 5, 0.005, 0)
    hjapi.DzFrameSetSize(chongwutanxian, 0.024, 0.032)
    hjapi.DzFrameSetTexture(chongwutanxian, "ReplaceableTextures\\shangcheng\\宠物探险.blp", 0)
    local chongwutanxianButton = hjapi.FrameTag("BUTTON", "ziyuan_button", chongwutanxian)
    hjapi.DzFrameSetPoint(chongwutanxianButton, 4, chongwutanxian, 4, 0, 0)
    hjapi.DzFrameSetSize(chongwutanxianButton, 0.024, 0.032)
    hjapi.DzFrameShow(chongwutanxianButton, true)
    hjapi.DzFrameSetScriptByCode(
        chongwutanxianButton,
        MOUSE_ORDER_ENTER,
        function()
            local tip = hcache.get(hplayer.loc(), "CHONGWUTANXIAN_MIAOSHU", "装载中")
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.2300, 0)
            hjapi.DzFrameSetPoint(tipsText, 6, chongwutanxianButton, 2, 0, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        chongwutanxianButton,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )
    hjapi.DzFrameShow(chongwutanxian, true)
end

local function init_shop_UI()
    hjapi.DzLoadToc("UI\\ui_shop.toc")
    local tmp = hjapi.DzCreateFrame("ShopFrmRootWindow", hjapi.DzGetGameUI(), 0)
    hjapi.DzFrameSetAbsolutePoint(tmp, 4, 0.6, 0.35)
    hjapi.DzFrameShow(tmp, false)

    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hshop.shopData[enumPlayer] = {
                currentPage = 1,
                currentNPCName = nil
            }
        end
    )

    -- 右上角关闭界面
    hjapi.DzFrameSetScriptByCode(
        hjapi.DzFrameFindByName("ShopBtnRootWindow_Close", 0),
        MOUSE_ORDER_CLICK,
        function()
            hjapi.DzFrameShow(tmp, false)
        end,
        false
    )
    -- 前一页
    hjapi.DzFrameSetScriptByCode(
        hjapi.DzFrameFindByName("ShopBtnRootWindow_PrePage", 0),
        MOUSE_ORDER_CLICK,
        function()
            local whichPlayer = hplayer.loc()
            local userShopData = hshop.shopData[whichPlayer]
            update_shop_UI_to_page(whichPlayer, userShopData.currentNPC, userShopData.currentPage - 1)
        end,
        false
    )
    -- 后一页
    hjapi.DzFrameSetScriptByCode(
        hjapi.DzFrameFindByName("ShopBtnRootWindow_NextPage", 0),
        MOUSE_ORDER_CLICK,
        function()
            local whichPlayer = hplayer.loc()
            local userShopData = hshop.shopData[whichPlayer]
            update_shop_UI_to_page(whichPlayer, userShopData.currentNPC, userShopData.currentPage + 1)
        end,
        false
    )
    -- 鼠标放上面的提示 以及按钮事件
    for i = 1, 10, 1 do
        local button = hjapi.DzFrameFindByName("ShopBtnRootWindow_Item" .. tostring(i) .. "_Button", 0)
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_ENTER,
            function()
                local whichPlayer = hplayer.loc()
                local userShopData = hshop.shopData[whichPlayer]
                local currentPage = userShopData.currentPage
                local index = 10 * (currentPage - 1) + i
                local tip = hshop.detail[userShopData.currentNPCName][index].tips
                local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
                local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
                hjapi.DzFrameClearAllPoints(tipsText)
                hjapi.DzFrameSetSize(tipsText, 0.1200, 0)
                hjapi.DzFrameSetPoint(tipsText, 5, tmp, 3, -0.01, 0)
                hjapi.DzFrameSetText(tipsText, tip)
                hjapi.DzFrameShow(tipsBack, true)
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_LEAVE,
            function()
                local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
                hjapi.DzFrameShow(tipsBack, false)
            end,
            false
        )
        hjapi.DzFrameSetScriptByCode(
            button,
            MOUSE_ORDER_CLICK,
            function()
                local whichPlayer = hplayer.loc()
                local userShopData = hshop.shopData[whichPlayer]
                local currentPage = userShopData.currentPage
                local index = 10 * (currentPage - 1) + i
                hshop.detail[userShopData.currentNPCName][index].callback()
            end,
            false
        )
    end
end

function turnOnUI(name)
    if name == "专业" then
        local zhuanyeFrame = hjapi.DzFrameFindByName("ZhuanyeFrmRootWindow", 0)
        hjapi.DzFrameShow(zhuanyeFrame, true)
        local shopsFrame = hjapi.DzFrameFindByName("ShopFrmRootWindow", 0)
        hjapi.DzFrameShow(shopsFrame, false)
        hjapi.DzFrameShow(UI_global_dabeibaoUI, false)
        hjapi.DzFrameShow(UI_global_tianfu, false)
        local achievementFrame = hjapi.DzFrameFindByName("FrmRootWindow", 0)
        hjapi.DzFrameShow(achievementFrame, false)
        hjapi.DzFrameShow(UI_global_sqtianfu["main"], false)
    elseif name == "大背包" then
        local zhuanyeFrame = hjapi.DzFrameFindByName("ZhuanyeFrmRootWindow", 0)
        hjapi.DzFrameShow(zhuanyeFrame, false)
        local shopsFrame = hjapi.DzFrameFindByName("ShopFrmRootWindow", 0)
        hjapi.DzFrameShow(shopsFrame, false)
        hjapi.DzFrameShow(UI_global_dabeibaoUI, true)
        hjapi.DzFrameShow(UI_global_tianfu, false)
        --local achievementFrame = hjapi.DzFrameFindByName("FrmRootWindow", 0)
        --hjapi.DzFrameShow(achievementFrame, false)
        hjapi.DzFrameShow(UI_global_sqtianfu["main"], false)
    elseif name == "商店" then
        local zhuanyeFrame = hjapi.DzFrameFindByName("ZhuanyeFrmRootWindow", 0)
        hjapi.DzFrameShow(zhuanyeFrame, false)
        local shopsFrame = hjapi.DzFrameFindByName("ShopFrmRootWindow", 0)
        hjapi.DzFrameShow(shopsFrame, true)
        hjapi.DzFrameShow(UI_global_dabeibaoUI, false)
        hjapi.DzFrameShow(UI_global_tianfu, false)
        local achievementFrame = hjapi.DzFrameFindByName("FrmRootWindow", 0)
        hjapi.DzFrameShow(achievementFrame, false)
        hjapi.DzFrameShow(UI_global_sqtianfu["main"], false)
    elseif name == "天赋" then
        local zhuanyeFrame = hjapi.DzFrameFindByName("ZhuanyeFrmRootWindow", 0)
        hjapi.DzFrameShow(zhuanyeFrame, false)
        local shopsFrame = hjapi.DzFrameFindByName("ShopFrmRootWindow", 0)
        hjapi.DzFrameShow(shopsFrame, false)
        hjapi.DzFrameShow(UI_global_dabeibaoUI, false)
        hjapi.DzFrameShow(UI_global_tianfu, true)
        local achievementFrame = hjapi.DzFrameFindByName("FrmRootWindow", 0)
        hjapi.DzFrameShow(achievementFrame, false)
        hjapi.DzFrameShow(UI_global_sqtianfu["main"], false)
    elseif name == "成就" then
        local zhuanyeFrame = hjapi.DzFrameFindByName("ZhuanyeFrmRootWindow", 0)
        hjapi.DzFrameShow(zhuanyeFrame, false)
        --local shopsFrame = hjapi.DzFrameFindByName("ShopFrmRootWindow", 0)
        --hjapi.DzFrameShow(shopsFrame, false)
        --hjapi.DzFrameShow(UI_global_dabeibaoUI, false)
        hjapi.DzFrameShow(UI_global_tianfu, false)
        local achievementFrame = hjapi.DzFrameFindByName("FrmRootWindow", 0)
        hjapi.DzFrameShow(achievementFrame, true)
        hjapi.DzFrameShow(UI_global_sqtianfu["main"], false)
    elseif name == "神器" then
        local zhuanyeFrame = hjapi.DzFrameFindByName("ZhuanyeFrmRootWindow", 0)
        hjapi.DzFrameShow(zhuanyeFrame, false)
        local shopsFrame = hjapi.DzFrameFindByName("ShopFrmRootWindow", 0)
        hjapi.DzFrameShow(shopsFrame, false)
        hjapi.DzFrameShow(UI_global_dabeibaoUI, false)
        hjapi.DzFrameShow(UI_global_tianfu, false)
        local achievementFrame = hjapi.DzFrameFindByName("FrmRootWindow", 0)
        hjapi.DzFrameShow(achievementFrame, false)
        hjapi.DzFrameShow(UI_global_sqtianfu["main"], true)
    end
end

function turnOffUI(name)
    if name == "专业" then
        local zhuanyeFrame = hjapi.DzFrameFindByName("ZhuanyeFrmRootWindow", 0)
        hjapi.DzFrameShow(zhuanyeFrame, false)
    elseif name == "大背包" then
        hjapi.DzFrameShow(UI_global_dabeibaoUI, false)
    elseif name == "商店" then
        local shopsFrame = hjapi.DzFrameFindByName("ShopFrmRootWindow", 0)
        hjapi.DzFrameShow(shopsFrame, false)
    elseif name == "天赋" then
        hjapi.DzFrameShow(UI_global_tianfu, false)
    elseif name == "成就" then
        local achievementFrame = hjapi.DzFrameFindByName("FrmRootWindow", 0)
        hjapi.DzFrameShow(achievementFrame, false)
    end
end

function update_shop_UI_to_page(whichPlayer, NPC, targetPage)
    local npcName = hunit.getName(NPC)
    if hshop.detail[npcName] == nil then
        echo(npcName .. "表示没有什么可以交易的")
        return
    end
    local categoryData = hshop.detail[npcName]
    local totalPageCount = math.max(math.ceil(#categoryData / 10), 1)
    if targetPage == nil or targetPage > totalPageCount or targetPage < 1 then
        return
    end
    hshop.shopData[whichPlayer].currentPage = targetPage
    hshop.shopData[whichPlayer].currentNPCName = npcName
    hshop.shopData[whichPlayer].currentNPC = NPC
    local pageText = tostring(targetPage) .. "/" .. tostring(totalPageCount)
    if hplayer.loc() == whichPlayer then
        hjapi.DzFrameSetText(hjapi.DzFrameFindByName("ShopTxtRootWindow_Title", 0), npcName)
        hjapi.DzFrameSetText(hjapi.DzFrameFindByName("ShopTxtRootWindow_PageNum", 0), pageText)
        for i = 10 * (targetPage - 1) + 1, 10 * targetPage, 1 do
            local UI_index = i - 10 * (targetPage - 1)
            if i <= #categoryData then
                hjapi.DzFrameSetText(
                    hjapi.DzFrameFindByName("ShopTxtRootWindow_Item" .. tostring(UI_index) .. "_Name", 0),
                    categoryData[i].name
                )
                hjapi.DzFrameSetTexture(
                    hjapi.DzFrameFindByName("ShopImgRootWindow_Item" .. tostring(UI_index) .. "_Icon", 0),
                    categoryData[i].art
                )
                hjapi.DzFrameShow(
                    hjapi.DzFrameFindByName("ShopImgRootWindow_Item" .. tostring(UI_index) .. "_Mask", 0),
                    false
                )
                hjapi.DzFrameShow(hjapi.DzFrameFindByName("ShopFrmRootWindow_Item" .. tostring(UI_index), 0), true)
            else
                hjapi.DzFrameShow(hjapi.DzFrameFindByName("ShopFrmRootWindow_Item" .. tostring(UI_index), 0), false)
            end
        end
        turnOnUI("商店")
    end
end

local init_gear_score_UI = function()
    hjapi.DzLoadToc("UI\\ui_gearScore.toc")
    local gearScore = hjapi.DzCreateFrame("gearScore", hjapi.DzGetGameUI(), 0)
    hjapi.DzFrameSetAbsolutePoint(gearScore, FRAME_ALIGN_CENTER, 0.255, 0.128)
end

local init_check_box = function()
    local zhinengshifaText = hjapi.FrameTag("TEXT", "zhinengshifatext", hjapi.DzGetGameUI())
    hjapi.DzFrameSetFont(zhinengshifaText, "war3mapImported\\fonts.ttf", 0.010, 0)
    hjapi.DzFrameSetText(zhinengshifaText, "智能施法")
    hjapi.DzFrameSetAbsolutePoint(zhinengshifaText, 3, 0, 0.252)
    hjapi.DzFrameShow(zhinengshifaText, true)
    local zhinengshifa =
        hjapi.DzCreateFrameByTagName("GLUECHECKBOX", "zhinengshifa", zhinengshifaText, "QuestCheckBox2", 0)
    hjapi.DzFrameSetPoint(zhinengshifa, 3, zhinengshifaText, 5, 0, 0)
    hjapi.DzFrameSetSize(zhinengshifa, 0.012, 0.016)
    hjapi.DzFrameShow(zhinengshifa, true)

    hjapi.DzFrameSetScriptByCode(
        zhinengshifa,
        FRAME_EVENT_CHECKBOX_CHECK,
        function()
            hsync.send("kaiqizhinengshifa", {})
        end,
        false
    )
    hsync.onSend(
        "kaiqizhinengshifa",
        function(syncData)
            hcache.set(syncData.triggerPlayer, "zhinengshifa", true)
        end
    )
    hjapi.DzFrameSetScriptByCode(
        zhinengshifa,
        FRAME_EVENT_CHECKBOX_UNCHECK,
        function()
            hsync.send("guanbizhinengshifa", {})
        end,
        false
    )
    hsync.onSend(
        "guanbizhinengshifa",
        function(syncData)
            hcache.set(syncData.triggerPlayer, "zhinengshifa", false)
        end
    )

    hjapi.DzFrameSetScriptByCode(
        zhinengshifa,
        MOUSE_ORDER_ENTER,
        function()
            local tip =
                hcolor.yellow("智能施法") .. "|n打开/关闭智能施法。打开后，指向型对敌技能会记录目标，下次再按指向性技能快捷键时会自动对记录的目标释放。如果鼠标当时指向敌人，则不会触发这个效果。"
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.1200, 0)
            hjapi.DzFrameSetPoint(tipsText, FRAMEPOINT_LEFT, zhinengshifa, FRAMEPOINT_RIGHT, 0.02, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        zhinengshifa,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )

    local lianxuzhizaoText = hjapi.FrameTag("TEXT", "lianxuzhizaoText", hjapi.DzGetGameUI())
    hjapi.DzFrameSetFont(lianxuzhizaoText, "war3mapImported\\fonts.ttf", 0.010, 0)
    hjapi.DzFrameSetText(lianxuzhizaoText, "连续制造")
    hjapi.DzFrameSetPoint(lianxuzhizaoText, 7, zhinengshifaText, 1, 0, 0.005)
    hjapi.DzFrameShow(lianxuzhizaoText, true)
    local lianxuzhizao =
        hjapi.DzCreateFrameByTagName("GLUECHECKBOX", "lianxuzhizao", lianxuzhizaoText, "QuestCheckBox2", 0)
    hjapi.DzFrameSetPoint(lianxuzhizao, 3, lianxuzhizaoText, 5, 0, 0)
    hjapi.DzFrameSetSize(lianxuzhizao, 0.012, 0.016)
    hjapi.DzFrameShow(lianxuzhizao, true)

    hjapi.DzFrameSetScriptByCode(
        lianxuzhizao,
        FRAME_EVENT_CHECKBOX_CHECK,
        function()
            hsync.send("kaiqilianxuzhizao", {})
        end,
        false
    )
    hsync.onSend(
        "kaiqilianxuzhizao",
        function(syncData)
            hcache.set(syncData.triggerPlayer, "lianxuzhizao", true)
        end
    )
    hjapi.DzFrameSetScriptByCode(
        lianxuzhizao,
        FRAME_EVENT_CHECKBOX_UNCHECK,
        function()
            hsync.send("guanbilianxuzhizao", {})
        end,
        false
    )
    hsync.onSend(
        "guanbilianxuzhizao",
        function(syncData)
            hcache.set(syncData.triggerPlayer, "lianxuzhizao", false)
        end
    )
    hjapi.DzFrameSetScriptByCode(
        lianxuzhizao,
        MOUSE_ORDER_ENTER,
        function()
            local tip = hcolor.yellow("连续制造") .. "|n打开/关闭连续制造。打开后，制作专业物品会自动继续制作，直到材料不足或者被打断。"
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.1200, 0)
            hjapi.DzFrameSetPoint(tipsText, FRAMEPOINT_LEFT, lianxuzhizao, FRAMEPOINT_RIGHT, 0.02, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        lianxuzhizao,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )

    local shanghaishuziText = hjapi.FrameTag("TEXT", "shanghaishuziText", hjapi.DzGetGameUI())
    hjapi.DzFrameSetFont(shanghaishuziText, "war3mapImported\\fonts.ttf", 0.010, 0)
    hjapi.DzFrameSetText(shanghaishuziText, "伤害数字")
    hjapi.DzFrameSetPoint(shanghaishuziText, 7, lianxuzhizaoText, 1, 0, 0.005)
    hjapi.DzFrameShow(shanghaishuziText, true)
    local shanghaishuzi =
        hjapi.DzCreateFrameByTagName("GLUECHECKBOX", "shanghaishuzi", shanghaishuziText, "QuestCheckBox2", 0)
    hjapi.DzFrameSetPoint(shanghaishuzi, 3, shanghaishuziText, 5, 0, 0)
    hjapi.DzFrameSetSize(shanghaishuzi, 0.012, 0.016)
    hjapi.DzFrameShow(shanghaishuzi, true)

    hjapi.DzFrameSetScriptByCode(
        shanghaishuzi,
        FRAME_EVENT_CHECKBOX_CHECK,
        function()
            hsync.send("kaiqishanghaishuzi", {})
        end,
        false
    )
    hsync.onSend(
        "kaiqishanghaishuzi",
        function(syncData)
            hcache.set(syncData.triggerPlayer, "shanghaishuzi", true)
        end
    )
    hjapi.DzFrameSetScriptByCode(
        shanghaishuzi,
        FRAME_EVENT_CHECKBOX_UNCHECK,
        function()
            hsync.send("guanbishanghaishuzi", {})
        end,
        false
    )
    hsync.onSend(
        "guanbishanghaishuzi",
        function(syncData)
            hcache.set(syncData.triggerPlayer, "shanghaishuzi", false)
        end
    )
    hjapi.DzFrameSetScriptByCode(
        shanghaishuzi,
        MOUSE_ORDER_ENTER,
        function()
            local tip = hcolor.yellow("伤害数字") .. "|n打开后，只会显示自己造成伤害的伤害数字。"
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.1200, 0)
            hjapi.DzFrameSetPoint(tipsText, FRAMEPOINT_LEFT, shanghaishuzi, FRAMEPOINT_RIGHT, 0.02, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        shanghaishuzi,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )

    local buffMonitorText = hjapi.FrameTag("TEXT", "buffMonitorText", hjapi.DzGetGameUI())
    hjapi.DzFrameSetFont(buffMonitorText, "war3mapImported\\fonts.ttf", 0.010, 0)
    hjapi.DzFrameSetText(buffMonitorText, "状态监视")
    hjapi.DzFrameSetPoint(buffMonitorText, 7, shanghaishuziText, 1, 0, 0.005)
    hjapi.DzFrameShow(buffMonitorText, true)
    local buffMonitor =
        hjapi.DzCreateFrameByTagName("GLUECHECKBOX", "buffMonitor", buffMonitorText, "QuestCheckBox2", 0)
    hjapi.DzFrameSetPoint(buffMonitor, 3, buffMonitorText, 5, 0, 0)
    hjapi.DzFrameSetSize(buffMonitor, 0.012, 0.016)
    hjapi.DzFrameShow(buffMonitor, true)

    hjapi.DzFrameSetScriptByCode(
        buffMonitor,
        FRAME_EVENT_CHECKBOX_CHECK,
        function()
            hsync.send("kaiqibuffMonitor", {})
        end,
        false
    )
    hsync.onSend(
        "kaiqibuffMonitor",
        function(syncData)
            hcache.set(syncData.triggerPlayer, "buffMonitor", true)
        end
    )
    hjapi.DzFrameSetScriptByCode(
        buffMonitor,
        FRAME_EVENT_CHECKBOX_UNCHECK,
        function()
            hsync.send("guanbibuffMonitor", {})
        end,
        false
    )
    hsync.onSend(
        "guanbibuffMonitor",
        function(syncData)
            hcache.set(syncData.triggerPlayer, "buffMonitor", false)
        end
    )
    hjapi.DzFrameSetScriptByCode(
        buffMonitor,
        MOUSE_ORDER_ENTER,
        function()
            local tip = hcolor.yellow("重要状态显示") .. "|n打开后，各职业的关键BUFF会额外显示在屏幕中间两侧。英雄自身的关键会显示在屏幕左边，敌人身上的关键状态会显示在屏幕右边。"
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.1200, 0)
            hjapi.DzFrameSetPoint(tipsText, FRAMEPOINT_LEFT, buffMonitor, FRAMEPOINT_RIGHT, 0.02, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        buffMonitor,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )

    local bossshanghaiText = hjapi.FrameTag("TEXT", "bossshanghaiText", hjapi.DzGetGameUI())
    hjapi.DzFrameSetFont(bossshanghaiText, "war3mapImported\\fonts.ttf", 0.010, 0)
    hjapi.DzFrameSetText(bossshanghaiText, "首领伤害")
    hjapi.DzFrameSetPoint(bossshanghaiText, 7, buffMonitorText, 1, 0, 0.005)
    hjapi.DzFrameShow(bossshanghaiText, true)
    local bossshanghai =
        hjapi.DzCreateFrameByTagName("GLUECHECKBOX", "bossshanghai", bossshanghaiText, "QuestCheckBox2", 0)
    hjapi.DzFrameSetPoint(bossshanghai, 3, bossshanghaiText, 5, 0, 0)
    hjapi.DzFrameSetSize(bossshanghai, 0.012, 0.016)
    hjapi.DzFrameShow(bossshanghai, true)

    hjapi.DzFrameSetScriptByCode(
        bossshanghai,
        FRAME_EVENT_CHECKBOX_CHECK,
        function()
            hsync.send("kaiqibossshanghai", {})
        end,
        false
    )
    hsync.onSend(
        "kaiqibossshanghai",
        function(syncData)
            hcache.set(syncData.triggerPlayer, "bossshanghai", true)
        end
    )
    hjapi.DzFrameSetScriptByCode(
        bossshanghai,
        FRAME_EVENT_CHECKBOX_UNCHECK,
        function()
            hsync.send("guanbibossshanghai", {})
        end,
        false
    )
    hsync.onSend(
        "guanbibossshanghai",
        function(syncData)
            hcache.set(syncData.triggerPlayer, "bossshanghai", false)
        end
    )
    hjapi.DzFrameSetScriptByCode(
        bossshanghai,
        MOUSE_ORDER_ENTER,
        function()
            local tip = hcolor.yellow("首领伤害") .. "|n打开后，伤害统计只会统计对首领造成的伤害。"
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.1200, 0)
            hjapi.DzFrameSetPoint(tipsText, FRAMEPOINT_LEFT, bossshanghai, FRAMEPOINT_RIGHT, 0.02, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        bossshanghai,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )

    local zdzdText = hjapi.FrameTag("TEXT", "zdzdText", hjapi.DzGetGameUI())
    hjapi.DzFrameSetFont(zdzdText, "war3mapImported\\fonts.ttf", 0.010, 0)
    hjapi.DzFrameSetText(zdzdText, "自动战斗")
    hjapi.DzFrameSetPoint(zdzdText, 7, bossshanghaiText, 1, 0, 0.005)
    hjapi.DzFrameShow(zdzdText, true)
    local zdzd =
        hjapi.DzCreateFrameByTagName("GLUECHECKBOX", "zdzd", bossshanghaiText, "QuestCheckBox2", 0)
    hjapi.DzFrameSetPoint(zdzd, 3, zdzdText, 5, 0, 0)
    hjapi.DzFrameSetSize(zdzd, 0.012, 0.016)
    hjapi.DzFrameShow(zdzd, true)

    hjapi.DzFrameSetScriptByCode(
        zdzd,
        FRAME_EVENT_CHECKBOX_CHECK,
        function()
            hsync.send("kaiqizdzd", {})
        end,
        false
    )
    hsync.onSend(
        "kaiqizdzd",
        function(syncData)
            local hero = hplayer.getMainHero(syncData.triggerPlayer)
            if hero == nil then
                return
            end
            hbuff.update(
                -1, hero, "自动战斗", true, nil, nil, "ReplaceableTextures\\daozei\\shuangchizhuanjing.blp",
                "自动战斗|n冒险者会自动攻击当前地图中的敌人。", 1, 1,
                function()
                    local ai = hcache.get(hero, CONST_CACHE.PLAYER_AI)
                    if ai ~= nil and type(ai) == 'function' then
                        ai()
                    end
                end, nil, nil, HBUFF_UPDATE_MODE.OVERWRITE, true
            )
        end
    )
    hjapi.DzFrameSetScriptByCode(
        zdzd,
        FRAME_EVENT_CHECKBOX_UNCHECK,
        function()
            hsync.send("guanbizdzd", {})
        end,
        false
    )
    hsync.onSend(
        "guanbizdzd",
        function(syncData)
            local hero = hplayer.getMainHero(syncData.triggerPlayer)
            if hero == nil then
                return
            end
            hbuff.delete(hero, "自动战斗")
        end
    )
    hjapi.DzFrameSetScriptByCode(
        zdzd,
        MOUSE_ORDER_ENTER,
        function()
            local tip = hcolor.yellow("自动战斗") .. "|n打开后，冒险者会自动攻击当前地图中的敌人。"
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.1200, 0)
            hjapi.DzFrameSetPoint(tipsText, FRAMEPOINT_LEFT, bossshanghai, FRAMEPOINT_RIGHT, 0.02, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        zdzd,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )

    local zdxqText = hjapi.FrameTag("TEXT", "zdxqText", hjapi.DzGetGameUI())
    hjapi.DzFrameSetFont(zdxqText, "war3mapImported\\fonts.ttf", 0.010, 0)
    hjapi.DzFrameSetText(zdxqText, "自动需求")
    hjapi.DzFrameSetPoint(zdxqText, 7, zdzdText, 1, 0, 0.005)
    hjapi.DzFrameShow(zdxqText, true)
    local zdxq =
        hjapi.DzCreateFrameByTagName("GLUECHECKBOX", "zdzd", zdxqText, "QuestCheckBox2", 0)
    hjapi.DzFrameSetPoint(zdxq, 3, zdxqText, 5, 0, 0)
    hjapi.DzFrameSetSize(zdxq, 0.012, 0.016)
    hjapi.DzFrameShow(zdxq, true)

    hjapi.DzFrameSetScriptByCode(
        zdxq,
        FRAME_EVENT_CHECKBOX_CHECK,
        function()
            hsync.send("kaiqizdxq", {})
        end,
        false
    )
    hsync.onSend(
        "kaiqizdxq",
        function(syncData)
            hcache.set(syncData.triggerPlayer, "zdxq", true)
        end
    )
    hjapi.DzFrameSetScriptByCode(
        zdxq,
        FRAME_EVENT_CHECKBOX_UNCHECK,
        function()
            hsync.send("guanbizdxq", {})
        end,
        false
    )
    hsync.onSend(
        "guanbizdxq",
        function(syncData)
            hcache.set(syncData.triggerPlayer, "zdxq", false)
        end
    )
    hjapi.DzFrameSetScriptByCode(
        zdxq,
        MOUSE_ORDER_ENTER,
        function()
            local tip = hcolor.yellow("自动需求") .. "|n打开后，物品Roll点时间结束会自动需求蓝色及以上品质的物品。"
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.1200, 0)
            hjapi.DzFrameSetPoint(tipsText, FRAMEPOINT_LEFT, zdxq, FRAMEPOINT_RIGHT, 0.02, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        zdxq,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )

    local sjssText = hjapi.FrameTag("TEXT", "sjssText", hjapi.DzGetGameUI())
    hjapi.DzFrameSetFont(sjssText, "war3mapImported\\fonts.ttf", 0.010, 0)
    hjapi.DzFrameSetText(sjssText, "收集史诗")
    hjapi.DzFrameSetPoint(sjssText, 7, zdxqText, 1, 0, 0.005)
    hjapi.DzFrameShow(sjssText, true)
    local sjss =
        hjapi.DzCreateFrameByTagName("GLUECHECKBOX", "zdzd", sjssText, "QuestCheckBox2", 0)
    hjapi.DzFrameSetPoint(sjss, 3, sjssText, 5, 0, 0)
    hjapi.DzFrameSetSize(sjss, 0.012, 0.016)
    hjapi.DzFrameShow(sjss, true)

    hjapi.DzFrameSetScriptByCode(
        sjss,
        FRAME_EVENT_CHECKBOX_CHECK,
        function()
            hsync.send("kaiqisjss", {})
        end,
        false
    )
    hsync.onSend(
        "kaiqisjss",
        function(syncData)
            hcache.set(syncData.triggerPlayer, "sjss", true)
        end
    )
    hjapi.DzFrameSetScriptByCode(
        sjss,
        FRAME_EVENT_CHECKBOX_UNCHECK,
        function()
            hsync.send("guanbisjss", {})
        end,
        false
    )
    hsync.onSend(
        "guanbisjss",
        function(syncData)
            hcache.set(syncData.triggerPlayer, "sjss", false)
        end
    )
    hjapi.DzFrameSetScriptByCode(
        sjss,
        MOUSE_ORDER_ENTER,
        function()
            local tip = hcolor.yellow("收集史诗") .. "|n打开后，用装备收集系统（F3）收集散件装备时会收集史诗难度的装备。"
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.1200, 0)
            hjapi.DzFrameSetPoint(tipsText, FRAMEPOINT_LEFT, zdxq, FRAMEPOINT_RIGHT, 0.02, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        sjss,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )
end

local function init_xuetiao_for_hero()
    htime.setInterval(
        0.03,
        function(curTimer)
            for _, player in ipairs(hplayer.players) do
                if hplayer.isUser(player) and hplayer.isPlaying(player) then
                    local mainHero = hplayer.getMainHero(player)
                    if mainHero ~= nil then
                        if hunit.isAlive(mainHero) then
                            local xuetiao = hcache.get(mainHero, "xuetiaoeffect")
                            if xuetiao == nil then
                                hjapi.DzSetUnitPreselectUIVisible(mainHero, false)
                                hjapi.DzSetUnitProperName(mainHero, hplayer.getName(player))
                                xuetiao =
                                    heffect.attach("war3mapImported\\Progressbar_HP.mdx", mainHero, "overhead", -1)
                                hcache.set(mainHero, "xuetiaoeffect", xuetiao)
                            end
                            local currentLifePercent = math.ceil(hunit.getCurLifePercent(mainHero)) or 100
                            hjapi.DzSetEffectAnimation(xuetiao, math.max(0, currentLifePercent - 1), 0)
                        else
                            local xuetiao = hcache.get(mainHero, "xuetiaoeffect")
                            if xuetiao ~= nil then
                                hjapi.DzUnbindEffect(xuetiao)
                                heffect.destroy(xuetiao)
                                hcache.free(mainHero, "xuetiaoeffect")
                            end
                        end
                    end
                end
            end
        end
    )
end

local function init_important_buff_UI()
    local importantSelfBuffICON = {}
    local importantSelfBuffTIME = {}
    local importantSelfBuffStack = {}

    local bagRx = 0.024
    local bagRy = 0.032

    for i = 1, 5 do
        local x = -(i - 1) * (bagRx + 0.005) - 0.03
        local y = -0.043
        --buff图标
        importantSelfBuffICON[i] = hjapi.FrameTag("BACKDROP", "slef_buff" .. i, hjapi.DzGetGameUI())
        hjapi.DzFrameSetPoint(importantSelfBuffICON[i], 4, hjapi.DzGetGameUI(), 4, x, y)
        hjapi.DzFrameSetSize(importantSelfBuffICON[i], bagRx, bagRy)
        hjapi.DzFrameShow(importantSelfBuffICON[i], false)

        --时间文本
        importantSelfBuffTIME[i] = hjapi.FrameTag("TEXT", "T666", importantSelfBuffICON[i])
        hjapi.DzFrameSetFont(importantSelfBuffTIME[i], "war3mapImported\\fonts.ttf", 0.012, 0)
        hjapi.DzFrameSetText(importantSelfBuffTIME[i], "")
        hjapi.DzFrameSetPoint(importantSelfBuffTIME[i], 1, importantSelfBuffICON[i], 7, 0, 0)
        hjapi.DzFrameShow(importantSelfBuffTIME[i], true)

        --叠加层数文本
        importantSelfBuffStack[i] = hjapi.FrameTag("TEXT", "stack", importantSelfBuffICON[i])
        hjapi.DzFrameSetFont(importantSelfBuffStack[i], "war3mapImported\\fonts.ttf", 0.012, 0)
        hjapi.DzFrameSetText(importantSelfBuffStack[i], "")
        hjapi.DzFrameSetPoint(importantSelfBuffStack[i], 7, importantSelfBuffICON[i], 1, 0, 0)
        hjapi.DzFrameShow(importantSelfBuffStack[i], true)
    end

    local importantTargetBuffICON = {}
    local importantTargetBuffTIME = {}
    local importantTargetBuffStack = {}

    for i = 1, 5 do
        local x = (i - 1) * (bagRx + 0.005) + 0.03
        local y = -0.043
        --buff图标
        importantTargetBuffICON[i] = hjapi.FrameTag("BACKDROP", "slef_buff" .. i, hjapi.DzGetGameUI())
        hjapi.DzFrameSetPoint(importantTargetBuffICON[i], 4, hjapi.DzGetGameUI(), 4, x, y)
        hjapi.DzFrameSetSize(importantTargetBuffICON[i], bagRx, bagRy)
        hjapi.DzFrameShow(importantTargetBuffICON[i], false)

        --时间文本
        importantTargetBuffTIME[i] = hjapi.FrameTag("TEXT", "T666", importantTargetBuffICON[i])
        hjapi.DzFrameSetFont(importantTargetBuffTIME[i], "war3mapImported\\fonts.ttf", 0.012, 0)
        hjapi.DzFrameSetText(importantTargetBuffTIME[i], "")
        hjapi.DzFrameSetPoint(importantTargetBuffTIME[i], 1, importantTargetBuffICON[i], 7, 0, 0)
        hjapi.DzFrameShow(importantTargetBuffTIME[i], true)

        --叠加层数文本
        importantTargetBuffStack[i] = hjapi.FrameTag("TEXT", "stack", importantTargetBuffICON[i])
        hjapi.DzFrameSetFont(importantTargetBuffStack[i], "war3mapImported\\fonts.ttf", 0.012, 0)
        hjapi.DzFrameSetText(importantTargetBuffStack[i], "")
        hjapi.DzFrameSetPoint(importantTargetBuffStack[i], 7, importantTargetBuffICON[i], 1, 0, 0)
        hjapi.DzFrameShow(importantTargetBuffStack[i], true)
    end

    htime.setInterval(
        0.1,
        function(_)
            for _, player in ipairs(hplayer.players) do
                if hplayer.isPlaying(player) and hplayer.isUser(player) then
                    local show = {}
                    local enableMonitorView = hcache.get(player, "buffMonitor")
                    local selection = hplayer.getSelection(player)
                    local mainHero = hplayer.getMainHero(player)
                    if
                        (selection ~= nil and selection == mainHero and hunit.isAlive(selection)) and
                        hfightzhuangtai.isInFight(mainHero)
                    then
                        local monitorSelf = hskill.getMonitorBuff(selection, true)
                        if player == hplayer.loc() then
                            for monitorBuffIndex, v in ipairs(monitorSelf) do
                                if (monitorBuffIndex <= 5) then
                                    local buffHandle = hbuff.getBuffHandle(selection, v)
                                    if (buffHandle ~= nil) and enableMonitorView then
                                        local art = buffHandle.art
                                        local stack = buffHandle.stack
                                        local remain = nil
                                        if buffHandle.timer ~= nil then
                                            remain = math.round(buffHandle.timer.remain(), 1)
                                            if buffHandle.interval ~= nil and buffHandle.remainingTime ~= nil then
                                                remain = remain + buffHandle.remainingTime - buffHandle.interval
                                                if remain >= 36000 then
                                                    remain = "常驻"
                                                end
                                            end
                                        else
                                            remain = "常驻"
                                        end
                                        if type(remain) == "number" then
                                            hjapi.DzFrameSetText(
                                                importantSelfBuffTIME[monitorBuffIndex],
                                                formatDuration(remain)
                                            )
                                        else
                                            hjapi.DzFrameSetText(importantSelfBuffTIME[monitorBuffIndex], remain)
                                        end
                                        hjapi.DzFrameSetTexture(importantSelfBuffICON[monitorBuffIndex], art, false)
                                        if stack > 1 then
                                            hjapi.DzFrameSetText(importantSelfBuffStack[monitorBuffIndex], stack)
                                        else
                                            hjapi.DzFrameSetText(importantSelfBuffStack[monitorBuffIndex], "")
                                        end
                                        if (type(remain) == "number" and remain <= 3) then
                                            local transparency = 50 + 255 * remain / 3
                                            hjapi.DzFrameSetAlpha(importantSelfBuffICON[monitorBuffIndex], transparency)
                                        else
                                            hjapi.DzFrameSetAlpha(importantSelfBuffICON[monitorBuffIndex], 255)
                                        end
                                        show[monitorBuffIndex] = true
                                    end
                                end
                            end
                        end
                    end
                    if player == hplayer.loc() then
                        for i = 1, 5 do
                            if show[i] == nil then
                                hjapi.DzFrameShow(importantSelfBuffICON[i], false)
                            else
                                hjapi.DzFrameShow(importantSelfBuffICON[i], true)
                            end
                        end
                    end

                    local unit = GLOBAL_LAST_DAMAGED_BOSS[player]
                    local newShow = {}
                    if unit ~= nil and hunit.isAlive(unit) and hfightzhuangtai.isInFight(mainHero) then
                        local monitorTarget = hskill.getMonitorBuff(mainHero, false)

                        if player == hplayer.loc() then
                            for monitorBuffIndex, v in ipairs(monitorTarget) do
                                if (monitorBuffIndex <= 5) then
                                    local buffHandle = hbuff.getBuffHandle(unit, v)
                                    if (buffHandle ~= nil) and enableMonitorView then
                                        local art = buffHandle.art
                                        local stack = buffHandle.stack
                                        local remain = nil
                                        if buffHandle.timer ~= nil then
                                            remain = math.round(buffHandle.timer.remain(), 1)
                                            if buffHandle.interval ~= nil and buffHandle.remainingTime ~= nil then
                                                remain = remain + buffHandle.remainingTime - buffHandle.interval
                                                if remain >= 36000 then
                                                    remain = "常驻"
                                                end
                                            end
                                        else
                                            remain = "常驻"
                                        end
                                        if type(remain) == "number" then
                                            hjapi.DzFrameSetText(
                                                importantTargetBuffTIME[monitorBuffIndex],
                                                formatDuration(remain)
                                            )
                                        else
                                            hjapi.DzFrameSetText(importantTargetBuffTIME[monitorBuffIndex], remain)
                                        end
                                        hjapi.DzFrameSetTexture(importantTargetBuffICON[monitorBuffIndex], art, false)
                                        if stack > 1 then
                                            hjapi.DzFrameSetText(importantTargetBuffStack[monitorBuffIndex], stack)
                                        else
                                            hjapi.DzFrameSetText(importantTargetBuffStack[monitorBuffIndex], "")
                                        end
                                        if (type(remain) == "number" and remain <= 3) then
                                            local transparency = 50 + 255 * remain / 3
                                            hjapi.DzFrameSetAlpha(
                                                importantTargetBuffICON[monitorBuffIndex],
                                                transparency
                                            )
                                        else
                                            hjapi.DzFrameSetAlpha(importantTargetBuffICON[monitorBuffIndex], 255)
                                        end

                                        newShow[monitorBuffIndex] = true
                                    end
                                end
                            end
                        end
                    end
                    if player == hplayer.loc() then
                        for i = 1, 5 do
                            if newShow[i] == nil then
                                hjapi.DzFrameShow(importantTargetBuffICON[i], false)
                            else
                                hjapi.DzFrameShow(importantTargetBuffICON[i], true)
                            end
                        end
                    end
                end
            end
        end
    )
end

UI = function()
    init_gear_score_UI()
    -- init KK logo
    init_general_icon()
    -- 设置伤害统计UI
    init_shanghaitongji_UI()
    -- 初始化任务提示UI
    init_quest_UI()
    -- 9格装备界面
    init_equipment_UI()
    -- 大背包
    init_dabeibao_UI()
    -- 设置背包提示UI
    init_bag_trigger_and_tooltip()
    -- 设置地面物品提示UI
    init_dimian_wupin_trigger()
    -- 成就UI
    init_achievement_UI()
    -- 专业UI
    init_zhuanye_UI()
    -- 初始化能量点系统
    init_energy_point()
    -- buff UI
    init_buff_UI()
    -- 敌人血条
    init_direnxuetiao_UI()
    -- 初始化商店界面
    init_shop_UI()
    -- 装备掉落UI
    init_dice_UI()
    -- 初始化属性提示UI
    init_attribute_UI()
    -- 初始化装备提示UI 包括背包，地面，装备栏
    init_zhuangbeitishi_UI()
    -- 施法条 UI
    init_shifatiao_UI()
    -- 初始化重要buff提示UI
    init_important_buff_UI()
    init_check_box()
    -- TODO 暂时回滚
    -- init_xuetiao_for_hero()
end
