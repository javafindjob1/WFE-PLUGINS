local shuchutianfu = {
    tianfutype = "输出",
    tianfu = {
        {
            {
                name = "鲁莽",
                description = "增加物理暴击几率",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "shuchutianfu",
                art = "ReplaceableTextures\\PASBTN_spell08.blp",
                cundangIndex = 1, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ wu_bao = "+0.2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ wu_bao = "+0.2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ wu_bao = "+0.2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ wu_bao = "+0.2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ wu_bao = "+0.2" })
                    }
                }
            },
            {
                name = "会心",
                description = "增加法术暴击几率",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "shuchutianfu",
                art = "ReplaceableTextures\\PASBTNTF_9.blp",
                cundangIndex = 2, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ fa_bao = "+0.2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ fa_bao = "+0.2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ fa_bao = "+0.2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ fa_bao = "+0.2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ fa_bao = "+0.2" })
                    }
                }
            }
        },
        {
            {
                name = "初级属性",
                description = "增加主属性",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "shuchutianfu",
                art = "ReplaceableTextures\\PASBTNTF_2.blp",
                cundangIndex = 3, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ zhushuxing = "+20" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ zhushuxing = "+20" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ zhushuxing = "+20" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ zhushuxing = "+20" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ zhushuxing = "+20" })
                    }
                }
            }
        },
        {
            {
                name = "攻击加速",
                description = "增加攻击速度",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "shuchutianfu",
                art = "ReplaceableTextures\\PASBTNwusheng01.blp",
                cundangIndex = 4, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ attack_speed = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ attack_speed = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ attack_speed = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ attack_speed = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ attack_speed = "+1" })
                    }
                }
            },
            {
                name = "施法加速",
                description = "增加施法速度",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "shuchutianfu",
                art = "ReplaceableTextures\\PASBTNTF_5.blp",
                cundangIndex = 5, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ skill_speed = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ skill_speed = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ skill_speed = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ skill_speed = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ skill_speed = "+0.5" })
                    }
                }
            }
        },
        {
            {
                name = "物理穿透",
                description = "增加物理穿透",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "shuchutianfu",
                art = "ReplaceableTextures\\PASBTN_ZS_Q2.blp",
                cundangIndex = 6, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ wu_chuan = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ wu_chuan = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ wu_chuan = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ wu_chuan = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ wu_chuan = "+0.5" })
                    }
                }
            },
            {
                name = "魔法穿透",
                description = "增加魔法穿透",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "shuchutianfu",
                art = "ReplaceableTextures\\PASBTN_WS_04.blp",
                cundangIndex = 7, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ fa_chuan = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ fa_chuan = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ fa_chuan = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ fa_chuan = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ fa_chuan = "+0.5" })
                    }
                }
            }
        },
        {
            {
                name = "物理伤害大师",
                description = "增加物理伤害",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "shuchutianfu",
                art = "ReplaceableTextures\\PASBTN_YX_BD3.blp",
                cundangIndex = 8, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ wu_zengshang = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ wu_zengshang = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ wu_zengshang = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ wu_zengshang = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ wu_zengshang = "+0.5" })
                    }
                }
            },
            {
                name = "魔法伤害大师",
                description = "增加魔法伤害",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "shuchutianfu",
                art = "ReplaceableTextures\\PASBTNWS_ZQHR.blp",
                cundangIndex = 9, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ fa_zengshang = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ fa_zengshang = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ fa_zengshang = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ fa_zengshang = "+0.5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ fa_zengshang = "+0.5" })
                    }
                }
            }
        },
        {
            {
                name = "技艺大师",
                description = "增加精通属性",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "shuchutianfu",
                art = "ReplaceableTextures\\PASBTNTF_3.blp",
                cundangIndex = 10, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ master = "+10" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ master = "+10" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ master = "+10" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ master = "+10" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ master = "+10" })
                    }
                }
            }
        },
        {
            {
                name = "卓越一击",
                description = "暴击伤害有一定概率伤害翻倍",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "shuchutianfu",
                art = "ReplaceableTextures\\PASBTNbm_03.blp",
                cundangIndex = 11, -- 确保是整数
                effect = {
                    {
                        description = "暴击伤害有额外2%的概率伤害翻倍"
                    },
                    {
                        description = "暴击伤害有额外2%的概率伤害翻倍"
                    },
                    {
                        description = "暴击伤害有额外2%的概率伤害翻倍"
                    },
                    {
                        description = "暴击伤害有额外2%的概率伤害翻倍"
                    },
                    {
                        description = "暴击伤害有额外2%的概率伤害翻倍"
                    }
                }
            },
            {
                name = "稳扎稳打",
                description = "非暴击物理/魔法伤害有一定概率伤害翻倍",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "shuchutianfu",
                art = "ReplaceableTextures\\BTN_ZS_JN04.blp",
                cundangIndex = 12, -- 确保是整数
                effect = {
                    {
                        description = "有3%的概率伤害翻倍"
                    },
                    {
                        description = "有额外3%的概率伤害翻倍"
                    },
                    {
                        description = "有额外3%的概率伤害翻倍"
                    },
                    {
                        description = "有额外3%的概率伤害翻倍"
                    },
                    {
                        description = "有额外3%的概率伤害翻倍"
                    }
                }
            }
        }
    }
}

local fangyutianfu = {
    tianfutype = "防御",
    tianfu = {
        {
            {
                name = "闪避专精",
                description = "被动增加英雄的闪避能力",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "fangyutianfu",
                art = "ReplaceableTextures\\PASBTN_YX_BD1.blp",
                cundangIndex = 1, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ shanbi = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ shanbi = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ shanbi = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ shanbi = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ shanbi = "+1" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            },
            {
                name = "招架专精",
                description = "被动增加英雄的招架能力",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "fangyutianfu",
                art = "ReplaceableTextures\\PASBTN_QS_01.blp",
                cundangIndex = 2, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ zhaojia = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ zhaojia = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ zhaojia = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ zhaojia = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ zhaojia = "+1" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            },
            {
                name = "格挡专精",
                description = "被动增加英雄的格挡能力",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "fangyutianfu",
                art = "ReplaceableTextures\\PASBTN_ZS_JN02.blp",
                cundangIndex = 3, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ gedang = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ gedang = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ gedang = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ gedang = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ gedang = "+1" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            }
            -- 省略其他天赋，保持示例简洁
        },
        {
            {
                name = "极效治疗石",
                description = "速效治疗石治疗效果增加",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "fangyutianfu",
                art = "ReplaceableTextures\\lianjin\\Warlock_ Healthstone.blp",
                cundangIndex = 4, -- 确保是整数
                effect = {
                    {
                        description = "速效治疗石治疗效果增加5%"
                    },
                    {
                        description = "速效治疗石治疗效果额外增加5%"
                    },
                    {
                        description = "速效治疗石治疗效果额外增加5%"
                    },
                    {
                        description = "速效治疗石治疗效果额外增加5%"
                    },
                    {
                        description = "速效治疗石治疗效果额外增加5%"
                    }
                }
            },
            {
                name = "自然的抚慰",
                description = "被动增加英雄的生命恢复能力",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "fangyutianfu",
                art = "ReplaceableTextures\\BTNLR_ZDXB.blp",
                cundangIndex = 5, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ life_back = "+10" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ life_back = "+10" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ life_back = "+10" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ life_back = "+10" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ life_back = "+10" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            }
        },
        {
            {
                name = "坚韧不拔",
                description = "增加英雄生命最大值",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "fangyutianfu",
                art = "ReplaceableTextures\\PASBTN_spell09.blp",
                cundangIndex = 6, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ shengming_baifenbi = "+2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ shengming_baifenbi = "+2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ shengming_baifenbi = "+2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ shengming_baifenbi = "+2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ shengming_baifenbi = "+2" })
                    }
                }
            },
            {
                name = "铜皮铁骨",
                description = "被动增加英雄的护甲",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "fangyutianfu",
                art = "ReplaceableTextures\\PASBTN_ZS_JN01.blp",
                cundangIndex = 7, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ defend_white = "+10" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ defend_white = "+10" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ defend_white = "+10" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ defend_white = "+10" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ defend_white = "+10" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            }
        },
        {
            {
                name = "闪避恢复",
                description = "闪避之后能恢复英雄生命值，CD3秒",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "fangyutianfu",
                art = "ReplaceableTextures\\PASBTN_YX_BD1.blp",
                cundangIndex = 8, -- 确保是整数
                effect = {
                    {
                        description = "恢复2%生命值",
                        action = CONST_EVENT.shanbi,
                        effect = function(evtData)
                            if htime.setupAndCheckCoolDown(evtData.triggerUnit, "闪避恢复", 3) then
                                hskill.heal(
                                    {
                                        healer = evtData.triggerUnit,
                                        healee = evtData.triggerUnit,
                                        heal = 0.02 * hunit.getMaxLife(evtData.triggerUnit),
                                        healType = HEAL_TYPE.SKILL,
                                        triggerSkill = hslk.n2i("装备技能")
                                    }
                                )
                            end
                        end
                    }
                    -- 省略其他效果，保持示例简洁
                }
            },
            {
                name = "招架恢复",
                description = "招架之后能恢复英雄生命值，CD3秒",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "fangyutianfu",
                art = "ReplaceableTextures\\PASBTN_QS_01.blp",
                cundangIndex = 9, -- 确保是整数
                effect = {
                    {
                        description = "恢复2%生命值",
                        action = CONST_EVENT.zhaojia,
                        effect = function(evtData)
                            if htime.setupAndCheckCoolDown(evtData.triggerUnit, "招架恢复", 3) then
                                hskill.heal(
                                    {
                                        healer = evtData.triggerUnit,
                                        healee = evtData.triggerUnit,
                                        heal = 0.02 * hunit.getMaxLife(evtData.triggerUnit),
                                        healType = HEAL_TYPE.SKILL,
                                        triggerSkill = hslk.n2i("装备技能")
                                    }
                                )
                            end
                        end
                    }
                    -- 省略其他效果，保持示例简洁
                }
            },
            {
                name = "格挡恢复",
                description = "格挡之后能恢复英雄生命值，CD3秒",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "fangyutianfu",
                art = "ReplaceableTextures\\PASBTN_ZS_JN02.blp",
                cundangIndex = 10, -- 确保是整数
                effect = {
                    {
                        description = "恢复英雄2%生命值",
                        action = CONST_EVENT.gedang,
                        effect = function(evtData)
                            if htime.setupAndCheckCoolDown(evtData.triggerUnit, "格挡恢复", 3) then
                                hskill.heal(
                                    {
                                        healer = evtData.triggerUnit,
                                        healee = evtData.triggerUnit,
                                        heal = 0.02 * hunit.getMaxLife(evtData.triggerUnit),
                                        healType = HEAL_TYPE.SKILL,
                                        triggerSkill = hslk.n2i("装备技能")
                                    }
                                )
                            end
                        end
                    }
                    -- 省略其他效果，保持示例简洁
                }
            }
        },
        {
            {
                name = "治疗专精",
                description = "被动增加英雄的治疗能力",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "fangyutianfu",
                art = "ReplaceableTextures\\PASBTN_QS_BD3.blp",
                cundangIndex = 11, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ healer_zengqiang = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ healer_zengqiang = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ healer_zengqiang = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ healer_zengqiang = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ healer_zengqiang = "+1" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            },
            {
                name = "恢复专精",
                description = "被动增加英雄受到的治疗量",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "fangyutianfu",
                art = "ReplaceableTextures\\PASBTN_QS_BD1.blp",
                cundangIndex = 12, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ healee_zengqiang = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ healee_zengqiang = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ healee_zengqiang = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ healee_zengqiang = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ healee_zengqiang = "+1" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            }
            -- 省略其他天赋，保持示例简洁
        },
        {
            {
                name = "魔法招架",
                description = "招架有概率招架魔法伤害",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "fangyutianfu",
                art = "ReplaceableTextures\\PASBTN_QS_01.blp",
                cundangIndex = 13, -- 确保是整数
                effect = {
                    {
                        description = "受到魔法伤害有5%招架概率规避该次魔法伤害"
                    },
                    {
                        description = "受到魔法伤害有额外5%招架概率规避该次魔法伤害"
                    },
                    {
                        description = "受到魔法伤害有额外5%招架概率规避该次魔法伤害"
                    },
                    {
                        description = "受到魔法伤害有额外5%招架概率规避该次魔法伤害"
                    },
                    {
                        description = "受到魔法伤害有额外5%招架概率规避该次魔法伤害"
                    }
                    -- 省略其他效果，保持示例简洁
                }
            },
            {
                name = "魔法格挡",
                description = "格挡有概率格挡魔法伤害",
                activePoints = { 0, 0, 0, 0, 0 },
                cundangStr = "fangyutianfu",
                art = "ReplaceableTextures\\PASBTN_ZS_JN02.blp",
                cundangIndex = 14, -- 确保是整数
                effect = {
                    {
                        description = "受到魔法伤害有5%格挡概率格挡该次魔法伤害"
                    },
                    {
                        description = "受到魔法伤害有额外5%格挡概率格挡该次魔法伤害"
                    },
                    {
                        description = "受到魔法伤害有额外5%格挡概率格挡该次魔法伤害"
                    },
                    {
                        description = "受到魔法伤害有额外5%格挡概率格挡该次魔法伤害"
                    },
                    {
                        description = "受到魔法伤害有额外5%格挡概率格挡该次魔法伤害"
                    }
                    -- 省略其他效果，保持示例简洁
                }
            }
            -- 省略其他天赋，保持示例简洁
        }
    }
}
local fuzhutianfu = {
    tianfutype = "辅助",
    tianfu = {
        {
            {
                name = "钓鱼高手",
                description = "被动增加英雄的钓鱼收获率",
                activePoints = { 0, 0, 0, 0, 0 },
                art = "ReplaceableTextures\\diaoyu\\yugan.blp",
                cundangStr = "fuzhutianfu",
                cundangIndex = 1, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ diaoyu_rate = "+5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ diaoyu_rate = "+5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ diaoyu_rate = "+5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ diaoyu_rate = "+5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ diaoyu_rate = "+5" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            },
            {
                name = "剥皮大师",
                description = "被动增加英雄的剥皮成功率",
                activePoints = { 0, 0, 0, 0, 0 },
                art = "ReplaceableTextures\\baopi\\BAOPI.blp",
                cundangStr = "fuzhutianfu",
                cundangIndex = 2, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ baopi_rate = "+5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ baopi_rate = "+5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ baopi_rate = "+5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ baopi_rate = "+5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ baopi_rate = "+5" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            },
            {
                name = "布料收集大师",
                description = "被动增加英雄布料收集的成功率",
                activePoints = { 0, 0, 0, 0, 0 },
                art = "ReplaceableTextures\\zhibu\\BTNWarcraft3 Ico.blp",
                cundangStr = "fuzhutianfu",
                cundangIndex = 3, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ zhibu_rate = "+5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ zhibu_rate = "+5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ zhibu_rate = "+5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ zhibu_rate = "+5" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ zhibu_rate = "+5" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            }
        },
        {
            {
                name = "淘金者",
                description = "杀怪掉落的金币有概率增加300%！",
                activePoints = { 0, 0, 0, 0, 0 },
                art = "ReplaceableTextures\\INV_Misc_Coin_02.blp",
                cundangStr = "fuzhutianfu",
                cundangIndex = 4, -- 确保是整数
                effect = {
                    {
                        description = "2%概率获得额外金币"
                    },
                    {
                        description = "额外2%概率获得额外金币"
                    },
                    {
                        description = "额外2%概率获得额外金币"
                    },
                    {
                        description = "额外2%概率获得额外金币"
                    },
                    {
                        description = "额外2%概率获得额外金币"
                    }
                }
            },
            {
                name = "经验大师",
                description = "杀怪获得的经验和巅峰经验有概率翻倍",
                activePoints = { 0, 0, 0, 0, 0 },
                art = "ReplaceableTextures\\BTN_VIP6.blp",
                cundangStr = "fuzhutianfu",
                cundangIndex = 5, -- 确保是整数
                effect = {
                    {
                        description = "2%概率翻倍"
                    },
                    {
                        description = "额外2%概率翻倍"
                    },
                    {
                        description = "额外2%概率翻倍"
                    },
                    {
                        description = "额外2%概率翻倍"
                    },
                    {
                        description = "额外2%概率翻倍"
                    }
                    -- 省略其他效果，保持示例简洁
                }
            }
        },
        {
            {
                name = "能量恢复",
                description = "增加被动能量恢复",
                activePoints = { 0, 0, 0, 0, 0 },
                art = "ReplaceableTextures\\PASBTNfs_3.blp",
                cundangStr = "fuzhutianfu",
                cundangIndex = 6, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ mana_back = "+0.2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ mana_back = "+0.2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ mana_back = "+0.2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ mana_back = "+0.2" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ mana_back = "+0.2" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            },
            {
                name = "能量掌控",
                description = "被动增加英雄的能量恢复能力",
                activePoints = { 0, 0, 0, 0, 0 },
                art = "ReplaceableTextures\\PASBTNTF_6.blp",
                cundangStr = "fuzhutianfu",
                cundangIndex = 7, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ energy_back = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ energy_back = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ energy_back = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ energy_back = "+1" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ energy_back = "+1" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            }
        },
        {
            {
                name = "采矿技艺精研",
                description = "被动增加采矿成功率",
                activePoints = { 0, 0, 0, 0, 0 },
                art = "ReplaceableTextures\\caikuang\\CAIKUANG.blp",
                cundangStr = "fuzhutianfu",
                cundangIndex = 8, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ caikuang_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ caikuang_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ caikuang_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ caikuang_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ caikuang_rate = "+4" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            },
            {
                name = "强化技艺精研",
                description = "被动增加强化成功率",
                activePoints = { 0, 0, 0, 0, 0 },
                art = "ReplaceableTextures\\duanzao\\duanzao.blp",
                cundangStr = "fuzhutianfu",
                cundangIndex = 9, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ qianghua_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ qianghua_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ qianghua_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ qianghua_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ qianghua_rate = "+4" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            }
        },
        {
            {
                name = "采药技艺精研",
                description = "被动增加采药成功率",
                activePoints = { 0, 0, 0, 0, 0 },
                art = "ReplaceableTextures\\caiyao\\BTNWarcraft3 Ico.blp",
                cundangStr = "fuzhutianfu",
                cundangIndex = 10, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ caiyao_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ caiyao_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ caiyao_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ caiyao_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ caiyao_rate = "+4" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            },
            {
                name = "精炼技艺精研",
                description = "被动增加精炼成功率",
                activePoints = { 0, 0, 0, 0, 0 },
                art = "ReplaceableTextures\\duanzao\\duanzao.blp",
                cundangStr = "fuzhutianfu",
                cundangIndex = 11, -- 确保是整数
                effect = {
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ jinglian_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ jinglian_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ jinglian_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ jinglian_rate = "+4" })
                    },
                    {
                        action = CONST_EVENT.attr,
                        effect = _attr({ jinglian_rate = "+4" })
                    }
                    -- 省略其他效果，保持示例简洁
                }
            }
        }
    }
}

TIANFU_CONFIG = {
    chengjieqi = {
        shuchutianfu,
        fangyutianfu,
        {
            tianfutype = "专精",
            tianfu = {
                {
                    {
                        name = "无尽审判",
                        description = "审判有概率触发无尽审判，伤害范围内的所有单位",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("审判", "Art"),
                        cundangIndex = 1, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率为8%"
                            },
                            {
                                description = "额外触发概率为16%"
                            },
                            {
                                description = "额外触发概率为24%"
                            },
                            {
                                description = "额外触发概率为32%"
                            },
                            {
                                description = "额外触发概率为40%"
                            }
                        }
                    },
                    {
                        name = "神圣利刃",
                        description = "触发由战争艺术加强的公正之剑时，有概率释放奉献，灼烧目标脚下的大地，对500码范围内的目标造成持续伤害，持续5秒，CD6秒",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\qishi\\Spell_Holy_InnerFire.blp",
                        cundangIndex = 2, -- 确保是整数
                        effect = {
                            {
                                description = "每秒造成15%主属性的光明魔法伤害。"
                            },
                            {
                                description = "每秒造成30%主属性的光明魔法伤害。"
                            },
                            {
                                description = "每秒造成45%主属性的光明魔法伤害。"
                            },
                            {
                                description = "每秒造成60%主属性的光明魔法伤害。"
                            },
                            {
                                description = "每秒造75%主属性的光明魔法伤害。"
                            }
                        }
                    },
                    {
                        name = "灰烬觉醒",
                        description = "神圣裁决有概率会对敌人进行猛烈打击，对前方400码210度扇形范围内的所有单位造成200%主属性和200%攻击的光明物理伤害，CD15秒。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("公正之剑", "Art"),
                        cundangIndex = 3, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率为20%。"
                            },
                            {
                                description = "额外20%触发概率。"
                            },
                            {
                                description = "额外20%触发概率。"
                            },
                            {
                                description = "额外20%触发概率。"
                            },
                            {
                                description = "额外20%触发概率。"
                            }
                        }
                    }
                },
                {
                    {
                        name = "愤怒审判",
                        description = "审判有概率造成两次伤害",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("审判", "Art"),
                        cundangIndex = 4, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率为5%"
                            },
                            {
                                description = "额外5%触发概率。"
                            },
                            {
                                description = "额外5%触发概率。"
                            },
                            {
                                description = "额外5%触发概率。"
                            },
                            {
                                description = "额外5%触发概率。"
                            }
                        }
                    },
                    {
                        name = "神圣奉献",
                        description = "被神圣风暴击中的敌人会在8秒内受到额外的奉献的伤害",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\qishi\\Spell_Holy_InnerFire.blp",
                        cundangIndex = 5, -- 确保是整数
                        effect = {
                            {
                                description = "受到额外20%奉献的伤害。"
                            },
                            {
                                description = "受到额外40%奉献的伤害。"
                            },
                            {
                                description = "受到额外60%奉献的伤害。"
                            },
                            {
                                description = "受到额外80%奉献的伤害。"
                            },
                            {
                                description = "受到额外100%奉献的伤害。"
                            }
                        }
                    },
                    {
                        name = "土归土",
                        description = "普攻有概率刷新灰烬觉醒CD。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("公正之剑", "Art"),
                        cundangIndex = 6, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率为2%"
                            },
                            {
                                description = "额外2%触发概率"
                            },
                            {
                                description = "额外2%触发概率"
                            },
                            {
                                description = "额外2%触发概率"
                            },
                            {
                                description = "额外2%触发概率"
                            }
                        }
                    }
                },
                {
                    {
                        name = "强化苍穹之力",
                        description = "苍穹之力触发时有概率同时刷新神圣风暴CD。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("苍穹之力", "Art"),
                        cundangIndex = 7, -- 确保是整数
                        effect = {
                            {
                                description = "苍穹之力触发时刷新概率为20%"
                            },
                            {
                                description = "苍穹之力触发时刷新概率为40%"
                            },
                            {
                                description = "苍穹之力触发时刷新概率为60%"
                            },
                            {
                                description = "苍穹之力触发时刷新概率为80%"
                            },
                            {
                                description = "苍穹之力触发时刷新概率为100%"
                            }
                        }
                    },
                    {
                        name = "圣言",
                        description = "奉献伤害有概率获得神圣能量，该效果具有1秒的最短生效间隔。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\qishi\\Spell_Holy_InnerFire.blp",
                        cundangIndex = 8, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率为2%"
                            },
                            {
                                description = "额外2%触发概率"
                            },
                            {
                                description = "额外2%触发概率"
                            },
                            {
                                description = "额外2%触发概率"
                            },
                            {
                                description = "额外2%触发概率"
                            }
                        }
                    },
                    {
                        name = "尘归尘", --[qishi]shenpan.mdx
                        description = "灰烬觉醒有30%概率会使使骑士获得短时间的复仇之力。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("公正之剑", "Art"),
                        cundangIndex = 9, -- 确保是整数
                        effect = {
                            {
                                description = "获得持续1秒的复仇之力"
                            },
                            {
                                description = "获得的复仇之力持续时间增加1秒。"
                            },
                            {
                                description = "获得的复仇之力持续时间增加1秒。"
                            },
                            {
                                description = "获得的复仇之力持续时间增加1秒。"
                            },
                            {
                                description = "获得的复仇之力持续时间增加1秒。"
                            }
                        }
                    }
                },
                {
                    {
                        name = "致命狂热",
                        description = "狂热还会提升你的物理和法术暴击率1%",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("狂热", "Art"),
                        cundangIndex = 10, -- 确保是整数
                        effect = {
                            {
                                description = "狂热还会提升你的物理和法术暴击率1%"
                            },
                            {
                                description = "狂热还会提升你的物理和法术暴击率2%"
                            },
                            {
                                description = "狂热还会提升你的物理和法术暴击率3%"
                            },
                            {
                                description = "狂热还会提升你的物理和法术暴击率4%"
                            },
                            {
                                description = "狂热还会提升你的物理和法术暴击率5%"
                            }
                        }
                    },
                    {
                        name = "光明使者的风暴",
                        description = "神圣风暴会向前方移动，对前方直线目标造成伤害，并增加伤害",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("神圣风暴", "Art"),
                        cundangIndex = 11, -- 确保是整数
                        effect = {
                            {
                                description = "移动距离为300，伤害提高1%"
                            },
                            {
                                description = "移动距离为350，伤害提高2%"
                            },
                            {
                                description = "移动距离为400，伤害提高3%"
                            },
                            {
                                description = "移动距离为450，伤害提高4%"
                            },
                            {
                                description = "移动距离为500，伤害提高5%"
                            }
                        }
                    },
                    {
                        name = "灰烬能量",
                        description = "触发灰烬觉醒会获得额外的神圣能量",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("公正之剑", "Art"),
                        cundangIndex = 12, -- 确保是整数
                        effect = {
                            {
                                description = "获得1个神圣能量"
                            },
                            {
                                description = "获得2个神圣能量"
                            },
                            {
                                description = "获得3个神圣能量"
                            },
                            {
                                description = "获得4个神圣能量"
                            },
                            {
                                description = "获得5个神圣能量"
                            }
                        }
                    }
                }
            }
        },
        fuzhutianfu
        -- 省略其他天赋类型，保持示例简洁
    },
    tongkushu = {
        shuchutianfu,
        fangyutianfu,
        {
            tianfutype = "专精",
            tianfu = {
                {
                    {
                        name = "强化痛苦献祭",
                        description = "痛苦献祭有概率爆炸，造成300范围火焰魔法伤害",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("痛苦献祭", "Art"),
                        cundangIndex = 1, -- 确保是整数
                        effect = {
                            {
                                description = "爆炸概率为2%"
                            },
                            {
                                description = "爆炸概率为4%"
                            },
                            {
                                description = "爆炸概率为6%"
                            },
                            {
                                description = "爆炸概率为8%"
                            },
                            {
                                description = "爆炸概率为10%"
                            }
                        }
                    },
                    {
                        name = "易爆之种",
                        description = " 腐蚀之种的爆炸伤害提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("腐蚀之种", "Art"),
                        cundangIndex = 2, -- 确保是整数
                        effect = {
                            {
                                description = "腐蚀之种的爆炸伤害提高5%"
                            },
                            {
                                description = "腐蚀之种的爆炸伤害提高10%"
                            },
                            {
                                description = "腐蚀之种的爆炸伤害提高15%"
                            },
                            {
                                description = "腐蚀之种的爆炸伤害提高20%"
                            },
                            {
                                description = "腐蚀之种的爆炸伤害提高25%"
                            }
                        }
                    },
                    {
                        name = "鲜血渴望",
                        description = "生命虹吸的冷却时间降低",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("生命虹吸", "Art"),
                        cundangIndex = 3, -- 确保是整数
                        effect = {
                            {
                                description = "生命虹吸的冷却时间降低2秒"
                            },
                            {
                                description = "生命虹吸的冷却时间降低4秒"
                            },
                            {
                                description = "生命虹吸的冷却时间降低6秒"
                            },
                            {
                                description = "生命虹吸的冷却时间降低8秒"
                            },
                            {
                                description = "生命虹吸的冷却时间降低10秒"
                            }
                        }
                    }
                },
                {
                    {
                        name = "梦魇",
                        description = "恐惧有概率会给受到影响的目标施加痛苦献祭",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("恐惧", "Art"),
                        cundangIndex = 4, -- 确保是整数
                        effect = {
                            {
                                description = "概率为20%"
                            },
                            {
                                description = "概率为40%"
                            },
                            {
                                description = "概率为60%"
                            },
                            {
                                description = "概率为80%"
                            },
                            {
                                description = "概率为100%"
                            }
                        }
                    },
                    {
                        name = "腐蚀传染",
                        description = "腐蚀之种有概率额外释放2个种子",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("腐蚀之种", "Art"),
                        cundangIndex = 5, -- 确保是整数
                        effect = {
                            {
                                description = "腐蚀之种有10%概率额外释放2个种子"
                            },
                            {
                                description = "腐蚀之种有20%概率额外释放2个种子"
                            },
                            {
                                description = "腐蚀之种有30%概率额外释放2个种子"
                            },
                            {
                                description = "腐蚀之种有40%概率额外释放2个种子"
                            },
                            {
                                description = "腐蚀之种有50%概率额外释放2个种子"
                            }
                        }
                    },
                    {
                        name = "深蚀",
                        description = "腐蚀术会使目标受到所有魔法伤害提高3%",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("腐蚀术", "Art"),
                        cundangIndex = 6, -- 确保是整数
                        effect = {
                            {
                                description = "腐蚀术会使目标受到所有魔法伤害提高0.6%"
                            },
                            {
                                description = "腐蚀术会使目标受到所有魔法伤害提高1.2%"
                            },
                            {
                                description = "腐蚀术会使目标受到所有魔法伤害提高1.8%"
                            },
                            {
                                description = "腐蚀术会使目标受到所有魔法伤害提高2.4%"
                            },
                            {
                                description = "腐蚀术会使目标受到所有魔法伤害提高3%"
                            }
                        }
                    }
                },
                {
                    {
                        name = "致命献祭",
                        description = "痛苦献祭造成伤害有概率会造成双倍伤害",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("痛苦献祭", "Art"),
                        cundangIndex = 7, -- 确保是整数
                        effect = {
                            {
                                description = "痛苦献祭造成伤害有4%概率会造成双倍伤害"
                            },
                            {
                                description = "痛苦献祭造成伤害有8%概率会造成双倍伤害"
                            },
                            {
                                description = "痛苦献祭造成伤害有12%概率会造成双倍伤害"
                            },
                            {
                                description = "痛苦献祭造成伤害有16%概率会造成双倍伤害"
                            },
                            {
                                description = "痛苦献祭造成伤害有20%概率会造成双倍伤害"
                            }
                        }
                    },
                    {
                        name = "痛苦回响",
                        description = "痛苦诅咒产生灵魂碎片的概率提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("痛苦诅咒", "Art"),
                        cundangIndex = 8, -- 确保是整数
                        effect = {
                            {
                                description = "痛苦诅咒产生灵魂碎片的概率提高1%"
                            },
                            {
                                description = "痛苦诅咒产生灵魂碎片的概率提高2%"
                            },
                            {
                                description = "痛苦诅咒产生灵魂碎片的概率提高3%"
                            },
                            {
                                description = "痛苦诅咒产生灵魂碎片的概率提高4%"
                            },
                            {
                                description = "痛苦诅咒产生灵魂碎片的概率提高5%"
                            }
                        }
                    },
                    {
                        name = "诅咒大师",
                        description = "腐蚀术和痛苦诅咒持续时间增加",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("腐蚀术", "Art"),
                        cundangIndex = 9, -- 确保是整数
                        effect = {
                            {
                                description = "腐蚀术和痛苦诅咒持续时间增加1秒"
                            },
                            {
                                description = "腐蚀术和痛苦诅咒持续时间增加2秒"
                            },
                            {
                                description = "腐蚀术和痛苦诅咒持续时间增加3秒"
                            },
                            {
                                description = "腐蚀术和痛苦诅咒持续时间增加4秒"
                            },
                            {
                                description = "腐蚀术和痛苦诅咒持续时间增加5秒"
                            }
                        }
                    }
                },
                {
                    {
                        name = "暗影之拥",
                        description = "暗影箭击中目标会提升你的法术穿透7%",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("暗影箭", "Art"),
                        cundangIndex = 10, -- 确保是整数
                        effect = {
                            {
                                description = "持续2秒"
                            },
                            {
                                description = "持续4秒"
                            },
                            {
                                description = "持续6秒"
                            },
                            {
                                description = "持续8秒"
                            },
                            {
                                description = "持续10秒"
                            }
                        }
                    },
                    {
                        name = "痛苦狂潮",
                        description = "无尽诅咒会对800码范围所有目标施加痛苦无常",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("无尽诅咒", "Art"),
                        cundangIndex = 11, -- 确保是整数
                        effect = {
                            {
                                description = "叠加1层痛苦无常"
                            },
                            {
                                description = "叠加2层痛苦无常"
                            },
                            {
                                description = "叠加3层痛苦无常"
                            },
                            {
                                description = "叠加4层痛苦无常"
                            },
                            {
                                description = "叠加5层痛苦无常"
                            }
                        }
                    },
                    {
                        name = "邪恶献祭",
                        description = "目标死亡时，如果有痛苦术献祭，则会造成300码范围的爆炸。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("痛苦献祭", "Art"),
                        cundangIndex = 12, -- 确保是整数
                        effect = {
                            {
                                description = "伤害为40%主属性"
                            },
                            {
                                description = "伤害为80%主属性"
                            },
                            {
                                description = "伤害为120%主属性"
                            },
                            {
                                description = "伤害为160%主属性"
                            },
                            {
                                description = "伤害为200%主属性"
                            }
                        }
                    }
                }
            }
        },
        fuzhutianfu
        -- 省略其他天赋类型，保持示例简洁
    },
    huofa = {
        shuchutianfu,
        fangyutianfu,
        {
            tianfutype = "专精",
            tianfu = {
                {
                    {
                        name = "火疗闪烁",
                        description = "释放闪现后，在5秒内每秒恢复生命值。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("闪现", "Art"),
                        cundangIndex = 1, -- 确保是整数
                        effect = {
                            {
                                description = "每秒恢复0.5%生命值。"
                            },
                            {
                                description = "每秒额外恢复0.5%生命值。"
                            },
                            {
                                description = "每秒额外恢复0.5%生命值。"
                            },
                            {
                                description = "每秒额外恢复0.5%生命值。"
                            },
                            {
                                description = "每秒额外恢复0.5%生命值。"
                            }
                        }
                    },
                    {
                        name = "触燃感触",
                        description = "火焰冲击使点燃伤害提高2%，持续12秒。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("火焰冲击", "Art"),
                        cundangIndex = 2, -- 确保是整数
                        effect = {
                            {
                                description = "该效果最高叠加1次。"
                            },
                            {
                                description = "该效果最高叠加2次。"
                            },
                            {
                                description = "该效果最高叠加3次。"
                            },
                            {
                                description = "该效果最高叠加4次。"
                            },
                            {
                                description = "该效果最高叠加5次。"
                            }
                        }
                    },
                    {
                        name = "烈焰飞舞",
                        description = "火焰冲击的冷却时间降低。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("火焰冲击", "Art"),
                        cundangIndex = 3, -- 确保是整数
                        effect = {
                            {
                                description = "火焰冲击的冷却时间降低0.7秒"
                            },
                            {
                                description = "火焰冲击的冷却时间降低0.7秒"
                            },
                            {
                                description = "火焰冲击的冷却时间降低0.7秒"
                            },
                            {
                                description = "火焰冲击的冷却时间降低0.7秒"
                            },
                            {
                                description = "火焰冲击的冷却时间降低0.7秒"
                            }
                        }
                    }
                },
                {
                    {
                        name = "烈焰之地",
                        description = "烈焰风暴留下一片烈焰之地，灼烧区域内的敌人，造成火焰魔法伤害，持续6秒。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("烈焰风暴", "Art"),
                        cundangIndex = 4, -- 确保是整数
                        effect = {
                            {
                                description = "烈焰之地伤害为20%主属性每秒"
                            },
                            {
                                description = "烈焰之地伤害为40%主属性每秒"
                            },
                            {
                                description = "烈焰之地伤害为60%主属性每秒"
                            },
                            {
                                description = "烈焰之地伤害为80%主属性每秒"
                            },
                            {
                                description = "烈焰之地伤害为100%主属性每秒"
                            }
                        }
                    },
                    {
                        name = "余震",
                        description = "降低烈焰风暴的冷却时间。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("烈焰风暴", "Art"),
                        cundangIndex = 5, -- 确保是整数
                        effect = {
                            {
                                description = "烈焰风暴的冷却时间降低1秒"
                            },
                            {
                                description = "烈焰风暴的冷却时间降低2秒"
                            },
                            {
                                description = "烈焰风暴的冷却时间降低3秒"
                            },
                            {
                                description = "烈焰风暴的冷却时间降低4秒"
                            },
                            {
                                description = "烈焰风暴的冷却时间降低5秒"
                            }
                        }
                    },
                    {
                        name = "烈焰喷发",
                        description = "烈焰风暴的伤害有概率给目标施加不会传播的活体炸弹",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("烈焰风暴", "Art"),
                        cundangIndex = 6, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率为5%"
                            },
                            {
                                description = "触发概率为10%"
                            },
                            {
                                description = "触发概率为15%"
                            },
                            {
                                description = "触发概率为20%"
                            },
                            {
                                description = "触发概率为25%"
                            }
                        }
                    }
                },
                {
                    {
                        name = "高温",
                        description = "消耗炽热连击有概率激活燃烧，持续5秒。触发高温后法师会进入冷却无法再次触发该技能，直到10秒钟后。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("炽热连击", "Art"),
                        cundangIndex = 7, -- 确保是整数
                        effect = {
                            {
                                description = "消耗炽热连击有2%概率激活燃烧"
                            },
                            {
                                description = "消耗炽热连击有额外2%概率激活燃烧"
                            },
                            {
                                description = "消耗炽热连击有额外2%概率激活燃烧"
                            },
                            {
                                description = "消耗炽热连击有额外2%概率激活燃烧"
                            },
                            {
                                description = "消耗炽热连击有额外2%概率激活燃烧"
                            }
                        }
                    },
                    {
                        name = "强化燃烧",
                        description = "燃烧可以提高点燃的伤害",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("燃烧", "Art"),
                        cundangIndex = 8, -- 确保是整数
                        effect = {
                            {
                                description = "提高点燃5%的伤害"
                            },
                            {
                                description = "额外提高点燃5%的伤害"
                            },
                            {
                                description = "额外提高点燃5%的伤害"
                            },
                            {
                                description = "额外提高点燃5%的伤害"
                            },
                            {
                                description = "额外提高点燃5%的伤害"
                            }
                        }
                    },
                    {
                        name = "薪火",
                        description = "火球术，炎爆术，火焰冲击，暴击时会降低燃烧的冷却时间",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("燃烧", "Art"),
                        cundangIndex = 9, -- 确保是整数
                        effect = {
                            {
                                description = "每次暴击降低0.2燃烧的冷却时间"
                            },
                            {
                                description = "每次暴击降低0.4燃烧的冷却时间"
                            },
                            {
                                description = "每次暴击降低0.6燃烧的冷却时间"
                            },
                            {
                                description = "每次暴击降低0.8燃烧的冷却时间"
                            },
                            {
                                description = "每次暴击降低1燃烧的冷却时间"
                            }
                        }
                    }
                },
                {
                    {
                        name = "烈火意志",
                        description = "消耗炽热连击使你的法术暴击提高0.5%，攻速提高1%，持续12秒。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("炽热连击", "Art"),
                        cundangIndex = 10, -- 确保是整数
                        effect = {
                            {
                                description = "此效果最多可叠加1次"
                            },
                            {
                                description = "此效果最多可叠加2次"
                            },
                            {
                                description = "此效果最多可叠加3次"
                            },
                            {
                                description = "此效果最多可叠加4次"
                            },
                            {
                                description = "此效果最多可叠加5次"
                            }
                        }
                    },
                    {
                        name = "烈焰大师",
                        description = "点燃造成的伤害提高。燃烧激活时，火焰冲击有概率会将点燃额外延烧至附近300码范围内的所有目标",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("点燃", "Art"),
                        cundangIndex = 11, -- 确保是整数
                        effect = {
                            {
                                description = "点燃伤害提高2%，点燃延烧概率为20%"
                            },
                            {
                                description = "点燃伤害提高4%，点燃延烧概率为40%"
                            },
                            {
                                description = "点燃伤害提高6%，点燃延烧概率为60%"
                            },
                            {
                                description = "点燃伤害提高8%，点燃延烧概率为80%"
                            },
                            {
                                description = "点燃伤害提高10%，点燃延烧概率为100%"
                            }
                        }
                    },
                    {
                        name = "太阳之王的愤怒",
                        description = "太阳之王的炎爆伤害整体提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("太阳之王的祝福", "Art"),
                        cundangIndex = 12, -- 确保是整数
                        effect = {
                            {
                                description = "伤害提高7%"
                            },
                            {
                                description = "伤害提高14%"
                            },
                            {
                                description = "伤害提高21%"
                            },
                            {
                                description = "伤害提高28%"
                            },
                            {
                                description = "伤害提高35%"
                            }
                        }
                    }
                }
            }
        },
        fuzhutianfu
        -- 省略其他天赋类型，保持示例简洁
    },
    zhandouzei = {
        shuchutianfu,
        fangyutianfu,
        {
            tianfutype = "专精",
            tianfu = {
                {
                    {
                        name = "强化作战潜能",
                        description = "作战潜能攻击回能的触发概率提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\daozei\\zuozhanqianneng.blp",
                        cundangIndex = 1, -- 确保是整数
                        effect = {
                            {
                                description = "作战潜能触发概率提高1%"
                            },
                            {
                                description = "作战潜能触发概率额外提高1%"
                            },
                            {
                                description = "作战潜能触发概率额外提高1%"
                            },
                            {
                                description = "作战潜能触发概率额外提高1%"
                            },
                            {
                                description = "作战潜能触发概率额外提高1%"
                            }
                        }
                    },
                    {
                        name = "双持专精",
                        description = "提高盗贼普通攻击的伤害",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\daozei\\shuangchizhuanjing.blp",
                        cundangIndex = 2, -- 确保是整数
                        effect = {
                            {
                                description = "提高盗贼普通攻击2%的伤害"
                            },
                            {
                                description = "额外提高盗贼普通攻击2%的伤害"
                            },
                            {
                                description = "额外提高盗贼普通攻击2%的伤害"
                            },
                            {
                                description = "额外提高盗贼普通攻击2%的伤害"
                            },
                            {
                                description = "额外提高盗贼普通攻击2%的伤害"
                            }
                        }
                    },
                    {
                        name = "连击精通",
                        description = "盗贼的连击天赋获得了提升，提高连击的伤害",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\daozei\\lianji.blp",
                        cundangIndex = 3, -- 确保是整数
                        effect = {
                            {
                                description = "提高盗贼连击攻击2%的伤害"
                            },
                            {
                                description = "提高盗贼连击攻击4%的伤害"
                            },
                            {
                                description = "提高盗贼连击攻击6%的伤害"
                            },
                            {
                                description = "提高盗贼连击攻击8%的伤害"
                            },
                            {
                                description = "提高盗贼连击攻击10%的伤害"
                            }
                        }
                    }
                },
                {
                    {
                        name = "邪恶攻击",
                        description = "提高影袭的伤害",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\daozei\\yingxi.blp",
                        cundangIndex = 4, -- 确保是整数
                        effect = {
                            {
                                description = "提高影袭的3%的伤害"
                            },
                            {
                                description = "额外提高影袭的3%的伤害"
                            },
                            {
                                description = "额外提高影袭的3%的伤害"
                            },
                            {
                                description = "额外提高影袭的3%的伤害"
                            },
                            {
                                description = "额外提高影袭的3%的伤害"
                            }
                        }
                    },
                    {
                        name = "剧毒",
                        description = "致命毒药的最大叠加层数增加",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\daozei\\zhimingyaogao.blp",
                        cundangIndex = 5, -- 确保是整数
                        effect = {
                            {
                                description = "致命毒药的最大叠加层数加1"
                            },
                            {
                                description = "致命毒药的最大叠加层数额外加1"
                            },
                            {
                                description = "致命毒药的最大叠加层数额外加1"
                            },
                            {
                                description = "致命毒药的最大叠加层数额外加1"
                            },
                            {
                                description = "致命毒药的最大叠加层数额外加1"
                            }
                        }
                    },
                    {
                        name = "剑术专家",
                        description = "增加剑刃飞舞的持续时间",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("剑刃飞舞", "Art"),
                        cundangIndex = 6, -- 确保是整数
                        effect = {
                            {
                                description = "剑刃飞舞的持续时间增加1秒"
                            },
                            {
                                description = "剑刃飞舞的持续时间增加2秒"
                            },
                            {
                                description = "剑刃飞舞的持续时间增加3秒"
                            },
                            {
                                description = "剑刃飞舞的持续时间增加4秒"
                            },
                            {
                                description = "剑刃飞舞的持续时间增加5秒"
                            }
                        }
                    }
                },
                {
                    {
                        name = "无休锋刃",
                        description = "每消耗一个连击点，冲动和杀戮盛宴的冷却时间缩短",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\daozei\\lianji.blp",
                        cundangIndex = 7, -- 确保是整数
                        effect = {
                            {
                                description = "每个连击点降低冲动和杀戮盛宴0.1秒冷却时间"
                            },
                            {
                                description = "每个连击点降低冲动和杀戮盛宴0.2秒冷却时间"
                            },
                            {
                                description = "每个连击点降低冲动和杀戮盛宴0.3秒冷却时间"
                            },
                            {
                                description = "每个连击点降低冲动和杀戮盛宴0.4秒冷却时间"
                            },
                            {
                                description = "每个连击点降低冲动和杀戮盛宴0.5秒冷却时间"
                            }
                        }
                    },
                    {
                        name = "连击技大师",
                        description = "盗贼的连击技巧再一次提升，提高破击和割裂的伤害，且精通效果可以提高该增幅",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("破击", "Art"),
                        cundangIndex = 8, -- 确保是整数
                        effect = {
                            {
                                description = "伤害提高值为2%，每35精通效果可以增幅1%终结技伤害"
                            },
                            {
                                description = "伤害提高值为4%，每30精通效果可以增幅1%终结技伤害"
                            },
                            {
                                description = "伤害提高值为6%，每25精通效果可以增幅1%终结技伤害"
                            },
                            {
                                description = "伤害提高值为8%，每20精通效果可以增幅1%终结技伤害"
                            },
                            {
                                description = "伤害提高值为10%，每15精通效果可以增幅1%终结技伤害"
                            }
                        }
                    },
                    {
                        name = "体能充沛",
                        description = "降低疾影的冷却时间",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("疾影", "Art"),
                        cundangIndex = 9, -- 确保是整数
                        effect = {
                            {
                                description = "疾影的冷却时间降低1秒"
                            },
                            {
                                description = "疾影的冷却时间降低2秒"
                            },
                            {
                                description = "疾影的冷却时间降低3秒"
                            },
                            {
                                description = "疾影的冷却时间降低4秒"
                            },
                            {
                                description = "疾影的冷却时间降低5秒"
                            }
                        }
                    }
                },
                {
                    {
                        name = "手法娴熟",
                        description = "需要先学会灌铅骰子，提高你灌铅骰子获得三种和六中增益的概率（对应降低2种buff的概率）",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("命运之骰", "Art"),
                        cundangIndex = 10, -- 确保是整数
                        effect = {
                            {
                                description = "获得三种增益概率2%，六种增益概率1%"
                            },
                            {
                                description = "获得三种增益概率4%，六种增益概率1%"
                            },
                            {
                                description = "获得三种增益概率6%，六种增益概率1%"
                            },
                            {
                                description = "获得三种增益概率8%，六种增益概率1%"
                            },
                            {
                                description = "获得三种增益概率10%，六种增益概率1%"
                            }
                        }
                    },
                    {
                        name = "切割技巧",
                        description = "降低割裂4%*lv的基础伤害间隔",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("割裂", "Art"),
                        cundangIndex = 11, -- 确保是整数
                        effect = {
                            {
                                description = "割裂伤害间隔减低4%"
                            },
                            {
                                description = "割裂伤害间隔减低8%"
                            },
                            {
                                description = "割裂伤害间隔减低12%"
                            },
                            {
                                description = "割裂伤害间隔减低16%"
                            },
                            {
                                description = "割裂伤害间隔减低20%"
                            }
                        }
                    },
                    {
                        name = "武器精通",
                        description = "根据主手武器的类型，匕首提升1%暴击，剑会有1%造成额外的连击，锤提升1%物理穿透，斧提升1%攻击力",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\daozei\\shuangchizhuanjing.blp",
                        cundangIndex = 12, -- 确保是整数
                        effect = {
                            {
                                description = "提升为1%"
                            },
                            {
                                description = "提升为2%"
                            },
                            {
                                description = "提升为3%"
                            },
                            {
                                description = "提升为4%"
                            },
                            {
                                description = "提升为5%"
                            }
                        }
                    }
                }
            }
        },
        fuzhutianfu
        -- 省略其他天赋类型，保持示例简洁
    },
    huimieshu = {
        shuchutianfu,
        fangyutianfu,
        {
            tianfutype = "专精",
            tianfu = {
                {
                    {
                        name = "爆破潜能",
                        description = "爆燃CD减少",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("爆燃", "Art"),
                        cundangIndex = 1, -- 确保是整数
                        effect = {
                            {
                                description = "爆燃CD减少0.2秒"
                            },
                            {
                                description = "爆燃CD减少0.4秒"
                            },
                            {
                                description = "爆燃CD减少0.6秒"
                            },
                            {
                                description = "爆燃CD减少0.8秒"
                            },
                            {
                                description = "爆燃CD减少1秒"
                            }
                        }
                    },
                    {
                        name = "毁灭仪式",
                        description =
                        "释放混乱之箭有概率使你获得毁灭仪式，叠加五层后会使得下一个混乱之箭施法时间降低50%且不消耗灵魂碎片，或者使下一个火雨伤害提高100%且产生的灵魂碎片基础概率提高15%",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("混乱之箭", "Art"),
                        cundangIndex = 2, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率为20%"
                            },
                            {
                                description = "触发概率为40%"
                            },
                            {
                                description = "触发概率为60%"
                            },
                            {
                                description = "触发概率为80%"
                            },
                            {
                                description = "触发概率为100%"
                            }
                        }
                    },
                    {
                        name = "天魔余烬",
                        description = "烧尽产生的混乱之种的基础概率提升",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("烧尽", "Art"),
                        cundangIndex = 3, -- 确保是整数
                        effect = {
                            {
                                description = "基础概率提升2%"
                            },
                            {
                                description = "基础概率提升4%"
                            },
                            {
                                description = "基础概率提升6%"
                            },
                            {
                                description = "基础概率提升8%"
                            },
                            {
                                description = "基础概率提升10%"
                            }
                        }
                    }
                },
                {
                    {
                        name = "暴乱",
                        description = "爆燃有概率为目标附近500码内的一个单位释放浩劫，持续5秒。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("浩劫", "Art"),
                        cundangIndex = 4, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率为5%"
                            },
                            {
                                description = "触发概率为10%"
                            },
                            {
                                description = "触发概率为15%"
                            },
                            {
                                description = "触发概率为20%"
                            },
                            {
                                description = "触发概率为25%"
                            }
                        }
                    },
                    {
                        name = "混乱浩劫",
                        description = "混乱之箭有概率对300码范围内敌人造成伤害，次级混乱之箭伤害提升",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("混乱之箭", "Art"),
                        cundangIndex = 5, -- 确保是整数
                        effect = {
                            {
                                description = "混乱之箭触发概率为2%，次级混乱之箭伤害提升2%"
                            },
                            {
                                description = "混乱之箭触发概率为4%，次级混乱之箭伤害提升4%"
                            },
                            {
                                description = "混乱之箭触发概率为6%，次级混乱之箭伤害提升6%"
                            },
                            {
                                description = "混乱之箭触发概率为8%，次级混乱之箭伤害提升8%"
                            },
                            {
                                description = "混乱之箭触发概率为10%，次级混乱之箭伤害提升10%"
                            }
                        }
                    },
                    {
                        name = "硫黄烈火",
                        description = "烧尽有概率变成范围伤害，对目标周围300码内的敌人造成伤害。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("烧尽", "Art"),
                        cundangIndex = 6, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率为5%"
                            },
                            {
                                description = "触发概率为10%"
                            },
                            {
                                description = "触发概率为15%"
                            },
                            {
                                description = "触发概率为20%"
                            },
                            {
                                description = "触发概率为25%"
                            }
                        }
                    }
                },
                {
                    {
                        name = "混乱具象",
                        description = "爆燃有概率使毁灭术士获得灵魂燃烧状态，持续5秒，该技能具有最低触发间隔10秒。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("灵魂燃烧", "Art"),
                        cundangIndex = 7, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率为3%"
                            },
                            {
                                description = "触发概率为6%"
                            },
                            {
                                description = "触发概率为9%"
                            },
                            {
                                description = "触发概率为12%"
                            },
                            {
                                description = "触发概率为15%"
                            }
                        }
                    },
                    {
                        name = "阿兹亚基的疯狂",
                        description = "混乱之箭有概率会触发阿兹亚基的疯狂，使下一次混乱之箭的伤害提高10%，施法时间缩短10%，或者下一次火焰之雨会使火焰之雨的伤害提高25%，持续4秒",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\SHUSHI\\HLZZ.blp",
                        cundangIndex = 8, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率为20%"
                            },
                            {
                                description = "触发概率为40%"
                            },
                            {
                                description = "触发概率为60%"
                            },
                            {
                                description = "触发概率为80%"
                            },
                            {
                                description = "触发概率为100%"
                            }
                        }
                    },
                    {
                        name = "焚烧成灰",
                        description = "混乱之箭会使得下个烧尽的伤害提高，最多叠加4次，持续8秒",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("烧尽", "Art"),
                        cundangIndex = 9, -- 确保是整数
                        effect = {
                            {
                                description = "烧尽伤害提高3%"
                            },
                            {
                                description = "烧尽伤害提高6%"
                            },
                            {
                                description = "烧尽伤害提高9%"
                            },
                            {
                                description = "烧尽伤害提高12%"
                            },
                            {
                                description = "烧尽伤害提高15%"
                            }
                        }
                    }
                },
                {
                    {
                        name = "闪点",
                        description = "献祭对80%以上目标造成伤害时，会提升技能加速，持续6秒。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("献祭", "Art"),
                        cundangIndex = 10, -- 确保是整数
                        effect = {
                            {
                                description = "提升2%的技能加速"
                            },
                            {
                                description = "提升4%的技能加速"
                            },
                            {
                                description = "提升6%的技能加速"
                            },
                            {
                                description = "提升8%的技能加速"
                            },
                            {
                                description = "提升10%的技能加速"
                            }
                        }
                    },
                    {
                        name = "魔典强化",
                        description = "火焰雨有概率可以对被影响的目标进行牺牲魔典的触发判定",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("火焰雨", "Art"),
                        cundangIndex = 11, -- 确保是整数
                        effect = {
                            {
                                description = "概率为20%"
                            },
                            {
                                description = "概率为40%"
                            },
                            {
                                description = "概率为60%"
                            },
                            {
                                description = "概率为80%"
                            },
                            {
                                description = "概率为100%"
                            }
                        }
                    },
                    {
                        name = "烈焰焚灭",
                        description = "烧尽的伤害提升",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("烧尽", "Art"),
                        cundangIndex = 12, -- 确保是整数
                        effect = {
                            {
                                description = "提升为4%"
                            },
                            {
                                description = "提升为8%"
                            },
                            {
                                description = "提升为12%"
                            },
                            {
                                description = "提升为16%"
                            },
                            {
                                description = "提升为20%"
                            }
                        }
                    }
                }
            }
        },
        fuzhutianfu
        -- 省略其他天赋类型，保持示例简洁
    },
    xingchenfashi = {
        shuchutianfu,
        fangyutianfu,
        {
            tianfutype = "专精",
            tianfu = {
                {
                    {
                        name = "艾露恩之赐",
                        description = "月蚀的持续时间增加，日蚀的持续时间降低，愤怒有概率叠加两层月蚀",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("月蚀", "Art"),
                        cundangIndex = 1, -- 确保是整数
                        effect = {
                            {
                                description = "月蚀持续时间增加0.5秒，日蚀持续时间降低0.5秒，愤怒有20%概率叠加两层月蚀"
                            },
                            {
                                description = "月蚀持续时间增加1秒，日蚀持续时间降低1秒，愤怒有40%概率叠加两层月蚀"
                            },
                            {
                                description = "月蚀持续时间增加1.5秒，日蚀持续时间降低1.5秒，愤怒有60%概率叠加两层月蚀"
                            },
                            {
                                description = "月蚀持续时间增加2秒，日蚀持续时间降低2秒，愤怒有80%概率叠加两层月蚀"
                            },
                            {
                                description = "月蚀持续时间增加2.5秒，日蚀持续时间降低2.5秒，愤怒有100%概率叠加两层月蚀"
                            }
                        }
                    },
                    {
                        name = "安舍之赐",
                        description = "日蚀的持续时间增加，月蚀的持续时间降低，星火术有概率叠加两层日蚀",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("日蚀", "Art"),
                        cundangIndex = 2, -- 确保是整数
                        effect = {
                            {
                                description = "日蚀持续时间增加0.5秒，月蚀持续时间降低0.5秒，星火术有20%概率叠加两层日蚀"
                            },
                            {
                                description = "日蚀持续时间增加1秒，月蚀持续时间降低1秒，星火术有40%概率叠加两层日蚀"
                            },
                            {
                                description = "日蚀持续时间增加1.5秒，月蚀持续时间降低1.5秒，星火术有60%概率叠加两层日蚀"
                            },
                            {
                                description = "日蚀持续时间增加2秒，月蚀持续时间降低2秒，星火术有80%概率叠加两层日蚀"
                            },
                            {
                                description = "日蚀持续时间增加2.5秒，月蚀持续时间降低2.5秒，星火术有100%概率叠加两层日蚀"
                            }
                        }
                    },
                    {
                        name = "群星之赐",
                        description = "星辰之力过载造成的蓝耗增加效果降低，造成的伤害增加效果提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("星涌术", "Art"),
                        cundangIndex = 3, -- 确保是整数
                        effect = {
                            {
                                description = "星辰之力过载造成的蓝耗增加效果降低3%，造成的伤害增加效果提高3%"
                            },
                            {
                                description = "星辰之力过载造成的蓝耗增加效果降低6%，造成的伤害增加效果提高6%"
                            },
                            {
                                description = "星辰之力过载造成的蓝耗增加效果降低9%，造成的伤害增加效果提高9%"
                            },
                            {
                                description = "星辰之力过载造成的蓝耗增加效果降低12%，造成的伤害增加效果提高12%"
                            },
                            {
                                description = "星辰之力过载造成的蓝耗增加效果降低15%，造成的伤害增加效果提高15%"
                            }
                        }
                    }
                },
                {
                    {
                        name = "日光涌动",
                        description = "阳炎术的伤害有概率使下一个愤怒连发",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("阳炎术", "Art"),
                        cundangIndex = 4, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率为5%"
                            },
                            {
                                description = "触发概率为10%"
                            },
                            {
                                description = "触发概率为15%"
                            },
                            {
                                description = "触发概率为20%"
                            },
                            {
                                description = "触发概率为25%"
                            }
                        }
                    },
                    {
                        name = "月之暗面",
                        description = "月火术造成伤害时增加下一个星火术30%的伤害。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("月火术", "Art"),
                        cundangIndex = 5, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率为5%"
                            },
                            {
                                description = "触发概率为10%"
                            },
                            {
                                description = "触发概率为15%"
                            },
                            {
                                description = "触发概率为20%"
                            },
                            {
                                description = "触发概率为25%"
                            }
                        }
                    },
                    {
                        name = "欧奈斯的洞察",
                        description = "坠星有概率使你获得欧奈斯的洞察效果，最多叠加2层，每层使下一个星涌术50%的魔法消耗，同时增加其20%的伤害。释放星涌术会消耗该效果。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("星涌术", "Art"),
                        cundangIndex = 6, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率2%"
                            },
                            {
                                description = "触发概率4%"
                            },
                            {
                                description = "触发概率6%"
                            },
                            {
                                description = "触发概率8%"
                            },
                            {
                                description = "触发概率10%"
                            }
                        }
                    }
                },
                {
                    {
                        name = "原始奥能脉冲星",
                        description = "进入日蚀和月蚀有概率获得超凡之盟效果，持续6秒。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("超凡之盟", "Art"),
                        cundangIndex = 7, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率为5%"
                            },
                            {
                                description = "触发概率为10%"
                            },
                            {
                                description = "触发概率为15%"
                            },
                            {
                                description = "触发概率为20%"
                            },
                            {
                                description = "触发概率为25%"
                            }
                        }
                    },
                    {
                        name = "万物平衡",
                        description = "超凡之盟还会提高法术暴击",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("超凡之盟", "Art"),
                        cundangIndex = 8, -- 确保是整数
                        effect = {
                            {
                                description = "提高2%法术暴击"
                            },
                            {
                                description = "提高4%法术暴击"
                            },
                            {
                                description = "提高6%法术暴击"
                            },
                            {
                                description = "提高8%法术暴击"
                            },
                            {
                                description = "提高10%法术暴击"
                            }
                        }
                    },
                    {
                        name = "生死循环",
                        description = "阳炎术，星火术，月火术的持续伤害效果伤害间隔降低，并且每次伤害有概率为你回复生命值",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("星火术", "Art"),
                        cundangIndex = 9, -- 确保是整数
                        effect = {
                            {
                                description = "伤害间隔降低5%,有2%概率回复2%生命值"
                            },
                            {
                                description = "伤害间隔降低10%,有4%概率回复2%生命值"
                            },
                            {
                                description = "伤害间隔降低15%,有6%概率回复2%生命值"
                            },
                            {
                                description = "伤害间隔降低20%,有8%概率回复2%生命值"
                            },
                            {
                                description = "伤害间隔降低25%,有10%概率回复2%生命值"
                            }
                        }
                    }
                },
                {
                    {
                        name = "烈阳之怒",
                        description = "愤怒有概率造成150%的伤害",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("愤怒", "Art"),
                        cundangIndex = 10, -- 确保是整数
                        effect = {
                            {
                                description = "概率为2%"
                            },
                            {
                                description = "概率为4%"
                            },
                            {
                                description = "概率为6%"
                            },
                            {
                                description = "概率为8%"
                            },
                            {
                                description = "概率为10%"
                            }
                        }
                    },
                    {
                        name = "劲烈星影",
                        description = "月蚀额外减少星火术读条",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("星火术", "Art"),
                        cundangIndex = 11, -- 确保是整数
                        effect = {
                            {
                                description = "降低0.1秒"
                            },
                            {
                                description = "降低0.2秒"
                            },
                            {
                                description = "降低0.3秒"
                            },
                            {
                                description = "降低0.4秒"
                            },
                            {
                                description = "降低0.5秒"
                            }
                        }
                    },
                    {
                        name = "星月交辉",
                        description = "月蚀期间星火术会降低你群星坠落冷却时间。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("群星坠落", "Art"),
                        cundangIndex = 12, -- 确保是整数
                        effect = {
                            {
                                description = "降低0.1秒"
                            },
                            {
                                description = "降低0.2秒"
                            },
                            {
                                description = "降低0.3秒"
                            },
                            {
                                description = "降低0.4秒"
                            },
                            {
                                description = "降低0.5秒"
                            }
                        }
                    }
                }
            }
        },
        fuzhutianfu
        -- 省略其他天赋类型，保持示例简洁
    },
    kuangbaozhan = {
        shuchutianfu,
        fangyutianfu,
        {
            tianfutype = "专精",
            tianfu = {
                {
                    {
                        name = "强化旋风斩",
                        description = "旋风斩伤害提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("旋风斩", "Art"),
                        cundangIndex = 1, -- 确保是整数
                        effect = {
                            {
                                description = "旋风斩伤害提高10%"
                            },
                            {
                                description = "旋风斩伤害提高20%"
                            },
                            {
                                description = "旋风斩伤害提高30%"
                            },
                            {
                                description = "旋风斩伤害提高40%"
                            },
                            {
                                description = "旋风斩伤害提高50%"
                            }
                        }
                    },
                    {
                        name = "狂乱深渊",
                        description = "死亡之愿持续时间提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("死亡之愿", "Art"),
                        cundangIndex = 2, -- 确保是整数
                        effect = {
                            {
                                description = "死亡之愿持续时间提高1秒"
                            },
                            {
                                description = "死亡之愿持续时间提高2秒"
                            },
                            {
                                description = "死亡之愿持续时间提高3秒"
                            },
                            {
                                description = "死亡之愿持续时间提高4秒"
                            },
                            {
                                description = "死亡之愿持续时间提高5秒"
                            }
                        }
                    },
                    {
                        name = "怒击专精",
                        description = "怒击刷新CD的概率提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("怒击", "Art"),
                        cundangIndex = 3, -- 确保是整数
                        effect = {
                            {
                                description = "怒击刷新CD的概率提高1%"
                            },
                            {
                                description = "怒击刷新CD的概率提高2%"
                            },
                            {
                                description = "怒击刷新CD的概率提高3%"
                            },
                            {
                                description = "怒击刷新CD的概率提高4%"
                            },
                            {
                                description = "怒击刷新CD的概率提高5%"
                            }
                        }
                    }
                },
                {
                    {
                        name = "灵敏风暴",
                        description = "每次普攻会降低旋风斩的CD时间",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("旋风斩", "Art"),
                        cundangIndex = 4, -- 确保是整数
                        effect = {
                            {
                                description = "降低旋风斩0.05秒的CD时间"
                            },
                            {
                                description = "降低旋风斩0.1秒的CD时间"
                            },
                            {
                                description = "降低旋风斩0.15秒的CD时间"
                            },
                            {
                                description = "降低旋风斩0.2秒的CD时间"
                            },
                            {
                                description = "降低旋风斩0.25秒的CD时间"
                            }
                        }
                    },
                    {
                        name = "强化英勇打击",
                        description = "英勇打击的伤害提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("英勇打击", "Art"),
                        cundangIndex = 5, -- 确保是整数
                        effect = {
                            {
                                description = "英勇打击的伤害提高3%"
                            },
                            {
                                description = "英勇打击的伤害提高6%"
                            },
                            {
                                description = "英勇打击的伤害提高9%"
                            },
                            {
                                description = "英勇打击的伤害提高12%"
                            },
                            {
                                description = "英勇打击的伤害提高15%"
                            }
                        }
                    },
                    {
                        name = "不羁狂野",
                        description = "怒击有概率进入死亡之愿状态，持续5秒。该技能具有10秒的触发冷却时间。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("怒击", "Art"),
                        cundangIndex = 6, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率2%"
                            },
                            {
                                description = "触发概率4%"
                            },
                            {
                                description = "触发概率6%"
                            },
                            {
                                description = "触发概率8%"
                            },
                            {
                                description = "触发概率10%"
                            }
                        }
                    }
                },
                {
                    {
                        name = "破甲风暴",
                        description = "旋风斩会使目标受到的物理伤害提高,持续6秒",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("旋风斩", "Art"),
                        cundangIndex = 7, -- 确保是整数
                        effect = {
                            {
                                description = "受到的物理伤害提高0.6%"
                            },
                            {
                                description = "受到的物理伤害提高1.2%"
                            },
                            {
                                description = "受到的物理伤害提高1.8%"
                            },
                            {
                                description = "受到的物理伤害提高2.4%"
                            },
                            {
                                description = "受到的物理伤害提高3%"
                            }
                        }
                    },
                    {
                        name = "怒不可遏",
                        description = "英勇打击会降低暴怒cd",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("英勇打击", "Art"),
                        cundangIndex = 8, -- 确保是整数
                        effect = {
                            {
                                description = "每次英勇打击会降低暴怒0.05秒冷却时间"
                            },
                            {
                                description = "每次英勇打击会降低暴怒0.1秒冷却时间"
                            },
                            {
                                description = "每次英勇打击会降低暴怒0.15秒冷却时间"
                            },
                            {
                                description = "每次英勇打击会降低暴怒0.2秒冷却时间"
                            },
                            {
                                description = "每次英勇打击会降低暴怒0.25秒冷却时间"
                            }
                        }
                    },
                    {
                        name = "怒冲云霄",
                        description = "怒击会使下次暴怒伤害提高,持续15秒，最多叠加5层，使用暴怒会消耗掉该效果",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("怒击", "Art"),
                        cundangIndex = 9, -- 确保是整数
                        effect = {
                            {
                                description = "每层提高暴怒伤害3%"
                            },
                            {
                                description = "每层提高暴怒伤害6%"
                            },
                            {
                                description = "每层提高暴怒伤害9%"
                            },
                            {
                                description = "每层提高暴怒伤害12%"
                            },
                            {
                                description = "每层提高暴怒伤害15%"
                            }
                        }
                    }
                },
                {
                    {
                        name = "强化怒不可遏",
                        description = "英勇打击也会降低龙吼的技能CD",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("英勇打击", "Art"),
                        cundangIndex = 10, -- 确保是整数
                        effect = {
                            {
                                description = "每次英勇打击会降低龙吼0.05秒冷却时间"
                            },
                            {
                                description = "每次英勇打击会降低龙吼0.10秒冷却时间"
                            },
                            {
                                description = "每次英勇打击会降低龙吼0.15秒冷却时间"
                            },
                            {
                                description = "每次英勇打击会降低龙吼0.20秒冷却时间"
                            },
                            {
                                description = "每次英勇打击会降低龙吼0.25秒冷却时间"
                            }
                        }
                    },
                    {
                        name = "一心狂暴",
                        description = "当你装备两把单手武器时，整体伤害提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("泰坦之握", "Art"),
                        cundangIndex = 11, -- 确保是整数
                        effect = {
                            {
                                description = "伤害提高5%"
                            },
                            {
                                description = "伤害提高10%"
                            },
                            {
                                description = "伤害提高15%"
                            },
                            {
                                description = "伤害提高20%"
                            },
                            {
                                description = "伤害提高25%"
                            }
                        }
                    },
                    {
                        name = "破坏者",
                        description = "你的旋风斩会在前方范围留下一个旋转的飞斧，每1.5秒对周围造成，持续6秒，CD9秒",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("旋风斩", "Art"),
                        cundangIndex = 12, -- 确保是整数
                        effect = {
                            {
                                description = "每次伤害为12%攻击力"
                            },
                            {
                                description = "每次伤害为24%攻击力"
                            },
                            {
                                description = "每次伤害为36%攻击力"
                            },
                            {
                                description = "每次伤害为48%攻击力"
                            },
                            {
                                description = "每次伤害为60%攻击力"
                            }
                        }
                    }
                }
            }
        },
        fuzhutianfu
        -- 省略其他天赋类型，保持示例简洁
    },
    wuqizhan = {
        shuchutianfu,
        fangyutianfu,
        {
            tianfutype = "专精",
            tianfu = {
                {
                    {
                        name = "战术专家",
                        description = "斩杀和致死打击每消耗1点怒气，就有概率刷新压制的冷却。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("压制", "Art"),
                        cundangIndex = 1, -- 确保是整数
                        effect = {
                            {
                                description = "消耗每点怒气触发概率为0.2%"
                            },
                            {
                                description = "消耗每点怒气触发概率为0.4%"
                            },
                            {
                                description = "消耗每点怒气触发概率为0.6%。"
                            },
                            {
                                description = "消耗每点怒气触发概率为0.8%"
                            },
                            {
                                description = "消耗每点怒气触发概率为1.0%"
                            }
                        }
                    },
                    {
                        name = "熟能生巧",
                        description = "战术专家的触发概率提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("压制", "Art"),
                        cundangIndex = 2, -- 确保是整数
                        effect = {
                            {
                                description = "战术专家的触发概率提高10%"
                            },
                            {
                                description = "战术专家的触发概率提高20%"
                            },
                            {
                                description = "战术专家的触发概率提高30%"
                            },
                            {
                                description = "战术专家的触发概率提高40%"
                            },
                            {
                                description = "战术专家的触发概率提高50%"
                            }
                        }
                    },
                    {
                        name = "斩杀技巧",
                        description = "消耗额外怒气的斩杀会返还怒气。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("斩杀", "Art"),
                        cundangIndex = 3, -- 确保是整数
                        effect = {
                            {
                                description = "恢复4点怒气"
                            },
                            {
                                description = "恢复8点怒气"
                            },
                            {
                                description = "恢复12点怒气"
                            },
                            {
                                description = "恢复16点怒气"
                            },
                            {
                                description = "恢复20点怒气"
                            }
                        }
                    }
                },
                {
                    {
                        name = "迷乱狂舞",
                        description = "利刃风暴每次伤害有概率会同时对周围随机2个目标释放致死打击",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("利刃风暴", "Art"),
                        cundangIndex = 4, -- 确保是整数
                        effect = {
                            {
                                description = "触发概率为6%"
                            },
                            {
                                description = "触发概率为12%"
                            },
                            {
                                description = "触发概率为18%"
                            },
                            {
                                description = "触发概率为24%"
                            },
                            {
                                description = "触发概率为30%"
                            }
                        }
                    },
                    {
                        name = "聚焦风暴",
                        description = "利刃风暴每次伤害会提升战士的物理伤害和暴击率，持续5秒。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("利刃风暴", "Art"),
                        cundangIndex = 5, -- 确保是整数
                        effect = {
                            {
                                description = "每次伤害提高0.15%物理伤害和暴击率"
                            },
                            {
                                description = "每次伤害提高0.3%物理伤害和暴击率"
                            },
                            {
                                description = "每次伤害提高0.45%物理伤害和暴击率"
                            },
                            {
                                description = "每次伤害提高0.6%物理伤害和暴击率"
                            },
                            {
                                description = "每次伤害提高0.75%物理伤害和暴击率"
                            }
                        }
                    },
                    {
                        name = "死亡之舞",
                        description = "利刃风暴期间每击杀一个敌人降低利刃风暴的冷却时间，冷却时间低于30秒时不会触发",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("利刃风暴", "Art"),
                        cundangIndex = 6, -- 确保是整数
                        effect = {
                            {
                                description = "每击杀一个敌人降低0.3秒冷却时间"
                            },
                            {
                                description = "每击杀一个敌人降低0.6秒冷却时间"
                            },
                            {
                                description = "每击杀一个敌人降低0.9秒冷却时间"
                            },
                            {
                                description = "每击杀一个敌人降低1.2秒冷却时间"
                            },
                            {
                                description = "每击杀一个敌人降低1.5秒冷却时间"
                            }
                        }
                    }
                },
                {
                    {
                        name = "愤怒掌控",
                        description = "斩杀和致死打击每消耗20点怒气，就会降低利刃风暴和巨人打击的冷却时间。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\MoreButtons\\KUANGBAOHUIFU\\BTNKUANGBAOHUIFU.blp",
                        cundangIndex = 7, -- 确保是整数
                        effect = {
                            {
                                description = "降低0.2秒利刃风暴冷却时间，0.1秒巨人打击的冷却时间"
                            },
                            {
                                description = "降低0.4秒利刃风暴冷却时间，0.2秒巨人打击的冷却时间"
                            },
                            {
                                description = "降低0.6秒利刃风暴冷却时间，0.3秒巨人打击的冷却时间"
                            },
                            {
                                description = "降低0.8秒利刃风暴冷却时间，0.4秒巨人打击的冷却时间"
                            },
                            {
                                description = "降低1秒利刃风暴冷却时间，0.5秒巨人打击的冷却时间"
                            }
                        }
                    },
                    {
                        name = "杀意",
                        description = "巨人打击会使战士变得兴奋，提高技能加速和攻击加速，持续5秒",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("巨人打击", "Art"),
                        cundangIndex = 8, -- 确保是整数
                        effect = {
                            {
                                description = "提高3%的攻击速度和2%的技能加速"
                            },
                            {
                                description = "提高6%的攻击速度和4%的技能加速"
                            },
                            {
                                description = "提高9%的攻击速度和6%的技能加速"
                            },
                            {
                                description = "提高12%的攻击速度和8%的技能加速"
                            },
                            {
                                description = "提高15%的攻击速度和10%的技能加速"
                            }
                        }
                    },
                    {
                        name = "巨力猛击",
                        description = "战士猛烈挥舞手中的武器进行猛击，猛击变为范围伤害",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("猛击", "Art"),
                        cundangIndex = 9, -- 确保是整数
                        effect = {
                            {
                                description = "伤害范围为200"
                            },
                            {
                                description = "伤害范围为250"
                            },
                            {
                                description = "伤害范围为300"
                            },
                            {
                                description = "伤害范围为350"
                            },
                            {
                                description = "伤害范围为400"
                            }
                        }
                    }
                },
                {
                    {
                        name = "酣畅打击",
                        description = "致死打击的怒气消耗提高，伤害提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("致死打击", "Art"),
                        cundangIndex = 10, -- 确保是整数
                        effect = {
                            {
                                description = "怒气消耗提高1，伤害提高2%"
                            },
                            {
                                description = "怒气消耗提高2，伤害提高4%"
                            },
                            {
                                description = "怒气消耗提高3，伤害提高6%"
                            },
                            {
                                description = "怒气消耗提高4，伤害提高8%"
                            },
                            {
                                description = "怒气消耗提高5，伤害提高10%"
                            }
                        }
                    },
                    {
                        name = "怒发冲冠",
                        description = "怒气值上限提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("泰坦之握", "Art"),
                        cundangIndex = 11, -- 确保是整数
                        effect = {
                            {
                                action = CONST_EVENT.attr,
                                effect = _attr({ mana = "+2" })
                            },
                            {
                                action = CONST_EVENT.attr,
                                effect = _attr({ mana = "+2" })
                            },
                            {
                                action = CONST_EVENT.attr,
                                effect = _attr({ mana = "+2" })
                            },
                            {
                                action = CONST_EVENT.attr,
                                effect = _attr({ mana = "+2" })
                            },
                            {
                                action = CONST_EVENT.attr,
                                effect = _attr({ mana = "+2" })
                            }
                        }
                    },
                    {
                        name = "撕裂猛击",
                        description = "猛击有概率撕裂目标",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("猛击", "Art"),
                        cundangIndex = 12, -- 确保是整数
                        effect = {
                            {
                                description = "概率为20%"
                            },
                            {
                                description = "概率为40%"
                            },
                            {
                                description = "概率为60%"
                            },
                            {
                                description = "概率为80%"
                            },
                            {
                                description = "概率为100%"
                            }
                        }
                    }
                }
            }
        },
        fuzhutianfu
        -- 省略其他天赋类型，保持示例简洁
    },
    shejilieren = {
        shuchutianfu,
        fangyutianfu,
        {
            tianfutype = "专精",
            tianfu = {
                {
                    {
                        name = "猎人标记",
                        description = "瞄准射击有概率标记目标5秒，使目标受到所有伤害提高3%。如果伤害来源是猎人，则效果翻倍",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\lieren\\Ability_Hunter_SniperShot.blp",
                        cundangIndex = 1, -- 确保是整数
                        effect = {
                            {
                                description = "瞄准射击标记概率20%"
                            },
                            {
                                description = "瞄准射击标记概率40%"
                            },
                            {
                                description = "瞄准射击标记概率60%"
                            },
                            {
                                description = "瞄准射击标记概率80%"
                            },
                            {
                                description = "瞄准射击标记概率100%"
                            }
                        }
                    },
                    {
                        name = "巨蛇追猎者的诡计",
                        description = "多重射击有一定概率给目标施加毒蛇钉刺",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("多重射击", "Art"),
                        cundangIndex = 2, -- 确保是整数
                        effect = {
                            {
                                description = "施加概率为5%"
                            },
                            {
                                description = "施加概率为10%"
                            },
                            {
                                description = "施加概率为15%"
                            },
                            {
                                description = "施加概率为20%"
                            },
                            {
                                description = "施加概率为25%"
                            }
                        }
                    },
                    {
                        name = "齐射",
                        description = "多重射击会使得猎人的下一次多重射击伤害提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("多重射击", "Art"),
                        cundangIndex = 3, -- 确保是整数
                        effect = {
                            {
                                description = "伤害提高10%"
                            },
                            {
                                description = "伤害提高20%"
                            },
                            {
                                description = "伤害提高30%"
                            },
                            {
                                description = "伤害提高40%"
                            },
                            {
                                description = "伤害提高50%"
                            }
                        }
                    }
                },
                {
                    {
                        name = "强化高效瞄准",
                        description = "高效瞄准触发概率提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\lieren\\miaozhunsheji.blp",
                        cundangIndex = 4, -- 确保是整数
                        effect = {
                            {
                                description = "高效瞄准触发概率提高1%"
                            },
                            {
                                description = "高效瞄准触发概率额外提高1%"
                            },
                            {
                                description = "高效瞄准触发概率额外提高1%"
                            },
                            {
                                description = "高效瞄准触发概率额外提高1%"
                            },
                            {
                                description = "高效瞄准触发概率额外提高1%"
                            }
                        }
                    },
                    {
                        name = "强化荷枪实弹",
                        description = "强化荷枪实弹触发概率提高",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\lieren\\heqiangshidan.blp",
                        cundangIndex = 5, -- 确保是整数
                        effect = {
                            {
                                description = "荷枪实弹触发概率提高1%"
                            },
                            {
                                description = "荷枪实弹触发概率额外提高1%"
                            },
                            {
                                description = "荷枪实弹触发概率额外提高1%"
                            },
                            {
                                description = "荷枪实弹触发概率额外提高1%"
                            },
                            {
                                description = "荷枪实弹触发概率额外提高1%"
                            }
                        }
                    },
                    {
                        name = "风行者的祝福",
                        description = "风行者之箭有概率转化为风行者祝福之箭，伤害为风行者之箭的5倍且为物理伤害",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\lieren\\PASBTN_BD2.blp",
                        cundangIndex = 6, -- 确保是整数
                        effect = {
                            {
                                description = "风行者之箭有2%概率转化为风行者祝福之箭"
                            },
                            {
                                description = "风行者之箭有额外2%概率转化为风行者祝福之箭"
                            },
                            {
                                description = "风行者之箭有额外2%概率转化为风行者祝福之箭"
                            },
                            {
                                description = "风行者之箭有额外2%概率转化为风行者祝福之箭"
                            },
                            {
                                description = "风行者之箭有额外2%概率转化为风行者祝福之箭"
                            }
                        }
                    }
                },
                {
                    {
                        name = "奥术快速射击",
                        description = "快速射击每次射击有概率替换为奥术射击",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\lieren\\Ability_Hunter_Efficiency.blp",
                        cundangIndex = 7, -- 确保是整数
                        effect = {
                            {
                                description = "快速射击每次射击有4%概率替换为奥术射击"
                            },
                            {
                                description = "快速射击每次射击有额外4%概率替换为奥术射击"
                            },
                            {
                                description = "快速射击每次射击有额外4%概率替换为奥术射击"
                            },
                            {
                                description = "快速射击每次射击有额外4%概率替换为奥术射击"
                            },
                            {
                                description = "快速射击每次射击有额外4%概率替换为奥术射击"
                            }
                        }
                    },
                    {
                        name = "瞄准快速射击",
                        description = "快速射击每次射击有概率替换为瞄准射击，但是该次瞄准射击无法触发高效瞄准",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\lieren\\Ability_Hunter_Efficiency.blp",
                        cundangIndex = 8, -- 确保是整数
                        effect = {
                            {
                                description = "快速射击每次射击有4%概率替换为瞄准射击"
                            },
                            {
                                description = "快速射击每次射击有额外4%概率替换为瞄准射击"
                            },
                            {
                                description = "快速射击每次射击有额外4%概率替换为瞄准射击"
                            },
                            {
                                description = "快速射击每次射击有额外4%概率替换为瞄准射击"
                            },
                            {
                                description = "快速射击每次射击有额外4%概率替换为瞄准射击"
                            }
                        }
                    },
                    {
                        name = "光速射击",
                        description = "猎人的快速射击技巧上升到了一个新高度，可以射出更多箭矢",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\lieren\\Ability_Hunter_Efficiency.blp",
                        cundangIndex = 9, -- 确保是整数
                        effect = {
                            {
                                description = ""
                            },
                            {
                                description = "快速射击额外射出一只箭矢"
                            },
                            {
                                description = ""
                            },
                            {
                                description = ""
                            },
                            {
                                description = "快速射击额外射出两只箭矢"
                            }
                        }
                    }
                },
                {
                    {
                        name = "致命奥术射击",
                        description = "奥术射击会提高你的法术暴击率，最高8层，持续8秒。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("奥术射击", "Art"),
                        cundangIndex = 10, -- 确保是整数
                        effect = {
                            {
                                description = "提高0.2%"
                            },
                            {
                                description = "提高0.4%"
                            },
                            {
                                description = "提高0.6%"
                            },
                            {
                                description = "提高0.8%"
                            },
                            {
                                description = "提高1%"
                            }
                        }
                    },
                    {
                        name = "致命瞄准射击",
                        description = "瞄准射击会提高你的物理暴击率，最高8层，持续8秒。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("瞄准射击", "Art"),
                        cundangIndex = 11, -- 确保是整数
                        effect = {
                            {
                                description = "提高0.2%"
                            },
                            {
                                description = "提高0.4%"
                            },
                            {
                                description = "提高0.6%"
                            },
                            {
                                description = "提高0.8%"
                            },
                            {
                                description = "提高1%"
                            }
                        }
                    },
                    {
                        name = "穿透箭",
                        description =
                        "基础射击有概率会穿透目标并自动寻找下一个目标，可以对一个目标造成重复伤害，可以重复触发，最多穿透三次。会触发风行者的馈赠等攻击特效，不会触发基础射击的回蓝以及荷枪实弹。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("基础射击", "Art"),
                        cundangIndex = 12, -- 确保是整数
                        effect = {
                            {
                                description = "概率为5%"
                            },
                            {
                                description = "概率为10%"
                            },
                            {
                                description = "概率为15%"
                            },
                            {
                                description = "概率为20%"
                            },
                            {
                                description = "概率为25%"
                            }
                        }
                    }
                }
            }
        },
        fuzhutianfu
        -- 省略其他天赋类型，保持示例简洁
    },
    emolieshou = {
        shuchutianfu,
        fangyutianfu,
        {
            tianfutype = "专精",
            tianfu = {
                {
                    {
                        name = "献祭",
                        description = "使你的刃舞释放完成后会激活献祭光环，每秒对300码范围内的敌人造成火焰魔法伤害，持续5秒，cd8秒",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\CommandButtons\\BTNImmolationOn.blp",
                        cundangIndex = 1, -- 确保是整数
                        effect = {
                            {
                                description = "献祭造成每秒15%敏捷的伤害"
                            },
                            {
                                description = "献祭造成每秒30%敏捷的伤害"
                            },
                            {
                                description = "献祭造成每秒45%敏捷的伤害"
                            },
                            {
                                description = "献祭造成每秒60%敏捷的伤害"
                            },
                            {
                                description = "献祭造成每秒75%敏捷的伤害"
                            }
                        }
                    },
                    {
                        name = "战刃风暴",
                        description = "使你的投掷利刃会在命中目标时在原地留下一对战刃持续斩击目标区域单位造成金系物理伤害，持续6秒，cd9秒",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\DH\\classicon_demonhunter.blp",
                        cundangIndex = 2, -- 确保是整数
                        effect = {
                            {
                                description = "伤害为攻击+敏捷的10%"
                            },
                            {
                                description = "伤害为攻击+敏捷的20%"
                            },
                            {
                                description = "伤害为攻击+敏捷的30%"
                            },
                            {
                                description = "伤害为攻击+敏捷的40%"
                            },
                            {
                                description = "伤害为攻击+敏捷的50%"
                            }
                        }
                    },
                    {
                        name = "盲目之怒",
                        description = "眼棱伤害次数增加",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\DH\\ability_demonhunter_eyebeam.blp",
                        cundangIndex = 3, -- 确保是整数
                        effect = {
                            {
                                description = "眼棱伤害次数增加1"
                            },
                            {
                                description = "眼棱伤害次数增加2"
                            },
                            {
                                description = "眼棱伤害次数增加3"
                            },
                            {
                                description = "眼棱伤害次数增加4"
                            },
                            {
                                description = "眼棱伤害次数增加5"
                            }
                        }
                    }
                },
                {
                    {
                        name = "灼热之伤",
                        description = "刃舞会让你对目标每秒造成混乱魔法伤害，持续4秒，同时提高目标受到的献祭伤害",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\DH\\ability_bosskilrogg_deadeye.blp",
                        cundangIndex = 4, -- 确保是整数
                        effect = {
                            {
                                description = "每秒造成10%敏捷的伤害，该状态下目标受到献祭伤害提高5%"
                            },
                            {
                                description = "每秒造成20%敏捷的伤害，该状态下目标受到献祭伤害提高10%"
                            },
                            {
                                description = "每秒造成3%敏捷的伤害，该状态下目标受到献祭伤害提高15%"
                            },
                            {
                                description = "每秒造成40%敏捷的伤害，该状态下目标受到献祭伤害提高20%"
                            },
                            {
                                description = "每秒造成50%敏捷的伤害，该状态下目标受到献祭伤害提高25%"
                            }
                        }
                    },
                    {
                        name = "战刃充能",
                        description = "裂魂伤害有概率刷新你投掷利刃的cd，cd3秒",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\DH\\ability_demonhunter_throwglaive.blp",
                        cundangIndex = 5, -- 确保是整数
                        effect = {
                            {
                                description = "刷新概率为3%"
                            },
                            {
                                description = "刷新概率为6%"
                            },
                            {
                                description = "刷新概率为9%"
                            },
                            {
                                description = "刷新概率为12%"
                            },
                            {
                                description = "刷新概率为15%"
                            }
                        }
                    },
                    {
                        name = "恶魔之眼",
                        description = "眼棱每次造成伤害会减少眼棱cd",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\DH\\artifactability_havocdemonhunter_anguishofthedeceiver.blp",
                        cundangIndex = 6, -- 确保是整数
                        effect = {
                            {
                                description = "眼棱每次伤害降低0.1秒cd"
                            },
                            {
                                description = "眼棱每次伤害降低0.2秒cd"
                            },
                            {
                                description = "眼棱每次伤害降低0.3秒cd"
                            },
                            {
                                description = "眼棱每次伤害降低0.4秒cd"
                            },
                            {
                                description = "眼棱每次伤害降低0.5秒cd"
                            }
                        }
                    }
                },
                {
                    {
                        name = "烈焰符咒",
                        description = "刃舞会在脚下释放一枚烈焰符咒，1秒后爆发造成的火焰魔法伤害，并提升目标所受到的所有伤害",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\DH\\ability_demonhunter_sigilofinquisition.blp",
                        cundangIndex = 7, -- 确保是整数
                        effect = {
                            {
                                description = "符咒爆发造成40%（攻击+敏捷）的伤害，提升目标受到的所有伤害0.6%"
                            },
                            {
                                description = "符咒爆发造成80%（攻击+敏捷）的伤害，提升目标受到的所有伤害1.2%"
                            },
                            {
                                description = "符咒爆发造成120%（攻击+敏捷）的伤害，提升目标受到的所有伤害1.8%"
                            },
                            {
                                description = "符咒爆发造成160%（攻击+敏捷）的伤害，提升目标受到的所有伤害2.4%"
                            },
                            {
                                description = "符咒爆发造成200%（攻击+敏捷）的伤害，提升目标受到的所有伤害3.0%"
                            }
                        }
                    },
                    {
                        name = "恶魔追击",
                        description = "投掷利刃可以使你下次A键攻击目标可以冲向目标并造成额外的混乱物理伤害，持续10秒",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\DH\\ability_demonhunter_doublejump.blp",
                        cundangIndex = 8, -- 确保是整数
                        effect = {
                            {
                                description = "冲锋最大距离600，造成30%（攻击+敏捷）的伤害"
                            },
                            {
                                description = "冲锋最大距离650，造成60%（攻击+敏捷）的伤害"
                            },
                            {
                                description = "冲锋最大距离700，造成90%（攻击+敏捷）的伤害"
                            },
                            {
                                description = "冲锋最大距离750，造成120%（攻击+敏捷）的伤害"
                            },
                            {
                                description = "冲锋最大距离800，造成150%（攻击+敏捷）的伤害"
                            }
                        }
                    },
                    {
                        name = "仇恨之轮",
                        description = "刃舞、混乱打击、投掷利刃每次释放会减少恶魔变形的cd",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\DH\\spell_fire_felfirenova.blp",
                        cundangIndex = 9, -- 确保是整数
                        effect = {
                            {
                                description = "减少0.4秒cd"
                            },
                            {
                                description = "减少0.8秒cd"
                            },
                            {
                                description = "减少1.2秒cd"
                            },
                            {
                                description = "减少1.6秒cd"
                            },
                            {
                                description = "减少2秒cd"
                            }
                        }
                    }
                },
                {
                    {
                        name = "不择手段",
                        description = "你造成的所有火焰伤害将受到精通加成",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = "ReplaceableTextures\\DH\\ability_demonhunter_sigilofinquisition.blp",
                        cundangIndex = 10, -- 确保是整数
                        effect = {
                            {
                                description = "20%精通加成"
                            },
                            {
                                description = "40%精通加成"
                            },
                            {
                                description = "60%精通加成"
                            },
                            {
                                description = "80%精通加成"
                            },
                            {
                                description = "100%精通加成"
                            }
                        }
                    },
                    {
                        name = "无情狩猎",
                        description = "施放邪能冲撞和恶魔追击后会让你下一个混乱打击或者刃舞伤害提升",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("邪能冲撞", "Art"),
                        cundangIndex = 11, -- 确保是整数
                        effect = {
                            {
                                description = "提高6%"
                            },
                            {
                                description = "提高12%"
                            },
                            {
                                description = "提高18%"
                            },
                            {
                                description = "提高24%"
                            },
                            {
                                description = "提高30%"
                            }
                        }
                    },
                    {
                        name = "恶魔释放",
                        description =
                        "进入恶魔形态会提升你物理魔法暴击伤害，持续8秒。",
                        activePoints = { 0, 0, 0, 0, 0 },
                        cundangStr = "zhuanjingtianfu",
                        art = hslk.n2v("恶魔变形", "Art"),
                        cundangIndex = 12, -- 确保是整数
                        effect = {
                            {
                                description = "提升3%的爆伤"
                            },
                            {
                                description = "提升6%的爆伤"
                            },
                            {
                                description = "提升9%的爆伤"
                            },
                            {
                                description = "提升12%的爆伤"
                            },
                            {
                                description = "提升15%的爆伤"
                            }
                        }
                    }
                }
            }
        },
        fuzhutianfu
        -- 省略其他天赋类型，保持示例简洁
    }
}
