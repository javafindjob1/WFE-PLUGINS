table.insert(
    FUBEN_LIST,
    {
        name = "圣光大教堂",
        setup = function()
            local nanduLevelConfig = {}
            nanduLevelConfig[FUBEN_NANDU.PUTONG] = 39
            nanduLevelConfig[FUBEN_NANDU.YINGXIONG] = 39
            nanduLevelConfig[FUBEN_NANDU.SHISHI] = 39
            nanduLevelConfig[FUBEN_NANDU.CHUANQI] = 60

            local yuzhanyuyong = {
                description = "愈战愈勇：完美缝合怪的攻击能额外造成最多100%攻击力的伤害，并且每次攻击后有50%的概率由于嗜血的本能会增加1%的攻击速度和1%的攻击力，持续60秒，可以无限叠加",
                attr_type = CONST_EVENT.beforeAttackDamage,
                attr = function(evtData)
                    evtData.damage = evtData.damage * math.random(100, 200) / 100
                    if math.random(1, 100) <= 50 then
                        local extraAttack = hattribute.get(evtData.sourceUnit, "attack_white", 100) * 0.01
                        hbuff.addStackAttrBuff(
                            CONST_DAMAGE_SRC.skill,
                            evtData.sourceUnit,
                            "愈战愈勇",
                            _attr({ attack = "+" .. tostring(extraAttack), attack_speed = "+1", move = "+5" }),
                            60,
                            9999,
                            "ReplaceableTextures\\PASBTN_spell09.blp",
                            "愈战愈勇：每层增加1%的攻击速度和2%的攻击力，持续60秒，可以无限叠加",
                            true
                        )
                    end
                end
            }

            local gedang = {
                description = "格挡专精，增加30%格挡",
                attr_type = CONST_EVENT.attr,
                attr = _attr({ gedang = "+30" })
            }

            local mushiAI = function(level, nandu)
                return UnitAI(
                    {
                        {
                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                name = "强效治疗术",
                                --healthBelowLimit = 100,
                                --notInterruptable = false,
                                minNandu = FUBEN_NANDU.PUTONG,
                                shifashijian = 3.0,
                                castCD = 12 - nandu, -- nil or <=1 means 1 second
                                customCondition = function(whichUnit)
                                    local groups = hgroup.createAllyGroupByUnit(whichUnit, 600)
                                    for _, unit in ipairs(groups) do
                                        if hunit.getCurLifePercent(unit) <= 50 then
                                            return true
                                        end
                                    end
                                    return false
                                end,
                                startEffect = function(evtData)
                                end,
                                periodEffect = function(evtData)
                                end,
                                effect = function(evtData)
                                    local target =
                                        hgroup.getLowestHealth(
                                            hgroup.createAllyGroupByUnit(evtData.triggerUnit, 800),
                                            hunit.x(evtData.triggerUnit),
                                            hunit.y(evtData.triggerUnit)
                                        )
                                    if target ~= nil then
                                        hskill.heal(
                                            {
                                                healer = evtData.triggerUnit,
                                                healee = target,
                                                heal = hunit.getMaxLife(target) * (0.1 + 0.05 * nandu),
                                                healType = HEAL_TYPE.SKILL,
                                                triggerSkill = hslk.n2i("AI技能模版")
                                            }
                                        )
                                    end
                                end
                            }
                        },
                        {
                            aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                            }
                        }
                    }
                )
            end

            hfuben.buildFuben(
                {
                    name = "圣光大教堂", --副本名字
                    status = FUBEN_STATUS.JIANHUA,
                    blp = "ReplaceableTextures\\xiaoditu\\UI_map_11.blp",
                    enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_09.blp",
                    nanduLevelConfig = nanduLevelConfig,                               -- 副本难度以及级别需求,
                    entryPosition = { x = -19738, y = -14988 },
                    startPosition = { x = 5452, y = 3054 },                            --英雄进副本后位置
                    rectParam = { minX = 962, minY = 2463, maxX = 7000, maxY = 8248 }, -- 副本区域
                    minions = {
                        {
                            name = "教堂近卫军", -- 名字 需要在物编定义好
                            x = 5841, -- 小怪刷新x坐标
                            y = 3417, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { gedang }, { gedang }, { gedang }, { gedang } }
                        },
                        {
                            name = "教堂近卫军", -- 名字 需要在物编定义好
                            x = 6176, -- 小怪刷新x坐标
                            y = 3417, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { gedang }, { gedang }, { gedang }, { gedang } }
                        },
                        {
                            name = "教堂近卫军", -- 名字 需要在物编定义好
                            x = 6491, -- 小怪刷新x坐标
                            y = 3417, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { gedang }, { gedang }, { gedang }, { gedang } }
                        },
                        {
                            name = "教堂近卫军", -- 名字 需要在物编定义好
                            x = 5836, -- 小怪刷新x坐标
                            y = 4529, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { gedang }, { gedang }, { gedang }, { gedang } }
                        },
                        {
                            name = "教堂牧师", -- 名字 需要在物编定义好
                            x = 5836, -- 小怪刷新x坐标
                            y = 4529, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = mushiAI,
                            passiveSkill = { {}, {}, {}, {} }
                        },
                        {
                            name = "教堂近卫军", -- 名字 需要在物编定义好
                            x = 6500, -- 小怪刷新x坐标
                            y = 4529, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { gedang }, { gedang }, { gedang }, { gedang } }
                        },
                        {
                            name = "教堂牧师", -- 名字 需要在物编定义好
                            x = 6500, -- 小怪刷新x坐标
                            y = 4529, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = mushiAI,
                            passiveSkill = { {}, {}, {}, {} }
                        },
                        {
                            name = "教堂近卫军", -- 名字 需要在物编定义好
                            x = 6500, -- 小怪刷新x坐标
                            y = 5557, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { gedang }, { gedang }, { gedang }, { gedang } }
                        },
                        {
                            name = "教堂牧师", -- 名字 需要在物编定义好
                            x = 6500, -- 小怪刷新x坐标
                            y = 5557, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = mushiAI,
                            passiveSkill = { {}, {}, {}, {} }
                        },
                        {
                            name = "教堂近卫军", -- 名字 需要在物编定义好
                            x = 5836, -- 小怪刷新x坐标
                            y = 5557, -- 小怪刷新y坐标
                            number = 2, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { gedang }, { gedang }, { gedang }, { gedang } }
                        },
                        {
                            name = "教堂牧师", -- 名字 需要在物编定义好
                            x = 5836, -- 小怪刷新x坐标
                            y = 5557, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = mushiAI,
                            passiveSkill = { {}, {}, {}, {} }
                        },
                        {
                            name = "教堂近卫军", -- 名字 需要在物编定义好
                            x = 6207, -- 小怪刷新x坐标
                            y = 6300, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { gedang }, { gedang }, { gedang }, { gedang } }
                        },
                        {
                            name = "教堂牧师", -- 名字 需要在物编定义好
                            x = 6207, -- 小怪刷新x坐标
                            y = 6400, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = mushiAI,
                            passiveSkill = { {}, {}, {}, {} }
                        },
                        {
                            name = "教堂近卫军", -- 名字 需要在物编定义好
                            x = 4935, -- 小怪刷新x坐标
                            y = 6209, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { gedang }, { gedang }, { gedang }, { gedang } }
                        },
                        {
                            name = "教堂牧师", -- 名字 需要在物编定义好
                            x = 4935, -- 小怪刷新x坐标
                            y = 6209, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = mushiAI,
                            passiveSkill = { {}, {}, {}, {} }
                        },
                        {
                            name = "教堂近卫军", -- 名字 需要在物编定义好
                            x = 4935, -- 小怪刷新x坐标
                            y = 5209, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { gedang }, { gedang }, { gedang }, { gedang } }
                        },
                        {
                            name = "教堂牧师", -- 名字 需要在物编定义好
                            x = 4935, -- 小怪刷新x坐标
                            y = 5209, -- 小怪刷新y坐标
                            number = 3, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = mushiAI,
                            passiveSkill = { {}, {}, {}, {} }
                        },
                        {
                            name = "试验腐败缝合怪", -- 名字 需要在物编定义好
                            x = 4494, -- 小怪刷新x坐标
                            y = 4056, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = {
                                { yuzhanyuyong },
                                { yuzhanyuyong },
                                { yuzhanyuyong },
                                { yuzhanyuyong }
                            }
                        },
                        {
                            name = "试验腐败缝合怪", -- 名字 需要在物编定义好
                            x = 4337, -- 小怪刷新x坐标
                            y = 3022, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = {
                                { yuzhanyuyong },
                                { yuzhanyuyong },
                                { yuzhanyuyong },
                                { yuzhanyuyong }
                            }
                        },
                        {
                            name = "试验腐败缝合怪", -- 名字 需要在物编定义好
                            x = 3043, -- 小怪刷新x坐标
                            y = 4645, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = {
                                { yuzhanyuyong },
                                { yuzhanyuyong },
                                { yuzhanyuyong },
                                { yuzhanyuyong }
                            }
                        },
                        {
                            name = "试验腐败缝合怪", -- 名字 需要在物编定义好
                            x = 1279, -- 小怪刷新x坐标
                            y = 4100, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = {
                                { yuzhanyuyong },
                                { yuzhanyuyong },
                                { yuzhanyuyong },
                                { yuzhanyuyong }
                            }
                        },
                        {
                            name = "试验腐败缝合怪", -- 名字 需要在物编定义好
                            x = 1371, -- 小怪刷新x坐标
                            y = 2947, -- 小怪刷新y坐标
                            number = 1, -- 小怪朝向
                            monsterType = MONSTER_TYPE.FUBEN_JINGYING,
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = {
                                { yuzhanyuyong, },
                                { yuzhanyuyong, },
                                { yuzhanyuyong, },
                                { yuzhanyuyong, }
                            }
                        },
                        {
                            name = "教堂近卫军", -- 名字 需要在物编定义好
                            x = 2000, -- 小怪刷新x坐标
                            y = 5800, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { gedang }, { gedang }, { gedang }, { gedang } }
                        },
                        {
                            name = "教堂牧师", -- 名字 需要在物编定义好
                            x = 2000, -- 小怪刷新x坐标
                            y = 5900, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = mushiAI,
                            passiveSkill = { {}, {}, {}, {} }
                        },
                        {
                            name = "教堂近卫军", -- 名字 需要在物编定义好
                            x = 3000, -- 小怪刷新x坐标
                            y = 5800, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { gedang }, { gedang }, { gedang }, { gedang } }
                        },
                        {
                            name = "教堂牧师", -- 名字 需要在物编定义好
                            x = 3000, -- 小怪刷新x坐标
                            y = 5900, -- 小怪刷新y坐标
                            number = 4, -- 小怪朝向
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = XIAOGUAI_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            200,
                                            200,
                                            200,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = mushiAI,
                            passiveSkill = { {}, {}, {}, {} }
                        }
                    },
                    bosses = {
                        {
                            name = "裁判长萨提斯",
                            x = 5533,
                            y = 7366,
                            levelAdj = 0,
                            diaoluoConfig = DiaoLuoConfig(
                                {
                                    {
                                        list = BOSS_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            10000,
                                            10000,
                                            10000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "战败勇士的鞋子" },
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            1000,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "惩戒巨斧", "裁判者之影", "惩戒巨弓", "致命圣契" },
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2000,
                                            2000,
                                            2000,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = function(level, nandu)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "致命审判",
                                                healthBelowLimit = 99,
                                                notInterruptable = false,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 2,
                                                castCD = 20, -- nil or <=1 means 1 second
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local basicAttack =
                                                        hattribute.get(evtData.triggerUnit, "attack", 100)
                                                    heffect.attach(
                                                        "war3mapImported\\[qishi]shenpan_1.mdx",
                                                        evtData.targetUnit,
                                                        "origin",
                                                        0
                                                    )
                                                    hskill.damage(
                                                        {
                                                            sourceUnit = evtData.triggerUnit,
                                                            targetUnit = evtData.targetUnit,
                                                            damage = 2 * basicAttack,
                                                            damageType = DAMAGE_TYPE.MOFA,
                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                            damageElementType = CONST_DAMAGE_ELEMENT_TYPE.LIGHT,
                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                        }
                                                    )
                                                    hbuff.update(
                                                        5,
                                                        evtData.targetUnit,
                                                        "致命审判debuff",
                                                        false,
                                                        function()
                                                            hevent.register(
                                                                evtData.targetUnit,
                                                                CONST_EVENT.damagingCustomTarget,
                                                                "致命审判debuff受到伤害",
                                                                function(evtData)
                                                                    evtData.damage = evtData.damage * 2
                                                                end
                                                            )
                                                        end,
                                                        function()
                                                            hevent.unregister(
                                                                evtData.targetUnit,
                                                                CONST_EVENT.damagingCustomTarget,
                                                                "致命审判debuff受到伤害"
                                                            )
                                                        end,
                                                        "ReplaceableTextures\\KUANGRE\\PASKUANGRE.blp",
                                                        "致命审判使得单位受到的任意伤害翻倍",
                                                        nil,
                                                        nil,
                                                        nil,
                                                        nil,
                                                        nil,
                                                        HBUFF_UPDATE_MODE.OVERWRITE,
                                                        true
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "狂暴顺劈",
                                                healthBelowLimit = 99,
                                                notInterruptable = true,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 1.8,
                                                castCD = 15 - nandu * 2, -- nil or <=1 means 1 second
                                                startEffect = function(evtData)
                                                    hskillMoban.radiusWarning(
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit),
                                                        hunit.z(evtData.triggerUnit),
                                                        400,
                                                        evtData.shifashijian
                                                    )
                                                    hunit.setAnimateSpeed(
                                                        evtData.triggerUnit,
                                                        1 / evtData.shifashijian,
                                                        evtData.shifashijian
                                                    )
                                                    hunit.animate(evtData.triggerUnit, 9)
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    local basicAttack =
                                                        hattribute.get(evtData.triggerUnit, "attack", 100)
                                                    heffect.xyz(
                                                        "[jineng]360shunpi.mdx",
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit),
                                                        hunit.z(evtData.triggerUnit),
                                                        0,
                                                        1,
                                                        1.3,
                                                        1.3,
                                                        1,
                                                        0,
                                                        0,
                                                        hunit.getFacing(evtData.triggerUnit)
                                                    )
                                                    hskillMoban.radiusAOE(
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit),
                                                        evtData.triggerUnit,
                                                        400,
                                                        function(unit)
                                                            hskill.damage(
                                                                {
                                                                    sourceUnit = evtData.triggerUnit,
                                                                    targetUnit = unit,
                                                                    damage = 4 * basicAttack,
                                                                    damageType = DAMAGE_TYPE.WULI,
                                                                    effect = "war3mapImported\\AZ_gelie.mdx",
                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                    damageElementType = CONST_DAMAGE_ELEMENT_TYPE.METAL,
                                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                                }
                                                            )
                                                        end
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                            }
                                        }
                                    }
                                )
                            end,
                            passiveSkill = { {}, {}, {}, {} }
                        },
                        {
                            name = "完美腐败缝合怪",
                            x = 2406,
                            y = 3709,
                            levelAdj = 0,
                            diaoluoConfig = DiaoLuoConfig(
                                {
                                    {
                                        list = BOSS_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            10000,
                                            10000,
                                            10000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "战败勇士的头盔", "污染者的意志" },
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            1000,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "黑暗污染指环", "嗜血锯刃" },
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2000,
                                            2000,
                                            2000,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = function(level, nandu)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                            }
                                        }
                                    }
                                )
                            end,
                            passiveSkill = {
                                { yuzhanyuyong, },
                                { yuzhanyuyong, },
                                { yuzhanyuyong, },
                                { yuzhanyuyong, }
                            }
                        },
                        {
                            name = "圣光主教布莱克安",
                            x = 2569,
                            y = 7536,
                            levelAdj = 0,
                            diaoluoConfig = DiaoLuoConfig(
                                {
                                    {
                                        list = BOSS_BASIC_DIAOLUO, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            10000,
                                            10000,
                                            10000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "圣光之核" },
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            0,
                                            300,
                                            0
                                        }
                                    },
                                    {
                                        list = { "光明核心碎片" },
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            0,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "能量涌动护符", "战败勇士的胸甲", "战败勇士的手套" },
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            1000,
                                            1000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "光明圣契", "光辉挂坠", "主教之杖", "光明魔法书" },
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            2000,
                                            2000,
                                            2000,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = function(level, nandu)
                                return UnitAI(
                                    {
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "光暗转化",
                                                --healthBelowLimit = 90,
                                                --castCountLimit = 1,
                                                notInterruptable = true,
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                shifashijian = 5.0,
                                                castCD = 30, -- nil or <=1 means 1 second
                                                customCondition = nil,
                                                startEffect = function(evtData)
                                                    hfuben.bossHanhua(evtData.triggerUnit, "让你见识见识光明和暗影的真谛！")
                                                    local lightX = math.random(1639, 2185)
                                                    local lightY = math.random(5818, 7254)
                                                    heffect.xyz(
                                                        "[jineng]guangmingguanghuan.mdx",
                                                        lightX,
                                                        lightY,
                                                        hjapi.Z(lightX, lightY),
                                                        30,
                                                        1
                                                    )
                                                    htime.setInterval(
                                                        1,
                                                        function(curTimer)
                                                            if curTimer.passedSec() > 30 then
                                                                curTimer.destroy()
                                                                return
                                                            end
                                                            local basicAttack =
                                                                0.7 * hattribute.get(evtData.triggerUnit, "attack", 100)
                                                            hskillMoban.radiusAOE(
                                                                lightX,
                                                                lightY,
                                                                evtData.triggerUnit,
                                                                400,
                                                                function(unit)
                                                                    if hbuff.hasBuff(unit, "圣光教堂暗影光环") then
                                                                        basicAttack =
                                                                            basicAttack *
                                                                            (hbuff.getBuffHandle(unit, "圣光教堂暗影光环").stack +
                                                                                1)
                                                                        hbuff.delete(unit, "圣光教堂暗影光环")
                                                                    end
                                                                    if hbuff.hasBuff(unit, "圣光教堂光明光环") then
                                                                        basicAttack =
                                                                            basicAttack *
                                                                            (1 -
                                                                                hbuff.getBuffHandle(unit, "圣光教堂光明光环").stack *
                                                                                0.1)
                                                                    end
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = evtData.triggerUnit,
                                                                            targetUnit = unit,
                                                                            damage = basicAttack,
                                                                            damageType = DAMAGE_TYPE.MOFA,
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageElementType = CONST_DAMAGE_ELEMENT_TYPE
                                                                                .LIGHT,
                                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                .IMMEDIATE
                                                                        }
                                                                    )
                                                                    hbuff.addStackAttrBuff(
                                                                        CONST_DAMAGE_SRC.skill,
                                                                        unit,
                                                                        "圣光教堂光明光环",
                                                                        {},
                                                                        5,
                                                                        8,
                                                                        "ReplaceableTextures\\status\\guangming.blp",
                                                                        "狂暴的光明之力充斥全身，每层使单位受到的光明伤害降低10%，但是受到的黑暗伤害增加20%",
                                                                        false
                                                                    )
                                                                end
                                                            )
                                                        end
                                                    )
                                                    local darkX = math.random(3070, 3898)
                                                    local darkY = math.random(5818, 7254)
                                                    heffect.xyz(
                                                        "[jineng]heianguanghuan.mdx",
                                                        darkX,
                                                        darkY,
                                                        hjapi.Z(darkX, darkY),
                                                        30,
                                                        1
                                                    )
                                                    htime.setInterval(
                                                        2,
                                                        function(curTimer)
                                                            if curTimer.passedSec() > 30 then
                                                                curTimer.destroy()
                                                                return
                                                            end
                                                            heffect.xyz(
                                                                "[jineng]heianguanghuan.mdx",
                                                                darkX,
                                                                darkY,
                                                                hjapi.Z(darkX, darkY),
                                                                30,
                                                                1
                                                            )
                                                        end
                                                    )
                                                    htime.setInterval(
                                                        1,
                                                        function(curTimer)
                                                            if curTimer.passedSec() > 30 then
                                                                curTimer.destroy()
                                                                return
                                                            end
                                                            local basicAttack =
                                                                0.7 * hattribute.get(evtData.triggerUnit, "attack", 100)
                                                            hskillMoban.radiusAOE(
                                                                darkX,
                                                                darkY,
                                                                evtData.triggerUnit,
                                                                400,
                                                                function(unit)
                                                                    if hbuff.hasBuff(unit, "圣光教堂光明光环") then
                                                                        basicAttack =
                                                                            basicAttack *
                                                                            (hbuff.getBuffHandle(unit, "圣光教堂光明光环").stack +
                                                                                1)
                                                                        hbuff.delete(unit, "圣光教堂光明光环")
                                                                    end
                                                                    if hbuff.hasBuff(unit, "圣光教堂暗影光环") then
                                                                        basicAttack =
                                                                            basicAttack *
                                                                            (1 -
                                                                                hbuff.getBuffHandle(unit, "圣光教堂暗影光环").stack *
                                                                                0.1)
                                                                    end
                                                                    hskill.damage(
                                                                        {
                                                                            sourceUnit = evtData.triggerUnit,
                                                                            targetUnit = unit,
                                                                            damage = basicAttack,
                                                                            damageType = DAMAGE_TYPE.MOFA,
                                                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                                                            damageElementType = CONST_DAMAGE_ELEMENT_TYPE
                                                                                .DARK,
                                                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                                .IMMEDIATE
                                                                        }
                                                                    )
                                                                    hbuff.addStackAttrBuff(
                                                                        CONST_DAMAGE_SRC.skill,
                                                                        unit,
                                                                        "圣光教堂暗影光环",
                                                                        {},
                                                                        5,
                                                                        8,
                                                                        "ReplaceableTextures\\status\\anying.blp",
                                                                        "狂暴的暗影之力充斥全身，每层使单位受到的暗影伤害降低10%，但是受到的光明伤害增加20%",
                                                                        false
                                                                    )
                                                                end
                                                            )
                                                        end
                                                    )
                                                end,
                                                periodEffect = function(evtData)
                                                end,
                                                effect = function(evtData)
                                                    if
                                                        hcache.get(evtData.triggerUnit, "guanganzhuanhua", "anying") ==
                                                        "anying"
                                                    then
                                                        hunit.setRGBA(evtData.triggerUnit, 230, 199, 60, 1)
                                                        hcache.set(evtData.triggerUnit, "guanganzhuanhua", "guangming")
                                                    else
                                                        hunit.setRGBA(evtData.triggerUnit, 55, 31, 63, 1)
                                                        hcache.set(evtData.triggerUnit, "guanganzhuanhua", "anying")
                                                    end
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "无限冲击",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                shifashijian = 3,
                                                castCD = 15,           -- nil or <=1 means 1 second
                                                healthBelowLimit = 80, -- only cast when health is < 65%
                                                customCondition = function(whichUnit)
                                                    return hcache.get(whichUnit, "guanganzhuanhua") ~= nil
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local basicDamage =
                                                        1.3 * (2 + nandu) * hattr.get(sourceUnit, "attack", 0)
                                                    hskillMoban.rectAOE(
                                                        hunit.getRect(sourceUnit),
                                                        sourceUnit,
                                                        function(unit)
                                                            if hcache.get(sourceUnit, "guanganzhuanhua") == "guangming" then
                                                                hskillMoban.missile(
                                                                    {
                                                                        --model = "war3mapImported\\[SPELL]_115.mdl",
                                                                        model = "[jineng]guangmingchongji.mdx",
                                                                        scale = 1.0,
                                                                        speed = 1000,
                                                                        hover = 50,
                                                                        sourceUnit = sourceUnit,
                                                                        targetUnit = unit,
                                                                        target_face_dis = 50,
                                                                        onEnd = function(_, _, endX, endY)
                                                                            local damage = basicDamage
                                                                            if hbuff.hasBuff(unit, "圣光教堂暗影光环") then
                                                                                damage =
                                                                                    damage *
                                                                                    (hbuff.getBuffHandle(
                                                                                            unit,
                                                                                            "圣光教堂暗影光环"
                                                                                        ).stack *
                                                                                        0.2 +
                                                                                        1)
                                                                            end
                                                                            if hbuff.hasBuff(unit, "圣光教堂光明光环") then
                                                                                damage =
                                                                                    damage *
                                                                                    (1 -
                                                                                        hbuff.getBuffHandle(
                                                                                            unit,
                                                                                            "圣光教堂光明光环"
                                                                                        ).stack *
                                                                                        0.1)
                                                                            end
                                                                            hskill.damage(
                                                                                {
                                                                                    sourceUnit = sourceUnit,
                                                                                    targetUnit = unit,
                                                                                    damage = damage,
                                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                                    damageElementType =
                                                                                        CONST_DAMAGE_ELEMENT_TYPE.LIGHT,
                                                                                    damageSpeedType =
                                                                                        CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                                                }
                                                                            )
                                                                        end
                                                                    }
                                                                )
                                                            elseif hcache.get(sourceUnit, "guanganzhuanhua") == "anying" then
                                                                hskillMoban.missile(
                                                                    {
                                                                        --model = "war3mapImported\\[SPELL]_115.mdl",
                                                                        model = "[jineng]anyingchongji.mdx",
                                                                        scale = 1.0,
                                                                        speed = 1000,
                                                                        hover = 50,
                                                                        sourceUnit = sourceUnit,
                                                                        targetUnit = unit,
                                                                        target_face_dis = 50,
                                                                        onEnd = function(_, _, endX, endY)
                                                                            local damage = basicDamage
                                                                            if hbuff.hasBuff(unit, "圣光教堂光明光环") then
                                                                                damage =
                                                                                    damage *
                                                                                    (hbuff.getBuffHandle(
                                                                                            unit,
                                                                                            "圣光教堂光明光环"
                                                                                        ).stack *
                                                                                        0.2 +
                                                                                        1)
                                                                            end
                                                                            if hbuff.hasBuff(unit, "圣光教堂暗影光环") then
                                                                                damage =
                                                                                    damage *
                                                                                    (1 -
                                                                                        hbuff.getBuffHandle(
                                                                                            unit,
                                                                                            "圣光教堂暗影光环"
                                                                                        ).stack *
                                                                                        0.1)
                                                                            end
                                                                            hskill.damage(
                                                                                {
                                                                                    sourceUnit = sourceUnit,
                                                                                    targetUnit = unit,
                                                                                    damage = damage,
                                                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                                                    damageType = DAMAGE_TYPE.MOFA,
                                                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                                                    damageElementType =
                                                                                        CONST_DAMAGE_ELEMENT_TYPE.DARK,
                                                                                    damageSpeedType =
                                                                                        CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                                                                }
                                                                            )
                                                                        end
                                                                    }
                                                                )
                                                            end
                                                        end
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "光明冲击",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                castDistance = 500,
                                                shifashijian = 2,
                                                castCD = 1, -- nil or <=1 means 1 second
                                                --healthBelowLimit = 65, -- only cast when health is < 65%
                                                customCondition = function(whichUnit)
                                                    if hcache.get(whichUnit, "guanganzhuanhua") == "guangming" then
                                                        return true
                                                    else
                                                        return false
                                                    end
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local damage = (2 + nandu) * hattr.get(sourceUnit, "attack", 0)
                                                    hskillMoban.missile(
                                                        {
                                                            --model = "war3mapImported\\[SPELL]_115.mdl",
                                                            model = "[jineng]guangmingchongji.mdx",
                                                            scale = 1.0,
                                                            speed = 1000,
                                                            hover = 50,
                                                            sourceUnit = sourceUnit,
                                                            targetUnit = targetUnit,
                                                            target_face_dis = 50,
                                                            onEnd = function(_, _, endX, endY)
                                                                if hbuff.hasBuff(targetUnit, "圣光教堂暗影光环") then
                                                                    damage =
                                                                        damage *
                                                                        (hbuff.getBuffHandle(targetUnit, "圣光教堂暗影光环").stack *
                                                                            0.2 +
                                                                            1)
                                                                end
                                                                if hbuff.hasBuff(targetUnit, "圣光教堂光明光环") then
                                                                    damage =
                                                                        damage *
                                                                        (1 -
                                                                            hbuff.getBuffHandle(targetUnit, "圣光教堂光明光环").stack *
                                                                            0.1)
                                                                end
                                                                hskill.damage(
                                                                    {
                                                                        sourceUnit = sourceUnit,
                                                                        targetUnit = targetUnit,
                                                                        damage = damage,
                                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                                        damageType = DAMAGE_TYPE.MOFA,
                                                                        triggerSkill = hslk.n2i("AI技能模版"),
                                                                        damageElementType = CONST_DAMAGE_ELEMENT_TYPE
                                                                            .LIGHT,
                                                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                            .IMMEDIATE
                                                                    }
                                                                )
                                                            end
                                                        }
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "暗影冲击",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                minNandu = FUBEN_NANDU.PUTONG,
                                                castDistance = 500,
                                                shifashijian = 2,
                                                castCD = 1, -- nil or <=1 means 1 second
                                                --healthBelowLimit = 65, -- only cast when health is < 65%
                                                customCondition = function(whichUnit)
                                                    if hcache.get(whichUnit, "guanganzhuanhua") == "anying" then
                                                        return true
                                                    else
                                                        return false
                                                    end
                                                end,
                                                startEffect = function(evtData)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    local damage = (2 + nandu) * hattr.get(sourceUnit, "attack", 0)
                                                    hskillMoban.missile(
                                                        {
                                                            --model = "war3mapImported\\[SPELL]_115.mdl",
                                                            model = "[jineng]anyingchongji.mdx",
                                                            scale = 1.0,
                                                            speed = 1000,
                                                            hover = 50,
                                                            sourceUnit = sourceUnit,
                                                            targetUnit = targetUnit,
                                                            target_face_dis = 50,
                                                            onEnd = function(_, _, endX, endY)
                                                                if hbuff.hasBuff(targetUnit, "圣光教堂光明光环") then
                                                                    damage =
                                                                        damage *
                                                                        (hbuff.getBuffHandle(targetUnit, "圣光教堂光明光环").stack *
                                                                            0.2 +
                                                                            1)
                                                                end
                                                                if hbuff.hasBuff(targetUnit, "圣光教堂暗影光环") then
                                                                    damage =
                                                                        damage *
                                                                        (1 -
                                                                            hbuff.getBuffHandle(targetUnit, "圣光教堂暗影光环").stack *
                                                                            0.1)
                                                                end
                                                                hskill.damage(
                                                                    {
                                                                        sourceUnit = sourceUnit,
                                                                        targetUnit = targetUnit,
                                                                        damage = damage,
                                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                                        damageType = DAMAGE_TYPE.MOFA,
                                                                        triggerSkill = hslk.n2i("AI技能模版"),
                                                                        damageElementType = CONST_DAMAGE_ELEMENT_TYPE
                                                                            .DARK,
                                                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                            .IMMEDIATE
                                                                    }
                                                                )
                                                            end
                                                        }
                                                    )
                                                end
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                            }
                                        }
                                    }
                                )
                            end,
                            passiveSkill = { {}, {}, {}, {} }
                        }
                    },
                    tongguanjiangli = {
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience,        value = 2000 },
                                { type = HSHOP_COST_TYPE.gold,              value = 500 },
                                { type = HSHOP_COST_TYPE.gongzhenghuizhang, value = 1 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 1,
                                    shengwangname = "王城"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience,        value = 3000 },
                                { type = HSHOP_COST_TYPE.gold,              value = 600 },
                                { type = HSHOP_COST_TYPE.gongzhenghuizhang, value = 2 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 2,
                                    shengwangname = "王城"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience,        value = 4000 },
                                { type = HSHOP_COST_TYPE.gold,              value = 800 },
                                { type = HSHOP_COST_TYPE.gongzhenghuizhang, value = 3 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 3,
                                    shengwangname = "王城"
                                },
                                {
                                    value = 100,
                                    maxLevel = 0,
                                    shengwangname = "冒险者工会"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience,        value = 5000 },
                                { type = HSHOP_COST_TYPE.gold,              value = 500 },
                                { type = HSHOP_COST_TYPE.gongzhenghuizhang, value = 3 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 3,
                                    shengwangname = "王城"
                                }
                            }
                        }
                    }
                }
            )
        end
    }
)
