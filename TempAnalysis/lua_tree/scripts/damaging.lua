-- 流：自上而下
-- 流动下options中的数据得以保留而延续
-- 当options.damage <= 0，则停止后续流动

--- 无敌判断
damaging.defined(
    "invincible",
    function(options)
        if (hunit.isInvincible(options.targetUnit) == true) then
            options.damage = 0
        end
    end
)

--- 等级差计算
damaging.defined(
    "dengjiyazhi",
    function(options)
        local srcLevel = hunit.getLevel(options.sourceUnit)
        local tagLevel = hunit.getLevel(options.targetUnit)
        options.levelGap = math.max(math.min(10, srcLevel - tagLevel), -10)
    end
)

--- 闪避
damaging.defined(
    "shanbi",
    function(options)
        if options.damageSpeedType == CONST_DAMAGE_SPEED_TYPE.DOT then
            return
        end
        local hit = hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "hit", 0)
        local shanbi = hattribute.getWithLimit(options.targetUnit, options.tmpAttr, "shanbi", 0)
        local finalHit = hit - shanbi + options.levelGap
        if math.random(0, 10000) / 100 > finalHit then
            options.damage = 0
            hevent.trigger(
                options.sourceUnit,
                CONST_EVENT.beishanbi,
                { triggerUnit = options.sourceUnit, targetUnit = options.targetUnit }
            )
            hevent.trigger(
                options.targetUnit,
                CONST_EVENT.shanbi,
                { triggerUnit = options.targetUnit, sourceUnit = options.sourceUnit }
            )
            local model = "war3mapImported\\AZ_hero_miss2.mdx"
            if hcache.get(hplayer.loc(), "shanghaishuzi", false) and options.sourceUnit ~= hplayer.loc() then
                model = ""
            end
            heffect.attach(model, options.targetUnit, "origin", 0)
        end
    end
)

--- 招架
damaging.defined(
    "zhaojia",
    function(options)
        if
            options.damageType ~= DAMAGE_TYPE.WULI or options.damageSrc ~= CONST_DAMAGE_SRC.attack or
            options.damageSpeedType == CONST_DAMAGE_SPEED_TYPE.DOT
        then
            return
        end
        local hit = hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "hit", 0)
        local zhaojia = hattribute.getWithLimit(options.targetUnit, options.tmpAttr, "zhaojia", 0)
        local finalHit = hit - zhaojia + options.levelGap
        local zj = false
        if hbuff.hasBuff(options.targetUnit, hslk.n2i("剑在人在")) or math.random(0, 10000) / 100 > finalHit then
            zj = true
        end
        if zj == true then
            options.damage = 0
            local model = "war3mapImported\\AZ_zhaojia.mdx"
            if hcache.get(hplayer.loc(), "shanghaishuzi", false) and options.sourceUnit ~= hplayer.loc() then
                model = ""
            end
            heffect.xyz(
                model,
                hunit.x(options.targetUnit) - 100,
                hunit.y(options.targetUnit),
                hunit.z(options.targetUnit) + 200
            )
            hsound.voice2Unit(
                hsound.voiceCreate("resource\\war3mapImported\\sound\\zhaojia.mp3", 1000, true),
                100,
                options.targetUnit
            )
            hevent.trigger(
                options.targetUnit,
                CONST_EVENT.zhaojia,
                { triggerUnit = options.targetUnit, sourceUnit = options.sourceUnit }
            )
        end
    end
)

--- 格挡
damaging.defined(
    "gedang",
    function(options)
        if options.damageType ~= DAMAGE_TYPE.WULI then
            return
        end
        if options.damageSpeedType == CONST_DAMAGE_SPEED_TYPE.DOT then
            return
        end
        local gedang = hattribute.getWithLimit(options.targetUnit, options.tmpAttr, "gedang", 0)
        if gedang > 0 and math.random(0, 10000) / 100 < gedang then
            options.damage =
                options.damage *
                (1 - 0.01 * hattribute.getWithLimit(options.targetUnit, options.tmpAttr, "gedang_jianshang", 0))
            local model = "war3mapImported\\AZ_gedang.mdx"
            if hcache.get(hplayer.loc(), "shanghaishuzi", false) and options.sourceUnit ~= hplayer.loc() then
                model = ""
            end
            heffect.attach(model, options.targetUnit, "origin", 0)
            hevent.trigger(
                options.targetUnit,
                CONST_EVENT.gedang,
                { triggerUnit = options.targetUnit, sourceUnit = options.sourceUnit }
            )
        end
    end
)

--- 护甲, 魔抗, 穿透
damaging.defined(
    "defend",
    function(options)
        if options.damageType == DAMAGE_TYPE.MOFA then
            local fa_wushi = hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "fa_wushi", 0)
            if math.random(0, 10000) / 100 < fa_wushi then
                return
            end
            local fa_chuan = hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "fa_chuan", 0)
            local mojia = hattribute.getWithLimit(options.targetUnit, options.tmpAttr, "mojia", 0)
            local pomo = hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "pomo", 0)
            local mokang = hattribute.getWithLimit(options.targetUnit, options.tmpAttr, "mokang", 0)
            mojia = math.max(0, mojia - pomo)
            mojia = mojia * (1 - 0.01 * fa_chuan)
            options.damage = options.damage * (1 - 3 * mojia / (1000 + 3 * mojia)) * (1 - 0.01 * mokang)
            return
        elseif options.damageType == DAMAGE_TYPE.WULI then
            local wu_wushi = hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "wu_wushi", 0)
            if math.random(0, 10000) / 100 < wu_wushi then
                return
            end
            local wu_chuan = hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "wu_chuan", 0)
            local hujia = hattribute.getWithLimit(options.targetUnit, options.tmpAttr, "defend", 0)
            local pojia = hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "pojia", 0)
            hujia = math.max(0, hujia - pojia)
            hujia = hujia * (1 - 0.01 * wu_chuan)
            options.damage = options.damage * (1 - 3 * hujia / (1000 + 3 * hujia))
            return
        elseif options.damageType == DAMAGE_TYPE.SHENSHENG then
            return
        else
            err("不认识的伤害类型:" .. tostring(options.damageType))
        end
    end
)

--- 物理法术全局元素增伤
damaging.defined(
    "multiplier",
    function(options)
        local zengshang =
            (hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "quanju_zengshang", 0) + 100) / 100
        if options.damageType == DAMAGE_TYPE.MOFA then
            zengshang =
                zengshang * (100 + hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "fa_zengshang", 0)) /
                100
        elseif options.damageType == DAMAGE_TYPE.WULI then
            zengshang =
                zengshang * (100 + hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "wu_zengshang", 0)) /
                100
        end
        local jinu_zengshang =
            (hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "jinu_zengshang", 0) + 100) / 100
        zengshang = zengshang * jinu_zengshang
        options.damage = options.damage * zengshang
    end
)

--- 减伤
damaging.defined(
    "jianshang",
    function(options)
        if options.damageType == DAMAGE_TYPE.SHENSHENG then
            return
        end
        local jianshang = (100 - hattribute.getWithLimit(options.targetUnit, options.tmpAttr, "jianshang", 0)) / 100
        options.damage = options.damage * jianshang
    end
)

--- 暴击
damaging.defined(
    "critical",
    function(options)
        echo(options.damaging)
        if options.damageType == DAMAGE_TYPE.SHENSHENG then
            return
        end
        local crit_damage = 0
        local crit_rate = options.levelGap
        if (options.damageType == DAMAGE_TYPE.WULI) then
            crit_rate = hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "wu_bao", 0)
            crit_damage = hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "wu_baoshang", 0)
        elseif (options.damageType == DAMAGE_TYPE.MOFA) then
            crit_rate = hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "fa_bao", 0)
            crit_damage = hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "fa_baoshang", 0)
        end

        crit_rate = crit_rate + options.levelGap

        if (crit_rate > 0) then
            if (math.random(0, 10000) / 100 < crit_rate) then
                options.damage = options.damage * crit_damage * 0.01
                options.isCritical = true
            end
        end
    end
)

--- 各职业特殊增伤
damaging.defined(
    "customSource",
    function(options)
        hevent.trigger(options.sourceUnit, CONST_EVENT.damagingCustomSource, options)
        hevent.trigger(options.targetUnit, CONST_EVENT.damagingCustomTarget, options)
        if options.damageSrc == CONST_DAMAGE_SRC.attack or options.isAttackReplacement == true then
            local pugong_shanghai = hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, "pugong_shanghai", 0)
            options.damage = options.damage * (1 + pugong_shanghai / 100)
        end
    end
)

local yuansu = {}
yuansu[CONST_DAMAGE_ELEMENT_TYPE.FIRE] = { "fire_enhance", "fire_yishang" }
yuansu[CONST_DAMAGE_ELEMENT_TYPE.EARTH] = { "earth_enhance", "earth_yishang" }
yuansu[CONST_DAMAGE_ELEMENT_TYPE.METAL] = { "metal_enhance", "metal_yishang" }
yuansu[CONST_DAMAGE_ELEMENT_TYPE.WATER] = { "water_enhance", "water_yishang" }
yuansu[CONST_DAMAGE_ELEMENT_TYPE.WOOD] = { "wood_enhance", "wood_yishang" }
yuansu[CONST_DAMAGE_ELEMENT_TYPE.LIGHT] = { "light_enhance", "light_yishang" }
yuansu[CONST_DAMAGE_ELEMENT_TYPE.DARK] = { "dark_enhance", "dark_yishang" }
yuansu[CONST_DAMAGE_ELEMENT_TYPE.HUNLUAN] = { "hunluan_enhance", "hunluan_yishang" }

--- 元素增伤
damaging.defined(
    "element",
    function(options)
        local damageElementType = options.damageElementType
        if damageElementType ~= nil and type(damageElementType) == "table" then
            for _, v in ipairs(damageElementType) do
                if yuansu[v] ~= nil then
                    local yuansuzengshang = hattribute.getWithLimit(options.sourceUnit, options.tmpAttr, yuansu[v][1], 0)
                    local yuansuyishang   = hattribute.getWithLimit(options.targetUnit, options.tmpAttr, yuansu[v][2], 0)
                    options.damage        = options.damage * (1 + yuansuzengshang / 100) * (1 + yuansuyishang / 100)
                end
            end
        end
    end
)

--- 团队角色
damaging.defined(
    "tuanduijuese",
    function(options)
        if hbuff.hasBuff(options.sourceUnit, "进攻手") or hbuff.hasBuff(options.sourceUnit, "先锋") then
            options.damage = options.damage * 1.02
        end
        if hbuff.hasBuff(options.sourceUnit, "守护者") then
            options.damage = options.damage * 0.1
        end
        if hbuff.hasBuff(options.targetUnit, "守护者") then
            options.damage = options.damage * 0.4
        end
    end
)

damaging.defined(
    "JJC",
    function(options)
        if hbuff.hasBuff(options.targetUnit, "竞技场") and hplayer.isUser(hunit.getOwner(options.sourceUnit)) then
            options.damage = options.damage * 0.05
        end
    end
)

---最终减伤
damaging.defined(
    "final_damage_reduction",
    function(options)
        local jianshang = hattribute.getWithLimit(options.targetUnit, options.tmpAttr, "final_damage_reduction", 0)
        if options.damageType ~= DAMAGE_TYPE.SHENSHENG then
            options.damage = math.max(options.damage - jianshang, 1)
        end
    end
)

--- 致死检查
damaging.defined(
    "killing",
    function(options)
        if options.damage >= hunit.getCurLife(options.targetUnit) then
            hevent.trigger(options.targetUnit, CONST_EVENT.dying, options)
        end
    end
)

heal.defined(
    "heal enhancement",
    function(options)
        local healer = options.healer
        local healee = options.healee
        local heal = options.heal
        local healer_zengqiang = hattribute.getWithLimit(healer, nil, "healer_zengqiang", 0)
        local healee_zengqiang = hattribute.getWithLimit(healee, nil, "healee_zengqiang", 0)
        options.heal = heal * (100 + healer_zengqiang) / 100 * (100 + healee_zengqiang) / 100
    end
)

heal.defined(
    "JJC",
    function(options)
        local healee = options.healee
        if hbuff.hasBuff(healee, "竞技场") then
            options.heal = options.heal * 0.2
        end
    end
)
