function initTiaoZhan()
    local config = {
        {
            name = "初级属性训练",
            place = "荣誉竞技场",
            npcName = "新手教官",
            art = "ReplaceableTextures\\BTNzb71.blp",
            tips = "进行基础属性训练，需要在规定时间内击败木桩。木桩可以减少固定伤害，请在具有一定的伤害能力之后再来挑战",
            cost = { { type = HSHOP_COST_TYPE.gold, value = 500 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, shengwangname = "新手村", value = 1 } },
            preStartCheck = function(whichUnit)
            end,
            start = function(whichUnit, rect)
                local whichPlayer = hunit.getOwner(whichUnit)
                local xunlianLevel = hxunlian.getXunlianLevel("初级属性训练", whichPlayer)
                if xunlianLevel == nil then
                    err("xunlianLevel is nil")
                    return false
                end
                hquestcustom.enqueue_dialog(whichPlayer, "新手训练师", "请在60秒内消灭挨打的木桩.")
                local requiredData = {}
                local tmpAttr =
                    hunit.getAttributeBasedOnOptions(
                        {
                            level = xunlianLevel + 5,
                            attackSpace = 1,
                            guaiwuType = MONSTER_TYPE.YEWAI_BOSS
                        }
                    )
                local ai =
                    UnitAI(
                        {
                            {
                                aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                atData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                }
                            }
                        }
                    )
                local tmpUnit =
                    henemy.create(
                        {
                            id = hslk.n2i("挨打的木桩"),
                            x = hrect.getX(rect) + 400,
                            y = hrect.getY(rect),
                            facing = 180,
                            attr = tmpAttr,
                            AI = table.clone(ai)
                        }
                    )
                hattribute.set(tmpUnit, 0, { life = "+" .. tostring(2 * hunit.getMaxLife(tmpUnit)) })
                hattribute.set(tmpUnit, 0, { attack_white = "0" })
                local final_damage_reduction = 15 * xunlianLevel
                hbuff.update(
                    0,
                    tmpUnit,
                    "final_damage_reduction",
                    true,
                    function()
                        hattribute.set(tmpUnit, 0, { final_damage_reduction = "+" .. tostring(final_damage_reduction) })
                    end,
                    function()
                        hattribute.set(tmpUnit, 0, { final_damage_reduction = "-" .. tostring(final_damage_reduction) })
                    end,
                    "ReplaceableTextures\\dunpai\\INV_Shield_PanStart_A_01.blp",
                    "最终伤害降低" .. tostring(final_damage_reduction) .. "点",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE,
                    false
                )

                hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                requiredData.guaiwu = tmpUnit
                return requiredData
            end,
            isActive = false,
            finishCheck = function(requiredData, whichUnit)
                if hunit.isDead(requiredData.guaiwu) or hunit.isDestroyed(requiredData.guaiwu) then
                    return true
                else
                    return false
                end
            end,
            finish = function(requiredData, whichUnit)
                hxunlian.tryShengji("初级属性训练", hunit.getOwner(whichUnit))
            end,
            timeout = 60,
            timeoutAction = function(requiredData, whichUnit)
                hquestcustom.enqueue_dialog(
                    hunit.getOwner(whichUnit),
                    "新手训练师",
                    "如果输出不够，可以通过升级，提升装备，获取图鉴，专业强化物品如炼金药水，锻造磨刀石等提升实力."
                )
            end,
            failAction = function(requiredData, whichUnit)
            end
        },
        {
            name = "中级属性训练",
            place = "荣誉竞技场",
            npcName = "王城总教头",
            art = "ReplaceableTextures\\BTNzb71.blp",
            tips = "进行中级属性训练，需要在规定时间内击败木桩。木桩可以减少固定伤害，请在具有一定的伤害能力之后再来挑战",
            cost = { { type = HSHOP_COST_TYPE.gold, value = 500 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, shengwangname = "王城", value = 0 } },
            preStartCheck = function(whichUnit)
            end,
            start = function(whichUnit, rect)
                local whichPlayer = hunit.getOwner(whichUnit)
                local xunlianLevel = hxunlian.getXunlianLevel("中级属性训练", whichPlayer)
                if xunlianLevel == nil then
                    err("xunlianLevel is nil")
                    return false
                end
                hquestcustom.enqueue_dialog(whichPlayer, "王城总教头", "请在60秒内消灭木桩.")
                local requiredData = {}
                local tmpAttr =
                    hunit.getAttributeBasedOnOptions(
                        {
                            level = xunlianLevel + 20,
                            attackSpace = 1,
                            guaiwuType = MONSTER_TYPE.YEWAI_BOSS
                        }
                    )
                local ai =
                    UnitAI(
                        {
                            {
                                aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                atData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                }
                            }
                        }
                    )
                local tmpUnit =
                    henemy.create(
                        {
                            id = hslk.n2i("挨打的木桩"),
                            x = hrect.getX(rect) + 400,
                            y = hrect.getY(rect),
                            facing = 180,
                            attr = tmpAttr,
                            AI = table.clone(ai)
                        }
                    )
                hattribute.set(tmpUnit, 0, { life = "+" .. tostring(4 * hunit.getMaxLife(tmpUnit)) })
                hattribute.set(tmpUnit, 0, { attack_white = "0" })
                local final_damage_reduction = 300 + 20 * xunlianLevel
                local life_back = 500 + 30 * xunlianLevel
                hbuff.update(
                    0,
                    tmpUnit,
                    "final_damage_reduction",
                    true,
                    function()
                        hattribute.set(
                            tmpUnit,
                            0,
                            {
                                final_damage_reduction = "+" .. tostring(final_damage_reduction),
                                life_back = "+" .. tostring(life_back)
                            }
                        )
                    end,
                    function()
                        hattribute.set(
                            tmpUnit,
                            0,
                            {
                                final_damage_reduction = "-" .. tostring(final_damage_reduction),
                                life_back = "+" .. tostring(life_back)
                            }
                        )
                    end,
                    "ReplaceableTextures\\dunpai\\INV_Shield_PanStart_A_01.blp",
                    "最终伤害降低" .. tostring(final_damage_reduction) .. "点",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE,
                    false
                )
                hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                requiredData.guaiwu = tmpUnit
                return requiredData
            end,
            isActive = false,
            finishCheck = function(requiredData, whichUnit)
                if hunit.isDead(requiredData.guaiwu) or hunit.isDestroyed(requiredData.guaiwu) then
                    return true
                else
                    return false
                end
            end,
            finish = function(requiredData, whichUnit)
                hxunlian.tryShengji("中级属性训练", hunit.getOwner(whichUnit))
            end,
            timeout = 60,
            timeoutAction = function(requiredData, whichUnit)
                hquestcustom.enqueue_dialog(
                    hunit.getOwner(whichUnit),
                    "王城总教头",
                    "如果输出不够，可以通过升级，提升装备，获取图鉴，专业强化物品如炼金药水，锻造磨刀石等提升实力."
                )
            end,
            failAction = function(requiredData, whichUnit)
            end
        },
        {
            name = "高级属性训练",
            place = "荣誉竞技场",
            npcName = "老兵格雷戈",
            art = "ReplaceableTextures\\BTNzb71.blp",
            tips = "进行高级属性训练，需要在规定时间内击败木桩。木桩可以减少固定伤害，请在具有一定的伤害能力之后再来挑战",
            cost = { { type = HSHOP_COST_TYPE.gold, value = 2000 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, shengwangname = "峡谷前哨站", value = 0 } },
            preStartCheck = function(whichUnit)
            end,
            start = function(whichUnit, rect)
                local whichPlayer = hunit.getOwner(whichUnit)
                local xunlianLevel = hxunlian.getXunlianLevel("高级属性训练", whichPlayer)
                if xunlianLevel == nil then
                    err("xunlianLevel is nil")
                    return false
                end
                hquestcustom.enqueue_dialog(whichPlayer, "老兵格雷戈", "请在60秒内消灭木桩.")
                local requiredData = {}
                local tmpAttr =
                    hunit.getAttributeBasedOnOptions(
                        {
                            level = xunlianLevel + 40,
                            attackSpace = 1,
                            guaiwuType = MONSTER_TYPE.YEWAI_BOSS
                        }
                    )
                local ai =
                    UnitAI(
                        {
                            {
                                aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                atData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                }
                            }
                        }
                    )
                local tmpUnit =
                    henemy.create(
                        {
                            id = hslk.n2i("挨打的木桩"),
                            x = hrect.getX(rect) + 400,
                            y = hrect.getY(rect),
                            facing = 180,
                            attr = tmpAttr,
                            AI = table.clone(ai)
                        }
                    )
                hattribute.set(tmpUnit, 0, { life = "+" .. tostring((10000 + 2000 * xunlianLevel) * 60) })
                hattribute.set(tmpUnit, 0, { attack_white = "0" })
                hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                requiredData.guaiwu = tmpUnit
                return requiredData
            end,
            isActive = false,
            finishCheck = function(requiredData, whichUnit)
                if hunit.isDead(requiredData.guaiwu) or hunit.isDestroyed(requiredData.guaiwu) then
                    return true
                else
                    return false
                end
            end,
            finish = function(requiredData, whichUnit)
                hxunlian.tryShengji("高级属性训练", hunit.getOwner(whichUnit))
            end,
            timeout = 60,
            timeoutAction = function(requiredData, whichUnit)
                hquestcustom.enqueue_dialog(
                    hunit.getOwner(whichUnit),
                    "老兵格雷戈",
                    "如果输出不够，可以通过升级，提升装备，获取图鉴，专业强化物品如炼金药水，锻造磨刀石等提升实力."
                )
            end,
            failAction = function(requiredData, whichUnit)
            end
        },
        {
            name = "初级会心训练",
            place = "荣誉竞技场",
            npcName = "王城总教头",
            art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_HAND_08.blp",
            tips = "进行初级会心训练，需要在规定时间内击败木桩。木桩只会受到暴击伤害并且受到的暴击伤害上限为1000，请在具有一定的暴击之后再来挑战",
            cost = { { type = HSHOP_COST_TYPE.gold, value = 500 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, shengwangname = "王城", value = 0 } },
            preStartCheck = function(whichUnit)
            end,
            start = function(whichUnit, rect)
                local whichPlayer = hunit.getOwner(whichUnit)
                local xunlianLevel = hxunlian.getXunlianLevel("初级会心训练", whichPlayer)
                if xunlianLevel == nil then
                    err("xunlianLevel is nil")
                    return false
                end
                hquestcustom.enqueue_dialog(whichPlayer, "王城总教头", "请在60秒内消灭木桩.")
                local requiredData = {}
                local tmpAttr =
                    hunit.getAttributeBasedOnOptions(
                        {
                            level = xunlianLevel + 20,
                            attackSpace = 1,
                            guaiwuType = MONSTER_TYPE.YEWAI_BOSS
                        }
                    )
                local ai =
                    UnitAI(
                        {
                            {
                                aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                atData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                }
                            }
                        }
                    )
                local tmpUnit =
                    henemy.create(
                        {
                            id = hslk.n2i("挨打的木桩"),
                            x = hrect.getX(rect) + 400,
                            y = hrect.getY(rect),
                            facing = 180,
                            attr = tmpAttr,
                            AI = table.clone(ai)
                        }
                    )
                hattribute.set(tmpUnit, 0, { life = "=" .. tostring(xunlianLevel * 500 + 6000) })
                hattribute.set(tmpUnit, 0, { life_back = "+" .. tostring(50 + 10 * xunlianLevel) })
                hbuff.update(
                    0,
                    tmpUnit,
                    "final_damage_reduction",
                    true,
                    function()
                        hevent.register(
                            tmpUnit,
                            CONST_EVENT.damagingCustomTarget,
                            "会心训练单位buff",
                            function(evtData)
                                if evtData.isCritical then
                                    evtData.damage = math.min(1000, evtData.damage)
                                else
                                    evtData.damage = 0
                                end
                            end
                        )
                    end,
                    function()
                    end,
                    "ReplaceableTextures\\zhuangbei\\INV_WEAPON_HAND_08.blp",
                    "只会受到暴击伤害，切暴击伤害不会超过1000点",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE,
                    false
                )
                hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                requiredData.guaiwu = tmpUnit
                return requiredData
            end,
            isActive = false,
            finishCheck = function(requiredData, whichUnit)
                if hunit.isDead(requiredData.guaiwu) or hunit.isDestroyed(requiredData.guaiwu) then
                    return true
                else
                    return false
                end
            end,
            finish = function(requiredData, whichUnit)
                hxunlian.tryShengji("初级会心训练", hunit.getOwner(whichUnit))
            end,
            timeout = 60,
            timeoutAction = function(requiredData, whichUnit)
                hquestcustom.enqueue_dialog(
                    hunit.getOwner(whichUnit),
                    "王城总教头",
                    "如果输出不够，可以通过升级，提升装备，获取图鉴，专业强化物品如炼金药水，锻造磨刀石等提升实力."
                )
            end,
            failAction = function(requiredData, whichUnit)
            end
        },
        {
            name = "中级会心训练",
            place = "荣誉竞技场",
            npcName = "老兵格雷戈",
            art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_HAND_08.blp",
            tips = "进行中级会心训练，需要在规定时间内击败木桩。木桩只会受到暴击伤害并且受到的暴击伤害上限为1000，请在具有一定的暴击之后再来挑战",
            cost = { { type = HSHOP_COST_TYPE.gold, value = 1000 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, shengwangname = "峡谷前哨站", value = 0 } },
            preStartCheck = function(whichUnit)
            end,
            start = function(whichUnit, rect)
                local whichPlayer = hunit.getOwner(whichUnit)
                local xunlianLevel = hxunlian.getXunlianLevel("中级会心训练", whichPlayer)
                if xunlianLevel == nil then
                    err("xunlianLevel is nil")
                    return false
                end
                hquestcustom.enqueue_dialog(whichPlayer, "老兵格雷戈", "请在60秒内消灭木桩.")
                local requiredData = {}
                local tmpAttr =
                    hunit.getAttributeBasedOnOptions(
                        {
                            level = xunlianLevel + 40,
                            attackSpace = 1,
                            guaiwuType = MONSTER_TYPE.YEWAI_BOSS
                        }
                    )
                local ai =
                    UnitAI(
                        {
                            {
                                aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                atData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                }
                            }
                        }
                    )
                local tmpUnit =
                    henemy.create(
                        {
                            id = hslk.n2i("挨打的木桩"),
                            x = hrect.getX(rect) + 400,
                            y = hrect.getY(rect),
                            facing = 180,
                            attr = tmpAttr,
                            AI = table.clone(ai)
                        }
                    )
                hattribute.set(tmpUnit, 0, { life = "=" .. tostring(xunlianLevel * 2000 + 20000) })
                hbuff.update(
                    0,
                    tmpUnit,
                    "final_damage_reduction",
                    true,
                    function()
                        hevent.register(
                            tmpUnit,
                            CONST_EVENT.damagingCustomTarget,
                            "会心训练单位buff",
                            function(evtData)
                                if evtData.isCritical then
                                    evtData.damage = math.min(1000, evtData.damage)
                                else
                                    evtData.damage = 0
                                end
                            end
                        )
                    end,
                    function()
                    end,
                    "ReplaceableTextures\\zhuangbei\\INV_WEAPON_HAND_08.blp",
                    "只会受到暴击伤害，且暴击伤害不会超过1000点",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE,
                    false
                )
                hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                requiredData.guaiwu = tmpUnit
                return requiredData
            end,
            isActive = false,
            finishCheck = function(requiredData, whichUnit)
                if hunit.isDead(requiredData.guaiwu) or hunit.isDestroyed(requiredData.guaiwu) then
                    return true
                else
                    return false
                end
            end,
            finish = function(requiredData, whichUnit)
                hxunlian.tryShengji("中级会心训练", hunit.getOwner(whichUnit))
            end,
            timeout = 60,
            timeoutAction = function(requiredData, whichUnit)
                hquestcustom.enqueue_dialog(
                    hunit.getOwner(whichUnit),
                    "老兵格雷戈",
                    "如果输出不够，可以通过升级，提升装备，获取图鉴，专业强化物品如炼金药水，锻造磨刀石等提升实力."
                )
            end,
            failAction = function(requiredData, whichUnit)
            end
        },
        {
            name = "初级速度训练",
            place = "荣誉竞技场",
            npcName = "王城总教头",
            art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_HAND_08.blp",
            tips = "进行初级速度训练，需要在规定时间内击败木桩。木桩每次受到伤害最大值为200。",
            cost = { { type = HSHOP_COST_TYPE.gold, value = 500 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, shengwangname = "王城", value = 0 } },
            preStartCheck = function(whichUnit)
            end,
            start = function(whichUnit, rect)
                local whichPlayer = hunit.getOwner(whichUnit)
                local xunlianLevel = hxunlian.getXunlianLevel("初级速度训练", whichPlayer)
                if xunlianLevel == nil then
                    err("xunlianLevel is nil")
                    return false
                end
                hquestcustom.enqueue_dialog(whichPlayer, "王城总教头", "请在60秒内消灭木桩.")
                local requiredData = {}
                local tmpAttr =
                    hunit.getAttributeBasedOnOptions(
                        {
                            level = xunlianLevel + 20,
                            attackSpace = 1,
                            guaiwuType = MONSTER_TYPE.YEWAI_BOSS
                        }
                    )
                local ai =
                    UnitAI(
                        {
                            {
                                aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                atData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                }
                            }
                        }
                    )
                local tmpUnit =
                    henemy.create(
                        {
                            id = hslk.n2i("挨打的木桩"),
                            x = hrect.getX(rect) + 400,
                            y = hrect.getY(rect),
                            facing = 180,
                            attr = tmpAttr,
                            AI = table.clone(ai)
                        }
                    )
                hattribute.set(tmpUnit, 0, { life = "=" .. tostring(xunlianLevel * 1000 + 11000) })
                hattribute.set(tmpUnit, 0, { life_back = "+" .. tostring(50 + 10 * xunlianLevel) })
                hbuff.update(
                    0,
                    tmpUnit,
                    "final_damage_reduction",
                    true,
                    function()
                        hevent.register(
                            tmpUnit,
                            CONST_EVENT.damagingCustomTarget,
                            "攻击速度训练单位buff",
                            function(evtData)
                                evtData.damage = math.min(200, evtData.damage)
                            end
                        )
                    end,
                    function()
                    end,
                    "ReplaceableTextures\\zhuangbei\\INV_WEAPON_HAND_08.blp",
                    "单次受到伤害最大值不会超过200点",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE,
                    false
                )
                hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                requiredData.guaiwu = tmpUnit
                return requiredData
            end,
            isActive = false,
            finishCheck = function(requiredData, whichUnit)
                if hunit.isDead(requiredData.guaiwu) or hunit.isDestroyed(requiredData.guaiwu) then
                    return true
                else
                    return false
                end
            end,
            finish = function(requiredData, whichUnit)
                hxunlian.tryShengji("初级速度训练", hunit.getOwner(whichUnit))
            end,
            timeout = 60,
            timeoutAction = function(requiredData, whichUnit)
                hquestcustom.enqueue_dialog(
                    hunit.getOwner(whichUnit),
                    "王城总教头",
                    "如果输出不够，可以通过升级，提升装备，获取图鉴，专业强化物品如炼金药水，锻造磨刀石等提升实力."
                )
            end,
            failAction = function(requiredData, whichUnit)
            end
        },
        {
            name = "中级速度训练",
            place = "荣誉竞技场",
            npcName = "老兵格雷戈",
            art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_HAND_08.blp",
            tips = "进行中级速度训练，需要在规定时间内击败木桩。木桩每次受到伤害最大值为200。",
            cost = { { type = HSHOP_COST_TYPE.gold, value = 1000 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, shengwangname = "峡谷前哨站", value = 0 } },
            preStartCheck = function(whichUnit)
            end,
            start = function(whichUnit, rect)
                local whichPlayer = hunit.getOwner(whichUnit)
                local xunlianLevel = hxunlian.getXunlianLevel("中级速度训练", whichPlayer)
                if xunlianLevel == nil then
                    err("xunlianLevel is nil")
                    return false
                end
                hquestcustom.enqueue_dialog(whichPlayer, "老兵格雷戈", "请在60秒内消灭木桩.")
                local requiredData = {}
                local tmpAttr =
                    hunit.getAttributeBasedOnOptions(
                        {
                            level = xunlianLevel + 40,
                            attackSpace = 1,
                            guaiwuType = MONSTER_TYPE.YEWAI_BOSS
                        }
                    )
                local ai =
                    UnitAI(
                        {
                            {
                                aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                atData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                }
                            }
                        }
                    )
                local tmpUnit =
                    henemy.create(
                        {
                            id = hslk.n2i("挨打的木桩"),
                            x = hrect.getX(rect) + 400,
                            y = hrect.getY(rect),
                            facing = 180,
                            attr = tmpAttr,
                            AI = table.clone(ai)
                        }
                    )
                hattribute.set(tmpUnit, 0, { life = "=" .. tostring(xunlianLevel * 3000 + 31000) })
                hbuff.update(
                    0,
                    tmpUnit,
                    "final_damage_reduction",
                    true,
                    function()
                        hevent.register(
                            tmpUnit,
                            CONST_EVENT.damagingCustomTarget,
                            "攻击速度训练单位buff",
                            function(evtData)
                                evtData.damage = math.min(200, evtData.damage)
                            end
                        )
                    end,
                    function()
                    end,
                    "ReplaceableTextures\\zhuangbei\\INV_WEAPON_HAND_08.blp",
                    "单次受到伤害最大值不会超过200点",
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE,
                    false
                )
                hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                requiredData.guaiwu = tmpUnit
                return requiredData
            end,
            isActive = false,
            finishCheck = function(requiredData, whichUnit)
                if hunit.isDead(requiredData.guaiwu) or hunit.isDestroyed(requiredData.guaiwu) then
                    return true
                else
                    return false
                end
            end,
            finish = function(requiredData, whichUnit)
                hxunlian.tryShengji("中级速度训练", hunit.getOwner(whichUnit))
            end,
            timeout = 60,
            timeoutAction = function(requiredData, whichUnit)
                hquestcustom.enqueue_dialog(
                    hunit.getOwner(whichUnit),
                    "老兵格雷戈",
                    "如果输出不够，可以通过升级，提升装备，获取图鉴，专业强化物品如炼金药水，锻造磨刀石等提升实力."
                )
            end,
            failAction = function(requiredData, whichUnit)
            end
        },
        {
            name = "初级皇家挑战",
            place = "荣誉竞技场",
            npcName = "王城总教头",
            art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_HAND_08.blp",
            tips = "王城最著名的试炼，适合任何想挑战极限的勇者们。需要在60秒内击击败所有王城勇士。",
            cost = { { type = HSHOP_COST_TYPE.gold, value = 1000 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, shengwangname = "王城", value = 0 } },
            preStartCheck = function(whichUnit)
                if hunit.getLevel(whichUnit) < 30 then
                    echo("等级不足30级，无法挑战", hunit.getOwner(whichUnit))
                    return false
                end
            end,
            start = function(whichUnit, rect)
                local whichPlayer = hunit.getOwner(whichUnit)
                local xunlianLevel = hxunlian.getXunlianLevel("初级皇家挑战", whichPlayer)
                if xunlianLevel == nil then
                    err("xunlianLevel is nil")
                    return false
                end
                hquestcustom.enqueue_dialog(whichPlayer, "王城总教头", "请在60秒内击击败所有王城勇士。")
                local requiredData = {}
                local guaiwu = {}
                for i = 1, 3, 1 do
                    local tmpAttr =
                        hunit.getAttributeBasedOnOptions(
                            {
                                level = xunlianLevel + 30,
                                attackSpace = 1,
                                guaiwuType = MONSTER_TYPE.YEWAI_BOSS
                            }
                        )
                    local ai =
                        UnitAI(
                            {
                                {
                                    aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                    atData = {
                                        targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                    }
                                }
                            }
                        )
                    local tmpUnit =
                        henemy.create(
                            {
                                id = hslk.n2i("试炼近卫军"),
                                x = hrect.getX(rect) + math.random(400, 600),
                                y = hrect.getY(rect),
                                facing = 180,
                                attr = tmpAttr,
                                AI = table.clone(ai)
                            }
                        )
                    hattribute.set(tmpUnit, 0, { life = "=" .. tostring(xunlianLevel * 1000 + 5000) })
                    hattribute.set(tmpUnit, 0, { life_back = "+" .. tostring(100 + 15 * xunlianLevel) })
                    hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                    table.insert(guaiwu, tmpUnit)
                end
                requiredData.guaiwu = guaiwu
                return requiredData
            end,
            isActive = false,
            finishCheck = function(requiredData, whichUnit)
                for _, guaiwu in ipairs(requiredData.guaiwu) do
                    if hunit.isAlive(guaiwu) then
                        return false
                    end
                end
                return true
            end,
            finish = function(requiredData, whichUnit)
                hxunlian.tryShengji("初级皇家挑战", hunit.getOwner(whichUnit))
            end,
            timeout = 60,
            timeoutAction = function(requiredData, whichUnit)
                hquestcustom.enqueue_dialog(
                    hunit.getOwner(whichUnit),
                    "王城总教头",
                    "如果输出不够，可以通过升级，提升装备，获取图鉴，专业强化物品如炼金药水，锻造磨刀石等提升实力。"
                )
            end,
            failAction = function(requiredData, whichUnit)
            end
        },
        {
            name = "专家级属性训练",
            place = "荣誉竞技场",
            npcName = "护卫队长彼得",
            art = "ReplaceableTextures\\BTNzb71.blp",
            tips = "进行专家级属性训练，需要在规定时间内击败木桩。请在具有一定的伤害能力之后再来挑战。",
            cost = { { type = HSHOP_COST_TYPE.gold, value = 5000 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, shengwangname = "和平之城", value = 1 } },
            preStartCheck = function(whichUnit)
            end,
            start = function(whichUnit, rect)
                local whichPlayer = hunit.getOwner(whichUnit)
                local xunlianLevel = hxunlian.getXunlianLevel("专家级属性训练", whichPlayer)
                if xunlianLevel == nil then
                    err("xunlianLevel is nil")
                    return false
                end
                hquestcustom.enqueue_dialog(whichPlayer, "护卫队长彼得", "请在60秒内消灭木桩.")
                local requiredData = {}
                local tmpAttr =
                    hunit.getAttributeBasedOnOptions(
                        {
                            level = 70,
                            attackSpace = 1,
                            guaiwuType = MONSTER_TYPE.YEWAI_BOSS
                        }
                    )
                local ai =
                    UnitAI(
                        {
                            {
                                aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                atData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                }
                            }
                        }
                    )
                local tmpUnit =
                    henemy.create(
                        {
                            id = hslk.n2i("挨打的木桩"),
                            x = hrect.getX(rect) + 400,
                            y = hrect.getY(rect),
                            facing = 180,
                            attr = tmpAttr,
                            AI = table.clone(ai)
                        }
                    )
                hattribute.set(tmpUnit, 0, { life = "+" .. tostring((6000 + 5000 * xunlianLevel) * 60) })
                hattribute.set(tmpUnit, 0, { attack_white = "0", defend_white = "=621", mojia = "=621", shanbi = "+10" })
                hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                requiredData.guaiwu = tmpUnit
                return requiredData
            end,
            isActive = false,
            finishCheck = function(requiredData, whichUnit)
                if hunit.isDead(requiredData.guaiwu) or hunit.isDestroyed(requiredData.guaiwu) then
                    return true
                else
                    return false
                end
            end,
            finish = function(requiredData, whichUnit)
                hxunlian.tryShengji("专家级属性训练", hunit.getOwner(whichUnit))
            end,
            timeout = 60,
            timeoutAction = function(requiredData, whichUnit)
                hquestcustom.enqueue_dialog(
                    hunit.getOwner(whichUnit),
                    "护卫队长彼得",
                    "如果输出不够，可以通过升级，提升装备，获取图鉴，专业强化物品如炼金药水，锻造磨刀石等提升实力."
                )
            end,
            failAction = function(requiredData, whichUnit)
            end
        },
        {
            name = "初级耐久训练",
            place = "荣誉竞技场",
            npcName = "新手教官",
            art = "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpOne.blp",
            tips = "进行初级耐久训练，需要在加特林教习的进攻下坚持30秒。请在具有一定的防御能力之后再来挑战。",
            cost = { { type = HSHOP_COST_TYPE.gold, value = 100 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, shengwangname = "新手村", value = 0 } },
            preStartCheck = function(whichUnit)
            end,
            start = function(whichUnit, rect)
                local whichPlayer = hunit.getOwner(whichUnit)
                local xunlianLevel = hxunlian.getXunlianLevel("初级耐久训练", whichPlayer)
                if xunlianLevel == nil then
                    err("xunlianLevel is nil")
                    return false
                end
                hquestcustom.enqueue_dialog(whichPlayer, "新手教官", "请在加特林教习的进攻下坚持30秒。")
                local requiredData = {}
                local tmpAttr =
                    hunit.getAttributeBasedOnOptions(
                        {
                            level = math.min(20, xunlianLevel + 1),
                            attackSpace = 1,
                            guaiwuType = MONSTER_TYPE.YEWAI_BOSS
                        }
                    )
                local ai =
                    UnitAI(
                        {
                            {
                                aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                atData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                }
                            }
                        }
                    )
                local tmpUnit =
                    henemy.create(
                        {
                            id = hslk.n2i("加特林教习"),
                            x = hrect.getX(rect) + 400,
                            y = hrect.getY(rect),
                            facing = 180,
                            attr = tmpAttr,
                            AI = table.clone(ai)
                        }
                    )
                hevent.register(
                    tmpUnit,
                    CONST_EVENT.damagingCustomTarget,
                    "耐久训练",
                    function(evtData)
                        evtData.damage = 0
                    end
                )
                hattribute.set(tmpUnit, 0,
                    {
                        attack_white = "=" .. tostring(10 + 5 * xunlianLevel),
                        hit = "=100"
                    })
                hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                requiredData.guaiwu = tmpUnit
                return requiredData
            end,
            isActive = false,
            finishCheck = function(requiredData, whichUnit)
                if hunit.isDead(requiredData.guaiwu) or hunit.isDestroyed(requiredData.guaiwu) then
                    return true
                else
                    return false
                end
            end,
            finish = function(requiredData, whichUnit)
            end,
            timeout = 30,
            timeoutAction = function(requiredData, whichUnit)
                hxunlian.tryShengji("初级耐久训练", hunit.getOwner(whichUnit))
            end,
            failAction = function(requiredData, whichUnit)
                hquestcustom.enqueue_dialog(
                    hunit.getOwner(whichUnit),
                    "新手教官",
                    "如果坚持不了那么长时间，可以考虑使用生命恢复药剂，或者以后变强大了再回来挑战"
                )
            end
        },
        {
            name = "中级耐久训练",
            place = "荣誉竞技场",
            npcName = "王城总教头",
            art = "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpOne.blp",
            tips = "进行初级耐久训练，需要在加特林教习的进攻下坚持30秒。请在具有一定的防御能力之后再来挑战。",
            cost = { { type = HSHOP_COST_TYPE.gold, value = 500 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, shengwangname = "王城", value = 0 } },
            preStartCheck = function(whichUnit)
            end,
            start = function(whichUnit, rect)
                local whichPlayer = hunit.getOwner(whichUnit)
                local xunlianLevel = hxunlian.getXunlianLevel("中级耐久训练", whichPlayer)
                if xunlianLevel == nil then
                    err("xunlianLevel is nil")
                    return false
                end
                hquestcustom.enqueue_dialog(whichPlayer, "王城总教头", "请在加特林教习的进攻下坚持30秒。")
                local requiredData = {}
                local tmpAttr =
                    hunit.getAttributeBasedOnOptions(
                        {
                            level = math.min(45, xunlianLevel + 31),
                            attackSpace = 1,
                            guaiwuType = MONSTER_TYPE.YEWAI_BOSS
                        }
                    )
                local ai =
                    UnitAI(
                        {
                            {
                                aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                atData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                }
                            }
                        }
                    )
                local tmpUnit =
                    henemy.create(
                        {
                            id = hslk.n2i("加特林教习"),
                            x = hrect.getX(rect) + 400,
                            y = hrect.getY(rect),
                            facing = 180,
                            attr = tmpAttr,
                            AI = table.clone(ai)
                        }
                    )
                hevent.register(
                    tmpUnit,
                    CONST_EVENT.damagingCustomTarget,
                    "耐久训练",
                    function(evtData)
                        evtData.damage = 0
                    end
                )
                hattribute.set(tmpUnit, 0,
                    {
                        attack_white = "=" .. tostring(110 + 100 * xunlianLevel),
                        hit = "=100"
                    })
                hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                requiredData.guaiwu = tmpUnit
                return requiredData
            end,
            isActive = false,
            finishCheck = function(requiredData, whichUnit)
                if hunit.isDead(requiredData.guaiwu) or hunit.isDestroyed(requiredData.guaiwu) then
                    return true
                else
                    return false
                end
            end,
            finish = function(requiredData, whichUnit)
            end,
            timeout = 30,
            timeoutAction = function(requiredData, whichUnit)
                hxunlian.tryShengji("中级耐久训练", hunit.getOwner(whichUnit))
            end,
            failAction = function(requiredData, whichUnit)
                hquestcustom.enqueue_dialog(
                    hunit.getOwner(whichUnit),
                    "王城总教头",
                    "如果坚持不了那么长时间，可以考虑使用生命恢复药剂，或者以后变强大了再回来挑战"
                )
            end
        },
        {
            name = "高级耐久训练",
            place = "荣誉竞技场",
            npcName = "老兵格雷戈",
            art = "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpTwo.blp",
            tips = "进行初级耐久训练，需要在加特林教习的进攻下坚持30秒。请在具有一定的防御能力之后再来挑战。",
            cost = { { type = HSHOP_COST_TYPE.gold, value = 1500 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, shengwangname = "峡谷前哨站", value = 0 } },
            preStartCheck = function(whichUnit)
            end,
            start = function(whichUnit, rect)
                local whichPlayer = hunit.getOwner(whichUnit)
                local xunlianLevel = hxunlian.getXunlianLevel("高级耐久训练", whichPlayer)
                if xunlianLevel == nil then
                    err("xunlianLevel is nil")
                    return false
                end
                hquestcustom.enqueue_dialog(whichPlayer, "老兵格雷戈", "请在加特林教习的进攻下坚持30秒。")
                local requiredData = {}
                local tmpAttr =
                    hunit.getAttributeBasedOnOptions(
                        {
                            level = math.min(60, xunlianLevel + 51),
                            attackSpace = 1,
                            guaiwuType = MONSTER_TYPE.YEWAI_BOSS
                        }
                    )
                local ai =
                    UnitAI(
                        {
                            {
                                aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                atData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                }
                            }
                        }
                    )
                local tmpUnit =
                    henemy.create(
                        {
                            id = hslk.n2i("加特林教习"),
                            x = hrect.getX(rect) + 400,
                            y = hrect.getY(rect),
                            facing = 180,
                            attr = tmpAttr,
                            AI = table.clone(ai)
                        }
                    )
                hevent.register(
                    tmpUnit,
                    CONST_EVENT.damagingCustomTarget,
                    "耐久训练",
                    function(evtData)
                        evtData.damage = 0
                    end
                )
                hattribute.set(tmpUnit, 0,
                    {
                        attack_white = "=" .. tostring(1110 + 300 * xunlianLevel),
                        hit = "=100"
                    })
                hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                requiredData.guaiwu = tmpUnit
                return requiredData
            end,
            isActive = false,
            finishCheck = function(requiredData, whichUnit)
                if hunit.isDead(requiredData.guaiwu) or hunit.isDestroyed(requiredData.guaiwu) then
                    return true
                else
                    return false
                end
            end,
            finish = function(requiredData, whichUnit)
            end,
            timeout = 30,
            timeoutAction = function(requiredData, whichUnit)
                hxunlian.tryShengji("高级耐久训练", hunit.getOwner(whichUnit))
            end,
            failAction = function(requiredData, whichUnit)
                hquestcustom.enqueue_dialog(
                    hunit.getOwner(whichUnit),
                    "老兵格雷戈",
                    "如果坚持不了那么长时间，可以考虑使用生命恢复药剂，或者以后变强大了再回来挑战"
                )
            end
        },
        {
            name = "专家级耐久训练",
            place = "荣誉竞技场",
            npcName = "护卫队长彼得",
            art = "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpTwo.blp",
            tips = "进行初级耐久训练，需要在加特林教习的进攻下坚持30秒。请在具有一定的防御能力之后再来挑战。",
            cost = { { type = HSHOP_COST_TYPE.gold, value = 5000 } },
            requirement = { { type = HSHOP_REQUIREMENT_TYPE.shengwang, shengwangname = "和平之城", value = 0 } },
            preStartCheck = function(whichUnit)
            end,
            start = function(whichUnit, rect)
                local whichPlayer = hunit.getOwner(whichUnit)
                local xunlianLevel = hxunlian.getXunlianLevel("专家级耐久训练", whichPlayer)
                if xunlianLevel == nil then
                    err("xunlianLevel is nil")
                    return false
                end
                hquestcustom.enqueue_dialog(whichPlayer, "护卫队长彼得", "请在加特林教习的进攻下坚持30秒。")
                local requiredData = {}
                local tmpAttr =
                    hunit.getAttributeBasedOnOptions(
                        {
                            level = math.min(70, math.floor(xunlianLevel / 3) + 60),
                            attackSpace = 1,
                            guaiwuType = MONSTER_TYPE.YEWAI_BOSS
                        }
                    )
                local ai =
                    UnitAI(
                        {
                            {
                                aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                atData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                }
                            }
                        }
                    )
                local tmpUnit =
                    henemy.create(
                        {
                            id = hslk.n2i("加特林教习"),
                            x = hrect.getX(rect) + 400,
                            y = hrect.getY(rect),
                            facing = 180,
                            attr = tmpAttr,
                            AI = table.clone(ai)
                        }
                    )
                hevent.register(
                    tmpUnit,
                    CONST_EVENT.damagingCustomTarget,
                    "耐久训练",
                    function(evtData)
                        evtData.damage = 0
                    end
                )
                hattribute.set(tmpUnit, 0,
                    {
                        attack_white = "=" .. tostring(5110 + 1000 * xunlianLevel),
                        hit = "=100"
                    })
                hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
                requiredData.guaiwu = tmpUnit
                return requiredData
            end,
            isActive = false,
            finishCheck = function(requiredData, whichUnit)
                if hunit.isDead(requiredData.guaiwu) or hunit.isDestroyed(requiredData.guaiwu) then
                    return true
                else
                    return false
                end
            end,
            finish = function(requiredData, whichUnit)
            end,
            timeout = 30,
            timeoutAction = function(requiredData, whichUnit)
                hxunlian.tryShengji("专家级耐久训练", hunit.getOwner(whichUnit))
            end,
            failAction = function(requiredData, whichUnit)
                hquestcustom.enqueue_dialog(
                    hunit.getOwner(whichUnit),
                    "护卫队长彼得",
                    "如果坚持不了那么长时间，可以考虑使用生命恢复药剂，或者以后变强大了再回来挑战"
                )
            end
        }
    }

    local areaConfig = {
        {
            name = "荣誉竞技场",
            minX = -3473,
            minY = 5370,
            maxX = -733,
            maxY = 7722,
            blp = "ReplaceableTextures\\xiaoditu\\UI_map_12.blp",
            titleArt = "ReplaceableTextures\\xitong\\ui_map_show_14.blp"
        }
    }
    htiaozhan.init(config, areaConfig)
end
