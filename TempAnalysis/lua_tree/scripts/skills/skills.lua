-- 装载技能
require("scripts.skills.fashi.fashi")
require("scripts.skills.wuqizhan.wuqizhan")
require("scripts.skills.kuangbaozhan.kuangbaozhan")
require("scripts.skills.chengjieqi.chengjieqi")
require("scripts.skills.huimieshu.huimieshu")
require("scripts.skills.zhandouzei.zhandouzei")
require("scripts.skills.boss.lichking")
require("scripts.skills.shejilieren.shejilieren")
require("scripts.skills.tongkushu.tongkushu")
require("scripts.skills.xingchenfashi.xingchenfashi")
require("scripts.skills.emolieshou.emolieshou")

---初始化技能
---@param whichPlayer userdata
---@return nil
function skill_init(whichPlayer)
    echo("初始化技能", whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    hunit.setCanFly(hero)
    if SKILL_SETUP[hunit.getName(hero)] ~= nil then
        SKILL_SETUP[hunit.getName(hero)](hero)
    end
    hskill.add(hero, hslk.n2i("饰品主动技能"), 1, 0)
    hskill.add(hero, hslk.n2i("功能合集"), 1, 0)
    hskill.add(hero, hslk.n2i("采集"), 1, 0)
    hskill.add(hero, hslk.n2i("制作"), 1, 0)
    -- 如果是1级，那么我们需要主动刷新被动技能
    if SKILL_ON_LEVEL_UP[hunit.getName(hero)] ~= nil then
        SKILL_ON_LEVEL_UP[hunit.getName(hero)](hero)
    end

    hevent.register(
        hero,
        CONST_EVENT.dead,
        "死亡建议",
        function(evtData)
            hquestcustom.enqueue_dialog(
                hunit.getOwner(evtData.triggerUnit),
                "新手村村长",
                "冒险者们请不要气馁，如果发现打不过怪，可以打开F3查看继续变强的途径。这里包括炼金药水，锻造磨刀石，锻造装备，珠宝镶嵌，附魔，裁缝刺绣，制皮护甲片，杀怪获取图鉴，完成成就挑战等等。"
            )
        end
    )

    hevent.register(
        hero,
        CONST_EVENT.reborn,
        "重生重置高度",
        function(evtData)
            hunit.setFlyHeight(hero, 0, 9999)
        end
    )

    hcache.set(hero, CONST_CACHE.PLAYER_AI, function()
        local rect = hcache.get(whichPlayer, CONST_CACHE.UNIT_RECT)
        local target = hgroup.findNearestEnemyByRect(hero, rect)
        if target == nil then
            return
        end
        cj.IssueTargetOrder(hero, "attack", target)
    end)
end

SKILLS["守护者"] = function(evtData)
    local whichUnit = evtData.triggerUnit
    if hfightzhuangtai.isInFight(whichUnit) then
        echo("战斗状态中不能更换团队角色", hunit.getOwner(whichUnit))
        return
    end
    if hunit.canTank(whichUnit) == false then
        echo("当前职业无法切换守护者", hunit.getOwner(whichUnit))
        return
    end

    hbuff.delete(whichUnit, "进攻手")
    hbuff.delete(whichUnit, "先锋")

    if hbuff.hasBuff(whichUnit, "守护者") then
        hbuff.delete(whichUnit, "守护者")
    else
        hbuff.update(
            -1,
            whichUnit,
            "守护者",
            true,
            function()
            end,
            function()
            end,
            "ReplaceableTextures\\PASBTN_ZS_JN11.blp",
            "守护者|n 60%的最终伤害减免，但是造成的所有伤害降低90%，同时获取的仇恨值提高100倍",
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

SKILLS["进攻手"] = function(evtData)
    local whichUnit = evtData.triggerUnit
    if hfightzhuangtai.isInFight(whichUnit) then
        echo("战斗状态中不能更换团队角色", hunit.getOwner(whichUnit))
        return
    end

    hbuff.delete(whichUnit, "守护者")
    hbuff.delete(whichUnit, "先锋")

    if hbuff.hasBuff(whichUnit, "进攻手") then
        hbuff.delete(whichUnit, "进攻手")
    else
        hbuff.update(
            -1,
            whichUnit,
            "进攻手",
            true,
            function()
            end,
            function()
            end,
            "ReplaceableTextures\\PASBTN_KRDS_SPZ.blp",
            "进攻手|n 造成伤害提高2%",
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

SKILLS["先锋"] = function(evtData)
    local whichUnit = evtData.triggerUnit
    if hfightzhuangtai.isInFight(whichUnit) then
        echo("战斗状态中不能更换团队角色", hunit.getOwner(whichUnit))
        return
    end
    if hunit.canTank(whichUnit) == false then
        echo("当前职业无法切换先锋", hunit.getOwner(whichUnit))
        return
    end

    hbuff.delete(whichUnit, "进攻手")
    hbuff.delete(whichUnit, "守护者")

    if hbuff.hasBuff(whichUnit, "先锋") then
        hbuff.delete(whichUnit, "先锋")
    else
        hbuff.update(
            -1,
            whichUnit,
            "先锋",
            true,
            function()
            end,
            function()
            end,
            "ReplaceableTextures\\BTN_ZS_JN03.blp",
            "先锋|n 伤害提高2%，同时获取的仇恨值提高10倍",
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
