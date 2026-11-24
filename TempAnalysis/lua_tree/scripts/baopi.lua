function initBaoPi()
    local config = {
        {
            reqLevel = 0,
            req = {
                { name = "轻皮", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "中皮",
                count = 1
            }
        },
        {
            reqLevel = 2,
            req = {
                { name = "中皮", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "重皮",
                count = 1
            }
        },
        {
            reqLevel = 3,
            req = {
                { name = "重皮", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "厚皮",
                count = 1
            }
        },
        {
            reqLevel = 3,
            req = {
                { name = "厚皮", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "结缔皮",
                count = 1
            }
        }
    }

    local shaguaiConfig = {
        {
            unitName = "野狼",
            kebaopi = true,
            output = {
                {
                    name = "轻皮",
                    count = 1,
                    rate = 500
                },
                {
                    name = "中皮",
                    count = 1,
                    rate = 50
                }
            }
        },
        {
            unitName = "铁狼",
            kebaopi = true,
            output = {
                {
                    name = "轻皮",
                    count = 1,
                    rate = 2000
                },
                {
                    name = "中皮",
                    count = 1,
                    rate = 200
                }
            }
        },
        {
            unitName = "银月狼王",
            kebaopi = true,
            output = {
                {
                    name = "轻皮",
                    count = 1,
                    rate = 5000
                },
                {
                    name = "中皮",
                    count = 1,
                    rate = 500
                }
            }
        },
        {
            unitName = "豺狼人",
            kebaopi = true,
            output = {
                {
                    name = "轻皮",
                    count = 1,
                    rate = 400
                },
                {
                    name = "中皮",
                    count = 1,
                    rate = 40
                }
            }
        },
        {
            unitName = "豺狼战士",
            kebaopi = true,
            output = {
                {
                    name = "轻皮",
                    count = 1,
                    rate = 800
                },
                {
                    name = "中皮",
                    count = 1,
                    rate = 80
                }
            }
        },
        {
            unitName = "豺狼领主",
            kebaopi = true,
            output = {
                {
                    name = "轻皮",
                    count = 1,
                    rate = 2000
                },
                {
                    name = "中皮",
                    count = 1,
                    rate = 200
                }
            }
        },
        {
            minUnitLevel = 40,
            maxUnitLevel = 60,
            kebaopi = true,
            output = {
                {
                    name = "中皮",
                    count = 1,
                    rate = 150
                },
                {
                    name = "重皮",
                    count = 1,
                    rate = 15
                }
            }
        },
        {
            unitName = "戈隆",
            kebaopi = true,
            output = {
                {
                    name = "厚皮",
                    count = 1,
                    rate = 800
                },
                {
                    name = "结缔皮",
                    count = 1,
                    rate = 80
                }
            }
        },
        {
            unitName = "恶魔卫士",
            kebaopi = true,
            output = {
                {
                    name = "厚皮",
                    count = 1,
                    rate = 400
                },
                {
                    name = "结缔皮",
                    count = 1,
                    rate = 40
                }
            }
        },
        {
            unitName = "神殿恶魔卫士",
            kebaopi = true,
            output = {
                {
                    name = "厚皮",
                    count = 1,
                    rate = 400
                },
                {
                    name = "结缔皮",
                    count = 1,
                    rate = 40
                }
            }
        }
    }
    hbaopi.init(config, shaguaiConfig)
end
