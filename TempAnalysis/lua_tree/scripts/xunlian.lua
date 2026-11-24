function initXunlian()
    local exampleConfig = {
        {
            name = "初级属性训练",
            cundangStr = "xunlian",
            isPerHero = true,
            cunDangStartIndex = 1,
            cunDangEndIndex = 3,
            art = "ReplaceableTextures\\status\\INV_Sword_04.blp",
            description = "进行基础训练以增加主属性。请寻找新手教官来开启训练。",
            currentLevel = 0,
            attributePerLevel = _attr({ zhushuxing = "+2" }),
            maxLevel = 20
        },
        {
            name = "中级属性训练",
            cundangStr = "xunlian",
            isPerHero = true,
            cunDangStartIndex = 4,
            cunDangEndIndex = 6,
            art = "ReplaceableTextures\\status\\INV_Sword_05.blp",
            description = "进行中级训练以增加主属性。请寻找王城总教头来开启训练。",
            currentLevel = 0,
            attributePerLevel = _attr({ zhushuxing = "+3" }),
            maxLevel = 20
        },
        {
            name = "初级会心训练",
            cundangStr = "xunlian",
            isPerHero = true,
            cunDangStartIndex = 7,
            cunDangEndIndex = 9,
            art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_HAND_08.blp",
            description = "进行初级会心训练以增加暴击属性。请寻找王城总教头来开启训练。",
            currentLevel = 0,
            attributePerLevel = _attr({ wu_bao = "+0.1", fa_bao = "+0.1" }),
            maxLevel = 10
        },
        {
            name = "初级速度训练",
            cundangStr = "xunlian",
            isPerHero = true,
            cunDangStartIndex = 10,
            cunDangEndIndex = 12,
            art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_HAND_08.blp",
            description = "进行初级速度训练以增加攻击和施法速度。请寻找王城总教头来开启训练。",
            currentLevel = 0,
            attributePerLevel = _attr({ attack_speed = "+0.1", skill_speed = "+0.05" }),
            maxLevel = 10
        },
        {
            name = "高级属性训练",
            cundangStr = "xunlian",
            isPerHero = true,
            cunDangStartIndex = 13,
            cunDangEndIndex = 15,
            art = "ReplaceableTextures\\status\\INV_Sword_05.blp",
            description = "进行高级训练以增加主属性。请寻找老兵格雷戈来开启训练。",
            currentLevel = 0,
            attributePerLevel = _attr({ zhushuxing = "+4" }),
            maxLevel = 20
        },
        {
            name = "中级会心训练",
            cundangStr = "xunlian",
            isPerHero = true,
            cunDangStartIndex = 16,
            cunDangEndIndex = 18,
            art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_HAND_08.blp",
            description = "进行初级会心训练以增加暴击属性。请寻找老兵格雷戈来开启训练。",
            currentLevel = 0,
            attributePerLevel = _attr({ wu_bao = "+0.15", fa_bao = "+0.15" }),
            maxLevel = 10
        },
        {
            name = "中级速度训练",
            cundangStr = "xunlian",
            isPerHero = true,
            cunDangStartIndex = 19,
            cunDangEndIndex = 21,
            art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_HAND_08.blp",
            description = "进行初级速度训练以增加攻击和施法速度。请寻找老兵格雷戈来开启训练。",
            currentLevel = 0,
            attributePerLevel = _attr({ attack_speed = "+0.2", skill_speed = "+0.1" }),
            maxLevel = 10
        },
        {
            name = "初级皇家挑战",
            cundangStr = "xunlian",
            isPerHero = true,
            cunDangStartIndex = 22,
            cunDangEndIndex = 24,
            art = "ReplaceableTextures\\zhuangbei\\INV_WEAPON_HAND_08.blp", --TODO
            description = "进行皇家挑战训练以增加伤害能力。请寻找王城总教头来开启训练。他在王城北边的城外。",
            currentLevel = 0,
            attributePerLevel = _attr({ quanju_zengshang = "+0.1" }),
            maxLevel = 10
        },
        {
            name = "专家级属性训练",
            cundangStr = "xunlian",
            isPerHero = true,
            cunDangStartIndex = 25,
            cunDangEndIndex = 27,
            art = "ReplaceableTextures\\CommandButtons\\BTNThoriumMelee.blp",
            description = "进行专家级训练以增加主属性。请寻找和平之城护卫队长彼得来开启训练。",
            currentLevel = 0,
            attributePerLevel = _attr({ zhushuxing = "+5" }),
            maxLevel = 50
        },
        {
            name = "初级耐久训练",
            cundangStr = "xunlian",
            isPerHero = true,
            cunDangStartIndex = 28,
            cunDangEndIndex = 30,
            art = "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpOne.blp",
            description = "进行初级耐久训练以增加生命最大值。请寻新手教官来开启训练。",
            currentLevel = 0,
            attributePerLevel = _attr({ life = "+5" }),
            maxLevel = 20
        },
        {
            name = "中级耐久训练",
            cundangStr = "xunlian",
            isPerHero = true,
            cunDangStartIndex = 31,
            cunDangEndIndex = 33,
            art = "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpOne.blp",
            description = "进行中级耐久训练以增加生命最大值。请寻找王城总教头来开启训练。",
            currentLevel = 0,
            attributePerLevel = _attr({ life = "+15" }),
            maxLevel = 20
        },
        {
            name = "高级耐久训练",
            cundangStr = "xunlian",
            isPerHero = true,
            cunDangStartIndex = 34,
            cunDangEndIndex = 36,
            art = "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpTwo.blp",
            description = "进行高级耐久训练以增加生命最大值。请寻找老兵格雷戈来开启训练。",
            currentLevel = 0,
            attributePerLevel = _attr({ life = "+30" }),
            maxLevel = 20
        },
        {
            name = "专家级耐久训练",
            cundangStr = "xunlian",
            isPerHero = true,
            cunDangStartIndex = 37,
            cunDangEndIndex = 39,
            art = "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpTwo.blp",
            description = "进行专家级耐久训练以增加生命最大值。请寻找和平之城护卫队长彼得来开启训练。",
            currentLevel = 0,
            attributePerLevel = _attr({ life = "+30" }),
            maxLevel = 50
        },
    }
    hxunlian.init(exampleConfig)
end
