hunitAI = {}

UNIT_AI_TYPE = {
    ATTACK_HIGEST_CHOUHENG = 1,
    CAST_SKILL = 2
}

UNIT_AI_TARGET_TYPE = {
    HIGHEST_CHOUHENG_UNIT = "仇恨最高单位",
    NEAREST_ENERMY_UNIT = "最近敌方单位",
    NEAREST_ALLY_UNIT = "最近友方单位",
    LOWEST_HEALTH_UNIT = "生命值最低敌方单位",
    LOWEST_HEALTH_ALLY = "生命值最低友方单位",
    RANDOM_ENERMY_UNIT = "随机敌方单位",
    FAREST_ENERMY_UNIT = "最远敌方单位",
    SELF = "自己"
}

--- AI config
--- {
---   {
---     aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
---     aiData = {
---       targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
---     }
---   },
---   {
---     aiType = UNIT_AI_TYPE.CAST_SKILL,
---     aiData = {
---       targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
---       name = "name",
---       description = "description",
---       healthBelowLimit = 0.4, -- only cast when health is below x
---       healthAboveLimit = 0.3, -- only cast when health is above x
---       castCountLimit = 1, -- cast only x times per battle
---       castCount = 0,
---       castCD = 1, -- nil or <=1 means 1 second
---       effect = function(),
---       shifashijian = 1,
---     }
---   },
---}
---

UnitAI = function(configs)
    local this = { configs = table.clone(configs) }
    this.getSkillDescription = function(ai)
        local msg = {}
        for _, config in ipairs(configs) do
            local aiType = config.aiType
            local skill = config.aiData
            table.insert(msg, "技能：" .. (skill.name or ""))
            table.insert(msg, "")
            table.insert(msg, "释放条件：")
            if skill.healthBelowLimit ~= nil then
                table.insert(msg, " -" .. "生命值低于" .. skill.healthBelowLimit .. "%")
            end
            if skill.healthAboveLimit ~= nil then
                table.insert(msg, " -" .. "生命值高于" .. skill.healthAboveLimit .. "%")
            end
            table.insert(msg, "释放目标：" .. skill.targetType)
            if skill.castCountLimit ~= nil then
                table.insert(msg, "最多释放" .. skill.castCountLimit .. "次")
            end
            if skill.notInterruptable == true then
                table.insert(msg, hcolor.green("可以") .. "打断")
            else
                table.insert(msg, hcolor.red("不可以") .. "打断")
            end
            if skill.minNandu ~= nil and skill.minNandu ~= FUBEN_NANDU.PUTONG then
                table.insert(msg, "技能生效难度：" .. skill.minNandu .. "及以上")
            end
            table.insert(msg, "施法时间" .. (skill.shifashijian or "") .. "及以上")
            table.insert(msg, "冷却时间" .. (skill.castCD or "") .. "及以上")
            table.insert(msg, "技能效果：" .. (skill.description or ""))
        end
        return string.implode("|n", msg)
    end
    this.canAttackNonChouhenDIYI = function(whichUnit)
        if hcache.get(whichUnit, "AI_SKILL_EFFECT", false) then
            return true
        end
        for _, config in ipairs(configs) do
            if config.aiType == UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG then
                return false
            end
        end
        return true
    end
    return this
end

hunitAI.disableAI = function(whichUnit)
    hcache.set(whichUnit,
        "AI_SKILL_EFFECT", true)
end
hunitAI.enableAI = function(whichUnit)
    hcache.set(whichUnit,
        "AI_SKILL_EFFECT", false)
end

hunitAI.action = function(whichUnit, ai)
    if ai == nil or whichUnit == nil then
        return
    end
    if hunit.isAlive(whichUnit) == false then
        return
    end
    if hunit.isPaused(whichUnit) == true then
        return
    end
    if hcache.get(whichUnit, "AI_SKILL_CASTING", false) then
        return
    end
    if hcache.get(whichUnit, "AI_SKILL_EFFECT", false) then
        return
    end
    if ai.configs == nil then
        error("no ai configs for " .. hunit.getName(whichUnit))
    end
    for idx, config in ipairs(ai.configs) do
        local nandu = hunit.getNandu(whichUnit)
        if
            (nandu ~= nil and config.aiData ~= nil and config.aiData.minNandu ~= nil and nandu < config.aiData.minNandu) or
            (config.aiData ~= nil and config.aiData.onlyInFight and hfightzhuangtai.isInFight(whichUnit) == false)
        then
            -- skip
        elseif config.aiType == UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG then
            if hfightzhuangtai.isInFight(whichUnit) == true then
                local chouhendiyi = hfightzhuangtai.getChouhengdiyi(whichUnit)
                if chouhendiyi ~= nil and hunit.isAlive(chouhendiyi) and hunit.isAlly(chouhendiyi, whichUnit) == false then
                    cj.IssueTargetOrder(whichUnit, "attack", chouhendiyi)
                    return
                end
            end
        elseif config.aiType == UNIT_AI_TYPE.CAST_SKILL then
            local hpp = hunit.getCurLifePercent(whichUnit)
            if
                ((config.aiData.healthBelowLimit ~= nil and hpp < config.aiData.healthBelowLimit) or
                    config.aiData.healthBelowLimit == nil) and
                ((config.aiData.healthAboveLimit ~= nil and hpp > config.aiData.healthAboveLimit) or
                    config.aiData.healthAboveLimit == nil) and
                ((config.aiData.castCountLimit ~= nil and
                        (config.aiData.castCount == nil or config.aiData.castCount < config.aiData.castCountLimit)) or
                    config.aiData.castCountLimit == nil) and
                ((config.aiData.castCD ~= nil and htime.checkCoolDown(whichUnit, "AI_SKILL_" .. idx) == true) or
                    config.aiData.castCD == nil) and
                (config.aiData.customCondition == nil or config.aiData.customCondition(whichUnit) == true)
            then
                local target = nil
                if config.aiData.targetType == UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT then
                    if hfightzhuangtai.isInFight(whichUnit) == true then
                        target = hfightzhuangtai.getChouhengdiyi(whichUnit)
                    end
                elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.LOWEST_HEALTH_UNIT then
                    if hfightzhuangtai.isInFight(whichUnit) == true then
                        target = hgroup.getLowestHealthEnermy(whichUnit, 1000)
                    end
                elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.SELF then
                    target = whichUnit
                elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.LOWEST_HEALTH_ALLY then
                    target =
                        hgroup.getLowestHealth(
                            hgroup.createByUnit(
                                whichUnit,
                                1000,
                                function(filterUnit)
                                    if hunit.isAlly(filterUnit, whichUnit) == true and hunit.isAlive(filterUnit) == true then
                                        return true
                                    end
                                end
                            ),
                            hunit.x(whichUnit),
                            hunit.y(whichUnit)
                        )
                elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.NEAREST_ALLY_UNIT then
                    target =
                        hgroup.getClosest(
                            hgroup.createByUnit(
                                whichUnit,
                                1000,
                                function(filterUnit)
                                    if
                                        hunit.isAlly(filterUnit, whichUnit) == true and hunit.isAlive(whichUnit) == true and
                                        filterUnit ~= whichUnit
                                    then
                                        return true
                                    end
                                end
                            ),
                            hunit.x(whichUnit),
                            hunit.y(whichUnit)
                        )
                elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.NEAREST_ENERMY_UNIT then
                    target =
                        hgroup.getClosest(
                            hgroup.createByUnit(
                                whichUnit,
                                1000,
                                function(filterUnit)
                                    if
                                        hunit.isAlly(filterUnit, whichUnit) == false and hunit.isAlive(whichUnit) == true and
                                        filterUnit ~= whichUnit
                                    then
                                        return true
                                    end
                                end
                            ),
                            hunit.x(whichUnit),
                            hunit.y(whichUnit)
                        )
                elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.RANDOM_ENERMY_UNIT then
                    target = hfightzhuangtai.getSuijiChouhengMubiao(whichUnit)
                elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.FAREST_ENERMY_UNIT then
                    target = hfightzhuangtai.getFarestChouhengMubiao(whichUnit)
                end
                local castDistance = config.aiData.castDistance or 1000
                if
                    target ~= nil and
                    (math.distance(hunit.x(whichUnit), hunit.y(whichUnit), hunit.x(target), hunit.y(target)) <
                        castDistance)
                then
                    hskill.set_next_ai_jineng(whichUnit, idx)
                    hskill.set_next_ai_target(whichUnit, target)
                    if hunit.isInvincible(target) == true or hunit.isImmune(target) == true then
                        cj.IssueTargetOrder(whichUnit, "thunderbolt", whichUnit)
                    else
                        cj.IssueTargetOrder(whichUnit, "thunderbolt", target)
                    end
                    return
                end
            end
        end
    end
end

hunitAI.leaveFight = function(ai)
    if ai == nil then
        return
    end
    for _, config in ipairs(ai.configs) do
        if config.aiData.castCountLimit ~= nil and config.aiData.castCount ~= 0 then
            config.aiData.castCount = 0
        end
    end
end

hunitAI.actionForALLUnit = function()
    for _, filterUnit in ipairs(hgroup.GLOBAL) do
        local res, errMsg = pcall(hunitAI.action, filterUnit, hunit.getAI(filterUnit))
        if res == false then
            err(errMsg)
        end
    end
end

--TODO  防止紧张被普攻暴毙
hunitAI.init = function()
    local AI_JINENG_ID = hslk.n2i("AI技能模版")
    hevent.reaction(
        CONST_EVENT.beAttackReady,
        "fangzhinonchouhen",
        function(evtData)
            local ai = hunit.getAI(evtData.attackUnit)
            if ai == nil then
                return
            end
            if ai.canAttackNonChouhenDIYI(evtData.attackUnit) then
                return
            end
            if
                hfightzhuangtai.isInFight(evtData.attackUnit) and
                hfightzhuangtai.getChouhengdiyi(evtData.attackUnit) ~= evtData.triggerUnit
            then
                cj.IssueImmediateOrder(evtData.attackUnit, "stop")
            end
        end
    )
    hevent.reaction(
        CONST_EVENT.skillEffect,
        "ai_jineng" .. AI_JINENG_ID,
        function(evtData)
            if
                evtData.targetUnit == nil or hskill.hasActiveAbility(evtData.triggerUnit, AI_JINENG_ID) == false or
                evtData.triggerSkill ~= AI_JINENG_ID
            then
                return
            end
            local aiIdx = hskill.get_next_ai_jineng(evtData.triggerUnit)
            local ai = hunit.getAI(evtData.triggerUnit)
            if aiIdx == nil or ai.configs[aiIdx] == nil then
                cj.IssueImmediateOrder(evtData.triggerUnit, "stop")
                return
            end
            local targetUnit = hskill.get_next_ai_target(evtData.triggerUnit)
            if targetUnit ~= nil then
                evtData.targetUnit = targetUnit
                hskill.clear_next_ai_target(evtData.triggerUnit)
            end
            hskill.clear_next_ai_jineng(evtData.triggerUnit)
            local aiConfig = ai.configs[aiIdx]
            -- 设置ai 技能cd
            if aiConfig.aiData.castCD ~= nil then
                htime.setupAndCheckCoolDown(evtData.triggerUnit, "AI_SKILL_" .. aiIdx, aiConfig.aiData.castCD)
            end

            local castCount = aiConfig.aiData.castCount
            if castCount == nil then
                aiConfig.aiData.castCount = 1
            else
                aiConfig.aiData.castCount = castCount + 1
            end
            local skip_skill_speed = aiConfig.aiData.skip_skill_speed or false
            local shifashijian = aiConfig.aiData.shifashijian or 0
            local skill_speed = hattribute.getWithLimit(evtData.triggerUnit, nil, "skill_speed", 0)
            if skip_skill_speed == false then
                shifashijian = shifashijian * 100 / (skill_speed + 100)
            end
            if shifashijian > 0 and shifashijian < 0.1 then
                shifashijian = 0.1
            end
            evtData.aiConfig = aiConfig
            evtData.shifashijian = shifashijian
            if aiConfig.aiData.startEffect ~= nil then
                aiConfig.aiData.startEffect(evtData)
            end
            if aiConfig.aiData.startWarning == true then
                hsound.voice2Unit(
                    hsound.voiceCreate("resource\\war3mapImported\\sound\\warning.wav", 1000, true),
                    100,
                    evtData.triggerUnit
                )
            end
            -- create effect
            if shifashijian ~= 0 then
                local skillName = aiConfig.aiData.name or "技能名字"
                hcache.set(evtData.triggerUnit, "AI_SKILL_CASTING", true)
                hcache.set(evtData.triggerUnit, "AI_SKILL_CASTING_NAME", skillName)
                hcache.set(evtData.triggerUnit, "AI_SKILL_CASTING_SHIFATIAO_MAX", shifashijian)
                if aiConfig.aiData.notInterruptable == true then
                    hbuff.wengu(shifashijian, evtData.triggerUnit)
                end
                local skillName = aiConfig.aiData.name or "技能名字"
                if aiConfig.aiData.skipTextTag ~= true then
                    evtData.skillName = htextTag.create2Unit(evtData.triggerUnit, skillName, 10, "ff3300", 1, 0, 50)
                end
                evtData.shifatiao =
                    heffect.xyz(
                        "GenericBar.mdx",
                        hunit.x(evtData.triggerUnit),
                        hunit.y(evtData.triggerUnit),
                        hunit.z(evtData.triggerUnit) - 500,
                        shifashijian
                    )
                hjapi.DzBindEffect(evtData.triggerUnit, "overhead", evtData.shifatiao)
                evtData.shifatiaoTimer =
                    htime.setInterval(
                        0.02,
                        function(curTimer)
                            local percentile =
                                math.max(0, math.min(100, math.ceil(curTimer.passedSec() / shifashijian * 100)))
                            hjapi.DzSetEffectAnimation(evtData.shifatiao, percentile, 0)
                            hcache.set(evtData.triggerUnit, "AI_SKILL_CASTING_SHIFATIAO_CURRENT", curTimer.passedSec())
                        end
                    )
                if aiConfig.aiData.interval ~= nil and aiConfig.aiData.periodEffect ~= nil then
                    hcache.set(
                        evtData.triggerUnit,
                        "zdjn_sfsj_interval_timer_" .. evtData.triggerSkill,
                        htime.setInterval(
                            math.round(aiConfig.aiData.interval * 100 / (skill_speed + 100)),
                            function(curTimer)
                                aiConfig.aiData.periodEffect(evtData, curTimer)
                            end
                        )
                    )
                end
            end
            evtData.targetX = hunit.x(evtData.targetUnit)
            evtData.targetY = hunit.y(evtData.targetUnit)
            evtData.targetZ = hunit.z(evtData.targetUnit)
            hcache.set(evtData.triggerUnit, "zdjn_finish_sh_" .. evtData.triggerSkill, false)
            hcache.set(evtData.triggerUnit, CONST_CACHE.SKILL_EFFECT .. evtData.triggerSkill, evtData)
            hcache.set(
                evtData.triggerUnit,
                "zdjn_sfsj_timer_" .. evtData.triggerSkill,
                htime.setTimeout(
                    shifashijian,
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
        "ai_jineng" .. AI_JINENG_ID,
        function(evtData)
            if
                hskill.hasActiveAbility(evtData.triggerUnit, AI_JINENG_ID) == false or
                evtData.triggerSkill ~= AI_JINENG_ID
            then
                return
            end
            local triggerData = hcache.get(evtData.triggerUnit, CONST_CACHE.SKILL_EFFECT .. evtData.triggerSkill)
            if (triggerData == nil or triggerData.targetUnit == nil) then
                return
            end
            if triggerData.shifatiao ~= nil then
                triggerData.shifatiaoTimer.destroy()
                hjapi.DzUnbindEffect(triggerData.shifatiao)
                hjapi.DzSetEffectPos(triggerData.shifatiao, 0, 0, -1000)
                heffect.destroy(triggerData.shifatiao)
                if triggerData.skillName ~= nil then
                    htextTag.destroy(triggerData.skillName)
                end
                hcache.set(evtData.triggerUnit, "AI_SKILL_CASTING", false)
            end
            hcache.free(evtData.triggerUnit, CONST_CACHE.SKILL_EFFECT .. evtData.triggerSkill)
            if hcache.get(evtData.triggerUnit, "zdjn_finish_sh_" .. evtData.triggerSkill, nil) == true then
                triggerData.aiConfig.aiData.effect(triggerData)
            else
                local skillName = triggerData.aiConfig.aiData.name or "技能名字"
                htextTag.create2Unit(evtData.triggerUnit, skillName .. "被打断", 10, "ff3300", 1, 1, 50)
            end
            hbuff.delete(evtData.triggerUnit, "稳固")
            if triggerData.aiConfig.aiData.endEffect ~= nil then
                triggerData.aiConfig.aiData.endEffect(triggerData)
            end
            local timer = hcache.get(evtData.triggerUnit, "zdjn_sfsj_timer_" .. evtData.triggerSkill)
            if timer ~= nil then
                timer.destroy()
            end
            hcache.free(evtData.triggerUnit, "zdjn_sfsj_timer_" .. evtData.triggerSkill)
            local intervalTimer = hcache.get(evtData.triggerUnit, "zdjn_sfsj_interval_timer_" .. evtData.triggerSkill)
            if intervalTimer ~= nil then
                intervalTimer.destroy()
            end
        end
    )
    htime.setInterval(
        1,
        function(_)
            hunitAI.actionForALLUnit()
        end
    )
end
