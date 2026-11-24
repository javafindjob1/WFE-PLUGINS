hcaikuang = {}

---
--- config = {
---     {
---        reqLevel = 1,
---        req = {
---          {name = "铁矿",count = 2}
---        },
---        successRate = 10000
---        output = {
---          name = "铁锭",
---          itemLevel = 10,
---          count = 1,
---          upgradeRate,
---        },
---     },
---     {}
---}
---
---config = {
---     {
---        kuangshiName = "铁矿",
---        output = {
---          {
---            name = "铁矿石"，
---            count = 1,
---            rate=10000,
---          },
---          {
---            name = "精铁矿石"
---            count = 1,
---            rate=2000,
---          }
---        },
---
---     }
---}

hcaikuang.init = function(config, caikuangConfig)
    hzhuanye.initSingleZhuanye(config, "熔炼", "采矿", CONST_EVENT.caikuang, nil, caikuangConfig)
end
