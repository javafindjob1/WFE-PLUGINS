local WUQIZHAN_JINGTONG_XISHU = 6

---被动技能cd类常数
local WUQIZHAN_CD = {}
WUQIZHAN_CD[hslk.n2i("压制")] = 12
WUQIZHAN_CD[hslk.n2i("猛击")] = 12
WUQIZHAN_CD[hslk.n2i("顺劈斩")] = 6
WUQIZHAN_CD[hslk.n2i("致死打击")] = 3
WUQIZHAN_CD[hslk.n2i("剑在人在")] = 180

local silie

local function yazhi(sourceUnit, targetUnit, skill)
    local damageMulti = 1.2
    if hshangcheng.hasItem(hunit.getOwner(sourceUnit), "见习武器战") then
        damageMulti = damageMulti * 1.05
    end
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("战争领主")) then
        damageMulti = damageMulti * 1.5
        if math.random(1, 100) <= 30 then
            hbuff.update(
                10,
                sourceUnit,
                "战争领主",
                true,
                nil,
                nil,
                hslk.i2v(hslk.n2i("战争领主"), "Art"),
                "下个致死打击不消耗怒气",
                1,
                nil,
                nil,
                nil,
                nil,
                HBUFF_UPDATE_MODE.OVERWRITE
            )
            htime.clearCoolDown(sourceUnit, hslk.n2i("致死打击"))
        end
    end
    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\yazhi.wav", 1000, true), 100, targetUnit)
    hskill.damage(
        {
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            damage = damageMulti * hattribute.getWithLimit(sourceUnit, nil, "attack", 0),
            damageSrc = CONST_DAMAGE_SRC.skill,
            damageType = DAMAGE_TYPE.WULI,
            triggerSkill = skill,
            tmpAttr = { wu_bao = "+100", hit = "+100" },
            isAttackReplacement = true
        }
    )
    heffect.xyz(
        "war3mapImported\\[Spell_QJTX].mdx",
        hunit.x(targetUnit),
        hunit.y(targetUnit),
        hunit.z(targetUnit),
        0,
        0.7,
        nil,
        nil,
        nil,
        nil,
        nil,
        hunit.getFacing(sourceUnit) + 180
    )
    hunit.addCurMana(sourceUnit, 5)
end

silie = function(sourceUnit, targetUnit, buffKey)
    local duration = 12
    local interval = 3
    local interval = math.round(interval * 100 / (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)))
    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\silie.wav", 1000, true), 100, targetUnit)
    heffect.attach("war3mapImported\\Gondar(1)_T_Impact.mdx", targetUnit, "chest", 0)
    hunit.addCurMana(sourceUnit, 5)
    hbuff.update(
        duration,
        targetUnit,
        buffKey,
        false,
        nil,
        nil,
        hslk.i2v(hslk.n2i("撕裂"), "Art"),
        "撕裂|n每隔一段时间造成物理伤害",
        1,
        interval,
        function(_, buffHandle)
            local damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0)
            if hcache.get(sourceUnit, "[T1]无畏勇士套装(4件)", false) then
                damage = damage * 1.5
            elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T1]无畏勇士套装") then
                damage = damage * 1.2
            end
            buffHandle.description = "撕裂|n：每隔" .. buffHandle.interval .. "秒时间造成" .. damage .. "点物理伤害"
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = targetUnit,
                    damage = damage,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.WULI,
                    triggerSkill = hslk.n2i("撕裂"),
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
                }
            )
            heffect.attach("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", targetUnit, "origin", 0)
            hunit.addCurMana(sourceUnit, 3)
            buffHandle.remainingTime = buffHandle.remainingTime - buffHandle.interval
            if hcache.get(sourceUnit, "[T1]无畏勇士套装(4件)", false) then
                hskill.heal(
                    {
                        healee = sourceUnit,
                        healer = sourceUnit,
                        heal = hunit.getMaxLife(sourceUnit) * 0.03,
                        healType = HEAL_TYPE.SKILL,
                        triggerSkill = hslk.n2i("撕裂")
                    }
                )
            elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T1]无畏勇士套装") then
                hskill.heal(
                    {
                        healee = sourceUnit,
                        healer = sourceUnit,
                        heal = hunit.getMaxLife(sourceUnit) * 0.01,
                        healType = HEAL_TYPE.SKILL,
                        triggerSkill = hslk.n2i("撕裂")
                    }
                )
            end
        end,
        function(buffhandle)
            buffhandle.remainingTime = duration
        end, nil,
        HBUFF_UPDATE_MODE.UPDATE
    )
end

local function zhisidaji(sourceUnit, targetUnit, skill, nocost)
    local manaCost = 25
    local damageMulti = 3.5
    local hanchang_points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "酣畅打击")
    if hanchang_points > 0 then
        manaCost = manaCost + hanchang_points
        damageMulti = damageMulti * (1 + hanchang_points * 0.02)
    end
    if nocost == true then
        manaCost = 0
    end
    if hbuff.hasBuff(sourceUnit, "屠杀") then
        damageMulti = damageMulti * 1.3
        hbuff.delete(sourceUnit, "屠杀")
    end
    if hbuff.hasBuff(sourceUnit, "战争领主") then
        manaCost = 0
        damageMulti = damageMulti * 1.3
        hbuff.delete(sourceUnit, "战争领主")
    end
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\zhisidaji.wav", 1000, true),
        100,
        targetUnit
    )
    local angel = math.angle(hunit.x(sourceUnit), hunit.y(sourceUnit), hunit.x(targetUnit), hunit.y(targetUnit))
    heffect.xyz(
        "war3mapImported\\AZ_XPDG.mdx",
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
        angel
    )
    hskill.damage(
        {
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            damage = damageMulti * hattribute.getWithLimit(sourceUnit, nil, "attack", 0),
            damageSrc = CONST_DAMAGE_SRC.skill,
            damageType = DAMAGE_TYPE.WULI,
            triggerSkill = skill,
            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
            isAttackReplacement = true
        }
    )
    hunit.subCurMana(sourceUnit, manaCost)

    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("猝死")) then
        local buffhandle = hbuff.getBuffHandle(targetUnit, "猝死斩杀增伤" .. tostring(sourceUnit))
        local zengshang = 10
        if hcache.get(sourceUnit, "[T3]无畏战将套装(4件)", false) then
            zengshang = zengshang + 6
        elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T3]无畏战将套装") then
            zengshang = zengshang + 4
        end
        local stack = 1
        if buffhandle ~= nil and buffhandle.stack ~= nil then
            stack = math.min(3, buffhandle.stack + 1)
        end
        hbuff.update(
            10,
            targetUnit,
            "猝死斩杀增伤" .. tostring(sourceUnit),
            false,
            nil,
            nil,
            hslk.n2v("斩杀", "Art"),
            "目标下次受到斩杀伤害提高，每层" .. zengshang .. "%",
            stack,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE,
            true
        )
    end

    local silieBuffKey = hslk.n2i("撕裂") .. "|" .. tostring(sourceUnit)
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("撕裂")) then
        silie(sourceUnit, targetUnit, silieBuffKey)
    end
end

local function mengji(sourceUnit, targetUnit, skill)
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "巨力猛击")
    local mengjisilie = function(localTarget)
        local siliemengji_points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "撕裂猛击")
        if siliemengji_points > 0 then
            local silie_chance = siliemengji_points * 20
            if math.random(1, 100) <= silie_chance then
                local silieBuffKey = hslk.n2i("撕裂") .. "|" .. tostring(sourceUnit)
                silie(sourceUnit, localTarget, silieBuffKey)
            end
        end
    end
    local scale = 0.6
    if points > 0 then
        local radius = 150 + 50 * points
        scale = 0.6 + 0.15 * points
        hskillMoban.radiusAOE(
            hunit.x(targetUnit),
            hunit.y(targetUnit),
            sourceUnit,
            radius,
            function(enum)
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = enum,
                        damage = 2.8 * hattribute.getWithLimit(sourceUnit, nil, "attack", 0),
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.WULI,
                        triggerSkill = skill,
                        isAttackReplacement = true,
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
                    }
                )
                mengjisilie(enum)
            end,
            false,
            true
        )
    else
        hskill.damage(
            {
                sourceUnit = sourceUnit,
                targetUnit = targetUnit,
                damage = 2.5 * hattribute.getWithLimit(sourceUnit, nil, "attack", 0),
                damageSrc = CONST_DAMAGE_SRC.skill,
                damageType = DAMAGE_TYPE.WULI,
                triggerSkill = skill,
                isAttackReplacement = true,
                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
            }
        )
        mengjisilie(targetUnit)
    end
    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\mengji.wav", 1000, true), 100, targetUnit)
    heffect.xyz(
        "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl",
        hunit.x(targetUnit),
        hunit.y(targetUnit),
        hunit.z(targetUnit),
        0,
        1,
        scale,
        scale,
        1,
        nil,
        nil,
        nil
    )
    hunit.addCurMana(sourceUnit, 5)
end

local function jianzairenzai(whichUnit)
    if hunit.getCurLifePercent(whichUnit) < 30 then
        hskill.heal(
            {
                healee = whichUnit,
                healer = whichUnit,
                heal = hunit.getMaxLife(whichUnit) * 0.3 - hunit.getCurLife(whichUnit),
                healType = HEAL_TYPE.SKILL,
                triggerSkill = hslk.n2i("剑在人在")
            }
        )
    end
    echo("here")
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\jianzairenzai.wav", 1000, true),
        100,
        whichUnit
    )
    heffect.attach("war3mapImported\\[Spell]_012_3_AZ.mdx", whichUnit, "origin", 5)
    htextTag.create2Unit(whichUnit, "剑在人在", 6, "ff3300", 1, 1, 50)
    hbuff.update(
        5,
        whichUnit,
        hslk.n2i("剑在人在"),
        true,
        function()
            hattribute.set(whichUnit, 0, { zhaojia = "+100" })
        end,
        function()
            hattribute.set(whichUnit, 0, { zhaojia = "-100" })
        end,
        hslk.i2v(hslk.n2i("剑在人在"), "Art"),
        "免疫一次死亡，同时招架提高100%",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.CREATE_ONLY
    )
    hbuff.update(
        WUQIZHAN_CD[hslk.n2i("剑在人在")],
        whichUnit,
        "剑在人在cd",
        false,
        nil,
        nil,
        hslk.i2v(hslk.n2i("剑在人在"), "Art"),
        "剑在人在正在CD中",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.CREATE_ONLY
    )
end

SKILLS["斩杀"] = function(evtData)
    if evtData.targetUnit == nil or hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("斩杀")) == false then
        return
    end
    local NBzhansha = false
    local zhanshathreshold = 20
    if hmingwen.isEquipped("狂热斩杀", hunit.getOwner(evtData.triggerUnit)) then
        zhanshathreshold = 35
    end
    if hunit.getCurLifePercent(evtData.targetUnit) <= zhanshathreshold or hbuff.hasBuff(evtData.triggerUnit, "猝死") then
        hbuff.delete(evtData.triggerUnit, "猝死")
        NBzhansha = true
    end
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\shizijundaji-shifa.wav", 1000, true),
        100,
        evtData.triggerUnit
    )
    hunit.setAnimateSpeed(evtData.triggerUnit, 2.2, 0.35)
    hunit.animate(evtData.triggerUnit, "attack Slam")
    htime.setTimeout(
        0.30,
        function(_)
            if hmingwen.isEquipped("屠杀", hunit.getOwner(evtData.triggerUnit)) then
                hbuff.update(
                    10,
                    evtData.triggerUnit,
                    "屠杀",
                    true,
                    nil,
                    nil,
                    hslk.i2v(hslk.n2i("斩杀"), "Art"),
                    "屠杀：下一次致死打击伤害提高30%",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE
                )
            end
            local damangeMultiplier = 2
            if NBzhansha then
                local currentMana = hunit.getCurMana(evtData.triggerUnit)
                damangeMultiplier = damangeMultiplier + currentMana / 12
                hunit.subCurMana(evtData.triggerUnit, currentMana)
                hcamera.quake(hplayer.loc(), 10, 0.1)
                local zsjqpoints = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "斩杀技巧")
                if zsjqpoints > 0 then
                    hunit.addCurMana(evtData.triggerUnit, 4 * zsjqpoints)
                end
            end
            if hunit.getCurLifePercent(evtData.targetUnit) <= zhanshathreshold then
                hskill.setCoolDown(evtData.triggerUnit, hslk.n2i("斩杀"), 3)
            end
            if hbuff.hasBuff(evtData.targetUnit, "猝死斩杀增伤" .. tostring(evtData.triggerUnit)) then
                local stack = hbuff.getBuffHandle(evtData.targetUnit, "猝死斩杀增伤" .. tostring(evtData.triggerUnit)).stack
                local damageIncreasePerStack = 0.1
                if hcache.get(evtData.triggerUnit, "[T3]无畏战将套装(4件)", false) then
                    damageIncreasePerStack = damageIncreasePerStack + 0.06
                elseif hzhuangbeishouji.isActive(hunit.getOwner(evtData.triggerUnit), "[T3]无畏战将套装") and math.random(1, 100) <= 5 then
                    damageIncreasePerStack = damageIncreasePerStack + 0.03
                end
                damangeMultiplier = damangeMultiplier * (damageIncreasePerStack * stack + 1)
                hbuff.delete(evtData.targetUnit, "猝死斩杀增伤" .. tostring(evtData.triggerUnit))
            end
            heffect.xyz(
                "war3mapImported\\[AZ]daoguang1.MDX",
                hunit.x(evtData.triggerUnit),
                hunit.y(evtData.triggerUnit),
                hunit.z(evtData.triggerUnit),
                0,
                1.3,
                nil,
                nil,
                nil,
                nil,
                nil,
                hunit.getFacing(evtData.triggerUnit)
            )
            hsound.voice2Unit(
                hsound.voiceCreate(
                    "resource\\war3mapImported\\sound\\spell_wr_execute_revamp_impact_01.wav",
                    1000,
                    true
                ),
                200,
                evtData.targetUnit
            )
            heffect.attach("war3mapImported\\AZ_hit3.mdx", evtData.targetUnit, "origin", 0)
            hskill.damage(
                {
                    sourceUnit = evtData.triggerUnit,
                    targetUnit = evtData.targetUnit,
                    damage = (hattribute.getWithLimit(evtData.triggerUnit, nil, "attack", 0) +
                            hattribute.getWithLimit(evtData.triggerUnit, nil, "str", 0)) *
                        damangeMultiplier,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.WULI,
                    triggerSkill = hslk.n2i("斩杀"),
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
                }
            )
            hunit.animate(evtData.triggerUnit, "stand ready second")
            local silieBuffKey = hslk.n2i("撕裂") .. "|" .. tostring(evtData.triggerUnit)
            silie(evtData.triggerUnit, evtData.targetUnit, silieBuffKey)
        end
    )
end

-- 重伤
local function zhongshang(triggerUnit, targetUnit, triggerSkill)
    if targetUnit == nil or triggerUnit == nil then
        return
    end
    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\silie.wav", 1000, true), 100, targetUnit)
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

    local damage =
        hattribute.getWithLimit(triggerUnit, nil, "attack", 0) *
        (0.60 + 0.01 * hattribute.getWithLimit(triggerUnit, nil, "master", 0) / WUQIZHAN_JINGTONG_XISHU)
    hbuff.update(
        6,
        targetUnit,
        hslk.n2i("重伤") .. "|" .. tostring(triggerUnit),
        false,
        function()
        end,
        function()
        end,
        hslk.i2v(hslk.n2i("重伤"), "Art"),
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

SKILLS["冲锋"] = function(evtData)
    if hcache.get(evtData.triggerUnit, "crackFlying", false) then
        echo("被击飞中冲锋失败", hunit.getOwner(evtData.triggerUnit))
        return
    end
    local damangeMultiplier = 4
    hunit.setAnimateSpeed(evtData.triggerUnit, 2.5, 0.5)
    local e = heffect.attach("war3mapImported\\[Spell]_056.mdx", evtData.triggerUnit, "origin", 0.8)
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\chongfeng.wav", 1000, true),
        100,
        evtData.triggerUnit
    )
    hskillMoban.leap(
        {
            arrowUnit = evtData.triggerUnit,  -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
            sourceUnit = evtData.triggerUnit, --伤害来源（必须有！不管有没有伤害）
            targetUnit = evtData.targetUnit,  --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
            speed = 50,                       --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
            acceleration = 0,
            shake = 0,                        --摇摆振幅角度[-90~+90|random]（可选的，默认0)
            filter = function(enum)
                return hunit.isEnemy(evtData.triggerUnit, enum) and hunit.isAlive(enum)
            end,                                --必须有
            tokenArrowScale = 1.00,             --前冲的特效作为马甲冲击时的模型缩放
            tokenArrowOpacity = 1.00,           --前冲的特效作为马甲冲击时的模型透明度[0-1]
            tokenArrowHeight = 0.00,            --前冲的特效作为马甲冲击时的初始离地高度
            effectMovement = nil,               --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
            animateMovement = 1,
            effectEnd = nil,                    --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
            damageMovement = 0,                 --移动过程中的伤害（可选的，默认为0）
            damageMovementRadius = 0,           --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
            damageMovementRepeat = false,       --移动过程中伤害是否可以重复造成（可选的，默认为不能）
            damageMovementDrag = false,         --移动过程是否拖拽敌人（可选的，默认为不能）
            damageEndRadius = 0,                --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
            damageSrc = CONST_DAMAGE_SRC.skill, --伤害的种类（可选）
            damageEffect = nil,                 --伤害特效（可选）
            damageType = DAMAGE_TYPE.WULI,
            damageSkill = hslk.n2i("冲锋"),
            oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
            endDistance = 150,
            onEnding = function(_, _, timePassed)
                hskill.damage(
                    {
                        sourceUnit = evtData.triggerUnit,
                        targetUnit = evtData.targetUnit,
                        damage = 100 +
                            hattribute.getWithLimit(evtData.triggerUnit, nil, "attack", 0) * damangeMultiplier *
                            timePassed,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.WULI,
                        triggerSkill = hslk.n2i("冲锋"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
                    }
                )
                hunit.addCurMana(evtData.triggerUnit, 20)
                heffect.attach("war3mapImported\\AZ_chongfeng.mdx", evtData.targetUnit, "origin", 0)
                hbuff.xuanyun(evtData.targetUnit, 0.1 + 2 * timePassed)
                cj.IssueTargetOrder(evtData.triggerUnit, "attack", evtData.targetUnit)
                if
                    hmingwen.isEquipped("致死冲锋", hunit.getOwner(evtData.triggerUnit)) and
                    hunit.getCurMana(evtData.triggerUnit) >= 25
                then
                    zhisidaji(evtData.triggerUnit, evtData.targetUnit, hslk.n2i("致死打击"), true)
                end
            end
        }
    )
end

local jurendaji = function(sourceUnit, targetUnit)
    local damangeMultiplier = 1.5
    -- TODO 测试是否work
    local duration = 5

    heffect.attach("war3mapImported\\Armor Penetration Orange.mdx", targetUnit, "chest", duration)
    heffect.attach("war3mapImported\\AZ_hit1.mdx", targetUnit, "chest", 0)
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\mengji.wav", 1000, true),
        100,
        targetUnit
    )
    hbuff.update(
        duration,
        targetUnit,
        "巨人打击增伤" .. tostring(sourceUnit),
        false,
        nil,
        nil,
        hslk.n2v("巨人打击", "Art"),
        "巨人打击使目标在5秒内受到来自武器战的额外30%伤害",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE
    )
    hskill.damage(
        {
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * damangeMultiplier,
            damageSrc = CONST_DAMAGE_SRC.skill,
            damageType = DAMAGE_TYPE.WULI,
            triggerSkill = hslk.n2i("巨人打击"),
            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
        }
    )
    hunit.animate(sourceUnit, "stand")
end

SKILLS["巨人打击"] = function(evtData)
    if evtData.targetUnit == nil or hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("巨人打击")) == false then
        return
    end
    hunit.setAnimateSpeed(evtData.triggerUnit, 2.2, 0.35)
    hunit.animate(evtData.triggerUnit, "attack Slam")
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\shizijundaji-shifa.wav", 1000, true),
        100,
        evtData.triggerUnit
    )
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "杀意")
    if points > 0 then
        local attr = hattribute.getAttributeWithMulti(_attr({ attack_speed = "+3", skill_speed = "+2" }), points)
        local desp = description.attribute(attr, ",")
        hbuff.update(
            5,
            evtData.triggerUnit,
            "杀意",
            true,
            function()
                hattribute.set(
                    evtData.triggerUnit,
                    0,
                    hattribute.getAttributeWithMulti(_attr({ attack_speed = "+3", skill_speed = "+2" }), points)
                )
            end,
            function()
                hattribute.set(
                    evtData.triggerUnit,
                    0,
                    hattribute.getAttributeWithMulti(_attr({ attack_speed = "-3", skill_speed = "-2" }), points)
                )
            end,
            hslk.n2v("巨人打击", "Art"),
            "杀意：巨人打击使战士兴奋，" .. desp,
            1,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE,
            true
        )
    end
    htime.setTimeout(
        0.30,
        function(_)
            if hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("灭战者")) then
                hunit.addCurMana(evtData.triggerUnit, 10)

                hskillMoban.radiusAOE(
                    hunit.x(evtData.targetUnit),
                    hunit.y(evtData.targetUnit),
                    evtData.triggerUnit,
                    300,
                    function(target)
                        jurendaji(evtData.triggerUnit, target)
                    end,
                    false,
                    true
                )
            else
                jurendaji(evtData.triggerUnit, evtData.targetUnit)
            end
        end
    )
end

SKILLS["雷霆一击"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    --  hunit.setAnimateSpeed(evtData.triggerUnit, 1, 0.35)
    hunit.animate(evtData.triggerUnit, "Spell Three")
    htime.setTimeout(
        0.30,
        function(_)
            heffect.xyz(
                "war3mapImported\\AZ_leitingyiji.MDX",
                hunit.x(sourceUnit),
                hunit.y(sourceUnit),
                hunit.z(sourceUnit),
                0,
                1
            )
            hsound.voice2Unit(
                hsound.voiceCreate("resource\\war3mapImported\\sound\\3349.mp3", 1000, true),
                80,
                evtData.triggerUnit
            )
            hcamera.quake(hplayer.loc(), 10, 0.1)
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
                            damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * 0.8,
                            damageSrc = CONST_DAMAGE_SRC.skill,
                            damageType = DAMAGE_TYPE.MOFA,
                            triggerSkill = hslk.n2i("雷霆一击"),
                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
                        }
                    )

                    if hmingwen.isEquipped("雷霆统治", hunit.getOwner(evtData.triggerUnit)) then
                        yazhi(sourceUnit, target, hslk.n2i("压制"))
                    else
                        zhongshang(sourceUnit, target, hslk.n2i("重伤"))
                    end
                end,
                false,
                true
            )

            if hmingwen.isEquipped("雷霆恢复", hunit.getOwner(evtData.triggerUnit)) then
                hskill.heal(
                    {
                        healee = sourceUnit,
                        healer = sourceUnit,
                        heal = hunit.getMaxLife(sourceUnit) * 0.1,
                        healType = HEAL_TYPE.SKILL,
                        triggerSkill = hslk.n2i("雷霆一击")
                    }
                )
            end
        end
    )
end

SKILLS["天神下凡"] = function(evtData)
    local whichUnit = evtData.triggerUnit
    local e =
        heffect.xyz(
            "war3mapImported\\AZ_FelgaurdBluePF_R.mdx",
            hunit.x(evtData.triggerUnit),
            hunit.y(evtData.triggerUnit),
            hunit.z(evtData.triggerUnit),
            0,
            1,
            1,
            1,
            1
        )
    hcamera.quake(hplayer.loc(), 10, 0.1)
    --  hunit.setAnimateSpeed(evtData.triggerUnit, 1, 0.35)
    hsound.voice2Unit(hsound.voiceCreate("Abilities\\Spells\\Human\\Avatar\\Avatar.wav", 3199, true), 100, whichUnit)

    local duration = 20
    hbuff.update(
        duration,
        whichUnit,
        hslk.n2i("天神下凡"),
        true,
        function()
            hattribute.set(whichUnit, 0, _attr({ shengming_baifenbi = "+50", jianshang = "+10" }))
            hevent.register(
                whichUnit,
                CONST_EVENT.damagingCustomSource,
                "天神下凡",
                function(evtData)
                    evtData.damage = evtData.damage * 1.3
                end
            )
            cj.SetUnitScale(whichUnit, 1.5, 1.5, 1.5)
        end,
        function()
            hevent.unregister(whichUnit, CONST_EVENT.damagingCustomSource, "天神下凡")
            hattribute.set(whichUnit, 0, _attr({ shengming_baifenbi = "-50", jianshang = "-10" }))
            cj.SetUnitScale(whichUnit, 1, 1, 1)
        end,
        hslk.n2v("天神下凡", "Art"),
        hslk.n2v("天神下凡", "Ubertip"),
        nil,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
end

---顺劈斩
---@param sourceUnit userdata
---@param model string
---@angle number 角度
local function shunpizhan(sourceUnit, model, angle)
    local damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * 1.2
    if hcache.get(sourceUnit, "[T2]熔铸勇士套装(4件)", false) then
        damage = damage * 1.5
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T2]熔铸勇士套装") then
        damage = damage * 1.2
    end
    local group =
        hgroup.createByAngleAndRadius(
            sourceUnit,
            400,
            angle,
            120,
            function(filterUnit)
                if
                    hunit.isAlly(sourceUnit, filterUnit) or hunit.isDead(filterUnit) or hunit.isDead(sourceUnit) or
                    hunit.isDestroyed(filterUnit) or
                    hunit.isDestroyed(sourceUnit)
                then
                    return false
                else
                    return true
                end
            end,
            true
        )
    for _, target in ipairs(group) do
        hskill.damage(
            {
                sourceUnit = sourceUnit,
                targetUnit = target,
                damage = damage,
                damageSrc = CONST_DAMAGE_SRC.skill,
                damageType = DAMAGE_TYPE.WULI,
                triggerSkill = hslk.n2i("顺劈斩"),
                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
            }
        )
        heffect.xyz(
            model,
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
            angle
        )
    end
end

SKILLS["利刃风暴"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local interval = 0.5
    --local attack_speed = hattribute.getWithLimit(sourceUnit, nil, "attack_speed", 0)
    local skill_speed = hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)
    interval = math.round(interval * 100 / (100 + skill_speed))
    --interval = math.round(interval * 100 / (100 + attack_speed))
    local damageMulti = 1.5
    heffect.attach("war3mapImported\\JRFB_[AZ].MDX", sourceUnit, "origin", 5)
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "死亡之舞")
    if points > 0 then
        local cooldownRed = 0.3 * points
        hbuff.update(
            5,
            sourceUnit,
            "死亡之舞",
            true,
            function()
                hevent.register(
                    sourceUnit,
                    CONST_EVENT.kill,
                    "死亡之舞",
                    function(evtData)
                        if hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("利刃风暴")) >= 30 then
                            hskill.setCoolDown(
                                evtData.triggerUnit,
                                hslk.n2i("利刃风暴"),
                                math.max(35, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("利刃风暴")) - cooldownRed)
                            )
                        end
                    end
                )
            end,
            function()
                hevent.unregister(sourceUnit, CONST_EVENT.kill, "死亡之舞")
            end,
            hslk.n2v("利刃风暴", "Art"),
            "死亡之舞，每击杀一个敌人降低利刃风暴" .. cooldownRed .. "秒冷却时间",
            1,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE
        )
    end
    htime.setInterval(
        interval,
        function(curTimer)
            if curTimer.passedSec() > 5 or hunit.isAlive(sourceUnit) == false then
                curTimer.destroy()
                return
            end
            local group =
                hgroup.createByUnit(
                    sourceUnit,
                    300,
                    function(filterUnit)
                        if
                            hunit.isAlly(sourceUnit, filterUnit) or hunit.isDead(filterUnit) or hunit.isDead(sourceUnit) or
                            hunit.isDestroyed(filterUnit) or
                            hunit.isDestroyed(sourceUnit)
                        then
                            return false
                        else
                            return true
                        end
                    end,
                    true
                )
            for _, target in ipairs(group) do
                heffect.attach("war3mapImported\\AZ_hit1.mdx", target, "chest", 0)
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = target,
                        damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * damageMulti,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.WULI,
                        triggerSkill = hslk.n2i("利刃风暴"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
                    }
                )

                if hskill.hasActiveAbility(sourceUnit, hslk.n2i("顺劈斩")) then
                    if math_random(1, 100) <= 15 then
                        shunpizhan(
                            sourceUnit,
                            "war3mapImported\\AZ_Z041.MDX",
                            math.angle(hunit.x(sourceUnit), hunit.y(sourceUnit), hunit.x(target), hunit.y(target))
                        )
                    end
                end
            end

            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "聚焦风暴")
            if points > 0 then
                local attr = hattribute.getAttributeWithMulti(_attr({ wu_bao = "+0.15", wu_zengshang = "+0.15" }), points)
                local desc = description.attribute(attr, "，")
                hbuff.addStackAttrBuff(
                    CONST_DAMAGE_SRC.skill,
                    sourceUnit,
                    "聚焦风暴",
                    attr,
                    5,
                    50,
                    hslk.n2v("利刃风暴", "Art"),
                    "聚焦风暴，每层提高" .. desc,
                    true
                )
            end

            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "迷乱狂舞")
            if points > 0 then
                if math.random(1, 100) <= 6 * points then
                    local units = table.random(group, 2)
                    for _, target in ipairs(units) do
                        zhisidaji(sourceUnit, target, hslk.n2i("致死打击"), true)
                    end
                end
            end
        end
    )
end

SKILL_ON_LEVEL_UP["武器战"] = function(whichUnit)
    local zhandounuhou = hslk.n2i("战斗怒吼")
    if hskill.hasActiveAbility(whichUnit, zhandounuhou) then
        hskillMoban.guanghuan(
            whichUnit,
            zhandounuhou,
            2000,
            hslk.i2v(zhandounuhou, "_guanghuanAttr"),
            true,
            true,
            "战斗怒吼|n10%攻击|n10%生命"
        )
        hskill.addProperty(whichUnit, zhandounuhou, 1)
    end
end



SKILLS_STOP["天神下凡"] = function(evtData)
    if hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("灭战者")) then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("天神下凡"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("天神下凡")) - 80)
        )
    end
end

SKILLS_STOP["雷霆一击"] = function(evtData)
    if hcache.get(evtData.triggerUnit, "[T3]无畏战将套装(3件)", false) then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("雷霆一击"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("雷霆一击")) - 2)
        )
    elseif hzhuangbeishouji.isActive(hunit.getOwner(evtData.triggerUnit), "[T3]无畏战将套装") then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("雷霆一击"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("雷霆一击")) - 1)
        )
    end
end

SKILLS_STOP["冲锋"] = function(evtData)
    if hmingwen.isEquipped("急速冲锋", hunit.getOwner(evtData.triggerUnit)) then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("冲锋"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("冲锋")) - 6)
        )
    end
    if hcache.get(evtData.triggerUnit, "[T2]熔铸勇士套装(3件)", false) then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("冲锋"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("冲锋")) - 2)
        )
    elseif hzhuangbeishouji.isActive(hunit.getOwner(evtData.triggerUnit), "[T2]熔铸勇士套装") then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("冲锋"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("冲锋")) - 1)
        )
    end
end

SKILL_SETUP["武器战"] = function(whichUnit)
    hskill.registerAutoCast(whichUnit, hslk.n2i("冲锋"))
    hskill.registerAutoCast(whichUnit, hslk.n2i("巨人打击"))
    hskill.registerAutoCast(whichUnit, hslk.n2i("斩杀"))
    hskill.registerMonitoringBuff(whichUnit, "猝死", true)
    hskill.registerMonitoringBuff(whichUnit, "猝死斩杀增伤" .. tostring(whichUnit), false)

    -- 武器战暴击
    hevent.register(
        whichUnit,
        CONST_EVENT.wulibaoji,
        "wuqizhan_jineng",
        function(evtData)
            if hunit.getName(evtData.triggerUnit) ~= "武器战" then
                return
            end
            local zhongshangID = hslk.n2i("重伤")
            if evtData.triggerSkill == zhongshangID then
                return
            end
            if hskill.hasActiveAbility(evtData.triggerUnit, zhongshangID) then
                zhongshang(evtData.triggerUnit, evtData.targetUnit, zhongshangID)
            end
        end
    )

    hevent.register(
        whichUnit,
        CONST_EVENT.dying,
        "wuqizhan",
        function(evtData)
            if hunit.getName(evtData.targetUnit) ~= "武器战" then
                return
            end
            if hskill.hasActiveAbility(evtData.targetUnit, hslk.n2i("剑在人在")) == false then
                return
            end
            if htime.setupAndCheckCoolDown(evtData.targetUnit, hslk.n2i("剑在人在"), WUQIZHAN_CD[hslk.n2i("剑在人在")]) then
                evtData.damage = 0
                jianzairenzai(evtData.targetUnit)
            end
        end
    )

    hevent.register(
        whichUnit,
        CONST_EVENT.beishanbi,
        "wuqizhan_jineng",
        function(evtData)
            if hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("压制")) == false then
                return
            end
            htime.clearCoolDown(evtData.triggerUnit, hslk.n2i("压制"))
        end
    )

    hevent.register(
        whichUnit,
        CONST_EVENT.damagingCustomSource,
        "wuqizhan_custom_zengshang",
        function(evtData)
            local targetUnit = evtData.targetUnit
            local sourceUnit = evtData.sourceUnit
            if hunit.isAlive(sourceUnit) == false then
                return
            end
            if hbuff.hasBuff(targetUnit, "巨人打击增伤" .. tostring(sourceUnit)) == true then
                evtData.damage = evtData.damage * 1.3
            end
        end
    )

    -- 武器战攻击事件
    hevent.register(
        whichUnit,
        CONST_EVENT.beforeAttackDamage,
        "wuqizhan_attack",
        function(evtData)
            local jichujiange = hattribute.getWithLimit(evtData.sourceUnit, nil, "attack_space_origin", 2.0)
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("猝死")) and math_random(1, 100) <= 10 then
                heffect.attach("war3mapImported\\AZ_LCDark_T1_overhead.MDX", evtData.sourceUnit, "overhead")
                hbuff.update(
                    10,
                    whichUnit,
                    "猝死",
                    true,
                    nil,
                    nil,
                    hslk.n2v("猝死", "Art"),
                    "斩杀可以无视目标生命百分百释放",
                    nil,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE
                )
                hskill.setCoolDown(evtData.sourceUnit, hslk.n2i("斩杀"), 0)
            end
            local zhanshathreshold = 20
            if hmingwen.isEquipped("狂热斩杀", hunit.getOwner(evtData.sourceUnit)) then
                zhanshathreshold = 35
            end
            if hunit.getCurLifePercent(evtData.targetUnit) <= zhanshathreshold then
                hskill.setCoolDown(
                    whichUnit,
                    hslk.n2i("斩杀"),
                    math.min(3, hskill.getCoolDown(whichUnit, hslk.n2i("斩杀")))
                )
            end
        end
    )

    -- 武器战攻击伤害前事件
    hevent.register(
        whichUnit,
        CONST_EVENT.beforeAttackDamage,
        "wuqizhan_before_attack",
        function(evtData)
            local jichujiange = hattribute.getWithLimit(evtData.sourceUnit, nil, "attack_space_origin", 2.0)
            hunit.addCurMana(evtData.sourceUnit, 3 * jichujiange)
            if hcache.get(evtData.sourceUnit, "[T1]无畏勇士套装(3件)", false) then
                hunit.addCurMana(evtData.sourceUnit, 2)
            elseif hzhuangbeishouji.isActive(hunit.getOwner(evtData.sourceUnit), "[T1]无畏勇士套装") then
                hunit.addCurMana(evtData.sourceUnit, 1)
            end
            if
                hskill.hasActiveAbility(whichUnit, hslk.n2i("顺劈斩")) and
                htime.setupAndCheckCoolDown(whichUnit, hslk.n2i("顺劈斩"), WUQIZHAN_CD[hslk.n2i("顺劈斩")])
            then
                shunpizhan(whichUnit, "war3mapImported\\AZ_Z041.mdx", hunit.getFacing(whichUnit))
            end
            if
                hskill.hasActiveAbility(evtData.sourceUnit, hslk.n2i("致死打击")) and
                htime.setupAndCheckCoolDown(evtData.sourceUnit, hslk.n2i("致死打击"), WUQIZHAN_CD[hslk.n2i("致死打击")]) and
                (hbuff.hasBuff(evtData.sourceUnit, "战争领主") or hunit.getCurMana(evtData.sourceUnit) > 80)
            then
                zhisidaji(evtData.sourceUnit, evtData.targetUnit, hslk.n2i("致死打击"))
                return
            end
            local mengjiCD = WUQIZHAN_CD[hslk.n2i("猛击")]
            if hskill.hasActiveAbility(evtData.sourceUnit, hslk.n2i("灭战者")) then
                mengjiCD = mengjiCD - 6
            end
            if
                hskill.hasActiveAbility(evtData.sourceUnit, hslk.n2i("猛击")) and
                htime.setupAndCheckCoolDown(evtData.sourceUnit, hslk.n2i("猛击"), mengjiCD)
            then
                mengji(evtData.sourceUnit, evtData.targetUnit, hslk.n2i("猛击"))
                return
            end
            if
                hskill.hasActiveAbility(evtData.sourceUnit, hslk.n2i("压制")) and
                htime.setupAndCheckCoolDown(evtData.sourceUnit, hslk.n2i("压制"), WUQIZHAN_CD[hslk.n2i("压制")])
            then
                yazhi(evtData.sourceUnit, evtData.targetUnit, hslk.n2i("压制"))
                return
            end
        end
    )

    hevent.register(
        whichUnit,
        CONST_EVENT.useMana,
        "wuqizhan_nuqixiaohao",
        function(evtData)
            local whichPlayer = hunit.getOwner(whichUnit)
            local points = htianfu.getActiveTianfuLevel(whichPlayer, "战术专家")
            if points > 0 then
                local rate = evtData.value * points * 0.2
                local snsqpoints = htianfu.getActiveTianfuLevel(whichPlayer, "熟能生巧")
                if snsqpoints > 0 then
                    rate = rate * (1 + 0.1 * snsqpoints)
                end
                if math.random(0, 1000) <= rate * 10 then
                    htime.clearCoolDown(whichUnit, hslk.n2i("压制"))
                    htextTag.create2Unit(whichUnit, "战术专家", 6, "ff3300", 1, 1, 50)
                end
            end
            local points = htianfu.getActiveTianfuLevel(whichPlayer, "愤怒掌控")
            if points > 0 then
                local cooldownRedLRFB = 0.2 * points / 20 * evtData.value
                hskill.setCoolDown(
                    evtData.triggerUnit,
                    hslk.n2i("利刃风暴"),
                    math.max(0, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("利刃风暴")) - cooldownRedLRFB)
                )
                local cooldownRedJRDJ = 0.1 * points / 20 * evtData.value
                hskill.setCoolDown(
                    evtData.triggerUnit,
                    hslk.n2i("巨人打击"),
                    math.max(0, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("巨人打击")) - cooldownRedJRDJ)
                )
            end
        end
    )
end
