local chirelianji_skill = {}
chirelianji_skill[hslk.n2i("火球术")] = 1
chirelianji_skill[hslk.n2i("炎爆术")] = 1
chirelianji_skill[hslk.n2i("火凤凰")] = 1
chirelianji_skill[hslk.n2i("火焰冲击")] = 1
chirelianji_skill[hslk.n2i("龙息术")] = 1
local fashijineng_cd = {}
fashijineng_cd["火凤凰"] = 10
fashijineng_cd["活体炸弹"] = 20
fashijineng_cd["烈焰护盾"] = 120

local lieyanfengbao

local FASHI_JINGTONG_XISHU = 20

local function lieyanzhisu(whichUnit)
    local huduneffect = heffect.attach("war3mapImported\\AZ_MagicShield_Gold.mdl", whichUnit, "origin", -1)
    hbuff.update(
        15,
        whichUnit,
        "烈焰护盾",
        true,
        nil,
        function()
            heffect.destroy(huduneffect)
        end,
        hslk.i2v(hslk.n2i("烈焰护盾"), "Art"),
        hslk.i2v(hslk.n2i("烈焰护盾"), "Ubertip"),
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.CREATE_ONLY,
        true,
        hunit.getMaxLife(whichUnit) * 0.3
    )
    hbuff.update(
        fashijineng_cd["烈焰护盾"],
        whichUnit,
        "烈焰护盾CD",
        false,
        nil,
        nil,
        hslk.i2v(hslk.n2i("烈焰护盾"), "Art"),
        "无法触发烈焰护盾",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.CREATE_ONLY,
        false,
        0
    )
end

-- 炽热连击
local function chirelianji(triggerUnit, isCritical)
    if isCritical == true then
        if hbuff.hasBuff(triggerUnit, "炽热连击", 1) or hbuff.hasBuff(triggerUnit, "炽热连击", 2) then
            local e = heffect.attach("[jineng]chirelianji.mdx", triggerUnit, "chest", 10)
            hbuff.update(
                10,
                triggerUnit,
                "炽热连击",
                true,
                nil,
                function()
                    heffect.destroy(e)
                end,
                hslk.n2v("炽热连击", "Art"),
                "下次攻击触发炎爆",
                2,
                nil,
                nil,
                nil,
                nil,
                HBUFF_UPDATE_MODE.OVERWRITE
            )
        else
            hbuff.update(
                10,
                triggerUnit,
                "炽热连击",
                true,
                nil,
                nil,
                hslk.n2v("炽热连击", "Art"),
                "连续两次指定法术暴击会使下一次普攻触发炎爆",
                1,
                nil,
                nil,
                nil,
                nil,
                HBUFF_UPDATE_MODE.OVERWRITE
            )
        end
    else
        if hbuff.hasBuff(triggerUnit, "炽热连击", 1) then
            hbuff.delete(triggerUnit, "炽热连击")
        end
    end
end

-- 点燃
local function dianran(triggerUnit, targetUnit, damage, triggerSkill, finalDamage)
    if targetUnit == nil or triggerUnit == nil then
        return
    end
    local dianranTotalDamage = damage * (0.15 + 0.01 * hattribute.get(triggerUnit, "master", 0) / FASHI_JINGTONG_XISHU)
    if hbuff.hasBuff(triggerUnit, "燃烧") then
        local points = htianfu.getActiveTianfuLevel(hunit.getOwner(triggerUnit), "强化燃烧")
        if points > 0 then
            dianranTotalDamage = dianranTotalDamage * (1 + 0.05 * points)
        end
    end
    local lieyandashi_points = htianfu.getActiveTianfuLevel(hunit.getOwner(triggerUnit), "烈焰大师")
    if lieyandashi_points > 0 then
        dianranTotalDamage = dianranTotalDamage * (1 + lieyandashi_points * 0.02)
    end
    if hbuff.hasBuff(triggerUnit, "触燃感触") and hbuff.getBuffHandle(triggerUnit, "触燃感触").stack then
        dianranTotalDamage = dianranTotalDamage * (1 + 0.02 * hbuff.getBuffHandle(triggerUnit, "触燃感触").stack)
    end
    if finalDamage ~= nil then
        dianranTotalDamage = finalDamage
    end
    hbuff.update(
        6,
        targetUnit,
        hslk.n2i("点燃") .. "|" .. tostring(triggerUnit),
        false,
        nil,
        nil,
        "ReplaceableTextures\\BTN_FS_01.blp",
        "点燃造成每秒" .. tostring(math.floor(dianranTotalDamage / 6.0) .. "点伤害"),
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
                    damageType = DAMAGE_TYPE.SHENSHENG,
                    triggerSkill = triggerSkill,
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT
                }
            )
            heffect.attach("Abilities\\Spells\\Other\\Incinerate\\IncinerateBuff.mdl", targetUnit, "head", 0.1)
            buffHandle.remainingTime = buffHandle.remainingTime - 1
            buffHandle.extraBuffData.damage = buffHandle.extraBuffData.damage - cur_damage
        end,
        function(buffHandle)
            if buffHandle == nil or buffHandle.extraBuffData == nil or buffHandle.extraBuffData.damage == nil then
                return
            end
            buffHandle.remainingTime = 6
            buffHandle.extraBuffData.damage = buffHandle.extraBuffData.damage + dianranTotalDamage
            buffHandle.description = "点燃造成每秒" .. tostring(math.floor(buffHandle.extraBuffData.damage / 6.0) .. "点伤害")
        end,
        {
            damage = dianranTotalDamage
        },
        HBUFF_UPDATE_MODE.UPDATE
    )
end

local lieyanbaozhu = function(triggerUnit, x, y)
    local angle = math.angle(hunit.x(triggerUnit), hunit.y(triggerUnit), x, y)
    local endX, endY = math.polarProjection(hunit.x(triggerUnit), hunit.y(triggerUnit), 1200, angle)
    local damageTarget = {}
    local damageInterval = 50
    local damageMulti = 0.8
    if hcache.get(triggerUnit, "[T3]高阶法师套装(3件)", false) then
        damageMulti = damageMulti * 1.1
    elseif hzhuangbeishouji.isActive(hunit.getOwner(triggerUnit), "[T3]高阶法师套装") then
        damageMulti = damageMulti * 1.05
    end
    if hcache.get(triggerUnit, "[T3]高阶法师套装(4件)", false) then
        damageInterval = math.floor(damageInterval / 1.3)
    elseif hzhuangbeishouji.isActive(hunit.getOwner(triggerUnit), "[T3]高阶法师套装") then
        damageInterval = math.floor(damageInterval / 1.15)
    end
    local ttl = 4
    local speed = 6
    if hmingwen.isEquipped("烈焰磨盘", hunit.getOwner(triggerUnit)) then
        speed = 10
    end
    hskillMoban.leap(
        {
            --otherAttach = { { "spell\\DH_E_small.mdl", "chest" } },
            arrowAttachModel = "war3mapImported\\OrbPoisonX.mdx",
            --arrowUnit = sourceUnit, -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
            sourceUnit = triggerUnit,      --伤害来源（必须有！不管有没有伤害）
            --targetUnit = evtData.targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
            tokenX = hunit.x(triggerUnit), --冲击开始x坐标（可选的，对点冲击，与某目标无关）
            tokenY = hunit.y(triggerUnit), --冲击开始y坐标（可选的，对点冲击，与某目标无关）
            unbindWhenEnd = true,
            x = endX,                      --冲击的x坐标（可选的，对点冲击，与某目标无关）
            y = endY,                      --冲击的y坐标（可选的，对点冲击，与某目标无关）
            speed = speed,                 --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
            acceleration = 0,
            shake = 0,                     --摇摆振幅角度[-90~+90|random]（可选的，默认0)
            ttl = ttl,
            filter = function(enum)
                return hunit.isEnemy(triggerUnit, enum) and hunit.isAlive(enum) and hunit.isInvincible(enum) == false
            end,                     --必须有
            tokenArrowScale = 2,     --前冲的特效作为马甲冲击时的模型缩放
            tokenArrowOpacity = 0.6, --前冲的特效作为马甲冲击时的模型透明度[0-1]
            tokenArrowHeight = 0.00, --前冲的特效作为马甲冲击时的初始离地高度
            effectMovement = nil,    --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
            --animateMovement = "attack",
            --animation = "attack",
            effectEnd = nil,                                        --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
            damageMovement = 0,                                     --移动过程中的伤害（可选的，默认为0）
            damageMovementRadius = 400,                             --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
            damageMovementRepeat = true,                            --移动过程中伤害是否可以重复造成（可选的，默认为不能）
            damageMovementDrag = false,                             --移动过程是否拖拽敌人（可选的，默认为不能）
            damageEndRadius = 0,                                    --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
            damageSrc = CONST_DAMAGE_SRC.skill,                     --伤害的种类（可选）
            --damageEffect = "war3mapImported\\AZ_gelie.mdx", --伤害特效（可选）
            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE }, --伤害的元素类型（可选）
            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
            damageType = DAMAGE_TYPE.MOFA,
            damageSkill = hslk.n2i("烈焰宝珠"),
            oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
            endDistance = 0,
            skipPathCheck = false,
            speedModifierWhenExtrImpact = function(whichUnit, speed)
                if hmingwen.isEquipped("烈焰磨盘", hunit.getOwner(triggerUnit)) then
                    return 3
                else
                    return speed
                end
            end,
            extraInfluence = function(whichUnit, currentX, currentY, currentZ, speed)
                if damageTarget[whichUnit] == nil or htime.inc - damageTarget[whichUnit] > damageInterval then
                    damageTarget[whichUnit] = htime.inc
                    hskillMoban.missile(
                        {
                            model = "Abilities\\Weapons\\FireBallMissile\\FireBallMissile.mdl",
                            scale = 0.7,
                            speed = 1200,
                            hover = 100,
                            sourceUnit = triggerUnit,
                            targetUnit = whichUnit,
                            startX = currentX,
                            startY = currentY,
                            onEnd = function()
                                local finalDamage = hunit.getZhushuxing(triggerUnit) * damageMulti
                                hskill.damage(
                                    {
                                        sourceUnit = triggerUnit,
                                        targetUnit = whichUnit,
                                        damage = finalDamage,
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.MOFA,
                                        triggerSkill = hslk.n2i("烈焰宝珠"),
                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE }
                                    }
                                )
                            end
                        }
                    )
                end
            end, --对选中的敌人的额外影响，会回调该敌人单位，可以对其做出自定义行为
            onEnding = function(_, _, timePassed)
            end
        }
    )
end

local function huotizhadan(triggerUnit, targetUnit, willSpread)
    hbuff.update(
        4,
        targetUnit,
        "活体炸弹" .. tostring(triggerUnit) .. tostring(willSpread),
        false,
        function()
            heffect.attach("Abilities\\Spells\\Other\\Incinerate\\IncinerateBuff.mdl", targetUnit, "head", 4)
        end,
        function()
            local group =
                hgroup.createByUnit(
                    targetUnit,
                    200,
                    function(filterUnit)
                        if
                            hunit.isAlly(triggerUnit, filterUnit) or hunit.isDead(filterUnit) or
                            hunit.isDestroyed(filterUnit) or
                            filterUnit == targetUnit
                        then
                            return false
                        else
                            return true
                        end
                    end
                )
            heffect.xyz(
                "Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode.mdl",
                hunit.x(targetUnit),
                hunit.y(targetUnit),
                hunit.z(targetUnit),
                0,
                1
            )
            for _, target in ipairs(group) do
                hskill.damage(
                    {
                        sourceUnit = triggerUnit,
                        targetUnit = target,
                        damage = hattribute.getWithLimit(triggerUnit, nil, "int", 0) * 1.5,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = hslk.n2i("活体炸弹"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                    }
                )
                if willSpread then
                    huotizhadan(triggerUnit, target, false)
                end
            end
        end,
        hslk.n2v("活体炸弹", "Art"),
        hslk.n2v("活体炸弹", "Ubertip"),
        1,
        1,
        function(_, buffHandle)
            buffHandle.remainingTime = buffHandle.remainingTime - 1
            hskill.damage(
                {
                    sourceUnit = triggerUnit,
                    targetUnit = targetUnit,
                    damage = hattribute.getWithLimit(triggerUnit, nil, "int", 0) * 0.2,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.MOFA,
                    triggerSkill = hslk.n2i("活体炸弹"),
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT
                }
            )
        end,
        nil,
        nil,
        HBUFF_UPDATE_MODE.CREATE_ONLY,
        true
    )
end

local function huoqiushu(triggerUnit, targetUnit, triggerSkill, canTriggerLianzhuhuoqiu)
    if canTriggerLianzhuhuoqiu == true and hmingwen.isEquipped("连珠火球", hunit.getOwner(triggerUnit)) then
        if math.random(1, 100) <= 20 then
            htime.setTimeout(
                0.2,
                function(curTimer)
                    huoqiushu(triggerUnit, targetUnit, triggerSkill, false)
                end
            )
        end
    end
    local damageMulti = 1.3
    if hshangcheng.hasItem(hunit.getOwner(triggerUnit), "见习火法") then
        damageMulti = damageMulti * 1.05
    end
    if hcache.get(triggerUnit, "[T2]炎灵套装(4件)", false) then
        damageMulti = damageMulti * 1.3
    elseif hzhuangbeishouji.isActive(hunit.getOwner(triggerUnit), "[T2]炎灵套装") then
        damageMulti = damageMulti * 1.1
    end
    if hmingwen.isEquipped("节能火球", hunit.getOwner(triggerUnit)) then
        hunit.subCurMana(triggerUnit, 1)
    else
        hunit.subCurMana(triggerUnit, 2)
    end
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\fire_cast.wav", 1000, true),
        90,
        triggerUnit
    )
    hskillMoban.missile(
        {
            model = "Abilities\\Weapons\\FireBallMissile\\FireBallMissile.mdl",
            scale = 1,
            speed = 1200,
            hover = 100,
            sourceUnit = triggerUnit,
            targetUnit = targetUnit,
            target_face_dis = 100,
            onEnd = function()
                local finalDamage = hattr.get(triggerUnit, "int", 0) * damageMulti
                local tmpAttr = _attr {}
                if hmingwen.isEquipped("灼烧", hunit.getOwner(triggerUnit)) and hunit.getCurLifePercent(targetUnit) <= 35 then
                    finalDamage = finalDamage * 0.5
                    tmpAttr = _attr { fa_bao = "+100" }
                end
                hskill.damage(
                    {
                        sourceUnit = triggerUnit,
                        targetUnit = targetUnit,
                        damage = finalDamage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = triggerSkill,
                        isAttackReplacement = true,
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                        tmpAttr = tmpAttr
                    }
                )
                if
                    hunit.isAlive(targetUnit) and hskill.hasActiveAbility(triggerUnit, hslk.n2i("活体炸弹")) and
                    hskill.checkAndEnterCD(triggerUnit, hslk.n2i("活体炸弹"), fashijineng_cd["活体炸弹"])
                then
                    huotizhadan(triggerUnit, targetUnit, true)
                end

                local lieyanfengbaocd = 12
                local points = htianfu.getActiveTianfuLevel(hunit.getOwner(triggerUnit), "余震")
                if points > 0 then
                    lieyanfengbaocd = lieyanfengbaocd - points
                end
                if hmingwen.isEquipped("极速烈焰风暴", hunit.getOwner(triggerUnit)) then
                    lieyanfengbaocd = lieyanfengbaocd - 1
                end
                if
                    hskill.hasActiveAbility(triggerUnit, hslk.n2i("烈焰风暴")) and
                    htime.setupAndCheckCoolDown(triggerUnit, "烈焰风暴", lieyanfengbaocd)
                then
                    lieyanfengbao(
                        triggerUnit,
                        hslk.n2i("烈焰风暴"),
                        hunit.x(targetUnit),
                        hunit.y(targetUnit),
                        hunit.z(targetUnit)
                    )
                end
            end
        }
    )
end

local function huofenghuang(triggerUnit, targetUnit, triggerSkill)
    local damage = hattr.get(triggerUnit, "int", 0) * 1.8

    if hcache.get(triggerUnit, "[T2]炎灵套装(3件)", false) then
        damage = damage * 1.3
    elseif hzhuangbeishouji.isActive(hunit.getOwner(triggerUnit), "[T2]炎灵套装") then
        damage = damage * 1.1
    end

    local mana = 10
    hunit.subCurMana(triggerUnit, mana)
    hskillMoban.missile(
        {
            model = "Units\\Human\\Phoenix\\Phoenix.mdx",
            scale = 0.8,
            speed = 1500,
            hover = 100,
            sourceUnit = triggerUnit,
            targetUnit = targetUnit,
            target_face_dis = 100,
            onEnd = function()
                local group =
                    hgroup.createByUnit(
                        targetUnit,
                        200,
                        function(filterUnit)
                            if
                                hunit.isAlly(triggerUnit, filterUnit) or hunit.isDead(filterUnit) or
                                hunit.isDead(triggerUnit) or
                                hunit.isDestroyed(filterUnit) or
                                hunit.isDestroyed(triggerUnit)
                            then
                                return false
                            else
                                return true
                            end
                        end
                    )
                for _, target in ipairs(group) do
                    hskill.damage(
                        {
                            sourceUnit = triggerUnit,
                            targetUnit = target,
                            damage = damage,
                            damageSrc = CONST_DAMAGE_SRC.skill,
                            damageType = DAMAGE_TYPE.MOFA,
                            triggerSkill = triggerSkill,
                            tmpAttr = _attr {
                                fa_bao = 100
                            },
                            isAttackReplacement = true,
                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                        }
                    )
                end
            end
        }
    )
end

lieyanfengbao = function(triggerUnit, triggerSkill, x, y, z)
    local group =
        hgroup.createByXY(
            x,
            y,
            300,
            function(filterUnit)
                if
                    hunit.isAlly(triggerUnit, filterUnit) or hunit.isDead(filterUnit) or hunit.isDead(triggerUnit) or
                    hunit.isDestroyed(filterUnit) or
                    hunit.isDestroyed(triggerUnit)
                then
                    return false
                else
                    return true
                end
            end
        )
    heffect.xyz("AZ_F034.mdx", x, y, z, 0, 1)
    for _, target in ipairs(group) do
        hskill.damage(
            {
                sourceUnit = triggerUnit,
                targetUnit = target,
                damage = hattribute.getWithLimit(triggerUnit, nil, "int", 0) * 2.5,
                damageSrc = CONST_DAMAGE_SRC.skill,
                damageType = DAMAGE_TYPE.MOFA,
                triggerSkill = triggerSkill,
                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
            }
        )
        heffect.attach("war3mapImported\\AZ_hit1.mdx", target, "origin", 0)
        local points = htianfu.getActiveTianfuLevel(hunit.getOwner(triggerUnit), "烈焰喷发")
        if points > 0 then
            if math.random(1, 100) <= (points * 5) then
                huotizhadan(triggerUnit, target, false)
            end
        end
    end
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(triggerUnit), "烈焰之地")
    if points > 0 then
        heffect.xyz("war3mapImported\\[Spell]_115_2.MDX", x, y, z, 8, 1)
        local damageCount = 0
        htime.setInterval(
            1,
            function(curTimer)
                if damageCount >= 6 then
                    curTimer.destroy()
                    return
                end
                damageCount = damageCount + 1
                hskillMoban.radiusAOE(
                    x,
                    y,
                    triggerUnit,
                    300,
                    function(target)
                        hskill.damage(
                            {
                                sourceUnit = triggerUnit,
                                targetUnit = target,
                                damage = hattribute.getWithLimit(triggerUnit, nil, "int", 0) * 0.2 * points,
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.MOFA,
                                triggerSkill = hslk.n2i("烈焰风暴"),
                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                shanghainame = "烈焰之地"
                            }
                        )
                    end,
                    false,
                    true
                )
            end
        )
    end
end

local function yanbaoshu(triggerUnit, targetUnit, triggerSkill, damage_scale, effect_scale, effect_art, shanghainame)
    local mana = 7
    if
        hcache.get(triggerUnit, "[T1]灵力波动套装(3件)", false) or
        hzhuangbeishouji.isActive(hunit.getOwner(triggerUnit), "[T1]灵力波动套装")
    then
        mana = mana - 1
    end
    hunit.subCurMana(triggerUnit, mana)
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\fire_cast.wav", 1000, true),
        100,
        triggerUnit
    )
    hskillMoban.missile(
        {
            --model = "war3mapImported\\[SPELL]_115.mdl",
            model = effect_art or "war3mapImported\\AZ_Misslie15.MDX",
            scale = effect_scale,
            speed = 1000,
            hover = 50,
            sourceUnit = triggerUnit,
            targetUnit = targetUnit,
            target_face_dis = 100,
            onEnd = function(_, _, endX, endY)
                hskill.damage(
                    {
                        sourceUnit = triggerUnit,
                        targetUnit = targetUnit,
                        damage = damage_scale * 5.5 * hattr.get(triggerUnit, "int", 0),
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = triggerSkill,
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                        isAttackReplacement = true,
                        shanghainame = shanghainame
                    }
                )
                hsound.voice2Unit(
                    hsound.voiceCreate("resource\\war3mapImported\\sound\\yanbaoshu.wav", 1000, true),
                    100,
                    targetUnit
                )
            end
        }
    )

    if hskill.hasActiveAbility(triggerUnit, hslk.n2i("烈焰宝珠")) and math.random(1, 100) <= 25 and htime.setupAndCheckCoolDown(
            triggerUnit,
            "烈焰宝珠",
            10
        ) then
        lieyanbaozhu(triggerUnit, hunit.x(targetUnit), hunit.y(targetUnit))
    end
end

local function lianzhuhuoqiu(triggerUnit, targetUnit, triggerSkill)
    hunit.subCurMana(triggerUnit, 15)
    local number_huoqiu = 7
    htime.setInterval(
        0.1,
        function(curTimer)
            if number_huoqiu == 0 then
                curTimer.destroy()
                return
            end
            number_huoqiu = number_huoqiu - 1
            hskillMoban.missile(
                {
                    model = "war3mapImported\\[SPELL]_111.mdl",
                    scale = 0.5,
                    speed = 1200,
                    hover = math.random(50, 200),
                    sourceUnit = triggerUnit,
                    targetUnit = targetUnit,
                    target_face_dis = 100,
                    target_face_left = math.random(-70, 70),
                    onEnd = function()
                        hskill.damage(
                            {
                                sourceUnit = triggerUnit,
                                targetUnit = targetUnit,
                                damage = hattr.get(triggerUnit, "int", 0),
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.MOFA,
                                triggerSkill = triggerSkill,
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                            }
                        )
                    end
                }
            )
        end
    )
end

local ranshao = function(whichUnit, duration)
    if hbuff.hasBuffThatLastLongerthan(whichUnit, "燃烧", duration) then
        return
    end
    local duration = duration
    local add_fa_baoshang = 0
    local effect = nil
    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\ranshao.wav", 3000, true), 100, whichUnit)
    hbuff.update(
        duration,
        whichUnit,
        "燃烧",
        true,
        function()
            add_fa_baoshang = hattribute.getWithLimit(whichUnit, nil, "fa_bao", 0)
            hattribute.set(whichUnit, 0, _attr({ fa_bao = "+100", fa_baoshang = "+" .. tostring(add_fa_baoshang) }))
            effect = heffect.attach("Abilities\\Spells\\Other\\Doom\\DoomTarget.mdl", whichUnit, "origin", duration)
        end,
        function()
            if add_fa_baoshang == 0 then
                err("燃烧结束时没有找到增加的暴伤")
                return
            end
            hattribute.set(whichUnit, 0, _attr({ fa_bao = "-100", fa_baoshang = "-" .. tostring(add_fa_baoshang) }))
            heffect.destroy(effect)
        end,
        hslk.n2v("燃烧", "Art"),
        hslk.n2v("燃烧", "Ubertip"),
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE
    )
end

-- 记录目标
local zhudongyanbaoshu = function(evtData)
    local damage_scale = 1
    local effectFile = nil
    if
        hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("太阳之王的祝福")) and
        hbuff.hasBuff(evtData.triggerUnit, "太阳之王的祝福")
    then
        damage_scale = 3.4
        hbuff.delete(evtData.triggerUnit, "太阳之王的祝福")
        effectFile = "war3mapImported\\[SPELL]_115.mdl"
        if hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("烈焰宝珠")) then
            lieyanbaozhu(evtData.triggerUnit, hunit.x(evtData.targetUnit), hunit.y(evtData.targetUnit))
        end
        local taiyangnufenpoints = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "太阳之王的愤怒")
        if taiyangnufenpoints > 0 then
            damage_scale = damage_scale * (1 + taiyangnufenpoints * 0.07)
        end
        if hmingwen.isEquipped("太阳之王的光芒", hunit.getOwner(evtData.triggerUnit)) then
            damage_scale = damage_scale *
                (1 + hattribute.getWithLimit(evtData.triggerUnit, nil, "master", 0) / 1500)
        end
    end
    yanbaoshu(evtData.triggerUnit, evtData.targetUnit, evtData.triggerSkill, damage_scale, 1, effectFile, "太阳之王的炎爆")
    heffect.xyz(
        "war3mapImported\\[Spell]_116.mdx",
        hunit.x(evtData.triggerUnit),
        hunit.y(evtData.triggerUnit),
        hunit.z(evtData.triggerUnit),
        0,
        1,
        nil,
        nil,
        nil,
        nil,
        nil,
        math.angle(
            hunit.x(evtData.triggerUnit),
            hunit.y(evtData.triggerUnit),
            hunit.x(evtData.targetUnit),
            hunit.y(evtData.targetUnit)
        )
    )
    cj.IssueTargetOrder(evtData.triggerUnit, "attack", evtData.targetUnit)
end

local huoyanchongji = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local targetUnit = evtData.targetUnit
    hskill.damage(
        {
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            damage = hattr.get(sourceUnit, "int", 0) * 1.5,
            damageSrc = CONST_DAMAGE_SRC.skill,
            damageType = DAMAGE_TYPE.MOFA,
            triggerSkill = hslk.n2i("火焰冲击"),
            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
            tmpAttr = { fa_bao = "+100" }
        }
    )
    heffect.attach("war3mapImported\\[spell]_120.mdx", targetUnit, "origin", 0)
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "触燃感触")
    if points > 0 then
        hbuff.addStackAttrBuff(
            CONST_DAMAGE_SRC.skill,
            sourceUnit,
            "触燃感触",
            _attr({}),
            12,
            points,
            hslk.n2v("火焰冲击", "Art"),
            "每层触燃感触使点燃伤害提高2%",
            true
        )
    end
    cj.IssueTargetOrder(sourceUnit, "attack", targetUnit)

    local lieyandashi_points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "烈焰大师")
    if lieyandashi_points > 0 and hbuff.hasBuff(sourceUnit, "燃烧") then
        local chance = lieyandashi_points * 20
        if math.random(1, 100) <= chance then
            local tagetDianranBuffHandle = hbuff.getBuffHandle(targetUnit, hslk.n2i("点燃") .. "|" .. tostring(sourceUnit))
            if tagetDianranBuffHandle ~= nil and tagetDianranBuffHandle.extraBuffData ~= nil and tagetDianranBuffHandle.extraBuffData.damage ~= nil then
                hskillMoban.radiusAOE(
                    hunit.x(targetUnit),
                    hunit.y(targetUnit),
                    sourceUnit,
                    300,
                    function(enum)
                        if enum ~= targetUnit then
                            dianran(sourceUnit, enum, 0, evtData.triggerSkill,
                                tagetDianranBuffHandle.extraBuffData.damage)
                        end
                    end,
                    false,
                    true
                )
            end
        end
    end
end

local longxishu = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local x = evtData.targetX
    local y = evtData.targetY
    local damage = hattribute.getWithLimit(sourceUnit, nil, "int", 0) * 2.5
    local facing = math.angle(hunit.x(sourceUnit), hunit.y(sourceUnit), x, y)
    local group =
        hgroup.createByAngleAndRadius(
            sourceUnit,
            900,
            facing,
            90,
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
    heffect.xyz(
        "war3mapImported\\AZ_HYHX.mdl",
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
        facing
    )
    for _, target in ipairs(group) do
        local distance = math.distance(hunit.x(sourceUnit), hunit.y(sourceUnit), hunit.x(target), hunit.y(target))
        htime.setTimeout(
            distance / 1600,
            function(curTimer)
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = target,
                        damage = damage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = hslk.n2i("龙息术"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                    }
                )
                hbuff.xuanyun(target, 1)
            end
        )
    end
end

local shanxian = function(evtData)
    local angel =
        math.angle(hunit.x(evtData.triggerUnit), hunit.y(evtData.triggerUnit), evtData.targetX, evtData.targetY)
    local originalDistance =
        math.distance(hunit.x(evtData.triggerUnit), hunit.y(evtData.triggerUnit), evtData.targetX, evtData.targetY)
    local finalx, finaly
    for i = 1, 35, 1 do
        local x, y = math.polarProjection(hunit.x(evtData.triggerUnit), hunit.y(evtData.triggerUnit), i * 20, angel)
        if cj.IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) then
            break
        elseif i * 20 >= originalDistance then
            finalx, finaly = evtData.targetX, evtData.targetY
            break
        else
            finalx, finaly = x, y
        end
    end
    if finalx == nil or finaly == nil then
        return
    end

    htime.setTimeout(
        0.02,
        function(curTimer)
            heffect.attach("Abilities\\Spells\\NightElf\\Blink\\BlinkTarget.mdl", evtData.triggerUnit, "origin", 0)
            local whichUnit = evtData.triggerUnit
            local x = finalx
            local y = finaly
            hunit.portal(whichUnit, x, y)
            hsound.voice2Unit(
                hsound.voiceCreate("resource\\war3mapImported\\sound\\shanxian.wav", 1000, true),
                100,
                whichUnit
            )
        end
    )
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "火疗闪烁")
    if points > 0 then
        hbuff.update(
            5,
            evtData.triggerUnit,
            "火疗闪烁",
            true,
            nil,
            nil,
            hslk.n2v("闪现", "Art"),
            "在5秒内每秒恢复" .. tostring(points * 0.5) .. "%大生命值",
            1,
            1,
            function(_, buffHandle)
                hskill.heal(
                    {
                        healer = evtData.triggerUnit,
                        healee = evtData.triggerUnit,
                        heal = hunit.getMaxLife(evtData.triggerUnit) * points * 0.005,
                        healType = HEAL_TYPE.SKILL,
                        triggerSkill = hslk.n2i("装备技能")
                    }
                )
                buffHandle.remainingTime = buffHandle.remainingTime - 1
            end,
            nil,
            nil,
            HBUFF_UPDATE_MODE.OVERWRITE,
            true
        )
    end
end

local yunshishu = function(evtData)
    local whichUnit = evtData.triggerUnit
    local x = evtData.targetX
    local y = evtData.targetY
    local z = evtData.targetZ
    heffect.xyz("war3mapImported\\AZ_Kaer_D1.MDX", x, y, z, 1.25, 1)
    local radius = 300
    local duration = 6
    local scale = 1

    if hmingwen.isEquipped("陨石余烬", hunit.getOwner(whichUnit)) then
        radius = radius + 100
        duration = duration + 6
        scale = scale * 1.33
    end
    htime.setTimeout(
        1.25,
        function(curTimer)
            hskillMoban.radiusAOE(
                x,
                y,
                whichUnit,
                radius,
                function(target)
                    hskill.damage(
                        {
                            sourceUnit = whichUnit,
                            targetUnit = target,
                            damage = hattribute.getWithLimit(whichUnit, nil, "int", 0) * 8,
                            damageSrc = CONST_DAMAGE_SRC.skill,
                            damageType = DAMAGE_TYPE.MOFA,
                            triggerSkill = hslk.n2i("陨石术"),
                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                        }
                    )
                    hbuff.xuanyun(target, 2)
                end,
                false,
                true
            )
            heffect.xyz("war3mapImported\\[Spell]_115_2.MDX", x, y, z, duration, 1, scale, scale, 1)
            local damageCount = 0
            htime.setInterval(
                1,
                function(curTimer)
                    if damageCount >= duration then
                        curTimer.destroy()
                        return
                    end
                    damageCount = damageCount + 1
                    hskillMoban.radiusAOE(
                        x,
                        y,
                        whichUnit,
                        radius,
                        function(target)
                            hskill.damage(
                                {
                                    sourceUnit = whichUnit,
                                    targetUnit = target,
                                    damage = hattribute.getWithLimit(whichUnit, nil, "int", 0) * 1,
                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                    damageType = DAMAGE_TYPE.MOFA,
                                    triggerSkill = hslk.n2i("陨石术"),
                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT
                                }
                            )
                        end,
                        false,
                        true
                    )
                end
            )
        end
    )
end

SKILLS["燃烧"] = function(evtData)
    ranshao(evtData.triggerUnit, 10)
end

SKILLS["火焰冲击"] = function(evtData)
    huoyanchongji(evtData)
end

SKILLS["龙息术"] = function(evtData)
    longxishu(evtData)
end

SKILLS["闪现"] = function(evtData)
    if hcache.get(evtData.triggerUnit, "crackFlying", false) then
        echo("被击飞中闪现失败", hunit.getOwner(evtData.triggerUnit))
        return
    end
    shanxian(evtData)
end

SKILLS_STOP["火焰冲击"] = function(evtData)
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "烈焰飞舞")
    if points > 0 then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("火焰冲击"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("火焰冲击")) - points * 0.7)
        )
    end
end

SKILL_ON_LEVEL_UP["火法"] = function(whichUnit)
    local lieyanzhixinid = hslk.n2i("烈焰之心")
    if hskill.hasActiveAbility(whichUnit, lieyanzhixinid) then
        hskill.addProperty(whichUnit, lieyanzhixinid, 1)
    end
end

SKILL_SETUP["火法"] = function(whichUnit)
    --基础回蓝1
    hattribute.set(whichUnit, 0, { mana_back = "=1" })
    hskill.registerAutoCast(whichUnit, hslk.n2i("火焰冲击"))
    hskill.registerAutoCast(whichUnit, hslk.n2i("炎爆术"))
    hskill.registerMonitoringBuff(whichUnit, "炽热连击", true)
    hskill.registerMonitoringBuff(whichUnit, "燃烧", true)
    hskill.registerMonitoringBuff(whichUnit, "太阳之王的祝福", true)
    hskill.setup_zhudong_jineng(
        whichUnit,
        hslk.n2i("炎爆术"),
        zhudongyanbaoshu,
        3,
        nil,
        "resource\\war3mapImported\\sound\\fire_casting.wav",
        nil,
        nil,
        function()
            hcache.set(
                whichUnit,
                "yanbaoshulefthandtexiao",
                heffect.attach("war3mapImported\\[Spell]_117.mdx", whichUnit, "hand left", 3)
            )
        end,
        function()
            heffect.destroy(hcache.get(whichUnit, "yanbaoshulefthandtexiao"))
        end,
        nil,
        nil,
        nil,
        true
    )
    hskill.setup_zhudong_jineng(
        whichUnit,
        hslk.n2i("陨石术"),
        yunshishu,
        2,
        nil,
        "resource\\war3mapImported\\sound\\fire_casting.wav",
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        true
    )

    --炽热极速
    hevent.register(
        whichUnit,
        CONST_EVENT.dying,
        "huofa",
        function(evtData)
            if hunit.getName(evtData.targetUnit) ~= "火法" then
                return
            end
            if hskill.hasActiveAbility(evtData.targetUnit, hslk.n2i("烈焰护盾")) == false then
                return
            end
            if htime.setupAndCheckCoolDown(evtData.targetUnit, hslk.n2i("烈焰护盾"), fashijineng_cd["烈焰护盾"]) then
                evtData.damage = 0
                lieyanzhisu(evtData.targetUnit)
            end
        end
    )

    hevent.register(
        whichUnit,
        CONST_EVENT.beforeAttackDamage,
        "fashi_auto_cast",
        function(evtData)
            evtData.damage = 0
            local sourceUnit = evtData.sourceUnit
            local targetUnit = evtData.targetUnit
            if
                hskill.hasActiveAbility(sourceUnit, hslk.n2i("炽热连击")) and
                hskill.hasActiveAbility(sourceUnit, hslk.n2i("炎爆术")) and
                hbuff.hasBuff(sourceUnit, "炽热连击", 2) and
                hunit.getCurMana(sourceUnit) >= 10
            then
                local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "高温")
                if points > 0 then
                    if math.random(1, 100) <= (points * 2) and htime.setupAndCheckCoolDown(whichUnit, "高温", 10) then
                        ranshao(whichUnit, 5)
                    end
                end

                local damage_scale = 1
                if hskill.hasActiveAbility(sourceUnit, hslk.n2i("太阳之王的祝福")) and math.random(1, 100) <= 15 then
                    hbuff.update(
                        30,
                        sourceUnit,
                        "太阳之王的祝福",
                        true,
                        function()
                            hcache.set(
                                sourceUnit,
                                "taiyangzhiwangtexiao",
                                heffect.attach("AZ_ranjzhixin.mdx", sourceUnit, "over head", -1)
                            )
                        end,
                        function()
                            heffect.destroy(hcache.get(sourceUnit, "taiyangzhiwangtexiao"))
                        end,
                        hslk.n2v("太阳之王的祝福", "Art"),
                        "下个手动释放的炎爆术伤害增加240%！",
                        1,
                        nil,
                        nil,
                        nil,
                        nil,
                        HBUFF_UPDATE_MODE.OVERWRITE
                    )
                    hskill.setCoolDown(sourceUnit, hslk.n2i("炎爆术"), 0)
                end
                local liehuoyizhi_points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "烈火意志")
                if liehuoyizhi_points > 0 then
                    hbuff.addStackAttrBuff(
                        CONST_DAMAGE_SRC.skill,
                        sourceUnit,
                        "烈火意志",
                        _attr({ fa_bao = "+0.5", attack_speed = "+1" }),
                        12,
                        liehuoyizhi_points,
                        hslk.n2v("炽热连击", "Art"),
                        "烈火意志|n每层提高0.5%法术暴击和1%攻击速度",
                        true
                    )
                end
                if hcache.get(sourceUnit, "[T1]灵力波动套装(4件)", false) then
                    hbuff.addStackAttrBuff(
                        CONST_DAMAGE_SRC.skill,
                        sourceUnit,
                        "[T1]灵力波动套装(4件)火法",
                        _attr({ fa_bao = "+1" }),
                        20,
                        3,
                        "ReplaceableTextures\\zhuangbei\\inv_chest_cloth_03.blp",
                        "灵力波动套装触发，每层增加1点法术暴击",
                        true
                    )
                elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T1]灵力波动套装") then
                    hbuff.addStackAttrBuff(
                        CONST_DAMAGE_SRC.skill,
                        sourceUnit,
                        "[T1]灵力波动套装(4件)火法收集",
                        _attr({ fa_bao = "+0.5" }),
                        20,
                        3,
                        "ReplaceableTextures\\zhuangbei\\inv_chest_cloth_03.blp",
                        "灵力波动套装触发，每层增加0.5点法术暴击",
                        true
                    )
                end
                yanbaoshu(sourceUnit, targetUnit, hslk.n2i("炎爆术"), damage_scale, 1)
                if hskill.hasActiveAbility(sourceUnit, hslk.n2i("强化炽热连击")) and math.random(1, 100) <= 10 then
                    echo("炽热连击连发！！！", hunit.getOwner(sourceUnit))
                else
                    hbuff.delete(sourceUnit, "炽热连击")
                end
                return
            end
            if
                hskill.hasActiveAbility(sourceUnit, hslk.n2i("火凤凰")) and hunit.getCurMana(sourceUnit) >= 10 and
                hskill.checkAndEnterCD(sourceUnit, hslk.n2i("火凤凰"), fashijineng_cd["火凤凰"])
            then
                huofenghuang(sourceUnit, targetUnit, hslk.n2i("火凤凰"))
                return
            end
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("火球术")) and hunit.getCurMana(sourceUnit) >= 2 then
                huoqiushu(sourceUnit, targetUnit, hslk.n2i("火球术"), true)
                return
            end
            hunit.animate(sourceUnit, "stand")
            if hskill.checkAndEnterCD(sourceUnit, "no_mana_hint", 5) then
                echo("魔法不够释放任何技能", hunit.getOwner(sourceUnit))
            end
        end
    )

    -- 法术暴击 法师触发逻辑区
    hevent.register(
        whichUnit,
        CONST_EVENT.fashubaoji,
        "fashi_jineng",
        function(evtData)
            if
                hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("点燃")) and
                evtData.damageSpeedType == CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
            then
                dianran(evtData.triggerUnit, evtData.targetUnit, evtData.damage, hslk.n2i("点燃"))
            end
            if
                evtData.triggerSkill == hslk.n2i("火球术") or
                evtData.triggerSkill == hslk.n2i("炎爆术") or
                evtData.triggerSkill == hslk.n2i("火焰冲击")
            then
                local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "薪火")
                if points > 0 then
                    hskill.setCoolDown(
                        evtData.triggerUnit,
                        hslk.n2i("燃烧"),
                        math.max(0, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("燃烧")) - points * 0.2)
                    )
                end
            end
        end
    )

    -- 法师伤害触发区
    hevent.register(
        whichUnit,
        CONST_EVENT.damage,
        "fashi_shanghai",
        function(evtData)
            if
                evtData.damageType == DAMAGE_TYPE.MOFA and
                hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("炽热连击")) and
                hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("炎爆术")) and
                chirelianji_skill[evtData.triggerSkill] ~= nil
            then
                chirelianji(evtData.triggerUnit, evtData.isCritical)
            end

            if
                hskill.hasActiveAbility(evtData.triggerUnit, hslk.n2i("烈焰之心")) and
                evtData.damageType == DAMAGE_TYPE.MOFA and
                math.random(1, 100) <= 10
            then
                hbuff.addStackAttrBuff(
                    CONST_DAMAGE_SRC.skill,
                    evtData.triggerUnit,
                    "烈焰之心触发",
                    { fa_baoshang = "+10" },
                    10,
                    3,
                    "ReplaceableTextures\\BTN_FS_01.blp",
                    "烈焰之心: 每层增加10% 法术暴击伤害"
                )
            end
        end
    )
end
