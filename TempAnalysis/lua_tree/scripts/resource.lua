init_resource = function()
    local config = {
        {
            type = HSHOP_COST_TYPE.gold,
            cdKey = "jinbi",
            isPerHero = false,
            max = function(whichPlayer)
                local ditudengji = hditudengji.getDitudengji(whichPlayer) or 1

                return 200000 + math.max(0, ditudengji - 10) * 5000
            end,
            resourceSource = HSHOP_COST_SOURCE.CUNDANG,
            art = "ReplaceableTextures\\INV_Misc_Coin_02.blp"
        },
        {
            type = HSHOP_COST_TYPE.experience,
            cdKey = "jingyan",
            isPerHero = true,
            max = function(whichPlayer)
                return 48000000
            end,
            resourceSource = HSHOP_COST_SOURCE.CUNDANG,
            art = "ReplaceableTextures\\XP_ICON.BLP"
        },
        {
            type = HSHOP_COST_TYPE.gongzhenghuizhang,
            cdKey = "gongzhenghuizhang",
            isPerHero = true,
            max = function(whichPlayer)
                return 600
            end,
            resourceSource = HSHOP_COST_SOURCE.CUNDANG,
            art = "ReplaceableTextures\\BTN_Zb_011.blp"
        },
        {
            type = HSHOP_COST_TYPE.dianfengjingyan,
            cdKey = "dianfengjingyan",
            isPerHero = false,
            max = function(whichPlayer)
                return 20000000
            end,
            resourceSource = HSHOP_COST_SOURCE.CUNDANG,
            art = "ReplaceableTextures\\XP2_ICON"
        },
        --{type = HSHOP_COST_TYPE.rongyudianshu, cdKey = "rongyudianshu", isPerHero = true, max = 12000, art = "ReplaceableTextures\\BTNAchievement_Arena_2v2_7.blp"},
        {
            type = HSHOP_COST_TYPE.yongqihuizhang,
            cdKey = "yongqihuizhang",
            isPerHero = true,
            max = function(whichPlayer)
                return 600
            end,
            resourceSource = HSHOP_COST_SOURCE.CUNDANG,
            art = "ReplaceableTextures\\BTN_Zb_012"
        },
        {
            type = HSHOP_COST_TYPE.chujixilianshi,
            cdKey = "SCHBCJXLS",
            isPerHero = false,
            max = function(whichPlayer)
                return 10000
            end,
            resourceSource = HSHOP_COST_SOURCE.SHANGCHENG,
            art = "ReplaceableTextures\\xilianshi1.blp"
        },
        {
            type = HSHOP_COST_TYPE.zhongjixilianshi,
            cdKey = "SCHBZJXLS",
            isPerHero = false,
            max = function(whichPlayer)
                return 10000
            end,
            resourceSource = HSHOP_COST_SOURCE.SHANGCHENG,
            art = "ReplaceableTextures\\xilianshi2.blp"
        },
        {
            type = HSHOP_COST_TYPE.maoxianzhehuizhang,
            cdKey = "SCMXZHZ",
            isPerHero = false,
            max = function(whichPlayer)
                return 10000
            end,
            resourceSource = HSHOP_COST_SOURCE.SHANGCHENG,
            art = "ReplaceableTextures\\chengjiu\\BTNACHIEVEMENT_GUILDPERK_HONORABLEMENTION_RANK2.blp"
        },
        {
            type = HSHOP_COST_TYPE.huoyanhuizhang,
            cdKey = "huoyanhuizhang",
            isPerHero = false,
            max = function(whichPlayer)
                return 160
            end,
            resourceSource = HSHOP_COST_SOURCE.CUNDANG,
            art = "ReplaceableTextures\\BTNcl50.blp"
        },
        {
            type = HSHOP_COST_TYPE.zhengyihuizhang,
            cdKey = "zhengyihuizhang",
            isPerHero = false,
            max = function(whichPlayer)
                return 200
            end,
            resourceSource = HSHOP_COST_SOURCE.CUNDANG,
            art = "ReplaceableTextures\\BTNAchievement_Dungeon_Outland_Dungeon_Hero.blp"
        },
        {
            type = HSHOP_COST_TYPE.zhixuhuizhang,
            cdKey = "zhixuhuizhang",
            isPerHero = false,
            max = function(whichPlayer)
                return 200
            end,
            resourceSource = HSHOP_COST_SOURCE.CUNDANG,
            art = "ReplaceableTextures\\BTNfm18"
        },
        {
            type = HSHOP_COST_TYPE.daixinjifen,
            isPerHero = false,
            max = function(whichPlayer)
                return 3000
            end,
            sumCDKey = "daixinjifensum",
            usedCDKey = "daixinjifenused",
            resourceSource = HSHOP_COST_SOURCE.FANGZUOBI_CUNDANG,
            art = "RReplaceableTextures\\Raf-Icon.blp"
        },
        {
            type = HSHOP_COST_TYPE.mifahuizhang,
            cdKey = "mifahuizhang",
            isPerHero = false,
            max = function(whichPlayer)
                return 200
            end,
            resourceSource = HSHOP_COST_SOURCE.CUNDANG,
            art = "ReplaceableTextures\\BTNAchievement_Dungeon_Outland_Dungeon_Hero.blp"
        },
        {
            type = HSHOP_COST_TYPE.monenghuizhang,
            cdKey = "monenghuizhang",
            isPerHero = false,
            max = function(whichPlayer)
                return 200
            end,
            resourceSource = HSHOP_COST_SOURCE.CUNDANG,
            art = "ReplaceableTextures\\BTNfm18"
        },
        {
            type = HSHOP_COST_TYPE.xieehuizhang,
            cdKey = "xieehuizhang",
            isPerHero = false,
            max = function(whichPlayer)
                return 200
            end,
            resourceSource = HSHOP_COST_SOURCE.CUNDANG,
            art = "ReplaceableTextures\\BTNAchievement_Dungeon_Outland_Dungeon_Hero.blp"
        },
        {
            type = HSHOP_COST_TYPE.emohuizhang,
            cdKey = "emohuizhang",
            isPerHero = false,
            max = function(whichPlayer)
                return 200
            end,
            resourceSource = HSHOP_COST_SOURCE.CUNDANG,
            art = "ReplaceableTextures\\BTNfm18"
        },
        {
            type = HSHOP_COST_TYPE.huihuanghuizhang,
            cdKey = "huihuanghuizhang",
            isPerHero = false,
            max = function(whichPlayer)
                return 200
            end,
            resourceSource = HSHOP_COST_SOURCE.CUNDANG,
            art = "ReplaceableTextures\\BTNAchievement_Dungeon_Outland_Dungeon_Hero.blp"
        },
        {
            type = HSHOP_COST_TYPE.kaixuanhuizhang,
            cdKey = "kaixuanhuizhang",
            isPerHero = false,
            max = function(whichPlayer)
                return 200
            end,
            resourceSource = HSHOP_COST_SOURCE.CUNDANG,
            art = "ReplaceableTextures\\BTNfm18"
        },
    }
    hresource.init(config)
end

MONSTER_TYPE_TO_EXP_RATIO = {
    [MONSTER_TYPE.FUBEN_BOSS] = 16,
    [MONSTER_TYPE.FUBEN_JINGYING] = 6,
    [MONSTER_TYPE.FUBEN_XIAOGUAI] = 4,
    [MONSTER_TYPE.SHIJIE_BOSS] = 100,
    [MONSTER_TYPE.YEWAI_BOSS] = 6,
    [MONSTER_TYPE.YEWAI_XIAOGUAI] = 2,
    [MONSTER_TYPE.YEWAI_JINGYING] = 4
}

-- 设置杀怪获取资源
hevent.reaction(
    CONST_EVENT.kill,
    "kill_get_resource",
    function(evtData)
        if evtData.triggerUnit == nil or evtData.targetUnit == nil then
            return
        end
        if hunit.isNormalDead(evtData.targetUnit) == false then
            return
        end
        if hunit.getExpReward(evtData.targetUnit) == 0 then
            return
        end
        local killerPlayer = hunit.getOwner(evtData.triggerUnit)
        if killerPlayer == nil or hplayer.isUser(killerPlayer) == false or hplayer.isPlaying(killerPlayer) == false then
            return
        end
        local targetLevel = hunit.getLevel(evtData.targetUnit)
        if targetLevel == nil then
            return
        end
        local heroes =
            hgroup.createByXY(
                hunit.x(evtData.targetUnit),
                hunit.y(evtData.targetUnit),
                1000,
                function(filterUnit)
                    if
                        (math.distance(
                                hunit.x(filterUnit),
                                hunit.y(filterUnit),
                                hunit.x(evtData.targetUnit),
                                hunit.y(evtData.targetUnit)
                            ) <= 1000 and
                            filterUnit == hplayer.getMainHero(hunit.getOwner(filterUnit)) and
                            hunit.isAlly(evtData.targetUnit, filterUnit) == false)
                    then
                        return true
                    else
                        return false
                    end
                end
            )
        for _, hero in ipairs(heroes) do
            local killerLevel = hunit.getLevel(hero)
            if math.abs(killerLevel - targetLevel) <= 9 then
                local expRatio = hattribute.getWithLimit(hero, nil, "exp_ratio", 0)
                local monsterType = hunit.getMonsterType(evtData.targetUnit) or MONSTER_TYPE.YEWAI_XIAOGUAI
                local experience =
                    math.floor(
                        10 * (targetLevel + 5) * (100 - killerLevel + targetLevel) * (expRatio + 100) / 10000 / 4 *
                        MONSTER_TYPE_TO_EXP_RATIO[monsterType]
                    )

                local points = htianfu.getActiveTianfuLevel(hunit.getOwner(hero), "经验大师")
                if points > 0 and math.random(1, 100) <= points * 2 then
                    experience = experience * 2
                end

                hresource.addSingleResource(hunit.getOwner(hero), HSHOP_COST_TYPE.experience, experience, false)
                if math.random(1, 100) <= 5 then
                    local dianfengExpRatio = hattribute.getWithLimit(hero, nil, "dianfeng_jingyan_ratio", 0)
                    local dianfengjingyan = math.floor(experience * (dianfengExpRatio + 100) / 1000)

                    hresource.addSingleResource(
                        hunit.getOwner(hero),
                        HSHOP_COST_TYPE.dianfengjingyan,
                        dianfengjingyan,
                        false
                    )
                end
            end
            if math.random(1, 100) <= 10 then
                local goldRatio = hattribute.getWithLimit(hero, nil, "gold_ratio", 0)
                local gold = math.floor(targetLevel * (goldRatio + 100) / 100)

                local points = htianfu.getActiveTianfuLevel(hunit.getOwner(hero), "淘金者")
                if points > 0 and math.random(1, 100) <= points * 2 then
                    gold = gold * 4
                end
                hresource.addSingleResource(hunit.getOwner(hero), HSHOP_COST_TYPE.gold, gold, true)
            end
        end
    end
)
