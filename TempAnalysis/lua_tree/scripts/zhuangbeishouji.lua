function initZhuangbeishouji()
    -- 使用示例

    local function generateEquipmentConfig(name, items, reward, artItem, cdIndex, requiredItemCounts)
        local config = {
            name = name,
            cundangStr = "zhuangbeishouji",
            shoujiType = ZHUANGBEISHOUIJI_TYPE.SANJIANSHOUJI,
            cunDangStartIndex = cdIndex, -- 这个值需要根据实际情况设置
            cunDangEndIndex = cdIndex,   -- 这个值需要根据实际情况设置
            art = hslk.n2v(artItem, "Art"),
            isActive = false,
            effectiveLevel = 1,
            currentLevel = 0,
            data = {}
        }

        local goldCosts = { 1000, 2000, 5000, 10000, 20000, 30000, 30000, 30000 }
        local itemCounts = requiredItemCounts or { 1, 2, 3, 4, 5, 6, 8, 9 }

        for i = 1, 8 do
            local level = {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = goldCosts[i] }
                },
                itemCost = {},
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr(reward)
                    },
                }
            }

            for j, item in ipairs(items) do
                table.insert(level.itemCost, {
                    name = item,
                    count = itemCounts[i],
                    currentCount = 0,
                })
            end

            table.insert(config.data, level)
        end

        return config
    end
    local config = {
        {
            name = "真鳞胸甲",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 1,
            cunDangEndIndex = 1,
            art = hslk.n2v("真鳞胸甲", "Art"),
            isActive = false,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            effectiveLevel = 30,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 10000 }
                },
                itemCost = {
                    { name = "真鳞胸甲", count = 1, qianghua = 8, jinglian = 8, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr(
                            { zhaojia = "+0.5", shanbi = "+0.5", mokang = "+0.5", defend_white = "+10", gedang = "+0.5" }
                        )
                    },
                    {
                        description = "龙力护体，受到伤害有10%概率完全无视该次伤害,并且在之后的5秒内每秒恢复1%的生命最大值，同时提高2%的闪避，招架，减伤和魔抗。CD60秒",
                        type = CONST_EVENT.damagingCustomTarget,
                        action = function(evtData)
                            if math.random(1, 100) <= 10 and htime.setupAndCheckCoolDown(evtData.targetUnit, "真鳞胸甲buff", 30) then
                                echo("龙力护体，全无视该次伤害", hunit.getOwner(evtData.targetUnit))
                                evtData.damage = 0
                                local life_back = math.floor(hunit.getMaxLife(evtData.targetUnit) * 0.01)
                                hbuff.update(
                                    5,
                                    evtData.targetUnit,
                                    "真鳞胸甲buff",
                                    true,
                                    function()
                                        hattribute.set(
                                            evtData.targetUnit,
                                            0,
                                            _attr(
                                                {
                                                    life_back = "+" .. tostring(life_back),
                                                    shanbi = "+2",
                                                    zhaojia = "+2",
                                                    jianshang = "+2",
                                                    mokang = "+2"
                                                }
                                            )
                                        )
                                    end,
                                    function()
                                        hattribute.set(
                                            evtData.targetUnit,
                                            0,
                                            _attr(
                                                {
                                                    life_back = "-" .. tostring(life_back),
                                                    shanbi = "-2",
                                                    zhaojia = "-2",
                                                    jianshang = "-2",
                                                    mokang = "-2"
                                                }
                                            )
                                        )
                                    end,
                                    "ReplaceableTextures\\BTNINV_Chest_Cloth_48.blp",
                                    "龙力护体，每秒恢复1%(" .. tostring(life_back) .. ")生命最大值，同时提高2%的闪避，招架，减伤和魔抗。",
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
                    }
                }
            } }
        },
        {
            name = "[T1]无畏勇士套装",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 2,
            cunDangEndIndex = 2,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("无畏勇士战甲", "Art"),
            isActive = false,
            effectiveLevel = 40,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 30000 }
                },
                itemCost = {
                    { name = "无畏勇士战甲", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 5, jinglian = 5, currentCount = 0 },
                    { name = "无畏勇士战盔", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 5, jinglian = 5, currentCount = 0 },
                    { name = "无畏勇士战靴", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 5, jinglian = 5, currentCount = 0 },
                    { name = "无畏勇士护手", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 5, jinglian = 5, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr({ life = "+200", life_back = "+10" })
                    },
                    {
                        description = "狂暴战英勇打击消耗怒气降低1点。武器战普通攻击额外恢复1点怒气。惩戒骑获得神圣愤怒时会恢复1点魔法"
                    },
                    { description = "狂暴战英勇打击伤害提高5%。武器战撕裂的伤害提高20%，并且造成伤害时会恢复1%最大生命值。惩戒骑殉难圣印附加伤害提高10%" }
                }
            } }
        },
        {
            name = "[T1]灵力波动套装",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 3,
            cunDangEndIndex = 3,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("灵力波动法袍", "Art"),
            isActive = false,
            effectiveLevel = 40,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 30000 }
                },
                itemCost = {
                    { name = "灵力波动法袍", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 5, jinglian = 5, currentCount = 0 },
                    { name = "灵力波动手套", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 5, jinglian = 5, currentCount = 0 },
                    { name = "灵力波动长靴", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 5, jinglian = 5, currentCount = 0 },
                    { name = "灵力波动兜帽", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 5, jinglian = 5, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr({ fa_bao = "+0.5" })
                    },
                    {
                        description = "火法炎爆术消耗魔法减1。毁灭术灵魂导管概率提高2%。痛苦术痛苦献祭伤害提高20%。愤怒的魔法消耗降低1点。"
                    },
                    {
                        description =
                        "火法消耗炽热连击会获得一个持续20秒的buff，法术暴击提高0.5%，可以叠加3次。毁灭术混乱之箭伤害提高5%。痛苦术痛苦诅咒伤害加4%，持续时间增加3秒。星火术伤害提高5%。"
                    }
                }
            } }
        },
        {
            name = "[T1]猎杀者套装",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 4,
            cunDangEndIndex = 4,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("猎杀者软甲", "Art"),
            isActive = false,
            effectiveLevel = 40,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 30000 }
                },
                itemCost = {
                    { name = "猎杀者软甲", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 5, jinglian = 5, currentCount = 0 },
                    { name = "猎杀者手套", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 5, jinglian = 5, currentCount = 0 },
                    { name = "猎杀者皮靴", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 5, jinglian = 5, currentCount = 0 },
                    { name = "猎杀者皮帽", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 5, jinglian = 5, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr(
                            {
                                attack_speed = "+2",
                                energy_back = "+2"
                            }
                        )
                    },
                    {
                        description = "盗贼魔法斗篷还会使盗贼闪避提高25%，猎人基础射击能量恢复提高0.5每次攻击，每隔10秒，使用邪能冲撞不会进入cd"
                    },
                    { description = "盗贼破击伤害增加10%，猎人瞄准射击的有5%的概率触发爆头，造成双倍伤害，势如破竹的增伤效果提高5%" }
                }
            } }
        },
        {
            name = "灰烬之力",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 5,
            cunDangEndIndex = 5,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("灰烬之力", "Art"),
            isActive = false,
            effectiveLevel = 45,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 10000 }
                },
                itemCost = {
                    { name = "灰烬之力", count = 1, qianghua = 8, jinglian = 8, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr({ attack_speed = "+2", master = "+15", hit = "+1" })
                    },
                    {
                        description = "终极惩戒，全面增强惩戒骑士的伤害技能。公正之剑，神圣风暴，十字军打击，审判和神圣裁决造成的伤害提高3%。",
                        type = CONST_EVENT.damagingCustomSource,
                        action = function(evtData)
                            if
                                evtData.triggerSkill == hslk.n2i("公正之剑") or evtData.triggerSkill == hslk.n2i("神圣风暴") or
                                evtData.triggerSkill == hslk.n2i("十字军打击") or
                                evtData.triggerSkill == hslk.n2i("审判") or
                                evtData.triggerSkill == hslk.n2i("神圣裁决")
                            then
                                evtData.damage = evtData.damage * 1.03
                            end
                        end
                    }
                }
            } }
        },
        {
            name = "[T2]熔铸勇士套装",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 6,
            cunDangEndIndex = 6,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("熔铸勇士战甲", "Art"),
            isActive = false,
            effectiveLevel = 60,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 50000 }
                },
                itemCost = {
                    { name = "熔铸勇士战甲", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 7, jinglian = 7, currentCount = 0 },
                    { name = "熔铸勇士战盔", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 7, jinglian = 7, currentCount = 0 },
                    { name = "熔铸勇士战靴", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 7, jinglian = 7, currentCount = 0 },
                    { name = "熔铸勇士护手", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 7, jinglian = 7, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr(
                            {
                                life = "+500",
                                life_back = "+20"
                            }
                        )
                    },
                    {
                        description = "审判CD降低1秒，冲锋CD降低1秒，嗜血CD降低1秒"
                    },
                    { description = "神圣风暴伤害提高20%，顺劈斩伤害提高20%，旋风斩伤害提高50%" }
                }
            } }
        },
        {
            name = "[T2]炎灵套装",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 7,
            cunDangEndIndex = 7,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("炎灵法袍", "Art"),
            isActive = false,
            effectiveLevel = 60,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 50000 }
                },
                itemCost = {
                    { name = "炎灵手套", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 7, jinglian = 7, currentCount = 0 },
                    { name = "炎灵长靴", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 7, jinglian = 7, currentCount = 0 },
                    { name = "炎灵兜帽", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 7, jinglian = 7, currentCount = 0 },
                    { name = "炎灵法袍", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 7, jinglian = 7, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr({ fa_bao = "+1" })
                    },
                    {
                        description = "火凤凰的伤害提高10%，痛苦诅咒最大堆叠数量+1层，烧尽的伤害提高15%，使用群星坠落会对周围所有单位释放月火术。"
                    },
                    {
                        description = "火球术的伤害提高10%，腐蚀术的伤害提高10%，爆燃的冷却时间降低1秒，每次被动触发的坠星会使群星坠落CD降低0.5秒（剩余CD低于30秒时无效）。"
                    }
                }
            } }
        },
        {
            name = "[T2]追猎者套装",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 8,
            cunDangEndIndex = 8,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("追猎者软甲", "Art"),
            isActive = false,
            effectiveLevel = 60,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 50000 }
                },
                itemCost = {
                    { name = "追猎者软甲", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 7, jinglian = 7, currentCount = 0 },
                    { name = "追猎者手套", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 7, jinglian = 7, currentCount = 0 },
                    { name = "追猎者皮靴", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 7, jinglian = 7, currentCount = 0 },
                    { name = "追猎者皮帽", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 7, jinglian = 7, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr(
                            {
                                master = "+8",
                                energy_back = "+5"
                            }
                        )
                    },
                    {
                        description = "毒蛇钉刺造成伤害时回复1点能量，影袭消耗降低2点，刃舞cd降低1秒。"
                    },
                    { description = "奥术射击魔法消耗降低2点，伤害提高5%，杀戮盛宴伤害提高10%，刃舞的伤害提高5%。" }
                }
            } }
        },
        {
            name = "雷霆之怒·逐风者之剑",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 9,
            cunDangEndIndex = 9,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("雷霆之怒·逐风者之剑", "Art"),
            isActive = false,
            effectiveLevel = 60,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 20000 }
                },
                itemCost = {
                    { name = "雷霆之怒·逐风者之剑", count = 1, qianghua = 8, jinglian = 8, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr({ attack_speed = "+2", master = "+15", hit = "+1" })
                    },
                    {
                        description = "逐风：增加影袭和狂暴劈砍3%的伤害。",
                        type = CONST_EVENT.damagingCustomSource,
                        action = function(evtData)
                            if evtData.triggerSkill == hslk.n2i("影袭") then
                                evtData.damage = evtData.damage * 1.03
                            end
                            if evtData.triggerSkill == hslk.n2i("狂暴劈砍") then
                                evtData.damage = evtData.damage * 1.03
                            end
                        end
                    }
                }
            } }
        },
        {
            name = "埃提耶什·守护者之杖",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 10,
            cunDangEndIndex = 10,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("埃提耶什·守护者之杖", "Art"),
            isActive = false,
            effectiveLevel = 60,
            currentLevel = 0,
            data = {
                {
                    resourceCost = {
                        { type = HSHOP_COST_TYPE.gold, value = 20000 }
                    },
                    itemCost = {
                        { name = "埃提耶什·守护者之杖", count = 1, qianghua = 8, jinglian = 8, currentCount = 0 }
                    },
                    activeEffect = {
                        {
                            type = CONST_EVENT.attr,
                            action = _attr(
                                {
                                    fa_baoshang = "+5",
                                    fa_bao = "+1",
                                    skill_speed = "+2"
                                }
                            )
                        },
                    }
                }
            }
        },
        {
            name = "炎魔之手",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 11,
            cunDangEndIndex = 11,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("炎魔之手", "Art"),
            isActive = false,
            effectiveLevel = 60,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 20000 }
                },
                itemCost = {
                    { name = "炎魔之手", count = 1, qianghua = 8, jinglian = 8, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr(
                            {
                                wu_bao = "+1",
                                wu_baoshang = "+5",
                                wu_chuan = "+2"
                            }
                        )
                    },
                    {
                        description = "远古打击：增加致死打击3%的伤害，增加怒击5%的伤害。",
                        type = CONST_EVENT.damagingCustomSource,
                        action = function(evtData)
                            if evtData.triggerSkill == hslk.n2i("致死打击") then
                                evtData.damage = evtData.damage * 1.03
                            end
                            if evtData.triggerSkill == hslk.n2i("怒击") then
                                evtData.damage = evtData.damage * 1.05
                            end
                        end
                    }
                }
            } }
        },
        {
            name = "[T3]无畏战将套装",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 12,
            cunDangEndIndex = 12,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("无畏战将战甲", "Art"),
            isActive = false,
            effectiveLevel = 65,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 100000 }
                },
                itemCost = {
                    { name = "无畏战将战甲", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 8, jinglian = 8, currentCount = 0 },
                    { name = "无畏战将护手", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 8, jinglian = 8, currentCount = 0 },
                    { name = "无畏战将战靴", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 8, jinglian = 8, currentCount = 0 },
                    { name = "无畏战将战盔", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 8, jinglian = 8, currentCount = 0 },
                    { name = "无畏战将披风", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 8, jinglian = 8, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr(
                            {
                                wu_chuan = "+3",
                                wu_baoshang = "+4"
                            }
                        )
                    },
                    {
                        description = "圣殿裁决伤害提升2%，旋风斩增益buff额外获得一层，雷霆一击CD降低1秒"
                    },
                    { description = "圣殿裁决触发连击概率提升3%，怒击刷新提高3%，致死打击给予斩杀的增伤效果每层提高3%" }
                }
            } }
        },
        {
            name = "[T3]暗影猎手套装",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 13,
            cunDangEndIndex = 13,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("暗影猎手战甲", "Art"),
            isActive = false,
            effectiveLevel = 65,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 100000 }
                },
                itemCost = {
                    { name = "暗影猎手战甲", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 8, jinglian = 8, currentCount = 0 },
                    { name = "暗影猎手护手", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 8, jinglian = 8, currentCount = 0 },
                    { name = "暗影猎手战靴", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 8, jinglian = 8, currentCount = 0 },
                    { name = "暗影猎手战盔", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 8, jinglian = 8, currentCount = 0 },
                    { name = "暗影猎手披风", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 8, jinglian = 8, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr({
                            master = "+15",
                            attack_speed = "+4"
                        })
                    },
                    {
                        description = "瞄准射击伤害提升2%，剑刃飞舞的CD降低5秒，提升混乱打击2%伤害。"
                    },
                    {
                        description = "快速射击的伤害提高5%，割裂造成的伤害可以恢复1点能量，势如破竹的持续时间增加2秒"
                    }
                }
            } }
        },
        {
            name = "[T3]高阶法师套装",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 14,
            cunDangEndIndex = 14,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("高阶法师长袍", "Art"),
            isActive = false,
            effectiveLevel = 65,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 100000 }
                },
                itemCost = {
                    { name = "高阶法师长袍", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 8, jinglian = 8, currentCount = 0 },
                    { name = "高阶法师护手", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 8, jinglian = 8, currentCount = 0 },
                    { name = "高阶法师长靴", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 8, jinglian = 8, currentCount = 0 },
                    { name = "高阶法师兜帽", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 8, jinglian = 8, currentCount = 0 },
                    { name = "高阶法师披风", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 8, jinglian = 8, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr(
                            {
                                master = "+15",
                                skill_speed = "+2"
                            }
                        )
                    },
                    {
                        description = "烈焰宝珠伤害提升5%，愤怒伤害提升5%，牺牲魔典伤害提升5%，黑眼射线伤害提升5%。"
                    },
                    { description = "烈焰宝珠攻击频率提高15%，星火术伤害提高5%，牺牲魔典的触发概率提高3%，黑眼射线伤害有5%获得一颗灵魂之种。" }
                }
            } }
        },
        generateEquipmentConfig(
            "丛林深处的守护",
            { "狼皮衣", "狼牙戒指", "银月之心" },
            { life_back = "+3" },
            "银月之心",
            15
        ),
        generateEquipmentConfig(
            "丛林深处的气息",
            { "锋利巨斧", "森林长弓", "染血利刃" },
            { zhushuxing = "+10" },
            "锋利巨斧",
            16
        ),
        generateEquipmentConfig(
            "月亮湖的气息",
            { "绿鳞的皮", "绿鳞的冷铁匕首", "沉重的黑木法杖", "浸水的魔法书", "湛蓝坠饰" },
            { life_back = "+3" },
            "湛蓝坠饰",
            17
        ),
        generateEquipmentConfig(
            "月亮湖的守护",
            { "蓝影披风", "蓝影手套", "蓝影头盔", "蓝影鞋子", "蓝影衣服" },
            { zhushuxing = "+11" },
            "蓝影披风",
            18
        ),
        generateEquipmentConfig(
            "王城监狱的守护",
            { "老旧的皮甲", "精准打击手套", "灵敏披风", "灵动皮靴", "霍克的武器链" },
            { life_back = "+4" },
            "灵敏披风",
            19
        ),
        generateEquipmentConfig(
            "王城监狱的气息",
            { "老旧战锤", "激怒护符", "浸毒箭袋", "带刺项圈", "残酷倒钩" },
            { zhushuxing = "+12" },
            "残酷倒钩",
            20
        ),
        generateEquipmentConfig(
            "血色军的守护",
            { "血色军护手", "血色军战盔", "血色军披风", "血色军战靴", "血色军锁甲" },
            { life_back = "+4" },
            "血色军锁甲",
            21
        ),
        generateEquipmentConfig(
            "血色军的气息",
            { "杜兰的哨子", "血色制式长弓", "破坏者", "堕落的灰烬之力", "祭祀之杖" },
            { zhushuxing = "+13" },
            "破坏者",
            22
        ),
        generateEquipmentConfig(
            "圣光教堂的守护",
            { "黑暗污染指环", "能量涌动护符", "光明圣契", "光辉挂坠", "光明魔法书", "裁判者之影" },
            { life_back = "+5" },
            "蓝影披风",
            23
        ),
        generateEquipmentConfig(
            "圣光教堂的气息",
            { "主教之杖", "惩戒巨斧", "惩戒巨弓", "致命圣契", "污染者的意志", "嗜血锯刃" },
            { zhushuxing = "+14" },
            "蓝影披风",
            24
        ),
        generateEquipmentConfig(
            "半人马的守护",
            { "野蛮斗士护手", "野蛮斗士战盔", "套马索", "酋长大氅", "酋长吊坠" },
            { life_back = "+5" },
            "酋长大氅",
            25
        ),
        generateEquipmentConfig(
            "半人马的气息",
            { "人马勇士之戒", "勇气圣契", "射手箭袋", "专注之戒", "速射长弓" },
            { zhushuxing = "+20" },
            "速射长弓",
            26
        ),
        generateEquipmentConfig(
            "矮人地下城的守护",
            { "石楠之环", "黑暗魔法书", "野蛮斗士战甲", "正义之手", "斗士披风", "野蛮斗士战靴" },
            { life_back = "+5" },
            "野蛮斗士战甲",
            27
        ),
        generateEquipmentConfig(
            "矮人地下城的气息",
            { "狂暴火焰护符", "乔丹法杖", "有坚不催之力", "沙赫拉姆黑剑", "反对者" },
            { zhushuxing = "+22" },
            "沙赫拉姆黑剑",
            28
        ),
        generateEquipmentConfig(
            "火焰之地的守护",
            { "烈焰勋章", "火焰符文魔典", "毁灭王冠", "冲击披风" },
            { life_back = "+6" },
            "毁灭王冠",
            29
        ),
        generateEquipmentConfig(
            "火焰之地的气息",
            { "黑手饰物", "炎魔之指", "火焰之王的项圈", "迅击戒指", "迅击项链" },
            { zhushuxing = "+20" },
            "火焰之王的项圈",
            30
        ),
        generateEquipmentConfig(
            "火焰之地的毁灭",
            { "速射强弓", "脊骨收割者", "削骨之刃", "毁灭之刃", "碧空之歌", "统御法杖" },
            { zhushuxing = "+20" },
            "脊骨收割者",
            31
        ),
        generateEquipmentConfig(
            "黑龙王子的守护",
            { "龙牙饰物", "上古角石魔典", "奈萨里奥之泪" },
            { life_back = "+6" },
            "蓝影披风",
            32
        ),
        generateEquipmentConfig(
            "黑龙王子的气息",
            { "暗影烈焰法杖", "黑曜石之刃", "多彩之剑" },
            { zhushuxing = "+20" },
            "蓝影披风",
            33
        ),
        generateEquipmentConfig(
            "破碎大厅的守护",
            { "纷争勇士战靴", "纷争勇士战盔", "纷争勇士护手", "纷争勇士战甲" },
            { life_back = "+13", jianshang = "+0.4" },
            "纷争勇士战甲",
            34,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "破碎大厅的气息",
            { "元首权利坠饰", "食人魔奴隶镣铐", "荣耀的召唤", "高阶术士魔典" },
            { zhushuxing = "+40" },
            "蓝影披风",
            35,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "破碎大厅的毁灭",
            { "鲜血指环", "冲突箭袋", "微光指环", "獠牙祭品" },
            { zhushuxing = "+40" },
            "鲜血指环",
            36,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "屠龙者的守护",
            { "纷争勇士披风", "刀塔作战手套", "食人魔法师野蛮披风", "莫加尔战盔" },
            { life_back = "+12", jianshang = "+0.4" },
            "莫加尔战盔",
            37,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "屠龙者的气息",
            { "龙脊奖章", "格鲁尔之眼", "戈隆之王锁链" },
            { zhushuxing = "+40" },
            "龙脊奖章",
            38,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "屠龙者的毁灭",
            { "血喉魔剑", "纳鲁之锤", "古加尔的项圈" },
            { zhushuxing = "+40" },
            "纳鲁之锤",
            39,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "法师塔的守护",
            { "埃兰的镇定宝石", "紫罗兰之眼", "达拉然暗影斗篷", "循环之戒" },
            { life_back = "+5", jianshang = "+0.2" },
            "埃兰的镇定宝石",
            40,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "法师塔的祝福",
            { "乌瑞恩国王战甲", "豹爪护符", "莫罗的怀表", "翡翠撕裂者" },
            { life_back = "+5", jianshang = "+0.2" },
            "乌瑞恩国王战甲",
            41,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "法师塔的气息",
            { "王权头饰",
                "贵族箭袋",
                "钢针面甲",
                "圣洁祝福手套" },
            { zhushuxing = "+20" },
            "圣洁祝福手套",
            42,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "法师塔的意志",
            { "缚光者胸甲",
                "石枝外套",
                "国王护卫大剑",
                "刀锋行者长靴", },
            { zhushuxing = "+20" },
            "国王护卫大剑",
            43,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "法师塔的毁灭",
            { "战痕长靴",
                "救赎灵魂圣契",
                "永生长夜法杖",
                "红宝石靴子", },
            { zhushuxing = "+20" },
            "永生长夜法杖",
            44,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "法师塔的绝望",
            { "凤凰日怒长弓",
                "绝望",
                "蹂躏者手甲",
                "千印之戒" },
            { zhushuxing = "+20" },
            "凤凰日怒长弓",
            45,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "风暴要塞的守护",
            {
                "凤凰双刃",
                "亵渎者护符",
                "欺诈指环",
                "游侠将军指环" },
            { life_back = "+5", jianshang = "+0.2" },
            "游侠将军指环",
            46,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "风暴要塞的祝福",
            {
                "太阳王的权柄",
                "辛多雷金弓",
                "奎尔萨拉斯坠饰",
                "光荣护手" },
            { life_back = "+5", jianshang = "+0.2" },
            "太阳王的权柄",
            47,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "风暴要塞的气息",
            {
                "终结锁链",
                "虚空之星",
                "黑暗咒术之环",
                "狡诈之盔" },
            { zhushuxing = "+15", attack_white = "+15" },
            "黑暗咒术之环",
            48,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "风暴要塞的意志",
            { "光荣长靴",
                "星术士的蓝宝石",
                "星月坠饰",
                "炽热救赎圣典",
                "燃烧的正义" },
            { zhushuxing = "+15", attack_white = "+15" },
            "星术士的蓝宝石",
            49,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "风暴要塞的毁灭",
            { "浴火指环",
                "凤凰指环",
                "虚空梦魇",
                "星界螺旋",
                "奥之爪", },
            { zhushuxing = "+15", attack_white = "+15" },
            "奥之爪",
            50,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "黑暗神殿的守护",
            {
                "欲望镣铐",
                "影月徽记",
                "上层精灵斗篷",
                "堕落欲望魔典", },
            { life_back = "+5", jianshang = "+0.2" },
            "堕落欲望魔典",
            51,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "黑暗神殿的祝福",
            {
                "背叛者的疯狂",
                "裂魂之斧",
                "黑暗意图箭袋",
                "血色珍珠披风", },
            { life_back = "+5", jianshang = "+0.2" },
            "血色珍珠披风",
            52,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "黑暗神殿的气息",
            {
                "鲁莽怒火战甲",
                "黑暗编年史",
                "神圣信仰胸甲",
                "静谧海岸外衣", },
            { zhushuxing = "+15", attack_white = "+15" },
            "鲁莽怒火战甲",
            53,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "黑暗神殿的意志",
            { "救赎灵魂披风",
                "光荣披风",
                "原罪披风",
                "诅咒火炬",
                "玛维的执行镣铐", },
            { zhushuxing = "+15", attack_white = "+15" },
            "诅咒火炬",
            54,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        generateEquipmentConfig(
            "黑暗神殿的毁灭",
            { "古尔丹之颅",
                "扎尔杜姆·吞噬者的法杖",
                "背叛者的黑暗之弓",
                "光荣战盔",
                "萨格拉斯的诅咒视界", },
            { zhushuxing = "+15", attack_white = "+15" },
            "萨格拉斯的诅咒视界",
            55,
            { 3, 6, 9, 10, 11, 12, 13, 14 }
        ),
        {
            name = "[T4]秩序守护者套装",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 56,
            cunDangEndIndex = 56,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("秩序守护者圣铠", "Art"),
            isActive = false,
            effectiveLevel = 70,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 100000 }
                },
                itemCost = {
                    { name = "秩序守护者圣铠", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 9, jinglian = 9, currentCount = 0 },
                    { name = "秩序守护者之握", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 9, jinglian = 9, currentCount = 0 },
                    { name = "秩序守护者之履", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 9, jinglian = 9, currentCount = 0 },
                    { name = "秩序守护者冠冕", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 9, jinglian = 9, currentCount = 0 },
                    { name = "秩序守护者之翼", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 9, jinglian = 9, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr(
                            {
                                jianshang = "+1",
                                wu_zengshang = "+2",
                                fa_zengshang = "+2",
                                str_baifenbi = "+2",
                            }
                        )
                    }
                }
            } }
        },
        {
            name = "[T4]晨曦游侠套装",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 57,
            cunDangEndIndex = 57,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("晨曦游侠之衣", "Art"),
            isActive = false,
            effectiveLevel = 70,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 100000 }
                },
                itemCost = {
                    { name = "晨曦游侠之衣", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 9, jinglian = 9, currentCount = 0 },
                    { name = "晨曦游侠手套", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 9, jinglian = 9, currentCount = 0 },
                    { name = "晨曦游侠靴", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 9, jinglian = 9, currentCount = 0 },
                    { name = "晨曦游侠头饰", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 9, jinglian = 9, currentCount = 0 },
                    { name = "晨曦游侠披风", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 9, jinglian = 9, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr(
                            {
                                jianshang = "+1",
                                wu_zengshang = "+2",
                                fa_zengshang = "+2",
                                agi_baifenbi = "+2",
                            }
                        )
                    }
                }
            } }
        },
        {
            name = "[T4]风暴术士套装",
            cundangStr = "zhuangbeishouji",
            cunDangStartIndex = 58,
            cunDangEndIndex = 58,
            shoujiType = ZHUANGBEISHOUIJI_TYPE.TEYOUSHOUJI,
            art = hslk.n2v("风暴术士长袍", "Art"),
            isActive = false,
            effectiveLevel = 70,
            currentLevel = 0,
            data = { {
                resourceCost = {
                    { type = HSHOP_COST_TYPE.gold, value = 100000 }
                },
                itemCost = {
                    { name = "风暴术士长袍", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 9, jinglian = 9, currentCount = 0 },
                    { name = "风暴术士手套", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 9, jinglian = 9, currentCount = 0 },
                    { name = "风暴术士长靴", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 9, jinglian = 9, currentCount = 0 },
                    { name = "风暴术士头冠", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 9, jinglian = 9, currentCount = 0 },
                    { name = "风暴术士披风", count = 1, nandu = FUBEN_NANDU.SHISHI, qianghua = 9, jinglian = 9, currentCount = 0 }
                },
                activeEffect = {
                    {
                        type = CONST_EVENT.attr,
                        action = _attr(
                            {
                                jianshang = "+1",
                                wu_zengshang = "+2",
                                fa_zengshang = "+2",
                                int_baifenbi = "+2",
                            }
                        )
                    }
                }
            } }
        },
        generateEquipmentConfig(
            "太阳之井的毁灭",
            { "光棱指环",
                "灾难长靴",
                "止战马靴",
                "神圣信仰战靴",
                "胜利指环",
                "灾难指环" },
            { zhushuxing = "+20", attack_white = "+20" },
            "灾难长靴",
            59,
            { 10, 11, 12, 12, 13, 13, 14, 14 }
        ),
        generateEquipmentConfig(
            "太阳之井的守护",
            { "堡垒护手",
                "诸界亵渎护手",
                "萨拉斯将军护手",
                "纯净的纳鲁薄片",
                "灰暗的纳鲁薄片",
                "变幻的纳鲁薄片" },
            { zhushuxing = "+20", attack_white = "+20" },
            "灰暗的纳鲁薄片",
            60,
            { 10, 11, 12, 12, 13, 13, 14, 14 }
        ),
        generateEquipmentConfig(
            "太阳之井的荣耀",
            { "村正",
                "奥博莱恩·裂魂之剑",
                "日灸",
                "天启",
                "光荣战甲",
                "大魔导师的洪流法杖",
                "奥博莱恩·碎魂之剑" },
            { zhushuxing = "+20", attack_white = "+20" },
            "村正",
            61,
            { 10, 11, 12, 12, 13, 13, 14, 14 }
        )
    }
    hzhuangbeishouji.initFromConfig(config)
end
