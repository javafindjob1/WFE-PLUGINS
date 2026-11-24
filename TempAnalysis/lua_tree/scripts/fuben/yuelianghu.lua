table.insert(
    FUBEN_LIST,
    {
        name = "月亮湖",
        setup = function()
            local xiaoguaiDiaoluoList = {
                "戒指",
                "项链",
                "披风",
                "手套",
                "衣服",
                "头盔",
                "鞋子",
                "法器"
            }
            local bossDiaoluoList = {
                "单手剑",
                "戒指",
                "项链",
                "披风",
                "手套",
                "衣服",
                "头盔",
                "鞋子",
                "法器",
                "单手锤",
                "双手剑",
                "双手斧",
                "双手锤",
                "法杖",
                "饰品"
            }

            local hanbingjianAI = {
                aiType = UNIT_AI_TYPE.CAST_SKILL,
                aiData = {
                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                    name = "寒冰箭",
                    --castCountLimit = 1, -- cast only x times per battle
                    minNandu = FUBEN_NANDU.PUTONG,
                    castCD = 1, -- nil or <=1 means 1 second
                    --healthBelowLimit = 65, -- only cast when health is < 65%
                    startEffect = function(evtData)
                    end,
                    --interval = 1,
                    periodEffect = function(evtData, curTimer)
                    end,
                    effect = function(evtData)
                        local sourceUnit = evtData.triggerUnit
                        local targetUnit = evtData.targetUnit
                        hskillMoban.missile(
                            {
                                --model = "war3mapImported\\[SPELL]_115.mdl",
                                model = "Abilities\\Weapons\\LichMissile\\LichMissile.mdl",
                                scale = 1.0,
                                speed = 1000,
                                hover = 50,
                                sourceUnit = sourceUnit,
                                targetUnit = targetUnit,
                                target_face_dis = 50,
                                onEnd = function(_, _, endX, endY)
                                    hskill.damage(
                                        {
                                            sourceUnit = sourceUnit,
                                            targetUnit = targetUnit,
                                            damage = 2.5 * hattr.get(sourceUnit, "attack", 0),
                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                            damageType = DAMAGE_TYPE.MOFA,
                                            triggerSkill = hslk.n2i("AI技能模版"),
                                            damageElementType = CONST_DAMAGE_ELEMENT_TYPE.WATER,
                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                                        }
                                    )
                                    hbuff.update(
                                        3,
                                        targetUnit,
                                        "严寒",
                                        false,
                                        function()
                                            hattribute.set(
                                                targetUnit,
                                                0,
                                                { attack_speed = "-10", move = "-50", skill_speed = "-10" }
                                            )
                                        end,
                                        function()
                                            hattribute.set(
                                                targetUnit,
                                                0,
                                                { attack_speed = "+10", move = "+50", skill_speed = "+10" }
                                            )
                                        end,
                                        "ReplaceableTextures\\fashi\\BTN_ASdQ2.blp",
                                        "严寒：降低10%的攻击，技能和50的移动速度",
                                        1,
                                        nil,
                                        nil,
                                        nil,
                                        nil,
                                        HBUFF_UPDATE_MODE.OVERWRITE,
                                        true
                                    )
                                end
                            }
                        )
                    end,
                    shifashijian = 3
                }
            }
            local yurenfashiAI =
                UnitAI(
                    {
                        hanbingjianAI,
                        {
                            aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                            aiData = {
                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                            }
                        }
                    }
                )

            local cigugongji = {
                description = "攻击有20%概率触发冰冷刺骨特效，造成1.5倍攻击力伤害，如果目标严寒状态，则伤害为2.5倍攻击",
                attr_type = CONST_EVENT.attack,
                attr = function(evtData)
                    if math.random(1, 100) <= 20 then
                        local sourceUnit = evtData.triggerUnit
                        local targetUnit = evtData.targetUnit
                        heffect.attach(
                            "Abilities\\Spells\\Other\\BreathOfFrost\\BreathOfFrostTarget.mdl",
                            targetUnit,
                            "chest",
                            0.1
                        )
                        local damageScale = 1.5
                        if hbuff.hasBuff(targetUnit, "严寒") then
                            damageScale = 2.5
                        end
                        htextTag.create2Unit(targetUnit, "冰冷刺骨", 10, "ff3300", 1, 1, 50)
                        hskill.damage(
                            {
                                sourceUnit = sourceUnit,
                                targetUnit = targetUnit,
                                damage = damageScale * hattr.get(sourceUnit, "attack", 0),
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.MOFA,
                                triggerSkill = hslk.n2i("AI技能模版"),
                                damageElementType = CONST_DAMAGE_ELEMENT_TYPE.WATER,
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE
                            }
                        )
                    end
                end
            }
            local binglengpifu = {
                description = "冰冷皮肤，该单位在被攻击时有40%的概率降低攻击者3%的攻击速度，持续5秒，可以叠加4层，满4层后击晕1秒并清空buff。",
                attr_type = CONST_EVENT.beAttackReady,
                attr = function(evtData)
                    if math.random(1, 100) <= 40 then
                        local attackUnit = evtData.attackUnit
                        local buffhandle = hbuff.getBuffHandle(attackUnit, "冰冷皮肤debuff")
                        if buffhandle ~= nil and buffhandle.stack >= 3 then
                            hbuff.delete(attackUnit, "冰冷皮肤debuff")
                            hbuff.xuanyun(attackUnit, 1)
                        else
                            hbuff.addStackAttrBuff(
                                CONST_DAMAGE_SRC.skill,
                                attackUnit,
                                "冰冷皮肤debuff",
                                { attack_speed = "-3" },
                                5,
                                4,
                                "ReplaceableTextures\\PASBTN_FS_bingjiashu.blp",
                                "每层降低3%的攻击速度",
                                false
                            )
                        end
                    end
                end
            }
            local nanduLevelConfig = {}
            nanduLevelConfig[FUBEN_NANDU.PUTONG] = 20
            nanduLevelConfig[FUBEN_NANDU.YINGXIONG] = 20
            nanduLevelConfig[FUBEN_NANDU.SHISHI] = 20
            nanduLevelConfig[FUBEN_NANDU.CHUANQI] = 60
            hfuben.buildFuben(
                {
                    name = "月亮湖", --副本名字
                    status = FUBEN_STATUS.JIANHUA,
                    blp = "ReplaceableTextures\\xiaoditu\\UI_map_07.blp",
                    enterTitleTextBlp = "ReplaceableTextures\\xiaoditu\\ui_map_show_07.blp",
                    nanduLevelConfig = nanduLevelConfig,                                    -- 副本难度以及级别需求,
                    entryPosition = { x = -28877, y = -23588 },
                    startPosition = { x = -25182, y = 5120 },                               --英雄进副本后位置
                    rectParam = { minX = -25751, minY = 4815, maxX = -19813, maxY = 8480 }, -- 副本区域
                    minions = {
                        {
                            name = "鱼人精英猎手", -- 名字 需要在物编定义好
                            x = -24985, -- 小怪刷新x坐标
                            y = 6043, -- 小怪刷新y坐标
                            number = 2, -- 小怪数量
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { cigugongji }, { cigugongji }, { cigugongji }, { cigugongji } }
                        },
                        {
                            name = "鱼人精英战士", -- 名字 需要在物编定义好
                            x = -24985, -- 小怪刷新x坐标
                            y = 6043, -- 小怪刷新y坐标
                            number = 1, -- 小怪数量
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { binglengpifu }, { binglengpifu }, { binglengpifu }, { binglengpifu } }
                        },
                        {
                            name = "鱼人精英猎手", -- 名字 需要在物编定义好
                            x = -24265, -- 小怪刷新x坐标
                            y = 7623, -- 小怪刷新y坐标
                            number = 1, -- 小怪数量
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { cigugongji }, { cigugongji }, { cigugongji }, { cigugongji } }
                        },
                        {
                            name = "鱼人精英猎手", -- 名字 需要在物编定义好
                            x = -23965, -- 小怪刷新x坐标
                            y = 7623, -- 小怪刷新y坐标
                            number = 1, -- 小怪数量
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { cigugongji }, { cigugongji }, { cigugongji }, { cigugongji } }
                        },
                        {
                            name = "鱼人精英猎手", -- 名字 需要在物编定义好
                            x = -23654, -- 小怪刷新x坐标
                            y = 6585, -- 小怪刷新y坐标
                            number = 2, -- 小怪数量
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { cigugongji }, { cigugongji }, { cigugongji }, { cigugongji } }
                        },
                        {
                            name = "鱼人精英战士", -- 名字 需要在物编定义好
                            x = -23654, -- 小怪刷新x坐标
                            y = 6585, -- 小怪刷新y坐标
                            number = 2, -- 小怪数量
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { binglengpifu }, { binglengpifu }, { binglengpifu }, { binglengpifu } }
                        },
                        {
                            name = "鱼人精英战士", -- 名字 需要在物编定义好
                            x = -22460, -- 小怪刷新x坐标
                            y = 7286, -- 小怪刷新y坐标
                            number = 2, -- 小怪数量
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { binglengpifu }, { binglengpifu }, { binglengpifu }, { binglengpifu } }
                        },
                        {
                            name = "鱼人精英法师", -- 名字 需要在物编定义好
                            x = -22460, -- 小怪刷新x坐标
                            y = 7286, -- 小怪刷新y坐标
                            number = 2, -- 小怪数量
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = yurenfashiAI
                        },
                        {
                            name = "鱼人精英战士", -- 名字 需要在物编定义好
                            x = -20924, -- 小怪刷新x坐标
                            y = 7176, -- 小怪刷新y坐标
                            number = 3, -- 小怪数量
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { binglengpifu }, { binglengpifu }, { binglengpifu }, { binglengpifu } }
                        },
                        {
                            name = "鱼人精英猎手", -- 名字 需要在物编定义好
                            x = -20832, -- 小怪刷新x坐标
                            y = 5721, -- 小怪刷新y坐标
                            number = 2, -- 小怪数量
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { cigugongji }, { cigugongji }, { cigugongji }, { cigugongji } }
                        },
                        {
                            name = "鱼人精英战士", -- 名字 需要在物编定义好
                            x = -20832, -- 小怪刷新x坐标
                            y = 5721, -- 小怪刷新y坐标
                            number = 2, -- 小怪数量
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = { { binglengpifu }, { binglengpifu }, { binglengpifu }, { binglengpifu } }
                        },
                        {
                            name = "鱼人精英法师", -- 名字 需要在物编定义好
                            x = -20832, -- 小怪刷新x坐标
                            y = 5721, -- 小怪刷新y坐标
                            number = 2, -- 小怪数量
                            diaoluoConfig = DiaoLuoConfig( --掉落配置
                                {
                                    {
                                        list = xiaoguaiDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            1000,
                                            1000,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = yurenfashiAI
                        }
                    },
                    bosses = {
                        {
                            name = "绿鳞",
                            x = -24088,
                            y = 8000,
                            levelAdj = 0,
                            diaoluoConfig = DiaoLuoConfig(
                                {
                                    {
                                        list = bossDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            10000,
                                            10000,
                                            10000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "蓝影衣服", "绿鳞的皮", "绿鳞的冷铁匕首" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            3000,
                                            3000,
                                            3000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "残破的鱼竿" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            100,
                                            300,
                                            500,
                                            0
                                        }
                                    },
                                    {
                                        list = { "魔物精魄" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            700,
                                            1500,
                                            3000,
                                            0
                                        }
                                    }
                                }
                            ),
                            passiveSkill = {
                                { cigugongji, binglengpifu },
                                { cigugongji, binglengpifu },
                                { cigugongji, binglengpifu },
                                { cigugongji, binglengpifu }
                            }
                        },
                        {
                            name = "黑鳞",
                            x = -20624,
                            y = 7476,
                            levelAdj = 0,
                            diaoluoConfig = DiaoLuoConfig(
                                {
                                    {
                                        list = bossDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            10000,
                                            10000,
                                            10000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "蓝影头盔", "蓝影鞋子", "沉重的黑木法杖" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            3000,
                                            3000,
                                            3000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "魔物精魄" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            700,
                                            1500,
                                            3000,
                                            0
                                        }
                                    }
                                }
                            ),
                            ai = UnitAI(
                                {
                                    hanbingjianAI,
                                    {
                                        aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                        aiData = {
                                            targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                        }
                                    }
                                }
                            )
                        },
                        {
                            name = "银鳞",
                            x = -22671,
                            y = 5527,
                            levelAdj = 0,
                            diaoluoConfig = DiaoLuoConfig(
                                {
                                    {
                                        list = bossDiaoluoList, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            10000,
                                            10000,
                                            10000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "蓝影披风", "蓝影手套", "银鳞胸甲", "浸水的魔法书", "湛蓝坠饰" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            3000,
                                            3000,
                                            3000,
                                            0
                                        }
                                    },
                                    {
                                        list = { "银色鳞片" },
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            0,
                                            300,
                                            500,
                                            0
                                        }
                                    },
                                    {
                                        list = { "魔物精魄" }, --物品名字 需要在物编定义好
                                        drop_rate = {
                                            --掉率 以此对应 普通 英雄 史诗 传奇副本难度
                                            1000,
                                            2500,
                                            4000,
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
                                                name = "龙力激荡",
                                                minNandu = FUBEN_NANDU.YINGXIONG,
                                                --castCountLimit = 1, -- cast only x times per battle
                                                castCD = 30,           -- nil or <=1 means 1 second
                                                healthBelowLimit = 50, -- only cast when health is < 65%
                                                startEffect = function(evtData)
                                                    hsound.voice2Unit(
                                                        hsound.voiceCreate(
                                                            "resource\\war3mapImported\\sound\\warning.wav",
                                                            1000,
                                                            true
                                                        ),
                                                        100,
                                                        evtData.triggerUnit
                                                    )
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                effect = function(evtData)
                                                    heffect.xyz(
                                                        "war3mapImported\\[Spell]_032.mdx",
                                                        hunit.x(evtData.triggerUnit),
                                                        hunit.y(evtData.triggerUnit),
                                                        hunit.z(evtData.triggerUnit),
                                                        0,
                                                        1,
                                                        3,
                                                        3,
                                                        1
                                                    )
                                                    local rect = hunit.getRect(evtData.triggerUnit)
                                                    if rect == nil then
                                                        err("rect is nil")
                                                    else
                                                        hskillMoban.rectAOE(
                                                            rect,
                                                            evtData.triggerUnit,
                                                            function(target)
                                                                hskill.damage(
                                                                    {
                                                                        sourceUnit = evtData.triggerUnit,
                                                                        targetUnit = target,
                                                                        damage = hattribute.getWithLimit(
                                                                            evtData.triggerUnit,
                                                                            nil,
                                                                            "attack",
                                                                            0
                                                                        ) * 10,
                                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                                        damageType = DAMAGE_TYPE.MOFA,
                                                                        triggerSkill = hslk.n2i("AI技能模版")
                                                                    }
                                                                )
                                                                hbuff.xuanyun(target, 5)
                                                            end
                                                        )
                                                    end
                                                end,
                                                shifashijian = 6
                                            }
                                        },
                                        {
                                            aiType = UNIT_AI_TYPE.CAST_SKILL,
                                            aiData = {
                                                targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                                name = "极速寒冰箭",
                                                --castCountLimit = 1, -- cast only x times per battle
                                                castCD = 5, -- nil or <=1 means 1 second
                                                --healthBelowLimit = 65, -- only cast when health is < 65%
                                                startEffect = function(evtData)
                                                end,
                                                --interval = 1,
                                                periodEffect = function(evtData, curTimer)
                                                end,
                                                effect = function(evtData)
                                                    local sourceUnit = evtData.triggerUnit
                                                    local targetUnit = evtData.targetUnit
                                                    hskillMoban.missile(
                                                        {
                                                            --model = "war3mapImported\\[SPELL]_115.mdl",
                                                            model = "Abilities\\Weapons\\LichMissile\\LichMissile.mdl",
                                                            scale = 1.0,
                                                            speed = 1000,
                                                            hover = 50,
                                                            sourceUnit = sourceUnit,
                                                            targetUnit = targetUnit,
                                                            target_face_dis = 50,
                                                            onEnd = function(_, _, endX, endY)
                                                                hskill.damage(
                                                                    {
                                                                        sourceUnit = sourceUnit,
                                                                        targetUnit = targetUnit,
                                                                        damage = (2 + nandu * 0.5) *
                                                                            hattr.get(sourceUnit, "attack", 0),
                                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                                        damageType = DAMAGE_TYPE.MOFA,
                                                                        triggerSkill = hslk.n2i("AI技能模版"),
                                                                        damageElementType = CONST_DAMAGE_ELEMENT_TYPE
                                                                            .WATER,
                                                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE
                                                                            .IMMEDIATE
                                                                    }
                                                                )
                                                                hbuff.update(
                                                                    3,
                                                                    targetUnit,
                                                                    "严寒",
                                                                    false,
                                                                    function()
                                                                        hattribute.set(
                                                                            targetUnit,
                                                                            0,
                                                                            {
                                                                                attack_speed = "-10",
                                                                                move = "-50",
                                                                                skill_speed = "-10"
                                                                            }
                                                                        )
                                                                    end,
                                                                    function()
                                                                        hattribute.set(
                                                                            targetUnit,
                                                                            0,
                                                                            {
                                                                                attack_speed = "+10",
                                                                                move = "+50",
                                                                                skill_speed = "+10"
                                                                            }
                                                                        )
                                                                    end,
                                                                    "ReplaceableTextures\\fashi\\BTN_ASdQ2.blp",
                                                                    "严寒：降低10%的攻击，技能和50的移动速度",
                                                                    1,
                                                                    nil,
                                                                    nil,
                                                                    nil,
                                                                    nil,
                                                                    HBUFF_UPDATE_MODE.OVERWRITE,
                                                                    true
                                                                )
                                                            end
                                                        }
                                                    )
                                                end,
                                                shifashijian = 2
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
                            passiveSkill = {
                                { cigugongji, binglengpifu },
                                { cigugongji, binglengpifu },
                                { cigugongji, binglengpifu },
                                { cigugongji, binglengpifu }
                            }
                        }
                    },
                    tongguanjiangli = {
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience, value = 2000 },
                                { type = HSHOP_COST_TYPE.gold,       value = 300 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 1,
                                    shengwangname = "新手村"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience, value = 2500 },
                                { type = HSHOP_COST_TYPE.gold,       value = 400 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 2,
                                    shengwangname = "新手村"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience, value = 3000 },
                                { type = HSHOP_COST_TYPE.gold,       value = 500 }
                            },
                            shengwang = {
                                {
                                    value = 275,
                                    maxLevel = 3,
                                    shengwangname = "新手村"
                                }
                            }
                        },
                        {
                            resource = {
                                { type = HSHOP_COST_TYPE.experience, value = 4000 },
                                { type = HSHOP_COST_TYPE.gold,       value = 600 }
                            },
                            shengwang = {
                                {
                                    value = 500,
                                    maxLevel = 3,
                                    shengwangname = "新手村"
                                }
                            }
                        }
                    }
                }
            )
        end
    }
)
