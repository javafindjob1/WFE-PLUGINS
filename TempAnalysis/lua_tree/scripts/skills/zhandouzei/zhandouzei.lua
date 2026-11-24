local DAOZEI_JINGTONG_XISHU = 15

---被动技能cd类常数
local ZHANDOUZEI_CD = {}
ZHANDOUZEI_CD[hslk.n2i("魔法斗篷")] = 60

local function getLianjidian(whichUnit)
    if whichUnit == nil then
        return 0
    end
    return hcache.get(whichUnit, "LIANJIDIAN_COUNT", 0)
end

local function addLianjidian(whichUnit, stack)
    if whichUnit == nil then
        return 0
    end
    local count = hcache.get(whichUnit, "LIANJIDIAN_COUNT", 0)
    local maxCount = 5
    if hmingwen.isEquipped("技击大师", hunit.getOwner(whichUnit)) then
        maxCount = maxCount + 1
    end
    count = math.min(maxCount, count + stack)
    hcache.set(whichUnit, "LIANJIDIAN_COUNT", count)
    set_energy_point(hunit.getOwner(whichUnit), count, maxCount, "hongse")
end

local function subLianjidian(whichUnit, stack)
    if whichUnit == nil then
        return 0
    end
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "无休锋刃")
    if points > 0 then
        hskill.setCoolDown(
            whichUnit,
            hslk.n2i("冲动"),
            math.max(0, hskill.getCoolDown(whichUnit, hslk.n2i("冲动")) - stack * points * 0.1)
        )
        hskill.setCoolDown(
            whichUnit,
            hslk.n2i("杀戮盛宴"),
            math.max(0, hskill.getCoolDown(whichUnit, hslk.n2i("杀戮盛宴")) - stack * points * 0.1)
        )
    end
    if hskill.hasActiveAbility(whichUnit, hslk.n2i("作战潜能")) then
        hunit.addCurMana(whichUnit, stack * 5)
    end
    local maxCount = 5
    if hmingwen.isEquipped("技击大师", hunit.getOwner(whichUnit)) then
        maxCount = maxCount + 1
    end
    local count = hcache.get(whichUnit, "LIANJIDIAN_COUNT", 0)
    count = math.max(0, count - stack)
    hcache.set(whichUnit, "LIANJIDIAN_COUNT", count)
    set_energy_point(hunit.getOwner(whichUnit), count, maxCount, "hongse")
    if hbuff.hasBuff(whichUnit, "冲动之命运") then
        hskill.setCoolDown(
            whichUnit,
            hslk.n2i("冲动"),
            math.max(0, hskill.getCoolDown(whichUnit, hslk.n2i("冲动")) - stack * 0.7)
        )
    end
end

SKILL_ON_LEVEL_UP["战斗贼"] = function(whichUnit)
    local shanbiid = hslk.n2i("闪避")
    if hskill.hasActiveAbility(whichUnit, shanbiid) then
        hskill.addProperty(whichUnit, shanbiid, 1)
    end
    local zhandounuhou = hslk.n2i("技艺精湛")
    if hskill.hasActiveAbility(whichUnit, zhandounuhou) then
        hskillMoban.guanghuan(
            whichUnit,
            zhandounuhou,
            2000,
            hslk.i2v(zhandounuhou, "_guanghuanAttr"),
            true,
            true,
            "技艺精湛|n盗贼的精湛技艺激励了同伴，赋予半径2000范围内所有友方单位50精通的增幅"
        )
        hskill.addProperty(whichUnit, zhandounuhou, 1)
    end
end

local MINGYUNZHISHAI_BUFF = {
    function(whichUnit, points)
        hbuff.update(
            12 * points,
            whichUnit,
            "狂暴之命运",
            true,
            function()
                hattribute.set(whichUnit, 0, _attr({ wu_bao = "+12" }))
            end,
            function()
                hattribute.set(whichUnit, 0, _attr({ wu_bao = "-12" }))
            end,
            "ReplaceableTextures\\daozei\\kuangbaozhimingyun.blp",
            "狂暴之命运：物理暴击增加10%",
            nil,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE,
            true
        )
    end,
    function(whichUnit, points)
        hbuff.update(
            12 * points,
            whichUnit,
            "能量之命运",
            true,
            function()
                hattribute.set(whichUnit, 0, _attr({ energy_back = "+12" }))
            end,
            function()
                hattribute.set(whichUnit, 0, _attr({ energy_back = "-12" }))
            end,
            "ReplaceableTextures\\daozei\\nengliangzhimingyun.blp",
            "能量之命运：能量恢复增加12%",
            nil,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE,
            true
        )
    end,
    function(whichUnit, points)
        hbuff.update(
            12 * points,
            whichUnit,
            "精通之命运",
            true,
            function()
                hattribute.set(whichUnit, 0, _attr({ master = "+80" }))
            end,
            function()
                hattribute.set(whichUnit, 0, _attr({ master = "-80" }))
            end,
            "ReplaceableTextures\\daozei\\jingtongtouzi.blp",
            "精通之命运：精通增加80",
            nil,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE,
            true
        )
    end,
    function(whichUnit, points)
        local lifeBackStr = tostring(math.ceil(0.02 * hunit.getMaxLife(whichUnit)))
        if hmingwen.isEquipped("活力复苏", hunit.getOwner(whichUnit)) then
            hbuff.update(
                12 * points,
                whichUnit,
                "恢复之命运",
                true,
                function()
                    hattribute.set(whichUnit, 0, _attr({ mana_back = "+3", life_back = "+" .. lifeBackStr }))
                end,
                function()
                    hattribute.set(whichUnit, 0, _attr({ mana_back = "-3", life_back = "-" .. lifeBackStr }))
                end,
                "ReplaceableTextures\\daozei\\huifuzhimingyun.blp",
                "恢复之命运：生命恢复速度增加2%每秒，因为装备了活力复苏铭文，额外获得了3点每秒的能量回复速度",
                nil,
                nil,
                nil,
                nil,
                nil,
                HBUFF_UPDATE_MODE.OVERWRITE,
                true
            )
        else
            hbuff.update(
                12 * points,
                whichUnit,
                "恢复之命运",
                true,
                function()
                    hattribute.set(whichUnit, 0, _attr({ life_back = "+" .. lifeBackStr }))
                end,
                function()
                    hattribute.set(whichUnit, 0, _attr({ life_back = "-" .. lifeBackStr }))
                end,
                "ReplaceableTextures\\daozei\\huifuzhimingyun.blp",
                "恢复之命运：生命恢复速度增加2%每秒",
                nil,
                nil,
                nil,
                nil,
                nil,
                HBUFF_UPDATE_MODE.OVERWRITE,
                true
            )
        end
    end,
    function(whichUnit, points)
        hbuff.update(
            12 * points,
            whichUnit,
            "连击之命运",
            true,
            nil,
            nil,
            "ReplaceableTextures\\daozei\\lianjizhimingyun.blp",
            "连击之命运：影袭会额外增加一个连击点",
            nil,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE,
            true
        )
    end,
    function(whichUnit, points)
        hbuff.update(
            12 * points,
            whichUnit,
            "冲动之命运",
            true,
            nil,
            nil,
            "ReplaceableTextures\\daozei\\chongdongzhimingyun.blp",
            "冲动之命运：每消耗一个连击点降低0.7秒冲动的cd",
            nil,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE,
            true
        )
    end
}
local function generateBuff(whichUnit)
    local randomNumber = math.random(1, 100)
    local numBuffs = 0
    if hskill.hasActiveAbility(whichUnit, hslk.n2i("灌铅骰子")) then
        local shoufaxianshuPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "手法娴熟")

        if randomNumber <= 60 - shoufaxianshuPoints * 3 then
            numBuffs = 2
        elseif randomNumber <= 90 - shoufaxianshuPoints then
            numBuffs = 3
        else
            numBuffs = 6
        end
    else
        if randomNumber <= 60 then
            numBuffs = 1
        elseif randomNumber <= 80 then
            numBuffs = 2
        elseif randomNumber <= 93 then
            numBuffs = 3
        else
            numBuffs = 6
        end
    end
    -- 初始化骰子结果和buff计数器

    local buffs = { 1, 2, 3, 4, 5, 6 }
    local finalBuff = table.random(buffs, numBuffs)
    if type(finalBuff) == "number" then
        finalBuff = { finalBuff }
    end
    return finalBuff
end

local function qiege(whichUnit, lianjidian)
    --TODO effect
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\spell_ro_deathfromabove_leap_impact_01.mp3", 1000, true),
        80,
        whichUnit
    )
    local duration = lianjidian * 12
    local lefte = heffect.attach("[daozei]xunji.mdl", whichUnit, "hand left", duration)
    local righte = heffect.attach("[daozei]xunji.mdl", whichUnit, "hand right", duration)
    hbuff.update(
        duration,
        whichUnit,
        "迅切",
        true,
        function()
            hattribute.set(whichUnit, 0, _attr({ attack_speed = "+30" }))
        end,
        function()
            hattribute.set(whichUnit, 0, _attr({ attack_speed = "-30" }))
            heffect.destroy(righte)
            heffect.destroy(lefte)
        end,
        hslk.n2v("迅切", "Art"),
        "迅切：攻击速度增加30%",
        nil,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
    if hskill.hasActiveAbility(whichUnit, hslk.n2i("命运之骰")) then
        for _, v in ipairs({ "狂暴之命运", "能量之命运", "精通之命运", "恢复之命运", "连击之命运", "冲动之命运" }) do
            hbuff.delete(whichUnit, v)
        end
        local buffIdx = generateBuff(whichUnit)
        for _, buffid in ipairs(buffIdx) do
            MINGYUNZHISHAI_BUFF[buffid](whichUnit, lianjidian)
        end
    end
end

SKILLS_CAST["迅切"] = function(evtData)
    local lianjidian = getLianjidian(evtData.triggerUnit)
    if lianjidian <= 0 then
        echo("连击点不足", hunit.getOwner(evtData.triggerUnit))
        return
    end
    subLianjidian(evtData.triggerUnit, lianjidian)
    qiege(evtData.triggerUnit, lianjidian)
end

local function mofadoupeng(whichUnit)
    local hasT1Sanjiantao = false
    if
        hcache.get(whichUnit, "[T1]猎杀者套装(3件)", false) or
        hzhuangbeishouji.isActive(hunit.getOwner(whichUnit), "[T1]猎杀者套装")
    then
        hasT1Sanjiantao = true
    end

    hbuff.update(
        5,
        whichUnit,
        "魔法斗篷",
        true,
        function()
            hevent.register(
                whichUnit,
                CONST_EVENT.damagingCustomTarget,
                "魔法斗篷",
                function(evtData)
                    if evtData.damageType == DAMAGE_TYPE.MOFA then
                        evtData.damage = evtData.damage * 0.5
                    end
                end
            )
            hunit.setRGBA(whichUnit, 55, 31, 63, 1)
            if hasT1Sanjiantao then
                hattribute.set(whichUnit, 0, _attr({ shanbi = "+25" }))
            end
        end,
        function()
            hevent.unregister(whichUnit, CONST_EVENT.damagingCustomTarget, "魔法斗篷")
            hunit.setRGBA(whichUnit, 255, 255, 255, 1)
            if hasT1Sanjiantao then
                hattribute.set(whichUnit, 0, _attr({ shanbi = "-25" }))
            end
        end,
        hslk.n2v("魔法斗篷", "Art"),
        "魔法斗篷：降低50%受到的魔法伤害",
        nil,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
end

local function jiying(whichUnit)
    local duration = 8
    hbuff.update(
        duration,
        whichUnit,
        "疾影",
        true,
        function()
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("魔法斗篷")) then
                mofadoupeng(whichUnit)
            end
            hattribute.set(whichUnit, 0, _attr({ shanbi = "+25", move = "+400" }))
        end,
        function()
            hattribute.set(whichUnit, 0, _attr({ shanbi = "-25", move = "-400" }))
        end,
        hslk.n2v("疾影", "Art"),
        "疾影: 移动速度到极限，闪避增加25%",
        nil,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\3553.mp3", 1000, true), 80, whichUnit)
    heffect.attach("war3mapImported\\ZB_LongJi.mdx", whichUnit, "origin", 3)
    heffect.attach("war3mapImported\\tuowei_white.mdx", whichUnit, "chest", duration)
end

SKILLS["疾影"] = function(evtData)
    jiying(evtData.triggerUnit)
end

local function jianrenluanwu(whichUnit)
    local duration = 10
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "剑术专家")
    if points > 0 then
        duration = duration + points
    end
    hbuff.update(
        duration,
        whichUnit,
        "剑刃飞舞",
        true,
        function()
            hattribute.set(whichUnit, 0, _attr({ attack_speed = "+20" }))
        end,
        function()
            hattribute.set(whichUnit, 0, _attr({ attack_speed = "-20" }))
        end,
        hslk.n2v("剑刃飞舞", "Art"),
        "剑刃飞舞：攻击速度增加20%，普通攻击，影袭，剔骨和杀戮盛宴会伤害周围300范围内的所有单位，持续8秒",
        nil,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
    heffect.attach("[daozei]jianrenluanwu2.mdx", whichUnit, "origin", 8)
end
SKILLS["剑刃飞舞"] = function(evtData)
    jianrenluanwu(evtData.triggerUnit)
end

local function gelie(whichUnit, targetUnit, lianjidian)
    local duration = lianjidian + 3
    local buffKey = "割裂" .. tostring(whichUnit)
    if hbuff.hasBuffThatLastLongerthan(targetUnit, buffKey, duration) then
        return
    end
    local interval = 1
    local qiegejiqiaoPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "切割技巧")
    interval = interval * (1 - qiegejiqiaoPoints * 0.04)
    local skillspeedfactor = (100 + hattribute.getWithLimit(whichUnit, nil, "skill_speed", 0)) / 100
    interval = math.round(interval / skillspeedfactor)
    local damage = hattribute.getWithLimit(whichUnit, nil, "attack", 0) * (0.2 + lianjidian * 0.1)
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "连击技大师")
    if points > 0 then
        damage =
            damage *
            (1 + points * 0.02 + hattribute.getWithLimit(whichUnit, nil, "master", 0) / 100 / (40 - 5 * points))
    end
    heffect.attach("war3mapImported\\AZ_gelie.mdx", targetUnit, "chest", 0)
    hbuff.update(
        duration,
        targetUnit,
        buffKey,
        false,
        function()
        end,
        function()
        end,
        hslk.n2v("割裂", "Art"),
        "割裂：每1秒造成" .. tostring(damage) .. "点物理伤害。",
        1,
        interval,
        function(curTimer, buffHandle)
            buffHandle.remainingTime = buffHandle.remainingTime - interval
            heffect.attach("war3mapImported\\AZ_gelie.mdx", targetUnit, "chest", 0)
            hskill.damage(
                {
                    sourceUnit = whichUnit,
                    targetUnit = targetUnit,
                    damage = damage,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.WULI,
                    triggerSkill = hslk.n2i("割裂"),
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT
                }
            )
            if hcache.get(whichUnit, "[T3]暗影猎手套装(4件)", false) then
                hunit.addCurMana(whichUnit, 2)
            elseif hzhuangbeishouji.isActive(hunit.getOwner(whichUnit), "[T3]暗影猎手套装") then
                hunit.addCurMana(whichUnit, 1)
            end
        end,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
end

local function cigu(whichUnit, targetUnit, lianjidian)
    local damage =
        (hattribute.getWithLimit(whichUnit, nil, "attack", 0) + hattribute.getWithLimit(whichUnit, nil, "agi", 0)) *
        0.65 *
        lianjidian
    if hcache.get(whichUnit, "[T1]猎杀者套装(4件)", false) then
        damage = damage * 1.2
    elseif hzhuangbeishouji.isActive(hunit.getOwner(whichUnit), "[T1]猎杀者套装") then
        damage = damage * 1.1
    end
    if hmingwen.isEquipped("剔骨", hunit.getOwner(whichUnit)) then
        damage = damage * 1.03
    end
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "连击技大师")
    if points > 0 then
        damage =
            damage *
            (1 + points * 0.02 + hattribute.getWithLimit(whichUnit, nil, "master", 0) / 100 / (40 - 5 * points))
    end
    if hbuff.hasBuff(whichUnit, "剑刃飞舞") then
        hskillMoban.radiusAOE(
            hunit.x(targetUnit),
            hunit.y(targetUnit),
            whichUnit,
            300,
            function(unit)
                local finalDamage = damage
                if unit ~= targetUnit then
                    finalDamage = damage * 0.5
                end
                hskill.damage(
                    {
                        sourceUnit = whichUnit,
                        targetUnit = unit,
                        damage = finalDamage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.WULI,
                        triggerSkill = hslk.n2i("破击"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                    }
                )
            end,
            false,
            true
        )
    else
        hskill.damage(
            {
                sourceUnit = whichUnit,
                targetUnit = targetUnit,
                damage = damage,
                damageSrc = CONST_DAMAGE_SRC.skill,
                damageType = DAMAGE_TYPE.WULI,
                triggerSkill = hslk.n2i("破击"),
                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
            }
        )
    end
    heffect.xyz(
        "[daozei]poji.MDX",
        hunit.x(targetUnit),
        hunit.y(targetUnit),
        hunit.z(targetUnit),
        0,
        1,
        nil,
        nil,
        nil,
        nil,
        nil,
        math.angle(hunit.x(whichUnit), hunit.y(whichUnit), hunit.x(targetUnit), hunit.y(targetUnit))
    )
    if hskill.hasActiveAbility(whichUnit, hslk.n2i("割裂")) then
        htime.setTimeout(
            0.3,
            function(curTimer)
                gelie(whichUnit, targetUnit, lianjidian)
            end
        )
    end
    if hmingwen.isEquipped("剔骨", hunit.getOwner(whichUnit)) == false then
        hbuff.xuanyun(targetUnit, 0.2 * lianjidian)
    end
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\YasuoQWindImpact.mp3", 1000, true),
        80,
        whichUnit
    )
    heffect.attach("war3mapImported\\AZ_hit3.mdl", targetUnit, "origin", 0)
    hcamera.quake(hplayer.loc(), 10, 0.1)
    cj.IssueTargetOrder(whichUnit, "attack", targetUnit)
end
SKILLS["破击"] = function(evtData)
    local lianjidian = getLianjidian(evtData.triggerUnit)
    if lianjidian <= 0 then
        echo("连击点不足", hunit.getOwner(evtData.triggerUnit))
        return
    end
    subLianjidian(evtData.triggerUnit, lianjidian)
    hunit.setAnimateSpeed(evtData.triggerUnit, 1.8, 0.25)
    hunit.animate(evtData.triggerUnit, "attack Slam")
    htime.setTimeout(
        0.2,
        function(curTimer)
            cigu(evtData.triggerUnit, evtData.targetUnit, lianjidian)
        end
    )
end

local function dancishalushengyan(whichUnit)
    local damageMulti = 1
    if hcache.get(whichUnit, "[T2]追猎者套装(4件)", false) then
        damageMulti = damageMulti * 1.3
    elseif hzhuangbeishouji.isActive(hunit.getOwner(whichUnit), "[T2]追猎者套装") then
        damageMulti = damageMulti * 1.1
    end
    local units = hgroup.createEnermyGroupByUnitWithoutInvincible(whichUnit, 500)
    if #units <= 0 then
        return
    end
    local targetUnit = units[math.random(1, #units)]
    hunit.portal(whichUnit, hunit.x(targetUnit) - 50, hunit.y(targetUnit), 0)
    hunit.portal(whichUnit, hunit.x(targetUnit) - 50, hunit.y(targetUnit), 0)
    hunit.setAnimateSpeed(whichUnit, 1.8, 0.2)
    hunit.animate(whichUnit, "attack")

    if hbuff.hasBuff(whichUnit, "剑刃飞舞") then
        hskillMoban.radiusAOE(
            hunit.x(targetUnit),
            hunit.y(targetUnit),
            whichUnit,
            300,
            function(unit)
                local damage = hattribute.getWithLimit(whichUnit, nil, "attack", 0) * 2 * damageMulti
                local damageSrc = CONST_DAMAGE_SRC.skill
                if unit ~= targetUnit then
                    damage = damage * 0.5
                    damageSrc = CONST_DAMAGE_SRC.attack
                end
                heffect.attach("war3mapImported\\AZ_hit1.mdx", unit, "chest", 0)
                hskill.damage(
                    {
                        sourceUnit = whichUnit,
                        targetUnit = unit,
                        damage = damage,
                        damageSrc = damageSrc,
                        damageType = DAMAGE_TYPE.WULI,
                        triggerSkill = hslk.n2i("杀戮盛宴"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                        shanghainame = "杀戮盛宴"
                    }
                )
                htime.setTimeout(
                    0.05,
                    function()
                        hskill.damage(
                            {
                                sourceUnit = whichUnit,
                                targetUnit = unit,
                                damage = damage,
                                damageSrc = damageSrc,
                                damageType = DAMAGE_TYPE.WULI,
                                triggerSkill = hslk.n2i("杀戮盛宴"),
                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                shanghainame = "杀戮盛宴"
                            }
                        )
                    end
                )
            end,
            false,
            true
        )
    else
        heffect.attach("war3mapImported\\AZ_hit1.mdx", targetUnit, "chest", 0)
        hskill.damage(
            {
                sourceUnit = whichUnit,
                targetUnit = targetUnit,
                damage = hattribute.getWithLimit(whichUnit, nil, "attack", 0) * 2 * damageMulti,
                damageSrc = CONST_DAMAGE_SRC.attack,
                damageType = DAMAGE_TYPE.WULI,
                triggerSkill = hslk.n2i("杀戮盛宴"),
                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                shanghainame = "杀戮盛宴"
            }
        )
        htime.setTimeout(
            0.05,
            function()
                hskill.damage(
                    {
                        sourceUnit = whichUnit,
                        targetUnit = targetUnit,
                        damage = hattribute.getWithLimit(whichUnit, nil, "attack", 0) * 2 * damageMulti,
                        damageSrc = CONST_DAMAGE_SRC.attack,
                        damageType = DAMAGE_TYPE.WULI,
                        triggerSkill = hslk.n2i("杀戮盛宴"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                        shanghainame = "杀戮盛宴"
                    }
                )
            end
        )
    end
end

local function shalushengyan(whichUnit)
    local count = 5
    local interval = 0.3
    dancishalushengyan(whichUnit)
    count = count - 1
    hbuff.update(
        interval * count,
        whichUnit,
        "杀戮盛宴",
        true,
        function()
            hunit.pause(whichUnit)
        end,
        function()
            hunit.resume(whichUnit)
        end,
        hslk.n2v("杀戮盛宴", "Art"),
        "杀戮盛宴中",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
    htime.setInterval(
        interval,
        function(curTimer)
            if count <= 0 then
                curTimer.destroy()
                return
            end
            count = count - 1
            dancishalushengyan(whichUnit)
        end
    )
end
SKILLS["杀戮盛宴"] = function(evtData)
    hunit.setAnimateSpeed(evtData.triggerUnit, 1.8, 0.2)
    hunit.animate(evtData.triggerUnit, "spell")
    shalushengyan(evtData.triggerUnit)
end

local function chongdong(whichUnit)
    local duration = 12
    hbuff.update(
        duration,
        whichUnit,
        hslk.n2i("冲动"),
        true,
        function()
            hattribute.set(whichUnit, 0, _attr({ mana_back = "+8", attack_speed = "+20" }))
        end,
        function()
            hattribute.set(whichUnit, 0, _attr({ mana_back = "-8", attack_speed = "-20" }))
        end,
        hslk.n2v("冲动", "Art"),
        "冲动：基础能量恢复速度+8点每秒，攻击速度加20%，并且影袭可以获得5个连击点，持续12秒",
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

SKILLS_STOP["冲动"] = function(evtData)
    if hmingwen.isEquipped("精力旺盛", hunit.getOwner(evtData.triggerUnit)) then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("冲动"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("冲动")) - 20)
        )
    end
end

SKILLS_STOP["疾影"] = function(evtData)
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "体能充沛")
    if points > 0 then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("疾影"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("疾影")) - points)
        )
    end
end

SKILLS_STOP["剑刃飞舞"] = function(evtData)
    if hcache.get(evtData.triggerUnit, "[T3]暗影猎手套装(3件)", false) then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("剑刃飞舞"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("剑刃飞舞")) - 10)
        )
    elseif hzhuangbeishouji.isActive(hunit.getOwner(evtData.triggerUnit), "[T3]暗影猎手套装") then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("剑刃飞舞"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("剑刃飞舞")) - 5)
        )
    end
end

SKILLS["冲动"] = function(evtData)
    hunit.setAnimateSpeed(evtData.triggerUnit, 1.8, 0.25)
    hunit.animate(evtData.triggerUnit, "spell")
    htime.setTimeout(
        0.2,
        function(curTimer)
            chongdong(evtData.triggerUnit)
        end
    )
end

local function yingxi(whichUnit, targetUnit, isDuochongyingxi)
    local manaCost = 40
    if hcache.get(whichUnit, "[T2]追猎者套装(3件)", false) then
        manaCost = manaCost - 4
    elseif hzhuangbeishouji.isActive(hunit.getOwner(whichUnit), "[T2]追猎者套装") then
        manaCost = manaCost - 2
    end
    if isDuochongyingxi == true then
    else
        hunit.subCurMana(whichUnit, manaCost)
    end
    local duochongyingxirate = 0
    if hmingwen.isEquipped("幻影之袭", hunit.getOwner(whichUnit)) then
        duochongyingxirate = 15
    elseif hmingwen.isEquipped("多重影袭", hunit.getOwner(whichUnit)) then
        duochongyingxirate = 10
    end
    if isDuochongyingxi ~= true and duochongyingxirate > 0 and math.random(1, 100) <= duochongyingxirate then
        htime.setTimeout(
            0.2,
            function(curTimer)
                yingxi(whichUnit, targetUnit, true)
            end
        )
    end
    heffect.xyz(
        "AZ_DG010.MDX",
        hunit.x(whichUnit),
        hunit.y(whichUnit),
        hunit.z(whichUnit),
        0,
        1,
        1.2,
        1.2,
        1.2,
        nil,
        nil,
        math.angle(hunit.x(whichUnit), hunit.y(whichUnit), hunit.x(targetUnit), hunit.y(targetUnit))
    )
    local damage =
        0.9 * (hattribute.getWithLimit(whichUnit, nil, "attack", 0) + hattribute.getWithLimit(whichUnit, nil, "agi", 0))
    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\yingxi.wav", 1000, true), 80, whichUnit)
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "邪恶攻击")
    if points > 0 then
        damage = damage * (1 + points * 0.03)
    end
    if hshangcheng.hasItem(hunit.getOwner(whichUnit), "见习战斗贼") then
        damage = damage * 1.05
    end
    if hbuff.hasBuff(whichUnit, "剑刃飞舞") then
        hskillMoban.radiusAOE(
            hunit.x(whichUnit),
            hunit.y(whichUnit),
            whichUnit,
            300,
            function(unit)
                local finalDamage = damage
                if unit ~= targetUnit then
                    finalDamage = damage * 0.5
                end
                heffect.attach("war3mapImported\\AZ_hit1.mdx", unit, "chest", 0)
                hskill.damage(
                    {
                        sourceUnit = whichUnit,
                        targetUnit = unit,
                        damage = finalDamage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.WULI,
                        triggerSkill = hslk.n2i("影袭"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                    }
                )
            end,
            false,
            true
        )
    else
        heffect.attach("war3mapImported\\AZ_hit1.mdx", targetUnit, "chest", 0)
        hskill.damage(
            {
                sourceUnit = whichUnit,
                targetUnit = targetUnit,
                damage = damage,
                damageSrc = CONST_DAMAGE_SRC.skill,
                damageType = DAMAGE_TYPE.WULI,
                triggerSkill = hslk.n2i("影袭"),
                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
            }
        )
    end
    if hbuff.hasBuff(whichUnit, hslk.n2i("冲动")) then
        addLianjidian(whichUnit, 10)
    else
        addLianjidian(whichUnit, 1)
    end
    if hbuff.hasBuff(whichUnit, "连击之命运") then
        addLianjidian(whichUnit, 1)
    end
end

local function zhimingduyao(whichUnit, targetUnit)
    local buffKey = "致命毒药" .. tostring(whichUnit)
    local handle = hbuff.getBuffHandle(targetUnit, buffKey)
    local stack = 0
    if handle ~= nil then
        stack = handle.stack
    end
    local duration = 12
    local maxStack = 5
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "剧毒")
    if points > 0 then
        maxStack = maxStack + points
    end
    if stack >= maxStack then
        --heffect.attach("Abilities\\Weapons\\PoisonSting\\PoisonStingTarget.mdl", targetUnit, "chest", 0.1)
        hskill.damage(
            {
                sourceUnit = whichUnit,
                targetUnit = targetUnit,
                damage = hattribute.getWithLimit(whichUnit, nil, "agi", 0) * 0.5,
                damageSrc = CONST_DAMAGE_SRC.skill,
                damageType = DAMAGE_TYPE.MOFA,
                triggerSkill = hslk.n2i("致命毒药"),
                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
            }
        )
        handle.remainingTime = duration
    else
        hbuff.update(
            duration,
            targetUnit,
            buffKey,
            false,
            function()
            end,
            function()
            end,
            hslk.n2v("致命毒药", "Art"),
            "致命毒药：每层造成每秒10%的敏捷的魔法伤害。",
            1,
            1,
            function(curTimer, buffHandle)
                --heffect.attach("Abilities\\Weapons\\PoisonSting\\PoisonStingTarget.mdl", targetUnit, "chest", 0.1)
                local stack = buffHandle.stack
                buffHandle.remainingTime = buffHandle.remainingTime - 1
                hskill.damage(
                    {
                        sourceUnit = whichUnit,
                        targetUnit = targetUnit,
                        damage = hattribute.getWithLimit(whichUnit, nil, "agi", 0) * 0.1 * stack,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = hslk.n2i("致命毒药"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT
                    }
                )
            end,
            function(buffHandle)
                buffHandle.remainingTime = duration
                buffHandle.stack = buffHandle.stack + 1
            end,
            nil,
            HBUFF_UPDATE_MODE.UPDATE,
            true
        )
    end
end

SKILL_SETUP["战斗贼"] = function(whichUnit)
    hattribute.set(whichUnit, 0, { mana_back = "+8" })
    hskill.registerAutoCast(whichUnit, hslk.n2i("破击"))

    -- 盗贼攻击
    hevent.register(
        whichUnit,
        CONST_EVENT.beforeAttackDamage,
        "zhandouzei_attack",
        function(evtData)
            local sourceUnit = evtData.sourceUnit
            local targetUnit = evtData.targetUnit
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "双持专精")
            if points > 0 then
                evtData.damage = evtData.damage * (1 + 0.02 * points)
            end
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("作战潜能")) then
                local rate = 15
                local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "强化作战潜能")
                if points > 0 then
                    rate = rate + points
                end
                if math.random(1, 100) <= rate then
                    hunit.addCurMana(whichUnit, 10)
                end
            end

            if hmingwen.isEquipped("吸血药膏", hunit.getOwner(sourceUnit)) then
                if math.random(1, 100) <= 10 then
                    hskill.heal(
                        {
                            healer = sourceUnit,
                            healee = sourceUnit,
                            heal = 80,
                            healType = HEAL_TYPE.SKILL
                        }
                    )
                end
            end
            if hmingwen.isEquipped("高级吸血药膏", hunit.getOwner(sourceUnit)) then
                if math.random(1, 100) <= 10 then
                    hskill.heal(
                        {
                            healer = sourceUnit,
                            healee = sourceUnit,
                            heal = 320,
                            healType = HEAL_TYPE.SKILL
                        }
                    )
                end
            end
            local buffKey = "致命毒药" .. tostring(whichUnit)
            hevent.register(
                whichUnit,
                CONST_EVENT.damagingCustomSource,
                "zhandouzeicustomdamage",
                function(evtData)
                    if evtData.sourceUnit ~= whichUnit then
                        err("Incorrect unit")
                        return
                    end
                    if hbuff.hasBuff(targetUnit, buffKey) then
                        local stack = hbuff.getBuffHandle(targetUnit, buffKey).stack or 1
                        evtData.damage = evtData.damage * (1 + 0.01 * stack)
                    end
                    local shp = hunit.getCurLifePercent(evtData.sourceUnit) or 100
                    local thp = hunit.getCurLifePercent(targetUnit) or 100
                    if hskill.hasActiveAbility(evtData.sourceUnit, hslk.n2i("欺凌弱小")) and shp > thp then
                        evtData.damage = evtData.damage * 1.15
                    end
                end
            )

            if hbuff.hasBuff(whichUnit, "剑刃飞舞") then
                hskillMoban.radiusAOE(
                    hunit.x(targetUnit),
                    hunit.y(targetUnit),
                    whichUnit,
                    300,
                    function(unit)
                        if unit == targetUnit then
                            return
                        end
                        hskill.damage(
                            {
                                sourceUnit = whichUnit,
                                targetUnit = unit,
                                damage = hattribute.getWithLimit(whichUnit, nil, "attack", 0) * 0.5,
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.WULI,
                                triggerSkill = hslk.n2i("剑刃飞舞"),
                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                            }
                        )
                    end,
                    false,
                    true
                )
            end

            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("连击")) then
                local defaultLianjirate =
                    math.min(
                        (20 + hattribute.getWithLimit(sourceUnit, nil, "master", 0) / DAOZEI_JINGTONG_XISHU),
                        60
                    )
                local daozeilianjirate = evtData.daozeilianjirate or defaultLianjirate
                if math.random(1, 100) <= daozeilianjirate then
                    htime.setTimeout(
                        0.2,
                        function(curTimer)
                            heffect.xyz(
                                "[daozei]lianji.mdx",
                                hunit.x(sourceUnit),
                                hunit.y(sourceUnit),
                                hunit.z(sourceUnit),
                                0,
                                1,
                                0.55,
                                0.55,
                                0.55,
                                nil,
                                nil,
                                math.angle(
                                    hunit.x(sourceUnit),
                                    hunit.y(sourceUnit),
                                    hunit.x(targetUnit),
                                    hunit.y(targetUnit)
                                )
                            )
                            hsound.voice2Unit(
                                hsound.voiceCreate("resource\\war3mapImported\\sound\\lianji.wav", 1000, true),
                                80,
                                whichUnit
                            )
                            heffect.attach("war3mapImported\\AZ_hit1.mdx", targetUnit, "chest", 0)
                            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "连击精通")
                            local damage = hattribute.getWithLimit(whichUnit, nil, "attack", 0)
                            if points > 0 then
                                damage = damage * (1 + 0.02 * points)
                            end
                            hskill.damage(
                                {
                                    sourceUnit = sourceUnit,
                                    targetUnit = targetUnit,
                                    damage = damage,
                                    damageSrc = CONST_DAMAGE_SRC.attack,
                                    damageType = DAMAGE_TYPE.WULI,
                                    triggerSkill = hslk.n2i("连击"),
                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                    daozeilianjirate = daozeilianjirate - 20,
                                    shanghainame = "连击"
                                }
                            )
                        end
                    )
                end
            end
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("影袭")) and hunit.getCurMana(whichUnit) >= 65 then
                yingxi(sourceUnit, targetUnit)
            end
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("致命毒药")) and math.random(1, 100) <= 18 then
                zhimingduyao(sourceUnit, targetUnit)
            end
        end
    )

    -- 盗贼闪避
    hevent.register(
        whichUnit,
        CONST_EVENT.shanbi,
        "zhandouzei_attack",
        function(evtData)
            if
                hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("闪避")) and
                htime.setupAndCheckCoolDown(evtData.triggerUnit, "闪避反伤", 1)
            then
                hskill.damage(
                    {
                        sourceUnit = evtData.triggerUnit,
                        targetUnit = evtData.sourceUnit,
                        damage = hattribute.getWithLimit(evtData.triggerUnit, nil, "attack", 0),
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.WULI,
                        triggerSkill = hslk.n2i("闪避"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                    }
                )
                addLianjidian(evtData.triggerUnit, 1)
            end
        end
    )

    htime.setInterval(
        5,
        function(curTimer)
            if hplayer.isPlaying(hunit.getOwner(whichUnit)) == false then
                curTimer.destroy()
                return
            end
            local wuqijingtongPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "武器精通")
            local leftHandItem = hplayer.dzCunDang[hunit.getOwner(whichUnit)].getEquipment(EQUIPMENT_SLOT_ID.zhushou)

            if wuqijingtongPoints > 0 and leftHandItem ~= nil then
                local eqType = hslk.i2v(leftHandItem.basic_item_id, "equipment_type")

                local bonusAttr = _attr({})
                local description = "武器精通|n"
                local bonus = wuqijingtongPoints

                if eqType == "匕首" then
                    bonusAttr.wu_bao = "+" .. bonus
                    description = description .. "物理暴击率增加" .. bonus .. "%"
                elseif eqType == "单手剑" then
                    description = description .. "攻击可以触发连击" .. bonus .. "%"
                elseif eqType == "单手锤" then
                    bonusAttr.wu_chuan = "+" .. bonus
                    description = description .. "物理穿透增加" .. bonus .. "%"
                elseif eqType == "单手斧" then
                    bonusAttr.gongji_baifenbi = "+" .. bonus
                    description = description .. "攻击力增加" .. bonus .. "%"
                else
                    bonusAttr.attack_speed = "+" .. bonus
                    description = description .. "攻击速度增加" .. bonus .. "%"
                end

                hbuff.update(
                    -1,
                    whichUnit,
                    "武器精通",
                    true,
                    function()
                        if eqType == "单手剑" then
                            hevent.register(
                                whichUnit,
                                CONST_EVENT.attack,
                                "wuqijingtong_attack",
                                function(evtData)
                                    if math.random(1, 100) <= bonus then
                                        htime.setTimeout(0.15, function(curTimer)
                                            heffect.xyz(
                                                "[boss]suoruisen3.mdx", hunit.x(whichUnit),
                                                hunit.y(whichUnit),
                                                hunit.z(whichUnit), 0, 1, 1, 1, 1, nil, nil,
                                                math.angle(hunit.x(whichUnit), hunit.y(whichUnit),
                                                    hunit.x(evtData.targetUnit), hunit.y(evtData.targetUnit)))
                                            hsound.voice2Unit(
                                                hsound.voiceCreate("resource\\war3mapImported\\sound\\lianji.wav", 1000,
                                                    true),
                                                80, whichUnit)
                                            heffect.attach("war3mapImported\\AZ_hit1.mdx", evtData.targetUnit, "chest", 0)
                                            hskill.damage({
                                                sourceUnit = whichUnit,
                                                targetUnit = evtData.targetUnit,
                                                damage = hattr.get(whichUnit, "attack", 1),
                                                damageSrc = CONST_DAMAGE_SRC.attack,
                                                damageType = DAMAGE_TYPE.WULI,
                                                effect = "Abilities\\Weapons\\Axe\\AxeMissile.mdl",
                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                                                shanghainame = "武器精通-剑"
                                            })
                                        end)
                                    end
                                end)
                        else
                            echo(123)
                            hattribute.caleAttribute(CONST_DAMAGE_SRC.skill, true, whichUnit, bonusAttr, 1)
                        end
                    end,
                    function()
                        if eqType == "单手剑" then
                            hevent.unregister(
                                whichUnit,
                                CONST_EVENT.attack,
                                "wuqijingtong_attack")
                        else
                            echo(321)
                            hattribute.caleAttribute(CONST_DAMAGE_SRC.skill, false, whichUnit, bonusAttr, 1)
                        end
                    end,
                    "ReplaceableTextures\\daozei\\shuangchizhuanjing.blp",
                    description,
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE,
                    true
                )
            else
                hbuff.delete(whichUnit, "武器精通")
            end
        end
    )
end
