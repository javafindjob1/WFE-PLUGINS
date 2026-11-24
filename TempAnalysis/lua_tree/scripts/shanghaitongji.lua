hevent.reaction(
    CONST_EVENT.beDamage,
    "shanghaitongji",
    function(evtData)
        local player = hunit.getOwner(evtData.sourceUnit)
        if hplayer.isUser(player) == false or hplayer.isPlaying(player) == false then
            return
        end
        local monsterType = hunit.getMonsterType(evtData.triggerUnit)
        hplayer.forEach(
            function(enumPlayer, _)
                if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                    return
                end

                if
                    hcache.get(enumPlayer, "bossshanghai", false) and monsterType ~= MONSTER_TYPE.FUBEN_BOSS and
                        monsterType ~= MONSTER_TYPE.SHIJIE_BOSS and
                        monsterType ~= MONSTER_TYPE.YEWAI_BOSS
                 then
                    return
                end
                local damage_data = hcache.get(enumPlayer, CONST_CACHE.SKILL_EFFECT .. "shanghaitongji_damage")
                if damage_data == nil then
                    damage_data = {}
                    damage_data.overallDamage = 0
                    damage_data.globalView = {}
                    damage_data.detail = {}
                    damage_data.count_detail = {}
                    damage_data.timePassed = 0
                    hcache.set(enumPlayer, CONST_CACHE.SKILL_EFFECT .. "shanghaitongji_damage", damage_data)
                end
                if damage_data.globalView[player] == nil then
                    damage_data.globalView[player] = 0
                end
                damage_data.globalView[player] = damage_data.globalView[player] + evtData.damage
            end
        )
        if
            hcache.get(player, "bossshanghai", false) and monsterType ~= MONSTER_TYPE.FUBEN_BOSS and
                monsterType ~= MONSTER_TYPE.SHIJIE_BOSS and
                monsterType ~= MONSTER_TYPE.YEWAI_BOSS
         then
            return
        end
        local skill_name = "攻击"
        if evtData.triggerSkill ~= nil then
            skill_name = hskill.getName(evtData.triggerSkill)
        end
        if evtData.shanghainame ~= nil then
            skill_name = evtData.shanghainame
        end
        local damage_data = hcache.get(player, CONST_CACHE.SKILL_EFFECT .. "shanghaitongji_damage")
        if damage_data == nil then
            err("nil damanage data, should not happen")
        end
        damage_data.overallDamage = evtData.damage + damage_data.overallDamage
        if damage_data.detail[skill_name] == nil then
            damage_data.detail[skill_name] = 0
        end
        damage_data.detail[skill_name] = evtData.damage + damage_data.detail[skill_name]
        if damage_data.count_detail[skill_name] == nil then
            damage_data.count_detail[skill_name] = 0
        end
        damage_data.count_detail[skill_name] = damage_data.count_detail[skill_name] + 1
    end
)
