local chongjibo =
    hslk_ability(
        {
            _parent = "ACca",
            -- Area of Effect
            Area = 50.0,
            -- Casting Time
            Cast = 1.0,
            -- Cooldown
            Cool = 0.0,
            -- Mana Cost
            Cost = 0,
            -- Damage
            DataA = 200.0,
            -- Max Damage
            DataB = 9999999.0,
            -- Final Area
            DataD = 50.0,
            -- Editor Suffix
            EditorSuffix = "野怪",
            -- Missile Art
            Missileart = "Abilities\\Weapons\\GargoyleMissile\\GargoyleMissile.mdl",
            -- Missile Speed
            Missilespeed = 1000,
            -- Name
            Name = "直线伤害1s释放 1000弹道速度 200伤害 50范围 "
        }
    )
hslk_unit(
    {
        _parent = "nftr",
        -- Name - Editor Suffix
        EditorSuffix = "野外",
        -- Hit Points Maximum (Base)
        HP = 5200,
        -- Name
        Name = "巨魔",
        rangeN1 = 150,
        -- Normal
        abilList = chongjibo._id,
        -- Tinting Color 3 (Blue)
        blue = 0,
        -- Death Type
        deathType = 0,
        -- Attack 1 - Damage Base
        dmgplus1 = 150,
        -- Tinting Color 2 (Green)
        green = 200,
        -- Level
        level = 16,
        -- Scaling Value
        modelScale = 1,
        -- Race
        race = "critters",
        -- Tinting Color 1 (Red)
        red = 200,
        -- Speed Base
        spd = 300,
        -- Stock Replenish Interval
        stockRegen = 45,
        -- Acquisition Range
        acquire = 300.0
        -- _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nftt",
        -- Name
        Name = "巨魔狂战士",
        -- Normal
        abilList = chongjibo._id,
        rangeN1 = 150,
        _canBOPI = true,
        -- Race 取消等级显示
        race = "critters",
        -- Acquisition Range
        acquire = 300.0
    }
)

hslk_unit(
    {
        _parent = "nftk",
        -- Name - Editor Suffix
        EditorSuffix = "野外",
        -- Hit Points Maximum (Base)
        HP = 5200,
        -- Name
        Name = "巨魔领主",
        rangeN1 = 150,
        -- Normal
        abilList = chongjibo._id,
        -- Tinting Color 3 (Blue)
        blue = 0,
        -- Death Type
        deathType = 0,
        -- Attack 1 - Damage Base
        dmgplus1 = 150,
        -- Tinting Color 2 (Green)
        green = 200,
        -- Level
        level = 16,
        -- Scaling Value
        modelScale = 1,
        -- Race
        race = "critters",
        -- Tinting Color 1 (Red)
        red = 200,
        -- Speed Base
        spd = 300,
        -- Stock Replenish Interval
        stockRegen = 45,
        -- Acquisition Range
        acquire = 300.0
    }
)

hslk_unit(
    {
        _parent = "nwlt",
        -- Name
        Name = "野狼",
        -- Normal
        abilList = chongjibo._id,
        _canBOPI = true,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nwlt",
        -- Name
        Name = "精英野狼",
        -- Scaling Value
        modelScale = 1.2,
        -- Normal
        abilList = chongjibo._id,
        _canBOPI = true,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)
hslk_unit(
    {
        _parent = "nwlg",
        -- Name
        Name = "巨狼",
        modelScale = 1.2,
        -- Normal
        abilList = chongjibo._id,
        _canBOPI = true,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)
hslk_unit(
    {
        _parent = "nwlt",
        -- Name
        Name = "铁狼",
        -- Scaling Value
        file = "war3mapImported\\ArmoredDireWolfFeet3.mdx",
        modelScale = 1,
        scale = -1,
        -- Normal
        abilList = chongjibo._id,
        _canBOPI = true,
        -- Race 取消等级显示
        race = "critters",
        collision = 0,
        castpt = 0
    }
)
hslk_unit(
    {
        _parent = "nwlt",
        -- Name
        Name = "银月狼王",
        -- Scaling Value
        modelScale = 1,
        -- Normal
        abilList = chongjibo._id,
        _canBOPI = true,
        file = "war3mapImported\\ArmoredDireWolfFeet3_Portrait.mdx",
        scale = -1,
        -- Race 取消等级显示
        race = "critters",
        collision = 0,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nahy",
        -- Name
        Name = "银鳞",
        -- Scaling Value
        modelScale = 1,
        -- Normal
        abilList = chongjibo._id,
        scale = -1,
        _canBOPI = true,
        file = "war3mapImported\\HydraSilver.mdx",
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nkob",
        -- Name
        Name = "狗头人",
        -- Scaling Value
        modelScale = 1.0,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nkot",
        -- Name
        Name = "狗头人战士",
        -- Scaling Value
        modelScale = 1.0,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nkog",
        -- Name
        Name = "狗头人术士",
        -- Scaling Value
        modelScale = 1.0,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nkol",
        -- Name
        Name = "狗头人领主",
        -- Scaling Value
        modelScale = 1.5,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nfrb",
        -- Name
        Name = "熊怪",
        -- Scaling Value
        modelScale = 1.0,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nfrg",
        -- Name
        Name = "熊怪战士",
        -- Scaling Value
        modelScale = 1.0,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nfra",
        -- Name
        Name = "熊怪领主",
        -- Scaling Value
        modelScale = 1.5,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nmcf",
        -- Name
        Name = "鱼人",
        -- Scaling Value
        modelScale = 1.0,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nmbg",
        -- Name
        Name = "鱼人法师",
        -- Scaling Value
        modelScale = 1.0,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nmtw",
        -- Name
        Name = "鱼人战士",
        -- Scaling Value
        modelScale = 1.0,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nmsn",
        -- Name
        Name = "鱼人猎手",
        -- Scaling Value
        modelScale = 1.0,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nmsn",
        -- Name
        Name = "鱼人精英猎手",
        -- Scaling Value
        modelScale = 1.2,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nmrv",
        -- Name
        Name = "鱼人领主",
        -- Scaling Value
        modelScale = 1.5,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nmcf",
        -- Name
        Name = "鱼人精英战士",
        -- Scaling Value
        modelScale = 1.3,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nmsc",
        -- Name
        Name = "鱼人精英法师",
        -- Scaling Value
        modelScale = 1.2,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nmsc",
        -- Name
        Name = "绿鳞",
        -- Scaling Value
        modelScale = 1,
        scale = -1,
        file = "war3mapImported\\MurlocNightCrawler_V2.mdx",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nmsc",
        -- Name
        Name = "黑鳞",
        -- Scaling Value
        modelScale = 1,
        scale = -1,
        file = "war3mapImported\\MurlocNightCrawler_V1.mdx",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "ngno",
        -- Name
        Name = "豺狼人",
        -- Normal
        abilList = chongjibo._id,
        _canBOPI = true,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "ngnb",
        -- Name
        Name = "豺狼战士",
        -- Normal
        abilList = chongjibo._id,
        _canBOPI = true,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "ngnv",
        -- Name
        Name = "豺狼领主",
        -- Normal
        abilList = chongjibo._id,
        _canBOPI = true,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nban",
        -- Name
        Name = "强盗喽啰",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nban",
        -- Name
        Name = "强盗",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nbrg",
        -- Name
        Name = "土匪",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nrog",
        -- Name
        Name = "刺客",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nban",
        -- Name
        Name = "精英强盗",
        -- Scaling Value
        modelScale = 1.2,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nbrg",
        -- Name
        Name = "精英土匪",
        -- Scaling Value
        modelScale = 1.2,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nrog",
        -- Name
        Name = "精英刺客",
        -- Scaling Value
        modelScale = 1.2,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nogm",
        -- Name
        Name = "暴徒洛克",
        file = "war3mapImported\\Captain Bob.mdx",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        scale = -1,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "ngnv",
        -- Name
        Name = "屠杀者霍克",
        file = "war3mapImported\\Hogger.mdx",
        -- Scaling Value
        modelScale = 1,
        scale = -1,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nban",
        -- Name
        Name = "监狱之王范克瑞夫",
        file = "war3mapImported\\[boss]VanCleef.mdx",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        scale = -1,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nban",
        -- Name
        Name = "血色军统帅莫格莱尼",
        file = "war3mapImported\\[boss]PlaladinHolyCrusader.mdx",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        scale = -1,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hsor",
        -- Name
        Name = "大检察官迈恩",
        file = "war3mapImported\\Sally Whitemane.mdx",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        scale = -1,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "血色勇士赫罗德",
        file = "war3mapImported\\[boss]xuese_Herod",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        scale = -1,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "血色军剑士",
        file = "[xiaoguai]xuesejunbaotu.mdx",
        -- Scaling Value
        modelScale = 1.6,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "血色军卫士",
        file = "[xiaoguai]xuesejunbubing.mdx",
        -- Scaling Value
        modelScale = 1.6,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hsor",
        -- Name
        Name = "血色军法师",
        file = "[xiaoguai]xuesejunfashi.mdx",
        -- Scaling Value
        modelScale = 1.6,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "训犬大师杜兰",
        file = "[boss]xuese_lao1.mdx",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        scale = -1,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nwlt",
        -- Name
        Name = "杜兰的猎犬",
        file = "[guaiwu]liequan.mdx",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        _canBOPI = true,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "教堂近卫军",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "uabo",
        -- Name
        Name = "试验腐败缝合怪",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "hmpr",
        -- Name
        Name = "教堂牧师",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "uabo",
        -- Name
        Name = "完美腐败缝合怪",
        file = "[boss][zengwu].mdx",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        blue = 255,
        scale = -1,
        spd = 400,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "hkni",
        -- Name
        Name = "裁判长萨提斯",
        file = "[boss]caipanzhang.mdx",
        -- Scaling Value
        modelScale = 1,
        scale = -1,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hmpr",
        -- Name
        Name = "圣光主教布莱克安",
        file = "[boss]Zhujiao.mdx",
        -- Scaling Value
        modelScale = 1,
        scale = -1,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        rangeN1 = 400,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "游荡的血色军剑士",
        file = "[xiaoguai]xuesejunbaotu.mdx",
        -- Scaling Value
        modelScale = 1.5,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "游荡的血色军卫士",
        file = "[xiaoguai]xuesejunbubing.mdx",
        -- Scaling Value
        modelScale = 1.5,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hsor",
        -- Name
        Name = "游荡的血色军法师",
        file = "[xiaoguai]xuesejunfashi.mdx",
        -- Scaling Value
        modelScale = 1.5,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "血色军下士",
        file = "[xiaoguai]xuesejunbaotu.mdx",
        -- Scaling Value
        modelScale = 1.8,
        red = 255,
        green = 200,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "uabo",
        -- Name
        Name = "低等缝合怪",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "反叛军步卒",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hmpr",
        -- Name
        Name = "反叛军牧师",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nwna",
        -- Name
        Name = "风元素领主",
        -- Scaling Value
        modelScale = 1,
        rangeN1 = 400,
        acquire = 400,
        file = "[boss]thunderan.mdx",
        red = 255,
        green = 255,
        scale = -1,
        blue = 255,
        -- Attack 1 - Animation Damage Point
        dmgpt1 = 1.0,
        -- Attack 1 - Cooldown Time
        cool1 = 2.0,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "ncea",
        -- Name
        Name = "人马弓箭手",
        -- Scaling Value
        modelScale = 1.5,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canBOPI = true
    }
)

hslk_unit(
    {
        _parent = "ncer",
        -- Name
        Name = "人马苦工",
        -- Scaling Value
        modelScale = 1.5,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canBOPI = true
    }
)

hslk_unit(
    {
        _parent = "ncim",
        -- Name
        Name = "人马刺客",
        -- Scaling Value
        modelScale = 1.5,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canBOPI = true
    }
)

hslk_unit(
    {
        _parent = "ncen",
        -- Name
        Name = "人马先行者",
        -- Scaling Value
        modelScale = 1.5,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canBOPI = true
    }
)

hslk_unit(
    {
        _parent = "ncks",
        -- Name
        Name = "人马先知",
        -- Scaling Value
        modelScale = 1.5,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canBOPI = true
    }
)

hslk_unit(
    {
        _parent = "ncnk",
        -- Name
        Name = "人马领主",
        -- Scaling Value
        modelScale = 2.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canBOPI = true
    }
)

hslk_unit(
    {
        _parent = "ncea",
        -- Name
        Name = "人马精英弓箭手",
        -- Scaling Value
        modelScale = 1.6,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canBOPI = true
    }
)

hslk_unit(
    {
        _parent = "ncks",
        -- Name
        Name = "人马精英先知",
        -- Scaling Value
        modelScale = 1.6,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canBOPI = true
    }
)

hslk_unit(
    {
        _parent = "ncen",
        -- Name
        Name = "人马精英勇士",
        -- Scaling Value
        modelScale = 1.6,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canBOPI = true
    }
)

hslk_unit(
    {
        _parent = "ncer",
        -- Name
        Name = "快刀手迅蹄",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        scale = -1,
        blue = 255,
        file = "war3mapImported\\[guaiwu]CentaurWarrior.mdx",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canBOPI = true
    }
)
hslk_unit(
    {
        _parent = "ncea",
        -- Name
        Name = "人马弓神布鲁斯",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        blue = 255,
        file = "war3mapImported\\[guaiwu]CentaurCaster.mdx",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        scale = -1,
        MissileHoming = 1,
        rangeN1 = 900,
        acquire = 900,
        Missilespeed = 1500,
        castpt = 0,
        _canBOPI = true
    }
)

hslk_unit(
    {
        _parent = "ncnk",
        -- Name
        Name = "人马酋长战争之蹄",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        scale = -1,
        green = 255,
        file = "war3mapImported\\Centaur1.mdx",
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canBOPI = true
    }
)

hslk_unit(
    {
        _parent = "nhar",
        -- Name
        Name = "鹰身女妖侦察者",
        -- Scaling Value
        modelScale = 1.5,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nhrr",
        -- Name
        Name = "鹰身女妖",
        -- Scaling Value
        modelScale = 1.5,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nhrh",
        -- Name
        Name = "鹰身女妖巫师",
        -- Scaling Value
        modelScale = 1.5,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nfpl",
        -- Name
        Name = "黑铁矮人矿工",
        -- Scaling Value
        modelScale = 0.8,
        red = 255,
        file = "war3mapImported\\Dwarvenminer.mdl",
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        Art = "ReplaceableTextures\\CommandButtons\\BTNPeasant.blp",
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nfpu",
        -- Name
        Name = "黑铁矮人守卫",
        -- Scaling Value
        modelScale = 0.7,
        Art = "ReplaceableTextures\\CommandButtons\\BTNFootman.blp",
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        file = "war3mapImported\\blackguard.mdx.mdl",
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hrif",
        -- Name
        Name = "黑铁矮人枪手",
        -- Scaling Value
        modelScale = 1.66,
        red = 255,
        green = 255,
        blue = 255,
        file = "war3mapImported\\blackRifleman.mdl",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nfpl",
        -- Name
        Name = "精英黑铁矮人矿工",
        -- Scaling Value
        modelScale = 0.9,
        Art = "ReplaceableTextures\\CommandButtons\\BTNPeasant.blp",
        red = 255,
        file = "war3mapImported\\Dwarvenminer.mdl",
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nfpu",
        -- Name
        Name = "精英黑铁矮人守卫",
        -- Scaling Value
        modelScale = 0.75,
        red = 255,
        green = 255,
        blue = 255,
        Art = "ReplaceableTextures\\CommandButtons\\BTNFootman.blp",
        -- Normal
        file = "war3mapImported\\blackguard.mdx.mdx",
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hrif",
        -- Name
        Name = "精英黑铁矮人枪手",
        -- Scaling Value
        modelScale = 1.70,
        red = 255,
        green = 255,
        blue = 255,
        file = "war3mapImported\\blackRifleman.mdl",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nfpu",
        -- Name
        Name = "矮人守卫队长杜尼尔",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        file = "war3mapImported\\blackguard.mdx.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNFootman.blp",
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        scale = -1,
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nfpl",
        -- Name
        Name = "嗜血的格洛格",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        Art = "ReplaceableTextures\\CommandButtons\\BTNOgreMagi.blp",
        file = "war3mapImported\\[guaiwu]U_OgreMage.mdl",
        green = 255,
        blue = 255,
        MaxPitch = 0,
        MaxRoll = 0,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        scale = -1,
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nfpl",
        -- Name
        Name = "黑铁矮人索瑞森大帝",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        dmgpt1 = 0.35,
        Art = "ReplaceableTextures\\CommandButtons\\BTNHeroMountainKing.blp",
        file = "war3mapImported\\[boss]Deathwing.mdl",
        green = 255,
        blue = 255,
        MaxPitch = 0,
        MaxRoll = 0,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        scale = -1,
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nsgg",
        -- Name
        Name = "火元素",
        -- Scaling Value
        modelScale = 1.0,
        file = "war3mapImported\\[guaiwu]FireElemental2.mdl",
        Art = "ReplaceableTextures\\CommandButtons\\BTNLavaSpawn.blp",
        red = 255,
        green = 255,
        blue = 255,
        MaxPitch = 0,
        MaxRoll = 0,
        dmgpt1 = 0.55,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nsgg",
        -- Name
        Name = "精英火元素",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        dmgpt1 = 0.55,
        MaxPitch = 0,
        MaxRoll = 0,
        blue = 255,
        file = "war3mapImported\\[guaiwu]FireElemental2.mdl",
        Art = "ReplaceableTextures\\CommandButtons\\BTNLavaSpawn.blp",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nsgg",
        -- Name
        Name = "炎魔之子",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        MaxPitch = 0,
        MaxRoll = 0,
        dmgpt1 = 0.55,
        file = "war3mapImported\\[guaiwu]FireElemental2.mdl",
        Art = "ReplaceableTextures\\CommandButtons\\BTNLavaSpawn.blp",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nsgg",
        -- Name
        Name = "嘉顿",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        scale = -1,
        green = 255,
        blue = 255,
        dmgpt1 = 0.55,
        MaxPitch = 0,
        MaxRoll = 0,
        -- Normal
        file = "war3mapImported\\[boss]FireElemental.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNLavaSpawn.blp",
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nggr",
        -- Name
        Name = "石元素",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        dmgpt1 = 0.55,
        MaxPitch = 0,
        MaxRoll = 0,
        -- Normal
        file = "war3mapImported\\[boss]Rock Elemental.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNRockGolem.blp",
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nggr",
        -- Name
        Name = "精英石元素",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        dmgpt1 = 0.55,
        MaxPitch = 0,
        MaxRoll = 0,
        -- Normal
        file = "war3mapImported\\[boss]Rock Elemental.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNRockGolem.blp",
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nggr",
        -- Name
        Name = "嘉尔",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        MaxPitch = 0,
        MaxRoll = 0,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\[boss]Rock Elemental3.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNRockGolem.blp",
        -- Race 取消等级显示
        scale = -1,
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nggr",
        -- Name
        Name = "炎巨人",
        -- Scaling Value
        modelScale = 0.8,
        red = 255,
        green = 255,
        dmgpt1 = 0.55,
        blue = 255,
        MaxPitch = 0,
        MaxRoll = 0,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\[boss]HeroTinyLava.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNInfernal.blp",
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nggr",
        -- Name
        Name = "精英炎巨人",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        dmgpt1 = 0.55,
        MaxPitch = 0,
        MaxRoll = 0,
        -- Attack 1 - Cooldown Time
        cool1 = 2.0,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\[boss]HeroTinyLava.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNInfernal.blp",
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nggr",
        -- Name
        Name = "焚化者古曼",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        MaxPitch = 0,
        MaxRoll = 0,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\[boss]HeroTinyLava2.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNInfernal.blp",
        -- Race 取消等级显示
        race = "critters",
        scale = -1,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nwlt",
        -- Name
        Name = "古曼的地狱犬",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        MaxPitch = 0,
        MaxRoll = 0,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\[boss]felbeast.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNInfernal.blp",
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nggr",
        -- Name
        Name = "炎魔之王",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        scale = -1,
        rangeN1 = 800,
        acquire = 800,
        blue = 255,
        collision = 300,
        dmgpt1 = 1,
        -- Attack 1 - Cooldown Time
        cool1 = 2.0,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\[boss]ragnaros.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNHeroAvatarOfFlame.blp",
        -- Race 取消等级显示
        race = "critters",
        -- Speed Base
        spd = 1,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "黑龙王子",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 200,
        acquire = 200,
        blue = 255,
        collision = 200,
        scale = -1,
        dmgpt1 = 1,
        MaxPitch = 0,
        MaxRoll = 0,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "DragonNefarian.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNBlackDragon.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdk",
        -- Name
        Name = "黑龙幼崽",
        -- Scaling Value
        modelScale = 0.8,
        Scale = 0.5,
        MaxPitch = 0,
        MaxRoll = 0,
        red = 255,
        green = 255,
        collision = 12,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        --file = "war3mapImported\\[boss]Rock Elemental3.mdx",
        --Art = "ReplaceableTextures\\CommandButtons\\BTNRockGolem.blp",
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "黑龙蛋",
        -- Scaling Value
        modelScale = 1,
        Scale = -1,
        red = 255,
        green = 255,
        blue = 255,
        rangeN1 = 200,
        acquire = 200,
        dmgpt1 = 1,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "Dragon_Egg.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNBlackDragon.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 0,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "试炼近卫军",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hmpr",
        -- Name
        Name = "试炼牧师",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hmpr",
        -- Name
        Name = "试炼枪手",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hmpr",
        -- Name
        Name = "试炼法师",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "戈隆",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 200,
        acquire = 200,
        blue = 255,
        --collision = 40,
        dmgpt1 = 1,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\GronnBladespireBrown.mdx",
        Art = "ReplaceableTextures\\BTNAchievement_Boss_GruulTheDragonkiller.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        _canBOPI = true,
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "屠龙者格鲁",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 200,
        acquire = 200,
        blue = 255,
        collision = 200,
        scale = -1,
        dmgpt1 = 0.5,
        -- Attack 1 - Cooldown Time
        cool1 = 2,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\[boss]a0.mdx",
        Art = "ReplaceableTextures\\BTNAchievement_Boss_GruulTheDragonkiller.blp",
        -- Race 取消等级显示
        race = "critters",
        _canBOPI = true,
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "hmpr",
        -- Name
        Name = "法师塔法师",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true,
        ustomTeamColor = 1,
        teamColor = 4,
        file = "war3mapImported\\BloodElvenMagister.mdx",
        Art = "ReplaceableTextures\\fashitafashi.blp",
    }
)

hslk_unit(
    {
        _parent = "hmpr",
        -- Name
        Name = "法师塔术士",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        file = "war3mapImported\\BloodMage1.mdx",
        Art = "ReplaceableTextures\\fashitashushi.blp",
        ustomTeamColor = 1,
        teamColor = 4,
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "法师塔卫士",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true,
        file = "war3mapImported\\felgolembl.mdx",
        Art = "ReplaceableTextures\\fashitashouwei.blp",
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "荣誉护卫木羽",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        file = "BloodelfWarPriest.mdx",
        Art = "ReplaceableTextures\\rongyuweishimuyu.blp",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hmpr",
        -- Name
        Name = "法师塔精英法师",
        -- Scaling Value
        modelScale = 1.3,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true,
        ustomTeamColor = 1,
        teamColor = 1,
        file = "war3mapImported\\BloodElvenMagister.mdx",
        Art = "ReplaceableTextures\\fashitafashi.blp",
    }
)

hslk_unit(
    {
        _parent = "hmpr",
        -- Name
        Name = "法师塔精英术士",
        -- Scaling Value
        modelScale = 1.3,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true,
        file = "war3mapImported\\BloodMage1.mdx",
        Art = "ReplaceableTextures\\fashitashushi.blp",
        ustomTeamColor = 1,
        teamColor = 1,
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "法师塔精英卫士",
        -- Scaling Value
        modelScale = 1.3,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        file = "war3mapImported\\ArcaneGolem.mdx",
        Art = "ReplaceableTextures\\fashitashouwei.blp",
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "大法师埃兰",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 200,
        acquire = 200,
        blue = 255,
        collision = 200,
        scale = -1,
        dmgpt1 = 1,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\FiveFireballs.mdx",
        Art = "ReplaceableTextures\\dafashiailan.blp",
        -- Race 取消等级显示
        race = "critters",
        -- Mana Initial Amount
        mana0 = 100,
        -- Mana Maximum
        manaN = 100,
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 0,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "星界闪电球",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Acquisition Range
        acquire = 2000.0,
        collision = 1,
        -- Speed Base
        spd = 522,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        file = "war3mapImported\\Wrath_Impact_Chest.mdx",
        Art = "ReplaceableTextures\\fashitafashi.blp",
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "夜魇骷髅",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Acquisition Range
        acquire = 2000.0,
        -- Speed Base
        collision = 6,
        spd = 100,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        file = "northrendskeletonmale.mdx",
        Art = "ReplaceableTextures\\yeyankulou.blp",
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "暗影魔",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Acquisition Range
        acquire = 2000.0,
        -- Speed Base
        collision = 6,
        spd = 100,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        file = "war3mapImported\\[mushi]FleshBeast.mdx",
        Art = "ReplaceableTextures\\yeyankulou.blp",
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "埃辛诺斯烈焰",
        -- Scaling Value
        modelScale = 2.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Acquisition Range
        acquire = 2000.0,
        -- Speed Base
        collision = 6,
        spd = 100,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        file = "fireelementalgreen.mdx",
        Art = "ReplaceableTextures\\yeyankulou.blp",
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "莫罗",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        --rangeN1 = 200,
        acquire = 600,
        blue = 255,
        --collision = 200,
        scale = -1,
        dmgpt1 = 1,
        -- Attack 1 - Cooldown Time
        cool1 = 1,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\scourgemale.mdx",
        Art = "ReplaceableTextures\\moluo.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "hmpr",
        -- Name
        Name = "凯特琳娜",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        --rangeN1 = 200,
        acquire = 2000,
        blue = 255,
        --collision = 200,
        dmgpt1 = 1,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\HumanFemale_AbsolutionRegalia.mdx",
        Art = "ReplaceableTextures\\kaitelingna.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "罗宾公爵",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        --rangeN1 = 200,
        acquire = 2000,
        blue = 255,
        --collision = 200,
        dmgpt1 = 0.6,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\luobinggongjue.mdx",
        Art = "ReplaceableTextures\\luobinggongjue.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "克利斯平公爵",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        --rangeN1 = 200,
        acquire = 2000,
        blue = 255,
        --collision = 200,
        dmgpt1 = 0.7,
        -- Attack 1 - Cooldown Time
        cool1 = 2,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\Deathsworn000.mdx",
        Art = "ReplaceableTextures\\kelisipinggongjue.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "图书馆馆长",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 200,
        acquire = 600,
        blue = 255,
        scale = -1,
        collision = 100,
        -- Mana Initial Amount
        mana0 = 100,
        -- Mana Maximum
        manaN = 100,
        dmgpt1 = 0.6,
        -- Attack 1 - Cooldown Time
        cool1 = 2,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\ArcaneGolem - 2.mdx",
        Art = "ReplaceableTextures\\tushuguanguanzhang.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "夜之魇",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 200,
        acquire = 600,
        blue = 255,
        scale = -1,
        collision = 100,
        dmgpt1 = 1,
        -- Attack 1 - Cooldown Time
        cool1 = 2,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\nightbane2.mdx",
        Art = "ReplaceableTextures\\BTN_ZQ_00000007.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "hmpr",
        -- Name
        Name = "高阶术士",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 400,
        acquire = 400,
        blue = 255,
        --collision = 100,
        scale = -1,
        dmgpt1 = 0.3,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\[boss]FelOrcWarlock.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNChaosWarlock.blp",
        -- Race 取消等级显示
        race = "critters",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nogm",
        -- Name
        Name = "战争使者",
        file = "war3mapImported\\OgreMageLord00.mdx",
        Art = "ReplaceableTextures\\zhanzshizhe.blp",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        dmgpt1 = 0.6,
        -- Attack 1 - Cooldown Time
        cool1 = 1.6,
        scale = -1,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nogm",
        -- Name
        Name = "酋长卡加斯·刃拳",
        file = "war3mapImported\\Kargath.mdx",
        Art = "ReplaceableTextures\\kajias.blp",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        dmgpt1 = 0.6,
        scale = -1,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)



hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "野蛮卫兵",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        file = "war3mapImported\\Hero_Warfiend_Portrait.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNChaosGrunt.blp",
        green = 255,
        acquire = 400,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "狂暴卫兵",
        -- Scaling Value
        modelScale = 1.0,
        acquire = 400,
        red = 255,
        green = 255,
        blue = 255,
        file = "war3mapImported\\[guaiwu]ChaosGrunt.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNChaosGrunt.blp",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "ohun",
        -- Name
        Name = "射手卫兵",
        -- Scaling Value
        modelScale = 1.0,
        acquire = 600,
        red = 255,
        green = 255,
        file = "war3mapImported\\ChaosOrcCrossbowman.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNChaosGrunt.blp",
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "精英野蛮卫兵",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        file = "war3mapImported\\Hero_Warfiend_Portrait.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNChaosWolfRider.blp",
        green = 255,
        acquire = 400,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "精英狂暴卫兵",
        -- Scaling Value
        modelScale = 1.0,
        acquire = 400,
        red = 255,
        green = 255,
        blue = 255,
        file = "war3mapImported\\[guaiwu]ChaosGrunt.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNChaosWolfRider.blp",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "ohun",
        -- Name
        Name = "精英射手卫兵",
        -- Scaling Value
        modelScale = 1.0,
        acquire = 600,
        red = 255,
        green = 255,
        Art = "ReplaceableTextures\\CommandButtons\\BTNChaosWolfRider.blp",
        file = "war3mapImported\\ChaosOrcCrossbowman.mdx",
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "酋长的野蛮卫兵",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        file = "war3mapImported\\Hero_Warfiend_Portrait.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNChaosWolfRider.blp",
        green = 255,
        acquire = 2000,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "酋长的狂暴卫兵",
        -- Scaling Value
        modelScale = 1.0,
        acquire = 2000,
        red = 255,
        green = 255,
        blue = 255,
        file = "war3mapImported\\[guaiwu]ChaosGrunt.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNChaosWolfRider.blp",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "ohun",
        -- Name
        Name = "酋长的射手卫兵",
        -- Scaling Value
        modelScale = 1.0,
        acquire = 2000,
        red = 255,
        green = 255,
        file = "war3mapImported\\ChaosOrcCrossbowman.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNChaosWolfRider.blp",
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "要塞护卫军士",
        -- Scaling Value
        -- Speed Base
        spd = 400,
        modelScale = 1.0,
        file = "HeroBloodKnight9.mdx",
        Art = "ReplaceableTextures\\yaosaihuwei.blp",
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "要塞护卫军士长",
        -- Scaling Value
        -- Speed Base
        spd = 400,
        modelScale = 1.3,
        red = 255,
        file = "HeroBloodKnight9.mdx",
        Art = "ReplaceableTextures\\yaosaihuwei.blp",
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hmpr",
        -- Name
        Name = "虚空占卜者",
        file = "SorcerorV2.mdx",
        Art = "ReplaceableTextures\\yaosaihuwei.blp",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        -- Speed Base
        spd = 400,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "ohun",
        -- Name
        Name = "要塞斥候",
        file = "Hero_Demonhuntress.mdx",
        Art = "ReplaceableTextures\\yaosaifashi.blp",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        -- Speed Base
        spd = 400,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "精英要塞护卫军士",
        -- Speed Base
        spd = 400,
        file = "HeroBloodKnight9.mdx",
        Art = "ReplaceableTextures\\yaosaihuwei.blp",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hmpr",
        -- Name
        Name = "精英虚空占卜者",
        file = "SorcerorV2.mdx",
        Art = "ReplaceableTextures\\yaosaihuwei.blp",
        -- Scaling Value
        modelScale = 1.0,
        -- Speed Base
        spd = 400,
        red = 255,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "ohun",
        -- Name
        Name = "精英要塞斥候",
        file = "Hero_Demonhuntress.mdx",
        Art = "ReplaceableTextures\\yaosaifashi.blp",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        -- Speed Base
        spd = 400,
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)


hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "高阶护卫军士",
        file = "HeroBloodKnight9.mdx",
        Art = "ReplaceableTextures\\yaosaihuwei.blp",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        acquire = 2000,
        -- Speed Base
        spd = 400,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hmpr",
        -- Name
        Name = "高阶虚空占卜者",
        file = "SorcerorV2.mdx",
        Art = "ReplaceableTextures\\yaosaihuwei.blp",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        acquire = 2000,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        -- Speed Base
        spd = 400,
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "奥",
        -- Scaling Value
        modelScale = 0.8,
        red = 255,
        green = 255,
        rangeN1 = 200,
        acquire = 200,
        blue = 255,
        collision = 200,
        scale = -1,
        dmgpt1 = 1,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "Phoenix.mdx",
        Art = "zuoqi\\Inv_Misc_SummerFest_BrazierOrange.blp",
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "奥的子嗣",
        -- Scaling Value
        modelScale = 0.5,
        acquire = 2000,
        red = 255,
        green = 255,
        blue = 255,
        file = "Phoenix.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNChaosWolfRider.blp",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        -- Speed Base
        spd = 300,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "大星术师",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 200,
        acquire = 200,
        blue = 255,
        collision = 200,
        dmgpt1 = 1,
        scale = -1,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "PriestFemaleT8.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNJaina.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 1,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "首席技师泰隆尼卡斯",
        -- Scaling Value
        modelScale = 1.0,
        acquire = 2000,
        red = 255,
        green = 255,
        blue = 255,
        file = "SorcerorV2.mdx",
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "扭曲预言家萨拉瑞德",
        -- Scaling Value
        modelScale = 1.0,
        acquire = 2000,
        red = 255,
        green = 255,
        file = "HeroBloodKnight9.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNChaosWolfRider.blp",
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0,
        spd = 360,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "凯尔萨斯·逐日者",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 200,
        acquire = 200,
        blue = 255,
        collision = 200,
        dmgpt1 = 1,
        scale = -1,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "[boss]kaiersasi.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNHeroBloodElfPrince.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nfgu",
        -- Name
        Name = "恶魔卫士",
        --file = "SorcerorV2.mdx",
        --Art = "ReplaceableTextures\\yaosaihuwei.blp",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        _canBOPI = true,
        acquire = 500,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        -- Speed Base
        spd = 400,
        castpt = 0,
        --_canZHIBU = true
    }
)
hslk_unit(
    {
        _parent = "nsra",
        -- Name
        Name = "黑暗术士",
        --file = "SorcerorV2.mdx",
        --Art = "ReplaceableTextures\\yaosaihuwei.blp",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        acquire = 500,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        -- Speed Base
        spd = 400,
        castpt = 0,
        --_canZHIBU = true
    }
)
hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "主母赫拉姆斯",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 200,
        acquire = 400,
        blue = 255,
        collision = 100,
        scale = -1,
        dmgpt1 = 0.5,
        -- Attack 1 - Cooldown Time
        cool1 = 1,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\[boss]FelShivarra.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNNightElfRunner.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "玛兰德女士",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 800,
        acquire = 800,
        blue = 255,
        collision = 100,
        scale = -1,
        dmgpt1 = 1,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\HumanFemale_AbsolutionRegalia.mdx",
        Art = "ReplaceableTextures\\kaitelingna.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "粉碎者加西奥斯",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 150,
        acquire = 800,
        scale = -1,
        blue = 255,
        collision = 100,
        dmgpt1 = 1,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\luobinggongjue.mdx",
        Art = "ReplaceableTextures\\luobinggongjue.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "高阶虚空术士塞雷巴",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        scale = -1,
        green = 255,
        rangeN1 = 800,
        acquire = 800,
        blue = 255,
        collision = 100,
        dmgpt1 = 1,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\FiveFireballs.mdx",
        Art = "ReplaceableTextures\\dafashiailan.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "维拉斯·黑暗之影",
        -- Scaling Value
        modelScale = 1,
        scale = -1,
        red = 255,
        green = 255,
        rangeN1 = 150,
        acquire = 800,
        blue = 255,
        collision = 100,
        dmgpt1 = 1,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "war3mapImported\\scourgemale.mdx",
        Art = "ReplaceableTextures\\moluo.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "背叛者",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 200,
        acquire = 500,
        scale = -1,
        blue = 255,
        collision = 150,
        dmgpt1 = 0.6,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "Illidan Stormrage.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNEvilIllidan.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "军团恶魔领主布胖",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 200,
        acquire = 400,
        blue = 255,
        collision = 100,
        scale = -1,
        dmgpt1 = 0.7,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "brutallus.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNNightElfRunner.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 400,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "虚空生物穆鲁",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 200,
        acquire = 200,
        scale = -1,
        blue = 255,
        collision = 200,
        dmgpt1 = 1,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "Muru.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNBlackDragon.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 100,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbdo",
        -- Name
        Name = "基尔加丹",
        -- Scaling Value
        modelScale = 1,
        red = 255,
        green = 255,
        rangeN1 = 1000,
        acquire = 1000,
        blue = 255,
        collision = 300,
        scale = -1,
        dmgpt1 = 1,
        -- Attack 1 - Cooldown Time
        cool1 = 1.5,
        -- Normal
        abilList = chongjibo._id,
        file = "Kiljaeden.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNBlackDragon.blp",
        -- Race 取消等级显示
        race = "critters",
        unitSound = "AzureDragon",
        -- Speed Base
        spd = 1,
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "hrif",
        -- Name
        Name = "加特林教习",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        rangeN1 = 2000,
        acquire = 2000,
        cool1 = 1,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)
hslk_unit(
    {
        _parent = "ndqn",
        -- Name
        Name = "恶魔女妖",
        --file = "SorcerorV2.mdx",
        --Art = "ReplaceableTextures\\yaosaihuwei.blp",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        green = 255,
        blue = 255,
        acquire = 500,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        -- Speed Base
        spd = 400,
        castpt = 0,
        --_canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nfgu",
        -- Name
        Name = "神殿恶魔卫士",
        --file = "SorcerorV2.mdx",
        --Art = "ReplaceableTextures\\yaosaihuwei.blp",
        -- Scaling Value
        modelScale = 1.2,
        red = 255,
        green = 255,
        blue = 255,
        _canBOPI = true,
        acquire = 500,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        -- Speed Base
        spd = 400,
        castpt = 0,
        --_canZHIBU = true
    }
)
hslk_unit(
    {
        _parent = "nsra",
        -- Name
        Name = "神殿黑暗术士",
        --file = "SorcerorV2.mdx",
        --Art = "ReplaceableTextures\\yaosaihuwei.blp",
        -- Scaling Value
        modelScale = 1.2,
        red = 255,
        green = 255,
        blue = 255,
        acquire = 500,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        -- Speed Base
        spd = 400,
        castpt = 0,
        --_canZHIBU = true
    }
)
hslk_unit(
    {
        _parent = "ndqn",
        -- Name
        Name = "神殿恶魔女妖",
        --file = "SorcerorV2.mdx",
        --Art = "ReplaceableTextures\\yaosaihuwei.blp",
        -- Scaling Value
        modelScale = 1.2,
        red = 255,
        green = 255,
        blue = 255,
        acquire = 500,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        -- Speed Base
        spd = 400,
        castpt = 0,
        --_canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nsra",
        -- Name
        Name = "神殿黑暗侍女",
        file = "war3mapImported\\[pifu]M2.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNSorceress.blp",
        -- Scaling Value
        modelScale = 1.2,
        red = 255,
        green = 255,
        blue = 255,
        acquire = 500,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        -- Speed Base
        spd = 400,
        castpt = 0,
        _canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nsra",
        -- Name
        Name = "恶魔之子",
        --file = "SorcerorV2.mdx",
        --Art = "ReplaceableTextures\\yaosaihuwei.blp",
        -- Scaling Value
        modelScale = 1.2,
        red = 255,
        green = 255,
        blue = 255,
        acquire = 3000,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        -- Speed Base
        spd = 400,
        castpt = 0,
        --_canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "nsra",
        -- Name
        Name = "欺诈者之手",
        --file = "SorcerorV2.mdx",
        --Art = "ReplaceableTextures\\yaosaihuwei.blp",
        -- Scaling Value
        modelScale = 1.2,
        red = 255,
        green = 255,
        blue = 255,
        acquire = 1000,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        -- Speed Base
        spd = 400,
        castpt = 0,
        --_canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "魔能灌注卫士",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        file = "war3mapImported\\Hero_Warfiend_Portrait.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNChaosWolfRider.blp",
        green = 255,
        acquire = 3000,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nsra",
        -- Name
        Name = "魔能灌注法师",
        --file = "SorcerorV2.mdx",
        --Art = "ReplaceableTextures\\yaosaihuwei.blp",
        -- Scaling Value
        modelScale = 1.2,
        red = 255,
        green = 255,
        blue = 255,
        acquire = 3000,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        -- Speed Base
        spd = 400,
        castpt = 0,
        --_canZHIBU = true
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "恶魔镜像",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        file = "war3mapImported\\Hero_Warfiend_Portrait.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNChaosWolfRider.blp",
        green = 255,
        acquire = 3000,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbal",
        -- Name
        Name = "末日护卫",
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nbal",
        -- Name
        Name = "精英末日护卫",
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nskm",
        -- Name
        Name = "末日弓箭手",
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "nskm",
        -- Name
        Name = "精英末日弓箭手",
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "ninf",
        -- Name
        Name = "恶魔地狱火",
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "ninf",
        -- Name
        Name = "精英恶魔地狱火",
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "恶魔狂战士",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        file = "war3mapImported\\[guaiwu]heimiaoFelGuardBarbarian.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNFelGuard.blp",
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Name
        Name = "精英恶魔狂战士",
        -- Scaling Value
        modelScale = 1.0,
        red = 255,
        file = "war3mapImported\\[guaiwu]heimiaoFelGuardBarbarian.mdx",
        Art = "ReplaceableTextures\\CommandButtons\\BTNFelGuard.blp",
        green = 255,
        blue = 255,
        -- Normal
        abilList = chongjibo._id,
        -- Race 取消等级显示
        race = "critters",
        castpt = 0
    }
)
