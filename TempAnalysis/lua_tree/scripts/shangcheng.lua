initShangcheng = function()
    local config = {
        {
            name = "财富石",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\财富石.blp",
            key = "SCJBCFS",
            description = "可以增加杀怪金币获取，在商城金币购买",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ gold_ratio = "+1" })
                }
            }
        },
        {
            name = "经验石",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\经验石.blp",
            key = "SCJBJYS",
            description = "可以增加杀怪经验获取，在商城金币购买",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1" })
                }
            }
        },
        {
            name = "防御专精",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\防御专精.blp",
            key = "SCQTFYZJ",
            description = "提高5点基础防御力",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            defend_white = "+5"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "格挡专精",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\格挡专精.blp",
            key = "SCQTGDZJ",
            description = "提高0.5%格挡概率",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            gedang = "+0.5"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "攻击祝福",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\攻击祝福.blp",
            key = "SCQTGJZF",
            description = "提高5点基础攻击力",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            attack_white = "+5"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "恢复祝福",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\恢复祝福.blp",
            key = "SCQTHFZJ",
            description = "提高1点每秒生命恢复速度",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            life_back = "+1"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "金币专精",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\金币专精.blp",
            key = "SCQTJBZJ",
            description = "提高1%金币获取",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            gold_ratio = "+1"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "经验祝福",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\经验祝福.blp",
            key = "SCQTJYZF",
            description = "提高1%经验获取",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            exp_ratio = "+1"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "闪避祝福",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\闪避祝福.blp",
            key = "SCQTSBZF",
            description = "提高0.5%闪避概率",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            shanbi = "+0.5"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "生命祝福",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\生命祝福.blp",
            key = "SCQTSMZF",
            description = "提高20点基础生命值",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            life = "+20"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "属性祝福",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\属性祝福.blp",
            key = "SCQTSXZF",
            description = "提高5点基础主属性",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            zhushuxing = "+5"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "速度专精",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\速度专精.blp",
            key = "SCQTSDZJ",
            description = "提高3点基础移动速度",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            move = "+3"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "伤害专精",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\伤害专精.blp",
            key = "SCQTSHZJ",
            description = "提高0.2%所有伤害",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            quanju_zengshang = "+0.2"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "魔法伤害专精",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\魔法伤害专精.blp",
            key = "SCQTMFSHZJ",
            description = "提高0.2%魔法增伤",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            fa_zengshang = "+0.2"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "魔法暴击专精",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\魔法暴击专精.blp",
            key = "SCQTMFBJZJ",
            description = "提高0.2%法术暴击概率",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            fa_bao = "+0.2"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "物理伤害专精",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\物理伤害专精.blp",
            key = "SCQTWLSHZJ",
            description = "提高0.2%物理伤害",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            wu_zengshang = "+0.2"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "物理暴击专精",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\物理暴击专精.blp",
            key = "SCQTWLBJZJ",
            description = "增加0.2%物理暴击概率",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            wu_bao = "+0.2"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "高级剥皮刀",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\高级剥皮刀.blp",
            key = "SCWPGJBPD",
            description = "增加10%剥皮成功率",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ baopi_rate = "+10" })
                }
            }
        },
        {
            name = "高级采药手套",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\高级采药手套.blp",
            key = "SCWPGJCYST",
            description = "增加10%采药获得草药的概率",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ caiyao_rate = "+10" })
                }
            }
        },
        {
            name = "高级锄",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\高级锄.blp",
            key = "SCWPGJC",
            description = "增加10%采矿获得矿物的概率",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ caikuang_rate = "+10" })
                }
            }
        },
        {
            name = "高级鱼竿",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\高级鱼竿.blp",
            key = "SCWPGJYG",
            description = "增加10%钓鱼成功率",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ diaoyu_rate = "+10" })
                }
            }
        },
        {
            name = "高级制布刀",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\高级制布刀.blp",
            key = "SCWPGJZBD",
            description = "增加10%收集布料成功率",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhibu_rate = "+10" })
                }
            }
        },
        {
            name = "高级采集工具盒",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\Achievement_ChallengeMode_MogushanPalace_Bronze.blp",
            description = "激活所有高级采集工具获得额外效果，采集速度增加。" .. hcolor.yellow("采集加速效果类似攻击和施法加速，100%加速意味着采集需要的时间降低一半，并非0间隔。"),
            shangchengtype = SHANGCHENG_TYPE.DEPENDENCY,
            dependency = { "高级剥皮刀", "高级采药手套", "高级锄", "高级鱼竿", "高级制布刀" },
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ caiji_speed = "+50" })
                }
            }
        },
        {
            name = "冒险手册",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\冒险手册.blp",
            key = "SCWPMXZSC",
            description = "可以增加20%怪物图鉴爆率",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ tujian_rate = "+20" })
                }
            }
        },
        {
            name = "青铜VIP",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\qtvip.blp",
            key = "SCQTVIP",
            description = "支持作者",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ exp_ratio = "+1", gold_ratio = "+1" })
                }
            },
            whiteList = { "呮茵伱呔媄#4613", "毁灭利刃#9142" }
        },
        {
            name = "白银VIP",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\byvip.blp",
            key = "SCBYVIP",
            description = "支持作者",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        { exp_ratio = "+2", gold_ratio = "+2", extra_ditudengji = "+1", life = "+50", life_back = "+1" }
                    )
                }
            },
            whiteList = { "呮茵伱呔媄#4613", "毁灭利刃#9142" }
        },
        {
            name = "黄金VIP",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\hjvip.blp",
            key = "SCHJVIP",
            description = "支持作者",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        { exp_ratio = "+2", gold_ratio = "+2", extra_ditudengji = "+2", life = "+80", life_back = "+2" }
                    )
                }
            },
            whiteList = { "呮茵伱呔媄#4613", "毁灭利刃#9142" }
        },
        {
            name = "铂金VIP",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\bjvip.blp",
            key = "SCBJVIP",
            description = "支持作者",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            exp_ratio = "+2",
                            gold_ratio = "+2",
                            extra_ditudengji = "+3",
                            life = "+120",
                            life_back = "+5",
                            extra_dianfeng = "+1"
                        }
                    )
                }
            },
            whiteList = {
                "开水来了让让#9082",
                "奶秀呀#5934",
                "萌萌哒小法#6536",
                "Eversee#7864",
                "质变大老#4318",
                "柠檬#1382",
                "Cunjunn#4549",
                "秋灬小杰#7398",
                "南山梦柯人#2168",
                "羊肉包子#3436",
                "呮茵伱呔媄#4613",
                "毁灭利刃#9142"
            }
        },
        {
            name = "钻石VIP",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\zsvip.blp",
            key = "SCZSVIP",
            description = "支持作者",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            exp_ratio = "+2",
                            gold_ratio = "+2",
                            extra_ditudengji = "+4",
                            life = "+150",
                            life_back = "+10",
                            extra_dianfeng = "+2"
                        }
                    )
                }
            },
            whiteList = { "呮茵伱呔媄#4613", "毁灭利刃#9142" }
        },
        {
            name = "巅峰VIP",
            pinzhi = ZHUANGBEI_PINZHI.SHENHUA,
            art = "ReplaceableTextures\\shangcheng\\巅峰VIP.blp",
            key = "SCDFVIP",
            description = "支持作者",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            exp_ratio = "+5",
                            gold_ratio = "+5",
                            extra_ditudengji = "+5",
                            life = "+300",
                            life_back = "+20",
                            extra_dianfeng = "+2"
                        }
                    )
                },
                {
                    description = "材料背包格子+40",
                    attr_type = CONST_EVENT.noeffect
                },
                {
                    description = "装备背包格子+15",
                    attr_type = CONST_EVENT.noeffect
                }
            },
            whiteList = { "呮茵伱呔媄#4613", "毁灭利刃#9142" }
        },
        {
            name = "小材料包",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\小材料包8.blp",
            key = "SCCLBXCLB",
            description = "支持作者",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "材料背包格子+8",
                    attr_type = CONST_EVENT.noeffect
                }
            },
            whiteList = { "呮茵伱呔媄#4613", "毁灭利刃#9142" }
        },
        {
            name = "中材料包",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\中材料包16.blp",
            key = "SCCLBZCLB",
            description = "支持作者",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "材料背包格子+16",
                    attr_type = CONST_EVENT.noeffect
                }
            },
            whiteList = { "呮茵伱呔媄#4613", "毁灭利刃#9142" }
        },
        {
            name = "大材料包",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\大材料包24.blp",
            key = "SCCLBDCLB",
            description = "支持作者",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "材料背包格子+24",
                    attr_type = CONST_EVENT.noeffect
                }
            },
            whiteList = { "呮茵伱呔媄#4613", "毁灭利刃#9142" }
        },
        {
            name = "巨无霸材料包",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\巨无霸材料包32.blp",
            key = "SCCLBJWB",
            description = "支持作者",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "材料背包格子+32",
                    attr_type = CONST_EVENT.noeffect
                }
            },
            whiteList = { "呮茵伱呔媄#4613", "毁灭利刃#9142" }
        },
        {
            name = "我超能装",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\INV_Misc_Bag_33.blp",
            description = "集齐四种不同的包后激活该效果.",
            shangchengtype = SHANGCHENG_TYPE.DEPENDENCY,
            dependency = { "小材料包", "中材料包", "大材料包", "巨无霸材料包" },
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "材料背包格子+20",
                    attr_type = CONST_EVENT.noeffect
                },
                {
                    description = "装备背包格子+15",
                    attr_type = CONST_EVENT.noeffect
                }
            }
        },
        {
            name = "荣誉会员",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\荣誉会员.blp",
            key = "SCRYHY",
            description =
                "荣誉会员的凭证。传送免费，增加金币获取，洗天赋金币消耗降低25%，矿石，草药和钓鱼点的最大堆叠数+8，采矿，采药和钓鱼的速度提高50%。同时降低副本刷新间隔（最低60秒）。并且自动拾取可以跳过基础装备。" ..
                hcolor.yellow("采集加速效果类似攻击和施法加速，100%加速意味着采集需要的时间降低一半，并非0间隔。"),
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ caiji_speed = "+50", gold_ratio = "+5", fuben_refresh_reduction = "+100" })
                }
            },
            whiteList = { "呮茵伱呔媄#4613", "毁灭利刃#9142" }
        },
        {
            name = "吉安娜的祝福",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\SSR_吉安娜.blp",
            key = "SCCJMDWZF",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            exp_ratio = "+2",
                            gold_ratio = "+2",
                            life = "+150",
                            life_back = "+10",
                            zhushuxing = "+20",
                            fa_bao = "+0.5",
                            skill_speed = "+2"
                        }
                    )
                }
            }
        },
        {
            name = "洛萨的祝福",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\SSR_洛萨.blp",
            key = "SCCJLSZF",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            exp_ratio = "+2",
                            gold_ratio = "+2",
                            life = "+150",
                            life_back = "+10",
                            master = "+5",
                            quanju_zengshang = "+0.5"
                        }
                    )
                }
            }
        },
        {
            name = "格罗姆的祝福",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\SSR_格罗姆.blp",
            key = "SCCJGLMZF",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            exp_ratio = "+2",
                            gold_ratio = "+2",
                            life = "+150",
                            life_back = "+10",
                            attack_white = "+20",
                            wu_bao = "+0.5",
                            attack_speed = "+2"
                        }
                    )
                }
            }
        },
        {
            name = "乌瑞恩的祝福",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\SSR_乌瑞恩.blp",
            key = "SCCJWREZF",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            exp_ratio = "+2",
                            gold_ratio = "+2",
                            life = "+100",
                            life_back = "+10",
                            attack_white = "+10",
                            wu_baoshang = "+2"
                        }
                    )
                }
            }
        },
        {
            name = "麦迪文的祝福",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\SSR_麦迪文.blp",
            key = "SCCJZMDWZF",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            exp_ratio = "+2",
                            gold_ratio = "+2",
                            life = "+100",
                            life_back = "+10",
                            zhushuxing = "+10",
                            fa_baoshang = "+2"
                        }
                    )
                }
            }
        },
        {
            name = "凯恩的祝福",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\凯恩的祝福.blp",
            key = "SCCJKEZF",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            exp_ratio = "+2",
                            gold_ratio = "+2",
                            life = "+200",
                            life_back = "+10",
                            zhushuxing = "+10",
                            shengming_baifenbi = "+2"
                        }
                    )
                }
            }
        },
        {
            name = "穆拉丁的祝福",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\穆拉丁的祝福.blp",
            key = "SCCJMLDZF",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            exp_ratio = "+2",
                            gold_ratio = "+2",
                            life = "+200",
                            life_back = "+10",
                            zhushuxing = "+10",
                            defend_white = "+10"
                        }
                    )
                }
            }
        },
        {
            name = "符文大师",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\符文大师.blp",
            key = "SCCJFWDS",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            fuwen_diaolv = "+10",
                            zhushuxing_baifenbi = "+1",
                        }
                    )
                }
            }
        },
        {
            name = "鉴定大师",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\鉴定大师.blp",
            key = "SCCJJDDS",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            lansecitiao_rate = "+2",
                            zisecitiao_rate = "+2",
                            zhushuxing_baifenbi = "+1",
                        }
                    )
                }
            }
        },
        {
            name = "寻宝大师",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\寻宝大师.blp",
            key = "SCCJXBDS",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            extra_drop_rate = "+5",
                            zhushuxing_baifenbi = "+1",
                        }
                    )
                }
            }
        },
        {
            name = "神器研究员",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\神器研究员.blp",
            key = "SCCJSQYJY",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            sqnl_huoqu = "+10",
                            zhushuxing_baifenbi = "+1",
                        }
                    )
                }
            }
        },
        {
            name = "黑暗游侠的祝福",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\黑暗游侠的祝福.blp",
            key = "SCCJHAYXZF",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            wu_zengshang = "+1",
                            zhushuxing_baifenbi = "+1",
                        }
                    )
                }
            }
        },
        {
            name = "卡德加的祝福",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\卡德加的祝福.blp",
            key = "SCCJKDJZF",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            fa_zengshang = "+1",
                            zhushuxing_baifenbi = "+1",
                        }
                    )
                }
            }
        },
        {
            name = "图拉杨的祝福",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\图拉杨.blp",
            key = "SCCJTLYZF",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            quanju_zengshang = "+1",
                            zhushuxing_baifenbi = "+1",
                        }
                    )
                }
            }
        },
        {
            name = "泰坦的祝福",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\泰坦的祝福.blp",
            key = "SCTAITANZF",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            quanju_zengshang = "+2",
                            wu_bao = "+1",
                            fa_bao = "+1",
                            jianshang = "+2",
                        }
                    )
                }
            }
        },
        {
            name = "古神的祝福",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\古神的祝福.blp",
            key = "SCGUSHENZF",
            description = "支持作者。宝箱抽奖获得，地图游戏时长任务会奖励抽奖券。",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            quanju_zengshang = "+2",
                            wu_chuan = "+1",
                            fa_chuan = "+1",
                            jianshang = "+2",
                        }
                    )
                }
            }
        },
        {
            name = "冒险者的徽章",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\baoshi6.blp", --TODO  换图标
            key = "SCMXZHZ",
            description = "冒险者工会发放的荣誉徽章，可以增加英雄的伤害。每10颗增加0.1%所有伤害。最大生效：1000个。地图游戏时长任务会奖励抽奖券，抽奖也可以获得。" ..
                hcolor.yellow("超出部分不生效。"),
            shangchengtype = SHANGCHENG_TYPE.DUIDIESHUXING,
            count = 0,
            maxCount = 1000,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ quanju_zengshang = "+0.1" }),
                    duidieCountPerEffect = 10
                }
            }
        },
        {
            name = "属性能量结晶",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\N_属性.blp",
            key = "SCSXNLJJ",
            description = "神奇的结晶，收集多颗可以增加主属性，每10颗增加1点主属性，每100颗增加0.5%主属性。最大生效：2000个。" .. hcolor.yellow("超出部分不生效。"),
            shangchengtype = SHANGCHENG_TYPE.DUIDIESHUXING,
            count = 0,
            maxCount = 2000,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing = "+1" }),
                    duidieCountPerEffect = 10
                },
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhushuxing_baifenbi = "+0.5" }),
                    duidieCountPerEffect = 100
                }
            }
        },
        {
            name = "生命能量结晶",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\N_生命.blp",
            key = "SCSMNLJJ",
            description = "神奇的结晶，收集多颗可以增加生命最大值，每1颗增加1点生命最大值，每100颗增加0.5%生命最大值。最大生效：2000个。" .. hcolor.yellow("超出部分不生效。"),
            shangchengtype = SHANGCHENG_TYPE.DUIDIESHUXING,
            count = 0,
            maxCount = 2000,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ life = "+1" }),
                    duidieCountPerEffect = 1
                },
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ shengming_baifenbi = "+0.5" }),
                    duidieCountPerEffect = 100
                }
            }
        },
        {
            name = "生命恢复能量结晶",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\N_生命回复.blp",
            key = "SCSMHFNLJJ",
            description = "神奇的结晶，收集多颗可以增加生命恢复速度，每10颗增加1点生命恢复速度。最大生效：2000个。" .. hcolor.yellow("超出部分不生效。"),
            shangchengtype = SHANGCHENG_TYPE.DUIDIESHUXING,
            count = 0,
            maxCount = 2000,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ life_back = "+1" }),
                    duidieCountPerEffect = 10
                }
            }
        },
        {
            name = "攻击能量结晶",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\N_攻击.blp",
            key = "SCGJNLJJ",
            description = "神奇的结晶，收集多颗可以增加攻击力，每10颗增加1点攻击力，每100颗增加0.5%攻击力。最大生效：2000个。" .. hcolor.yellow("超出部分不生效。"),
            shangchengtype = SHANGCHENG_TYPE.DUIDIESHUXING,
            count = 0,
            maxCount = 2000,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ attack_white = "+1" }),
                    duidieCountPerEffect = 10
                },
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ gongji_baifenbi = "+0.5" }),
                    duidieCountPerEffect = 100
                }
            }
        },
        {
            name = "防御能量结晶",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\R_防御.blp",
            key = "SCFYNLJJ",
            description = "神奇的结晶，收集多颗可以增加伤害抗性，每20颗增加0.1%点所有伤害减免。最大生效：1000个。" .. hcolor.yellow("超出部分不生效。"),
            shangchengtype = SHANGCHENG_TYPE.DUIDIESHUXING,
            count = 0,
            maxCount = 1000,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ jianshang = "+0.1" }),
                    duidieCountPerEffect = 20
                }
            }
        },
        {
            name = "灵敏能量结晶",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\R_灵敏.blp",
            key = "SCLMNLJJ",
            description = "神奇的结晶，收集多颗可以增加闪避能力，每10颗增加0.1%的闪避。最大生效：1000个。" .. hcolor.yellow("超出部分不生效。"),
            shangchengtype = SHANGCHENG_TYPE.DUIDIESHUXING,
            count = 0,
            maxCount = 1000,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ shanbi = "+0.1" }),
                    duidieCountPerEffect = 10
                }
            }
        },
        {
            name = "坚硬能量结晶",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\R_坚硬png.blp",
            key = "SCJYNLJJ",
            description = "神奇的结晶，收集多颗可以增加招架能力，每10颗增加0.1%招架概率。最大生效：1000个。" ..
                hcolor.yellow(
                    "超出部分不生效。同时，由于该结晶没有第一时间加到抽奖箱子里，许多玩家会出现其它水晶的数量远远大于此水晶数量，影响了游戏体验。作为补偿，此结晶会额外获得其余三种精良品质能量水晶的数量的平均值。"
                ),
            shangchengtype = SHANGCHENG_TYPE.DUIDIESHUXING,
            count = 0,
            maxCount = 1000,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ zhaojia = "+0.1" }),
                    duidieCountPerEffect = 10
                }
            }
        },
        {
            name = "灰暗能量结晶",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\R_灰暗.blp",
            key = "SCHANLJJ",
            description = "神奇的结晶，收集多颗可以增加魔法抗性，每20颗增加0.1%魔抗。最大生效：1000个。" .. hcolor.yellow("超出部分不生效。"),
            shangchengtype = SHANGCHENG_TYPE.DUIDIESHUXING,
            count = 0,
            maxCount = 1000,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ mokang = "+0.1" }),
                    duidieCountPerEffect = 20
                }
            }
        },
        {
            name = "尖锐能量结晶",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\SR_尖锐.blp",
            key = "SCJRNLJJ",
            description = "神奇的结晶，收集多颗可以增加物理伤害暴击概率，每10颗增加0.1%物理暴击率。最大生效：200个。" .. hcolor.yellow("超出部分不生效。"),
            shangchengtype = SHANGCHENG_TYPE.DUIDIESHUXING,
            count = 0,
            maxCount = 200,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ wu_bao = "+0.1" }),
                    duidieCountPerEffect = 10
                }
            }
        },
        {
            name = "闪耀能量结晶",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\SR_闪耀.blp",
            key = "SCSYNLJJ",
            description = "神奇的结晶，收集多颗可以增加法术暴击概率，每10颗增加0.1%法术暴击率。最大生效：200个。" .. hcolor.yellow("超出部分不生效。"),
            shangchengtype = SHANGCHENG_TYPE.DUIDIESHUXING,
            count = 0,
            maxCount = 200,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ fa_bao = "+0.1" }),
                    duidieCountPerEffect = 10
                }
            }
        },
        {
            name = "技巧能量结晶",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\SR_技巧.blp",
            key = "SCJQNLJJ",
            description = "神奇的结晶，收集多颗可以增加精通，每5颗增加1点。最大生效：200个。" .. hcolor.yellow("超出部分不生效。"),
            shangchengtype = SHANGCHENG_TYPE.DUIDIESHUXING,
            count = 0,
            maxCount = 200,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ master = "+1" }),
                    duidieCountPerEffect = 5
                }
            }
        },
        {
            name = "精准能量结晶",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\SR_精准.blp",
            key = "SCJZNLJJ",
            description = "神奇的结晶，收集多颗可以增加命中率，每5颗增加0.1%命中。最大生效：200个。" .. hcolor.yellow("超出部分不生效。"),
            shangchengtype = SHANGCHENG_TYPE.DUIDIESHUXING,
            count = 0,
            maxCount = 200,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr({ hit = "+0.1" }),
                    duidieCountPerEffect = 5
                }
            }
        },
        {
            name = "见习战斗贼",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\见习战斗贼.blp",
            key = "SCZJJXZDZ",
            description = "",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            zhushuxing = "+3"
                        }
                    )
                },
                {
                    description = "提高5%影袭伤害",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.triggerSkill == hslk.n2i("影袭") then
                            evtData.damage = evtData.damage * 1.05
                        end
                    end
                }
            }
        },
        {
            name = "见习火法",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\见习火法.blp",
            key = "SCZJJXHF",
            description = "",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            zhushuxing = "+3"
                        }
                    )
                },
                {
                    description = "提高5%火球术伤害",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.triggerSkill == hslk.n2i("火球术") then
                            evtData.damage = evtData.damage * 1.05
                        end
                    end
                }
            }
        },
        {
            name = "见习武器战",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\见习武器战.blp",
            key = "SCZJJXWQZ",
            description = "",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            zhushuxing = "+3"
                        }
                    )
                },
                {
                    description = "提高5%压制伤害",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.triggerSkill == hslk.n2i("压制") then
                            evtData.damage = evtData.damage * 1.05
                        end
                    end
                }
            }
        },
        {
            name = "见习狂暴战",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\见习狂暴战.blp",
            key = "SCZJJXKBZ",
            description = "",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            zhushuxing = "+3"
                        }
                    )
                },
                {
                    description = "提高5%怒击伤害",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.triggerSkill == hslk.n2i("怒击") then
                            evtData.damage = evtData.damage * 1.05
                        end
                    end
                }
            }
        },
        {
            name = "见习毁灭术",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\见习毁灭术.blp",
            key = "SCZJJXHMS",
            description = "",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            zhushuxing = "+3"
                        }
                    )
                },
                {
                    description = "提高5%烧尽伤害",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.triggerSkill == hslk.n2i("烧尽") then
                            evtData.damage = evtData.damage * 1.05
                        end
                    end
                }
            }
        },
        {
            name = "见习痛苦术",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\见习痛苦术.blp",
            key = "SCZJJXTKS",
            description = "",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            zhushuxing = "+3"
                        }
                    )
                },
                {
                    description = "提高5%腐蚀术伤害",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.triggerSkill == hslk.n2i("腐蚀术") then
                            evtData.damage = evtData.damage * 1.05
                        end
                    end
                }
            }
        },
        {
            name = "见习射击猎",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\见习射击猎.blp",
            key = "SCZJJXSJL",
            description = "",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            zhushuxing = "+3"
                        }
                    )
                },
                {
                    description = "提高5%基础射击伤害",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.triggerSkill == hslk.n2i("基础射击") then
                            evtData.damage = evtData.damage * 1.05
                        end
                    end
                }
            }
        },
        {
            name = "见习惩戒骑",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\见习惩戒骑.blp",
            key = "SCZJJXCJQ",
            description = "",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            zhushuxing = "+3"
                        }
                    )
                },
                {
                    description = "提高5%审判伤害",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.triggerSkill == hslk.n2i("审判") then
                            evtData.damage = evtData.damage * 1.05
                        end
                    end
                }
            }
        },
        {
            name = "见习星辰法师",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\见习星辰法师.blp",
            key = "SCZJJXXCFS",
            description = "",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            zhushuxing = "+3"
                        }
                    )
                },
                {
                    description = "提高5%坠星伤害",
                    attr_type = CONST_EVENT.damagingCustomSource,
                    attr = function(evtData)
                        if evtData.triggerSkill == hslk.n2i("坠星") then
                            evtData.damage = evtData.damage * 1.05
                        end
                    end
                }
            }
        },
        {
            name = "见习职业大师",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\Achievement_ChallengeMode_MogushanPalace_Bronze.blp",
            description = "激活所有见习职业精通获得额外效果",
            shangchengtype = SHANGCHENG_TYPE.DEPENDENCY,
            dependency = { "见习射击猎", "见习痛苦术", "见习毁灭术", "见习狂暴战", "见习武器战", "见习火法", "见习战斗贼", "见习星辰法师", "见习惩戒骑" },
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            zhushuxing = "+20",
                            master = "+5",
                            attack_speed = "+1",
                            skill_speed = "+0.5"
                        }
                    )
                }
            }
        },
        {
            name = "第四存档位",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\4.blp",
            key = "SCQTDSCDW",
            description = "开启第四个冒险者存档位",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {},
            whiteList = { "毁灭利刃", "呮茵伱呔媄#4613", "小小晚安#1312" }
        },
        {
            name = "第五存档位",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\5.blp",
            key = "SCQTDWCDW",
            description = "开启第五个冒险者存档位",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {},
            whiteList = { "毁灭利刃", "呮茵伱呔媄#4613" }
        },
        {
            name = "外交天赋",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\外交天赋.blp",
            key = "SCQTWJTF",
            description = "任务和完成副本获得的声望奖励提高10%",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            shengwang_rate = "+10"
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "职业转换信",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\职业转换信.blp",
            key = "SCQTZZJSX",
            description = "冒险者工会发放的凭证，可以用来在冒险者工会会长处转换职业。",
            shangchengtype = SHANGCHENG_TYPE.DUIDIESHUXING,
            count = 0,
            maxCount = 1000,
            isActive = false
        },
        {
            name = "初级工会",
            pinzhi = ZHUANGBEI_PINZHI.PUTONG,
            art = "ReplaceableTextures\\shangcheng\\初级工会.blp",
            key = "GHCJGH",
            description = "一级工会奖励",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            exp_ratio = "+2",
                            gold_ratio = "+2",
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "中级工会",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\中级工会.blp",
            key = "GHZJGH",
            description = "二级工会奖励",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            exp_ratio = "+3",
                            gold_ratio = "+3",
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "高级工会",
            pinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
            art = "ReplaceableTextures\\shangcheng\\高级工会.blp",
            key = "GHGJGH",
            description = "三级工会奖励",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            exp_ratio = "+3",
                            gold_ratio = "+3",
                            sqnl_huoqu = "+3",
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "超级工会",
            pinzhi = ZHUANGBEI_PINZHI.SHISHI,
            art = "ReplaceableTextures\\shangcheng\\超级工会.blp",
            key = "GHCHAOJGH",
            description = "四级工会奖励",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            zhushuxing_baifenbi = "+1",
                            dianfeng_jingyan_ratio = "+3",
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "巅峰工会",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\巅峰工会.blp",
            key = "GHDFGH",
            description = "五级工会奖励",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            effects = {
                {
                    description = "",
                    attr_type = CONST_EVENT.attr,
                    attr = _attr(
                        {
                            quanju_zengshang = "+1",
                            extra_drop_rate = "+1",
                        }
                    )
                }
            },
            whiteList = {}
        },
        {
            name = "双天赋",
            pinzhi = ZHUANGBEI_PINZHI.CHUANQI,
            art = "ReplaceableTextures\\shangcheng\\双天赋.blp",
            key = "SCSHUANGTF",
            description = "可以切换第二个天赋栏",
            shangchengtype = SHANGCHENG_TYPE.TEQUAN,
            count = 0,
            isActive = false,
            whiteList = {}
        },
    }

    local heroNames = { "火法", "惩戒骑", "射击猎", "狂暴战", "武器战", "战斗贼", "星辰法师", "毁灭术", "痛苦术", "恶魔猎手" }
    for _, heroName in ipairs(heroNames) do
        hshop.addItem(
            "冒险者工会会长",
            "转职：" .. heroName,
            hslk.n2v(heroName, "Art"),
            { { type = HSHOP_COST_TYPE.gold, value = 10000 } },
            {},
            "消耗一个职业转换信（商城），转职成为" ..
            heroName .. "，请注意！使用该功能后游戏会" .. hcolor.red("强制结束！") .. "转职前务必把主手和副手的武器卸下，并且物品不要丢在地上，不然武器/物品会丢失！",
            function(whichPlayer)
                hjapi.DzAPI_Map_ConsumeMallItem(whichPlayer, "SCQTZZJSX", 1)
                hplayer.dzCunDang[whichPlayer].saveCundang(
                    "cundangherostr",
                    false,
                    hplayer.dzCunDang[whichPlayer]._cundangwei,
                    hplayer.dzCunDang[whichPlayer]._cundangwei,
                    tostring(HERONAME_TO_INDEX[heroName])
                )
                hcache.set(whichPlayer, "disablezhuangbei", true)
                htime.setTimeout(
                    1,
                    function()
                        hplayer.defeat(whichPlayer, "转职成为" .. heroName .. "，请重新登陆")
                    end
                )
            end,
            function(whichPlayer)
                local zhxcount = hshangcheng.getItemCount(whichPlayer, "职业转换信")
                if zhxcount <= 0 then
                    echo(hcolor.yellow("职业转换信不足"), whichPlayer)
                    return false
                end
                local mainHero = hplayer.getMainHero(whichPlayer)
                if mainHero == nil then
                    echo(hcolor.yellow("请先选择英雄"), whichPlayer)
                    return false
                end
                if hunit.getName(mainHero) == heroName then
                    echo(hcolor.yellow("已经是" .. heroName .. "，无法转职"), whichPlayer)
                    return false
                end
                if
                    hplayer.dzCunDang[whichPlayer].getEquipment(EQUIPMENT_SLOT_ID.zhushou) ~= nil or
                    hplayer.dzCunDang[whichPlayer].getEquipment(EQUIPMENT_SLOT_ID.fushou) ~= nil
                then
                    echo(hcolor.yellow("请先卸下主手副手装备"), whichPlayer)
                    return false
                end
                return true
            end
        )
    end

    hshangcheng.init(config)
end
