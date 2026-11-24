hskill = {}

SKILLS = {}
SKILLS_FINISH = {}
SKILLS_STOP = {}
SKILLS_CAST = {}
SKILL_SETUP = {}
SKILL_ON_LEVEL_UP = {}
GLOBAL_LAST_DAMAGED_BOSS = {}

--- 获取属性加成,需要注册
---@param abilityId string|number
---@return table|nil
function hskill.getAttribute(abilityId)
    if (type(abilityId) == "number") then
        abilityId = i2c(abilityId)
    end
    return hslk.i2v(abilityId, "_attr")
end

--- 附加单位获得技能后的属性
function hskill.addProperty(whichUnit, abilityId, level)
    local attr = hskill.getAttribute(abilityId)
    if (attr ~= nil) then
        if (#attr > 0) then
            level = level or 1
            attr = attr[level]
        end
        hbuff.addAttribute(CONST_DAMAGE_SRC.skill, whichUnit, abilityId, attr, 0)
    end
end
--- 削减单位获得技能后的属性
---@protected
function hskill.subProperty(whichUnit, abilityId, level)
    local attr = hskill.getAttribute(abilityId)
    if (attr ~= nil) then
        if (#attr > 0) then
            level = level or 1
            attr = attr[level]
        end
        hattribute.caleAttribute(CONST_DAMAGE_SRC.skill, false, whichUnit, attr, 1)
    end
end

function hskill.registerAutoCast(hero, abilityId)
    local whichPlayer = hunit.getOwner(hero)
    hevent.register(
        hero,
        CONST_EVENT.skillEffect,
        "track skill target" .. abilityId,
        function(evtData)
            if hcache.get(whichPlayer, "zhinengshifa") ~= true then
                return
            end
            if evtData.triggerSkill == abilityId then
                if hcache.get(whichPlayer, "autoCastTarget") ~= evtData.targetUnit then
                    echo("自动施法目标：" .. hunit.getName(evtData.targetUnit), whichPlayer)
                    hcache.set(whichPlayer, "autoCastTarget", evtData.targetUnit)
                end
            end
        end
    )

    if whichPlayer == hplayer.loc() then
        hjapi.DzTriggerRegisterKeyEventByCode(
            nil,
            string.byte(hslk.i2v(abilityId, "Hotkey")),
            GAME_KEY_ACTION_RELEASE,
            false,
            function()
                local target = hjapi.DzGetUnitUnderMouse()
                local owner = hunit.getOwner(target)
                if hcache.get(hplayer.loc(), "zhinengshifa") ~= true then
                    return
                end
                if
                    hunit.isDead(target) or hplayer.isUser(owner) or hplayer.isNeutral(owner) or
                        hunit.isAlly(hplayer.loc(), owner)
                 then
                    hsync.send("skillautocast", {abilityId})
                end
            end
        )
    end
end

--- 获取技能名称
---@param abilityId number|string
---@return string
function hskill.getName(abilityId)
    local id = abilityId
    if (type(abilityId) == "string") then
        id = c2i(id)
    end
    return cj.GetObjectName(id)
end

--- 获取技能等级
---@param whichUnit userdata
---@param abilityId number|string
---@return string
function hskill.getLevel(whichUnit, abilityId)
    local id = abilityId
    if (type(abilityId) == "string") then
        id = c2i(id)
    end
    return cj.GetUnitAbilityLevel(whichUnit, id)
end

--- 设置技能等级
---@param whichUnit userdata
---@param abilityId number|string
---@param level number
---@return string
function hskill.setLevel(whichUnit, abilityId, level)
    local id = abilityId
    if (type(abilityId) == "string") then
        id = c2i(id)
    end
    return cj.SetUnitAbilityLevel(whichUnit, id, level)
end

--- 添加技能
---@param whichUnit userdata
---@param abilityId string|number
---@param level number
---@param during number
function hskill.add(whichUnit, abilityId, level, during)
    local id = abilityId
    if (type(abilityId) == "string") then
        id = c2i(id)
    end
    level = level or 1
    if (during == nil or during <= 0) then
        cj.UnitAddAbility(whichUnit, id)
        cj.UnitMakeAbilityPermanent(whichUnit, true, id)
        if (level > 1) then
            cj.SetUnitAbilityLevel(whichUnit, id, level)
        end
        hskill.addProperty(whichUnit, id, level)
    else
        cj.UnitAddAbility(whichUnit, id)
        if (level > 1) then
            cj.SetUnitAbilityLevel(whichUnit, id, level)
        end
        hskill.addProperty(whichUnit, id, level)
        htime.setTimeout(
            during,
            function(t)
                t.destroy()
                hskill.destroy(whichUnit, id)
            end
        )
    end
end

--- 设置技能等级
---@param whichUnit userdata
---@param abilityId string|number
---@param level number
---@param during number
function hskill.set(whichUnit, abilityId, level, during)
    local id = abilityId
    if (type(abilityId) == "string") then
        id = c2i(id)
    end
    local prevLv = cj.GetUnitAbilityLevel(whichUnit, id)
    if (level == nil or level == prevLv) then
        return
    end
    if (prevLv < 1) then
        hskill.add(whichUnit, abilityId, level, during)
    else
        if (during == nil or during <= 0) then
            hskill.subProperty(whichUnit, id, prevLv)
            cj.SetUnitAbilityLevel(whichUnit, id, level)
            hskill.addProperty(whichUnit, id, level)
        else
            htime.setTimeout(
                during,
                function(t)
                    t.destroy()
                    hskill.set(whichUnit, abilityId, prevLv, nil)
                end
            )
        end
    end
end

--- 删除技能
---@param whichUnit userdata
---@param abilityId string|number
---@param delay number
function hskill.destroy(whichUnit, abilityId, delay)
    local id = abilityId
    if (type(abilityId) == "string") then
        id = c2i(id)
    end
    local lv = cj.GetUnitAbilityLevel(whichUnit, id)
    if (lv < 1) then
        return
    end
    if (delay == nil or delay <= 0) then
        cj.UnitRemoveAbility(whichUnit, id)
        hskill.subProperty(whichUnit, id, lv)
    else
        cj.UnitRemoveAbility(whichUnit, id)
        hskill.subProperty(whichUnit, id, lv)
        htime.setTimeout(
            delay,
            function(t)
                t.destroy()
                hskill.add(whichUnit, id, lv)
            end
        )
    end
end

--- 设置技能的永久使用性
---@param whichUnit userdata
---@param abilityId string|number
function hskill.forever(whichUnit, abilityId)
    local id = abilityId
    if (type(abilityId) == "string") then
        id = c2i(id)
    end
    cj.UnitMakeAbilityPermanent(whichUnit, true, id)
end

--- 是否拥有技能
---@param whichUnit userdata
---@param abilityId string|number
function hskill.has(whichUnit, abilityId)
    if (whichUnit == nil or abilityId == nil) then
        return false
    end
    local id = abilityId
    if (type(abilityId) == "string") then
        id = c2i(id)
    end
    if (cj.GetUnitAbilityLevel(whichUnit, id) >= 1) then
        return true
    end
    return false
end

--- 是否拥有技能并且科技达标
---@param whichUnit userdata
---@param abilityId string|number
function hskill.hasActiveAbility(whichUnit, abilityId)
    local hasAbility = hskill.has(whichUnit, abilityId)
    if hasAbility == false then
        return false
    end
    local upgradeName = hslk.i2v(abilityId, "Requires")
    local upgradeLevel = hslk.i2v(abilityId, "Requiresamount")
    if upgradeName == nil or upgradeLevel == nil then
        return true
    end
    local techLevel = hplayer.getPlayerTechResearched(hunit.getOwner(whichUnit), c2i(upgradeName))
    if techLevel >= tonumber(upgradeLevel) then
        return true
    else
        return false
    end
end

SKILL_SETUP_FUNCTION = function()
    ---@param evtData onSkillEffectData
    hevent.reaction(
        CONST_EVENT.skillEffect,
        "skills",
        function(evtData)
            local name = hslk.i2v(evtData.triggerSkill, "slk", "Name")
            -- 触发技能效果
            if (type(SKILLS[name]) == "function") then
                SKILLS[name](evtData)
            end
        end
    )

    hevent.reaction(
        CONST_EVENT.skillCast,
        "skills",
        function(evtData)
            local name = hslk.i2v(evtData.triggerSkill, "slk", "Name")
            -- 触发技能效果
            if (type(SKILLS_CAST[name]) == "function") then
                SKILLS_CAST[name](evtData)
            end
        end
    )

    hevent.reaction(
        CONST_EVENT.skillFinish,
        "skills",
        function(evtData)
            local name = hslk.i2v(evtData.triggerSkill, "slk", "Name")
            -- 触发技能效果
            if (type(SKILLS_FINISH[name]) == "function") then
                SKILLS_FINISH[name](evtData)
            end
        end
    )

    hevent.reaction(
        CONST_EVENT.skillStop,
        "skills",
        function(evtData)
            local name = hslk.i2v(evtData.triggerSkill, "slk", "Name")
            -- 触发技能效果
            if (type(SKILLS_STOP[name]) == "function") then
                htime.setTimeout(
                    0.01,
                    function()
                        SKILLS_STOP[name](evtData)
                    end
                )
            end
        end
    )

    hsync.onSend(
        "skillautocast",
        function(syncData)
            local order = hslk.i2v(syncData.triggerData[1], "DataF")
            local target = hcache.get(syncData.triggerPlayer, "autoCastTarget")
            local hero = hplayer.getMainHero(syncData.triggerPlayer)
            if target == nil then
                --echo("没有自动施法目标", syncData.triggerPlayer)
            elseif hunit.isAlive(target) == false then
                --echo("自动施法目标已死亡", syncData.triggerPlayer)
            elseif math.distance(hunit.x(hero), hunit.y(hero), hunit.x(target), hunit.y(target)) > 1500 then
                --echo("自动施法目标距离过远", syncData.triggerPlayer)
            else
                cj.IssueTargetOrder(hero, order, target)
            end
        end
    )
end

function hskill.isUnitCasting(whichUnit)
    return hcache.get(whichUnit, "zdjn_shifatiao_timer") ~= nil
end

--- 设置主动技能函数
function hskill.setup_zhudong_jineng(
    whichUnit,
    skillID,
    skillFunc,
    shifashijian,
    resrouceCheck,
    castingSound,
    interval,
    intervalPurpose,
    start,
    stop,
    skipIntervalSpeed,
    cancel,
    clearCoolDownOnFinish,
    clearCoolDownOnCancel)
    if skillFunc == nil then
        err("no skillFunc")
        return
    end
    hevent.register(
        whichUnit,
        CONST_EVENT.skillEffect,
        "zhudongjineng" .. skillID,
        function(evtData)
            if
                (evtData.targetUnit == nil and
                    (evtData.targetX == nil or evtData.targetY == nil or evtData.targetZ == nil)) or
                    hskill.hasActiveAbility(evtData.triggerUnit, skillID) == false or
                    evtData.triggerSkill ~= skillID
             then
                return
            end
            if resrouceCheck ~= nil and resrouceCheck(whichUnit) == false then
                cj.IssueImmediateOrder(evtData.triggerUnit, "stop")
                return
            end
            local basicShifashijian = shifashijian
            if type(shifashijian) == "function" then
                basicShifashijian = shifashijian(evtData.triggerUnit, evtData.targetUnit)
            end
            local skillspeedfactor = (100 + hattribute.getWithLimit(evtData.triggerUnit, nil, "skill_speed", 0)) / 100
            local finalShifashijian = math.ceil(100 * basicShifashijian / skillspeedfactor) / 100
            local finalInterval
            if interval ~= nil then
                finalInterval = interval(evtData.triggerUnit, evtData.targetUnit)
                if skipIntervalSpeed ~= true then
                    finalInterval = finalInterval / skillspeedfactor
                end
                finalInterval = math.max(0.01, math.floor(finalInterval * 100) / 100)
            end
            if hplayer.loc() == hunit.getOwner(whichUnit) then
                ui_set_shifatiaovalue(hskill.getName(skillID), 0, finalShifashijian)
            end
            local i = 1
            local intervalCount = 0
            hcache.set(
                evtData.triggerUnit,
                "zdjn_shifatiao_timer",
                htime.setInterval(
                    0.01,
                    function(curTimer)
                        if hplayer.loc() == hunit.getOwner(whichUnit) then
                            ui_set_shifatiaovalue(hskill.getName(skillID), i * 0.01, finalShifashijian)
                        end
                        i = i + 1
                        intervalCount = intervalCount + 1
                        if finalInterval ~= nil and finalInterval * 100 <= intervalCount then
                            intervalPurpose(
                                evtData.triggerUnit,
                                evtData.targetUnit,
                                evtData.targetX,
                                evtData.targetY,
                                evtData.targetZ
                            )
                            intervalCount = 0
                        end
                        if i >= (finalShifashijian * 100) then
                            curTimer.destroy()
                        end
                    end
                )
            )
            if castingSound ~= nil then
                local sound
                if type(castingSound) == "table" then
                    sound = hsound.voiceCreate(castingSound[1], finalShifashijian * 1000, castingSound[2])
                else
                    sound = hsound.voiceCreate(castingSound, finalShifashijian * 1000, true)
                end
                evtData.castingSoundInstance = sound
                hsound.voice2Unit(sound, 100, evtData.triggerUnit)
            end
            if start then
                start(evtData.triggerUnit, evtData.targetUnit, evtData.targetX, evtData.targetY, evtData.targetZ)
            end
            hcache.set(evtData.triggerUnit, "zdjn_finish_sh_" .. evtData.triggerSkill, false)
            hcache.set(evtData.triggerUnit, CONST_CACHE.SKILL_EFFECT .. evtData.triggerSkill, evtData)
            hcache.set(
                evtData.triggerUnit,
                "zdjn_sfsj_timer_" .. evtData.triggerSkill,
                htime.setTimeout(
                    finalShifashijian,
                    function(_)
                        hcache.free(evtData.triggerUnit, "zdjn_sfsj_timer_" .. evtData.triggerSkill)
                        hcache.set(evtData.triggerUnit, "zdjn_finish_sh_" .. evtData.triggerSkill, true)
                        cj.IssueImmediateOrder(evtData.triggerUnit, "stop")
                    end
                )
            )
        end
    )
    hevent.register(
        whichUnit,
        CONST_EVENT.skillStop,
        "zhudongjineng" .. skillID,
        function(evtData)
            if hskill.hasActiveAbility(evtData.triggerUnit, skillID) == false or evtData.triggerSkill ~= skillID then
                return
            end
            local triggerData = hcache.get(evtData.triggerUnit, CONST_CACHE.SKILL_EFFECT .. evtData.triggerSkill)
            if
                (triggerData == nil or
                    (triggerData.targetUnit == nil and
                        (triggerData.targetX == nil or triggerData.targetY == nil or triggerData.targetZ == nil)))
             then
                return
            end
            if triggerData.castingSoundInstance ~= nil then
                cj.StopSound(triggerData.castingSoundInstance, false, true)
            end
            hcache.free(evtData.triggerUnit, CONST_CACHE.SKILL_EFFECT .. evtData.triggerSkill)
            if hcache.get(evtData.triggerUnit, "zdjn_finish_sh_" .. evtData.triggerSkill, nil) == true then
                skillFunc(triggerData)
                if clearCoolDownOnFinish then
                    hskill.setCoolDown(evtData.triggerUnit, evtData.triggerSkill, 0)
                end
                if triggerData.targetUnit ~= nil then
                    --echo(123)
                    cj.IssueTargetOrder(triggerData.triggerUnit, "attack", triggerData.targetUnit)
                end
            else
                if clearCoolDownOnCancel then
                    hskill.setCoolDown(evtData.triggerUnit, evtData.triggerSkill, 0)
                end
                if cancel then
                    cancel(triggerData.triggerUnit, triggerData.targetUnit)
                end
            end
            local timer = hcache.get(evtData.triggerUnit, "zdjn_sfsj_timer_" .. evtData.triggerSkill)
            if timer ~= nil then
                timer.destroy()
            end
            -- 取消读条UI
            if hplayer.loc() == hunit.getOwner(whichUnit) then
                ui_clear_shifatiao()
            end
            local shifatiaoTimer = hcache.get(evtData.triggerUnit, "zdjn_shifatiao_timer", nil)
            if shifatiaoTimer ~= nil then
                shifatiaoTimer.destroy()
            end
            hcache.free(evtData.triggerUnit, "zdjn_shifatiao_timer")
            hcache.free(evtData.triggerUnit, "zdjn_sfsj_timer_" .. evtData.triggerSkill)
            if stop then
                stop(triggerData.triggerUnit, triggerData.targetUnit)
            end
        end
    )
end

function hskill.set_next_ai_jineng(whichUnit, idx)
    if whichUnit == nil or idx == nil then
        err("fail to set aijineng")
        return
    end
    hcache.set(whichUnit, CONST_CACHE.AI_NEXT_JINENG, idx)
end

function hskill.get_next_ai_jineng(whichUnit)
    if whichUnit == nil then
        return
    end
    return hcache.get(whichUnit, CONST_CACHE.AI_NEXT_JINENG, nil)
end

function hskill.set_next_ai_target(whichUnit, targetUnit)
    if whichUnit == nil or targetUnit == nil then
        err("fail to set ai target")
        return
    end
    hcache.set(whichUnit, CONST_CACHE.AI_NEXT_TARTET, targetUnit)
end

function hskill.get_next_ai_target(whichUnit, targetUnit)
    if whichUnit == nil then
        return
    end
    return hcache.get(whichUnit, CONST_CACHE.AI_NEXT_TARTET, nil)
end

function hskill.clear_next_ai_target(whichUnit)
    if whichUnit == nil then
        return
    end
    return hcache.free(whichUnit, CONST_CACHE.AI_NEXT_TARTET)
end

function hskill.clear_next_ai_jineng(whichUnit)
    if whichUnit == nil then
        return
    end
    return hcache.free(whichUnit, CONST_CACHE.AI_NEXT_JINENG)
end

--- [JAPI]设置单位某个技能的冷却时间
---@param whichUnit userdata
---@param abilityId string|number
---@param coolDown number
function hskill.setCoolDown(whichUnit, abilityId, coolDown)
    if (coolDown >= 9999) then
        coolDown = 9999
    elseif (coolDown < 0) then
        coolDown = 0
    end
    hjapi.EXSetAbilityState(hjapi.EXGetUnitAbility(whichUnit, abilityId), 1, coolDown)
end

--- [JAPI]获得单位某个技能的冷却时间
---@param whichUnit userdata
---@param abilityId string|number
---@return coolDown number
function hskill.getCoolDown(whichUnit, abilityId)
    return hjapi.EXGetAbilityState(hjapi.EXGetUnitAbility(whichUnit, abilityId), 1)
end

--- [JAPI]改变单位某个技能的技能说明 Ubertip
---@param whichUnit userdata
---@param abilityId string|number 四位id为最佳 数字id也行
---@param tip string
---@return void
function hskill.setAbilityUberTip(whichUnit, abilityId, tip)
    hjapi.EXSetAbilityDataString(
        hjapi.EXGetUnitAbility(whichUnit, c2i(abilityId)),
        cj.GetUnitAbilityLevel(whichUnit, c2i(abilityId)),
        218,
        tip
    )
end

--- [JAPI]改变单位某个技能的art
---@param whichUnit userdata
---@param abilityId string|number 四位id为最佳 数字id也行
---@param tip string
---@return void
function hskill.setAbilityArt(whichUnit, abilityId, tip)
    hjapi.EXSetAbilityDataString(
        hjapi.EXGetUnitAbility(whichUnit, c2i(abilityId)),
        cj.GetUnitAbilityLevel(whichUnit, c2i(abilityId)),
        204,
        tip
    )
end

--[[
    造成治疗 
    options = {
        healer = nil, --(可选)
        healee = nil, --目标单位
        heal = 0, --实际治疗 
        healType = nil, -- 治疗类型
        triggerSkill = nil, -- 技能
        effect = string, --特效路径  
        tmpAttr = nil|table, -- 该次伤害触发单位额外属性
    }
]]
---@alias noteSkillHeal {healer:userdata,healee:userdata,heal:number,effect:string,healType:any,triggerSkill:any, tmpAttr:nil|table}
---@param options noteSkillHeal
function hskill.heal(options)
    options.heal = options.heal or 0
    if (options.heal < 0.125) then
        return
    end
    if (options.healee == nil) then
        return
    end
    if (hunit.isDead(options.healee) or hunit.isDestroyed(options.healee)) then
        return
    end
    if (options.healer ~= nil and hunit.isDestroyed(options.healer)) then
        return
    end
    --双方attr get
    if (hattribute.get(options.healee) == nil) then
        return
    end
    if (options.healer ~= nil and hattribute.get(options.healer) == nil) then
        return
    end
    --- 对接伤害过程
    heal.actions.forEach(
        function(_, callFunc)
            callFunc(options)
            return options.heal > 0
        end
    )
    local finalHeal = options.heal
    local overHeal = 0
    if hunit.getCurLife(options.healee) + finalHeal > hunit.getMaxLife(options.healee) then
        overHeal = finalHeal - hunit.getMaxLife(options.healee) + hunit.getCurLife(options.healee)
        finalHeal = hunit.getMaxLife(options.healee) - hunit.getCurLife(options.healee)
    end
    hunit.addCurLife(options.healee, finalHeal)
    hevent.trigger(
        options.healee,
        CONST_EVENT.heal,
        {healer = options.healer, healee = options.healee, heal = finalHeal, overHeal = overHeal}
    )
end

--[[
    造成伤害
    options = {
        sourceUnit = nil, --伤害来源(可选)
        targetUnit = nil, --目标单位
        damage = 0, --实际伤害 
        damageSrc = "unknown", --伤害来源请查看 CONST_DAMAGE_SRC
        damangeTyoe = nil, -- 伤害类型
        triggerSkill = nil, -- 技能
        effect = string, --特效路径
        tmpAttr = nil|table, -- 该次伤害触发单位额外属性
        damageElementType = nil,
        damageSpeedType=nil ,
        shanghainame = str,
        cirticalEffect = function(options)
    } 
]]
---@alias noteSkillDamage {sourceUnit:userdata,targetUnit:userdata,damage:number,effect:string,damageSrc:string,damageType:any,triggerSkill:any, tmpAttr:nil|table, damageElementType:CONST_DAMAGE_ELEMENT_TYPE,damageSpeedType:CONST_DAMAGE_SPEED_TYPE,shanghainame:string,criticalEffect:function}
---@param options noteSkillDamage
function hskill.damage(options)
    options.damage = options.damage or 0
    options.damageSpeedType = options.damageSpeedType or CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
    if (options.damage < 0.125) then
        return
    end
    if (options.targetUnit == nil) then
        return
    end
    if (hunit.isDead(options.targetUnit) or hunit.isDestroyed(options.targetUnit)) then
        return
    end
    if (hunit.isDestroyed(options.targetUnit)) then
        return
    end
    if (options.sourceUnit ~= nil and hunit.isDestroyed(options.sourceUnit)) then
        return
    end
    if (options.damageSrc == nil) then
        options.damageSrc = CONST_DAMAGE_SRC.unknown
    end
    --双方attr get
    if (hattribute.get(options.targetUnit) == nil) then
        return
    end
    if (options.sourceUnit ~= nil and hattribute.get(options.sourceUnit) == nil) then
        return
    end
    if (options.damageSrc == CONST_DAMAGE_SRC.attack) then
        options.damage = hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "attack", 0)
        hevent.trigger(options.sourceUnit, CONST_EVENT.beforeAttackDamage, options)
        if options.damage < 0.125 then
            return
        end
    end
    --- 对接伤害过程
    damaging.actions.forEach(
        function(_, callFunc)
            callFunc(options)
            return options.damage > 0
        end
    )
    -- 护盾
    options.damage = hbuff.xiaochuhudun(options.targetUnit, options.damage) or options.damage
    -- 最终伤害
    if (options.damage > 0.125 and hunit.isDestroyed(options.targetUnit) == false) then
        -- 设置单位|玩家正在受伤
        local isBeDamagingTimer = hcache.get(options.targetUnit, CONST_CACHE.ATTR_BE_DAMAGING_TIMER, nil)
        if (isBeDamagingTimer ~= nil) then
            isBeDamagingTimer.destroy()
            hcache.set(options.targetUnit, CONST_CACHE.ATTR_BE_DAMAGING_TIMER, nil)
        end
        hcache.set(options.targetUnit, CONST_CACHE.ATTR_BE_DAMAGING, true)
        hcache.set(
            options.targetUnit,
            CONST_CACHE.ATTR_BE_DAMAGING_TIMER,
            htime.setTimeout(
                3.5,
                function(t)
                    t.destroy()
                    hcache.set(options.targetUnit, CONST_CACHE.ATTR_BE_DAMAGING_TIMER, nil)
                    hcache.set(options.targetUnit, CONST_CACHE.ATTR_BE_DAMAGING, false)
                end
            )
        )
        local targetPlayer = hunit.getOwner(options.targetUnit)
        hplayer.addBeDamage(targetPlayer, options.damage)
        local isPlayerBeDamagingTimer = hcache.get(targetPlayer, CONST_CACHE.ATTR_BE_DAMAGING_TIMER, nil)
        if (isPlayerBeDamagingTimer ~= nil) then
            isPlayerBeDamagingTimer.destroy()
            hcache.set(targetPlayer, CONST_CACHE.ATTR_BE_DAMAGING_TIMER, nil)
        end
        hcache.set(targetPlayer, CONST_CACHE.ATTR_BE_DAMAGING, true)
        hcache.set(
            targetPlayer,
            CONST_CACHE.ATTR_BE_DAMAGING_TIMER,
            htime.setTimeout(
                3.5,
                function(t)
                    t.destroy()
                    hcache.set(targetPlayer, CONST_CACHE.ATTR_BE_DAMAGING_TIMER, nil)
                    hcache.set(targetPlayer, CONST_CACHE.ATTR_BE_DAMAGING, false)
                end
            )
        )
        -- 设置单位|玩家正在造成伤害
        if (options.sourceUnit ~= nil and hunit.isDestroyed(options.sourceUnit) == false) then
            local isDamagingTimer = hcache.get(options.sourceUnit, CONST_CACHE.ATTR_DAMAGING_TIMER, nil)
            if (isDamagingTimer ~= nil) then
                isDamagingTimer.destroy()
                hcache.set(options.sourceUnit, CONST_CACHE.ATTR_DAMAGING_TIMER, nil)
            end
            hcache.set(options.sourceUnit, CONST_CACHE.ATTR_DAMAGING, true)
            hevent.setLastDamage(options.sourceUnit, options.targetUnit)
            hcache.set(
                options.sourceUnit,
                CONST_CACHE.ATTR_DAMAGING_TIMER,
                htime.setTimeout(
                    3.5,
                    function(t)
                        t.destroy()
                        hcache.set(options.sourceUnit, CONST_CACHE.ATTR_DAMAGING_TIMER, nil)
                        hcache.set(options.sourceUnit, CONST_CACHE.ATTR_DAMAGING, false)
                        hevent.setLastDamage(options.sourceUnit, nil)
                    end
                )
            )
            local sourcePlayer = hunit.getOwner(options.sourceUnit)
            hplayer.addDamage(sourcePlayer, options.damage)
            local isPlayerDamagingTimer = hcache.get(sourcePlayer, CONST_CACHE.ATTR_DAMAGING_TIMER, nil)
            if (isPlayerDamagingTimer ~= nil) then
                isPlayerDamagingTimer.destroy()
                hcache.set(sourcePlayer, CONST_CACHE.ATTR_DAMAGING_TIMER, nil)
            end
            hcache.set(sourcePlayer, CONST_CACHE.ATTR_DAMAGING, true)
            hcache.set(
                sourcePlayer,
                CONST_CACHE.ATTR_DAMAGING_TIMER,
                htime.setTimeout(
                    3.5,
                    function(t)
                        t.destroy()
                        hcache.set(sourcePlayer, CONST_CACHE.ATTR_DAMAGING_TIMER, nil)
                        hcache.set(sourcePlayer, CONST_CACHE.ATTR_DAMAGING, false)
                    end
                )
            )
        end

        local damagetaken = hcache.get(options.targetUnit, CONST_CACHE.DAMAGE_TAKEN, 0)
        hcache.set(options.targetUnit, CONST_CACHE.DAMAGE_TAKEN, damagetaken + options.damage)
        hcache.set(hunit.getOwner(options.sourceUnit), CONST_CACHE.LAST_DAMAGE_TIME, htime.inc)
        -- 扣血
        hunit.subCurLife(options.targetUnit, options.damage)

        if (type(options.effect) == "string") then
            heffect.xyz(
                options.effect,
                hunit.x(options.targetUnit),
                hunit.y(options.targetUnit),
                hunit.z(options.targetUnit),
                0
            )
        end
        -- @暴击伤害事件
        if (options.sourceUnit ~= nil and options.isCritical == true) then
            if options.criticalEffect ~= nil then
                options.criticalEffect(options)
            end
            if options.damageType == DAMAGE_TYPE.WULI or options.damageSrc == CONST_DAMAGE_SRC.attack then
                hevent.trigger(
                    options.sourceUnit,
                    CONST_EVENT.wulibaoji,
                    {
                        triggerUnit = options.sourceUnit,
                        targetUnit = options.targetUnit,
                        damage = options.damage,
                        damageSrc = options.damageSrc,
                        damageType = options.damageType,
                        triggerSkill = options.triggerSkill,
                        damageSpeedType = options.damageSpeedType
                    }
                )
            end
            if options.damageType == DAMAGE_TYPE.MOFA then
                hevent.trigger(
                    options.sourceUnit,
                    CONST_EVENT.fashubaoji,
                    {
                        triggerUnit = options.sourceUnit,
                        targetUnit = options.targetUnit,
                        damage = options.damage,
                        damageSrc = options.damageSrc,
                        damageType = options.damageType,
                        triggerSkill = options.triggerSkill,
                        damageSpeedType = options.damageSpeedType
                    }
                )
            end
        end
        -- @记录伤害目标
        if (options.sourceUnit ~= nil) then
            local owner = hunit.getOwner(options.sourceUnit)
            if hplayer.isUser(owner) and hplayer.isComputer(owner) == false and hplayer.isPlaying(owner) then
                local monsterType = hunit.getMonsterType(options.targetUnit)
                if
                    monsterType == MONSTER_TYPE.SHIJIE_BOSS or monsterType == MONSTER_TYPE.FUBEN_BOSS or
                        monsterType == MONSTER_TYPE.YEWAI_BOSS or
                        hunit.getName(options.targetUnit) == "挨打的木桩"
                 then
                    GLOBAL_LAST_DAMAGED_BOSS[owner] = options.targetUnit
                end
            end
        end
        -- @触发伤害事件
        if (options.sourceUnit ~= nil) then
            hevent.trigger(
                options.sourceUnit,
                CONST_EVENT.damage,
                {
                    triggerUnit = options.sourceUnit,
                    targetUnit = options.targetUnit,
                    damage = options.damage,
                    damageSrc = options.damageSrc,
                    damageType = options.damageType,
                    isCritical = options.isCritical,
                    triggerSkill = options.triggerSkill,
                    shanghainame = options.shanghainame
                }
            )
        end
        -- @触发被伤害事件
        hevent.trigger(
            options.targetUnit,
            CONST_EVENT.beDamage,
            {
                triggerUnit = options.targetUnit,
                sourceUnit = options.sourceUnit,
                damage = options.damage,
                damageSrc = options.damageSrc,
                damageType = options.damageType,
                isCritical = options.isCritical,
                triggerSkill = options.triggerSkill,
                shanghainame = options.shanghainame,
                damageSpeedType = options.damageSpeedType
            }
        )
        if (options.damageSrc == CONST_DAMAGE_SRC.attack or options.isAttackReplacement == true) then
            if (options.sourceUnit ~= nil) then
                -- @触发攻击事件
                hevent.trigger(
                    options.sourceUnit,
                    CONST_EVENT.attack,
                    {
                        triggerUnit = options.sourceUnit,
                        targetUnit = options.targetUnit,
                        damage = options.damage,
                        damageType = options.damageType,
                        daozeilianjirate = options.daozeilianjirate
                    }
                )
            end
            -- @触发被攻击事件
            hevent.trigger(
                options.targetUnit,
                CONST_EVENT.beAttack,
                {
                    triggerUnit = options.targetUnit,
                    attackUnit = options.sourceUnit,
                    damageType = options.damageType,
                    damage = options.damage
                }
            )
        end
    end
end

function hskill.getMonitorBuff(whichUnit, isSelf)
    if (whichUnit == nil) then
        err("no unit")
        return {}
    end
    if (isSelf == nil) then
        err("no isSelf")
        return {}
    end
    if (hcache.get(whichUnit, "monitoringBuff") == nil) then
        return {}
    end
    local monitoringBuff = hcache.get(whichUnit, "monitoringBuff")
    if isSelf then
        return monitoringBuff.self
    else
        return monitoringBuff.enemy
    end
end

function hskill.registerMonitoringBuff(whichUnit, key, isSelf)
    if (whichUnit == nil) then
        err("no unit")
        return
    end
    if (isSelf == nil) then
        err("no isSelf")
        return
    end
    if (key == nil) then
        err("no key")
        return
    end
    if (hcache.get(whichUnit, "monitoringBuff") == nil) then
        hcache.set(whichUnit, "monitoringBuff", {self = {}, enemy = {}})
    end
    local monitoringBuff = hcache.get(whichUnit, "monitoringBuff")
    if isSelf then
        table.insert(monitoringBuff.self, key)
    else
        table.insert(monitoringBuff.enemy, key)
    end
end

-- 用一次性计时器和缓存模拟冷却 可用于被动技能冷却
---@param whichUnit userdata which unit
---@param triggerSkill string id
---@param coolDown number
---@return boolean
function hskill.checkAndEnterCD(whichUnit, triggerSkill, coolDown)
    if whichUnit == nil or triggerSkill == nil or coolDown == nil or coolDown <= 0 then
        return
    end
    local timer = hcache.get(whichUnit, CONST_CACHE.SKILL_CD .. triggerSkill)
    if timer ~= nil then
        return false
    end
    hcache.set(
        whichUnit,
        CONST_CACHE.SKILL_CD .. triggerSkill,
        htime.setTimeout(
            coolDown,
            function(curTimer)
                curTimer.destroy()
                hcache.free(whichUnit, CONST_CACHE.SKILL_CD .. triggerSkill)
            end
        )
    )
    return true
end

--- 无敌
---@param whichUnit userdata
---@param during number
---@param effect string
---@param attach string
---@return void
function hskill.invulnerable(whichUnit, during, effect, attach)
    if (whichUnit == nil) then
        return
    end
    if (during < 0) then
        during = 0.00 -- 如果设置持续时间错误，则0秒无敌
    end
    cj.UnitAddAbility(whichUnit, HL_ID.ability_invulnerable)
    if (during > 0 and effect ~= nil) then
        attach = attach or "origin"
        heffect.attach(effect, whichUnit, attach, during)
    end
    htime.setTimeout(
        during,
        function(t)
            t.destroy()
            cj.UnitRemoveAbility(whichUnit, HL_ID.ability_invulnerable)
        end
    )
end
