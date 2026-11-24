local KUANGBAOZHAN_JINGTONG_XISHU = 15

---被动技能cd类常数
local KUANGBAOZHAN_CD = {}
KUANGBAOZHAN_CD[hslk.n2i("旋风斩")] = 8
KUANGBAOZHAN_CD[hslk.n2i("狂暴劈砍")] = 5
KUANGBAOZHAN_CD[hslk.n2i("顺劈斩")] = 12
KUANGBAOZHAN_CD[hslk.n2i("嗜血")] = 10

-- 重伤
local function zhongshang(triggerUnit, targetUnit, triggerSkill)
    if targetUnit == nil or triggerUnit == nil then
        return
    end
    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\silie.wav", 1000, true), 100, targetUnit)
    local damage = hattribute.getWithLimit(triggerUnit, nil, "attack", 0) * 0.48
    heffect.xyz(
        "war3mapImported\\AZ_D033_1.mdx",
        hunit.x(targetUnit),
        hunit.y(targetUnit),
        hunit.z(targetUnit),
        0,
        0.9,
        nil,
        nil,
        nil,
        nil,
        nil,
        math.angle(hunit.x(triggerUnit), hunit.y(triggerUnit), hunit.x(targetUnit), hunit.y(targetUnit)) - 90
    )
    hbuff.update(
        6,
        targetUnit,
        hslk.n2i("狂暴战重伤") .. "|" .. tostring(triggerUnit),
        false,
        function()
        end,
        function()
        end,
        hslk.i2v(hslk.n2i("狂暴战重伤"), "Art"),
        "重伤流血每秒造成" .. tostring(math.floor(damage / 6.0) .. "点伤害"),
        1,
        1,
        function(_, buffHandle)
            if buffHandle == nil or buffHandle.extraBuffData == nil or buffHandle.extraBuffData.damage == nil then
                return
            end
            local cur_damage = buffHandle.extraBuffData.damage / buffHandle.remainingTime
            if cur_damage < 0.125 then
                buffHandle.remainingTime = 0
                return
            end
            hskill.damage(
                {
                    sourceUnit = triggerUnit,
                    targetUnit = targetUnit,
                    damage = cur_damage,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.WULI,
                    triggerSkill = triggerSkill,
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
                }
            )
            heffect.attach("war3mapImported\\AZ_gelie.mdx", targetUnit, "chest", 0)
            buffHandle.remainingTime = buffHandle.remainingTime - 1
            buffHandle.extraBuffData.damage = buffHandle.extraBuffData.damage - cur_damage
        end,
        function(buffHandle)
            if buffHandle == nil or buffHandle.extraBuffData == nil or buffHandle.extraBuffData.damage == nil then
                return
            end
            buffHandle.remainingTime = 6
            buffHandle.extraBuffData.damage = buffHandle.extraBuffData.damage + damage
            buffHandle.description = "重伤造成每秒" .. tostring(math.floor(buffHandle.extraBuffData.damage / 6.0) .. "点伤害")
        end,
        {
            damage = damage
        },
        HBUFF_UPDATE_MODE.UPDATE
    )
end

local function kuangbaopikan(sourceUnit, targetUnit, skillID)
    htime.setTimeout(
        0.05,
        function(_)
            hbuff.addStackAttrBuff(
                CONST_DAMAGE_SRC.skill,
                sourceUnit,
                skillID,
                { attack_speed = "+5" },
                15,
                3,
                hslk.i2v(skillID, "Art"),
                "狂暴劈砍|n每层增加攻速5%"
            )
            hsound.voice2Unit(
                hsound.voiceCreate("resource\\war3mapImported\\sound\\yingyongdaji.wav", 1000, true),
                90,
                targetUnit
            )
            heffect.xyz(
                "war3mapImported\\AZ_DG010.MDX",
                hunit.x(sourceUnit),
                hunit.y(sourceUnit),
                hunit.z(sourceUnit),
                0,
                1,
                nil,
                nil,
                nil,
                nil,
                nil,
                math.angle(hunit.x(sourceUnit), hunit.y(sourceUnit), hunit.x(targetUnit), hunit.y(targetUnit))
            )
            hunit.addCurMana(sourceUnit, 5)
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = targetUnit,
                    damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0),
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.WULI,
                    triggerSkill = skillID,
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
                }
            )
        end
    )
end

local siwangzhiyuan
local function nuji(sourceUnit, targetUnit, skillID)
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "不羁狂野")
    if
        points > 0 and hbuff.hasBuff(sourceUnit, "死亡之愿") == false and math.random(1, 100) <= points * 2 and
        htime.setupAndCheckCoolDown(sourceUnit, "不羁狂野", 10)
    then
        siwangzhiyuan(sourceUnit, 5)
    end

    hunit.addCurMana(sourceUnit, 10)
    local tmpAttr = {}
    local damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0)
    if hmingwen.isEquipped("狂暴怒击", hunit.getOwner(sourceUnit)) then
        tmpAttr["wu_bao"] = "+10"
        damage = damage * 1.2
    end
    if hshangcheng.hasItem(hunit.getOwner(sourceUnit), "见习狂暴战") then
        damage = damage * 1.05
    end
    local enermies = {}
    local range = 300
    if hmingwen.isEquipped("巨力挥舞", hunit.getOwner(sourceUnit)) then
        range = range + 50
    end

    if hbuff.hasBuff(sourceUnit, "旋风斩增益") then
        hbuff.removeStack(sourceUnit, "旋风斩增益", 1)
        enermies =
            hgroup.createByUnit(
                sourceUnit,
                range,
                function(filterUnit)
                    if
                        hunit.isAlly(sourceUnit, filterUnit) or hunit.isDead(filterUnit) or hunit.isDead(sourceUnit) or
                        hunit.isDestroyed(filterUnit) or
                        hunit.isDestroyed(sourceUnit) or
                        filterUnit == targetUnit
                    then
                        return false
                    else
                        return true
                    end
                end
            )
    end
    table.insert(enermies, targetUnit)

    for _, enermy in ipairs(enermies) do
        heffect.attach("war3mapImported\\[spell]az_baodian_heihong.mdx", enermy, "chest", 0)
        hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\mengji.wav", 500, true), 90, enermy)
        hskill.damage(
            {
                sourceUnit = sourceUnit,
                targetUnit = enermy,
                damage = damage,
                damageSrc = CONST_DAMAGE_SRC.skill,
                damageType = DAMAGE_TYPE.WULI,
                triggerSkill = skillID,
                tmpAttr = tmpAttr,
                damageElementType = CONST_DAMAGE_ELEMENT_TYPE.METAL,
                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
            }
        )
        hskill.damage(
            {
                sourceUnit = sourceUnit,
                targetUnit = enermy,
                damage = damage,
                damageSrc = CONST_DAMAGE_SRC.skill,
                damageType = DAMAGE_TYPE.WULI,
                triggerSkill = skillID,
                tmpAttr = tmpAttr,
                damageElementType = CONST_DAMAGE_ELEMENT_TYPE.METAL,
                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
            }
        )
        if hmingwen.isEquipped("精准怒击", hunit.getOwner(sourceUnit)) then
            hbuff.xuanyun(enermy, 0.1)
        end
        heffect.xyz(
            "war3mapImported\\[Spell]_133.MDX",
            hunit.x(sourceUnit),
            hunit.y(sourceUnit),
            hunit.z(sourceUnit),
            0,
            1,
            nil,
            nil,
            nil,
            nil,
            nil,
            math.angle(hunit.x(sourceUnit), hunit.y(sourceUnit), hunit.x(enermy), hunit.y(enermy))
        )

        heffect.attach("war3mapImported\\AZ_hit1.mdx", enermy, "chest", 0)
    end
    local shuaxinrate = 15
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "怒击专精")
    if points > 0 then
        shuaxinrate = shuaxinrate + points
    end
    if hcache.get(sourceUnit, "[T3]无畏战将套装(4件)", false) then
        shuaxinrate = shuaxinrate + 5
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T3]无畏战将套装") then
        shuaxinrate = shuaxinrate + 3
    end
    if math.random(1, 100) <= shuaxinrate then
        hskill.setCoolDown(sourceUnit, c2i(skillID), 0)
    end
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "怒冲云霄")
    if points > 0 then
        hbuff.addStackAttrBuff(
            CONST_DAMAGE_SRC.skill,
            sourceUnit,
            "怒冲云霄",
            {},
            15,
            5,
            hslk.i2v(skillID, "Art"),
            "怒冲云霄|n每层使暴怒伤害提高" .. tostring(points * 3) .. "%"
        )
    end
end

SKILLS["怒击"] = function(evtData)
    hunit.setAnimateSpeed(evtData.triggerUnit, 2, 0.2)
    hunit.animate(evtData.triggerUnit, "attack slam")
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\nuji_cast.wav", 1000, true),
        90,
        evtData.triggerUnit
    )
    htime.setTimeout(
        0.15,
        function(curTimer)
            curTimer.destroy()
            local sourceUnit = evtData.triggerUnit
            local targetUnit = evtData.targetUnit
            local skillID = hslk.n2i("怒击")
            nuji(sourceUnit, targetUnit, skillID)
        end
    )
end

local function jinu(sourceUnit, skillID)
    local jingtong = hattribute.getWithLimit(sourceUnit, nil, "master", 0)
    local zengshang = 15 + (jingtong / KUANGBAOZHAN_JINGTONG_XISHU)
    local speed = 40
    hbuff.update(
        4,
        sourceUnit,
        "激怒",
        true,
        function()
            --TODO 激怒特效（音效待定）
            hattribute.set(sourceUnit, 0, { jinu_zengshang = "+" .. tostring(zengshang), move = "+" .. tostring(speed) })
        end,
        function()
            hattribute.set(sourceUnit, 0, { jinu_zengshang = "-" .. tostring(zengshang), move = "-" .. tostring(speed) })
        end,
        hslk.i2v(skillID, "Art"),
        "激怒|n物理暴击使得移动速度提升40 伤害提高" .. string.format("%.1f", zengshang) .. "%",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE
    )
end

local function julongnuhou(sourceUnit)
    local damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * 4
    local tmpAttr = _attr({ wu_bao = "+100" })
    heffect.xyz("war3mapImported\\AZ_longpaoxiao.mdx", hunit.x(sourceUnit), hunit.y(sourceUnit), hunit.z(sourceUnit), 0,
        1)
    htime.setTimeout(0.28, function()
        hskillMoban.radiusAOE(
            hunit.x(sourceUnit),
            hunit.y(sourceUnit),
            sourceUnit,
            400,
            function(target)
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = target,
                        damage = damage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.WULI,
                        triggerSkill = hslk.n2i("巨龙怒吼"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                        tmpAttr = tmpAttr
                    }
                )
            end,
            false,
            true
        )
    end)
end

SKILLS["暴怒"] = function(evtData)
    jinu(evtData.triggerUnit, hslk.n2i("激怒"))
    local numAttack = 3
    if hbuff.hasBuff(evtData.triggerUnit, hslk.n2i("乱舞")) then
        numAttack = numAttack + 1
    end
    local animateSpeed = numAttack + 1
    local interval = 0.7 / numAttack
    local damageMultiplier = 1.5

    if hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("巨龙怒吼")) and htime.setupAndCheckCoolDown(evtData.triggerUnit, "巨龙怒吼", 20) then
        julongnuhou(evtData.triggerUnit)
    end


    if hbuff.hasBuff(evtData.triggerUnit, "怒冲云霄") then
        local buffHandle = hbuff.getBuffHandle(evtData.triggerUnit, "怒冲云霄")
        local stack = buffHandle.stack or 0
        local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "怒冲云霄")
        damageMultiplier = damageMultiplier * (1 + 0.03 * stack * points)
        hbuff.delete(evtData.triggerUnit, "怒冲云霄")
    end

    local range = 300
    if hmingwen.isEquipped("巨力挥舞", hunit.getOwner(evtData.triggerUnit)) then
        range = range + 50
    end

    local enermies = {}
    if hbuff.hasBuff(evtData.triggerUnit, "旋风斩增益") then
        hbuff.removeStack(evtData.triggerUnit, "旋风斩增益", 1)
        enermies =
            hgroup.createByUnit(
                evtData.triggerUnit,
                range,
                function(filterUnit)
                    if
                        hunit.isAlly(evtData.triggerUnit, filterUnit) or hunit.isDead(filterUnit) or
                        hunit.isDead(evtData.triggerUnit) or
                        hunit.isDestroyed(filterUnit) or
                        hunit.isDestroyed(evtData.triggerUnit) or
                        filterUnit == evtData.targetUnit
                    then
                        return false
                    else
                        return true
                    end
                end
            )
    end
    table.insert(enermies, evtData.targetUnit)

    hunit.setAnimateSpeed(evtData.triggerUnit, animateSpeed, interval)
    hunit.animate(evtData.triggerUnit, "attack")

    for _, enermy in ipairs(enermies) do
        hskill.damage(
            {
                sourceUnit = evtData.triggerUnit,
                targetUnit = enermy,
                damage = hattribute.getWithLimit(evtData.triggerUnit, nil, "attack", 0) * damageMultiplier,
                damageSrc = CONST_DAMAGE_SRC.skill,
                damageType = DAMAGE_TYPE.WULI,
                triggerSkill = hslk.n2i("暴怒"),
                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
            }
        )
        heffect.attach("war3mapImported\\[spell]az_baodian_heihong.mdx", enermy, "chest", 0)
        hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\mengji.wav", 500, true), 90, enermy)
    end

    numAttack = numAttack - 1
    htime.setInterval(
        interval,
        function(curTimer)
            numAttack = numAttack - 1
            hunit.setAnimateSpeed(evtData.triggerUnit, animateSpeed, interval)
            hunit.animate(evtData.triggerUnit, "attack")
            for _, enermy in ipairs(enermies) do
                hskill.damage(
                    {
                        sourceUnit = evtData.triggerUnit,
                        targetUnit = enermy,
                        damage = hattribute.getWithLimit(evtData.triggerUnit, nil, "attack") * damageMultiplier,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.WULI,
                        triggerSkill = hslk.n2i("暴怒"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
                    }
                )
                heffect.attach("war3mapImported\\[spell]az_baodian_heihong.mdx", enermy, "chest", 0)
                hsound.voice2Unit(
                    hsound.voiceCreate("resource\\war3mapImported\\sound\\mengji.wav", 500, true),
                    90,
                    enermy
                )
            end
            if numAttack <= 0 then
                curTimer.destroy()
            end
        end
    )
end


SKILLS_STOP["暴怒"] = function(evtData)
    local whichUnit = evtData.triggerUnit
    if hskill.hasActiveAbility(whichUnit, hslk.n2i("暴怒")) then
        local leftHandItem = hplayer.dzCunDang[hunit.getOwner(whichUnit)].getEquipment(EQUIPMENT_SLOT_ID.zhushou)
        local rightHandItem = hplayer.dzCunDang[hunit.getOwner(whichUnit)].getEquipment(EQUIPMENT_SLOT_ID.fushou)
        if leftHandItem and rightHandItem and hitem.isShuangShouWuqi(leftHandItem) == false and hitem.isShuangShouWuqi(rightHandItem) == false then
            if hmingwen.isEquipped("极速毁灭", hunit.getOwner(whichUnit)) then
                hskill.setCoolDown(
                    whichUnit,
                    hslk.n2i("暴怒"),
                    math.max(0, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("暴怒")) - 5)
                )
            end
        end
    end
end


local function xuanfenzhan(sourceUnit, targetUnit, skillID)
    local damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * 0.8
    if hcache.get(sourceUnit, "[T2]熔铸勇士套装(4件)", false) then
        damage = damage * 2
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T2]熔铸勇士套装") then
        damage = damage * 1.5
    end

    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "强化旋风斩")
    if points > 0 then
        damage = damage * (1 + 0.1 * points)
    end

    local range = 300

    if hmingwen.isEquipped("巨力挥舞", hunit.getOwner(sourceUnit)) then
        range = range + 50
    end

    hunit.addCurMana(sourceUnit, 5)

    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\xuanfengzhan.wav", 1000, true),
        90,
        sourceUnit
    )
    heffect.xyz(
        "war3mapImported\\AZ_JUGG_F1.MDX",
        hunit.x(sourceUnit),
        hunit.y(sourceUnit),
        hunit.z(sourceUnit) - 50,
        0,
        1
    )
    hskillMoban.radiusAOE(
        hunit.x(sourceUnit),
        hunit.y(sourceUnit),
        sourceUnit,
        300,
        function(target)
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = target,
                    damage = damage,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.WULI,
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                    triggerSkill = hslk.n2i("旋风斩")
                }
            )
            heffect.attach("war3mapImported\\AZ_hit1.mdx", target, "origin", 0)
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "破甲风暴")
            if points > 0 then
                hbuff.update(
                    6,
                    target,
                    "破甲风暴",
                    false,
                    function()
                        hevent.register(
                            target,
                            CONST_EVENT.damagingCustomTarget,
                            "破甲风暴",
                            function(evtData)
                                if evtData.damageType == DAMAGE_TYPE.WULI then
                                    evtData.damage = evtData.damage * (1 + 0.006 * points)
                                end
                            end
                        )
                    end,
                    function()
                        hevent.unregister(target, CONST_EVENT.damagingCustomTarget, "破甲风暴")
                    end,
                    hslk.n2v("旋风斩", "Art"),
                    "破甲风暴|n受到的物理伤害提高" .. tostring(points) .. "%",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE
                )
            end
        end,
        false,
        true
    )

    local stack = 2
    if hcache.get(sourceUnit, "[T3]无畏战将套装(3件)", false) or hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T3]无畏战将套装") then
        stack = stack + 1
    end
    hbuff.update(
        10,
        sourceUnit,
        "旋风斩增益",
        true,
        nil,
        nil,
        hslk.n2v("旋风斩", "Art"),
        "暴怒和怒击能伤害周围所有单位",
        stack,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE
    )

    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "破坏者")
    if points > 0 and htime.setupAndCheckCoolDown(sourceUnit, "破坏者", 9) then
        local newX, newY = hunit.x(targetUnit), hunit.y(targetUnit)
        local e = heffect.xyz("war3mapImported\\[zhanshi]pohuaizhe.mdx", newX, newY, hunit.z(sourceUnit) + 50, 6, 1)
        local damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * points * 0.12
        local duration = 6
        local interval = 1.5

        htime.setInterval(interval, function(t)
            if t.passedSec() > duration then
                heffect.destroy(e)
                t.destroy()
                return
            end

            hskillMoban.radiusAOE(
                newX,
                newY,
                sourceUnit,
                300,
                function(u)
                    hskill.damage({
                        sourceUnit = sourceUnit,
                        targetUnit = u,
                        damage = damage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.WULI,
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                        triggerSkill = hslk.n2i("装备技能"),
                        shanghainame = "破坏者"
                    })
                end,
                false,
                true
            )
        end)
    end
end

local function yingyongdaji(sourceUnit, targetUnit, skillID)
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "怒不可遏")
    if points > 0 and hskill.getCoolDown(sourceUnit, hslk.n2i("暴怒")) > 0 then
        hskill.setCoolDown(
            sourceUnit,
            hslk.n2i("暴怒"),
            math.max(0, hskill.getCoolDown(sourceUnit, hslk.n2i("暴怒")) - 0.05 * points)
        )
    end
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "强化怒不可遏")
    if points > 0 then
        htime.reduceCoolDown(sourceUnit, "巨龙怒吼", points * 0.05 + 0.01)
    end

    local manaCost = 20
    if hmingwen.isEquipped("节能英勇打击", hunit.getOwner(sourceUnit)) then
        manaCost = manaCost - 1
    end
    if
        hcache.get(sourceUnit, "[T1]无畏勇士套装(3件)", false) or
        hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T1]无畏勇士套装")
    then
        manaCost = manaCost - 1
    end
    local damageMultiplier = 1.2
    if hmingwen.isEquipped("势大力沉", hunit.getOwner(sourceUnit)) then
        damageMultiplier = damageMultiplier + 0.4
        manaCost = manaCost + 5
    end
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "强化英勇打击")
    if points > 0 then
        damageMultiplier = damageMultiplier * (1 + 0.03 * points)
    end
    local damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * damageMultiplier
    if hcache.get(sourceUnit, "[T1]无畏勇士套装(4件)", false) then
        damage = damage * 1.1
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T1]无畏勇士套装") then
        damage = damage * 1.05
    end
    hunit.subCurMana(sourceUnit, manaCost)
    hskill.damage(
        {
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            damage = damage,
            damageSrc = CONST_DAMAGE_SRC.skill,
            damageType = DAMAGE_TYPE.WULI,
            triggerSkill = skillID,
            isAttackReplacement = true,
            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
        }
    )
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\yingyongdaji.wav", 1000, true),
        100,
        targetUnit
    )
    heffect.attach("war3mapImported\\AZ_hit1.mdx", targetUnit, "chest", 0)
end

SKILLS["英勇打击"] = function(evtData)
    local status = hcache.get(evtData.triggerUnit, "yydj_zhuangtai", nil)
    if status == nil or status == 2 then
        hcache.set(evtData.triggerUnit, "yydj_zhuangtai", 1)
        echo("英勇打击激活，怒气大于70自动释放。", hunit.getOwner(evtData.triggerUnit))
        hbuff.update(
            nil,
            evtData.triggerUnit,
            "英勇打击",
            true,
            nil,
            nil,
            hslk.n2v("英勇打击", "Art"),
            "英勇打击激活，怒气大于70自动释放。",
            nil,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE
        )
    else
        hcache.set(evtData.triggerUnit, "yydj_zhuangtai", 2)
        hbuff.delete(evtData.triggerUnit, "英勇打击")
        echo("关闭英勇打击，不会自动释放。", hunit.getOwner(evtData.triggerUnit))
    end
end

local function shixue(sourceUnit, targetUnit, skillID)
    htime.setTimeout(
        0.1,
        function(_)
            hunit.addCurMana(sourceUnit, 15)
            hskill.heal(
                {
                    healer = sourceUnit,
                    healee = sourceUnit,
                    heal = hunit.getMaxLife(sourceUnit) * 0.07,
                    effect = nil,
                    healType = HEAL_TYPE.SKILL,
                    triggerSkill = skillID
                }
            )
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = targetUnit,
                    damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * 0.7,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.WULI,
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                    triggerSkill = skillID
                }
            )
            heffect.attach("war3mapImported\\AZ_hit1.mdx", targetUnit, "chest", 0)
            if math.random(1, 100) < 30 then
                jinu(sourceUnit, hslk.n2i("激怒"))
            end
        end
    )
end

local function luanwu(sourceUnit, skillID)
    local attackSpeed = 30
    hbuff.update(
        6,
        sourceUnit,
        skillID,
        true,
        function()
            hattribute.set(sourceUnit, 0, { attack_speed = "+" .. tostring(attackSpeed) })
        end,
        function()
            hattribute.set(sourceUnit, 0, { attack_speed = "-" .. tostring(attackSpeed) })
        end,
        hslk.i2v(skillID, "Art"),
        "乱舞|n攻击速度加30% 持续3次攻击或6秒 乱舞状态下暴怒攻击次数加一",
        3,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE
    )
end

siwangzhiyuan = function(whichUnit, duration)
    if hbuff.hasBuffThatLastLongerthan(whichUnit, hslk.n2i("死亡之愿"), duration) then
        return
    end
    heffect.attach("war3mapImported\\AZ_X039_1.mdx", whichUnit, "origin", 0)
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\siwangzhiyuan.wav", 1000, true),
        100,
        whichUnit
    )
    hbuff.update(
        duration,
        whichUnit,
        hslk.n2i("死亡之愿"),
        true,
        function()
            hattribute.set(whichUnit, 0, _attr({ wu_bao = "+20", wu_baoshang = "+20" }))
            hevent.register(
                whichUnit,
                CONST_EVENT.damagingCustomSource,
                "死亡之愿",
                function(evtData)
                    evtData.damage = evtData.damage * 1.3
                end
            )
            heffect.attach("war3mapImported\\AZ_G052.MDX", whichUnit, "origin", duration)
        end,
        function()
            hevent.unregister(whichUnit, CONST_EVENT.damagingCustomSource, "死亡之愿")
            hattribute.set(whichUnit, 0, _attr({ wu_bao = "-20", wu_baoshang = "-20" }))
        end,
        hslk.n2v("死亡之愿", "Art"),
        hslk.n2v("死亡之愿", "Ubertip"),
        1,
        nil,
        function(_, buffHandle)
            hunit.addCurMana(whichUnit, 10)
        end,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE
    )
end

local function kuangbaohuifu(whichUnit)
    if hunit.isAlive(whichUnit) == false then
        return
    end
    local recovery = 0.12
    if hbuff.hasBuff(whichUnit, "激怒") then
        hbuff.delete(whichUnit, "激怒")
        recovery = 0.20
    end
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\kuangbaohuifu.wav", 1000, true),
        100,
        whichUnit
    )
    hskill.heal(
        {
            healer = whichUnit,
            healee = whichUnit,
            heal = hunit.getMaxLife(whichUnit) * recovery,
            effect = nil,
            healType = HEAL_TYPE.SKILL,
            triggerSkill = hslk.n2i("狂暴恢复")
        }
    )
end

local yingyongtiaoyue = function(whichUnit, x, y, z)
    local dis = math.distance(x, y, hunit.x(whichUnit), hunit.y(whichUnit))
    if hcache.get(whichUnit, "crackFlying", false) then
        echo("被击飞中无法使用该技能", hunit.getOwner(whichUnit))
        return
    end
    hunit.setAnimateSpeed(whichUnit, 2.5, 0.5)
    hskillMoban.leap(
        {
            arrowUnit = whichUnit,    -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
            animation = "spell slam", -- 动画
            sourceUnit = whichUnit,   --伤害来源（必须有！不管有没有伤害）
            targetUnit = nil,         --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
            x = x,                    --冲击的x坐标（可选的，对点冲击，与某目标无关）
            y = y,                    --冲击的y坐标（可选的，对点冲击，与某目标无关）
            speed = dis / 0.5 * 0.02, --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
            acceleration = 0,         --冲击加速度（可选的，每个周期都会增加0.02秒一次)
            height = 200,             --飞跃高度（可选的，默认0)
            shake = 0,                --摇摆振幅角度[-90~+90|random]（可选的，默认0)
            filter = function(filterUnit)
                if
                    hunit.isAlly(whichUnit, filterUnit) or hunit.isDead(filterUnit) or hunit.isDead(whichUnit) or
                    hunit.isDestroyed(filterUnit) or
                    hunit.isDestroyed(whichUnit)
                then
                    return false
                else
                    return true
                end
            end,                                                                    --必须有
            tokenX = nil,                                                           --强制设定token初始创建的x坐标（可选的，同时设定tokenY时才有效）
            tokenY = nil,                                                           --强制设定token初始创建的y坐标（可选的，同时设定tokenX时才有效）
            tokenArrow = nil,                                                       --前冲的特效（arrowUnit=nil时认为必须！自身冲击就是bind，否则为马甲本身，如冲击波的波）
            tokenArrowScale = 1.00,                                                 --前冲的特效作为马甲冲击时的模型缩放
            tokenArrowOpacity = 1.00,                                               --前冲的特效作为马甲冲击时的模型透明度[0-1]
            tokenArrowHeight = hunit.z(whichUnit),                                  --前冲的特效作为马甲冲击时的初始离地高度
            effectMovement = nil,                                                   --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
            effectEnd = nil,                                                        --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
            damageMovement = 0,                                                     --移动过程中的伤害（可选的，默认为0）
            damageMovementRadius = nil,                                             --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
            damageMovementRepeat = false,                                           --移动过程中伤害是否可以重复造成（可选的，默认为不能）
            damageMovementDrag = false,                                             --移动过程是否拖拽敌人（可选的，默认为不能）
            damageEnd = hattribute.getWithLimit(whichUnit, nil, "attack", 0) * 0.5, --移动结束时对目标的伤害（可选的，默认为0）
            damageEndRadius = 300,                                                  --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
            damageSrc = CONST_DAMAGE_SRC.skill,                                     --伤害的种类（可选）
            damageEffect = nil,                                                     --伤害特效（可选）
            oneHitOnly = false,                                                     --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事）
            damageType = DAMAGE_TYPE.WULI,
            damageSkill = hslk.n2i("英勇跳跃"),
            onEnding = function()
                heffect.xyz(
                    "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl",
                    hunit.x(whichUnit),
                    hunit.y(whichUnit),
                    hunit.z(whichUnit),
                    0,
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    nil,
                    nil
                )
                hunit.setFlyHeight(whichUnit, 0, 9999)
            end, --结束时触发的动作
            extraInfluence = function(filterUnit)
                hbuff.xuanyun(filterUnit, 2)
            end --对选中的敌人的额外影响，会回调该敌人单位，可以对其做出自定义行为
        }
    )
end

SKILL_ON_LEVEL_UP["狂暴战"] = function(whichUnit)
    local kuangbaozhixinid = hslk.n2i("狂暴之心")
    if hskill.hasActiveAbility(whichUnit, kuangbaozhixinid) then
        hskillMoban.guanghuan(
            whichUnit,
            kuangbaozhixinid,
            2000,
            hslk.i2v(kuangbaozhixinid, "_guanghuanAttr"),
            true,
            true,
            "狂暴之心|n3%双暴"
        )
        hskill.addProperty(whichUnit, kuangbaozhixinid, 1)
    end
    local kuangbaozitaiid = hslk.n2i("狂暴姿态")
    if hskill.hasActiveAbility(whichUnit, kuangbaozitaiid) then
        hskill.addProperty(whichUnit, kuangbaozitaiid, 1)
    end
end

SKILLS_CAST["死亡之愿"] = function(evtData)
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "狂乱深渊")
    local duration = 15
    if points > 0 then
        duration = duration + points
    end
    siwangzhiyuan(evtData.triggerUnit, duration)
end

SKILLS["英勇跳跃"] = function(evtData)
    yingyongtiaoyue(evtData.triggerUnit, evtData.targetX, evtData.targetY, evtData.targetZ)
end

SKILLS["狂暴恢复"] = function(evtData)
    hunit.setAnimateSpeed(evtData.triggerUnit, 1.8, 0.25)
    hunit.animate(evtData.triggerUnit, "spell")
    htime.setTimeout(
        0.2,
        function(curTimer)
            curTimer.destroy()
            kuangbaohuifu(evtData.triggerUnit)
        end
    )
end

SKILL_SETUP["狂暴战"] = function(whichUnit)
    hskill.registerAutoCast(whichUnit, hslk.n2i("暴怒"))
    hskill.registerAutoCast(whichUnit, hslk.n2i("怒击"))
    hskill.registerMonitoringBuff(whichUnit, "激怒", true)
    hskill.registerMonitoringBuff(whichUnit, "旋风斩增益", true)
    hskill.registerMonitoringBuff(whichUnit, hslk.n2i("乱舞"), true)

    -- 狂暴战暴击
    hevent.register(
        whichUnit,
        CONST_EVENT.wulibaoji,
        "kuangbaozhan_jineng",
        function(evtData)
            local zhongshangID = hslk.n2i("狂暴战重伤")
            if evtData.triggerSkill ~= zhongshangID and hskill.hasActiveAbility(evtData.triggerUnit, zhongshangID) then
                zhongshang(evtData.triggerUnit, evtData.targetUnit, zhongshangID)
            end
            local yydj = hslk.n2i("英勇打击")
            if evtData.triggerSkill == yydj then
                if hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("无尽狂怒")) then
                    hunit.addCurMana(evtData.triggerUnit, 10)
                else
                    hunit.addCurMana(evtData.triggerUnit, 15)
                end
            end
            local luanwuid = hslk.n2i("乱舞")
            if hskill.hasActiveAbility(evtData.triggerUnit, luanwuid) then
                luanwu(evtData.triggerUnit, luanwuid)
            end
            local jinuid = hslk.n2i("激怒")
            if hskill.hasActiveAbility(evtData.triggerUnit, jinuid) then
                jinu(evtData.triggerUnit, jinuid)
            end
        end
    )

    -- 狂暴战攻击
    hevent.register(
        whichUnit,
        CONST_EVENT.attack,
        "kuangbaozhan_attack",
        function(evtData)
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "灵敏风暴")
            if points > 0 then
                htime.reduceCoolDown(evtData.triggerUnit, hslk.n2i("旋风斩"), 0.05 * points)
            end
            local jichujiange = hattribute.getWithLimit(evtData.triggerUnit, nil, "attack_space_origin", 2.0)
            local pugong_nuqi = 5 * jichujiange
            if hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("无尽狂怒")) then
                pugong_nuqi = pugong_nuqi * 1.25
            end
            hunit.addCurMana(evtData.triggerUnit, pugong_nuqi)
            if hbuff.hasBuff(evtData.triggerUnit, hslk.n2i("乱舞")) then
                hbuff.removeStack(evtData.triggerUnit, hslk.n2i("乱舞"), 1)
            end
            local shixuecd = KUANGBAOZHAN_CD[hslk.n2i("嗜血")]
            if hcache.get(evtData.triggerUnit, "[T2]熔铸勇士套装(3件)", false) then
                shixuecd = math.max(1, shixuecd - 3)
            elseif hzhuangbeishouji.isActive(hunit.getOwner(evtData.triggerUnit), "[T2]熔铸勇士套装") then
                shixuecd = math.max(1, shixuecd - 1)
            end
            if
                hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("嗜血")) and
                htime.setupAndCheckCoolDown(evtData.triggerUnit, hslk.n2i("嗜血"), shixuecd)
            then
                shixue(evtData.triggerUnit, evtData.targetUnit, hslk.n2i("嗜血"))
            end
            if
                hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("旋风斩")) and
                htime.setupAndCheckCoolDown(evtData.triggerUnit, hslk.n2i("旋风斩"), KUANGBAOZHAN_CD[hslk.n2i("旋风斩")])
            then
                xuanfenzhan(evtData.triggerUnit, evtData.targetUnit, hslk.n2i("旋风斩"))
                return
            end
            if
                hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("狂暴劈砍")) and
                htime.setupAndCheckCoolDown(
                    evtData.triggerUnit,
                    hslk.n2i("狂暴劈砍"),
                    KUANGBAOZHAN_CD[hslk.n2i("狂暴劈砍")]
                )
            then
                kuangbaopikan(evtData.triggerUnit, evtData.targetUnit, hslk.n2i("狂暴劈砍"))
                return
            end
        end
    )

    -- 触发英勇打击则取消普攻
    hevent.register(
        whichUnit,
        CONST_EVENT.beforeAttackDamage,
        "yydj",
        function(options)
            if
                hcache.get(options.sourceUnit, "yydj_zhuangtai", nil) == 1 and
                hskill.hasActiveAbility(options.sourceUnit, hslk.n2i("英勇打击")) and
                hunit.getCurMana(options.sourceUnit) >= 70
            then
                yingyongdaji(options.sourceUnit, options.targetUnit, hslk.n2i("英勇打击"))
                options.damage = 0
            end
        end
    )

    -- 一心狂暴 hitem.isShuangShouWuqi
    hevent.register(
        whichUnit,
        CONST_EVENT.damagingCustomSource,
        "yixinkuangbao",
        function(evtData)
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "一心狂暴")
            if points > 0 then
                local leftHandItem = hplayer.dzCunDang[hunit.getOwner(whichUnit)].getEquipment(EQUIPMENT_SLOT_ID.zhushou)
                local rightHandItem = hplayer.dzCunDang[hunit.getOwner(whichUnit)].getEquipment(EQUIPMENT_SLOT_ID.fushou)
                if leftHandItem and rightHandItem and hitem.isShuangShouWuqi(leftHandItem) == false and hitem.isShuangShouWuqi(rightHandItem) == false then
                    evtData.damage = evtData.damage * (1 + points * 0.05)
                end
            end
        end
    )
end
