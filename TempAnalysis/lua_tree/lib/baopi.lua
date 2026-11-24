-- 打怪概率掉带皮的尸体，采集可以获得皮
-- 合成稀有皮

hbaopi = {}

---
--- config = {
---     {
---        reqLevel = 1,
---        req = {
---          {name = "轻皮",count = 10}
---        },
---        successRate = 10000
---        output = {
---          name = "中皮"
---          count = 1
---        },
---     }
---}
---
--- shaguaiConfig = {
---     {
---        minUnitLevel = 1,
---        maxUnitLevel = 10,
---        unitName = "野狼",
---        kebaopi = true,
---        output = {
---          {
---            name = "轻皮",
---            count = 1,
---            rate=1000,
---          },
---          {
---            name = "中皮",
---            count = 1,
---            rate=100,
---          }
---        },
---     }
--- }

hbaopi.init = function(config, shaguaiConfig)
    hzhuanye.initSingleZhuanye(config, "制作", "剥皮", CONST_EVENT.baopi, nil, nil, shaguaiConfig)
end
