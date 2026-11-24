local CHENGJIEQI_JINGTONG_XISHU = 14

---被动技能cd类常数
local CHENGJIEQI_CD = {}
CHENGJIEQI_CD[hslk.n2i("十字军打击")] = 6
CHENGJIEQI_CD[hslk.n2i("公正之剑")] = 10
CHENGJIEQI_CD["光明赐福"] = 180

local SHENGYIN_CONFIG = {
    {
        name = "命令圣印",
        description = "命令圣印:攻击30%概率额外50%攻击力光明魔法伤害",
        art = "ReplaceableTextures\\MoreButtons\\KUANGBAO\\BTNKUANGBAO.blp",
        event = CONST_EVENT.attack,
        action = function(evtData)
            local triggerUnit = evtData.triggerUnit
            local targetUnit = evtData.targetUnit
            if math.random(1, 100) <= 30 then
                if hmingwen.isEquipped("强效命令圣印", hunit.getOwner(triggerUnit)) then
                    hskillMoban.radiusAOE(
                        hunit.x(targetUnit),
                        hunit.y(targetUnit),
                        triggerUnit,
                        300,
                        function(u)
                            hskill.damage(
                                {
                                    sourceUnit = triggerUnit,
                                    targetUnit = u,
                                    damage = hattribute.getWithLimit(triggerUnit, nil, "attack", 0) * 0.5,
                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                    damageType = DAMAGE_TYPE.MOFA,
                                    triggerSkill = hslk.n2i("圣印"),
                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT }
                                }
                            )
                        end
                    )
                else
                    hskill.damage(
                        {
                            sourceUnit = triggerUnit,
                            targetUnit = targetUnit,
                            damage = hattribute.getWithLimit(triggerUnit, nil, "attack", 0) * 0.5,
                            damageSrc = CONST_DAMAGE_SRC.skill,
                            damageType = DAMAGE_TYPE.MOFA,
                            triggerSkill = hslk.n2i("圣印"),
                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT }
                        }
                    )
                end
            end
        end
    },
    {
        name = "光明圣印",
        description = "光明圣印:攻击100%概率回1%血",
        art = "ReplaceableTextures\\BTN_QS_BD3.blp",
        event = CONST_EVENT.attack,
        action = function(evtData)
            local triggerUnit = evtData.triggerUnit
            hunit.addCurLife(triggerUnit, hunit.getMaxLife(triggerUnit) * 0.01)
        end
    },
    {
        name = "智慧圣印",
        description = "智慧圣印:攻击100%概率回2蓝",
        art = "ReplaceableTextures\\ZHIHUISHENGYIN\\ZHIHUISHENGYIN.blp",
        event = CONST_EVENT.attack,
        action = function(evtData)
            local triggerUnit = evtData.triggerUnit
            hunit.addCurMana(triggerUnit, 2)
        end
    },
    {
        name = "殉难圣印",
        description = "殉难圣印:攻击100%概率造成额外50%攻击力光明魔法伤害，但是自己会受到1%最大生命值的伤害",
        art = "ReplaceableTextures\\XUNNANSHENGYIN\\XUNNANSHENGYIN.blp",
        event = CONST_EVENT.attack,
        action = function(evtData)
            local triggerUnit = evtData.triggerUnit
            local targetUnit = evtData.targetUnit
            local fanshi = hunit.getMaxLife(triggerUnit) * 0.01
            if hmingwen.isEquipped("理智殉难", hunit.getOwner(triggerUnit)) then
                fanshi = fanshi * 0.5
            end
            hunit.subCurLife(triggerUnit, fanshi)
            local damage = hattribute.getWithLimit(triggerUnit, nil, "attack", 0) * 0.5
            if hcache.get(triggerUnit, "[T1]无畏勇士套装(4件)", false) then
                damage = damage * 1.3
            elseif hzhuangbeishouji.isActive(hunit.getOwner(triggerUnit), "[T1]无畏勇士套装") then
                damage = damage * 1.1
            end
            if hskill.hasActiveAbility(triggerUnit, hslk.n2i("众神赐福")) then
                damage = damage * 1.1
            end
            hskill.damage(
                {
                    sourceUnit = triggerUnit,
                    targetUnit = targetUnit,
                    damage = damage,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.MOFA,
                    triggerSkill = hslk.n2i("圣印"),
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT }
                }
            )
        end
    }
}

local guangmingcifu = function(whichUnit)
    hunit.setCurLifePercent(whichUnit, 30)
    hbuff.update(
        CHENGJIEQI_CD["光明赐福"],
        whichUnit,
        "光明赐福",
        false,
        nil,
        nil,
        "ReplaceableTextures\\BTN_QS_BD3.blp",
        "光明赐福本能正在CD中",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.CREATE_ONLY, false
    )
end

local function getShenshengFennu(whichUnit)
    if whichUnit == nil then
        return 0
    end
    return hcache.get(whichUnit, "SHENSHENGFENNU_COUNT", 0)
end

local function addShenshengFennu(whichUnit, stack)
    if whichUnit == nil then
        return 0
    end
    local count = hcache.get(whichUnit, "SHENSHENGFENNU_COUNT", 0)
    local maxCount = 3
    if hskill.hasActiveAbility(whichUnit, hslk.n2i("惩戒大师")) then
        maxCount = maxCount + 1
    end
    if hmingwen.isEquipped("强化神圣愤怒", hunit.getOwner(whichUnit)) then
        maxCount = maxCount + 1
    end
    count = math.min(maxCount, count + stack)
    hcache.set(whichUnit, "SHENSHENGFENNU_COUNT", count)
    if hcache.get(whichUnit, "[T1]无畏勇士套装(3件)", false) then
        hunit.addCurMana(whichUnit, 3)
    elseif hzhuangbeishouji.isActive(hunit.getOwner(whichUnit), "[T1]无畏勇士套装") then
        hunit.addCurMana(whichUnit, 1)
    end
    set_energy_point(hunit.getOwner(whichUnit), count, maxCount, "huangse")
end

local function subShenshengFennu(whichUnit, stack)
    if whichUnit == nil then
        return 0
    end
    local maxCount = 3
    if hskill.hasActiveAbility(whichUnit, hslk.n2i("惩戒大师")) then
        maxCount = maxCount + 1
    end
    if hmingwen.isEquipped("强化神圣愤怒", hunit.getOwner(whichUnit)) then
        maxCount = maxCount + 1
    end
    local count = hcache.get(whichUnit, "SHENSHENGFENNU_COUNT", 0)
    count = math.max(0, count - stack)
    hcache.set(whichUnit, "SHENSHENGFENNU_COUNT", count)
    set_energy_point(hunit.getOwner(whichUnit), count, maxCount, "huangse")
end

local fuchouzhinu = function(sourceUnit, duration)
    if hbuff.hasBuffThatLastLongerthan(sourceUnit, hslk.n2i("复仇之怒"), duration) then
        return
    end
    --htextTag.create2Unit(sourceUnit, "复仇之怒", 10, "ff3300", 1, 1, 50)
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\fuchouzhinu.wav", 1000, true),
        100,
        sourceUnit
    )
    heffect.attach("war3mapImported\\TomeOfRetrainingCaster.mdx", sourceUnit, "origin", 0)
    local e = heffect.attach("war3mapImported\\[Spell]_075.mdx", sourceUnit, "chest", -1)
    hbuff.update(
        duration,
        sourceUnit,
        hslk.n2i("复仇之怒"),
        true,
        function()
            hevent.register(
                sourceUnit,
                CONST_EVENT.damagingCustomSource,
                "复仇之怒",
                function(evtData)
                    evtData.damage = evtData.damage * 1.3
                end
            )
        end,
        function()
            hevent.unregister(sourceUnit, CONST_EVENT.damagingCustomSource, "复仇之怒")
            heffect.destroy(e)
        end,
        hslk.n2v("复仇之怒", "Art"),
        "复仇之怒:伤害增加30%，十字军打击冷却时间降低3秒",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE
    )
end

local function shenshengfengbao(sourceUnit, skillID)
    local damageMulti = 4
    if hcache.get(sourceUnit, "[T2]熔铸勇士套装(4件)", false) then
        damageMulti = damageMulti * 1.5
    elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T2]熔铸勇士套装") then
        damageMulti = damageMulti * 1.2
    end
    local effect = "war3mapImported\\[Spell]_071_X.mdx"
    if hbuff.hasBuff(sourceUnit, hslk.n2i("苍穹之力")) then
        damageMulti = damageMulti * 1.5
        effect = "war3mapImported\\[Spell]_071.mdx"
        hbuff.delete(sourceUnit, hslk.n2i("苍穹之力"))
        hunit.addCurMana(sourceUnit, 7)
    end

    if hmingwen.isEquipped("混乱风暴", hunit.getOwner(sourceUnit)) then
        damageMulti = damageMulti * 0.7
    end

    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\shenshengfengbao_shifang.wav", 1000, true),
        100,
        sourceUnit
    )
    addShenshengFennu(sourceUnit, 1)

    local damageFunction = function(localUnit, damageMulti)
        hskill.damage(
            {
                sourceUnit = sourceUnit,
                targetUnit = localUnit,
                damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * damageMulti,
                damageSrc = CONST_DAMAGE_SRC.skill,
                damageType = DAMAGE_TYPE.WULI,
                triggerSkill = skillID,
                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT }
            }
        )
        local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "神圣奉献")
        if points > 0 then
            hbuff.update(
                8,
                localUnit,
                "神圣奉献",
                false,
                nil,
                nil,
                "ReplaceableTextures\\qishi\\Spell_Holy_InnerFire.blp",
                "神圣奉献:受到的奉献的伤害提高" .. (20 * points) .. "%",
                1,
                nil,
                nil,
                nil,
                nil,
                HBUFF_UPDATE_MODE.OVERWRITE
            )
        end
        if hmingwen.isEquipped("混乱风暴", hunit.getOwner(sourceUnit)) then
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = localUnit,
                    damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * damageMulti,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = DAMAGE_TYPE.MOFA,
                    triggerSkill = skillID,
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT }
                }
            )
        end
        hsound.voice2Unit(
            hsound.voiceCreate("resource\\war3mapImported\\sound\\shenshengfengbao_shanghai.wav", 1000, true),
            100,
            localUnit
        )
    end

    local gmszfbpoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "光明使者的风暴")
    if gmszfbpoints > 0 then
        local moveDistance = 300 + gmszfbpoints * 50
        local damageMulti = damageMulti * (1 + gmszfbpoints * 0.01)
        local facing = hunit.getFacing(sourceUnit)
        local startX, startY = hunit.x(sourceUnit), hunit.y(sourceUnit)
        local endX, endY = math.polarProjection(startX, startY, moveDistance, facing)
        hskillMoban.leap(
            {
                ttl = 3,
                arrowAttachModel = effect,
                --arrowUnit = sourceUnit, -- 前冲的单位（有就是自身冲击，没有就是马甲特效冲击）
                sourceUnit = sourceUnit,      --伤害来源（必须有！不管有没有伤害）
                --targetUnit = evtData.targetUnit, --冲击的目标单位（可选的，有单位目标，那么冲击到单位就结束）
                tokenX = hunit.x(sourceUnit), --冲击开始x坐标（可选的，对点冲击，与某目标无关）
                tokenY = hunit.y(sourceUnit), --冲击开始y坐标（可选的，对点冲击，与某目标无关）
                x = endX,                     --冲击的x坐标（可选的，对点冲击，与某目标无关）
                y = endY,                     --冲击的y坐标（可选的，对点冲击，与某目标无关）
                speed = 15,                   --冲击的速度（可选的，默认10，0.02秒的移动距离,大概1秒500px)
                acceleration = 0,
                shake = 0,                    --摇摆振幅角度[-90~+90|random]（可选的，默认0)
                filter = function(enum)
                    return hunit.isEnemy(sourceUnit, enum) and hunit.isAlive(enum)
                end,                      --必须有
                tokenArrowScale = 1.00,   --前冲的特效作为马甲冲击时的模型缩放
                tokenArrowOpacity = 1.00, --前冲的特效作为马甲冲击时的模型透明度[0-1]
                tokenArrowHeight = 0.00,  --前冲的特效作为马甲冲击时的初始离地高度
                effectMovement = nil,     --移动过程，每个间距的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                --animateMovement = "attack",
                --animation = "attack",
                effectEnd = nil,                    --到达最后位置时的特效（可选的，采用的0秒删除法，请使用explode类型的特效）
                damageMovement = 0,                 --移动过程中的伤害（可选的，默认为0）
                damageMovementRadius = 400,         --移动过程中的伤害（可选的，默认为0，易知0范围是无效的所以有伤害也无法体现）
                damageMovementRepeat = false,       --移动过程中伤害是否可以重复造成（可选的，默认为不能）
                damageMovementDrag = false,         --移动过程是否拖拽敌人（可选的，默认为不能）
                damageEndRadius = 0,                --移动结束时对目标的伤害范围（可选的，默认为0，此处0范围是有效的，会只对targetUnit生效，除非unit不存在）
                damageSrc = CONST_DAMAGE_SRC.skill, --伤害的种类（可选）
                --damageEffect = "war3mapImported\\AZ_gelie.mdx", --伤害特效（可选）
                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT },
                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                damageType = DAMAGE_TYPE.WULI,
                damageSkill = hslk.n2i("神圣风暴"),
                oneHitOnly = false, --是否打击一次就立刻失效（类似格挡，这个一次和只攻击一个单位不是一回事
                endDistance = 0,
                skipPathCheck = true,
                extraInfluence = function(whichUnit)
                    damageFunction(whichUnit, damageMulti)
                end, --对选中的敌人的额外影响，会回调该敌人单位，可以对其做出自定义行为
                onEnding = function(_, _, timePassed)
                end
            }
        )
    else
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
                end, true
            )
        heffect.xyz(effect, hunit.x(sourceUnit), hunit.y(sourceUnit), hunit.z(sourceUnit), 0.5, 1, 1, 1, 1)
        for _, target in ipairs(group) do
            damageFunction(target, damageMulti)
        end
    end
end
local function gongzhengzhijian(sourceUnit, targetUnit, skillID)
    local damageMulti = 1.8
    local effect = "war3mapImported\\[Spell]_072_1.mdx"
    local shenshengfennu = 1

    if hmingwen.isEquipped("愤怒之剑", hunit.getOwner(sourceUnit)) then
        damageMulti = damageMulti * 0.85
        shenshengfennu = shenshengfennu + 1
    end
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("战争艺术")) then
        damageMulti = damageMulti * 1.2
        if math.random(1, 100) <= 10 then
            addShenshengFennu(sourceUnit, 1)
        end
        local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "神圣利刃")
        if points > 0 and htime.setupAndCheckCoolDown(sourceUnit, "奉献", 6) then
            local x = hunit.x(targetUnit)
            local y = hunit.y(targetUnit)
            local z = hunit.z(targetUnit)
            heffect.xyz("war3mapImported\\[Spell]_147.mdx", x, y, z, 5, 1, 1, 1, 1)
            local second = 1
            htime.setInterval(
                1,
                function(curTimer)
                    if second > 5 then
                        curTimer.destroy()
                        return
                    end
                    second = second + 1
                    hskillMoban.radiusAOE(
                        x,
                        y,
                        sourceUnit,
                        500,
                        function(unit)
                            local shenshenglirenpoints =
                                htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "神圣利刃")
                            if shenshenglirenpoints > 0 then
                                if
                                    math.random(1, 100) < shenshenglirenpoints * 2 and
                                    htime.setupAndCheckCoolDown(sourceUnit, "奉献产豆", 1)
                                then
                                    addShenshengFennu(sourceUnit, 1)
                                    htextTag.create2Unit(sourceUnit, "神圣利刃", 6, "ff3300", 1, 1, 50)
                                end
                            end
                            local fenxiandamageMulti = 1
                            if hbuff.hasBuff(unit, "神圣奉献") then
                                local shenshengfengxianpoints =
                                    htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "神圣奉献")
                                fenxiandamageMulti = fenxiandamageMulti * (1 + 0.2 * shenshengfengxianpoints)
                            end
                            hskill.damage(
                                {
                                    sourceUnit = sourceUnit,
                                    targetUnit = unit,
                                    damage = hunit.getZhushuxing(sourceUnit) * points * 0.15 * fenxiandamageMulti,
                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                    damageType = DAMAGE_TYPE.MOFA,
                                    triggerSkill = hslk.n2i("装备技能"),
                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT },
                                    shanghainame = "奉献",
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
    end
    hunit.subCurMana(sourceUnit, 5)
    addShenshengFennu(sourceUnit, shenshengfennu)
    heffect.xyz(effect, hunit.x(targetUnit), hunit.y(targetUnit), hunit.z(targetUnit), 0.5, 1, 1, 1, 1)
    hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\shenpan.wav", 1000, true), 100, targetUnit)
    hskill.damage(
        {
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * damageMulti,
            damageSrc = CONST_DAMAGE_SRC.skill,
            damageType = DAMAGE_TYPE.WULI,
            triggerSkill = skillID,
            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT }
        }
    )
end

SKILLS["圣印"] = function(evtData)
    -- TODO, change this to Buff style
    local whichUnit = evtData.triggerUnit
    local status = hcache.get(whichUnit, "SHENGYIN_CURRENT", nil)
    if status == nil then
        status = 1
    elseif status >= #SHENGYIN_CONFIG then
        hevent.unregister(
            whichUnit,
            SHENGYIN_CONFIG[#SHENGYIN_CONFIG].event,
            "SHENGYIN" .. tostring(#SHENGYIN_CONFIG),
            SHENGYIN_CONFIG[#SHENGYIN_CONFIG].action
        )
        status = 1
    else
        hevent.unregister(
            whichUnit,
            SHENGYIN_CONFIG[status].event,
            "SHENGYIN" .. tostring(status),
            SHENGYIN_CONFIG[status].action
        )
        status = status + 1
    end
    echo("激活:" .. SHENGYIN_CONFIG[status].name, hunit.getOwner(whichUnit))
    hcache.set(whichUnit, "SHENGYIN_CURRENT", status)
    hevent.register(
        whichUnit,
        SHENGYIN_CONFIG[status].event,
        "SHENGYIN" .. tostring(status),
        SHENGYIN_CONFIG[status].action
    )
    hbuff.update(
        0,
        whichUnit,
        "圣印",
        true,
        nil,
        nil,
        SHENGYIN_CONFIG[status].art,
        SHENGYIN_CONFIG[status].description,
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE, false
    )
end

local shizijundaji = function(sourceUnit, targetUnit)
    addShenshengFennu(sourceUnit, 1)

    local skillID = hslk.n2i("十字军打击")
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\shizijundaji-shanghai.wav", 1000, true),
        100,
        targetUnit
    )
    heffect.attach("war3mapImported\\[spell]az_baodian_jinse.mdx", targetUnit, "chest", 0)
    --htextTag.create2Unit(targetUnit, "十字军打击", 10, "ff3300", 1, 1, 50)
    hskill.damage(
        {
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
            damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) + hunit.getZhushuxing(sourceUnit),
            damageSrc = CONST_DAMAGE_SRC.skill,
            damageType = DAMAGE_TYPE.WULI,
            triggerSkill = skillID,
            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT }
        }
    )
    if hskill.hasActiveAbility(sourceUnit, hslk.n2i("苍穹之力")) then
        if math.random(1, 100) <= 20 then
            hbuff.update(
                10,
                sourceUnit,
                hslk.n2i("苍穹之力"),
                true,
                nil,
                nil,
                hslk.n2v("神圣风暴", "Art"),
                "你的下一个神圣风暴会恢复7点法力值，并额外造成50%的伤害",
                1,
                nil,
                nil,
                nil,
                nil,
                HBUFF_UPDATE_MODE.OVERWRITE
            )
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "强化苍穹之力")
            if points > 0 then
                if math.random(1, 100) <= points * 20 then
                    hskill.setCoolDown(sourceUnit, hslk.n2i("神圣风暴"), 0)
                end
            end
        end
    end
end

SKILLS["神圣风暴"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    hunit.setAnimateSpeed(sourceUnit, 2.5, 0.25)
    hunit.animate(sourceUnit, "attack slam")
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\shizijundaji-shifa.wav", 1000, true),
        100,
        sourceUnit
    )
    htime.setTimeout(
        0.25,
        function(_)
            shenshengfengbao(sourceUnit, hslk.n2i("神圣风暴"))
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("众神赐福")) and hcache.get(sourceUnit, "SHENGYIN_CURRENT", nil) == 1 and math.random(1, 100) <= 30 then
                htime.setTimeout(
                    0.25,
                    function(_)
                        htextTag.create2Unit(sourceUnit, "众神赐福", 6, "ff3300", 1, 1, 50)
                        shenshengfengbao(sourceUnit, hslk.n2i("神圣风暴"))
                    end
                )
            end
        end
    )
end

SKILLS["神圣裁决"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local targetUnit = evtData.targetUnit
    if hbuff.hasBuff(sourceUnit, hslk.n2i("正义之火")) == false and getShenshengFennu(sourceUnit) < 3 then
        echo("神圣愤怒不足以释放裁决之力", hunit.getOwner(sourceUnit))
        hunit.animate(sourceUnit, "stand")
        return
    end
    hunit.setAnimateSpeed(sourceUnit, 3, 0.25)
    hunit.animate(sourceUnit, "attack slam")
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\shizijundaji-shifa.wav", 1000, true),
        100,
        sourceUnit
    )
    htime.setTimeout(
        0.25,
        function(_)
            local skillID = hslk.n2i("神圣裁决")
            --htextTag.create2Unit(targetUnit, "神圣裁决", 10, "ff3300", 1, 1, 50)
            local damageMulti = 5
            local hasSecondHit = false
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("众神赐福")) and
                hcache.get(sourceUnit, "SHENGYIN_CURRENT", nil) == 4 then
                damageMulti = damageMulti * 1.1
            end
            if hcache.get(sourceUnit, "[T3]无畏战将套装(3件)", false) then
                damageMulti = damageMulti * 1.04
            elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T3]无畏战将套装") then
                damageMulti = damageMulti * 1.02
            end
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("正义裁决")) then
                local buffHandle = hbuff.getBuffHandle(sourceUnit, hslk.n2i("正义裁决"))
                local stack = 1
                local lianjiRate = 20
                if hcache.get(sourceUnit, "[T3]无畏战将套装(4件)", false) then
                    lianjiRate = lianjiRate + 5
                elseif hzhuangbeishouji.isActive(hunit.getOwner(sourceUnit), "[T3]无畏战将套装") then
                    lianjiRate = lianjiRate + 3
                end
                if math.random(1, 100) <= lianjiRate then
                    hasSecondHit = true
                    stack = 2
                end
                if buffHandle ~= nil then
                    stack = math.min(buffHandle.stack + stack, 5)
                end
                damageMulti = (stack * 0.06 + 1) * damageMulti
                hbuff.update(
                    12,
                    sourceUnit,
                    hslk.n2i("正义裁决"),
                    true,
                    nil,
                    nil,
                    hslk.n2v("正义裁决", "Art"),
                    "神圣裁决造成的伤害提高" .. tostring(6 * stack) .. "%",
                    stack,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE
                )
            end

            if hbuff.hasBuff(sourceUnit, hslk.n2i("正义之火")) then
                hbuff.delete(sourceUnit, hslk.n2i("正义之火"))
            else
                subShenshengFennu(sourceUnit, 3)
            end

            hsound.voice2Unit(
                hsound.voiceCreate("resource\\war3mapImported\\sound\\mengji.wav", 1000, true),
                150,
                targetUnit
            )
            local shanghaileixing = DAMAGE_TYPE.MOFA
            if hmingwen.isEquipped("圣殿骑士的裁决", hunit.getOwner(sourceUnit)) then
                shanghaileixing = DAMAGE_TYPE.WULI
            end
            hskill.damage(
                {
                    sourceUnit = sourceUnit,
                    targetUnit = targetUnit,
                    damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * damageMulti,
                    damageSrc = CONST_DAMAGE_SRC.skill,
                    damageType = shanghaileixing,
                    triggerSkill = skillID,
                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT }
                }
            )
            heffect.attach("war3mapImported\\AZ_MD_4D1_1_2972256609.mdx", targetUnit, "chest", 0)

            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "灰烬觉醒")
            if points > 0 then
                local rate = points * 20
                if math.random(1, 100) <= rate and htime.setupAndCheckCoolDown(sourceUnit, "灰烬觉醒", 15) then
                    local cgcpoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "尘归尘")
                    if cgcpoints > 0 and math.random(1, 100) <= 30 then
                        fuchouzhinu(sourceUnit, cgcpoints)
                    end
                    heffect.xyz(
                        "war3mapImported\\[qishi]shenpan.mdx",
                        hunit.x(sourceUnit),
                        hunit.y(sourceUnit),
                        hunit.z(sourceUnit),
                        0,
                        1,
                        1,
                        1,
                        1,
                        nil,
                        nil,
                        hunit.getFacing(sourceUnit)
                    )
                    local huijingjuexingDamage =
                        (hunit.getZhushuxing(sourceUnit) + hattribute.getWithLimit(sourceUnit, nil, "attack", 0)) * 2
                    hskillMoban.radiusAngleAOE(
                        sourceUnit,
                        400,
                        hunit.getFacing(sourceUnit),
                        210,
                        function(u)
                            if hunit.isEnemy(sourceUnit, u) then
                                hskill.damage(
                                    {
                                        sourceUnit = sourceUnit,
                                        targetUnit = u,
                                        damage = huijingjuexingDamage,
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.WULI,
                                        triggerSkill = hslk.n2i("装备技能"),
                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT },
                                        shanghainame = "灰烬觉醒"
                                    }
                                )
                            end
                        end,
                        true
                    )

                    -- 灰烬能量天赋效果
                    local hjnlpoints = htianfu.getActiveTianfuLevel(hunit.getOwner(sourceUnit), "灰烬能量")
                    if hjnlpoints > 0 then
                        addShenshengFennu(sourceUnit, hjnlpoints)
                        htextTag.create2Unit(sourceUnit, "灰烬能量+" .. hjnlpoints, 6, "ff3300", 1, 1, 50)
                    end
                end
            end

            if hasSecondHit then
                htime.setTimeout(
                    0.25,
                    function(_)
                        --htextTag.create2Unit(targetUnit, "正义裁决连击", 10, "ff3300", 1, 1, 50)
                        hskill.damage(
                            {
                                sourceUnit = sourceUnit,
                                targetUnit = targetUnit,
                                damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * damageMulti * 1.25,
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = shanghaileixing,
                                triggerSkill = skillID,
                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT }
                            }
                        )
                        hsound.voice2Unit(
                            hsound.voiceCreate("resource\\war3mapImported\\sound\\mengji.wav", 1000, true),
                            150,
                            targetUnit
                        )
                        heffect.attach("war3mapImported\\AZ_MD_4D1_1_2972256609.mdx", targetUnit, "chest", 0)
                    end
                )
            end
        end
    )
end

local shenpanshanghai = function(sourceUnit, targetUnit, effect, damage, isWujingShenpan)
    if isWujingShenpan then
        hskillMoban.radiusAOE(
            hunit.x(targetUnit),
            hunit.y(targetUnit),
            sourceUnit,
            300,
            function(u)
                hskill.damage(
                    {
                        sourceUnit = sourceUnit,
                        targetUnit = u,
                        damage = damage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = hslk.n2i("审判"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT }
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
                targetUnit = targetUnit,
                damage = damage,
                damageSrc = CONST_DAMAGE_SRC.skill,
                damageType = DAMAGE_TYPE.MOFA,
                triggerSkill = hslk.n2i("审判"),
                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT }
            }
        )
    end
end

SKILLS["审判"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    local targetUnit = evtData.targetUnit
    hunit.setAnimateSpeed(sourceUnit, 3, 0.25)
    hunit.animate(sourceUnit, "spell")
    local damageMulti = 1.2
    if hshangcheng.hasItem(hunit.getOwner(sourceUnit), "见习惩戒骑") then
        damageMulti = damageMulti * 1.05
    end
    local effect = "war3mapImported\\[qishi]shenpan_1.mdx"
    local isWujingShenpan = false
    local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "无尽审判")
    if points > 0 then
        if math.random(1, 100) <= points * 8 then
            effect = "war3mapImported\\[qishi]shenpan_2.mdx"
            isWujingShenpan = true
        end
    end
    heffect.attach(effect, targetUnit, "origin", 0)
    htime.setTimeout(
        0.25,
        function(_)
            local skillID = hslk.n2i("审判")
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("狂热")) then
                local duration = 4
                if hmingwen.isEquipped("执着狂热", hunit.getOwner(sourceUnit)) then
                    duration = duration + 2
                end
                damageMulti = damageMulti * 1.25
                local zmkrpoints = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "致命狂热")
                hbuff.update(
                    duration,
                    sourceUnit,
                    hslk.n2i("狂热"),
                    true,
                    function()
                        hattribute.set(sourceUnit, 0, {
                            attack_speed = "+30"
                        })
                        if zmkrpoints > 0 then
                            hattribute.set(sourceUnit, 0, {
                                wu_bao = "+" .. zmkrpoints,
                                fa_bao = "+" .. zmkrpoints
                            })
                        end
                        hevent.register(
                            sourceUnit,
                            CONST_EVENT.attack,
                            hslk.n2i("狂热"),
                            function(newEvtData)
                                hskill.damage(
                                    {
                                        sourceUnit = sourceUnit,
                                        targetUnit = newEvtData.targetUnit,
                                        damage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * 0.1,
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.MOFA,
                                        triggerSkill = hslk.n2i("狂热"),
                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT }
                                    }
                                )
                            end
                        )
                    end,
                    function()
                        hattribute.set(sourceUnit, 0, {
                            attack_speed = "-30"
                        })
                        if zmkrpoints > 0 then
                            hattribute.set(sourceUnit, 0, {
                                wu_bao = "-" .. zmkrpoints,
                                fa_bao = "-" .. zmkrpoints
                            })
                        end
                        hevent.unregister(sourceUnit, CONST_EVENT.attack, hslk.n2i("狂热"))
                    end,
                    hslk.n2v("狂热", "Art"),
                    "审判使你获得神圣狂热，普攻攻击速度提高30%，并额外造成攻击力10%点光明魔法伤害，物理和法术暴击率提高" .. zmkrpoints .. "%",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE
                )
            end

            local status = hcache.get(sourceUnit, "SHENGYIN_CURRENT", nil)
            local name = "审判"
            if status == nil then
            elseif status == 1 then
                name = "命令审判"
                local buffDamage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * 0.08
                hbuff.update(
                    6,
                    targetUnit,
                    "命令审判",
                    false,
                    function()
                        hevent.register(
                            targetUnit,
                            CONST_EVENT.beAttack,
                            "命令审判",
                            function(newEvtData)
                                hskill.damage(
                                    {
                                        sourceUnit = newEvtData.attackUnit,
                                        targetUnit = newEvtData.triggerUnit,
                                        damage = buffDamage,
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.MOFA,
                                        triggerSkill = hslk.n2i("审判"),
                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT }
                                    }
                                )
                            end
                        )
                    end,
                    function()
                        hevent.unregister(targetUnit, CONST_EVENT.beAttack, "命令审判")
                    end,
                    hslk.n2v("审判", "Art"),
                    "命令审判：被审判目标6秒内受到普通攻击会受到惩戒骑8%的攻击力(" .. tostring(math.floor(buffDamage)) .. ")的伤害",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE
                )
            elseif status == 2 then
                hskill.heal(
                    {
                        healer = sourceUnit,
                        healee = sourceUnit,
                        heal = hunit.getMaxLife(sourceUnit) * 0.05,
                        healType = HEAL_TYPE.SKILL,
                        triggerSkill = hslk.n2i("审判")
                    }
                )
                name = "光明审判"
            elseif status == 3 then
                hunit.addCurMana(sourceUnit, 10)
                name = "智慧审判"
            elseif status == 4 then
                hunit.subCurLife(sourceUnit, hunit.getMaxLife(sourceUnit) * 0.05)
                name = "殉难审判"
                damageMulti = damageMulti * 2
                local buffDamage = hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * 0.12
                hbuff.update(
                    6,
                    targetUnit,
                    "殉难审判",
                    false,
                    function()
                        hevent.register(
                            targetUnit,
                            CONST_EVENT.beAttack,
                            "殉难审判",
                            function(newEvtData)
                                hskill.damage(
                                    {
                                        sourceUnit = newEvtData.attackUnit,
                                        targetUnit = newEvtData.triggerUnit,
                                        damage = buffDamage,
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.MOFA,
                                        triggerSkill = hslk.n2i("审判"),
                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT }
                                    }
                                )
                            end
                        )
                    end,
                    function()
                        hevent.unregister(targetUnit, CONST_EVENT.beAttack, "殉难审判")
                    end,
                    hslk.n2v("审判", "Art"),
                    "殉难审判：被审判目标6秒内受到普通攻击会受到惩戒骑12%的攻击力(" .. tostring(math.floor(buffDamage)) .. ")的伤害",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE
                )
            end

            shenpanshanghai(
                sourceUnit,
                targetUnit,
                effect,
                hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * damageMulti,
                isWujingShenpan
            )
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("正义之火")) then
                hbuff.xuanyun(targetUnit, 0.4)
                if math.random(1, 100) <= 20 then
                    local e = heffect.attach("war3mapImported\\[Spell]_126.mdx", sourceUnit, "chest", 10)
                    hbuff.update(
                        10,
                        sourceUnit,
                        hslk.n2i("正义之火"),
                        true,
                        function()
                        end,
                        function()
                            heffect.destroy(e)
                        end,
                        hslk.n2v("正义之火", "Art"),
                        "你的下一个神圣裁决不消耗神圣愤怒",
                        1,
                        nil,
                        nil,
                        nil,
                        nil,
                        HBUFF_UPDATE_MODE.OVERWRITE
                    )
                end
            end
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(evtData.triggerUnit), "愤怒审判")
            if points > 0 then
                if math.random(1, 100) <= points * 5 then
                    heffect.attach(effect, targetUnit, "origin", 0)
                    htime.setTimeout(
                        0.25,
                        function(curTimer)
                            shenpanshanghai(
                                sourceUnit,
                                targetUnit,
                                effect,
                                hattribute.getWithLimit(sourceUnit, nil, "attack", 0) * damageMulti,
                                isWujingShenpan
                            )
                        end
                    )
                end
            end
        end
    )
end

SKILLS["圣佑术"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    --htextTag.create2Unit(sourceUnit, "圣佑术", 10, "ff3300", 1, 1, 50)
    hsound.voice2Unit(
        hsound.voiceCreate("resource\\war3mapImported\\sound\\shengyoushu.wav", 1000, true),
        100,
        sourceUnit
    )
    local e = heffect.attach("war3mapImported\\AZ_MagicShield_Gold.MDX", sourceUnit, "origin", -1)
    hbuff.update(
        6,
        sourceUnit,
        hslk.n2i("圣佑术"),
        true,
        function()
            hattribute.set(sourceUnit, 0, { jianshang = "+30", move = "+100 " })
        end,
        function()
            hattribute.set(sourceUnit, 0, { jianshang = "-30", move = "-100 " })
            heffect.destroy(e)
        end,
        hslk.n2v("圣佑术", "Art"),
        "降低30%受到的伤害，提高60点移动速度",
        1,
        nil,
        nil,
        nil,
        nil,
        HBUFF_UPDATE_MODE.OVERWRITE
    )
end

SKILLS["复仇之怒"] = function(evtData)
    local sourceUnit = evtData.triggerUnit
    fuchouzhinu(sourceUnit, 20)
end

SKILL_ON_LEVEL_UP["惩戒骑"] = function(whichUnit)
    local kuangbaozhixinid = hslk.n2i("王者祝福")
    if hskill.hasActiveAbility(whichUnit, kuangbaozhixinid) then
        hskillMoban.guanghuan(
            whichUnit,
            kuangbaozhixinid,
            2000,
            hslk.i2v(kuangbaozhixinid, "_guanghuanAttr"),
            true,
            true,
            "王者祝福|n10%全属性"
        )
        hskill.addProperty(whichUnit, kuangbaozhixinid, 1)
    end
    if hskill.hasActiveAbility(whichUnit, hslk.n2i("惩戒大师")) and hcache.get(whichUnit, "惩戒大师12回能", nil) == nil then
        hcache.set(
            whichUnit,
            "惩戒大师12回能",
            htime.setInterval(
                12,
                function(_)
                    if
                        hunit.isDead(whichUnit) or hunit.isDestroyed(whichUnit) or
                        hfightzhuangtai.isInFight(whichUnit) == false
                    then
                        return
                    else
                        addShenshengFennu(whichUnit, 1)
                    end
                end
            )
        )
    end
end

SKILL_SETUP["惩戒骑"] = function(whichUnit)
    --基础回蓝1
    hattribute.set(whichUnit, 0, { mana_back = "=1" })
    hskill.registerAutoCast(whichUnit, hslk.n2i("审判"))
    hskill.registerAutoCast(whichUnit, hslk.n2i("神圣裁决"))

    hskill.registerMonitoringBuff(whichUnit, hslk.n2i("正义之火"), true)
    hskill.registerMonitoringBuff(whichUnit, hslk.n2i("复仇之怒"), true)

    --设置神圣惩戒技能
    hevent.register(
        whichUnit,
        CONST_EVENT.damagingCustomSource,
        "神圣惩戒被动",
        function(evtData)
            if type(evtData.damageElementType) == "table" then
                for _, damageType in ipairs(evtData.damageElementType) do
                    if damageType == CONST_DAMAGE_ELEMENT_TYPE.LIGHT then
                        local master = hattribute.getWithLimit(whichUnit, nil, "master", 0)
                        evtData.damage = evtData.damage * (115 + master / CHENGJIEQI_JINGTONG_XISHU) / 100
                    end
                end
            end
        end
    )
    -- 惩戒骑攻击
    hevent.register(
        whichUnit,
        CONST_EVENT.beforeAttackDamage,
        "chengjieqi_attack",
        function(evtData)
            local shizijundajicd = CHENGJIEQI_CD[hslk.n2i("十字军打击")]
            local sourceUnit = evtData.sourceUnit
            local targetUnit = evtData.targetUnit
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("众神赐福")) and
                hcache.get(sourceUnit, "SHENGYIN_CURRENT", nil) == 3 then
                shizijundajicd = shizijundajicd - 1
            end
            if hbuff.hasBuff(sourceUnit, hslk.n2i("复仇之怒")) then
                shizijundajicd = shizijundajicd - 3
            end
            if hskill.hasActiveAbility(sourceUnit, hslk.n2i("战争艺术")) and math.random(1, 100) <= 12 then
                htime.clearCoolDown(sourceUnit, hslk.n2i("公正之剑"))
            end
            local points = htianfu.getActiveTianfuLevel(hunit.getOwner(whichUnit), "土归土")
            if points > 0 then
                if math.random(1, 100) <= points * 2 then
                    htime.clearCoolDown(sourceUnit, "灰烬觉醒")
                    htextTag.create2Unit(sourceUnit, "土归土", 6, "ff3300", 1, 1, 50)
                end
            end

            if
                hunit.getCurMana(whichUnit) >= 5 and hskill.hasActiveAbility(sourceUnit, hslk.n2i("公正之剑")) and
                htime.setupAndCheckCoolDown(sourceUnit, hslk.n2i("公正之剑"), CHENGJIEQI_CD[hslk.n2i("公正之剑")])
            then
                gongzhengzhijian(sourceUnit, targetUnit, hslk.n2i("公正之剑"))
                return
            end

            if
                hskill.hasActiveAbility(sourceUnit, hslk.n2i("十字军打击")) and
                htime.setupAndCheckCoolDown(sourceUnit, hslk.n2i("十字军打击"), shizijundajicd)
            then
                shizijundaji(sourceUnit, targetUnit)
                return
            end
        end
    )

    hevent.register(
        whichUnit,
        CONST_EVENT.dying,
        "emolieshou",
        function(evtData)
            if hskill.hasActiveAbility(whichUnit, hslk.n2i("众神赐福")) == false then
                return
            end
            if hcache.get(whichUnit, "SHENGYIN_CURRENT", nil) ~= 2 then
                return
            end
            if htime.setupAndCheckCoolDown(whichUnit, "光明赐福", CHENGJIEQI_CD["光明赐福"]) then
                evtData.damage = 0
                guangmingcifu(whichUnit)
            end
        end
    )
end

SKILLS_STOP["审判"] = function(evtData)
    if hcache.get(evtData.triggerUnit, "[T2]熔铸勇士套装(3件)", false) then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("审判"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("审判")) - 2)
        )
    elseif hzhuangbeishouji.isActive(hunit.getOwner(evtData.triggerUnit), "[T2]熔铸勇士套装") then
        hskill.setCoolDown(
            evtData.triggerUnit,
            hslk.n2i("审判"),
            math.max(1, hskill.getCoolDown(evtData.triggerUnit, hslk.n2i("审判")) - 1)
        )
    end
end
