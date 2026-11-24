local duihua =
    hslk_item(
        {
            _parent = "stwp",
            _id_force = "I100",
            -- Interface Icon
            Art = "ReplaceableTextures\\xitong\\BTNTalking2.blp",
            -- Button Position (X)
            Buttonpos_1 = 0,
            -- Button Position (Y)
            Buttonpos_2 = 0,
            -- Description
            Description = "与NPC对话获取信息",
            -- Hotkey
            Hotkey = "D",
            -- Name
            Name = "对话",
            -- Requirements
            Requires = "",
            -- Tooltip - Basic
            Tip = "对话",
            -- Tooltip - Extended
            Ubertip = "与NPC对话",
            -- Abilities
            abilList = "",
            -- Classification
            class = "PowerUp",
            -- Model Used
            file = "war3mapImported\\treasurechest.mdl",
            _bypassDynamicItemCheck = true,
            -- Gold Cost
            goldcost = 0,
            -- Use Automatically When Acquired
            powerup = 1,
            -- Stock Maximum
            stockMax = 1,
            -- Stock Replenish Interval
            stockRegen = 1,
            -- Stock Start Delay
            stockStart = 1
        }
    )

local jiaoyi =
    hslk_item(
        {
            _parent = "stwp",
            _id_force = "I105",
            -- Interface Icon
            Art = "ReplaceableTextures\\CommandButtons\\BTNGLExchange.blp",
            -- Button Position (X)
            Buttonpos_1 = 0,
            -- Button Position (Y)
            Buttonpos_2 = 0,
            -- Description
            Description = "与NPC对话进行交易",
            -- Hotkey
            Hotkey = "J",
            -- Name
            Name = "交易",
            -- Requirements
            Requires = "",
            -- Tooltip - Basic
            Tip = "交易",
            -- Tooltip - Extended
            Ubertip = "与NPC交易，包括购买物品，进行挑战以及其他功能",
            -- Abilities
            abilList = "",
            -- Classification
            class = "PowerUp",
            -- Model Used
            file = "war3mapImported\\treasurechest.mdl",
            _bypassDynamicItemCheck = true,
            -- Gold Cost
            goldcost = 0,
            -- Use Automatically When Acquired
            powerup = 1,
            -- Stock Maximum
            stockMax = 1,
            -- Stock Replenish Interval
            stockRegen = 1,
            -- Stock Start Delay
            stockStart = 1
        }
    )

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "新手村村长",
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "units\\creeps\\Medivh\\Medivh",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

local qianghua =
    hslk_item(
        {
            _parent = "stwp",
            _id_force = "I101",
            -- Interface Icon
            Art = "ReplaceableTextures\\duanzao\\duanzao.blp",
            -- Button Position (X)
            Buttonpos_1 = 0,
            -- Button Position (Y)
            Buttonpos_2 = 0,
            -- Description
            Description = "强化物品栏第一格的装备",
            -- Hotkey
            Hotkey = "Q",
            -- Name
            Name = "强化",
            -- Requirements
            Requires = "",
            -- Tooltip - Basic
            Tip = "强化",
            -- Tooltip - Extended
            Ubertip =
            "消耗金币|cffffcc00强化|r物品栏第一格的装备，最高可以强化到+9。强化可以增加装备的基础属性（白色词条），无法增幅绿色固有词条和随机词条。|n|cffffcc00金币消耗|r：强化等级乘以100（普通）/200（精良）/300（史诗）/400（传奇），同时装备等级越高，需要的金币也越多。|n|cff00ff00强化成功率|r：（0-1）100%，（1-2）50%，（2-3）40%，（3-4）30%，（4-5）20%，（5-6）20%，（6-7）20%，（7-8）20%，（8-9）20%|n|cff00ff00强化掉级率|r：0%，0%，0%，5%，5%，5%，10%，10%，10%|n|cff00ff00强化清零率|r：0%，0%，0%，0%，0%，0%，0%，0%，2%|n|cff00ff00基础属性加成|r：2%，5%，8%，12%，16%，20%，25%，30%，40%",
            -- Abilities
            abilList = "",
            -- Classification
            class = "PowerUp",
            -- Model Used
            file = "war3mapImported\\treasurechest.mdl",
            _bypassDynamicItemCheck = true,
            -- Gold Cost
            goldcost = 0,
            -- Use Automatically When Acquired
            powerup = 1,
            -- Stock Maximum
            stockMax = 1,
            -- Stock Replenish Interval
            stockRegen = 1,
            -- Stock Start Delay
            stockStart = 1
        }
    )

local jinglian =
    hslk_item(
        {
            _parent = "stwp",
            _id_force = "I102",
            -- Interface Icon
            Art = "ReplaceableTextures\\duanzao\\duanzao.blp",
            -- Button Position (X)
            Buttonpos_1 = 0,
            -- Button Position (Y)
            Buttonpos_2 = 0,
            -- Description
            Description = "精炼",
            -- Hotkey
            Hotkey = "W",
            -- Name
            Name = "精炼",
            -- Requirements
            Requires = "",
            -- Tooltip - Basic
            Tip = "精炼",
            -- Tooltip - Extended
            Ubertip =
            "消耗金币|cffffcc00精炼|r物品栏第一格的装备，最高可以精炼到+9。精炼可以增加装备的随机词条属性，无法白色词条和固有词条（绿色）。|n|cffffcc00金币消耗|r：精炼等级乘以100（普通）/200（精良）/300（史诗）/400（传奇），同时装备等级越高，需要的金币也越多。|n|cff00ff00精炼成功率|r：（0-1）100%，（1-2）50%，（2-3）40%，（3-4）30%，（4-5）20%，（5-6）20%，（6-7）20%，（7-8）20%，（8-9）20%|n|cff00ff00精炼掉级率|r：0%，0%，0%，5%，5%，5%，10%，10%，10%|n|cff00ff00精炼清零率|r：0%，0%，0%，0%，0%，0%，0%，0%，2%|n|cff00ff00词条属性加成|r：3%，6%，9%，12%，15%，18%，21%，24%，30%",
            -- Abilities
            abilList = "",
            -- Classification
            class = "PowerUp",
            -- Model Used
            file = "war3mapImported\\treasurechest.mdl",
            _bypassDynamicItemCheck = true,
            -- Gold Cost
            goldcost = 0,
            -- Use Automatically When Acquired
            powerup = 1,
            -- Stock Maximum
            stockMax = 1,
            -- Stock Replenish Interval
            stockRegen = 1,
            -- Stock Start Delay
            stockStart = 1
        }
    )

local xilian =
    hslk_item(
        {
            _parent = "stwp",
            _id_force = "I106",
            -- Interface Icon
            Art = "ReplaceableTextures\\duanzao\\duanzao.blp",
            -- Button Position (X)
            Buttonpos_1 = 0,
            -- Button Position (Y)
            Buttonpos_2 = 0,
            -- Description
            Description = "洗练",
            -- Hotkey
            Hotkey = "W",
            -- Name
            Name = "洗练",
            -- Requirements
            Requires = "",
            -- Tooltip - Basic
            Tip = "洗练",
            -- Tooltip - Extended
            Ubertip =
            "消耗装备|cffffcc00洗练|r物品栏第一格的装备，该过程可以重置装备的随机词条。洗练需要将两个相同物品等级，物品名称，物品品质，物品难度等级的装备放在第一格和第二格，第一格为被洗练装备，第二格为要消耗的装备。",
            -- Abilities
            abilList = "",
            -- Classification
            class = "PowerUp",
            -- Model Used
            file = "war3mapImported\\treasurechest.mdl",
            _bypassDynamicItemCheck = true,
            -- Gold Cost
            goldcost = 0,
            -- Use Automatically When Acquired
            powerup = 1,
            -- Stock Maximum
            stockMax = 1,
            -- Stock Replenish Interval
            stockRegen = 1,
            -- Stock Start Delay
            stockStart = 1
        }
    )

local gaojixilian =
    hslk_item(
        {
            _parent = "stwp",
            _id_force = "I106",
            -- Interface Icon
            Art = "ReplaceableTextures\\duanzao\\duanzao.blp",
            -- Button Position (X)
            Buttonpos_1 = 0,
            -- Button Position (Y)
            Buttonpos_2 = 0,
            -- Description
            Description = "洗练",
            -- Hotkey
            Hotkey = "W",
            -- Name
            Name = "高级洗练",
            -- Requirements
            Requires = "",
            -- Tooltip - Basic
            Tip = "洗练",
            -- Tooltip - Extended
            Ubertip = "消耗洗练石|cffffcc00洗练|r物品栏第一格的装备，该过程可以重置装备的随机词条。洗练需要消耗一个对应级别的洗练石。63级及以下的装备需要消耗初级洗练石。",
            -- Abilities
            abilList = "",
            -- Classification
            class = "PowerUp",
            -- Model Used
            file = "war3mapImported\\treasurechest.mdl",
            _bypassDynamicItemCheck = true,
            -- Gold Cost
            goldcost = 0,
            -- Use Automatically When Acquired
            powerup = 1,
            -- Stock Maximum
            stockMax = 1,
            -- Stock Replenish Interval
            stockRegen = 1,
            -- Stock Start Delay
            stockStart = 1
        }
    )

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "受伤的农夫",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "猎人阿普",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "克文",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

local zhurongji =
    hslk_item(
        {
            _parent = "blba",
            _id_force = "I103",
            -- Interface Icon
            Art = "ReplaceableTextures\\caikuang\\INV_Misc_Ammo_Gunpowder_01.blp",
            -- Button Position (X)
            Buttonpos_1 = 0,
            -- Button Position (Y)
            Buttonpos_2 = 0,
            -- Description
            Description = "一种常见的道具，可以帮助装备锻造",
            -- Name
            Name = "助熔剂",
            -- Requirements
            Requires = "",
            Ubertip = "用于盛放药剂的容器，可以从炼金师那里买到",
            -- Abilities
            abilList = "",
            -- Classification
            class = "Charged",
            -- Model Used
            file = "war3mapImported\\treasurechest.mdl",
            -- Gold Cost
            goldcost = 0,
            -- Use Automatically When Acquired
            powerup = 0,
            -- Stock Maximum
            stockMax = 10,
            -- Stock Replenish Interval
            stockRegen = 5,
            -- Stock Start Delay
            stockStart = 5
        }
    )

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "铁匠哈特",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id ..
            "," ..
            jiaoyi._id .. "," .. qianghua._id .. "," .. jinglian._id .. "," .. xilian._id .. "," .. gaojixilian._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

local kuanshi =
    hslk_unit(
        {
            _parent = "hpea",
            -- Structures Built
            Builds = "",
            -- Name - Editor Suffix
            EditorSuffix = "NPC",
            -- Name
            Name = "铁矿",
            -- Items Sold
            -- Sellitems = caijiziyuan._id,
            -- Normal
            abilList = "Aneu,Avul,Apit",
            -- Model File
            file = "war3mapImported\\gold_Miningnode_01",
            -- Food Cost
            fused = 0,
            -- Hide Minimap Display
            hideOnMinimap = 1,
            -- Selection Scale
            scale = -1.0,
            -- Speed Base
            spd = 0,
            -- Unit Classification
            type = "",
            -- Shadow Image (Unit)
            unitShadow = "ShadowFlyer",
            -- Upgrades Used
            upgrades = "",
            -- Attacks Enabled
            weapsOn = 0,
            modelScale = 0.5,
            _canCAIKUANG = true
        }
    )

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "精铁矿",
        -- Items Sold
        -- Sellitems = caijiziyuan._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "war3mapImported\\gold_Miningnode_01",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0,
        modelScale = 0.5,
        _canCAIKUANG = true
    }
)

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "秘银矿",
        -- Items Sold
        -- Sellitems = caijiziyuan._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "war3mapImported\\gold_Miningnode_01",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0,
        modelScale = 0.5,
        _canCAIKUANG = true
    }
)

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "精金矿",
        -- Items Sold
        -- Sellitems = caijiziyuan._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "war3mapImported\\gold_Miningnode_01",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0,
        modelScale = 0.5,
        _canCAIKUANG = true
    }
)

local pingzi =
    hslk_item(
        {
            _parent = "blba",
            _id_force = "I104",
            Name = "瓶子",
            Art = "ReplaceableTextures\\lianjin\\INV_Alchemy_LeadedVial.blp",
            hitem_type = "材料",
            Description = "用于盛放药剂的容器，可以从炼金师那里买到",
            min_pinzhi = 1,
            -- Tooltip - Basic
            Tip = "",
            -- Tooltip - Extended
            Ubertip = "用于盛放药剂的容器，可以从炼金师那里买到",
            abilList = "",
            class = "Charged",
            perishable = 1,
            -- Gold Cost
            goldcost = 500,
            -- Use Automatically When Acquired
            powerup = 0,
            -- Stock Maximum
            stockMax = 10,
            -- Stock Replenish Interval
            stockRegen = 5,
            -- Stock Start Delay
            stockStart = 5
        }
    )

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "药剂学徒瑞克",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

local caoyao =
    hslk_unit(
        {
            _parent = "hpea",
            -- Structures Built
            Builds = "",
            -- Name - Editor Suffix
            EditorSuffix = "NPC",
            -- Name
            Name = "基础草药",
            -- Items Sold
            -- Sellitems = caijiziyuan._id,
            -- Normal
            abilList = "Aneu,Avul,Apit",
            -- Model File
            file = "war3mapImported\\UE11301.mdx",
            -- Food Cost
            fused = 0,
            -- Hide Minimap Display
            hideOnMinimap = 1,
            -- Selection Scale
            scale = 1.0,
            -- Speed Base
            spd = 0,
            -- Unit Classification
            type = "",
            -- Shadow Image (Unit)
            unitShadow = "ShadowFlyer",
            -- Upgrades Used
            upgrades = "",
            -- Attacks Enabled
            weapsOn = 0,
            modelScale = 1,
            _caiyaoLevel = 0,
            _canCAIYAO = true
        }
    )

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "金色草药",
        -- Items Sold
        -- Sellitems = caijiziyuan._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "war3mapImported\\UE11301.mdx",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = 1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0,
        modelScale = 1,
        _caiyaoLevel = 0,
        _canCAIYAO = true
    }
)

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "沙漠草药",
        -- Items Sold
        -- Sellitems = caijiziyuan._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "war3mapImported\\UE11301.mdx",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = 1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0,
        modelScale = 1,
        _caiyaoLevel = 0,
        _canCAIYAO = true
    }
)

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "汲血草药",
        -- Items Sold
        -- Sellitems = caijiziyuan._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "war3mapImported\\UE11301.mdx",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = 1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0,
        modelScale = 1,
        _caiyaoLevel = 0,
        _canCAIYAO = true
    }
)

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "新手村钓鱼点",
        -- Items Sold
        -- Sellitems = caijiziyuan._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "[diaoyu]yu.mdx",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0,
        modelScale = 0.5,
        _canDIAOYU = true
    }
)

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "王城喷泉",
        -- Items Sold
        -- Sellitems = caijiziyuan._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "war3mapImported\\BE_Fountain01.mdl",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        collision = 200,
        -- Attacks Enabled
        weapsOn = 0,
        modelScale = 1,
        _canDIAOYU = true
    }
)

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "沙漠深井",
        -- Items Sold
        -- Sellitems = caijiziyuan._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "[diaoyu]shuijing.mdx",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = 1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0,
        modelScale = 0.5,
        _canDIAOYU = true
    }
)

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "和平之城钓鱼点",
        -- Items Sold
        -- Sellitems = caijiziyuan._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "[diaoyu]yu.mdx",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        collision = 300,
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0,
        modelScale = 1.0,
        _canDIAOYU = true
    }
)

hslk_unit(
    {
        _parent = "hhes",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "新手教官",
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        modelScale = 1.2,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nchp",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "资深牧师萨缪尔",
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        modelScale = 1.2,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nmed",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "历史学家埃尔文",
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        modelScale = 1.2,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nhem",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "炼金师塞德里克",
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        modelScale = 1.2,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "资深铁匠加里克",
        -- Items Sold
        Sellitems = duihua._id ..
            "," ..
            jiaoyi._id .. "," .. qianghua._id .. "," .. jinglian._id .. "," .. xilian._id .. "," .. gaojixilian._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        modelScale = 1.2,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "Hapm",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "城主约翰",
        Propernames = "约翰",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "王牌卧底德尼尔",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hfoo",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "竞技场大师凯德",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nchp",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "附魔大师加夫里尔",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nchp",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "制皮大师莱瑟",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nchp",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "裁缝大师马斯特",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nchp",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "珠宝大师索恩",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nbee",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "军需处长谭恩",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nbee",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "冒险者工会会长",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "war3mapImported\\[npc]mimiron.mdx",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "副本传送门",
        -- Items Sold
        Sellitems = "",
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "war3mapImported\\[AZ]chuansongmen.mdx",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hhes",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "王城总教头",
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "war3mapImported\\[npc]Footman Hero.mdx",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        modelScale = 1.2,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hhes",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "王城禁军",
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        modelScale = 1.2,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hhes",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "和平之城守卫",
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        modelScale = 1.2,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hhes",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "钓鱼大师派罗",
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "units\\creeps\\Medivh\\Medivh",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        modelScale = 1.2,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hhes",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "传说中的钓鱼佬",
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "units\\creeps\\Medivh\\Medivh",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        modelScale = 1.2,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hhes",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "守备官斯通哈特",
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        modelScale = 1.2,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hhes",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "传奇铁匠福吉菲尔",
        -- Items Sold
        Sellitems = duihua._id ..
            "," ..
            jiaoyi._id .. "," .. qianghua._id .. "," .. jinglian._id .. "," .. xilian._id .. "," .. gaojixilian._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "units\\human\\HeroMountainKing\\HeroMountainKing",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        modelScale = 1.2,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hhes",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "虚空商人",
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "war3mapImported\\[guaiwu]EtherialRobeBBlack.mdx",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        modelScale = 0.65,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "ogru",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "兽人老兵火刃",
        -- Items Sold
        Sellitems = duihua._id ..
            "," ..
            jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        modelScale = 1.2,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "ogru",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "纳鲁",
        -- Items Sold
        Sellitems = duihua._id ..
            "," ..
            jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "war3mapImported\\[NPC]NaaruWhite.mdx",
        -- Food Cost
        fused = 0,
        modelScale = 1.5,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nbee",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "正义军需官",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nbee",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "秩序军需官",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nbee",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "秘法军需官",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)
hslk_unit(
    {
        _parent = "nbee",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "魔能军需官",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)
hslk_unit(
    {
        _parent = "nbee",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "邪恶军需官",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)
hslk_unit(
    {
        _parent = "nbee",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "恶魔军需官",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nbee",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "法师叛徒瑞斯",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "war3mapImported\\BloodElvenMagister.mdx",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hpea",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "受伤的小黑子",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hhes",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "护卫队长彼得",
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "war3mapImported\\[npc]Footman Hero.mdx",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        modelScale = 1.2,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "hhes",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "老兵格雷戈",
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        modelScale = 1.2,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nchp",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "铭文大师德拉里",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nbee",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "老法师奥利弗",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "war3mapImported\\[pifu]F1.mdx",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nbee",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "阿卡玛",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "units\\other\\DranaiMage\\DranaiMage",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nbee",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "辉煌军需官",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)
hslk_unit(
    {
        _parent = "nbee",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "凯旋军需官",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        --file = "units\\human\\Peasant\\Peasant",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nbee",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "温蕾萨·风行者",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "units\\creeps\\SylvanusWindrunner\\SylvanusWindrunner",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)

hslk_unit(
    {
        _parent = "nbee",
        -- Structures Built
        Builds = "",
        -- Name - Editor Suffix
        EditorSuffix = "NPC",
        -- Name
        Name = "奥蕾莉亚·风行者",
        modelScale = 1.2,
        -- Items Sold
        Sellitems = duihua._id .. "," .. jiaoyi._id,
        -- Normal
        abilList = "Aneu,Avul,Apit",
        -- Model File
        file = "units\\creeps\\SylvanusWindrunner\\SylvanusWindrunner",
        -- Food Cost
        fused = 0,
        -- Hide Minimap Display
        hideOnMinimap = 1,
        -- Selection Scale
        scale = -1.0,
        -- Speed Base
        spd = 0,
        -- Unit Classification
        type = "",
        -- Shadow Image (Unit)
        unitShadow = "ShadowFlyer",
        -- Upgrades Used
        upgrades = "",
        -- Attacks Enabled
        weapsOn = 0
    }
)
