function initQuest()
    local config = {
        {
            name = "主线任务",
            cundangStr = "zhuxian",
            questType = QUEST_TYPE.ONCE_LIFETIME,
            isPerHero = true,
            currentIndex = 1,
            data = {
                {
                    index = 1, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = false,
                            fitClass = { "狂暴战", "战斗贼", "恶魔猎手" },
                            itemName = "单手剑",
                            itemLevel = 1,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 2
                        },
                        {
                            fitAllClass = false,
                            fitClass = { "武器战", "惩戒骑" },
                            itemName = "双手剑",
                            itemLevel = 1,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        },
                        {
                            fitAllClass = false,
                            fitClass = { "火法", "毁灭术", "痛苦术", "星辰法师" },
                            itemName = "法杖",
                            itemLevel = 1,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        },
                        {
                            fitAllClass = false,
                            fitClass = { "射击猎" },
                            itemName = "弓",
                            itemLevel = 1,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 100,
                            maxLevel = 2,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "欢迎来到新世界, 请找到村长来开启主线任务", --任务文本
                    finishText = "欢迎你们，冒险者们！",
                    title = "初来乍到", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 1
                },
                {
                    index = 2, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "头盔",
                            itemLevel = 2,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 250,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "最近村子外的魔物出现更加频繁了，你能去村子外面帮忙吗?", --任务文本
                    title = "魔物肆虐", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "受伤的农夫",
                    level = 1
                },
                {
                    index = 3,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "鞋子",
                            itemLevel = 2,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 250,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "巨魔太猖狂了，你能帮忙清除村口的巨魔吗?", --任务文本
                    title = "清理魔物", -- 任务标题
                    req = {
                        -- max 3
                        -- 任务需求
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "巨魔", number = 10 } --杀怪数
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "受伤的农夫",
                    level = 2
                },
                {
                    index = 4,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "手套",
                            itemLevel = 3,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 250,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "干的不错，请继续帮忙清理2个巨魔狂战士，他们就在树林深处。", --任务文本
                    title = "清理魔物", -- 任务标题
                    req = {
                        -- max 3
                        -- 任务需求
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "巨魔狂战士", number = 2 } --杀怪数
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "受伤的农夫",
                    level = 3
                },
                {
                    index = 5,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "我们还有一个敌人，消灭巨魔领主！", --任务文本
                    title = "清理魔物", -- 任务标题
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "衣服",
                            itemLevel = 3,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        }
                    },
                    req = {
                        -- max 3
                        -- 任务需求
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "巨魔领主", number = 1 } --杀怪数
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "受伤的农夫",
                    level = 3
                },
                {
                    index = 6, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "请回去告诉村长，最近的魔物似乎太多了", --任务文本
                    title = "魔物的消息", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 3
                },
                {
                    index = 7, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "村长似乎知道些什么，但是他没有明说。他建议你继续清理村口的魔物，或许可以得到更多线索。去找农夫讨论下一步行动", --任务文本
                    title = "魔物的消息", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "受伤的农夫",
                    level = 3
                },
                {
                    index = 8,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 250,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "披风",
                            itemLevel = 4,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        }
                    },
                    text = "森林的东边似乎有一群狗头人盘踞,农夫建议继续清理巨魔，然后寻找狗头人的踪迹。", --任务文本
                    title = "狗头人部落", -- 任务标题
                    req = { { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "狗头人", number = 12 } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "受伤的农夫",
                    level = 3
                },
                {
                    index = 9,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "戒指",
                            itemLevel = 4,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 250,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "狗头人只是狗头人部落最基础的力量，消灭狗头人部落的精英，狗头人战士和狗头人术士", --任务文本
                    title = "狗头人部落", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "狗头人战士", number = 6 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "狗头人术士", number = 6 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "受伤的农夫",
                    level = 3
                },
                {
                    index = 10,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "项链",
                            itemLevel = 5,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "是时候消灭狗头人部落的领主了，他在部落的最深处，是一个体型巨大的狗头人", --任务文本
                    title = "狗头人部落", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "狗头人领主", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "受伤的农夫",
                    level = 3
                },
                {
                    index = 11,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = false,
                            fitClass = { "狂暴战", "战斗贼", "恶魔猎手" },
                            itemName = "单手斧",
                            itemLevel = 8,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 2
                        },
                        {
                            fitAllClass = false,
                            fitClass = { "武器战", "惩戒骑" },
                            itemName = "双手斧",
                            itemLevel = 8,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        },
                        {
                            fitAllClass = false,
                            fitClass = { "火法", "毁灭术", "痛苦术", "星辰法师" },
                            itemName = "法杖",
                            itemLevel = 8,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        },
                        {
                            fitAllClass = false,
                            fitClass = { "射击猎" },
                            itemName = "弓",
                            itemLevel = 8,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "勇士们辛苦了，村长在找你们", --任务文本
                    title = "再次拜访村长", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 3
                },
                {
                    index = 12, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "强大的实力是对抗魔物的第一要素，村子的东南角有一个熔炉（新手村传送点的右边，铁匠的身边），尝试用熔炉来强化一次装备", --任务文本
                    title = "第一次强化装备", -- 任务标题
                    req = { { type = QUEST_CUSTOM_EXECUTE_TYPE.QIANGHUA, name = "任意目标", number = 1 } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 5
                },
                {
                    index = 13, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "强化可以增加装备的基础属性（白字），但是无法增幅装备的绿色属性。尝试使用精炼来增幅装备的词条属性吧。（只有蓝色以及以上装备才有词条），精炼也是在熔炉进行。", --任务文本
                    title = "第一次精炼装备", -- 任务标题
                    req = { { type = QUEST_CUSTOM_EXECUTE_TYPE.JINGLIAN, name = "任意目标", number = 1 } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 5
                },
                {
                    index = 14, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "你已经学会了通过强化和精炼装备来提升战斗力。提升全身装备的强化和精炼还可以触发套装效果，进一步增强英雄的实力。猎人阿普在村子东南方等你，他需要你的帮助。", --任务文本
                    title = "猎人阿普", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "猎人阿普",
                    level = 10
                },
                {
                    index = 15,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 250,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "冒险者们，你们终于来了！请先帮忙清理一下周围的熊怪，之后我们可以讨论下一步行动。", --任务文本
                    title = "消灭熊怪", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "熊怪", number = 10 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "熊怪战士", number = 5 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "猎人阿普",
                    level = 11
                },
                {
                    index = 16,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "头盔",
                            itemLevel = 10,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 250,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "你们动作真快。看到旁边的熊怪领主了吗，请帮忙消灭他。另外我听说熊怪领主收藏有野蛮锁甲，听说铁匠在找这件物品。", --任务文本
                    title = "熊怪领主", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "熊怪领主", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "猎人阿普",
                    level = 12
                },
                {
                    index = 17,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "衣服",
                            itemLevel = 12,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 250,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text =
                    "干得不错，冒险者们。接下来我们有一件大任务。森林深处最近变得特别不安宁，我们怀疑是森林狼们沾染了魔物的气息。冒险者们，请帮助我们探查一下森林深处。请注意，森林深处的魔物特别凶猛，请一定注意安全。", --任务文本
                    title = "丛林深处", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "野狼", number = 2 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "猎人阿普",
                    level = 12
                },
                {
                    index = 18, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "这些魔物的威胁程度还在我的预料之上。请回去找村长，他或许有一些方法能增强你们的实力。", --任务文本
                    title = "返回村子", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 13
                },
                {
                    index = 19, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "如果想要进一步提升实力，长期的话可以通过大量击杀魔物获取魔物图鉴。在此过程中，别忘了找铁匠接取历练任务。短期的话可以通过炼金来提升实力。请去找炼金学徒瑞克吧。", --任务文本
                    title = "炼金术", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "药剂学徒瑞克",
                    level = 13
                },
                {
                    index = 20,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 250,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text =
                    "冒险者们，我听说了你们的事迹。炼金术可以制作药水来提供强大的实力增幅，但是缺点是药水制作需要草药，并且药水的持续时间有限。我们先从准备材料开始,先去村子外面采集两朵银叶草吧，村口农夫旁边就有草药。", --任务文本
                    title = "采集草药", -- 任务标题
                    req = { { type = QUEST_CUSTOM_EXECUTE_TYPE.CAIYAO, name = "银叶草", number = 1 } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "药剂学徒瑞克",
                    level = 13
                },
                {
                    index = 21,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 250,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "很好，我们先用银叶草制作一瓶初级生命恢复药剂。这种药剂能增加生命恢复速度，可以有效的提高与魔物战斗时的安全性。请在打开F3界面，转到专业界面，点击炼金界面，点击左键来制造药水。", --任务文本
                    title = "初级生命恢复药剂", -- 任务标题
                    req = { { type = QUEST_CUSTOM_EXECUTE_TYPE.LIANJIN, name = "基础生命恢复药剂", number = 1 } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "药剂学徒瑞克",
                    level = 14
                },
                {
                    index = 22, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "炼金还能制作很多其它的药剂和药水。你可以慢慢研究，现在，请去找猎人阿普吧。", --任务文本
                    title = "实力提升", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "猎人阿普",
                    level = 15
                },
                {
                    index = 23,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "冒险者们，看来你们已经找到了提升实力的方法。是时候去消灭丛林深处的魔物了。", --任务文本
                    title = "实力提升", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "野狼", number = 9 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英野狼", number = 2 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "铁狼", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "猎人阿普",
                    level = 16
                },
                {
                    index = 24,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "鞋子",
                            itemLevel = 17,
                            itemPinzhi = ZHUANGBEI_PINZHI.PUTONG,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "你竟然消灭了铁狼。真厉害！丛林深处最恐怖的魔物是一头狼王，不知道现在它进化成什么样子了。请消灭银月狼王。", --任务文本
                    title = "实力提升", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英野狼", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "巨狼", number = 2 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "银月狼王", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "猎人阿普",
                    level = 17
                },
                {
                    index = 25, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "猎人手套",
                            itemLevel = 18,
                            itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "谢谢你们，希望森林可以暂时恢复宁静。这是我打猎多年用的手套，送给你们了。希望你们会喜欢。", --任务文本
                    title = "实力提升", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "猎人阿普",
                    level = 18
                },
                {
                    index = 26, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "怎么样，手套不错吧。再次感谢你们，请回去找村长告知这个好消息吧。", --任务文本
                    title = "实力提升", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 18
                },
                {
                    index = 27, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "欢迎你们回来，冒险者们。谢谢你们的帮助，村子外的魔物密度降低了很多。听说村子外面北方的月亮湖周围出现了很多鱼人，快去看看吧。", --任务文本
                    title = "克文的困扰", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "克文",
                    level = 18
                },
                {
                    index = 28,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 250,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "冒险者们，你们终于来了。我早已听说你们的事迹。附近有太多鱼人了，请帮忙处理一下吧。", --任务文本
                    title = "清理鱼人", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鱼人", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鱼人猎手", number = 8 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鱼人法师", number = 8 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "克文",
                    level = 18
                },
                {
                    index = 29,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "你们动作真快。看到那个巨大的鱼人了吗？你可以帮忙消灭鱼人领主吗。", --任务文本
                    title = "清理鱼人", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鱼人领主", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "克文",
                    level = 18
                },
                {
                    index = 30,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "鱼人简直太多了，根本杀不完。我们需要从根源上解决问题。请回去找村长商量下一步行动。", --任务文本
                    title = "鱼人泛滥的原因", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 19
                },
                {
                    index = 31,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "鱼人泛滥的原因可能出在月亮湖。冒险者们，请你们前往月亮湖探究一下。月亮湖就在村外的西北角。", --任务文本
                    title = "探索月亮湖", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鱼人精英战士", number = 2 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 20
                },
                {
                    index = 32, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "看来问题确实出在月亮湖。根据你们的描述，月亮湖的鱼人变得非常凶猛，并且深处还出现了九头蛇的身影。这将是一场硬仗。在出发前，请去找铁匠学习下磨刀石的制作。", --任务文本
                    title = "探索月亮湖", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "铁匠哈特",
                    level = 20
                },
                {
                    index = 33,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "磨刀石是锻造的产物。使用磨刀石可以短时间内提升武器的伤害，或者其它效果。先去寻找铁矿，并制作一个初级锋利磨刀石吧。", --任务文本
                    title = "磨刀石", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.DUANZAO, name = "初级锋利磨刀石", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.DUANZAO, name = "初级厚重磨刀石", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "铁匠哈特",
                    level = 20
                },
                {
                    index = 34,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "很好，尝试使用磨刀石吧。磨刀石虽然是消耗品，但是它带来的增益可以不容小觑的。你可以回去找村长了。", --任务文本
                    title = "磨刀石", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 20
                },
                {
                    index = 35, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "看来你获得了提升实力的方法，接下来去找克文吧，他会指引下一步行动。", --任务文本
                    title = "返回克文", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "克文",
                    level = 20
                },
                {
                    index = 36,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "是时候查清月亮湖异动的原因了。请帮忙清理月亮湖里的魔物。", --任务文本
                    title = "开荒月亮湖", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "绿鳞", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鱼人精英战士", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鱼人精英猎手", number = 12 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "克文",
                    level = 21
                },
                {
                    index = 37,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "干的不错，接下来继续清理魔物吧，消灭鱼人法师：黑鳞", --任务文本
                    title = "开荒月亮湖", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "黑鳞", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鱼人精英法师", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鱼人精英猎手", number = 12 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "克文",
                    level = 21
                },
                {
                    index = 38,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "你们动作真快。现在轮到最后的九头蛇了，去消灭它吧，魔物暴动的源头或许就来自于它", --任务文本
                    title = "九头巨蛇", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "银鳞", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鱼人精英战士", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鱼人精英法师", number = 12 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "克文",
                    level = 21
                },
                {
                    index = 39, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 250,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "你们成功了！请收下我最真挚的感谢，尊敬的冒险者们。请你们把这个好消息告诉村长吧。", --任务文本
                    title = "凯旋", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 22
                },
                {
                    index = 40, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "你们回来了，我代表整个村子感谢你们。你们已经足够强大了，可以去王城闯荡了，王城就在村外的东北方向，你去找我的老朋友历史学家埃尔文吧，他会继续指引你们", --任务文本
                    title = "凯旋", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "历史学家埃尔文",
                    level = 23
                },
                {
                    index = 41,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text =
                    "冒险者们，我已经知道了你们的故事，王城最近正在遭遇大变，但是以你们目前的水平，可能帮不上忙。但是这里有一些其它任务，你们或许可以帮忙。想必你们也见到了来时路上的豺狼和盗贼，请帮忙清理一下豺狼人吧。", --任务文本
                    title = "清剿豺狼人", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "豺狼领主", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "豺狼战士", number = 10 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "豺狼人", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "历史学家埃尔文",
                    level = 24
                },
                {
                    index = 42,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "很好，接下来是土匪和盗贼。", --任务文本
                    title = "清剿土匪", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "土匪", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "强盗", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "刺客", number = 10 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "历史学家埃尔文",
                    level = 25
                },
                {
                    index = 43,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "你们证明了你们的能力。王城的监狱最近发生了暴动，一群暴徒劫持了监狱并将其当成了大本营。你们可以帮忙让这些人安分一些吗？", --任务文本
                    title = "暴徒洛克", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英土匪", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英强盗", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "暴徒洛克", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "历史学家埃尔文",
                    level = 26
                },
                {
                    index = 44,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "很好，监狱里还有一个首领级的角色，手上沾满了献血，你们去消灭他吧。", --任务文本
                    title = "屠杀者霍克", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英土匪", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英强盗", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "屠杀者霍克", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "历史学家埃尔文",
                    level = 27
                },
                {
                    index = 45,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "接下来是范克瑞夫，曾经的叛军首领，现在的监狱之王。", --任务文本
                    title = "监狱之王", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英土匪", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英强盗", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "监狱之王范克瑞夫", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "历史学家埃尔文",
                    level = 28
                },
                {
                    index = 46, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    --attr = {{"quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY}}, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "好样的，你是我见过成长最快的冒险者。王城需要你这样的人。请去皇宫找城主约翰吧，他会告诉你这次大变更多的细节。", --任务文本
                    title = "城主约翰", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "城主约翰",
                    level = 29
                },
                {
                    index = 47, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    --attr = {{"quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY}}, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "我们的家园正在遭受严重的威胁。曾经王城最重要的军队，血色军，竟然叛变了。我需要能力出色的人来找出原因。你们先去找军需处长谭恩吧，他会给你安排一些任务。", --任务文本
                    title = "军需处长谭恩", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "军需处长谭恩",
                    level = 30
                },
                {
                    index = 48,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "你们通过了考验，是时候知道更多细节了。原本坚定拥护城主的血色军竟然叛变了。现在城外充斥着翻盘的血色军。冒险者们，你们可以帮忙阻挡一下反叛军进攻的节奏吗？", --任务文本
                    title = "血色军的反叛", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "游荡的血色军剑士", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "游荡的血色军卫士", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "游荡的血色军法师", number = 30 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "军需处长谭恩",
                    level = 30
                },
                {
                    index = 49,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "很好，我们暂时挡住了敌人的攻势。接下来我们需要找机会反击。血色军在外面的最高指挥官是血色军下士，你们懂得，从他那获取一些血色军的信息吧，为以后的反攻做准备。", --任务文本
                    title = "血色军的信息", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "血色军下士", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "军需处长谭恩",
                    level = 30
                },
                {
                    index = 50, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "根据下士提供的情况，血色军目前集结在血色军大营，那可不是一个安全的地方，先去找附魔大师加夫里尔学习一下附魔的技巧吧", --任务文本
                    title = "附魔大师", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "附魔大师加夫里尔",
                    level = 31
                },
                {
                    index = 51, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "你们来了。附魔可以给装备附加属性或者特效，使装备变得更加强大。先制作一个初级闪避附魔卷轴吧。", --任务文本
                    title = "附魔大师", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FUMO,
                            name = "初级闪避",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "附魔大师加夫里尔",
                    level = 31
                },
                {
                    index = 52, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "干的不错，附魔卷轴可以使用，对装备栏第一格装备进行强化。请注意不同附魔卷轴能附魔的装备部位不同。接下来去拜访制皮大师吧，他会教会你们如何制作护甲片。", --任务文本
                    title = "制皮大师莱瑟", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "制皮大师莱瑟",
                    level = 32
                },
                {
                    index = 53, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "制皮专业除了可以制作皮具之外，还可以制作护甲片，护甲片可以强化护甲装备。作为出发学，从制作一个轻盈护甲片开始吧。", --任务文本
                    title = "制皮大师莱瑟", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.ZHIPI,
                            name = "轻盈护甲片",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "制皮大师莱瑟",
                    level = 32
                },
                {
                    index = 54, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "好了，去找裁缝大师吧。", --任务文本
                    title = "裁缝大师马斯特", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "裁缝大师马斯特",
                    level = 32
                },
                {
                    index = 55, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "裁缝可以制作不同的刺绣，能提供强大的特效。学习制作一个灵敏刺绣吧。", --任务文本
                    title = "裁缝大师马斯特", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.CAIFENG,
                            name = "灵敏刺绣",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "裁缝大师马斯特",
                    level = 32
                },
                {
                    index = 56, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "你们已经掌握了我们几个老家伙的看家本领，回去找城主约翰接手下一步指引吧。", --任务文本
                    title = "实力增强", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "城主约翰",
                    level = 32
                },
                {
                    index = 57, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "你们变强了。去找王城总教头吧，他会给你们商量进攻血色军的计划。他在城外北边靠近城墙处训练士兵。", --任务文本
                    title = "王城总教头", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "王城总教头",
                    level = 32
                },
                {
                    index = 58,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "冒险者们，你们来的正好，我们正打算和血色军决一死战。既然你们来了，突袭血色军大营的任务就交给你们了。", --任务文本
                    title = "突袭血色军大营", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "训犬大师杜兰", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "血色军卫士", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "血色军剑士", number = 12 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "王城总教头",
                    level = 33
                },
                {
                    index = 59,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "干的不错，赫洛德是血色军第一勇士，去消灭他吧。他一直在血色军大营守护那对狗男女。", --任务文本
                    title = "突袭血色军大营", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "血色勇士赫罗德", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "血色军卫士", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "血色军剑士", number = 12 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "王城总教头",
                    level = 34
                },
                {
                    index = 60,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "我们就差最后一步了，前往血色军大营消灭血色军统帅莫格莱尼和大检察官迈恩吧！", --任务文本
                    title = "决战血色军大营", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "血色军统帅莫格莱尼", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "大检察官迈恩", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "血色军法师", number = 12 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "王城总教头",
                    level = 35
                },
                {
                    index = 61, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "背叛者终于死了，你是我们的英雄！快去告诉城主这个好消息吧", --任务文本
                    title = "凯旋", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "城主约翰",
                    level = 36
                },
                {
                    index = 62, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = false,
                            fitClass = { "狂暴战", "战斗贼", "恶魔猎手" },
                            itemName = "单手剑",
                            itemLevel = 36,
                            itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                            count = 2
                        },
                        {
                            fitAllClass = false,
                            fitClass = { "武器战", "惩戒骑" },
                            itemName = "双手剑",
                            itemLevel = 36,
                            itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                            count = 1
                        },
                        {
                            fitAllClass = false,
                            fitClass = { "火法", "毁灭术", "痛苦术", "星辰法师" },
                            itemName = "法杖",
                            itemLevel = 36,
                            itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                            count = 1
                        },
                        {
                            fitAllClass = false,
                            fitClass = { "射击猎" },
                            itemName = "弓",
                            itemLevel = 36,
                            itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "干的不错，冒险者们。这是对你们的奖励，请接受吧", --任务文本
                    title = "凯旋", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "城主约翰",
                    level = 36
                },
                {
                    index = 63, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "根据前方的战报，血色军是受到了圣光主教的蛊惑而背叛的。到底是什么样的东西能使得我最好的朋友背叛我！冒险者们，你们可以帮忙探查一下吗？去找资深牧师萨缪尔，他知道更多关于圣光大教堂的信息。", --任务文本
                    title = "血色军的背叛", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "资深牧师萨缪尔",
                    level = 37
                },
                {
                    index = 64,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "你们来了，我听说了圣光大教堂的事。真没想到，昔日拥有崇高品德的圣光主教竟然会做出这种事情。我们有一个卧底在圣光教堂附近，去找他吧，顺便清理路上的叛军。", --任务文本
                    title = "血色军的背叛", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "反叛军步卒", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "反叛军牧师", number = 30 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "王牌卧底德尼尔",
                    level = 38
                },
                {
                    index = 65,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "相信你们的看到了，圣光大教堂周围已经一片废墟，这是我从来没有见到过的力量。你们能帮忙击杀几只右边的怪物吗？", --任务文本
                    title = "废墟", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "低等缝合怪", number = 12 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "王牌卧底德尼尔",
                    level = 39
                },
                {
                    index = 66,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "这种浓郁的死气和圣光大教堂的能量完全相反，不知道是怎么共存的。不过不重要了，既然圣光教堂背叛了城主，那么就让我们来消灭他们吧。", --任务文本
                    title = "进军圣光大教堂", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "裁判长萨提斯", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "教堂近卫军", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "教堂牧师", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "王牌卧底德尼尔",
                    level = 40
                },
                {
                    index = 67,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "裁判长是个死脑经，只知道忠于主教，不会知道太多。看来我们还要继续深入。", --任务文本
                    title = "进军圣光大教堂", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "完美腐败缝合怪", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "试验腐败缝合怪", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "王牌卧底德尼尔",
                    level = 41
                },
                {
                    index = 68,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "这是什么怪物，简直闻所未闻，可惜不能沟通。所有的问题只能找主教才能问清楚了", --任务文本
                    title = "圣光主教布莱克安", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "圣光主教布莱克安", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "教堂近卫军", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "教堂牧师", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "王牌卧底德尼尔",
                    level = 42
                },
                {
                    index = 69, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "原来这种死亡之力来自于遥远的北方，我们暂时没有办法知道更多信息了。把这里的消息报给城主吧。", --任务文本
                    title = "死亡之力", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "城主约翰",
                    level = 42
                },
                {
                    index = 70, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "看来我们需要向北方深入来找出问题的源头。冒险者们，我们的北伐军队目前在灼热峡谷，去找守备官斯通哈特吧。", --任务文本
                    title = "守备官斯通哈特", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 43
                },
                {
                    index = 71,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "你们来了，冒险者们，你们的事迹已经传遍了整个北伐军。我们正好遇到了一点，小麻烦。去往北方的路上充满了魔物，我们的战士疲于应付，你们可以帮忙消灭路上的半人马吗？", --任务文本
                    title = "清理半人马", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马苦工", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马弓箭手", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马刺客", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 44
                },
                {
                    index = 72,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "谢谢你们，但是还不够，请再帮忙清理更多的人马吧", --任务文本
                    title = "清理半人马", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马先知", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马先行者", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 45
                },
                {
                    index = 73,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "好样的，不过听说最近峡谷中又来了一批鹰身人，就看你们的了。", --任务文本
                    title = "清理鹰身人", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鹰身女妖侦察者", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鹰身女妖", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 46
                },
                {
                    index = 74,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "接下来要找到人马首领，或许可以知道为什么人马们要阻挠我们的北伐。", --任务文本
                    title = "人马首领", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马领主", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 47
                },
                {
                    index = 75,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "人马领主竟然只是一个小头目，根据你们带来的线索，峡谷深处还有一个半人马的大本营，去试试他们的斤两吧。", --任务文本
                    title = "半人马营地", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马精英勇士", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马精英弓箭手", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "快刀手迅蹄", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 48
                },
                {
                    index = 76,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "继续深入吧。", --任务文本
                    title = "半人马营地", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马精英勇士", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马精英弓箭手", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马弓神布鲁斯", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 49
                },
                {
                    index = 77,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "消灭人马酋长战争之蹄，这个老家伙才是发号施令的源头。", --任务文本
                    title = "半人马营地", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马精英勇士", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马精英弓箭手", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马酋长战争之蹄", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 50
                },
                {
                    index = 78, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "这里的事情告一段落了，但是我们遇到的新的麻烦，黑铁矮人一族在峡谷中部有一个据点，他们不知道为何一直在攻击我们，既然这样，那我们也不能客气，给他们点颜色看看吧。", --任务文本
                    title = "黑铁矮人一族", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "黑铁矮人守卫", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "黑铁矮人枪手", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "黑铁矮人矿工", number = 30 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 51
                },
                {
                    index = 79,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "这帮矮人的老巢在矿场深处，他们竟然修建了一个地下城，看来我们不得不深入来调查了。", --任务文本
                    title = "矮人地下城", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英黑铁矮人矿工", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英黑铁矮人守卫", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "矮人守卫队长杜尼尔", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 52
                },
                {
                    index = 80,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "干得好，继续深入吧。", --任务文本
                    title = "矮人地下城", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英黑铁矮人枪手", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英黑铁矮人守卫", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "嗜血的格洛格", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 53
                },
                {
                    index = 81,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "最后一步，找到黑铁矮人索瑞森大帝，让他看看我们的厉害。", --任务文本
                    title = "黑铁矮人索瑞森大帝", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英黑铁矮人枪手", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英黑铁矮人守卫", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "黑铁矮人索瑞森大帝", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 54
                },
                {
                    index = 82, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text =
                    "根据消息，黑铁矮人是迫于峡谷深处的压力才来对付我们的。真是有意思，我们之前没有来过这里，为什么会引起对方的敌意。看来要通过峡谷去往北方，我们不得不和峡谷的老大们打交道了。去找钓鱼大师派罗，他对这里可是很熟悉，他一般会在峡谷中部钓鱼。", --任务文本
                    title = "峡谷深处", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "钓鱼大师派罗",
                    level = 55
                },
                {
                    index = 83, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = {},  --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text =
                    "我知道了你们的来意。我确实知道一些峡谷的故事，灼热峡谷沉睡着许多远古生物，包括火山深处的炎魔和不远处的黑龙王子，如果北伐大军想通过这里，必须要和这些生物打交道。当然，远古生物打交道的方式就是打架，你们行吗？先从说服炎魔开始吧。", --任务文本
                    title = "峡谷深处", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "火元素", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "石元素", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "炎巨人", number = 30 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "钓鱼大师派罗",
                    level = 56
                },
                {
                    index = 84,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "外面这些小喽啰不值一提，峡谷西南角可以通往火焰之心，炎魔的老巢就在那里。去和他们打声招呼吧。", --任务文本
                    title = "火焰之心", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英石元素", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英火元素", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "嘉尔", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "钓鱼大师派罗",
                    level = 57
                },
                {
                    index = 85,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "继续。", --任务文本
                    title = "火焰之心", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英石元素", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英火元素", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "嘉顿", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "钓鱼大师派罗",
                    level = 58
                },
                {
                    index = 86,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "再接再厉。", --任务文本
                    title = "火焰之心", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英炎巨人", number = 8 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英火元素", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "焚化者古曼", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "钓鱼大师派罗",
                    level = 59
                },
                {
                    index = 87,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "好了，是时候见正主了，他就在火焰之心的最深处，去和他好好聊聊吧。", --任务文本
                    title = "火焰之心", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英石元素", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英炎巨人", number = 8 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "炎魔之王", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "钓鱼大师派罗",
                    level = 60
                },
                {
                    index = 88,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "干的不错，我们只要再和黑龙聊聊，问题应该就能解决了。", --任务文本
                    title = "黑龙巢穴", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "黑龙王子", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "钓鱼大师派罗",
                    level = 60
                },
                {
                    index = 89,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "现在没有人能阻挡你们了，快去告诉斯通哈特这个好消息。", --任务文本
                    title = "完成任务", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 60
                },
                {
                    index = 90,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "冒险者们，你们再次证明了你们的实力，我代替北伐军由衷的感谢你们。接下来我们需要通过峡谷西边的通道前往下一个地方，谁也不知道我们会遇到什么。", --任务文本
                    title = "新的征程", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "受伤的小黑子",
                    level = 60
                },
                {
                    index = 91,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "你们好，我是小黑子，看到前面的残暴兽人了吗？他们要害我，你们想知道更多信息的话先帮我教训教训野蛮卫兵", --任务文本
                    title = "帮小黑子出气", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "野蛮卫兵", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "受伤的小黑子",
                    level = 60
                },
                {
                    index = 92,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "我看野蛮卫兵很不顺眼，你能帮忙再消灭20个吗？", --任务文本
                    title = "帮小黑子出气", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "野蛮卫兵", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "受伤的小黑子",
                    level = 60
                },
                {
                    index = 93,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "哈哈，干的好，我现在可以告诉你这是什么地方。这里是纷争之地，无数的势力再这里扎堆，比如说…… 你再帮我教训下狂暴卫兵吧", --任务文本
                    title = "帮小黑子出气", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "狂暴卫兵", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "受伤的小黑子",
                    level = 60
                },
                {
                    index = 94,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "嘿嘿，我们接着说，纷争之地有很多势力，距离这里最近的就是邪兽人势力，他们在这里无恶不作，霸占了好大一块地，据说还和远古巨兽搭上了关系。而且 …… 你再帮我教训下射手卫兵吧", --任务文本
                    title = "帮小黑子出气", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "射手卫兵", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "受伤的小黑子",
                    level = 60
                },
                {
                    index = 95,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text =
                    "真解气，哈哈。什么？你让我介绍下别的势力？额……其实我也是刚来的，知道的也不多，不过我知道哪里可以得到更多信息。沿着这条路往东就是纷争之地的主城，和平之城，那里有一位远古生物坐镇，是整个纷争之地最安全的地方，你们可以去那里碰碰运气。", --任务文本
                    title = "和平之城", -- 任务标题
                    req = {
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "纳鲁",
                    level = 61
                },
                {
                    index = 96,                                                  --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text =
                    "你们好，外来者们。欢饮你们来到和平之城。你们可以在这里放心的休息然后想回去的时候就回去吧。什么？你们想通过这里前往北方？这可不是一件简单的事情。开启通往北方的传送阵需要整个纷争之地齐心合力，而这根本不肯能实现。你们不信的话先去找兽人老兵火刃了解下纷争之地的历史。", --任务文本
                    title = "和平之城", -- 任务标题
                    req = {
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "兽人老兵火刃",
                    level = 61
                },
                {
                    index = 97,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text =
                    "你们是？纳鲁让你们来找我的？好吧，我知道了。你们想知道如何让纷争之地的势力团结起来，嘿嘿，这事说起来很难，但是也可以很简单。你们只是想让这帮暴徒贡献资源和力量的话，那最简单的办法就是以力服人了，懂？你们真有心的话可以先试试左边的破碎大厅吧，里面是邪兽人的大本营。", --任务文本
                    title = "破碎大厅", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英射手卫兵", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英野蛮卫兵", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "高阶术士", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "兽人老兵火刃",
                    level = 62
                },
                {
                    index = 98,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text =
                    "不错不错，继续深入吧", --任务文本
                    title = "破碎大厅", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英狂暴卫兵", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英野蛮卫兵", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "战争使者", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "兽人老兵火刃",
                    level = 62
                },
                {
                    index = 99,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text =
                    "挑战兽人酋长吧", --任务文本
                    title = "破碎大厅", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英狂暴卫兵", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英射手卫兵", number = 12 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "酋长卡加斯·刃拳", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "兽人老兵火刃",
                    level = 62
                },
                {
                    index = 100,                                                 --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text =
                    "你们已经成功拉拢了一个势力，不过邪兽人只能算纷争之地最弱的势力，他们的仰仗是纷争之地西南方的戈隆一族，相比你们已经见识过了。", --任务文本
                    title = "说服戈隆", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "戈隆", number = 21 },
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "兽人老兵火刃",
                    level = 62
                },
                {
                    index = 101,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text =
                    "屠龙者格鲁是戈隆一族的领袖，他已经存在了不知道多少年，你们要是能说服它，我就说服纳鲁来帮你们", --任务文本
                    title = "说服屠龙者格鲁", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "屠龙者格鲁", number = 1 },
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "兽人老兵火刃",
                    level = 63
                },
                {
                    index = 102,                                                 --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text =
                    "你们的实力说服了我，带上我的信回去找纳鲁吧。", --任务文本
                    title = "返回和平之城", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "纳鲁",
                    level = 64
                },
                {
                    index = 103,                                                 --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "看来纷争之地的局势要改变了，你们既然已经说服了邪兽人和戈隆一族，那么在和平之城西北方向的邪恶法师势力就是下一个目标，去找瑞斯吧。", --任务文本
                    title = "出发，法师塔", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "法师叛徒瑞斯",
                    level = 64
                },
                {
                    index = 104,                                                 --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "我知道你们的来意，我简直太开心了，终于有人制裁这帮疯子了。先消灭周围的法师塔杂兵吧。", --任务文本
                    title = "法师塔的毁灭", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "法师塔法师", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "法师塔术士", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "法师塔卫士", number = 30 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "法师叛徒瑞斯",
                    level = 64
                },
                {
                    index = 105,                                                 --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "好了，我们只要小面旁边这个看门的就能进入法师塔了", --任务文本
                    title = "法师塔的毁灭", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "荣誉护卫木羽", number = 1 },
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "法师叛徒瑞斯",
                    level = 65
                },
                {
                    index = 106,                                                 --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "我们开始吧。先消灭法师塔管家莫罗，注意他会召唤一堆护卫", --任务文本
                    title = "法师塔的毁灭", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "法师塔精英法师", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "法师塔精英术士", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "莫罗", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "法师叛徒瑞斯",
                    level = 65
                },
                {
                    index = 107,                                                 --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "接下来是馆长，馆长负责看管图书馆，它具有强大的防御力，注意一定要在它唤醒的时候对他造成伤害", --任务文本
                    title = "法师塔的毁灭", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "法师塔精英法师", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "法师塔精英术士", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "图书馆馆长", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "法师叛徒瑞斯",
                    level = 65
                },
                {
                    index = 108,                                                 --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "接下来是夜之靥，这个骨龙是法师塔邪恶试验的产物，你们一定要小心", --任务文本
                    title = "法师塔的毁灭", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "法师塔精英法师", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "法师塔精英术士", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "夜之魇", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "法师叛徒瑞斯",
                    level = 65
                },
                {
                    index = 109,                                                 --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "最后是大法师埃兰，虽然我恨他，但是也不得不承认他强大的魔法实力，他的看家本领是烈焰火环和奥爆术，一定要防止这俩技能在靠近的时机释放。", --任务文本
                    title = "法师塔的毁灭", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "法师塔精英法师", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "法师塔精英术士", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "大法师埃兰", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "法师叛徒瑞斯",
                    level = 65
                },
                {
                    index = 110,                                                 --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "感谢你们，帮我报仇了，哈哈哈哈哈哈哈哈哈哈。你们可以回去找纳鲁告知这里的情况了", --任务文本
                    title = "返回和平之城", -- 任务标题
                    req = {
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "纳鲁",
                    level = 66
                },
                {
                    index = 111,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text = "冒险者们，你们回来了。我有些不好的消息要告诉你们。和平之城东边的血精灵们最近变得蠢蠢欲动，我担心他们可能在策划什么。能否请你们去打探一下情况？",
                    title = "血精灵的动向",
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "纳鲁",
                    level = 67
                },
                {
                    index = 112,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text = "血精灵的领地戒备森严。我们需要清理一些外围的护卫才能深入调查。请消灭一些要塞护卫军士、虚空占卜者和要塞斥候。",
                    title = "清理外围",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "要塞护卫军士", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "虚空占卜者", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "要塞斥候", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "纳鲁",
                    level = 68
                },
                {
                    index = 113,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 400,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text = "外围的护卫已经被清理，但我们还需要更多信息。有传言说要塞护卫军士长掌握着重要情报。去找到他，从他那里获取我们需要的信息。",
                    title = "军士长的秘密",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "要塞护卫军士长", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "纳鲁",
                    level = 69
                },
                {
                    index = 114,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text = "从军士长那里获得的情报令人震惊。血精灵们正在一个叫做风暴要塞的地方集结力量。我们必须阻止他们的阴谋！请前往风暴要塞，击败那里的守卫。",
                    title = "进军风暴要塞",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英要塞护卫军士", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英虚空占卜者", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英要塞斥候", number = 30 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "纳鲁",
                    level = 70
                },
                {
                    index = 115,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 1000,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text = "勇敢的冒险者们，你们已经成功潜入了风暴要塞。现在是时候面对真正的挑战了。奥、大星术师和凯尔萨斯·逐日者是这个阴谋的核心人物。击败他们，粉碎血精灵的野心！",
                    title = "挫败阴谋",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "奥", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "大星术师", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "凯尔萨斯·逐日者", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "纳鲁",
                    level = 70
                },
                {
                    index = 116,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text =
                    "和平之城的守护者纳鲁感受到了来自东方的不祥之兆。黑暗的力量正在悄然蔓延，威胁着这片土地最后的希望。作为新崛起的英雄，你被召唤来调查这个可能改变世界命运的危机。前往东方，揭开这个神秘威胁的面纱。",
                    title = "黑暗的预兆",
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "护卫队长彼得",
                    level = 70
                },
                {
                    index = 117,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text =
                    "东边的恶魔荒地已被邪恶力量侵蚀，成群的恶魔在此肆虐。这些生物似乎被一股强大的黑暗力量所驱使。勇士啊，踏入这片被诅咒的土地，斩杀这些邪恶生物，寻找背后隐藏的真相！",
                    title = "邪恶的踪迹",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "黑暗术士", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "恶魔卫士", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "恶魔女妖", number = 10 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "护卫队长彼得",
                    level = 70
                },
                {
                    index = 118,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text =
                    "经过浴血奋战，你从被击败的恶魔身上发现了惊人的线索，指向一个名为黑暗神殿的禁忌之地。这座古老的建筑可能是一切邪恶的源头。英勇的冒险者，是时候深入敌穴，发现这个威胁整个世界的黑暗秘密了！",
                    title = "黑暗神殿的阴影",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "神殿恶魔卫士", number = 10 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "护卫队长彼得",
                    level = 70
                },
                {
                    index = 119,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text =
                    "站在黑暗神殿的入口，你能感受到其中散发出的邪恶气息。无数生命在其中哀嚎，无数灵魂在其中挣扎。勇士啊，现在是时候展现你的勇气和力量，强行闯入这个邪恶的巢穴，发现其中隐藏的可怕真相！",
                    title = "闯入神殿",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "神殿黑暗术士", number = 10 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "护卫队长彼得",
                    level = 70
                },
                {
                    index = 120,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text =
                    "神殿内部比你想象的还要可怕。被腐化的生物在黑暗中游荡，邪恶的仪式在阴影中进行。每一步都可能是致命的陷阱，每一个转角都可能有新的威胁。但你必须前进，因为整个世界的命运都取决于你能否阻止这里的邪恶计划！",
                    title = "对抗邪恶",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "神殿恶魔卫士", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "神殿黑暗术士", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "护卫队长彼得",
                    level = 70
                },
                {
                    index = 121,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text =
                    "在神殿的深处，你终于与邪恶的源头——主母赫拉姆斯对峙。她正在进行一项可怕的仪式，企图释放被封印的远古之恶。这场战斗不仅关乎你的生死，更关乎整个世界的存亡。英雄啊，用你的力量终结这场疯狂的仪式，拯救这个世界！",
                    title = "主母赫拉姆斯",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "主母赫拉姆斯", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "护卫队长彼得",
                    level = 70
                },
                {
                    index = 122,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text =
                    "赫拉姆斯的陨落只是开始。随着她的束缚消失，神殿深处的力量正在苏醒。你必须继续深入，面对更强大的敌人和更可怕的挑战。每一步都可能是你的最后一步，但你知道，若不阻止这里的邪恶，整个世界都将陷入永恒的黑暗！",
                    title = "深入神殿核心",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "神殿恶魔卫士", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "神殿黑暗术士", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "护卫队长彼得",
                    level = 70
                },
                {
                    index = 123,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text =
                    "你终于来到了神殿的核心，在这里，你将面对黑暗议会——一群操纵世界命运的邪恶存在。玛兰德女士、粉碎者加西奥斯、高阶虚空术士塞雷巴和维拉斯·黑暗之影，每一个都拥有毁灭世界的力量。这将是一场史诗级的战斗，胜利将让你成为传奇，失败则意味着世界的终结。",
                    title = "对抗黑暗议会",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "粉碎者加西奥斯", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "高阶虚空术士塞雷巴", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "维拉斯·黑暗之影", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "护卫队长彼得",
                    level = 70
                },
                {
                    index = 124,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 1000,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text =
                    "击败黑暗议会后，你发现了一个骇人听闻的真相：背叛者，曾经的英雄，现在是这一切邪恶的幕后黑手。他的力量远超你的想象，他的计划比你所知的更为可怕。这是你最后的，也是最艰难的战斗。胜利将带来光明，失败将使世界永坠黑暗。英雄啊，为了这个世界的未来，向命运发起最后的挑战吧！",
                    title = "背叛者的最后一战",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "背叛者", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "护卫队长彼得",
                    level = 70
                },
                {
                    index = 125,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text =
                    "背叛者倒下了，但黑暗神殿中的邪恶能量仍在肆虐。如果不彻底清除这些残余的黑暗力量，它们可能会重新聚集，再次威胁世界。英雄啊，完成你的使命，彻底净化这个曾经威胁整个世界的邪恶之地！你的每一击都将驱散黑暗，为这个世界带来新的希望。",
                    title = "肃清余孽",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "神殿恶魔卫士", number = 25 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "神殿黑暗术士", number = 25 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "护卫队长彼得",
                    level = 69
                },
                {
                    index = 126,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text =
                    "你做到了！黑暗神殿的威胁已经被彻底消除。整个世界都在庆祝你的胜利。但是，真正的英雄知道，和平来之不易，守护和平更是永无止境的使命。带着你的荣耀和责任，返回和平之城，向纳鲁报告你的胜利。你的名字将永远被铭记，你的事迹将成为传说，激励未来的勇士们继续守护这个世界。",
                    title = "凯旋归来",
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "纳鲁",
                    level = 70
                },
                {
                    index = 127,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    },
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text =
                    "纳鲁以无比崇敬的目光注视着你，称赞你拯救了整个世界。但他的眼中又闪过一丝忧虑：更大的危机可能正在酝酿。英雄啊，你的传奇才刚刚开始。休整片刻，因为更艰巨的挑战正等待着你。世界的命运再次落在你的肩上，你准备好了吗？新的冒险即将开始，而你，将再次成为这个世界的希望之光。",
                    title = "警惕新威胁",
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "纳鲁",
                    level = 70
                },
                {
                    index = 128,
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    resources = {
                        { HSHOP_COST_TYPE.gold, QUEST_JIANGLI_SCALE_TYPE.TINY },
                    },
                    shengwang = { { value = 100, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\CommandButtons\\BTNMoonArcher.blp",
                    text = "勇敢的冒险者，我们收到消息说恶魔军团正在集结力量。我需要你的帮助来削弱他们的力量。首先，我们需要清理前方的恶魔巡逻队。",
                    finishText = "你做得很好。这对削弱恶魔军团的力量非常有帮助。",
                    title = "削弱恶魔力量",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "恶魔狂战士", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "恶魔地狱火", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "末日护卫", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "纳鲁",
                    level = 70
                },
                {
                    index = 129,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } },
                    resources = {
                        { HSHOP_COST_TYPE.gold, QUEST_JIANGLI_SCALE_TYPE.SMALL },
                    },
                    shengwang = { { value = 200, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text = "我们必须阻止更多的恶魔被召唤到我们的世界里来。继续清理这些恶魔，进一步削弱他们的力量。",
                    finishText = "干得漂亮！你的行动大大削弱了恶魔军团的力量。",
                    title = "继续清理",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "末日弓箭手", number = 25 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "末日护卫", number = 25 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "纳鲁",
                    level = 70
                },
                {
                    index = 130,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } },
                    resources = {
                        { HSHOP_COST_TYPE.gold, QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                    },
                    shengwang = { { value = 300, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text = "我们需要更多的信息。深入恶魔军团的领地，寻找他们的计划。小心那些精英守卫，他们可能掌握重要情报。",
                    finishText = "你带回来的情报非常有价值。我们现在对恶魔军团的计划有了更清晰的认识。",
                    title = "深入敌后",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英末日护卫", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "纳鲁",
                    level = 70
                },
                {
                    index = 131,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } },
                    resources = {
                        { HSHOP_COST_TYPE.gold, QUEST_JIANGLI_SCALE_TYPE.SMALL },
                    },
                    shengwang = { { value = 400, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text = "太阳之井是世界上的奇迹之一，拥有强大的能量，但也是燃烧军团的目标。我们必须保护它，防止它落入恶魔手中。先去消灭布胖吧，不要小看他。",
                    finishText = "你成功了！布胖已经倒下，太阳之井暂时安全了。",
                    title = "军团恶魔领主布胖",
                    req = { { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "军团恶魔领主布胖", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英末日护卫", number = 20 } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "纳鲁",
                    level = 70
                },
                {
                    index = 132,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } },
                    resources = {
                        { HSHOP_COST_TYPE.gold, QUEST_JIANGLI_SCALE_TYPE.SMALL },
                    },
                    shengwang = { { value = 400, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text = "穆鲁原本是太阳之井的守护者，但现在他已经被恶魔腐化，成为了燃烧军团的爪牙。我们必须阻止他，否则太阳之井将彻底沦陷。",
                    finishText = "你成功了！穆鲁已经倒下，太阳之井暂时安全了。",
                    title = "虚空生物穆鲁",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "虚空生物穆鲁", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英恶魔狂战士", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "纳鲁",
                    level = 70
                },
                {
                    index = 133,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } },
                    resources = {
                        { HSHOP_COST_TYPE.gold, QUEST_JIANGLI_SCALE_TYPE.SMALL },
                    },
                    shengwang = { { value = 400, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text = "到了面对基尔加丹的时候了，他是恶魔军团的首领，也是所有恶魔的统治者。我们必须阻止他，否则太阳之井将彻底沦陷。",
                    finishText = "你成功了！基尔加丹已经倒下，太阳之井暂时安全了。你的英勇行为将被永远铭记。",
                    title = "基尔加丹",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "基尔加丹", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英恶魔地狱火", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "精英末日弓箭手", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "纳鲁",
                    level = 70
                },
                {
                    index = 134,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } },
                    resources = {
                        { HSHOP_COST_TYPE.gold, QUEST_JIANGLI_SCALE_TYPE.LARGE },
                    },
                    shengwang = { { value = 400, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp",
                    text = "你已经成功地消灭了太阳之井的威胁。你的英勇行为将被永远铭记。",
                    title = "胜利",
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "纳鲁",
                    level = 70
                },
            }
        },
        {
            name = "历练任务",
            cundangStr = "lilian",
            isPerHero = true,
            currentIndex = 1,
            questType = QUEST_TYPE.ONCE_LIFETIME,
            data = {
                {
                    index = 1, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "欢迎来到新世界, 请找到铁匠哈特来开启历练任务", --任务文本
                    title = "初来乍到", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "铁匠哈特",
                    level = 1
                },
                {
                    index = 2,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "真正的勇士需要接受血的历练。完成历练任务可以获得大量属性奖励，但是任务要求较高。接受你的第一个历练任务吧，勇士！请清理村外的巨魔，需要清理30个巨魔，10个巨魔战士，1个巨魔领主。", --任务文本
                    title = "身先士卒", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "巨魔", number = 30 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "巨魔狂战士", number = 10 },
                        --杀怪数，
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "巨魔领主", number = 2 } --杀怪数
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.immediately,
                    -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能）
                    level = 8
                },
                {
                    index = 3,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "恭喜你完成第一次历练。接下来请清理村外的狗头人和熊怪，需要清理100个狗头人，100个熊怪，50个熊怪战士", --任务文本
                    title = "身先士卒", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "狗头人", number = 40 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "熊怪", number = 40 },
                        --杀怪数，
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "熊怪战士", number = 30 } --杀怪数
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.immediately,
                    -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能）
                    level = 15
                },
                {
                    index = 4,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "很好。接下来将会是非常挑战的任务。请清理普通难度的丛林深处副本3次。", --任务文本
                    title = "身先士卒", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                            name = FUBEN_NANDU_LABEL[FUBEN_NANDU.PUTONG] .. "丛林深处",
                            number = 3
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.immediately,
                    -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能）
                    level = 18
                },
                {
                    index = 5,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "你们开挂了吧，竟然能击败英雄难度的银月狼王。北方的鱼人泛滥，你们能帮忙清理一下吗？", --任务文本
                    title = "身先士卒", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鱼人", number = 60 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鱼人战士", number = 30 },
                        --杀怪数，
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鱼人法师", number = 20 } --杀怪数
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.immediately,
                    -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能）
                    level = 18
                },
                {
                    index = 6,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "请清理英雄难度的月亮湖副本3次。", --任务文本
                    title = "身先士卒", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                            name = FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "月亮湖",
                            number = 3
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.immediately,
                    -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能）
                    level = 23
                },
                {
                    index = 7,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "请清理去往王城路上的豺狼人部落。", --任务文本
                    title = "前往王城", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "豺狼人", number = 120 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "豺狼战士", number = 60 },
                        --杀怪数，
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "豺狼领主", number = 20 } --杀怪数
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.immediately,
                    -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能）
                    level = 25
                },
                {
                    index = 8,                                                     --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "请继续清理剩下的去往王城路上的敌人。", --任务文本
                    title = "前往王城", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "强盗", number = 100 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "土匪", number = 100 },
                        --杀怪数，
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "刺客", number = 100 } --杀怪数
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.immediately,
                    -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能）
                    level = 25
                },
                {
                    index = 9,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "历史学家在寻求帮助来清理英雄难度的王城监狱。", --任务文本
                    title = "前往王城", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                            name = FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "王城监狱",
                            number = 3
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "历史学家埃尔文",
                    level = 26
                },
                {
                    index = 10,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "帮助清理血色军叛军", --任务文本
                    title = "血色叛军", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "游荡的血色军剑士", number = 120 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "游荡的血色军卫士", number = 120 },
                        --杀怪数，
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "游荡的血色军法师", number = 120 } --杀怪数
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "历史学家埃尔文",
                    level = 30
                },
                {
                    index = 11,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "历史学家在寻求帮助来清理英雄难度的血色军大营，然后找总教头吧。", --任务文本
                    title = "前往王城", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                            name = FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "血色军大营",
                            number = 3
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "王城总教头",
                    level = 32
                },
                {
                    index = 12,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "清理教堂叛军，然后找王牌间谍报道", --任务文本
                    title = "清理教堂叛军", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "反叛军步卒", number = 120 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "反叛军牧师", number = 120 },
                        --杀怪数，
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "低等缝合怪", number = 120 } --杀怪数
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "王牌卧底德尼尔",
                    level = 36
                },
                {
                    index = 13,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "帮助王牌卧底德尼尔来清理英雄难度的圣光大教堂，然后找城主约翰吧。", --任务文本
                    title = "清理圣光大教堂", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                            name = FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "圣光大教堂",
                            number = 3
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "城主约翰",
                    level = 39
                },
                {
                    index = 14,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "守备官斯通哈特需要你的帮助，他在灼热山谷，位于王城东北方向。", --任务文本
                    title = "前往灼热山谷", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 40
                },
                {
                    index = 15,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "请帮忙清理路上的人马，他们一直妨碍着我们进军峡谷深处。", --任务文本
                    title = "清理半人马", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马苦工", number = 50 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马弓箭手", number = 100 },
                        --杀怪数，
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马刺客", number = 100 } --杀怪数
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 42
                },
                {
                    index = 16,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "干的不错，再接再厉。", --任务文本
                    title = "清理半人马", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马先行者", number = 100 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "人马先知", number = 100 },
                        --杀怪数，
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "鹰身女妖", number = 100 } --杀怪数
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 44
                },
                {
                    index = 17,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "清理半人马营地来彻底解决人马的骚扰吧。", --任务文本
                    title = "半人马营地", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                            name = FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "半人马营地",
                            number = 3
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 46
                },
                {
                    index = 18,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "峡谷深处的露天矿周围聚集了很多黑铁矮人，去消灭他们吧。", --任务文本
                    title = "前往灼热山谷", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "黑铁矮人矿工", number = 100 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "黑铁矮人守卫", number = 100 },
                        --杀怪数，
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "黑铁矮人枪手", number = 100 } --杀怪数
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 50
                },
                {
                    index = 19,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "挑战英雄难度的矮人地下城，只有这样才能消灭他们阻挠我们的决心。", --任务文本
                    title = "矮人地下城", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                            name = FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "矮人地下城",
                            number = 3
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 53
                },
                {
                    index = 20,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "峡谷的西南方向最近出现了很多魔物，你懂的。", --任务文本
                    title = "前往灼热山谷", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "火元素", number = 100 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "石元素", number = 100 },
                        --杀怪数，
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "炎巨人", number = 100 } --杀怪数
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 57
                },
                {
                    index = 21,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "挑战英雄难度的火焰之心，打击炎魔之王的气焰。", --任务文本
                    title = "火焰之心", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                            name = FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "火焰之心",
                            number = 3
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 60
                },
                {
                    index = 22,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\lilian.blp", --任务图标文件
                    text = "挑战英雄难度的黑龙王子，他可不好惹，最好找一位可靠的守护者同行。", --任务文本
                    title = "黑龙王子的巢穴", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                            name = FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "黑龙王子的巢穴",
                            number = 3
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 60
                }
            }
        },
        {
            name = "日常任务",
            currentIndex = 1,
            isPerHero = false,
            cundangStr = "richangquest",
            questType = QUEST_TYPE.LIMIT_PER_CYCLE,
            cycleCundangStr = "richang",
            cycleCheckPointIndex = 1,
            dailyLimit = 1,
            data = {
                {
                    index = 1,      --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {}, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\qita.blp", --任务图标文件
                    text = "军需处长需要你帮助", --任务文本
                    title = "需要帮助", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "军需处长谭恩",
                    level = 20
                },
                {
                    index = 2, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.experience,      QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.MEDIUM, 1000000 }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "精致麻布",
                            count = 4
                        },
                        {
                            fitAllClass = true,
                            itemName = "中皮",
                            count = 4
                        }
                    },
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "上交3个轻皮和3个麻布", --任务文本
                    title = "初级剥皮制布", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "麻布",
                            number = 3
                        },
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "轻皮",
                            number = 3
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "军需处长谭恩",
                    level = 20
                },
                {
                    index = 3, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.experience,      QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.MEDIUM, 1000000 }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "金银草",
                            count = 4
                        },
                        {
                            fitAllClass = true,
                            itemName = "圣光草",
                            count = 2
                        },
                        {
                            fitAllClass = true,
                            itemName = "精铁矿石",
                            count = 4
                        }
                    },
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "请帮忙采集草药获得3株银叶草（不用上交）,采矿获得3个铁矿（不用上交）", --任务文本
                    title = "初级采矿采药", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.CAIYAO, name = "银叶草", number = 3 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.CAIKUANG, name = "铁矿石", number = 3 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "军需处长谭恩",
                    level = 20
                },
                {
                    index = 4, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,              QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.experience,        QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.gongzhenghuizhang, 5 },
                        { HSHOP_COST_TYPE.dianfengjingyan,   QUEST_JIANGLI_SCALE_TYPE.LARGE, 1000000 }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "击杀任意难度监狱，血色军大营和圣光大教堂关底boss各一次", --任务文本
                    title = "挑战地下城", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.KILL,
                            name = "监狱之王范克瑞夫",
                            number = 1
                        },
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.KILL,
                            name = "血色军统帅莫格莱尼",
                            number = 1
                        },
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.KILL,
                            name = "圣光主教布莱克安",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "军需处长谭恩",
                    level = 20
                }
            }
        },
        {
            name = "灼热峡谷日常",
            currentIndex = 1,
            isPerHero = false,
            cundangStr = "richangquest-zhuorexiagu",
            questType = QUEST_TYPE.LIMIT_PER_CYCLE,
            cycleCundangStr = "richang",
            cycleCheckPointIndex = 2,
            dailyLimit = 1,
            data = {
                {
                    index = 1,      --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {}, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\qita.blp", --任务图标文件
                    text = "守备官斯通哈特需要你帮助。", --任务文本
                    title = "需要帮助", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 48
                },
                {
                    index = 2, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.experience,      QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.MEDIUM, 2000000 }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "精致丝绸",
                            count = 4
                        },
                        {
                            fitAllClass = true,
                            itemName = "重皮",
                            count = 4
                        }
                    },
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "上交3个丝绸和3个中皮", --任务文本
                    title = "剥皮制布", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "丝绸",
                            number = 3
                        },
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "中皮",
                            number = 3
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 48
                },
                {
                    index = 3, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.experience,      QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.MEDIUM, 2000000 }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "烈焰草",
                            count = 4
                        },
                        {
                            fitAllClass = true,
                            itemName = "烈焰菇",
                            count = 2
                        },
                        {
                            fitAllClass = true,
                            itemName = "精金矿石",
                            count = 8
                        }
                    },
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "请帮忙采集草药获得3株火焰草（不用上交）,采矿获得3个精铁矿石（不用上交）", --任务文本
                    title = "采矿采药", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.CAIYAO, name = "火焰草", number = 3 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.CAIKUANG, name = "精铁矿石", number = 3 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 48
                },
                {
                    index = 4, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.experience,      QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.yongqihuizhang,  5 },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE, 2000000 }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "击杀任意半人马营地，矮人地下城关底boss各一次", --任务文本
                    title = "挑战地下城", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.KILL,
                            name = "人马酋长战争之蹄",
                            number = 1
                        },
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.KILL,
                            name = "黑铁矮人索瑞森大帝",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 48
                }
            }
        },
        {
            name = "纷争之地日常",
            currentIndex = 1,
            isPerHero = false,
            cundangStr = "richangquest-fenzhengzhidi",
            questType = QUEST_TYPE.LIMIT_PER_CYCLE,
            cycleCundangStr = "richang",
            cycleCheckPointIndex = 5,
            dailyLimit = 1,
            data = {
                {
                    index = 1,      --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {}, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\qita.blp", --任务图标文件
                    text = "纳鲁需要你的帮助", --任务文本
                    title = "需要帮助", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "纳鲁",
                    level = 65
                },
                {
                    index = 2, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.experience,      QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.MEDIUM, 6000000 }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "灵纹布",
                            count = 1
                        },
                        {
                            fitAllClass = true,
                            itemName = "结缔皮",
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "上交1个符文布和1个厚皮", --任务文本
                    title = "剥皮制布", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "符文布",
                            number = 1
                        },
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "厚皮",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "纳鲁",
                    level = 65
                },
                {
                    index = 3, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.experience,      QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.MEDIUM, 6000000 }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "绽放之血",
                            count = 2
                        },
                        {
                            fitAllClass = true,
                            itemName = "奥金矿石",
                            count = 8
                        }
                    },
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "请帮忙采集草药获得1株汲血草（不用上交）,采矿获得1个秘银矿石（不用上交）", --任务文本
                    title = "采矿采药", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.CAIYAO, name = "汲血草", number = 1 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.CAIKUANG, name = "秘银矿石", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "纳鲁",
                    level = 65
                },
                {
                    index = 4, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.experience,      QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.zhengyihuizhang, 3 },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE, 6000000 }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "和平之城"
                        }
                    },
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "煞能铁锭",
                            count = 1,
                            requirement = function(whichPlayer)
                                if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：血吼") then
                                    return true
                                else
                                    return false
                                end
                            end,
                            requirementDesc = "需要冒险者完成血吼任务线"
                        },
                        {
                            fitAllClass = true,
                            itemName = "凝练的烈日精华",
                            count = 1,
                            requirement = function(whichPlayer)
                                if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：烈焰之击") then
                                    return true
                                else
                                    return false
                                end
                            end,
                            requirementDesc = "需要冒险者完成烈焰之击任务线"
                        },
                        {
                            fitAllClass = true,
                            itemName = "黑暗魔石",
                            count = 1,
                            requirement = function(whichPlayer)
                                if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：恶魔战刃") then
                                    return true
                                else
                                    return false
                                end
                            end,
                            requirementDesc = "需要冒险者完成恶魔战刃任务线"
                        },
                        {
                            fitAllClass = true,
                            itemName = "群星之怒的残片",
                            count = 1,
                            requirement = function(whichPlayer)
                                if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：群星之怒") then
                                    return true
                                else
                                    return false
                                end
                            end,
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "击杀破碎大厅，屠龙者格鲁，法师塔关底boss各一次", --任务文本
                    title = "挑战地下城", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.KILL,
                            name = "酋长卡加斯·刃拳",
                            number = 1
                        },
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.KILL,
                            name = "屠龙者格鲁",
                            number = 1
                        },
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.KILL,
                            name = "大法师埃兰",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "纳鲁",
                    level = 65
                }
            }
        },
        {
            name = "团队日常",
            currentIndex = 1,
            isPerHero = false,
            cundangStr = "richangquest-tiaozhan",
            questType = QUEST_TYPE.LIMIT_PER_CYCLE,
            cycleCundangStr = "richang",
            cycleCheckPointIndex = 3,
            dailyLimit = 1,
            data = {
                {
                    index = 1,      --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {}, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\qita.blp", --任务图标文件
                    text = "守备官斯通哈特正在寻找最强大的冒险者。", --任务文本
                    title = "强大的冒险者", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 60
                },
                {
                    index = 2, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.HUGE, 3000000 },
                        { HSHOP_COST_TYPE.huoyanhuizhang,  4 }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "火焰之心的魔物蠢蠢欲动，勇士们，你们能去通关英雄难度的火焰之心吗？", --任务文本
                    title = "英雄火焰之心", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                            name = FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "火焰之心",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 60
                },
                {
                    index = 3, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.HUGE, 3000000 },
                        { HSHOP_COST_TYPE.huoyanhuizhang,  4 }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "黑龙王子最近的活动越来越频繁了，勇士们，你们能去通关英雄难度的黑龙王子的巢穴吗？", --任务文本
                    title = "英雄黑龙王子的巢穴", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                            name = FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "黑龙王子的巢穴",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "守备官斯通哈特",
                    level = 60
                }
            }
        },
        {
            name = "秘境日常",
            currentIndex = 1,
            isPerHero = false,
            cundangStr = "richangquest-mijing",
            questType = QUEST_TYPE.LIMIT_PER_CYCLE,
            cycleCundangStr = "richang",
            cycleCheckPointIndex = 4,
            dailyLimit = 1,
            data = {
                {
                    index = 1,      --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {}, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\qita.blp", --任务图标文件
                    text = "钓鱼大师派罗正在找人帮忙清理秘境。", --任务文本
                    title = "清理秘境", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "钓鱼大师派罗",
                    level = 60
                },
                {
                    index = 2, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.HUGE, 6000000 },
                        { HSHOP_COST_TYPE.huoyanhuizhang,  4 }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "秘境里的魔物们快要压制不住了，勇士们，你们能去清理任意传奇难度的秘境吗？", --任务文本
                    title = "传奇秘境", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                            number = 1,
                            name = "任意副本的传奇难度"
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "钓鱼大师派罗",
                    level = 60
                },
                {
                    index = 3, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.HUGE, 6000000 },
                        { HSHOP_COST_TYPE.huoyanhuizhang,  4 }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "干的不错，请再接再厉，你们能去继续清理一次传奇难度的秘境吗？", --任务文本
                    title = "继续清理传奇秘境", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                            number = 1,
                            name = "任意副本的传奇难度"
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "钓鱼大师派罗",
                    level = 60
                }
            }
        },
        {
            name = "纷争之地团队日常",
            currentIndex = 1,
            isPerHero = false,
            cundangStr = "richangquest-fzzdtuandui",
            questType = QUEST_TYPE.LIMIT_PER_CYCLE,
            cycleCundangStr = "richang",
            cycleCheckPointIndex = 6,
            dailyLimit = 1,
            data = {
                {
                    index = 1,      --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {}, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\qita.blp", --任务图标文件
                    text = "护卫队长彼得负责维护和平之城的安全，最近他面临了严重的挑战，快去帮帮他吧", --任务文本
                    title = "强大的冒险者", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "护卫队长彼得",
                    level = 70
                },
                {
                    index = 2, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.HUGE, 10000000 },
                        { HSHOP_COST_TYPE.zhengyihuizhang, 3 }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "西南方向的屠龙者已经残害了我们不少同僚了，勇士们，你们能去通关英雄难度的屠龙者的巢穴吗？", --任务文本
                    title = "英雄屠龙者的巢穴", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                            name = FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "屠龙者的巢穴",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "护卫队长彼得",
                    level = 70
                },
                {
                    index = 3, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.HUGE, 10000000 },
                        { HSHOP_COST_TYPE.zhengyihuizhang, 3 }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\zhuxian.blp", --任务图标文件
                    text = "法师塔的法师们最近动作频频，勇士们，你们能去通关英雄难度的法师塔吗？", --任务文本
                    title = "英雄法师塔", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                            name = FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "法师塔",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "护卫队长彼得",
                    level = 70
                }
            }
        },
        {
            name = "传奇任务：真鳞胸甲",
            cundangStr = "chuanji-zhenlinxiongjia",
            isPerHero = false,
            currentIndex = 1,
            questType = QUEST_TYPE.ONCE_LIFETIME,
            data = {
                {
                    index = 1,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\BTNINV_Chest_Cloth_48.blp", --任务图标文件
                    text = "广为人知的银鳞胸甲其实有着鲜为人知的秘密。如果你想进一步了解这段隐秘，请找亲自锻造一个银鳞胸甲。先从熊怪领主哪里获得一件野蛮锁甲，它将是锻造银鳞胸甲的关键", --任务文本
                    title = "野蛮锁甲", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "野蛮锁甲",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "铁匠哈特",
                    level = 10
                },
                {
                    index = 2,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\BTNINV_Chest_Cloth_48.blp", --任务图标文件
                    text = "接下来我们需要锻造一件银鳞胸甲。锻造除了野蛮锁甲，还需要铁锭。铁锭可以通过铁矿石熔炼而来。铁矿石可以通过采矿得到。村外就有好几个铁矿，快去采集吧", --任务文本
                    title = "铁锭", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "铁锭",
                            number = 2
                        }
                    },
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "野蛮锁甲",
                            itemLevel = 10,
                            count = 1
                        },
                        {
                            fitAllClass = true,
                            itemName = "铁锭",
                            count = 2
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "铁匠哈特",
                    level = 10
                },
                {
                    index = 3,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\BTNINV_Chest_Cloth_48.blp", --任务图标文件
                    text = "接下来我们需要锻造一件银鳞胸甲。在熔炉边上打造吧。", --任务文本
                    title = "银鳞胸甲，5金一件？", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.DUANZAO,
                            name = "银鳞胸甲",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "铁匠哈特",
                    level = 10
                },
                {
                    index = 4,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\BTNINV_Chest_Cloth_48.blp", --任务图标文件
                    text = "接下来要去请去找村长，他可以告诉你更多的关于真鳞胸甲的故事", --任务文本
                    title = "银鳞胸甲，蓝色品质", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 12
                },
                {
                    index = 5,                                                     --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    items = {},
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\BTNINV_Chest_Cloth_48.blp", --任务图标文件
                    text = "恭喜你，距离恢复这件传奇装备的荣光近了一步。接下来，击杀地下城的魔物领主获取魔物精魄来强化这件装备。完成后去找哈特来强化银鳞胸甲", --任务文本
                    title = "魔物精魄", -- 任务标题
                    req = { { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "魔物精魄", number = 10 } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "铁匠哈特",
                    level = 15
                },
                {
                    index = 6,                                                     --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\BTNINV_Chest_Cloth_48.blp", --任务图标文件
                    text = "融入魔物精魄需要5瓶助熔剂，以及2块精铁锭", --任务文本
                    title = "融入魔物精魄", -- 任务标题
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "银鳞胸甲",
                            itemLevel = 18,
                            itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                            count = 1
                        }
                    },
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "助熔剂", number = 5 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "精铁锭", number = 2 },
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "银鳞胸甲",
                            number = 1,
                            pinzhi = ZHUANGBEI_PINZHI.PUTONG
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "铁匠哈特",
                    level = 18
                },
                {
                    index = 7,                                                     --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "银鳞胸甲",
                            itemLevel = 20,
                            itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\BTNINV_Chest_Cloth_48.blp", --任务图标文件
                    text =
                    "就快成功了，精良级的银鳞胸甲已经足以支撑至关重要的一步，真龙之力的灌注。月亮湖的最深处有一头带有真龙血脉的多头蛇，击杀它来获取带有真龙之力的银色鳞片。真龙之力融入银鳞胸甲后会提升装备品质到史诗级。", --任务文本
                    title = "获取银色鳞片", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "银色鳞片", number = 1 },
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "银鳞胸甲",
                            number = 1,
                            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "铁匠哈特",
                    level = 20
                },
                {
                    index = 8,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "真鳞胸甲",
                            itemLevel = 30,
                            itemPinzhi = ZHUANGBEI_PINZHI.CHUANQI,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 1000,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\BTNINV_Chest_Cloth_48.blp", --任务图标文件
                    text = "要完全融入真龙之力需要大量的助熔剂已保证成功率，请带来5个助熔剂，这将是最后一步", --任务文本
                    finishText = "恭喜你！终于重现了这件传奇装备！",
                    title = "传奇装备：真鳞胸甲！", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "助熔剂", number = 5 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "铁匠哈特",
                    level = 25
                }
            }
        },
        {
            name = "传奇任务：灰烬之力",
            cundangStr = "chuanji-huijinzhili",
            isPerHero = false,
            currentIndex = 1,
            questType = QUEST_TYPE.ONCE_LIFETIME,
            data = {
                {
                    index = 1,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\shuangshoujian\\huijingzhijian.blp", --任务图标文件
                    text = "王城居民区的历史学家埃尔文似乎在寻求冒险者们的帮助。", --任务文本
                    finishText = "我是一个历史学家，一直在文献中寻找关于一把传说中的武器，灰烬之力，的故事",
                    title = "历史学家的请求", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "历史学家埃尔文",
                    level = 28
                },
                {
                    index = 2,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\shuangshoujian\\huijingzhijian.blp", --任务图标文件
                    text = "我的研究被中断了，因为可恶的范克瑞夫曾经偷盗了王城图书馆，带走了珍贵的资料。冒险者们，你们可以帮忙去监狱的最深处从范克瑞夫手上获得古老的历史文献吗？", --任务文本
                    title = "古老的历史文献", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "古老的历史文献",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "历史学家埃尔文",
                    level = 29
                },
                {
                    index = 3,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 250,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\chuanqi.blp", --任务图标文件
                    text =
                    "就是这些文献。让我研究研究……有了！上面提到灰烬使者曾经是一位强大的圣器所用的武器，能够把一切敌人化为灰烬，但是后来这把武器遗失了，莫格莱尼家族很可能保存着这把传奇的武器。请去找城主询问关于莫格莱尼家族的事情", --任务文本
                    title = "莫格莱尼家族", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "城主约翰",
                    level = 30
                },
                {
                    index = 4,                                                     --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\shuangshoujian\\huijingzhijian.blp", --任务图标文件
                    text =
                    "莫格莱尼家族？那个该死的叛徒家族，我恨不得将其挫骨扬灰。他曾经是王牌军队，血色军，的主帅，但是何曾想到他竟然背弃了荣耀，投靠了反叛军。你们在找的东西很可能就在他身上。他现在在城外不远的血色大本营。", --任务文本
                    title = "血色大本营", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "堕落的灰烬之力",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "历史学家埃尔文",
                    level = 31
                },
                {
                    index = 5,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\shuangshoujian\\huijingzhijian.blp", --任务图标文件
                    text = "没想到有生之年竟然能见到这把传奇武器。不过听你们说莫格莱尼并没有使用这把武器，现在看来应该是因为这把武器被污染了。净化污染这方面你可以询问资深牧师萨缪尔", --任务文本
                    title = "资深牧师萨缪尔", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "资深牧师萨缪尔",
                    level = 32
                },
                {
                    index = 6,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\shuangshoujian\\huijingzhijian.blp", --任务图标文件
                    text =
                    "这把武器的污染程度真是闻所未闻，上面的邪恶之力不是一朝一夕能形成的。净化如此强大的邪恶之力，我只能想到一件东西，那就是圣光之核。你可以去王城东北方向的圣光大教堂外找王牌卧底德尼尔来获取更多信息。", --任务文本
                    title = "寻找净化的方法", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "王牌卧底德尼尔",
                    level = 35
                },
                {
                    index = 7,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\shuangshoujian\\huijingzhijian.blp", --任务图标文件
                    text = "圣光之核掌握在圣光大主教的手上，曾经的他是城主最主要的搭档，如今却成了反叛军的首领，去击杀他吧。", --任务文本
                    title = "圣光之核", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "圣光之核",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishText = "你们竟然真的拿到圣光之核了，那必定经过了艰苦的战斗。",
                    finishNPC = "资深牧师萨缪尔",
                    level = 38
                },
                {
                    index = 8,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.HUGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.HUGE }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "灰烬之力",
                            itemLevel = 45,
                            itemPinzhi = ZHUANGBEI_PINZHI.CHUANQI,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 1000,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\shuangshoujian\\huijingzhijian.blp", --任务图标文件
                    text = "最后一步净化堕落的灰烬之力需要20棵圣光草（采药）。", --任务文本
                    finishText = "恭喜你！终于恢复了这件传奇装备的威能！",
                    title = "灰烬之力", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "圣光草", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "资深牧师萨缪尔",
                    level = 40
                }
            }
        },
        {
            name = "传奇任务：炎魔之手",
            cundangStr = "chuanqi-yanmozhishou",
            isPerHero = false,
            currentIndex = 1,
            questType = QUEST_TYPE.ONCE_LIFETIME,
            data = {
                {
                    index = 1,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Hammer_Unique_Sulfuras.blp", --任务图标文件
                    text = "传奇铁匠福吉菲尔最近遇到了一点困难，需要你的帮助。", --任务文本
                    finishText = "你好朋友，我是传奇铁匠福吉菲尔，我需要你的帮助。", --任务完成文本
                    title = "福吉菲尔的请求", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "传奇铁匠福吉菲尔",
                    level = 60
                },
                {
                    index = 2,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Hammer_Unique_Sulfuras.blp", --任务图标文件
                    text = "我最近在研究黑石矮人的锻造技术，他们曾经锻造出传奇武器，炎魔之手，去矮人地下城看看有没有什么关于这个锻造过程的记载吧。", --任务文本
                    finishText = "对！就是这个，真没想到他们竟然把这个过程记载的如此详细，让我研究研究。", --任务完成文本
                    title = "炎魔之手锻造手札", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "炎魔之手锻造手札",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "传奇铁匠福吉菲尔",
                    level = 60
                },
                {
                    index = 3,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Hammer_Unique_Sulfuras.blp", --任务图标文件
                    text = "根据记载，锻造炎魔之手的第一步是锻造器胚：炎魔之锤。让我看看材料，嗯，这个不容易，快去行动吧。", --任务文本
                    finishText = "太棒了，我们可以进行下一步了。", --任务完成文本
                    title = "锻造炎魔之锤", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "炎魔之锤",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "传奇铁匠福吉菲尔",
                    level = 60
                },
                {
                    index = 4,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Hammer_Unique_Sulfuras.blp", --任务图标文件
                    text = "炎魔之手的真正力量来自于火焰之心的烈焰，我们要锻造的是神器，普通的材料肯定不行。听说火焰之心的最深处有一个炎魔之王，它的火焰之力都凝聚在眼睛上，那肯定是一个最棒的材料，快去吧！", --任务文本
                    finishText = "你们的实习真是令人刮目相看。", --任务完成文本
                    title = "炎魔之眼", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "炎魔之眼",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "传奇铁匠福吉菲尔",
                    level = 60
                },
                {
                    index = 5,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.HUGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.HUGE }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "炎魔之手",
                            itemLevel = 60,
                            itemPinzhi = ZHUANGBEI_PINZHI.CHUANQI,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 1000,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Hammer_Unique_Sulfuras.blp", --任务图标文件
                    text = "搞定了，我这就把他们俩融合起来，在此之前先准备80个助熔剂吧!", --任务文本
                    finishText = "恭喜你获得这把传奇武器！",
                    title = "炎魔之手", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "助熔剂", number = 80 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "传奇铁匠福吉菲尔",
                    level = 60
                }
            }
        },
        {
            name = "传奇任务：雷霆之怒",
            cundangStr = "chuanqi-leitingzhinu",
            isPerHero = false,
            currentIndex = 1,
            questType = QUEST_TYPE.ONCE_LIFETIME,
            data = {
                {
                    index = 1,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Sword_39.blp",
                    text = "钓鱼大师派罗有一些了不得的发现，可以去问问发生了什么。", --任务文本
                    finishText = "你好朋友，我是派罗，你也是被南边的巨大动静吸引过来的吧。", --任务完成文本
                    title = "派罗", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "钓鱼大师派罗",
                    level = 60
                },
                {
                    index = 2,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Sword_39.blp",
                    text = "我从古籍上看到过它，风元素领主，没想到它竟然还活着。先去会会他吧，看看有什么发现。", --任务文本
                    finishText = "这把剑，难道是传说中的逐风者之剑？可是为什么破损至此。", --任务完成文本
                    title = "风吻之刃", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "风吻之刃",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "钓鱼大师派罗",
                    level = 60
                },
                {
                    index = 3,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Sword_39.blp",
                    text = "如果你们想要重现这把武器的巅峰时刻，那么可以去找福吉菲尔，他可是武器锻造的行家。", --任务文本
                    finishText = "你们好，看看你们带来了什么好东西。", --任务完成文本
                    title = "传奇铁匠福吉菲尔", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "传奇铁匠福吉菲尔",
                    level = 60
                },
                {
                    index = 4,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Sword_39.blp",
                    text =
                    "我记得它，传奇武器，雷霆之怒·逐风者之剑。这把武器经过时间的洗礼已经失去了灵性。要恢复其灵性，第一步就要收集蕴含强大风雷之力的物品。我听说火焰之心的领主收藏有这样的物品，逐风者禁锢之颅。去拿到他们吧。", --任务文本
                    finishText = "就是他们，我们来准备下一步吧。", --任务完成文本
                    title = "逐风者禁锢之颅", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "逐风者禁锢之颅（右）",
                            number = 1
                        },
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "逐风者禁锢之颅（左）",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "传奇铁匠福吉菲尔",
                    level = 60
                },
                {
                    index = 5,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Sword_39.blp",
                    text = "我们还需要蕴含强大火焰力量的物品来激活禁锢之颅和风吻之力。去收集火焰之王的精华吧，他只会出现在高难度的炎魔之王手中。", --任务文本
                    finishText = "很好，接下来是最后一步", --任务完成文本
                    title = "火焰之王的精华", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "火焰之王的精华",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "传奇铁匠福吉菲尔",
                    level = 60
                },
                {
                    index = 6,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.HUGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.HUGE }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "雷霆之怒·逐风者之剑",
                            itemLevel = 60,
                            itemPinzhi = ZHUANGBEI_PINZHI.CHUANQI,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 1000,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Sword_39.blp",
                    text = "我们还需要一些锻造神器的金属材料，因为恢复的过程中风吻之刃需要吞噬一部分材料才能达到最佳的状态。", --任务文本
                    finishText = "恭喜你获得这把传奇武器！",
                    title = "雷霆之怒·逐风者之剑", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "助熔剂", number = 50 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "源质锭", number = 10 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "传奇铁匠福吉菲尔",
                    level = 60
                }
            }
        },
        {
            name = "传奇任务：埃提耶什",
            cundangStr = "chuanqi-aitiyeshi",
            isPerHero = false,
            currentIndex = 1,
            questType = QUEST_TYPE.ONCE_LIFETIME,
            data = {
                {
                    index = 1,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\inv_staff_medivh.blp",
                    text = "新手村村长曾经也是一个了不得的人物，和他聊聊，说不定有什么收获。", --任务文本
                    finishText = "好久不见，冒险者们。", --任务完成文本
                    title = "再见新手村村长", -- 任务标题
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 60
                },
                {
                    index = 2,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\inv_staff_medivh.blp",
                    text =
                    "听说最近火焰之地魔物们又活跃起来了，这让我想起前辈们之前用过的一把武器，埃提耶什，它就被封印在火焰之地。根据记载，这把武器被分解成3部分，最重要部分的杖柄被分成许多个埃提耶什碎片，散落在火焰之心的深处。为了对抗魔物，先去把它取来吧。当你获取足够的碎片后可以用锻造来再次合成杖柄。", --任务文本
                    finishText = "这就是埃提耶什的杖柄？和记载的简直一摸一样。", --任务完成文本
                    title = "埃提耶什的杖柄", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "埃提耶什的杖柄",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 60
                },
                {
                    index = 3,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\inv_staff_medivh.blp",
                    text = "我们还需要两个部分，杖头和杖尾。杖头记得封印在风元素领地，快去看看吧。", --任务文本
                    finishText = "就是它，你们动作真快。", --任务完成文本
                    title = "埃提耶什的杖头", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "埃提耶什的杖头",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 60
                },
                {
                    index = 4,                                                    --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\inv_staff_medivh.blp",
                    text = "最后一部分是杖尾，杖尾原本被王城将军艾德所保存，但是听说他在与黑龙王子的斗争中被击败，我想杖尾也应该在黑龙王子的巢穴里", --任务文本
                    finishText = "就差最后一步了。", --任务完成文本
                    title = "埃提耶什的杖尾", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "埃提耶什的杖尾",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "新手村村长",
                    level = 60
                },
                {
                    index = 5,                                                   --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.HUGE } }, --任务完成属性奖励
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.HUGE }
                    }, --资源奖励
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "埃提耶什·守护者之杖",
                            itemLevel = 60,
                            itemPinzhi = ZHUANGBEI_PINZHI.CHUANQI,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 1000,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\inv_staff_medivh.blp",
                    text = "将这三部分融合，需要巨大的火焰之力，如果拿到火焰之王的精华，就可以马上开始融合了", --任务文本
                    finishText = "恭喜你获得这把传奇武器！",
                    title = "埃提耶什·守护者之杖", -- 任务标题
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "助熔剂", number = 50 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "火焰之王的精华", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "新手村村长",
                    level = 60
                }
            }
        },
        {
            name = "传奇任务：血吼",
            cundangStr = "chuanqi-xuehou",
            isPerHero = false,
            currentIndex = 1,
            questType = QUEST_TYPE.ONCE_LIFETIME,
            data = {
                {
                    index = 1,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } },
                    resources = { { HSHOP_COST_TYPE.gold, QUEST_JIANGLI_SCALE_TYPE.TINY }, { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.TINY }, },
                    shengwang = { { value = 100, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Axe_60.blp",
                    text = "我追随地狱咆哮的传说来到这里，听说地狱咆哮的战斧遗失在破碎大厅深处，你们可以帮忙探查一下吗?",
                    finishText = "这把斧子曾是战歌氏族酋长所持的战斧，因斩杀深渊领主—玛诺洛斯而被众人所熟知，格罗姆·地狱咆哮死亡之后，它便消失了，没想到有生之年竟然还能见到这把传奇武器。",
                    title = "血吼的传说",
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                        name = "残破的战斧",
                        number = 1
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "兽人老兵火刃",
                    level = 70
                },
                {
                    index = 2,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } },
                    resources = { { HSHOP_COST_TYPE.gold, QUEST_JIANGLI_SCALE_TYPE.LARGE }, { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE } },
                    shengwang = { { value = 500, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Axe_60.blp",
                    text =
                    "这把武器曾经是地狱咆哮的标志武器，但是如今沉寂太久了，失去了原有的血气。我们需要寻找一些蕴含强大血气的东西来激活它。纷争之地不缺这样强大的生物。和平之城西南边就有一个强大的生物，想必它的心脏能够唤醒这把传奇武器。",
                    finishText = "戈隆的心脏有狂暴的鲜血力量，这下应该可以唤醒沉寂的血吼了。",
                    title = "唤醒血吼",
                    req = { { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "屠龙者的心脏", number = 8 } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "兽人老兵火刃",
                    level = 70
                },
                {
                    index = 3,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } },
                    resources = { { HSHOP_COST_TYPE.gold, QUEST_JIANGLI_SCALE_TYPE.LARGE }, { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE } },
                    shengwang = { { value = 100, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Axe_60.blp",
                    text = "看来它还是沉寂太久了，或许我们需要一些其他力量让他彻底觉醒，听闻法师塔的埃兰被煞能污染，从而获得了无尽的魔力，你可以去那边寻找看看，是不是能找到他获取煞能的秘密。",
                    finishText = "就是它，或许可以开始重铸他了。",
                    title = "寻找煞能",
                    req = { { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "煞能精华", number = 10 } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "兽人老兵火刃",
                    level = 70
                },
                {
                    index = 4,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } },
                    resources = { { HSHOP_COST_TYPE.gold, QUEST_JIANGLI_SCALE_TYPE.LARGE }, { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE } },
                    shengwang = { { value = 500, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Axe_60.blp",
                    text = "就是这把战斧，我还依稀记得当年地狱咆哮的英姿，可惜那些可恶的邪兽人背叛了地狱咆哮！导致了他的陨落，拿着这把斧头用仇敌的鲜血洗刷当初的耻辱！",
                    title = "消灭兽人",
                    req = { { type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN, name = FUBEN_NANDU_LABEL[FUBEN_NANDU.SHISHI] .. "破碎大厅", number = 15 } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "兽人老兵火刃",
                    level = 70
                },
                {
                    index = 5,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } },
                    resources = { { HSHOP_COST_TYPE.gold, QUEST_JIANGLI_SCALE_TYPE.LARGE }, { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE } },
                    shengwang = { { value = 500, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Axe_60.blp",
                    text = "这把武器已经被完全唤醒，现在需要最后一步，去战胜强大的魔物把，来给这把武器最后的洗礼。",
                    finishText = "恭喜你，这把武器已经恢复所有的威能！如果要恢复到全盛时期的威能，可以去找和平之城中间的纳鲁，他有办法可以进一步加强这把武器的威力。",
                    title = "血之怒吼",
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "血吼",
                            itemLevel = 70,
                            itemPinzhi = ZHUANGBEI_PINZHI.CHUANQI,
                            count = 1
                        }
                    },
                    req = { { type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN, name = FUBEN_NANDU_LABEL[FUBEN_NANDU.SHISHI] .. "屠龙者的巢穴", number = 15 } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "兽人老兵火刃",
                    level = 70
                }, }
        },
        {
            name = "传奇任务：烈焰之击",
            cundangStr = "chuanqi-lieyanjiji",
            isPerHero = false,
            currentIndex = 1,
            questType = QUEST_TYPE.ONCE_LIFETIME,
            data = {
                {
                    index = 1,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    },
                    shengwang = { { value = 100, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Weapon_Shortblade_89.blp",
                    text = "勇敢的冒险者啊,纷争之地正笼罩在一片阴霾之下。往日温顺的生物变得狂暴嗜血,连空气中都弥漫着不祥的气息。我们怀疑这一切与法师塔有关。请前往那里一探究竟,揭开这诡谲变化的真相!",
                    finishText = "出什么事了? 埃兰大法师...他掌握了一种前所未有的强大魔力。恐怕正是这股力量导致了纷争之地的异变。事态紧急!我们必须想办法削弱埃兰的力量,否则后果不堪设想!",
                    title = "不详的预兆",
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                        name = FUBEN_NANDU_LABEL[FUBEN_NANDU.SHISHI] .. "法师塔",
                        number = 5
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "老法师奥利弗",
                    level = 70
                },
                {
                    index = 2,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    },
                    shengwang = { { value = 200, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Weapon_Shortblade_89.blp",
                    text = "时间紧迫,冒险者!埃兰的魔力每分每秒都在增长,我们必须尽快行动。潜入法师塔,找到10个埃兰的魔力精华。这个任务危险重重,但你是我们最后的希望。愿诸神保佑你平安归来!",
                    finishText = "太好了,你安全回来了!让我看看你带回了什么...没错,就是这个!埃兰的力量果然来自于此。我们得好好研究一下这个神秘的魔力精华。",
                    title = "夺取魔精",
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                        name = "埃兰的魔力精华",
                        number = 10
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "老法师奥利弗",
                    level = 70
                },
                {
                    index = 3,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    },
                    shengwang = { { value = 300, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Weapon_Shortblade_89.blp",
                    text =
                    "冒险者,事情比我们想象的还要复杂。埃兰的魔力精华中存在一种异常的能量波动,这暗示着背后可能还有更强大的势力在操控。我们需要你前往南方的风暴要塞,那里可能藏有重要线索。小心行事,敌人的爪牙无处不在!",
                    finishText =
                    "我在风暴要塞发现了一些令人不安的事情...那里充斥着各种魔法能量石和能量装置。看来,有人正在秘密集结一支强大的军队。情况比我们预想的还要糟糕。纷争之地即将陷入一场前所未有的浩劫。我们必须未雨绸缪,为即将到来的战争做好准备。",
                    title = "神秘势力",
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                        name = FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "风暴要塞",
                        number = 10
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "老法师奥利弗",
                    level = 70
                },
                {
                    index = 4,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    },
                    shengwang = { { value = 400, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Weapon_Shortblade_89.blp",
                    text =
                    "听闻凯尔萨斯王子拥有一把名为'烈焰之击'的神器,据说是用太阳精华凝练而成。在即将到来的黑暗中,这把神器可能是我们最后的希望。冒险者,你的任务是说服或击败凯尔萨斯,夺取烈焰之击。记住,这把武器对我们至关重要,无论付出什么代价都要带回来!",
                    finishText =
                    "天哪!你看起来伤痕累累...战斗一定很激烈吧? 凯尔萨斯...他宁愿毁掉神器也不愿交出来。我们...差点都没能活着回来。烈焰之击...虽然现在只是残破之躯,但它依然散发着不可思议的能量。凯尔萨斯在最后关头散去了大部分力量,但我们还有希望让它重现光芒。",
                    title = "烈焰之击",
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                        name = "残破的烈焰之击",
                        number = 1
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "老法师奥利弗",
                    level = 70
                },
                {
                    index = 5,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    },
                    shengwang = { { value = 500, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Weapon_Shortblade_89.blp",
                    text =
                    "冒险者,我们还有最后的希望!虽然烈焰之击现在只是一把残破的武器,但通过收集烈日精华,我们可以让它重新焕发光芒。前往风暴要塞和凯尔萨斯的领地,收集烈日精华。这个任务艰巨而危险,但整个世界的命运都掌握在你手中。去吧,让我们一起重铸这把传说中的神兵!",
                    finishText =
                    "太棒了!有了这些烈日精华,我们终于可以开始修复烈焰之击了。看哪,烈焰之击重获新生了!虽然它的力量还不及全盛时期,但已经是一把强大的武器了。烈焰之击需要持续不断地注入魔力才能逐步恢复它往日的威能。这将是一个漫长的过程,但只要我们坚持不懈,终有一天它会重现昔日的荣光,成为对抗黑暗的最强利器!",
                    title = "烈日重生",
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "烈焰之击",
                            itemLevel = 71,
                            nandu = FUBEN_NANDU.PUTONG,
                            count = 1
                        }
                    },
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                        name = "烈日精华",
                        number = 10
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "老法师奥利弗",
                    level = 70
                },
            }
        },
        {
            name = "传奇任务：恶魔战刃",
            cundangStr = "chuanqi-emzr",
            isPerHero = false,
            currentIndex = 1,
            questType = QUEST_TYPE.ONCE_LIFETIME,
            data = {
                {
                    index = 1,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    },
                    shengwang = { { value = 100, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\BTNINV_Weapon_Glave_01.blp",
                    text =
                    "英勇的冒险者，命运的齿轮已然转动。一股来自黑暗神殿的古老力量正在觉醒，它的呼唤震撼着整个世界的根基。穿越战火与磨难，前往黑暗神殿的大门，寻找智者阿卡玛。唯有他的智慧，才能揭开这股力量的真相。",
                    title = "命运的召唤",
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "阿卡玛",
                    level = 70
                },
                {
                    index = 2,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    },
                    shengwang = { { value = 200, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\BTNINV_Weapon_Glave_01.blp",
                    text =
                    "听啊，命运的勇士！背叛者的魔爪紧握着传说中的恶魔战刃，这对神器蕴含着足以撕裂现实的力量。若你渴望成为它们的主人，就必须挑战那个堕落的灵魂。但此刻，你尚未做好准备。深入神殿的心脏，从扭曲的恶魔中汲取黑暗精华。唯有这样，你才能在即将到来的史诗对决中存活。",
                    title = "暗影中的真相",
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                        name = "黑暗精华",
                        number = 20
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "阿卡玛",
                    level = 70
                },
                {
                    index = 3,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    },
                    shengwang = { { value = 300, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\BTNINV_Weapon_Glave_01.blp",
                    text = "黑暗的力量已经在你的血管中流淌，但这还远远不够。要与背叛者匹敌，你需要驾驭更加狂暴的能量。闯入风暴要塞的中心，那里的狂暴烈焰精华将成为你的磨刀石，锻造你成为真正的传奇。",
                    title = "烈焰中的淬炼",
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                        name = "狂暴烈焰精华",
                        number = 10
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "阿卡玛",
                    level = 70
                },
                {
                    index = 4,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    },
                    shengwang = { { value = 400, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\BTNINV_Weapon_Glave_01.blp",
                    text =
                    "时机已至，命运的战士！回到黑暗神殿，直面那个背叛一切的堕落之魂。他手中的恶魔战刃散发着毁灭世界的光芒。击败他，这对传说中的神器就将认你为主。但要谨记，即便在失败的刹那，这对战刃的力量也可能会反噬其主。准备好迎接有史以来最艰巨的挑战了吗？",
                    title = "命运的决战",
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "破损的恶魔战刃（主手）",
                            number = 1
                        },
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "破损的恶魔战刃（副手）",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "阿卡玛",
                    level = 70
                },
                {
                    index = 5,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    },
                    shengwang = { { value = 500, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\BTNINV_Weapon_Glave_01.blp",
                    text =
                    "你做到了不可能的事！恶魔战刃虽已在你手，却因激烈的战斗而伤痕累累。但命运的齿轮并未停止转动。穿越烈焰与岩浆，寻找灼热峡谷中的传奇铁匠福吉菲尔。他的hammer是打造神话的工具，只有他才能让这对战刃重现昔日的荣光。",
                    title = "重铸传奇",
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                        name = "助熔剂",
                        number = 300
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "传奇铁匠福吉菲尔",
                    level = 70
                },
                {
                    index = 6,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.LARGE } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    },
                    shengwang = { { value = 1000, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\BTNINV_Weapon_Glave_01.blp",
                    text =
                    "勇士，你已经站在了传奇的门槛。材料已备齐，是时候让这对神器在烈焰中重生了。但真正的考验才刚刚开始。恶魔战刃渴望一位无畏的主人，一个能与之共同书写史诗的灵魂。唯有征服黑暗神殿的至高难度，你才能证明自己配得上这对神器。准备好开启你的传奇了吗？",
                    title = "传奇的诞生",
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
                        name = FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "黑暗神殿",
                        number = 10
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "传奇铁匠福吉菲尔",
                    level = 70,
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "恶魔战刃（主手）",
                            itemLevel = 72,
                            nandu = FUBEN_NANDU.CHUANQI,
                            count = 1
                        },
                        {
                            fitAllClass = true,
                            itemName = "恶魔战刃（副手）",
                            itemLevel = 72,
                            nandu = FUBEN_NANDU.CHUANQI,
                            count = 1
                        }
                    }
                },
            }
        },
        {
            name = "传奇任务：深渊垂钓者",
            cundangStr = "chuanqi-diaoyu",
            isPerHero = false,
            currentIndex = 1,
            questType = QUEST_TYPE.ONCE_LIFETIME,
            data = {
                {
                    index = 1,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    },
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "粗糙的鱼竿",
                            itemLevel = 10,
                            itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                            count = 1
                        }
                    },
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Fishingpole_03.blp",
                    text = "我是5年前王城钓鱼大赛的冠军选手，我可以传授你一些钓鱼的技巧，但是你需要先获得一把鱼竿。去找一把残破的鱼竿吧。",
                    finishText = "不错，虽然这把鱼竿很破旧，但对初学者来说足够了。让我们来练习钓鱼吧。",
                    title = "钓鱼入门",
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                        name = "残破的鱼竿",
                        number = 1,
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "克文",
                    level = 10
                },
                {
                    index = 2,
                    attr = { { "diaoyurate", QUEST_JIANGLI_SCALE_TYPE.TINY } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.TINY },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.TINY }
                    },
                    shengwang = {
                        {
                            value = 100,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Fishingpole_03.blp",
                    text = "你的鱼竿实在太破了，我帮你换了套钩线，现在勉强能用了。看到前面的回湾了吗？那里是个好地方，你要在那里学会调漂。",
                    finishText = "看来你已经掌握了基本的钓鱼技巧，做得不错！",
                    title = "学习调漂",
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.DIAOYU,
                        name = "新手村钓鱼点",
                        number = 100
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "克文",
                    level = 5
                },
                {
                    index = 3,
                    attr = { { "diaoyurate", QUEST_JIANGLI_SCALE_TYPE.SMALL } },
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "精致的鱼竿",
                            itemLevel = 10,
                            itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                            count = 1
                        }
                    },
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    },
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Fishingpole_03.blp",
                    text = "看到你第一次钓鱼就能爆护，我觉得你是万中无一的天才。我决定复出，和你组成一个队伍，参加这次王城钓鱼大赛的小组赛事。不过你需要先强化一下你的装备到+8+8。",
                    finishText = "太棒了！你的鱼竿现在已经足够参加比赛了。让我给你一个更好的鱼竿作为奖励吧。",
                    title = "强化鱼竿",
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                        name = "粗糙的鱼竿",
                        itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                        number = 1,
                        qianghua = 8,
                        jinglian = 8
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "克文",
                    level = 10
                },
                {
                    index = 4,
                    attr = { { "diaoyurate", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    },
                    shengwang = {
                        {
                            value = 300,
                            shengwangname = "王城"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Fishingpole_03.blp",
                    text = "你现在的装备已经有挑战巨物的资格了。我们组成了一个小队参加王城的钓鱼赛事，去王城喷泉钓鱼200次吧。",
                    finishText = "太棒了！我们的表现真是惊艳全场！",
                    title = "王城钓鱼大赛",
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.DIAOYU,
                        name = "王城喷泉",
                        number = 200
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "克文",
                    level = 20
                },
                {
                    index = 5,
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    },
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Fishingpole_03.blp",
                    text = "我们获得了冠军！这是我钓鱼生涯的完美落幕，而你将是钓鱼界冉冉升起的新星。我给你写了一封介绍信，去灼热峡谷找钓鱼大师派罗吧，向他学习最高深的野钓技巧。",
                    finishText = "克文向我提到过你，年轻人。看来你在钓鱼方面确实很有天赋。",
                    title = "拜访钓鱼大师",
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "钓鱼大师派罗",
                    level = 40
                },
                {
                    index = 6,
                    attr = { { "diaoyurate", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    },
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Fishingpole_03.blp",
                    text = "要真正理解野钓的真谛，你需要在极端环境中实践。去沙漠深井中钓鱼500次，感受一下真正的挑战。",
                    finishText = "不错，看来你已经开始领悟野钓的精髓了。",
                    title = "野钓挑战",
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.DIAOYU,
                        name = "沙漠深井",
                        number = 500
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "钓鱼大师派罗",
                    level = 25
                },
                {
                    index = 7,
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "特制鱼竿",
                            itemLevel = 60,
                            itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                            count = 1
                        }
                    },
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    },
                    shengwang = {
                        {
                            value = 1000,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Fishingpole_03.blp",
                    text = "你的钓鱼技巧已经相当不错了，但是在这样的极端环境下，你的装备可能还跟不上。让我帮你改装一下鱼竿吧，记得先把鱼竿强化到+8+8以上。",
                    finishText = "恭喜你，年轻的钓鱼大师！这把特制鱼竿将助你在钓鱼的道路上更进一步。",
                    title = "钓鱼大师的馈赠",
                    req = { {
                        type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                        name = "精致的鱼竿",
                        number = 1,
                        qianghua = 8,
                        jinglian = 8
                    } },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "钓鱼大师派罗",
                    level = 30
                },
                {
                    index = 8,
                    attr = { { "diaoyurate", QUEST_JIANGLI_SCALE_TYPE.LARGE } },
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "深渊垂钓者",
                            itemLevel = 70,
                            itemPinzhi = ZHUANGBEI_PINZHI.CHUANQI,
                            count = 1
                        }
                    },
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.HUGE }
                    },
                    shengwang = {
                        {
                            value = 2000,
                            shengwangname = "和平之城"
                        }
                    },
                    art = "ReplaceableTextures\\zhuangbei\\INV_Fishingpole_03.blp",
                    text =
                    "你已经掌握了高深的钓鱼技巧，但传说中的钓鱼佬才是真正的大师。他在纷争之地等着你。去找他，证明你的实力吧！根据以往的经验，他会要求你在和平之城钓鱼点钓鱼999次，同时将特制鱼竿强化到9级，精炼到9级。",
                    finishText = "哈哈，年轻人，你做到了！你已经成为真正的钓鱼佬了。这把神竿就归你了，它会让你成为传说中的钓鱼大师！",
                    title = "成为钓鱼佬",
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.DIAOYU,
                            name = "和平之城钓鱼点",
                            number = 999
                        },
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "特制鱼竿",
                            number = 1,
                            qianghua = 9,
                            jinglian = 9
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "传说中的钓鱼佬",
                    level = 70
                },
            }
        },
        {
            name = "传奇任务：群星之怒",
            cundangStr = "chuanqi-qunxingzhinu",
            isPerHero = false,
            currentIndex = 1,
            questType = QUEST_TYPE.ONCE_LIFETIME,
            data = {
                {
                    index = 1,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.SMALL } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    },
                    shengwang = { { value = 200, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_BOW_39.blp",
                    text = "勇敢的冒险者，恶魔军团的威胁日益严重。我需要你的帮助来击退这些入侵者。证明你的实力，我将向你透露一个关于改变冒险者世界历史的远古神器的秘密。",
                    finishText = "你的勇气和实力令人钦佩。现在，听好了：传说中的神器'群星之怒'可能还有重现天日的机会。这把神器曾经改变了冒险者世界的命运，而现在，重铸它的任务就交到你手上了。",
                    title = "风行者的考验",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "恶魔狂战士", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "恶魔地狱火", number = 20 },
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.KILL, name = "末日护卫", number = 20 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "温蕾萨·风行者",
                    level = 70
                },
                {
                    index = 2,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    },
                    shengwang = { { value = 300, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_BOW_39.blp",
                    text =
                    "重铸群星之怒需要极为珍稀的材料。首先，我们需要'永恒魔力精华'。这种物质蕴含着难以想象的能量，只有在传奇难度的法师塔最深处才能找到。你必须击败塔中的守护者才有机会获得它。准备好接受挑战了吗？",
                    finishText = "太棒了！你成功获得了永恒魔力精华。这种神奇的物质在你手中闪烁着奥术的光芒，它将成为重铸群星之怒的关键材料之一。",
                    title = "永恒魔力的追寻",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "永恒魔力精华", number = 10 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "温蕾萨·风行者",
                    level = 70
                },
                {
                    index = 3,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.MEDIUM } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.MEDIUM },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    },
                    shengwang = { { value = 400, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_BOW_39.blp",
                    text =
                    "群星之怒的弓弦需要使用'远古巨龙之筋'。这种材料来自上古巨龙，具有无与伦比的韧性和力量。你需要前往传奇难度的屠龙者巢穴，在那里击败远古巨龙守护者。这将是一场艰苦的战斗，但为了重铸神器，这是必要的牺牲。",
                    finishText = "令人惊叹！你不仅活着回来了，还带回了远古巨龙之筋。这种材料蕴含着巨龙的力量，将赋予群星之怒无与伦比的威力。",
                    title = "巨龙的馈赠",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "远古巨龙之筋", number = 1 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "温蕾萨·风行者",
                    level = 70
                },
                {
                    index = 4,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    },
                    shengwang = { { value = 500, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_BOW_39.blp",
                    text =
                    "你已经收集到了两种关键材料，干得好！现在，我们需要寻找群星之怒的前任持有者——奥蕾莉亚·风行者。她正在太阳之井守卫着最后的希望。前往太阳之井，找到奥蕾莉亚。她会指引你完成重铸神器的最后步骤。",
                    finishText = "我感受到了永恒魔力精华和远古巨龙之筋的力量。你做得很好，但我们的任务还没有结束。重铸群星之怒还需要一种特殊的金属。",
                    title = "寻找守护者",
                    req = {},
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "奥蕾莉亚·风行者",
                    level = 70
                },
                {
                    index = 5,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.TINY } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.LARGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.LARGE }
                    },
                    shengwang = { { value = 600, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_BOW_39.blp",
                    text =
                    "重铸群星之怒还需要一种名为'虚空陨铁'的特殊金属。这种金属只存在于黑暗神殿的最深处，被强大的恶魔守卫着。你必须深入神殿，击败重重守卫，才能获得这稀有的陨铁。这将是一次危险的冒险，但为了艾泽拉斯的未来，我们别无选择。",
                    finishText = "你带回了虚空陨铁！这种金属中蕴含着来自虚空的神秘力量，它将成为群星之怒的核心部分。我们离重铸神器只差最后一步了。",
                    title = "虚空的馈赠",
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "虚空陨铁", number = 10 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "奥蕾莉亚·风行者",
                    level = 70
                },
                {
                    index = 6,
                    attr = { { "quanshuxing", QUEST_JIANGLI_SCALE_TYPE.HUGE } },
                    resources = {
                        { HSHOP_COST_TYPE.gold,            QUEST_JIANGLI_SCALE_TYPE.HUGE },
                        { HSHOP_COST_TYPE.dianfengjingyan, QUEST_JIANGLI_SCALE_TYPE.HUGE }
                    },
                    shengwang = { { value = 1000, shengwangname = "和平之城" } },
                    art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_BOW_39.blp",
                    text =
                    "勇士，这是最后也是最危险的任务。我们需要太阳之井的纯净能量来融合所有材料。然而，这种能量现在被恶魔领主基尔加丹所掌控。你必须在史诗难度下挑战基尔加丹，从他手中夺取'太阳之井的精华'。只有击败这个强大的对手，我们才能重铸群星之怒。艾泽拉斯的命运就掌握在你手中了。",
                    finishText = "你做到了！你不仅击败了基尔加丹，还带回了太阳之井的精华。现在，让我们开始重铸群星之怒的仪式吧。愿这把神器在你手中发挥出它真正的力量，成为抵抗黑暗力量的希望之光！",
                    title = "命运的抉择",
                    items = {
                        {
                            fitAllClass = true,
                            itemName = "群星之怒·暗月",
                            itemLevel = 73,
                            itemPinzhi = ZHUANGBEI_PINZHI.CHUANQI,
                            count = 1
                        },
                        {
                            fitAllClass = true,
                            itemName = "群星之怒·烈阳",
                            itemLevel = 73,
                            itemPinzhi = ZHUANGBEI_PINZHI.CHUANQI,
                            count = 1
                        }
                    },
                    req = {
                        { type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG, name = "太阳之井的精华", number = 10 }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC,
                    finishNPC = "奥蕾莉亚·风行者",
                    level = 70
                },
            }
        },
        {
            name = "炼金师的烦恼",
            currentIndex = 1,
            questType = QUEST_TYPE.INFINITE,
            data = {
                {
                    index = 1, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 275,
                            shengwangname = "新手村"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\qita.blp", --任务图标文件
                    text = "炼金术的提升需要大量的草药，请帮我收集一些基础草药吧，我会报答你的！", --任务文本
                    title = "更多草药", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "银叶草",
                            number = 10
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "药剂学徒瑞克",
                    level = 10
                }
            }
        },
        {
            name = "恶龙的困扰",
            currentIndex = 1,
            questType = QUEST_TYPE.INFINITE,
            data = {
                {
                    index = 1, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold, QUEST_JIANGLI_SCALE_TYPE.MEDIUM }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 500,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = hslk.n2v("黑龙王子", "slk", "Art"), --任务图标文件
                    text = "黑龙王子在灼热峡谷肆虐，去把他的头颅带来吧。", --任务文本
                    title = "黑龙王子", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "黑龙王子的徽记",
                            number = 1
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "城主约翰",
                    finishText = "勇士们，你们的实力真是令人刮目相看。你们的贡献鼓舞了所有人！",
                    finishEffect = function(whichPlayer)
                        for _, v in ipairs(hplayer.players) do
                            if hplayer.isUser(v) and hplayer.isPlaying(v) and hplayer.getMainHero(v) ~= nil then
                                local hero = hplayer.getMainHero(v)
                                if hunit.getLevel(hero) <= 60 then
                                    hbuff.update(
                                        7200,
                                        hero,
                                        "屠龙者的咆哮",
                                        true,
                                        function()
                                            hattribute.set(hero, 0, { wu_bao = "+2", fa_bao = "+2" })
                                        end,
                                        function()
                                            hattribute.set(hero, 0, { wu_bao = "-2", fa_bao = "-2" })
                                        end,
                                        hslk.n2v("黑龙王子的徽记", "slk", "Art"),
                                        "屠龙者的咆哮：物理和法术暴击提高2%，单位等级高于60无效。",
                                        1,
                                        nil,
                                        nil,
                                        nil,
                                        nil,
                                        HBUFF_UPDATE_MODE.OVERWRITE,
                                        false
                                    )
                                end
                            end
                        end
                    end,
                    level = 60
                }
            }
        },
        {
            name = "福吉菲尔的新研究",
            currentIndex = 1,
            questType = QUEST_TYPE.INFINITE,
            data = {
                {
                    index = 1, --索引 每个任务线必须有从1开始的连续的索引 否则初始化报错
                    resources = {
                        { HSHOP_COST_TYPE.gold,       QUEST_JIANGLI_SCALE_TYPE.SMALL },
                        { HSHOP_COST_TYPE.experience, QUEST_JIANGLI_SCALE_TYPE.SMALL }
                    }, --资源奖励
                    shengwang = {
                        {
                            value = 200,
                            shengwangname = "峡谷前哨站"
                        }
                    },
                    art = "ReplaceableTextures\\Quest\\qita.blp", --任务图标文件
                    text = "传奇铁匠福吉菲尔正在研究草药炼器法，因为需要大量火焰草。快去去看一眼。", --任务文本
                    finishText = "太好了！你们还有吗？有多少我要多少！",
                    title = "收集火焰草", -- 任务标题
                    req = {
                        {
                            type = QUEST_CUSTOM_EXECUTE_TYPE.HAS_ITEM_IN_BAG,
                            name = "火焰草",
                            number = 20
                        }
                    },
                    finish = QUEST_CUSTOM_FINISH_TYPE.talkToNPC, -- 任务完成方法 可以是立即完成，靠近npc或者 对话（npc带一个技能
                    finishNPC = "传奇铁匠福吉菲尔",
                    level = 40
                }
            }
        }
    }
    local jiangliConfig = {}
    local goldConfig = {}
    goldConfig[QUEST_JIANGLI_SCALE_TYPE.TINY] = function(level)
        return 50
    end
    goldConfig[QUEST_JIANGLI_SCALE_TYPE.SMALL] = function(level)
        return math.max(50, level * 25)
    end
    goldConfig[QUEST_JIANGLI_SCALE_TYPE.MEDIUM] = function(level)
        return math.max(50, level * 50)
    end
    goldConfig[QUEST_JIANGLI_SCALE_TYPE.LARGE] = function(level)
        return math.max(50, level * 100)
    end
    goldConfig[QUEST_JIANGLI_SCALE_TYPE.HUGE] = function(level)
        return math.max(50, level * 400)
    end
    jiangliConfig[HSHOP_COST_TYPE.gold] = goldConfig

    local expConfig = {}
    expConfig[QUEST_JIANGLI_SCALE_TYPE.TINY] = function(level)
        local expNeededForThisLevel = hhero.getExpNeed(level + 1) - hhero.getExpNeed(level)
        return math.max(100, math.ceil(0.05 * expNeededForThisLevel) + level * 40)
    end
    expConfig[QUEST_JIANGLI_SCALE_TYPE.SMALL] = function(level)
        local expNeededForThisLevel = hhero.getExpNeed(level + 1) - hhero.getExpNeed(level)
        return math.max(100, math.ceil(0.1 * expNeededForThisLevel) + level * 80)
    end
    expConfig[QUEST_JIANGLI_SCALE_TYPE.MEDIUM] = function(level)
        local expNeededForThisLevel = hhero.getExpNeed(level + 1) - hhero.getExpNeed(level)
        return math.max(100, math.ceil(0.2 * expNeededForThisLevel) + level * 160)
    end
    expConfig[QUEST_JIANGLI_SCALE_TYPE.LARGE] = function(level)
        local expNeededForThisLevel = hhero.getExpNeed(level + 1) - hhero.getExpNeed(level)
        return math.max(100, math.ceil(0.4 * expNeededForThisLevel) + level * 320)
    end
    expConfig[QUEST_JIANGLI_SCALE_TYPE.HUGE] = function(level)
        local expNeededForThisLevel = hhero.getExpNeed(level + 1) - hhero.getExpNeed(level)
        return math.max(100, math.ceil(0.8 * expNeededForThisLevel) + level * 640)
    end
    jiangliConfig[HSHOP_COST_TYPE.experience] = expConfig

    local sexpConfig = {}
    sexpConfig[QUEST_JIANGLI_SCALE_TYPE.TINY] = function(level)
        return 2000
    end
    sexpConfig[QUEST_JIANGLI_SCALE_TYPE.SMALL] = function(level)
        return 4000
    end
    sexpConfig[QUEST_JIANGLI_SCALE_TYPE.MEDIUM] = function(level)
        return 8000
    end
    sexpConfig[QUEST_JIANGLI_SCALE_TYPE.LARGE] = function(level)
        return 16000
    end
    sexpConfig[QUEST_JIANGLI_SCALE_TYPE.HUGE] = function(level)
        return 32000
    end
    jiangliConfig[HSHOP_COST_TYPE.dianfengjingyan] = sexpConfig

    local attrJiangliConfig = {}
    local quanshuxingConfig = {}
    local quanshuxingPerLevel = {}
    quanshuxingPerLevel[1] = 1
    for i = 2, 100 do
        quanshuxingPerLevel[i] = quanshuxingPerLevel[i - 1] * 1.04
    end
    quanshuxingConfig[QUEST_JIANGLI_SCALE_TYPE.TINY] = function(level)
        local number = "+" .. tostring(math.ceil(quanshuxingPerLevel[level]))
        return _attr(
            {
                zhushuxing = number
            }
        )
    end
    quanshuxingConfig[QUEST_JIANGLI_SCALE_TYPE.SMALL] = function(level)
        local number = "+" .. tostring(math.ceil(quanshuxingPerLevel[level] * 1.2))
        return _attr(
            {
                zhushuxing = number
            }
        )
    end
    quanshuxingConfig[QUEST_JIANGLI_SCALE_TYPE.MEDIUM] = function(level)
        local number = "+" .. tostring(math.ceil(quanshuxingPerLevel[level] * 1.5))
        return _attr(
            {
                zhushuxing = number
            }
        )
    end
    quanshuxingConfig[QUEST_JIANGLI_SCALE_TYPE.LARGE] = function(level)
        local number = "+" .. tostring(math.ceil(quanshuxingPerLevel[level] * 2))
        return _attr(
            {
                zhushuxing = number
            }
        )
    end
    quanshuxingConfig[QUEST_JIANGLI_SCALE_TYPE.HUGE] = function(level)
        local number = "+" .. tostring(math.ceil(quanshuxingPerLevel[level] * 3))
        return _attr(
            {
                zhushuxing = number
            }
        )
    end
    attrJiangliConfig.quanshuxing = quanshuxingConfig
    local diaoyurateJiangliConfig = {}
    diaoyurateJiangliConfig[QUEST_JIANGLI_SCALE_TYPE.TINY] = function(level)
        return _attr(
            {
                diaoyu_rate = "+1"
            }
        )
    end
    diaoyurateJiangliConfig[QUEST_JIANGLI_SCALE_TYPE.SMALL] = function(level)
        local number = "+" .. tostring(math.ceil(quanshuxingPerLevel[level] * 1.2))
        return _attr(
            {
                diaoyu_rate = "+3"
            }
        )
    end
    diaoyurateJiangliConfig[QUEST_JIANGLI_SCALE_TYPE.MEDIUM] = function(level)
        local number = "+" .. tostring(math.ceil(quanshuxingPerLevel[level] * 1.5))
        return _attr(
            {
                diaoyu_rate = "+6"
            }
        )
    end
    diaoyurateJiangliConfig[QUEST_JIANGLI_SCALE_TYPE.LARGE] = function(level)
        local number = "+" .. tostring(math.ceil(quanshuxingPerLevel[level] * 2))
        return _attr(
            {
                diaoyu_rate = "+12"
            }
        )
    end
    diaoyurateJiangliConfig[QUEST_JIANGLI_SCALE_TYPE.HUGE] = function(level)
        local number = "+" .. tostring(math.ceil(quanshuxingPerLevel[level] * 3))
        return _attr(
            {
                diaoyu_rate = "+24"
            }
        )
    end
    attrJiangliConfig.diaoyurate = diaoyurateJiangliConfig
    hquestcustom.init(config, jiangliConfig, attrJiangliConfig)

    hshop.addItem(
        "虚空商人",
        hitem.getColoredNameBasedOnPinzhi("灰烬之力"),
        hslk.n2v("灰烬之力", "Art"),
        { { type = HSHOP_COST_TYPE.gold, value = 150000 } },
        {},
        "你是否丢失了灰烬之力？没关系，我的团队专门从虚空中找到有价值的物品，一定可以帮你找回来！当然，这需要花点钱，而且你必须已经完成了灰烬之力任务线。",
        function(whichPlayer)
            local dynamicItem = DynamicItem(hslk.n2i("灰烬之力"))
            local pinzhi = hitem.getItemMinPinzhi(hslk.n2i("灰烬之力"))
            dynamicItem.pinzhi = pinzhi
            dynamicItem.setOwner(whichPlayer)
            dynamicItem.setStack(1)
            dynamicItem.initBasedOnPinzhi(pinzhi, 45, nil, nil, { hplayer.getMainHero(whichPlayer) })
            hitem.create(
                {
                    id = hslk.n2i("灰烬之力"),
                    charges = 1,
                    whichUnit = hplayer.getMainHero(whichPlayer),
                    dynamicItem = dynamicItem
                }
            )
            echo("获得：" .. hitem.getColoredNameBasedOnPinzhi("灰烬之力"), whichPlayer)
        end,
        function(whichPlayer)
            if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：灰烬之力") then
                return true
            else
                return false
            end
        end
    )

    hshop.addItem(
        "虚空商人",
        hitem.getColoredNameBasedOnPinzhi("真鳞胸甲"),
        hslk.n2v("真鳞胸甲", "Art"),
        { { type = HSHOP_COST_TYPE.gold, value = 100000 } },
        {},
        "你是否丢失了真鳞胸甲？没关系，我的团队专门从虚空中找到有价值的物品，一定可以帮你找回来！当然，这需要花点钱，而且你必须已经完成了真鳞胸甲任务线。",
        function(whichPlayer)
            local dynamicItem = DynamicItem(hslk.n2i("真鳞胸甲"))
            local pinzhi = hitem.getItemMinPinzhi(hslk.n2i("真鳞胸甲"))
            dynamicItem.pinzhi = pinzhi
            dynamicItem.setOwner(whichPlayer)
            dynamicItem.setStack(1)
            dynamicItem.initBasedOnPinzhi(pinzhi, 30, nil, nil, { hplayer.getMainHero(whichPlayer) })
            hitem.create(
                {
                    id = hslk.n2i("真鳞胸甲"),
                    charges = 1,
                    whichUnit = hplayer.getMainHero(whichPlayer),
                    dynamicItem = dynamicItem
                }
            )
            echo("获得：" .. hitem.getColoredNameBasedOnPinzhi("真鳞胸甲"), whichPlayer)
        end,
        function(whichPlayer)
            if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：真鳞胸甲") then
                return true
            else
                return false
            end
        end
    )

    hshop.addItem(
        "虚空商人",
        hitem.getColoredNameBasedOnPinzhi("炎魔之手"),
        hslk.n2v("炎魔之手", "Art"),
        { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 3 } },
        {},
        "你是否丢失了" ..
        hitem.getColoredNameBasedOnPinzhi("炎魔之手") ..
        "？没关系，我的团队专门从虚空中找到有价值的物品，一定可以帮你找回来！当然，这需要花点钱，而且你必须已经完成了炎魔之手任务线。",
        function(whichPlayer)
            local dynamicItem = DynamicItem(hslk.n2i("炎魔之手"))
            local pinzhi = hitem.getItemMinPinzhi(hslk.n2i("炎魔之手"))
            dynamicItem.pinzhi = pinzhi
            dynamicItem.setOwner(whichPlayer)
            dynamicItem.setStack(1)
            dynamicItem.initBasedOnPinzhi(pinzhi, 60, nil, nil, { hplayer.getMainHero(whichPlayer) })
            hitem.create(
                {
                    id = hslk.n2i("炎魔之手"),
                    charges = 1,
                    whichUnit = hplayer.getMainHero(whichPlayer),
                    dynamicItem = dynamicItem
                }
            )
            echo("获得：" .. hitem.getColoredNameBasedOnPinzhi("炎魔之手"), whichPlayer)
        end,
        function(whichPlayer)
            if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：炎魔之手") then
                return true
            else
                return false
            end
        end
    )

    hshop.addItem(
        "虚空商人",
        hitem.getColoredNameBasedOnPinzhi("雷霆之怒·逐风者之剑"),
        hslk.n2v("雷霆之怒·逐风者之剑", "Art"),
        { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 3 } },
        {},
        "你是否丢失了" ..
        hitem.getColoredNameBasedOnPinzhi("雷霆之怒·逐风者之剑") ..
        "？没关系，我的团队专门从虚空中找到有价值的物品，一定可以帮你找回来！当然，这需要花点钱，而且你必须已经完成了雷霆之怒任务线。",
        function(whichPlayer)
            local dynamicItem = DynamicItem(hslk.n2i("雷霆之怒·逐风者之剑"))
            local pinzhi = hitem.getItemMinPinzhi(hslk.n2i("雷霆之怒·逐风者之剑"))
            dynamicItem.pinzhi = pinzhi
            dynamicItem.setOwner(whichPlayer)
            dynamicItem.setStack(1)
            dynamicItem.initBasedOnPinzhi(pinzhi, 60, nil, nil, { hplayer.getMainHero(whichPlayer) })
            hitem.create(
                {
                    id = hslk.n2i("雷霆之怒·逐风者之剑"),
                    charges = 1,
                    whichUnit = hplayer.getMainHero(whichPlayer),
                    dynamicItem = dynamicItem
                }
            )
            echo("获得：" .. hitem.getColoredNameBasedOnPinzhi("雷霆之怒·逐风者之剑"), whichPlayer)
        end,
        function(whichPlayer)
            if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：雷霆之怒") then
                return true
            else
                return false
            end
        end
    )

    hshop.addItem(
        "虚空商人",
        hitem.getColoredNameBasedOnPinzhi("埃提耶什·守护者之杖"),
        hslk.n2v("埃提耶什·守护者之杖", "Art"),
        { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 3 } },
        {},
        "你是否丢失了" ..
        hitem.getColoredNameBasedOnPinzhi("埃提耶什·守护者之杖") ..
        "？没关系，我的团队专门从虚空中找到有价值的物品，一定可以帮你找回来！当然，这需要花点钱，而且你必须已经完成了埃提耶什任务线。",
        function(whichPlayer)
            local dynamicItem = DynamicItem(hslk.n2i("埃提耶什·守护者之杖"))
            local pinzhi = hitem.getItemMinPinzhi(hslk.n2i("埃提耶什·守护者之杖"))
            dynamicItem.pinzhi = pinzhi
            dynamicItem.setOwner(whichPlayer)
            dynamicItem.setStack(1)
            dynamicItem.initBasedOnPinzhi(pinzhi, 60, nil, nil, { hplayer.getMainHero(whichPlayer) })
            hitem.create(
                {
                    id = hslk.n2i("埃提耶什·守护者之杖"),
                    charges = 1,
                    whichUnit = hplayer.getMainHero(whichPlayer),
                    dynamicItem = dynamicItem
                }
            )
            echo("获得：" .. hitem.getColoredNameBasedOnPinzhi("埃提耶什·守护者之杖"), whichPlayer)
        end,
        function(whichPlayer)
            if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：埃提耶什") then
                return true
            else
                return false
            end
        end
    )

    hshop.addItem(
        "虚空商人",
        hitem.getColoredNameBasedOnPinzhi("血吼"),
        hslk.n2v("血吼", "Art"),
        { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 3 } },
        {},
        "你是否丢失了" ..
        hitem.getColoredNameBasedOnPinzhi("血吼") ..
        "？没关系，我的团队专门从虚空中找到有价值的物品，一定可以帮你找回来！当然，这需要花点钱，而且你必须已经完成了血吼任务线。",
        function(whichPlayer)
            local dynamicItem = DynamicItem(hslk.n2i("血吼"))
            local pinzhi = hitem.getItemMinPinzhi(hslk.n2i("血吼"))
            dynamicItem.pinzhi = pinzhi
            dynamicItem.setOwner(whichPlayer)
            dynamicItem.setStack(1)
            dynamicItem.initBasedOnPinzhi(pinzhi, 70, nil, nil, { hplayer.getMainHero(whichPlayer) })
            hitem.create(
                {
                    id = hslk.n2i("血吼"),
                    charges = 1,
                    whichUnit = hplayer.getMainHero(whichPlayer),
                    dynamicItem = dynamicItem
                }
            )
            echo("获得：" .. hitem.getColoredNameBasedOnPinzhi("血吼"), whichPlayer)
        end,
        function(whichPlayer)
            if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：血吼") then
                return true
            else
                return false
            end
        end
    )

    hshop.addItem(
        "虚空商人",
        hitem.getColoredNameBasedOnPinzhi("烈焰之击"),
        hslk.n2v("烈焰之击", "Art"),
        { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 3 } },
        {},
        "你是否丢失了" ..
        hitem.getColoredNameBasedOnPinzhi("烈焰之击") ..
        "？没关系，我的团队专门从虚空中找到有价值的物品，一定可以帮你找回来！当然，这需要花点钱，而且你必须已经完成了烈焰之击任务线。",
        function(whichPlayer)
            local dynamicItem = DynamicItem(hslk.n2i("烈焰之击"))
            local pinzhi = hitem.getItemMinPinzhi(hslk.n2i("烈焰之击"))
            dynamicItem.pinzhi = pinzhi
            dynamicItem.setOwner(whichPlayer)
            dynamicItem.setStack(1)
            dynamicItem.initBasedOnPinzhi(pinzhi, 71, nil, nil, { hplayer.getMainHero(whichPlayer) })
            hitem.create(
                {
                    id = hslk.n2i("烈焰之击"),
                    charges = 1,
                    whichUnit = hplayer.getMainHero(whichPlayer),
                    dynamicItem = dynamicItem
                }
            )
            echo("获得：" .. hitem.getColoredNameBasedOnPinzhi("烈焰之击"), whichPlayer)
        end,
        function(whichPlayer)
            if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：烈焰之击") then
                return true
            else
                return false
            end
        end
    )

    hshop.addItem(
        "虚空商人",
        hitem.getColoredNameBasedOnPinzhi("深渊垂钓者"),
        hslk.n2v("深渊垂钓者", "Art"),
        { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 3 } },
        {},
        "你是否丢失了" ..
        hitem.getColoredNameBasedOnPinzhi("深渊垂钓者") ..
        "？没关系，我的团队专门从虚空中找到有价值的物品，一定可以帮你找回来！当然，这需要花点钱，而且你必须已经完成了深渊垂钓者任务线。",
        function(whichPlayer)
            local dynamicItem = DynamicItem(hslk.n2i("深渊垂钓者"))
            local pinzhi = hitem.getItemMinPinzhi(hslk.n2i("深渊垂钓者"))
            dynamicItem.pinzhi = pinzhi
            dynamicItem.setOwner(whichPlayer)
            dynamicItem.setStack(1)
            dynamicItem.initBasedOnPinzhi(pinzhi, 70, nil, nil, { hplayer.getMainHero(whichPlayer) })
            hitem.create(
                {
                    id = hslk.n2i("深渊垂钓者"),
                    charges = 1,
                    whichUnit = hplayer.getMainHero(whichPlayer),
                    dynamicItem = dynamicItem
                }
            )
            echo("获得：" .. hitem.getColoredNameBasedOnPinzhi("深渊垂钓者"), whichPlayer)
        end,
        function(whichPlayer)
            if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：深渊垂钓者") then
                return true
            else
                return false
            end
        end
    )

    hshop.addItem(
        "虚空商人",
        hitem.getColoredNameBasedOnPinzhi("恶魔战刃（主手）"),
        hslk.n2v("恶魔战刃（主手）", "Art"),
        { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 3 } },
        {},
        "你是否丢失了" ..
        hitem.getColoredNameBasedOnPinzhi("恶魔战刃（主手）") ..
        "？没关系，我的团队专门从虚空中找到有价值的物品，一定可以帮你找回来！当然，这需要花点钱，而且你必须已经完成了恶魔战刃任务线。",
        function(whichPlayer)
            local dynamicItem = DynamicItem(hslk.n2i("恶魔战刃（主手）"))
            local pinzhi = hitem.getItemMinPinzhi(hslk.n2i("恶魔战刃（主手）"))
            dynamicItem.pinzhi = pinzhi
            dynamicItem.setOwner(whichPlayer)
            dynamicItem.setStack(1)
            dynamicItem.initBasedOnPinzhi(pinzhi, 72, nil, nil, { hplayer.getMainHero(whichPlayer) })
            hitem.create(
                {
                    id = hslk.n2i("恶魔战刃（主手）"),
                    charges = 1,
                    whichUnit = hplayer.getMainHero(whichPlayer),
                    dynamicItem = dynamicItem
                }
            )
            echo("获得：" .. hitem.getColoredNameBasedOnPinzhi("恶魔战刃（主手）"), whichPlayer)
        end,
        function(whichPlayer)
            if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：恶魔战刃") then
                return true
            else
                return false
            end
        end
    )

    hshop.addItem(
        "虚空商人",
        hitem.getColoredNameBasedOnPinzhi("恶魔战刃（副手）"),
        hslk.n2v("恶魔战刃（副手）", "Art"),
        { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 3 } },
        {},
        "你是否丢失了" ..
        hitem.getColoredNameBasedOnPinzhi("恶魔战刃（副手）") ..
        "？没关系，我的团队专门从虚空中找到有价值的物品，一定可以帮你找回来！当然，这需要花点钱，而且你必须已经完成了恶魔战刃任务线。",
        function(whichPlayer)
            local dynamicItem = DynamicItem(hslk.n2i("恶魔战刃（副手）"))
            local pinzhi = hitem.getItemMinPinzhi(hslk.n2i("恶魔战刃（副手）"))
            dynamicItem.pinzhi = pinzhi
            dynamicItem.setOwner(whichPlayer)
            dynamicItem.setStack(1)
            dynamicItem.initBasedOnPinzhi(pinzhi, 72, nil, nil, { hplayer.getMainHero(whichPlayer) })
            hitem.create(
                {
                    id = hslk.n2i("恶魔战刃（副手）"),
                    charges = 1,
                    whichUnit = hplayer.getMainHero(whichPlayer),
                    dynamicItem = dynamicItem
                }
            )
            echo("获得：" .. hitem.getColoredNameBasedOnPinzhi("恶魔战刃（副手）"), whichPlayer)
        end,
        function(whichPlayer)
            if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：恶魔战刃") then
                return true
            else
                return false
            end
        end
    )

    hshop.addItem(
        "虚空商人",
        hitem.getColoredNameBasedOnPinzhi("群星之怒·暗月"),
        hslk.n2v("群星之怒·暗月", "Art"),
        { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 3 } },
        {},
        "你是否丢失了" ..
        hitem.getColoredNameBasedOnPinzhi("群星之怒·暗月") ..
        "？没关系，我的团队专门从虚空中找到有价值的物品，一定可以帮你找回来！当然，这需要花点钱，而且你必须已经完成了群星之怒任务线。",
        function(whichPlayer)
            local dynamicItem = DynamicItem(hslk.n2i("群星之怒·暗月"))
            local pinzhi = hitem.getItemMinPinzhi(hslk.n2i("群星之怒·暗月"))
            dynamicItem.pinzhi = pinzhi
            dynamicItem.setOwner(whichPlayer)
            dynamicItem.setStack(1)
            dynamicItem.initBasedOnPinzhi(pinzhi, 73, nil, nil, { hplayer.getMainHero(whichPlayer) })
            hitem.create(
                {
                    id = hslk.n2i("群星之怒·暗月"),
                    charges = 1,
                    whichUnit = hplayer.getMainHero(whichPlayer),
                    dynamicItem = dynamicItem
                }
            )
            echo("获得：" .. hitem.getColoredNameBasedOnPinzhi("群星之怒·暗月"), whichPlayer)
        end,
        function(whichPlayer)
            if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：群星之怒") then
                return true
            else
                return false
            end
        end
    )

    hshop.addItem(
        "虚空商人",
        hitem.getColoredNameBasedOnPinzhi("群星之怒·烈阳"),
        hslk.n2v("群星之怒·烈阳", "Art"),
        { { type = HSHOP_COST_TYPE.maoxianzhehuizhang, value = 3 } },
        {},
        "你是否丢失了" ..
        hitem.getColoredNameBasedOnPinzhi("群星之怒·烈阳") ..
        "？没关系，我的团队专门从虚空中找到有价值的物品，一定可以帮你找回来！当然，这需要花点钱，而且你必须已经完成了群星之怒任务线。",
        function(whichPlayer)
            local dynamicItem = DynamicItem(hslk.n2i("群星之怒·烈阳"))
            local pinzhi = hitem.getItemMinPinzhi(hslk.n2i("群星之怒·烈阳"))
            dynamicItem.pinzhi = pinzhi
            dynamicItem.setOwner(whichPlayer)
            dynamicItem.setStack(1)
            dynamicItem.initBasedOnPinzhi(pinzhi, 73, nil, nil, { hplayer.getMainHero(whichPlayer) })
            hitem.create(
                {
                    id = hslk.n2i("群星之怒·烈阳"),
                    charges = 1,
                    whichUnit = hplayer.getMainHero(whichPlayer),
                    dynamicItem = dynamicItem
                }
            )
            echo("获得：" .. hitem.getColoredNameBasedOnPinzhi("群星之怒·烈阳"), whichPlayer)
        end,
        function(whichPlayer)
            if hquestcustom.isQuestFinished(whichPlayer, "传奇任务：群星之怒") then
                return true
            else
                return false
            end
        end
    )
end
