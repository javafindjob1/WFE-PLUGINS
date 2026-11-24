---被动技能cd类常数
local TONGKUSHU_CD = {}
TONGKUSHU_CD["生命吸取"] = 30

local TONGKUSHU_JINGTONG_XISHU = 10

local function getHunluanzhizhong(whichUnit)
    if whichUnit == nil then
        return 0
    end
    return hcache.get(whichUnit, "HUNLUANZHIZHONG_COUNT", 0)
end

local function addHunluanzhizhong(whichUnit, stack)
    if whichUnit == nil then
        return 0
    end
    local count = hcache.get(whichUnit, "HUNLUANZHIZHONG_COUNT", 0)
    local maxCount = 5

    count = math.min(5, count + stack)

    hcache.set(whichUnit, "HUNLUANZHIZHONG_COUNT", count)
    set_energy_point(hunit.getOwner(whichUnit), count, maxCount, "lvse")
end

local function subHunluanzhizhong(whichUnit, stack)
    if whichUnit == nil then
        return 0
    end
    local linghundaoguanrate = 15
    if hskill.hasActiveAbility(whichUnit, hslk.n2i("逆风收割者")) then
        linghundaoguanrate = 25
    end
    if hskill.hasActiveAbility(whichUnit, hslk.n2i("痛苦之魂")) and math.random(1, 100) <= linghundaoguanrate then
        htextTag.create2Unit(whichUnit, "痛苦之魂", 6, "ff3300", 1, 1, 50)
        return
    end
    local maxCount = 5
    local count = hcache.get(whichUnit, "HUNLUANZHIZHONG_COUNT", 0)
    count = math.max(0, count - stack)
    hcache.set(whichUnit, "HUNLUANZHIZHONG_COUNT", count)
    set_energy_point(hunit.getOwner(whichUnit), count, maxCount, "lvse")
end

local xianji

SKILLS["恐惧"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local x = evtData.targetX
    local y = evtData.targetY
    heffect.xyz("war3mapImported\\AYZN_[AZ].mdx", x, y, hunit.z(evtData.triggerUnit), 0, 1, 1, 1, 1)
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\shadowfury_impact_base.mp3", 1000, true),
        100,
        evtData.triggerUnit
    )
    local damage = hattr.get(sourceUnit, "int", 0) * 2

    hskillMoban.radiusAOE(
        x,
        y,
        sourceUnit,
        300,
        function(filterUnit)
            if hmingwen.isEquipped("恐怖哀嚎", hunit.getOwner(sourceUnit)) then
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = filterUnit,
                        damage = damage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = hslk.n2i("恐惧"),
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK },
                        shanghainame = "恐惧"
                    }
                )
            else
                hbuff.xuanyun(filterUnit, 2)
            end
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "梦魇")
            if points > 0 and math.random(1, 100) <= 20 * points then
                xianji(sourceUnit, filterUnit)
            end
        end,
        false,
        true
    )
end

SKILLS_STOP["恐惧"] = function(evtData)
    if hmingwen.isEquipped("恐怖哀嚎", hunit.getOwner(evtData.triggerUnit)) then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("恐惧"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("恐惧")) - 10)
        )
    end
end

local shengminghongxi = function(sourceUnit, targetUnit, cost)
    hunit.subCurMana(sourceUnit, cost)
    local damageMulti = 0.3
    local life_back = hunit.getMaxLife(sourceUnit) * 0.02
    local duration = 10
    if hmingwen.isEquipped("持久生命汲取", hunit.getOwner(sourceUnit)) then
        duration = duration + 5
    end
    local interval = math.round(2 * 100 / (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)))
    hbuff.update(
        duration,
        targetUnit,
        hslk.n2i("生命虹吸") .. tostring(sourceUnit),
        false,
        nil,
        nil,
        hslk.n2v("生命虹吸", "Art"),
        "生命虹吸：目标在痛苦术士1000范围内每2秒会被吸取生命，造成30%智力的伤害，恢复术士2%最大生命值",
        1,
        interval,
        function(_, buffHandle)
            buffHandle.remainingTime = buffHandle.remainingTime - buffHandle.interval
            if
                hunit.isAlive(sourceUnit) and hunit.isAlive(targetUnit) and
                math.distance(hunit.x(sourceUnit), hunit.y(sourceUnit), hunit.x(targetUnit), hunit.y(targetUnit)) <
                1000
            then
                local damage = math.round(hattr.get(sourceUnit, "int", 0) * damageMulti, 0)
                buffHandle.description = "生命虹吸|n每" .. buffHandle.interval .. "秒造成" .. damage .. "点暗影魔法伤害，并恢复术士2%最大生命值"
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = targetUnit,
                        damage = damage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = hslk.n2i("生命虹吸"),
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK },
                        shanghainame = "生命虹吸"
                    }
                )
                heffect.attach("Abilities\\Spells\\Other\\Drain\\DrainTarget.mdl", targetUnit, "chest", 0.5)
                hskill.heal(
                    {
                        healee = sourceUnit,
                        healer = sourceUnit,
                        heal = life_back,
                        healType = HEAL_TYPE.SKILL,
                        triggerSkill = hslk.n2i("生命虹吸")
                    }
                )
                heffect.attach("Abilities\\Spells\\Other\\Drain\\DrainCaster.mdl", sourceUnit, "chest", 0.5)
            end
        end,
        function(buffhandle)
            buffhandle.remainingTime = duration
            buffhandle.interval = interval
            local damage = math.round(hattr.get(sourceUnit, "int", 0) * damageMulti, 0)
            buffhandle.description = "生命虹吸|n每" .. buffhandle.interval .. "秒造成" .. damage .. "点暗影魔法伤害，并恢复术士2%最大生命值"
        end,
        nil,
        HBUFF_UPDATE_MODE.UPDATE,
        true
    )
end

local function xiexiexianji(sourceUnit, targetUnit)
    local xiexiexianjiPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "邪恶献祭")
    if xiexiexianjiPoints > 0 then
        local damage = hunit.getZhushuxing(sourceUnit) * (xiexiexianjiPoints * 0.4)
        hskillMoban.radiusAOE(
            hunit.x(targetUnit),
            hunit.y(targetUnit),
            sourceUnit,
            300,
            function(unit)
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = unit,
                        damage = damage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = hslk.n2i("邪恶献祭"),
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                        shanghainame = "邪恶献祭",
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK }
                    }
                )
            end,
            false,
            true
        )
        heffect.xyz(
            "Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode.mdl",
            hunit.x(targetUnit),
            hunit.y(targetUnit),
            hunit.z(targetUnit),
            0,
            1
        )
    end
end

xianji = function(sourceUnit, targetUnit)
    local damageMulti = 0.4
    if
        hcache.get(sourceUnit, "[T1]灵力波动套装(3件)", false) or
        hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T1]灵力波动套装")
    then
        damageMulti = damageMulti * 1.2
    end
    local duration = 18
    local basicInterval = 1
    if hbuff.hasBuff(sourceUnit, "无尽诅咒") then
        basicInterval = basicInterval * 0.6
    end
    local interval =
        math.round(basicInterval * 100 / (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)))
    hbuff.update(
        duration,
        targetUnit,
        "痛苦献祭" .. tostring(sourceUnit),
        false,
        nil,
        function()
            if hunit.isDead(targetUnit) then
                xiexiexianji(sourceUnit, targetUnit)
            end
        end,
        hslk.n2v("痛苦献祭", "Art"),
        "痛苦献祭：每秒造成20%智力的伤害，10% 概率获得混乱之种",
        1,
        interval,
        function(_, buffHandle)
            buffHandle.remainingTime = buffHandle.remainingTime - buffHandle.interval
            local damage = math.round(damageMulti * hattr.getWithLimit(sourceUnit, nil, "int", 0), 0)
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "致命献祭")
            if points > 0 and math.random(1, 100) < 4 * points then
                damage = damage * 2
            end
            buffHandle.description = "痛苦献祭|n每" .. buffHandle.interval .. "秒造成" .. damage .. "点火焰魔法伤害"

            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "强化痛苦献祭")
            if points > 0 and math.random(1, 100) < 2 * points then
                hskillMoban.radiusAOE(
                    hunit.x(targetUnit),
                    hunit.y(targetUnit),
                    sourceUnit,
                    300,
                    function(unit)
                        heffect.attach("Abilities\\Spells\\Other\\Incinerate\\IncinerateBuff.mdl", unit, "head", 0.1)
                        hskill.damage(
                            {
                                sourceUnit = sourceUnit,
                                targetUnit = unit,
                                damage = damage,
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.MOFA,
                                triggerSkill = hslk.n2i("痛苦献祭"),
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                shanghainame = "痛苦献祭"
                            }
                        )
                    end,
                    false,
                    true
                )
            else
                heffect.attach("Abilities\\Spells\\Other\\Incinerate\\IncinerateBuff.mdl", targetUnit, "head", 0.1)
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = targetUnit,
                        damage = damage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = hslk.n2i("痛苦献祭"),
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                        shanghainame = "痛苦献祭"
                    }
                )
            end
            if math.random(1, 100) <= 10 then
                addHunluanzhizhong(sourceUnit, 1)
            end
        end,
        function(buffHandle)
            buffHandle.remainingTime = duration
            buffHandle.interval = interval
            local damage = math.round(hattr.get(sourceUnit, "int", 0) * damageMulti, 0)
            buffHandle.description = "痛苦献祭|n每" .. buffHandle.interval .. "秒造成" .. damage .. "点火焰魔法伤害"
        end,
        nil,
        HBUFF_UPDATE_MODE.UPDATE,
        true
    )
end

local fushizhizhongbaozha
local fushishu = function(sourceUnit, targetUnit)
    local basicInterval = 1
    if hmingwen.isEquipped("极速腐蚀术", hunit.getOwner(sourceUnit)) then
        basicInterval = basicInterval * 0.95
    end
    if hbuff.hasBuff(sourceUnit, "无尽诅咒") then
        basicInterval = basicInterval * 0.6
    end
    local interval =
        math.round(basicInterval * 100 / (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)))
    local duration = 18
    local zkds = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "诅咒大师")
    if zkds > 0 then
        duration = duration + zkds
    end
    hbuff.update(
        duration,
        targetUnit,
        "腐蚀术" .. tostring(sourceUnit),
        false,
        nil,
        nil,
        hslk.n2v("腐蚀术", "Art"),
        "腐蚀术|n每秒造成伤害并且可以引爆腐蚀之种。",
        1,
        interval,
        function(curTimer, buffHandle)
            buffHandle.remainingTime = buffHandle.remainingTime - buffHandle.interval
            local damageMulti = 0.3
            if hcache.get(sourceUnit, "[T2]炎灵套装(4件)", false) then
                damageMulti = damageMulti * 1.2
            elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T2]炎灵套装") then
                damageMulti = damageMulti * 1.1
            end
            if hshangcheng.hasItem(hunit.getOwner(sourceUnit), "见习痛苦术") then
                damageMulti = damageMulti * 1.05
            end
            local damage = math.round(hattr.get(sourceUnit, "int", 0) * damageMulti)
            buffHandle.description = "腐蚀术|n每" .. buffHandle.interval .. "秒造成" .. damage .. "点暗影魔法伤害"
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = targetUnit,
                    damage = damage,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.MOFA,
                    triggerSkill = hslk.n2i("腐蚀术"),
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK },
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT
                }
            )
            heffect.attach("[shushi]zuzhou3.mdx", targetUnit, "origin", 0.1)
            if hbuff.hasBuff(targetUnit, "腐蚀之种" .. tostring(sourceUnit)) then
                fushizhizhongbaozha(sourceUnit, targetUnit)
            end

            local shenshi = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "深蚀")
            if shenshi > 0 then
                hbuff.update(
                    6,
                    targetUnit,
                    "深蚀",
                    false,
                    function()
                        hevent.register(
                            targetUnit,
                            CONST_EVENT.damagingCustomTarget,
                            "深蚀",
                            function(evtData)
                                if evtData.damageType == DAMAGE_TYPE.MOFA then
                                    evtData.damage = evtData.damage * (1 + 0.006 * shenshi)
                                end
                            end
                        )
                    end,
                    function()
                        hevent.unregister(targetUnit, CONST_EVENT.damagingCustomTarget, "深蚀")
                    end,
                    hslk.n2v("腐蚀之种", "Art"),
                    "深蚀|n受到的魔法伤害提高" .. tostring(0.6 * shenshi) .. "%",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE
                )
            end
        end,
        function(buffHandle)
            buffHandle.remainingTime = duration
            buffHandle.interval = interval
            local damageMulti = 0.3
            if hcache.get(sourceUnit, "[T2]炎灵套装(4件)", false) then
                damageMulti = damageMulti * 1.2
            elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T2]炎灵套装") then
                damageMulti = damageMulti * 1.1
            end
            if hshangcheng.hasItem(hunit.getOwner(sourceUnit), "见习痛苦术") then
                damageMulti = damageMulti * 1.05
            end
            local damage = math.round(hattr.get(sourceUnit, "int", 0) * damageMulti, 0)
            buffHandle.description = "腐蚀术|n每" .. buffHandle.interval .. "秒造成" .. damage .. "点暗影魔法伤害"
        end,
        nil,
        HBUFF_UPDATE_MODE.UPDATE,
        true
    )
end

local anyingjian = function(sourceUnit, targetUnit, cost)
    hunit.subCurMana(sourceUnit, cost)
    local damage = math.round(hattr.get(sourceUnit, "int", 0), 0)
    hskillMoban.missile(
        {
            model = "war3mapImported\\[Spell]_1111_new.mdl",
            scale = 1,
            speed = 800,
            hover = 100,
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            height = 20,
            target_face_dis = 100,
            onEnd = function()
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = targetUnit,
                        damage = damage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = hslk.n2i("暗影箭"),
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                        shanghainame = "暗影箭",
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK },
                        isAttackReplacement = true
                    }
                )
                if math.random(1, 100) <= 50 then
                    addHunluanzhizhong(sourceUnit, 1)
                end
                local anyingzhiyongPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "暗影之拥")
                if anyingzhiyongPoints > 0 then
                    hbuff.update(
                        2 * anyingzhiyongPoints,
                        sourceUnit,
                        "暗影之拥",
                        true,
                        function()
                            hattribute.set(sourceUnit, 0, { fa_chuan = "+7" })
                        end,
                        function()
                            hattribute.set(sourceUnit, 0, { fa_chuan = "-7" })
                        end,
                        hslk.n2v("暗影箭", "Art"),
                        "暗影之拥：法术穿透提高7%",
                        1,
                        nil,
                        nil,
                        nil,
                        nil,
                        HBUFF_UPDATE_MODE.OVERWRITE
                    )
                end
            end
        }
    )
    local shengminghongxiCD = TONGKUSHU_CD["生命吸取"]
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "鲜血渴望")
    if points > 0 then
        shengminghongxiCD = shengminghongxiCD - 2 * points
    end
    if
        hskill.hasActiveAbility(sourceUnit, hslk.n2i("生命虹吸")) and hunit.getCurMana(sourceUnit) >= 5 and
        htime.setupAndCheckCoolDown(sourceUnit, "生命虹吸", shengminghongxiCD)
    then
        shengminghongxi(sourceUnit, targetUnit, 5)
        return
    end
end

local tongkuzuzhou = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local targetUnit = evtData.targetUnit
    local basicInterval = 2
    if hmingwen.isEquipped("索命诅咒", hunit.getOwner(sourceUnit)) then
        basicInterval = basicInterval - 0.1
    end
    if hbuff.hasBuff(sourceUnit, "无尽诅咒") then
        basicInterval = basicInterval * 0.6
    end
    local interval =
        math.round(basicInterval * 100 / (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)))
    local duration = 18
    if
        hcache.get(sourceUnit, "[T1]灵力波动套装(4件)", false) or
        hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T1]灵力波动套装")
    then
        duration = duration + 3
    end
    local zkds = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "诅咒大师")
    if zkds > 0 then
        duration = duration + zkds
    end
    heffect.attach("war3mapImported\\MS_W.mdx", targetUnit, "overhead", 0.1)
    local maxStack = 8
    if hcache.get(sourceUnit, "[T2]炎灵套装(3件)", false) then
        maxStack = maxStack + 2
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T2]炎灵套装") then
        maxStack = maxStack + 1
    end
    hbuff.update(
        duration,
        targetUnit,
        "痛苦诅咒" .. tostring(sourceUnit),
        false,
        nil,
        nil,
        hslk.n2v("痛苦诅咒", "Art"),
        "痛苦诅咒|n每2秒造成20%智力伤害。每次造成伤害会使得剩下时间内每次伤害提高10%，最多叠加8次。该技能造成伤害时有20%的概率获得一颗灵魂之种",
        1,
        interval,
        function(curTimer, buffHandle)
            buffHandle.remainingTime = buffHandle.remainingTime - buffHandle.interval
            local damageMulti = 0.2 + buffHandle.stack * 0.1
            if hcache.get(sourceUnit, "[T1]灵力波动套装(4件)", false) then
                damageMulti = damageMulti * 1.08
            elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T1]灵力波动套装") then
                damageMulti = damageMulti * 1.04
            end
            local damage = math.round(hattr.get(sourceUnit, "int", 0) * damageMulti, 0)
            buffHandle.description = "痛苦诅咒|n每" .. buffHandle.interval .. "秒造成" .. damage .. "点暗影魔法伤害"
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = targetUnit,
                    damage = damage,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.MOFA,
                    triggerSkill = hslk.n2i("痛苦诅咒"),
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK },
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT
                }
            )
            heffect.attach("war3mapImported\\MS_W.mdx", targetUnit, "head", 0.1)
            local tkhx = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "痛苦回响")
            local hnrate = 20
            if tkhx > 0 then
                hnrate = hnrate + tkhx
            end
            if math.random(1, 100) <= hnrate then
                addHunluanzhizhong(sourceUnit, 1)
            end
            buffHandle.stack = math.min(buffHandle.stack + 1, maxStack)
        end,
        function(buffHandle)
            buffHandle.remainingTime = duration
            buffHandle.interval = interval
            local damageMulti = 0.2 + buffHandle.stack * 0.1
            local damage = math.round(hattr.get(sourceUnit, "int", 0) * damageMulti, 0)
            buffHandle.description = "痛苦诅咒|n每" .. buffHandle.interval .. "秒造成" .. damage .. "点暗影魔法伤害"
        end,
        nil,
        HBUFF_UPDATE_MODE.UPDATE,
        true
    )
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("腐蚀术")) then
        fushishu(sourceUnit, targetUnit)
    end
end

local tongkuwuchang = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local targetUnit = evtData.targetUnit
    if evtData.skipCost ~= true then
        subHunluanzhizhong(sourceUnit, 1)
    end
    local maxStack = 5
    local basicInterval = 1
    if hbuff.hasBuff(sourceUnit, "无尽诅咒") then
        basicInterval = basicInterval * 0.6
    end
    local interval =
        math.round(basicInterval * 100 / (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)))
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\3344.mp3", 1000, true),
        100,
        evtData.targetUnit
    )
    local duration = 12
    hbuff.update(
        duration,
        evtData.targetUnit,
        "痛苦无常" .. tostring(sourceUnit),
        false,
        function()
            hcache.set(
                evtData.targetUnit,
                "痛苦无常" .. tostring(sourceUnit) .. "特效",
                heffect.attach("war3mapImported\\az_shilingyibing.mdx", evtData.targetUnit, "overhead", -1)
            )
        end,
        function()
            heffect.destroy(hcache.get(evtData.targetUnit, "痛苦无常" .. tostring(sourceUnit) .. "特效"))
        end,
        hslk.n2v("痛苦无常", "Art"),
        "痛苦无常|n每秒每层会造成20%智力的伤害，可以叠加，最多叠加" .. maxStack .. "层",
        1,
        interval,
        function(curTimer, buffHandle)
            buffHandle.remainingTime = buffHandle.remainingTime - buffHandle.interval
            local damageMulti = buffHandle.stack * 0.2
            local damage = math.round(hattr.get(sourceUnit, "int", 0) * damageMulti, 0)
            buffHandle.description = "痛苦无常|n每" .. buffHandle.interval .. "秒造成" .. damage .. "点暗影魔法伤害"
            local tmpAttr = {}
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("无常永在")) then
                tmpAttr.fa_bao = "+8"
                tmpAttr.fa_baoshang = "+15"
                if hskill.hasActiveAbility(sourceUnit, hslk.n2i("逆风收割者")) then
                    tmpAttr.fa_bao = "+16"
                    tmpAttr.fa_bao = "+30"
                end
            end
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = targetUnit,
                    damage = damage,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.MOFA,
                    triggerSkill = hslk.n2i("痛苦无常"),
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK },
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                    tmpAttr = tmpAttr
                }
            )
            heffect.attach("[shushi]zuzhou2.mdx", targetUnit, "origin", 0.1)
        end,
        function(buffHandle)
            buffHandle.stack = math.min(buffHandle.stack + 1, maxStack)
            buffHandle.remainingTime = duration
            buffHandle.interval = interval
            local damageMulti = buffHandle.stack * 0.2
            local damage = math.round(hattr.get(sourceUnit, "int", 0) * damageMulti, 0)
            buffHandle.description = "痛苦无常|n每" .. buffHandle.interval .. "秒造成" .. damage .. "点暗影魔法伤害"
        end,
        nil,
        HBUFF_UPDATE_MODE.UPDATE,
        true
    )
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("痛苦献祭")) then
        xianji(sourceUnit, targetUnit)
    end
end

fushizhizhongbaozha = function(sourceUnit, targetUnit)
    hbuff.delete(targetUnit, "腐蚀之种" .. tostring(sourceUnit))
    local baozhadamage = hattr.get(sourceUnit, "int", 0) * 1.3
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "易爆之种")
    if points > 0 then
        baozhadamage = baozhadamage * (1 + 0.05 * points)
    end

    heffect.xyz(
        "[shushi]fushizhizhongbaozha.mdx",
        hunit.x(targetUnit),
        hunit.y(targetUnit),
        hunit.z(targetUnit),
        0,
        1,
        2,
        2,
        2
    )
    hskillMoban.radiusAOE(
        hunit.x(targetUnit),
        hunit.y(targetUnit),
        sourceUnit,
        300,
        function(unit)
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = unit,
                    damage = baozhadamage,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.MOFA,
                    triggerSkill = hslk.n2i("腐蚀之种"),
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                    shanghainame = "腐蚀之种",
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK }
                }
            )
            fushishu(sourceUnit, unit)
            if hbuff.hasBuff(unit, "腐蚀之种" .. tostring(sourceUnit)) then
                fushizhizhongbaozha(sourceUnit, unit)
            end
        end,
        false,
        true
    )
end

local fushizhizhong = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local targetUnit = evtData.targetUnit
    local x = hunit.x(targetUnit)
    local y = hunit.y(targetUnit)
    subHunluanzhizhong(sourceUnit, 2)
    local units = hgroup.createEnermyGroupByXY(sourceUnit, x, y, 300)
    local unitsWithouTarget = {}
    for _, unit in ipairs(units) do
        if unit ~= targetUnit then
            table.insert(unitsWithouTarget, unit)
        end
    end
    local num = 3
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "腐蚀传染")
    if points > 0 and math.random(1, 100) <= 10 * points then
        num = num + 2
    end
    local selected = table.random(unitsWithouTarget, num - 1)
    table.insert(selected, targetUnit)
    for _, targetUnit in ipairs(selected) do
        hskillMoban.missile(
            {
                model = "[shushi]fushizhizhong.mdl",
                scale = 1,
                speed = 900,
                hover = 100,
                sourceUnit = sourceUnit,
                targetUnit = targetUnit,
                target_face_dis = 10,
                onEnd = function()
                    hbuff.update(
                        10,
                        targetUnit,
                        "腐蚀之种" .. tostring(sourceUnit),
                        false,
                        function()
                        end,
                        function()
                        end,
                        hslk.n2v("腐蚀之种", "Art"),
                        "腐蚀之种|n受到腐蚀之种爆炸或者腐蚀术伤害会爆炸，对周围300码单位造成一次暗影魔法伤害",
                        1,
                        nil,
                        nil,
                        nil,
                        nil,
                        HBUFF_UPDATE_MODE.OVERWRITE,
                        true
                    )
                end
            }
        )
    end
end

local heiyanzuzhou = function(sourceUnit, targetUnit)
    local damageMulti = 0.2
    if hbuff.hasBuff(targetUnit, "腐蚀术" .. tostring(sourceUnit)) then
        damageMulti = damageMulti + 0.05
    end
    if hbuff.hasBuff(targetUnit, "痛苦无常" .. tostring(sourceUnit)) then
        damageMulti = damageMulti + 0.05
    end
    if hbuff.hasBuff(targetUnit, "痛苦诅咒" .. tostring(sourceUnit)) then
        damageMulti = damageMulti + 0.05
    end
    if hbuff.hasBuff(targetUnit, "痛苦献祭" .. tostring(sourceUnit)) then
        damageMulti = damageMulti + 0.05
    end
    if hbuff.hasBuff(targetUnit, "生命虹吸" .. tostring(sourceUnit)) then
        damageMulti = damageMulti + 0.05
    end
    local damage = hattr.get(sourceUnit, "int", 0) * damageMulti
    if hcache.get(sourceUnit, "[T3]高阶法师套装(3件)", false) then
        damage = damage * 1.1
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T3]高阶法师套装") then
        damage = damage * 1.05
    end
    if hcache.get(sourceUnit, "[T3]高阶法师套装(4件)", false) and math.random(1, 100) <= 10 then
        addHunluanzhizhong(sourceUnit, 1)
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T3]高阶法师套装") and math.random(1, 100) <= 5 then
        addHunluanzhizhong(sourceUnit, 1)
    end
    hskill.damage(
        {
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            damage = damage,
            damageSrc = CONST_DAMAGE_SRC.skill,
            damageType = DAMAGE_TYPE.MOFA,
            triggerSkill = hslk.n2i("黑眼射线"),
            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
            shanghainame = "黑眼射线",
            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK }
        }
    )
end

SKILLS["无尽诅咒"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    heffect.attach("war3mapImported\\FX_Enery_purple_002.mdx", sourceUnit, "origin", 12)
    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\9001.mp3", 1000, true), 100, sourceUnit)
    hbuff.update(
        12,
        sourceUnit,
        "无尽诅咒",
        true,
        function()
        end,
        function()
        end,
        hslk.n2v("无尽诅咒", "Art"),
        "无尽诅咒|n 该状态痛苦术士的技能基础伤害间隔降低40%",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE
    )
    local tongkukuangchaoPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "痛苦狂潮")
    if tongkukuangchaoPoints > 0 then
        hskillMoban.radiusAOE(
            hunit.x(sourceUnit),
            hunit.y(sourceUnit),
            sourceUnit,
            800,
            function(unit)
                for i = 1, tongkukuangchaoPoints do
                    tongkuwuchang({ triggerUnit = sourceUnit, targetUnit = unit, skipCost = true })
                end
            end,
            false,
            true)
    end
end

SKILLS["痛苦诅咒"] = function(evtData)
    tongkuzuzhou(evtData)
end

SKILL_ON_LEVEL_UP["痛苦术"] = function(whichUnit)
    local xiezhou = hslk.n2i("邪咒")
    if hskill.hasActiveAbility(whichUnit, xiezhou) then
        hskillMoban.guanghuan(whichUnit, xiezhou, 2000, hslk.i2v(xiezhou, "_guanghuanAttr"), true, true, "增加友军5%的技能加速")
    end
end

SKILL_SETUP["痛苦术"] = function(whichUnit)
    --基础回蓝1
    hattribute.set(whichUnit, 0, { mana_back = "=1" })
    hskill.registerAutoCast(whichUnit, hslk.n2i("痛苦诅咒"))
    hskill.registerAutoCast(whichUnit, hslk.n2i("痛苦无常"))
    hskill.registerAutoCast(whichUnit, hslk.n2i("灾难狂欢"))
    hskill.registerAutoCast(whichUnit, hslk.n2i("腐蚀之种"))

    hskill.registerMonitoringBuff(whichUnit, "无尽诅咒", true)
    hskill.registerMonitoringBuff(whichUnit, "痛苦诅咒" .. tostring(whichUnit), false)
    hskill.registerMonitoringBuff(whichUnit, "腐蚀术" .. tostring(whichUnit), false)
    hskill.registerMonitoringBuff(whichUnit, "痛苦无常" .. tostring(whichUnit), false)
    hskill.registerMonitoringBuff(whichUnit, "痛苦献祭" .. tostring(whichUnit), false)

    hskill.setup_zhudong_jineng(
        whichUnit,
        hslk.n2i("痛苦无常"),
        tongkuwuchang,
        function(sourceUnit, targetUnit)
            local shifashijian = 1.5
            return shifashijian
        end,
        function(checkUnit)
            if getHunluanzhizhong(checkUnit) < 1 then
                echo("没有足够的灵魂之种", hunit.getOwner(checkUnit))
                return false
            end
            if hunit.getCurMana(checkUnit) < 5 then
                echo("魔法值不足以释放痛苦无常", hunit.getOwner(checkUnit))
                return false
            end
            return true
        end,
        "resource\\war3mapImported\\sound\\fire_casting.wav",
        nil,
        nil,
        function()
            hunit.subCurMana(whichUnit, 5)
            hcache.set(
                whichUnit,
                "hlzjlefthandtexiao",
                heffect.attach("war3mapImported\\[Spell]_117_new_p.mdx", whichUnit, "hand left", 3)
            )
            hcache.set(
                whichUnit,
                "hlzjrighthandtexiao",
                heffect.attach("war3mapImported\\[Spell]_117_new_p.mdx", whichUnit, "hand right", 3)
            )
        end,
        function()
            heffect.destroy(hcache.get(whichUnit, "hlzjlefthandtexiao"))
            heffect.destroy(hcache.get(whichUnit, "hlzjrighthandtexiao"))
        end,
        nil,
        nil,
        true,
        true
    )
    hskill.setup_zhudong_jineng(
        whichUnit,
        hslk.n2i("腐蚀之种"),
        fushizhizhong,
        function(sourceUnit, targetUnit)
            local shifashijian = 2
            return shifashijian
        end,
        function(checkUnit)
            if getHunluanzhizhong(checkUnit) < 2 then
                echo("没有足够的灵魂之种", hunit.getOwner(checkUnit))
                return false
            end
            if hunit.getCurMana(checkUnit) < 7 then
                echo("魔法值不足以释放腐蚀之种", hunit.getOwner(checkUnit))
                return false
            end
            return true
        end,
        "resource\\war3mapImported\\sound\\fire_casting.wav",
        nil,
        nil,
        function()
            hunit.subCurMana(whichUnit, 7)
            hcache.set(
                whichUnit,
                "hlzjlefthandtexiao",
                heffect.attach("war3mapImported\\[Spell]_117_new_p.mdx", whichUnit, "hand left", 3)
            )
            hcache.set(
                whichUnit,
                "hlzjrighthandtexiao",
                heffect.attach("war3mapImported\\[Spell]_117_new_p.mdx", whichUnit, "hand right", 3)
            )
        end,
        function()
            heffect.destroy(hcache.get(whichUnit, "hlzjlefthandtexiao"))
            heffect.destroy(hcache.get(whichUnit, "hlzjrighthandtexiao"))
        end,
        nil,
        nil,
        true,
        true
    )
    hskill.setup_zhudong_jineng(
        whichUnit,
        hslk.n2i("灾难狂欢"),
        function()
        end,
        function(sourceUnit, targetUnit)
            local shifashijian = 30
            return shifashijian
        end,
        function(checkUnit)
            return getHunluanzhizhong(checkUnit) >= 1
        end,
        "resource\\war3mapImported\\sound\\fire_casting.wav",
        function(whichUnit, targetUnit)
            local interval = 1
            return interval
        end,
        function(whichUnit, targetUnit)
            subHunluanzhizhong(whichUnit, 1)
            if getHunluanzhizhong(whichUnit) < 1 then
                cj.IssueImmediateOrder(whichUnit, "stop")
                return
            end
            hlightning.unit2unit(hlightning.type.fa_li_ran_shao, whichUnit, targetUnit, 1)
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("黑眼射线")) then
                heiyanzuzhou(whichUnit, targetUnit)
            end
        end,
        function(whichUnit, targetUnit)
            hlightning.unit2unit(hlightning.type.fa_li_ran_shao, whichUnit, targetUnit, 1)
            hbuff.update(
                -1,
                targetUnit,
                "灾难狂欢" .. tostring(whichUnit),
                false,
                function()
                end,
                function()
                end,
                hslk.n2v("灾难狂欢", "Art"),
                "desc",
                1,
                nil,
                nil,
                nil,
                nil,
                HBUFF_UPDATE_MODE.OVERWRITE,
                true
            )
            hcache.set(
                whichUnit,
                "hlzjlefthandtexiao",
                heffect.attach("war3mapImported\\[Spell]_117_new_p.mdx", whichUnit, "hand left", 3)
            )
            hcache.set(
                whichUnit,
                "hlzjrighthandtexiao",
                heffect.attach("war3mapImported\\[Spell]_117_new_p.mdx", whichUnit, "hand right", 3)
            )
        end,
        function(whichUnit, targetUnit)
            hbuff.delete(targetUnit, "灾难狂欢" .. tostring(whichUnit))
            heffect.destroy(hcache.get(whichUnit, "hlzjlefthandtexiao"))
            heffect.destroy(hcache.get(whichUnit, "hlzjrighthandtexiao"))
        end,
        true,
        nil,
        true,
        true
    )

    hevent.register(
        whichUnit,
        CONST_EVENT.damagingCustomSource,
        "hunluannengliang",
        function(evtData)
            if evtData.sourceUnit ~= whichUnit then
                err("Incorrect unit")
                return
            end
            if
                hskill.hasActiveAbility(whichUnit, hslk.n2i("痛苦之源")) and
                evtData.damageSpeedType == CONST_DAMAGE_SPEED_TYPE.DOT
            then
                local jingtong = hattribute.getWithLimit(whichUnit, nil, "master", 0)
                local zengshang = jingtong / TONGKUSHU_JINGTONG_XISHU + 10
                if hbuff.hasBuff(whichUnit, "无尽诅咒") and hmingwen.isEquipped("强化无尽诅咒", hunit.getOwner(whichUnit)) then
                    zengshang = zengshang * 2
                end
                evtData.damage = evtData.damage * (1 + zengshang / 100)
            end
            local buffHandle = hbuff.getBuffHandle(evtData.targetUnit, "痛苦无常" .. tostring(whichUnit))
            if
                buffHandle and evtData.damageSpeedType == CONST_DAMAGE_SPEED_TYPE.DOT and
                hskill.hasActiveAbility(whichUnit, hslk.n2i("鬼影缠身"))
            then
                local stack = buffHandle.stack or 0
                evtData.damage = evtData.damage * (1 + stack * 0.02)
            end

            local buffHandle = hbuff.getBuffHandle(evtData.targetUnit, "灾难狂欢" .. tostring(whichUnit))
            if buffHandle and evtData.damageSpeedType == CONST_DAMAGE_SPEED_TYPE.DOT then
                evtData.damage = evtData.damage * 1.6
            end
        end
    )

    -- 痛苦术攻击
    hevent.register(
        whichUnit,
        CONST_EVENT.beforeAttackDamage,
        "tongkushu_attack",
        function(evtData)
            evtData.damage = 0
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("暗影箭")) and hunit.getCurMana(whichUnit) >= 2 then
                anyingjian(whichUnit, evtData.targetUnit, 2)
                return
            end
            hunit.animate(whichUnit, "stand")
            if hskill.checkAndEnterCD(whichUnit, "no_mana_hint", 5) then
                echo("魔法不够释放任何技能", hunit.getOwner(whichUnit))
            end
        end
    )
end
