local EMOLIESHOU_JINGTONG_XISHU = 15

---被动技能cd类常数
local EMOLIESHOU_CD = {}
EMOLIESHOU_CD["绝望本能"] = 180

SKILL_ON_LEVEL_UP["恶魔猎手"] = function(whichUnit)
    local zhandounuhou = hslk.n2i("恶魔气息")
    if hskill.hasActiveAbility(whichUnit, zhandounuhou) then
        hskillMoban.guanghuan(
            whichUnit,
            zhandounuhou,
            2000,
            hslk.i2v(zhandounuhou, "_guanghuanAttr"),
            true,
            true,
            "恶魔气息|n恶魔猎手身上的恶魔气息赋予半径2000范围内所有友方单位8%攻击速度的增幅"
        )
        hskill.addProperty(whichUnit, zhandounuhou, 1)
    end
end

local emozhiren = function(sourceUnit, targetUnit)
    local damage = hattribute.getWithLimit(sourceUnit, nil, "agi", 0) * 1.2
    local manaback = 20
    if hmingwen.isEquipped("恶魔之刃精通", hunit.getOwner(sourceUnit)) then
        damage = hattribute.getWithLimit(sourceUnit, nil, "agi", 0) * 0.3
        manaback = 6
    end
    if hmingwen.isEquipped("恶魔之咬", hunit.getOwner(sourceUnit)) then
        manaback = manaback * 1.2
    end

    hskill.damage(
        {
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            damage = damage,
            damageSrc = CONST_DAMAGE_SRC.skill,
            damageType = DAMAGE_TYPE.WULI,
            triggerSkill = hslk.n2i("恶魔之刃"),
            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.HUNLUAN },
            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
        }
    )
    hunit.addCurMana(sourceUnit, manaback)
end

dancitouzhiliren = function(sourceUnit, targetUnit, damage, tanshe, missileStartUnit, firstHit, damageElementType)
    local finalMissileStartUnit = missileStartUnit or sourceUnit
    hskillMoban.missile(
        {
            model = "spell\\DH_Q.mdx",
            scale = 1,
            speed = 1500,
            hover = 100,
            height = 10,
            shake = 0.1,
            sourceUnit = finalMissileStartUnit,
            targetUnit = targetUnit,
            target_face_dis = 10,
            onEnd = function()
                local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "战刃风暴")
                if points > 0 and htime.setupAndCheckCoolDown(sourceUnit, "战刃风暴", 9) then
                    local zrfbdamage =
                        points * 0.1 *
                        (hunit.getZhushuxing(sourceUnit) + hattr.getWithLimit(sourceUnit, nil, "attack", 0))
                    local interval = 1
                    local skillspeedfactor = (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)) / 100
                    interval = math.round(interval / skillspeedfactor)
                    local duration = 6
                    local x, y = hunit.x(targetUnit), hunit.y(targetUnit)
                    local e = heffect.xyz("spell\\DH_Q.mdl", x, y, hjapi.Z(x, y) + 50, duration, 1, 3, 3, 1)

                    htime.setInterval(
                        interval,
                        function(curTimer)
                            if curTimer.passedSec() >= duration then
                                curTimer.destroy()
                                heffect.destroy(e)
                                return
                            end
                            hskillMoban.radiusAOE(
                                x,
                                y,
                                sourceUnit,
                                200,
                                function(u)
                                    hskill.damage(
                                        {
                                            sourceUnit = sourceUnit,
                                            targetUnit = u,
                                            damage = zrfbdamage,
                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                            damageType = DAMAGE_TYPE.WULI,
                                            triggerSkill = hslk.n2i("装备技能"),
                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                                            shanghainame = "战刃风暴"
                                        }
                                    )
                                end,
                                false,
                                true
                            )
                        end
                    )
                end

                local lirendamage = damage
                if hmingwen.isEquipped("第一滴血", hunit.getOwner(sourceUnit)) and firstHit then
                    lirendamage = lirendamage * 2
                end
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = targetUnit,
                        damage = lirendamage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.WULI,
                        triggerSkill = hslk.n2i("投掷利刃"),
                        --isAttackReplacement = true,
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                        shanghainame = "投掷利刃",
                        damageElementType = { damageElementType or CONST_DAMAGE_ELEMENT_TYPE.METAL }
                    }
                )
                hbuff.xuanyun(targetUnit, 0.01)
                hunit.addCurMana(sourceUnit, 5)
                if math.random(1, 2) == 1 then
                    hsound.voice2Unit(
                        hsound.voiceCreate(
                            "resource\\war3mapImported\\sound\\spell_dh_throwglaives_impact_01.mp3",
                            1000,
                            true
                        ),
                        100,
                        targetUnit
                    )
                else
                    hsound.voice2Unit(
                        hsound.voiceCreate(
                            "resource\\war3mapImported\\sound\\spell_dh_throwglaives_impact_02.mp3",
                            1000,
                            true
                        ),
                        100,
                        targetUnit
                    )
                end
                if hskill.hasActiveAbility(sourceUnit, hslk.n2i("裂魂")) then
                    local interval = 1
                    local skillspeedfactor = (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)) / 100
                    interval = math.round(interval / skillspeedfactor)
                    local liehundamage = math.floor(hunit.getZhushuxing(sourceUnit) * 0.8)
                    local duration = 6
                    if hmingwen.isEquipped("裂魂之伤", hunit.getOwner(sourceUnit)) then
                        duration = duration + 2
                    end
                    hbuff.update(
                        duration,
                        targetUnit,
                        "裂魂" .. tostring(sourceUnit),
                        false,
                        function()
                        end,
                        function()
                        end,
                        hslk.n2v("投掷利刃", "Art"),
                        "裂魂|n 每" .. interval .. "秒受到" .. liehundamage .. "混乱物理伤害",
                        1,
                        interval,
                        function(_, buffHandle)
                            buffHandle.remainingTime = buffHandle.remainingTime - buffHandle.interval
                            hskill.damage(
                                {
                                    sourceUnit = sourceUnit,
                                    targetUnit = targetUnit,
                                    damage = liehundamage,
                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                    damageType = DAMAGE_TYPE.WULI,
                                    triggerSkill = hslk.n2i("裂魂"),
                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                                    shanghainame = "裂魂",
                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.HUNLUAN }
                                }
                            )
                            -- 裂魂dot buff
                            heffect.attach("spell\\DH_X.mdx", targetUnit, "chest", 0)

                            local zrcnpoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "战刃充能")
                            if
                                zrcnpoints > 0 and math.random(1, 100) <= 3 * zrcnpoints and
                                htime.setupAndCheckCoolDown(sourceUnit, "战刃充能", 3)
                            then
                                hskill.setCoolDown(sourceUnit, hslk.n2i("投掷利刃"), 0)
                            end
                        end,
                        nil,
                        nil,
                        HBUFF_UPDATE_MODE.OVERWRITE,
                        true
                    )
                end
                if tanshe > 0 then
                    local bounceUnits =
                        hgroup.createEnermyGroupByXY(sourceUnit, hunit.x(targetUnit), hunit.y(targetUnit), 500)
                    table.delete(bounceUnits, targetUnit)
                    if #bounceUnits > 0 then
                        local bounceUnit = table.random(bounceUnits, 1)
                        dancitouzhiliren(sourceUnit, bounceUnit, damage, tanshe - 1, targetUnit, false, damageElementType)
                    end
                end
            end
        }
    )
end

SKILLS_CAST["投掷利刃"] = function(evtData)
    hunit.setAnimateSpeed(evtData.triggerUnit, 2.5, 0.2)
    hunit.animate(evtData.triggerUnit, "attack")
    local damage =
        hattribute.getWithLimit(evtData.triggerUnit, nil, "attack", 0) +
        hattribute.getWithLimit(evtData.triggerUnit, nil, "agi", 0)
    if math.random(1, 2) == 1 then
        hsound.voice2Unit(
            hsound.voiceCreate("resource\\war3mapImported\\sound\\spell_dh_throw_glaives_cast_01.mp3", 1000, true),
            100,
            evtData.triggerUnit
        )
    else
        hsound.voice2Unit(
            hsound.voiceCreate("resource\\war3mapImported\\sound\\spell_dh_throw_glaives_cast_02.mp3", 1000, true),
            100,
            evtData.triggerUnit
        )
    end
    htime.setTimeout(
        0.2,
        function()
            local emzjpoints = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "恶魔追击")
            if emzjpoints > 0 then
                hbuff.update(
                    10,
                    evtData.triggerUnit,
                    "恶魔追击",
                    true,
                    function()
                    end,
                    function()
                    end,
                    hslk.n2v("投掷利刃", "Art"),
                    "恶魔追击|n下次攻击会向敌人冲锋并造成额外伤害",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE
                )
            end
            local damageElementType = CONST_DAMAGE_ELEMENT_TYPE.METAL
            if hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("战刃艺术")) then
                damage = damage * 1.3
                hbuff.update(
                    10,
                    evtData.triggerUnit,
                    "战刃艺术",
                    true,
                    function()
                    end,
                    function()
                    end,
                    hslk.i2v(hslk.n2i("战刃艺术"), "Art"),
                    "战刃艺术|n强化你的下一次混乱打击和刃舞。混乱打击触发无情强攻概率翻倍，刃舞伤害增加1段。",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE
                )
                damageElementType = CONST_DAMAGE_ELEMENT_TYPE.HUNLUAN
            end
            dancitouzhiliren(evtData.triggerUnit, evtData.targetUnit, damage, 2, evtData.triggerUnit, true,
                damageElementType)
        end
    )
end

SKILLS_CAST["刃舞"] = function(evtData)
    local sourceUnit = evtData.triggerUnit

    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("混沌理论")) then
        hbuff.update(
            10,
            sourceUnit,
            "混沌理论",
            true,
            function()
            end,
            function()
            end,
            hslk.i2v(hslk.n2i("混沌理论"), "Art"),
            "混沌理论|n下一次混乱打击暴击率提高30%并且伤害提高10%",
            1,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE
        )
    end

    local lyfzpoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "烈焰符咒")
    if lyfzpoints > 0 then
        local x, y = hunit.x(sourceUnit), hunit.y(sourceUnit)
        heffect.xyz("spell\\DH_lieyanfuwen_green.MDX", x, y, hjapi.Z(x, y) + 50, 1, 1, 1, 1, 1)
        htime.setTimeout(
            1,
            function()
                hskillMoban.radiusAOE(
                    x,
                    y,
                    sourceUnit,
                    300,
                    function(u)
                        hskill.damage(
                            {
                                sourceUnit = sourceUnit,
                                targetUnit = u,
                                damage = lyfzpoints * 0.4 *
                                    (hunit.getZhushuxing(sourceUnit) + hattr.getWithLimit(sourceUnit, nil, "attack", 0)),
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.MOFA,
                                triggerSkill = hslk.n2i("装备技能"),
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                shanghainame = "烈焰符咒"
                            }
                        )
                        hbuff.update(
                            3,
                            u,
                            "烈焰符咒",
                            false,
                            function()
                                hevent.register(
                                    u,
                                    CONST_EVENT.damagingCustomTarget,
                                    "烈焰符咒增伤",
                                    function(evtData)
                                        evtData.damage = evtData.damage * (1 + 0.006 * lyfzpoints)
                                    end
                                )
                            end,
                            function()
                                hevent.unregister(u, CONST_EVENT.damagingCustomTarget, "烈焰符咒增伤")
                            end,
                            "ReplaceableTextures\\DH\\ability_demonhunter_sigilofinquisition.blp",
                            "烈焰符咒|n提高受到" .. lyfzpoints * 0.6 .. "%受到的伤害",
                            1,
                            nil,
                            nil,
                            nil,
                            nil,
                            HBUFF_UPDATE_MODE.OVERWRITE,
                            true
                        )
                    end
                )
            end
        )
    end

    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "献祭")
    if points > 0 and htime.setupAndCheckCoolDown(sourceUnit, "献祭", 8) then
        local damage = points * 0.15 * (hunit.getZhushuxing(sourceUnit))
        local interval = math.round(1 * 100 / (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)))
        local duration = 5
        local e =
            heffect.attach("Abilities\\Spells\\NightElf\\Immolation\\ImmolationTarget.mdl", sourceUnit, "origin", -1)
        hbuff.update(
            duration,
            sourceUnit,
            "献祭",
            true,
            function()
            end,
            function()
                heffect.destroy(e)
            end,
            hslk.n2v("献祭", "Art"),
            "献祭：每" .. interval .. "秒对周围单位造成" .. damage .. "火焰魔法伤害",
            1,
            interval,
            function(_, buffHandle)
                buffHandle.remainingTime = buffHandle.remainingTime - buffHandle.interval
                hskillMoban.radiusAOE(
                    hunit.x(sourceUnit),
                    hunit.y(sourceUnit),
                    sourceUnit,
                    300,
                    function(u)
                        heffect.attach("Abilities\\Spells\\NightElf\\Immolation\\ImmolationDamage.mdl", u, "head", 0.1)
                        local finalDamage = damage
                        if hbuff.hasBuff(u, "灼热之伤" .. tostring(sourceUnit)) then
                            local zrzspoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "灼热之伤")
                            finalDamage = finalDamage * (1 + zrzspoints * 0.05)
                        end
                        hskill.damage(
                            {
                                sourceUnit = sourceUnit,
                                targetUnit = u,
                                damage = finalDamage,
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.MOFA,
                                triggerSkill = hslk.n2i("装备技能"),
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                shanghainame = "献祭"
                            }
                        )
                    end,
                    false,
                    true
                )
            end,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE,
            true
        )
    end

    local damage =
        (hattribute.getWithLimit(sourceUnit, nil, "attack", 0) + hattribute.getWithLimit(sourceUnit, nil, "agi", 0)) *
        1.2
    if hbuff.hasBuff(sourceUnit, "无情狩猎") then
        local wqslPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "无情狩猎")
        local bonus = 1 + wqslPoints * 0.06
        damage = damage * bonus
        hbuff.delete(sourceUnit, "无情狩猎")
    end
    local maxCount = 3
    if hbuff.hasBuff(sourceUnit, "战刃艺术") then
        maxCount = maxCount + 1
        hbuff.delete(sourceUnit, "战刃艺术")
    end
    local interval = 0.2
    local skillspeedfactor = (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)) / 100
    interval = math.round(interval / skillspeedfactor)
    local count = 1

    local x, y = hunit.x(sourceUnit), hunit.y(sourceUnit)
    local centerX, centerY = math.polarProjection(x, y, 150, hunit.getFacing(sourceUnit))
    local z = hjapi.Z(x, y)

    if hcache.get(sourceUnit, "[T2]追猎者套装(4件)", false) then
        damage = damage * 1.1
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T2]追猎者套装") then
        damage = damage * 1.05
    end

    local singleRenwu = function(currentCount)
        local randomAngel = math.random(0, 360)
        local startX, startY = math.polarProjection(centerX, centerY, 300, randomAngel)
        local endX, endY = math.polarProjection(centerX, centerY, 300, randomAngel + 180)

        local model = hhuanhua.getUnitHuanhuaStatus(sourceUnit)[HUANHUA_POSITION.JUESE].file
        local zhushou, fushou
        if hhuanhua.getUnitHuanhuaStatus(sourceUnit)[HUANHUA_POSITION.ZHUSHOU] then
            zhushou = hhuanhua.getUnitHuanhuaStatus(sourceUnit)[HUANHUA_POSITION.ZHUSHOU].file
        end
        if hhuanhua.getUnitHuanhuaStatus(sourceUnit)[HUANHUA_POSITION.FUSHOU] then
            fushou = hhuanhua.getUnitHuanhuaStatus(sourceUnit)[HUANHUA_POSITION.FUSHOU].file
        end
        if math.random(1, 2) == 1 then
            hsound.voice2Unit(
                hsound.voiceCreate("resource\\war3mapImported\\sound\\spell_dh_fel_barrage_cast_02.mp3", 1000, true),
                100,
                sourceUnit
            )
        else
            hsound.voice2Unit(
                hsound.voiceCreate("resource\\war3mapImported\\sound\\spell_dh_fel_barrage_cast_01.mp3", 1000, true),
                100,
                sourceUnit
            )
        end
        local damageElementType = CONST_DAMAGE_ELEMENT_TYPE.METAL
        if hbuff.hasBuff(sourceUnit, "恶魔变形") then
            damageElementType = CONST_DAMAGE_ELEMENT_TYPE.HUNLUAN
            damage = damage * 1.1
        end

        hskillMoban.leap(
            {
                leftAttach = fushou,
                rightAttach = zhushou,
                otherAttach = { { "spell\\DH_E_small.mdl", "chest" } },
                arrowAttachModel = model,
                --arrowUnit = sourceUnit, -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                sourceUnit = sourceUnit, --伤害来源（必须有！不管有没有伤害）
                --targetUnit = evtData.targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                tokenX = startX,         --冲击开始x坐标（可选的，对点冲击，与某目标无关）
                tokenY = startY,         --冲击开始y坐标（可选的，对点冲击，与某目标无关）
                unbindWhenEnd = true,
                x = endX,                --冲击的x坐标（可选的，对点冲击，与某目标无关）
                y = endY,                --冲击的y坐标（可选的，对点冲击，与某目标无关）
                speed = 45,              --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                acceleration = 1,
                shake = 0,               --摇摆振幅角度[-90~+90|random]（可选的，默认0)
                filter = function(enum)
                    return hunit.isEnemy(sourceUnit, enum) and hunit.isAlive(enum)
                end,                     --必须有
                tokenArrowScale = 1.00,  --前冲的特效作为马甲冲击时的模型缩放
                tokenArrowOpacity = 0.6, --前冲的特效作为马甲冲击时的模型透明度[0-1]
                tokenArrowHeight = 0.00, --前冲的特效作为马甲冲击时的初始离地高度
                effectMovement = nil,    --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                --animateMovement = "attack",
                animation = "attack",
                effectEnd = nil,                    --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                damageMovement = damage,            --移动过程中的伤害（可选的，默认为0）
                damageMovementRadius = 300,         --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
                damageMovementRepeat = false,       --移动过程中伤害是否可以重复造成（可选的，默认为不能）
                damageMovementDrag = false,         --移动过程是否拖拽敌人（可选的，默认为不能）
                damageEndRadius = 0,                --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
                damageSrc = CONST_DAMAGE_SRC.skill, --伤害的种类（可选）
                --damageEffect = "war3mapImported\\AZ_gelie.mdx", --伤害特效（可选）
                damageElementType = { damageElementType },
                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                damageType = DAMAGE_TYPE.WULI,
                damageSkill = hslk.n2i("刃舞"),
                oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
                endDistance = 0,
                skipPathCheck = true,
                extraInfluence = function(whichUnit)
                    local zrzspoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "灼热之伤")
                    if zrzspoints > 0 then
                        local zrzsinternal =
                            math.round(1 * 100 / (100 + hattribute.getWithLimit(sourceUnit, nil, "skill_speed", 0)))
                        local zrzsdamage = zrzspoints * 0.1 * (hunit.getZhushuxing(sourceUnit))
                        hbuff.update(
                            4,
                            whichUnit,
                            "灼热之伤" .. tostring(sourceUnit),
                            false,
                            function()
                            end,
                            function()
                            end,
                            hslk.n2v("献祭", "Art"),
                            --TODO 图标
                            "灼热之伤：每" .. zrzsinternal .. "秒造成造成" .. zrzsdamage .. "点混乱魔法伤害",
                            1,
                            zrzsinternal,
                            function(_, buffHandle)
                                buffHandle.remainingTime = buffHandle.remainingTime - buffHandle.interval
                                hskill.damage(
                                    {
                                        sourceUnit = sourceUnit,
                                        targetUnit = whichUnit,
                                        damage = zrzsdamage,
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.MOFA,
                                        triggerSkill = hslk.n2i("装备技能"),
                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.HUNLUAN },
                                        shanghainame = "灼热之伤"
                                    }
                                )
                            end,
                            nil,
                            nil,
                            HBUFF_UPDATE_MODE.OVERWRITE,
                            true
                        )
                    end
                end, --对选中的敌人的额外影响，会回调该敌人单位，可以对其做出自定义行为
                onEnding = function(_, _, timePassed)
                end
            }
        )
    end

    count = count + 1
    singleRenwu(count)
    htime.setInterval(
        interval,
        function(curTimer)
            if count > maxCount then
                curTimer.destroy()
                return
            end
            count = count + 1
            singleRenwu(count)
        end
    )
end

SKILLS_CAST["邪能冲撞"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local damage = (hattribute.getWithLimit(sourceUnit, nil, "attack", 0) + hunit.getZhushuxing(sourceUnit)) * 1.5

    local distance = 700
    local pointX, pointY = evtData.targetX, evtData.targetY
    local angle = math.angle(hunit.x(sourceUnit), hunit.y(sourceUnit), pointX, pointY)
    local x, y = math.polarProjection(hunit.x(sourceUnit), hunit.y(sourceUnit), distance, angle)
    if math.distance(hunit.x(sourceUnit), hunit.y(sourceUnit), pointX, pointY) < distance then
        x, y = pointX, pointY
    end
    local manaBack = 30
    hunit.addCurMana(sourceUnit, manaBack)
    htime.setTimeout(
        0.07,
        function()
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("势如破竹")) then
                local zengshang = 10
                if hcache.get(sourceUnit, "[T1]猎杀者套装(4件)", false) then
                    zengshang = zengshang + 10
                elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T1]猎杀者套装") then
                    zengshang = zengshang + 5
                end
                local duration = 5
                if hcache.get(sourceUnit, "[T3]暗影猎手套装(4件)", false) then
                    duration = duration + 4
                elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T3]暗影猎手套装") then
                    duration = duration + 2
                end
                hbuff.update(
                    duration,
                    sourceUnit,
                    "势如破竹",
                    true,
                    function()
                        hevent.register(
                            sourceUnit,
                            CONST_EVENT.damagingCustomSource,
                            "邪能冲撞增伤",
                            function(evtData)
                                evtData.damage = evtData.damage * (1 + zengshang / 100)
                            end
                        )
                    end,
                    function()
                        hevent.unregister(sourceUnit, CONST_EVENT.damagingCustomSource, "邪能冲撞增伤")
                    end,
                    hslk.i2v(hslk.n2i("邪能冲撞"), "Art"),
                    "势如破竹|n持续时间内所有伤害提高" .. zengshang .. "%（独立增伤）",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE
                )
            end
            hsound.voice2Unit(
                hsound.voiceCreate("resource\\war3mapImported\\sound\\spell_dh_felrush_cast_01.mp3", 1000, true),
                100,
                sourceUnit
            )
            if hmingwen.isEquipped("嗜血冲撞", hunit.getOwner(sourceUnit)) then
                hskill.heal(
                    {
                        healer = sourceUnit,
                        healee = sourceUnit,
                        heal = hunit.getMaxLife(sourceUnit) * 0.05,
                        effect = nil,
                        healType = HEAL_TYPE.SKILL
                    }
                )
            end
            local e = heffect.attach("spell\\DH_E.mdl", sourceUnit, "origin", 0.8)
            hskillMoban.leap(
                {
                    arrowUnit = sourceUnit,  -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                    sourceUnit = sourceUnit, --伤害来源（必须有！不管有没有伤害）
                    --targetUnit = evtData.targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                    x = x,                   --冲击的x坐标（可选的，对点冲击，与某目标无关）
                    y = y,                   --冲击的y坐标（可选的，对点冲击，与某目标无关）
                    speed = 22,              --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                    acceleration = 5,
                    shake = 0,               --摇摆振幅角度[-90~+90|random]（可选的，默认0)
                    filter = function(enum)
                        return hunit.isEnemy(sourceUnit, enum) and hunit.isAlive(enum)
                    end,                      --必须有
                    tokenArrowScale = 1.00,   --前冲的特效作为马甲冲击时的模型缩放
                    tokenArrowOpacity = 1.00, --前冲的特效作为马甲冲击时的模型透明度[0-1]
                    tokenArrowHeight = 0.00,  --前冲的特效作为马甲冲击时的初始离地高度
                    effectMovement = nil,     --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                    --animateMovement = 1,
                    animation = "walk",
                    effectEnd = nil,                                --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                    damageMovement = damage,                        --移动过程中的伤害（可选的，默认为0）
                    damageMovementRadius = 200,                     --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
                    damageMovementRepeat = false,                   --移动过程中伤害是否可以重复造成（可选的，默认为不能）
                    damageMovementDrag = false,                     --移动过程是否拖拽敌人（可选的，默认为不能）
                    damageEndRadius = 0,                            --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
                    damageSrc = CONST_DAMAGE_SRC.skill,             --伤害的种类（可选）
                    damageEffect = "war3mapImported\\AZ_gelie.mdx", --伤害特效（可选）
                    damageType = DAMAGE_TYPE.WULI,
                    damageSkill = hslk.n2i("邪能冲撞"),
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                    oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
                    endDistance = 0,
                    extraInfluence = function(whichUnit)
                        hbuff.xuanyun(whichUnit, 0.01)
                    end, --对选中的敌人的额外影响，会回调该敌人单位，可以对其做出自定义行为
                    onStart = function()
                        hjapi.DzUnitSilence(sourceUnit, true)
                    end,
                    onEnding = function(_, _, timePassed)
                        heffect.destroy(e)
                        hjapi.DzUnitSilence(sourceUnit, false)
                    end
                }
            )

            local wqslPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "无情狩猎")
            if wqslPoints > 0 then
                local bonus = wqslPoints * 0.06
                hbuff.update(
                    10,
                    sourceUnit,
                    "无情狩猎",
                    true,
                    nil,
                    nil,
                    hslk.n2v("邪能冲撞", "Art"),
                    "无情狩猎：下一个混乱打击或者刃舞伤害提升" .. (bonus * 100) .. "%",
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

local dancihunluandaji
dancihunluandaji = function(sourceUnit, targetUnit, canDuochong)
    local damage = (hattribute.getWithLimit(sourceUnit, nil, "attack", 0) + hunit.getZhushuxing(sourceUnit)) * 1.5
    local tmpAttr = {}
    if hbuff.hasBuff(sourceUnit, "混沌理论") then
        tmpAttr["wu_bao"] = "+30"
        hbuff.delete(sourceUnit, "混沌理论")
        if hmingwen.isEquipped("混沌真理", hunit.getOwner(sourceUnit)) then
            damage = damage * 1.2
        else
            damage = damage * 1.1
        end
    end

    if hcache.get(sourceUnit, "[T3]暗影猎手套装(3件)", false) then
        damage = damage * 1.04
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T3]暗影猎手套装") then
        damage = damage * 1.02
    end

    if math.random(1, 2) == 1 then
        hsound.voice2Unit(
            hsound.voiceCreate("resource\\war3mapImported\\sound\\spell_dh_demonblade_cast_01.mp3", 1000, true),
            100,
            targetUnit
        )
    else
        hsound.voice2Unit(
            hsound.voiceCreate("resource\\war3mapImported\\sound\\spell_dh_demonblade_cast_02.mp3", 1000, true),
            100,
            targetUnit
        )
    end
    heffect.xyz(
        "spell\\DH_R1.mdx",
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
        hunit.getFacing(sourceUnit)
    )

    heffect.xyz(
        "spell\\DH_R2.mdx",
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
        hunit.getFacing(sourceUnit) - 180
    )
    local damageElementType = CONST_DAMAGE_ELEMENT_TYPE.METAL
    if hbuff.hasBuff(sourceUnit, "恶魔变形") then
        damageElementType = CONST_DAMAGE_ELEMENT_TYPE.HUNLUAN
        damage = damage * 1.1
    end
    if hbuff.hasBuff(sourceUnit, "无情狩猎") then
        local wqslPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "无情狩猎")
        local bonus = 1 + wqslPoints * 0.06
        damage = damage * bonus
        hbuff.delete(sourceUnit, "无情狩猎")
    end

    hskill.damage(
        {
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            damage = damage,
            damageSrc = CONST_DAMAGE_SRC.skill,
            damageType = DAMAGE_TYPE.WULI,
            triggerSkill = hslk.n2i("混乱打击"),
            damageElementType = { damageElementType },
            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
            tmpAttr = tmpAttr,
            criticalEffect = function(options)
                hunit.addCurMana(sourceUnit, 10)
            end
        }
    )
    hskill.damage(
        {
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            damage = damage,
            damageSrc = CONST_DAMAGE_SRC.skill,
            damageType = DAMAGE_TYPE.WULI,
            triggerSkill = hslk.n2i("混乱打击"),
            damageElementType = { damageElementType },
            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
            tmpAttr = tmpAttr,
            criticalEffect = function(options)
                hunit.addCurMana(sourceUnit, 10)
            end
        }
    )

    local wqqgrate = 15
    if hbuff.hasBuff(sourceUnit, "战刃艺术") then
        wqqgrate = wqqgrate + 15
        hbuff.delete(sourceUnit, "战刃艺术")
    end
    if canDuochong and hskill.hasActiveAbility(sourceUnit, hslk.n2i("无情强攻")) and math.random(1, 100) <= wqqgrate then
        htime.setTimeout(
            0.15,
            function()
                dancihunluandaji(sourceUnit, targetUnit, false)
            end
        )
    end
end

SKILLS_CAST["混乱打击"] = function(evtData)
    hunit.setAnimateSpeed(evtData.triggerUnit, 2, 0.25)
    hunit.animate(evtData.triggerUnit, "Attack")
    htime.setTimeout(
        0.2,
        function(curTimer)
            dancihunluandaji(evtData.triggerUnit, evtData.targetUnit, true)
        end
    )
end

local emobianxing = function(whichUnit, duration)
    local mohuaFile = "war3mapImported\\emolieshoubiansheng.mdx"
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\spell_dh_impact_land_metamorph_01.mp3", 1000, true),
        100,
        whichUnit
    )
    hunit.addCurMana(whichUnit, hunit.getMaxMana(whichUnit))
    local emsfPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "恶魔释放")
    if emsfPoints > 0 then
        local critDamageBonus = emsfPoints * 3
        hbuff.update(
            8,
            whichUnit,
            "恶魔释放",
            true,
            function()
                hattribute.set(whichUnit, 0, {
                    wu_baoshang = "+" .. critDamageBonus,
                    fa_baoshang = "+" .. critDamageBonus
                })
            end,
            function()
                hattribute.set(whichUnit, 0, {
                    wu_baoshang = "-" .. critDamageBonus,
                    fa_baoshang = "-" .. critDamageBonus
                })
            end,
            hslk.n2v("恶魔变形", "Art"),
            "恶魔释放|n提升" .. critDamageBonus .. "%的爆伤",
            1,
            nil,
            nil,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE
        )
    end
    hbuff.update(
        duration,
        whichUnit,
        "恶魔变形",
        true,
        function()
            hattribute.set(whichUnit, 0, _attr({ attack_speed = "+30" }))
            hcache.set(
                whichUnit,
                "emobianxingoriginFile",
                hhuanhua.getUnitHuanhuaStatus(whichUnit)[HUANHUA_POSITION.JUESE].file
            )
            hhuanhua.setUnitHuanhuaStatus(whichUnit, HUANHUA_POSITION.JUESE, mohuaFile)
            hevent.register(
                whichUnit,
                CONST_EVENT.damagingCustomSource,
                "emobianxingzengshang",
                function(evtData)
                    local damageElementType = evtData.damageElementType
                    if damageElementType ~= nil and type(damageElementType) == "table" then
                        for _, v in ipairs(damageElementType) do
                            if v == CONST_DAMAGE_ELEMENT_TYPE.HUNLUAN then
                                evtData.damage = evtData.damage * 1.1
                                return
                            end
                        end
                    end
                end
            )
        end,
        function()
            hevent.unregister(whichUnit, CONST_EVENT.damagingCustomSource, "emobianxingzengshang")
            hattribute.set(whichUnit, 0, _attr({ attack_speed = "-30" }))
            if hhuanhua.getUnitHuanhuaStatus(whichUnit)[HUANHUA_POSITION.JUESE].file == mohuaFile then
                hhuanhua.setUnitHuanhuaStatus(
                    whichUnit,
                    HUANHUA_POSITION.JUESE,
                    hcache.get(whichUnit, "emobianxingoriginFile") or hslk.i2v(hunit.getId(whichUnit), "file")
                )
            end
        end,
        hslk.n2v("恶魔变形", "Art"),
        hslk.n2v("恶魔变形", "Ubertip"),
        1,
        nil,
        nil,
        function(buffHandle)
            buffHandle.timer.remain(duration, 30)
        end,
        nil,
        HBUFF_UPDATE_MODE.UPDATE
    )
end

SKILLS_CAST["恶魔变形"] = function(evtData)
    local whichUnit = evtData.triggerUnit
    local x, y, z = evtData.targetX, evtData.targetY, evtData.targetZ
    local dis = math.distance(x, y, hunit.x(whichUnit), hunit.y(whichUnit))
    if hcache.get(whichUnit, "crackFlying", false) then
        echo("被击飞中无法使用该技能", hunit.getOwner(whichUnit))
        htime.setTimeout(
            1,
            function(t)
                hskill.setCoolDown(whichUnit, hslk.n2i("恶魔变形"), 0)
            end
        )
        return
    end
    htime.setTimeout(
        0.07,
        function()
            local e = heffect.attach("spell\\DH_E.mdl", whichUnit, "origin", 2)
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
                    damageSkill = hslk.n2i("恶魔变形"),
                    onStart = function()
                        hjapi.DzUnitSilence(whichUnit, true)
                    end,
                    onEnding = function()
                        hjapi.DzUnitSilence(whichUnit, false)
                        heffect.destroy(e)
                        heffect.xyz(
                            "spell\\DH_T.mdl",
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
                        emobianxing(whichUnit, 20)
                        hskill.setCoolDown(evtData.triggerUnit, hslk.n2i("眼棱"), 0)
                        hskill.setCoolDown(evtData.triggerUnit, hslk.n2i("刃舞"), 0)
                        hskillMoban.radiusAOE(
                            hunit.x(whichUnit),
                            hunit.y(whichUnit),
                            whichUnit,
                            300,
                            function(u)
                                hskill.damage(
                                    {
                                        sourceUnit = whichUnit,
                                        targetUnit = u,
                                        damage = (hattribute.getWithLimit(whichUnit, nil, "attack", 0) +
                                                hunit.getZhushuxing(whichUnit)) *
                                            1.5,
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.MOFA,
                                        triggerSkill = hslk.n2i("恶魔变形"),
                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.HUNLUAN },
                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                    }
                                )
                            end,
                            false,
                            true
                        )
                    end, --结束时触发的动作
                    extraInfluence = function(filterUnit)
                        hbuff.xuanyun(filterUnit, 2)
                    end --对选中的敌人的额外影响，会回调该敌人单位，可以对其做出自定义行为
                }
            )
        end
    )
end

local juewangbenneng = function(whichUnit)
    hunit.setCurLifePercent(whichUnit, 30)
    hbuff.update(
        10,
        whichUnit,
        "绝望本能",
        true,
        function()
            hattr.set(whichUnit, 0, _attr({ shanbi = "+50", move = "+150" }))
        end,
        function()
            hattr.set(whichUnit, 0, _attr({ shanbi = "-50", move = "-150" }))
        end,
        hslk.i2v(hslk.n2i("绝望本能"), "Art"),
        "绝望本能|n持续时间内获得50%闪避和移速",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE
    )
    hbuff.update(
        EMOLIESHOU_CD["绝望本能"],
        whichUnit,
        "绝望本能CD",
        false,
        nil,
        nil,
        hslk.i2v(hslk.n2i("绝望本能"), "Art"),
        "绝望本能正在CD中",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.CREATE_ONLY, false
    )
end

SKILL_SETUP["恶魔猎手"] = function(whichUnit)
    hskill.registerAutoCast(whichUnit, hslk.n2i("投掷利刃"))
    hskill.registerAutoCast(whichUnit, hslk.n2i("混乱打击"))
    hskill.registerMonitoringBuff(whichUnit, "势如破竹", true)
    hskill.registerMonitoringBuff(whichUnit, "恶魔变形", true)

    hskill.setup_zhudong_jineng(
        whichUnit,
        hslk.n2i("眼棱"),
        function(evtData)
        end,
        function(whichUnit, targetUnit)
            local shifashijian = 3
            local numberjian = 10
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "盲目之怒")
            numberjian = numberjian + points
            local interval = math.max(0.1, math.ceil(shifashijian / numberjian * 100) / 100)
            return interval * numberjian + 0.01
        end,
        function(whichUnit)
            return true
        end,
        "resource\\war3mapImported\\sound\\spell_dh_eye_beam_loop_01.mp3",
        function(whichUnit, targetUnit)
            local shifashijian = 3
            local numberjian = 10
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "盲目之怒")
            numberjian = numberjian + points
            local interval = math.max(0.1, math.ceil(shifashijian / numberjian * 100) / 100)
            return interval
        end,
        function(whichUnit, targetUnit, x, y, z)
            local damage = hattr.get(whichUnit, "agi", 0) * 1.5
            local tmpAttr = {}
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("致命眼神")) then
                tmpAttr = _attr({ fa_bao = "+100" })
            end
            hskillMoban.changfangxingFacingAOE(
                whichUnit,
                400,
                700,
                function(u)
                    hskill.damage(
                        {
                            sourceUnit = whichUnit,
                            targetUnit = u,
                            damage = damage,
                            damageSrc = CONST_DAMAGE_SRC.skill,
                            damageType = DAMAGE_TYPE.MOFA,
                            triggerSkill = hslk.n2i("眼棱"),
                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.HUNLUAN },
                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                            tmpAttr = tmpAttr
                        }
                    )
                    local emzypoints = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "恶魔之眼")
                    if emzypoints > 0 then
                        hskill.setCoolDown(
                            whichUnit,
                            hslk.n2i("眼棱"),
                            math.max(0, hskill.getCoolDown(whichUnit, hslk.n2i("眼棱")) - emzypoints * 0.1)
                        )
                    end
                end
            )
        end,
        function(whichUnit, targetUnit, x, y, z)
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("魔化")) then
                local duration = 10
                emobianxing(whichUnit, duration)
            end
            hunit.animate(whichUnit, "spell")
            local shifashijian = 3
            hcache.set(
                whichUnit,
                "emolieshou_yanleng_effect",
                heffect.xyz(
                    "spell\\DH_D.mdx",
                    hunit.x(whichUnit),
                    hunit.y(whichUnit),
                    hunit.z(whichUnit),
                    shifashijian,
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    nil,
                    math.angle(hunit.x(whichUnit), hunit.y(whichUnit), x, y)
                )
            )
        end,
        function(whichUnit, targetUnit)
            heffect.destroy(hcache.get(whichUnit, "emolieshou_yanleng_effect"))
        end
    )

    -- 恶魔猎手攻击
    hevent.register(
        whichUnit,
        CONST_EVENT.attack,
        "zhandouzei_attack",
        function(evtData)
            if hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("恶魔之刃")) then
                local emzhirenCD = 3
                if hmingwen.isEquipped("恶魔之刃精通", hunit.getOwner(evtData.triggerUnit)) then
                    emozhiren(evtData.triggerUnit, evtData.targetUnit)
                else
                    if htime.setupAndCheckCoolDown(evtData.triggerUnit, "恶魔之刃", emzhirenCD) then
                        emozhiren(evtData.triggerUnit, evtData.targetUnit)
                    end
                end
            end
        end
    )

    hevent.register(
        whichUnit,
        CONST_EVENT.attackOrder,
        "emozhuiji",
        function(evtData)
            if evtData.triggerUnit ~= whichUnit then
                return
            end
            if evtData.targetUnit == nil then
                return
            end
            if hunit.isAlly(evtData.triggerUnit, evtData.targetUnit) then
                return
            end
            if hbuff.hasBuff(evtData.triggerUnit, "恶魔追击") then
                local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "恶魔追击")
                local distance = 550 + points * 50
                if
                    math.distance(
                        hunit.x(whichUnit),
                        hunit.y(whichUnit),
                        hunit.x(evtData.targetUnit),
                        hunit.y(evtData.targetUnit)
                    ) < distance
                then
                    local cfdamage =
                        (hattribute.getWithLimit(evtData.triggerUnit, nil, "attack", 0) +
                            hunit.getZhushuxing(evtData.triggerUnit)) *
                        points *
                        0.3
                    hbuff.delete(evtData.triggerUnit, "恶魔追击")
                    local e = heffect.attach("spell\\DH_E.mdl", evtData.triggerUnit, "origin", 0.8)
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
                            damageEnd = cfdamage,               --移动结束时对目标的伤害（可选的，默认为0）
                            damageSkill = hslk.n2i("物品技能"),
                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.HUNLUAN },
                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                            oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
                            endDistance = 150,
                            onEnding = function(_, _, timePassed)
                                heffect.destroy(e)
                            end
                        }
                    )

                    local wqslPoints = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "无情狩猎")
                    if wqslPoints > 0 then
                        local bonus = wqslPoints * 0.06
                        hbuff.update(
                            10,
                            evtData.triggerUnit,
                            "无情狩猎",
                            true,
                            nil,
                            nil,
                            hslk.n2v("邪能冲撞", "Art"),
                            "无情狩猎：下一个混乱打击或者刃舞伤害提升" .. (bonus * 100) .. "%",
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
        end
    )

    hevent.register(
        whichUnit,
        CONST_EVENT.damagingCustomSource,
        "emolieshouemoxingtai",
        function(evtData)
            if evtData.sourceUnit ~= whichUnit then
                err("Incorrect unit")
                return
            end
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("恶魔形态")) == false then
                return
            end
            local damageElementType = evtData.damageElementType
            if damageElementType ~= nil and type(damageElementType) == "table" then
                for _, v in ipairs(damageElementType) do
                    if v == CONST_DAMAGE_ELEMENT_TYPE.HUNLUAN then
                        local jingtong = hattribute.getWithLimit(whichUnit, nil, "master", 0)
                        local zengshangxishu = jingtong / EMOLIESHOU_JINGTONG_XISHU + 15
                        local zengshang = 1 + zengshangxishu / 100
                        evtData.damage = evtData.damage * zengshang
                        return
                    end
                    if v == CONST_DAMAGE_ELEMENT_TYPE.FIRE then
                        local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "不择手段")
                        if points > 0 then
                            local jingtong = hattribute.getWithLimit(whichUnit, nil, "master", 0)
                            local zengshangxishu = jingtong / EMOLIESHOU_JINGTONG_XISHU + 15
                            local zengshang = 1 + zengshangxishu * (points * 0.2) / 100
                            evtData.damage = evtData.damage * zengshang
                        end
                        return
                    end
                end
            end
        end
    )

    hevent.register(
        whichUnit,
        CONST_EVENT.dying,
        "emolieshou",
        function(evtData)
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("绝望本能")) == false then
                return
            end
            if htime.setupAndCheckCoolDown(whichUnit, hslk.n2i("绝望本能"), EMOLIESHOU_CD["绝望本能"]) then
                evtData.damage = 0
                juewangbenneng(whichUnit)
            end
        end
    )
end

SKILLS_STOP["邪能冲撞"] = function(evtData)
    if
        (hcache.get(evtData.triggerUnit, "[T1]猎杀者套装(3件)", false) or
            hzhuangbeishouji.isActive(hunit.getOwner(evtData.triggerUnit), "[T1]猎杀者套装")) and
        htime.setupAndCheckCoolDown(evtData.triggerUnit, "T1刷新冲撞CD", 10)
    then
        hskill.setCoolDown(evtData.triggerUnit, hslk.n2i("邪能冲撞"), 0)
    end
end

SKILLS_STOP["刃舞"] = function(evtData)
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "仇恨之轮")
    if points > 0 then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("恶魔变形"),
            math.max(0, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("恶魔变形")) - 0.4 * points)
        )
    end
    if hcache.get(evtData.triggerUnit, "[T2]追猎者套装(3件)", false) then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("刃舞"),
            math.max(0, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("刃舞")) - 2)
        )
    elseif hzhuangbeishouji.isActive(hunit.getOwner(evtData.triggerUnit), "[T2]追猎者套装") then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("刃舞"),
            math.max(0, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("刃舞")) - 1)
        )
    end
end
SKILLS_STOP["混乱打击"] = function(evtData)
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "仇恨之轮")
    if points > 0 then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("恶魔变形"),
            math.max(0, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("恶魔变形")) - 0.4 * points)
        )
    end
end
SKILLS_STOP["投掷利刃"] = function(evtData)
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "仇恨之轮")
    if points > 0 then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("恶魔变形"),
            math.max(0, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("恶魔变形")) - 0.4 * points)
        )
    end
end
