hartifact = { artifactNameMap = {} }


--- first column is cunDangvalue, second colum is cumulatedshengqinengliang, third column is shengqinengliang to reach next level
SQNL_CONFIG   = {
    { 2000,   8000,    8000 },
    { 4000,   20000,   12000 },
    { 6000,   33000,   13000 },
    { 8000,   47000,   14000 },
    { 10000,  62000,   15000 },
    { 12000,  78000,   16000 },
    { 14000,  95000,   17000 },
    { 16000,  113000,  18000 },
    { 18000,  132000,  19000 },
    { 20000,  152000,  20000 },
    { 22000,  173000,  21000 },
    { 24000,  195000,  22000 },
    { 26000,  218000,  23000 },
    { 28000,  242000,  24000 },
    { 30000,  267000,  25000 },
    { 32000,  293000,  26000 },
    { 34000,  320000,  27000 },
    { 36000,  348000,  28000 },
    { 38000,  377000,  29000 },
    { 40000,  407000,  30000 },
    { 42000,  438000,  31000 },
    { 44000,  470000,  32000 },
    { 46000,  503000,  33000 },
    { 48000,  537000,  34000 },
    { 50000,  572000,  35000 },
    { 52000,  608000,  36000 },
    { 54000,  645000,  37000 },
    { 56000,  683000,  38000 },
    { 58000,  722000,  39000 },
    { 60000,  762000,  40000 },
    { 62000,  803000,  41000 },
    { 64000,  845000,  42000 },
    { 66000,  888000,  43000 },
    { 68000,  932000,  44000 },
    { 70000,  977000,  45000 },
    { 72000,  1023000, 46000 },
    { 74000,  1070000, 47000 },
    { 76000,  1118000, 48000 },
    { 78000,  1167000, 49000 },
    { 80000,  1217000, 50000 },
    { 82000,  1268000, 51000 },
    { 84000,  1320000, 52000 },
    { 86000,  1373000, 53000 },
    { 88000,  1427000, 54000 },
    { 90000,  1482000, 55000 },
    { 92000,  1538000, 56000 },
    { 94000,  1595000, 57000 },
    { 96000,  1653000, 58000 },
    { 98000,  1712000, 59000 },
    { 100000, 1772000, 60000 },
    { 102000, 1833000, 61000 },
    { 104000, 1895000, 62000 },
    { 106000, 1958000, 63000 },
    { 108000, 2022000, 64000 },
    { 110000, 2087000, 65000 },
    { 112000, 2153000, 66000 },
    { 114000, 2220000, 67000 },
    { 116000, 2288000, 68000 },
    { 118000, 2357000, 69000 },
    { 120000, 2427000, 70000 },
    { 122000, 2498000, 71000 },
    { 124000, 2570000, 72000 },
    { 126000, 2643000, 73000 },
    { 128000, 2717000, 74000 },
    { 130000, 2792000, 75000 },
    { 132000, 2868000, 76000 },
    { 134000, 2945000, 77000 },
    { 136000, 3023000, 78000 },
    { 138000, 3102000, 79000 },
    { 140000, 3182000, 80000 },
    { 142000, 3263000, 81000 },
    { 144000, 3345000, 82000 },
    { 146000, 3428000, 83000 },
    { 148000, 3512000, 84000 },
    { 150000, 3597000, 85000 },
    { 152000, 3683000, 86000 },
    { 154000, 3770000, 87000 },
    { 156000, 3858000, 88000 },
    { 158000, 3947000, 89000 },
    { 160000, 4037000, 90000 },
    { 162000, 4128000, 91000 },
    { 164000, 4220000, 92000 },
    { 166000, 4313000, 93000 },
    { 168000, 4407000, 94000 },
    { 170000, 4502000, 95000 },
    { 172000, 4598000, 96000 },
    { 174000, 4695000, 97000 },
    { 176000, 4793000, 98000 },
    { 178000, 4892000, 99000 },
    { 180000, 4992000, 100000 },
    { 182000, 5093000, 101000 },
    { 184000, 5195000, 102000 },
    { 186000, 5298000, 103000 },
    { 188000, 5402000, 104000 },
    { 190000, 5507000, 105000 },
    { 192000, 5613000, 106000 },
    { 194000, 5720000, 107000 },
    { 196000, 5828000, 108000 },
    { 198000, 5937000, 109000 },
    { 200000, 6047000, 110000 },
    { 202000, 6158000, 111000 },
    { 204000, 6270000, 112000 },
}

SQNLHQ_CONFIG = {}
local function build_single_sqnl(fubenname, volume, ptrate, yxrate, ssrate, cqrate, cqvolume, schedule)
    SQNLHQ_CONFIG[fubenname] = {}
    SQNLHQ_CONFIG[fubenname][FUBEN_NANDU.PUTONG] = { rate = ptrate, volume = volume }
    SQNLHQ_CONFIG[fubenname][FUBEN_NANDU.YINGXIONG] = { rate = yxrate, volume = volume }
    SQNLHQ_CONFIG[fubenname][FUBEN_NANDU.SHISHI] = { rate = ssrate, volume = volume }
    SQNLHQ_CONFIG[fubenname][FUBEN_NANDU.CHUANQI] = {}
    SQNLHQ_CONFIG[fubenname].schedule = schedule
    for i = 1, 40 do
        SQNLHQ_CONFIG[fubenname][FUBEN_NANDU.CHUANQI][i] = {
            rate = cqrate,
            volume =
                cqvolume * (1.11 ^ i)
        }
    end
end
build_single_sqnl("丛林深处", 0, 0, 0, 0, 100, 30, { 1, 0, 0, 0, 0, 1, 1 })
build_single_sqnl("月亮湖", 0, 0, 0, 0, 100, 40, { 0, 1, 0, 0, 0, 1, 1 })
build_single_sqnl("王城监狱", 0, 0, 0, 0, 100, 50, { 0, 0, 1, 0, 0, 1, 1 })
build_single_sqnl("血色军大营", 0, 0, 0, 0, 100, 60, { 0, 0, 0, 1, 0, 1, 1 })
build_single_sqnl("圣光大教堂", 0, 0, 0, 0, 100, 70, { 0, 0, 0, 0, 1, 1, 1 })
build_single_sqnl("半人马营地", 0, 0, 0, 0, 100, 80, { 0, 0, 0, 1, 0, 1, 1 })
build_single_sqnl("矮人地下城", 0, 0, 0, 0, 100, 90, { 0, 0, 1, 0, 0, 1, 1 })
build_single_sqnl("火焰之心", 0, 0, 0, 0, 100, 300, { 0, 1, 0, 0, 0, 1, 1 })
build_single_sqnl("黑龙王子的巢穴", 0, 0, 0, 0, 100, 100, { 1, 0, 0, 0, 0, 1, 1 })
build_single_sqnl("屠龙者的巢穴", 0, 0, 0, 0, 100, 200, { 0, 1, 0, 0, 0, 1, 1 })
build_single_sqnl("破碎大厅", 0, 0, 0, 0, 100, 600, { 0, 0, 1, 0, 0, 1, 1 })
build_single_sqnl("法师塔", 0, 0, 0, 0, 100, 720, { 0, 0, 0, 1, 0, 1, 1 })
build_single_sqnl("风暴要塞", 0, 0, 0, 0, 100, 1000, { 0, 0, 0, 0, 1, 1, 1 })

local function generateArtifactConfig(params)
    local defaultPassiveEffect = function(level)
        return {
            action = CONST_EVENT.attr,
            effect = _attr({ zhushuxing = "+" .. (level + 2) })
        }
    end

    local defaultActiveEffect = function(level, perLevelDescription, action, effect)
        if level == 1 then
            return {
                description = perLevelDescription(level),
                action = action,
                effect = effect or function(evtData)
                end
            }
        else
            return {
                description = perLevelDescription(level),
                action = CONST_EVENT.none,
                effect = effect or function(evtData)
                end
            }
        end
    end

    local function generateTalent(talentParams, tianfuIndex)
        local talent = {
            name = talentParams.name,
            description = talentParams.description,
            maxLevel = talentParams.maxLevel or 10,
            art = talentParams.art,
            activeLevel = talentParams.activeLevel or 0,
            dependency = talentParams.dependency or {},
            cunDangPosition = talentParams.cunDangPosition,
            requiredExp = talentParams.requiredExp,
            isElite = talentParams.isElite or false,
            passiveEffects = {},
            activeEffects = {}
        }

        for i = 1, talent.maxLevel do
            table.insert(talent.passiveEffects, defaultPassiveEffect(tianfuIndex))
            table.insert(talent.activeEffects,
                defaultActiveEffect(i, talentParams.perLevelDescription, talentParams.action, talentParams.effect))
        end

        return talent
    end

    local artifact = {
        name = params.name,
        icon = params.icon,
        art = params.art,
        description = params.description,
        cundangStr = params.cundangStr,
        talentTree = {},
        totalExp = params.totalExp or 0,
        maxTotalExp = params.maxTotalExp or 0,
        expCunDangStr = params.expCunDangStr,
        canEquip = params.canEquip or function(whichPlayer) return true end,
        canEquipDesc = params.canEquipDesc or "",
        isEquipped = params.isEquipped or false
    }

    for _, row in ipairs(params.talents) do
        local talentRow = {}
        for i, talentParams in ipairs(row) do
            table.insert(talentRow, generateTalent(talentParams, i))
        end
        table.insert(artifact.talentTree, talentRow)
    end

    return artifact
end

local fengjian                          = generateArtifactConfig({
    name = "雷霆之怒",
    icon = "ReplaceableTextures\\zhuangbei\\INV_Sword_39.blp",
    art = "ReplaceableTextures\\shenqi\\sq_zhufengjian.blp",
    description =
    "在远古的风暴中锻造，由元素之灵祝福，这把神圣的利刃承载着萨满教的至高荣耀。它的刀锋闪烁着闪电的光芒，每一次挥舞都伴随着雷霆的怒吼。这不仅是一把武器，更是风元素的化身，是大地与天空的纽带。曾在英雄萨尔手中驰骋沙场，如今它寻找着新的主人，一位能够驾驭其狂暴力量的勇士。它的力量可以召唤风暴，驱散黑暗，庇护盟友。但要小心，因为它的力量如同双刃剑，不慎使用可能会招致元素的愤怒。拥有此剑者，将成为元素的主宰，风暴的统帅。你，可曾听到雷霆的呼唤？",
    cundangStr = "artifactltzn",
    expCunDangStr = "artltznexp",
    talents = {
        { -- 第一列天赋（原第一行）
            {
                name                = "雷霆之怒",
                description         = "攻击时有7%概率触发基于攻击力的金系魔法伤害，该技能触发CD为2秒。",
                art                 = "ReplaceableTextures\\shenqi\\leitingzhinu.blp",
                cunDangPosition     = 2,
                requiredExp         = 4000,
                perLevelDescription = function(level) return "雷霆之怒的基础伤害为" .. (100 + level * 10) .. "%攻击力" end,
                action              = CONST_EVENT.attack,
                effect              = function(evtData, artifact)
                    local tianfu1     = hartifact.getTianfuLevel(artifact, "雷霆之怒")
                    local tianfu2     = hartifact.getTianfuLevel(artifact, "怒雷狂啸")
                    local tianfu3     = hartifact.getTianfuLevel(artifact, "闪电枷锁")
                    local tianfu4     = hartifact.getTianfuLevel(artifact, "雷神之眼")
                    local tianfu5     = hartifact.getTianfuLevel(artifact, "闪电之舞")
                    local tianfu6     = hartifact.getTianfuLevel(artifact, "雷霆万钧")
                    local tianfu7     = hartifact.getTianfuLevel(artifact, "雷神之触")
                    local damageMulti = 1 + 0.1 * tianfu1
                    local damageMulti = damageMulti * (1 + 0.02 * tianfu2)
                    local rate        = 7 + 0.3 * tianfu5
                    if math.random(1, 100) <= rate and htime.setupAndCheckCoolDown(evtData.triggerUnit, "雷霆之怒CD", 2) then
                        local sourceUnit = evtData.triggerUnit
                        local targetUnit = evtData.targetUnit
                        local leitingzhinu
                        leitingzhinu = function()
                            local damage = hattr.getWithLimit(sourceUnit, nil, "attack", 10) * damageMulti
                            local scale = 1
                            if math.random(1, 100) <= tianfu3 * 10 then
                                damage = damage * 2
                                scale = 2
                            end
                            hskill.damage({
                                sourceUnit = sourceUnit,
                                targetUnit = targetUnit,
                                damage = damage,
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.MOFA,
                                effect = nil,
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                                shanghainame = "雷霆之怒",
                                tmpAttr = _attr({ fa_bao = "+" .. (0.1 + tianfu4 * 3) }),
                            })
                            heffect.xyz(
                                "war3mapImported\\[Spell]_083.MDX",
                                hunit.x(targetUnit),
                                hunit.y(targetUnit),
                                hunit.z(targetUnit),
                                0,
                                1,
                                scale,
                                scale,
                                scale
                            )
                            if math.random(1, 100) <= tianfu6 * 2 then
                                htime.setTimeout(0.2, function(t)
                                    leitingzhinu()
                                end)
                            end
                            if math.random(1, 100) <= tianfu7 * 10 then
                                hunit.addCurMana(sourceUnit, 2)
                            end
                        end
                        leitingzhinu()
                    end
                end
            },
            {
                name = "怒雷狂啸",
                description = "雷霆之怒的伤害提高。",
                art = "ReplaceableTextures\\shenqi\\nuleikuangxiao.blp",
                cunDangPosition = 3,
                requiredExp = 8000,
                dependency = { "雷霆之怒" },
                perLevelDescription = function(level) return "雷霆之怒的伤害提高" .. (level * 2) .. "%" end,
            },
            {
                name = "闪电枷锁",
                description = "雷霆之怒有概率触发雷电枷锁，伤害翻倍。",
                art = "ReplaceableTextures\\shenqi\\shandianjiasuo.blp",
                cunDangPosition = 4,
                requiredExp = 16000,
                dependency = { "怒雷狂啸" },
                perLevelDescription = function(level) return "触发概率为" .. (level * 2) .. "%" end,
            },
            {
                name = "雷神之眼",
                description = "雷霆之怒的暴击概率提高lv*3。",
                art = "ReplaceableTextures\\shenqi\\leishenzhiyan.blp",
                cunDangPosition = 5,
                requiredExp = 32000,
                dependency = { "闪电枷锁" },
                perLevelDescription = function(level) return "雷霆之怒的暴击概率提高" .. (level * 2) .. "%" end,
            },
            {
                name = "闪电之舞",
                description = "雷霆之怒的触发概率提高。",
                art = "ReplaceableTextures\\shenqi\\shandianzhiwu.blp",
                cunDangPosition = 6,
                requiredExp = 64000,
                dependency = { "雷神之眼" },
                perLevelDescription = function(level) return "雷霆之怒的触发概率提高。" .. (level * 0.3) .. "%" end,
            },
            {
                name = "雷霆万钧",
                description = "雷霆之怒有概率会连续触发。",
                art = "ReplaceableTextures\\shenqi\\leitingwanjun.blp",
                cunDangPosition = 7,
                requiredExp = 128000,
                dependency = { "闪电之舞" },
                perLevelDescription = function(level) return "连续触发概率为" .. (level * 2) .. "%" end,
            },
            {
                name = "雷神之触",
                description = "雷霆之怒造成伤害时有概率获得2点能量值。",
                art = "ReplaceableTextures\\shenqi\\leishenzhichu.blp",
                cunDangPosition = 8,
                requiredExp = 256000,
                dependency = { "雷霆万钧" },
                perLevelDescription = function(level) return "触发概率为" .. (level * 10) .. "%" end,
            },
        },
        { -- 第二列天赋（原第二行）
            {
                name                = "风暴之心",
                description         = "攻击时有10%概率召唤雷云每秒对范围内所有单位造成基于攻击力的金系魔法伤害，持续5秒，冷却时间30秒。",
                art                 = "ReplaceableTextures\\shenqi\\fengbaozhixin.blp",
                cunDangPosition     = 9,
                requiredExp         = 4000,
                perLevelDescription = function(level) return "雷霆之怒的基础伤害为" .. (50 + level * 5) .. "%攻击力" end,
                action              = CONST_EVENT.attack,
                effect              = function(evtData, artifact)
                    local tianfu1     = hartifact.getTianfuLevel(artifact, "风暴之心")
                    local tianfu2     = hartifact.getTianfuLevel(artifact, "风暴主宰")
                    local tianfu3     = hartifact.getTianfuLevel(artifact, "雷霆之魂")
                    local tianfu4     = hartifact.getTianfuLevel(artifact, "暴风之怒")
                    local tianfu5     = hartifact.getTianfuLevel(artifact, "狂雷天怒")
                    local tianfu6     = hartifact.getTianfuLevel(artifact, "风暴之力")
                    local tianfu7     = hartifact.getTianfuLevel(artifact, "风雷主宰")
                    local damageMulti = 0.5 + 0.05 * tianfu1
                    damageMulti       = damageMulti * (1 + 0.03 * tianfu5)
                    local cd          = 30 - tianfu2
                    local duration    = 5 + 0.5 * tianfu3
                    -- 实现惩戒之力的具体逻辑
                    if math.random(1, 100) <= 5 and htime.setupAndCheckCoolDown(evtData.triggerUnit, "风暴之心", cd) then
                        local sourceUnit = evtData.triggerUnit
                        local targetUnit = evtData.targetUnit
                        local x = hunit.x(targetUnit)
                        local y = hunit.y(targetUnit)
                        heffect.xyz("[boss]fengyuansulingzhu2.mdx", x, y, hunit.z(targetUnit), duration, 1)
                        htime.setInterval(1, function(t)
                            if t.passedSec() > duration then
                                t.destroy()
                                return
                            end
                            hskillMoban.radiusAOE(x, y, sourceUnit, 480, function(targetUnit)
                                if tianfu6 > 0 then
                                    hbuff.update(
                                        10,
                                        targetUnit,
                                        "风暴之力",
                                        false,
                                        function()
                                            hevent.register(
                                                targetUnit, CONST_EVENT.damagingCustomTarget, "风暴之力debuff",
                                                function(evtData)
                                                    if evtData.damageType == DAMAGE_TYPE.WULI then
                                                        evtData.damage = evtData.damage * (1 + 0.003 * tianfu6)
                                                    end
                                                end
                                            )
                                        end,
                                        function()
                                            hevent.unregister(
                                                targetUnit, CONST_EVENT.damagingCustomTarget, "风暴之力debuff"
                                            )
                                        end,
                                        "ReplaceableTextures\\shenqi\\fengbaozhili.blp",
                                        "风暴之力",
                                        1,
                                        nil,
                                        nil,
                                        nil,
                                        nil,
                                        HBUFF_UPDATE_MODE.OVERWRITE
                                    )
                                end
                                hskill.damage({
                                    sourceUnit = sourceUnit,
                                    targetUnit = targetUnit,
                                    damage = hattr.get(sourceUnit, "attack", 1) * damageMulti,
                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                    damageType = DAMAGE_TYPE.MOFA,
                                    effect = "[boss]fengyuansu.mdx",
                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                                    shanghainame = "风暴之心",
                                    tmpAttr = _attr({ fa_bao = "+" .. (0.1 + tianfu4 * 3) }),
                                })
                            end)
                        end)
                        if tianfu7 > 0 then
                            hbuff.addStackAttrBuff(CONST_DAMAGE_SRC.skill, sourceUnit, "风雷主宰",
                                _attr({
                                    energy_back = "+" .. (3 * tianfu7) }),
                                10,
                                1,
                                "ReplaceableTextures\\shenqi\\fengleizhuzai.blp",
                                "风雷主宰",
                                true
                            )
                        end
                    end
                end
            },
            {
                name = "风暴主宰",
                description = "风暴之心的冷却时间降低",
                art = "ReplaceableTextures\\shenqi\\fengbaozhuzai.blp",
                cunDangPosition = 10,
                requiredExp = 8000,
                dependency = { "风暴之心" },
                perLevelDescription = function(level) return "风暴之心的冷却时间降低" .. (level) .. "秒" end,
            },
            {
                name = "雷霆之魂",
                description = "风暴之心的持续时间增加。",
                art = "ReplaceableTextures\\shenqi\\leitingzhihun.blp",
                cunDangPosition = 11,
                requiredExp = 16000,
                dependency = { "风暴主宰" },
                perLevelDescription = function(level) return "风暴之心的持续时间增加" .. (level * 0.5) .. "秒" end,
            },
            {
                name = "暴风之怒",
                description = "风暴之心的暴击概率提高。",
                art = "ReplaceableTextures\\shenqi\\baofengzhinu.blp",
                cunDangPosition = 12,
                requiredExp = 32000,
                dependency = { "雷霆之魂" },
                perLevelDescription = function(level) return "风暴之心的暴击概率提高" .. (level * 3) .. "%" end,
            },
            {
                name = "狂雷天怒",
                description = "风暴之心的伤害提高。",
                art = "ReplaceableTextures\\shenqi\\kuangleitiannu.blp",
                cunDangPosition = 13,
                requiredExp = 64000,
                dependency = { "暴风之怒" },
                perLevelDescription = function(level) return "风暴之心的伤害提高" .. (level * 3) .. "%" end,
            },
            {
                name = "风暴之力",
                description = "风暴之心能够使敌方单位获得物理易伤状态，持续10秒。",
                art = "ReplaceableTextures\\shenqi\\fengbaozhili.blp",
                cunDangPosition = 14,
                requiredExp = 128000,
                dependency = { "狂雷天怒" },
                perLevelDescription = function(level) return "风暴之心能够使敌方单位获得" .. (level * 0.3) .. "%的物理易伤" end,
            },
            {
                name = "风雷主宰",
                description = "风暴之心使你在10秒内能量获取提高。",
                art = "ReplaceableTextures\\shenqi\\fengleizhuzai.blp",
                cunDangPosition = 15,
                requiredExp = 256000,
                dependency = { "风暴之力" },
                perLevelDescription = function(level) return "能量获取提高" .. (level * 3) .. "%" end,
            },
        },
    },
    canEquip = function(whichPlayer)
        return hquestcustom.isQuestFinished(whichPlayer, "传奇任务：雷霆之怒")
    end,
    canEquipDesc = "需要完成传说任务：雷霆之怒"
})

local emozhanren                        = generateArtifactConfig({
    name = "恶魔战刃",
    icon = "ReplaceableTextures\\BTNINV_Weapon_Glave_01.blp",
    art = "ReplaceableTextures\\shenqi\\uidandao.tga",
    description = "由恶魔猎手所持有的强大武器，蕴含着黑暗与灵魂的力量。这对战刃不仅能够切割敌人的肉体，更能撕裂他们的灵魂。拥有这把武器的人将获得操控黑暗和灵魂的能力，但也要小心不被其中的力量所腐蚀。",
    cundangStr = "artifactemzr",
    expCunDangStr = "artemzrexp",
    talents = {
        { -- 第一列天赋
            {
                name = "黑暗剪切",
                description = "你的攻击有4%概率触发黑暗剪切，额外造成一次攻击力伤害，可触发攻击特效。",
                art = "ReplaceableTextures\\shenqi\\黑暗剪切.blp",
                cunDangPosition = 2,
                requiredExp = 4000,
                perLevelDescription = function(level) return "额外造成" .. (100 + level * 10) .. "%攻击力伤害" end,
                action = CONST_EVENT.attack,
                effect = function(evtData, artifact)
                    local tianfu1 = hartifact.getTianfuLevel(artifact, "黑暗剪切")
                    local tianfu2 = hartifact.getTianfuLevel(artifact, "黑暗斩击")
                    local tianfu3 = hartifact.getTianfuLevel(artifact, "精准斩击")
                    local tianfu4 = hartifact.getTianfuLevel(artifact, "黑暗模仿")
                    local tianfu5 = hartifact.getTianfuLevel(artifact, "黑暗之灵")
                    local tianfu6 = hartifact.getTianfuLevel(artifact, "黑暗狂热")
                    local tianfu7 = hartifact.getTianfuLevel(artifact, "黑暑主宰")

                    local damageMulti = 1 + 0.1 * tianfu1
                    damageMulti = damageMulti * (1 + 0.02 * tianfu2)
                    local triggerRate = 4 + 0.2 * tianfu5

                    if math.random(1, 100) <= triggerRate then
                        local sourceUnit = evtData.triggerUnit
                        local targetUnit = evtData.targetUnit
                        local damage = hattr.getWithLimit(sourceUnit, nil, "attack", 10) * damageMulti
                        htime.setTimeout(
                            0.01, function()
                                hskill.damage({
                                    sourceUnit = sourceUnit,
                                    targetUnit = targetUnit,
                                    damage = damage,
                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                    damageType = DAMAGE_TYPE.WULI,
                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                                    shanghainame = "黑暗剪切",
                                    tmpAttr = _attr({ wu_bao = "+" .. (0.1 + tianfu3 * 2) }),
                                })
                            end)
                        heffect.xyz(
                            "AZ_PA_C_green.MDX",
                            hunit.x(sourceUnit),
                            hunit.y(sourceUnit),
                            hunit.z(sourceUnit),
                            0,
                            1,
                            1,
                            1,
                            1,
                            nil,
                            nil,
                            hunit.getFacing(sourceUnit)
                        )
                        if tianfu4 > 0 and math.random(1, 100) <= tianfu4 * 2 then
                            htime.setTimeout(
                                0.13,
                                function()
                                    hskill.damage({
                                        sourceUnit = sourceUnit,
                                        targetUnit = targetUnit,
                                        damage = damage,
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.WULI,
                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                                        isAttackReplacement = true,
                                        shanghainame = "黑暗剪切",
                                        tmpAttr = _attr({ wu_bao = "+" .. (0.1 + tianfu3 * 2) }),
                                    })
                                end
                            )
                            heffect.xyz(
                                "AZ_PA_C_green.MDX",
                                hunit.x(sourceUnit),
                                hunit.y(sourceUnit),
                                hunit.z(sourceUnit),
                                0,
                                1,
                                1,
                                1,
                                1,
                                nil,
                                nil,
                                hunit.getFacing(sourceUnit)
                            )
                        end

                        if tianfu6 > 0 then
                            if tianfu7 > 0 then
                                hbuff.addStackAttrBuff(CONST_DAMAGE_SRC.skill, sourceUnit, "黑暗狂热",
                                    _attr({ attack_speed = "+" .. (tianfu6), pugong_shanghai = "+" .. (tianfu7) }),
                                    5,
                                    1,
                                    "ReplaceableTextures\\shenqi\\黑暗狂热.blp",
                                    "黑暗狂热|n增加攻击速度和普攻伤害",
                                    true
                                )
                            else
                                hbuff.addStackAttrBuff(CONST_DAMAGE_SRC.skill, sourceUnit, "黑暗狂热",
                                    _attr({ attack_speed = "+" .. (tianfu6) }),
                                    5,
                                    1,
                                    "ReplaceableTextures\\shenqi\\黑暗狂热.blp",
                                    "黑暗狂热|n增加攻击速度",
                                    true
                                )
                            end
                        end
                    end
                end
            },
            {
                name = "黑暗斩击",
                description = "提升黑暗剪切伤害。",
                art = "ReplaceableTextures\\shenqi\\黑暗斩击.blp",
                cunDangPosition = 3,
                requiredExp = 8000,
                dependency = { "黑暗剪切" },
                perLevelDescription = function(level) return "黑暗剪切伤害提高" .. (level * 2) .. "%" end,
            },
            {
                name = "精准斩击",
                description = "提升黑暗剪切暴击率。",
                art = "ReplaceableTextures\\shenqi\\精准斩击.blp",
                cunDangPosition = 4,
                requiredExp = 16000,
                dependency = { "黑暗斩击" },
                perLevelDescription = function(level) return "黑暗剪切暴击率提高" .. (level * 2) .. "%" end,
            },
            {
                name = "黑暗模仿",
                description = "战刃剪切有概率触发两次。",
                art = "ReplaceableTextures\\shenqi\\黑暗模仿.blp",
                cunDangPosition = 5,
                requiredExp = 32000,
                dependency = { "精准斩击" },
                perLevelDescription = function(level) return "触发两次的概率为" .. (level * 2) .. "%" end,
            },
            {
                name = "黑暗之灵",
                description = "提升黑暗剪切触发概率。",
                art = "ReplaceableTextures\\shenqi\\黑暗之灵.blp",
                cunDangPosition = 6,
                requiredExp = 64000,
                dependency = { "黑暗模仿" },
                perLevelDescription = function(level) return "黑暗剪切触发概率提高" .. (level * 0.2) .. "%" end,
            },
            {
                name = "黑暗狂热",
                description = "触发黑暗剪切会临时提升你的攻击速度，持续5秒。",
                art = "ReplaceableTextures\\shenqi\\黑暗狂热.blp",
                cunDangPosition = 7,
                requiredExp = 128000,
                dependency = { "黑暗之灵" },
                perLevelDescription = function(level) return "触发黑暗剪切时攻击速度提升" .. (level) .. "%" end,
            },
            {
                name = "黑暗主宰",
                description = "黑暗狂热期间会同时提升你的攻击伤害（可以触发攻击特效的攻击均会被增强）。",
                art = "ReplaceableTextures\\shenqi\\黑暗主宰.blp",
                cunDangPosition = 8,
                requiredExp = 256000,
                dependency = { "黑暗狂热" },
                perLevelDescription = function(level) return "黑暗狂热期间额外提普通攻击伤害" .. (level) .. "%" end,
            },
        },
        { -- 第二列天赋
            {
                name = "吸取灵魂",
                description = "造成伤害有概率对正面400码内所有单位造成一次基于攻击力和主属性的物理伤害，CD30秒。",
                art = "ReplaceableTextures\\shenqi\\吸取灵魂.blp",
                cunDangPosition = 9,
                requiredExp = 4000,
                perLevelDescription = function(level) return "造成" .. (150 + level * 15) .. "%点攻击力和主属性的物理伤害" end,
                action = CONST_EVENT.damage,
                effect = function(evtData, artifact)
                    local sourceUnit = evtData.triggerUnit
                    local tianfu1 = hartifact.getTianfuLevel(artifact, "吸取灵魂")
                    local tianfu2 = hartifact.getTianfuLevel(artifact, "灵魂破碎")
                    local tianfu3 = hartifact.getTianfuLevel(artifact, "灵魂汲取")
                    local tianfu4 = hartifact.getTianfuLevel(artifact, "灵魂掌控")
                    local tianfu5 = hartifact.getTianfuLevel(artifact, "灵魂回响")
                    local tianfu6 = hartifact.getTianfuLevel(artifact, "易碎灵魂")
                    local tianfu7 = hartifact.getTianfuLevel(artifact, "灵魂觉醒")

                    local damage = (1.5 + tianfu1 * 0.15) * (hattr.getWithLimit(sourceUnit, nil, "attack", 1) +
                        hunit.getZhushuxing(sourceUnit))
                    damage = damage * (1 + 0.02 * tianfu2)
                    local cd = 30 - tianfu4 * 1

                    if math.random(1, 100) <= 10 and htime.setupAndCheckCoolDown(sourceUnit, "吸取灵魂cd", cd) then
                        heffect.xyz(
                            "war3mapImported\\[zhanshi]Cleave_Cast_Base_Purple.mdx",
                            hunit.x(sourceUnit),
                            hunit.y(sourceUnit),
                            hunit.z(sourceUnit),
                            0,
                            1,
                            3,
                            3,
                            3,
                            nil,
                            nil,
                            hunit.getFacing(sourceUnit)
                        )
                        hskillMoban.radiusAngleAOE(
                            sourceUnit, 400, hunit.getFacing(sourceUnit), 180,
                            function(targetUnit)
                                local finalDamage = damage
                                if math.random(1, 100) <= tianfu5 * 2 then
                                    finalDamage = finalDamage * 2
                                end
                                hskill.damage({
                                    sourceUnit = sourceUnit,
                                    targetUnit = targetUnit,
                                    damage = finalDamage,
                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                    damageType = DAMAGE_TYPE.WULI,
                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.METAL },
                                    shanghainame = "吸取灵魂",
                                })
                                if tianfu6 > 0 then
                                    hbuff.addStackAttrBuff(CONST_DAMAGE_SRC.skill, targetUnit, "易碎灵魂",
                                        _attr({
                                            defend_baifenbi = "-" .. (0.5 * tianfu6)
                                        }),
                                        10,
                                        1,
                                        "ReplaceableTextures\\shenqi\\易碎灵魂.blp",
                                        "易碎灵魂|n降低目标护甲",
                                        false
                                    )
                                end
                            end)
                        if tianfu3 > 0 then
                            hskill.heal(
                                {
                                    healee = sourceUnit,
                                    healer = sourceUnit,
                                    heal = hunit.getMaxLife(sourceUnit) * (0.02 * tianfu3),
                                    healType = HEAL_TYPE.SKILL,
                                }
                            )
                        end
                        if tianfu7 > 0 then
                            hbuff.addStackAttrBuff(CONST_DAMAGE_SRC.skill, sourceUnit, "灵魂觉醒",
                                _attr({
                                    wu_chuan = "+" .. (tianfu7)
                                }),
                                10,
                                1,
                                "ReplaceableTextures\\shenqi\\灵魂觉醒.blp",
                                "灵魂觉醒|n提升物理穿透",
                                true
                            )
                        end
                    end
                end
            },
            {
                name = "灵魂破碎",
                description = "提升吸取灵魂伤害。",
                art = "ReplaceableTextures\\shenqi\\灵魂破碎.blp",
                cunDangPosition = 10,
                requiredExp = 8000,
                dependency = { "吸取灵魂" },
                perLevelDescription = function(level) return "吸取灵魂伤害提高" .. (level * 2) .. "%" end,
            },
            {
                name = "灵魂汲取",
                description = "触发吸取灵魂会回复你最大生命值。",
                art = "ReplaceableTextures\\shenqi\\灵魂汲取.blp",
                cunDangPosition = 11,
                requiredExp = 16000,
                dependency = { "灵魂破碎" },
                perLevelDescription = function(level) return "触发吸取灵魂回复" .. (level * 2) .. "%最大生命值" end,
            },
            {
                name = "灵魂掌控",
                description = "减少吸取灵魂的冷却时间。",
                art = "ReplaceableTextures\\shenqi\\灵魂掌控.blp",
                cunDangPosition = 12,
                requiredExp = 32000,
                dependency = { "灵魂汲取" },
                perLevelDescription = function(level) return "吸取灵魂冷却时间减少" .. (level) .. "秒" end,
            },
            {
                name = "灵魂回响",
                description = "吸取灵魂造成伤害有概率翻倍。",
                art = "ReplaceableTextures\\shenqi\\灵魂回响.blp",
                cunDangPosition = 13,
                requiredExp = 64000,
                dependency = { "灵魂掌控" },
                perLevelDescription = function(level) return "吸取灵魂伤害有" .. (level * 2) .. "%概率翻倍" end,
            },
            {
                name = "易碎灵魂",
                description = "吸取灵魂造成伤害时会降低目标护甲及魔法护甲。",
                art = "ReplaceableTextures\\shenqi\\易碎灵魂.blp",
                cunDangPosition = 14,
                requiredExp = 128000,
                dependency = { "灵魂回响" },
                perLevelDescription = function(level) return "吸取灵魂降低目标" .. (0.5 * level) .. "%护甲，持续10秒" end,
            },
            {
                name = "灵魂觉醒",
                description = "触发吸取灵魂时，会提升你物理穿透。",
                art = "ReplaceableTextures\\shenqi\\灵魂觉醒.blp",
                cunDangPosition = 15,
                requiredExp = 256000,
                dependency = { "易碎灵魂" },
                perLevelDescription = function(level) return "触发吸取灵魂时，提升" .. (level) .. "%物理穿透，持续10秒" end,
            },
        },
    },
    canEquip = function(whichPlayer)
        return hquestcustom.isQuestFinished(whichPlayer, "传奇任务：恶魔战刃")
    end,
    canEquipDesc = "需要完成传奇任务：恶魔战刃"
})

local yanmozhi_shou                     = generateArtifactConfig({
    name = "炎魔之手",
    icon = "ReplaceableTextures\\zhuangbei\\INV_Hammer_Unique_Sulfuras.blp",
    art = "ReplaceableTextures\\shenqi\\yanmozhichui.tga",
    description =
    "狂暴的火焰之力围绕着这把锤子，似乎可以撕裂一切。炎魔之手蕴含着远古火焰之王的力量，能够召唤炽热的火球和释放毁灭性的范围攻击。",
    cundangStr = "artifactymzs",
    expCunDangStr = "artymzsexp",
    talents = {
        { -- 第一列天赋（炎魔之怒）
            {
                name = "炎魔之怒",
                description = "攻击时有7%概率触发，对周围300范围内的敌人造成基于攻击力的火系物理伤害，CD30秒。",
                art = "ReplaceableTextures\\shenqi\\炎魔之怒.blp",
                cunDangPosition = 2,
                requiredExp = 4000,
                perLevelDescription = function(level) return "炎魔之怒的伤害提升到" .. (250 + level * 25) .. "%攻击力" end,
                action = CONST_EVENT.attack,
                effect = function(evtData, artifact)
                    local ymznLevel = hartifact.getTianfuLevel(artifact, "炎魔之怒")
                    local nhrsLevel = hartifact.getTianfuLevel(artifact, "怒火燃烧")
                    local jrlyLevel = hartifact.getTianfuLevel(artifact, "灼热领域")
                    local bnyjLevel = hartifact.getTianfuLevel(artifact, "暴怒一击")
                    local czlLevel = hartifact.getTianfuLevel(artifact, "炽焰之力")
                    local lyfbLevel = hartifact.getTianfuLevel(artifact, "烈焰风暴")
                    local ymzxLevel = hartifact.getTianfuLevel(artifact, "炎魔之心")

                    local damageMulti = 2.5 + 0.25 * ymznLevel
                    local radius = 300 + 20 * jrlyLevel
                    local scale = radius / 300
                    local cd = 30 - czlLevel
                    local rate = 7 + nhrsLevel

                    if math.random(1, 100) <= rate and htime.setupAndCheckCoolDown(evtData.triggerUnit, "炎魔之怒CD", cd) then
                        local sourceUnit = evtData.triggerUnit
                        hskillMoban.radiusAOE(
                            hunit.x(sourceUnit),
                            hunit.y(sourceUnit),
                            sourceUnit,
                            radius,
                            function(targetUnit)
                                local damage = hattr.getWithLimit(sourceUnit, nil, "attack", 10) * damageMulti
                                if math.random(1, 100) <= bnyjLevel * 3 then
                                    damage = damage * 2
                                end
                                hskill.damage({
                                    sourceUnit = sourceUnit,
                                    targetUnit = targetUnit,
                                    damage = damage,
                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                    damageType = DAMAGE_TYPE.WULI,
                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                    shanghainame = "炎魔之怒",
                                })
                            end
                        )
                        heffect.xyz("war3mapImported\\[Spell]_055.MDX", hunit.x(sourceUnit), hunit.y(sourceUnit),
                            hunit.z(sourceUnit), 0, 1, scale, scale, scale)
                        if lyfbLevel > 0 and math.random(1, 100) <= lyfbLevel * 2 then
                            htime.setTimeout(0.5, function()
                                hskillMoban.radiusAOE(
                                    hunit.x(sourceUnit),
                                    hunit.y(sourceUnit),
                                    sourceUnit,
                                    radius,
                                    function(targetUnit)
                                        local damage = hattr.getWithLimit(sourceUnit, nil, "attack", 10) * damageMulti
                                        if math.random(1, 100) <= bnyjLevel * 3 then
                                            damage = damage * 2
                                        end
                                        hskill.damage({
                                            sourceUnit = sourceUnit,
                                            targetUnit = targetUnit,
                                            damage = damage,
                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                            damageType = DAMAGE_TYPE.WULI,
                                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                            shanghainame = "炎魔之怒",
                                        })
                                    end
                                )
                            end)
                        end

                        if ymzxLevel > 0 then
                            hbuff.addStackAttrBuff(CONST_DAMAGE_SRC.skill, sourceUnit, "炎魔之心",
                                _attr({ wu_bao_shang = "+" .. (ymzxLevel * 2) }),
                                ymzxLevel,
                                1,
                                "ReplaceableTextures\\shenqi\\炎魔之心.blp",
                                "炎魔之心|n增加暴击伤害",
                                true
                            )
                        end
                    end
                end
            },
            {
                name = "怒火燃烧",
                description = "提高炎魔之怒的触发概率。",
                art = "ReplaceableTextures\\shenqi\\怒火燃烧.blp",
                cunDangPosition = 3,
                requiredExp = 8000,
                dependency = { "炎魔之怒" },
                perLevelDescription = function(level) return "炎魔之怒的触发概率提高" .. level .. "%" end,
            },
            {
                name = "灼热领域",
                description = "增加炎魔之怒的作用范围。",
                art = "ReplaceableTextures\\shenqi\\灼热领域.blp",
                cunDangPosition = 4,
                requiredExp = 16000,
                dependency = { "怒火燃烧" },
                perLevelDescription = function(level) return "炎魔之怒的作用范围增加" .. (level * 20) .. "" end,
            },
            {
                name = "暴怒一击",
                description = "炎魔之怒有概率造成双倍伤害。",
                art = "ReplaceableTextures\\shenqi\\暴怒一击.blp",
                cunDangPosition = 5,
                requiredExp = 32000,
                dependency = { "灼热领域" },
                perLevelDescription = function(level) return "炎魔之怒的双倍伤害概率增加" .. (level * 3) .. "%" end,
            },
            {
                name = "炽焰之力",
                description = "降低炎魔之怒的冷却时间。",
                art = "ReplaceableTextures\\shenqi\\炽焰之力.blp",
                cunDangPosition = 6,
                requiredExp = 64000,
                dependency = { "暴怒一击" },
                perLevelDescription = function(level) return "炎魔之怒的冷却时间" .. (level) .. "秒" end,
            },
            {
                name = "烈焰风暴",
                description = "炎魔之怒触发时，有几率额外释放一次。",
                art = "ReplaceableTextures\\shenqi\\烈焰风暴.blp",
                cunDangPosition = 7,
                requiredExp = 128000,
                dependency = { "炽焰之力" },
                perLevelDescription = function(level) return "炎魔之怒有" .. (level * 2) .. "%概率额外释放一次" end,
            },
            {
                name = "炎魔之心",
                description = "炎魔之怒触发时，增加自身暴击伤害，持续短时间。",
                art = "ReplaceableTextures\\shenqi\\炎魔之心.blp",
                cunDangPosition = 8,
                requiredExp = 256000,
                dependency = { "烈焰风暴" },
                perLevelDescription = function(level) return "炎魔之怒触发时，增加" .. (level * 2) .. "%暴击伤害，持续" .. level .. "秒" end,
            },
        },
        { -- 第二列天赋（灼热火球）
            {
                name = "灼热火球",
                description = "攻击有20%概率对目标发射火球，造成基于攻击力的火法魔法伤害，并点燃对方，每秒造成50%攻击力的火焰魔法持续伤害，持续5秒，CD15秒。",
                art = "ReplaceableTextures\\shenqi\\灼热火球.blp",
                cunDangPosition = 9,
                requiredExp = 4000,
                perLevelDescription = function(level) return "灼热火球的初始伤害提升到" .. (100 + level * 5) .. "%攻击力" end,
                action = CONST_EVENT.attack,
                effect = function(evtData, artifact)
                    local sourceUnit = evtData.triggerUnit
                    local targetUnit = evtData.targetUnit

                    -- 获取天赋等级
                    local zhrhqLevel = hartifact.getTianfuLevel(artifact, "灼热火球")
                    local hyjsLevel = hartifact.getTianfuLevel(artifact, "火焰精通")
                    local zsqhLevel = hartifact.getTianfuLevel(artifact, "灼烧强化")
                    local ymzzLevel = hartifact.getTianfuLevel(artifact, "炎魔之触")
                    local lyzwLevel = hartifact.getTianfuLevel(artifact, "烈焰之舞")
                    local fscsLevel = hartifact.getTianfuLevel(artifact, "焚烧残余")
                    local zrctLevel = hartifact.getTianfuLevel(artifact, "炽热穿透")

                    -- 计算触发概率和冷却时间
                    local triggerChance = 20 + hyjsLevel * 2
                    local cooldown = 15 - ymzzLevel * 0.5

                    if math.random(1, 100) <= triggerChance and htime.setupAndCheckCoolDown(sourceUnit, "灼热火球CD", cooldown) then
                        -- 计算初始伤害
                        local damage = hattr.getWithLimit(sourceUnit, nil, "attack", 10) * (1 + zhrhqLevel * 0.05)

                        local function launchFireball(source, target, isRicochet)
                            hskillMoban.missile({
                                model = "Abilities\\Weapons\\RedDragonBreath\\RedDragonMissile.mdl",
                                scale = 1.0,
                                speed = 1000,
                                height = 50,
                                sourceUnit = source,
                                targetUnit = target,
                                onEnd = function(_, _, endX, endY)
                                    -- 造成初始伤害
                                    hskill.damage({
                                        sourceUnit = source,
                                        targetUnit = target,
                                        damage = isRicochet and damage * 0.5 or damage,
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.MOFA,
                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                        shanghainame = isRicochet and "灼热火球弹射" or "灼热火球",
                                    })

                                    if not isRicochet then
                                        -- 添加灼烧效果
                                        local burnDuration = 5 + zsqhLevel * 0.5
                                        local burnDamagePerSecond = hattr.getWithLimit(source, nil, "attack", 10) * 0.5

                                        hbuff.update(
                                            burnDuration, target, "灼热火球" .. tostring(source), false,
                                            function()
                                            end,
                                            function()
                                                -- 焚烧残余效果
                                                if fscsLevel > 0 then
                                                    hskill.damage({
                                                        sourceUnit = source,
                                                        targetUnit = target,
                                                        damage = hattr.getWithLimit(source, nil, "attack", 10) *
                                                            (fscsLevel * 0.2),
                                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                                        damageType = DAMAGE_TYPE.MOFA,
                                                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                                        shanghainame = "焚烧残余",
                                                    })
                                                end
                                            end,
                                            "ReplaceableTextures\\shenqi\\灼热火球.blp",
                                            "灼热火球：每秒造成火焰魔法伤害", 1, 1,
                                            function(curTimer, buffHandle)
                                                buffHandle.remainingTime = buffHandle.remainingTime - buffHandle
                                                    .interval
                                                hskill.damage({
                                                    sourceUnit = source,
                                                    targetUnit = target,
                                                    damage = burnDamagePerSecond,
                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                    damageType = DAMAGE_TYPE.MOFA,
                                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                                                    shanghainame = "灼热火球",
                                                    tmpAttr = _attr({ fa_baoshang = "+" .. (1 + fscsLevel * 5) }),
                                                })
                                                heffect.attach(
                                                    "Abilities\\Spells\\Other\\BreathOfFire\\BreathOfFireDamage.mdl",
                                                    target, "chest", 0.1)
                                            end, nil, nil, HBUFF_UPDATE_MODE.OVERWRITE, true)

                                        -- 炽热穿透效果
                                        if zrctLevel > 0 then
                                            hbuff.addStackAttrBuff(CONST_DAMAGE_SRC.skill, target, "炽热穿透",
                                                _attr({ defend_baifenbi = "-" .. (zrctLevel) }),
                                                zrctLevel,
                                                1,
                                                "ReplaceableTextures\\shenqi\\炽热穿透.blp",
                                                "炽热穿透|n降低目标物理防御",
                                                false
                                            )
                                        end

                                        -- 烈焰之舞效果
                                        if lyzwLevel > 0 and math.random(1, 100) <= lyzwLevel * 3 then
                                            local nearbyEnemies = hgroup.createEnermyGroupByXY(source, endX, endY, 500)
                                            hgroup.removeUnit(nearbyEnemies, target)

                                            if not hgroup.isEmpty(nearbyEnemies) then
                                                local nearbyTarget = nearbyEnemies[math.random(1, #nearbyEnemies)]
                                                launchFireball(source, nearbyTarget, true)
                                            end
                                        end
                                    end
                                end
                            })
                        end

                        launchFireball(sourceUnit, targetUnit, false)
                    end
                end
            },
            {
                name = "火焰精通",
                description = "提高灼热火球的触发概率。",
                art = "ReplaceableTextures\\shenqi\\火焰精通.blp",
                cunDangPosition = 10,
                requiredExp = 8000,
                dependency = { "灼热火球" },
                perLevelDescription = function(level) return "灼热火球的触发概率提高" .. (level * 2) .. "%" end,
            },
            {
                name = "灼烧强化",
                description = "增加灼热火球的持续伤害时间。",
                art = "ReplaceableTextures\\shenqi\\灼烧强化.blp",
                cunDangPosition = 11,
                requiredExp = 16000,
                dependency = { "火焰精通" },
                perLevelDescription = function(level) return "灼热火球的持续伤害时间增加" .. (level * 0.5) .. "秒" end,
            },
            {
                name = "炎魔之触",
                description = "灼热火球的冷却时间减低。",
                art = "ReplaceableTextures\\shenqi\\炎魔之触.blp",
                cunDangPosition = 12,
                requiredExp = 32000,
                dependency = { "灼烧强化" },
                perLevelDescription = function(level) return "灼热火球的冷却时间减低" .. (level * 0.5) .. "秒" end,
            },
            {
                name = "烈焰之舞",
                description = "灼热火球有几率弹射到附近目标。",
                art = "ReplaceableTextures\\shenqi\\烈焰之舞.blp",
                cunDangPosition = 13,
                requiredExp = 64000,
                dependency = { "炎魔之触" },
                perLevelDescription = function(level) return "灼热火球有" .. (level * 3) .. "%概率弹射到附近目标" end,
            },
            {
                name = "焚烧残余",
                description = "灼热火球结束时造成额外伤害。",
                art = "ReplaceableTextures\\shenqi\\焚烧残余.blp",
                cunDangPosition = 14,
                requiredExp = 128000,
                dependency = { "烈焰之舞" },
                perLevelDescription = function(level) return "灼热火球结束时造成" .. (level * 20) .. "%攻击力的额外伤害" end,
            },
            {
                name = "炽热穿透",
                description = "灼热火球命中时，降低目标物理防御。",
                art = "ReplaceableTextures\\shenqi\\炽热穿透.blp",
                cunDangPosition = 15,
                requiredExp = 256000,
                dependency = { "焚烧残余" },
                perLevelDescription = function(level) return "灼热火球命中时，降低目标" .. (level * 1) .. "%物理防御，持续" .. level .. "秒" end,
            },
        },
    },
    canEquip = function(whichPlayer)
        return hquestcustom.isQuestFinished(whichPlayer, "传奇任务：炎魔之手")
    end,
    canEquipDesc = "需要完成传说任务：炎魔之手"
})

local qunxingzhi                        = generateArtifactConfig({
    name = "群星之怒",
    icon = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_BOW_39.blp",
    art = "ReplaceableTextures\\shenqi\\Bow_1H_HunterLegend.tga",
    description = "蕴含星辰之力的神器，能够召唤群星之怒降临敌人。",
    cundangStr = "artifactqxzn",
    expCunDangStr = "artqxzaexp",
    talents = {
        { -- 第一列天赋
            {
                name = "群星坠落",
                description = "攻击有7%概率触发群星坠落，每1秒对目标范围300码内所有敌人触发星落，造成100%主属性的魔法伤害，持续3秒，CD45秒。",
                art = "ReplaceableTextures\\shenqi\\群星坠落.blp",
                cunDangPosition = 2,
                requiredExp = 4000,
                perLevelDescription = function(level) return "群星坠落的基础伤害为" .. (100 + level * 10) .. "%主属性" end,
                action = CONST_EVENT.attack,
                effect = function(evtData, artifact)
                    local tianfu1 = hartifact.getTianfuLevel(artifact, "群星坠落")
                    local tianfu2 = hartifact.getTianfuLevel(artifact, "星辰洪流")
                    local tianfu3 = hartifact.getTianfuLevel(artifact, "星光强化")
                    local tianfu4 = hartifact.getTianfuLevel(artifact, "星轨加速")
                    local tianfu5 = hartifact.getTianfuLevel(artifact, "星域扩张")
                    local tianfu6 = hartifact.getTianfuLevel(artifact, "双子星陨")
                    local tianfu7 = hartifact.getTianfuLevel(artifact, "星能激发")

                    local sourceUnit = evtData.triggerUnit
                    local targetUnit = evtData.targetUnit
                    if tianfu7 > 0 then
                        hbuff.addStackAttrBuff(
                            CONST_DAMAGE_SRC.skill, sourceUnit, "星能激发",
                            _attr({ fa_zengshang = "+" .. tianfu7 }), 10, 1,
                            "ReplaceableTextures\\shenqi\\星能激发.blp",
                            "星能激发|n增加" .. (tianfu7) .. "%法术增伤", true)
                    end
                    local damageMulti = 1 + 0.1 * tianfu1
                    damageMulti = damageMulti * (1 + 0.1 * tianfu3)
                    local duration = 3 + 0.5 * tianfu2
                    local cd = 45 - 3 * tianfu4
                    local range = 300 + 10 * tianfu5
                    local doubleDamageChance = 2 * tianfu6

                    local damage = hunit.getZhushuxing(sourceUnit) * damageMulti
                    if math.random(1, 100) <= 7 and htime.setupAndCheckCoolDown(sourceUnit, "群星之怒群星坠落", cd) then
                        local finalDamage = damage
                        if math.random(1, 100) <= doubleDamageChance then
                            finalDamage = finalDamage * 2
                        end
                        local danciqunxingzhinu = function(danciTarget)
                            heffect.attach("StarFall.mdx", danciTarget, "origin",
                                0)
                            htime.setTimeout(
                                1.45,
                                function(t)
                                    hskill.damage(
                                        {
                                            sourceUnit = sourceUnit,
                                            targetUnit = danciTarget,
                                            damage = damage,
                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                            damageType = DAMAGE_TYPE.MOFA,
                                            triggerSkill = hslk.n2i("装备技能"),
                                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                            shanghainame = "群星之怒"
                                        }
                                    )
                                end
                            )
                        end
                        local x, y = hunit.x(targetUnit), hunit.y(targetUnit)
                        htime.setInterval(
                            1,
                            function(curTimer)
                                if curTimer.passedSec() > duration then
                                    curTimer.destroy()
                                    return
                                end
                                hskillMoban.radiusAOE(x, y, sourceUnit, range, function(filterUnit)
                                    htime.setTimeout(math.random(1, 10) * 0.02,
                                        function()
                                            danciqunxingzhinu(filterUnit)
                                        end)
                                end)
                            end
                        )
                    end
                end
            },
            {
                name = "星辰洪流",
                description = "增加群星坠落的持续时间。",
                art = "ReplaceableTextures\\shenqi\\星辰洪流.blp",
                cunDangPosition = 3,
                requiredExp = 8000,
                dependency = { "群星坠落" },
                perLevelDescription = function(level) return "群星坠落的持续时间增加" .. (level * 0.5) .. "秒" end,
            },
            {
                name = "星光强化",
                description = "增加群星坠落的伤害。",
                art = "ReplaceableTextures\\shenqi\\星光强化.blp",
                cunDangPosition = 4,
                requiredExp = 16000,
                dependency = { "星辰洪流" },
                perLevelDescription = function(level) return "群星坠落的伤害提高" .. (level * 2) .. "%" end,
            },
            {
                name = "星轨加速",
                description = "降低群星坠落的冷却时间。",
                art = "ReplaceableTextures\\shenqi\\星轨加速.blp",
                cunDangPosition = 5,
                requiredExp = 32000,
                dependency = { "星光强化" },
                perLevelDescription = function(level) return "群星坠落的冷却时间降低" .. (level * 3) .. "秒" end,
            },
            {
                name = "星域扩张",
                description = "增加群星坠落的影响范围。",
                art = "ReplaceableTextures\\shenqi\\星域扩张.blp",
                cunDangPosition = 6,
                requiredExp = 64000,
                dependency = { "星轨加速" },
                perLevelDescription = function(level) return "群星坠落的影响范围增加" .. (level * 10) .. "码" end,
            },
            {
                name = "双子星陨",
                description = "群星坠落有概率造成双倍伤害。",
                art = "ReplaceableTextures\\shenqi\\双子星陨.blp",
                cunDangPosition = 7,
                requiredExp = 128000,
                dependency = { "星域扩张" },
                perLevelDescription = function(level) return "群星坠落有" .. (level * 2) .. "%概率造成双倍伤害" end,
            },
            {
                name = "星能激发",
                description = "触发群星坠落后，暂时提高法术伤害。",
                art = "ReplaceableTextures\\shenqi\\星能激发.blp",
                cunDangPosition = 8,
                requiredExp = 256000,
                dependency = { "双子星陨" },
                perLevelDescription = function(level) return "触发群星坠落后，提高" .. (level * 1) .. "%法术伤害，持续10秒" end,
            },
        },
        { -- 第二列天赋（预留，可以后续添加）
            {
                name = "月神箭雨",
                description = "攻击有7%概率触发月神箭雨，每0.3秒对目标范围200码内随机位置发射一只月神之箭，造成基于攻击力的范围物理伤害，范围大小为200码，基础10支箭矢，CD45秒。",
                art = "ReplaceableTextures\\shenqi\\月神箭雨.blp",
                cunDangPosition = 9,
                requiredExp = 4000,
                perLevelDescription = function(level) return "月神箭雨的基础伤害为" .. (50 + level * 5) .. "%攻击力" end,
                action = CONST_EVENT.attack,
                effect = function(evtData, artifact)
                    local tianfu1 = hartifact.getTianfuLevel(artifact, "月神箭雨")
                    local tianfu2 = hartifact.getTianfuLevel(artifact, "箭矢增幅")
                    local tianfu3 = hartifact.getTianfuLevel(artifact, "月光锐化")
                    local tianfu4 = hartifact.getTianfuLevel(artifact, "月相加速")
                    local tianfu5 = hartifact.getTianfuLevel(artifact, "月影扩散")
                    local tianfu6 = hartifact.getTianfuLevel(artifact, "新月之力")
                    local tianfu7 = hartifact.getTianfuLevel(artifact, "月光祝福")

                    local sourceUnit = evtData.triggerUnit
                    local targetUnit = evtData.targetUnit
                    if tianfu7 > 0 then
                        hbuff.addStackAttrBuff(
                            CONST_DAMAGE_SRC.skill, sourceUnit, "月光祝福",
                            _attr({ wu_zengshang = "+" .. tianfu7 }), 10, 1,
                            "ReplaceableTextures\\shenqi\\月光祝福.blp",
                            "月光祝福|n增加" .. (tianfu7) .. "%物理增伤", true)
                    end
                    local damageMulti = 1 + 0.1 * tianfu1
                    damageMulti = damageMulti * (1 + 0.02 * tianfu3)
                    local waves = 10 + tianfu2
                    local cd = 45 - 3 * tianfu4
                    local range = 200 + 10 * tianfu5
                    local doubleDamageChance = 2 * tianfu6

                    local damage = hattr.getWithLimit(sourceUnit, nil, "attack", 0) * damageMulti
                    if math.random(1, 100) <= 7 and htime.setupAndCheckCoolDown(sourceUnit, "群星之怒月神箭雨", cd) then
                        local finalDamage = damage
                        if math.random(1, 100) <= doubleDamageChance then
                            finalDamage = finalDamage * 2
                        end
                        local danciqunxingzhinu = function(danciTarget, finalX, finalY)
                            heffect.xyz("war3mapImported\\[Spell]_031.MDX", finalX, finalY, hjapi.Z(finalX, finalY),
                                0, 1)
                            htime.setTimeout(
                                0.15,
                                function(t)
                                    hskill.damage(
                                        {
                                            sourceUnit = sourceUnit,
                                            targetUnit = danciTarget,
                                            damage = damage,
                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                            damageType = DAMAGE_TYPE.WULI,
                                            triggerSkill = hslk.n2i("装备技能"),
                                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                            shanghainame = "月神箭雨"
                                        }
                                    )
                                end
                            )
                        end
                        local x, y = hunit.x(targetUnit), hunit.y(targetUnit)
                        local currentWave = 1
                        htime.setInterval(
                            0.3,
                            function(curTimer)
                                if currentWave > waves then
                                    curTimer.destroy()
                                    return
                                end
                                currentWave = currentWave + 1
                                local rangleAngle = math.random(0, 360)
                                local rangleDis = math.random(0, 200)
                                local finalX = x + rangleDis * math.cos(rangleAngle)
                                local finalY = y + rangleDis * math.sin(rangleAngle)
                                hskillMoban.radiusAOE(finalX, finalY, sourceUnit, range, function(filterUnit)
                                    htime.setTimeout(math.random(1, 10) * 0.02,
                                        function()
                                            danciqunxingzhinu(filterUnit, finalX, finalY)
                                        end)
                                end)
                            end
                        )
                    end
                end
            },
            {
                name = "箭矢增幅",
                description = "增加月神箭雨的箭矢数量。",
                art = "ReplaceableTextures\\shenqi\\箭矢增幅.blp",
                cunDangPosition = 10,
                requiredExp = 8000,
                dependency = { "月神箭雨" },
                perLevelDescription = function(level) return "月神箭雨的箭矢数量增加" .. level .. "支" end,
            },
            {
                name = "月光锐化",
                description = "增加月神箭雨的伤害。",
                art = "ReplaceableTextures\\shenqi\\月光锐化.blp",
                cunDangPosition = 11,
                requiredExp = 16000,
                dependency = { "箭矢增幅" },
                perLevelDescription = function(level) return "月神箭雨的伤害提高" .. (level * 2) .. "%" end,
            },
            {
                name = "月相加速",
                description = "降低月神箭雨的冷却时间。",
                art = "ReplaceableTextures\\shenqi\\月相加速.blp",
                cunDangPosition = 12,
                requiredExp = 32000,
                dependency = { "月光锐化" },
                perLevelDescription = function(level) return "月神箭雨的冷却时间降低" .. (level * 3) .. "秒" end,
            },
            {
                name = "月影扩散",
                description = "增加月神箭雨的影响范围。",
                art = "ReplaceableTextures\\shenqi\\月影扩散.blp",
                cunDangPosition = 13,
                requiredExp = 64000,
                dependency = { "月相加速" },
                perLevelDescription = function(level) return "每只月神箭雨的伤害范围增加" .. (level * 10) .. "码" end,
            },
            {
                name = "新月之力",
                description = "月神箭雨有概率造成双倍伤害。",
                art = "ReplaceableTextures\\shenqi\\新月之力.blp",
                cunDangPosition = 14,
                requiredExp = 128000,
                dependency = { "月影扩散" },
                perLevelDescription = function(level) return "月神箭雨有" .. (level * 2) .. "%概率造成双倍伤害" end,
            },
            {
                name = "月光祝福",
                description = "触发月神箭雨后，暂时提高物理伤害。",
                art = "ReplaceableTextures\\shenqi\\月光祝福.blp",
                cunDangPosition = 15,
                requiredExp = 256000,
                dependency = { "新月之力" },
                perLevelDescription = function(level) return "触发月神箭雨后，提高" .. (level) .. "%物理伤害，持续10秒" end,
            },

        },
    },
    canEquip = function(whichPlayer)
        return hquestcustom.isQuestFinished(whichPlayer, "传奇任务：群星之怒")
    end,
    canEquipDesc = "需要完成传说任务：群星之怒"
})

-- 神器配置示例
ARTIFACT_CONFIG                         = {
    {
        name = "灰烬之力", -- 神器名字
        icon = "ReplaceableTextures\\zhuangbei\\shuangshoujian\\huijingzhijian.blp", -- 神器图标
        art = "UI\\huijinzhili.blp", -- 神器天赋背景图片
        description =
        "灰烬之力是一把传说中的神器，曾是正义的象征，却因守护者的堕落而被玷污。这把能将敌人化为灰烬的圣剑，据说是众神赐予凡人维护世界平衡的礼物。如今，它的纯净烈焰被扭曲，等待着勇敢的英雄踏上危险的征程，通过收集古老知识、面对堕落英雄并驾驭纯净圣光来净化它。重生后的灰烬之力将成为抵御黑暗的希望之光，拥有劈开坚固防御、净化邪恶、鼓舞盟友的惊人力量。然而，如此强大的武器也伴随着巨大的责任，只有内心纯洁、意志坚定的英雄才能真正驾驭它，否则可能再度沦为毁灭世界的工具。",
        cundangStr = "artifacthjzl", -- 存档字符串 一共有63位 第一位表示是否激活 第二位表示是否装备 其它表示天赋等级
        talentTree = {               -- 天赋树配置，天赋共有两级，第一级为基础天赋
            {                        -- 第一行天赋
                {                    -- 第一列天赋
                    name = "灰烬之力",
                    description = "攻击时有20%概率触发灰烬之力，对目标造成基于攻击力和主属性的的光明魔法伤害，基础冷却时间为45秒。",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\huijingzhili.blp",
                    activeLevel = 0,
                    dependency = {},     -- 前置天赋需求
                    cunDangPosition = 2, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 4000,  -- 激活所需神器能量
                    isElite = false,     -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "灰烬之力的基础伤害为210%（攻击力+主属性）",
                            action = CONST_EVENT.attack,
                            effect = function(evtData, artifact)
                                local hjzlLevel = hartifact.getTianfuLevel(artifact, "灰烬之力")
                                local gmzlLevel = hartifact.getTianfuLevel(artifact, "光明之力")
                                local hjkrLevel = hartifact.getTianfuLevel(artifact, "灰烬狂热")
                                local hjspLevel = hartifact.getTianfuLevel(artifact, "灰烬审判")
                                local hjszjLevel = hartifact.getTianfuLevel(artifact, "灰烬十字军")
                                local damageMulti = 2 + 0.1 * hjzlLevel
                                local damageMulti = damageMulti * (1 + 0.05 * hjkrLevel + 0.02 * hjspLevel)
                                local radius = 200 + 10 * hjspLevel
                                local cd = 45 - 2 * gmzlLevel
                                local rate = 20
                                if math.random(1, 100) <= rate and
                                    htime.setupAndCheckCoolDown(evtData.triggerUnit, "sqzhhjzl", cd) then
                                    local sourceUnit = evtData.triggerUnit
                                    local targetUnit = evtData.targetUnit
                                    local primaryAttribute = hunit.getZhushuxing(sourceUnit)
                                    local attack = hattr.getWithLimit(sourceUnit, nil, "attack", 0)
                                    local basicDamage = attack + primaryAttribute
                                    if hjspLevel > 0 then
                                        hskillMoban.radiusAOE(
                                            hunit.x(targetUnit),
                                            hunit.y(targetUnit),
                                            sourceUnit,
                                            radius,
                                            function(filterUnit)
                                                heffect.attach("Garen_R.mdx", filterUnit, "origin", 0)
                                                hskill.damage({
                                                    sourceUnit = sourceUnit,
                                                    targetUnit = filterUnit,
                                                    damage = damageMulti * basicDamage,
                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                    damageType = DAMAGE_TYPE.MOFA,
                                                    triggerSkill = hslk.n2i("AI技能模版"),
                                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT },
                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                                    shanghainame = "灰烬之力"
                                                })
                                            end,
                                            false,
                                            true

                                        )
                                    else
                                        heffect.attach("Garen_R.mdx", targetUnit, "origin", 0)
                                        hskill.damage({
                                            sourceUnit = sourceUnit,
                                            targetUnit = targetUnit,
                                            damage = damageMulti * basicDamage,
                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                            damageType = DAMAGE_TYPE.MOFA,
                                            triggerSkill = hslk.n2i("AI技能模版"),
                                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT },
                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                            shanghainame = "灰烬之力"
                                        })
                                    end
                                    if hjszjLevel > 0 then
                                        hbuff.addStackAttrBuff(
                                            CONST_DAMAGE_SRC.skill, sourceUnit, "灰烬十字军",
                                            _attr({ zhushuxing_baifenbi = "+" .. (3 * hjszjLevel) }), 10, 1,
                                            "ReplaceableTextures\\shenqi\\huijingshizijun.blp",
                                            "灰烬十字军|n增加" .. (3 * hjszjLevel) .. "%主属性", true)
                                    end
                                end
                            end
                        },
                        {
                            description = "灰烬之力的基础伤害为220%（攻击力+主属性）",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的基础伤害为230%（攻击力+主属性）",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的基础伤害为240%（攻击力+主属性）",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的基础伤害为250%（攻击力+主属性）",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的基础伤害为260%（攻击力+主属性）",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的基础伤害为270%（攻击力+主属性）",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的基础伤害为280%（攻击力+主属性）",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的基础伤害为290%（攻击力+主属性）",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的基础伤害为300%（攻击力+主属性）",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "光明狂热",
                    description = "提高单位造成的光明魔法伤害",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\guangmingkuangre.blp",
                    activeLevel = 0,
                    dependency = { "灰烬之力" }, -- 前置天赋需求
                    cunDangPosition = 3, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 8000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "提高1%光明魔法伤害",
                            action = CONST_EVENT.damagingCustomSource,
                            effect = function(evtData, artifact)
                                local hjzlLevel = hartifact.getTianfuLevel(artifact, "光明狂热")
                                if evtData.damageType == DAMAGE_TYPE.MOFA and type(evtData.damageElementType) == 'table' and table.includes(evtData.damageElementType, CONST_DAMAGE_ELEMENT_TYPE.LIGHT) then
                                    evtData.damage = evtData.damage * (1 + 0.01 * hjzlLevel)
                                end
                            end
                        },
                        {
                            description = "提高1%光明魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "无私奉献",
                    description = "奉献造成的伤害提高",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\wusifengxian.blp",
                    activeLevel = 0,
                    dependency = { "光明狂热" }, -- 前置天赋需求
                    cunDangPosition = 4, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 16000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "提高3%奉献造成的伤害",
                            action = CONST_EVENT.damagingCustomSource,
                            effect = function(evtData, artifact)
                                local wsfxLevel = hartifact.getTianfuLevel(artifact, "无私奉献")
                                if evtData.shanghainame == "奉献" then
                                    evtData.damage = evtData.damage * (1 + 0.03 * wsfxLevel)
                                end
                            end
                        },
                        {
                            description = "提高3%奉献造成的伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高3%奉献造成的伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高3%奉献造成的伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高3%奉献造成的伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高3%奉献造成的伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高3%奉献造成的伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高3%奉献造成的伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高3%奉献造成的伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高3%奉献造成的伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "光明之力",
                    description = "降低灰烬之力的冷却时间",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\guangmingzhili.blp",
                    activeLevel = 0,
                    dependency = { "无私奉献" }, -- 前置天赋需求
                    cunDangPosition = 5, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 32000, -- 激活所需神器能量
                    isElite = true, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "降低灰烬之力的冷却时间2秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "降低灰烬之力的冷却时间2秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "降低灰烬之力的冷却时间2秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "降低灰烬之力的冷却时间2秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "降低灰烬之力的冷却时间2秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "降低灰烬之力的冷却时间2秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "降低灰烬之力的冷却时间2秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "降低灰烬之力的冷却时间2秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "降低灰烬之力的冷却时间2秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "降低灰烬之力的冷却时间2秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "灰烬狂热",
                    description = "灰烬之力的伤害提高",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\huijingkuangre.blp",
                    activeLevel = 0,
                    dependency = { "光明之力" }, -- 前置天赋需求
                    cunDangPosition = 6, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 48000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },

                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "灰烬之力的整体伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的整体伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的整体伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的整体伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的整体伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的整体伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的整体伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的整体伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的整体伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "灰烬之力的整体伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }

                },
                { -- 第一列天赋
                    name = "灰烬审判",
                    description = "灰烬之力能够造成范围伤害，同时伤害提高",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\huijingshenpan.blp",
                    activeLevel = 0,
                    dependency = { "灰烬狂热" }, -- 前置天赋需求
                    cunDangPosition = 7, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 64000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },

                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "伤害范围为210，伤害提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "伤害范围为220，伤害额外提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "伤害范围为230，伤害额外提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "伤害范围为240，伤害额外提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "伤害范围为250，伤害额外提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "伤害范围为260，伤害额外提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "伤害范围为270，伤害额外提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "伤害范围为280，伤害额外提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "伤害范围为290，伤害额外提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "伤害范围为300，伤害额外提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "灰烬十字军",
                    description = "触发灰烬之力会使你在10秒内主属性百分比提高",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\huijingshizijun.blp",
                    activeLevel = 0,
                    dependency = { "灰烬审判" }, -- 前置天赋需求
                    cunDangPosition = 8, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 80000, -- 激活所需神器能量
                    isElite = true, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "触发主属性提高3%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "触发主属性提高6%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "触发主属性提高9%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "触发主属性提高12%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "触发主属性提高15%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "触发主属性提高18%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "触发主属性提高21%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "触发主属性提高24%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "触发主属性提高27%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "触发主属性提高30%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
            },
            {     -- 第一行天赋
                { -- 第一列天赋
                    name = "惩戒之力",
                    description = "攻击时有20%概率触发惩戒之力，对目标造成基于攻击力的光明物理伤害，基础冷却时间为6秒。",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\chenjiezhili.blp",
                    activeLevel = 0,
                    dependency = {},     -- 前置天赋需求
                    cunDangPosition = 9, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 4000,  -- 激活所需神器能量
                    isElite = false,     -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "惩戒之力的基础伤害为105%攻击力",
                            action = CONST_EVENT.attack,
                            effect = function(evtData, artifact)
                                local cjzlLevel   = hartifact.getTianfuLevel(artifact, "惩戒之力")
                                local cjjtLevel   = hartifact.getTianfuLevel(artifact, "惩戒精通")
                                local cjszLevel   = hartifact.getTianfuLevel(artifact, "惩戒使者")
                                local cjcjLevel   = hartifact.getTianfuLevel(artifact, "惩戒裁决")
                                local cjszjLevel  = hartifact.getTianfuLevel(artifact, "惩戒十字军")
                                local damageMulti = 1 + 0.05 * cjzlLevel
                                local damageMulti = damageMulti * (1 + 0.05 * cjszLevel)
                                local cd          = 6 - 0.3 * cjjtLevel
                                local rate        = 20 + cjjtLevel
                                if math.random(1, 100) <= rate and
                                    htime.setupAndCheckCoolDown(evtData.triggerUnit, "sqhjzlchzl", cd) then
                                    local sourceUnit = evtData.triggerUnit
                                    local targetUnit = evtData.targetUnit
                                    local attack = hattr.getWithLimit(sourceUnit, nil, "attack", 0)
                                    local function dancichegnjizhili()
                                        heffect.attach("AZ_D056.mdx", targetUnit, "origin", 0)
                                        hskill.damage({
                                            sourceUnit = sourceUnit,
                                            targetUnit = targetUnit,
                                            damage = damageMulti * attack,
                                            damageSrc = CONST_DAMAGE_SRC.skill,
                                            damageType = DAMAGE_TYPE.WULI,
                                            triggerSkill = hslk.n2i("AI技能模版"),
                                            damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.LIGHT },
                                            damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                            shanghainame = "惩戒之力"
                                        })
                                        if cjszjLevel > 0 then
                                            hbuff.addStackAttrBuff(
                                                CONST_DAMAGE_SRC.skill, sourceUnit, "惩戒十字军",
                                                _attr({ gongji_baifenbi = "+1" }), 10, cjszjLevel,
                                                "ReplaceableTextures\\zhuangbei\\shuangshoujian\\huijingzhijian.blp",
                                                "惩戒十字军|n每层增加1%攻击力", true)
                                        end
                                    end
                                    dancichegnjizhili()
                                    local lianjirate = 2 * cjcjLevel
                                    if math.random(1, 100) <= lianjirate then
                                        htime.setTimeout(0.25, function()
                                            dancichegnjizhili()
                                        end)
                                    end
                                end
                            end
                        },
                        {
                            description = "惩戒之力的基础伤害为110%攻击力",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的基础伤害为115%攻击力",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的基础伤害为120%攻击力",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的基础伤害为125%攻击力",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的基础伤害为130%攻击力",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的基础伤害为135%攻击力",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的基础伤害为140%攻击力",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的基础伤害为145%攻击力",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的基础伤害为150%攻击力",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "惩戒狂热",
                    description = "提高单位造成的光明物理伤害",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\chenjiekuangre.blp",
                    activeLevel = 0,
                    dependency = { "惩戒之力" }, -- 前置天赋需求
                    cunDangPosition = 10, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 8000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "提高1%光明物理伤害",
                            action = CONST_EVENT.damagingCustomSource,
                            effect = function(evtData, artifact)
                                local hjzlLevel = hartifact.getTianfuLevel(artifact, "光明狂热")
                                if evtData.damageType == DAMAGE_TYPE.MOFA and type(evtData.damageElementType) == 'table' and table.includes(evtData.damageElementType, CONST_DAMAGE_ELEMENT_TYPE.LIGHT) then
                                    evtData.damage = evtData.damage * (1 + 0.01 * hjzlLevel)
                                end
                            end
                        },
                        {
                            description = "提高1%光明物理伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明物理伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明物理伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明物理伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明物理伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明物理伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明物理伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明物理伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高1%光明物理伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "牺牲",
                    description = "圣印的伤害提高",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\xisheng.blp",
                    activeLevel = 0,
                    dependency = { "惩戒狂热" }, -- 前置天赋需求
                    cunDangPosition = 11, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 16000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "圣印的伤害提高2%",
                            action = CONST_EVENT.damagingCustomSource,
                            effect = function(evtData, artifact)
                                local wsfxLevel = hartifact.getTianfuLevel(artifact, "牺牲")
                                if evtData.triggerSkill == hslk.n2i("圣印") then
                                    evtData.damage = evtData.damage * (1 + 0.02 * wsfxLevel)
                                end
                            end
                        },
                        {
                            description = "圣印的伤害提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "圣印的伤害提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "圣印的伤害提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "圣印的伤害提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "圣印的伤害提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "圣印的伤害提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "圣印的伤害提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "圣印的伤害提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "圣印的伤害提高2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "惩戒精通",
                    description = "惩戒之力的触发概率提高，冷却时间降低",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\chenjiejingtong.blp",
                    activeLevel = 0,
                    dependency = { "牺牲" }, -- 前置天赋需求
                    cunDangPosition = 12, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 32000, -- 激活所需神器能量
                    isElite = true, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "触发概率提高1%，冷却时间降低0.3秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "触发概率提高1%，冷却时间降低0.3秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "触发概率提高1%，冷却时间降低0.3秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "触发概率提高1%，冷却时间降低0.3秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "触发概率提高1%，冷却时间降低0.3秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "触发概率提高1%，冷却时间降低0.3秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "触发概率提高1%，冷却时间降低0.3秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "触发概率提高1%，冷却时间降低0.3秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "触发概率提高1%，冷却时间降低0.3秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "触发概率提高1%，冷却时间降低0.3秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "惩戒使者",
                    description = "惩戒之力的伤害提高",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\chenjieshizhe.blp",
                    activeLevel = 0,
                    dependency = { "惩戒精通" }, -- 前置天赋需求
                    cunDangPosition = 13, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 48000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },

                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "惩戒之力的伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "惩戒之力的伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }

                },
                { -- 第一列天赋
                    name = "惩戒裁决",
                    description = "惩戒之力有概率触发连击，造成两次伤害",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\chenjiecaijue.blp",
                    activeLevel = 0,
                    dependency = { "惩戒使者" }, -- 前置天赋需求
                    cunDangPosition = 14, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 64000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },

                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "连击概率为2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "连击概率提升2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "连击概率提升2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "连击概率提升2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "连击概率提升2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "连击概率提升2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "连击概率提升2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "连击概率提升2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "连击概率提升2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "连击概率提升2%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "惩戒十字军",
                    description = "触发惩戒之力会使你在10秒内攻击力百分比提高",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\zhuangbei\\shuangshoujian\\huijingzhijian.blp",
                    activeLevel = 0,
                    dependency = { "惩戒裁决" }, -- 前置天赋需求
                    cunDangPosition = 15, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 80000, -- 激活所需神器能量
                    isElite = true, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "最大叠加层数为1层",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "最大叠加层数为2层",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "最大叠加层数为3层",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "最大叠加层数为4层",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "最大叠加层数为5层",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "最大叠加层数为6层",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "最大叠加层数为7层",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "最大叠加层数为8层",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "最大叠加层数为9层",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "最大叠加层数为10层",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
            },
            -- 其他天赋类型...
        },
        totalExp = 0, -- 拥有的神器能量
        maxTotalExp = 0, -- 当前游戏神器最大能量
        expCunDangStr = "arthjzlexp", -- 神器能量存档字符串
        canEquip = function(whichPlayer) return hquestcustom.isQuestFinished(whichPlayer, "传奇任务：灰烬之力") end, -- 是否可以装备
        canEquipDesc = "需要完成传说任务：灰烬之力", -- 是否可以装备
        isEquipped = false, -- 神器是否装备
    }
    ,
    {
        name = "守护者之杖", -- 神器名字
        icon = "ReplaceableTextures\\zhuangbei\\inv_staff_medivh.blp", -- 神器图标
        art = "UI\\UIAtiesh.tga", -- 神器天赋背景图片
        description =
        "埃提耶什·守护者之杖,一件被时间遗忘却从未消逝的传奇法器。它的力量曾震慑群魔,如今却化为三道残影:杖柄沉眠于烈焰深处,杖头栖息在狂风呼啸的元素领地,杖尾则隐匿于黑龙王子的阴影之中。唯有勇者能跨越重重险阻,收集这三大核心,再以火焰之王的精华为引,方可重铸这把足以改变世界命运的神器。持有埃提耶什者,不仅继承了远古守护者的无上威能,更肩负起守卫世界、对抗黑暗的神圣使命。当暗流涌动、魔物蠢蠢欲动之际,新一代守护者的崛起,将如同黑夜中的明灯,为世界带来希望与光明。",
        cundangStr = "artifactatys",  -- 存档字符串 一共有63位 第一位表示是否激活 第二位表示是否装备 其它表示天赋等级
        totalExp = 0,                 -- 拥有的神器能量
        maxTotalExp = 0,              -- 当前游戏神器最大能量
        expCunDangStr = "artatysexp", -- 神器能量存档字符串
        canEquip = function(whichPlayer)
            return hquestcustom.isQuestFinished(whichPlayer, "传奇任务：埃提耶什")
        end, -- 是否可以装备
        canEquipDesc = "需要完成传奇任务：埃提耶什", -- 是否可以装备
        isEquipped = false, -- 神器是否装备
        talentTree = { -- 天赋树配置，天赋共有两级，第一级为基础天赋
            { -- 第一行天赋
                { -- 第一列天赋
                    name = "守护者的诅咒",
                    description = "造成魔法伤害对目标周围半径400码范围内的所有敌方单位附加诅咒，每秒造成主属性的暗影魔法伤害，持续10秒，冷却30秒。",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\守护者的诅咒.blp",
                    activeLevel = 0,
                    dependency = {},     -- 前置天赋需求
                    cunDangPosition = 2, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 4000,  -- 激活所需神器能量
                    isElite = false,     -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "每秒造成23%主属性的暗影魔法伤害",
                            action = CONST_EVENT.damage,
                            effect = function(evtData, artifact)
                                if evtData.damageType ~= DAMAGE_TYPE.MOFA then
                                    return
                                end
                                local tianfu1     = hartifact.getTianfuLevel(artifact, "守护者的诅咒")
                                local tianfu2     = hartifact.getTianfuLevel(artifact, "麦迪文之影")
                                --local tianfu3     = hartifact.getTianfuLevel(artifact, "黑暗潜伏")
                                local tianfu4     = hartifact.getTianfuLevel(artifact, "卡德加的抉择")
                                local tianfu5     = hartifact.getTianfuLevel(artifact, "黑檀之寒")
                                local tianfu6     = hartifact.getTianfuLevel(artifact, "星界法师")
                                local tianfu7     = hartifact.getTianfuLevel(artifact, "黑暗泰坦之陨")
                                local damageMulti = 0.2 + 0.03 * tianfu1
                                damageMulti       = damageMulti * (1 + 0.05 * tianfu2)
                                local cd          = 30 - tianfu4
                                if htime.setupAndCheckCoolDown(evtData.triggerUnit, "守护者的诅咒", cd) == false then
                                    return
                                end
                                heffect.xyz("[zhuangbei]aitiyeshizuzhou.mdx", hunit.x(evtData.targetUnit),
                                    hunit.y(evtData.targetUnit),
                                    hunit.z(evtData.targetUnit), 0.5, 1, 1.8, 1.8, 1)
                                hskillMoban.radiusAOE(hunit.x(evtData.targetUnit), hunit.y(evtData.targetUnit),
                                    evtData.triggerUnit, 400,
                                    function(enumUnit)
                                        local damage = hunit.getZhushuxing(evtData.triggerUnit) * damageMulti
                                        hbuff.update(10, enumUnit, "守护者的诅咒" .. tostring(evtData.triggerUnit), false,
                                            function()
                                                hevent.register(enumUnit, CONST_EVENT.damagingCustomTarget, "守护者的诅咒易伤",
                                                    function(evtData)
                                                        if evtData.damageType ~= DAMAGE_TYPE.MOFA then
                                                            return
                                                        end
                                                        evtData.damage = evtData.damage * (1 + tianfu6 * 0.003)
                                                    end)
                                            end,
                                            function()
                                                hevent.unregister(enumUnit, CONST_EVENT.damagingCustomTarget, "守护者的诅咒易伤")
                                            end,
                                            "ReplaceableTextures\\zhuangbei\\inv_staff_medivh.blp",
                                            "守护者的诅咒：每秒造成暗影魔法伤害，如果激活星界法师天赋还能造成法术易伤", 1, 1,
                                            function(curTimer, buffHandle)
                                                buffHandle.remainingTime = buffHandle.remainingTime - buffHandle
                                                    .interval
                                                hskill.damage({
                                                    sourceUnit = evtData.triggerUnit,
                                                    targetUnit = enumUnit,
                                                    damage = damage,
                                                    damageSrc = CONST_DAMAGE_SRC.skill,
                                                    damageType = DAMAGE_TYPE.MOFA,
                                                    damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.DARK },
                                                    damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                                                    shanghainame = "守护者的诅咒",
                                                    tmpAttr = _attr({ fa_baoshang = "+" .. (1 + tianfu5 * 5) }),
                                                })
                                                heffect.attach("[shushi]tongkuzuzhou.mdx", enumUnit, "head", 0.1)
                                                if tianfu7 > 0 then
                                                    hbuff.addStackAttrBuff(
                                                        CONST_DAMAGE_SRC.skill, evtData.triggerUnit, "黑暗泰坦之陨",
                                                        _attr({ zhushuxing_baifenbi = "+" .. (tianfu7) }), 3, 1,
                                                        "ReplaceableTextures\\zhuangbei\\inv_staff_medivh.blp",
                                                        "黑暗泰坦之陨|n增加" .. (tianfu7) .. "%主属性", true)
                                                end
                                            end, nil, nil, HBUFF_UPDATE_MODE.OVERWRITE, true)
                                    end)
                            end
                        },
                        {
                            description = "每秒造成26%主属性的暗影魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "每秒造成29%主属性的暗影魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "每秒造成32%主属性的暗影魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "每秒造成35%主属性的暗影魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "每秒造成38%主属性的暗影魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "每秒造成41%主属性的暗影魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "每秒造成44%主属性的暗影魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "每秒造成47%主属性的暗影魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "每秒造成50%主属性的暗影魔法伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "麦迪文之影",
                    description = "守护者的诅咒伤害提高",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\麦迪文之影.blp",
                    activeLevel = 0,
                    dependency = { "守护者的诅咒" }, -- 前置天赋需求
                    cunDangPosition = 3, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 8000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "守护者的诅咒伤害提高5%",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "守护者的诅咒伤害提高10%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害提高15%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害提高20%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害提高25%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害提高30%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害提高35%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害提高40%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害提高45%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害提高50%",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "黑暗潜伏",
                    description = "暗影伤害提高提高",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\黑暗潜伏.blp",
                    activeLevel = 0,
                    dependency = { "麦迪文之影" }, -- 前置天赋需求
                    cunDangPosition = 4, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 16000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ dark_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ dark_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ dark_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ dark_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ dark_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ dark_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ dark_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ dark_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ dark_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ dark_enhance = "+0.5" })
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "卡德加的抉择",
                    description = "守护者的诅咒冷却时间降低秒",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\卡德加的抉择.blp",
                    activeLevel = 0,
                    dependency = { "黑暗潜伏" }, -- 前置天赋需求
                    cunDangPosition = 5, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 32000, -- 激活所需神器能量
                    isElite = true, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "守护者的诅咒冷却时间降低1秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "守护者的诅咒冷却时间降低2秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "守护者的诅咒冷却时间降低3秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "守护者的诅咒冷却时间降低4秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "守护者的诅咒冷却时间降低5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "守护者的诅咒冷却时间降低6秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "守护者的诅咒冷却时间降低7秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "守护者的诅咒冷却时间降低8秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "守护者的诅咒冷却时间降低9秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "守护者的诅咒冷却时间降低10秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "黑檀之寒",
                    description = "守护者的诅咒伤害暴击会有额外暴击伤害",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\黑檀之寒.blp",
                    activeLevel = 0,
                    dependency = { "卡德加的抉择" }, -- 前置天赋需求
                    cunDangPosition = 6, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 48000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },

                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "守护者的诅咒伤害暴击会有额外5%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害暴击会有额外10%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害暴击会有额外15%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害暴击会有额外20%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害暴击会有额外25%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害暴击会有额外30%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害暴击会有额外35%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害暴击会有额外40%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害暴击会有额外45%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒伤害暴击会有额外50%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }

                },
                { -- 第一列天赋
                    name = "星界法师",
                    description = "守护者的诅咒持续时间内会对目标造成法术易伤状态",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\星界法师.blp",
                    activeLevel = 0,
                    dependency = { "黑檀之寒" }, -- 前置天赋需求
                    cunDangPosition = 7, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 64000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },

                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "守护者的诅咒持续时间内会对目标造成0.3%法术易伤状态",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒持续时间内会对目标造成0.6%法术易伤状态",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒持续时间内会对目标造成0.9%法术易伤状态",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒持续时间内会对目标造成1.2%法术易伤状态",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒持续时间内会对目标造成1.5%法术易伤状态",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒持续时间内会对目标造成1.8%法术易伤状态",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒持续时间内会对目标造成2.1%法术易伤状态",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒持续时间内会对目标造成2.4%法术易伤状态",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒持续时间内会对目标造成2.7%法术易伤状态",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒持续时间内会对目标造成3.0%法术易伤状态",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "黑暗泰坦之陨",
                    description = "守护者的诅咒造成伤害会在3秒内提高主属性百分比",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\黑暗泰坦之陨.blp",
                    activeLevel = 0,
                    dependency = { "星界法师" }, -- 前置天赋需求
                    cunDangPosition = 8, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 80000, -- 激活所需神器能量
                    isElite = true, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "守护者的诅咒造成伤害会在3秒内提高主属性百分比1%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒造成伤害会在3秒内提高主属性百分比2%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒造成伤害会在3秒内提高主属性百分比3%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒造成伤害会在3秒内提高主属性百分比4%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒造成伤害会在3秒内提高主属性百分比5%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒造成伤害会在3秒内提高主属性百分比6%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒造成伤害会在3秒内提高主属性百分比7%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒造成伤害会在3秒内提高主属性百分比8%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒造成伤害会在3秒内提高主属性百分比9%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的诅咒造成伤害会在3秒内提高主属性百分比10%",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
            },
            {     -- 第一行天赋
                { -- 第一列天赋
                    name = "守护者的祝福",
                    description = "造成魔法伤害会使周围半径1000码范围内的所有友军的法术造成暴击的几率提高5%，冷却30秒。",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\守护者的祝福.blp",
                    activeLevel = 0,
                    dependency = {},     -- 前置天赋需求
                    cunDangPosition = 9, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 4000,  -- 激活所需神器能量
                    isElite = false,     -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+3" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "强化持续时间5.5秒",
                            action = CONST_EVENT.damage,
                            effect = function(evtData, artifact)
                                if evtData.damageType ~= DAMAGE_TYPE.MOFA then
                                    return
                                end
                                local tianfu1 = hartifact.getTianfuLevel(artifact, "守护者的祝福")
                                local tianfu2 = hartifact.getTianfuLevel(artifact, "艾格文之歌")
                                --local tianfu3     = hartifact.getTianfuLevel(artifact, "伟大传承")
                                local tianfu4 = hartifact.getTianfuLevel(artifact, "麦德安的奇遇")
                                local tianfu5 = hartifact.getTianfuLevel(artifact, "艾露尼斯")
                                local tianfu6 = hartifact.getTianfuLevel(artifact, "渡鸦先知")
                                local tianfu7 = hartifact.getTianfuLevel(artifact, "空间恶魔之殇")

                                local damageMulti = 2 + tianfu2 * 0.2
                                local duration = 5 + 0.5 * tianfu1 + 0.5 * tianfu6
                                local cd = 30 - tianfu4 * 0.5
                                if htime.setupAndCheckCoolDown(evtData.triggerUnit, "守护者的祝福", cd) == false then
                                    return
                                end
                                if tianfu2 > 0 then
                                    local damage = hunit.getZhushuxing(evtData.triggerUnit) * damageMulti
                                    hskillMoban.radiusAOE(
                                        hunit.x(evtData.targetUnit),
                                        hunit.y(evtData.targetUnit),
                                        evtData.triggerUnit,
                                        800,
                                        function(filterUnit)
                                            hskill.damage({
                                                sourceUnit = evtData.triggerUnit,
                                                targetUnit = filterUnit,
                                                damage = damage,
                                                damageSrc = CONST_DAMAGE_SRC.skill,
                                                damageType = DAMAGE_TYPE.MOFA,
                                                triggerSkill = hslk.n2i("AI技能模版"),
                                                damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.WOOD },
                                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                                shanghainame = "艾格文之歌",
                                                tmpAttr = _attr({ fa_baoshang = "+" .. (1 + tianfu5 * 5) }),
                                            })
                                        end,
                                        false,
                                        true
                                    )
                                end
                                heffect.xyz("war3mapImported\\[Spell]_045.MDX", hunit.x(evtData.triggerUnit),
                                    hunit.y(evtData.triggerUnit),
                                    hunit.z(evtData.triggerUnit), 0, 1, 1, 1, 1)
                                hgroup.forEach(hgroup.createAllyGroupByUnit(evtData.triggerUnit, 1000),
                                    function(enumUnit)
                                        hbuff.update(duration, enumUnit, "守护者的祝福", true, function()
                                                hattr.set(enumUnit, 0, _attr({
                                                    fa_bao = "+5", zhushuxing_baifenbi = "+" .. (tianfu7)
                                                }))
                                            end, function()
                                                hattr.set(enumUnit, 0, _attr({
                                                    fa_bao = "-5", zhushuxing_baifenbi = "-" .. (tianfu7)
                                                }))
                                            end, "ReplaceableTextures\\zhuangbei\\inv_staff_medivh.blp",
                                            "守护者的祝福：法术造成爆击的几率提高5%", 1, nil, nil, nil, nil,
                                            HBUFF_UPDATE_MODE.OVERWRITE, true)
                                    end)
                            end
                        },
                        {
                            description = "强化持续时间6.0秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "强化持续时间6.5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "强化持续时间7.0秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "强化持续时间7.5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "强化持续时间8.0秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "强化持续时间8.5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "强化持续时间9.0秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "强化持续时间9.5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "强化持续时间10.0秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "艾格文之歌",
                    description = "守护者的祝福触发时会对自身800码范围内的所有目标造成自然魔法伤害。",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\艾格文之歌.blp",
                    activeLevel = 0,
                    dependency = { "守护者的祝福" }, -- 前置天赋需求
                    cunDangPosition = 10, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 8000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+4" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "伤害为主属性的220%",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "伤害为主属性的240%",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "伤害为主属性的260%",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "伤害为主属性的280%",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "伤害为主属性的300%",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "伤害为主属性的320%",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "伤害为主属性的340%",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "伤害为主属性的360%",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "伤害为主属性的380%",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "伤害为主属性的400%",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "伟大传承",
                    description = "自然伤害提高。",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\伟大传承.blp",
                    activeLevel = 0,
                    dependency = { "艾格文之歌" }, -- 前置天赋需求
                    cunDangPosition = 11, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 16000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+5" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ wood_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ wood_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ wood_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ wood_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ wood_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ wood_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ wood_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ wood_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ wood_enhance = "+0.5" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ wood_enhance = "+0.5" })
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "麦德安的奇遇",
                    description = "守护者祝福的冷却时间降低秒",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\麦德安的奇遇.blp",
                    activeLevel = 0,
                    dependency = { "伟大传承" }, -- 前置天赋需求
                    cunDangPosition = 12, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 32000, -- 激活所需神器能量
                    isElite = true, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+6" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "冷却时间降低0.5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "冷却时间降低1秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "冷却时间降低1.5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "冷却时间降低2秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "冷却时间降低2.5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "冷却时间降低3秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "冷却时间降低3.5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "冷却时间降低4秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "冷却时间降低4.5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        {
                            description = "冷却时间降低5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData, artifact)
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "艾露尼斯",
                    description = "艾格文之歌的伤害有额外的暴击伤害。",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\艾露尼斯.blp",
                    activeLevel = 0,
                    dependency = { "麦德安的奇遇" }, -- 前置天赋需求
                    cunDangPosition = 13, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 48000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+7" })
                        },

                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "艾格文之歌伤害暴击会有额外5%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "艾格文之歌伤害暴击会有额外10%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "艾格文之歌伤害暴击会有额外15%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "艾格文之歌伤害暴击会有额外20%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "艾格文之歌伤害暴击会有额外25%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "艾格文之歌伤害暴击会有额外30%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "艾格文之歌伤害暴击会有额外35%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "艾格文之歌伤害暴击会有额外40%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "艾格文之歌伤害暴击会有额外45%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "艾格文之歌伤害暴击会有额外50%暴击伤害",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }

                },
                { -- 第一列天赋
                    name = "渡鸦先知",
                    description = "守护者的祝福持续时间延长秒",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\渡鸦先知.blp",
                    activeLevel = 0,
                    dependency = { "艾露尼斯" }, -- 前置天赋需求
                    cunDangPosition = 14, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 64000, -- 激活所需神器能量
                    isElite = false, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+8" })
                        },

                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "守护者的祝福持续时间延长0.5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的祝福持续时间延长1秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的祝福持续时间延长1.5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的祝福持续时间延长2秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的祝福持续时间延长2.5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的祝福持续时间延长3秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的祝福持续时间延长3.5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的祝福持续时间延长4秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的祝福持续时间延长4.5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "守护者的祝福持续时间延长5秒",
                            action = CONST_EVENT.none,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
                { -- 第一列天赋
                    name = "空间恶魔之殇",
                    description = "守护者的祝福额外提高你的主属性百分比。",
                    maxLevel = 10,
                    art = "ReplaceableTextures\\shenqi\\空间恶魔之殇.blp",
                    activeLevel = 0,
                    dependency = { "渡鸦先知" }, -- 前置天赋需求
                    cunDangPosition = 15, -- 存档指定位的数字代表了天赋等级
                    requiredExp = 80000, -- 激活所需神器能量
                    isElite = true, -- 是否精英天赋
                    passiveEffects = {
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        {
                            action = CONST_EVENT.attr,
                            effect = _attr({ zhushuxing = "+9" })
                        },
                        -- 其他等级效果...
                    },
                    activeEffects = {
                        {
                            description = "提高1%主属性",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高2%主属性",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高3%主属性",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高4%主属性",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高5%主属性",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高6%主属性",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高7%主属性",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高8%主属性",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高9%主属性",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        {
                            description = "提高10%主属性",
                            action = CONST_EVENT.attack,
                            effect = function(evtData)
                                -- 实现伤害逻辑
                            end
                        },
                        -- 其他等级效果...
                    }
                },
            },
            -- 其他天赋类型...
        },
    },
    fengjian,
    emozhanren,
    yanmozhi_shou,
    qunxingzhi
}

-- 初始化神器系统
hartifact.init                          = function()
    hartifact.validateConfig(ARTIFACT_CONFIG)
    hplayer.forEach(
        function(enumPlayer, _)
            if hplayer.isUser(enumPlayer) == false or hplayer.isPlaying(enumPlayer) == false then
                return
            end
            hartifact[enumPlayer] = table.clone(ARTIFACT_CONFIG)
            if ACHIEVEMENT_DATA[enumPlayer] == nil then
                ACHIEVEMENT_DATA[enumPlayer] = {}
            end
            ACHIEVEMENT_DATA[enumPlayer]["神器"] = {}
            ACHIEVEMENT_DATA[enumPlayer]["神器"].categoryUIName = "BtnRootWindow_Category_Category15"
            local categoryData = {}
            for i, v in ipairs(hartifact[enumPlayer]) do
                local tmpItem = {}
                tmpItem.name = v.name
                tmpItem.art = v.icon
                tmpItem.callback = function()
                    if v.canEquip(enumPlayer) == false then
                        sysecho(v.canEquipDesc, enumPlayer)
                        return
                    end
                    hartifact.switchPage(enumPlayer, i)
                    turnOnUI("神器")
                end
                tmpItem.tip = hartifact.getDescription(enumPlayer, v)
                tmpItem.enable = true
                table.insert(categoryData, tmpItem)
            end
            ACHIEVEMENT_DATA[enumPlayer]["神器"].categoryData = categoryData
        end
    )
    hsync.onSend(
        "jihuoshenqijuexing",
        function(syncData)
            local shenqiIndex = math.tointeger(syncData.triggerData[1])
            local whichPlayer = syncData.triggerPlayer
            hartifact.tryEquipShenqi(whichPlayer, shenqiIndex)
        end
    )
    hartifact.initUI()
end

hartifact.isDoubleDiaoluo               = function(fubenname)
    if SQNLHQ_CONFIG[fubenname] == nil then
        return false
    end
    local weekOfDay = os.date("!*t", hjapi.DzAPI_Map_GetGameStartTime() + 28800).wday
    if SQNLHQ_CONFIG[fubenname].schedule ~= nil then
        if SQNLHQ_CONFIG[fubenname].schedule[weekOfDay] == 1 then
            return true
        end
    end
    return false
end

hartifact.diaoluoSQNL                   = function(fubenname, nandu, mijing)
    if SQNLHQ_CONFIG[fubenname] == nil then
        return 0
    end
    if SQNLHQ_CONFIG[fubenname][nandu] == nil then
        return 0
    end
    local rate = 1
    if hartifact.isDoubleDiaoluo(fubenname) then
        rate = 2
    end
    if nandu == FUBEN_NANDU.CHUANQI then
        if SQNLHQ_CONFIG[fubenname][nandu][mijing] == nil then
            return 0
        else
            if math.random(1, 100) <= SQNLHQ_CONFIG[fubenname][nandu][mijing].rate then
                return SQNLHQ_CONFIG[fubenname][nandu][mijing].volume * rate
            end
        end
    else
        if math.random(1, 100) <= SQNLHQ_CONFIG[fubenname][nandu].rate then
            return SQNLHQ_CONFIG[fubenname][nandu].volume * rate
        end
    end
    return 0
end

hartifact.tryEquipShenqi                = function(whichPlayer, shenqiIndex)
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        sysecho("还没有选择英雄", whichPlayer)
        return false
    end

    local artifact = hartifact[whichPlayer][shenqiIndex]
    if not artifact then
        sysecho("神器不存在", whichPlayer)
        return false
    end

    if artifact.canEquip(whichPlayer) == false then
        sysecho("神器无法装备", whichPlayer)
        return false
    end

    -- 检查是否已经装备了其他神器
    for i, otherArtifact in ipairs(hartifact[whichPlayer]) do
        if i ~= shenqiIndex and otherArtifact.isEquipped then
            -- 卸下已装备的神器
            otherArtifact.isEquipped = false
            hartifact.updateActiveEffects(whichPlayer, otherArtifact)
            -- 保存数据
            hartifact.saveCundang(whichPlayer, otherArtifact)
            -- 更新UI
            hartifact.refreshUI(whichPlayer)
            ui_update_equip_achievement_data_at_category_and_idx(whichPlayer, "神器", i, false, false)
            ui_update_text_achievement_data_at_category_and_idx(whichPlayer, "神器", shenqiIndex,
                hartifact.getDescription(whichPlayer, otherArtifact))
            sysecho("已卸下神器之魂: " .. otherArtifact.name, whichPlayer)
            break
        end
    end

    -- 切换当前神器的装备状态
    artifact.isEquipped = not artifact.isEquipped

    -- 更新神器装备状态和效果
    hartifact.updateActiveEffects(whichPlayer, artifact)
    -- 保存数据
    hartifact.saveCundang(whichPlayer, artifact)
    -- 更新UI
    hartifact.refreshUI(whichPlayer)
    if artifact.isEquipped then
        ui_update_equip_achievement_data_at_category_and_idx(whichPlayer, "神器", shenqiIndex, true, false)
        sysecho("成功装备神器之魂: " .. artifact.name, whichPlayer)
    else
        ui_update_equip_achievement_data_at_category_and_idx(whichPlayer, "神器", shenqiIndex, false, false)
        sysecho("已卸下神器之魂: " .. artifact.name, whichPlayer)
    end
    ui_update_text_achievement_data_at_category_and_idx(whichPlayer, "神器", shenqiIndex,
        hartifact.getDescription(whichPlayer, artifact))
    return true
end

hartifact.getDescription                = function(whichPlayer, artifact)
    local descriptionParts = {}

    -- 添加神器名字
    table.insert(descriptionParts, hcolor.yellow(artifact.name))
    table.insert(descriptionParts, "")
    -- 添加装备状态
    table.insert(descriptionParts, hcolor.yellow("装备需求：") .. (artifact.canEquipDesc))
    table.insert(descriptionParts, "")
    table.insert(descriptionParts, hcolor.yellow("简介:") .. artifact.description)
    table.insert(descriptionParts, "")
    table.insert(descriptionParts, hcolor.yellow("注意:"))
    table.insert(descriptionParts, "- 点击左键可以打开神器天赋面板并进行神器装备/卸下操作")
    table.insert(descriptionParts, "- 只有装备的神器才会激活特效！")
    table.insert(descriptionParts, "- 神器能量可以通过通关秘境获取！")

    -- 将所有部分用 |n 连接
    return table.concat(descriptionParts, "|n")
end

hartifact.getDescriptionForSingleTianfu = function(tianfu, artifact)
    local descriptionParts = {}
    local color = hcolor.grey
    if tianfu.activeLevel > 0 then
        color = hcolor.green
    end
    -- 添加天赋名称
    table.insert(descriptionParts,
        hcolor.green(tianfu.name) ..
        color("（" .. (tostring(tianfu.activeLevel) .. "/" .. tostring(tianfu.maxLevel)) .. "）"))
    table.insert(descriptionParts, "")
    -- 添加是否为精英天赋
    if tianfu.isElite then
        table.insert(descriptionParts, hcolor.orange("主要天赋"))
        table.insert(descriptionParts, "")
    end

    -- 添加天赋描述
    table.insert(descriptionParts, color(tianfu.description))
    table.insert(descriptionParts, "")
    -- 添加所需经验
    if tianfu.activeLevel < tianfu.maxLevel and hartifact.checkDependLevelEnough(artifact, tianfu.name) then
        table.insert(descriptionParts, "激活需要神器能量: " .. hcolor.jinglianglan(tostring(tianfu.requiredExp)))
        table.insert(descriptionParts, "")
    end


    -- 添加依赖信息
    if tianfu.dependency and #tianfu.dependency > 0 and hartifact.checkDependLevelEnough(artifact, tianfu.name) == false then
        table.insert(descriptionParts, hcolor.yellow("需要前置天赋满级: ") .. table.concat(tianfu.dependency, ", "))
        table.insert(descriptionParts, "")
    end

    -- 添加被动效果信息
    if tianfu.passiveEffects and #tianfu.passiveEffects > 0 then
        table.insert(descriptionParts, hcolor.yellow("永久效果（无需穿戴）:"))
        for i, effect in ipairs(tianfu.passiveEffects) do
            local tmpDesc
            if effect.action == CONST_EVENT.attr then
                tmpDesc = description.attribute(effect.effect, ",")
            else
                tmpDesc = effect.description
            end
            if i <= tianfu.activeLevel then
                table.insert(descriptionParts, "- " .. hcolor.green(tmpDesc))
            else
                table.insert(descriptionParts, "- " .. hcolor.grey(tmpDesc))
            end
        end
        table.insert(descriptionParts, "|n")
    end

    -- 添加主动效果信息
    if tianfu.activeEffects and #tianfu.activeEffects > 0 then
        table.insert(descriptionParts, hcolor.yellow("穿戴效果:"))
        for i, effect in ipairs(tianfu.activeEffects) do
            local tmpDesc
            if effect.action == CONST_EVENT.attr then
                tmpDesc = description.attribute(effect.effect, ",")
            else
                tmpDesc = effect.description
            end
            if i <= tianfu.activeLevel then
                table.insert(descriptionParts, "- " .. hcolor.green(tmpDesc))
            else
                table.insert(descriptionParts, "- " .. hcolor.grey(tmpDesc))
            end
        end
    end

    -- 将所有部分用 |n 连接
    return table.concat(descriptionParts, "|n")
end

-- 为玩家初始化神器
hartifact.initPlayerArtifact            = function(whichPlayer)
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        sysecho("还没有选择英雄", whichPlayer)
        return
    end
    hartifact.loadCunDang(whichPlayer)
    for _, artifact in ipairs(hartifact[whichPlayer]) do
        -- 更新UI
        hartifact.updateUI(whichPlayer, artifact)
    end

    hevent.register(
        hero,
        CONST_EVENT.finishFUBEN,
        "神器通关",
        function(evtData)
            if hplayer.isPlaying(whichPlayer) == false or hplayer.isUser(whichPlayer) == false then
                return
            end
            local volume = hartifact.diaoluoSQNL(evtData.fubenName, evtData.nandu, evtData.mijing)
            if volume > 0 then
                hartifact.huodeSQNL(whichPlayer, volume)
            end
        end
    )
end

local function convertCunDangToEXP(cundangValue)
    for i, config in ipairs(SQNL_CONFIG) do
        if cundangValue <= config[1] then
            if i == 1 then
                return math.floor(config[2] * (cundangValue / config[1]))
            else
                local prevConfig = SQNL_CONFIG[i - 1]
                local expDiff = config[2] - prevConfig[2]
                local cundangDiff = config[1] - prevConfig[1]
                local ratio = (cundangValue - prevConfig[1]) / cundangDiff
                return math.floor(prevConfig[2] + (expDiff * ratio))
            end
        end
    end
    -- If cundangValue is greater than the highest defined level
    local lastConfig = SQNL_CONFIG[#SQNL_CONFIG]
    return math.floor(lastConfig[2] + ((cundangValue - lastConfig[1]) / 2000) * lastConfig[3])
end

local function convertExpToCunDang(exp)
    for i, config in ipairs(SQNL_CONFIG) do
        if exp <= config[2] then
            if i == 1 then
                return math.floor(config[1] * (exp / config[2]))
            else
                local prevConfig = SQNL_CONFIG[i - 1]
                local cundangDiff = config[1] - prevConfig[1]
                local expDiff = config[2] - prevConfig[2]
                local ratio = (exp - prevConfig[2]) / expDiff
                return math.floor(prevConfig[1] + (cundangDiff * ratio))
            end
        end
    end
    -- If exp is greater than the highest defined level
    local lastConfig = SQNL_CONFIG[#SQNL_CONFIG]
    return math.floor(lastConfig[1] + ((exp - lastConfig[2]) / lastConfig[3]) * 2000)
end

-- 从存档加载神器数据
hartifact.loadCunDang          = function(whichPlayer)
    for i, artifact in ipairs(hartifact[whichPlayer]) do
        -- 加载神器状态和天赋等级
        local cundangValue = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(artifact.cundangStr, false)

        if cundangValue and #cundangValue == 63 then
            -- 解析神器装备状态
            artifact.isEquipped = cundangValue:sub(1, 1) == "1"
            if artifact.canEquip(whichPlayer) == false then
                artifact.isEquipped = false
            end
            if artifact.isEquipped then
                ui_update_equip_achievement_data_at_category_and_idx(whichPlayer, "神器", i, true, false)
            end
            -- 解析天赋等级
            for _, row in ipairs(artifact.talentTree) do
                for _, talent in ipairs(row) do
                    local levelHex = cundangValue:sub(talent.cunDangPosition, talent.cunDangPosition)
                    talent.activeLevel = tonumber(levelHex, 16) or 0
                end
            end

            -- 加载神器能量
            local cdValueStr = hplayer.dzCunDang[whichPlayer].loadKeyFromCunDang(artifact.expCunDangStr, false,
                true, true)
            if cdValueStr == 0 then
                hplayer.dzCunDang[whichPlayer].saveCundangWihtoutIndx(
                    artifact.expCunDangStr,
                    false,
                    "0",
                    true
                )
            end
            local cdValue = tonumber(cdValueStr) or 0
            artifact.totalExp = convertCunDangToEXP(cdValue)
            local limit = hplayer.dzCunDang[whichPlayer].loadDailyLimitKey(artifact.expCunDangStr, false)
            if DEBUGGING then limit = 2000 end
            artifact.maxTotalExp = convertCunDangToEXP(limit + cdValue)

            -- 检查能量以及dependency是否合理
            local isValid = hartifact.validateArtifactData(artifact)

            if isValid then
                -- 更新神器效果
                for _, row in ipairs(artifact.talentTree) do
                    for _, talent in ipairs(row) do
                        hartifact.updateTalent(whichPlayer, artifact, talent)
                    end
                end
            else
                -- 如果数据无效，重置神器状态
                hartifact.resetArtifact(artifact)
                sysecho("神器数据无效，已重置: " .. artifact.name, whichPlayer)
            end
        else
            -- 如果没有存档数据，初始化为默认值
            hartifact.resetArtifact(artifact)
        end
    end
end

-- 验证神器数据
hartifact.validateArtifactData = function(artifact)
    -- 检查能量是否合理
    if hartifact.recalculateTotalExpConsumption(artifact) > artifact.totalExp then
        return false
    end

    -- 检查天赋依赖关系
    for _, row in ipairs(artifact.talentTree) do
        for _, talent in ipairs(row) do
            if talent.activeLevel > 0 then
                for _, dependencyName in ipairs(talent.dependency or {}) do
                    local depTalent = hartifact.findTalentByName(artifact, dependencyName)
                    if not depTalent or depTalent.activeLevel < depTalent.maxLevel then
                        return false
                    end
                end
            end
        end
    end

    return true
end

-- 重置神器状态
hartifact.resetArtifact        = function(artifact)
    artifact.isEquipped = false
    for _, row in ipairs(artifact.talentTree) do
        for _, talent in ipairs(row) do
            talent.activeLevel = 0
        end
    end
end

function hartifact.validateConfig(config)
    for artifactIndex, artifact in ipairs(config) do
        if type(artifact) ~= "table" then
            error(string.format("Artifact #%d is not a table", artifactIndex))
        end

        if type(artifact.name) ~= "string" then
            error(string.format("Artifact #%d does not have a valid name", artifactIndex))
        end

        if type(artifact.talentTree) ~= "table" then
            error(string.format("Artifact '%s' does not have a valid talentTree", artifact.name))
        end

        local talentNames = {}

        for rowIndex, row in ipairs(artifact.talentTree) do
            for talentIndex, talent in ipairs(row) do
                if type(talent) ~= "table" then
                    error(string.format("Talent #%d in row #%d of artifact '%s' is not a table", talentIndex, rowIndex,
                        artifact.name))
                end

                if type(talent.name) ~= "string" then
                    error(string.format("Talent #%d in row #%d of artifact '%s' does not have a valid name", talentIndex,
                        rowIndex, artifact.name))
                end

                -- Check for unique talent names
                if talentNames[talent.name] then
                    error(string.format("Duplicate talent name '%s' found in artifact '%s'", talent.name, artifact.name))
                else
                    talentNames[talent.name] = true
                end

                if type(talent.maxLevel) ~= "number" then
                    error(string.format("Talent '%s' in artifact '%s' does not have a valid maxLevel", talent.name,
                        artifact.name))
                end

                if (talent.passiveEffects and type(talent.passiveEffects) ~= "table") or (talent.activeEffects and type(talent.activeEffects) ~= "table") then
                    error(string.format(
                        "Talent '%s' in artifact '%s' does not have valid passiveEffects or activeEffects tables",
                        talent.name, artifact.name))
                end

                if (talent.activeEffects and #talent.activeEffects > 0 and talent.maxLevel ~= #talent.activeEffects) or (talent.passiveEffects and #talent.passiveEffects > 0 and #talent.passiveEffects ~= talent.maxLevel) then
                    error(string.format(
                        "Talent '%s' in artifact '%s': The length of passiveEffects (%d) and activeEffects (%d) must be equal to maxLevel (%d)",
                        talent.name, artifact.name, #talent.passiveEffects, #talent.activeEffects, talent.maxLevel))
                end

                if talent.passiveEffects then
                    for i, effect in ipairs(talent.passiveEffects) do
                        if effect.action == CONST_EVENT.attr then
                            if type(effect.effect) ~= "table" then
                                error(string.format(
                                    "Artifact '%s', Talent '%s', Passive Effect #%d: For CONST_EVENT.attr action, effect must be a table",
                                    artifact.name, talent.name, i))
                            end
                        else
                            if type(effect.effect) ~= "function" then
                                error(string.format(
                                    "Artifact '%s', Talent '%s', Passive Effect #%d: For non-CONST_EVENT.attr action, effect must be a function",
                                    artifact.name, talent.name, i))
                            end
                        end
                    end
                end

                if talent.activeEffects then
                    for i, effect in ipairs(talent.activeEffects) do
                        if effect.action == CONST_EVENT.attr then
                            if type(effect.effect) ~= "table" then
                                error(string.format(
                                    "Artifact '%s', Talent '%s', Active Effect #%d: For CONST_EVENT.attr action, effect must be a table",
                                    artifact.name, talent.name, i))
                            end
                        else
                            if type(effect.effect) ~= "function" then
                                error(string.format(
                                    "Artifact '%s', Talent '%s', Active Effect #%d: For non-CONST_EVENT.attr action, effect must be a function",
                                    artifact.name, talent.name, i))
                            end
                        end
                    end
                end
            end
        end
    end
end

-- 更新UI
hartifact.updateUI                       = function(whichPlayer, artifact)
    -- 实现UI更新逻辑，类似于天赋系统的UI更新
end
-- 重新计算神器总能量消耗
hartifact.recalculateTotalExpConsumption = function(artifact)
    local totalExpConsumption = 0
    for _, row in ipairs(artifact.talentTree) do
        for _, talent in ipairs(row) do
            if talent.activeLevel > 0 then
                local talentExpConsumption = 0
                for i = 1, talent.activeLevel do
                    talentExpConsumption = talentExpConsumption + (talent.requiredExp or 100)
                end
                totalExpConsumption = totalExpConsumption + talentExpConsumption
            end
        end
    end
    return totalExpConsumption
end

-- 尝试移除天赋
hartifact.tryRemoveTalent                = function(whichPlayer, artifactIndex, talentRow, talentColumn)
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        sysecho("还没有选择英雄", whichPlayer)
        return false
    end

    local artifact = hartifact[whichPlayer][artifactIndex]
    if not artifact then
        sysecho("神器不存在", whichPlayer)
        return false
    end

    local talent = artifact.talentTree[talentRow][talentColumn]
    if not talent then
        sysecho("天赋不存在", whichPlayer)
        return false
    end

    if talent.activeLevel <= 0 then
        sysecho("该天赋尚未激活", whichPlayer)
        return false
    end

    -- 检查是否有其他天赋依赖于此天赋
    if hartifact.checkDependencies(artifact, talent.name) then
        sysecho("无法移除该天赋，其他天赋依赖于它", whichPlayer)
        return false
    end

    talent.activeLevel = talent.activeLevel - 1

    -- 应用天赋效果
    hartifact.updateTalent(whichPlayer, artifact, talent)

    -- 重新计算能量消耗
    local newExpConsumption = hartifact.recalculateTotalExpConsumption(artifact)

    -- 更新神器能量
    artifact.currentExp = artifact.totalExp - newExpConsumption

    -- 更新UI
    hartifact.refreshUI(whichPlayer)
    if whichPlayer == hplayer.players[1] then
        local tipsText = hjapi.DzFrameFindByName("TIANFU_Tips_Desc", 0)
        hjapi.DzFrameSetText(tipsText, hartifact.getDescriptionForSingleTianfu(talent, artifact))
    end
    -- 保存数据
    hartifact.saveCundang(whichPlayer, artifact)

    sysecho("成功移除天赋: " .. talent.name, whichPlayer)
    return true
end

-- 检查是否有其他天赋依赖于指定天赋
hartifact.checkDependencies              = function(artifact, talentName)
    for _, row in ipairs(artifact.talentTree) do
        for _, talent in ipairs(row) do
            if talent.activeLevel > 0 and talent.dependency then
                for _, dependency in ipairs(talent.dependency) do
                    if dependency == talentName then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- 检查前置需求是否满足
hartifact.checkDependLevelEnough         = function(artifact, talentName)
    -- 找到指定的天赋
    local targetTalent = hartifact.findTalentByName(artifact, talentName)

    if not targetTalent then
        error(string.format("Talent '%s' not found in artifact '%s'", talentName, artifact.name))
    end

    -- 如果天赋没有依赖，直接返回true
    if not targetTalent.dependency or #targetTalent.dependency == 0 then
        return true
    end

    -- 检查每个依赖天赋
    for _, dependencyName in ipairs(targetTalent.dependency) do
        local dependencyTalent = hartifact.findTalentByName(artifact, dependencyName)

        if not dependencyTalent then
            error(string.format("Dependency talent '%s' not found for talent '%s' in artifact '%s'", dependencyName,
                talentName, artifact.name))
        end

        -- 检查依赖天赋是否达到最大等级
        if dependencyTalent.activeLevel < dependencyTalent.maxLevel then
            return false
        end
    end

    -- 所有依赖都满足，返回true
    return true
end

-- 尝试激活天赋
hartifact.tryActivateTalent              = function(whichPlayer, artifactIndex, talentRow, talentColumn)
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        sysecho("还没有选择英雄", whichPlayer)
        return false
    end

    local artifact = hartifact[whichPlayer][artifactIndex]
    if not artifact then
        sysecho("神器不存在", whichPlayer)
        return false
    end

    local talent = artifact.talentTree[talentRow][talentColumn]
    if not talent then
        sysecho("天赋不存在", whichPlayer)
        return false
    end

    if talent.activeLevel >= talent.maxLevel then
        sysecho("该天赋已达到最大等级", whichPlayer)
        return false
    end

    -- 检查前置条件
    if not hartifact.checkTalentPreconditions(whichPlayer, artifactIndex, talentRow, talentColumn) then
        sysecho("未满足激活条件", whichPlayer)
        return false
    end

    -- 检查并消耗神器能量
    local requiredExp = talent.requiredExp or 100 -- 使用天赋自身的 requiredExp，如果没有则默认为 100
    -- 重新计算能量消耗
    local newExpConsumption = hartifact.recalculateTotalExpConsumption(artifact)

    if newExpConsumption + requiredExp > artifact.totalExp then
        sysecho("神器能量不足", whichPlayer)
        return false
    end

    -- 激活天赋
    talent.activeLevel = talent.activeLevel + 1

    -- 应用天赋效果
    hartifact.updateTalent(whichPlayer, artifact, talent)
    -- 更新UI
    hartifact.refreshUI(whichPlayer)

    if whichPlayer == hplayer.loc() then
        local tipsText = hjapi.DzFrameFindByName("TIANFU_Tips_Desc", 0)
        hjapi.DzFrameSetText(tipsText, hartifact.getDescriptionForSingleTianfu(talent, artifact))
    end

    -- 保存数据
    hartifact.saveCundang(whichPlayer, artifact)
    sysecho("成功激活天赋: " .. talent.name .. " (" .. talent.activeLevel .. "/" .. talent.maxLevel .. ")", whichPlayer)
    return true
end

-- 根据天赋名字查找天赋
hartifact.findTalentByName               = function(artifact, talentName)
    for _, row in ipairs(artifact.talentTree) do
        for _, talent in ipairs(row) do
            if talent.name == talentName then
                return talent
            end
        end
    end
    return nil
end

-- 检查天赋前置条件
hartifact.checkTalentPreconditions       = function(whichPlayer, artifactIndex, talentRow, talentColumn)
    local artifact = hartifact[whichPlayer][artifactIndex]
    local talent = artifact.talentTree[talentRow][talentColumn]

    -- 检查依赖的天赋是否已经激活
    for _, dependencyName in ipairs(talent.dependency or {}) do
        local depTalent = hartifact.findTalentByName(artifact, dependencyName)
        if not depTalent then
            sysecho("前置天赋不存在: " .. dependencyName, whichPlayer)
            return false
        end
        if depTalent.activeLevel < depTalent.maxLevel then
            sysecho("前置天赋等级不足: " .. dependencyName, whichPlayer)
            return false
        end
    end
    return true
end

-- 获取指定天赋的等级
hartifact.getTianfuLevel                 = function(artifact, tianfuName)
    local talent = hartifact.findTalentByName(artifact, tianfuName)

    if talent then
        return talent.activeLevel or 0
    else
        return 0 -- 如果找不到指定的天赋，返回0
    end
end

-- 更改单个天赋
hartifact.updateTalent                   = function(whichPlayer, artifact, talent)
    local hero = hplayer.getMainHero(whichPlayer)

    local function updateEffect(effect, effectType, index, isAdd, artifact)
        local key = "artifact_" .. artifact.name .. "_" .. talent.name .. "_" .. effectType .. "_" .. index
        hunit.updateEffect(hero, key, effect, isAdd, artifact)
    end

    -- 移除被动效果
    if talent.passiveEffects then
        for i = 1, #(talent.passiveEffects) do
            local effect = talent.passiveEffects[i]
            if i <= talent.activeLevel then
                updateEffect(effect, "passive", i, true, artifact)
            else
                updateEffect(effect, "passive", i, false, artifact)
            end
        end
    end

    -- 移除主动效果
    if talent.activeEffects then
        for i = 1, #(talent.activeEffects) do
            local effect = talent.activeEffects[i]
            if i <= talent.activeLevel and artifact.isEquipped then
                updateEffect(effect, "active", i, true, artifact)
            else
                updateEffect(effect, "active", i, false, artifact)
            end
        end
    end
end

-- 更新主动效果
hartifact.updateActiveEffects            = function(whichPlayer, artifact)
    for _, row in ipairs(artifact.talentTree) do
        for _, talent in ipairs(row) do
            hartifact.updateTalent(whichPlayer, artifact, talent)
        end
    end
end

-- 更新神器装备状态
hartifact.updateArtifactEquipStatus      = function(whichPlayer, artifact, isEquipped)
    artifact.isEquipped = isEquipped
    hartifact.updateActiveEffects(whichPlayer, artifact)
end

-- 保存神器数据
hartifact.saveCundang                    = function(whichPlayer, artifact)
    -- 初始化 cundangValue 为 63 个 "0"
    local cundangValue = string.rep("0", 63)

    -- 保存神器激活状态和装备状态
    cundangValue = (artifact.isEquipped and "1" or "0") .. string.sub(cundangValue, 2)

    -- 创建一个临时表来存储所有天赋等级及其位置
    local talentLevels = {}

    -- 收集所有天赋等级及其位置
    for _, row in ipairs(artifact.talentTree) do
        for _, talent in ipairs(row) do
            if talent.cunDangPosition >= 2 and talent.cunDangPosition <= 63 then
                local levelHex = string.format("%X", math.min(talent.activeLevel, 15))
                talentLevels[talent.cunDangPosition] = levelHex
            end
        end
    end

    -- 按位置顺序应用天赋等级
    for i = 2, 63 do
        if talentLevels[i] then
            cundangValue = string.sub(cundangValue, 1, i - 1) .. talentLevels[i] .. string.sub(cundangValue, i + 1)
        end
    end

    -- 保存神器数据
    hplayer.dzCunDang[whichPlayer].saveCundang(
        artifact.cundangStr,
        false,
        1,
        63,
        cundangValue
    )
    local cdValue = convertExpToCunDang(artifact.totalExp)
    hplayer.dzCunDang[whichPlayer].saveCundangWihtoutIndx(
        artifact.expCunDangStr,
        false,
        cdValue, true
    )
end

local function createBackdrop(name, parent, width, height, texture, alignPosition, parentAlignPosition, offsetX, offsetY)
    local backdrop = hjapi.DzCreateFrameByTagName("BACKDROP", name, parent, "", 0)
    hjapi.DzFrameSetSize(backdrop, width, height)
    hjapi.DzFrameSetTexture(backdrop, texture)
    hjapi.DzFrameSetPoint(backdrop, alignPosition, parent, parentAlignPosition, offsetX, offsetY)
    hjapi.DzFrameShow(backdrop, true)
    return backdrop
end

local function createButton(name, parent, width, height, alignPosition, parentAlignPosition, offsetX, offsetY)
    local backdrop = hjapi.DzCreateFrameByTagName("BUTTON", name, parent, "", 0)
    hjapi.DzFrameSetSize(backdrop, width, height)
    hjapi.DzFrameSetPoint(backdrop, alignPosition, parent, parentAlignPosition, offsetX, offsetY)
    hjapi.DzFrameShow(backdrop, true)
    return backdrop
end


local function createText(name, parent, font, fontSize)
    local text = hjapi.DzCreateFrameByTagName("TEXT", name, parent, "", 0)
    hjapi.DzFrameSetFont(text, font, fontSize, 0)
    hjapi.DzFrameShow(text, true)
    return text
end

function hartifact.initUI()
    UI_global_sqtianfu         = {}

    -- 创建总frame
    UI_global_sqtianfu["main"] = createBackdrop("UI_global_sqtianfumain_back", hjapi.DzGetGameUI(), 0.6,
        0.4,
        "UI\\background_retraction.tga", FRAME_ALIGN_CENTER, FRAME_ALIGN_CENTER, 0, 0.06)
    hjapi.DzFrameShow(UI_global_sqtianfu["main"], false)
    UI_global_sqtianfu["sqart"] = createBackdrop("UI_global_sqtianfusqart", UI_global_sqtianfu["main"], 0.36, 0.48,
        "UI\\huijinzhili.blp", FRAME_ALIGN_CENTER, FRAME_ALIGN_CENTER, 0, 0)
    hjapi.DzFrameSetAlpha(UI_global_sqtianfu["sqart"], 150)
    -- 创建说明文本
    UI_global_sqtianfu["sqnengliang"] = createText("sqnengliang", UI_global_sqtianfu["main"],
        "war3mapImported\\fonts.ttf",
        0.011)
    hjapi.DzFrameSetPoint(UI_global_sqtianfu["sqnengliang"], FRAME_ALIGN_CENTER, UI_global_sqtianfu["main"],
        FRAME_ALIGN_TOP, 0, -0.08)
    hjapi.DzFrameSetText(UI_global_sqtianfu["sqnengliang"], "神器能量：" .. hcolor.jinglianglan("999"))
    UI_global_sqtianfu["sqmingzi"] = createText("sqmingzi", UI_global_sqtianfu["main"],
        "war3mapImported\\fonts.ttf",
        0.013)
    hjapi.DzFrameSetPoint(UI_global_sqtianfu["sqmingzi"], FRAME_ALIGN_CENTER, UI_global_sqtianfu["main"],
        FRAME_ALIGN_TOP, 0, -0.06)
    hjapi.DzFrameSetText(UI_global_sqtianfu["sqmingzi"], hcolor.yellow("未知神器"))

    UI_global_sqtianfu["sqzhuangbei"] = createButton("sqzhuangbei",
        UI_global_sqtianfu["main"], 0.05,
        0.03, FRAME_ALIGN_CENTER,
        FRAME_ALIGN_CENTER, 0, -0.12)

    UI_global_sqtianfu["sqzhuangbeiback"] = createBackdrop("sqzhuangbeiback",
        UI_global_sqtianfu["sqzhuangbei"], 0.05,
        0.03, "UI\\AZAchieve\\mask.blp", FRAME_ALIGN_CENTER, FRAME_ALIGN_CENTER,
        0,
        0)

    UI_global_sqtianfu["sqzhuangbeihighlight"] = createBackdrop("sqzhuangbeihighlight",
        UI_global_sqtianfu["sqzhuangbei"], 0.05,
        0.03, "MoonWellWater.BLP", FRAME_ALIGN_CENTER, FRAME_ALIGN_CENTER,
        0,
        0)
    hjapi.DzFrameSetAlpha(UI_global_sqtianfu["sqzhuangbeihighlight"], 100)
    hjapi.DzFrameShow(UI_global_sqtianfu["sqzhuangbeihighlight"], false)

    hjapi.DzFrameSetScriptByCode(
        UI_global_sqtianfu["sqzhuangbei"],
        MOUSE_ORDER_ENTER,
        function()
            hjapi.DzFrameShow(UI_global_sqtianfu["sqzhuangbeihighlight"], true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        UI_global_sqtianfu["sqzhuangbei"],
        MOUSE_ORDER_LEAVE,
        function()
            hjapi.DzFrameShow(UI_global_sqtianfu["sqzhuangbeihighlight"], false)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        UI_global_sqtianfu["sqzhuangbei"],
        MOUSE_ORDER_CLICK,
        function()
            if UI_global_active_artifact_index == nil then
                return
            end
            hsync.send("jihuoshenqijuexing", { UI_global_active_artifact_index })
        end,
        false
    )

    UI_global_sqtianfu["closebutton"] = createButton("closebutton",
        UI_global_sqtianfu["main"], 0.024,
        0.032, FRAME_ALIGN_CENTER,
        FRAME_ALIGN_CENTER, 0.2, 0.17)

    UI_global_sqtianfu["closeback"] = createBackdrop("closeback",
        UI_global_sqtianfu["closebutton"], 0.024,
        0.032, "UI\\AZAchieve\\UI_01_close.blp", FRAME_ALIGN_CENTER, FRAME_ALIGN_CENTER,
        0,
        0)

    UI_global_sqtianfu["closehighlight"] = createBackdrop("closehighlight",
        UI_global_sqtianfu["closebutton"], 0.024,
        0.032, "MoonWellWater.BLP", FRAME_ALIGN_CENTER, FRAME_ALIGN_CENTER,
        0,
        0)
    hjapi.DzFrameSetAlpha(UI_global_sqtianfu["closehighlight"], 100)
    hjapi.DzFrameShow(UI_global_sqtianfu["closehighlight"], false)

    hjapi.DzFrameSetScriptByCode(
        UI_global_sqtianfu["closebutton"],
        MOUSE_ORDER_ENTER,
        function()
            hjapi.DzFrameShow(UI_global_sqtianfu["closehighlight"], true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        UI_global_sqtianfu["closebutton"],
        MOUSE_ORDER_LEAVE,
        function()
            hjapi.DzFrameShow(UI_global_sqtianfu["closehighlight"], false)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        UI_global_sqtianfu["closebutton"],
        MOUSE_ORDER_CLICK,
        function()
            hjapi.DzFrameShow(UI_global_sqtianfu["main"], false)
        end,
        false
    )

    local activeButton

    for i = 1, 2 do
        for j = 1, 7, 1 do
            UI_global_sqtianfu["tianfuback" .. i .. "|" .. j] = createBackdrop("tianfu" .. i .. "|" .. j,
                UI_global_sqtianfu
                ["main"], 0.03,
                0.04, "ReplaceableTextures\\zhuangbei\\shuangshoujian\\huijingzhijian.blp", FRAME_ALIGN_CENTER,
                FRAME_ALIGN_LEFT, 0.15 + 0.05 * (j - 1),
                0.1 * (1 - i) + 0.04)

            UI_global_sqtianfu["tianfubotton" .. i .. "|" .. j] = createButton("tianfu" .. i .. "|" .. j,
                UI_global_sqtianfu["tianfuback" .. i .. "|" .. j], 0.03,
                0.04, FRAME_ALIGN_CENTER,
                FRAME_ALIGN_CENTER, 0, 0)

            UI_global_sqtianfu["tianfumask" .. i .. "|" .. j] = createBackdrop("tianfu" .. i .. "|" .. j,
                UI_global_sqtianfu["tianfuback" .. i .. "|" .. j], 0.03,
                0.04, "UI\\AZAchieve\\mask.blp", FRAME_ALIGN_CENTER, FRAME_ALIGN_CENTER,
                0,
                0)

            UI_global_sqtianfu["tianfuframebasic" .. i .. "|" .. j] = createBackdrop("tianfu" .. i .. "|" .. j,
                UI_global_sqtianfu["tianfuback" .. i .. "|" .. j], 0.03,
                0.04, "UI\\ui-quickslot-depress.tga", FRAME_ALIGN_CENTER, FRAME_ALIGN_CENTER,
                0,
                0)

            UI_global_sqtianfu["tianfuframe" .. i .. "|" .. j] = createBackdrop("tianfu" .. i .. "|" .. j,
                UI_global_sqtianfu["tianfuback" .. i .. "|" .. j], 0.054,
                0.072, "UI\\ui-dialogbox-gold-dragon.blp", FRAME_ALIGN_CENTER, FRAME_ALIGN_CENTER,
                0,
                0)

            UI_global_sqtianfu["tianfuhighlight" .. i .. "|" .. j] = createBackdrop("tianfu" .. i .. "|" .. j,
                UI_global_sqtianfu["tianfuback" .. i .. "|" .. j], 0.03,
                0.04, "MoonWellWater.BLP", FRAME_ALIGN_CENTER, FRAME_ALIGN_CENTER,
                0,
                0)
            hjapi.DzFrameSetAlpha(UI_global_sqtianfu["tianfuhighlight" .. i .. "|" .. j], 100)
            hjapi.DzFrameShow(UI_global_sqtianfu["tianfuhighlight" .. i .. "|" .. j], false)

            hjapi.DzFrameSetScriptByCode(
                UI_global_sqtianfu["tianfubotton" .. i .. "|" .. j],
                MOUSE_ORDER_ENTER,
                function()
                    if UI_global_active_artifact_index == nil then
                        return
                    end
                    local artifact = hartifact[hplayer.loc()][UI_global_active_artifact_index]
                    local tianfu = artifact.talentTree[i][j]
                    local tip = hartifact.getDescriptionForSingleTianfu(tianfu, artifact)
                    local tipsBack = hjapi.DzFrameFindByName("TIANFU_Tips", 0)
                    local tipsText = hjapi.DzFrameFindByName("TIANFU_Tips_Desc", 0)
                    hjapi.DzFrameSetPriority(tipsBack, 0)
                    hjapi.DzFrameClearAllPoints(tipsText)
                    hjapi.DzFrameSetSize(tipsText, 0.1500, 0)
                    hjapi.DzFrameSetPoint(
                        tipsText,
                        FRAME_ALIGN_RIGHT,
                        UI_global_sqtianfu["main"],
                        FRAME_ALIGN_LEFT,
                        0.07,
                        0
                    )
                    hjapi.DzFrameSetText(tipsText, tip)
                    hjapi.DzFrameShow(tipsBack, true)
                    hjapi.DzFrameShow(UI_global_sqtianfu["tianfuhighlight" .. i .. "|" .. j], true)
                    activeButton = { i, j }
                end,
                false
            )
            hjapi.DzFrameSetScriptByCode(
                UI_global_sqtianfu["tianfubotton" .. i .. "|" .. j],
                MOUSE_ORDER_LEAVE,
                function()
                    local tipsBack = hjapi.DzFrameFindByName("TIANFU_Tips", 0)
                    activeButton = nil
                    hjapi.DzFrameShow(tipsBack, false)
                    hjapi.DzFrameShow(UI_global_sqtianfu["tianfuhighlight" .. i .. "|" .. j], false)
                end,
                false
            )
            hjapi.DzFrameSetScriptByCode(
                UI_global_sqtianfu["tianfubotton" .. i .. "|" .. j],
                MOUSE_ORDER_CLICK,
                function()
                    if UI_global_active_artifact_index == nil then
                        return
                    end
                    hsync.send("tryjihuosqtianfu", { i, j, UI_global_active_artifact_index })
                end,
                false
            )
        end
    end

    hjapi.DzTriggerRegisterMouseEventByCode(
        hplayer.loc(),
        GAME_KEY_MOUSE_RIGHT,
        GAME_KEY_ACTION_RELEASE,
        false,
        function()
            if activeButton ~= nil and UI_global_active_artifact_index ~= nil then
                hsync.send("trydisablesqtianfu", { activeButton[1], activeButton[2], UI_global_active_artifact_index })
            end
        end
    )

    hsync.onSend(
        "tryjihuosqtianfu",
        function(syncData)
            local i             = math.tointeger(syncData.triggerData[1])
            local j             = math.tointeger(syncData.triggerData[2])
            local artifactIndex = math.tointeger(syncData.triggerData[3])
            local whichPlayer   = syncData.triggerPlayer
            if htime.setupAndCheckCoolDown(
                    whichPlayer,
                    "tryjihuosqtianfu",
                    1
                ) then
                hartifact.tryActivateTalent(whichPlayer, artifactIndex, i, j)
            else
                sysecho("冷却时间未到", whichPlayer)
            end
        end
    )
    hsync.onSend(
        "trydisablesqtianfu",
        function(syncData)
            local i = math.tointeger(syncData.triggerData[1])
            local j = math.tointeger(syncData.triggerData[2])
            local artifactIndex = math.tointeger(syncData.triggerData[3])
            local whichPlayer = syncData.triggerPlayer
            if htime.setupAndCheckCoolDown(
                    whichPlayer,
                    "trydisablesqtianfucd",
                    1
                ) then
                hartifact.tryRemoveTalent(whichPlayer, artifactIndex, i, j)
            else
                sysecho("冷却时间未到", whichPlayer)
            end
        end
    )
end

function hartifact.switchPage(whichPlayer, artifactIndex)
    UI_global_active_artifact_index = artifactIndex
    hartifact.refreshUI(whichPlayer)
end

function hartifact.refreshUI(whichPlayer)
    if whichPlayer ~= hplayer.loc() then return end
    local artifact = hartifact[whichPlayer][UI_global_active_artifact_index]
    local artifactTotalExp = artifact.totalExp
    local artifactExp = artifactTotalExp - hartifact.recalculateTotalExpConsumption(artifact)
    local artifactExpText = artifactExp
    local artifactTalents = artifact.talentTree
    local remainingExp = math.max(0, artifact.maxTotalExp - artifactTotalExp)
    hjapi.DzFrameSetText(UI_global_sqtianfu["sqnengliang"],
        "神器能量：" ..
        hcolor.jinglianglan(tostring(artifactExpText)) .. " 今日还可获取：" .. hcolor.jinglianglan(tostring(remainingExp)))
    hjapi.DzFrameSetText(UI_global_sqtianfu["sqmingzi"], hcolor.yellow(artifact.name))
    hjapi.DzFrameSetTexture(UI_global_sqtianfu["sqart"], artifact.art)
    if artifact.isEquipped then
        hjapi.DzFrameSetTexture(UI_global_sqtianfu["sqzhuangbeiback"], "UI\\anniu_xiexia.tga")
    else
        hjapi.DzFrameSetTexture(UI_global_sqtianfu["sqzhuangbeiback"], "UI\\anniu_zhuangbei.tga")
    end
    for i = 1, 2 do
        for j = 1, 9 do
            local talentBack = UI_global_sqtianfu["tianfuback" .. i .. "|" .. j]
            local talentFrame = UI_global_sqtianfu["tianfuframe" .. i .. "|" .. j]
            local talentMast = UI_global_sqtianfu["tianfumask" .. i .. "|" .. j]
            if artifactTalents[i] ~= nil and artifactTalents[i][j] ~= nil then
                local talent = artifactTalents[i][j]
                hjapi.DzFrameSetTexture(talentBack, talent.art)
                hjapi.DzFrameShow(talentBack, true)
                if talent.isElite then
                    hjapi.DzFrameShow(talentFrame, true)
                else
                    hjapi.DzFrameShow(talentFrame, false)
                end
                if talent.activeLevel > 0 then
                    hjapi.DzFrameShow(talentMast, false)
                else
                    hjapi.DzFrameShow(talentMast, true)
                end
            else
                hjapi.DzFrameShow(talentBack, false)
                hjapi.DzFrameShow(talentFrame, false)
            end
        end
    end
    hjapi.DzFrameShow(UI_global_sqtianfu["main"], true)
end

hartifact.shuasqnl = function(whichPlayer)
    if not whichPlayer or not hplayer.isPlaying(whichPlayer) then
        return
    end
    local artifact = hartifact[whichPlayer][UI_global_active_artifact_index]
    artifact.totalExp = 6000000
end

--  指定用户获得神器能量
hartifact.huodeSQNL = function(whichPlayer, volume)
    if not whichPlayer or not hplayer.isPlaying(whichPlayer) then
        return
    end

    local equippedArtifact = nil
    -- 找到装备的神器
    for _, artifact in ipairs(hartifact[whichPlayer]) do
        if artifact.isEquipped then
            equippedArtifact = artifact
            break
        end
    end

    -- 如果没有装备的神器，直接返回
    if not equippedArtifact then
        sysecho("没有装备神器，无法获得神器能量", whichPlayer)
        return
    end

    local currentExp = equippedArtifact.totalExp
    local maxExp = equippedArtifact.maxTotalExp

    local sqnl_huoqu = hattr.getWithLimit(hplayer.getMainHero(whichPlayer), nil, "sqnl_huoqu", 0)
    volume = math.floor(volume * (1 + sqnl_huoqu / 100))
    -- 计算可以获得的能量（考虑日常上限）
    local gainableExp = math.min(volume, maxExp - currentExp)
    if gainableExp <= 0 then
        sysecho(equippedArtifact.name .. " 的神器能量已达到今日上限", whichPlayer)
        return
    end

    -- 更新神器能量
    equippedArtifact.totalExp = currentExp + gainableExp
    hartifact.saveCundang(whichPlayer, equippedArtifact)
    -- 刷新UI（如果是当前玩家）
    if whichPlayer == hplayer.loc() and UI_global_active_artifact_index and hjapi.DzFrameIsVisible(UI_global_sqtianfu["main"]) then
        hartifact.refreshUI(whichPlayer)
    end
    -- 通知玩家
    sysecho(hcolor.yellow(equippedArtifact.name) .. " 获得了 " .. hcolor.jinglianglan(tostring(gainableExp)) .. " 点神器能量",
        whichPlayer)
end
