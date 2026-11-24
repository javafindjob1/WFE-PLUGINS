hchengjiu = {}

---
--- chengjiu config
---
---{
---  {
---    name: "新手上路",
--     cundangStr = "chengjiu",
--     isPerHero = false,
--     cunDangStartIndex = 1,
--     cunDangEndIndex = 1,
--     art = "art",
--     enabled = false,
--     description = "说明书",
--     attribute = {},
---  }
---}

function hchengjiu.init(config)
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hchengjiu[enumPlayer] = table.clone(config)
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end
            ACHIEVEMENT_DATA[enumPlayer]["成就"] = {}
            ACHIEVEMENT_DATA[enumPlayer]["成就"].categoryUIName = "BtnRootWindow_Category_Category5"
            local categoryData = {}
            for i, v in ipairs(config) do
                local tmpItem = {}
                tmpItem.name = v.name
                tmpItem.art = v.art
                tmpItem.callback = function()
                    echo("点击了成就系统的" .. v.name .. "按钮", enumPlayer)
                end
                tmpItem.tip = hchengjiu.getDescription(v)
                tmpItem.enable = false
                table.insert(categoryData, tmpItem)
            end
            ACHIEVEMENT_DATA[enumPlayer]["成就"].categoryData = categoryData
        end
    )
end

function hchengjiu.getDescription(chengjiu)
    local msg = {}
    table.insert(msg, chengjiu.name)
    table.insert(msg, "")
    table.insert(msg, chengjiu.description)
    table.insert(msg, "")
    table.insert(msg, "效果：")
    table.insert(msg, hcolor.green(description.attribute(chengjiu.attribute)))
    return string.implode("|n", msg)
end

function hchengjiu.cundang(chengjiu, whichPlayer)
    hplayer.dzCunDang[whichPlayer].saveCundang(
        chengjiu.cundangStr,
        chengjiu.isPerHero,
        chengjiu.cunDangStartIndex,
        chengjiu.cunDangEndIndex,
        "1"
    )
end

function hchengjiu.JiHuoChengJiu(chengjiuName, whichPlayer, cundang)
    for i, chengjiu in ipairs(hchengjiu[whichPlayer]) do
        if chengjiu.name == chengjiuName then
            chengjiu.enabled = true
            hattribute.set(hplayer.getMainHero(whichPlayer), 0, chengjiu.attribute)
            ui_enable_achievement_data_at_category_and_idx(whichPlayer, "成就", i)
            if cundang == true then
                hchengjiu.cundang(chengjiu, whichPlayer)
                hquestcustom.enqueue_dialog(whichPlayer, "系统", "恭喜激活成就:" .. chengjiuName)
                heffect.attach("war3mapImported\\[qishi][Spell]_152.mdx", hplayer.getMainHero(whichPlayer), "origin", 0)
                if whichPlayer == hplayer.loc() then
                    local model = hjapi.FrameTag("SPRITE", "test_model", hjapi.DzGetGameUI())
                    hjapi.DzFrameSetModel(model, "war3mapImported\\[UI]1.mdx", 0, 0)
                    hjapi.DzFrameSetPoint(model, 4, hjapi.DzGetGameUI(), 4, 0, -0.12)
                    hjapi.DzFrameSetSize(model, 0.00001, 0.00001)
                end
                hsound.voice2Unit(
                    hsound.voiceCreate("resource\\war3mapImported\\sound\\achievement.mp3", 1000, false),
                    150,
                    hplayer.getMainHero(whichPlayer)
                )
            end
        end
    end
end

function hchengjiu.loadcundang(whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    for i, chengjiu in ipairs(hchengjiu[whichPlayer]) do
        local cundang = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(chengjiu.cundangStr, chengjiu.isPerHero)
        if string.sub(cundang, chengjiu.cunDangStartIndex, chengjiu.cunDangEndIndex) == "1" then
            hchengjiu.JiHuoChengJiu(chengjiu.name, whichPlayer, false)
        else
            if chengjiu.trigger ~= nil then
                hevent.register(
                    hero,
                    chengjiu.trigger.attr_type,
                    "chengjiutrigger" .. i,
                    function(evtData)
                        if chengjiu.trigger.passCriteria(evtData) == true then
                            hchengjiu.tryJihuoChengjiu(chengjiu.name, whichPlayer, true)
                            hevent.unregister(hero, chengjiu.trigger.attr_type, "chengjiutrigger" .. i, true)
                        end
                    end
                )
            end
        end
    end
    htime.setInterval(
        2,
        function(curTimer)
            if hplayer.isPlaying(whichPlayer) == false then
                curTimer.destroy()
                return
            end
            hevent.trigger(
                hplayer.getMainHero(whichPlayer),
                CONST_EVENT.periodCheck,
                { triggerPlayer = whichPlayer, triggerUnit = hplayer.getMainHero(whichPlayer) }
            )
        end
    )
end

function hchengjiu.tryJihuoChengjiu(chengjiuName, whichPlayer)
    if hplayer.getMainHero(whichPlayer) == nil then
        return
    end
    if hchengjiu.isChengjiuEnabled(chengjiuName, whichPlayer) == true then
        return
    end
    hchengjiu.JiHuoChengJiu(chengjiuName, whichPlayer, true)
end

function hchengjiu.isChengjiuEnabled(chengjiuName, whichPlayer)
    if hplayer.getMainHero(whichPlayer) == nil then
        return false
    end
    for i, chengjiu in ipairs(hchengjiu[whichPlayer]) do
        if chengjiu.name == chengjiuName then
            return chengjiu.enabled
        end
    end
end

hchengjiu.jihuosuoyouchengjiu = function(whichPlayer)
    for i, chengjiu in ipairs(hchengjiu[whichPlayer]) do
        hchengjiu.JiHuoChengJiu(chengjiu.name, whichPlayer, false)
    end
end
