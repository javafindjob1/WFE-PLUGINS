init_period_job_for_player = function(whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    local statsCache = {}
    statsCache[whichPlayer] = {}
    statsCache[whichPlayer]["gearScore"] = 0
    statsCache[whichPlayer]["dfdengji"] = 0
    statsCache[whichPlayer]["lastjuese"] = 0
    htime.setInterval(
        5,
        function(curTimer)
            if hplayer.isPlaying(whichPlayer) == false then
                curTimer.destroy()
                return
            end
            --- save gear score
            local gearScore = hcache.get(whichPlayer, "gearScore", 0)
            if gearScore ~= statsCache[whichPlayer]["gearScore"] then
                hjapi.DzAPI_Map_Stat_SetStat(whichPlayer, "gearscore", tostring(gearScore))
                statsCache[whichPlayer]["gearScore"] = gearScore
                hdzcundang.save_gear_score_level(whichPlayer, gearScore)
            end
            --- save dianfengjingyan
            local level = htianfu.getDianfengdengji(whichPlayer)
            if level ~= statsCache[whichPlayer]["dfdengji"] then
                hjapi.DzAPI_Map_Stat_SetStat(whichPlayer, "dfdengji", tostring(level))
                statsCache[whichPlayer]["dfdengji"] = level
            end

            --- juese dengji
            local hero = hplayer.getMainHero(whichPlayer)
            local level = hunit.getLevel(hero) or 0
            if level ~= statsCache[whichPlayer]["lastjuese"] then
                statsCache[whichPlayer]["lastjuese"] = level
                hjapi.DzAPI_Map_Stat_SetStat(whichPlayer, "lastjuese", level .. "级" .. hunit.getName(hero))
            end
        end
    )
    -- 检测攻击速度 和等级
    htime.setInterval(
        3,
        function(curTimer)
            if hplayer.isPlaying(whichPlayer) == false then
                curTimer.destroy()
                return
            end
            local hero = hplayer.getMainHero(whichPlayer)
            local attack_speed = hjapi.GetUnitState(hero, UNIT_STATE_ATTACK_SPEED)
            local correctAS = hattr.getWithLimit(hero, nil, "attack_speed")
            if attack_speed - (correctAS + 100) / 100 > 0.1 then
                echo("检测到玩家" .. hplayer.getName(whichPlayer) .. "攻击速度异常，已踢出游戏。")
                hdzcundang.addZuobiCount(whichPlayer)
                hplayer.defeat(whichPlayer, "检测到您攻击速度异常，已自动退出游戏。")
            end
            local level = hunit.getLevel(hero) or 0
            local experience = hresource.getResource(whichPlayer, HSHOP_COST_TYPE.experience)
            local ideallevel = hhero.getLevelGivenExp(experience, 70)
            if level - ideallevel > 2 then
                echo("检测到玩家" .. hplayer.getName(whichPlayer) .. "等级异常，已踢出游戏。")
                hdzcundang.addZuobiCount(whichPlayer)
                if DEBUGGING == false then
                    hplayer.defeat(whichPlayer, "检测到您等级异常，已自动退出游戏。")
                end
            end

            local attack_space_origin = hjapi.GetUnitState(hero, UNIT_STATE_ATTACK_SPACE)
            local correctASO = hattr.getWithLimit(hero, nil, "attack_space_origin")
            if math.abs(correctASO - attack_space_origin) > 0.05 then
                echo("检测到玩家" .. hplayer.getName(whichPlayer) .. "攻击间隔异常。")
                hdzcundang.addZuobiCount(whichPlayer)
                hplayer.defeat(whichPlayer, "检测到您攻击间隔异常，已自动退出游戏。")
            end

            local life = cj.GetUnitState(hero, UNIT_STATE_MAX_LIFE)
            local lualife = hattr.getWithLimit(hero, nil, "life")
            if math.abs(lualife - life) > 100 then
                echo("检测到玩家" .. hplayer.getName(whichPlayer) .. "生命值异常。")
                hdzcundang.addZuobiCount(whichPlayer)
                hplayer.defeat(whichPlayer, "检测到您生命值异常，已自动退出游戏。")
            end

            local attr = cj.GetUnitState(hero, UNIT_STATE_MAX_MANA)
            local luaAttr = hattr.getWithLimit(hero, nil, "mana")
            if math.abs(attr - luaAttr) > 10 then
                echo("检测到玩家" .. hplayer.getName(whichPlayer) .. "魔法值异常。")
                hdzcundang.addZuobiCount(whichPlayer)
                hplayer.defeat(whichPlayer, "检测到您魔法值异常，已自动退出游戏。")
            end

            -- 巅峰等级
            local dfLevel = htianfu.getDianfengdengji(whichPlayer)
            local dfLimit = tonumber(hjapi.DzAPI_Map_GetMapConfig("DFDJLIMIT")) or 9999
            if dfLevel >= dfLimit then
                echo("检测到玩家" .. hplayer.getName(whichPlayer) .. "巅峰等级异常。")
                hdzcundang.addZuobiCount(whichPlayer)
                if DEBUGGING == false then
                    hplayer.defeat(whichPlayer, "检测到您巅峰等级异常，已自动退出游戏。")
                end
            end
        end
    )
    --[[
    -- 检测攻击速度 和等级
    htime.setInterval(
        0.1,
        function(curTimer)
            if hplayer.isPlaying(whichPlayer) == false then
                curTimer.destroy()
                return
            end
            local hero = hplayer.getMainHero(whichPlayer)
            local x = hunit.x(hero)
            local y = hunit.y(hero)
            local lastX = hcache.get(hero, "lastX", x)
            local lastY = hcache.get(hero, "lastY", y)
            local lastPortal = hcache.get(hero, "lastportalts")
            if lastPortal ~= nil and htime.inc - lastPortal > 0.1 and math.distance(x, y, lastX, lastY) > 200 then
                echo("检测到玩家" .. hplayer.getName(whichPlayer) .. "移动速度异常，如果你没有作弊，请联系作者。")
                hdzcundang.addZuobiCount(whichPlayer)
            --hplayer.defeat(whichPlayer, "检测到您移动速度异常，已自动退出游戏。")
            end
            hcache.set(hero, "lastX", x)
            hcache.set(hero, "lastY", y)
        end
    )
    ]]
end
