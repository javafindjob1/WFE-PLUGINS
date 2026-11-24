function init_tujian_config()
    local config = {
        {
            name = "巨魔",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 1,
            cunDangEndIndex = 2,
            currentCount = 0,
            effectiveLevel = 1,
            attr = _attr(
                {
                    zhushuxing = "+1"
                }
            )
        },
        {
            name = "巨魔狂战士",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 3,
            cunDangEndIndex = 4,
            currentCount = 0,
            effectiveLevel = 1,
            attr = _attr(
                {
                    zhushuxing = "+1"
                }
            )
        },
        {
            name = "巨魔领主",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 5,
            cunDangEndIndex = 6,
            currentCount = 0,
            effectiveLevel = 1,
            attr = _attr(
                {
                    life = "+5"
                }
            )
        },
        {
            name = "狗头人",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 9,
            cunDangEndIndex = 10,
            currentCount = 0,
            effectiveLevel = 1,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "狗头人战士",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 11,
            cunDangEndIndex = 12,
            currentCount = 0,
            effectiveLevel = 1,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "狗头人术士",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 13,
            cunDangEndIndex = 14,
            currentCount = 0,
            effectiveLevel = 1,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "狗头人领主",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 15,
            cunDangEndIndex = 16,
            currentCount = 0,
            effectiveLevel = 1,
            attr = _attr(
                {
                    life = "+6"
                }
            )
        },
        {
            name = "熊怪",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 17,
            cunDangEndIndex = 18,
            currentCount = 0,
            effectiveLevel = 1,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "熊怪战士",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 19,
            cunDangEndIndex = 20,
            currentCount = 0,
            effectiveLevel = 1,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "熊怪领主",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 21,
            cunDangEndIndex = 22,
            currentCount = 0,
            effectiveLevel = 1,
            attr = _attr(
                {
                    life_back = "+1"
                }
            )
        },
        {
            name = "野狼",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 7,
            cunDangEndIndex = 8,
            currentCount = 0,
            effectiveLevel = 10,
            attr = _attr(
                {
                    defend_white = "+1"
                }
            )
        },
        {
            name = "精英野狼",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 23,
            cunDangEndIndex = 24,
            currentCount = 0,
            effectiveLevel = 10,
            attr = _attr(
                {
                    defend_white = "+2"
                }
            )
        },
        {
            name = "巨狼",
            rate = 5000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 25,
            cunDangEndIndex = 26,
            currentCount = 0,
            effectiveLevel = 10,
            attr = _attr(
                {
                    life = "+7"
                }
            )
        },
        {
            name = "铁狼",
            rate = 5000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 27,
            cunDangEndIndex = 28,
            currentCount = 0,
            effectiveLevel = 10,
            attr = _attr(
                {
                    zhushuxing = "+3"
                }
            )
        },
        {
            name = "银月狼王",
            rate = 5000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 29,
            cunDangEndIndex = 30,
            currentCount = 0,
            effectiveLevel = 10,
            attr = _attr(
                {
                    life_back = "+2"
                }
            )
        },
        {
            name = "鱼人",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 31,
            cunDangEndIndex = 32,
            currentCount = 0,
            effectiveLevel = 10,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "鱼人战士",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 33,
            cunDangEndIndex = 34,
            currentCount = 0,
            effectiveLevel = 10,
            attr = _attr(
                {
                    life = "+5"
                }
            )
        },
        {
            name = "鱼人法师",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 35,
            cunDangEndIndex = 36,
            currentCount = 0,
            effectiveLevel = 10,
            attr = _attr(
                {
                    defend_white = "+2"
                }
            )
        },
        {
            name = "鱼人猎手",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 37,
            cunDangEndIndex = 38,
            currentCount = 0,
            effectiveLevel = 10,
            attr = _attr(
                {
                    life_back = "+1"
                }
            )
        },
        {
            name = "鱼人精英战士",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 39,
            cunDangEndIndex = 40,
            currentCount = 0,
            effectiveLevel = 15,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "鱼人精英法师",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 41,
            cunDangEndIndex = 42,
            currentCount = 0,
            effectiveLevel = 15,
            attr = _attr(
                {
                    life = "+6"
                }
            )
        },
        {
            name = "鱼人精英猎手",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 43,
            cunDangEndIndex = 44,
            currentCount = 0,
            effectiveLevel = 15,
            attr = _attr(
                {
                    defend_white = "+2"
                }
            )
        },
        {
            name = "鱼人领主",
            rate = 1000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 45,
            cunDangEndIndex = 46,
            currentCount = 0,
            effectiveLevel = 10,
            attr = _attr(
                {
                    life_back = "+2"
                }
            )
        },
        {
            name = "绿鳞",
            rate = 5000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 53,
            cunDangEndIndex = 54,
            currentCount = 0,
            effectiveLevel = 15,
            attr = _attr(
                {
                    attack_speed = "+0.1"
                }
            )
        },
        {
            name = "黑鳞",
            rate = 5000,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 3,
            cunDangEndIndex = 4,
            currentCount = 0,
            effectiveLevel = 15,
            attr = _attr(
                {
                    zhushuxing = "+4"
                }
            )
        },
        {
            name = "银鳞",
            rate = 5000,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 45,
            cunDangEndIndex = 46,
            currentCount = 0,
            effectiveLevel = 15,
            attr = _attr(
                {
                    skill_speed = "+0.1"
                }
            )
        },
        {
            name = "豺狼人",
            rate = 900,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 47,
            cunDangEndIndex = 48,
            currentCount = 0,
            effectiveLevel = 20,
            attr = _attr(
                {
                    life = "+6"
                }
            )
        },
        {
            name = "豺狼战士",
            rate = 900,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 49,
            cunDangEndIndex = 50,
            currentCount = 0,
            effectiveLevel = 20,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "豺狼领主",
            rate = 900,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 51,
            cunDangEndIndex = 52,
            currentCount = 0,
            effectiveLevel = 20,
            attr = _attr(
                {
                    life_back = "1"
                }
            )
        },
        {
            name = "强盗",
            rate = 900,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 55,
            cunDangEndIndex = 56,
            currentCount = 0,
            effectiveLevel = 20,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "土匪",
            rate = 900,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 57,
            cunDangEndIndex = 58,
            currentCount = 0,
            effectiveLevel = 20,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "刺客",
            rate = 900,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 59,
            cunDangEndIndex = 60,
            currentCount = 0,
            effectiveLevel = 20,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "精英强盗",
            rate = 900,
            cundangStr = "tujian",
            isPerHero = false,
            cunDangStartIndex = 61,
            cunDangEndIndex = 62,
            currentCount = 0,
            effectiveLevel = 25,
            attr = _attr(
                {
                    zhushuxing = "+3"
                }
            )
        },
        {
            name = "精英土匪",
            rate = 900,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 1,
            cunDangEndIndex = 2,
            currentCount = 0,
            effectiveLevel = 25,
            attr = _attr(
                {
                    zhushuxing = "+3"
                }
            )
        },
        {
            name = "暴徒洛克",
            rate = 5000,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 5,
            cunDangEndIndex = 6,
            currentCount = 0,
            effectiveLevel = 25,
            attr = _attr(
                {
                    attack_white = "+5"
                }
            )
        },
        {
            name = "屠杀者霍克",
            rate = 5000,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 7,
            cunDangEndIndex = 8,
            currentCount = 0,
            effectiveLevel = 25,
            attr = _attr(
                {
                    life_back = "+2"
                }
            )
        },
        {
            name = "监狱之王范克瑞夫",
            rate = 5000,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 9,
            cunDangEndIndex = 10,
            currentCount = 0,
            effectiveLevel = 25,
            attr = _attr(
                {
                    attack_speed = "+0.2"
                }
            )
        },
        {
            name = "血色军剑士",
            rate = 900,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 11,
            cunDangEndIndex = 12,
            currentCount = 0,
            effectiveLevel = 32,
            attr = _attr(
                {
                    zhushuxing = "+3"
                }
            )
        },
        {
            name = "血色军卫士",
            rate = 900,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 13,
            cunDangEndIndex = 14,
            currentCount = 0,
            effectiveLevel = 32,
            attr = _attr(
                {
                    life = "+7"
                }
            )
        },
        {
            name = "血色军法师",
            rate = 900,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 15,
            cunDangEndIndex = 16,
            currentCount = 0,
            effectiveLevel = 32,
            attr = _attr(
                {
                    zhushuxing = "+3"
                }
            )
        },
        {
            name = "血色军统帅莫格莱尼",
            rate = 5000,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 17,
            cunDangEndIndex = 18,
            currentCount = 0,
            effectiveLevel = 32,
            attr = _attr(
                {
                    life = "+7"
                }
            )
        },
        {
            name = "训犬大师杜兰",
            rate = 5000,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 19,
            cunDangEndIndex = 20,
            currentCount = 0,
            effectiveLevel = 32,
            attr = _attr(
                {
                    zhushuxing = "+4"
                }
            )
        },
        {
            name = "血色勇士赫罗德",
            rate = 5000,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 21,
            cunDangEndIndex = 22,
            currentCount = 0,
            effectiveLevel = 32,
            attr = _attr(
                {
                    wu_bao = "+0.1"
                }
            )
        },
        {
            name = "大检察官迈恩",
            rate = 5000,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 23,
            cunDangEndIndex = 24,
            currentCount = 0,
            effectiveLevel = 32,
            attr = _attr(
                {
                    zhushuxing = "+5"
                }
            )
        },
        {
            name = "游荡的血色军剑士",
            rate = 500,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 25,
            cunDangEndIndex = 26,
            currentCount = 0,
            effectiveLevel = 31,
            attr = _attr(
                {
                    attack_white = "+3"
                }
            )
        },
        {
            name = "游荡的血色军卫士",
            rate = 500,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 27,
            cunDangEndIndex = 28,
            currentCount = 0,
            effectiveLevel = 31,
            attr = _attr(
                {
                    life = "+7"
                }
            )
        },
        {
            name = "游荡的血色军法师",
            rate = 500,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 29,
            cunDangEndIndex = 30,
            currentCount = 0,
            effectiveLevel = 31,
            attr = _attr(
                {
                    zhushuxing = "+3"
                }
            )
        },
        {
            name = "血色军下士",
            rate = 1000,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 31,
            cunDangEndIndex = 32,
            currentCount = 0,
            effectiveLevel = 32,
            attr = _attr(
                {
                    defend_white = "+2"
                }
            )
        },
        {
            name = "反叛军步卒",
            rate = 500,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 33,
            cunDangEndIndex = 34,
            currentCount = 0,
            effectiveLevel = 34,
            attr = _attr(
                {
                    gedang = "+0.1"
                }
            )
        },
        {
            name = "反叛军牧师",
            rate = 500,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 35,
            cunDangEndIndex = 36,
            currentCount = 0,
            effectiveLevel = 35,
            attr = _attr(
                {
                    life_back = "+2"
                }
            )
        },
        {
            name = "低等缝合怪",
            rate = 500,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 37,
            cunDangEndIndex = 38,
            currentCount = 0,
            effectiveLevel = 36,
            attr = _attr(
                {
                    life = "+10"
                }
            )
        },
        {
            name = "教堂近卫军",
            rate = 500,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 39,
            cunDangEndIndex = 40,
            currentCount = 0,
            effectiveLevel = 40,
            attr = _attr(
                {
                    defend_white = "+2"
                }
            )
        },
        {
            name = "教堂牧师",
            rate = 500,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 41,
            cunDangEndIndex = 42,
            currentCount = 0,
            effectiveLevel = 40,
            attr = _attr(
                {
                    healer_zengqiang = "+0.2"
                }
            )
        },
        {
            name = "试验腐败缝合怪",
            rate = 1000,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 43,
            cunDangEndIndex = 44,
            currentCount = 0,
            effectiveLevel = 40,
            attr = _attr(
                {
                    life = "+10"
                }
            )
        },
        {
            name = "裁判长萨提斯",
            rate = 5000,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 45,
            cunDangEndIndex = 46,
            currentCount = 0,
            effectiveLevel = 41,
            attr = _attr(
                {
                    master = "+3"
                }
            )
        },
        {
            name = "完美腐败缝合怪",
            rate = 5000,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 47,
            cunDangEndIndex = 48,
            currentCount = 0,
            effectiveLevel = 41,
            attr = _attr(
                {
                    life_back = "+3"
                }
            )
        },
        {
            name = "圣光主教布莱克安",
            rate = 5000,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 49,
            cunDangEndIndex = 50,
            currentCount = 0,
            effectiveLevel = 42,
            attr = _attr(
                {
                    skill_speed = "+0.1"
                }
            )
        },
        {
            name = "人马苦工",
            rate = 300,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 51,
            cunDangEndIndex = 52,
            currentCount = 0,
            effectiveLevel = 40,
            attr = _attr(
                {
                    life_back = "+1"
                }
            )
        },
        {
            name = "人马弓箭手",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 55,
            cunDangEndIndex = 56,
            currentCount = 0,
            effectiveLevel = 40,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "人马刺客",
            rate = 300,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 53,
            cunDangEndIndex = 54,
            currentCount = 0,
            effectiveLevel = 40,
            attr = _attr(
                {
                    attack_white = "+5"
                }
            )
        },
        {
            name = "人马先行者",
            rate = 300,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 55,
            cunDangEndIndex = 56,
            currentCount = 0,
            effectiveLevel = 40,
            attr = _attr(
                {
                    life = "+8"
                }
            )
        },
        {
            name = "人马先知",
            rate = 300,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 57,
            cunDangEndIndex = 58,
            currentCount = 0,
            effectiveLevel = 40,
            attr = _attr(
                {
                    fa_chuan = "+0.1"
                }
            )
        },
        {
            name = "人马领主",
            rate = 600,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 59,
            cunDangEndIndex = 60,
            currentCount = 0,
            effectiveLevel = 40,
            attr = _attr(
                {
                    life_back = "+1"
                }
            )
        },
        {
            name = "人马精英弓箭手",
            rate = 300,
            cundangStr = "tujian1",
            isPerHero = false,
            cunDangStartIndex = 61,
            cunDangEndIndex = 62,
            currentCount = 0,
            effectiveLevel = 40,
            attr = _attr(
                {
                    wu_chuan = "+0.1"
                }
            )
        },
        {
            name = "人马精英先知",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 1,
            cunDangEndIndex = 2,
            currentCount = 0,
            effectiveLevel = 40,
            attr = _attr(
                {
                    fa_chuan = "+0.1"
                }
            )
        },
        {
            name = "人马精英勇士",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 3,
            cunDangEndIndex = 4,
            currentCount = 0,
            effectiveLevel = 40,
            attr = _attr(
                {
                    life = "+10"
                }
            )
        },
        {
            name = "快刀手迅蹄",
            rate = 5000,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 5,
            cunDangEndIndex = 6,
            currentCount = 0,
            effectiveLevel = 45,
            attr = _attr(
                {
                    wu_chuan = "+0.1"
                }
            )
        },
        {
            name = "人马弓神布鲁斯",
            rate = 5000,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 7,
            cunDangEndIndex = 8,
            currentCount = 0,
            effectiveLevel = 45,
            attr = _attr(
                {
                    hit = "+0.1"
                }
            )
        },
        {
            name = "人马酋长战争之蹄",
            rate = 5000,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 9,
            cunDangEndIndex = 10,
            currentCount = 0,
            effectiveLevel = 45,
            attr = _attr(
                {
                    jianshang = "+0.1"
                }
            )
        },
        {
            name = "鹰身女妖侦察者",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 11,
            cunDangEndIndex = 12,
            currentCount = 0,
            effectiveLevel = 40,
            attr = _attr(
                {
                    move = "+1"
                }
            )
        },
        {
            name = "鹰身女妖",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 13,
            cunDangEndIndex = 14,
            currentCount = 0,
            effectiveLevel = 40,
            attr = _attr(
                {
                    zhushuxing = "+3"
                }
            )
        },
        {
            name = "鹰身女妖巫师",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 15,
            cunDangEndIndex = 16,
            currentCount = 0,
            effectiveLevel = 40,
            attr = _attr(
                {
                    energy_back = "+0.1"
                }
            )
        },
        {
            name = "黑铁矮人矿工",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 17,
            cunDangEndIndex = 18,
            currentCount = 0,
            effectiveLevel = 50,
            attr = _attr(
                {
                    life_back = "+1"
                }
            )
        },
        {
            name = "黑铁矮人守卫",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 19,
            cunDangEndIndex = 20,
            currentCount = 0,
            effectiveLevel = 50,
            attr = _attr(
                {
                    defend_white = "+1"
                }
            )
        },
        {
            name = "黑铁矮人枪手",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 21,
            cunDangEndIndex = 22,
            currentCount = 0,
            effectiveLevel = 50,
            attr = _attr(
                {
                    hit = "+0.1"
                }
            )
        },
        {
            name = "精英黑铁矮人矿工",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 23,
            cunDangEndIndex = 24,
            currentCount = 0,
            effectiveLevel = 53,
            attr = _attr(
                {
                    life_back = "+2"
                }
            )
        },
        {
            name = "精英黑铁矮人守卫",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 25,
            cunDangEndIndex = 26,
            currentCount = 0,
            effectiveLevel = 53,
            attr = _attr(
                {
                    defend_white = "+2"
                }
            )
        },
        {
            name = "精英黑铁矮人枪手",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 27,
            cunDangEndIndex = 28,
            currentCount = 0,
            effectiveLevel = 53,
            attr = _attr(
                {
                    hit = "+0.1"
                }
            )
        },
        {
            name = "矮人守卫队长杜尼尔",
            rate = 5000,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 29,
            cunDangEndIndex = 30,
            currentCount = 0,
            effectiveLevel = 55,
            attr = _attr(
                {
                    defend_white = "+2"
                }
            )
        },
        {
            name = "嗜血的格洛格",
            rate = 5000,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 31,
            cunDangEndIndex = 32,
            currentCount = 0,
            effectiveLevel = 55,
            attr = _attr(
                {
                    skill_speed = "+0.1"
                }
            )
        },
        {
            name = "黑铁矮人索瑞森大帝",
            rate = 5000,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 33,
            cunDangEndIndex = 34,
            currentCount = 0,
            effectiveLevel = 55,
            attr = _attr(
                {
                    quanju_zengshang = "+0.1"
                }
            )
        },
        {
            name = "火元素",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 35,
            cunDangEndIndex = 36,
            currentCount = 0,
            effectiveLevel = 56,
            attr = _attr(
                {
                    life_back = "+2"
                }
            )
        },
        {
            name = "精英火元素",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 37,
            cunDangEndIndex = 38,
            currentCount = 0,
            effectiveLevel = 56,
            attr = _attr(
                {
                    life_back = "+2"
                }
            )
        },
        {
            name = "嘉顿",
            rate = 5000,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 39,
            cunDangEndIndex = 40,
            currentCount = 0,
            effectiveLevel = 60,
            attr = _attr(
                {
                    life_back = "+3"
                }
            )
        },
        {
            name = "石元素",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 41,
            cunDangEndIndex = 42,
            currentCount = 0,
            effectiveLevel = 56,
            attr = _attr(
                {
                    life = "+9"
                }
            )
        },
        {
            name = "精英石元素",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 43,
            cunDangEndIndex = 44,
            currentCount = 0,
            effectiveLevel = 56,
            attr = _attr(
                {
                    life = "+10"
                }
            )
        },
        {
            name = "嘉尔",
            rate = 5000,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 45,
            cunDangEndIndex = 46,
            currentCount = 0,
            effectiveLevel = 60,
            attr = _attr(
                {
                    life = "+12"
                }
            )
        },
        {
            name = "炎巨人",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 47,
            cunDangEndIndex = 48,
            currentCount = 0,
            effectiveLevel = 56,
            attr = _attr(
                {
                    defend_white = "+2"
                }
            )
        },
        {
            name = "精英炎巨人",
            rate = 300,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 49,
            cunDangEndIndex = 50,
            currentCount = 0,
            effectiveLevel = 56,
            attr = _attr(
                {
                    defend_white = "+3"
                }
            )
        },
        {
            name = "焚化者古曼",
            rate = 5000,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 51,
            cunDangEndIndex = 52,
            currentCount = 0,
            effectiveLevel = 60,
            attr = _attr(
                {
                    defend_white = "+4"
                }
            )
        },
        {
            name = "炎魔之王",
            rate = 5000,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 53,
            cunDangEndIndex = 54,
            currentCount = 0,
            effectiveLevel = 60,
            attr = _attr(
                {
                    quanju_zengshang = "+0.2"
                }
            )
        },
        {
            name = "野蛮卫兵",
            rate = 200,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 55,
            cunDangEndIndex = 56,
            currentCount = 0,
            effectiveLevel = 61,
            attr = _attr(
                {
                    zhushuxing = "+3"
                }
            )
        },
        {
            name = "狂暴卫兵",
            rate = 200,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 57,
            cunDangEndIndex = 58,
            currentCount = 0,
            effectiveLevel = 62,
            attr = _attr(
                {
                    attack_white = "+5"
                }
            )
        },
        {
            name = "射手卫兵",
            rate = 200,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 59,
            cunDangEndIndex = 60,
            currentCount = 0,
            effectiveLevel = 63,
            attr = _attr(
                {
                    attack_speed = "+0.1"
                }
            )
        },
        {
            name = "精英野蛮卫兵",
            rate = 200,
            cundangStr = "tujian2",
            isPerHero = false,
            cunDangStartIndex = 61,
            cunDangEndIndex = 62,
            currentCount = 0,
            effectiveLevel = 63,
            attr = _attr(
                {
                    zhushuxing = "+3"
                }
            )
        },
        {
            name = "精英狂暴卫兵",
            rate = 200,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 1,
            cunDangEndIndex = 2,
            currentCount = 0,
            effectiveLevel = 63,
            attr = _attr(
                {
                    attack_white = "+5"
                }
            )
        },
        {
            name = "精英射手卫兵",
            rate = 200,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 3,
            cunDangEndIndex = 4,
            currentCount = 0,
            effectiveLevel = 63,
            attr = _attr(
                {
                    attack_speed = "+0.1"
                }
            )
        },
        {
            name = "戈隆",
            rate = 300,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 5,
            cunDangEndIndex = 6,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    shengming_baifenbi = "+0.1"
                }
            )
        },
        {
            name = "高阶术士",
            rate = 3000,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 7,
            cunDangEndIndex = 8,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    skill_speed = "+0.1"
                }
            )
        },
        {
            name = "战争使者",
            rate = 3000,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 9,
            cunDangEndIndex = 10,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    gongji_baifenbi = "+0.1"
                }
            )
        },
        {
            name = "酋长卡加斯·刃拳",
            rate = 3000,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 11,
            cunDangEndIndex = 12,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    wu_zengshang = "+0.1"
                }
            )
        },
        {
            name = "屠龙者格鲁",
            rate = 3000,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 13,
            cunDangEndIndex = 14,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    quanju_zengshang = "+0.1"
                }
            )
        },
        {
            name = "法师塔卫士",
            rate = 200,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 15,
            cunDangEndIndex = 16,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    defend_white = "+1"
                }
            )
        },
        {
            name = "法师塔术士",
            rate = 200,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 17,
            cunDangEndIndex = 18,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    zhushuxing = "+3"
                }
            )
        },
        {
            name = "法师塔法师",
            rate = 200,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 19,
            cunDangEndIndex = 20,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    zhushuxing = "+3"
                }
            )
        },
        {
            name = "荣誉护卫木羽",
            rate = 1000,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 21,
            cunDangEndIndex = 22,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    attack_white = "+5"
                }
            )
        },
        {
            name = "法师塔精英卫士",
            rate = 200,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 23,
            cunDangEndIndex = 24,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    defend_white = "+1"
                }
            )
        },
        {
            name = "法师塔精英术士",
            rate = 200,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 25,
            cunDangEndIndex = 26,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    zhushuxing = "+3"
                }
            )
        },
        {
            name = "法师塔精英法师",
            rate = 200,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 27,
            cunDangEndIndex = 28,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    zhushuxing = "+3"
                }
            )
        },
        {
            name = "莫罗",
            rate = 3000,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 29,
            cunDangEndIndex = 30,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    attack_white = "+6"
                }
            )
        },
        {
            name = "图书馆馆长",
            rate = 3000,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 31,
            cunDangEndIndex = 32,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    zhushuxing = "+4"
                }
            )
        },
        {
            name = "夜之魇",
            rate = 3000,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 33,
            cunDangEndIndex = 34,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    zhushuxing = "+4"
                }
            )
        },
        {
            name = "大法师埃兰",
            rate = 3000,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 35,
            cunDangEndIndex = 36,
            currentCount = 0,
            effectiveLevel = 65,
            attr = _attr(
                {
                    fa_zengshang = "+0.1"
                }
            )
        },
        {
            name = "要塞护卫军士",
            rate = 200,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 37,
            cunDangEndIndex = 38,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "虚空占卜者",
            rate = 200,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 39,
            cunDangEndIndex = 40,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "要塞斥候",
            rate = 200,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 41,
            cunDangEndIndex = 42,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "要塞护卫军士长",
            rate = 1000,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 43,
            cunDangEndIndex = 44,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+3"
                }
            )
        },
        {
            name = "精英要塞护卫军士",
            rate = 200,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 45,
            cunDangEndIndex = 46,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "精英要塞斥候",
            rate = 200,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 47,
            cunDangEndIndex = 48,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "精英虚空占卜者",
            rate = 200,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 49,
            cunDangEndIndex = 50,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "奥",
            rate = 3000,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 51,
            cunDangEndIndex = 52,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+4"
                }
            )
        },
        {
            name = "大星术师",
            rate = 3000,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 53,
            cunDangEndIndex = 54,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+4"
                }
            )
        },
        {
            name = "凯尔萨斯·逐日者",
            rate = 3000,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 55,
            cunDangEndIndex = 56,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+4"
                }
            )
        },
        {
            name = "恶魔卫士",
            rate = 100,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 57,
            cunDangEndIndex = 58,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "黑暗术士",
            rate = 100,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 59,
            cunDangEndIndex = 60,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "恶魔女妖",
            rate = 100,
            cundangStr = "tujian3",
            isPerHero = false,
            cunDangStartIndex = 61,
            cunDangEndIndex = 62,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "神殿恶魔卫士",
            rate = 100,
            cundangStr = "tujian4",
            isPerHero = false,
            cunDangStartIndex = 1,
            cunDangEndIndex = 2,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+3"
                }
            )
        },
        {
            name = "神殿黑暗术士",
            rate = 100,
            cundangStr = "tujian4",
            isPerHero = false,
            cunDangStartIndex = 3,
            cunDangEndIndex = 4,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "神殿恶魔女妖",
            rate = 100,
            cundangStr = "tujian4",
            isPerHero = false,
            cunDangStartIndex = 5,
            cunDangEndIndex = 6,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "神殿黑暗侍女",
            rate = 100,
            cundangStr = "tujian4",
            isPerHero = false,
            cunDangStartIndex = 7,
            cunDangEndIndex = 8,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+2"
                }
            )
        },
        {
            name = "主母赫拉姆斯",
            rate = 1500,
            cundangStr = "tujian4",
            isPerHero = false,
            cunDangStartIndex = 9,
            cunDangEndIndex = 10,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+5"
                }
            )
        },
        {
            name = "背叛者",
            rate = 1500,
            cundangStr = "tujian4",
            isPerHero = false,
            cunDangStartIndex = 11,
            cunDangEndIndex = 12,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+5"
                }
            )
        },
        {
            name = "末日护卫",
            rate = 50,
            cundangStr = "tujian4",
            isPerHero = false,
            cunDangStartIndex = 13,
            cunDangEndIndex = 14,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+5"
                }
            )
        },
        {
            name = "末日弓箭手",
            rate = 50,
            cundangStr = "tujian4",
            isPerHero = false,
            cunDangStartIndex = 15,
            cunDangEndIndex = 16,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+5"
                }
            )
        },
        {
            name = "恶魔地狱火",
            rate = 50,
            cundangStr = "tujian4",
            isPerHero = false,
            cunDangStartIndex = 17,
            cunDangEndIndex = 18,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+5"
                }
            )
        },
        {
            name = "恶魔狂战士",
            rate = 50,
            cundangStr = "tujian4",
            isPerHero = false,
            cunDangStartIndex = 19,
            cunDangEndIndex = 20,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+5"
                }
            )
        },
        {
            name = "精英末日护卫",
            rate = 50,
            cundangStr = "tujian4",
            isPerHero = false,
            cunDangStartIndex = 21,
            cunDangEndIndex = 22,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+7"
                }
            )
        },
        {
            name = "精英末日弓箭手",
            rate = 50,
            cundangStr = "tujian4",
            isPerHero = false,
            cunDangStartIndex = 23,
            cunDangEndIndex = 24,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+7"
                }
            )
        },
        {
            name = "精英恶魔地狱火",
            rate = 50,
            cundangStr = "tujian4",
            isPerHero = false,
            cunDangStartIndex = 25,
            cunDangEndIndex = 26,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+7"
                }
            )
        },
        {
            name = "精英恶魔狂战士",
            rate = 50,
            cundangStr = "tujian4",
            isPerHero = false,
            cunDangStartIndex = 27,
            cunDangEndIndex = 28,
            currentCount = 0,
            effectiveLevel = 70,
            attr = _attr(
                {
                    zhushuxing = "+7"
                }
            )
        },
    }

    htujian.initFromConfig(config)
end
