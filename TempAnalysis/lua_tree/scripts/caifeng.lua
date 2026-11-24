function initCaiFeng()
    local config = {
        {
            reqLevel = 0,
            req = {
                { name = "麻布", count = 5 }
            },
            successRate = 10000,
            output = {
                name = "手工布鞋",
                itemLevel = 10,
                itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                count = 1,
                upgradeRate = 1000
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 0,
            req = {
                { name = "麻布", count = 15 }
            },
            successRate = 10000,
            output = {
                name = "灵敏刺绣",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2,
            zhizuoshijian = 10
        },
        {
            reqLevel = 0,
            req = {
                { name = "麻布", count = 40 }
            },
            successRate = 10000,
            output = {
                name = "回春刺绣",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 3,
            zhizuoshijian = 15
        },
        {
            reqLevel = 1,
            req = {
                { name = "精致麻布", count = 3 }
            },
            successRate = 10000,
            output = {
                name = "魔力刺绣",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 6,
            zhizuoshijian = 15
        },
        {
            reqLevel = 1,
            req = {
                { name = "战败勇士的头盔", count = 1 },
                { name = "血色军战盔", count = 1 },
                { name = "蓝影头盔", count = 1 },
                { name = "魔力针线", count = 5 },
                { name = "精致麻布", count = 5 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "灵力波动兜帽",
                itemLevel = 39,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 1,
            req = {
                { name = "灵力波动兜帽", count = 1 },
                { name = "光明核心碎片", count = 1 },
                { name = "魔力针线", count = 5 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "灵力波动兜帽",
                itemLevel = 39,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 1,
            req = {
                { name = "战败勇士的胸甲", count = 1 },
                { name = "血色军锁甲", count = 1 },
                { name = "蓝影衣服", count = 1 },
                { name = "魔力针线", count = 5 },
                { name = "精致麻布", count = 5 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "灵力波动法袍",
                itemLevel = 39,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 1,
            req = {
                { name = "灵力波动法袍", count = 1 },
                { name = "光明核心碎片", count = 1 },
                { name = "魔力针线", count = 5 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "灵力波动法袍",
                itemLevel = 39,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 1,
            req = {
                { name = "战败勇士的手套", count = 1 },
                { name = "血色军护手", count = 1 },
                { name = "蓝影手套", count = 1 },
                { name = "魔力针线", count = 5 },
                { name = "精致麻布", count = 5 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "灵力波动手套",
                itemLevel = 39,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 1,
            req = {
                { name = "灵力波动手套", count = 1 },
                { name = "光明核心碎片", count = 1 },
                { name = "魔力针线", count = 5 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "灵力波动手套",
                itemLevel = 39,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 1,
            req = {
                { name = "战败勇士的鞋子", count = 1 },
                { name = "血色军战靴", count = 1 },
                { name = "蓝影鞋子", count = 1 },
                { name = "魔力针线", count = 5 },
                { name = "精致麻布", count = 5 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "灵力波动长靴",
                itemLevel = 39,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 1,
            req = {
                { name = "灵力波动长靴", count = 1 },
                { name = "光明核心碎片", count = 1 },
                { name = "魔力针线", count = 5 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "灵力波动长靴",
                itemLevel = 39,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 1,
            req = {
                { name = "裁判者之影", count = 1 },
                { name = "蓝影披风", count = 1 },
                { name = "血色军披风", count = 1 },
                { name = "灵敏披风", count = 1 },
                { name = "魔法水晶", count = 2 },
                { name = "魔力针线", count = 5 }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "判决者的披风",
                itemLevel = 39,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 2,
            req = {
                { name = "冠军斗士战盔", count = 1 },
                { name = "先驱法师头盔", count = 1 },
                { name = "魔力针线", count = 20 },
                { name = "丝绸", count = 15 },
                { name = "精致丝绸", count = 5 },
                { name = "火焰精华", count = 3 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "炎灵兜帽",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "冠军斗士护手", count = 1 },
                { name = "先驱法师护手", count = 1 },
                { name = "魔力针线", count = 20 },
                { name = "丝绸", count = 15 },
                { name = "精致丝绸", count = 5 },
                { name = "火焰精华", count = 3 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "炎灵手套",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "冠军斗士战靴", count = 1 },
                { name = "先驱法师腿甲", count = 1 },
                { name = "魔力针线", count = 20 },
                { name = "丝绸", count = 15 },
                { name = "精致丝绸", count = 5 },
                { name = "火焰精华", count = 3 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "炎灵长靴",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "冠军斗士战甲", count = 1 },
                { name = "先驱法师胸甲", count = 1 },
                { name = "魔力针线", count = 20 },
                { name = "丝绸", count = 15 },
                { name = "精致丝绸", count = 5 },
                { name = "火焰精华", count = 3 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "炎灵法袍",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "炎灵兜帽", count = 1 },
                { name = "远古先驱法师头盔", count = 1 },
                { name = "魔力针线", count = 30 },
                { name = "丝绸", count = 30 },
                { name = "精致丝绸", count = 10 },
                { name = "火焰精华", count = 10 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "炎灵兜帽",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "炎灵手套", count = 1 },
                { name = "远古先驱法师护手", count = 1 },
                { name = "魔力针线", count = 30 },
                { name = "丝绸", count = 30 },
                { name = "精致丝绸", count = 10 },
                { name = "火焰精华", count = 10 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "炎灵手套",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "炎灵长靴", count = 1 },
                { name = "远古先驱法师腿甲", count = 1 },
                { name = "魔力针线", count = 30 },
                { name = "丝绸", count = 30 },
                { name = "精致丝绸", count = 10 },
                { name = "火焰精华", count = 10 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "炎灵长靴",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "炎灵法袍", count = 1 },
                { name = "远古先驱法师胸甲", count = 1 },
                { name = "魔力针线", count = 30 },
                { name = "丝绸", count = 30 },
                { name = "精致丝绸", count = 10 },
                { name = "火焰精华", count = 10 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "炎灵法袍",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "判决者的披风", count = 1 },
                { name = "酋长大氅", count = 1 },
                { name = "斗士披风", count = 1 },
                { name = "冲击披风", count = 1 },
                { name = "成年黑龙的肌腱", count = 1 },
                { name = "魔力针线", count = 15 }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "龙王披风",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "精致丝绸", count = 5 },
                { name = "人马图腾", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "中级魔力刺绣",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 10,
            zhizuoshijian = 15
        },
        {
            reqLevel = 3,
            req = {
                { name = "符文布", count = 5 },
                { name = "灵纹布", count = 1 },
                { name = "守护者的宝石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "高级魔力刺绣",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 5,
            zhizuoshijian = 10
        },
        {
            reqLevel = 3,
            req = {
                { name = "符文布", count = 5 },
                { name = "灵纹布", count = 1 },
                { name = "守护者的宝石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "高级刀锋刺绣",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 5,
            zhizuoshijian = 10
        },
        {
            reqLevel = 3,
            req = {
                { name = "符文布", count = 5 },
                { name = "灵纹布", count = 1 },
                { name = "守护者的宝石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "高级回春刺绣",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 5,
            zhizuoshijian = 10
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "纷争勇士护手",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "远征军护手",
                    count = 1
                },
                { name = "魔力针线", count = 30 },
                { name = "灵纹布", count = 10 },
                {
                    name = "屠龙者之血",
                    count = 1
                },
                {
                    name = "卡拉赞的回响",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "高阶法师护手",
                itemLevel = 70,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "纷争勇士战靴",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "远征军战靴",
                    count = 1
                },
                { name = "魔力针线", count = 30 },
                { name = "灵纹布", count = 10 },
                {
                    name = "屠龙者之血",
                    count = 1
                },
                {
                    name = "卡拉赞的回响",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "高阶法师长靴",
                itemLevel = 70,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "纷争勇士战盔",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "远征军战盔",
                    count = 1
                },
                { name = "魔力针线", count = 30 },
                { name = "灵纹布", count = 10 },
                {
                    name = "屠龙者之血",
                    count = 1
                },
                {
                    name = "卡拉赞的回响",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "高阶法师兜帽",
                itemLevel = 70,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "纷争勇士战甲",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "远征军战甲",
                    count = 1
                },
                { name = "魔力针线", count = 30 },
                { name = "灵纹布", count = 10 },
                {
                    name = "屠龙者之血",
                    count = 1
                },
                {
                    name = "卡拉赞的回响",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "高阶法师长袍",
                itemLevel = 70,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "高阶法师护手",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "先锋远征军护手",
                    count = 1
                },
                {
                    name = "魔力针线",
                    count = 50
                },
                {
                    name = "灵纹布",
                    count = 20
                },
                {
                    name = "屠龙者之血",
                    count = 2
                },
                {
                    name = "卡拉赞的回响",
                    count = 2
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "高阶法师护手",
                itemLevel = 70,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "高阶法师长靴",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "先锋远征军战靴",
                    count = 1
                },
                {
                    name = "魔力针线",
                    count = 50
                },
                {
                    name = "灵纹布",
                    count = 20
                },
                {
                    name = "屠龙者之血",
                    count = 2
                },
                {
                    name = "卡拉赞的回响",
                    count = 2
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "高阶法师长靴",
                itemLevel = 70,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "高阶法师兜帽",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "先锋远征军战盔",
                    count = 1
                },
                {
                    name = "魔力针线",
                    count = 50
                },
                {
                    name = "灵纹布",
                    count = 20
                },
                {
                    name = "屠龙者之血",
                    count = 2
                },
                {
                    name = "卡拉赞的回响",
                    count = 2
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "高阶法师兜帽",
                itemLevel = 70,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "高阶法师长袍",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "先锋远征军战甲",
                    count = 1
                },
                {
                    name = "魔力针线",
                    count = 50
                },
                {
                    name = "灵纹布",
                    count = 20
                },
                {
                    name = "屠龙者之血",
                    count = 2
                },
                {
                    name = "卡拉赞的回响",
                    count = 2
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "高阶法师长袍",
                itemLevel = 70,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "纷争勇士披风",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "远征军斗篷",
                    count = 1
                },
                { name = "魔力针线", count = 30 },
                { name = "灵纹布", count = 10 },
                {
                    name = "屠龙者之血",
                    count = 1
                },
                {
                    name = "卡拉赞的回响",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "无畏战将披风",
                itemLevel = 70,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "无畏战将披风",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "先锋远征军斗篷",
                    count = 1
                },
                { name = "魔力针线", count = 50 },
                { name = "灵纹布", count = 20 },
                {
                    name = "屠龙者之血",
                    count = 2
                },
                {
                    name = "卡拉赞的回响",
                    count = 2
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "无畏战将披风",
                itemLevel = 70,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "纷争勇士披风",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "远征军斗篷",
                    count = 1
                },
                { name = "魔力针线", count = 30 },
                { name = "灵纹布", count = 10 },
                {
                    name = "屠龙者之血",
                    count = 1
                },
                {
                    name = "卡拉赞的回响",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "暗影猎手披风",
                itemLevel = 70,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "暗影猎手披风",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "先锋远征军斗篷",
                    count = 1
                },
                { name = "魔力针线", count = 50 },
                { name = "灵纹布", count = 20 },
                {
                    name = "屠龙者之血",
                    count = 2
                },
                {
                    name = "卡拉赞的回响",
                    count = 2
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "暗影猎手披风",
                itemLevel = 70,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "纷争勇士披风",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "远征军斗篷",
                    count = 1
                },
                { name = "魔力针线", count = 30 },
                { name = "灵纹布", count = 10 },
                {
                    name = "屠龙者之血",
                    count = 1
                },
                {
                    name = "卡拉赞的回响",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "高阶法师披风",
                itemLevel = 70,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "高阶法师披风",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "先锋远征军斗篷",
                    count = 1
                },
                { name = "魔力针线", count = 50 },
                { name = "灵纹布", count = 20 },
                {
                    name = "屠龙者之血",
                    count = 2
                },
                {
                    name = "卡拉赞的回响",
                    count = 2
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "高阶法师披风",
                itemLevel = 70,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "光荣护手",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "黑暗意志手套",
                    count = 1
                },
                { name = "魔力针线", count = 100 },
                { name = "灵纹布", count = 40 },
                {
                    name = "翠绿魔珠",
                    count = 5
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "风暴术士手套",
                itemLevel = 71,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "光荣长靴",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "黑暗意志长靴",
                    count = 1
                },
                { name = "魔力针线", count = 100 },
                { name = "灵纹布", count = 40 },
                {
                    name = "翠绿魔珠",
                    count = 5
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "风暴术士长靴",
                itemLevel = 71,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "光荣战盔",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "黑暗意志头盔",
                    count = 1
                },
                { name = "魔力针线", count = 100 },
                { name = "灵纹布", count = 40 },
                {
                    name = "黑暗精华",
                    count = 5
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "风暴术士头冠",
                itemLevel = 72,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "风暴术士手套",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "史诗黑暗意志手套",
                    count = 1
                },
                { name = "魔力针线", count = 150 },
                { name = "灵纹布", count = 60 },
                {
                    name = "翠绿魔珠",
                    count = 8
                },
                {
                    name = "女祭司的记忆",
                    count = 3
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "风暴术士手套",
                itemLevel = 71,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "风暴术士长靴",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "史诗黑暗意志长靴",
                    count = 1
                },
                { name = "魔力针线", count = 150 },
                { name = "灵纹布", count = 60 },
                {
                    name = "翠绿魔珠",
                    count = 8
                },
                {
                    name = "女祭司的记忆",
                    count = 3
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "风暴术士长靴",
                itemLevel = 71,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "风暴术士头冠",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "史诗黑暗意志头盔",
                    count = 1
                },
                { name = "魔力针线", count = 150 },
                { name = "灵纹布", count = 60 },
                {
                    name = "黑暗精华",
                    count = 8
                },
                {
                    name = "女祭司的记忆",
                    count = 3
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "风暴术士头冠",
                itemLevel = 72,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "光荣披风",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "黑暗意志披风",
                    count = 1
                },
                { name = "魔力针线", count = 100 },
                { name = "灵纹布", count = 40 },
                {
                    name = "黑暗精华",
                    count = 5,
                },
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "风暴术士披风",
                itemLevel = 72,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "风暴术士披风",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "史诗黑暗意志披风",
                    count = 1
                },
                { name = "魔力针线", count = 150 },
                { name = "灵纹布", count = 60 },
                {
                    name = "黑暗精华",
                    count = 8
                },
                {
                    name = "女祭司的记忆",
                    count = 3
                },
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "风暴术士披风",
                itemLevel = 72,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "光荣披风",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "黑暗意志披风",
                    count = 1
                },
                { name = "魔力针线", count = 100 },
                { name = "灵纹布", count = 40 },
                {
                    name = "黑暗精华",
                    count = 5,
                },
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "晨曦游侠披风",
                itemLevel = 72,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "晨曦游侠披风",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "史诗黑暗意志披风",
                    count = 1
                },
                { name = "魔力针线", count = 150 },
                { name = "灵纹布", count = 60 },
                {
                    name = "黑暗精华",
                    count = 8
                },
                {
                    name = "女祭司的记忆",
                    count = 3
                },
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "晨曦游侠披风",
                itemLevel = 72,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "光荣披风",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "黑暗意志披风",
                    count = 1
                },
                { name = "魔力针线", count = 100 },
                { name = "灵纹布", count = 40 },
                {
                    name = "黑暗精华",
                    count = 5,
                },
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "秩序守护者之翼",
                itemLevel = 72,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "秩序守护者之翼",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "史诗黑暗意志披风",
                    count = 1
                },
                { name = "魔力针线", count = 150 },
                { name = "灵纹布", count = 60 },
                {
                    name = "黑暗精华",
                    count = 8
                },
                {
                    name = "女祭司的记忆",
                    count = 3
                },
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "秩序守护者之翼",
                itemLevel = 72,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "光荣战甲",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "黑暗意志胸甲",
                    count = 1
                },
                { name = "魔力针线", count = 100 },
                { name = "灵纹布", count = 40 },
                {
                    name = "黑暗精华",
                    count = 5
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "风暴术士长袍",
                itemLevel = 73,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.YINGXIONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "风暴术士长袍",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "史诗黑暗意志胸甲",
                    count = 1
                },
                { name = "魔力针线", count = 150 },
                { name = "灵纹布", count = 60 },
                {
                    name = "欺诈者之眼",
                    count = 3
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "风暴术士长袍",
                itemLevel = 73,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
    }

    local cixiuConfig = {
        {
            name = "灵敏刺绣",
            itemCunDangStr = "1",
            _skillEffect = {
                {
                    description = "生命降低到50%以下会触发灵敏效果，闪避提高10%，持续10秒，CD60秒",
                    attr_type = CONST_EVENT.beDamage,
                    attr = function(evtData)
                        if
                            hunit.getCurLifePercent(evtData.triggerUnit) <= 50 and
                            hskill.checkAndEnterCD(evtData.triggerUnit, "灵敏刺绣", 60)
                        then
                            hbuff.update(
                                10,
                                evtData.triggerUnit,
                                "灵敏刺绣buff",
                                true,
                                function()
                                    hattribute.set(evtData.triggerUnit, 0, _attr({ shanbi = "+10" }))
                                end,
                                function()
                                    hattribute.set(evtData.triggerUnit, 0, _attr({ shanbi = "-10" }))
                                end,
                                hslk.n2v("灵敏刺绣", "Art"),
                                "灵敏刺绣:闪避提高10%",
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
            },
            zhuangbeiTypes = { "披风" }
        },
        {
            name = "回春刺绣",
            itemCunDangStr = "2",
            _skillEffect = {
                {
                    description = "被攻击有概率触发回春效果，生命恢复提高2%，持续10秒，CD60秒",
                    attr_type = CONST_EVENT.beDamage,
                    attr = function(evtData)
                        if
                            hunit.getCurLifePercent(evtData.triggerUnit) <= 50 and
                            hskill.checkAndEnterCD(evtData.triggerUnit, "回春刺绣", 60)
                        then
                            local lifeback = tostring(hunit.getMaxLife(evtData.triggerUnit) * 0.02 or 1)
                            hbuff.update(
                                10,
                                evtData.triggerUnit,
                                "回春刺绣buff",
                                true,
                                function()
                                    hattribute.set(evtData.triggerUnit, 0, _attr({ life_back = "+" .. lifeback }))
                                end,
                                function()
                                    hattribute.set(evtData.triggerUnit, 0, _attr({ life_back = "-" .. lifeback }))
                                end,
                                hslk.n2v("回春刺绣", "Art"),
                                "回春刺绣：生命恢复提高" .. lifeback,
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
            },
            zhuangbeiTypes = { "披风" }
        },
        {
            name = "魔力刺绣",
            itemCunDangStr = "3",
            _skillEffect = {
                {
                    description = "施法有概率触发魔力精通效果，提高造成的所有魔法伤害2%，持续10秒，cd60秒",
                    attr_type = CONST_EVENT.skillEffect,
                    attr = function(evtData)
                        if hskill.checkAndEnterCD(evtData.triggerUnit, "魔力刺绣", 60) then
                            hbuff.update(
                                10,
                                evtData.triggerUnit,
                                "魔力刺绣buff",
                                true,
                                function()
                                    hevent.register(
                                        evtData.triggerUnit,
                                        CONST_EVENT.damagingCustomSource,
                                        "魔力刺绣额外增伤",
                                        function(newData)
                                            if newData.damageType == DAMAGE_TYPE.MOFA then
                                                newData.damage = newData.damage * 1.02
                                            end
                                        end
                                    )
                                end,
                                function()
                                    hevent.unregister(evtData.triggerUnit, CONST_EVENT.damagingCustomSource, "魔力刺绣额外增伤")
                                end,
                                hslk.n2v("魔力刺绣", "Art"),
                                "魔力刺绣:所有魔法伤害2%",
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
            },
            zhuangbeiTypes = { "披风" }
        },
        {
            name = "中级魔力刺绣",
            itemCunDangStr = "4",
            _skillEffect = {
                {
                    description = "施法有概率触发中级魔力精通效果，提高造成的所有魔法伤害3%，持续10秒，cd60秒",
                    attr_type = CONST_EVENT.skillEffect,
                    attr = function(evtData)
                        if hskill.checkAndEnterCD(evtData.triggerUnit, "魔力刺绣", 60) then
                            hbuff.update(
                                10,
                                evtData.triggerUnit,
                                "魔力刺绣buff",
                                true,
                                function()
                                    hevent.register(
                                        evtData.triggerUnit,
                                        CONST_EVENT.damagingCustomSource,
                                        "中级魔力刺绣额外增伤",
                                        function(newData)
                                            if newData.damageType == DAMAGE_TYPE.MOFA then
                                                newData.damage = newData.damage * 1.03
                                            end
                                        end
                                    )
                                end,
                                function()
                                    hevent.unregister(
                                        evtData.triggerUnit,
                                        CONST_EVENT.damagingCustomSource,
                                        "中级魔力刺绣额外增伤"
                                    )
                                end,
                                hslk.n2v("中级魔力刺绣", "Art"),
                                "中级魔力刺绣:所有魔法伤害3%",
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
            },
            zhuangbeiTypes = { "披风" }
        },
        {
            name = "高级魔力刺绣",
            itemCunDangStr = "5",
            _skillEffect = {
                {
                    description = "施法有概率触发高级魔力精通效果，提高造成的所有魔法伤害3.5%，持续10秒，cd60秒",
                    attr_type = CONST_EVENT.skillEffect,
                    attr = function(evtData)
                        if hskill.checkAndEnterCD(evtData.triggerUnit, "魔力刺绣", 60) then
                            hbuff.update(
                                10,
                                evtData.triggerUnit,
                                "魔力刺绣buff",
                                true,
                                function()
                                    hevent.register(
                                        evtData.triggerUnit,
                                        CONST_EVENT.damagingCustomSource,
                                        "高级魔力刺绣额外增伤",
                                        function(newData)
                                            if newData.damageType == DAMAGE_TYPE.MOFA then
                                                newData.damage = newData.damage * 1.035
                                            end
                                        end
                                    )
                                end,
                                function()
                                    hevent.unregister(
                                        evtData.triggerUnit,
                                        CONST_EVENT.damagingCustomSource,
                                        "高级魔力刺绣额外增伤"
                                    )
                                end,
                                hslk.n2v("高级魔力刺绣", "Art"),
                                "高级魔力刺绣:所有魔法伤害3.5%",
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
            },
            zhuangbeiTypes = { "披风" }
        },
        {
            name = "高级刀锋刺绣",
            itemCunDangStr = "6",
            _skillEffect = {
                {
                    description = "攻击有概率触发高级刀锋刺绣效果，提高造成的所有物理伤害3.5%，持续10秒，cd60秒",
                    attr_type = CONST_EVENT.attack,
                    attr = function(evtData)
                        if hskill.checkAndEnterCD(evtData.triggerUnit, "刀锋刺绣", 60) then
                            hbuff.update(
                                10,
                                evtData.triggerUnit,
                                "刀锋刺绣buff",
                                true,
                                function()
                                    hevent.register(
                                        evtData.triggerUnit,
                                        CONST_EVENT.damagingCustomSource,
                                        "高级刀锋刺绣额外增伤",
                                        function(newData)
                                            if newData.damageType == DAMAGE_TYPE.WULI then
                                                newData.damage = newData.damage * 1.035
                                            end
                                        end
                                    )
                                end,
                                function()
                                    hevent.unregister(
                                        evtData.triggerUnit,
                                        CONST_EVENT.damagingCustomSource,
                                        "高级刀锋刺绣额外增伤"
                                    )
                                end,
                                hslk.n2v("高级刀锋刺绣", "Art"),
                                "高级刀锋刺绣:所有物理伤害3.5%",
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
            },
            zhuangbeiTypes = { "披风" }
        },
        {
            name = "高级回春刺绣",
            itemCunDangStr = "7",
            _skillEffect = {
                {
                    description = "被攻击有概率触发高级回春效果，生命恢复提高2.5%，持续10秒，CD60秒",
                    attr_type = CONST_EVENT.beDamage,
                    attr = function(evtData)
                        if
                            hunit.getCurLifePercent(evtData.triggerUnit) <= 50 and
                            hskill.checkAndEnterCD(evtData.triggerUnit, "回春刺绣", 60)
                        then
                            local lifeback = tostring(hunit.getMaxLife(evtData.triggerUnit) * 0.025 or 1)
                            hbuff.update(
                                10,
                                evtData.triggerUnit,
                                "回春刺绣buff",
                                true,
                                function()
                                    hattribute.set(evtData.triggerUnit, 0, _attr({ life_back = "+" .. lifeback }))
                                end,
                                function()
                                    hattribute.set(evtData.triggerUnit, 0, _attr({ life_back = "-" .. lifeback }))
                                end,
                                hslk.n2v("高级回春刺绣", "Art"),
                                "高级回春刺绣：生命恢复提高" .. lifeback,
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
            },
            zhuangbeiTypes = { "披风" }
        }
    }
    hshop.addNormalItem(
        "军需处长谭恩",
        "魔力针线",
        { { type = HSHOP_COST_TYPE.gold, value = 1200 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 4, shengwangname = "王城" } }
    )

    hshop.addNormalItem("裁缝大师马斯特", "魔力针线", { { type = HSHOP_COST_TYPE.gold, value = 2000 } }, {})

    hshop.addItem(
        "裁缝大师马斯特",
        "刺绣剥离",
        "ReplaceableTextures\\caifeng\\CAIFENG.blp",
        { { type = HSHOP_COST_TYPE.gold, value = 5000 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 2, shengwangname = "王城" } },
        "去除物品栏第一格装备的刺绣，概不退款，误操作也不退",
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
            if dynamicItem.cixiu == nil then
                echo("第一格物品没有刺绣", whichPlayer)
                return
            end
            dynamicItem.cixiu = nil
            dynamicItem.updateDescription()
            echo("成功去除刺绣", whichPlayer)
        end
    )
    hcaifeng.init(config, cixiuConfig)

    hshop.addNormalItem(
        "守备官斯通哈特",
        "先驱法师头盔",
        { { type = HSHOP_COST_TYPE.yongqihuizhang, value = 100 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "先驱法师护手",
        { { type = HSHOP_COST_TYPE.yongqihuizhang, value = 100 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "先驱法师腿甲",
        { { type = HSHOP_COST_TYPE.yongqihuizhang, value = 100 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "先驱法师胸甲",
        { { type = HSHOP_COST_TYPE.yongqihuizhang, value = 100 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "远古先驱法师头盔",
        { { type = HSHOP_COST_TYPE.huoyanhuizhang, value = 60 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "远古先驱法师护手",
        { { type = HSHOP_COST_TYPE.huoyanhuizhang, value = 60 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "远古先驱法师腿甲",
        { { type = HSHOP_COST_TYPE.huoyanhuizhang, value = 60 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "远古先驱法师胸甲",
        { { type = HSHOP_COST_TYPE.huoyanhuizhang, value = 60 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
end
