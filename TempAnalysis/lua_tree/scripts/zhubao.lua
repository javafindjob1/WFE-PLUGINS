function initZhuBao()
    local config = {
        {
            reqLevel = 0,
            req = {
                { name = "铁矿石", count = 10 }
            },
            successRate = 10000,
            output = {
                name = "珠宝原石",
                count = 1
            }
        },
        {
            reqLevel = 0,
            req = {
                { name = "珠宝原石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "初级绿宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 0,
            req = {
                { name = "珠宝原石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "初级红宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 0,
            req = {
                { name = "珠宝原石", count = 2 }
            },
            successRate = 10000,
            output = {
                name = "初级黄宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 0,
            req = {
                { name = "珠宝原石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "初级蓝宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 0,
            req = {
                { name = "珠宝原石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "初级紫宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 0,
            req = {
                { name = "珠宝原石", count = 2 }
            },
            successRate = 10000,
            output = {
                name = "初级橙宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 1,
            req = {
                { name = "珠宝原石", count = 4 }
            },
            successRate = 10000,
            output = {
                name = "红宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 1,
            req = {
                { name = "珠宝原石", count = 4 }
            },
            successRate = 10000,
            output = {
                name = "黄宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 1,
            req = {
                { name = "珠宝原石", count = 4 }
            },
            successRate = 10000,
            output = {
                name = "蓝宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 1,
            req = {
                { name = "珠宝原石", count = 4 }
            },
            successRate = 10000,
            output = {
                name = "橙宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 1,
            req = {
                { name = "珠宝原石", count = 4 }
            },
            successRate = 10000,
            output = {
                name = "豪华珠宝戒指",
                itemLevel = 32,
                itemPinzhi = ZHUANGBEI_PINZHI.JINGLIANG,
                nandu = FUBEN_NANDU.PUTONG,
                count = 1
            },
            zhizuoExp = 10
        },
        {
            reqLevel = 2,
            req = {
                { name = "罕见珠宝原石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "精致红宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 2,
            req = {
                { name = "罕见珠宝原石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "精致黄宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 2,
            req = {
                { name = "罕见珠宝原石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "精致蓝宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 2,
            req = {
                { name = "罕见珠宝原石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "精致橙宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 2,
            req = {
                { name = "炎魔之指", count = 1 },
                { name = "黑龙精华", count = 1 },
                { name = "罕见珠宝原石", count = 5 },
                { name = "火焰精华", count = 6 }
            },
            successRate = 10000,
            output = {
                name = "强化炎魔之指",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "火焰之王的项圈", count = 1 },
                { name = "黑龙精华", count = 1 },
                { name = "罕见珠宝原石", count = 5 },
                { name = "火焰精华", count = 6 }
            },
            successRate = 10000,
            output = {
                name = "强化火焰之王的项圈",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "迅击戒指", count = 1 },
                { name = "黑龙精华", count = 1 },
                { name = "罕见珠宝原石", count = 5 },
                { name = "火焰精华", count = 6 }
            },
            successRate = 10000,
            output = {
                name = "强化迅击戒指",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "迅击项链", count = 1 },
                { name = "黑龙精华", count = 1 },
                { name = "罕见珠宝原石", count = 5 },
                { name = "火焰精华", count = 6 }
            },
            successRate = 10000,
            output = {
                name = "强化迅击项链",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "龙牙饰物", count = 1 },
                { name = "正义之手", count = 1 },
                { name = "黑手饰物", count = 1 },
                { name = "污染者的意志", count = 1 },
                { name = "黑龙精华", count = 1 },
                { name = "火焰精华", count = 6 }
            },
            successRate = 10000,
            output = {
                name = "熔铸龙牙饰物",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 2,
            req = {
                { name = "奈萨里奥之泪", count = 1 },
                { name = "狂暴火焰护符", count = 1 },
                { name = "石楠之环", count = 1 },
                { name = "烈焰勋章", count = 1 },
                { name = "能量涌动护符", count = 1 },
                { name = "黑龙精华", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "赋能的奈萨里奥之泪",
                itemLevel = 60,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                { name = "附能珠宝原石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "完美红宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 3,
            req = {
                { name = "附能珠宝原石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "完美紫宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 3,
            req = {
                { name = "附能珠宝原石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "完美钻石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 3,
            req = {
                { name = "附能珠宝原石", count = 1 }
            },
            successRate = 10000,
            output = {
                name = "完美精准黄宝石",
                count = 1
            },
            zhizuoExp = 2
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "纯净的纳鲁薄片",
                    count = 1,
                    nandu = FUBEN_NANDU.SHISHI
                },
                {
                    name = "暗月卡片：复仇",
                    count = 1,
                    nandu = FUBEN_NANDU.SHISHI
                },
                {
                    name = "影月徽记",
                    count = 1,
                    nandu = FUBEN_NANDU.SHISHI
                }
            },
            successRate = 10000,
            output = {
                name = "圣洁纳鲁薄片",
                itemLevel = 73,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "灰暗的纳鲁薄片",
                    count = 1,
                    nandu = FUBEN_NANDU.SHISHI
                },
                {
                    name = "暗月卡片：怒火",
                    count = 1,
                    nandu = FUBEN_NANDU.SHISHI
                },
                {
                    name = "背叛者的疯狂",
                    count = 1,
                    nandu = FUBEN_NANDU.SHISHI
                }
            },
            successRate = 10000,
            output = {
                name = "深黯纳鲁薄片",
                itemLevel = 73,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "灰暗的纳鲁薄片",
                    count = 1,
                    nandu = FUBEN_NANDU.SHISHI
                },
                {
                    name = "暗月卡片：远征",
                    count = 1,
                    nandu = FUBEN_NANDU.SHISHI
                },
                {
                    name = "背叛者的疯狂",
                    count = 1,
                    nandu = FUBEN_NANDU.SHISHI
                }
            },
            successRate = 10000,
            output = {
                name = "深黯纳鲁薄片",
                itemLevel = 73,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "变幻的纳鲁薄片",
                    count = 1,
                    nandu = FUBEN_NANDU.SHISHI
                },
                {
                    name = "暗月卡片：疯狂",
                    count = 1,
                    nandu = FUBEN_NANDU.SHISHI
                },
                {
                    name = "古尔丹之颅",
                    count = 1,
                    nandu = FUBEN_NANDU.SHISHI
                }
            },
            successRate = 10000,
            output = {
                name = "嬗代纳鲁薄片",
                itemLevel = 73,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
        {
            reqLevel = 3,
            req = {
                {
                    name = "变幻的纳鲁薄片",
                    count = 1,
                    nandu = FUBEN_NANDU.SHISHI
                },
                {
                    name = "暗月卡片：伟大",
                    count = 1,
                    nandu = FUBEN_NANDU.SHISHI
                },
                {
                    name = "古尔丹之颅",
                    count = 1,
                    nandu = FUBEN_NANDU.SHISHI
                }
            },
            successRate = 10000,
            output = {
                name = "嬗代纳鲁薄片",
                itemLevel = 73,
                itemPinzhi = ZHUANGBEI_PINZHI.SHISHI,
                nandu = FUBEN_NANDU.SHISHI,
                count = 1
            },
            zhizuoExp = 5
        },
    }

    local fangju = { "衣服", "头盔", "披风", "手套", "鞋子" }
    local wuqishoushi = { "双手剑", "单手剑", "双手斧", "单手斧", "双手锤", "单手锤", "匕首", "拳套", "法杖", "戒指", "项链", "饰品", "弓", "法剑" }

    local zhubaoConfig = {
        {
            name = "初级绿宝石",
            itemCunDangStr = "01",
            attr = _attr({ life_back = "+3" }),
            _skillEffect = {
                {
                    description = "被攻击有10%概率恢复5点生命, 多枚宝石可以叠加",
                    attr_type = CONST_EVENT.beAttack,
                    attr = function(evtData)
                        if math.random(1, 100) <= 5 then
                            hskill.heal(
                                {
                                    healer = evtData.triggerUnit,
                                    healee = evtData.triggerUnit,
                                    5,
                                    healType = HEAL_TYPE.SKILL,
                                    triggerSkill = hslk.n2i("装备技能")
                                }
                            )
                        end
                    end
                }
            },
            zhuangbeiTypes = fangju
        },
        {
            name = "初级红宝石",
            itemCunDangStr = "02",
            attr = _attr({ zhushuxing = "+5" }),
            fitAllTypes = true
        },
        {
            name = "初级黄宝石",
            itemCunDangStr = "03",
            attr = _attr({ wu_bao = "+0.2", fa_bao = "+0.2" }),
            zhuangbeiTypes = wuqishoushi
        },
        {
            name = "初级蓝宝石",
            itemCunDangStr = "04",
            attr = _attr({ life = "+12" }),
            zhuangbeiTypes = fangju
        },
        {
            name = "初级橙宝石",
            itemCunDangStr = "05",
            attr = _attr({ attack_speed = "+1", skill_speed = "+0.5" }),
            zhuangbeiTypes = wuqishoushi
        },
        {
            name = "初级紫宝石",
            itemCunDangStr = "06",
            attr = _attr({ energy_back = "+1" }),
            zhuangbeiTypes = wuqishoushi
        },
        {
            name = "红宝石",
            itemCunDangStr = "07",
            attr = _attr({ zhushuxing = "+8" }),
            fitAllTypes = true
        },
        {
            name = "黄宝石",
            itemCunDangStr = "08",
            attr = _attr({ wu_bao = "+0.3", fa_bao = "+0.3" }),
            zhuangbeiTypes = wuqishoushi
        },
        {
            name = "蓝宝石",
            itemCunDangStr = "09",
            attr = _attr({ life = "+50" }),
            zhuangbeiTypes = fangju
        },
        {
            name = "橙宝石",
            itemCunDangStr = "0a",
            attr = _attr({ attack_speed = "+1.5", skill_speed = "+0.8" }),
            zhuangbeiTypes = wuqishoushi
        },
        {
            name = "精致红宝石",
            itemCunDangStr = "0b",
            attr = _attr({ zhushuxing = "+10" }),
            fitAllTypes = true
        },
        {
            name = "精致黄宝石",
            itemCunDangStr = "0c",
            attr = _attr({ wu_bao = "+0.5", fa_bao = "+0.5" }),
            zhuangbeiTypes = wuqishoushi
        },
        {
            name = "精致蓝宝石",
            itemCunDangStr = "0d",
            attr = _attr({ life = "+80" }),
            zhuangbeiTypes = fangju
        },
        {
            name = "精致橙宝石",
            itemCunDangStr = "0e",
            attr = _attr({ attack_speed = "+2.0", skill_speed = "+1.2" }),
            zhuangbeiTypes = wuqishoushi
        },
        {
            name = "完美红宝石",
            itemCunDangStr = "0f",
            attr = _attr({ zhushuxing = "+15" }),
            fitAllTypes = true
        },
        {
            name = "完美紫宝石",
            itemCunDangStr = "0g",
            attr = _attr({ energy_back = "+3" }),
            zhuangbeiTypes = wuqishoushi
        },
        {
            name = "完美钻石",
            itemCunDangStr = "0h",
            attr = _attr({ master = "+15" }),
            zhuangbeiTypes = wuqishoushi
        },
        {
            name = "完美精准黄宝石",
            itemCunDangStr = "0i",
            attr = _attr({ hit = "+0.8" }),
            zhuangbeiTypes = wuqishoushi
        }
    }
    hshop.addNormalItem(
        "军需处长谭恩",
        "珠宝原石",
        { { type = HSHOP_COST_TYPE.gongzhenghuizhang, value = 5 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 1, shengwangname = "王城" } }
    )
    hshop.addItem(
        "珠宝大师索恩",
        "宝石剥离",
        "ReplaceableTextures\\zhubao\\BTNWarcraft3 Ico.blp",
        { { type = HSHOP_COST_TYPE.gold, value = 5000 } },
        { { type = HSHOP_REQUIREMENT_TYPE.shengwang, value = 2, shengwangname = "王城" } },
        "剥离物品栏第一格装备的所有宝石，概不退款，误操作也不退。该操作会破坏宝石。",
        function(whichPlayer)
            local whichUnit = hplayer.getMainHero(whichPlayer)
            if whichUnit == nil then
                return
            end
            local item = cj.UnitItemInSlot(whichUnit, 0)
            if item == nil then
                echo("物品栏第一格无物品", whichPlayer)
                return
            end
            local dynamicItem = hitem.getDynamicItem(item)
            local hitem_type = hslk.i2v(dynamicItem.basic_item_id, "hitem_type")
            if hitem_type ~= "装备" then
                echo("第一格物品非装备", whichPlayer)
                return
            end
            dynamicItem.baoshi.yi.baoshiName = nil
            dynamicItem.baoshi.er.baoshiName = nil
            dynamicItem.baoshi.san.baoshiName = nil
            dynamicItem.updateDescription()
            echo("剥离宝石完成", whichPlayer)
        end
    )
    hzhubao.init(config, zhubaoConfig)
end
