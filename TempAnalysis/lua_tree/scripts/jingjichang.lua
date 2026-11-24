function initJingjichang()
    local config = {
        {
            name = "1v1",
            place = "鲜血竞技场",
            npcName = "竞技场大师凯德",
            art = "ReplaceableTextures\\BTNzb71.blp",
            tips = "解决恩怨的最佳方式就是决斗，来一场酣畅淋漓的决斗吧！耍嘴皮子是懦夫的方式。请竞技双方在旁边的红色和蓝色旗帜周围准备，再来找我开启决斗。",
            groupAx = -27637,
            groupAy = -14844,
            groupAStartx = 4113,
            groupAStarty = -12640,
            groupBx = -27622,
            groupBy = -15539,
            groupBStartx = 6669,
            groupBStarty = -15569,
            count = 1,
            cost = {{type = HSHOP_COST_TYPE.gold, value = 1000}},
            requirement = {},
            isActive = false,
            timeout = 60
        },
        {
            name = "2v2",
            place = "鲜血竞技场",
            npcName = "竞技场大师凯德",
            art = "ReplaceableTextures\\BTNzb71.blp",
            tips = "解决恩怨的最佳方式就是决斗，来一场酣畅淋漓的决斗吧！耍嘴皮子是懦夫的方式。请竞技双方在旁边的红色和蓝色旗帜周围准备，再来找我开启决斗。",
            groupAx = -27637,
            groupAy = -14844,
            groupAStartx = 4113,
            groupAStarty = -12640,
            groupBx = -27622,
            groupBy = -15539,
            groupBStartx = 6669,
            groupBStarty = -15569,
            count = 2,
            cost = {{type = HSHOP_COST_TYPE.gold, value = 1000}},
            requirement = {},
            isActive = false,
            timeout = 60
        },
        {
            name = "3v3",
            place = "鲜血竞技场",
            npcName = "竞技场大师凯德",
            art = "ReplaceableTextures\\BTNzb71.blp",
            tips = "解决恩怨的最佳方式就是决斗，来一场酣畅淋漓的决斗吧！耍嘴皮子是懦夫的方式。请竞技双方在旁边的红色和蓝色旗帜周围准备，再来找我开启决斗。",
            groupAx = -27637,
            groupAy = -14844,
            groupAStartx = 4113,
            groupAStarty = -12640,
            groupBx = -27622,
            groupBy = -15539,
            groupBStartx = 6669,
            groupBStarty = -15569,
            count = 3,
            cost = {{type = HSHOP_COST_TYPE.gold, value = 1000}},
            requirement = {},
            isActive = false,
            timeout = 60
        }
    }

    local areaConfig = {
        {
            name = "鲜血竞技场",
            minX = 3705,
            minY = -16132,
            maxX = 7171,
            maxY = -12160,
            blp = "ReplaceableTextures\\xiaoditu\\UI_map_19.blp",
            titleArt = "ReplaceableTextures\\xiaoditu\\ui_map_show_19.blp"
        }
    }
    hjingjichang.init(config, areaConfig)
end
