initDaixin = function()
    local config = {
        fuben = {
            { name = "火焰之心", nandu = { FUBEN_NANDU.YINGXIONG, FUBEN_NANDU.SHISHI } },
            { name = "黑龙王子的巢穴", nandu = { FUBEN_NANDU.YINGXIONG, FUBEN_NANDU.SHISHI } },
            { name = "屠龙者的巢穴", nandu = { FUBEN_NANDU.YINGXIONG, FUBEN_NANDU.SHISHI } },
            { name = "破碎大厅", nandu = { FUBEN_NANDU.YINGXIONG, FUBEN_NANDU.SHISHI } },
            { name = "法师塔", nandu = { FUBEN_NANDU.YINGXIONG, FUBEN_NANDU.SHISHI } },
            { name = "半人马营地", nandu = { FUBEN_NANDU.SHISHI, FUBEN_NANDU.CHUANQI } },
            { name = "矮人地下城", nandu = { FUBEN_NANDU.SHISHI, FUBEN_NANDU.CHUANQI } },
            { name = "丛林深处", nandu = { FUBEN_NANDU.CHUANQI } },
            { name = "月亮湖", nandu = { FUBEN_NANDU.CHUANQI } },
            { name = "王城监狱", nandu = { FUBEN_NANDU.CHUANQI } },
            { name = "血色军大营", nandu = { FUBEN_NANDU.SHISHI, FUBEN_NANDU.CHUANQI } },
            { name = "圣光大教堂", nandu = { FUBEN_NANDU.SHISHI, FUBEN_NANDU.CHUANQI } },
            { name = "风暴要塞", nandu = { FUBEN_NANDU.PUTONG, FUBEN_NANDU.YINGXIONG, FUBEN_NANDU.SHISHI } },
            { name = "黑暗神殿", nandu = { FUBEN_NANDU.PUTONG, FUBEN_NANDU.YINGXIONG, FUBEN_NANDU.SHISHI } },
        },
        jiangli = {
            { jifen = 50, type = "huanhua", name = "鲜红之剑（主手）" },
            { jifen = 50, type = "huanhua", name = "鲜红之剑（副手）" },
            { jifen = 100, type = "huanhua", name = "龙爪巨斧（主手）" },
            { jifen = 100, type = "huanhua", name = "龙爪巨斧（副手）" },
            { jifen = 150, type = "huanhua", name = "灵魂燃烧之杖" },
            { jifen = 200, type = "huanhua", name = "血红之弓" },
            { jifen = 300, type = "zuoqi", name = "迅捷猎豹" },
            { jifen = 350, type = "huanhua", name = "上古守护者的长弓" },
            { jifen = 400, type = "huanhua", name = "地狱烈焰法杖" },
            { jifen = 450, type = "huanhua", name = "混乱之刃（主手）" },
            { jifen = 450, type = "huanhua", name = "混乱之刃（副手）" },
            { jifen = 500, type = "huanhua", name = "阿而坎迪·兄弟会之剑（主手）" },
            { jifen = 500, type = "huanhua", name = "阿而坎迪·兄弟会之剑（副手）" },
            { jifen = 600, type = "zuoqi", name = "星光麋鹿" },
            { jifen = 900, type = "zuoqi", name = "凿孔蟹" },
        },
    }
    hdaixin.init(config)
end
