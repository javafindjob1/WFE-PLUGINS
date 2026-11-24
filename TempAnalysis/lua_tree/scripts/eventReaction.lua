-- 事件反应

hmodelTag.char("0", "war3mapImported\\1wlshanghai0.mdx", 1.9)
hmodelTag.char("1", "war3mapImported\\1wlshanghai1.mdx", 1.8)
hmodelTag.char("2", "war3mapImported\\1wlshanghai2.mdx", 1.8)
hmodelTag.char("3", "war3mapImported\\1wlshanghai3.mdx", 1.8)
hmodelTag.char("4", "war3mapImported\\1wlshanghai4.mdx", 1.8)
hmodelTag.char("5", "war3mapImported\\1wlshanghai5.mdx", 1.8)
hmodelTag.char("6", "war3mapImported\\1wlshanghai6.mdx", 1.8)
hmodelTag.char("7", "war3mapImported\\1wlshanghai7.mdx", 1.8)
hmodelTag.char("8", "war3mapImported\\1wlshanghai8.mdx", 1.8)
hmodelTag.char("9", "war3mapImported\\1wlshanghai9.mdx", 1.8)
hmodelTag.char("+", "hLua\\ttg\\s_jia.mdl", 1.7)
hmodelTag.char("-", "hLua\\ttg\\s_jian.mdl", 1.7)

local wuli_shanghai = {}
wuli_shanghai["0"] = "war3mapImported\\1wlshanghai0.mdx"
wuli_shanghai["1"] = "war3mapImported\\1wlshanghai1.mdx"
wuli_shanghai["2"] = "war3mapImported\\1wlshanghai2.mdx"
wuli_shanghai["3"] = "war3mapImported\\1wlshanghai3.mdx"
wuli_shanghai["4"] = "war3mapImported\\1wlshanghai4.mdx"
wuli_shanghai["5"] = "war3mapImported\\1wlshanghai5.mdx"
wuli_shanghai["6"] = "war3mapImported\\1wlshanghai6.mdx"
wuli_shanghai["7"] = "war3mapImported\\1wlshanghai7.mdx"
wuli_shanghai["8"] = "war3mapImported\\1wlshanghai8.mdx"
wuli_shanghai["9"] = "war3mapImported\\1wlshanghai9.mdx"

local wuli_baoji_shanghai = {}
wuli_baoji_shanghai["0"] = "war3mapImported\\Bshanghaibaoji0.mdx"
wuli_baoji_shanghai["1"] = "war3mapImported\\Bshanghaibaoji1.mdx"
wuli_baoji_shanghai["2"] = "war3mapImported\\Bshanghaibaoji2.mdx"
wuli_baoji_shanghai["3"] = "war3mapImported\\Bshanghaibaoji3.mdx"
wuli_baoji_shanghai["4"] = "war3mapImported\\Bshanghaibaoji4.mdx"
wuli_baoji_shanghai["5"] = "war3mapImported\\Bshanghaibaoji5.mdx"
wuli_baoji_shanghai["6"] = "war3mapImported\\Bshanghaibaoji6.mdx"
wuli_baoji_shanghai["7"] = "war3mapImported\\Bshanghaibaoji7.mdx"
wuli_baoji_shanghai["8"] = "war3mapImported\\Bshanghaibaoji8.mdx"
wuli_baoji_shanghai["9"] = "war3mapImported\\Bshanghaibaoji9.mdx"

local fashu_shanghai = {}
fashu_shanghai["0"] = "war3mapImported\\fsshanghai0.mdx"
fashu_shanghai["1"] = "war3mapImported\\fsshanghai1.mdx"
fashu_shanghai["2"] = "war3mapImported\\fsshanghai2.mdx"
fashu_shanghai["3"] = "war3mapImported\\fsshanghai3.mdx"
fashu_shanghai["4"] = "war3mapImported\\fsshanghai4.mdx"
fashu_shanghai["5"] = "war3mapImported\\fsshanghai5.mdx"
fashu_shanghai["6"] = "war3mapImported\\fsshanghai6.mdx"
fashu_shanghai["7"] = "war3mapImported\\fsshanghai7.mdx"
fashu_shanghai["8"] = "war3mapImported\\fsshanghai8.mdx"
fashu_shanghai["9"] = "war3mapImported\\fsshanghai9.mdx"

local fashu_baoji_shanghai = {}
fashu_baoji_shanghai["0"] = "war3mapImported\\fsshanghaibaoji0.mdx"
fashu_baoji_shanghai["1"] = "war3mapImported\\fsshanghaibaoji1.mdx"
fashu_baoji_shanghai["2"] = "war3mapImported\\fsshanghaibaoji2.mdx"
fashu_baoji_shanghai["3"] = "war3mapImported\\fsshanghaibaoji3.mdx"
fashu_baoji_shanghai["4"] = "war3mapImported\\fsshanghaibaoji4.mdx"
fashu_baoji_shanghai["5"] = "war3mapImported\\fsshanghaibaoji5.mdx"
fashu_baoji_shanghai["6"] = "war3mapImported\\fsshanghaibaoji6.mdx"
fashu_baoji_shanghai["7"] = "war3mapImported\\fsshanghaibaoji7.mdx"
fashu_baoji_shanghai["8"] = "war3mapImported\\fsshanghaibaoji8.mdx"
fashu_baoji_shanghai["9"] = "war3mapImported\\fsshanghaibaoji9.mdx"

local function _z(u, offset)
    return hunit.h(u) + 130 + offset
end

---@param x number position
---@param y number position
---@param z number position
---@param damage_number number damage number
---@param damage number model
local function show_damange_number(x, y, z, damange_number, damage_model, scale, targetUnit, damagePlayer)
    if targetUnit == nil or damagePlayer == nil then
        return
    end
    local damagePerUnit = hcache.get(targetUnit, "damage_number", 0)
    local newZ = z + damagePerUnit * 20
    hcache.set(targetUnit, "damage_number", damagePerUnit + 1)
    htime.setTimeout(
        1,
        function(_)
            local damagePerUnit = hcache.get(targetUnit, "damage_number", 0)
            if damagePerUnit > 0 then
                hcache.set(targetUnit, "damage_number", damagePerUnit - 1)
            end
        end
    )
    scale = scale or 0.5
    local str = tostring(math.floor(damange_number)) or ""
    local words = mbstring.split(str, 1)
    if (#words > 0) then
        for i = #words, 1, -1 do
            local model = damage_model[words[i]]
            if hcache.get(hplayer.loc(), "shanghaishuzi", false) and damagePlayer ~= hplayer.loc() then
                model = ""
            end
            heffect.xyz(model, x + ((i - 1) * 47 * scale), y, newZ, 0, 1, scale, scale, scale)
        end
    end
end

---@param evtData onBeDamageData
hevent.reaction(
    CONST_EVENT.beDamage,
    function(evtData)
        if evtData.damageSpeedType == CONST_DAMAGE_SPEED_TYPE.IMMEDIATE then
            heffect.attach("war3mapImported\\hit0.mdx", evtData.triggerUnit, "chest", 0)
        end
        if hplayer.isUser(hunit.getOwner(evtData.triggerUnit)) == true then
            local tag =
                htextTag.create2XY(
                hunit.x(evtData.triggerUnit),
                hunit.y(evtData.triggerUnit),
                "-" .. string.format("%.0f", evtData.damage),
                9,
                "e32a00",
                1,
                1,
                50
            )
            htextTag.setVelocity(tag, 0, 0.05)
        else
            local x = hunit.x(evtData.triggerUnit)
            local y = hunit.y(evtData.triggerUnit)
            local z = _z(evtData.triggerUnit, 0)
            local damage_model = nil
            local scale = nil
            local sourceUnit = evtData.sourceUnit
            local damagePlayer = hunit.getOwner(sourceUnit)
            if evtData.damageType == DAMAGE_TYPE.MOFA then
                if evtData.isCritical == true then
                    scale = 0.7
                    damage_model = fashu_baoji_shanghai
                else
                    scale = 0.4
                    damage_model = fashu_shanghai
                end
            end
            if evtData.damageType == DAMAGE_TYPE.WULI then
                if evtData.isCritical == true then
                    scale = 0.7
                    damage_model = wuli_baoji_shanghai
                else
                    scale = 0.4
                    damage_model = wuli_shanghai
                end
            end
            if evtData.damageType == DAMAGE_TYPE.SHENSHENG then
                scale = 0.4
                -- TODO  改成神圣伤害数字
                damage_model = fashu_shanghai
            end
            if damage_model == nil then
                dump("unsupported damange type")
                return
            end
            show_damange_number(x, y, z + 20, evtData.damage, damage_model, scale, evtData.triggerUnit, damagePlayer)
        end
    end
)

---@param evtData onExpData
hevent.reaction(
    CONST_EVENT.customResourceChange,
    "expFloatText",
    function(evtData)
        if evtData.showEffect == false then
            return
        end
        if (evtData.type == HSHOP_COST_TYPE.experience) then
            local sign = "+"
            local value = evtData.addedValue
            if evtData.usedValue > 0 then
                sign = "-"
                value = evtData.usedValue
            end
            local tag =
                htextTag.create2XY(
                hunit.x(evtData.triggerUnit) + 100,
                hunit.y(evtData.triggerUnit),
                sign .. math.floor(math.abs(value)) .. "exp",
                9,
                "facf7e",
                1,
                1,
                50
            )
            htextTag.setVelocity(tag, 0, 0.05)
        end
        if (evtData.type == HSHOP_COST_TYPE.dianfengjingyan) then
            local sign = "+"
            local value = evtData.addedValue
            if evtData.usedValue > 0 then
                sign = "-"
                value = evtData.usedValue
            end
            local tag =
                htextTag.create2XY(
                hunit.x(evtData.triggerUnit) + 80,
                hunit.y(evtData.triggerUnit) - 20,
                sign .. math.floor(math.abs(value)) .. "sexp",
                9,
                "103497",
                1,
                1,
                50
            )
            htextTag.setVelocity(tag, 0, 0.05)
        end
    end
)
---@param evtData onCustomResourceChange
hevent.reaction(
    CONST_EVENT.customResourceChange,
    "goldFloatText",
    function(evtData)
        if evtData.showEffect == false then
            return
        end
        if (evtData.type == HSHOP_COST_TYPE.gold) then
            local sign = "+"
            local value = evtData.addedValue
            if evtData.usedValue > 0 then
                sign = "-"
                value = evtData.usedValue
            end
            local tag =
                htextTag.create2XY(
                hunit.x(evtData.triggerUnit) - 100,
                hunit.y(evtData.triggerUnit),
                sign .. math.floor(math.abs(value)) .. "g",
                9,
                "fea706",
                1,
                1,
                50
            )
            htextTag.setVelocity(tag, 0, 0.05)
            hsound.voice2Unit(JassGlobals.gg_snd_ReceiveGold, 100, evtData.triggerUnit)
        end
    end
)

hevent.reaction(
    CONST_EVENT.heal,
    "heal number",
    function(evtData)
        if evtData.showEffect == false then
            return
        end
        local healee = evtData.healee
        local tag =
            htextTag.create2XY(
            hunit.x(healee),
            hunit.y(healee),
            "+" .. string.format("%.0f", evtData.heal) .. "(" .. string.format("%.0f", evtData.overHeal) .. ")",
            8,
            "13fe06",
            1,
            1,
            50
        )
        htextTag.setVelocity(tag, 0, 0.05)
        heffect.attach("war3mapImported\\AZ_D065.mdl", healee, "origin", 0.5)
    end
)
