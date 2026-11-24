-- 打怪概率掉带布的尸体，采集可以获得布料
-- 合成稀有精良布料

hzhibu = {}

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

hzhibu.init = function(config, shaguaiConfig)
    hzhuanye.initSingleZhuanye(config, "制作", "制布", CONST_EVENT.zhibu, nil, nil, shaguaiConfig)
end
