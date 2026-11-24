function initFuMo()
    local fangju = { "衣服", "头盔", "披风", "手套", "鞋子" }
    local wuqishoushi = { "双手剑", "单手剑", "双手斧", "单手斧", "双手锤", "单手锤", "匕首", "拳套", "法杖", "戒指", "项链", "饰品" }
    local wuqi = { "双手剑", "单手剑", "双手斧", "单手斧", "双手锤", "单手锤", "匕首", "拳套", "法杖", "弓", "法剑" }

    local config = {
        {
            reqLevel = 0,
            req = {
                { name = "白纸", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "附魔羊皮纸",
                itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 0,
            req = {
                { name = "初级微光之尘", count = 20 },
                { name = "初级微光精华", count = 2 },
                { name = "附魔羊皮纸", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "初级主属性",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 0,
            req = {
                { name = "初级微光之尘", count = 20 },
                { name = "初级微光精华", count = 2 },
                { name = "附魔羊皮纸", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "初级攻击强度",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 0,
            req = {
                { name = "初级微光之尘", count = 20 },
                { name = "初级微光精华", count = 2 },
                { name = "附魔羊皮纸", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "初级攻击速度",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 0,
            req = {
                { name = "初级微光之尘", count = 20 },
                { name = "初级微光精华", count = 2 },
                { name = "附魔羊皮纸", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "初级技能速度",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 0,
            req = {
                { name = "初级微光之尘", count = 20 },
                { name = "初级微光精华", count = 2 },
                { name = "附魔羊皮纸", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "初级闪避",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 0,
            req = {
                { name = "初级微光之尘", count = 20 },
                { name = "初级微光精华", count = 2 },
                { name = "附魔羊皮纸", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "初级格挡",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 0,
            req = {
                { name = "初级微光之尘", count = 20 },
                { name = "初级微光精华", count = 2 },
                { name = "附魔羊皮纸", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "初级招架",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 0,
            req = {
                { name = "初级微光之尘", count = 30 }
            },
            successRate = 10000,
            output = {
                name = "初级微光精华",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 1,
            req = {
                { name = "初级微光之尘", count = 40 },
                { name = "初级微光精华", count = 5 },
                { name = "附魔羊皮纸", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "灼热",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 1,
            req = {
                { name = "初级微光之尘", count = 50 },
                { name = "初级微光精华", count = 10 },
                { name = "附魔羊皮纸", count = 1 },
                { name = "魔法水晶", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "狂暴",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 1,
            req = {
                { name = "初级微光之尘", count = 50 },
                { name = "初级微光精华", count = 10 },
                { name = "附魔羊皮纸", count = 1 },
                { name = "魔法水晶", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "能量洪流",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 1,
            req = {
                { name = "中级微光之尘", count = 20 },
                { name = "中级微光精华", count = 2 },
                { name = "附魔羊皮纸", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "中级闪避",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 1,
            req = {
                { name = "中级微光之尘", count = 20 },
                { name = "中级微光精华", count = 2 },
                { name = "附魔羊皮纸", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "中级格挡",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 1,
            req = {
                { name = "中级微光之尘", count = 20 },
                { name = "中级微光精华", count = 2 },
                { name = "附魔羊皮纸", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "中级招架",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 1,
            req = {
                { name = "中级微光之尘", count = 20 },
                { name = "中级微光精华", count = 2 },
                { name = "附魔羊皮纸", count = 1 },
                { name = "人马图腾", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "初级防具属性",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 3,
            req = {
                { name = "高级微光之尘", count = 20 },
                { name = "高级微光精华", count = 2 },
                { name = "附魔羊皮纸", count = 1 },
                { name = "守护者的宝石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "猫鼬",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "高级微光之尘", count = 20 },
                { name = "高级微光精华", count = 2 },
                { name = "附魔羊皮纸", count = 1 },
                { name = "守护者的宝石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "斩灭",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "高级微光之尘", count = 20 },
                { name = "高级微光精华", count = 2 },
                { name = "附魔羊皮纸", count = 1 },
                { name = "守护者的宝石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "野蛮",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "高级微光之尘", count = 20 },
                { name = "高级微光精华", count = 2 },
                { name = "附魔羊皮纸", count = 1 },
                { name = "守护者的宝石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "魂霜",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 0,
            req = {
                { name = "高级微光精华", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "中级微光精华",
                count = 10
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 0,
            req = {
                { name = "中级微光精华", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "初级微光精华",
                count = 10
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 0,
            req = {
                { name = "初级微光精华", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "初级微光之尘",
                count = 5
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 0,
            req = {
                { name = "高级微光精华", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "高级微光之尘",
                count = 5
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 0,
            req = {
                { name = "中级微光精华", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "中级微光之尘",
                count = 5
            },
            zhizuoExp = 1
        },
    }
    local fumoConfig = {
        {
            name = "灼热",
            itemCunDangStr = "1",
            attr = _attr({ zhushuxing = "+10" }),
            _skillEffect = {
                {
                    description = "攻击有10%概率对目标造成主属性50%的火焰魔法伤害",
                    attr_type = CONST_EVENT.attack,
                    attr = function(evtData)
                        if math.random(1, 100) <= 15 then
                            local primary = hhero.getPrimary(evtData.triggerUnit)
                            local primaryAttributeName = string.lower(primary) .. "_white"
                            hskill.damage(
                                {
                                    sourceUnit = evtData.triggerUnit,
                                    targetUnit = evtData.targetUnit,
                                    damage = hattribute.getWithLimit(evtData.triggerUnit, nil, primaryAttributeName) *
                                        0.5,
                                    effect = "war3mapImported\\AZ_Misslie06.MDX",
                                    damageSrc = CONST_DAMAGE_SRC.item,
                                    damageType = DAMAGE_TYPE.MOFA,
                                    triggerSkill = hslk.n2i("装备技能"),
                                    damageElementType = CONST_DAMAGE_ELEMENT_TYPE.FIRE,
                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                    shanghainame = "灼热"
                                }
                            )
                        end
                    end
                }
            },
            zhuangbeiTypes = wuqi
        },
        {
            name = "初级主属性",
            itemCunDangStr = "2",
            attr = _attr({ zhushuxing_baifenbi = "+3" }),
            zhuangbeiTypes = wuqi
        },
        {
            name = "初级攻击强度",
            itemCunDangStr = "3",
            attr = _attr({ gongji_baifenbi = "+3" }),
            zhuangbeiTypes = wuqi
        },
        {
            name = "初级攻击速度",
            itemCunDangStr = "4",
            attr = _attr({ attack_speed = "+4" }),
            zhuangbeiTypes = wuqi
        },
        {
            name = "初级技能速度",
            itemCunDangStr = "5",
            attr = _attr({ skill_speed = "+2" }),
            zhuangbeiTypes = wuqi
        },
        {
            name = "初级闪避",
            itemCunDangStr = "6",
            attr = _attr({ shanbi = "+1" }),
            zhuangbeiTypes = fangju
        },
        {
            name = "初级招架",
            itemCunDangStr = "7",
            attr = _attr({ zhaojia = "+2" }),
            zhuangbeiTypes = fangju
        },
        {
            name = "初级格挡",
            itemCunDangStr = "8",
            attr = _attr({ gedang = "+2" }),
            zhuangbeiTypes = fangju
        },
        {
            name = "狂暴",
            itemCunDangStr = "9",
            --attr = _attr({zhushuxing = "+10"}),
            _skillEffect = {
                {
                    description = "攻击有30%概率获得300点攻击力加成，持续8秒，cd15秒（多个狂暴共享cd）",
                    attr_type = CONST_EVENT.attack,
                    attr = function(evtData)
                        if math.random(1, 100) <= 30 and htime.setupAndCheckCoolDown(evtData.triggerUnit, "狂暴", 15) then
                            local primary = hhero.getPrimary(evtData.triggerUnit)
                            local primaryAttributeName = string.lower(primary) .. "_white"
                            hbuff.update(
                                8,
                                evtData.triggerUnit,
                                "狂暴攻击增幅",
                                true,
                                function()
                                    hattribute.set(evtData.triggerUnit, 0, _attr({ attack = "+300" }))
                                end,
                                function()
                                    hattribute.set(evtData.triggerUnit, 0, _attr({ attack = "-300" }))
                                end,
                                "ReplaceableTextures\\MoreButtons\\KUANGBAO\\PASBTNKUANGBAO.blp",
                                "狂暴|n获得300点攻击力加成",
                                nil,
                                nil,
                                nil,
                                nil,
                                nil,
                                HBUFF_UPDATE_MODE.OVERWRITE,
                                true
                            )
                        end
                    end
                }
            },
            zhuangbeiTypes = wuqi
        },
        {
            name = "能量洪流",
            itemCunDangStr = "a",
            --attr = _attr({zhushuxing = "+10"}),
            _skillEffect = {
                {
                    description = "攻击有30%概率获得200点主属性加成，持续8秒，cd15秒",
                    attr_type = CONST_EVENT.attack,
                    attr = function(evtData)
                        if math.random(1, 100) <= 30 and htime.setupAndCheckCoolDown(evtData.triggerUnit, "能量洪流", 15) then
                            local primary = hhero.getPrimary(evtData.triggerUnit)
                            local primaryAttributeName = string.lower(primary) .. "_white"
                            local addAttr = {}
                            addAttr[primaryAttributeName] = "+200"
                            local minusAttr = {}
                            minusAttr[primaryAttributeName] = "-200"
                            hbuff.update(
                                8,
                                evtData.triggerUnit,
                                "能量洪流主属性增幅",
                                true,
                                function()
                                    hattribute.set(evtData.triggerUnit, 0, addAttr)
                                end,
                                function()
                                    hattribute.set(evtData.triggerUnit, 0, minusAttr)
                                end,
                                "ReplaceableTextures\\BTNAS_BD2.blp",
                                "能量洪流|n获得200点主属性加成",
                                nil,
                                nil,
                                nil,
                                nil,
                                nil,
                                HBUFF_UPDATE_MODE.OVERWRITE,
                                true
                            )
                        end
                    end
                }
            },
            zhuangbeiTypes = wuqi
        },
        {
            name = "中级闪避",
            itemCunDangStr = "b",
            attr = _attr({ shanbi = "+1.5" }),
            zhuangbeiTypes = fangju
        },
        {
            name = "中级招架",
            itemCunDangStr = "c",
            attr = _attr({ zhaojia = "+2.5" }),
            zhuangbeiTypes = fangju
        },
        {
            name = "中级格挡",
            itemCunDangStr = "d",
            attr = _attr({ gedang = "+2.5" }),
            zhuangbeiTypes = fangju
        },
        {
            name = "初级防具属性",
            itemCunDangStr = "e",
            attr = _attr({ zhushuxing_baifenbi = "+1" }),
            zhuangbeiTypes = fangju
        },
        {
            name = "猫鼬",
            itemCunDangStr = "f",
            _skillEffect = {
                {
                    description = "物理伤害的普通攻击时有15%几率使攻击速度提升5%，主属性提高300点。持续8秒，cd15秒（多个狂暴共享cd）",
                    attr_type = CONST_EVENT.attack,
                    attr = function(evtData)
                        if
                            evtData.damageType == DAMAGE_TYPE.WULI and math.random(1, 100) <= 30 and
                            htime.setupAndCheckCoolDown(evtData.triggerUnit, "猫鼬", 15)
                        then
                            hbuff.update(
                                8,
                                evtData.triggerUnit,
                                "猫鼬",
                                true,
                                function()
                                    hattribute.set(
                                        evtData.triggerUnit,
                                        0,
                                        _attr({ attack_speed = "+5", zhushuxing = "+300" })
                                    )
                                end,
                                function()
                                    hattribute.set(
                                        evtData.triggerUnit,
                                        0,
                                        _attr({ attack_speed = "-5", zhushuxing = "-300" })
                                    )
                                end,
                                "ReplaceableTextures\\MoreButtons\\KUANGBAO\\PASBTNKUANGBAO.blp",
                                "猫鼬|n攻击速度提升5%，主属性提高300点",
                                nil,
                                nil,
                                nil,
                                nil,
                                nil,
                                HBUFF_UPDATE_MODE.OVERWRITE,
                                true
                            )
                        end
                    end
                }
            },
            zhuangbeiTypes = wuqi
        },
        {
            name = "斩灭",
            itemCunDangStr = "g",
            _skillEffect = {
                {
                    description = "物理伤害的普通攻击时有30%几率提升10%物理穿透。持续8秒，cd30秒（多个斩灭共享cd）",
                    attr_type = CONST_EVENT.attack,
                    attr = function(evtData)
                        if
                            evtData.damageType == DAMAGE_TYPE.WULI and math.random(1, 100) <= 30 and
                            htime.setupAndCheckCoolDown(evtData.triggerUnit, "斩灭", 30)
                        then
                            hbuff.update(
                                8,
                                evtData.triggerUnit,
                                "斩灭",
                                true,
                                function()
                                    hattribute.set(evtData.triggerUnit, 0, _attr({ wu_chuan = "+10" }))
                                end,
                                function()
                                    hattribute.set(evtData.triggerUnit, 0, _attr({ wu_chuan = "-10" }))
                                end,
                                "ReplaceableTextures\\MoreButtons\\KUANGBAO\\PASBTNKUANGBAO.blp",
                                "斩灭|n提升10%物理穿透",
                                nil,
                                nil,
                                nil,
                                nil,
                                nil,
                                HBUFF_UPDATE_MODE.OVERWRITE,
                                true
                            )
                        end
                    end
                }
            },
            zhuangbeiTypes = wuqi
        },
        {
            name = "野蛮",
            itemCunDangStr = "h",
            attr = _attr({ gongji_baifenbi = "+4" }),
            zhuangbeiTypes = wuqi
        },
        {
            name = "魂霜",
            itemCunDangStr = "i",
            _skillEffect = {
                {
                    description = "魂霜，造成魔法伤害有50%的概率对目标发射一枚寒冰箭，造成100%主属性的冰系魔法伤害，该效果具有3秒的触发CD。",
                    attr_type = CONST_EVENT.damage,
                    attr = function(evtData)
                        if
                            evtData.damageType == DAMAGE_TYPE.MOFA and math.random(1, 100) <= 50 and
                            htime.setupAndCheckCoolDown(evtData.triggerUnit, "魂霜", 3)
                        then
                            local sourceUnit = evtData.triggerUnit
                            local targetUnit = evtData.targetUnit
                            hskillMoban.missile(
                                {
                                    model = "Abilities\\Weapons\\LichMissile\\LichMissile.mdl",
                                    scale = 1.0,
                                    speed = 1000,
                                    hover = 50,
                                    sourceUnit = sourceUnit,
                                    targetUnit = targetUnit,
                                    target_face_dis = 50,
                                    onEnd = function(_, _, endX, endY)
                                        local primaryAttribute = hunit.getZhushuxing(sourceUnit)
                                        hskill.damage(
                                            {
                                                sourceUnit = sourceUnit,
                                                targetUnit = targetUnit,
                                                damage = primaryAttribute,
                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                damageType = DAMAGE_TYPE.MOFA,
                                                triggerSkill = hslk.n2i("装备技能"),
                                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WATER },
                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                                shanghainame = "魂霜"
                                            }
                                        )
                                    end
                                }
                            )
                        end
                    end
                }
            },
            zhuangbeiTypes = wuqi
        }
    }

    local fenjieConfig = {}
    fenjieConfig[ZHUANGBEI_PINZHI.PUTONG] = {
        {
            minItemLevel = 1,
            maxItemLevel = 29,
            output = { { name = "初级微光之尘", weight = 500 } },
            zhuanyeLevel = 0,
            zhuanyeExpRate = 2000
        },
        {
            minItemLevel = 30,
            maxItemLevel = 50,
            output = { { name = "初级微光之尘", weight = 300 } },
            zhuanyeLevel = 1,
            zhuanyeExpRate = 2000
        },
        {
            minItemLevel = 51,
            maxItemLevel = 60,
            output = { { name = "中级微光之尘", weight = 1000 } },
            zhuanyeLevel = 2,
            zhuanyeExpRate = 2000
        },
        {
            minItemLevel = 61,
            maxItemLevel = 74,
            output = { { name = "高级微光之尘", weight = 1000 } },
            zhuanyeLevel = 3,
            zhuanyeExpRate = 2000
        }
    }
    fenjieConfig[ZHUANGBEI_PINZHI.JINGLIANG] = {
        {
            minItemLevel = 1,
            maxItemLevel = 29,
            output = { { name = "初级微光之尘", weight = 200 }, { name = "初级微光精华", rate = 100 } },
            zhuanyeLevel = 0,
            zhuanyeExpRate = 3000
        },
        {
            minItemLevel = 30,
            maxItemLevel = 50,
            output = { { name = "初级微光之尘", weight = 200 }, { name = "初级微光精华", rate = 100 } },
            zhuanyeLevel = 1,
            zhuanyeExpRate = 3000
        },
        {
            minItemLevel = 51,
            maxItemLevel = 60,
            output = { { name = "中级微光之尘", weight = 200 }, { name = "中级微光精华", rate = 100 } },
            zhuanyeLevel = 2,
            zhuanyeExpRate = 3000
        },
        {
            minItemLevel = 61,
            maxItemLevel = 74,
            output = { { name = "高级微光之尘", weight = 200 }, { name = "高级微光精华", rate = 100 } },
            zhuanyeLevel = 3,
            zhuanyeExpRate = 3000
        }
    }
    fenjieConfig[ZHUANGBEI_PINZHI.SHISHI] = {
        {
            minItemLevel = 1,
            maxItemLevel = 29,
            output = { { name = "初级微光精华", rate = 100 } },
            zhuanyeLevel = 0,
            zhuanyeExpRate = 10000
        },
        {
            minItemLevel = 30,
            maxItemLevel = 50,
            output = { { name = "初级微光精华", rate = 100 } },
            zhuanyeLevel = 1,
            zhuanyeExpRate = 10000
        },
        {
            minItemLevel = 51,
            maxItemLevel = 60,
            output = { { name = "中级微光精华", rate = 100 } },
            zhuanyeLevel = 2,
            zhuanyeExpRate = 10000
        },
        {
            minItemLevel = 61,
            maxItemLevel = 74,
            output = { { name = "高级微光精华", rate = 100 } },
            zhuanyeLevel = 3,
            zhuanyeExpRate = 10000
        }
    }
    fenjieConfig[ZHUANGBEI_PINZHI.CHUANQI] = {
        {
            minItemLevel = 1,
            maxItemLevel = 29,
            output = { { name = "初级微光精华", rate = 10 } },
            zhuanyeLevel = 0,
            zhuanyeExpRate = 10000
        },
        {
            minItemLevel = 30,
            maxItemLevel = 50,
            output = { { name = "初级微光精华", rate = 10 } },
            zhuanyeLevel = 1,
            zhuanyeExpRate = 10000
        },
        {
            minItemLevel = 51,
            maxItemLevel = 60,
            output = { { name = "中级微光精华", rate = 100 } },
            zhuanyeLevel = 2,
            zhuanyeExpRate = 10000
        },
        {
            minItemLevel = 61,
            maxItemLevel = 74,
            output = { { name = "高级微光精华", rate = 100 } },
            zhuanyeLevel = 3,
            zhuanyeExpRate = 10000
        }
    }
    fenjieConfig[ZHUANGBEI_PINZHI.SHENHUA] = {
        {
            minItemLevel = 1,
            maxItemLevel = 29,
            output = { { name = "初级微光精华", rate = 10 } },
            zhuanyeLevel = 0,
            zhuanyeExpRate = 10000
        },
        {
            minItemLevel = 30,
            maxItemLevel = 50,
            output = { { name = "初级微光精华", rate = 10 } },
            zhuanyeLevel = 1,
            zhuanyeExpRate = 10000
        },
        {
            minItemLevel = 51,
            maxItemLevel = 60,
            output = { { name = "中级微光精华", rate = 100 } },
            zhuanyeLevel = 2,
            zhuanyeExpRate = 10000
        },
        {
            minItemLevel = 61,
            maxItemLevel = 74,
            output = { { name = "高级微光精华", rate = 100 } },
            zhuanyeLevel = 3,
            zhuanyeExpRate = 10000
        }
    }
    hshop.addNormalItem("附魔大师加夫里尔", "白纸", { { type = HSHOP_COST_TYPE.gold, value = 300 } })
    hshop.addNormalItem(
        "铭文大师德拉里", "附魔羊皮纸", { { type = HSHOP_COST_TYPE.gold, value = 2000 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 2, shengwangname = "王城" } }
    )
    hshop.addNormalItem(
        "军需处长谭恩",
        "白纸",
        { { type = HSHOP_COST_TYPE.gold, value = 180 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 3, shengwangname = "王城" } }
    )
    hshop.addItem(
        "附魔大师加夫里尔",
        "去魔",
        "ReplaceableTextures\\fumo\\BTNWarcraft3 Ico.blp",
        { { type = HSHOP_COST_TYPE.gold, value = 5000 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 2, shengwangname = "王城" } },
        "去除物品栏第一格装备的附魔效果，概不退款，误操作也不退",
        function(whichPlayer)
            local whichUnit = hplayer.getMainHero(whichPlayer)
            if whichUnit == nil then
                return
            end
            local item = cj.UnitItemInSlot(whichUnit, 0)
            if item == nil then
                echo("物品栏第一格无物品", whichPlayer)
                return
            end
            local dynamicItem = hitem.getDynamicItem(item)
            local hitem_type = hslk.i2v(dynamicItem.basic_item_id, "hitem_type")
            if hitem_type ~= "装备" then
                echo("第一格物品非装备", whichPlayer)
                return
            end
            if dynamicItem.fumo == nil then
                echo("第一格物品没有附魔", whichPlayer)
                return
            end
            dynamicItem.fumo = nil
            dynamicItem.updateDescription()
            echo("成功去魔", whichPlayer)
        end
    )

    hfumo.init(config, fumoConfig, fenjieConfig)
end
