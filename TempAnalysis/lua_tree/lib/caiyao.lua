hcaiyao = {}

---
--- config = {
---     {
---        reqLevel = 1,
---        req = {
---          {name = "银叶草",count = 10}
---        },
---        successRate = 10000
---        output = {
---          name = "金银草"
---          count = 1
---        },
---     }
---}
---
---config = {
---     {
---        kuangshiName = "基础草药",
---        output = {
---          {
---            name = "银叶草"，
---            count = 1,
---            rate=10000,
---          },
---          {
---            name = "金银草"
---            count = 1,
---            rate=1000,
---          }
---        },
---
---     }
---}

hcaiyao.init = function(config, caiyaoConfig)
    hzhuanye.initSingleZhuanye(config, "转化", "采药", CONST_EVENT.caiyao, nil, caiyaoConfig)
end
