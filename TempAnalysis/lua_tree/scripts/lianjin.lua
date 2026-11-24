function initLianjin()
    local config = {
        {
            reqLevel = 0,
            req = {
                { name = "银叶草", count = 1 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "基础生命恢复药剂",
                itemLevel = 10,
                itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                count = 1,
                upgradeRate = 1000
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 0,
            req = {
                { name = "基础生命恢复药剂", count = 10 }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "初级速效治疗石",
                itemLevel = 1,
                itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 0,
            req = {
                { name = "银叶草", count = 2 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "基础迅捷药剂",
                itemLevel = 10,
                itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                count = 1,
                upgradeRate = 1000
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 0,
            req = {
                { name = "银叶草", count = 2 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "基础能量恢复药剂",
                itemLevel = 10,
                itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                count = 1,
                upgradeRate = 1000
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 0,
            req = {
                { name = "银叶草", count = 40 },
                { name = "金银草", count = 10 },
                { name = "圣光草", count = 2 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "先祖智慧合剂",
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 1,
            req = {
                { name = "金银草", count = 1 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "中级生命恢复药剂",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 1,
            req = {
                { name = "中级生命恢复药剂", count = 10 },
                { name = "初级速效治疗石", count = 2 }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "中级速效治疗石",
                itemLevel = 1,
                itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 1,
            req = {
                { name = "金银草", count = 1 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "中级迅捷药剂",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 1,
            req = {
                { name = "圣光草", count = 1 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "初级潜能激发药水",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 1,
            req = {
                { name = "金银草", count = 2 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "中级能量恢复药剂",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 2,
            req = {
                { name = "火焰草", count = 2 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "高级生命恢复药剂",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 2,
            req = {
                { name = "高级生命恢复药剂", count = 10 },
                { name = "中级速效治疗石", count = 2 },
                { name = "烈焰菇", count = 5 }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "高级速效治疗石",
                itemLevel = 1,
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "火焰草", count = 3 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "高级迅捷药剂",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 2,
            req = {
                { name = "烈焰菇", count = 1 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "中级潜能激发药水",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 2,
            req = {
                { name = "烈焰草", count = 1 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "高级能量恢复药剂",
                count = 1
            },
            zhizuoExp = 1
        },
        {
            reqLevel = 2,
            req = {
                { name = "烈焰草", count = 20 },
                { name = "烈焰菇", count = 5 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "泰坦合剂",
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "绽放之血", count = 10 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "强固合剂",
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "绽放之血", count = 15 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "无情突袭合剂",
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "绽放之血", count = 15 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "强效思维合剂",
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "绽放之血", count = 20 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "魔血合剂",
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "汲血草", count = 10 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "魔能药剂",
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "汲血草", count = 10 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "法能药剂",
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "汲血草", count = 10 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "掌控药剂",
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "汲血草", count = 5 },
                { name = "瓶子", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "专家级生命恢复药剂",
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "专家级生命恢复药剂", count = 10 },
                { name = "高级速效治疗石", count = 2 },
                { name = "绽放之血", count = 10 }
            },
            successRate = 10000,
            zhizuoshijian = 20,
            output = {
                name = "专家级速效治疗石",
                itemLevel = 1,
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                count = 1
            },
            zhizuoExp = 5
        },
    }
    hlianjin.init(config)
    hshop.addNormalItem("药剂学徒瑞克", "瓶子", { { type = HSHOP_COST_TYPE.gold, value = 500 } }, {})
    hshop.addNormalItem(
        "新手村村长",
        "瓶子",
        { { type = HSHOP_COST_TYPE.gold, value = 300 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 3, shengwangname = "新手村" } }
    )
end
