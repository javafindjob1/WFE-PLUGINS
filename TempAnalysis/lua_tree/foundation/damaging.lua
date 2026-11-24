--- 伤害流
---@class damaging
damaging = damaging or {}

--- 附魔类型集
---@type Array
damaging.actions = Array()

DAMAGE_TYPE = {
    WULI = "wuli",
    MOFA = "mofa",
    SHENSHENG = "shensheng"
}

--- 伤害过程流
--- 伤害过程自上而下运行，对接ability damage函数的过程
---@param key string
---@param callFunc fun(options:noteSkillDamage):void
function damaging.defined(key, callFunc)
    damaging.actions.set(key, callFunc)
end

heal = heal or {}

--- 附魔类型集
---@type Array
heal.actions = Array()

HEAL_TYPE = {
    SKILL = "skill"
}

--- 伤害过程流
--- 伤害过程自上而下运行，对接ability damage函数的过程
---@param key string
---@param callFunc fun(options:noteSkillDamage):void
function heal.defined(key, callFunc)
    heal.actions.set(key, callFunc)
end
