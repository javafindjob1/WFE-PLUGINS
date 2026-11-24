initMijjing = function()
    local citiaoConfig = {
        {
            startLevel = 5,
            cizhui = {
                {
                    name = "耐久",
                    art = "ReplaceableTextures\\mijing\\ui_spell_naijiu.blp",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ shengming_baifenbi = "+50" })
                },
                {
                    name = "巨力",
                    art = "ReplaceableTextures\\mijing\\ui_spell_juli.blp",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ gongji_baifenbi = "+30" })
                },
                {
                    name = "乱舞",
                    art = "ReplaceableTextures\\mijing\\ui_spell_luanwu.blp",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ attack_speed = "+30" })
                },
                {
                    name = "迅捷",
                    art = "ReplaceableTextures\\mijing\\ui_spell_xunjie.blp",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ skill_speed = "+30" })
                },
                {
                    name = "疾速",
                    art = "ReplaceableTextures\\mijing\\ui_spell_jisu.blp",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ move = "+200" })
                },
                {
                    name = "物甲",
                    art = "ReplaceableTextures\\mijing\\ui_spell_wujia.blp",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ defend_baifenbi = "+50" })
                },
                {
                    name = "魔甲",
                    art = "ReplaceableTextures\\mijing\\ui_spell_mojia.blp",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ mojia_baifenbi = "+50" })
                }
            }
        },
        {
            startLevel = 10,
            cizhui = {
                {
                    name = "激励",
                    art = "ReplaceableTextures\\mijing\\ui_spell_jili.blp",
                    description = "死亡会鼓舞旁边500码范围内的所有单位，使其伤害提高30%，可无限叠加。",
                    attr_type = CONST_EVENT.dead,
                    attr = function(evtData)
                        heffect.attach(
                            "Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl",
                            evtData.triggerUnit,
                            "over head",
                            0
                        )

                        for _, unit in ipairs(hgroup.createAllyGroupByUnit(evtData.triggerUnit, 500)) do
                            if unit ~= evtData.triggerUnit then
                                hbuff.addStackAttrBuff(
                                    CONST_DAMAGE_SRC.skill,
                                    unit,
                                    "激励",
                                    _attr(
                                        {
                                            quanju_zengshang = "+30"
                                        }
                                    ),
                                    60,
                                    999,
                                    "ReplaceableTextures\\KUANGRE\\PASKUANGRE.blp",
                                    "激励：友军被击杀激励了该单位，每层使其伤害提高30%，可无限叠加。",
                                    true
                                )
                            end
                        end
                    end
                },
                {
                    name = "激流",
                    art = "ReplaceableTextures\\mijing\\ui_spell_jiliu.blp",
                    description = "造成伤害有50%概率对距离最远的在仇恨列表的敌方单位释放激流，2秒后激流爆发对目标地点200范围内的单位造成生命最大值40%的真实伤害，冷却10秒",
                    attr_type = CONST_EVENT.damage,
                    attr = function(evtData)
                        if math.random(1, 100) <= 50 and htime.setupAndCheckCoolDown(evtData.triggerUnit, "激流", 10) then
                            local diren = hfightzhuangtai.getFarestChouhengMubiao(evtData.triggerUnit)
                            if diren == nil then
                                return
                            end
                            local x, y = hunit.x(diren), hunit.y(diren)
                            hskillMoban.radiusWarning(x, y, hjapi.Z(x, y), 200, 2)
                            heffect.xyz("war3mapImported\\AZ_Coco(2)_E1_Gather.mdx", x, y, hjapi.Z(x, y), 2, 1, 1, 1, 1)
                            htime.setTimeout(
                                2,
                                function()
                                    heffect.xyz(
                                        "war3mapImported\\AZ_Coco(2)_E2_Blast.mdx",
                                        x,
                                        y,
                                        hjapi.Z(x, y),
                                        0,
                                        1,
                                        1,
                                        1,
                                        1
                                    )

                                    hskillMoban.radiusAOE(
                                        x,
                                        y,
                                        evtData.triggerUnit,
                                        200,
                                        function(unit)
                                            hskill.damage(
                                                {
                                                    sourceUnit = evtData.triggerUnit,
                                                    targetUnit = unit,
                                                    damage = hunit.getMaxLife(unit) * 0.4,
                                                    damageType = DAMAGE_TYPE.SHENSHENG,
                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WATER },
                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                                    skipSourceUnitDeathCheck = true
                                                }
                                            )
                                        end,
                                        true
                                    )
                                end
                            )
                        end
                        --
                    end
                },
                {
                    name = "尸爆",
                    art = "ReplaceableTextures\\mijing\\ui_spell_shibao.blp",
                    description = "死亡2秒后会对周围200码范围内的敌人造成40%生命最大值的真实伤害。",
                    attr_type = CONST_EVENT.dead,
                    attr = function(evtData)
                        local x, y = hunit.x(evtData.triggerUnit), hunit.y(evtData.triggerUnit)
                        hskillMoban.radiusWarning(x, y, hjapi.Z(x, y), 200, 2)
                        htime.setTimeout(
                            2,
                            function()
                                heffect.xyz("war3mapImported\\AZ_dsdx.mdx", x, y, hjapi.Z(x, y), 0, 1, 1, 1, 1)
                                heffect.xyz("war3mapImported\\AZ_baozha06.mdx", x, y, hjapi.Z(x, y), 0, 1, 1, 1, 1)
                                hskillMoban.radiusAOE(
                                    x,
                                    y,
                                    evtData.triggerUnit,
                                    200,
                                    function(unit)
                                        hskill.damage(
                                            {
                                                sourceUnit = evtData.triggerUnit,
                                                targetUnit = unit,
                                                damage = hunit.getMaxLife(unit) * 0.4,
                                                damageType = DAMAGE_TYPE.SHENSHENG,
                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK },
                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                                skipSourceUnitDeathCheck = true
                                            }
                                        )
                                    end,
                                    true
                                )
                            end
                        )
                    end
                }
            }
        },
        {
            startLevel = 15,
            cizhui = {
                {
                    name = "疾病",
                    art = "ReplaceableTextures\\mijing\\ui_spell_jibing.blp",
                    description = "普通攻击会给敌人施加疾病，每层疾病使目标收到的伤害提高3%，可以无限叠加",
                    attr_type = CONST_EVENT.attack,
                    attr = function(evtData)
                        hbuff.addStackAttrBuff(
                            CONST_DAMAGE_SRC.skill,
                            evtData.targetUnit,
                            "疾病",
                            {
                                jianshang = "-3"
                            },
                            5,
                            999,
                            "ReplaceableTextures\\KUANGRE\\PASKUANGRE.blp",
                            "你被带有疾病的单位攻击了。每层疾病使目标收到的伤害提高3%，可以无限叠加",
                            false
                        )
                    end
                },
                {
                    name = "碾压",
                    art = "ReplaceableTextures\\mijing\\ui_spell_nianya.blp",
                    description = "普通攻击造成的伤害提高100%",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.damageSrc == CONST_DAMAGE_SRC.attack then
                            evtData.damage = evtData.damage * 2
                        end
                    end
                },
                {
                    name = "繁盛",
                    art = "ReplaceableTextures\\mijing\\ui_spell_fansheng.blp",
                    description = "副本小怪的数量翻倍",
                    attr_type = CONST_EVENT.noevent,
                    attr = function(evtData)
                    end
                },
                {
                    name = "统领",
                    art = "ReplaceableTextures\\mijing\\ui_spell_tongling.blp",
                    description = "副本Boss的血量提高100%",
                    attr_type = CONST_EVENT.noevent,
                    attr = function(evtData)
                    end
                }
            }
        }
    }

    local config = {
        {
            name = "丛林深处",
            schedule = { 1, 1, 1, 1, 1, 1, 1 },
            art = hslk.n2v("银月狼王", "slk", "Art"),
            curKey = "damijingcur",
            curCdStartIndex = 1,
            curCdEndIndex = 2,
            maxKey = "damijingmax",
            maxCdStartIndex = 1,
            maxCdEndIndex = 2,
            isActive = false,
            currentLevel = 0,
            maxHistoryLevel = 0,
            maxLevel = 99,
            cizhuiconfig = citiaoConfig,
            effectiveLevel = 60,
            timeRequirement = {
                600,
                400,
                200
            },
            jiangliConfig = {
                {
                    startLevel = 1,
                    attrPerLevel = _attr({ life = "+10" })
                },
                {
                    startLevel = 10,
                    attrPerLevel = _attr({ life = "+10" })
                },
                {
                    startLevel = 20,
                    attrPerLevel = _attr({ life = "+10" })
                }
            }
        },
        {
            name = "月亮湖",
            schedule = { 1, 1, 1, 1, 1, 1, 1 },
            art = hslk.n2v("银鳞", "slk", "Art"),
            curKey = "damijingcur",
            curCdStartIndex = 3,
            curCdEndIndex = 4,
            maxKey = "damijingmax",
            maxCdStartIndex = 3,
            maxCdEndIndex = 4,
            isActive = false,
            currentLevel = 0,
            maxHistoryLevel = 0,
            maxLevel = 99,
            cizhuiconfig = citiaoConfig,
            effectiveLevel = 60,
            timeRequirement = {
                900,
                600,
                300
            },
            jiangliConfig = {
                {
                    startLevel = 1,
                    attrPerLevel = _attr({ attack_speed = "+0.1" })
                },
                {
                    startLevel = 10,
                    attrPerLevel = _attr({ attack_speed = "+0.1" })
                },
                {
                    startLevel = 20,
                    attrPerLevel = _attr({ attack_speed = "+0.1" })
                }
            }
        },
        {
            name = "王城监狱",
            schedule = { 1, 1, 1, 1, 1, 1, 1 },
            art = hslk.n2v("监狱之王范克瑞夫", "slk", "Art"),
            curKey = "damijingcur",
            curCdStartIndex = 5,
            curCdEndIndex = 6,
            maxKey = "damijingmax",
            maxCdStartIndex = 5,
            maxCdEndIndex = 6,
            isActive = false,
            currentLevel = 0,
            maxHistoryLevel = 0,
            maxLevel = 99,
            cizhuiconfig = citiaoConfig,
            effectiveLevel = 60,
            timeRequirement = {
                900,
                600,
                300
            },
            jiangliConfig = {
                {
                    startLevel = 1,
                    attrPerLevel = _attr({ pojia = "+1", pomo = "+1" })
                },
                {
                    startLevel = 10,
                    attrPerLevel = _attr({ pojia = "+1", pomo = "+1" })
                },
                {
                    startLevel = 20,
                    attrPerLevel = _attr({ pojia = "+1", pomo = "+1" })
                }
            }
        },
        {
            name = "血色军大营",
            schedule = { 1, 1, 1, 1, 1, 1, 1 },
            art = hslk.n2v("血色军统帅莫格莱尼", "slk", "Art"),
            curKey = "damijingcur",
            curCdStartIndex = 7,
            curCdEndIndex = 8,
            maxKey = "damijingmax",
            maxCdStartIndex = 7,
            maxCdEndIndex = 8,
            isActive = false,
            currentLevel = 0,
            maxHistoryLevel = 0,
            maxLevel = 99,
            cizhuiconfig = citiaoConfig,
            effectiveLevel = 60,
            timeRequirement = {
                1200,
                800,
                400
            },
            jiangliConfig = {
                {
                    startLevel = 1,
                    attrPerLevel = _attr({ master = "+1" })
                },
                {
                    startLevel = 10,
                    attrPerLevel = _attr({ master = "+1" })
                },
                {
                    startLevel = 20,
                    attrPerLevel = _attr({ master = "+1" })
                }
            }
        },
        {
            name = "圣光大教堂",
            schedule = { 1, 1, 1, 1, 1, 1, 1 },
            art = hslk.n2v("圣光主教布莱克安", "slk", "Art"),
            curKey = "damijingcur",
            curCdStartIndex = 9,
            curCdEndIndex = 10,
            maxKey = "damijingmax",
            maxCdStartIndex = 9,
            maxCdEndIndex = 10,
            isActive = false,
            currentLevel = 0,
            maxHistoryLevel = 0,
            maxLevel = 99,
            cizhuiconfig = citiaoConfig,
            effectiveLevel = 60,
            timeRequirement = {
                900,
                600,
                300
            },
            jiangliConfig = {
                {
                    startLevel = 1,
                    attrPerLevel = _attr({ zhushuxing = "+2" })
                },
                {
                    startLevel = 10,
                    attrPerLevel = _attr({ zhushuxing = "+2" })
                },
                {
                    startLevel = 20,
                    attrPerLevel = _attr({ zhushuxing = "+2" })
                }
            }
        },
        {
            name = "半人马营地",
            schedule = { 1, 1, 1, 1, 1, 1, 1 },
            art = hslk.n2v("人马酋长战争之蹄", "slk", "Art"),
            curKey = "damijingcur",
            curCdStartIndex = 11,
            curCdEndIndex = 12,
            maxKey = "damijingmax",
            maxCdStartIndex = 11,
            maxCdEndIndex = 12,
            isActive = false,
            currentLevel = 0,
            maxHistoryLevel = 0,
            maxLevel = 99,
            cizhuiconfig = citiaoConfig,
            effectiveLevel = 60,
            timeRequirement = {
                900,
                600,
                300
            },
            jiangliConfig = {
                {
                    startLevel = 1,
                    attrPerLevel = _attr({ attack_white = "+2" })
                },
                {
                    startLevel = 10,
                    attrPerLevel = _attr({ attack_white = "+2" })
                },
                {
                    startLevel = 20,
                    attrPerLevel = _attr({ attack_white = "+2" })
                }
            }
        },
        {
            name = "矮人地下城",
            schedule = { 1, 1, 1, 1, 1, 1, 1 },
            art = hslk.n2v("黑铁矮人索瑞森大帝", "slk", "Art"),
            curKey = "damijingcur",
            curCdStartIndex = 13,
            curCdEndIndex = 14,
            maxKey = "damijingmax",
            maxCdStartIndex = 13,
            maxCdEndIndex = 14,
            isActive = false,
            currentLevel = 0,
            maxHistoryLevel = 0,
            maxLevel = 99,
            cizhuiconfig = citiaoConfig,
            effectiveLevel = 60,
            timeRequirement = {
                900,
                600,
                300
            },
            jiangliConfig = {
                {
                    startLevel = 1,
                    attrPerLevel = _attr({ defend_white = "+1" })
                },
                {
                    startLevel = 10,
                    attrPerLevel = _attr({ defend_white = "+1" })
                },
                {
                    startLevel = 20,
                    attrPerLevel = _attr({ defend_white = "+1" })
                }
            }
        },
        {
            name = "黑龙王子的巢穴",
            schedule = { 1, 1, 1, 1, 1, 1, 1 },
            art = hslk.n2v("黑龙王子", "slk", "Art"),
            curKey = "damijingcur",
            curCdStartIndex = 15,
            curCdEndIndex = 16,
            maxKey = "damijingmax",
            maxCdStartIndex = 15,
            maxCdEndIndex = 16,
            isActive = false,
            currentLevel = 0,
            maxHistoryLevel = 0,
            maxLevel = 99,
            cizhuiconfig = citiaoConfig,
            effectiveLevel = 70,
            timeRequirement = {
                300,
                200,
                100
            },
            jiangliConfig = {
                {
                    startLevel = 1,
                    attrPerLevel = _attr({ life = "+15" })
                },
                {
                    startLevel = 10,
                    attrPerLevel = _attr({ life = "+15" })
                },
                {
                    startLevel = 20,
                    attrPerLevel = _attr({ life = "+15" })
                }
            }
        },
        {
            name = "火焰之心",
            schedule = { 1, 1, 1, 1, 1, 1, 1 },
            art = hslk.n2v("炎魔之王", "slk", "Art"),
            curKey = "damijingcur",
            curCdStartIndex = 17,
            curCdEndIndex = 18,
            maxKey = "damijingmax",
            maxCdStartIndex = 17,
            maxCdEndIndex = 18,
            isActive = false,
            currentLevel = 0,
            maxHistoryLevel = 0,
            maxLevel = 99,
            cizhuiconfig = citiaoConfig,
            effectiveLevel = 70,
            timeRequirement = {
                1200,
                900,
                400
            },
            jiangliConfig = {
                {
                    startLevel = 1,
                    attrPerLevel = _attr({ zhushuxing_baifenbi = "+0.1" })
                },
                {
                    startLevel = 10,
                    attrPerLevel = _attr({ zhushuxing_baifenbi = "+0.1" })
                },
                {
                    startLevel = 20,
                    attrPerLevel = _attr({ zhushuxing_baifenbi = "+0.1" })
                }
            }
        },
        {
            name = "破碎大厅",
            schedule = { 1, 1, 1, 1, 1, 1, 1 },
            art = hslk.n2v("酋长卡加斯·刃拳", "slk", "Art"),
            curKey = "damijingcur",
            curCdStartIndex = 19,
            curCdEndIndex = 20,
            maxKey = "damijingmax",
            maxCdStartIndex = 19,
            maxCdEndIndex = 20,
            isActive = false,
            currentLevel = 0,
            maxHistoryLevel = 0,
            maxLevel = 99,
            cizhuiconfig = citiaoConfig,
            effectiveLevel = 70,
            timeRequirement = {
                900,
                600,
                300
            },
            jiangliConfig = {
                {
                    startLevel = 1,
                    attrPerLevel = _attr({ fa_chuan = "+0.1" })
                },
                {
                    startLevel = 10,
                    attrPerLevel = _attr({ fa_chuan = "+0.1" })
                },
                {
                    startLevel = 20,
                    attrPerLevel = _attr({ fa_chuan = "+0.1" })
                }
            }
        },
        {
            name = "屠龙者的巢穴",
            schedule = { 1, 1, 1, 1, 1, 1, 1 },
            art = hslk.n2v("屠龙者格鲁", "slk", "Art"),
            curKey = "damijingcur",
            curCdStartIndex = 21,
            curCdEndIndex = 22,
            maxKey = "damijingmax",
            maxCdStartIndex = 21,
            maxCdEndIndex = 22,
            isActive = false,
            currentLevel = 0,
            maxHistoryLevel = 0,
            maxLevel = 99,
            cizhuiconfig = citiaoConfig,
            effectiveLevel = 70,
            timeRequirement = {
                900,
                600,
                300
            },
            jiangliConfig = {
                {
                    startLevel = 1,
                    attrPerLevel = _attr({ wu_chuan = "+0.1" })
                },
                {
                    startLevel = 10,
                    attrPerLevel = _attr({ wu_chuan = "+0.1" })
                },
                {
                    startLevel = 20,
                    attrPerLevel = _attr({ wu_chuan = "+0.1" })
                }
            }
        },
        {
            name = "法师塔",
            schedule = { 1, 1, 1, 1, 1, 1, 1 },
            art = hslk.n2v("大法师埃兰", "slk", "Art"),
            curKey = "damijingcur",
            curCdStartIndex = 23,
            curCdEndIndex = 24,
            maxKey = "damijingmax",
            maxCdStartIndex = 23,
            maxCdEndIndex = 24,
            isActive = false,
            currentLevel = 0,
            maxHistoryLevel = 0,
            maxLevel = 99,
            cizhuiconfig = citiaoConfig,
            effectiveLevel = 70,
            timeRequirement = {
                1200,
                800,
                400
            },
            jiangliConfig = {
                {
                    startLevel = 1,
                    attrPerLevel = _attr({ quanju_zengshang = "+0.1" })
                },
                {
                    startLevel = 10,
                    attrPerLevel = _attr({ quanju_zengshang = "+0.1" })
                },
                {
                    startLevel = 20,
                    attrPerLevel = _attr({ quanju_zengshang = "+0.1" })
                }
            }
        },
        {
            name = "风暴要塞",
            schedule = { 1, 1, 1, 1, 1, 1, 1 },
            art = hslk.n2v("凯尔萨斯·逐日者", "slk", "Art"),
            curKey = "damijingcur",
            curCdStartIndex = 25,
            curCdEndIndex = 26,
            maxKey = "damijingmax",
            maxCdStartIndex = 25,
            maxCdEndIndex = 26,
            isActive = false,
            currentLevel = 0,
            maxHistoryLevel = 0,
            maxLevel = 30,
            cizhuiconfig = citiaoConfig,
            effectiveLevel = 71,
            timeRequirement = {
                900,
                600,
                300
            },
            jiangliConfig = {
                {
                    startLevel = 1,
                    attrPerLevel = _attr({ zhushuxing_baifenbi = "+0.1" })
                },
                {
                    startLevel = 10,
                    attrPerLevel = _attr({ zhushuxing_baifenbi = "+0.1" })
                },
                {
                    startLevel = 20,
                    attrPerLevel = _attr({ zhushuxing_baifenbi = "+0.1" })
                }
            }
        }
    }
    local nanduConfig = {
        lifeFactor = 1.09,
        attackFactor = 1.02
    }

    hmijing.initFromConfig(config, nanduConfig)
end
