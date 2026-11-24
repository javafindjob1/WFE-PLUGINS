-- 铭文主页面显示已解锁的铭文
-- 单击可以带上或者取下铭文
-- 铭文可以携带数量有上限 上限可以调整
-- 没激活情况下单击为制作铭文
-- 制作铭文有成功率 不管成功与否都加经验

hmingwen = { descriptions = {}, perUserMingwenlimitMain = {}, perUserMingwenlimitMinor = {} }

CONST_MINGWEN_TYPE = {
    MAJOR = "大型",
    MINOR = "小型"
}

CONST_MINGWEN_DATA = {}
CONST_MINGWEN_DATA[CONST_MINGWEN_TYPE.MAJOR] = { limit = 1 }
CONST_MINGWEN_DATA[CONST_MINGWEN_TYPE.MINOR] = { limit = 1 }

---
---{
---  {
---     name = "强化火球"
---     art = "art"
---     description = "description"
---     isActive = false,
---     cundangStr = "mingwen",
---     isPerHero = false,
---     mingwenType = CONST_MINGWEN_TYPE.MAJOR
---     cunDangStartIndex = 1,
---     cunDangEndIndex = 2,
---     isEquipped = false,
---     req = {
---         {name = "铁矿",count = 2},
---         {name = "野蛮锁甲", count = 1}
---     },
---  }
---}
--
---
hmingwen.init = function(config, mingwenConfig)
    hzhuanye.initSingleZhuanye(config, "制作", "铭文", CONST_EVENT.mingwen)
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hmingwen[enumPlayer] = table.clone(mingwenConfig)
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end
            ACHIEVEMENT_DATA[enumPlayer]["铭文"] = {}
            ACHIEVEMENT_DATA[enumPlayer]["铭文"].categoryUIName = "BtnRootWindow_Category_Category6"
            local categoryData = {}
            ACHIEVEMENT_DATA[enumPlayer]["铭文"].categoryData = categoryData
        end
    )
    --- 初始化铭文UI及触发
    --- 铭文使用以及铭文效果等
end

hmingwen.initPlayer = function(whichPlayer)
    local config = hmingwen[whichPlayer]
    local hero = hplayer.getMainHero(whichPlayer)


    hmingwen.perUserMingwenlimitMain[whichPlayer] = CONST_MINGWEN_DATA[CONST_MINGWEN_TYPE.MAJOR].limit
    hmingwen.perUserMingwenlimitMinor[whichPlayer] = CONST_MINGWEN_DATA[CONST_MINGWEN_TYPE.MINOR].limit
    if hunit.getLevel(hero) >= 70 then
        hmingwen.perUserMingwenlimitMinor[whichPlayer] = hmingwen.perUserMingwenlimitMinor[whichPlayer] + 1
    end
    if hditudengji.getDitudengji(whichPlayer) >= 70 then
        hmingwen.perUserMingwenlimitMain[whichPlayer] = hmingwen.perUserMingwenlimitMain[whichPlayer] + 1
    end

    local zhiye_cundang_str = hslk.n2v(hunit.getName(hero), "zhiye_cundang_str")
    local categoryData = {}
    for i, v in ipairs(config) do
        if v.zhiye_cundang_str == zhiye_cundang_str then
            local tmpItem = {}
            tmpItem.name = v.name
            tmpItem.art = v.art
            tmpItem.callback = function()
                hsync.send("clickmingwen", { v.name, hplayer.index(whichPlayer) })
            end
            tmpItem.tip = hmingwen.getDescription(v)
            tmpItem.enable = false
            table.insert(categoryData, tmpItem)
        end
    end
    ACHIEVEMENT_DATA[whichPlayer]["铭文"].categoryData = categoryData

    hsync.onSend(
        "clickmingwen",
        function(syncData)
            local name = syncData.triggerData[1]
            local whichPlayer = syncData.triggerPlayer
            if hmingwen.isMingwenEnabled(name, whichPlayer) then
                if hmingwen.isEquipped(name, whichPlayer) then
                    hmingwen.unEquipMingwen(name, whichPlayer)
                else
                    hmingwen.equipMingwen(name, whichPlayer, true)
                end
            else
                hmingwen.tryJihuo(name, whichPlayer)
            end
        end
    )
    hmingwen.loadcundang(whichPlayer)
end

function hmingwen.getDescription(mingwen)
    local msg = {}
    local prefix = ""
    if mingwen.isEquipped then
        prefix = hcolor.green("[已装备]")
    else
        prefix = hcolor.grey("[未装备]")
    end
    table.insert(msg, prefix .. hcolor.green("[" .. mingwen.mingwenType .. "]") .. mingwen.name)
    table.insert(msg, mingwen.description)
    table.insert(msg, "")
    if mingwen.isActive ~= true then
        table.insert(msg, "激活需要材料（放大背包（非六格背包）后点击本图标激活）：")
        for i, singleReq in ipairs(mingwen.req) do
            local pinzhi = hitem.getItemMinPinzhi(hslk.n2i(singleReq.name))
            pinzhi = pinzhi or ZHUANGBEI_PINZHI.PUTONG
            local color = ZHUANGBEI_PINZHI_DATA[pinzhi].color
            table.insert(msg, " - " .. color(singleReq.name) .. " X " .. singleReq.count)
        end
    end
    return string.implode("|n", msg)
end

function hmingwen.cundang(cundang, whichPlayer)
    local cdStr = ""
    if cundang.isActive then
        cdStr = cdStr .. "1"
    else
        cdStr = cdStr .. "0"
    end
    if cundang.isEquipped then
        cdStr = cdStr .. "1"
    else
        cdStr = cdStr .. "0"
    end
    hplayer.dzCunDang[whichPlayer].saveCundang(
        cundang.cundangStr,
        cundang.isPerHero,
        cundang.cunDangStartIndex,
        cundang.cunDangEndIndex,
        cdStr
    )
end

function hmingwen.updateUI(mingwenName, whichPlayer)
    local indexForHero = 0
    local hero = hplayer.getMainHero(whichPlayer)
    local zhiye_cundang_str = hslk.n2v(hunit.getName(hero), "zhiye_cundang_str")
    for i, mingwen in ipairs(hmingwen[whichPlayer]) do
        if mingwen.zhiye_cundang_str == zhiye_cundang_str then
            indexForHero = indexForHero + 1
        end
        if mingwen.name == mingwenName then
            ui_enable_achievement_data_at_category_and_idx(whichPlayer, "铭文", indexForHero)
            ui_update_text_achievement_data_at_category_and_idx(
                whichPlayer,
                "铭文",
                indexForHero,
                hmingwen.getDescription(mingwen)
            )
            ui_update_equip_achievement_data_at_category_and_idx(whichPlayer, "铭文", indexForHero, mingwen.isEquipped)
        end
    end
    hmingwen.updateDescription(whichPlayer)
end

function hmingwen.jihuomingwen(mingwenName, whichPlayer, cundang)
    for i, mingwen in ipairs(hmingwen[whichPlayer]) do
        if mingwen.name == mingwenName then
            mingwen.isActive = true
            hmingwen.updateUI(mingwenName, whichPlayer)
            if cundang == true then
                hmingwen.cundang(mingwen, whichPlayer)
                echo("恭喜激活铭文：" .. hcolor.green(mingwen.name), whichPlayer)
            end
        end
    end
end

function hmingwen.loadcundang(whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    local zhiye_cundang_str = hslk.n2v(hunit.getName(hero), "zhiye_cundang_str")
    for i, mignwen in ipairs(hmingwen[whichPlayer]) do
        if mignwen.zhiye_cundang_str == zhiye_cundang_str then
            local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(mignwen.cundangStr, mignwen.isPerHero)
            local specificCundang = string.sub(cundang, mignwen.cunDangStartIndex, mignwen.cunDangEndIndex)
            local isActive = string.sub(specificCundang, 1, 1) == "1"
            local isEquipped = string.sub(specificCundang, 2, 2) == "1"
            if isActive then
                hmingwen.jihuomingwen(mignwen.name, whichPlayer, false)
            end
            if isEquipped then
                hmingwen.equipMingwen(mignwen.name, whichPlayer, false)
            end
        end
    end
    hmingwen.updateDescription(whichPlayer)
end

function hmingwen.tryJihuo(mingwenName, whichPlayer)
    if hplayer.getMainHero(whichPlayer) == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    local zhiye_cundang_str = hslk.n2v(hunit.getName(hero), "zhiye_cundang_str")
    for i, mingwen in ipairs(hmingwen[whichPlayer]) do
        if mingwen.name == mingwenName and mingwen.zhiye_cundang_str == zhiye_cundang_str then
            if hitem.hasRequiredItems(mingwen.req, hero, true) then
                hitem.removeItemFromBag(mingwen.req, hero)
                hmingwen.jihuomingwen(mingwenName, whichPlayer, true)
            else
                echo(hcolor.yellow("系统：") .. "激活铭文失败，缺少必须物品", whichPlayer)
            end
        end
    end
end

function hmingwen.isMingwenEnabled(mingwenName, whichPlayer)
    if hplayer.getMainHero(whichPlayer) == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    local zhiye_cundang_str = hslk.n2v(hunit.getName(hero), "zhiye_cundang_str")
    for i, mingwen in ipairs(hmingwen[whichPlayer]) do
        if mingwen.name == mingwenName and mingwen.zhiye_cundang_str == zhiye_cundang_str then
            if mingwen.isActive then
                return true
            else
                return false
            end
        end
    end
    return false
end

function hmingwen.updateDescription(whichPlayer)
    if hplayer.getMainHero(whichPlayer) == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    local zhiye_cundang_str = hslk.n2v(hunit.getName(hero), "zhiye_cundang_str")
    local msg = {}
    local majorCount = 0
    local minorCount = 0
    table.insert(msg, hcolor.green("铭文装备情况："))
    table.insert(msg, "")
    for i, mingwen in ipairs(hmingwen[whichPlayer]) do
        if mingwen.zhiye_cundang_str == zhiye_cundang_str and mingwen.isEquipped and mingwen.isActive then
            table.insert(msg, hmingwen.getDescription(mingwen))
            table.insert(msg, "")
            if mingwen.mingwenType == CONST_MINGWEN_TYPE.MAJOR then
                majorCount = majorCount + 1
            elseif mingwen.mingwenType == CONST_MINGWEN_TYPE.MINOR then
                minorCount = minorCount + 1
            end
        end
    end
    table.insert(
        msg,
        "已激活" ..
        hcolor.green(CONST_MINGWEN_TYPE.MAJOR) ..
        "铭文：" .. majorCount .. "/" .. hmingwen.perUserMingwenlimitMain[whichPlayer] .. "个"
    )
    table.insert(
        msg,
        "已激活" ..
        hcolor.green(CONST_MINGWEN_TYPE.MINOR) ..
        "铭文：" .. minorCount .. "/" .. hmingwen.perUserMingwenlimitMinor[whichPlayer] .. "个"
    )
    table.insert(
        msg,
        ""
    )
    table.insert(
        msg,
        hcolor.yellow("注：")
    )
    table.insert(
        msg,
        hcolor.yellow(" - 每个冒险者基础可以装备一个大型铭文和一个小型铭文")
    )
    table.insert(
        msg,
        hcolor.yellow(" - 冒险者等级到达70级可以获得一个额外的小型铭文位（需要开局读取70级冒险者存档才会生效）")
    )
    hmingwen.descriptions[whichPlayer] = string.implode("|n", msg)
end

function hmingwen.equipMingwen(mingwenName, whichPlayer, cundang)
    if hplayer.getMainHero(whichPlayer) == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hfightzhuangtai.isInFight(hero) then
        echo("战斗中不能更换铭文", whichPlayer)
        return
    end
    local zhiye_cundang_str = hslk.n2v(hunit.getName(hero), "zhiye_cundang_str")
    for i, mingwen in ipairs(hmingwen[whichPlayer]) do
        if mingwen.name == mingwenName and mingwen.zhiye_cundang_str == zhiye_cundang_str then
            if mingwen.isActive then
                local mingwenType = mingwen.mingwenType
                local mingwenCount = 0
                for _, mingwen in ipairs(hmingwen[whichPlayer]) do
                    if
                        mingwen.zhiye_cundang_str == zhiye_cundang_str and mingwen.isEquipped and
                        mingwen.mingwenType == mingwenType
                    then
                        mingwenCount = mingwenCount + 1
                    end
                end
                local limit = 0
                if mingwenType == CONST_MINGWEN_TYPE.MAJOR then
                    limit = hmingwen.perUserMingwenlimitMain[whichPlayer]
                elseif mingwenType == CONST_MINGWEN_TYPE.MINOR then
                    limit = hmingwen.perUserMingwenlimitMinor[whichPlayer]
                end
                if mingwenCount < limit then
                    mingwen.isEquipped = true
                    hmingwen.updateUI(mingwen.name, whichPlayer)
                    if cundang then
                        hmingwen.cundang(mingwen, whichPlayer)
                        echo("装备铭文：" .. hcolor.green(mingwen.name) .. "成功！", whichPlayer)
                    end
                else
                    echo(
                        "装备铭文：" ..
                        hcolor.green(mingwen.name) .. "失败，当前可装备" .. mingwenType .. "铭文数量已满（上限" .. limit .. "个）",
                        whichPlayer
                    )
                end
                return
            end
        end
    end
end

function hmingwen.unEquipMingwen(mingwenName, whichPlayer)
    if hplayer.getMainHero(whichPlayer) == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if hfightzhuangtai.isInFight(hero) then
        echo("战斗中不能更换铭文", whichPlayer)
        return
    end
    local zhiye_cundang_str = hslk.n2v(hunit.getName(hero), "zhiye_cundang_str")
    for i, mingwen in ipairs(hmingwen[whichPlayer]) do
        if mingwen.name == mingwenName and mingwen.zhiye_cundang_str == zhiye_cundang_str then
            if mingwen.isActive and mingwen.isEquipped then
                mingwen.isEquipped = false
                hmingwen.updateUI(mingwen.name, whichPlayer)
                hmingwen.cundang(mingwen, whichPlayer)
                echo("卸下铭文：" .. hcolor.green(mingwen.name) .. "。", whichPlayer)
                return
            end
        end
    end
end

function hmingwen.isEquipped(mingwenName, whichPlayer)
    if hplayer.getMainHero(whichPlayer) == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    local zhiye_cundang_str = hslk.n2v(hunit.getName(hero), "zhiye_cundang_str")
    for i, mingwen in ipairs(hmingwen[whichPlayer]) do
        if mingwen.name == mingwenName and mingwen.zhiye_cundang_str == zhiye_cundang_str then
            if mingwen.isActive and mingwen.isEquipped then
                return true
            end
        end
    end
    return false
end
