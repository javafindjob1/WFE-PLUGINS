for i = 1, 45, 1 do
    ITEM_LEVEL_TO_EQUIP_REQ_DITULEVEL[i] = 1
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i] = {}
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.PUTONG] = 0
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.YINGXIONG] = 0
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.SHISHI] = 0
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.CHUANQI] = 0
end
for i = 46, 55, 1 do
    ITEM_LEVEL_TO_EQUIP_REQ_DITULEVEL[i] = 1
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i] = {}
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.PUTONG] = 0
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.YINGXIONG] = 0
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.SHISHI] = 0
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.CHUANQI] = 0
end
for i = 56, 60, 1 do
    ITEM_LEVEL_TO_EQUIP_REQ_DITULEVEL[i] = 1
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i] = {}
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.PUTONG] = 0
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.YINGXIONG] = 0
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.SHISHI] = 0
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.CHUANQI] = 0
end
for i = 61, 69, 1 do
    ITEM_LEVEL_TO_EQUIP_REQ_DITULEVEL[i] = 1
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i] = {}
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.PUTONG] = 0
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.YINGXIONG] = 0
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.SHISHI] = 0
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.CHUANQI] = 0
end
for i = 70, 80, 1 do
    ITEM_LEVEL_TO_EQUIP_REQ_DITULEVEL[i] = 5
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i] = {}
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.PUTONG] = 0
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.YINGXIONG] = 0
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.SHISHI] = 5
    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[i][FUBEN_NANDU.CHUANQI] = 0
end

-- 穿戴装备函数
function init_zhuangbei(whichUnit)
    hevent.onItemUsed(whichUnit, function(evtData)
        if evtData.triggerSkill ~= nil and hskill.getName(evtData.triggerSkill) == "装备使用" and
            evtData.triggerItem ~= nil then
            if hfightzhuangtai.isInFight(whichUnit) then
                echo("战斗状态中不能更换装备", hunit.getOwner(whichUnit))
                return
            end
            if hcache.get(hunit.getOwner(whichUnit), "disablezhuangbei", false) then
                echo("当前状态不能更换装备", hunit.getOwner(whichUnit))
                return
            end
            hplayer.equipItem(hunit.getOwner(evtData.triggerUnit), evtData.triggerItem)
        end
    end)

    -- 修正饰品CD以及触发饰品特效
    hevent.register(whichUnit, CONST_EVENT.skillStop, function(evtData)
        if evtData.triggerSkill == nil or hskill.getName(evtData.triggerSkill) ~= "饰品主动技能" then
            return
        end
        local whichPlayer = hunit.getOwner(whichUnit)
        if hplayer.dzCunDang[whichPlayer] ~= nil and
            hplayer.dzCunDang[whichPlayer].getEquipment(EQUIPMENT_SLOT_ID.shipin) ~= nil then
            local dynamicItem = hplayer.dzCunDang[whichPlayer].getEquipment(EQUIPMENT_SLOT_ID.shipin)
            local skills = hslk.i2v(dynamicItem.basic_item_id, "equipped_skill")
            if skills == nil then
                return
            end
            for i, skill in ipairs(skills) do
                if skill.cd ~= nil then
                    hskill.setCoolDown(whichUnit, c2i(hslk.n2i("饰品主动技能")), skill.cd)
                end
            end
            return
        end
    end)
end

-- 初始化套装属性

local data = {}
data[2] = {
    description = "增加攻击速度20",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        attack_speed = "+20"
    })
}
data[3] = {
    description = "获得新手之力攻击20%概率触发攻击力100%伤害",
    attr_type = CONST_EVENT.damage,
    attr = function(evtData)
        echo("新手之力三件套攻击触发")
    end
}

hitem.addTaozhuangShuxing("新手套装", data)

local data = {}
data[2] = {
    description = "获得法师之力受到伤害20%概率对周围造成智力100%伤害",
    attr_type = CONST_EVENT.beDamage,
    attr = function(evtData)
        echo("法师之力二件套受伤触发")
    end
}
data[3] = {
    description = "获得大法师之力施法20%概率触发攻击力100%智力伤害",
    attr_type = CONST_EVENT.skillCast,
    attr = function(evtData)
        echo("大法师之力施法触发")
    end
}
hitem.addTaozhuangShuxing("新手法师套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "赋予穿戴者如森林狼般的勇猛之力，增加10%攻击速度和200点最大生命值。",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        attack_speed = "+10",
        life = "+200"
    })
}
hitem.addTaozhuangShuxing("森林屠戮者", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "生命最大值+200",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        life = "+200"
    })
}
data[3] = {
    description = "生命值恢复速度+10",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        life_back = "+10"
    })
}
data[4] = {
    description = "物理和法术暴击概率加1%",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        wu_bao = "+1",
        fa_bao = "+1"
    })
}
data[5] = {
    description = "蓝影之力，受到月亮湖魔物的伤害降低15%",
    attr_type = CONST_EVENT.damagingCustomTarget,
    attr = function(evtData)
        local sourceUnit = evtData.sourceUnit
        local sourceUnitRect = hunit.getRect(sourceUnit)
        if sourceUnitRect ~= nil and hrect.getName(sourceUnitRect) == "月亮湖" then
            evtData.damage = evtData.damage * 0.85
        end
    end
}
hitem.addTaozhuangShuxing("蓝影套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "生命最大值+250",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        life = "+250"
    })
}
data[3] = {
    description = "生命值恢复速度+12",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        life_back = "+12"
    })
}
data[4] = {
    description = "经验提高5%",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        exp_ratio = "+5"
    })
}
data[5] = {
    description = "血色军的意志，受到血色军意志的鼓舞，造成伤害有概率鼓舞周围友军，使其攻击速度和施法速度提高5%，持续8秒，cd 20秒。",
    attr_type = CONST_EVENT.damage,
    attr = function(evtData)
        if htime.setupAndCheckCoolDown(evtData.triggerUnit, "血色军鼓舞", 20) then
            heffect.attach("Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl", evtData.triggerUnit, "head", 0)
            hgroup.forEach(hgroup.createAllyGroupByUnit(evtData.triggerUnit, 600), function(enumUnit, idx)
                hbuff.update(8, enumUnit, "血色鼓舞", true, function()
                        hattribute.set(enumUnit, 0, {
                            attack_speed = "+5",
                            skill_speed = "+5"
                        })
                    end, function()
                        hattribute.set(enumUnit, 0, {
                            attack_speed = "-5",
                            skill_speed = "-5"
                        })
                    end, "ReplaceableTextures\\KUANGRE\\PASKUANGRE.blp",
                    "血色军的意志鼓舞了你，攻击速度和施法速度提高5%", 1, nil, nil, nil, nil,
                    HBUFF_UPDATE_MODE.UPDATE, true)
            end)
        end
    end
}
hitem.addTaozhuangShuxing("血色军套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "造成直接伤害时有5%的概率触发光明冲击，暗影冲击或者无限冲击，对目标（无限冲击为目标周围300码范围所有单位）造成150%主属性的魔法伤害，内置cd10秒",
    attr_type = CONST_EVENT.damage,
    attr = function(evtData)
        if math.random(1, 100) <= 100 then
            if htime.setupAndCheckCoolDown(evtData.triggerUnit, "光暗交织", 10) then
                local sourceUnit = evtData.triggerUnit
                local damage = 1.5 * hunit.getZhushuxing(sourceUnit)
                if math.random(1, 100) <= 20 then
                    hskillMoban.radiusAOE(hunit.x(evtData.targetUnit), hunit.y(evtData.targetUnit), sourceUnit, 300,
                        function(unit)
                            local effect = "[jineng]guangmingchongji.mdx"
                            local damageElementType = CONST_DAMAGE_ELEMENT_TYPE.LIGHT
                            if math.random(1, 2) == 1 then
                                effect = "[jineng]anyingchongji.mdx"
                                damageElementType = CONST_DAMAGE_ELEMENT_TYPE.DARK
                            end
                            hskillMoban.missile({
                                model = effect,
                                scale = 1.0,
                                speed = 1000,
                                hover = 50,
                                sourceUnit = sourceUnit,
                                targetUnit = unit,
                                target_face_dis = 50,
                                onEnd = function(_, _, endX, endY)
                                    hskill.damage({
                                        sourceUnit = sourceUnit,
                                        targetUnit = unit,
                                        damage = damage,
                                        damageSrc = CONST_DAMAGE_SRC.skill,
                                        damageType = DAMAGE_TYPE.MOFA,
                                        triggerSkill = hslk.n2i("装备技能"),
                                        damageElementType = damageElementType,
                                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                        shanghainame = "光暗交织"
                                    })
                                end
                            })
                        end)
                else
                    local effect = "[jineng]guangmingchongji.mdx"
                    local damageElementType = CONST_DAMAGE_ELEMENT_TYPE.LIGHT
                    if math.random(1, 2) == 1 then
                        effect = "[jineng]anyingchongji.mdx"
                        damageElementType = CONST_DAMAGE_ELEMENT_TYPE.DARK
                    end
                    hskillMoban.missile({
                        model = effect,
                        scale = 1.0,
                        speed = 1000,
                        hover = 50,
                        sourceUnit = sourceUnit,
                        targetUnit = evtData.targetUnit,
                        target_face_dis = 50,
                        onEnd = function(_, _, endX, endY)
                            hskill.damage({
                                sourceUnit = sourceUnit,
                                targetUnit = evtData.targetUnit,
                                damage = damage,
                                damageSrc = CONST_DAMAGE_SRC.skill,
                                damageType = DAMAGE_TYPE.MOFA,
                                triggerSkill = hslk.n2i("装备技能"),
                                damageElementType = damageElementType,
                                damageSpeedType = CONST_DAMAGE_SPEED_TYPE.IMMEDIATE,
                                shanghainame = "光暗交织"
                            })
                        end
                    })
                end
            end
        end
    end
}
hitem.addTaozhuangShuxing("光暗交织", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "生命最大值+500，生命恢复提高20点",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        life = "+500",
        life_back = "+20"
    })
}
data[3] = {
    description = "狂暴战英勇打击消耗怒气降低1点。武器战普通攻击额外恢复2点怒气。惩戒骑获得神圣愤怒时会恢复3点魔法"
}
data[4] = {
    description = "狂暴战英勇打击伤害提高10%。武器战撕裂的伤害提高50%，并且造成伤害时会恢复3%最大生命值。惩戒骑殉难圣印附加伤害提高30%"
}
hitem.addTaozhuangShuxing("[T1]无畏勇士套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "法术暴击+1%",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        fa_bao = "+1"
    })
}
data[3] = {
    description = "火法炎爆术消耗魔法减1。毁灭术灵魂导管概率提高5%。痛苦术痛苦献祭伤害提高20%。愤怒的魔法消耗降低1点。"
}
data[4] = {
    description = "火法消耗炽热连击会获得一个持续20秒的buff，法术暴击提高1%，可以叠加3次。毁灭术混乱之箭伤害提高10%。痛苦术痛苦诅咒伤害加8%，持续时间增加3秒。星火术伤害提高10%"
}
hitem.addTaozhuangShuxing("[T1]灵力波动套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "攻击速度+5%，能量回复速度+5%",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        attack_speed = "+5",
        energy_back = "+5"
    })
}
data[3] = {
    description = "盗贼魔法斗篷还会使盗贼闪避提高25%，猎人基础射击能量恢复提高0.5每次攻击，每隔10秒，使用邪能冲撞不会进入cd"
}
data[4] = {
    description = "盗贼破击伤害增加20%，猎人瞄准射击的有15%的概率触发爆头，造成双倍伤害，势如破竹的增伤效果提高10%"
}
hitem.addTaozhuangShuxing("[T1]猎杀者套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "提高20点生命恢复速度",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        life_back = "+20"
    })
}
data[3] = {
    description = "提高5%的攻击速度和3%的施法速度",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        attack_speed = "+5",
        skill_speed = "+3"
    })
}
data[4] = {
    description = "提高主属性75",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        zhushuxing = "+75"
    })
}
hitem.addTaozhuangShuxing("野蛮斗士套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "提高30点生命恢复速度",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        life_back = "+30"
    })
}
data[3] = {
    description = "提高8%的攻击速度和4%的施法速度",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        attack_speed = "+8",
        skill_speed = "+4"
    })
}
data[4] = {
    description = "提高主属性100",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        zhushuxing = "+100"
    })
}
hitem.addTaozhuangShuxing("冠军斗士套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "造成魔法伤害有30%的概率触发灼热岩浆，在目标脚下召唤一个岩浆，持续5秒，每秒对400范围内的目标造成100%主属性的魔法伤害，冷却时间30秒。",
    attr_type = CONST_EVENT.damage,
    attr = function(evtData)
        if evtData.damageType == DAMAGE_TYPE.MOFA and math.random(1, 100) <= 30 and
            htime.setupAndCheckCoolDown(evtData.triggerUnit, "炎魔之力", 30) then
            local x = hunit.x(evtData.targetUnit)
            local y = hunit.y(evtData.targetUnit)
            local size = 400
            local scale = size / 400 * 3.4
            local e = heffect.xyz("war3mapImported\\[spell]rongyanhuoyan22.mdx", x, y, hunit.z(evtData.targetUnit), 30,
                1, scale, scale, 1)
            htime.setInterval(1, function(curTimer)
                if curTimer.passedSec() >= 5 then
                    curTimer.destroy()
                    heffect.destroy(e)
                    return
                end
                local damage = hunit.getZhushuxing(evtData.triggerUnit)
                hskillMoban.radiusAOE(x, y, evtData.triggerUnit, size, function(targetUnit)
                    hskill.damage({
                        sourceUnit = evtData.triggerUnit,
                        targetUnit = targetUnit,
                        damage = damage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = hslk.n2i("装备技能"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                        shanghainame = "炎魔之力"
                    })
                end)
            end)
        end
    end
}
hitem.addTaozhuangShuxing("炎魔之力", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "造成物理伤害有30%的概率进入迅击状态，持续8秒，攻击速度提高10%, 物理穿透提高5%，冷却时间30秒",
    attr_type = CONST_EVENT.damage,
    attr = function(evtData)
        if evtData.damageType == DAMAGE_TYPE.WULI and math.random(1, 100) <= 30 and
            htime.setupAndCheckCoolDown(evtData.triggerUnit, "迅击套装", 30) then
            hbuff.update(8, evtData.triggerUnit, "迅击状态", true, function()
                    hattr.set(evtData.triggerUnit, 0, {
                        attack_speed = "+10",
                        wu_chuan = "+5"
                    })
                end, function()
                    hattr.set(evtData.triggerUnit, 0, {
                        attack_speed = "-10",
                        wu_chuan = "-5"
                    })
                end, "ReplaceableTextures\\zhuangbei\\INV_Jewelry_Ring_14.blp",
                "迅击状态，攻击速度提高10%,物理穿透提高5%", nil, nil, nil, nil, nil,
                HBUFF_UPDATE_MODE.OVERWRITE, true)
        end
    end
}
hitem.addTaozhuangShuxing("迅击套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "造成魔法伤害有30%的概率触发灼热岩浆，在目标脚下召唤一个岩浆，持续5秒，每秒对400范围内的目标造成150%主属性的魔法伤害，冷却时间30秒。",
    attr_type = CONST_EVENT.damage,
    attr = function(evtData)
        if evtData.damageType == DAMAGE_TYPE.MOFA and math.random(1, 100) <= 30 and
            htime.setupAndCheckCoolDown(evtData.triggerUnit, "炎魔之力", 30) then
            local x = hunit.x(evtData.targetUnit)
            local y = hunit.y(evtData.targetUnit)
            local size = 400
            local scale = size / 400 * 3.4
            local e = heffect.xyz("war3mapImported\\[spell]rongyanhuoyan22.mdx", x, y, hunit.z(evtData.targetUnit), 30,
                1, scale, scale, 1)
            htime.setInterval(1, function(curTimer)
                if curTimer.passedSec() >= 5 then
                    curTimer.destroy()
                    heffect.destroy(e)
                    return
                end
                local damage = hunit.getZhushuxing(evtData.triggerUnit) * 1.5
                hskillMoban.radiusAOE(x, y, evtData.triggerUnit, size, function(targetUnit)
                    hskill.damage({
                        sourceUnit = evtData.triggerUnit,
                        targetUnit = targetUnit,
                        damage = damage,
                        damageSrc = CONST_DAMAGE_SRC.skill,
                        damageType = DAMAGE_TYPE.MOFA,
                        triggerSkill = hslk.n2i("装备技能"),
                        damageElementType = { CONST_DAMAGE_ELEMENT_TYPE.FIRE },
                        damageSpeedType = CONST_DAMAGE_SPEED_TYPE.DOT,
                        shanghainame = "炎魔之力"
                    })
                end)
            end)
        end
    end
}
hitem.addTaozhuangShuxing("强化炎魔之力", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "造成物理伤害有30%的概率进入迅击状态，持续8秒，攻击速度提高15%, 物理穿透提高10%，冷却时间30秒",
    attr_type = CONST_EVENT.damage,
    attr = function(evtData)
        if evtData.damageType == DAMAGE_TYPE.WULI and math.random(1, 100) <= 30 and
            htime.setupAndCheckCoolDown(evtData.triggerUnit, "迅击套装", 30) then
            hbuff.update(8, evtData.triggerUnit, "迅击状态", true, function()
                    hattr.set(evtData.triggerUnit, 0, {
                        attack_speed = "+15",
                        wu_chuan = "+10"
                    })
                end, function()
                    hattr.set(evtData.triggerUnit, 0, {
                        attack_speed = "-15",
                        wu_chuan = "-10"
                    })
                end, "ReplaceableTextures\\zhuangbei\\INV_Jewelry_Ring_14.blp",
                "迅击状态，攻击速度提高15%,物理穿透提高10%", nil, nil, nil, nil, nil,
                HBUFF_UPDATE_MODE.OVERWRITE, true)
        end
    end
}
hitem.addTaozhuangShuxing("强化迅击套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "生命最大值+1000，生命恢复提高50点",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        life = "+1000",
        life_back = "+50"
    })
}
data[3] = {
    description = "审判CD降低2秒，冲锋CD降低2秒，嗜血CD降低3秒"
}
data[4] = {
    description = "神圣风暴伤害提高50%，顺劈斩伤害提高50%，旋风斩伤害提高100%"
}
hitem.addTaozhuangShuxing("[T2]熔铸勇士套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "法术暴击+2%",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        fa_bao = "+2"
    })
}
data[3] = {
    description = "火凤凰的伤害提高30%，痛苦诅咒最大堆叠数量+2层，烧尽的伤害提高30%，使用群星坠落会对周围所有单位释放月火术。"
}
data[4] = {
    description = "火球术的伤害提高30%，腐蚀术的伤害提高20%，爆燃的冷却时间降低2秒，每次被动触发的坠星会使群星坠落CD降低1秒（剩余CD低于30秒时无效）。"
}
hitem.addTaozhuangShuxing("[T2]炎灵套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "精通+15，能量回复速度+10%",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        master = "+15",
        energy_back = "+10"
    })
}
data[3] = {
    description = "毒蛇钉刺造成伤害时回复2点能量，影袭消耗降低4点，刃舞cd降低2秒。"
}
data[4] = {
    description = "奥术射击魔法消耗降低5点，伤害提高10%，杀戮盛宴伤害提高30%，刃舞的伤害提高10%。"
}
hitem.addTaozhuangShuxing("[T2]追猎者套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "提高3%命中",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        hit = "+3"
    })
}
data[3] = {
    description = "提高0.5%的物理和魔法暴击",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        wu_bao = "+0.5",
        fa_bao = "+0.5"
    })
}
data[4] = {
    description = "提高150点攻击力和150点主属性",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        zhushuxing = "+150",
        attack_white = "+150"
    })
}
hitem.addTaozhuangShuxing("纷争勇士套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "提高5%物理穿透，8%物理暴击伤害",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        wu_chuan = "+5",
        wu_baoshang = "+8"
    })
}
data[3] = {
    description = "圣殿裁决伤害提升4%，旋风斩增益buff额外获得一层，雷霆一击CD降低2秒"
}
data[4] = {
    description = "圣殿裁决触发连击概率提升5%，怒击刷新提高5%，致死打击给予斩杀的增伤效果每层提高6%"
}
hitem.addTaozhuangShuxing("[T3]无畏战将套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "提高30点精通和8%攻击加速",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        master = "+30",
        attack_speed = "+8"
    })
}
data[3] = {
    description = "瞄准射击伤害提升4%，剑刃飞舞的CD降低10秒，提升混乱打击4%伤害。"
}
data[4] = {
    description = "快速射击的伤害提高10%，割裂造成的伤害可以恢复2点能量，势如破竹的持续时间增加4秒"
}
hitem.addTaozhuangShuxing("[T3]暗影猎手套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "提高30点精通和4%技能加速",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        master = "+30",
        skill_speed = "+4"
    })
}
data[3] = {
    description = "烈焰宝珠伤害提升10%，愤怒伤害提升10%，牺牲魔典伤害提升10%，黑眼射线伤害提升10%。"
}
data[4] = {
    description = "烈焰宝珠攻击频率提高30%，星火术伤害提高10%，牺牲魔典的触发概率提高5%，黑眼射线伤害有10%获得一颗灵魂之种。"
}
hitem.addTaozhuangShuxing("[T3]高阶法师套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        jianshang = "+3",
        life = "+2500",
        defend_white = "+100",
        attack_speed = "+10",
    })
}
data[3] = {
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        jianshang = "+4",
        wu_bao = "+5",
        fa_bao = "+3",
        hit = "+5",
    })
}
data[4] = {
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        jianshang = "+5",
        wu_zengshang = "+5",
        fa_zengshang = "+3",
        str_baifenbi = "+5",
    })
}
hitem.addTaozhuangShuxing("[T4]秩序守护者套装", data) -- set trigger for 套装
local data = {}
data[2] = {
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        jianshang = "+3",
        attack_speed = "+15",
        skill_speed = "+10",
    })
}
data[3] = {
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        jianshang = "+4",
        wu_bao = "+4",
        fa_bao = "+4",
        hit = "+5",
    })
}
data[4] = {
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        jianshang = "+5",
        wu_zengshang = "+4",
        fa_zengshang = "+4",
        agi_baifenbi = "+5",
    })
}
hitem.addTaozhuangShuxing("[T4]晨曦游侠套装", data) -- set trigger for 套装
local data = {}
data[2] = {
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        jianshang = "+3",
        skill_speed = "+15",
    })
}
data[3] = {
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        jianshang = "+4",
        fa_bao = "+5",
        hit = "+5",
    })
}
data[4] = {
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        jianshang = "+5",
        fa_zengshang = "+6",
        int_baifenbi = "+5",
    })
}
hitem.addTaozhuangShuxing("[T4]风暴术士套装", data) -- set trigger for 套装

local data = {}
data[2] = {
    description = "提高4%命中",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        hit = "+4"
    })
}
data[3] = {
    description = "提高1%的物理和魔法暴击",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        wu_bao = "+1",
        fa_bao = "+1"
    })
}
data[4] = {
    description = "提高200点攻击力和200点主属性",
    attr_type = CONST_EVENT.attr,
    attr = _attr({
        zhushuxing = "+200",
        attack_white = "+200"
    })
}
hitem.addTaozhuangShuxing("光荣套装", data) -- set trigger for 套装

local data = {}
data[2] = {

    description = "恶魔之力：恶魔变身状态下额外提高10%造成的所有伤害，同时增加破击，混乱打击和暴怒8%的伤害。",
    attr_type = CONST_EVENT.damagingCustomSource,
    attr = function(evtData)
        if hbuff.hasBuff(evtData.sourceUnit, "恶魔变形") then
            evtData.damage = evtData.damage * 1.1
        end
        if evtData.triggerSkill == hslk.n2i("破击") or evtData.triggerSkill == hslk.n2i("混乱打击") or evtData.triggerSkill == hslk.n2i("暴怒") then
            evtData.damage = evtData.damage * 1.08
        end
    end
}
hitem.addTaozhuangShuxing("恶魔战刃", data) -- set trigger for 套装

local wuli_wuqi_general_citiao = { "zhaojia", "wu_baoshang", "wu_chuan", "wu_zengshang", "zhushuxing_baifenbi",
    "gongji_baifenbi", "attack_speed", "hit" }

local fashu_wuqi_general_citiao = { "fa_baoshang", "fa_chuan", "fa_zengshang", "zhushuxing_baifenbi", "attack_speed",
    "skill_speed", "hit" }

--- 配置物品词条以及基础属性

EQUIPMENT_TYPE_BASIC_ATTR["鱼竿"] = {
    zhushuxing = 1
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["鱼竿"] = wuli_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["单手锤"] = {
    zhushuxing = 2,
    attack_white = 24
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["单手锤"] = wuli_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["单手斧"] = {
    zhushuxing = 3,
    attack_white = 23
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["单手斧"] = wuli_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["单手剑"] = {
    zhushuxing = 4,
    attack_white = 22
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["单手剑"] = wuli_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["法剑"] = {
    zhushuxing = 15
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["法剑"] = fashu_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["匕首"] = {
    zhushuxing = 5,
    attack_white = 21
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["匕首"] = wuli_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["拳套"] = {
    zhushuxing = 6,
    attack_white = 20
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["拳套"] = wuli_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["双手锤"] = {
    zhushuxing = 3,
    attack_white = 26
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["双手锤"] = wuli_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["双手斧"] = {
    zhushuxing = 4,
    attack_white = 25
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["双手斧"] = wuli_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["双手剑"] = {
    zhushuxing = 5,
    attack_white = 24
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["双手剑"] = wuli_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["弓"] = {
    zhushuxing = 7,
    attack_white = 26
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["弓"] = wuli_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["箭袋"] = {
    zhushuxing = 1
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["箭袋"] = wuli_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["武器链"] = {
    zhushuxing = 1
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["武器链"] = wuli_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["圣契"] = {
    zhushuxing = 1
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["圣契"] = wuli_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["法杖"] = {
    zhushuxing = 17
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["法杖"] = fashu_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["法器"] = {
    zhushuxing = 1
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["法器"] = fashu_wuqi_general_citiao

EQUIPMENT_TYPE_BASIC_ATTR["头盔"] = {
    life = 30,
    defend_white = 1,
    life_back = 1
}
EQUIPMENT_TYPE_MAX_ATTR["头盔"] = {
    defend_white = 60
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["头盔"] = { "life_back", "jianshang", "mokang", "zhushuxing_baifenbi",
    "shengming_baifenbi", "defend_white", "shanbi" }

EQUIPMENT_TYPE_BASIC_ATTR["衣服"] = {
    life = 40,
    defend_white = 2,
    life_back = 1
}
EQUIPMENT_TYPE_MAX_ATTR["衣服"] = {
    defend_white = 120
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["衣服"] = { "life_back", "jianshang", "mokang", "defend_white", "zhushuxing_baifenbi",
    "shengming_baifenbi", "shanbi" }

EQUIPMENT_TYPE_BASIC_ATTR["手套"] = {
    life = 20,
    zhushuxing = 2,
    defend_white = 1
}
EQUIPMENT_TYPE_MAX_ATTR["手套"] = {
    defend_white = 60
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["手套"] = { "wu_bao", "fa_bao", "energy_back", "attack_speed", "skill_speed",
    "zhushuxing_baifenbi", "master" }

EQUIPMENT_TYPE_BASIC_ATTR["鞋子"] = {
    life = 20,
    zhushuxing = 2,
    defend_white = 1,
    move = 10
}
EQUIPMENT_TYPE_MAX_ATTR["鞋子"] = {
    defend_white = 60,
    move = 25
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["鞋子"] = { "life_back", "jianshang", "mokang", "zhushuxing_baifenbi",
    "shengming_baifenbi", "shanbi", "defend_white", "move" }

EQUIPMENT_TYPE_BASIC_ATTR["披风"] = {
    zhushuxing = 2,
    defend_white = 0.5
}
EQUIPMENT_TYPE_MAX_ATTR["披风"] = {
    defend_white = 30
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["披风"] = { "life_back", "jianshang", "mokang", "zhushuxing_baifenbi",
    "shengming_baifenbi", "shanbi", "defend_white" }

EQUIPMENT_TYPE_BASIC_ATTR["戒指"] = {
    zhushuxing = 2
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["戒指"] = { "wu_bao", "wu_baoshang", "fa_bao", "fa_baoshang", "energy_back",
    "attack_speed", "skill_speed", "zhushuxing_baifenbi", "shengming_baifenbi",
    "master", "hit" }

EQUIPMENT_TYPE_BASIC_ATTR["项链"] = {
    zhushuxing = 3
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["项链"] = { "wu_bao", "wu_baoshang", "fa_bao", "fa_baoshang", "quanju_zengshang",
    "energy_back", "attack_speed", "skill_speed", "zhushuxing_baifenbi",
    "shengming_baifenbi", "master", "hit" }

EQUIPMENT_TYPE_BASIC_ATTR["饰品"] = {
    zhushuxing = 1
}
EQUIPMENT_TYPE_TO_CITIAO_TYPE["饰品"] = { "wu_bao", "wu_baoshang", "fa_bao", "fa_baoshang", "quanju_zengshang",
    "energy_back", "attack_speed", "skill_speed", "zhushuxing_baifenbi",
    "shengming_baifenbi", "master", "hit" }

--- 配置物品等级对装备基础属性影响
EQUIPMENT_LEVEL_TO_BASIC_ATTR_MULTI[1] = 1

for i = 2, 60, 1 do
    EQUIPMENT_LEVEL_TO_BASIC_ATTR_MULTI[i] = EQUIPMENT_LEVEL_TO_BASIC_ATTR_MULTI[i - 1] * 1.06
end
for i = 61, 70, 1 do
    EQUIPMENT_LEVEL_TO_BASIC_ATTR_MULTI[i] = EQUIPMENT_LEVEL_TO_BASIC_ATTR_MULTI[i - 1] * 1.071
end
EQUIPMENT_LEVEL_TO_BASIC_ATTR_MULTI[71] = EQUIPMENT_LEVEL_TO_BASIC_ATTR_MULTI[70] * 1.1
EQUIPMENT_LEVEL_TO_BASIC_ATTR_MULTI[72] = EQUIPMENT_LEVEL_TO_BASIC_ATTR_MULTI[71] * 1.1
EQUIPMENT_LEVEL_TO_BASIC_ATTR_MULTI[73] = EQUIPMENT_LEVEL_TO_BASIC_ATTR_MULTI[72] * 1.1

--- 配置物品等级对装备随机词条属性影响
EQUIPMENT_LEVEL_TO_CITIAO_MULTI[1] = 1
for i = 2, 60, 1 do
    EQUIPMENT_LEVEL_TO_CITIAO_MULTI[i] = EQUIPMENT_LEVEL_TO_CITIAO_MULTI[i - 1] * 1.01
end
for i = 61, 69, 1 do
    EQUIPMENT_LEVEL_TO_CITIAO_MULTI[i] = EQUIPMENT_LEVEL_TO_CITIAO_MULTI[i - 1] * 1.008
end
EQUIPMENT_LEVEL_TO_CITIAO_MULTI[70] = EQUIPMENT_LEVEL_TO_CITIAO_MULTI[69] * 1.02
EQUIPMENT_LEVEL_TO_CITIAO_MULTI[71] = EQUIPMENT_LEVEL_TO_CITIAO_MULTI[70] * 1.01
EQUIPMENT_LEVEL_TO_CITIAO_MULTI[72] = EQUIPMENT_LEVEL_TO_CITIAO_MULTI[71] * 1.01
EQUIPMENT_LEVEL_TO_CITIAO_MULTI[73] = EQUIPMENT_LEVEL_TO_CITIAO_MULTI[72] * 1.01

--- 配置怪物等级对应掉落装备物品等级
--- 需要在游戏文件定义

for i = 1, 1000, 1 do
    MONSTER_LEVEL_TO_ITEM_LEVEL[i] = i
end
