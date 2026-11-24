function initCaiYao()
    local config = {
        {
            reqLevel = 0,
            req = {
                { name = "银叶草", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "金银草",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 1,
            req = {
                { name = "金银草", count = 5 }
            },
            successRate = 10000,
            output = {
                name = "圣光草",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 2,
            req = {
                { name = "火焰草", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "烈焰草",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 2,
            req = {
                { name = "烈焰草", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "烈焰菇",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 3,
            req = {
                { name = "烈焰菇", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "汲血草",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 3,
            req = {
                { name = "汲血草", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "绽放之血",
                count = 1
            },
            zhizuoExp = 1
        }
    }
    local caiyaoConfig = {
        {
            name = "基础草药",
            data = {
                output = {
                    {
                        name = "银叶草",
                        count = 2,
                        rate = 10000
                    },
                    {
                        name = "金银草",
                        count = 1,
                        rate = 1000
                    }
                },
                requiredLevel = 0,
                requiredZhuanye = "采药",
                caijishijian = 5,
                event = CONST_EVENT.caiyao,
                destroyTarget = false,
                refreshTime = 400,
                maxCaijiCount = 15
            }
        },
        {
            name = "金色草药",
            data = {
                output = {
                    {
                        name = "银叶草",
                        count = 3,
                        rate = 10000
                    },
                    {
                        name = "金银草",
                        count = 1,
                        rate = 2000
                    },
                    {
                        name = "圣光草",
                        count = 1,
                        rate = 500
                    }
                },
                requiredLevel = 1,
                requiredZhuanye = "采药",
                caijishijian = 5,
                event = CONST_EVENT.caiyao,
                destroyTarget = false,
                refreshTime = 800,
                maxCaijiCount = 15
            }
        },
        {
            name = "沙漠草药",
            data = {
                output = {
                    {
                        name = "火焰草",
                        count = 1,
                        rate = 10000
                    },
                    {
                        name = "烈焰草",
                        count = 1,
                        rate = 2000
                    },
                    {
                        name = "烈焰菇",
                        count = 1,
                        rate = 500
                    }
                },
                requiredLevel = 2,
                requiredZhuanye = "采药",
                caijishijian = 5,
                event = CONST_EVENT.caiyao,
                destroyTarget = false,
                refreshTime = 1200,
                maxCaijiCount = 15
            }
        },
        {
            name = "汲血草药",
            data = {
                output = {
                    {
                        name = "汲血草",
                        count = 1,
                        rate = 10000
                    },
                    {
                        name = "绽放之血",
                        count = 1,
                        rate = 1000
                    }
                },
                requiredLevel = 3,
                requiredZhuanye = "采药",
                caijishijian = 5,
                event = CONST_EVENT.caiyao,
                destroyTarget = false,
                refreshTime = 1200,
                maxCaijiCount = 15
            }
        }
    }
    hcaiyao.init(config, caiyaoConfig)
end
