local heishui =
    hslk_ability(
    {
        _parent = "ANcl",
        -- Animation Names
        Animnames = "spell",
        -- Icon - Normal
        Art = "ReplaceableTextures\\CommandButtons\\BTNCleavingAttack.blp",
        -- Button Position - Normal (X)
        Buttonpos_1 = 1,
        -- Button Position - Normal (Y)
        Buttonpos_2 = 2,
        -- Caster
        CasterArt = "",
        -- Cooldown
        Cool = 0,
        -- Mana Cost
        Cost = 0,
        -- Follow Through Time
        DataA = 2,
        -- Target Type
        DataB = 1,
        -- Options
        DataC = 1,
        -- Art Duration
        DataD = 2,
        -- Disable Other Abilities
        DataE = 0,
        -- Base Order ID
        DataF = "thunderbolt",
        -- Editor Suffix
        EditorSuffix = "战士",
        -- Effect
        EffectArt = "",
        -- Hotkey - Normal
        Hotkey = "",
        -- Name
        Name = "巫妖王黑水",
        -- Cast Range
        Rng = 1000.0,
        -- Target
        TargetArt = "",
        -- Tooltip - Normal
        Tip = "巫妖王黑水",
        -- Tooltip - Normal - Extended
        Ubertip = "巫妖王黑水",
        -- Tooltip - Turn Off
        Untip = "巫妖王黑水",
        -- Hero Ability
        hero = 0,
        -- Levels
        levels = 1,
        -- Race
        race = "human",
        -- Targets Allowed
        targs = "enemies"
    }
)

hslk_unit(
    {
        _parent = "ndrj",
        -- Name - Editor Suffix
        EditorSuffix = "野外",
        -- Hit Points Maximum (Base)
        HP = 1000000,
        -- Name
        Name = "巫妖王",
        _unitType = "tuandui boss",
        -- Normal
        abilList = heishui._id,
        -- Death Type
        deathType = 0,
        -- Attack 1 - Damage Base
        dmgplus1 = 150,
        -- Scaling Value
        modelScale = 2.00,
        -- Race
        race = "critters",
        -- Speed Base
        spd = 360,
        -- Stock Replenish Interval
        stockRegen = 45,
        -- Model File
        file = "War3mapImported\\LichKing2.mdx", -- Icon - Game Interface
        Art = "ReplaceableTextures\\BTNzb71.blp"
    }
)
