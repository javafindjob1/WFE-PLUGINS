local function heishui(evtData)
    htime.setTimeout(
        2,
        function(_)
            local triggerUnit = evtData.triggerUnit
            local targetUnit = evtData.targetUnit
            htextTag.create2Unit(targetUnit, "黑水", 10, "ff3300", 1, 1, 50)
            local radius = 300
            local scale = 0.5
            local x = hunit.x(targetUnit)
            local y = hunit.y(targetUnit)
            local z = hunit.z(targetUnit)
            local effect = heffect.xyz("war3mapImported\\[Spell]_074.mdx", x, y, z, -1, 1, scale, scale, scale)
            htime.setInterval(
                1,
                function(curTimer)
                    if hunit.isDead(triggerUnit) or hunit.isDestroyed(triggerUnit) or curTimer.passedSec() > 30 then
                        curTimer.destroy()
                        heffect.destroy(effect)
                    end
                    local group =
                        hgroup.createByXY(
                        x,
                        y,
                        radius,
                        function(filterUnit)
                            if hunit.isAlly(filterUnit, triggerUnit) == false and hunit.isAlive(filterUnit) then
                                return true
                            else
                                return false
                            end
                        end
                    )
                    for _, v in ipairs(group) do
                        hskill.damage(
                            {
                                sourceUnit = triggerUnit,
                                targetUnit = v,
                                damage = 200,
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.MOFA
                            }
                        )
                        if hunit.isHero(v) then
                            if radius <= 1500 then
                                radius = radius + 100
                                local newScale = scale + 0.16
                                local scaleChange = newScale / scale
                                hjapi.EXEffectMatScale(effect, scaleChange, scaleChange, scaleChange)
                                scale = newScale
                                htextTag.create2XY(x, y, "黑水吸收能量（对英雄造成伤害），范围扩大", 10, "ff3300", 1, 1, 50)
                            end
                        end
                    end
                end
            )
        end
    )
end

SKILLS["巫妖王黑水"] = function(evtData)
    if htime.setupAndCheckCoolDown(evtData.triggerUnit, "巫妖王黑水", 10) then
        heishui(evtData)
    end
end

hevent.reaction(
    CONST_EVENT.attack,
    "test",
    function(evtData)
        if hunit.getName(evtData.triggerUnit) == "巫妖王" then
            cj.IssueTargetOrder(evtData.triggerUnit, "thunderbolt", evtData.targetUnit)
        end
    end
)
