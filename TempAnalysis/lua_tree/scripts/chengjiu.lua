function initChengjiu()
    local config = {
        {
            name = "10级!",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 1,
            cunDangEndIndex = 1,
            art = "ReplaceableTextures\\chengjiu\\Achievement_Level_10.blp",
            enabled = false,
            description = "任意英雄等级达到10级",
            attribute = _attr({exp_ratio = "+1"}),
            trigger = {
                attr_type = CONST_EVENT.levelUp,
                passCriteria = function(evtData)
                    if hhero.getCurLevel(evtData.triggerUnit) >= 10 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "20级!",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 2,
            cunDangEndIndex = 2,
            art = "ReplaceableTextures\\chengjiu\\Achievement_Level_20.blp",
            enabled = false,
            description = "任意英雄等级达到20级",
            attribute = _attr({exp_ratio = "+1"}),
            trigger = {
                attr_type = CONST_EVENT.levelUp,
                passCriteria = function(evtData)
                    if hhero.getCurLevel(evtData.triggerUnit) >= 20 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "30级!",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 3,
            cunDangEndIndex = 3,
            art = "ReplaceableTextures\\chengjiu\\Achievement_Level_30.blp",
            enabled = false,
            description = "任意英雄等级达到30级",
            attribute = _attr({exp_ratio = "+1"}),
            trigger = {
                attr_type = CONST_EVENT.levelUp,
                passCriteria = function(evtData)
                    if hhero.getCurLevel(evtData.triggerUnit) >= 30 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "40级!",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 4,
            cunDangEndIndex = 4,
            art = "ReplaceableTextures\\chengjiu\\Achievement_Level_40.blp",
            enabled = false,
            description = "任意英雄等级达到40级",
            attribute = _attr({exp_ratio = "+1"}),
            trigger = {
                attr_type = CONST_EVENT.levelUp,
                passCriteria = function(evtData)
                    if hhero.getCurLevel(evtData.triggerUnit) >= 40 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "50级!",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 5,
            cunDangEndIndex = 5,
            art = "ReplaceableTextures\\chengjiu\\Achievement_Level_50.blp",
            enabled = false,
            description = "任意英雄等级达到50级",
            attribute = _attr({exp_ratio = "+1"}),
            trigger = {
                attr_type = CONST_EVENT.levelUp,
                passCriteria = function(evtData)
                    if hhero.getCurLevel(evtData.triggerUnit) >= 50 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "游戏开始",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 6,
            cunDangEndIndex = 6,
            art = "ReplaceableTextures\\chengjiu\\Achievement_Level_60.blp",
            enabled = false,
            description = "任意英雄等级达到60级",
            attribute = _attr({exp_ratio = "+1"}),
            trigger = {
                attr_type = CONST_EVENT.levelUp,
                passCriteria = function(evtData)
                    if hhero.getCurLevel(evtData.triggerUnit) >= 60 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "丛林深处（普通）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 7,
            cunDangEndIndex = 7,
            art = hslk.n2v("巨狼", "slk", "Art"),
            enabled = false,
            description = "通关普通难度丛林深处副本",
            attribute = _attr({zhushuxing = "+3"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.PUTONG and evtData.fubenName == "丛林深处" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "丛林深处（英雄）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 8,
            cunDangEndIndex = 8,
            art = hslk.n2v("巨狼", "slk", "Art"),
            enabled = false,
            description = "通关英雄难度丛林深处副本",
            attribute = _attr({life = "+30"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.YINGXIONG and evtData.fubenName == "丛林深处" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "月亮湖（普通）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 9,
            cunDangEndIndex = 9,
            art = hslk.n2v("银鳞", "slk", "Art"),
            enabled = false,
            description = "通关普通难度月亮湖副本",
            attribute = _attr({zhushuxing = "+6"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.PUTONG and evtData.fubenName == "月亮湖" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "月亮湖（英雄）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 10,
            cunDangEndIndex = 10,
            art = hslk.n2v("银鳞", "slk", "Art"),
            enabled = false,
            description = "通关英雄难度月亮湖副本",
            attribute = _attr({life = "+60"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.YINGXIONG and evtData.fubenName == "月亮湖" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "月亮湖（史诗）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 11,
            cunDangEndIndex = 11,
            art = hslk.n2v("银鳞", "slk", "Art"),
            enabled = false,
            description = "通关史诗难度月亮湖副本",
            attribute = _attr({attack_speed = "+0.2", skill_speed = "+0.1"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.SHISHI and evtData.fubenName == "月亮湖" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "监狱（普通）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 12,
            cunDangEndIndex = 12,
            art = hslk.n2v("监狱之王范克瑞夫", "slk", "Art"),
            enabled = false,
            description = "通关普通难度监狱副本",
            attribute = _attr({zhushuxing = "+6"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.PUTONG and evtData.fubenName == "王城监狱" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "监狱（英雄）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 13,
            cunDangEndIndex = 13,
            art = hslk.n2v("监狱之王范克瑞夫", "slk", "Art"),
            enabled = false,
            description = "通关英雄难度监狱副本",
            attribute = _attr({life = "+60"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.YINGXIONG and evtData.fubenName == "王城监狱" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "监狱（史诗）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 14,
            cunDangEndIndex = 14,
            art = hslk.n2v("监狱之王范克瑞夫", "slk", "Art"),
            enabled = false,
            description = "通关史诗难度监狱副本",
            attribute = _attr({attack_speed = "+0.2", skill_speed = "+0.1"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.SHISHI and evtData.fubenName == "王城监狱" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "血色军大营（普通）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 16,
            cunDangEndIndex = 16,
            art = hslk.n2v("血色军统帅莫格莱尼", "slk", "Art"),
            enabled = false,
            description = "通关普通难度血色军大营副本",
            attribute = _attr({zhushuxing = "+6"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.PUTONG and evtData.fubenName == "血色军大营" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "血色军大营（英雄）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 17,
            cunDangEndIndex = 17,
            art = hslk.n2v("血色军统帅莫格莱尼", "slk", "Art"),
            enabled = false,
            description = "通关英雄难度血色军大营副本",
            attribute = _attr({life = "+60"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.YINGXIONG and evtData.fubenName == "血色军大营" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "血色军大营（史诗）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 18,
            cunDangEndIndex = 18,
            art = hslk.n2v("血色军统帅莫格莱尼", "slk", "Art"),
            enabled = false,
            description = "通关史诗难度血色军大营副本",
            attribute = _attr({attack_speed = "+0.2", skill_speed = "+0.1"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.SHISHI and evtData.fubenName == "血色军大营" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "圣光大教堂（普通）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 20,
            cunDangEndIndex = 20,
            art = hslk.n2v("圣光主教布莱克安", "slk", "Art"),
            enabled = false,
            description = "通关普通难度圣光大教堂副本",
            attribute = _attr({zhushuxing = "+6"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.PUTONG and evtData.fubenName == "圣光大教堂" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "圣光大教堂（英雄）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 21,
            cunDangEndIndex = 21,
            art = hslk.n2v("圣光主教布莱克安", "slk", "Art"),
            enabled = false,
            description = "通关英雄难度圣光大教堂副本",
            attribute = _attr({life = "+60"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.YINGXIONG and evtData.fubenName == "圣光大教堂" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "圣光大教堂（史诗）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 22,
            cunDangEndIndex = 22,
            art = hslk.n2v("圣光主教布莱克安", "slk", "Art"),
            enabled = false,
            description = "通关史诗难度圣光大教堂副本",
            attribute = _attr({attack_speed = "+0.2", skill_speed = "+0.1"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.SHISHI and evtData.fubenName == "圣光大教堂" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "半人马营地（普通）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 23,
            cunDangEndIndex = 23,
            art = hslk.n2v("人马酋长战争之蹄", "slk", "Art"),
            enabled = false,
            description = "通关普通难度半人马营地副本",
            attribute = _attr({zhushuxing = "+7"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.PUTONG and evtData.fubenName == "半人马营地" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "半人马营地（英雄）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 24,
            cunDangEndIndex = 24,
            art = hslk.n2v("人马酋长战争之蹄", "slk", "Art"),
            enabled = false,
            description = "通关英雄难度半人马营地副本",
            attribute = _attr({life = "+80"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.YINGXIONG and evtData.fubenName == "半人马营地" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "半人马营地（史诗）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 25,
            cunDangEndIndex = 25,
            art = hslk.n2v("人马酋长战争之蹄", "slk", "Art"),
            enabled = false,
            description = "通关史诗难度半人马营地副本",
            attribute = _attr({attack_speed = "+0.2", skill_speed = "+0.1"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.SHISHI and evtData.fubenName == "半人马营地" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "矮人地下城（普通）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 26,
            cunDangEndIndex = 26,
            art = hslk.n2v("黑铁矮人索瑞森大帝", "slk", "Art"),
            enabled = false,
            description = "通关普通难度矮人地下城副本",
            attribute = _attr({zhushuxing = "+8"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.PUTONG and evtData.fubenName == "矮人地下城" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "矮人地下城（英雄）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 27,
            cunDangEndIndex = 27,
            art = hslk.n2v("黑铁矮人索瑞森大帝", "slk", "Art"),
            enabled = false,
            description = "通关英雄难度矮人地下城副本",
            attribute = _attr({life = "+100"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.YINGXIONG and evtData.fubenName == "矮人地下城" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "矮人地下城（史诗）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 28,
            cunDangEndIndex = 28,
            art = hslk.n2v("黑铁矮人索瑞森大帝", "slk", "Art"),
            enabled = false,
            description = "通关史诗难度矮人地下城副本",
            attribute = _attr({master = "+5"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.SHISHI and evtData.fubenName == "矮人地下城" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "火焰之心（普通）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 29,
            cunDangEndIndex = 29,
            art = hslk.n2v("炎魔之王", "slk", "Art"),
            enabled = false,
            description = "通关普通难度火焰之心副本",
            attribute = _attr({zhushuxing = "+10"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.PUTONG and evtData.fubenName == "火焰之心" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "火焰之心（英雄）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 30,
            cunDangEndIndex = 30,
            art = hslk.n2v("炎魔之王", "slk", "Art"),
            enabled = false,
            description = "通关英雄难度火焰之心副本",
            attribute = _attr({life = "+120"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.YINGXIONG and evtData.fubenName == "火焰之心" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "火焰之心（史诗）",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 31,
            cunDangEndIndex = 31,
            art = hslk.n2v("炎魔之王", "slk", "Art"),
            enabled = false,
            description = "通关史诗难度火焰之心副本",
            attribute = _attr({wu_bao = "+0.2", fa_bao = "+0.2"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.SHISHI and evtData.fubenName == "火焰之心" then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "进阶一",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 32,
            cunDangEndIndex = 32,
            art = "ReplaceableTextures\\BTNAchievement_Arena_2v2_1.blp",
            enabled = false,
            description = "任意角色装备评分达到800",
            attribute = _attr({zhushuxing = "+3", attack_white = "+3"}),
            trigger = {
                attr_type = CONST_EVENT.periodCheck,
                passCriteria = function(evtData)
                    if hitem.getGearScore(hunit.getOwner(evtData.triggerUnit)) >= 800 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "进阶二",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 33,
            cunDangEndIndex = 33,
            art = "ReplaceableTextures\\BTNAchievement_Arena_2v2_2.blp",
            enabled = false,
            description = "任意角色装备评分达到1000",
            attribute = _attr({zhushuxing = "+3", attack_white = "+3"}),
            trigger = {
                attr_type = CONST_EVENT.periodCheck,
                passCriteria = function(evtData)
                    if hitem.getGearScore(hunit.getOwner(evtData.triggerUnit)) >= 1000 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "进阶三",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 34,
            cunDangEndIndex = 34,
            art = "ReplaceableTextures\\BTNAchievement_Arena_2v2_3.blp",
            enabled = false,
            description = "任意角色装备评分达到1200",
            attribute = _attr({zhushuxing = "+3", attack_white = "+3"}),
            trigger = {
                attr_type = CONST_EVENT.periodCheck,
                passCriteria = function(evtData)
                    if hitem.getGearScore(hunit.getOwner(evtData.triggerUnit)) >= 1200 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "速通圣光大教堂",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 35,
            cunDangEndIndex = 35,
            art = "ReplaceableTextures\\BTNAchievement_Arena_2v2_3.blp",
            enabled = false,
            description = "在150秒内击通关史诗难度圣光大教堂",
            attribute = _attr({quanju_zengshang = "+0.2"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.SHISHI and evtData.fubenName == "圣光大教堂" and evtData.haoshi < 150 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "速通半人马营地",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 36,
            cunDangEndIndex = 36,
            art = "ReplaceableTextures\\BTNAchievement_Arena_2v2_3.blp",
            enabled = false,
            description = "在150秒内击通关史诗难度半人马营地",
            attribute = _attr({quanju_zengshang = "+0.2"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.SHISHI and evtData.fubenName == "半人马营地" and evtData.haoshi < 150 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "速通矮人地下城",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 37,
            cunDangEndIndex = 37,
            art = "ReplaceableTextures\\BTNAchievement_Arena_2v2_3.blp",
            enabled = false,
            description = "在150秒内击通关史诗难度矮人地下城",
            attribute = _attr({quanju_zengshang = "+0.2"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.SHISHI and evtData.fubenName == "矮人地下城" and evtData.haoshi < 150 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "速通火焰之心",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 38,
            cunDangEndIndex = 38,
            art = "ReplaceableTextures\\BTNAchievement_Arena_2v2_3.blp",
            enabled = false,
            description = "在300秒内击通关史诗难度火焰之心",
            attribute = _attr({quanju_zengshang = "+0.2"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.SHISHI and evtData.fubenName == "火焰之心" and evtData.haoshi < 300 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "火车王",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 39,
            cunDangEndIndex = 39,
            art = "ReplaceableTextures\\BTNAchievement_Arena_2v2_3.blp",
            enabled = false,
            description = "在100秒内击通关史诗难度黑龙王子的巢穴",
            attribute = _attr({quanju_zengshang = "+0.2"}),
            trigger = {
                attr_type = CONST_EVENT.finishFUBEN,
                passCriteria = function(evtData)
                    if evtData.nandu >= FUBEN_NANDU.SHISHI and evtData.fubenName == "黑龙王子的巢穴" and evtData.haoshi < 100 then
                        return true
                    else
                        return false
                    end
                end
            }
        }
    }
    hchengjiu.init(config)

    local notusedchengjiu = {
        {
            name = "60级火法",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 35,
            cunDangEndIndex = 35,
            art = hslk.n2v("火法", "Art"),
            enabled = false,
            description = "火法到达60级",
            attribute = _attr({zhushuxing = "+2"}),
            trigger = {
                attr_type = CONST_EVENT.periodCheck,
                passCriteria = function(evtData)
                    if hunit.getName(evtData.triggerUnit) == "火法" and hunit.getLevel(evtData.triggerUnit) >= 60 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "60级武器战",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 36,
            cunDangEndIndex = 36,
            art = hslk.n2v("武器战", "Art"),
            enabled = false,
            description = "武器战到达60级",
            attribute = _attr({zhushuxing = "+2"}),
            trigger = {
                attr_type = CONST_EVENT.periodCheck,
                passCriteria = function(evtData)
                    if hunit.getName(evtData.triggerUnit) == "武器战" and hunit.getLevel(evtData.triggerUnit) >= 60 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "60级狂暴战",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 37,
            cunDangEndIndex = 37,
            art = hslk.n2v("狂暴战", "Art"),
            enabled = false,
            description = "狂暴战到达60级",
            attribute = _attr({zhushuxing = "+2"}),
            trigger = {
                attr_type = CONST_EVENT.periodCheck,
                passCriteria = function(evtData)
                    if hunit.getName(evtData.triggerUnit) == "狂暴战" and hunit.getLevel(evtData.triggerUnit) >= 60 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "60级星辰法师",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 38,
            cunDangEndIndex = 38,
            art = hslk.n2v("星辰法师", "Art"),
            enabled = false,
            description = "星辰法师到达60级",
            attribute = _attr({zhushuxing = "+2"}),
            trigger = {
                attr_type = CONST_EVENT.periodCheck,
                passCriteria = function(evtData)
                    if hunit.getName(evtData.triggerUnit) == "星辰法师" and hunit.getLevel(evtData.triggerUnit) >= 60 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "60级射击猎",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 39,
            cunDangEndIndex = 39,
            art = hslk.n2v("射击猎", "Art"),
            enabled = false,
            description = "射击猎到达60级",
            attribute = _attr({zhushuxing = "+2"}),
            trigger = {
                attr_type = CONST_EVENT.periodCheck,
                passCriteria = function(evtData)
                    if hunit.getName(evtData.triggerUnit) == "射击猎" and hunit.getLevel(evtData.triggerUnit) >= 60 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "60级战斗贼",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 40,
            cunDangEndIndex = 40,
            art = hslk.n2v("战斗贼", "Art"),
            enabled = false,
            description = "战斗贼到达60级",
            attribute = _attr({zhushuxing = "+2"}),
            trigger = {
                attr_type = CONST_EVENT.periodCheck,
                passCriteria = function(evtData)
                    if hunit.getName(evtData.triggerUnit) == "战斗贼" and hunit.getLevel(evtData.triggerUnit) >= 60 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "60级毁灭术",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 41,
            cunDangEndIndex = 41,
            art = hslk.n2v("毁灭术", "Art"),
            enabled = false,
            description = "毁灭术到达60级",
            attribute = _attr({zhushuxing = "+2"}),
            trigger = {
                attr_type = CONST_EVENT.periodCheck,
                passCriteria = function(evtData)
                    if hunit.getName(evtData.triggerUnit) == "毁灭术" and hunit.getLevel(evtData.triggerUnit) >= 60 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "60级痛苦术",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 42,
            cunDangEndIndex = 42,
            art = hslk.n2v("痛苦术", "Art"),
            enabled = false,
            description = "痛苦术到达60级",
            attribute = _attr({zhushuxing = "+2"}),
            trigger = {
                attr_type = CONST_EVENT.periodCheck,
                passCriteria = function(evtData)
                    if hunit.getName(evtData.triggerUnit) == "痛苦术" and hunit.getLevel(evtData.triggerUnit) >= 60 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "60级惩戒骑",
            cundangStr = "chengjiu",
            isPerHero = false,
            cunDangStartIndex = 43,
            cunDangEndIndex = 43,
            art = hslk.n2v("惩戒骑", "Art"),
            enabled = false,
            description = "惩戒骑到达60级",
            attribute = _attr({zhushuxing = "+2"}),
            trigger = {
                attr_type = CONST_EVENT.periodCheck,
                passCriteria = function(evtData)
                    if hunit.getName(evtData.triggerUnit) == "惩戒骑" and hunit.getLevel(evtData.triggerUnit) >= 60 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "60级高手",
            cundangStr = "chengjiu",
            isPerHero = false,
            dependency = {},
            cunDangStartIndex = 44,
            cunDangEndIndex = 44,
            art = "",
            enabled = false,
            description = "以下九个职业的" ..
                hcolor.green(tostring(3) .. "个") .. "职业到达到60级：火法、武器战、狂暴战、星辰法师、射击猎、战斗贼、毁灭术、痛苦术、惩戒骑。",
            attribute = _attr({wu_bao = "+0.1", fa_bao = "+0.1"}),
            trigger = {
                attr_type = CONST_EVENT.periodCheck,
                passCriteria = function(evtData)
                    local list = {"火法", "武器战", "狂暴战", "星辰法师", "射击猎", "战斗贼", "毁灭术", "痛苦术", "惩戒骑"}
                    local countOf60 = 0
                    for _, name in ipairs(list) do
                        if hchengjiu.isChengjiuEnabled("60级" .. name, evtData.triggerPlayer) then
                            countOf60 = countOf60 + 1
                        end
                    end
                    if countOf60 >= 3 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "60级大佬",
            cundangStr = "chengjiu",
            isPerHero = false,
            dependency = {},
            cunDangStartIndex = 45,
            cunDangEndIndex = 45,
            art = "",
            enabled = false,
            description = "以下九个职业的" ..
                hcolor.green(tostring(5) .. "个") .. "职业达到60级：火法、武器战、狂暴战、星辰法师、射击猎、战斗贼、毁灭术、痛苦术、惩戒骑。",
            attribute = _attr({wu_zengshang = "+0.1", fa_zengshang = "+0.1"}),
            trigger = {
                attr_type = CONST_EVENT.periodCheck,
                passCriteria = function(evtData)
                    local list = {"火法", "武器战", "狂暴战", "星辰法师", "射击猎", "战斗贼", "毁灭术", "痛苦术", "惩戒骑"}
                    local countOf60 = 0
                    for _, name in ipairs(list) do
                        if hchengjiu.isChengjiuEnabled("60级" .. name, evtData.triggerPlayer) then
                            countOf60 = countOf60 + 1
                        end
                    end
                    if countOf60 >= 5 then
                        return true
                    else
                        return false
                    end
                end
            }
        },
        {
            name = "60级全职业大师",
            cundangStr = "chengjiu",
            isPerHero = false,
            dependency = {},
            cunDangStartIndex = 46,
            cunDangEndIndex = 46,
            art = "",
            enabled = false,
            description = "以下九个职业的" .. hcolor.green("所有") .. "职业到60级：火法、武器战、狂暴战、星辰法师、射击猎、战斗贼、毁灭术、痛苦术、惩戒骑。",
            attribute = _attr({wu_baoshang = "+1", fa_baoshang = "+1"}),
            trigger = {
                attr_type = CONST_EVENT.periodCheck,
                passCriteria = function(evtData)
                    local list = {"火法", "武器战", "狂暴战", "星辰法师", "射击猎", "战斗贼", "毁灭术", "痛苦术", "惩戒骑"}
                    local countOf60 = 0
                    for _, name in ipairs(list) do
                        if hchengjiu.isChengjiuEnabled("60级" .. name, evtData.triggerPlayer) then
                            countOf60 = countOf60 + 1
                        end
                    end
                    if countOf60 >= 9 then
                        return true
                    else
                        return false
                    end
                end
            }
        }
    }
end
