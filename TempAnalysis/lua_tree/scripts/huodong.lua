local function get_beijing_time()
    -- 如果游戏时间和系统时间相差超过1小时，则认为系统时间不准确，使用游戏时间
    local utc_time = hjapi.DzAPI_Map_GetGameStartTime() + math.floor(htime.inc / 100)
    return os.date("!*t", utc_time + 8 * 3600) -- 北京时间为 UTC+8
end

local function is_active_time(config, current_time)
    return config.day[current_time.wday] == 1 and
        current_time.hour >= config.startHour and
        current_time.hour < config.endHour
end

local function get_description_for_buff(huodongConfig)
    local localdescription = hcolor.yellow("地图活动介绍：\n\n")
    local week_day_to_name = { "周日", "周一", "周二", "周三", "周四", "周五", "周六" }

    for _, config in ipairs(huodongConfig) do
        localdescription = localdescription .. string.format(hcolor.green("【%s】\n"), config.name)
        localdescription = localdescription ..
            string.format(hcolor.yellow("效果：") .. "%s\n", hcolor.green(description.attribute(config.attr, "，", nil)))
        local active_days = {}
        for day, active in ipairs(config.day) do
            if active == 1 then
                table.insert(active_days, week_day_to_name[day])
            end
        end
        localdescription = localdescription ..
            string.format(hcolor.yellow("生效日期：") .. "%s\n", table.concat(active_days, "、"))
        localdescription = localdescription ..
            string.format(hcolor.yellow("生效时间：") .. "%d:00至%d:00\n\n", config.startHour, config.endHour)
    end

    return localdescription
end



local function update_player_buffs(player, current_time, huodongConfig)
    local buffDesc = get_description_for_buff(huodongConfig)
    local hero = hplayer.getMainHero(player)
    for _, config in ipairs(huodongConfig) do
        if is_active_time(config, current_time) then
            hbuff.update(
                -1,
                hero,
                config.name,
                true,
                function()
                    hattr.caleAttribute(CONST_DAMAGE_SRC.skill, true, hero, config.attr, 1)
                end,
                function()
                    hattr.caleAttribute(CONST_DAMAGE_SRC.skill, false, hero, config.attr, 1)
                end,
                config.art,
                hcolor.green(config.name .. "|n" .. description.attribute(config.attr, "，", nil)),
                1,
                nil, nil, nil, nil,
                HBUFF_UPDATE_MODE.OVERWRITE,
                false
            )
        else
            hbuff.delete(hero, config.name)
        end
    end
end


function init_huodong()
    local huodongConfig = {
        {
            name = "经验暴增",
            art = "huodong\\ACHIEVEMENT_GUILDPERK_MRPOPULARITY_RANK2.blp",
            day = { 1, 0, 0, 0, 0, 0, 1 },
            startHour = 0,
            endHour = 24,
            attr = _attr({ exp_ratio = "+50" })
        },
        {
            name = "爆率提升",
            art = "huodong\\Achievement_FeatsOfStrength_Gladiator_08.blp",
            day = { 1, 1, 0, 0, 0, 0, 1 },
            startHour = 20,
            endHour = 23,
            attr = _attr({ extra_drop_rate = "+20" })
        },
        {
            name = "极品狂欢",
            art = "huodong\\ACHIEVEMENT_GUILDPERK_QUICK AND DEAD.blp",
            day = { 1, 0, 1, 0, 0, 0, 1 },
            startHour = 20,
            endHour = 23,
            attr = _attr({ lansecitiao_rate = "+10", zisecitiao_rate = "+5" })
        },
        {
            name = "神器祝福",
            art = "huodong\\Achievement_BG_trueAVshutout.blp",
            day = { 1, 0, 0, 1, 0, 0, 1 },
            startHour = 18,
            endHour = 24,
            attr = _attr({ sqnl_huoqu = "+50" })
        },
        {
            name = "战神的祝福",
            art = "huodong\\Achievement_FeatsOfStrength_Gladiator_08.blp",
            day = { 1, 0, 0, 0, 1, 0, 1 },
            startHour = 18,
            endHour = 24,
            attr = _attr({ quanju_zengshang = "+10", life_back = "+100" })
        },
        {
            name = "丰收之神的祝福",
            art = "huodong\\Achievement_Profession_Fishing_FindFish.blp",
            day = { 1, 0, 0, 0, 0, 1, 1 },
            startHour = 12,
            endHour = 24,
            attr = _attr({ caiji_speed = "+100", zaisheng_speed = "+100" })
        }
    }

    htime.setInterval(1, function()
        local current_time = get_beijing_time()
        hplayer.forEach(function(player)
            if hplayer.isUser(player) and hplayer.isPlaying(player) then
                update_player_buffs(player, current_time, huodongConfig)
            end
        end)
    end)

    GLOBAL_HUODONG_JIESHAO = get_description_for_buff(huodongConfig)
end
