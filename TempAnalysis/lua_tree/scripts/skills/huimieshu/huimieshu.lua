---@diagnostic disable: missing-parameter
---被动技能cd类常数
local HUIMIESHU_CD = {}
HUIMIESHU_CD[hslk.n2i("灵魂石")] = 60

local HUIMIESHU_JINGTONG_XISHU = 10

local function getHunluanzhizhong(whichUnit)
    if whichUnit == nil then
        return 0
    end
    return hcache.get(whichUnit, "HUNLUANZHIZHONG_COUNT", 0)
end

local xishengmodian = function(sourceUnit, targetUnit)
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("牺牲魔典")) == false then return end
    local rate = 15
    local damage = hattr.get(sourceUnit, "int") * 0.5

    if hcache.get(sourceUnit, "[T3]高阶法师套装(3件)", false) then
        damage = damage * 1.1
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T3]高阶法师套装") then
        damage = damage * 1.05
    end
    if hcache.get(sourceUnit, "[T3]高阶法师套装(4件)", false) then
        rate = rate + 5
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T3]高阶法师套装") then
        rate = rate + 3
    end
    if math.random(1, 100) <= rate then
        hskillMoban.radiusAOE(
            hunit.x(targetUnit),
            hunit.y(targetUnit),
            sourceUnit,
            300,
            function(filterUnit)
                if hmingwen.isEquipped("地狱恶魔的魔典", hunit.getOwner(sourceUnit)) then
                    hbuff.addStackAttrBuff(
                        CONST_DAMAGE_SRC.skill,
                        targetUnit,
                        "地狱恶魔的魔典",
                        _attr({}),
                        5,
                        10,
                        hslk.n2v("牺牲魔典", "Art"),
                        "地狱恶魔的魔典|n每层使怪物受到地狱魔典的伤害提高10%，最多叠加10层",
                        false
                    )
                end
                local stack = hbuff.getStack(targetUnit, "地狱恶魔的魔典") or 0
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = filterUnit,
                        damage = damage * (1 + 0.1 * stack),
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK },
                        shanghainame = "牺牲魔典"
                    }
                )
                heffect.xyz(
                    "Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode.mdl",
                    hunit.x(targetUnit),
                    hunit.y(targetUnit),
                    hunit.z(targetUnit),
                    0,
                    1
                )
            end,
            false,
            true
        )
    end
end

local haojie = function(sourceUnit, targetUnit, duration, numTarget)
    local targets = {}
    table.insert(targets, targetUnit)
    hgroup.createByUnit(
        targetUnit,
        500,
        function(filterUnit)
            if
                filterUnit ~= targetUnit and hunit.isAlly(filterUnit, sourceUnit) == false and hunit.isAlive(filterUnit) and
                #targets < numTarget and
                hunit.isInvincible(filterUnit) == false
            then
                table.insert(targets, filterUnit)
            end
        end
    )
    for _, unit in ipairs(targets) do
        local e = heffect.attach("war3mapImported\\[BUFF]Fear - 2.mdx", unit, "overhead", -1)
        hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\13998.mp3", 1000, true), 100, unit)
        hbuff.update(
            duration,
            unit,
            hslk.n2i("浩劫") .. tostring(sourceUnit),
            false,
            function()
                hevent.register(
                    unit,
                    CONST_EVENT.damagingCustomTarget,
                    "浩劫易伤" .. tostring(hplayer.index(hunit.getOwner(sourceUnit))),
                    function(evtData)
                        local tmpSourceUnit = evtData.sourceUnit
                        if sourceUnit == tmpSourceUnit then
                            evtData.damage = evtData.damage * 1.1
                        end
                    end
                )
            end,
            function()
                heffect.destroy(e)
                hevent.unregister(
                    unit,
                    CONST_EVENT.damagingCustomTarget,
                    "浩劫易伤" .. tostring(hplayer.index(hunit.getOwner(sourceUnit)))
                )
            end,
            hslk.n2v("浩劫", "Art"),
            "浩劫降临！毁灭术士对该单位造成的伤害提高10%。同时单体伤害技能对其它目标释放时会额外对浩劫目标造成效果。",
            1,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE
        )
    end
end

local cijihunluanzhijian = function(whichUnit, count)
    local units =
        hgroup.createByUnit(
            whichUnit,
            1000,
            function(filterUnit)
                if
                    hunit.isEnemy(whichUnit, filterUnit) == true and hunit.isAlive(filterUnit) and
                    hunit.isDestroyed(filterUnit) == false and
                    hunit.isInvincible(filterUnit) == false and
                    hfightzhuangtai.isInFight(filterUnit) == true
                then
                    return true
                end
            end
        )

    local damageMulti = 1.2
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "混乱浩劫")
    if points > 0 then
        damageMulti = damageMulti * (1 + 0.02 * points)
    end
    local scale = 0.8
    local fabao = hattribute.getWithLimit(whichUnit, nil, "fa_bao", 0)
    damageMulti = damageMulti * (1 + 0.01 * fabao)

    if #units > 0 then
        for i = 1, count, 1 do
            local targetUnit = table.random(units, 1)
            hsound.voice2Unit(
                hsound.voiceCreate("resource\\war3mapImported\\sound\\fire_cast.wav", 1000, true),
                80,
                whichUnit
            )
            hskillMoban.missile(
                {
                    model = "war3mapImported\\Firebolt Classic_new.mdl",
                    scale = scale,
                    speed = 400,
                    height = 200,
                    hover = 50,
                    sourceUnit = whichUnit,
                    targetUnit = targetUnit,
                    target_face_dis = 50,
                    onEnd = function()
                        hskill.damage(
                            {
                                sourceUnit = whichUnit,
                                targetUnit = targetUnit,
                                damage = damageMulti * hattr.getWithLimit(whichUnit, nil, "int", 0),
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.MOFA,
                                triggerSkill = hslk.n2i("混乱之箭"),
                                tmpAttr = { fa_bao = "+100" },
                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK },
                                shanghainame = "次级混乱之箭"
                            }
                        )
                        xishengmodian(whichUnit, targetUnit)
                    end
                }
            )
        end
    end
end

local function addHunluanzhizhong(whichUnit, stack)
    if whichUnit == nil or hunit.isDead(whichUnit) then
        return 0
    end
    local count = hcache.get(whichUnit, "HUNLUANZHIZHONG_COUNT", 0)
    local totalCountBefore = count + stack
    local maxCount = 4
    if hmingwen.isEquipped("深渊意志", hunit.getOwner(whichUnit)) then
        maxCount = maxCount + 1
    end
    if hskill.hasActiveAbility(whichUnit, hslk.n2i("混乱主宰")) then
        maxCount = maxCount + 1
    end
    count = math.min(maxCount, count + stack)
    local maxout = totalCountBefore - count
    if maxout > 0 and hskill.hasActiveAbility(whichUnit, hslk.n2i("混乱主宰")) then
        cijihunluanzhijian(whichUnit, maxout)
    end
    hcache.set(whichUnit, "HUNLUANZHIZHONG_COUNT", count)
    set_energy_point(hunit.getOwner(whichUnit), count, maxCount, "lvse")
end

local function subHunluanzhizhong(whichUnit, stack)
    if whichUnit == nil then
        return 0
    end
    local linghundaoguanrate = 20
    if hcache.get(whichUnit, "[T1]灵力波动套装(3件)", false) then
        linghundaoguanrate = linghundaoguanrate + 5
    elseif hzhuangbeishouji.isActive(hunit.getOwner(whichUnit), "[T1]灵力波动套装") then
        linghundaoguanrate = linghundaoguanrate + 2
    end
    if hskill.hasActiveAbility(whichUnit, hslk.n2i("灵魂导管")) and math.random(1, 100) <= linghundaoguanrate then
        htextTag.create2Unit(whichUnit, "灵魂导管", 6, "ff3300", 1, 1, 50)
        return
    end
    local maxCount = 4
    if hskill.hasActiveAbility(whichUnit, hslk.n2i("混乱主宰")) then
        maxCount = maxCount + 1
    end
    if hmingwen.isEquipped("深渊意志", hunit.getOwner(whichUnit)) then
        maxCount = maxCount + 1
    end
    local count = hcache.get(whichUnit, "HUNLUANZHIZHONG_COUNT", 0)
    count = math.max(0, count - stack)
    hcache.set(whichUnit, "HUNLUANZHIZHONG_COUNT", count)
    set_energy_point(hunit.getOwner(whichUnit), count, maxCount, "lvse")
end

local linghunranshao = function(sourceUnit, duration)
    if hbuff.hasBuffThatLastLongerthan(sourceUnit, hslk.n2i("灵魂燃烧"), duration) then
        return
    end
    local e = heffect.attach("war3mapImported\\FX_Enery_purple_002.mdx", sourceUnit, "origin", duration)
    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\9001.mp3", 1000, true), 100, sourceUnit)
    addHunluanzhizhong(sourceUnit, 5)
    hbuff.update(
        duration,
        sourceUnit,
        hslk.n2i("灵魂燃烧"),
        true,
        function()
        end,
        function()
        end,
        hslk.n2v("灵魂燃烧", "Art"),
        "灵魂燃烧|n 该状态下混乱能量触发最大值",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE
    )
end

local function hunluanzhijian(evtData)
    local sourceUnit = evtData.triggerUnit
    local targetUnit = evtData.targetUnit
    local skillID = evtData.triggerSkill
    local damageMulti = 2.5
    local scale = 1.1
    local fabao = hattribute.getWithLimit(sourceUnit, nil, "fa_bao", 0)
    damageMulti = damageMulti * (1 + 0.01 * fabao)
    local cost = 1
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("混乱主宰")) then
        cost = 2
        damageMulti = damageMulti * 2.3
        scale = 1.5
    end
    if hcache.get(sourceUnit, "[T1]灵力波动套装(4件)", false) then
        damageMulti = damageMulti * 1.1
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T1]灵力波动套装") then
        damageMulti = damageMulti * 1.05
    end
    if hbuff.hasBuff(sourceUnit, "毁灭仪式") and (hbuff.getBuffHandle(sourceUnit, "毁灭仪式").stack or 1) >= 5 then
        cost = 0
        hbuff.delete(sourceUnit, "毁灭仪式")
    end
    if hbuff.hasBuff(sourceUnit, "阿兹亚基的疯狂") then
        damageMulti = damageMulti * 1.1
        hbuff.delete(sourceUnit, "阿兹亚基的疯狂")
    end
    subHunluanzhizhong(sourceUnit, cost)
    local units =
        hgroup.createByUnit(
            sourceUnit,
            1500,
            function(filterUnit)
                if targetUnit == filterUnit then
                    return false
                end
                if
                    hunit.isAlly(filterUnit, sourceUnit) == false and hunit.isAlive(filterUnit) and
                    hbuff.hasBuff(filterUnit, hslk.n2i("浩劫") .. tostring(sourceUnit))
                then
                    return true
                else
                    return false
                end
            end
        )
    table.insert(units, targetUnit)
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\fire_cast.wav", 1000, true),
        100,
        sourceUnit
    )
    for _, unit in ipairs(units) do
        hskillMoban.missile(
            {
                model = "war3mapImported\\Firebolt Classic_new.mdl",
                scale = scale,
                speed = 400,
                height = 200,
                hover = 50,
                sourceUnit = sourceUnit,
                targetUnit = unit,
                target_face_dis = 50,
                onEnd = function()
                    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("根除")) then
                        hbuff.update(
                            10,
                            unit,
                            "混乱之箭增伤" .. tostring(sourceUnit),
                            false,
                            nil,
                            nil,
                            hslk.n2v("混乱之箭", "Art"),
                            "混乱之箭使得毁灭术士对目标伤害提高10%",
                            1,
                            nil,
                            nil,
                            nil,
                            nil,
                            HBUFF_UPDATE_MODE.OVERWRITE,
                            true,
                            nil,
                            sourceUnit
                        )
                    end

                    local targets = { unit }
                    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "混乱浩劫")
                    if points > 0 and math.random(1, 100) <= 2 * points then
                        targets = hgroup.createEnermyGroupByXY(evtData.triggerUnit, hunit.x(unit), hunit.y(unit), 300)
                    end
                    -- 爆炸特效 TODO
                    for _, finaldamagetarget in ipairs(targets) do
                        hskill.damage(
                            {
                                sourceUnit = sourceUnit,
                                targetUnit = finaldamagetarget,
                                damage = damageMulti * hattr.getWithLimit(sourceUnit, nil, "int", 0),
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.MOFA,
                                triggerSkill = skillID,
                                tmpAttr = { fa_bao = "+100" },
                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK },
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                shanghainame = "混乱之箭"
                            }
                        )
                        xishengmodian(sourceUnit, finaldamagetarget)
                    end
                end
            }
        )
    end
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "毁灭仪式")
    if points > 0 and math.random(1, 100) <= 20 * points then
        hbuff.addStackAttrBuff(
            CONST_DAMAGE_SRC.skill,
            evtData.triggerUnit,
            "毁灭仪式",
            _attr({}),
            10,
            5,
            hslk.n2v("混乱之箭", "Art"),
            "毁灭仪式|n叠加五层后会使得下一个混乱之箭施法时间降低50%且不消耗灵魂碎片，或者使下一个火雨伤害提高100%切产生的灵魂碎片基础概率提高15%",
            true
        )
    end

    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "阿兹亚基的疯狂")
    if points > 0 and math.random(1, 100) <= points * 20 then
        hbuff.update(
            4,
            evtData.triggerUnit,
            "阿兹亚基的疯狂",
            true,
            nil,
            nil,
            "ReplaceableTextures\\SHUSHI\\HLZZ.blp",
            "阿兹亚基的疯狂|n使下一次混乱之箭的伤害提高10%，施法时间缩短10%，或者下一次火焰之雨会使火焰之雨的伤害提高25%，持续4秒",
            1,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE,
            true
        )
    end

    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "焚烧成灰")
    if points > 0 then
        hbuff.addStackAttrBuff(
            CONST_DAMAGE_SRC.skill,
            sourceUnit,
            "焚烧成灰",
            _attr({}),
            8,
            4,
            hslk.n2v("烧尽", "Art"),
            "焚烧成灰|n使得下个烧尽的伤害提高，最多叠加4次，持续8秒",
            true
        )
    end
end

local shandian = function(sourceUnit, targetUnit)
    local shirdianPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "闪点")
    if shirdianPoints > 0 then
        if hunit.getCurLifePercent(targetUnit) >= 80 then
            local bonusSkillSpeed = shirdianPoints * 2
            hbuff.update(
                6,
                sourceUnit,
                "闪点",
                true,
                function()
                    hattribute.set(sourceUnit, 0, { skill_speed = "+" .. bonusSkillSpeed })
                end,
                function()
                    hattribute.set(sourceUnit, 0, { skill_speed = "-" .. bonusSkillSpeed })
                end,
                hslk.n2v("献祭", "Art"),
                "闪点：技能加速提升" .. bonusSkillSpeed .. "%",
                1,
                nil,
                nil,
                nil,
                nil,
                HBUFF_UPDATE_MODE.OVERWRITE
            )
        end
    end
end

local function xianji(sourceUnit, targetUnit)
    local skillID = hslk.n2i("献祭")
    local damageMulti = 0.3
    local duration = 15
    local interval = 1 * 100 / (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0))
    if hmingwen.isEquipped("急速献祭", hunit.getOwner(sourceUnit)) then
        interval = interval * 0.9
    end
    local units = {}
    table.insert(units, targetUnit)
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("大灾变")) then
        local extraUnits = {}
        for _, unit in ipairs(units) do
            local currentGroup =
                hgroup.createByUnit(
                    unit,
                    300,
                    function(filterUnit)
                        if unit == filterUnit then
                            return false
                        end
                        if
                            hunit.isAlly(filterUnit, sourceUnit) == false and hunit.isAlive(filterUnit) == true and
                            hunit.isInvincible(filterUnit) == false
                        then
                            return true
                        else
                            return false
                        end
                    end
                )
            for _, v in ipairs(currentGroup) do
                table.insert(extraUnits, v)
            end
        end
        for _, v in ipairs(extraUnits) do
            table.insert(units, v)
        end
    end
    for _, unit in ipairs(units) do
        heffect.attach("war3mapImported\\AZ_Misslie06.MDX", unit, "chest", 0)
        hbuff.update(
            duration,
            unit,
            hslk.n2i("献祭") .. tostring(sourceUnit),
            false,
            nil,
            nil,
            hslk.n2v("献祭", "Art"),
            "献祭：每秒造成30%智力的伤害，10% 概率获得混乱之种，暴击时获得概率翻倍",
            1,
            interval,
            function(_, buffHandle)
                buffHandle.remainingTime = buffHandle.remainingTime - 1
                heffect.attach("Abilities\\Spells\\Other\\Incinerate\\IncinerateBuff.mdl", unit, "head", 0.1)
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = unit,
                        damage = damageMulti * hattr.getWithLimit(sourceUnit, nil, "int", 0),
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = skillID,
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                        damageElementType = CONST_DAMAGE_ELEMENT_TYPE.FIRE,
                        shanghainame = "献祭"
                    }
                )
                shandian(sourceUnit, unit)
            end,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE,
            true
        )
    end
end

local function baoran(evtData)
    local sourceUnit = evtData.triggerUnit
    local targetUnit = evtData.targetUnit
    local skillID = evtData.triggerSkill
    local damageMulti = 1.5
    local units = {}
    units =
        hgroup.createByUnit(
            sourceUnit,
            1500,
            function(filterUnit)
                if targetUnit == filterUnit then
                    return false
                end
                if
                    hunit.isAlly(filterUnit, sourceUnit) == false and hunit.isAlive(filterUnit) == true and
                    hunit.isInvincible(filterUnit) == false and
                    hbuff.hasBuff(filterUnit, hslk.n2i("浩劫") .. tostring(sourceUnit))
                then
                    return true
                else
                    return false
                end
            end
        )
    table.insert(units, targetUnit)
    for _, unit in ipairs(units) do
        hskill.damage(
            {
                sourceUnit = sourceUnit,
                targetUnit = unit,
                damage = damageMulti * hattr.getWithLimit(sourceUnit, nil, "int", 0),
                damageSrc = CONST_DAMAGE_SRC.skill,
                damageType = DAMAGE_TYPE.MOFA,
                triggerSkill = skillID,
                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                damageElementType = CONST_DAMAGE_ELEMENT_TYPE.FIRE,
                shanghainame = "爆燃"
            }
        )
        heffect.attach("war3mapImported\\RanBao_[AZ].MDX", unit, "origin", 0)
        if hskill.hasActiveAbility(sourceUnit, hslk.n2i("献祭")) then
            xianji(sourceUnit, targetUnit)
        end
    end
    hbuff.update(
        10,
        sourceUnit,
        "爆燃",
        true,
        nil,
        nil,
        hslk.n2v("爆燃", "Art"),
        "爆燃使得毁灭术士下一个混乱之箭施法时间缩短0.8秒",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "暴乱")
    if points > 0 and math.random(1, 100) <= 5 * points then
        local group = hgroup.createEnermyGroupByXY(sourceUnit, hunit.x(targetUnit), hunit.y(targetUnit), 500)
        if #group > 0 then
            local target = table.random(group, 1)
            haojie(sourceUnit, targetUnit, 5, 1)
        end
    end
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "混乱具象")
    if points > 0 and math.random(1, 100) <= 3 * points and htime.setupAndCheckCoolDown(sourceUnit, "混乱具象", 10) then
        linghunranshao(sourceUnit, 5)
    end
end

local function shaojing(sourceUnit, targetUnit, skillID)
    local damageMulti = 1.3
    if hshangcheng.hasItem(hunit.getOwner(sourceUnit), "见习毁灭术") then
        damageMulti = damageMulti * 1.05
    end
    local lianyanfenmiePoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "烈焰焚灭")
    if lianyanfenmiePoints > 0 then
        damageMulti = damageMulti * (1 + lianyanfenmiePoints * 0.04)
    end
    if hcache.get(sourceUnit, "[T2]炎灵套装(3件)", false) then
        damageMulti = damageMulti * 1.3
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T2]炎灵套装") then
        damageMulti = damageMulti * 1.15
    end
    if hbuff.hasBuff(sourceUnit, "焚烧成灰") then
        local stack = hbuff.getBuffHandle(sourceUnit, "焚烧成灰").stack or 0
        damageMulti = damageMulti * (1 + 0.15 * stack)
        hbuff.delete(sourceUnit, "焚烧成灰")
    end
    local tmpAttr = {}
    local mana = 2
    if hmingwen.isEquipped("精准燃烧", hunit.getOwner(sourceUnit)) then
        mana = mana - 1
    end
    hunit.subCurMana(sourceUnit, mana)
    if hbuff.hasBuff(sourceUnit, hslk.n2i("混沌燃烧")) then
        tmpAttr["fa_bao"] = "+100"
        local fabao = hattribute.getWithLimit(sourceUnit, nil, "fa_bao", 0)
        damageMulti = damageMulti * (1 + 0.01 * fabao)
        hbuff.delete(sourceUnit, hslk.n2i("混沌燃烧"))
    end
    local units =
        hgroup.createByUnit(
            sourceUnit,
            1500,
            function(filterUnit)
                if targetUnit == filterUnit then
                    return false
                end
                if
                    hunit.isAlly(filterUnit, sourceUnit) == false and hunit.isAlive(filterUnit) and
                    hbuff.hasBuff(filterUnit, hslk.n2i("浩劫") .. tostring(sourceUnit))
                then
                    return true
                else
                    return false
                end
            end
        )
    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\fire_cast.wav", 500, true), 100, sourceUnit)
    table.insert(units, targetUnit)
    for _, unit in ipairs(units) do
        hskillMoban.missile(
            {
                model = "war3mapImported\\[SPELL]_111_new.mdl",
                scale = 1,
                speed = 800,
                height = 100,
                hover = 100,
                sourceUnit = sourceUnit,
                targetUnit = unit,
                target_face_dis = 100,
                onEnd = function()
                    hsound.voice2Unit(
                        hsound.voiceCreate("resource\\war3mapImported\\sound\\shaojing_impact.wav", 1000, true),
                        60,
                        unit
                    )

                    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "硫黄烈火")
                    if points > 0 and math.random(1, 100) <= points * 5 then
                        hskillMoban.radiusAOE(
                            hunit.x(unit),
                            hunit.y(unit),
                            sourceUnit,
                            300,
                            function(u)
                                hskill.damage(
                                    {
                                        sourceUnit = sourceUnit,
                                        targetUnit = u,
                                        damage = damageMulti * hattr.get(sourceUnit, "int", 0),
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.MOFA,
                                        triggerSkill = skillID,
                                        tmpAttr = tmpAttr,
                                        isAttackReplacement = true
                                    }
                                )
                            end,
                            false,
                            true
                        )
                    else
                        hskill.damage(
                            {
                                sourceUnit = sourceUnit,
                                targetUnit = unit,
                                damage = damageMulti * hattr.get(sourceUnit, "int", 0),
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.MOFA,
                                triggerSkill = skillID,
                                tmpAttr = tmpAttr,
                                isAttackReplacement = true
                            }
                        )
                        xishengmodian(sourceUnit, unit)
                    end
                end
            }
        )
    end
end

SKILLS["爆燃"] = function(evtData)
    baoran(evtData)
end

SKILLS_STOP["爆燃"] = function(evtData)
    if hcache.get(evtData.triggerUnit, "[T2]炎灵套装(4件)", false) then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("爆燃"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("爆燃")) - 2)
        )
    elseif hzhuangbeishouji.isActive(hunit.getOwner(evtData.triggerUnit), "[T2]炎灵套装") then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("爆燃"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("爆燃")) - 1)
        )
    end
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "爆破潜能")
    if points > 0 then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("爆燃"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("爆燃")) - 0.2 * points)
        )
    end
end

SKILLS["火焰雨"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local x = evtData.targetX
    local y = evtData.targetY
    local z = evtData.targetZ

    local boshu = 12
    local damageMulti = 0.3
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("强化火雨")) then
        damageMulti = damageMulti * 1.3
    end
    local rate = 10
    if hbuff.hasBuff(sourceUnit, "毁灭仪式") and (hbuff.getBuffHandle(sourceUnit, "毁灭仪式").stack or 1) >= 5 then
        rate = rate + 15
        damageMulti = damageMulti * 2
        hbuff.delete(sourceUnit, "毁灭仪式")
    end
    if hbuff.hasBuff(sourceUnit, "阿兹亚基的疯狂") then
        damageMulti = damageMulti * 1.25
        hbuff.delete(sourceUnit, "阿兹亚基的疯狂")
    end
    local modianqianghuaPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "魔典强化")
    local modianqianghuaChance = modianqianghuaPoints * 20
    local yicihuoyu = function()
        for i = -1, 1, 1 do
            for j = -1, 1, 1 do
                heffect.xyz("war3mapImported\\Rain of Fire Vol. II.mdl", x + i * 200, y + j * 200, z, 0, 1, 1, 1, 1)
            end
        end
        hsound.voice2Unit(
            hsound.voiceCreate("resource\\war3mapImported\\sound\\huoyu.wav", 1000, true),
            100,
            sourceUnit
        )
        htime.setTimeout(
            0.8,
            function(_)
                hskillMoban.radiusAOE(
                    x,
                    y,
                    sourceUnit,
                    300,
                    function(unit)
                        if hskill.hasActiveAbility(sourceUnit, hslk.n2i("强化火雨")) and math.random(1, 100) <= rate then
                            addHunluanzhizhong(sourceUnit, 1)
                        end
                        hskill.damage(
                            {
                                sourceUnit = sourceUnit,
                                targetUnit = unit,
                                damage = hattribute.getWithLimit(sourceUnit, nil, "int", 0) * damageMulti,
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.MOFA,
                                triggerSkill = hslk.n2i("火焰雨"),
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                shanghainame = "火焰雨"
                            }
                        )
                        if modianqianghuaPoints > 0 and math.random(1, 100) <= modianqianghuaChance then
                            xishengmodian(sourceUnit, unit)
                        end
                    end,
                    false,
                    true
                )
            end
        )
    end
    yicihuoyu()
    boshu = boshu - 1
    htime.setInterval(
        1,
        function(curTimer)
            if boshu <= 0 then
                curTimer.destroy()
                return
            end
            boshu = boshu - 1
            yicihuoyu()
        end
    )
end

SKILLS["暗影之怒"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local x = evtData.targetX
    local y = evtData.targetY
    heffect.xyz("war3mapImported\\AYZN_[AZ].mdx", x, y, hunit.z(evtData.triggerUnit), 0, 1, 1, 1, 1)
    hcamera.quake(hplayer.loc(), 10, 0.1)
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\shadowfury_impact_base.mp3", 1000, true),
        80,
        evtData.triggerUnit
    )
    local units =
        hgroup.createByXY(
            x,
            y,
            300,
            function(filterUnit)
                if hunit.isAlly(filterUnit, sourceUnit) == false and hunit.isAlive(filterUnit) then
                    return true
                else
                    return false
                end
            end
        )
    for _, unit in ipairs(units) do
        hbuff.xuanyun(unit, 2)
    end
end

SKILLS["浩劫"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local targetUnit = evtData.targetUnit
    local duration = 10
    local numTarget = 1
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("浩劫复仇")) then
        duration = duration + 3
        numTarget = 2
    end
    haojie(sourceUnit, targetUnit, duration, numTarget)
end

SKILLS["灵魂燃烧"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    linghunranshao(sourceUnit, 10)
end

SKILL_ON_LEVEL_UP["毁灭术"] = function(whichUnit)
    local kuangbaozhixinid = hslk.n2i("灵魂石")
    if hskill.hasActiveAbility(whichUnit, kuangbaozhixinid) then
        hskillMoban.guanghuan(
            whichUnit,
            kuangbaozhixinid,
            2000,
            hslk.i2v(kuangbaozhixinid, "_guanghuanAttr"),
            true,
            true,
            "如果友军生命低于30% 吃一颗灵魂石回血30% cd 60秒",
            CONST_EVENT.beDamage,
            function(evtData)
                htime.setTimeout(
                    0.5,
                    function(_)
                        local targetUnit = evtData.triggerUnit
                        if hunit.getCurLifePercent(targetUnit) < 30 and hbuff.hasBuff(targetUnit, "灵魂石触发特效") == false then
                            hskill.heal(
                                {
                                    healee = targetUnit,
                                    healer = whichUnit,
                                    heal = hunit.getMaxLife(targetUnit) * 0.3,
                                    healType = HEAL_TYPE.SKILL,
                                    triggerSkill = hslk.n2i("灵魂石")
                                }
                            )
                            htextTag.create2Unit(targetUnit, "灵魂石使用", 6, "ff3300", 1, 1, 50)
                            hbuff.update(
                                60,
                                targetUnit,
                                "灵魂石触发特效",
                                false,
                                nil,
                                nil,
                                hslk.n2v("灵魂石", "Art"),
                                "你刚使用过一颗灵魂石, 短时间内无法再次使用",
                                1,
                                nil,
                                nil,
                                nil,
                                nil,
                                HBUFF_UPDATE_MODE.OVERWRITE
                            )
                        end
                    end
                )
            end
        )
    end
end

SKILL_SETUP["毁灭术"] = function(whichUnit)
    --基础回蓝1
    hattribute.set(whichUnit, 0, { mana_back = "=1" })
    hskill.registerAutoCast(whichUnit, hslk.n2i("爆燃"))
    hskill.registerAutoCast(whichUnit, hslk.n2i("混乱之箭"))

    hskill.registerMonitoringBuff(whichUnit, "毁灭仪式", true)
    hskill.registerMonitoringBuff(whichUnit, hslk.n2i("灵魂燃烧"), true)

    hskill.setup_zhudong_jineng(
        whichUnit,
        hslk.n2i("混乱之箭"),
        hunluanzhijian,
        function(sourceUnit, targetUnit)
            local shifashijian = 2.0
            if hbuff.hasBuff(sourceUnit, "爆燃") then
                shifashijian = shifashijian - 0.8
                hbuff.delete(sourceUnit, "爆燃")
            end
            if hbuff.hasBuff(sourceUnit, "毁灭仪式") and (hbuff.getBuffHandle(sourceUnit, "毁灭仪式").stack or 1) >= 5 then
                shifashijian = shifashijian * 0.5
            end
            if hbuff.hasBuff(sourceUnit, "阿兹亚基的疯狂") then
                shifashijian = shifashijian * 0.9
            end
            return math.round(shifashijian)
        end,
        function(checkUnit)
            if
                getHunluanzhizhong(checkUnit) == 0 or
                (getHunluanzhizhong(checkUnit) == 1 and hskill.hasActiveAbility(checkUnit, hslk.n2i("混乱主宰")))
            then
                echo("没有足够的混乱之种", hunit.getOwner(checkUnit))
                return false
            end
            if hunit.getCurMana(checkUnit) < 7 then
                echo("魔法值不足以释放混乱之箭", hunit.getOwner(checkUnit))
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
                heffect.attach("war3mapImported\\[Spell]_117_new.mdx", whichUnit, "hand left", 3)
            )
            hcache.set(
                whichUnit,
                "hlzjrighthandtexiao",
                heffect.attach("war3mapImported\\[Spell]_117_new.mdx", whichUnit, "hand right", 3)
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

    hevent.register(
        whichUnit,
        CONST_EVENT.damagingCustomSource,
        "hunluannengliang",
        function(evtData)
            if evtData.sourceUnit ~= whichUnit then
                err("Incorrect unit")
                return
            end
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("混乱能量")) == false then
                return
            end
            local jingtong = hattribute.getWithLimit(whichUnit, nil, "master", 0)
            local maxZengShang = jingtong / HUIMIESHU_JINGTONG_XISHU + 20
            if hbuff.hasBuff(whichUnit, hslk.n2i("灵魂燃烧")) == false then
                maxZengShang = math.random(0, maxZengShang)
            end
            local zengshang = 1 + maxZengShang / 100
            if hbuff.hasBuff(evtData.targetUnit, "混乱之箭增伤" .. tostring(whichUnit)) then
                zengshang = zengshang * 1.1
            end
            evtData.damage = evtData.damage * zengshang
        end
    )

    hevent.register(
        whichUnit,
        CONST_EVENT.damagingCustomTarget,
        "hunluannengliang",
        function(evtData)
            if evtData.targetUnit ~= whichUnit then
                err("Incorrect unit")
                return
            end
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("混乱能量")) == false then
                return
            end
            local jingtong = hattribute.getWithLimit(whichUnit, nil, "master", 0)
            local maxJianShang = jingtong / HUIMIESHU_JINGTONG_XISHU / 6 + 10
            if hbuff.hasBuff(whichUnit, hslk.n2i("灵魂燃烧")) == false then
                maxJianShang = math.random(0, maxJianShang)
            end
            local jianshang = 1 - maxJianShang / 100
            evtData.damage = evtData.damage * jianshang
        end
    )

    -- 毁灭术攻击
    hevent.register(
        whichUnit,
        CONST_EVENT.beforeAttackDamage,
        "huimieshu_attack",
        function(evtData)
            evtData.damage = 0
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("烧尽")) and hunit.getCurMana(whichUnit) >= 2 then
                shaojing(whichUnit, evtData.targetUnit, hslk.n2i("烧尽"))
                return
            end
            hunit.animate(whichUnit, "stand")
            if hskill.checkAndEnterCD(whichUnit, "no_mana_hint", 5) then
                echo("魔法不够释放任何技能", hunit.getOwner(whichUnit))
            end
        end
    )

    hevent.register(
        whichUnit,
        CONST_EVENT.damage,
        "huimieshudamage",
        function(evtData)
            local triggerSkill = evtData.triggerSkill
            local sourceUnit = evtData.triggerUnit
            if triggerSkill == nil then
                return
            end
            if triggerSkill == hslk.n2i("烧尽") then
                local hundunranshaorate = 15
                if hmingwen.isEquipped("无尽混沌燃烧", hunit.getOwner(sourceUnit)) then
                    hundunranshaorate = 30
                end
                if
                    hskill.hasActiveAbility(sourceUnit, hslk.n2i("混沌燃烧")) == true and
                    math.random(1, 100) <= hundunranshaorate
                then
                    hbuff.update(
                        5,
                        sourceUnit,
                        hslk.n2i("混沌燃烧"),
                        true,
                        nil,
                        nil,
                        hslk.n2v("混沌燃烧", "Art"),
                        "下次烧尽必爆, 且伤害提高（原理和混乱之箭一样)。烧尽暴击后获得混乱之种概率提高一倍",
                        1,
                        nil,
                        nil,
                        nil,
                        nil,
                        HBUFF_UPDATE_MODE.OVERWRITE
                    )
                end

                local shaojingrate = 15
                local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "天魔余烬")
                if points > 0 then
                    shaojingrate = shaojingrate + points * 2
                end

                if evtData.isCritical and hskill.hasActiveAbility(sourceUnit, hslk.n2i("混沌燃烧")) == true then
                    if math.random(1, 100) <= (2 * shaojingrate) then
                        addHunluanzhizhong(sourceUnit, 1)
                    end
                else
                    if math.random(1, 100) <= shaojingrate then
                        addHunluanzhizhong(sourceUnit, 1)
                    end
                end
            elseif triggerSkill == hslk.n2i("献祭") then
                if evtData.isCritical then
                    if math.random(1, 100) <= 20 then
                        addHunluanzhizhong(sourceUnit, 1)
                    end
                else
                    if math.random(1, 100) <= 10 then
                        addHunluanzhizhong(sourceUnit, 1)
                    end
                end
            elseif triggerSkill == hslk.n2i("爆燃") then
                addHunluanzhizhong(sourceUnit, 1)
            end
        end
    )
end
