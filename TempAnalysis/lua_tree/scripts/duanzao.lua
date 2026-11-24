function initDuanzao()
    local config = {
        {
            reqLevel = 0,
            req = {
                {
                    name = "铁锭",
                    count = 2
                },
                {
                    name = "野蛮锁甲",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "银鳞胸甲",
                itemLevel = 10,
                itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                count = 1,
                upgradeRate = 1000
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 0,
            req = {
                {
                    name = "铁矿石",
                    count = 1
                }
            },
            successRate = 10000,
            output = {
                name = "初级锋利磨刀石",
                count = 1
            }
        },
        {
            reqLevel = 0,
            req = {
                {
                    name = "铁矿石",
                    count = 1
                }
            },
            successRate = 10000,
            output = {
                name = "初级厚重磨刀石",
                count = 1
            }
        },
        {
            reqLevel = 0,
            req = {
                {
                    name = "残破的鱼竿",
                    count = 2
                }
            },
            successRate = 10000,
            output = {
                name = "粗糙的鱼竿",
                count = 1,
                itemLevel = 10
            }
        },
        {
            reqLevel = 0,
            req = {
                {
                    name = "粗糙的鱼竿",
                    count = 2
                }
            },
            successRate = 10000,
            output = {
                name = "精致的鱼竿",
                count = 1,
                itemLevel = 10
            }
        },
        {
            reqLevel = 0,
            req = {
                {
                    name = "精致的鱼竿",
                    count = 2
                }
            },
            successRate = 10000,
            output = {
                name = "特制鱼竿",
                count = 1,
                itemLevel = 60
            }
        },
        {
            reqLevel = 0,
            req = {
                {
                    name = "精铁矿石",
                    count = 1
                }
            },
            successRate = 10000,
            output = {
                name = "锋利磨刀石",
                count = 1
            }
        },
        {
            reqLevel = 0,
            req = {
                {
                    name = "精铁矿石",
                    count = 1
                }
            },
            successRate = 10000,
            output = {
                name = "厚重磨刀石",
                count = 1
            }
        },
        {
            reqLevel = 0,
            req = {
                {
                    name = "绿鳞的冷铁匕首",
                    count = 1
                },
                {
                    name = "魔物精魄",
                    count = 5
                },
                {
                    name = "助熔剂",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "魔化冷铁匕首",
                itemLevel = 30,
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1,
                upgradeRate = 500
            },
            zhizuoExp = 3
        },
        {
            reqLevel = 0,
            req = {
                {
                    name = "沉重的黑木法杖",
                    count = 1
                },
                {
                    name = "魔物精魄",
                    count = 5
                },
                {
                    name = "助熔剂",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "魔化黑木法杖",
                itemLevel = 30,
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1,
                upgradeRate = 500
            },
            zhizuoExp = 3
        },
        {
            reqLevel = 1,
            req = {
                {
                    name = "战败勇士的头盔",
                    count = 1
                },
                {
                    name = "血色军战盔",
                    count = 1
                },
                {
                    name = "蓝影头盔",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 5
                },
                {
                    name = "精铁锭",
                    count = 3
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "无畏勇士战盔",
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
                {
                    name = "无畏勇士战盔",
                    count = 1
                },
                {
                    name = "光明核心碎片",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 5
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "无畏勇士战盔",
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
                {
                    name = "战败勇士的胸甲",
                    count = 1
                },
                {
                    name = "血色军锁甲",
                    count = 1
                },
                {
                    name = "蓝影衣服",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 5
                },
                {
                    name = "精铁锭",
                    count = 3
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "无畏勇士战甲",
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
                {
                    name = "无畏勇士战甲",
                    count = 1
                },
                {
                    name = "光明核心碎片",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 5
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "无畏勇士战甲",
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
                {
                    name = "战败勇士的手套",
                    count = 1
                },
                {
                    name = "血色军护手",
                    count = 1
                },
                {
                    name = "蓝影手套",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 5
                },
                {
                    name = "精铁锭",
                    count = 3
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "无畏勇士护手",
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
                {
                    name = "无畏勇士护手",
                    count = 1
                },
                {
                    name = "光明核心碎片",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 5
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "无畏勇士护手",
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
                {
                    name = "战败勇士的鞋子",
                    count = 1
                },
                {
                    name = "血色军战靴",
                    count = 1
                },
                {
                    name = "蓝影鞋子",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 5
                },
                {
                    name = "精铁锭",
                    count = 3
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "无畏勇士战靴",
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
                {
                    name = "无畏勇士战靴",
                    count = 1
                },
                {
                    name = "光明核心碎片",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 5
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "无畏勇士战靴",
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
                {
                    name = "魔化黑木法杖",
                    count = 1
                },
                {
                    name = "祭祀之杖",
                    count = 1
                },
                {
                    name = "主教之杖",
                    count = 1
                },
                {
                    name = "魔法水晶",
                    count = 2
                },
                {
                    name = "光明核心碎片",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 10
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "灵魂燃烧之杖",
                itemLevel = 39,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 1,
            req = {
                {
                    name = "嗜血锯刃",
                    count = 1
                },
                {
                    name = "残酷倒钩",
                    count = 1
                },
                {
                    name = "染血利刃",
                    count = 1
                },
                {
                    name = "魔法水晶",
                    count = 1
                },
                {
                    name = "光明核心碎片",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 5
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "鲜红之剑",
                itemLevel = 39,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 1,
            req = {
                {
                    name = "惩戒巨斧",
                    count = 1
                },
                {
                    name = "破坏者",
                    count = 1
                },
                {
                    name = "锋利巨斧",
                    count = 1
                },
                {
                    name = "魔法水晶",
                    count = 2
                },
                {
                    name = "光明核心碎片",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 5
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "千军",
                itemLevel = 39,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 1,
            req = {
                {
                    name = "森林长弓",
                    count = 1
                },
                {
                    name = "血色制式长弓",
                    count = 1
                },
                {
                    name = "惩戒巨弓",
                    count = 1
                },
                {
                    name = "魔法水晶",
                    count = 3
                },
                {
                    name = "光明核心碎片",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 10
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "血红之弓",
                itemLevel = 39,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                {
                    name = "野蛮斗士护手",
                    count = 1
                },
                {
                    name = "冠军之证",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 10
                },
                {
                    name = "秘银锭",
                    count = 4
                },
                {
                    name = "精金锭",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "冠军斗士护手",
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
                {
                    name = "野蛮斗士战甲",
                    count = 1
                },
                {
                    name = "冠军之证",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 10
                },
                {
                    name = "秘银锭",
                    count = 4
                },
                {
                    name = "精金锭",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "冠军斗士战甲",
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
                {
                    name = "野蛮斗士战盔",
                    count = 1
                },
                {
                    name = "冠军之证",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 10
                },
                {
                    name = "秘银锭",
                    count = 4
                },
                {
                    name = "精金锭",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "冠军斗士战盔",
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
                {
                    name = "野蛮斗士战靴",
                    count = 1
                },
                {
                    name = "冠军之证",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 10
                },
                {
                    name = "秘银锭",
                    count = 4
                },
                {
                    name = "精金锭",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "冠军斗士战靴",
                itemLevel = 53,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 1,
            req = {
                {
                    name = "秘银矿石",
                    count = 1
                }
            },
            successRate = 10000,
            output = {
                name = "精致锋利磨刀石",
                count = 1
            }
        },
        {
            reqLevel = 1,
            req = {
                {
                    name = "秘银矿石",
                    count = 1
                }
            },
            successRate = 10000,
            output = {
                name = "精致厚重磨刀石",
                count = 1
            }
        },
        {
            reqLevel = 2,
            req = {
                {
                    name = "精金矿石",
                    count = 1
                }
            },
            successRate = 10000,
            output = {
                name = "高级锋利磨刀石",
                count = 1
            }
        },
        {
            reqLevel = 2,
            req = {
                {
                    name = "精金矿石",
                    count = 1
                }
            },
            successRate = 10000,
            output = {
                name = "高级厚重磨刀石",
                count = 1
            }
        },
        {
            reqLevel = 2,
            req = {
                {
                    name = "套马索",
                    count = 1
                },
                {
                    name = "霍克的武器链",
                    count = 1
                },
                {
                    name = "人马图腾",
                    count = 2
                },
                {
                    name = "魔法水晶",
                    count = 1
                },
                {
                    name = "精金锭",
                    count = 1
                },
                {
                    name = "烈焰墨水",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "强化套马索",
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
                {
                    name = "精金锭",
                    count = 25
                },
                {
                    name = "萨弗隆铁锭",
                    count = 8
                },
                {
                    name = "火焰精华",
                    count = 25
                },
                {
                    name = "助熔剂",
                    count = 20
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "炎魔之锤",
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                {
                    name = "埃提耶什的碎片",
                    count = 40
                },
                {
                    name = "助熔剂",
                    count = 20
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "埃提耶什的杖柄",
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                {
                    name = "速射长弓",
                    count = 1
                },
                {
                    name = "速射强弓",
                    count = 1
                },
                {
                    name = "血红之弓",
                    count = 1
                },
                {
                    name = "远古石叶",
                    count = 1
                },
                {
                    name = "成年黑龙的肌腱",
                    count = 1
                },
                {
                    name = "火焰精华",
                    count = 10
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "上古守护者的长弓",
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
                {
                    name = "冠军斗士护手",
                    count = 1
                },
                {
                    name = "先驱勇士护手",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 20
                },
                {
                    name = "秘银锭",
                    count = 10
                },
                {
                    name = "精金锭",
                    count = 3
                },
                {
                    name = "火焰精华",
                    count = 3
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "熔铸勇士护手",
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
                {
                    name = "冠军斗士战靴",
                    count = 1
                },
                {
                    name = "先驱勇士腿甲",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 20
                },
                {
                    name = "秘银锭",
                    count = 10
                },
                {
                    name = "精金锭",
                    count = 3
                },
                {
                    name = "火焰精华",
                    count = 3
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "熔铸勇士战靴",
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
                {
                    name = "冠军斗士战盔",
                    count = 1
                },
                {
                    name = "先驱勇士头盔",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 20
                },
                {
                    name = "秘银锭",
                    count = 10
                },
                {
                    name = "精金锭",
                    count = 3
                },
                {
                    name = "火焰精华",
                    count = 3
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "熔铸勇士战盔",
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
                {
                    name = "冠军斗士战甲",
                    count = 1
                },
                {
                    name = "先驱勇士胸甲",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 20
                },
                {
                    name = "秘银锭",
                    count = 10
                },
                {
                    name = "精金锭",
                    count = 3
                },
                {
                    name = "火焰精华",
                    count = 3
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "熔铸勇士战甲",
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
                {
                    name = "熔铸勇士护手",
                    count = 1
                },
                {
                    name = "远古先驱勇士护手",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 30
                },
                {
                    name = "秘银锭",
                    count = 12
                },
                {
                    name = "精金锭",
                    count = 5
                },
                {
                    name = "火焰精华",
                    count = 10
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "熔铸勇士护手",
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
                {
                    name = "熔铸勇士战靴",
                    count = 1
                },
                {
                    name = "远古先驱勇士腿甲",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 30
                },
                {
                    name = "秘银锭",
                    count = 12
                },
                {
                    name = "精金锭",
                    count = 5
                },
                {
                    name = "火焰精华",
                    count = 10
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "熔铸勇士战靴",
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
                {
                    name = "熔铸勇士战盔",
                    count = 1
                },
                {
                    name = "远古先驱勇士头盔",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 30
                },
                {
                    name = "秘银锭",
                    count = 12
                },
                {
                    name = "精金锭",
                    count = 5
                },
                {
                    name = "火焰精华",
                    count = 10
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "熔铸勇士战盔",
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
                {
                    name = "熔铸勇士战甲",
                    count = 1
                },
                {
                    name = "远古先驱勇士胸甲",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 30
                },
                {
                    name = "秘银锭",
                    count = 12
                },
                {
                    name = "精金锭",
                    count = 5
                },
                {
                    name = "火焰精华",
                    count = 10
                }
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "熔铸勇士战甲",
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
                {
                    name = "黑曜石之刃",
                    count = 1
                },
                {
                    name = "沙赫拉姆黑剑",
                    count = 1
                },
                {
                    name = "削骨之刃",
                    count = 1
                },
                {
                    name = "黑龙精华",
                    count = 1
                },
                {
                    name = "千军",
                    count = 1
                },
                {
                    name = "精金锭",
                    count = 10
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "阿而坎迪·兄弟会之剑",
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
                {
                    name = "暗影烈焰法杖",
                    count = 1
                },
                {
                    name = "统御法杖",
                    count = 1
                },
                {
                    name = "灵魂燃烧之杖",
                    count = 1
                },
                {
                    name = "乔丹法杖",
                    count = 1
                },
                {
                    name = "精金锭",
                    count = 10
                },
                {
                    name = "黑龙精华",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "地狱烈焰法杖",
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
                {
                    name = "多彩之剑",
                    count = 1
                },
                {
                    name = "鲜红之剑",
                    count = 1
                },
                {
                    name = "反对者",
                    count = 1
                },
                {
                    name = "正义之手",
                    count = 1
                },
                {
                    name = "黑龙精华",
                    count = 1
                },
                {
                    name = "精金锭",
                    count = 10
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "混乱之刃",
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
                {
                    name = "碧空之歌",
                    count = 1
                },
                {
                    name = "统御法杖",
                    count = 1
                },
                {
                    name = "灵魂燃烧之杖",
                    count = 1
                },
                {
                    name = "狂暴火焰护符",
                    count = 1
                },
                {
                    name = "精金锭",
                    count = 10
                },
                {
                    name = "黑龙精华",
                    count = 1
                }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "灼热的碧空之歌",
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
                {
                    name = "奥金矿石",
                    count = 1
                }
            },
            successRate = 10000,
            output = {
                name = "奥金锋利磨刀石",
                count = 1
            }
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "奥金矿石",
                    count = 1
                }
            },
            successRate = 10000,
            output = {
                name = "奥金厚重磨刀石",
                count = 1
            }
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
                    name = "助熔剂",
                    count = 30
                },
                {
                    name = "奥金锭",
                    count = 4
                },
                {
                    name = "精金锭",
                    count = 6
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
                name = "无畏战将护手",
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
                    name = "助熔剂",
                    count = 30
                },
                {
                    name = "奥金锭",
                    count = 4
                },
                {
                    name = "精金锭",
                    count = 6
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
                name = "无畏战将战靴",
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
                    name = "助熔剂",
                    count = 30
                },
                {
                    name = "奥金锭",
                    count = 4
                },
                {
                    name = "精金锭",
                    count = 6
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
                name = "无畏战将战盔",
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
                    name = "助熔剂",
                    count = 30
                },
                {
                    name = "奥金锭",
                    count = 4
                },
                {
                    name = "精金锭",
                    count = 6
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
                name = "无畏战将战甲",
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
                    name = "无畏战将护手",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "先锋远征军护手",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 50
                },
                {
                    name = "奥金锭",
                    count = 12
                },
                {
                    name = "精金锭",
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
                name = "无畏战将护手",
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
                    name = "无畏战将战靴",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "先锋远征军战靴",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 50
                },
                {
                    name = "奥金锭",
                    count = 12
                },
                {
                    name = "精金锭",
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
                name = "无畏战将战靴",
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
                    name = "无畏战将战盔",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "先锋远征军战盔",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 50
                },
                {
                    name = "奥金锭",
                    count = 12
                },
                {
                    name = "精金锭",
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
                name = "无畏战将战盔",
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
                    name = "无畏战将战甲",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "先锋远征军战甲",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 50
                },
                {
                    name = "奥金锭",
                    count = 12
                },
                {
                    name = "精金锭",
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
                name = "无畏战将战甲",
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
                {
                    name = "助熔剂",
                    count = 100
                },
                {
                    name = "奥金锭",
                    count = 10
                },
                {
                    name = "精金锭",
                    count = 20
                },
                {
                    name = "翠绿魔珠",
                    count = 5
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "秩序守护者之握",
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
                    name = "助熔剂",
                    count = 100
                },
                {
                    name = "奥金锭",
                    count = 10
                },
                {
                    name = "精金锭",
                    count = 20
                },
                {
                    name = "翠绿魔珠",
                    count = 5
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "秩序守护者之履",
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
                    name = "助熔剂",
                    count = 100
                },
                {
                    name = "奥金锭",
                    count = 15
                },
                {
                    name = "精金锭",
                    count = 25
                },
                {
                    name = "黑暗精华",
                    count = 5
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "秩序守护者冠冕",
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
                    name = "秩序守护者之握",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "史诗黑暗意志手套",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 150
                },
                {
                    name = "奥金锭",
                    count = 15
                },
                {
                    name = "精金锭",
                    count = 30
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
                name = "秩序守护者之握",
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
                    name = "秩序守护者之履",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "史诗黑暗意志长靴",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 100
                },
                {
                    name = "奥金锭",
                    count = 15
                },
                {
                    name = "精金锭",
                    count = 30
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
                name = "秩序守护者之履",
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
                    name = "秩序守护者冠冕",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "史诗黑暗意志头盔",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 100
                },
                {
                    name = "奥金锭",
                    count = 20
                },
                {
                    name = "精金锭",
                    count = 40
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
                name = "秩序守护者冠冕",
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
                    name = "助熔剂",
                    count = 100
                },
                {
                    name = "奥金锭",
                    count = 10
                },
                {
                    name = "精金锭",
                    count = 20
                },
                {
                    name = "黑暗精华",
                    count = 5
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "秩序守护者圣铠",
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
                    name = "秩序守护者圣铠",
                    count = 1,
                    nandu = FUBEN_NANDU.YINGXIONG
                },
                {
                    name = "史诗黑暗意志胸甲",
                    count = 1
                },
                {
                    name = "助熔剂",
                    count = 100
                },
                {
                    name = "奥金锭",
                    count = 20
                },
                {
                    name = "精金锭",
                    count = 40
                },
                {
                    name = "欺诈者之眼",
                    count = 3
                },
            },
            successRate = 10000,
            zhizuoshijian = 10,
            output = {
                name = "秩序守护者圣铠",
                itemLevel = 73,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
    }
    hshop.addNormalItem(
        "铁匠哈特",
        "助熔剂",
        {
            {
                type = HSHOP_COST_TYPE.gold,
                value = 2000
            }
        },
        {}
    )
    hshop.addNormalItem(
        "新手村村长",
        "助熔剂",
        {
            {
                type = HSHOP_COST_TYPE.gold,
                value = 1200
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "新手村"
            }
        }
    )
    hshop.addNormalItem(
        "军需处长谭恩",
        "战败勇士的头盔",
        {
            {
                type = HSHOP_COST_TYPE.gongzhenghuizhang,
                value = 20
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "王城"
            }
        }
    )
    hshop.addNormalItem(
        "军需处长谭恩",
        "战败勇士的胸甲",
        {
            {
                type = HSHOP_COST_TYPE.gongzhenghuizhang,
                value = 20
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "王城"
            }
        }
    )
    hshop.addNormalItem(
        "军需处长谭恩",
        "战败勇士的手套",
        {
            {
                type = HSHOP_COST_TYPE.gongzhenghuizhang,
                value = 20
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "王城"
            }
        }
    )
    hshop.addNormalItem(
        "军需处长谭恩",
        "战败勇士的鞋子",
        {
            {
                type = HSHOP_COST_TYPE.gongzhenghuizhang,
                value = 20
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "王城"
            }
        }
    )
    hshop.addNormalItem(
        "军需处长谭恩",
        "光明核心碎片",
        {
            {
                type = HSHOP_COST_TYPE.gongzhenghuizhang,
                value = 50
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "王城"
            }
        }
    )
    hshop.addNormalItem(
        "军需处长谭恩",
        "圣光之核",
        {
            {
                type = HSHOP_COST_TYPE.gongzhenghuizhang,
                value = 100
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "王城"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "冠军之证",
        {
            {
                type = HSHOP_COST_TYPE.yongqihuizhang,
                value = 50
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "火焰精华",
        {
            {
                type = HSHOP_COST_TYPE.yongqihuizhang,
                value = 10
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "先驱勇士头盔",
        {
            {
                type = HSHOP_COST_TYPE.yongqihuizhang,
                value = 100
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "先驱勇士胸甲",
        {
            {
                type = HSHOP_COST_TYPE.yongqihuizhang,
                value = 100
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "先驱勇士护手",
        {
            {
                type = HSHOP_COST_TYPE.yongqihuizhang,
                value = 100
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "先驱勇士腿甲",
        {
            {
                type = HSHOP_COST_TYPE.yongqihuizhang,
                value = 100
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "远古石叶",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "成年黑龙的肌腱",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "远古先驱勇士头盔",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "远古先驱勇士胸甲",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "远古先驱勇士护手",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "远古先驱勇士腿甲",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "黑龙精华",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "萨弗隆铁锭",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "逐风者禁锢之颅（左）",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 150
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "逐风者禁锢之颅（右）",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 150
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "火焰之王的精华",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 150
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "炎魔之眼",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 150
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "埃提耶什的碎片",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 4
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "埃提耶什的杖头",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 150
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "埃提耶什的杖尾",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 150
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "峡谷前哨站"
            }
        }
    )
    hshop.addNormalItem(
        "守备官斯通哈特",
        "风吻之刃",
        {
            {
                type = HSHOP_COST_TYPE.huoyanhuizhang,
                value = 80
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "峡谷前哨站"
            }
        }
    )

    hshop.addNormalItem(
        "正义军需官",
        "远征军战靴",
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 90
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "正义军需官",
        "远征军护手",
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 90
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "正义军需官",
        "远征军战盔",
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 90
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "正义军需官",
        "远征军战甲",
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 90
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "正义军需官",
        "远征军斗篷",
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 90
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "正义军需官",
        "屠龙者之血",
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "正义军需官",
        "埃兰的魔力精华",
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "正义军需官",
        "屠龙者的心脏",
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "正义军需官",
        "残破的战斧",
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "正义军需官",
        "煞能精华",
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "正义军需官",
        "守护者的宝石",
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "正义军需官",
        "卡拉赞的回响",
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "秩序军需官",
        "先锋远征军战靴",
        {
            {
                type = HSHOP_COST_TYPE.zhixuhuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "秩序军需官",
        "先锋远征军护手",
        {
            {
                type = HSHOP_COST_TYPE.zhixuhuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "秩序军需官",
        "先锋远征军战盔",
        {
            {
                type = HSHOP_COST_TYPE.zhixuhuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "秩序军需官",
        "先锋远征军战甲",
        {
            {
                type = HSHOP_COST_TYPE.zhixuhuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "秩序军需官",
        "先锋远征军斗篷",
        {
            {
                type = HSHOP_COST_TYPE.zhixuhuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 3,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addFullItem(
        "正义军需官",
        "纷争勇士披风",
        hslk.n2v("纷争勇士披风", "Art"),
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        },
        { {
            name = "纷争勇士披风",
            itemLevel = 70,
            itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
            nandu = FUBEN_NANDU.YINGXIONG,
            count = 1
        } }
    )
    hshop.addFullItem(
        "正义军需官",
        "纷争勇士护手",
        hslk.n2v("纷争勇士护手", "Art"),
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        },
        { {
            name = "纷争勇士护手",
            itemLevel = 70,
            itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
            nandu = FUBEN_NANDU.YINGXIONG,
            count = 1
        } }
    )
    hshop.addFullItem(
        "正义军需官",
        "纷争勇士战甲",
        hslk.n2v("纷争勇士战甲", "Art"),
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        },
        { {
            name = "纷争勇士战甲",
            itemLevel = 70,
            itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
            nandu = FUBEN_NANDU.YINGXIONG,
            count = 1
        } }
    )
    hshop.addFullItem(
        "正义军需官",
        "纷争勇士战盔",
        hslk.n2v("纷争勇士战盔", "Art"),
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        },
        { {
            name = "纷争勇士战盔",
            itemLevel = 70,
            itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
            nandu = FUBEN_NANDU.YINGXIONG,
            count = 1
        } }
    )
    hshop.addFullItem(
        "正义军需官",
        "纷争勇士战靴",
        hslk.n2v("纷争勇士战靴", "Art"),
        {
            {
                type = HSHOP_COST_TYPE.zhengyihuizhang,
                value = 60
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 1,
                shengwangname = "和平之城"
            }
        },
        { {
            name = "纷争勇士战靴",
            itemLevel = 70,
            itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
            nandu = FUBEN_NANDU.YINGXIONG,
            count = 1
        } }
    )

    hshop.addNormalItem(
        "秘法军需官",
        "烈日精华",
        {
            {
                type = HSHOP_COST_TYPE.mifahuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )

    hshop.addNormalItem(
        "魔能军需官",
        "狂暴烈焰精华",
        {
            {
                type = HSHOP_COST_TYPE.monenghuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )

    hshop.addNormalItem(
        "秘法军需官",
        "黑暗意志手套",
        {
            {
                type = HSHOP_COST_TYPE.mifahuizhang,
                value = 40
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "秘法军需官",
        "翠绿魔珠",
        {
            {
                type = HSHOP_COST_TYPE.mifahuizhang,
                value = 20
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "秘法军需官",
        "黑暗意志长靴",
        {
            {
                type = HSHOP_COST_TYPE.mifahuizhang,
                value = 40
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )

    hshop.addNormalItem(
        "魔能军需官",
        "史诗黑暗意志手套",
        {
            {
                type = HSHOP_COST_TYPE.monenghuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "魔能军需官",
        "史诗黑暗意志长靴",
        {
            {
                type = HSHOP_COST_TYPE.monenghuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "邪恶军需官",
        "黑暗意志头盔",
        {
            {
                type = HSHOP_COST_TYPE.xieehuizhang,
                value = 40
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )

    hshop.addNormalItem(
        "恶魔军需官",
        "史诗黑暗意志头盔",
        {
            {
                type = HSHOP_COST_TYPE.emohuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "邪恶军需官",
        "黑暗意志披风",
        {
            {
                type = HSHOP_COST_TYPE.xieehuizhang,
                value = 40
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "恶魔军需官",
        "史诗黑暗意志披风",
        {
            {
                type = HSHOP_COST_TYPE.emohuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "邪恶军需官",
        "黑暗精华",
        {
            {
                type = HSHOP_COST_TYPE.xieehuizhang,
                value = 20
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "邪恶军需官",
        "破损的恶魔战刃（主手）",
        {
            {
                type = HSHOP_COST_TYPE.xieehuizhang,
                value = 80
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "邪恶军需官",
        "破损的恶魔战刃（副手）",
        {
            {
                type = HSHOP_COST_TYPE.xieehuizhang,
                value = 80
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )

    hshop.addNormalItem(
        "邪恶军需官",
        "女祭司的记忆",
        {
            {
                type = HSHOP_COST_TYPE.xieehuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )

    hshop.addNormalItem(
        "恶魔军需官",
        "女祭司的记忆",
        {
            {
                type = HSHOP_COST_TYPE.emohuizhang,
                value = 20
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )

    hshop.addFullItem(
        "秘法军需官",
        "光荣护手",
        hslk.n2v("光荣护手", "Art"),
        {
            {
                type = HSHOP_COST_TYPE.mifahuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        },
        { {
            name = "光荣护手",
            itemLevel = 71,
            itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
            nandu = FUBEN_NANDU.YINGXIONG,
            count = 1
        } }
    )
    hshop.addFullItem(
        "秘法军需官",
        "光荣长靴",
        hslk.n2v("光荣长靴", "Art"),
        {
            {
                type = HSHOP_COST_TYPE.mifahuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        },
        { {
            name = "光荣长靴",
            itemLevel = 71,
            itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
            nandu = FUBEN_NANDU.YINGXIONG,
            count = 1
        } }
    )
    hshop.addFullItem(
        "辉煌军需官",
        "光荣战甲",
        hslk.n2v("光荣战甲", "Art"),
        {
            {
                type = HSHOP_COST_TYPE.huihuanghuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        },
        { {
            name = "光荣战甲",
            itemLevel = 73,
            itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
            nandu = FUBEN_NANDU.YINGXIONG,
            count = 1
        } }
    )
    hshop.addFullItem(
        "邪恶军需官",
        "光荣披风",
        hslk.n2v("光荣披风", "Art"),
        {
            {
                type = HSHOP_COST_TYPE.xieehuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        },
        { {
            name = "光荣披风",
            itemLevel = 72,
            itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
            nandu = FUBEN_NANDU.YINGXIONG,
            count = 1
        } }
    )
    hshop.addFullItem(
        "邪恶军需官",
        "光荣战盔",
        hslk.n2v("光荣战盔", "Art"),
        {
            {
                type = HSHOP_COST_TYPE.xieehuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        },
        { {
            name = "光荣战盔",
            itemLevel = 72,
            itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
            nandu = FUBEN_NANDU.YINGXIONG,
            count = 1
        } }
    )
    hshop.addNormalItem(
        "辉煌军需官",
        "黑暗意志胸甲",
        {
            {
                type = HSHOP_COST_TYPE.huihuanghuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "辉煌军需官",
        "欺诈者之眼",
        {
            {
                type = HSHOP_COST_TYPE.huihuanghuizhang,
                value = 100
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "凯旋军需官",
        "欺诈者之眼",
        {
            {
                type = HSHOP_COST_TYPE.kaixuanhuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "辉煌军需官",
        "太阳之井的精华",
        {
            {
                type = HSHOP_COST_TYPE.huihuanghuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )
    hshop.addNormalItem(
        "凯旋军需官",
        "史诗黑暗意志胸甲",
        {
            {
                type = HSHOP_COST_TYPE.kaixuanhuizhang,
                value = 30
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )

    hshop.addNormalItem(
        "凯旋军需官",
        "太阳之井的精华",
        {
            {
                type = HSHOP_COST_TYPE.kaixuanhuizhang,
                value = 20
            }
        },
        {
            {
                type = HSHOP_REQUIREMENT_TYPE.shengwang,
                value = 2,
                shengwangname = "和平之城"
            }
        }
    )

    local function addUpgradeItem(weaponName, currentDifficulty, nextDifficulty, costGold, requiredMaterial,
                                  materialCount)
        local artId = hslk.n2v(weaponName, "Art")
        local difficultyNames = {
            [FUBEN_NANDU.PUTONG] = "普通",
            [FUBEN_NANDU.YINGXIONG] = "英雄",
            [FUBEN_NANDU.SHISHI] = "史诗"
        }

        hshop.addItem(
            "纳鲁",
            "升级" .. difficultyNames[currentDifficulty] .. weaponName,
            artId,
            {
                {
                    type = HSHOP_COST_TYPE.gold,
                    value = costGold
                }
            },
            {
                {
                    type = HSHOP_REQUIREMENT_TYPE.shengwang,
                    value = 1,
                    shengwangname = "和平之城"
                }
            },
            string.format("利用%s继续升级%s，升级%s难度的%s到%s难度。%s可以通过纷争之地日常任务获取（需要先完成%s任务线）。",
                requiredMaterial, weaponName, difficultyNames[currentDifficulty], weaponName,
                difficultyNames[nextDifficulty],
                requiredMaterial, weaponName),
            function(whichPlayer)
                local hero = hplayer.getMainHero(whichPlayer)
                local item = hitem.getItemAtSlot(hero, 0)
                local dynamicItem = hitem.getDynamicItem(item)
                dynamicItem.setNandu(nextDifficulty)
            end,
            function(whichPlayer)
                local hero = hplayer.getMainHero(whichPlayer)
                local item = hitem.getItemAtSlot(hero, 0)
                if not item then
                    echo("物品栏第一格是空的", whichPlayer)
                    return false
                end
                local dynamicItem = hitem.getDynamicItem(item)
                if not dynamicItem then
                    echo("物品栏第一格错误", whichPlayer)
                    return false
                end
                if hitem.getName(dynamicItem.basic_item_id) ~= weaponName then
                    echo("物品栏第一格不是" .. weaponName, whichPlayer)
                    return false
                end
                if dynamicItem.nandu ~= currentDifficulty then
                    echo(weaponName .. "不是" .. difficultyNames[currentDifficulty] .. "难度", whichPlayer)
                    return false
                end
                if dynamicItem.getOwner() ~= whichPlayer then
                    echo(weaponName .. "所有者不是当前玩家", whichPlayer)
                    return false
                end
                return true
            end,
            {
                {
                    name = requiredMaterial,
                    count = materialCount
                }
            }
        )
    end

    -- 使用简化后的函数添加升级项
    addUpgradeItem("血吼", FUBEN_NANDU.PUTONG, FUBEN_NANDU.YINGXIONG, 100000, "煞能铁锭", 10)
    addUpgradeItem("血吼", FUBEN_NANDU.YINGXIONG, FUBEN_NANDU.SHISHI, 100000, "煞能铁锭", 20)
    addUpgradeItem("烈焰之击", FUBEN_NANDU.PUTONG, FUBEN_NANDU.YINGXIONG, 100000, "凝练的烈日精华", 10)
    addUpgradeItem("烈焰之击", FUBEN_NANDU.YINGXIONG, FUBEN_NANDU.SHISHI, 100000, "凝练的烈日精华", 20)
    addUpgradeItem("恶魔战刃（主手）", FUBEN_NANDU.PUTONG, FUBEN_NANDU.YINGXIONG, 100000, "黑暗魔石", 5)
    addUpgradeItem("恶魔战刃（主手）", FUBEN_NANDU.YINGXIONG, FUBEN_NANDU.SHISHI, 100000, "黑暗魔石", 10)
    addUpgradeItem("恶魔战刃（副手）", FUBEN_NANDU.PUTONG, FUBEN_NANDU.YINGXIONG, 100000, "黑暗魔石", 5)
    addUpgradeItem("恶魔战刃（副手）", FUBEN_NANDU.YINGXIONG, FUBEN_NANDU.SHISHI, 100000, "黑暗魔石", 10)
    addUpgradeItem("群星之怒·烈阳", FUBEN_NANDU.PUTONG, FUBEN_NANDU.YINGXIONG, 100000, "群星之怒的残片", 5)
    addUpgradeItem("群星之怒·烈阳", FUBEN_NANDU.YINGXIONG, FUBEN_NANDU.SHISHI, 100000, "群星之怒的残片", 10)
    addUpgradeItem("群星之怒·暗月", FUBEN_NANDU.PUTONG, FUBEN_NANDU.YINGXIONG, 100000, "群星之怒的残片", 5)
    addUpgradeItem("群星之怒·暗月", FUBEN_NANDU.YINGXIONG, FUBEN_NANDU.SHISHI, 100000, "群星之怒的残片", 10)
    hduanzao.init(config)
end
