local hero = hplayer.getMainHero(hplayer.loc())

--heffect.attach("war3mapImported\\weapon_JuJian06.mdx", hplayer.getMainHero(hplayer.loc()), "left", -1)
--heffect.attach("war3mapImported\\weapon_JuJian06.mdx", hplayer.getMainHero(hplayer.loc()), "right", -1)
--local hero = hplayer.getMainHero(hplayer.loc())
--echo(tostring(cj.GetPlayerTechResearched(hplayer.loc(), c2i("R000")), false))
--echo(cj.GetPlayerTechCount(hplayer.loc(), c2i("R000"), true))
--hplayer.setPlayerTechResearched(hplayer.loc(), c2i("R000"), 14)
--echo(cj.GetPlayerTechResearched(hplayer.loc(), c2i("R000")))
--dump(hjapi.EXSetUnitReal(hplayer.loc(), 0x43, 500))
--Attachmentlinkprops
--echo(0x43)
--dump(hjapi.EXSetUnitString(c2i(hslk.n2i("狂暴战")), 5, "second"))
--hitem.dropIt(hplayer.getMainHero(hplayer.loc()), it)
--hitem.setVisible(it, true)
--cj.SetItemVisible(it, false)
--dump(hitem.isVisible(it))
--dump(cj.IsItemOwned(it))
--hitem.setVisible(it, true)
--dump(hplayer.dzCunDang[hplayer.loc()].getEquipment(2))
--local it = hplayer.dzCunDang[hplayer.loc()].getEquipment(2).it
--dump(it)
--dump(cj.IsItemOwned(it))
--dump(cj.IsItemVisible(it))
--cj.SetItemVisible(it,false)
--hitem.setVisible(it, false)
--dump(cj.IsItemVisible(it))
--hitem.getDynamicItem(it)
--dump(hitem.getDynamicItem(it))
--cj.SetItemVisible(it, false)
--echo(1)
--echo(hslk.n2i("主手剑"))
--htime.setInterval(
--    1,
--    function(c)
--        dump(cj.IsItemVisible(it))
--       dump(it)
--    end
--)
--local hero = hplayer.getMainHero(hplayer.loc())
--dump(hcache.get(hero, CONST_CACHE.ATTR, nil))
--local hero = hplayer.getMainHero(hplayer.loc())
--hevent.reaction(
--    CONST_EVENT.beAttackReady,
--    "testtest",
--    function()
--        hunit.animate(hero, "attack slam")
--   end
--)
--hevent.reaction(
--    CONST_EVENT.attack,
--    "testtest",
--    function()
--        hunit.animate(hero, "stand ready")
--    end
--)
--hunit.animate(hero, "attack slam")
--local hero = hplayer.getMainHero(hplayer.loc())
--hattribute.set(hero, 0, {attack_white = "+60.0"})
--local trig = cj.CreateTrigger()
--dump(trig)
--hjapi.DzTriggerRegisterKeyEventByCode(
--    trig,
--    "B",
--   0,
--   true,
--  function()
--       echo(123)
--   end
--)
--local hero = hplayer.getMainHero(hplayer.loc())
--echo(hattribute.get(hero, "attack_speed", 0))
--local hero = hplayer.getMainHero(hplayer.loc())
--hitem.qianghua(hero)
--hplayer.addGold(hplayer.loc(),1000)
-- hunit.setAnimateSpeed(hero, 2, 0.2)
--hunit.animate(hero, "attack slam")
--hunit.addCurMana(hero,100)

local function fullmana()
    htime.setInterval(
        0.5,
        function(_)
            local hero = hplayer.getMainHero(hplayer.loc())
            hunit.addCurMana(hero, 100)
        end
    )
end
local function printshuxing()
    local hero = hplayer.getMainHero(hplayer.loc())
    dump(hcache.get(hero, CONST_CACHE.ATTR, nil))
end
--fullmana()
--printshuxing()
--hevent.register(
--    hero,
--    CONST_EVENT.skillStop,
--   "asdfasdf",
--    function()
--        echo(123)
--cj.IssueImmediateOrder(hero, "stop")
--    end
--)
--hunit.animate(hero, "spell slam")
--hbuff.xuanyun(hero, 3)
--hbuff.xuanyun(hero, 1)
--heffect.xyz("war3mapImported\\[Spell]_147_1.mdx", hunit.x(hero), hunit.y(hero), hunit.z(hero), 10, 1, 1, 1, 1)
--echo(123)

--cj.IssueImmediateOrder(hero, "stop")

local function shua_dingji_zhuangbei()
    local equipment_type = {
        "猎杀者手套",
        "猎杀者皮帽",
        "猎杀者皮靴",
        "猎杀者软甲"
    }
    --equipment_type = {
    --    "鲜红之剑",
    --    "鲜红之剑"
    -- }

    for _, equipment_type in ipairs(equipment_type) do
        local name = equipment_type
        local item = DynamicItem(hslk.n2i(name))
        --item.baoshi.yi.has_slot = true
        --item.baoshi.yi.baoshiName = "初级绿宝石"
        --item.fumo = "灼热"
        item.qianghua = 8
        item.setOwner(hplayer.loc())
        item.jinglian = 8
        item.initBasedOnPinzhi(ZHUANGBEI_PINZHI.SHISHI, 39, 3, FUBEN_NANDU.SHISHI)
        hitem.create(
            {
                id = hslk.n2i(name),
                x = hunit.x(hero),
                y = hunit.y(hero),
                dynamicItem = item
            }
        )
    end
end

--shua_dingji_zhuangbei()
--hquestcustom.testFullQuest(hplayer.loc())

function testMovie(model)
    hattribute.set(hero, 0, { master = "+300" })
    hfightzhuangtai.enable_fightzhuangtai()
    hjapi.DzFrameSetText(hjapi.DzFrameFindByName("TxtRootWindow_Title", 0), "sdfdf")
    heffect.attach("war3mapImported\\[Spell]_065.mdx", hero, "head", 0)
end

function test()
    echo(123)
    dump(hjapi.DzAPI_Map_GetServerValue(hplayer.loc(), "xunlian-1"))
    hxunlian.tryShengji("攻击训练", hplayer.loc())
    echo(123)
    local a = hjapi.DzAPI_Map_GetServerValue(hplayer.loc(), "xunlian-1")
    dump(hjapi.DzAPI_Map_GetServerValue(hplayer.loc(), "xunlian-1"))
    dump(string.len(a))
end

function testDamage()
    for i = 1, 15, 1 do
        local healee = hero
        if math.random(1, 100) <= 20 then
            local tag =
                htextTag.create2XY(
                    hunit.x(healee) + math.random(1, 50) - 25,
                    hunit.y(healee) + math.random(1, 50) - 25,
                    string.format("%.0f", math.random(1, 100)),
                    15,
                    "fe0606",
                    1,
                    1,
                    50
                )
        else
            local tag =
                htextTag.create2XY(
                    hunit.x(healee) + math.random(1, 50) - 25,
                    hunit.y(healee) + math.random(1, 50) - 25,
                    string.format("%.0f", math.random(1, 100)),
                    8,
                    "fe0606",
                    1,
                    0.4,
                    50
                )
            htextTag.setVelocity(tag, 0, 0.05)
        end
    end
end

-- 电影 cj.SetCinematicScene(c2i(hero), cj.GetPlayerColor(player), "大师傅", "大师傅希望你好好学习" .. hunit.getName(hero), 5, 1)
--hjapi.DzFrameHideInterface()
--heffect.attach("[jineng]huanxing.mdx", hero, "origin", 10)
-- TODO  [UI]shengjizhuangbei1
---任务版 alliance_taskboard
---AZ_chongfeng
---AZ_CSM01
---AZ_diaobao
---AZ_Goods_DUN4
---AZ_JuLi01
---AZ_MagicShield_b
---AZ_U007_150
---AZ_UI_SYZH
---bullebleuyellow
--local bar = hjapi.DzFrameFindByName("shifatiao_bar", 0)
--hjapi.DzFrameSetTexture(bar, "ReplaceableTextures\\shifatiao_lanse.blp", 0)

--local bar = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
--hjapi.DzFrameShow(bar, false)
--hjapi.DzFrameSetTexture(bar, "ReplaceableTextures\\shifatiao_lanse.blp", 0)
--hjapi.DzFrameSetText(bar, "123")

--local bar = hjapi.DzFrameFindByName("ALL_Tips_Back", 0)
--hjapi.DzFrameShow(bar, true)
--local back = hjapi.DzCreateFrame("QUEST_SIMPLE", hjapi.DzGetGameUI(), 0)
--hjapi.DzFrameSetAlpha(back, 10)

--dump(hslk.n2v("铁狼", "slk", "file"))
--local arrowToken = cj.AddSpecialEffect("units\\creeps\\TimberWolf\\TimberWolf", hunit.x(hero), hunit.y(hero))
--heffect.xyz(hslk.n2v("铁狼", "slk", "file")..".mdl", hunit.x(hero), hunit.y(hero), hunit.z(hero), 10, 1)
--hskill.setCoolDown(hero, c2i(hslk.n2i("饰品主动技能")), 0)
--heffect.xyz("war3mapImported\\AZ_MagicShield_b.MDX", hunit.x(hero), hunit.y(hero), hunit.z(hero), 0, 1, 1, 1, 1)
--hskillMoban.radiusWarning(hunit.x(hero), hunit.y(hero), hunit.z(hero), 300, 1)

--dump(hplayer.dzCunDang[hplayer.loc()].getEquipment(4))

local function test()
    local item = DynamicItem(hslk.n2i("狼皮衣"))
    item.initBasedOnPinzhi(ZHUANGBEI_PINZHI.CHUANQI, 60, nil, FUBEN_NANDU.CHUANQI)
    item.updateDescription()
    dump(item)
end

-- echo(#(hgroup.GLOBAL))
--hsound.voice2Unit(hsound.voiceCreate("Abilities\\Spells\\Human\\Avatar\\Avatar.wav", 3199, true), 100.0, hero)
--hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\silie.wav", 967, true), 100, hero)
--hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\gongzhengzhijian.wav", 1000, true), 90, hero)

--heffect.attach("war3mapImported\\[qishi]shenpan_wing.mdx", hero, "origin", 0)
--shua_dingji_zhuangbei()

--dump(hitem.getDynamicItem(cj.UnitItemInSlot(hero, 0)).getCunDangString())

--hresource.addSingleResource(hplayer.loc(), HSHOP_COST_TYPE.maoxianzhehuizhang, 3000, true)

--shua_dingji_zhuangbei()

--dump(hattribute.get(hero, "attack_space_main"))

--dump(hcache.get(hero, CONST_CACHE.ATTR))

--dump(description.attribute({attack_space_origin = 1.1}))
--shua_dingji_zhuangbei()

function effectTest()
    local shifatiao = heffect.xyz("GenericBar.mdx", hunit.x(hero), hunit.y(hero), hunit.z(hero), 1)
    hjapi.DzSetEffectVertexAlpha(shifatiao, 255)
    --hjapi.exec("DzSetEffectVertexColor", shifatiao, hjapi.DzGetColor(0, 122, 237, 0.8))
    hjapi.DzSetEffectAnimation(shifatiao, 50, 0)
    --hjapi.exec("DzSetEffectVertexColor", shifatiao, hjapi.DzGetColor(0, 122, 237, 0.8))
    hjapi.DzBindEffect(hero, "overhead", shifatiao)
    --hjapi.exec("DzSetEffectVertexColor", shifatiao, hjapi.DzGetColor(0, 122, 237, 0.8))
    htime.setTimeout(
        3,
        function(curTimer)
            echo(123)
            hjapi.DzSetEffectVertexAlpha(shifatiao, 0)
            hjapi.DzUnbindEffect(shifatiao)
            heffect.destroy(shifatiao)
        end
    )
end

--local item =
--  hgroup.createByUnit(
-- hero,
-- 300,
-- function(filterUnit)
--  if filterUnit ~= hero then
--      return true
--   else
--        return false
--   end
-- end
--)
--dump(item)
--cj.IssueImmediateOrder(hero, "innerfire", item[1])
--cj.IssueTargetOrder(hero, hslk.n2v("采集", "DataF"), item[1])
--dump(hunit.getName(item[1]))
--dump(hslk.n2v("采集", "DataF"))

--hattribute.set(hero, 0, {zhushuxing_baifenbi = "+100"})

--hattribute.set(hero, 0, {wu_bao = "+0.1"})
function testfubenfinish()
    hquestcustom.addEventCount(
        hplayer.loc(),
        QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
        FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "圣光大教堂"
    )
    hquestcustom.addEventCount(
        hplayer.loc(),
        QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
        FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "王城监狱"
    )

    hquestcustom.addEventCount(
        hplayer.loc(),
        QUEST_CUSTOM_EXECUTE_TYPE.FINISH_FUBEN,
        FUBEN_NANDU_LABEL[FUBEN_NANDU.YINGXIONG] .. "血色军大营"
    )
end

--hresource.addSingleResource(hplayer.loc(), HSHOP_COST_TYPE.dianfengjingyan, 1000000, true)
--hresource.addSingleResource(hplayer.loc(), HSHOP_COST_TYPE.gold, 1000000, true)
--hquestcustom.testFullQuest(hplayer.loc())
--hquestcustom.resetQuest(hplayer.loc())
--hshengwang.huodeShengWang("王城", hplayer.loc(), true, 10000)
--hshengwang.huodeShengWang("新手村", hplayer.loc(), true, 10000)

--heffect.attach("Abilities\\Spells\\NightElf\\ManaBurn\\ManaBurnTarget.mdl", hero, "chest", 0)
--heffect.attach("[shushi]zuzhou2.mdx", hero, "origin", 0.1)

--hresource.addSingleResource(hplayer.loc(), HSHOP_COST_TYPE.gongzhenghuizhang, 100, true)

-- TODO AZ_U007_150

--dump(JassJapi["KKApiGetServerValueLimitLeft"])
local function abc()
    heffect.xyz(
        "war3mapImported\\[qishi]shenpan.mdx",
        hunit.x(hero),
        hunit.y(hero),
        hunit.z(hero),
        0,
        1,
        1,
        1,
        1,
        1,
        1,
        hunit.getFacing(hero)
    )
end
--hskillMoban.radiusWarning(hunit.x(hero), hunit.y(hero), hunit.z(hero), 400, 1)
function AITEST()
    local units = hgroup.createEnermyGroupByUnit(hero, 4000)

    nbaction = function(whichUnit, ai)
        echo(0)
        if ai == nil or whichUnit == nil then
            echo(1)
            return
        end
        if hunit.isAlive(whichUnit) == false then
            echo(2)
            return
        end
        if hunit.isPaused(whichUnit) == true then
            echo(3)
            return
        end
        if hcache.get(whichUnit, "AI_SKILL_CASTING", false) then
            echo(4)
            return
        end
        if ai.configs == nil then
            error("no ai configs for " .. hunit.getName(whichUnit))
        end
        for idx, config in ipairs(ai.configs) do
            local nandu = hunit.getNandu(whichUnit)
            if
                nandu ~= nil and config.aiData ~= nil and config.aiData.minNandu ~= nil and
                nandu < config.aiData.minNandu
            then
                -- skip
            elseif config.aiType == UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG then
                if hfightzhuangtai.isInFight(whichUnit) == true then
                    local chouhendiyi = hfightzhuangtai.getChouhengdiyi(whichUnit)
                    if
                        chouhendiyi ~= nil and hunit.isAlive(chouhendiyi) and
                        hunit.isAlly(chouhendiyi, whichUnit) == false
                    then
                        cj.IssueTargetOrder(whichUnit, "attack", chouhendiyi)
                        echo(5)
                        return
                    end
                end
                echo(6)
            elseif config.aiType == UNIT_AI_TYPE.CAST_SKILL then
                local hpp = hunit.getCurLifePercent(whichUnit)
                if
                    ((config.aiData.healthBelowLimit ~= nil and hpp < config.aiData.healthBelowLimit) or
                        config.aiData.healthBelowLimit == nil) and
                    ((config.aiData.healthAboveLimit ~= nil and hpp > config.aiData.healthBelowLimit) or
                        config.aiData.healthAboveLimit == nil) and
                    ((config.aiData.castCountLimit ~= nil and
                            (config.aiData.castCount == nil or config.aiData.castCount < config.aiData.castCountLimit)) or
                        config.aiData.castCountLimit == nil) and
                    ((config.aiData.castCD ~= nil and htime.checkCoolDown(whichUnit, "AI_SKILL_" .. idx) == true) or
                        config.aiData.castCD == nil) and
                    (config.aiData.customCondition == nil or config.aiData.customCondition(whichUnit) == true)
                then
                    local target = nil
                    if config.aiData.targetType == UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT then
                        if hfightzhuangtai.isInFight(whichUnit) == true then
                            target = hfightzhuangtai.getChouhengdiyi(whichUnit)
                        end
                    elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.LOWEST_HEALTH_UNIT then
                        target = hgroup.getLowestHealthEnermy(whichUnit, 1000)
                    elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.SELF then
                        target = whichUnit
                    elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.LOWEST_HEALTH_ALLY then
                        target =
                            hgroup.getLowestHealth(
                                hgroup.createByUnit(
                                    whichUnit,
                                    1000,
                                    function(filterUnit)
                                        if hunit.isAlly(filterUnit, whichUnit) == true and hunit.isAlive(whichUnit) == true then
                                            return true
                                        end
                                    end
                                ),
                                hunit.x(whichUnit),
                                hunit.y(whichUnit)
                            )
                    elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.NEAREST_ALLY_UNIT then
                        target =
                            hgroup.getClosest(
                                hgroup.createByUnit(
                                    whichUnit,
                                    1000,
                                    function(filterUnit)
                                        if
                                            hunit.isAlly(filterUnit, whichUnit) == true and hunit.isAlive(whichUnit) == true and
                                            filterUnit ~= whichUnit
                                        then
                                            return true
                                        end
                                    end
                                ),
                                hunit.x(whichUnit),
                                hunit.y(whichUnit)
                            )
                    elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.NEAREST_ENERMY_UNIT then
                        target =
                            hgroup.getClosest(
                                hgroup.createByUnit(
                                    whichUnit,
                                    1000,
                                    function(filterUnit)
                                        if
                                            hunit.isAlly(filterUnit, whichUnit) == false and
                                            hunit.isAlive(whichUnit) == true and
                                            filterUnit ~= whichUnit
                                        then
                                            return true
                                        end
                                    end
                                ),
                                hunit.x(whichUnit),
                                hunit.y(whichUnit)
                            )
                    end
                    local castDistance = config.aiData.castDistance or 1000
                    if
                        target ~= nil and
                        (math.distance(hunit.x(whichUnit), hunit.y(whichUnit), hunit.x(target), hunit.y(target)) <
                            castDistance)
                    then
                        hskill.set_next_ai_jineng(whichUnit, idx)
                        hskill.set_next_ai_target(whichUnit, target)
                        if hunit.isInvincible(target) == true or hunit.isImmune(target) == true then
                            echo(8)
                            cj.IssueTargetOrder(whichUnit, "thunderbolt", whichUnit)
                        else
                            echo(9)
                            cj.IssueTargetOrder(whichUnit, "thunderbolt", target)
                        end
                        dump(config.aiData)
                        echo(7)
                        return
                    end
                end
            end
        end
    end

    for _, unit in ipairs(units) do
        if hunit.getName(unit) == "炎魔之王" then
            --cj.IssueTargetOrder(unit, "attack", hero)
            hevent.register(
                unit,
                CONST_EVENT.skillEffect,
                "nbaction",
                function(e)
                    dump(e)
                end
            )
            dump(hunit.getName(unit))
            dump(cj.GetUnitCurrentOrder(unit))
            dump(hcache.get(whichUnit, "AI_SKILL_CASTING", false))
            nbaction(unit, hunit.getAI(unit))
        end
    end
end

--AITEST()

function new_local_test()
    hunitAI.action = function(whichUnit, ai)
        if ai == nil or whichUnit == nil then
            echo(1)
            return
        end
        echo(hunit.getName(whichUnit))
        if hunit.isAlive(whichUnit) == false then
            echo(2)
            return
        end
        if hunit.isPaused(whichUnit) == true then
            echo(3)
            return
        end
        if hcache.get(whichUnit, "AI_SKILL_CASTING", false) then
            echo(4)
            return
        end
        if ai.configs == nil then
            error("no ai configs for " .. hunit.getName(whichUnit))
        end
        for idx, config in ipairs(ai.configs) do
            local nandu = hunit.getNandu(whichUnit)
            if
                nandu ~= nil and config.aiData ~= nil and config.aiData.minNandu ~= nil and
                nandu < config.aiData.minNandu
            then
                -- skip
            elseif config.aiType == UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG then
                if hfightzhuangtai.isInFight(whichUnit) == true then
                    local chouhendiyi = hfightzhuangtai.getChouhengdiyi(whichUnit)
                    if
                        chouhendiyi ~= nil and hunit.isAlive(chouhendiyi) and
                        hunit.isAlly(chouhendiyi, whichUnit) == false
                    then
                        cj.IssueTargetOrder(whichUnit, "attack", chouhendiyi)
                        return
                    end
                end
                echo(5)
            elseif config.aiType == UNIT_AI_TYPE.CAST_SKILL then
                local hpp = hunit.getCurLifePercent(whichUnit)
                if
                    ((config.aiData.healthBelowLimit ~= nil and hpp < config.aiData.healthBelowLimit) or
                        config.aiData.healthBelowLimit == nil) and
                    ((config.aiData.healthAboveLimit ~= nil and hpp > config.aiData.healthBelowLimit) or
                        config.aiData.healthAboveLimit == nil) and
                    ((config.aiData.castCountLimit ~= nil and
                            (config.aiData.castCount == nil or config.aiData.castCount < config.aiData.castCountLimit)) or
                        config.aiData.castCountLimit == nil) and
                    ((config.aiData.castCD ~= nil and htime.checkCoolDown(whichUnit, "AI_SKILL_" .. idx) == true) or
                        config.aiData.castCD == nil) and
                    (config.aiData.customCondition == nil or config.aiData.customCondition(whichUnit) == true)
                then
                    local target = nil
                    if config.aiData.targetType == UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT then
                        if hfightzhuangtai.isInFight(whichUnit) == true then
                            target = hfightzhuangtai.getChouhengdiyi(whichUnit)
                        end
                    elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.LOWEST_HEALTH_UNIT then
                        target = hgroup.getLowestHealthEnermy(whichUnit, 1000)
                    elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.SELF then
                        target = whichUnit
                    elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.LOWEST_HEALTH_ALLY then
                        target =
                            hgroup.getLowestHealth(
                                hgroup.createByUnit(
                                    whichUnit,
                                    1000,
                                    function(filterUnit)
                                        if hunit.isAlly(filterUnit, whichUnit) == true and hunit.isAlive(whichUnit) == true then
                                            return true
                                        end
                                    end
                                ),
                                hunit.x(whichUnit),
                                hunit.y(whichUnit)
                            )
                    elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.NEAREST_ALLY_UNIT then
                        target =
                            hgroup.getClosest(
                                hgroup.createByUnit(
                                    whichUnit,
                                    1000,
                                    function(filterUnit)
                                        if
                                            hunit.isAlly(filterUnit, whichUnit) == true and hunit.isAlive(whichUnit) == true and
                                            filterUnit ~= whichUnit
                                        then
                                            return true
                                        end
                                    end
                                ),
                                hunit.x(whichUnit),
                                hunit.y(whichUnit)
                            )
                    elseif config.aiData.targetType == UNIT_AI_TARGET_TYPE.NEAREST_ENERMY_UNIT then
                        target =
                            hgroup.getClosest(
                                hgroup.createByUnit(
                                    whichUnit,
                                    1000,
                                    function(filterUnit)
                                        if
                                            hunit.isAlly(filterUnit, whichUnit) == false and
                                            hunit.isAlive(whichUnit) == true and
                                            filterUnit ~= whichUnit
                                        then
                                            return true
                                        end
                                    end
                                ),
                                hunit.x(whichUnit),
                                hunit.y(whichUnit)
                            )
                    end
                    local castDistance = config.aiData.castDistance or 1000
                    if
                        target ~= nil and
                        (math.distance(hunit.x(whichUnit), hunit.y(whichUnit), hunit.x(target), hunit.y(target)) <
                            castDistance)
                    then
                        hskill.set_next_ai_jineng(whichUnit, idx)
                        hskill.set_next_ai_target(whichUnit, target)
                        if hunit.isInvincible(target) == true or hunit.isImmune(target) == true then
                            cj.IssueTargetOrder(whichUnit, "thunderbolt", whichUnit)
                        else
                            cj.IssueTargetOrder(whichUnit, "thunderbolt", target)
                        end
                        echo(6)
                        return
                    end
                end
            end
        end
    end

    local AI_JINENG_ID = hslk.n2i("AI技能模版")
    hevent.reaction(
        CONST_EVENT.skillEffect,
        "ai_jineng" .. AI_JINENG_ID,
        function(evtData)
            echo("start")
            if
                evtData.targetUnit == nil or hskill.hasActiveAbility(evtData.triggerUnit, AI_JINENG_ID) == false or
                evtData.triggerSkill ~= AI_JINENG_ID
            then
                return
            end
            local aiIdx = hskill.get_next_ai_jineng(evtData.triggerUnit)
            local ai = hunit.getAI(evtData.triggerUnit)
            if aiIdx == nil or ai.configs[aiIdx] == nil then
                cj.IssueImmediateOrder(evtData.triggerUnit, "stop")
                return
            end
            local targetUnit = hskill.get_next_ai_target(evtData.triggerUnit)
            if targetUnit ~= nil then
                evtData.targetUnit = targetUnit
                hskill.clear_next_ai_target(evtData.triggerUnit)
            end
            hskill.clear_next_ai_jineng(evtData.triggerUnit)
            local aiConfig = ai.configs[aiIdx]
            -- 设置ai 技能cd
            if aiConfig.aiData.castCD ~= nil then
                htime.setupAndCheckCoolDown(evtData.triggerUnit, "AI_SKILL_" .. aiIdx, aiConfig.aiData.castCD)
            end

            local castCount = aiConfig.aiData.castCount
            if castCount == nil then
                aiConfig.aiData.castCount = 1
            else
                aiConfig.aiData.castCount = castCount + 1
            end
            local shifashijian = aiConfig.aiData.shifashijian or 0
            local skill_speed = hattribute.getWithLimit(evtData.triggerUnit, nil, "skill_speed", 0)
            shifashijian = shifashijian * 100 / (skill_speed + 100)
            if shifashijian > 0 and shifashijian < 0.1 then
                shifashijian = 0.1
            end
            evtData.aiConfig = aiConfig
            evtData.shifashijian = shifashijian
            if aiConfig.aiData.startEffect ~= nil then
                aiConfig.aiData.startEffect(evtData)
            end
            -- create effect
            if shifashijian ~= 0 then
                hcache.set(evtData.triggerUnit, "AI_SKILL_CASTING", true)
                hcache.set(evtData.triggerUnit, "AI_SKILL_CASTING_SHIFATIAO_CURRENT", shifashijian)
                if aiConfig.aiData.notInterruptable == true then
                    hbuff.wengu(shifashijian, evtData.triggerUnit)
                end
                local skillName = aiConfig.aiData.name or "技能名字"
                evtData.skillName = htextTag.create2Unit(evtData.triggerUnit, skillName, 10, "ff3300", 1, 0, 50)
                evtData.shifatiao =
                    heffect.xyz(
                        "GenericBar.mdx",
                        hunit.x(evtData.triggerUnit),
                        hunit.y(evtData.triggerUnit),
                        hunit.z(evtData.triggerUnit) - 500,
                        shifashijian
                    )
                hjapi.DzBindEffect(evtData.triggerUnit, "overhead", evtData.shifatiao)
                evtData.shifatiaoTimer =
                    htime.setInterval(
                        0.02,
                        function(curTimer)
                            local percentile =
                                math.max(0, math.min(100, math.ceil(curTimer.passedSec() / shifashijian * 100)))
                            hjapi.DzSetEffectAnimation(evtData.shifatiao, percentile, 0)
                            hcache.set(evtData.triggerUnit, "AI_SKILL_CASTING_SHIFATIAO_CURRENT", curTimer.passedSec())
                        end
                    )
                if aiConfig.aiData.interval ~= nil and aiConfig.aiData.periodEffect ~= nil then
                    hcache.set(
                        evtData.triggerUnit,
                        "zdjn_sfsj_interval_timer_" .. evtData.triggerSkill,
                        htime.setInterval(
                            math.round(aiConfig.aiData.interval * 100 / (skill_speed + 100)),
                            function(curTimer)
                                aiConfig.aiData.periodEffect(evtData, curTimer)
                            end
                        )
                    )
                end
            end
            evtData.targetX = hunit.x(evtData.targetUnit)
            evtData.targetY = hunit.y(evtData.targetUnit)
            evtData.targetZ = hunit.z(evtData.targetUnit)
            hcache.set(evtData.triggerUnit, "zdjn_finish_sh_" .. evtData.triggerSkill, false)
            hcache.set(evtData.triggerUnit, CONST_CACHE.SKILL_EFFECT .. evtData.triggerSkill, evtData)
            hcache.set(
                evtData.triggerUnit,
                "zdjn_sfsj_timer_" .. evtData.triggerSkill,
                htime.setTimeout(
                    shifashijian,
                    function(_)
                        echo("timeout")
                        hcache.free(evtData.triggerUnit, "zdjn_sfsj_timer_" .. evtData.triggerSkill)
                        hcache.set(evtData.triggerUnit, "zdjn_finish_sh_" .. evtData.triggerSkill, true)
                        cj.IssueImmediateOrder(evtData.triggerUnit, "stop")
                    end
                )
            )
        end
    )
    hevent.reaction(
        CONST_EVENT.skillStop,
        "ai_jineng" .. AI_JINENG_ID,
        function(evtData)
            echo("skillStop")
            if
                hskill.hasActiveAbility(evtData.triggerUnit, AI_JINENG_ID) == false or
                evtData.triggerSkill ~= AI_JINENG_ID
            then
                return
            end
            local triggerData = hcache.get(evtData.triggerUnit, CONST_CACHE.SKILL_EFFECT .. evtData.triggerSkill)
            if (triggerData == nil or triggerData.targetUnit == nil) then
                return
            end
            if triggerData.shifatiao ~= nil then
                triggerData.shifatiaoTimer.destroy()
                hjapi.DzUnbindEffect(triggerData.shifatiao)
                hjapi.DzSetEffectPos(triggerData.shifatiao, 0, 0, -1000)
                heffect.destroy(triggerData.shifatiao)
                htextTag.destroy(triggerData.skillName)
                hcache.set(evtData.triggerUnit, "AI_SKILL_CASTING", false)
            end
            hcache.free(evtData.triggerUnit, CONST_CACHE.SKILL_EFFECT .. evtData.triggerSkill)
            if hcache.get(evtData.triggerUnit, "zdjn_finish_sh_" .. evtData.triggerSkill, nil) == true then
                triggerData.aiConfig.aiData.effect(triggerData)
            else
                local skillName = triggerData.aiConfig.aiData.name or "技能名字"
                htextTag.create2Unit(evtData.triggerUnit, skillName .. "被打断", 10, "ff3300", 1, 1, 50)
            end
            hbuff.delete(evtData.triggerUnit, "稳固")
            local timer = hcache.get(evtData.triggerUnit, "zdjn_sfsj_timer_" .. evtData.triggerSkill)
            if timer ~= nil then
                timer.destroy()
            end
            hcache.free(evtData.triggerUnit, "zdjn_sfsj_timer_" .. evtData.triggerSkill)
            local intervalTimer = hcache.get(evtData.triggerUnit, "zdjn_sfsj_interval_timer_" .. evtData.triggerSkill)
            if intervalTimer ~= nil then
                intervalTimer.destroy()
            end
        end
    )
    local tmpAttr =
        hunit.getAttributeBasedOnOptions(
            {
                level = 60,
                attackSpace = hslk.n2v("炎魔之子", "cool1"),
                guaiwuType = MONSTER_TYPE.FUBEN_XIAOGUAI,
                nandu = FUBEN_NANDU.PUTONG,
                count = 1
            }
        )
    for i = 1, 6, 1 do
        local tmpUnit =
            henemy.create(
                {
                    id = hslk.n2i("炎魔之子"),
                    x = hunit.x(hero) + math.random(-500, 500),
                    y = hunit.y(hero) + math.random(-500, 500),
                    facing = 0,
                    attr = tmpAttr,
                    nandu = 1,
                    AI = UnitAI(
                        {
                            {
                                aiType = UNIT_AI_TYPE.CAST_SKILL,
                                aiData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT,
                                    name = "融入岩浆",
                                    castCD = 1,
                                    --castCountLimit = 1,
                                    shifashijian = 2,
                                    castDistance = 10000,
                                    minNandu = FUBEN_NANDU.PUTONG,
                                    --healthBelowLimit = 50, -- only cast when health is < 65%
                                    notInterruptable = true,
                                    customCondition = function(whichUnit)
                                        if hcache.get(whichUnit, "消灭所有炎魔之子", false) then
                                            return false
                                        else
                                            return true
                                        end
                                    end,
                                    startEffect = function(evtData)
                                    end,
                                    effect = function(evtData)
                                        if hcache.get(evtData.triggerUnit, "释放过", false) then
                                            dump(i .. "释放过")
                                        end
                                        hcache.set(evtData.triggerUnit, "释放过", true)
                                        hunit.pause(evtData.triggerUnit)
                                        hunit.animate(evtData.triggerUnit, 0)
                                        hevent.register(
                                            evtData.triggerUnit,
                                            CONST_EVENT.damagingCustomTarget,
                                            "炎魔无敌",
                                            function(evtData)
                                                evtData.damage = 0
                                            end
                                        )
                                        hunit.setInvulnerable(evtData.triggerUnit, true)

                                        htime.setTimeout(
                                            i,
                                            function(t)
                                                hunit.animate(evtData.triggerUnit, 1)
                                                htime.setTimeout(
                                                    2,
                                                    function(t)
                                                        hunit.resume(evtData.triggerUnit)
                                                        hunit.setInvulnerable(evtData.triggerUnit, false)
                                                        hevent.unregister(
                                                            evtData.triggerUnit,
                                                            CONST_EVENT.damagingCustomTarget,
                                                            "炎魔无敌"
                                                        )
                                                    end
                                                )
                                            end
                                        )
                                    end
                                }
                            },
                            {
                                aiType = UNIT_AI_TYPE.ATTACK_HIGEST_CHOUHENG,
                                aiData = {
                                    targetType = UNIT_AI_TARGET_TYPE.HIGHEST_CHOUHENG_UNIT
                                }
                            }
                        }
                    ),
                    tuozhanshijian = 36000
                }
            )
        hskill.add(tmpUnit, hslk.n2i("AI技能模版"), 1, 0)
        hunit.setExpReward(tmpUnit, 0)
    end
end

--new_local_test()

--hskill.add(hero, "BSTN", 1, 10)
--BlzSetAbilityRealLevelField(BlzGetUnitAbility(unit, FourCC("BSTN")), ABILITY_RLF_DURATION_NORMAL, 0, 3.0)
--local ability = hjapi.EXGetUnitAbility(hero, "BSTN")

--hskill.destroy(hero, "Aatk", 1)
--hskill.destroy(hero, "Amov", 1)

--hzhuanye.tryZengJiaExp("采矿", hplayer.loc(), 1)

--dump(hplayer.dzCunDang[hplayer.loc()].loadKeyFromCunDang("richangquest", false, false))

--hdzcundang.save_to_server(
-- hplayer.loc(),
--  "richangquest",
--   "000000000000000000000000000000000000000000000000000000000000000",
--    true
--)

--hquestcustom.addEventCount(hplayer.loc(), CONST_EVENT.kill, "黑铁矮人索瑞森大帝")

--hjapi.DzUnitDisableAttack(hero, true)

--hunit.setFlyHeight(hero,500,9999)

--echo(hattr.get(hero, "move"))

--hskill.setCoolDown(hero, hslk.n2i("利刃风暴"), 0)

function localtestFullQuest(whichPlayer)
    for _, questSeries in ipairs(hquestcustom[whichPlayer]) do
        questSeries.currentIndex = #(questSeries.data)
        if questSeries.name == "主线任务" then
            questSeries.currentIndex = 87
            hquestcustom.cundang(questSeries, whichPlayer)
            return
        end
    end
end

--localtestFullQuest(hplayer.loc())
--dump(KEYS_LOADED_ALL)

function understandcundangstatus()
    local cundang = hplayer.dzCunDang[hplayer.loc()]
    local status = cundang.loadKeyFromCunDang("richangquest", false, false)
    local status2 = cundang.loadKeyFromCunDang("richangquest", false, true)
    local status3 = cundang.loadKeyFromCunDang("richangquest", true, false)
    local status4 = cundang.loadKeyFromCunDang("richangquest", true, true)
    dump(status)
    dump(status2)
    dump(status3)
    dump(status4)

    local i = 0
    local j = 0
    local a = 0
    for k, v in pairs(KEYS_LOADED_ALL) do
        i = i + 1
        if string.find(k, "juese") then
            j = j + 1
        end
        if string.find(k, "juesewuqizhan") then
            a = a + 1
        end
    end
    dump(KEYS_LOADED_ALL)
    dump(i)
    dump(j)
    dump(a)
end

--hjapi.DzSetUnitModel(hero, "war3mapImported\\FelStalker Mount.mdx")
--local e = heffect.attach("war3mapImported\\[pifu]M2.mdx", hero, "sprite", -1)
--hunit.setFlyHeight(hero, 0, 9999)

--hzuoqi.jihuozuoqi("骑乘用马", hplayer.loc(), true)

--dump(hzuoqi.isZuoqiActive(hcolor.green("大军马"), hplayer.loc()))
--dump(hzuoqi.isZuoqiActiveByIndex(2, hplayer.loc()))
--dump(hjapi.exec("DzAPI_Map_GetUserID", hplayer.loc()))

--heffect.xyz("Abilities\\Spells\\Other\\Tornado\\Tornado_Target.mdl", hunit.x(hero), hunit.y(hero), hunit.z(hero), 5, 1, 6, 6, 6 )
--hskillMoban.radiusWarning(hunit.x(hero), hunit.y(hero), hunit.z(hero), 400, 1)

--dump(hdzcundang.cache[hplayer.loc()])

--dump(hdzcundang.cache[hplayer.loc()]["dabeibao0"])

--dump(bit32.decrypt(hjapi.KKApiPlayerGUID(hplayer.loc()),hdzcundang.cache[hplayer.loc()]["dabeibao0"]))

--hquestcustom.addEventCount(hplayer.loc(), CONST_EVENT.caiyao, "银叶草")
--hquestcustom.addEventCount(hplayer.loc(), CONST_EVENT.caikuang, "铁矿石")
--hquestcustom.addEventCount(hplayer.loc(), CONST_EVENT.kill, "监狱之王范克瑞夫")
--hquestcustom.addEventCount(hplayer.loc(), CONST_EVENT.kill, "血色军统帅莫格莱尼")
--hquestcustom.addEventCount(hplayer.loc(), CONST_EVENT.kill, "圣光主教布莱克安")

function add_local_test_item()
    hitem.create(
        {
            id = hslk.n2i("炎魔之手"),
            x = hunit.x(hero),
            y = hunit.y(hero)
        }
    )
end

--dump(hhuanhua[hplayer.loc()])

--dump(hhuanhua.getUnitHuanhuaStatus(hero))

--dump(hhuanhua.getUnitHuanhuaStatus(hero)[HUANHUA_POSITION.JUESE].file)

--- check if we have single resources
---@return boolean

--dump(hresource.description)

--local model = hjapi.DzFrameFindByName("Tips_Model_Model", 0)
--hjapi.DzFrameSetScale(model, 0.8)

--dump(hxiaoditu)

--local model = hjapi.FrameTag("SPRITE", "test", hjapi.DzGetGameUI(), "")
--hjapi.DzFrameSetPoint(model, 4, hjapi.DzGetGameUI(), 4, 0, 0)
--hjapi.DzFrameSetAnimate(model, 0, true)
--hjapi.DzFrameSetSize(model, 0.2, 0.2)
--hjapi.DzFrameSetModel(model, "war3mapImported\\[AZ]lianjidian_DZ.mdx", 0, 0)
--hjapi.DzFrameSetModel(model, "war3mapImported\\AZ_UI_SYZH.MDX", 0, 0)
--heffect.xyz("war3mapImported\\AZ_UI_SYZH.MDX", hunit.x(hero), hunit.y(hero), hunit.z(hero), 10, 1)
--hjapi.DzFrameSetScale(model, 1)
--hjapi.DzFrameShow(model, true)

--hxiaoditu.showDaditu()
--dump(hxiaoditu.dadituBack)
--dump(hxiaoditu.isDadituOpen)

--hjapi.DzFrameSetTexture(hjapi.DzFrameGetMinimap(), "ReplaceableTextures\\xiaoditu\\UI_map_02.blp")
local function test_test_test()
    local frame = hjapi.DzFrameGetMinimap()
    hjapi.DzSetWar3MapMap("ReplaceableTextures\\xiaoditu\\UI_map_09.blp")
    while frame ~= nil do
        hjapi.DzFrameSetTexture(frame, "ReplaceableTextures\\xiaoditu\\UI_map_04.blp")
        if hjapi.DzFrameGetChildrenCount(frame) > 0 then
            dump(hjapi.DzFrameGetChildrenCount(frame))
            dump(hjapi.DzFrameGetChildrenCount(frame))
            frame = hjapi.DzFrameGetChild(frame, 0)
        else
            frame = nil
        end
    end
end
--hjapi.exec("DzUnlockBlpSizeLimit")
--hjapi.DzSetWar3MapMap("ReplaceableTextures\\xiaoditu\\UI_map_02.blp")

--- 这个是测试UI模型的 不是特效模型
local function newtestestest()
    local model = hjapi.FrameTag("SPRITE", "test_model", hjapi.DzGetGameUI())
    hjapi.DzFrameSetModel(model, "war3mapImported\\[UI]1.mdx", 0, 0)
    hjapi.DzFrameSetPoint(model, 4, hjapi.DzGetGameUI(), 4, 0, -0.12)
    hjapi.DzFrameSetSize(model, 0.00001, 0.00001)
    --hjapi.DzFrameShow(model, true)
end
-- 这个文件的代码支持热更新 比如 新加一行
--heffect.attach("[daozei]xunji.mdl", hero, "hand right", 8) --hero 是之前定义好的 代表当前玩家的英雄 这里代码修改完后保存 ctrl+S
--heffect.attach("war3mapImported\\AZ_ranjzhixin.mdx", hero, "overhead", 8)
--heffect.xyz("war3mapImported\\ShadowWell.mdx", hunit.x(hero), hunit.y(hero), hunit.z(hero), 5, 1, 1, 1, 1)
--heffect.attach("BonefireArrow1.mdx", hero, "overhead", 10) --hero 是之前定义好的 代表当前玩家的英雄 这里代码修改完后保存 ctrl+S
--local e = heffect.attach("war3mapImported\\chest_magec_gh_orange.mdx", hero, "chest", 60)
--hcamera.quake(hplayer.loc(), 10, 0.1)--这个接口可以用来触发震动 baocun yixa 保存 这里测试完了要删掉 或者加上--来屏蔽掉，不然每次启动游戏都会自动跑这些代码 万一出错地图就无法装载了
--hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\3553.mp3", 1000, true), 80, hero)
--local e = heffect.xyz("war3mapImported\\zb_longji.mdx", hunit.x(hero), hunit.y(hero), hunit.z(hero), 1, 1, 1, 1, 1)
--local e = heffect.xyz("spell\\XCFS_Q.mdx", hunit.x(hero), hunit.y(hero), hunit.z(hero), 1, 1, 1.5, 1.5, 1.5)

--hcamera.quake(hplayer.loc(), 5, 1)--这个接口可以用来触发震动 baocun yixa 保存 这里测试完了要删掉 或者加上--来屏蔽掉，不然每次启动游戏都会自动跑这些代码 万一出错地图就无法装载了

--hsound.voice2Unit(hsound.voiceCreate("resource\\spell\\4155.mp3", 1000, true), 80, hero)
--echo(hslk.n2v("火法","slk","collision"))

--hsound.voice2Unit(hsound.voiceCreate("resource\\war3mapImported\\sound\\spell_dh_eye_beam_loop_01.mp3", 1000, true), 100, hero)

--dump(hdzcundang.cacheAll)
--heffect.attach("AZ_ranjzhixin.mdx", hero, "over head", 10)

--hzuoqi.jihuozuoqi("疾行蝎", hplayer.loc(), true)

function huanyingxiong(name)
    hunit.destroy(hero)
    local newHero =
        hunit.create(
            {
                whichPlayer = hplayer.loc(),
                id = hslk.n2i(name),
                x = hunit.x(hero),
                y = hunit.y(hero),
                attr = {
                    reborn = DEFAULT_HERO_REBORN,
                    rebornX = hunit.x(hero),
                    rebornY = hunit.y(hero)
                }
            }
        )
    hhero.player_heroes[hplayer.index(hplayer.loc())][1] = newHero
    hunit.destroy(hero)
end

--huanyingxiong("战斗贼")


--hresource.addSingleResource(hplayer.loc(), HSHOP_COST_TYPE.daixinjifen, 2, true)
--hresource.changeSingleResource(hplayer.loc(), HSHOP_COST_TYPE.gold, 11126)
