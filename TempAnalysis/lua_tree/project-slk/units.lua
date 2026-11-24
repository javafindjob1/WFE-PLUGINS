local lilianrenwu =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\BTN_FS_01.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 0,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- Name
        Name = "历练任务",
        -- Follow Through Time
        DataA = 0,
        -- Tooltip - Normal - Extended
        Ubertip = "历练任务",
        -- Tooltip - Turn Off
        Untip = "",
        -- Hero Ability
        hero = 0,
        -- Levels
        levels = 1,
        -- Race
        race = "human"
    }
)

hslk_ability(
    {
        _parent = "Aspb",
        -- Icon - Normal
        Art = "ReplaceableTextures\\CommandButtons\\PASBTNJN_XX_V.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 3,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 0,
        -- Spell List
        DataA = lilianrenwu._id,
        -- Shared Spell Cooldown
        DataB = 0,
        -- Minimum Spells
        DataC = 12,
        Ubertip = "主线任务",
        -- Maximum Spells
        DataD = 12,
        -- Base Order ID
        DataE = "tornado",
        Hotkey = "O",
        -- Name
        Name = "主线任务"
    }
)

local fengjian_moxing =
    hslk_ability(
    {
        _parent = "AItg",
        -- Attack Bonus
        DataA = 0,
        -- Editor Suffix
        EditorSuffix = "",
        -- Name
        Name = "武器绑定：逐风剑",
        -- Target
        TargetArt = "war3mapImported\\weapon_JuJian06.mdx",
        -- Target Attachment Point 1
        Targetattach = "hand,right",
        -- Target Attachment Point 2
        Targetattach1 = "hand,right",
        -- Target Attachments
        Targetattachcount = 1
    }
)

local shanghai_tongji =
    hslk_ability(
    {
        -- Icon - Normal
        Art = "ReplaceableTextures\\BTN_FS_01.blp",
        -- Button Position - Normal (X)
        _parent = "AOcr",
        Buttonpos_1 = 2,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 1,
        -- Name
        Name = "伤害统计",
        -- Follow Through Time
        DataA = 0,
        -- Tooltip - Normal - Extended
        Ubertip = "伤害统计",
        -- Tooltip - Turn Off
        Untip = "伤害统计",
        -- Hero Ability
        hero = 0,
        -- Levels
        levels = 1,
        -- Race
        race = "human"
    }
)

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Hit Points Maximum (Base)
        HP = 10000,
        -- Name
        Name = "挨打的木桩",
        -- Normal
        abilList = shanghai_tongji._id,
        -- Armor Type
        armor = "Wood",
        -- Can Flee
        canFlee = 0,
        -- Animation - Cast Backswing
        castbsw = 0.0,
        -- Animation - Cast Point
        castpt = 0.0,
        -- Defense Base
        def = 100,
        -- Attack 1 - Damage Base
        dmgplus1 = 0,
        -- Model File
        file = "war3mapImported\\[npc]fcgbvw3v414.mdl",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Scaling Value
        modelScale = 1.25,
        -- Attack 1 - Range
        rangeN1 = 100,
        -- Hit Points Regeneration Rate
        regenHP = 0.0,
        -- Attack 1 - Damage Sides per Die
        sides1 = 1,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Unit Sound Set
        unitSound = "",
        -- Upgrades Used
        upgrades = "",
        -- Attack 1 - Weapon Sound
        weapType1 = "",
        -- Attacks Enabled
        weapsOn = 1
    }
)
