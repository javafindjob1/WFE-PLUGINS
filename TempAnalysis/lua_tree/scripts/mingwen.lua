function initMingWen()
    local config = {
        {
            reqLevel = 0,
            req = {
                { name = "银叶草", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "天青墨水",
                itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 1,
            req = {
                { name = "天青墨水", count = 1 },
                { name = "附魔羊皮纸", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "基础铭文",
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 1,
            req = {
                { name = "天青墨水", count = 1 },
                { name = "附魔羊皮纸", count = 1 },
                { name = "魔法水晶", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "初级铭文",
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 2,
            req = {
                { name = "火焰草", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "烈焰墨水",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 2,
            req = {
                { name = "勇气圣契", count = 1 },
                { name = "光明圣契", count = 1 },
                { name = "致命圣契", count = 1 },
                { name = "人马图腾", count = 2 },
                { name = "魔法水晶", count = 1 },
                { name = "烈焰墨水", count = 1 }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "无上勇气圣契",
                itemLevel = 53,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 20
        },
        {
            reqLevel = 2,
            req = {
                { name = "浸水的魔法书", count = 1 },
                { name = "光明魔法书", count = 1 },
                { name = "黑暗魔法书", count = 1 },
                { name = "人马图腾", count = 2 },
                { name = "魔法水晶", count = 1 },
                { name = "烈焰墨水", count = 1 }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "辉煌魔法书",
                itemLevel = 53,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 20
        },
        {
            reqLevel = 2,
            req = {
                { name = "烈焰墨水", count = 2 },
                { name = "附魔羊皮纸", count = 1 },
                { name = "人马图腾", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "灼热铭文",
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 2,
            req = {
                { name = "烈焰墨水", count = 5 },
                { name = "附魔羊皮纸", count = 1 },
                { name = "火焰精华", count = 10 },
                { name = "冠军之证", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "火焰铭文",
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 2,
            req = {
                { name = "辉煌魔法书", count = 1 },
                { name = "上古角石魔典", count = 1 },
                { name = "火焰符文魔典", count = 1 },
                { name = "黑龙精华", count = 1 },
                { name = "火焰铭文", count = 1 }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "上古火焰魔典",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 20
        },
        {
            reqLevel = 2,
            req = {
                { name = "无上勇气圣契", count = 1 },
                { name = "黑龙精华", count = 1 },
                { name = "火焰铭文", count = 1 }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "上古勇气圣契",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 20
        },
        {
            reqLevel = 3,
            req = {
                { name = "汲血草", count = 10 },
                { name = "附魔羊皮纸", count = 1 },
                { name = "守护者的宝石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "战争铭文",
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "绽放之血", count = 1 },
                { name = "附魔羊皮纸", count = 5 }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "远征之一",
                    count = 1,
                    weight = 1
                },
                {
                    name = "远征之二",
                    count = 1,
                    weight = 1
                },
                {
                    name = "远征之三",
                    count = 1,
                    weight = 1
                },
                {
                    name = "远征之四",
                    count = 1,
                    weight = 1
                },
                {
                    name = "远征之五",
                    count = 1,
                    weight = 1
                },
                {
                    name = "远征之六",
                    count = 1,
                    weight = 1
                },
                {
                    name = "远征之七",
                    count = 1,
                    weight = 1
                },
                {
                    name = "远征之八",
                    count = 1,
                    weight = 1
                },
                {
                    name = "疯狂之一",
                    count = 1,
                    weight = 1
                },
                {
                    name = "疯狂之二",
                    count = 1,
                    weight = 1
                },
                {
                    name = "疯狂之三",
                    count = 1,
                    weight = 1
                },
                {
                    name = "疯狂之四",
                    count = 1,
                    weight = 1
                },
                {
                    name = "疯狂之五",
                    count = 1,
                    weight = 1
                },
                {
                    name = "疯狂之六",
                    count = 1,
                    weight = 1
                },
                {
                    name = "疯狂之七",
                    count = 1,
                    weight = 1
                },
                {
                    name = "疯狂之八",
                    count = 1,
                    weight = 1
                },
                {
                    name = "复仇之一",
                    count = 1,
                    weight = 1
                },
                {
                    name = "复仇之二",
                    count = 1,
                    weight = 1
                },
                {
                    name = "复仇之三",
                    count = 1,
                    weight = 1
                },
                {
                    name = "复仇之四",
                    count = 1,
                    weight = 1
                },
                {
                    name = "复仇之五",
                    count = 1,
                    weight = 1
                },
                {
                    name = "复仇之六",
                    count = 1,
                    weight = 1
                },
                {
                    name = "复仇之七",
                    count = 1,
                    weight = 1
                },
                {
                    name = "复仇之八",
                    count = 1,
                    weight = 1
                },
                {
                    name = "怒火之一",
                    count = 1,
                    weight = 1
                },
                {
                    name = "怒火之二",
                    count = 1,
                    weight = 1
                },
                {
                    name = "怒火之三",
                    count = 1,
                    weight = 1
                },
                {
                    name = "怒火之四",
                    count = 1,
                    weight = 1
                },
                {
                    name = "怒火之五",
                    count = 1,
                    weight = 1
                },
                {
                    name = "怒火之六",
                    count = 1,
                    weight = 1
                },
                {
                    name = "怒火之七",
                    count = 1,
                    weight = 1
                },
                {
                    name = "怒火之八",
                    count = 1,
                    weight = 1
                },
                {
                    name = "伟大之一",
                    count = 1,
                    weight = 1
                },
                {
                    name = "伟大之二",
                    count = 1,
                    weight = 1
                },
                {
                    name = "伟大之三",
                    count = 1,
                    weight = 1
                },
                {
                    name = "伟大之四",
                    count = 1,
                    weight = 1
                },
                {
                    name = "伟大之五",
                    count = 1,
                    weight = 1
                },
                {
                    name = "伟大之六",
                    count = 1,
                    weight = 1
                },
                {
                    name = "伟大之七",
                    count = 1,
                    weight = 1
                },
                {
                    name = "伟大之八",
                    count = 1,
                    weight = 1
                },
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "绽放之血", count = 1 },
                { name = "附魔羊皮纸", count = 10 },
                { name = "守护者的宝石", count = 1 }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "疯狂之一",
                    count = 1,
                    weight = 1
                },
                {
                    name = "疯狂之二",
                    count = 1,
                    weight = 1
                },
                {
                    name = "疯狂之三",
                    count = 1,
                    weight = 1
                },
                {
                    name = "疯狂之四",
                    count = 1,
                    weight = 1
                },
                {
                    name = "疯狂之五",
                    count = 1,
                    weight = 1
                },
                {
                    name = "疯狂之六",
                    count = 1,
                    weight = 1
                },
                {
                    name = "疯狂之七",
                    count = 1,
                    weight = 1
                },
                {
                    name = "疯狂之八",
                    count = 1,
                    weight = 1
                },
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "绽放之血", count = 1 },
                { name = "附魔羊皮纸", count = 10 },
                { name = "守护者的宝石", count = 1 }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "远征之一",
                    count = 1,
                    weight = 1
                },
                {
                    name = "远征之二",
                    count = 1,
                    weight = 1
                },
                {
                    name = "远征之三",
                    count = 1,
                    weight = 1
                },
                {
                    name = "远征之四",
                    count = 1,
                    weight = 1
                },
                {
                    name = "远征之五",
                    count = 1,
                    weight = 1
                },
                {
                    name = "远征之六",
                    count = 1,
                    weight = 1
                },
                {
                    name = "远征之七",
                    count = 1,
                    weight = 1
                },
                {
                    name = "远征之八",
                    count = 1,
                    weight = 1
                },
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "绽放之血", count = 1 },
                { name = "附魔羊皮纸", count = 10 },
                { name = "守护者的宝石", count = 1 }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "怒火之一",
                    count = 1,
                    weight = 1
                },
                {
                    name = "怒火之二",
                    count = 1,
                    weight = 1
                },
                {
                    name = "怒火之三",
                    count = 1,
                    weight = 1
                },
                {
                    name = "怒火之四",
                    count = 1,
                    weight = 1
                },
                {
                    name = "怒火之五",
                    count = 1,
                    weight = 1
                },
                {
                    name = "怒火之六",
                    count = 1,
                    weight = 1
                },
                {
                    name = "怒火之七",
                    count = 1,
                    weight = 1
                },
                {
                    name = "怒火之八",
                    count = 1,
                    weight = 1
                },
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "绽放之血", count = 1 },
                { name = "附魔羊皮纸", count = 10 },
                { name = "守护者的宝石", count = 1 }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "复仇之一",
                    count = 1,
                    weight = 1
                },
                {
                    name = "复仇之二",
                    count = 1,
                    weight = 1
                },
                {
                    name = "复仇之三",
                    count = 1,
                    weight = 1
                },
                {
                    name = "复仇之四",
                    count = 1,
                    weight = 1
                },
                {
                    name = "复仇之五",
                    count = 1,
                    weight = 1
                },
                {
                    name = "复仇之六",
                    count = 1,
                    weight = 1
                },
                {
                    name = "复仇之七",
                    count = 1,
                    weight = 1
                },
                {
                    name = "复仇之八",
                    count = 1,
                    weight = 1
                },
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "绽放之血", count = 1 },
                { name = "附魔羊皮纸", count = 10 },
                { name = "守护者的宝石", count = 1 }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "伟大之一",
                    count = 1,
                    weight = 1
                },
                {
                    name = "伟大之二",
                    count = 1,
                    weight = 1
                },
                {
                    name = "伟大之三",
                    count = 1,
                    weight = 1
                },
                {
                    name = "伟大之四",
                    count = 1,
                    weight = 1
                },
                {
                    name = "伟大之五",
                    count = 1,
                    weight = 1
                },
                {
                    name = "伟大之六",
                    count = 1,
                    weight = 1
                },
                {
                    name = "伟大之七",
                    count = 1,
                    weight = 1
                },
                {
                    name = "伟大之八",
                    count = 1,
                    weight = 1
                },
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "远征之一", count = 1 },
                { name = "远征之二", count = 1 },
                { name = "远征之三", count = 1 },
                { name = "远征之四", count = 1 },
                { name = "远征之五", count = 1 },
                { name = "远征之六", count = 1 },
                { name = "远征之七", count = 1 },
                { name = "远征之八", count = 1 },
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：远征",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "复仇之一", count = 1 },
                { name = "复仇之二", count = 1 },
                { name = "复仇之三", count = 1 },
                { name = "复仇之四", count = 1 },
                { name = "复仇之五", count = 1 },
                { name = "复仇之六", count = 1 },
                { name = "复仇之七", count = 1 },
                { name = "复仇之八", count = 1 },
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：复仇",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "怒火之一", count = 1 },
                { name = "怒火之二", count = 1 },
                { name = "怒火之三", count = 1 },
                { name = "怒火之四", count = 1 },
                { name = "怒火之五", count = 1 },
                { name = "怒火之六", count = 1 },
                { name = "怒火之七", count = 1 },
                { name = "怒火之八", count = 1 },
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：怒火",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "伟大之一", count = 1 },
                { name = "伟大之二", count = 1 },
                { name = "伟大之三", count = 1 },
                { name = "伟大之四", count = 1 },
                { name = "伟大之五", count = 1 },
                { name = "伟大之六", count = 1 },
                { name = "伟大之七", count = 1 },
                { name = "伟大之八", count = 1 },
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：伟大",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "疯狂之一", count = 1 },
                { name = "疯狂之二", count = 1 },
                { name = "疯狂之三", count = 1 },
                { name = "疯狂之四", count = 1 },
                { name = "疯狂之五", count = 1 },
                { name = "疯狂之六", count = 1 },
                { name = "疯狂之七", count = 1 },
                { name = "疯狂之八", count = 1 },
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：疯狂",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "暗月卡片：远征",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.PUTONG,
                    count = 1,
                },
                {
                    name = "暗月精华",
                    count = 50
                }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：远征",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.YINGXIONG,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "暗月卡片：伟大",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.PUTONG,
                    count = 1,
                },
                {
                    name = "暗月精华",
                    count = 50
                }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：伟大",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.YINGXIONG,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "暗月卡片：疯狂",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.PUTONG,
                    count = 1,
                },
                {
                    name = "暗月精华",
                    count = 50
                }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：疯狂",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.YINGXIONG,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "暗月卡片：复仇",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.PUTONG,
                    count = 1,
                },
                {
                    name = "暗月精华",
                    count = 50
                }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：复仇",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.YINGXIONG,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "暗月卡片：怒火",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.PUTONG,
                    count = 1,
                },
                {
                    name = "暗月精华",
                    count = 50
                }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：怒火",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.YINGXIONG,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "暗月卡片：远征",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.YINGXIONG,
                    count = 1,
                },
                {
                    name = "暗月精华",
                    count = 100
                }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：远征",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "暗月卡片：伟大",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.YINGXIONG,
                    count = 1,
                },
                {
                    name = "暗月精华",
                    count = 100
                }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：伟大",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "暗月卡片：疯狂",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.YINGXIONG,
                    count = 1,
                },
                {
                    name = "暗月精华",
                    count = 100
                }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：疯狂",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "暗月卡片：复仇",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.YINGXIONG,
                    count = 1,
                },
                {
                    name = "暗月精华",
                    count = 100
                }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：复仇",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "暗月卡片：怒火",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.YINGXIONG,
                    count = 1,
                },
                {
                    name = "暗月精华",
                    count = 100
                }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：怒火",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },

        {
            reqLevel = 3,
            req = {
                {
                    name = "暗月卡片：远征",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                },
                {
                    name = "星界螺旋",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 71,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                },
                {
                    name = "翠绿魔珠",
                    count = 5
                }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：远征",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 71,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "暗月卡片：伟大",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                },
                {
                    name = "虚空之星",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 71,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                },
                {
                    name = "翠绿魔珠",
                    count = 5
                }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：伟大",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 71,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "暗月卡片：疯狂",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                },
                {
                    name = "虚空之星",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 71,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                },
                {
                    name = "翠绿魔珠",
                    count = 5
                }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：疯狂",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 71,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "暗月卡片：复仇",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                },
                {
                    name = "奥之爪",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 71,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                },
                {
                    name = "翠绿魔珠",
                    count = 5
                }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：复仇",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 71,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                }
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "暗月卡片：怒火",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 70,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                },
                {
                    name = "星界螺旋",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 71,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                },
                {
                    name = "翠绿魔珠",
                    count = 5
                }
            },
            successRate = 10000,
            outputPool = {
                {
                    name = "暗月卡片：怒火",
                    itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                    itemLevel = 71,
                    nandu = FUBEN_NANDU.SHISHI,
                    count = 1,
                }
            },
            zhizuoExp = 5
        }
    }

    local mingwenConfig = {
        {
            name = "节能火球",
            art = "ReplaceableTextures\\PASBTNSpell_Fire_FireBolt02.blp",
            description = "降低火球术魔法消耗为1点。",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 1,
            cunDangEndIndex = 2,
            zhiye_cundang_str = "huofa",
            isEquipped = false,
            req = {
                { name = "基础铭文", count = 1 }
            }
        },
        {
            name = "连珠火球",
            art = "ReplaceableTextures\\PASBTNSpell_Fire_FireBolt02.blp",
            description = "火球术造成伤害时有20%的概率会额外发射一枚,不会重复触发.",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 3,
            cunDangEndIndex = 4,
            zhiye_cundang_str = "huofa",
            isEquipped = false,
            req = {
                { name = "初级铭文", count = 3 }
            }
        },
        {
            name = "致死冲锋",
            art = "ReplaceableTextures\\BTN_KRDS_CF.blp",
            description = "冲锋对目标造成伤害的同时附带一次致死打击。",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 5,
            cunDangEndIndex = 6,
            zhiye_cundang_str = "wuqizhan",
            isEquipped = false,
            req = {
                { name = "基础铭文", count = 1 }
            }
        },
        {
            name = "雷霆统治",
            art = "ReplaceableTextures\\BTN_ZS_JN14.blp",
            description = "雷霆一击对所有受到影响的敌人施加一次压制",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 7,
            cunDangEndIndex = 8,
            zhiye_cundang_str = "wuqizhan",
            isEquipped = false,
            req = {
                { name = "初级铭文", count = 3 }
            }
        },
        {
            name = "节能英勇打击",
            art = "ReplaceableTextures\\BTN_ZS_Q1.blp",
            description = "英勇打击消耗的怒气值降低1点",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 9,
            cunDangEndIndex = 10,
            zhiye_cundang_str = "kuangbaozhan",
            isEquipped = false,
            req = {
                { name = "基础铭文", count = 1 }
            }
        },
        {
            name = "狂暴怒击",
            art = "ReplaceableTextures\\MoreButtons\\NUJI\\BTNNUJI.blp",
            description = "怒击的暴击概率提高10%，伤害提高20%",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 11,
            cunDangEndIndex = 12,
            zhiye_cundang_str = "kuangbaozhan",
            isEquipped = false,
            req = {
                { name = "初级铭文", count = 3 }
            }
        },
        {
            name = "吸血药膏",
            art = "ReplaceableTextures\\daozei\\zhimingyaogao.blp",
            description = "盗贼在武器上会同时涂抹吸血药膏，攻击有10%的概率恢复80点生命值",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 13,
            cunDangEndIndex = 14,
            zhiye_cundang_str = "zhandouzei",
            isEquipped = false,
            req = {
                { name = "基础铭文", count = 1 }
            }
        },
        {
            name = "多重影袭",
            art = "ReplaceableTextures\\daozei\\yingxi.blp",
            description = "影袭有10%的概率额外触发一次。",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 15,
            cunDangEndIndex = 16,
            zhiye_cundang_str = "zhandouzei",
            isEquipped = false,
            req = {
                { name = "初级铭文", count = 3 }
            }
        },
        {
            name = "执着狂热",
            art = "ReplaceableTextures\\KUANGRE\\PASKUANGRE.blp",
            description = "狂热效果延长2秒",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 17,
            cunDangEndIndex = 18,
            zhiye_cundang_str = "chengjieqi",
            isEquipped = false,
            req = {
                { name = "基础铭文", count = 1 }
            }
        },
        {
            name = "混乱风暴",
            art = "ReplaceableTextures\\SHENSHENGFENGBAO\\PASSHENSHENGFENGBAO.blp",
            description = "神圣风暴会同时造成物理和魔法伤害，但单次伤害值降低到原来的70%",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 19,
            cunDangEndIndex = 20,
            zhiye_cundang_str = "chengjieqi",
            isEquipped = false,
            req = {
                { name = "初级铭文", count = 3 }
            }
        },
        {
            name = "急速献祭",
            art = "ReplaceableTextures\\SHUSHI\\Spell_Fire_Immolation.blp",
            description = "献祭的基础伤害间隔降低10%",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 21,
            cunDangEndIndex = 22,
            zhiye_cundang_str = "huimieshu",
            isEquipped = false,
            req = {
                { name = "基础铭文", count = 1 }
            }
        },
        {
            name = "无尽混沌燃烧",
            art = "ReplaceableTextures\\SHUSHI\\PASHDRS.blp",
            description = "混沌燃烧的触发概率提高一倍至30%",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 23,
            cunDangEndIndex = 24,
            zhiye_cundang_str = "huimieshu",
            isEquipped = false,
            req = {
                { name = "初级铭文", count = 3 }
            }
        },
        {
            name = "精力旺盛",
            art = "ReplaceableTextures\\daozei\\chongdong.blp",
            description = "降低冲动20秒CD",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 25,
            cunDangEndIndex = 26,
            zhiye_cundang_str = "zhandouzei",
            isEquipped = false,
            req = {
                { name = "初级铭文", count = 3 }
            }
        },
        {
            name = "急速冲锋",
            art = "ReplaceableTextures\\BTN_KRDS_CF.blp",
            description = "使得战士能够更加频繁的使用冲锋，降低冲锋的技能冷却6秒。",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 27,
            cunDangEndIndex = 28,
            zhiye_cundang_str = "wuqizhan",
            isEquipped = false,
            req = {
                { name = "基础铭文", count = 1 }
            }
        },
        {
            name = "蝰蛇钉刺",
            art = "ReplaceableTextures\\lieren\\Ability_Hunter_Quickshot.blp",
            description = "毒蛇钉刺造成伤害时会吸取能量并恢复猎人2点能量值",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 29,
            cunDangEndIndex = 30,
            zhiye_cundang_str = "shejilieren",
            isEquipped = false,
            req = {
                { name = "基础铭文", count = 1 }
            }
        },
        {
            name = "强化快速射击",
            art = "ReplaceableTextures\\lieren\\Ability_Hunter_Efficiency.blp",
            description = "快速射击额外射出一只箭矢",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 31,
            cunDangEndIndex = 32,
            zhiye_cundang_str = "shejilieren",
            isEquipped = false,
            req = {
                { name = "初级铭文", count = 3 }
            }
        },
        {
            name = "极速腐蚀术",
            art = hslk.n2v("腐蚀术", "Art"),
            description = "腐蚀术的基础伤害间隔降低5%",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 33,
            cunDangEndIndex = 34,
            zhiye_cundang_str = "tongkushu",
            isEquipped = false,
            req = {
                { name = "基础铭文", count = 1 }
            }
        },
        {
            name = "索命诅咒",
            art = hslk.n2v("痛苦诅咒", "Art"),
            description = "痛苦诅咒的伤害间隔降低0.1秒",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 35,
            cunDangEndIndex = 36,
            zhiye_cundang_str = "tongkushu",
            isEquipped = false,
            req = {
                { name = "初级铭文", count = 3 }
            }
        },
        {
            name = "快速瞄准",
            art = hslk.n2v("瞄准射击", "Art"),
            description = "瞄准射击的冷却时间缩短1秒",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 37,
            cunDangEndIndex = 38,
            zhiye_cundang_str = "shejilieren",
            isEquipped = false,
            req = {
                { name = "灼热铭文", count = 1 }
            }
        },
        {
            name = "奥术弹射",
            art = hslk.n2v("奥术射击", "Art"),
            description = "奥术射击可以弹射500码内额外一个单位",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 39,
            cunDangEndIndex = 40,
            zhiye_cundang_str = "shejilieren",
            isEquipped = false,
            req = {
                { name = "灼热铭文", count = 3 }
            }
        },
        {
            name = "水蛭钉刺",
            art = hslk.n2v("毒蛇钉刺", "Art"),
            description = "毒蛇钉刺造成伤害时会恢复猎人1%生命值",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 41,
            cunDangEndIndex = 42,
            zhiye_cundang_str = "shejilieren",
            isEquipped = false,
            req = {
                { name = "灼热铭文", count = 1 }
            }
        },
        {
            name = "精准怒击",
            art = hslk.n2v("怒击", "Art"),
            description = "怒击可以打断敌人施法",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 43,
            cunDangEndIndex = 44,
            zhiye_cundang_str = "kuangbaozhan",
            isEquipped = false,
            req = {
                { name = "灼热铭文", count = 1 }
            }
        },
        {
            name = "雷霆恢复",
            art = "ReplaceableTextures\\BTN_ZS_JN14.blp",
            description = "雷霆一击会恢复生命值，数值为10%最大生命值",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 45,
            cunDangEndIndex = 46,
            zhiye_cundang_str = "wuqizhan",
            isEquipped = false,
            req = {
                { name = "初级铭文", count = 3 }
            }
        },
        {
            name = "势大力沉",
            art = hslk.n2v("英勇打击", "Art"),
            description = "英勇打击额外造成40%攻击力的伤害，但是怒气消耗增加5点",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 47,
            cunDangEndIndex = 48,
            zhiye_cundang_str = "kuangbaozhan",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 1 }
            }
        },
        {
            name = "屠杀",
            art = hslk.n2v("致死打击", "Art"),
            description = "斩杀会使下一个致死打击的伤害提高30%，致死打击会消耗该效果",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 49,
            cunDangEndIndex = 50,
            zhiye_cundang_str = "wuqizhan",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 1 }
            }
        },
        {
            name = "星辰活力",
            art = hslk.n2v("坠星", "Art"),
            description = "坠星暴击时获得的法力值提高3点",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 51,
            cunDangEndIndex = 52,
            zhiye_cundang_str = "xingchenfashi",
            isEquipped = false,
            req = {
                { name = "基础铭文", count = 1 }
            }
        },
        {
            name = "星火专注",
            art = hslk.n2v("星火术", "Art"),
            description = "星火术会使得下一个星火术的伤害提高2%，最多叠加5次，持续时间为10秒",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 53,
            cunDangEndIndex = 54,
            zhiye_cundang_str = "xingchenfashi",
            isEquipped = false,
            req = {
                { name = "初级铭文", count = 3 }
            }
        },
        {
            name = "圣殿骑士的裁决",
            art = hslk.n2v("神圣裁决", "Art"),
            description = "神圣裁决的伤害类型变为物理",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 55,
            cunDangEndIndex = 56,
            zhiye_cundang_str = "chengjieqi",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 1 }
            }
        },
        {
            name = "陨石余烬",
            art = hslk.n2v("陨石术", "Art"),
            description = "陨石术的后续伤害范围提高100，并且持续时间+6秒",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 57,
            cunDangEndIndex = 58,
            zhiye_cundang_str = "huofa",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 1 }
            }
        },
        {
            name = "高级吸血药膏",
            art = "ReplaceableTextures\\daozei\\zhimingyaogao.blp",
            description = "盗贼在武器上会同时涂抹高级吸血药膏，攻击有10%的概率恢复320点生命值",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 59,
            cunDangEndIndex = 60,
            zhiye_cundang_str = "zhandouzei",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 1 }
            }
        },
        {
            name = "幻影之袭",
            art = "ReplaceableTextures\\daozei\\yingxi.blp",
            description = "影袭有15%的概率额外触发一次。（不与多重影袭叠加）",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 61,
            cunDangEndIndex = 62,
            zhiye_cundang_str = "zhandouzei",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 3 }
            }
        },
        {
            name = "活力复苏",
            art = "ReplaceableTextures\\daozei\\huifuzhimingyun.blp",
            description = "恢复之命运会额外增加每秒3点的能量回复速度",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 1,
            cunDangEndIndex = 2,
            zhiye_cundang_str = "zhandouzei",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 1 }
            }
        },
        {
            name = "技击大师",
            art = "ReplaceableTextures\\BTNAbility_Rogue_MasterOfSubtlety.png.blp",
            description = "盗贼的最大连击点数提高1点",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 3,
            cunDangEndIndex = 4,
            zhiye_cundang_str = "zhandouzei",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 3 }
            }
        },
        {
            name = "精准燃烧",
            art = hslk.n2v("烧尽", "Art"),
            description = "烧尽的魔法消耗降低1点",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 5,
            cunDangEndIndex = 6,
            zhiye_cundang_str = "huimieshu",
            isEquipped = false,
            req = {
                { name = "灼热铭文", count = 1 }
            }
        },
        {
            name = "深渊意志",
            art = hslk.n2v("混乱之箭", "Art"),
            description = "混乱之种的上限加一",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 7,
            cunDangEndIndex = 8,
            zhiye_cundang_str = "huimieshu",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 3 }
            }
        },
        {
            name = "持久生命汲取",
            art = hslk.n2v("生命虹吸", "Art"),
            description = "生命虹吸的持续时间增加5秒",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 9,
            cunDangEndIndex = 10,
            zhiye_cundang_str = "tongkushu",
            isEquipped = false,
            req = {
                { name = "灼热铭文", count = 1 }
            }
        },
        {
            name = "恐怖哀嚎",
            art = hslk.n2v("恐惧", "Art"),
            description = "恐惧失去打断效果，但是可以对范围内的敌人造成主属性200%的范围伤害，冷却时间，释放后冷却时间缩短10秒",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 11,
            cunDangEndIndex = 12,
            zhiye_cundang_str = "tongkushu",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 1 }
            }
        },
        {
            name = "强效命令圣印",
            art = hslk.n2v("圣印", "Art"),
            description = "命令圣印造成的伤害现在会对目标300码范围内的所有敌人造成伤害。",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 13,
            cunDangEndIndex = 14,
            zhiye_cundang_str = "chengjieqi",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 1 }
            }
        },
        {
            name = "理智殉难",
            art = hslk.n2v("圣印", "Art"),
            description = "殉难圣印造成的自我反噬效果降低50%。",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 15,
            cunDangEndIndex = 16,
            zhiye_cundang_str = "chengjieqi",
            isEquipped = false,
            req = {
                { name = "灼热铭文", count = 1 }
            }
        },
        {
            name = "愤怒之剑",
            art = hslk.n2v("公正之剑", "Art"),
            description = "公正之剑可以额外获得一层神圣愤怒，但是其造成的伤害降低15%",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 17,
            cunDangEndIndex = 18,
            zhiye_cundang_str = "chengjieqi",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 3 }
            }
        },
        {
            name = "台风之速",
            art = hslk.n2v("台风", "Art"),
            description = "释放台风会增加星辰法师80点移动速度，持续6秒",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 19,
            cunDangEndIndex = 20,
            zhiye_cundang_str = "xingchenfashi",
            isEquipped = false,
            req = {
                { name = "灼热铭文", count = 1 }
            }
        },
        {
            name = "强化坠星",
            art = hslk.n2v("坠星", "Art"),
            description = "增加坠星10%的伤害。",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 21,
            cunDangEndIndex = 22,
            zhiye_cundang_str = "xingchenfashi",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 1 }
            }
        },
        {
            name = "巨力挥舞",
            art = hslk.n2v("旋风斩", "Art"),
            description = "旋风斩的伤害范围增加50，旋风斩状态下怒击和暴怒的额外伤害判定范围也增加50。",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 23,
            cunDangEndIndex = 24,
            zhiye_cundang_str = "kuangbaozhan",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 1 }
            }
        },
        {
            name = "狂热斩杀",
            art = hslk.n2v("斩杀", "Art"),
            description = "斩杀线从20%提高至35%。",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 25,
            cunDangEndIndex = 26,
            zhiye_cundang_str = "wuqizhan",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 3 }
            }
        },
        {
            name = "极速烈焰风暴",
            art = hslk.n2v("烈焰风暴", "Art"),
            description = "烈焰风暴的冷却时间缩短1秒。",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 27,
            cunDangEndIndex = 28,
            zhiye_cundang_str = "huofa",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 1 }
            }
        },
        {
            name = "灼烧",
            art = hslk.n2v("火球术", "Art"),
            description = "火球术在对生命值低于35%的单位造成伤害会必定暴击，但是伤害会降低50%",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 29,
            cunDangEndIndex = 30,
            zhiye_cundang_str = "huofa",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 3 }
            }
        },
        {
            name = "恶魔之刃精通",
            art = hslk.n2v("恶魔之刃", "Art"),
            description = "你的恶魔之刃效果现在没有cd，但是伤害会降为30%敏捷的混乱物理伤害，同时回复效果为6点恶魔能量。",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 31,
            cunDangEndIndex = 32,
            zhiye_cundang_str = "emolieshou",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 1 }
            }
        },
        {
            name = "恶魔之咬",
            art = hslk.n2v("恶魔之刃", "Art"),
            description = "你的恶魔之刃能量回复效果增加20%",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 33,
            cunDangEndIndex = 34,
            zhiye_cundang_str = "emolieshou",
            isEquipped = false,
            req = {
                { name = "基础铭文", count = 1 }
            }
        },
        {
            name = "裂魂之伤",
            art = hslk.n2v("裂魂", "Art"),
            description = "裂魂持续时间增加2秒",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 35,
            cunDangEndIndex = 36,
            zhiye_cundang_str = "emolieshou",
            isEquipped = false,
            req = {
                { name = "初级铭文", count = 1 }
            }
        },
        {
            name = "第一滴血",
            art = hslk.n2v("投掷利刃", "Art"),
            description = "你的投掷利刃会对第一个目标造成伤害提高100%",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 37,
            cunDangEndIndex = 38,
            zhiye_cundang_str = "emolieshou",
            isEquipped = false,
            req = {
                { name = "初级铭文", count = 3 }
            }
        },
        {
            name = "混沌真理",
            art = hslk.n2v("混沌理论", "Art"),
            description = "混沌理论对混乱打击伤害提升效果增加10%",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 39,
            cunDangEndIndex = 40,
            zhiye_cundang_str = "emolieshou",
            isEquipped = false,
            req = {
                { name = "火焰铭文", count = 3 }
            }
        },
        {
            name = "嗜血冲撞",
            art = hslk.n2v("邪能冲撞", "Art"),
            description = "邪能冲撞会恢复恶魔猎手5%的最大生命值",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 41,
            cunDangEndIndex = 42,
            zhiye_cundang_str = "emolieshou",
            isEquipped = false,
            req = {
                { name = "战争铭文", count = 1 }
            }
        },
        {
            name = "烈焰磨盘",
            art = hslk.n2v("烈焰宝珠", "Art"),
            description = "烈焰宝珠基础移动速度提高至500，并且在释放第一个次级火球术之后移动速度降低为150",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 43,
            cunDangEndIndex = 44,
            zhiye_cundang_str = "huofa",
            isEquipped = false,
            req = {
                { name = "战争铭文", count = 1 }
            }
        },
        {
            name = "剔骨",
            art = hslk.n2v("破击", "Art"),
            description = "破击的伤害提高3%，但是不再有打断效果",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MINOR,
            cunDangStartIndex = 45,
            cunDangEndIndex = 46,
            zhiye_cundang_str = "zhandouzei",
            isEquipped = false,
            req = {
                { name = "战争铭文", count = 1 }
            }
        },
        {
            name = "魔武双修",
            art = hslk.n2v("奥术射击", "Art"),
            description = "奥术射击现在不会占用普攻",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 47,
            cunDangEndIndex = 48,
            zhiye_cundang_str = "shejilieren",
            isEquipped = false,
            req = {
                { name = "战争铭文", count = 2 }
            }
        },
        {
            name = "太阳之王的光芒",
            art = hslk.n2v("太阳之王的祝福", "Art"),
            description = "太阳之王的炎爆现在会受到精通的加成，每15点精通增加1%整体伤害",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 49,
            cunDangEndIndex = 50,
            zhiye_cundang_str = "huofa",
            isEquipped = false,
            req = {
                { name = "战争铭文", count = 3 }
            }
        },
        {
            name = "地狱恶魔的魔典",
            art = hslk.n2v("牺牲魔典", "Art"),
            description = "牺牲魔典的伤害会使得目标受到牺牲魔典的伤害提高10%，最高叠加10，持续时间5秒",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 51,
            cunDangEndIndex = 52,
            zhiye_cundang_str = "huimieshu",
            isEquipped = false,
            req = {
                { name = "战争铭文", count = 2 }
            }
        },
        {
            name = "强化无尽诅咒",
            art = hslk.n2v("无尽诅咒", "Art"),
            description = "无尽诅咒期间痛苦术士的精通伤害加成翻倍",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 53,
            cunDangEndIndex = 54,
            zhiye_cundang_str = "tongkushu",
            isEquipped = false,
            req = {
                { name = "战争铭文", count = 2 }
            }
        },
        {
            name = "强化神圣愤怒",
            art = "ReplaceableTextures\\PASBTNMS_7.blp",
            description = "神圣愤怒的数量上限+1",
            isActive = false,
            cundangStr = "mingwen1",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 55,
            cunDangEndIndex = 56,
            zhiye_cundang_str = "chengjieqi",
            isEquipped = false,
            req = {
                { name = "战争铭文", count = 2 }
            }
        },
        {
            name = "星辰专注",
            art = hslk.n2v("群星坠落", "Art"),
            description = "群星坠落现在只会攻击一个单位，但是持续时间延长3秒",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 57,
            cunDangEndIndex = 58,
            zhiye_cundang_str = "xingchenfashi",
            isEquipped = false,
            req = {
                { name = "战争铭文", count = 2 }
            }
        },
        {
            name = "极速毁灭",
            art = hslk.n2v("暴怒", "Art"),
            description = "双持单手武器时，暴怒的冷却时间缩短5秒",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 59,
            cunDangEndIndex = 60,
            zhiye_cundang_str = "kuangbaozhan",
            isEquipped = false,
            req = {
                { name = "战争铭文", count = 2 }
            }
        },
        {
            name = "远古奥能脉冲星",
            art = hslk.n2v("超凡之盟", "Art"),
            description = "原始奥能脉冲星触发的超凡之盟的持续时间增加2秒",
            isActive = false,
            cundangStr = "mingwen",
            isPerHero = false,
            mingwenType = CONST_MINGWEN_TYPE.MAJOR,
            cunDangStartIndex = 61,
            cunDangEndIndex = 62,
            zhiye_cundang_str = "xingchenfashi",
            isEquipped = false,
            req = {
                { name = "战争铭文", count = 2 }
            }
        },
    }
    hmingwen.init(config, mingwenConfig)

    hshop.addNormalItem(
        "军需处长谭恩",
        "魔法水晶",
        { { type = HSHOP_COST_TYPE.gongzhenghuizhang, value = 10 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "王城" } }
    )

    hshop.addNormalItem(
        "守备官斯通哈特",
        "人马图腾",
        { { type = HSHOP_COST_TYPE.yongqihuizhang, value = 10 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "峡谷前哨站" } }
    )


    local function isKapian(itemName)
        -- 定义可能的前缀和数字范围
        local prefixes = {
            "疯狂之",
            "复仇之",
            "伟大之",
            "远征之",
            "怒火之"
        }
        local suffix = {
            "一",
            "二",
            "三",
            "四",
            "五",
            "六",
            "七",
            "八"
        }
        -- 使用模式匹配检查itemName是否符合要求
        for _, prefix in ipairs(prefixes) do
            for _, s in ipairs(suffix) do
                if string.find(itemName, prefix .. s) then
                    return true
                end
            end
        end
        -- 如果没有匹配成功，返回false
        return false
    end

    hshop.addItem(
        "铭文大师德拉里",
        "分解卡牌",
        "ReplaceableTextures\\mingwen\\INV_Inscription_TarotDeath.blp",
        { { type = HSHOP_COST_TYPE.gold, value = 2000 } },
        {},
        "你有多余的卡牌吗？我可以帮你分解成暗月精华，只收你2000金币。请把你要分解的卡牌放在六格背包的第一格。每次只会分解一张卡片。",
        function(whichPlayer)
            local whichUnit = hplayer.getMainHero(whichPlayer)
            local item = cj.UnitItemInSlot(whichUnit, 0)
            local dynamicItem = hitem.getDynamicItem(item)
            if dynamicItem.stack == nil or dynamicItem.stack == 1 then
                hitem.destroy(item)
            else
                hitem.setCharges(item, dynamicItem.stack - 1)
            end
            local newItem = DynamicItem(hslk.n2i("暗月精华"))
            newItem.setOwner(whichPlayer)
            newItem.initBasedOnPinzhi()
            if hplayer.dzCunDang[whichPlayer].saveItemInInventory(newItem) == false then
                hitem.create({ id = hslk.n2i("暗月精华"), whichUnit = whichUnit, dynamicItem = newItem })
            end
        end,
        function(whichPlayer)
            local whichUnit = hplayer.getMainHero(whichPlayer)
            if whichUnit == nil then
                return false
            end
            local item = cj.UnitItemInSlot(whichUnit, 0)
            if item == nil then
                echo("物品栏第一格无物品", whichPlayer)
                return false
            end

            local dynamicItem = hitem.getDynamicItem(item)
            if dynamicItem.getOwner() ~= whichPlayer then
                echo("物品不属于你", whichPlayer)
                return false
            end
            local itemName = hslk.i2v(dynamicItem.basic_item_id, "Name")
            if isKapian(itemName) == false then
                echo("第一格物品不是卡片", whichPlayer)
                return false
            end
            return true
        end
    )

    hitem.registerItemSource("暗月精华", "铭文大师德拉里")
end
