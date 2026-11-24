function initCaikuang()
    local config = {
        {
            reqLevel = 0,
            req = {
                { name = "铁矿石", count = 2 }
            },
            successRate = 10000,
            output = {
                name = "铁锭",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 0,
            req = {
                { name = "精铁矿石", count = 2 }
            },
            successRate = 10000,
            output = {
                name = "精铁锭",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 0,
            req = {
                { name = "铁矿石", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "精铁矿石",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 0,
            req = {
                { name = "精铁矿石", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "秘银矿石",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 0,
            req = {
                { name = "秘银矿石", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "精金矿石",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 2,
            req = {
                { name = "秘银矿石", count = 3 }
            },
            successRate = 10000,
            output = {
                name = "秘银锭",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 2,
            req = {
                { name = "精金矿石", count = 4 }
            },
            successRate = 10000,
            output = {
                name = "精金锭",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 2,
            req = {
                { name = "源质矿石", count = 2 },
                { name = "火焰精华", count = 2 },
                { name = "精金锭", count = 1 },
                { name = "助熔剂", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "源质锭",
                count = 1
            },
            zhizuoExp = 2,
            zhizuoshijian = 10
        },
        {
            reqLevel = 3,
            req = {
                { name = "精金矿石", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "奥金矿石",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 3,
            req = {
                { name = "奥金矿石", count = 4 }
            },
            successRate = 10000,
            output = {
                name = "奥金锭",
                count = 1
            },
            zhizuoExp = 1
        }
    }

    local caikuangConfig = {
        {
            name = "铁矿",
            data = {
                output = {
                    {
                        name = "铁矿石",
                        count = 2,
                        rate = 10000
                    },
                    {
                        name = "精铁矿石",
                        count = 1,
                        rate = 500
                    },
                    {
                        name = "珠宝原石",
                        count = 1,
                        rate = 500
                    }
                },
                requiredLevel = 0,
                requiredZhuanye = "采矿",
                caijishijian = 5,
                event = CONST_EVENT.caikuang,
                destroyTarget = false,
                refreshTime = 400,
                maxCaijiCount = 15
            }
        },
        {
            name = "精铁矿",
            data = {
                output = {
                    {
                        name = "铁矿石",
                        count = 3,
                        rate = 10000
                    },
                    {
                        name = "精铁矿石",
                        count = 1,
                        rate = 2000
                    },
                    {
                        name = "珠宝原石",
                        count = 1,
                        rate = 1000
                    }
                },
                requiredLevel = 1,
                requiredZhuanye = "采矿",
                caijishijian = 5,
                event = CONST_EVENT.caikuang,
                destroyTarget = false,
                refreshTime = 800,
                maxCaijiCount = 15
            }
        },
        {
            name = "秘银矿",
            data = {
                output = {
                    {
                        name = "精铁矿石",
                        count = 1,
                        rate = 10000
                    },
                    {
                        name = "秘银矿石",
                        count = 1,
                        rate = 2500
                    },
                    {
                        name = "精金矿石",
                        count = 1,
                        rate = 1000
                    },
                    {
                        name = "罕见珠宝原石",
                        count = 1,
                        rate = 1000
                    }
                },
                requiredLevel = 2,
                requiredZhuanye = "采矿",
                caijishijian = 5,
                event = CONST_EVENT.caikuang,
                destroyTarget = false,
                refreshTime = 1200,
                maxCaijiCount = 15
            }
        },
        {
            name = "精金矿",
            data = {
                output = {
                    {
                        name = "秘银矿石",
                        count = 1,
                        rate = 10000
                    },
                    {
                        name = "精金矿石",
                        count = 1,
                        rate = 3000
                    },
                    {
                        name = "奥金矿石",
                        count = 1,
                        rate = 1000
                    },
                    {
                        name = "附能珠宝原石",
                        count = 1,
                        rate = 1000
                    }
                },
                requiredLevel = 3,
                requiredZhuanye = "采矿",
                caijishijian = 5,
                event = CONST_EVENT.caikuang,
                destroyTarget = false,
                refreshTime = 1200,
                maxCaijiCount = 15
            }
        }
    }
    hcaikuang.init(config, caikuangConfig)
end
