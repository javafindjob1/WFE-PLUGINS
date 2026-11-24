function initShengWang()
    local config = {
        {
            name = "新手村",
            cundangStr = "shengwang",
            isPerHero = true,
            lvlCunDangStartIndex = 1,
            lvlCunDangEndIndex = 1,
            expCunDangStartIndex = 2,
            expCunDangEndIndex = 6,
            currentExp = 0,
            currentLevel = 0,
            description = "一切开始的地方，提高声望可以获得不错的属性奖励和便宜材料的购买权。可以在新手村村长那里查询可以购买物品。",
            art = hslk.n2v("新手村村长", "slk", "Art"),
            attr = {
                _attr({life_back = "+5"}), --友善
                _attr({life_back = "+10"}), --尊敬
                _attr({life_back = "+20"}), --崇敬
                _attr({life_back = "+32"}) --崇拜
            }
        },
        {
            name = "王城",
            cundangStr = "shengwang",
            isPerHero = true,
            lvlCunDangStartIndex = 7,
            lvlCunDangEndIndex = 7,
            expCunDangStartIndex = 8,
            expCunDangEndIndex = 12,
            currentExp = 0,
            currentLevel = 0,
            description = "大陆最繁华的城市之一，声望的用处也很大。可以在王城的军需官处查看可购买物品。",
            art = hslk.n2v("城主约翰", "slk", "Art"),
            attr = {
                _attr({mokang = "+0.5"}), --友善
                _attr({mokang = "+1"}), --尊敬
                _attr({mokang = "+1.5"}), --崇敬
                _attr({mokang = "+2"}) --崇拜
            }
        },
        {
            name = "峡谷前哨站",
            cundangStr = "shengwang",
            isPerHero = true,
            lvlCunDangStartIndex = 13,
            lvlCunDangEndIndex = 13,
            expCunDangStartIndex = 14,
            expCunDangEndIndex = 18,
            currentExp = 0,
            currentLevel = 0,
            description = "灼热峡谷的前哨站。",
            art = hslk.n2v("守备官斯通哈特", "slk", "Art"),
            attr = {
                _attr({wu_chuan = "+1", fa_chuan = "+1"}), --友善
                _attr({wu_chuan = "+1.5", fa_chuan = "+1.5"}), --尊敬
                _attr({wu_chuan = "+2", fa_chuan = "+2"}), --崇敬
                _attr({wu_chuan = "+2.5", fa_chuan = "+2.5"}) --崇拜
            }
        },
        {
            name = "冒险者工会",
            cundangStr = "shengwang",
            isPerHero = true,
            lvlCunDangStartIndex = 19,
            lvlCunDangEndIndex = 19,
            expCunDangStartIndex = 20,
            expCunDangEndIndex = 24,
            currentExp = 0,
            currentLevel = 0,
            description = "冒险者组成的工会，总部在王城，里面有许多好东西。",
            art = "ReplaceableTextures\\shangcheng\\baoshi6.blp",
            attr = {
                _attr({quanju_zengshang = "+0.5"}), --友善
                _attr({quanju_zengshang = "+1.0"}), --尊敬
                _attr({quanju_zengshang = "+1.5"}), --崇敬
                _attr({quanju_zengshang = "+2"}) --崇拜
            }
        },
        {
            name = "和平之城",
            cundangStr = "shengwang",
            isPerHero = true,
            lvlCunDangStartIndex = 25,
            lvlCunDangEndIndex = 25,
            expCunDangStartIndex = 26,
            expCunDangEndIndex = 30,
            currentExp = 0,
            currentLevel = 0,
            description = "纷争之地唯一的净土。",
            art = hslk.n2v("新手村村长", "slk", "Art"),
            attr = {
                _attr({wu_bao = "+0.2", fa_bao = "+0.2"}), --友善
                _attr({wu_bao = "+0.4", fa_bao = "+0.4"}), --尊敬
                _attr({wu_bao = "+0.6", fa_bao = "+0.6"}), --崇敬
                _attr({wu_bao = "+1", fa_bao = "+1"}) --崇拜
            }
        }
    }
    hshengwang.initFromConfig(config)
end
