function initZhuanye()
    local config = {
        {
            name = "锻造",
            cundangStr = "zhuanye",
            isPerHero = false,
            lvlCunDangStartIndex = 1,
            lvlCunDangEndIndex = 1,
            expCunDangStartIndex = 2,
            expCunDangEndIndex = 3,
            art = "ReplaceableTextures\\duanzao\\duanzao.blp",
            maxLevel = 4,
            description = "制造武器，护甲以及各种材料。可以通过制造物品提高等级。等级提升可以提高强化和精炼的成功率，并降低消耗。等级提升还可以解锁更多物品的制作方法。专业等级在不同职业之间共享。",
            currentLevel = 0,
            currentExp = 0,
            attributeLevel = {
                _attr({qianghua_rate = "+10", jinglian_rate = "+10"}),
                _attr({qianghua_rate = "+20", jinglian_rate = "+20"}),
                _attr({qianghua_rate = "+30", jinglian_rate = "+30"}),
                _attr({qianghua_rate = "+40", jinglian_rate = "+40"}),
                _attr({qianghua_rate = "+50", jinglian_rate = "+50"}),
                _attr({qianghua_rate = "+60", jinglian_rate = "+60"})
            }
        },
        {
            name = "采矿",
            cundangStr = "zhuanye",
            isPerHero = false,
            lvlCunDangStartIndex = 4,
            lvlCunDangEndIndex = 4,
            expCunDangStartIndex = 5,
            expCunDangEndIndex = 6,
            art = "ReplaceableTextures\\caikuang\\CAIKUANG.blp",
            maxLevel = 4,
            description = "采集以及熔炼矿石。可以通过采矿或者熔炼矿石提高等级。等级提升可以提高可以开采矿石的种类。专业等级在不同职业之间共享。",
            currentLevel = 0,
            currentExp = 0,
            attributeLevel = {
                _attr({shengming_baifenbi = "+2"}),
                _attr({shengming_baifenbi = "+4"}),
                _attr({shengming_baifenbi = "+6"}),
                _attr({shengming_baifenbi = "+8"}),
                _attr({shengming_baifenbi = "+10"}),
                _attr({shengming_baifenbi = "+12"})
            }
        },
        {
            name = "采药",
            cundangStr = "zhuanye",
            isPerHero = false,
            lvlCunDangStartIndex = 7,
            lvlCunDangEndIndex = 7,
            expCunDangStartIndex = 8,
            expCunDangEndIndex = 9,
            art = "ReplaceableTextures\\caiyao\\BTNWarcraft3 Ico.blp",
            maxLevel = 4,
            description = "采集野外的草药采集点获得草药。可以通过采集活动提高等级。等级提升可以提高可采集的采集点的种类。专业等级在不同职业之间共享。",
            currentLevel = 0,
            currentExp = 0,
            attributeLevel = {
                _attr({life_back = "+6"}),
                _attr({life_back = "+12"}),
                _attr({life_back = "+18"}),
                _attr({life_back = "+24"}),
                _attr({life_back = "+32"}),
                _attr({life_back = "+40"})
            }
        },
        {
            name = "剥皮",
            cundangStr = "zhuanye",
            isPerHero = false,
            lvlCunDangStartIndex = 10,
            lvlCunDangEndIndex = 10,
            expCunDangStartIndex = 11,
            expCunDangEndIndex = 12,
            art = "ReplaceableTextures\\BTNzb5.blp",
            maxLevel = 4,
            description = "击杀可以剥皮的怪物可概率获得皮料。皮料是制皮专业的重要原料。每次剥皮成功都能获得专业技能经验。等级提升可以提高剥皮的成功率。专业等级在不同职业之间共享。",
            currentLevel = 0,
            currentExp = 0,
            attributeLevel = {
                _attr({wu_bao = "+0.2", baopi_rate = "+5"}),
                _attr({wu_bao = "+0.4", baopi_rate = "+10"}),
                _attr({wu_bao = "+0.6", baopi_rate = "+20"}),
                _attr({wu_bao = "+0.8", baopi_rate = "+35"}),
                _attr({wu_bao = "+1.0", baopi_rate = "+55"}),
                _attr({wu_bao = "+1.2", baopi_rate = "+80"})
            }
        },
        {
            name = "制布",
            cundangStr = "zhuanye",
            isPerHero = false,
            lvlCunDangStartIndex = 13,
            lvlCunDangEndIndex = 13,
            expCunDangStartIndex = 14,
            expCunDangEndIndex = 15,
            art = "ReplaceableTextures\\zhibu\\BTNWarcraft3 Ico.blp",
            maxLevel = 4,
            description = "击杀可收集布料的怪物有概率可以收集到布料，布料是裁缝专业的主要原料。可以通过制获取布料提高等级。等级提升可以提高制布的成功率。专业等级在不同职业之间共享。",
            currentLevel = 0,
            currentExp = 0,
            attributeLevel = {
                _attr({fa_bao = "+0.2", zhibu_rate = "+5"}),
                _attr({fa_bao = "+0.4", zhibu_rate = "+10"}),
                _attr({fa_bao = "+0.6", zhibu_rate = "+20"}),
                _attr({fa_bao = "+0.8", zhibu_rate = "+35"}),
                _attr({fa_bao = "+1.0", zhibu_rate = "+55"}),
                _attr({fa_bao = "+1.2", zhibu_rate = "+80"})
            }
        },
        {
            name = "裁缝",
            cundangStr = "zhuanye",
            isPerHero = false,
            lvlCunDangStartIndex = 16,
            lvlCunDangEndIndex = 16,
            expCunDangStartIndex = 17,
            expCunDangEndIndex = 18,
            art = "ReplaceableTextures\\caifeng\\CAIFENG.blp",
            maxLevel = 4,
            description = "制造布质护甲以及各种材料。可以通过制造物品提高等级。等级提升还可以解锁更多物品的制作方法。专业等级在不同职业之间共享。",
            currentLevel = 0,
            currentExp = 0,
            attributeLevel = {
                _attr({fa_baoshang = "+3"}),
                _attr({fa_baoshang = "+6"}),
                _attr({fa_baoshang = "+9"}),
                _attr({fa_baoshang = "+12"}),
                _attr({fa_baoshang = "+15"}),
                _attr({fa_baoshang = "+18"})
            }
        },
        {
            name = "制皮",
            cundangStr = "zhuanye",
            isPerHero = false,
            lvlCunDangStartIndex = 19,
            lvlCunDangEndIndex = 19,
            expCunDangStartIndex = 20,
            expCunDangEndIndex = 21,
            art = "ReplaceableTextures\\zhipi\\BTNWarcraft3 Ico.blp",
            maxLevel = 4,
            description = "制造皮质护甲，护甲片以及各种材料。可以通过制造物品提高等级。专业等级在不同职业之间共享。",
            currentLevel = 0,
            currentExp = 0,
            attributeLevel = {
                _attr({wu_baoshang = "+3"}),
                _attr({wu_baoshang = "+6"}),
                _attr({wu_baoshang = "+9"}),
                _attr({wu_baoshang = "+12"}),
                _attr({wu_baoshang = "+15"}),
                _attr({wu_baoshang = "+18"})
            }
        },
        {
            name = "珠宝",
            cundangStr = "zhuanye",
            isPerHero = false,
            lvlCunDangStartIndex = 22,
            lvlCunDangEndIndex = 22,
            expCunDangStartIndex = 23,
            expCunDangEndIndex = 24,
            art = "ReplaceableTextures\\zhubao\\BTNWarcraft3 Ico.blp",
            maxLevel = 4,
            description = "制造宝石以及各种材料。宝石可以镶嵌到装备。可以通过制造物品提高等级。专业等级在不同职业之间共享。",
            currentLevel = 0,
            currentExp = 0,
            attributeLevel = {
                _attr({wu_zengshang = "+1"}),
                _attr({wu_zengshang = "+3"}),
                _attr({wu_zengshang = "+5"}),
                _attr({wu_zengshang = "+7"}),
                _attr({wu_zengshang = "+9"}),
                _attr({wu_zengshang = "+11"})
            }
        },
        {
            name = "附魔",
            cundangStr = "zhuanye",
            isPerHero = false,
            lvlCunDangStartIndex = 25,
            lvlCunDangEndIndex = 25,
            expCunDangStartIndex = 26,
            expCunDangEndIndex = 27,
            art = "ReplaceableTextures\\fumo\\BTNWarcraft3 Ico.blp",
            maxLevel = 4,
            description = "制造附魔卷轴以及各种材料。附魔可以增强装备的属性，有的附魔还可以使装备获得技能。可以通过制造物品提高等级。专业等级在不同职业之间共享。",
            currentLevel = 0,
            currentExp = 0,
            attributeLevel = {
                _attr({fa_zengshang = "+1"}),
                _attr({fa_zengshang = "+3"}),
                _attr({fa_zengshang = "+5"}),
                _attr({fa_zengshang = "+7"}),
                _attr({fa_zengshang = "+9"}),
                _attr({fa_zengshang = "+11"})
            }
        },
        {
            name = "铭文",
            cundangStr = "zhuanye",
            isPerHero = false,
            lvlCunDangStartIndex = 28,
            lvlCunDangEndIndex = 28,
            expCunDangStartIndex = 29,
            expCunDangEndIndex = 30,
            art = "ReplaceableTextures\\mingwen\\BTNWarcraft3 Ico.blp",
            maxLevel = 4,
            description = "制造铭文以及各种材料。铭文可以改变特定职业技能的机制，是后期不可或缺的物品。可以通过制造物品提高等级。专业等级在不同职业之间共享。",
            currentLevel = 0,
            currentExp = 0,
            attributeLevel = {
                _attr({exp_ratio = "+1"}),
                _attr({exp_ratio = "+2"}),
                _attr({exp_ratio = "+4"}),
                _attr({exp_ratio = "+6"}),
                _attr({exp_ratio = "+10"}),
                _attr({exp_ratio = "+15"})
            }
        },
        {
            name = "钓鱼",
            cundangStr = "zhuanye",
            isPerHero = false,
            lvlCunDangStartIndex = 31,
            lvlCunDangEndIndex = 31,
            expCunDangStartIndex = 32,
            expCunDangEndIndex = 33,
            art = "ReplaceableTextures\\diaoyu\\yugan.blp",
            maxLevel = 4,
            description = "可以在钓鱼点钓鱼（新手村的钓鱼点在月亮湖副本入口的右边）。钓到的鱼可以增加英雄的属性。稀有度越高的鱼加成越高。可以通过钓鱼提高等级。等级提升可以提高钓鱼的成功率。钓鱼图鉴存档全职业" ..
                hcolor.yellow("共享"),
            currentLevel = 0,
            currentExp = 0,
            attributeLevel = {
                _attr({master = "+10", diaoyu_rate = "+5"}),
                _attr({master = "+15", diaoyu_rate = "+10"}),
                _attr({master = "+20", diaoyu_rate = "+20"}),
                _attr({master = "+25", diaoyu_rate = "+35"}),
                _attr({master = "+30", diaoyu_rate = "+55"}),
                _attr({master = "+35", diaoyu_rate = "+80"})
            }
        },
        {
            name = "炼金",
            cundangStr = "zhuanye",
            isPerHero = false,
            lvlCunDangStartIndex = 34,
            lvlCunDangEndIndex = 34,
            expCunDangStartIndex = 35,
            expCunDangEndIndex = 36,
            art = "ReplaceableTextures\\lianjin\\BTNWarcraft3 Ico.blp",
            maxLevel = 4,
            description = "制造药水和药剂以及各种材料。药水可以极大增强英雄的实力，是开荒的利器。可以通过制造物品提高等级。等级提升可以提高药水的持续时间。等级提升还可以解锁更多物品的制作方法。专业等级在不同职业之间共享。",
            currentLevel = 0,
            currentExp = 0,
            attributeLevel = {
                _attr({yaoshui_shijian = "+10"}),
                _attr({yaoshui_shijian = "+15"}),
                _attr({yaoshui_shijian = "+20"}),
                _attr({yaoshui_shijian = "+25"}),
                _attr({yaoshui_shijian = "+30"}),
                _attr({yaoshui_shijian = "+35"})
            }
        }
    }
    hzhuanye.init(config)
end

-- TODO  上架前共享专业
