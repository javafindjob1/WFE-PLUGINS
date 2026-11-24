function initZhiPi()
    local config = {
        {
            reqLevel = 0,
            req = {
                { name = "轻皮", count = 5 }
            },
            successRate = 10000,
            output = {
                name = "耐用的靴子",
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
                { name = "轻皮", count = 20 }
            },
            successRate = 10000,
            output = {
                name = "轻盈护甲片",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2,
            zhizuoshijian = 5
        },
        {
            reqLevel = 0,
            req = {
                { name = "中皮", count = 5 },
                { name = "魔物精魄", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "聚灵护甲片",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 4,
            zhizuoshijian = 10
        },
        {
            reqLevel = 0,
            req = {
                { name = "中皮", count = 10 },
                { name = "魔法水晶", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "尖刺护甲片",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 5,
            zhizuoshijian = 10
        },
        {
            reqLevel = 0,
            req = {
                { name = "中皮", count = 10 },
                { name = "魔法水晶", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "闪灵护甲片",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 5,
            zhizuoshijian = 10
        },
        {
            reqLevel = 1,
            req = {
                { name = "战败勇士的头盔", count = 1 },
                { name = "血色军战盔", count = 1 },
                { name = "蓝影头盔", count = 1 },
                { name = "中皮", count = 5 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "猎杀者皮帽",
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
                { name = "猎杀者皮帽", count = 1 },
                { name = "光明核心碎片", count = 1 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "猎杀者皮帽",
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
                { name = "中皮", count = 5 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "猎杀者软甲",
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
                { name = "猎杀者软甲", count = 1 },
                { name = "光明核心碎片", count = 1 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "猎杀者软甲",
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
                { name = "中皮", count = 5 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "猎杀者手套",
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
                { name = "猎杀者手套", count = 1 },
                { name = "光明核心碎片", count = 1 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "猎杀者手套",
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
                { name = "中皮", count = 5 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "猎杀者皮靴",
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
                { name = "猎杀者皮靴", count = 1 },
                { name = "光明核心碎片", count = 1 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "猎杀者皮靴",
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
                { name = "中皮", count = 2 }
            },
            successRate = 10000,
            zhizuoshijian = 5,
            output = {
                name = "英勇之鼓",
                count = 1
            },
            zhizuoExp = 4
        },
        {
            reqLevel = 2,
            req = {
                { name = "重皮", count = 2 }
            },
            successRate = 10000,
            zhizuoshijian = 5,
            output = {
                name = "高级英勇之鼓",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 2,
            req = {
                { name = "重皮", count = 20 }
            },
            successRate = 10000,
            output = {
                name = "高级轻盈护甲片",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2,
            zhizuoshijian = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "重皮", count = 5 },
                { name = "人马图腾", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "高级聚灵护甲片",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 4,
            zhizuoshijian = 10
        },
        {
            reqLevel = 2,
            req = {
                { name = "重皮", count = 10 },
                { name = "人马图腾", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "高级尖刺护甲片",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 5,
            zhizuoshijian = 10
        },
        {
            reqLevel = 2,
            req = {
                { name = "重皮", count = 10 },
                { name = "人马图腾", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "高级闪灵护甲片",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 5,
            zhizuoshijian = 10
        },
        {
            reqLevel = 2,
            req = {
                { name = "浸毒箭袋", count = 1 },
                { name = "射手箭袋", count = 1 },
                { name = "人马图腾", count = 2 },
                { name = "魔法水晶", count = 1 },
                { name = "重皮", count = 10 }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "精英射手箭袋",
                itemLevel = 53,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "冠军斗士战盔", count = 1 },
                { name = "先驱斥候头盔", count = 1 },
                { name = "中皮", count = 20 },
                { name = "重皮", count = 10 },
                { name = "火焰精华", count = 4 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "追猎者皮帽",
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
                { name = "先驱斥候护手", count = 1 },
                { name = "中皮", count = 20 },
                { name = "重皮", count = 10 },
                { name = "火焰精华", count = 4 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "追猎者手套",
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
                { name = "先驱斥候腿甲", count = 1 },
                { name = "中皮", count = 20 },
                { name = "重皮", count = 10 },
                { name = "火焰精华", count = 4 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "追猎者皮靴",
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
                { name = "先驱斥候胸甲", count = 1 },
                { name = "中皮", count = 20 },
                { name = "重皮", count = 10 },
                { name = "火焰精华", count = 4 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "追猎者软甲",
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
                { name = "追猎者皮帽", count = 1 },
                { name = "远古先驱斥候头盔", count = 1 },
                { name = "中皮", count = 50 },
                { name = "重皮", count = 20 },
                { name = "火焰精华", count = 12 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "追猎者皮帽",
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
                { name = "追猎者手套", count = 1 },
                { name = "远古先驱斥候护手", count = 1 },
                { name = "中皮", count = 50 },
                { name = "重皮", count = 20 },
                { name = "火焰精华", count = 12 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "追猎者手套",
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
                { name = "追猎者皮靴", count = 1 },
                { name = "远古先驱斥候腿甲", count = 1 },
                { name = "中皮", count = 50 },
                { name = "重皮", count = 20 },
                { name = "火焰精华", count = 12 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "追猎者皮靴",
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
                { name = "追猎者软甲", count = 1 },
                { name = "远古先驱斥候胸甲", count = 1 },
                { name = "中皮", count = 50 },
                { name = "重皮", count = 20 },
                { name = "火焰精华", count = 12 }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "追猎者软甲",
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
                { name = "精英射手箭袋", count = 1 },
                { name = "成年黑龙的肌腱", count = 1 },
                { name = "重皮", count = 20 }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "龙筋箭袋",
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
                { name = "强化套马索", count = 1 },
                { name = "成年黑龙的肌腱", count = 1 },
                { name = "重皮", count = 20 }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "龙筋锁链",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "厚皮", count = 10 },
                { name = "结缔皮", count = 3 },
                { name = "守护者的宝石", count = 3 }
            },
            successRate = 10000,
            output = {
                name = "厚重结缔皮护甲片",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 10,
            zhizuoshijian = 10
        },
        {
            reqLevel = 3,
            req = {
                { name = "厚皮", count = 10 },
                { name = "结缔皮", count = 3 },
                { name = "守护者的宝石", count = 2 }
            },
            successRate = 10000,
            output = {
                name = "专家级轻盈护甲片",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2,
            zhizuoshijian = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "厚皮", count = 10 },
                { name = "结缔皮", count = 3 },
                { name = "守护者的宝石", count = 2 }
            },
            successRate = 10000,
            output = {
                name = "专家级聚灵护甲片",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 4,
            zhizuoshijian = 10
        },
        {
            reqLevel = 3,
            req = {
                { name = "厚皮", count = 10 },
                { name = "结缔皮", count = 3 },
                { name = "守护者的宝石", count = 2 }
            },
            successRate = 10000,
            output = {
                name = "专家级尖刺护甲片",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 5,
            zhizuoshijian = 10
        },
        {
            reqLevel = 3,
            req = {
                { name = "厚皮", count = 10 },
                { name = "结缔皮", count = 3 },
                { name = "守护者的宝石", count = 2 }
            },
            successRate = 10000,
            output = {
                name = "专家级闪灵护甲片",
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
                {
                    name = "结缔皮",
                    count = 10
                },
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
                name = "暗影猎手护手",
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
                {
                    name = "结缔皮",
                    count = 10
                },
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
                name = "暗影猎手战靴",
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
                {
                    name = "结缔皮",
                    count = 10
                },
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
                name = "暗影猎手战盔",
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
                {
                    name = "结缔皮",
                    count = 10
                },
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
                name = "暗影猎手战甲",
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
                    name = "暗影猎手护手",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "先锋远征军护手",
                    count = 1
                },
                {
                    name = "结缔皮",
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
                name = "暗影猎手护手",
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
                    name = "暗影猎手战靴",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "先锋远征军战靴",
                    count = 1
                },
                {
                    name = "结缔皮",
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
                name = "暗影猎手战靴",
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
                    name = "暗影猎手战盔",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "先锋远征军战盔",
                    count = 1
                },
                {
                    name = "结缔皮",
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
                name = "暗影猎手战盔",
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
                    name = "暗影猎手战甲",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "先锋远征军战甲",
                    count = 1
                },
                {
                    name = "结缔皮",
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
                name = "暗影猎手战甲",
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
                { name = "结缔皮", count = 2 }
            },
            successRate = 10000,
            zhizuoshijian = 5,
            output = {
                name = "无畏英勇之鼓",
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
                {
                    name = "结缔皮",
                    count = 40
                },
                {
                    name = "翠绿魔珠",
                    count = 5
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "晨曦游侠手套",
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
                {
                    name = "结缔皮",
                    count = 40
                },
                {
                    name = "翠绿魔珠",
                    count = 5
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "晨曦游侠靴",
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
                {
                    name = "结缔皮",
                    count = 40
                },
                {
                    name = "黑暗精华",
                    count = 5
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "晨曦游侠头饰",
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
                    name = "晨曦游侠手套",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "史诗黑暗意志手套",
                    count = 1
                },
                {
                    name = "结缔皮",
                    count = 60
                },
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
                name = "晨曦游侠手套",
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
                    name = "晨曦游侠靴",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "史诗黑暗意志长靴",
                    count = 1
                },
                {
                    name = "结缔皮",
                    count = 60
                },
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
                name = "晨曦游侠靴",
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
                    name = "晨曦游侠头饰",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "史诗黑暗意志头盔",
                    count = 1
                },
                {
                    name = "结缔皮",
                    count = 60
                },
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
                name = "晨曦游侠头饰",
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
                {
                    name = "结缔皮",
                    count = 40
                },
                {
                    name = "黑暗精华",
                    count = 5
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "晨曦游侠之衣",
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
                    name = "晨曦游侠之衣",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "史诗黑暗意志胸甲",
                    count = 1
                },
                {
                    name = "结缔皮",
                    count = 60
                },
                {
                    name = "欺诈者之眼",
                    count = 3
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "晨曦游侠之衣",
                itemLevel = 73,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
    }
    local hujiapianConfig = {
        {
            name = "轻盈护甲片",
            itemCunDangStr = "1",
            attr = _attr({ zhushuxing = "+10" }),
            zhuangbeiTypes = { "鞋子" }
        },
        {
            name = "聚灵护甲片",
            itemCunDangStr = "2",
            attr = _attr({ energy_back = "+3" }),
            zhuangbeiTypes = { "衣服" }
        },
        {
            name = "尖刺护甲片",
            itemCunDangStr = "3",
            attr = _attr({ wu_bao = "+0.3" }),
            zhuangbeiTypes = { "手套" }
        },
        {
            name = "闪灵护甲片",
            itemCunDangStr = "4",
            attr = _attr({ fa_bao = "+0.3" }),
            zhuangbeiTypes = { "手套" }
        },
        {
            name = "高级轻盈护甲片",
            itemCunDangStr = "5",
            attr = _attr({ zhushuxing = "+30" }),
            zhuangbeiTypes = { "鞋子" }
        },
        {
            name = "高级聚灵护甲片",
            itemCunDangStr = "6",
            attr = _attr({ energy_back = "+5" }),
            zhuangbeiTypes = { "衣服" }
        },
        {
            name = "高级尖刺护甲片",
            itemCunDangStr = "7",
            attr = _attr({ wu_bao = "+0.5", wu_chuantou = "+2" }),
            zhuangbeiTypes = { "手套" }
        },
        {
            name = "高级闪灵护甲片",
            itemCunDangStr = "8",
            attr = _attr({ fa_bao = "+0.5", fa_chuantou = "+2" }),
            zhuangbeiTypes = { "手套" }
        },
        {
            name = "厚重结缔皮护甲片",
            itemCunDangStr = "9",
            attr = _attr({ life = "+300" }),
            zhuangbeiTypes = { "头盔" }
        },
        {
            name = "专家级轻盈护甲片",
            itemCunDangStr = "a",
            attr = _attr({ zhushuxing = "+45" }),
            zhuangbeiTypes = { "鞋子" }
        },
        {
            name = "专家级聚灵护甲片",
            itemCunDangStr = "b",
            attr = _attr({ energy_back = "+7" }),
            zhuangbeiTypes = { "衣服" }
        },
        {
            name = "专家级尖刺护甲片",
            itemCunDangStr = "c",
            attr = _attr({ wu_bao = "+0.6", wu_chuantou = "+3" }),
            zhuangbeiTypes = { "手套" }
        },
        {
            name = "专家级闪灵护甲片",
            itemCunDangStr = "d",
            attr = _attr({ fa_bao = "+0.6", fa_chuantou = "+3" }),
            zhuangbeiTypes = { "手套" }
        },
    }

    hshop.addItem(
        "制皮大师莱瑟",
        "护甲片剥离",
        "ReplaceableTextures\\zhipi\\BTNWarcraft3 Ico.blp",
        { { type = HSHOP_COST_TYPE.gold, value = 5000 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 2, shengwangname = "王城" } },
        "去除物品栏第一格装备的护甲片，概不退款，误操作也不退",
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
            if dynamicItem.hujiapian == nil then
                echo("第一格物品没有附魔", whichPlayer)
                return
            end
            dynamicItem.hujiapian = nil
            dynamicItem.updateDescription()
            echo("成功去除护甲片", whichPlayer)
        end
    )

    hshop.addNormalItem(
        "守备官斯通哈特",
        "先驱斥候头盔",
        { { type = HSHOP_COST_TYPE.yongqihuizhang, value = 100 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "先驱斥候护手",
        { { type = HSHOP_COST_TYPE.yongqihuizhang, value = 100 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "先驱斥候腿甲",
        { { type = HSHOP_COST_TYPE.yongqihuizhang, value = 100 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "先驱斥候胸甲",
        { { type = HSHOP_COST_TYPE.yongqihuizhang, value = 100 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "远古先驱斥候头盔",
        { { type = HSHOP_COST_TYPE.huoyanhuizhang, value = 60 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "远古先驱斥候护手",
        { { type = HSHOP_COST_TYPE.huoyanhuizhang, value = 60 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "远古先驱斥候腿甲",
        { { type = HSHOP_COST_TYPE.huoyanhuizhang, value = 60 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "远古先驱斥候胸甲",
        { { type = HSHOP_COST_TYPE.huoyanhuizhang, value = 60 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )
    hzhipi.init(config, hujiapianConfig)
end
