function initZhiBu()
    local config = {
        {
            reqLevel = 0,
            req = {
                { name = "麻布", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "精致麻布",
                count = 1
            }
        },
        {
            reqLevel = 1,
            req = {
                { name = "精致麻布", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "丝绸",
                count = 1
            }
        },
        {
            reqLevel = 2,
            req = {
                { name = "丝绸", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "精致丝绸",
                count = 1
            }
        },
        {
            reqLevel = 3,
            req = {
                { name = "精致丝绸", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "符文布",
                count = 1
            }
        },
        {
            reqLevel = 3,
            req = {
                { name = "符文布", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "灵纹布",
                count = 1
            }
        }
    }

    local shaguaiConfig = {
        {
            minUnitLevel = 1,
            maxUnitLevel = 30,
            kezhibu = true,
            output = {
                {
                    name = "麻布",
                    count = 1,
                    rate = 200
                },
                {
                    name = "精致麻布",
                    count = 1,
                    rate = 20
                }
            }
        },
        {
            minUnitLevel = 31,
            maxUnitLevel = 45,
            kezhibu = true,
            output = {
                {
                    name = "麻布",
                    count = 1,
                    rate = 400
                },
                {
                    name = "精致麻布",
                    count = 1,
                    rate = 40
                }
            }
        },
        {
            minUnitLevel = 46,
            maxUnitLevel = 60,
            kezhibu = true,
            output = {
                {
                    name = "丝绸",
                    count = 1,
                    rate = 100
                },
                {
                    name = "精致丝绸",
                    count = 1,
                    rate = 10
                }
            }
        },
        {
            minUnitLevel = 61,
            maxUnitLevel = 74,
            kezhibu = true,
            output = {
                {
                    name = "符文布",
                    count = 1,
                    rate = 100
                },
                {
                    name = "灵纹布",
                    count = 1,
                    rate = 10
                }
            }
        }
    }
    hzhibu.init(config, shaguaiConfig)
end
