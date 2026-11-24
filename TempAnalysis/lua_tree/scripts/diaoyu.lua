function initDiaoYu()
    local diaoyuConfig = {
        {
            name = "新手村钓鱼点",
            data = {
                requiredLevel = 0,
                output = {},
                requiredZhuanye = "钓鱼",
                caijishijian = 5,
                event = CONST_EVENT.diaoyu,
                destroyTarget = false,
                maxCaijiCount = 100,
                refreshTime = 2
            }
        },
        {
            name = "王城喷泉",
            data = {
                requiredLevel = 1,
                output = {},
                requiredZhuanye = "钓鱼",
                caijishijian = 3,
                event = CONST_EVENT.diaoyu,
                destroyTarget = false,
                maxCaijiCount = 20,
                refreshTime = 6
            }
        },
        {
            name = "沙漠深井",
            data = {
                requiredLevel = 2,
                output = {},
                requiredZhuanye = "钓鱼",
                caijishijian = 5,
                event = CONST_EVENT.diaoyu,
                destroyTarget = false,
                maxCaijiCount = 20,
                refreshTime = 8
            }
        },
        {
            name = "和平之城钓鱼点",
            data = {
                requiredLevel = 3,
                output = {},
                requiredZhuanye = "钓鱼",
                caijishijian = 5,
                event = CONST_EVENT.diaoyu,
                destroyTarget = false,
                maxCaijiCount = 20,
                refreshTime = 8
            }
        }
    }
    local nameIconConfig = {
        { "针眼旋鲨", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_01.blp", ZHUANGBEI_PINZHI.PUTONG, "新手村钓鱼点", 200 },
        { "皇家蓝叶鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_02.blp", ZHUANGBEI_PINZHI.PUTONG, "新手村钓鱼点", 200 },
        { "黄金纹章师", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_03.blp", ZHUANGBEI_PINZHI.PUTONG, "新手村钓鱼点", 200 },
        { "翠绿宝石鳃鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_04.blp", ZHUANGBEI_PINZHI.PUTONG, "新手村钓鱼点", 200 },
        { "紫罗兰斑点鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_05.blp", ZHUANGBEI_PINZHI.PUTONG, "新手村钓鱼点", 200 },
        { "橙霓斑纹鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_06.blp", ZHUANGBEI_PINZHI.PUTONG, "新手村钓鱼点", 200 },
        { "珊瑚红扇尾鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_07.blp", ZHUANGBEI_PINZHI.PUTONG, "新手村钓鱼点", 200 },
        { "浅蓝纵带鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_08.blp", ZHUANGBEI_PINZHI.PUTONG, "新手村钓鱼点", 200 },
        { "锦绣斜纹鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_09.blp", ZHUANGBEI_PINZHI.PUTONG, "新手村钓鱼点", 200 },
        { "靛蓝波纹鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_10.blp", ZHUANGBEI_PINZHI.PUTONG, "新手村钓鱼点", 200 },
        { "翡翠斑螺鲨", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_11.blp", ZHUANGBEI_PINZHI.PUTONG, "新手村钓鱼点", 200 },
        { "深蓝冥界鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_12.blp", ZHUANGBEI_PINZHI.JINGLIANG, "新手村钓鱼点", 50 },
        { "紫影幻鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_13.blp", ZHUANGBEI_PINZHI.JINGLIANG, "新手村钓鱼点", 50 },
        { "赤炎龙虾", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_14.blp", ZHUANGBEI_PINZHI.JINGLIANG, "新手村钓鱼点", 50 },
        { "雪影鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_19.blp", ZHUANGBEI_PINZHI.JINGLIANG, "新手村钓鱼点", 50 },
        { "蓝晶鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_20.blp", ZHUANGBEI_PINZHI.JINGLIANG, "新手村钓鱼点", 50 },
        { "紫晶飞鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_21.blp", ZHUANGBEI_PINZHI.JINGLIANG, "新手村钓鱼点", 50 },
        { "烈焰吞噬者", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_22.blp", ZHUANGBEI_PINZHI.SHISHI, "新手村钓鱼点", 20 },
        { "深海蓝影", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_23.blp", ZHUANGBEI_PINZHI.SHISHI, "新手村钓鱼点", 20 },
        { "碧波幽灵鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_24.blp", ZHUANGBEI_PINZHI.CHUANQI, "新手村钓鱼点", 10 },
        { "深渊影鲨", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_25.blp", ZHUANGBEI_PINZHI.PUTONG, "王城喷泉", 150 },
        { "幽蓝夜行者", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_26.blp", ZHUANGBEI_PINZHI.PUTONG, "王城喷泉", 150 },
        { "火焰吞食者", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_27.blp", ZHUANGBEI_PINZHI.PUTONG, "王城喷泉", 150 },
        { "翠绿潜行鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_28.blp", ZHUANGBEI_PINZHI.PUTONG, "王城喷泉", 150 },
        { "梦幻粉纱鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_29.blp", ZHUANGBEI_PINZHI.PUTONG, "王城喷泉", 150 },
        { "银鳞闪光鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_30.blp", ZHUANGBEI_PINZHI.PUTONG, "王城喷泉", 150 },
        { "暗流潮鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_31.blp", ZHUANGBEI_PINZHI.PUTONG, "王城喷泉", 150 },
        { "紫雾幽灵", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_32.blp", ZHUANGBEI_PINZHI.PUTONG, "王城喷泉", 150 },
        { "灰岩斑点鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_33.blp", ZHUANGBEI_PINZHI.PUTONG, "王城喷泉", 150 },
        { "星空虚空鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_34.blp", ZHUANGBEI_PINZHI.PUTONG, "王城喷泉", 150 },
        { "星辰彩鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_35.blp", ZHUANGBEI_PINZHI.PUTONG, "王城喷泉", 150 },
        { "金光烁鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_36.blp", ZHUANGBEI_PINZHI.JINGLIANG, "王城喷泉", 40 },
        { "雷霆怒鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_37.blp", ZHUANGBEI_PINZHI.JINGLIANG, "王城喷泉", 40 },
        { "翠羽鲨鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_38.blp", ZHUANGBEI_PINZHI.JINGLIANG, "王城喷泉", 40 },
        { "翡翠梦鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_39.blp", ZHUANGBEI_PINZHI.JINGLIANG, "王城喷泉", 40 },
        { "龙鳞煌鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_40.blp", ZHUANGBEI_PINZHI.JINGLIANG, "王城喷泉", 40 },
        { "暮色鲨鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_41.blp", ZHUANGBEI_PINZHI.JINGLIANG, "王城喷泉", 40 },
        { "灵珠幻鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_42.blp", ZHUANGBEI_PINZHI.SHISHI, "王城喷泉", 15 },
        { "紫晶鲨鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_43.blp", ZHUANGBEI_PINZHI.SHISHI, "王城喷泉", 15 },
        { "绿影妖鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_44.blp", ZHUANGBEI_PINZHI.CHUANQI, "王城喷泉", 8 },
        { "狂野须尾鳗", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_45.blp", ZHUANGBEI_PINZHI.PUTONG, "沙漠深井", 50 },
        { "蓝唇灵蝠鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_46.blp", ZHUANGBEI_PINZHI.PUTONG, "沙漠深井", 50 },
        { "金眼暗影鲈", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_47.blp", ZHUANGBEI_PINZHI.PUTONG, "沙漠深井", 50 },
        { "幽魂鬼鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_48.blp", ZHUANGBEI_PINZHI.PUTONG, "沙漠深井", 50 },
        { "寒冰裂齿鲨", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_49.blp", ZHUANGBEI_PINZHI.PUTONG, "沙漠深井", 50 },
        { "翠绿游龙鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_50.blp", ZHUANGBEI_PINZHI.PUTONG, "沙漠深井", 50 },
        { "蓝月流光鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_51.blp", ZHUANGBEI_PINZHI.PUTONG, "沙漠深井", 50 },
        { "碧波闪耀鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_52.blp", ZHUANGBEI_PINZHI.PUTONG, "沙漠深井", 50 },
        { "紫韵灵动鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_53.blp", ZHUANGBEI_PINZHI.PUTONG, "沙漠深井", 50 },
        { "霓裳曼舞鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_54.blp", ZHUANGBEI_PINZHI.PUTONG, "沙漠深井", 50 },
        { "翡翠飞羽鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_55.blp", ZHUANGBEI_PINZHI.PUTONG, "沙漠深井", 50 },
        { "丹霞游鹿鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_56.blp", ZHUANGBEI_PINZHI.JINGLIANG, "沙漠深井", 20 },
        { "靛蓝精灵鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_57.blp", ZHUANGBEI_PINZHI.JINGLIANG, "沙漠深井", 20 },
        { "锦鳞舞衣鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_58.blp", ZHUANGBEI_PINZHI.JINGLIANG, "沙漠深井", 20 },
        { "紫罗兰影鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_59.blp", ZHUANGBEI_PINZHI.JINGLIANG, "沙漠深井", 20 },
        { "玄冰凤凰鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_60.blp", ZHUANGBEI_PINZHI.JINGLIANG, "沙漠深井", 20 },
        { "极寒冰川鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_61.blp", ZHUANGBEI_PINZHI.JINGLIANG, "沙漠深井", 20 },
        { "魔夜葡萄鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_62.blp", ZHUANGBEI_PINZHI.SHISHI, "沙漠深井", 10 },
        { "烈焰朱砂鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_63.blp", ZHUANGBEI_PINZHI.SHISHI, "沙漠深井", 10 },
        { "翡翠苍龙鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_64.blp", ZHUANGBEI_PINZHI.CHUANQI, "沙漠深井", 5 },
        { "血鳍巨鲨", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_65.blp", ZHUANGBEI_PINZHI.PUTONG, "和平之城钓鱼点", 25 },
        { "深海幽鳐", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_66.blp", ZHUANGBEI_PINZHI.PUTONG, "和平之城钓鱼点", 25 },
        { "彩纹剑鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_67.blp", ZHUANGBEI_PINZHI.PUTONG, "和平之城钓鱼点", 25 },
        { "黄金锦鲤", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_68.blp", ZHUANGBEI_PINZHI.PUTONG, "和平之城钓鱼点", 25 },
        { "星光蓝鲱", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_69.blp", ZHUANGBEI_PINZHI.PUTONG, "和平之城钓鱼点", 25 },
        { "绿触水母", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_70.blp", ZHUANGBEI_PINZHI.PUTONG, "和平之城钓鱼点", 25 },
        { "烈焰水母", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_71.blp", ZHUANGBEI_PINZHI.PUTONG, "和平之城钓鱼点", 25 },
        { "夜光鳗鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_72.blp", ZHUANGBEI_PINZHI.PUTONG, "和平之城钓鱼点", 25 },
        { "火焰精灵", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_73.blp", ZHUANGBEI_PINZHI.PUTONG, "和平之城钓鱼点", 25 },
        { "暗影毒鳗", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_74.blp", ZHUANGBEI_PINZHI.PUTONG, "和平之城钓鱼点", 25 },
        { "翡翠鳞鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_75.blp", ZHUANGBEI_PINZHI.PUTONG, "和平之城钓鱼点", 25 },
        { "暗影鳞鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_76.blp", ZHUANGBEI_PINZHI.JINGLIANG, "和平之城钓鱼点", 12 },
        { "棘鳞怪鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_77.blp", ZHUANGBEI_PINZHI.JINGLIANG, "和平之城钓鱼点", 12 },
        { "鲜艳红鲤", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_78.blp", ZHUANGBEI_PINZHI.JINGLIANG, "和平之城钓鱼点", 12 },
        { "金鳞游鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_79.blp", ZHUANGBEI_PINZHI.JINGLIANG, "和平之城钓鱼点", 12 },
        { "幽灵蛇鳗", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_80.blp", ZHUANGBEI_PINZHI.JINGLIANG, "和平之城钓鱼点", 12 },
        { "凶齿巨鲨", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_81.blp", ZHUANGBEI_PINZHI.JINGLIANG, "和平之城钓鱼点", 12 },
        { "森林幽鲤", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_82.blp", ZHUANGBEI_PINZHI.SHISHI, "和平之城钓鱼点", 6 },
        { "赤牙凶鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_83.blp", ZHUANGBEI_PINZHI.SHISHI, "和平之城钓鱼点", 6 },
        { "青铜潜鱼", "ReplaceableTextures\\diaoyu\\INV_Misc_Fish_84.blp", ZHUANGBEI_PINZHI.CHUANQI, "和平之城钓鱼点", 3 }

    }
    local tujianConfig = {}
    for i, v in ipairs(nameIconConfig) do
        local cdstr = "diaoyuTujian" .. tostring(math.floor((i - 1) / 31))
        local cunDangStartIndex = ((i - 1) % 31) * 2 + 1
        local cunDangEndIndex = cunDangStartIndex + 1
        local life = "+" .. tostring(1 * (2 ^ (math.floor(i / 20) + 1)) * v[3])
        local exp_ratio = "+0.1"
        local attack_speed = "+0.1"
        local skill_speed = "+0.1"
        local attr = { life = life }
        if v[3] == ZHUANGBEI_PINZHI.PUTONG then
            attr = { life = life }
        elseif v[3] == ZHUANGBEI_PINZHI.JINGLIANG then
            attr = { exp_ratio = exp_ratio }
        elseif v[3] == ZHUANGBEI_PINZHI.SHISHI then
            attr = { attack_speed = attack_speed }
        elseif v[3] == ZHUANGBEI_PINZHI.CHUANQI then
            attr = { skill_speed = skill_speed }
        end

        table.insert(
            tujianConfig,
            {
                name = ZHUANGBEI_PINZHI_DATA[v[3]].color(v[1]),
                cundangStr = cdstr,
                art = v[2],
                isPerHero = false,
                cunDangStartIndex = cunDangStartIndex,
                cunDangEndIndex = cunDangEndIndex,
                description = "可以在" .. v[4] .. "钓鱼获得，每次钓鱼获得概率为" .. string.format("%.2f%%", (v[5] / 10000) * 100),
                currentCount = 0,
                attr = {
                    {
                        requriedCount = 1,
                        attr = attr
                    },
                    {
                        requriedCount = 5,
                        attr = attr
                    },
                    {
                        requriedCount = 10,
                        attr = attr
                    },
                    {
                        requriedCount = 20,
                        attr = attr
                    },
                    {
                        requriedCount = 50,
                        attr = attr
                    },
                    {
                        requriedCount = 99,
                        attr = attr
                    }
                }
            }
        )
        for _, diaoyudian in ipairs(diaoyuConfig) do
            if diaoyudian.name == v[4] then
                table.insert(
                    diaoyudian.data.output,
                    {
                        name = ZHUANGBEI_PINZHI_DATA[v[3]].color(v[1]),
                        rate = v[5],
                        outputType = "diaoyutujian"
                    }
                )
            end
        end
    end
    hdiaoyu.init(diaoyuConfig, tujianConfig)
end
