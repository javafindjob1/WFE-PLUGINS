---被动技能cd类常数
local SHEJILIEREN_CD = {}
SHEJILIEREN_CD["瞄准射击"] = 6
SHEJILIEREN_CD["奥术射击"] = 12

local LIEREN_JINGTONG_XISHU = 10

local SHOWHU_CONFIG = {
    {
        name = "雄鹰守护",
        description = "雄鹰守护：攻击力提高15%",
        art = "ReplaceableTextures\\lieren\\Spell_Hunter_AspectOfTheIronHawk.blp",
        event = CONST_EVENT.attr,
        action = _attr({ gongji_baifenbi = "+15" })
    },
    {
        name = "猎豹守护",
        description = "猎豹守护：移动提高30点，攻击速度提高20%",
        art = "ReplaceableTextures\\lieren\\Ability_Mount_JungleTiger.blp",
        event = CONST_EVENT.attr,
        action = _attr({ move = "+30", attack_speed = "+20" })
    },
    {
        name = "灵龙守护",
        description = "灵龙守护：基础射击能量恢复值提高3点",
        art = "ReplaceableTextures\\CommandButtons\\BTNFaerieDragon.blp",
        event = CONST_EVENT.damage,
        action = function(evtData)
            if evtData.triggerSkill == hslk.n2i("基础射击") then
                hunit.addCurMana(evtData.triggerUnit, 3)
            end
        end
    }
}

local miaozhunsheji
local aoshusheji
local fengxingzhedekuizeng = function(sourceUnit, targetUnit, delay)
    if hunit.isDead(targetUnit) then
        return
    end
    htime.setTimeout(
        delay,
        function(curTimer)
            local damage =
                (hattr.getWithLimit(sourceUnit, nil, "agi", 0) + hattr.getWithLimit(sourceUnit, nil, "attack", 0)) *
                0.33
            hsound.voice2Unit(
                hsound.voiceCreate("resource\\war3mapImported\\sound\\fire_cast.wav", 1000, true),
                90,
                sourceUnit
            )
            local model = "[lieren]jianshi.mdl"
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "风行者的祝福")
            local damageType = DAMAGE_TYPE.MOFA
            if points > 0 then
                if math.random(1, 100) <= 2 * points then
                    damage = damage * 5
                    model = "war3mapImported\\[lieren]kuangfengsheji_lr_AZ.mdl"
                    damageType = DAMAGE_TYPE.WULI
                end
            end
            hskillMoban.missile(
                {
                    model = model,
                    scale = 1,
                    speed = 1200,
                    hover = 100,
                    sourceUnit = sourceUnit,
                    targetUnit = targetUnit,
                    target_face_dis = 10,
                    target_face_left = 0,
                    onEnd = function()
                        hskill.damage(
                            {
                                sourceUnit = sourceUnit,
                                targetUnit = targetUnit,
                                damage = damage,
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = damageType,
                                triggerSkill = hslk.n2i("风行者的馈赠"),
                                isAttackReplacement = false,
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                shanghainame = "风行者的馈赠",
                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD }
                            }
                        )
                        hunit.addCurMana(sourceUnit, 1)
                        hbuff.addStackAttrBuff(
                            CONST_DAMAGE_SRC.skill,
                            sourceUnit,
                            "风行者的馈赠增伤",
                            _attr({ skill_speed = "+0.5", attack_speed = "+1" }),
                            10,
                            20,
                            hslk.n2v("风行者的馈赠", "Art"),
                            "每层增加0.5%技能加速和1%的攻击速度",
                            true
                        )
                    end
                }
            )
        end
    )
end

local dushedingcixiaoguo = function(sourceUnit, targetUnit)
    local damage = hattr.get(sourceUnit, "agi", 0) * 0.8

    local interval = 2
    local skillspeedfactor = (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)) / 100
    interval = math.round(interval / skillspeedfactor)
    hbuff.update(
        16,
        targetUnit,
        "毒蛇钉刺" .. tostring(sourceUnit),
        false,
        function()
            hattribute.set(targetUnit, 0, _attr({ move = "-20" }))
        end,
        function()
            hattribute.set(targetUnit, 0, _attr({ move = "+20" }))
        end,
        hslk.n2v("毒蛇钉刺", "Art"),
        "毒蛇钉刺|n 每" .. interval .. "秒受到一次自然魔法伤害",
        1,
        interval,
        function(_, buffHandle)
            buffHandle.remainingTime = buffHandle.remainingTime - buffHandle.interval
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = targetUnit,
                    damage = damage,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.MOFA,
                    triggerSkill = hslk.n2i("毒蛇钉刺"),
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                    shanghainame = "毒蛇钉刺",
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD }
                }
            )
            if hmingwen.isEquipped("蝰蛇钉刺", hunit.getOwner(sourceUnit)) then
                hunit.addCurMana(sourceUnit, 2)
            end
            if hcache.get(sourceUnit, "[T2]追猎者套装(3件)", false) then
                hunit.addCurMana(sourceUnit, 2)
            elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T2]追猎者套装") then
                hunit.addCurMana(sourceUnit, 1)
            end
            if hmingwen.isEquipped("水蛭钉刺", hunit.getOwner(sourceUnit)) then
                hskill.heal(
                    {
                        healer = sourceUnit,
                        healee = sourceUnit,
                        heal = hunit.getMaxLife(sourceUnit) * 0.01,
                        effect = nil,
                        healType = HEAL_TYPE.SKILL,
                        triggerSkill = hslk.n2i("毒蛇钉刺")
                    }
                )
            end
            heffect.attach("Abilities\\Weapons\\PoisonSting\\PoisonStingTarget.mdl", targetUnit, "chest", 0.1)
        end,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
end

SKILLS["毒蛇钉刺"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local targetUnit = evtData.targetUnit
    if hunit.isAlive(targetUnit) == false then
        return
    end
    hunit.animate(sourceUnit, "attack")
    hskillMoban.missile(
        {
            model = "war3mapImported\\[LIEREN]DUJIAN.mdl",
            scale = 1,
            speed = 1200,
            hover = 100,
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            target_face_dis = 10,
            onEnd = function()
                if hunit.isAlive(targetUnit) == false then
                    return
                end
                dushedingcixiaoguo(sourceUnit, targetUnit)
            end
        }
    )
end

SKILLS["哀痛之箭"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local x = evtData.targetX
    local y = evtData.targetY
    hunit.animate(sourceUnit, "attack")
    local damage = hattr.get(sourceUnit, "attack", 0) * 0.5
    htime.setTimeout(
        0.25,
        function(curTimer)
            hsound.voice2Unit(
                hsound.voiceCreate("resource\\war3mapImported\\sound\\fire_cast.wav", 1000, true),
                90,
                sourceUnit
            )
            hskillMoban.missile(
                {
                    model = "war3mapImported\\effect_AZ_Drak_Arrow - 3.mdl",
                    scale = 1,
                    speed = 2400,
                    hover = 100,
                    sourceUnit = sourceUnit,
                    targetX = x,
                    targetY = y,
                    height = 300,
                    target_face_dis = 10,
                    onEnd = function()
                        local units = hgroup.createEnermyGroupByXY(sourceUnit, x, y, 300, true)
                        heffect.xyz("war3mapImported\\effect_AZ_Drak_Arrow - 2.mdx", x, y, hjapi.Z(x, y), 0, 1)
                        for _, unit in ipairs(units) do
                            hskill.damage(
                                {
                                    sourceUnit = sourceUnit,
                                    targetUnit = unit,
                                    damage = damage,
                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                    damageType = DAMAGE_TYPE.MOFA,
                                    triggerSkill = hslk.n2i("哀痛之箭"),
                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                    shanghainame = "哀痛之箭",
                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK }
                                }
                            )
                            hbuff.xuanyun(unit, 0.3)
                        end
                    end
                }
            )
        end
    )
end

SKILLS["守护"] = function(evtData)
    local whichUnit = evtData.triggerUnit
    local status = hcache.get(whichUnit, "SHOUHU_CURRENT")
    if status == nil then
        status = 1
    elseif status >= #SHOWHU_CONFIG then
        local config = SHOWHU_CONFIG[#SHOWHU_CONFIG]
        if config.event == CONST_EVENT.attr then
            hattribute.caleAttribute(CONST_DAMAGE_SRC.skill, false, whichUnit, config.action, 1)
        else
            hevent.unregister(whichUnit, config.event, "SHOUHU" .. tostring(#SHOWHU_CONFIG))
        end
        status = 1
    else
        local config = SHOWHU_CONFIG[status]
        if config.event == CONST_EVENT.attr then
            hattribute.caleAttribute(CONST_DAMAGE_SRC.skill, false, whichUnit, config.action, 1)
        else
            hevent.unregister(whichUnit, config.event, "SHOUHU" .. tostring(#SHOWHU_CONFIG))
        end
        status = status + 1
    end
    echo("激活:" .. SHOWHU_CONFIG[status].name, hunit.getOwner(whichUnit))
    hcache.set(whichUnit, "SHOUHU_CURRENT", status)
    local config = SHOWHU_CONFIG[status]
    if config.event == CONST_EVENT.attr then
        hattribute.caleAttribute(CONST_DAMAGE_SRC.skill, true, whichUnit, config.action, 1)
    else
        hevent.register(whichUnit, config.event, "SHOUHU" .. tostring(#SHOWHU_CONFIG), config.action)
    end

    hbuff.update(
        0,
        whichUnit,
        "守护",
        true,
        nil,
        nil,
        SHOWHU_CONFIG[status].art,
        SHOWHU_CONFIG[status].description,
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        false
    )
end

SKILLS["多重射击"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local x = evtData.targetX
    local y = evtData.targetY
    hunit.animate(sourceUnit, "attack")
    local damage = hattr.get(sourceUnit, "attack", 0)
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "齐射")
    if hbuff.hasBuff(sourceUnit, "齐射") then
        damage = damage * (1 + 0.1 * points)
        hbuff.delete(sourceUnit, "齐射")
    end
    if points > 0 then
        hbuff.update(
            10,
            sourceUnit,
            "齐射",
            true,
            nil,
            nil,
            hslk.n2v("射击技巧", "Art"),
            "下一次多重射击伤害提高" .. 10 * points .. "%",
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
        0.25,
        function(curTimer)
            hsound.voice2Unit(
                hsound.voiceCreate("resource\\war3mapImported\\sound\\fire_cast.wav", 1000, true),
                90,
                sourceUnit
            )
            local units = hgroup.createEnermyGroupByXY(sourceUnit, x, y, 300, true)
            for _, unit in ipairs(units) do
                hskillMoban.missile(
                    {
                        model = "war3mapImported\\[lieren]SylvanusWindrunnePFr_Attack.mdl",
                        scale = 1,
                        speed = 1200,
                        hover = 100,
                        sourceUnit = sourceUnit,
                        targetUnit = unit,
                        target_face_dis = 10,
                        onEnd = function()
                            hskill.damage(
                                {
                                    sourceUnit = sourceUnit,
                                    targetUnit = unit,
                                    damage = damage,
                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                    damageType = DAMAGE_TYPE.WULI,
                                    triggerSkill = hslk.n2i("多重射击"),
                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                    shanghainame = "多重射击",
                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
                                }
                            )

                            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("射击技巧")) then
                                hbuff.update(
                                    10,
                                    unit,
                                    "射击技巧" .. tostring(sourceUnit),
                                    false,
                                    nil,
                                    nil,
                                    hslk.n2v("射击技巧", "Art"),
                                    "猎人的瞄准射击和奥术射击会额外对改目标释放，释放后会消耗该效果",
                                    1,
                                    nil,
                                    nil,
                                    nil,
                                    nil,
                                    HBUFF_UPDATE_MODE.OVERWRITE,
                                    true
                                )
                            end
                            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "巨蛇追猎者的诡计")
                            if points > 0 then
                                if math.random(1, 100) <= 5 * points then
                                    dushedingcixiaoguo(sourceUnit, unit)
                                end
                            end
                        end
                    }
                )
            end
        end
    )
end

SKILLS["百发百中"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local duration = 15
    heffect.attach("war3mapImported\\origin_win_AZ.MDX", evtData.triggerUnit, "origin", duration)
    heffect.attach("war3mapImported\\ZB_LongJi.mdx", evtData.triggerUnit, "origin", 0)
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\3553.mp3", 1000, true),
        100,
        evtData.triggerUnit
    )
    hunit.addCurMana(sourceUnit, 200)
    hbuff.update(
        duration,
        sourceUnit,
        "百发百中",
        true,
        function()
            hattr.set(sourceUnit, 0, _attr({ skill_speed = "+20", attack_speed = "+30" }))
        end,
        function()
            hattr.set(sourceUnit, 0, _attr({ skill_speed = "-20", attack_speed = "-30" }))
        end,
        hslk.n2v("百发百中", "Art"),
        hslk.n2v("百发百中", "Ubertip"),
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE
    )
    htime.clearCoolDown(sourceUnit, "瞄准射击CD")
    htime.clearCoolDown(sourceUnit, "奥术射击CD")
end

local kuaisusheji = function(evtData)
end

SKILL_ON_LEVEL_UP["射击猎"] = function(whichUnit)
    local qiangjiguanghuan = hslk.n2i("强击光环")
    if hskill.hasActiveAbility(whichUnit, qiangjiguanghuan) then
        hskillMoban.guanghuan(
            whichUnit,
            qiangjiguanghuan,
            2000,
            hslk.i2v(qiangjiguanghuan, "_guanghuanAttr"),
            true,
            true,
            "强击光环|n7%攻击|n3%命中"
        )
        hskill.addProperty(whichUnit, qiangjiguanghuan, 1)
    end
end

local setup_kuaisusheji = function(whichUnit)
    hskill.setup_zhudong_jineng(
        whichUnit,
        hslk.n2i("快速射击"),
        function(evtData)
        end,
        function(whichUnit, targetUnit)
            local shifashijian = 3.5
            local numberjian = 5
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("兽神守护")) and hcache.get(whichUnit, "SHOUHU_CURRENT") == 2 then
                numberjian = numberjian + 1
            end
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "光速射击")
            if points >= 2 then
                numberjian = numberjian + 1
            end
            if points >= 5 then
                numberjian = numberjian + 1
            end
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("急速射击")) then
                shifashijian = shifashijian - 0.5
                numberjian = numberjian + 1
            end
            if hmingwen.isEquipped("强化快速射击", hunit.getOwner(whichUnit)) then
                numberjian = numberjian + 1
            end
            local attack_speed = hattr.getWithLimit(whichUnit, nil, "attack_speed", 0)
            shifashijian = shifashijian * 100 / (100 + attack_speed)
            local interval = math.max(0.1, math.ceil(shifashijian / numberjian * 100) / 100)
            return interval * numberjian + 0.01
        end,
        function(whichUnit)
            hunit.animate(whichUnit, "attack")
        end,
        nil,
        function(whichUnit, targetUnit)
            local shifashijian = 3.5
            local numberjian = 5
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("兽神守护")) and hcache.get(whichUnit, "SHOUHU_CURRENT") == 2 then
                numberjian = numberjian + 1
            end
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "光速射击")
            if points >= 2 then
                numberjian = numberjian + 1
            end
            if points >= 5 then
                numberjian = numberjian + 1
            end
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("急速射击")) then
                shifashijian = shifashijian - 0.5
                numberjian = numberjian + 1
            end
            if hmingwen.isEquipped("强化快速射击", hunit.getOwner(whichUnit)) then
                numberjian = numberjian + 1
            end
            local attack_speed = hattr.getWithLimit(whichUnit, nil, "attack_speed", 0)
            shifashijian = shifashijian * 100 / (100 + attack_speed)
            local interval = math.max(0.1, math.ceil(shifashijian / numberjian * 100) / 100)
            return interval
        end,
        function(whichUnit, targetUnit)
            local damage = (hattr.get(whichUnit, "attack", 0) + hattr.get(whichUnit, "agi", 0))
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("兽神守护")) and hcache.get(whichUnit, "SHOUHU_CURRENT") == 2 then
                damage = damage * 1.05
            end
            if hcache.get(whichUnit, "[T3]暗影猎手套装(4件)", false) then
                damage = damage * 1.1
            elseif hzhuangbeishouji.isActive(hunit.getOwner(whichUnit), "[T3]暗影猎手套装") then
                damage = damage * 1.05
            end
            hsound.voice2Unit(
                hsound.voiceCreate("resource\\war3mapImported\\sound\\fire_cast.wav", 1000, true),
                90,
                whichUnit
            )
            local units = { targetUnit }
            for _, unit in ipairs(units) do
                local ksassjPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "奥术快速射击")
                local mzkssjPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "瞄准快速射击")
                if mzkssjPoints > 0 and math.random(1, 100) <= 5 * mzkssjPoints then
                    miaozhunsheji(whichUnit, unit, false)
                elseif ksassjPoints > 0 and math.random(1, 100) <= 5 * ksassjPoints then
                    aoshusheji(whichUnit, unit, 0)
                else
                    hskillMoban.missile(
                        {
                            model = "war3mapImported\\[lieren]SylvanusWindrunnePFr_Attack.mdl",
                            scale = 1,
                            speed = 1200,
                            hover = 100,
                            sourceUnit = whichUnit,
                            targetUnit = unit,
                            target_face_dis = 10,
                            onEnd = function()
                                hskill.damage(
                                    {
                                        sourceUnit = whichUnit,
                                        targetUnit = unit,
                                        damage = damage,
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.WULI,
                                        triggerSkill = hslk.n2i("快速射击"),
                                        isAttackReplacement = true,
                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                        shanghainame = "快速射击",
                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
                                    }
                                )
                            end
                        }
                    )
                end
            end
            hunit.animate(whichUnit, "attack")
            heffect.xyz(
                "war3mapImported\\[Spell]_020 - 1.mdx",
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
                math.angle(hunit.x(whichUnit), hunit.y(whichUnit), hunit.x(targetUnit), hunit.y(targetUnit))
            )
        end
    )
end
local jichusheji = function(triggerUnit, targetUnit)
    local damage = hattr.get(triggerUnit, "attack", 0)
    if hshangcheng.hasItem(hunit.getOwner(triggerUnit), "见习射击猎") then
        damage = damage * 1.05
    end
    local manaBack = 1
    if
        hcache.get(triggerUnit, "[T1]猎杀者套装(3件)", false) or
        hzhuangbeishouji.isActive(hunit.getOwner(triggerUnit), "[T1]猎杀者套装")
    then
        manaBack = manaBack + 0.5
    end
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\fire_cast.wav", 1000, true),
        90,
        triggerUnit
    )
    local chuantouRate = 0
    local maxChuantou = 0
    local chuantouPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(triggerUnit), "穿透箭")
    if chuantouPoints > 0 then
        chuantouRate = chuantouPoints * 5
        maxChuantou = 3
    end
    local model = "war3mapImported\\[lieren]SylvanusWindrunnePFr_Attack.mdl"
    local zhushouitem = hunit.getEquipmentAtPosition(triggerUnit, EQUIPMENT_SLOT_ID.zhushou)
    local damageType = DAMAGE_TYPE.WULI
    if zhushouitem ~= nil and hslk.i2v(zhushouitem.basic_item_id, "Name") == "群星之怒·烈阳" then
        local nandu = zhushouitem.nandu
        damage = damage * (1 + 0.02 * nandu)
        model = "[lieren]SpiritArrow_ByEpsilon_2.mdx"
        damageType = DAMAGE_TYPE.MOFA
    elseif zhushouitem ~= nil and hslk.i2v(zhushouitem.basic_item_id, "Name") == "群星之怒·暗月" then
        local nandu = zhushouitem.nandu
        damage = damage * (1 + 0.02 * nandu)
    end

    hskillMoban.missile(
        {
            model = model,
            scale = 1,
            speed = 1200,
            hover = 100,
            sourceUnit = triggerUnit,
            targetUnit = targetUnit,
            target_face_dis = 10,
            chauntouRate = chuantouRate, --穿透概率
            chuantouDistance = 300,      --穿透距离
            maxChuantou = maxChuantou,   --最大穿透次数
            ctssDistance = 500,          --穿透后的间隔距离
            onEnd = function(_, curTargetUnit, _, _)
                hskill.damage(
                    {
                        sourceUnit          = triggerUnit,
                        targetUnit          = curTargetUnit,
                        damage              = damage,
                        damageSrc           = CONST_DAMAGE_SRC.skill,
                        damageType          = damageType,
                        triggerSkill        = hslk.n2i("基础射击"),
                        isAttackReplacement = true,
                        damageSpeedType     = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                        shanghainame        = "基础射击",
                        damageElementType   = { CONST_DAMAGE_ELEMENT_TYPE.METAL }
                    }
                )
            end
        }
    )
    hunit.addCurMana(triggerUnit, manaBack)

    local rate = 10

    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(triggerUnit), "强化荷枪实弹")
    if points > 0 then
        rate = rate + points
    end
    if hskill.hasActiveAbility(triggerUnit, hslk.n2i("荷枪实弹")) and math.random(1, 100) <= rate then
        htime.clearCoolDown(triggerUnit, "瞄准射击CD")
        htextTag.create2Unit(triggerUnit, "荷枪实弹", 6, "ff3300", 1, 1, 50)
    end
end

miaozhunsheji = function(sourceUnit, targetUnit, cantriggerGaoxiaomiaozhun)
    local damage = 2 * (hattr.get(sourceUnit, "attack", 0) + hattr.get(sourceUnit, "agi", 0))
    if hcache.get(sourceUnit, "[T1]猎杀者套装(4件)", false) then
        if math.random(1, 100) <= 15 then
            damage = damage * 2
        end
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T1]猎杀者套装") then
        if math.random(1, 100) <= 5 then
            damage = damage * 2
        end
    end
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("兽神守护")) and hcache.get(sourceUnit, "SHOUHU_CURRENT") == 1 then
        damage = damage * 1.08
    end
    if hcache.get(sourceUnit, "[T3]暗影猎手套装(3件)", false) then
        damage = damage * 1.04
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T3]暗影猎手套装") then
        damage = damage * 1.02
    end
    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\fire_cast.wav", 1000, true), 90, sourceUnit)
    local units = { targetUnit }
    hgroup.createByUnit(
        sourceUnit,
        1500,
        function(unit)
            if
                hunit.isEnemy(sourceUnit, unit) == true and hunit.isAlive(unit) and
                hbuff.hasBuff(unit, "射击技巧" .. tostring(sourceUnit))
            then
                if unit ~= targetUnit then
                    table.insert(units, unit)
                end
                hbuff.delete(unit, "射击技巧" .. tostring(sourceUnit))
            end
        end
    )

    local model = "war3mapImported\\[lieren]miaozhunsheji2.mdl"
    local zhushouitem = hunit.getEquipmentAtPosition(sourceUnit, EQUIPMENT_SLOT_ID.zhushou)
    local damageType = DAMAGE_TYPE.WULI
    if zhushouitem ~= nil and hslk.i2v(zhushouitem.basic_item_id, "Name") == "群星之怒·烈阳" then
        local nandu = zhushouitem.nandu
        damage = damage * (1 + 0.02 * nandu)
        model = "StarArrow.mdx"
        damageType = DAMAGE_TYPE.MOFA
    elseif zhushouitem ~= nil and hslk.i2v(zhushouitem.basic_item_id, "Name") == "群星之怒·暗月" then
        local nandu = zhushouitem.nandu
        damage = damage * (1 + 0.02 * nandu)
    end
    for _, unit in ipairs(units) do
        hskillMoban.missile(
            {
                model = model,
                scale = 1,
                speed = 1500,
                hover = 100,
                sourceUnit = sourceUnit,
                targetUnit = unit,
                target_face_dis = 10,
                onEnd = function()
                    hskill.damage(
                        {
                            sourceUnit = sourceUnit,
                            targetUnit = unit,
                            damage = damage,
                            damageSrc = CONST_DAMAGE_SRC.skill,
                            damageType = damageType,
                            triggerSkill = hslk.n2i("瞄准射击"),
                            isAttackReplacement = true,
                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                            shanghainame = "瞄准射击",
                            damageElementType = CONST_DAMAGE_ELEMENT_TYPE.METAL
                        }
                    )
                    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "猎人标记")
                    if points > 0 then
                        if math.random(1, 100) <= 20 * points then
                            local e = heffect.attach("war3mapImported\\[Spell]_028.mdx", unit, "over head", 5)
                            hbuff.update(
                                5,
                                unit,
                                "猎人标记",
                                true,
                                function()
                                    hevent.register(
                                        unit,
                                        CONST_EVENT.damagingCustomTarget,
                                        "猎人标记",
                                        function(evtData)
                                            if hunit.getName(evtData.sourceUnit) == "射击猎" then
                                                evtData.damage = evtData.damage * 1.06
                                            else
                                                evtData.damage = evtData.damage * 1.03
                                            end
                                        end
                                    )
                                end,
                                function()
                                    hevent.unregister(unit, CONST_EVENT.damagingCustomTarget, "猎人标记")
                                    heffect.destroy(e)
                                end,
                                "ReplaceableTextures\\lieren\\Ability_Hunter_SniperShot.blp",
                                "猎人标记|n受到的伤害提高3%",
                                1,
                                nil,
                                nil,
                                nil,
                                nil,
                                HBUFF_UPDATE_MODE.OVERWRITE,
                                true
                            )
                        end
                    end
                end
            }
        )
        if hskill.hasActiveAbility(sourceUnit, hslk.n2i("风行者的馈赠")) then
            fengxingzhedekuizeng(sourceUnit, unit, 0.2)
            fengxingzhedekuizeng(sourceUnit, unit, 0.4)
        end
    end

    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "强化高效瞄准")
    local rate = 15
    if points > 0 then
        rate = rate + points
    end
    if
        cantriggerGaoxiaomiaozhun and hskill.hasActiveAbility(sourceUnit, hslk.n2i("高效瞄准")) and
        math.random(1, 100) <= rate
    then
        hskill.setCoolDown(sourceUnit, hslk.n2i("快速射击"), 0)
        htextTag.create2Unit(sourceUnit, "高效瞄准", 6, "ff3300", 1, 1, 50)
    end
    local zhimingmiaozhunPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "致命瞄准射击")
    if zhimingmiaozhunPoints > 0 then
        local bonusCrit = zhimingmiaozhunPoints * 0.2
        hbuff.addStackAttrBuff(
            CONST_DAMAGE_SRC.skill,
            sourceUnit,
            "致命瞄准射击",
            _attr({ wu_bao = "+" .. bonusCrit }),
            8,
            8,
            hslk.n2v("瞄准射击", "Art"),
            "致命瞄准射击：每层提高" .. bonusCrit .. "%物理暴击率",
            true
        )
    end
end

local danciaoshusheji = nil
danciaoshusheji = function(sourceUnit, targetUnit, damage, tanshe, missileStartUnit)
    local finalMissileStartUnit = missileStartUnit or sourceUnit
    local model = "war3mapImported\\[lieren]SpiritArrow_ByEpsilon.mdl"
    local zhushouitem = hunit.getEquipmentAtPosition(sourceUnit, EQUIPMENT_SLOT_ID.zhushou)
    local damageType = DAMAGE_TYPE.MOFA
    if zhushouitem ~= nil and hslk.i2v(zhushouitem.basic_item_id, "Name") == "群星之怒·烈阳" then
        local nandu = zhushouitem.nandu
        damage = damage * (1 + 0.02 * nandu)
        model = "StarDust_orange.mdx"
    elseif zhushouitem ~= nil and hslk.i2v(zhushouitem.basic_item_id, "Name") == "群星之怒·暗月" then
        local nandu = zhushouitem.nandu
        damage = damage * (1 + 0.02 * nandu)
        model = "StarDust.mdx"
        damageType = DAMAGE_TYPE.WULI
    end
    hskillMoban.missile(
        {
            model = model,
            scale = 1,
            speed = 1200,
            hover = 100,
            sourceUnit = finalMissileStartUnit,
            targetUnit = targetUnit,
            target_face_dis = 10,
            onEnd = function()
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = targetUnit,
                        damage = damage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = damageType,
                        triggerSkill = hslk.n2i("奥术射击"),
                        isAttackReplacement = true,
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                        shanghainame = "奥术射击",
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE }
                    }
                )
                if tanshe > 0 then
                    local bounceUnits =
                        hgroup.createEnermyGroupByXY(sourceUnit, hunit.x(targetUnit), hunit.y(targetUnit), 500)
                    table.delete(bounceUnits, targetUnit)
                    if #bounceUnits > 0 then
                        local bounceUnit = table.random(bounceUnits, 1)
                        danciaoshusheji(sourceUnit, bounceUnit, damage, tanshe - 1, targetUnit)
                    end
                end
            end
        }
    )
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("风行者的馈赠")) then
        fengxingzhedekuizeng(sourceUnit, targetUnit, 0.2)
        fengxingzhedekuizeng(sourceUnit, targetUnit, 0.4)
    end
    local zhimingaoshuPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "致命奥术射击")
    if zhimingaoshuPoints > 0 then
        local bonusCrit = zhimingaoshuPoints * 0.2
        hbuff.addStackAttrBuff(
            CONST_DAMAGE_SRC.skill,
            sourceUnit,
            "致命奥术射击",
            _attr({ fa_bao = "+" .. bonusCrit }),
            8,
            8,
            hslk.n2v("奥术射击", "Art"),
            "致命奥术射击：每层提高" .. bonusCrit .. "%法术暴击率",
            true
        )
    end
end

aoshusheji = function(sourceUnit, targetUnit, cost)
    if cost ~= nil and cost > 0 then
        hunit.subCurMana(sourceUnit, cost)
    end
    local damage = 3 * hattr.get(sourceUnit, "agi", 0)
    if hcache.get(sourceUnit, "[T2]追猎者套装(4件)", false) then
        damage = damage * 1.1
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T2]追猎者套装") then
        damage = damage * 1.05
    end
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("兽神守护")) and hcache.get(sourceUnit, "SHOUHU_CURRENT") == 3 then
        damage = damage * 1.05
    end
    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\fire_cast.wav", 1000, true), 90, sourceUnit)
    local units = { targetUnit }
    hgroup.createByUnit(
        sourceUnit,
        1500,
        function(unit)
            if
                hunit.isEnemy(sourceUnit, unit) == true and hunit.isAlive(unit) and
                hbuff.hasBuff(unit, "射击技巧" .. tostring(sourceUnit))
            then
                if unit ~= targetUnit then
                    table.insert(units, unit)
                end
                hbuff.delete(unit, "射击技巧" .. tostring(sourceUnit))
            end
        end
    )
    for _, unit in ipairs(units) do
        local tanshe = 0
        if hmingwen.isEquipped("奥术弹射", hunit.getOwner(sourceUnit)) then
            tanshe = 1
        end
        danciaoshusheji(sourceUnit, unit, damage, tanshe)
    end
end

SKILL_SETUP["射击猎"] = function(whichUnit)
    --基础回蓝1
    hattribute.set(whichUnit, 0, { mana_back = "=3" })
    hskill.registerAutoCast(whichUnit, hslk.n2i("毒蛇钉刺"))
    hskill.registerAutoCast(whichUnit, hslk.n2i("快速射击"))
    hskill.registerMonitoringBuff(whichUnit, "毒蛇钉刺" .. tostring(whichUnit), false)
    hskill.registerMonitoringBuff(whichUnit, "百发百中", true)
    setup_kuaisusheji(whichUnit)
    hevent.register(
        whichUnit,
        CONST_EVENT.damagingCustomSource,
        "baibuchuanyang",
        function(evtData)
            if evtData.damageSpeedType == CONST_DAMAGE_SPEED_TYPE.DOT then
                return
            end
            if evtData.sourceUnit ~= whichUnit then
                err("Incorrect unit")
                return
            end
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("百步穿杨")) == false then
                return
            end
            local jingtong = hattribute.getWithLimit(whichUnit, nil, "master", 0)
            local maxZengShang = jingtong / LIEREN_JINGTONG_XISHU + 20
            local distance =
                math.distance(
                    hunit.x(evtData.sourceUnit),
                    hunit.y(evtData.sourceUnit),
                    hunit.x(evtData.targetUnit),
                    hunit.y(evtData.targetUnit)
                )
            local minZengshang = maxZengShang / 2
            local zengshang = (math.min(1, distance / 800) * (maxZengShang - minZengshang) + minZengshang + 100) / 100
            evtData.damage = evtData.damage * zengshang
        end
    )

    -- 射击猎人攻击
    hevent.register(
        whichUnit,
        CONST_EVENT.beforeAttackDamage,
        "shejilieren_attack",
        function(evtData)
            evtData.damage = 0
            local miaozhuncd = SHEJILIEREN_CD["瞄准射击"]
            local aoshushejicost = 40
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("兽神守护")) and hcache.get(whichUnit, "SHOUHU_CURRENT") == 3 then
                aoshushejicost = aoshushejicost - 3
            end
            if hcache.get(whichUnit, "[T2]追猎者套装(4件)", false) then
                aoshushejicost = aoshushejicost - 5
            elseif hzhuangbeishouji.isActive(hunit.getOwner(whichUnit), "[T2]追猎者套装") then
                aoshushejicost = aoshushejicost - 2
            end
            if hmingwen.isEquipped("快速瞄准", hunit.getOwner(whichUnit)) then
                miaozhuncd = miaozhuncd - 1
            end
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("兽神守护")) and hcache.get(whichUnit, "SHOUHU_CURRENT") == 1 then
                miaozhuncd = miaozhuncd - 0.5
            end
            if hbuff.hasBuff(whichUnit, "百发百中") then
                miaozhuncd = miaozhuncd / 2
                aoshushejicost = aoshushejicost / 2
            end
            if
                hskill.hasActiveAbility(whichUnit, hslk.n2i("瞄准射击")) == true and
                htime.setupAndCheckCoolDown(whichUnit, "瞄准射击CD", miaozhuncd)
            then
                miaozhunsheji(whichUnit, evtData.targetUnit, true)
                return
            end

            if hskill.hasActiveAbility(whichUnit, hslk.n2i("奥术射击")) and hunit.getCurMana(whichUnit) > 60 then
                aoshusheji(whichUnit, evtData.targetUnit, aoshushejicost)
                if hmingwen.isEquipped("魔武双修", hunit.getOwner(whichUnit)) == false then
                    return
                end
            end
            jichusheji(evtData.sourceUnit, evtData.targetUnit)
        end
    )
    hevent.register(
        whichUnit,
        CONST_EVENT.attack,
        "shejilie_attack",
        function(evtData)
            if hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("风行者的馈赠")) and math.random(1, 100) <= 25 then
                fengxingzhedekuizeng(evtData.triggerUnit, evtData.targetUnit, 0.1)
            end
        end
    )
end
