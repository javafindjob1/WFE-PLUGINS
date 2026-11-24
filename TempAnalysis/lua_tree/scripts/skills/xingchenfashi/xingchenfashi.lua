local jineng_cd = {}
jineng_cd["阳炎术"] = 12

local JINGTONG_XISHU = 15

local yuehuoshu, xinghuoshu, taifeng, xingyongshu, qunxingzhuiluo, chaofanzhimeng, fennu, yangyanshu, danciliuxing

XINGJIE_NENGLIANG = {
    RISHI = "日蚀能量",
    YUESHI = "月蚀能量"
}

local addRishi = function(sourceUnit)
    hbuff.delete(sourceUnit, "日蚀能量")
    local master = hattribute.getWithLimit(sourceUnit, nil, "master", 0)
    local speed = 20 + math.round(master / JINGTONG_XISHU)
    local duration = 8
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "安舍之赐")
    if points > 0 then
        duration = duration + 0.5 * points
    end
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "艾露恩之赐")
    if points > 0 then
        duration = duration - 0.5 * points
    end
    hbuff.update(
        duration,
        sourceUnit,
        "日蚀",
        true,
        function()
            if hbuff.hasBuff(sourceUnit, "月蚀") then
                heffect.destroy(hcache.get(sourceUnit, "riyueshitexiao"))
                hcache.set(
                    sourceUnit,
                    "riyueshitexiao",
                    heffect.attach("spell\\XCFS_RY.mdx", sourceUnit, "overhead", duration)
                )
            else
                hcache.set(
                    sourceUnit,
                    "riyueshitexiao",
                    heffect.attach("spell\\XCFS_RS.mdx", sourceUnit, "overhead", duration)
                )
            end
            hattr.set(sourceUnit, 0, _attr({ attack_speed = "+" .. tostring(speed) }))
        end,
        function()
            if hbuff.hasBuff(sourceUnit, "月蚀") then
                heffect.destroy(hcache.get(sourceUnit, "riyueshitexiao"))
                local remainingTime = hbuff.getBuffHandle(sourceUnit, "月蚀").remainingTime
                hcache.set(
                    sourceUnit,
                    "riyueshitexiao",
                    heffect.attach("spell\\XCFS_YS.mdx", sourceUnit, "overhead", remainingTime)
                )
            else
                heffect.destroy(hcache.get(sourceUnit, "riyueshitexiao"))
            end
            hattr.set(sourceUnit, 0, _attr({ attack_speed = "-" .. tostring(speed) }))
        end,
        hslk.n2v("日蚀", "Art"),
        "日蚀|n提高攻击速度和愤怒的伤害",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("至日")) then
        hbuff.update(
            5,
            sourceUnit,
            "至日",
            true,
            nil,
            nil,
            hslk.n2v("至日", "Art"),
            "坠星的触发概率提高100%",
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

local addYueshi = function(sourceUnit)
    hbuff.delete(sourceUnit, "月蚀能量")
    local master = hattribute.getWithLimit(sourceUnit, nil, "master", 0)
    local speed = 20 + math.round(master / JINGTONG_XISHU)
    local duration = 8
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "艾露恩之赐")

    if points > 0 then
        duration = duration + 0.5 * points
    end
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "安舍之赐")
    if points > 0 then
        duration = duration - 0.5 * points
    end
    hbuff.update(
        duration,
        sourceUnit,
        "月蚀",
        true,
        function()
            if hbuff.hasBuff(sourceUnit, "日蚀") then
                heffect.destroy(hcache.get(sourceUnit, "riyueshitexiao"))
                hcache.set(
                    sourceUnit,
                    "riyueshitexiao",
                    heffect.attach("spell\\XCFS_RY.mdx", sourceUnit, "overhead", duration)
                )
            else
                heffect.destroy(hcache.get(sourceUnit, "riyueshitexiao"))
                hcache.set(
                    sourceUnit,
                    "riyueshitexiao",
                    heffect.attach("spell\\XCFS_YS.mdx", sourceUnit, "overhead", duration)
                )
            end
        end,
        function()
            if hbuff.hasBuff(sourceUnit, "日蚀") then
                heffect.destroy(hcache.get(sourceUnit, "riyueshitexiao"))
                local remainingTime = hbuff.getBuffHandle(sourceUnit, "日蚀").remainingTime
                hcache.set(
                    sourceUnit,
                    "riyueshitexiao",
                    heffect.attach("spell\\XCFS_RS.mdx", sourceUnit, "overhead", remainingTime)
                )
            else
                heffect.destroy(hcache.get(sourceUnit, "riyueshitexiao"))
            end
        end,
        hslk.n2v("月蚀", "Art"),
        "月蚀|n降低星火术的施法时间，并提高该技能的暴击率和暴击伤害",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("至日")) then
        hbuff.update(
            5,
            sourceUnit,
            "至日",
            true,
            nil,
            nil,
            hslk.n2v("至日", "Art"),
            "坠星的触发概率提高100%",
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

local addxingjienengliang = function(sourceUnit, xingjienengliang)
    local rishiBuffhandle = hbuff.getBuffHandle(sourceUnit, "日蚀能量")
    local yueshiBuffhandle = hbuff.getBuffHandle(sourceUnit, "月蚀能量")
    local rishistack = 0
    local yueshistack = 0
    if rishiBuffhandle ~= nil then
        rishistack = rishiBuffhandle.stack
    end
    if yueshiBuffhandle ~= nil then
        yueshistack = yueshiBuffhandle.stack
    end
    if xingjienengliang == XINGJIE_NENGLIANG.RISHI and hbuff.hasBuff(sourceUnit, "日蚀") == false then
        if rishistack <= 4 then
            hbuff.addStackAttrBuff(
                CONST_DAMAGE_SRC.skill,
                sourceUnit,
                "日蚀能量",
                _attr({}),
                12,
                rishistack + 1,
                hslk.n2v("日蚀", "Art"),
                "日蚀能量|n叠加到6层时触发日蚀状态",
                true
            )
        elseif rishistack == 5 then
            addRishi(sourceUnit)
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "原始奥能脉冲星")
            if points > 0 and math.random(1, 100) <= 5 * points then
                local duration = 6
                if hmingwen.isEquipped("远古奥能脉冲星", hunit.getOwner(sourceUnit)) then
                    duration = duration + 2
                end
                chaofanzhimeng(sourceUnit, duration)
            end
        end
    elseif xingjienengliang == XINGJIE_NENGLIANG.YUESHI and hbuff.hasBuff(sourceUnit, "月蚀") == false then
        if yueshistack <= 4 then
            hbuff.addStackAttrBuff(
                CONST_DAMAGE_SRC.skill,
                sourceUnit,
                "月蚀能量",
                _attr({}),
                12,
                yueshistack + 1,
                hslk.n2v("月蚀", "Art"),
                "月蚀能量|n叠加到6层时触发月蚀状态",
                true
            )
        elseif yueshistack == 5 then
            addYueshi(sourceUnit)
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "原始奥能脉冲星")
            if points > 0 and math.random(1, 100) <= 5 * points then
                local duration = 6
                if hmingwen.isEquipped("远古奥能脉冲星", hunit.getOwner(sourceUnit)) then
                    duration = duration + 2
                end
                chaofanzhimeng(sourceUnit, duration)
            end
        end
    end
end

yangyanshu = function(sourceUnit, targetUnit)
    local basicInterval = 2
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "生死循环")
    if points > 0 then
        basicInterval = basicInterval * (1 - 0.05 * points)
    end
    local interval =
        math.round(basicInterval * 100 / (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)))
    local duration = 12
    heffect.xyz("spell\\XCFS_YYS.MDX", hunit.x(targetUnit), hunit.y(targetUnit), hunit.z(targetUnit), 0, 1, 1, 1, 1)
    hbuff.update(
        duration,
        targetUnit,
        "阳炎术" .. tostring(sourceUnit),
        false,
        nil,
        nil,
        hslk.n2v("阳炎术", "Art"),
        "阳炎术|n",
        1,
        interval,
        function(curTimer, buffHandle)
            buffHandle.remainingTime = buffHandle.remainingTime - interval
            local damageMulti = 0.3
            local damage = math.round(hattr.get(sourceUnit, "int", 0) * damageMulti, 0)
            buffHandle.description = "阳炎术|n每" .. buffHandle.interval .. "秒造成" .. damage .. "点火焰魔法伤害"
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = targetUnit,
                    damage = damage,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.MOFA,
                    triggerSkill = hslk.n2i("阳炎术"),
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT
                }
            )
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "生死循环")
            if points > 0 and math.random(1, 100) < 2 * points then
                hskill.heal(
                    {
                        healer = sourceUnit,
                        healee = sourceUnit,
                        heal = hunit.getMaxLife(sourceUnit) * 0.02,
                        healType = HEAL_TYPE.SKILL,
                        triggerSkill = hslk.n2i("阳炎术")
                    }
                )
            end
            local zhuixingrate = 20
            if hbuff.hasBuff(sourceUnit, "至日") then
                zhuixingrate = zhuixingrate * 2
            end
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("坠星")) and math.random(1, 100) <= zhuixingrate then
                danciliuxing(sourceUnit, targetUnit, false)
            end

            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "日光涌动")
            if points > 0 and math.random(1, 100) <= 5 * points then
                hbuff.update(
                    10,
                    sourceUnit,
                    "日光涌动",
                    true,
                    nil,
                    nil,
                    hslk.n2v("阳炎术", "Art"),
                    "日光涌动|n下一个愤怒可以连发",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE,
                    true
                )
            end
        end,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
end

yuehuoshu = function(sourceUnit, targetUnit) -- sourceUnit是施法单位 targetunit是目标单位
    local basicInterval = 2
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "生死循环")
    if points > 0 then
        basicInterval = basicInterval * (1 - 0.05 * points)
    end
    local interval =
        math.round(basicInterval * 100 / (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)))
    local duration = 12
    heffect.xyz("spell\\XCFS_Q.mdx", hunit.x(targetUnit), hunit.y(targetUnit), hunit.z(targetUnit), 0, 1, 1, 1, 1)
    hbuff.update(
        duration,
        targetUnit,
        "月火术" .. tostring(sourceUnit),
        false,
        nil,
        nil,
        hslk.n2v("月火术", "Art"),
        "月火术|n",
        1,
        interval,
        function(curTimer, buffHandle)
            buffHandle.remainingTime = buffHandle.remainingTime - interval
            local damageMulti = 0.5
            local damage = math.round(hattr.get(sourceUnit, "int", 0) * damageMulti, 0)
            buffHandle.description = "月火术|n每" .. buffHandle.interval .. "秒造成" .. damage .. "点自然魔法伤害"
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = targetUnit,
                    damage = damage,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.MOFA,
                    triggerSkill = hslk.n2i("月火术"),
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT
                }
            )
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "生死循环")
            if points > 0 and math.random(1, 100) < 2 * points then
                hskill.heal(
                    {
                        healer = sourceUnit,
                        healee = sourceUnit,
                        heal = hunit.getMaxLife(sourceUnit) * 0.02,
                        healType = HEAL_TYPE.SKILL,
                        triggerSkill = hslk.n2i("月火术")
                    }
                )
            end
            local zhuixingrate = 20
            if hbuff.hasBuff(sourceUnit, "至日") then
                zhuixingrate = 100
            end
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("坠星")) and math.random(1, 100) <= zhuixingrate then
                danciliuxing(sourceUnit, targetUnit, false)
            end
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "月之暗面")
            if points > 0 and math.random(1, 100) <= 5 * points then
                hbuff.update(
                    10,
                    sourceUnit,
                    "月之暗面",
                    true,
                    nil,
                    nil,
                    hslk.n2v("月火术", "Art"),
                    "月之暗面|n下一个星火术伤害提高30%",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE,
                    true
                )
            end
        end,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\4155.mp3", 1000, true), 80, targetUnit)
end

SKILLS["月火术"] = function(evtData)
    yuehuoshu(evtData.triggerUnit, evtData.targetUnit)
end

SKILLS["台风"] = function(evtData)
    taifeng(evtData)
end

taifeng = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local damage = hunit.getZhushuxing(sourceUnit) * 0.5
    local x, y = evtData.targetX, evtData.targetY
    local duration = 5
    local basicInterval = 1

    if hmingwen.isEquipped("台风之速", hunit.getOwner(sourceUnit)) then
        hbuff.update(
            6,
            sourceUnit,
            "台风之速",
            true,
            function()
                hattr.set(sourceUnit, 0, _attr({ move = "+80" }))
            end,
            function()
                hattr.set(sourceUnit, 0, _attr({ move = "-80" }))
            end,
            hslk.n2v("台风", "Art"),
            "台风之速|n移动速度增加80",
            1,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE,
            true
        )
    end

    local interval =
        math.round(basicInterval * 100 / (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)))
    heffect.xyz("spell\\XCFS_E2.MDX", x, y, hjapi.Z(x, y), duration, 1, 1, 1, 1)
    heffect.xyz("spell\\XCFS_E.MDX", x, y, hjapi.Z(x, y), 0, 1, 1, 1, 1)
    hskillMoban.radiusAOE(
        x,
        y,
        sourceUnit,
        400,
        function(enmeyUnit)
            hbuff.xuanyun(enmeyUnit, 1)
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = enmeyUnit,
                    damage = damage * 1.5,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.MOFA,
                    triggerSkill = hslk.n2i("台风"),
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                    shanghainame = "台风"
                }
            )
        end,
        false,
        true
    )
    htime.setInterval(
        interval,
        function(curTimer)
            if curTimer.passedSec() > duration then
                curTimer.destroy()
                return
            end
            hskillMoban.radiusAOE(
                x,
                y,
                sourceUnit,
                400,
                function(enmeyUnit)
                    hskill.damage(
                        {
                            sourceUnit = sourceUnit,
                            targetUnit = enmeyUnit,
                            damage = damage,
                            damageSrc = CONST_DAMAGE_SRC.skill,
                            damageType = DAMAGE_TYPE.MOFA,
                            triggerSkill = hslk.n2i("台风"),
                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                            shanghainame = "台风"
                        }
                    )
                end,
                false,
                true
            )
        end
    )
end

danciliuxing = function(sourceUnit, targetUnit, isFromQunxingzhuiluo)
    heffect.attach("Abilities\\Spells\\NightElf\\Starfall\\StarfallTarget.mdl", targetUnit, "origin", 0)
    --heffect.attach("war3mapImported\\[Spell]_047.mdx", targetUnit, "origin", 0)
    local damage = hunit.getZhushuxing(sourceUnit) * 1
    if hmingwen.isEquipped("强化坠星", hunit.getOwner(sourceUnit)) then
        damage = damage * 1.1
    end
    htime.setTimeout(
        0.8,
        function(t)
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = targetUnit,
                    damage = damage,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.MOFA,
                    triggerSkill = hslk.n2i("坠星"),
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                    shanghainame = "坠星"
                }
            )
        end
    )

    if hcache.get(sourceUnit, "[T2]炎灵套装(4件)", false) then
        if hskill.getCoolDown(sourceUnit, hslk.n2i("群星坠落")) >= 30 then
            hskill.setCoolDown(sourceUnit, hslk.n2i("群星坠落"), hskill.getCoolDown(sourceUnit, hslk.n2i("群星坠落")) - 1)
        end
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T2]炎灵套装") then
        if hskill.getCoolDown(sourceUnit, hslk.n2i("群星坠落")) >= 30 then
            hskill.setCoolDown(sourceUnit, hslk.n2i("群星坠落"), hskill.getCoolDown(sourceUnit, hslk.n2i("群星坠落")) - 0.5)
        end
    end

    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("坠星")) then
        hunit.addCurMana(sourceUnit, 3)
    end

    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "欧奈斯的洞察")
    if points > 0 and math.random(1, 100) <= 2 * points then
        hbuff.addStackAttrBuff(
            CONST_DAMAGE_SRC.skill,
            sourceUnit,
            "欧奈斯的洞察",
            _attr({}),
            10,
            2,
            hslk.n2v("星涌术", "Art"),
            "欧奈斯的洞察|n降低下一个星涌术50%的魔法消耗，同时增加其20%的伤害，该效果最多叠加2层",
            true
        )
    end
end

qunxingzhuiluo = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local basicInterval = 0.5
    local interval =
        math.round(basicInterval * 100 / (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)))
    local duration = 5
    if hmingwen.isEquipped("星辰专注", hunit.getOwner(sourceUnit)) then
        duration = duration + 3
    end
    hskill.setCoolDown(sourceUnit, hslk.n2i("星涌术"), 0)
    hbuff.update(
        duration,
        sourceUnit,
        "群星坠落",
        true,
        nil,
        nil,
        hslk.n2v("群星坠落", "Art"),
        "群星坠落|n",
        1,
        interval,
        function(curTimer, buffHandle)
            buffHandle.remainingTime = buffHandle.remainingTime - interval
            buffHandle.description = "群星坠落|n每" .. buffHandle.interval .. "秒向800码内随机2个单位释放坠星，造成自然魔法伤害"
            if hmingwen.isEquipped("星辰专注", hunit.getOwner(sourceUnit)) then
                local tmpTarget = table.randomOne(hgroup.createEnermyGroupByUnit(sourceUnit, 800))
                if tmpTarget ~= nil then
                    danciliuxing(sourceUnit, tmpTarget, true)
                end
            else
                local targetUnits = table.random(hgroup.createEnermyGroupByUnit(sourceUnit, 800), 2)
                for _, unit in ipairs(targetUnits) do
                    danciliuxing(sourceUnit, unit, true)
                end
            end
        end,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )

    if
        hcache.get(sourceUnit, "[T2]炎灵套装(3件)", false) or
        hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T2]炎灵套装")
    then
        local units = hgroup.createEnermyGroupByUnit(sourceUnit, 800)
        for _, unit in ipairs(units) do
            yuehuoshu(sourceUnit, unit)
        end
    end
end

SKILLS["群星坠落"] = function(evtData)
    qunxingzhuiluo(evtData)
end

SKILLS["超凡之盟"] = function(evtData)
    chaofanzhimeng(evtData.triggerUnit, 15)
end

SKILLS["星涌术"] = function(evtData)
    xingyongshu(evtData, false)
end

chaofanzhimeng = function(whichUnit, duration)
    if hbuff.hasBuffThatLastLongerthan(whichUnit, "超凡之盟", duration) then
        return
    end
    if hskill.hasActiveAbility(whichUnit, hslk.n2i("万灵之召")) then
        htime.setInterval(
            0.5,
            function(t)
                if t.passedSec() > 2 then
                    t.destroy()
                    return
                end
                local target = table.random(hgroup.createEnermyGroupByUnitWithoutInvincible(whichUnit, 800), 1)
                if type(target) ~= "table" then
                    local mathRandom = math.random(1, 100)
                    if mathRandom <= 70 then
                        fennu(whichUnit, target)
                    else
                        xinghuoshu({ triggerUnit = whichUnit, targetUnit = target })
                    end
                end
            end
        )
    end
    heffect.attach("chaofanzhimeng.mdx", whichUnit, "chest", duration)
    --  hunit.setAnimateSpeed(evtData.triggerUnit, 1, 0.35)
    --hsound.voice2Unit(hsound.voiceCreate("Abilities\\Spells\\Human\\Avatar\\Avatar.wav", 3199, true), 100, whichUnit)
    addRishi(whichUnit)
    addYueshi(whichUnit)

    local addAttr = _attr({})
    local minusAttr = _attr({})

    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "万物平衡")
    if points > 0 then
        addAttr = _attr({ fa_bao = "+" .. tostring(points * 2) })
        minusAttr = _attr({ fa_bao = "-" .. tostring(points * 2) })
    end

    hbuff.update(
        duration,
        whichUnit,
        "超凡之盟",
        true,
        function()
            hattr.set(whichUnit, 0, addAttr)
        end,
        function()
            hattr.set(whichUnit, 0, minusAttr)
        end,
        hslk.n2v("超凡之盟", "Art"),
        hslk.n2v("超凡之盟", "Ubertip"),
        nil,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE,
        true
    )
end

xinghuoshu = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local targetUnit = evtData.targetUnit
    local scale = 1
    local damage = hunit.getZhushuxing(sourceUnit) * 3

    if hcache.get(sourceUnit, "[T3]高阶法师套装(4件)", false) then
        damage = damage * 1.1
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T3]高阶法师套装") then
        damage = damage * 1.05
    end
    if hmingwen.isEquipped("星火专注", hunit.getOwner(sourceUnit)) then
        hbuff.addStackAttrBuff(
            CONST_DAMAGE_SRC.skill,
            sourceUnit,
            "星火专注",
            _attr({}),
            10,
            5,
            hslk.n2v("星火术", "Art"),
            "星火专注|n星火术会使得下一个星火术的伤害提高2%，最多叠加5次，持续时间为10秒",
            true
        )

        local stack = hbuff.getBuffHandle(sourceUnit, "星火专注").stack or 1
        damage = damage * (1 + 0.02 * stack)
    end
    local tmpAttr
    if hbuff.hasBuff(sourceUnit, "月蚀") then
        local master = hattribute.getWithLimit(sourceUnit, nil, "master", 0)
        local baojibaoshang = 20 + math.round(master / JINGTONG_XISHU)
        tmpAttr = _attr({ fa_bao = "+" .. baojibaoshang, fa_baoshang = "+" .. baojibaoshang })
        scale = scale * 1.2
    end
    if hbuff.hasBuff(sourceUnit, "超凡之盟") then
        local master = hattribute.getWithLimit(sourceUnit, nil, "master", 0)
        if hbuff.hasBuff(sourceUnit, "日蚀") then
            damage = damage * (1.4 + 0.02 * master / JINGTONG_XISHU)
            scale = scale * 1.2
        end
    end
    if hbuff.hasBuff(sourceUnit, "星涌") then
        damage = damage * 1.2
    end
    if hbuff.hasBuff(sourceUnit, "月之暗面") then
        hbuff.delete(sourceUnit, "月之暗面")
        damage = damage * 1.3
    end
    if hcache.get(sourceUnit, "[T1]灵力波动套装(4件)", false) then
        damage = damage * 1.1
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T1]灵力波动套装") then
        damage = damage * 1.05
    end
    heffect.xyz(
        "war3mapImported\\[Spell]_087.mdx",
        hunit.x(targetUnit),
        hunit.y(targetUnit),
        hunit.z(targetUnit),
        0,
        1,
        scale,
        scale,
        scale
    )
    hskill.damage(
        {
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            damage = damage,
            damageSrc = CONST_DAMAGE_SRC.skill,
            damageType = DAMAGE_TYPE.MOFA,
            triggerSkill = hslk.n2i("星火术"),
            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
            shanghainame = "星火术",
            tmpAttr = tmpAttr
        }
    )
    hskillMoban.radiusAOE(
        hunit.x(targetUnit),
        hunit.y(targetUnit),
        sourceUnit,
        300,
        function(enmeyUnit)
            if enmeyUnit == targetUnit then
                return
            end
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = enmeyUnit,
                    damage = damage / 3,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.MOFA,
                    triggerSkill = hslk.n2i("星火术"),
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                    shanghainame = "星火术",
                    tmpAttr = tmpAttr
                }
            )
        end,
        false,
        true
    )
    if hbuff.hasBuff(sourceUnit, "星涌") then
        hbuff.delete(sourceUnit, "星涌")
        local basicInterval = 2
        local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "生死循环")
        if points > 0 then
            basicInterval = basicInterval * (1 - 0.05 * points)
        end
        local interval =
            math.round(basicInterval * 100 / (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)))
        local duration = 12
        local damagePerJump = math.round(damage / duration * basicInterval)
        hbuff.update(
            duration,
            targetUnit,
            "星火术" .. tostring(sourceUnit),
            false,
            nil,
            nil,
            hslk.n2v("星火术", "Art"),
            "星火术|n",
            1,
            interval,
            function(curTimer, buffHandle)
                buffHandle.remainingTime = buffHandle.remainingTime - interval
                buffHandle.description = "星火术|n每" .. buffHandle.interval .. "秒造成" .. damagePerJump .. "点自然魔法伤害"
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = targetUnit,
                        damage = damagePerJump,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = hslk.n2i("星火术"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT
                    }
                )
                local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "生死循环")
                if points > 0 and math.random(1, 100) < 2 * points then
                    hskill.heal(
                        {
                            healer = sourceUnit,
                            healee = sourceUnit,
                            heal = hunit.getMaxLife(sourceUnit) * 0.02,
                            healType = HEAL_TYPE.SKILL,
                            triggerSkill = hslk.n2i("星火术")
                        }
                    )
                end
            end,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE,
            true
        )
    end

    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("日蚀")) then
        addxingjienengliang(sourceUnit, XINGJIE_NENGLIANG.RISHI)
        local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "安舍之赐")
        if points > 0 and math.random(1, 100) <= 20 * points then
            addxingjienengliang(sourceUnit, XINGJIE_NENGLIANG.RISHI)
        end
    end
    hskill.setCoolDown(sourceUnit, hslk.n2i("星火术"), 0)

    if hbuff.hasBuff(sourceUnit, "月蚀") then
        local xingyuejiaohuiPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "星月交辉")
        if xingyuejiaohuiPoints > 0 then
            local cooldownReduction = xingyuejiaohuiPoints * 0.1
            local currentCooldown = hskill.getCoolDown(sourceUnit, hslk.n2i("群星坠落"))
            hskill.setCoolDown(sourceUnit, hslk.n2i("群星坠落"), math.max(0, currentCooldown - cooldownReduction))
        end
    end
end

xingyongshu = function(evtData, skipMana)
    local manaCost = 20
    local sourceUnit = evtData.triggerUnit
    local targetUnit = evtData.targetUnit
    local damage = hunit.getZhushuxing(sourceUnit) * 4
    local guozaifalifactor = 1
    local guozaishanghaifactor = 0.5
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "群星之赐")
    if points > 0 then
        guozaifalifactor = guozaifalifactor - 0.03 * points
        guozaishanghaifactor = guozaishanghaifactor + 0.03 * points
    end
    if hbuff.hasBuff(sourceUnit, "星辰之力过载") then
        local stack = hbuff.getBuffHandle(sourceUnit, "星辰之力过载").stack or 1
        if hbuff.hasBuff(sourceUnit, "群星坠落") == false then
            manaCost = manaCost * (1 + guozaifalifactor * stack)
        end
        damage = damage * (1 + guozaishanghaifactor * stack)
    end
    if hbuff.hasBuff(sourceUnit, "欧奈斯的洞察") then
        local stack = hbuff.getBuffHandle(sourceUnit, "欧奈斯的洞察").stack or 1
        hbuff.delete(sourceUnit, "欧奈斯的洞察")
        damage = damage * (1 + 0.2 * stack)
        manaCost = manaCost * (1 - 0.5 * stack)
    end
    if skipMana ~= true then
        if hunit.getCurMana(sourceUnit) < manaCost then
            echo("法力值不足以释放星涌术", hunit.getOwner(sourceUnit))
            return
        end
        hunit.subCurMana(sourceUnit, manaCost)
    end
    local scale = 1
    local tmpAttr
    if hbuff.hasBuff(sourceUnit, "超凡之盟") then
        local master = hattribute.getWithLimit(sourceUnit, nil, "master", 0)
        if hbuff.hasBuff(sourceUnit, "月蚀") then
            local baojibaoshang = 20 + math.round(master / JINGTONG_XISHU)
            tmpAttr = _attr({ fa_bao = "+" .. baojibaoshang, fa_baoshang = "+" .. baojibaoshang })
            scale = scale * 1.2
        end
        if hbuff.hasBuff(sourceUnit, "日蚀") then
            damage = damage * (1.4 + 0.02 * master / JINGTONG_XISHU)
            scale = scale * 1.2
        end
    end
    heffect.xyz(
        "spell\\XCFS_R.MDX",
        --"xingyongshu1.mdx",
        hunit.x(targetUnit),
        hunit.y(targetUnit),
        hunit.z(targetUnit),
        0,
        1,
        scale,
        scale,
        scale
    )
    hskill.damage(
        {
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            damage = damage,
            damageSrc = CONST_DAMAGE_SRC.skill,
            damageType = DAMAGE_TYPE.MOFA,
            triggerSkill = hslk.n2i("星涌术"),
            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
            shanghainame = "星涌术",
            tmpAttr = tmpAttr
        }
    )
    hskillMoban.radiusAOE(
        hunit.x(targetUnit),
        hunit.y(targetUnit),
        sourceUnit,
        300,
        function(enmeyUnit)
            if enmeyUnit == targetUnit then
                return
            end
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = enmeyUnit,
                    damage = damage / 3,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.MOFA,
                    triggerSkill = hslk.n2i("星涌术"),
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                    shanghainame = "星涌术",
                    tmpAttr = tmpAttr
                }
            )
        end,
        false,
        true
    )
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("星辰漂移")) then
        hbuff.update(
            12,
            sourceUnit,
            "星涌",
            true,
            nil,
            nil,
            hslk.n2v("星涌术", "Art"),
            "星涌|n下一个星火术可以造成额外伤害并且该伤害会附加持续伤害",
            1,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE,
            true
        )
    end
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("星辰领主")) then
        hbuff.addStackAttrBuff(
            CONST_DAMAGE_SRC.skill,
            sourceUnit,
            "星辰领主",
            _attr({ attack_speed = "+3", skill_speed = "+3" }),
            15,
            6,
            hslk.n2v("星辰领主", "Art"),
            "星辰领主|n每层增加3%的攻击速度和施法速度",
            true
        )
    end
    hbuff.addStackAttrBuff(
        CONST_DAMAGE_SRC.skill,
        sourceUnit,
        "星辰之力过载",
        _attr({}),
        5,
        2,
        hslk.n2v("星涌术", "Art"),
        "星辰之力过载|n每层增加星涌术50%的伤害和100%的法力消耗",
        false
    )
end

fennu = function(sourceUnit, targetUnit)
    local mana = 2
    if
        hcache.get(sourceUnit, "[T1]灵力波动套装(3件)", false) or
        hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T1]灵力波动套装")
    then
        mana = mana - 1
    end

    if hbuff.hasBuff(sourceUnit, "日光涌动") then
        hbuff.delete(sourceUnit, "日光涌动")
        htime.setTimeout(
            0.2,
            function(t)
                fennu(sourceUnit, targetUnit)
            end
        )
    end
    local damage = hunit.getZhushuxing(sourceUnit) * 1.3
    local scale = 1
    local tmpAttr
    if hcache.get(sourceUnit, "[T3]高阶法师套装(3件)", false) then
        damage = damage * 1.1
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T3]高阶法师套装") then
        damage = damage * 1.05
    end
    local liyangzhinuPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "烈阳之怒")
    if liyangzhinuPoints > 0 then
        local chance = liyangzhinuPoints * 2
        if math.random(1, 100) <= chance then
            damage = damage * 1.5
            scale = scale * 1.2
        end
    end
    if hbuff.hasBuff(sourceUnit, "日蚀") then
        local master = hattribute.getWithLimit(sourceUnit, nil, "master", 0)
        local extraDamage = 20 + math.round(master / JINGTONG_XISHU)
        damage = damage * (1 + extraDamage / 100)
        scale = scale * 1.2
    end
    if hbuff.hasBuff(sourceUnit, "超凡之盟") then
        local master = hattribute.getWithLimit(sourceUnit, nil, "master", 0)
        if hbuff.hasBuff(sourceUnit, "月蚀") then
            local baojibaoshang = 20 + math.round(master / JINGTONG_XISHU)
            tmpAttr = _attr({ fa_bao = "+" .. baojibaoshang, fa_baoshang = "+" .. baojibaoshang })
            scale = scale * 1.2
        end
    end
    hunit.subCurMana(sourceUnit, mana)
    hskillMoban.missile(
        {
            model = "spell\\XCFS_FN.mdx",
            scale = scale,
            speed = 1200,
            hover = 100,
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            target_face_dis = 100,
            onEnd = function()
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = targetUnit,
                        damage = damage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = hslk.n2i("愤怒"),
                        isAttackReplacement = true,
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                        shanghainame = "愤怒",
                        tmpAttr = tmpAttr
                    }
                )
                if hskill.hasActiveAbility(sourceUnit, hslk.n2i("月蚀")) then
                    addxingjienengliang(sourceUnit, XINGJIE_NENGLIANG.YUESHI)
                    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "艾露恩之赐")
                    if points > 0 and math.random(1, 100) <= 20 * points then
                        addxingjienengliang(sourceUnit, XINGJIE_NENGLIANG.YUESHI)
                    end
                end
                if
                    hskill.hasActiveAbility(sourceUnit, hslk.n2i("阳炎术")) and
                    htime.setupAndCheckCoolDown(sourceUnit, "yangyanshu", jineng_cd["阳炎术"])
                then
                    yangyanshu(sourceUnit, targetUnit)
                end
            end
        }
    )
end

SKILL_SETUP["星辰法师"] = function(whichUnit)
    --基础回蓝1
    hattribute.set(whichUnit, 0, { mana_back = "=1" })
    hskill.registerAutoCast(whichUnit, hslk.n2i("星火术"))
    hskill.registerAutoCast(whichUnit, hslk.n2i("月火术"))
    hskill.registerAutoCast(whichUnit, hslk.n2i("星涌术"))
    hskill.registerMonitoringBuff(whichUnit, "日蚀", true)
    hskill.registerMonitoringBuff(whichUnit, "月蚀", true)
    hskill.registerMonitoringBuff(whichUnit, "星辰之力过载", true)
    hskill.registerMonitoringBuff(whichUnit, "星辰领主", true)
    hskill.registerMonitoringBuff(whichUnit, "群星坠落", true)
    hskill.registerMonitoringBuff(whichUnit, "月火术" .. tostring(whichUnit), false)
    hskill.setup_zhudong_jineng(
        whichUnit,
        hslk.n2i("星火术"),
        xinghuoshu,
        function(whichUnit, targetUnit)
            if hbuff.hasBuff(whichUnit, "月蚀") then
                local jinliexingyingPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "劲烈星影")
                return 1.5 - (jinliexingyingPoints * 0.1)
            end
            return 2.5
        end,
        nil,
        "resource\\war3mapImported\\sound\\fire_casting.wav",
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        true,
        true
    )
    hevent.register(
        whichUnit,
        CONST_EVENT.beforeAttackDamage,
        "xingchenfashi_auto_cast",
        function(evtData)
            evtData.damage = 0
            local sourceUnit = evtData.sourceUnit
            local targetUnit = evtData.targetUnit
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("愤怒")) and hunit.getCurMana(sourceUnit) >= 2 then
                fennu(sourceUnit, targetUnit)
                return
            end
            hunit.animate(sourceUnit, "stand")
            if hskill.checkAndEnterCD(sourceUnit, "no_mana_hint", 2) then
                echo("魔法不够释放任何技能", hunit.getOwner(sourceUnit))
            end
        end
    )

    hevent.register(
        whichUnit,
        CONST_EVENT.fashubaoji,
        "xingchenfashi_baoji",
        function(evtData)
            if
                hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("坠星")) and
                evtData.damageSpeedType == CONST_DAMAGE_SPEED_TYPE.IMMEDIATE and
                evtData.triggerSkill == hslk.n2i("坠星") and
                hmingwen.isEquipped("星辰活力", hunit.getOwner(whichUnit))
            then
                hunit.addCurMana(whichUnit, 3)
            end

            if
                hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("星辰光环")) and
                evtData.damageSpeedType == CONST_DAMAGE_SPEED_TYPE.IMMEDIATE and
                math.random(1, 100) <= 20
            then
                hgroup.forEach(
                    hgroup.createAllyGroupByUnit(evtData.triggerUnit, 2000),
                    function(enumUnit)
                        hbuff.addStackAttrBuff(
                            CONST_DAMAGE_SRC.skill,
                            enumUnit,
                            "星辰光环",
                            _attr({ fa_bao = "+1" }),
                            10,
                            4,
                            hslk.n2v("星辰光环", "Art"),
                            "星辰光环|n每层增加1%法爆",
                            true
                        )
                    end
                )
            end
        end
    )
end
