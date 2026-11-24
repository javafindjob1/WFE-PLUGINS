---@class hitem 物品
hitem = {}
NUM_EQUIPMENT_SLOT = 10
EQUIPMENT_SLOT_ID = {
    zhushou = 1,   --主手
    fushou = 2,    -- 副手
    toukui = 3,    --头盔
    yifu = 4,      --衣服
    xiezi = 5,     --鞋子
    shoutao = 6,   --手套
    pifeng = 7,    -- 披风
    jiezhi = 8,    --戒指
    xianglian = 9, --项链
    shipin = 10    -- 饰品
}
ITEM_LEVEL_TO_EQUIP_REQ_DITULEVEL = {}
ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL = {}
ITEM_SOURCE_INFO = {}
ZHUANYE_NEED_UPDATE_ITEM_SOURCE = {}

EQUIPMENT_SLOT_ID_TO_SLOT_NAME = {
    "主手",
    "副手",
    "头盔",
    "衣服",
    "鞋子",
    "手套",
    "披风",
    "戒指",
    "项链",
    "饰品"
}

HUANHUA_POSITION = {
    JUESE = "角色",
    ZHUSHOU = "主手",
    FUSHOU = "副手",
    TOUKUI = "头盔",
    CHIBANG = "翅膀",
    GUANGHUAN = "光环",
    ZUOQI = "坐骑"
}
HUANHUA_POSITION_LIST = {
    HUANHUA_POSITION.JUESE,
    HUANHUA_POSITION.ZHUSHOU,
    HUANHUA_POSITION.FUSHOU,
    HUANHUA_POSITION.TOUKUI,
    HUANHUA_POSITION.CHIBANG,
    HUANHUA_POSITION.GUANGHUAN,
    HUANHUA_POSITION.ZUOQI
}

EQUIPMENT_SLOT_TO_HUANHUA_POSITION = {}
EQUIPMENT_SLOT_TO_HUANHUA_POSITION[EQUIPMENT_SLOT_ID.zhushou] = HUANHUA_POSITION.ZHUSHOU
EQUIPMENT_SLOT_TO_HUANHUA_POSITION[EQUIPMENT_SLOT_ID.fushou] = HUANHUA_POSITION.FUSHOU

EQUIPMENT_TYPE_DEFAULT_EFFECT = {}
EQUIPMENT_TYPE_DEFAULT_EFFECT["单手剑"] = "war3mapImported\\weapon_DSJ_07.mdx"
EQUIPMENT_TYPE_DEFAULT_EFFECT["法剑"] = "war3mapImported\\weapon_DSJ_07.mdx"
EQUIPMENT_TYPE_DEFAULT_EFFECT["单手斧"] = "war3mapImported\\Weapon_DSF_02.mdx"
EQUIPMENT_TYPE_DEFAULT_EFFECT["单手锤"] = "war3mapImported\\Weapon_DSC_01.mdx"
EQUIPMENT_TYPE_DEFAULT_EFFECT["匕首"] = "war3mapImported\\weapon_bs_14.mdx"
EQUIPMENT_TYPE_DEFAULT_EFFECT["拳套"] = "war3mapImported\\Weapon_QT#005.mdx"
EQUIPMENT_TYPE_DEFAULT_EFFECT["双手剑"] = "war3mapImported\\weapon_ssj_001.mdx"
EQUIPMENT_TYPE_DEFAULT_EFFECT["鱼竿"] = "war3mapImported\\weapon_ssj_001.mdx"
EQUIPMENT_TYPE_DEFAULT_EFFECT["双手斧"] = "war3mapImported\\Weapon_Axe_013.mdx"
EQUIPMENT_TYPE_DEFAULT_EFFECT["双手锤"] = "war3mapImported\\Weapon_Chui01.mdx"
EQUIPMENT_TYPE_DEFAULT_EFFECT["法杖"] = "war3mapImported\\Weapon_FZ02.mdx"
EQUIPMENT_TYPE_DEFAULT_EFFECT["弓"] = "war3mapImported\\weapon_Bow02.mdx"

EQUIPMENT_TYPE_TO_SLOT = {}
EQUIPMENT_TYPE_TO_SLOT["单手剑"] = {
    huofa = { EQUIPMENT_SLOT_ID.zhushou },
    kuangbaozhan = { EQUIPMENT_SLOT_ID.zhushou, EQUIPMENT_SLOT_ID.fushou },
    wuqizhan = {},
    zhandouzei = { EQUIPMENT_SLOT_ID.zhushou, EQUIPMENT_SLOT_ID.fushou },
    shejilieren = {},
    chengjieqi = {},
    huimieshu = { EQUIPMENT_SLOT_ID.zhushou },
    tongkushu = { EQUIPMENT_SLOT_ID.zhushou },
    xingchenfashi = {},
    emolieshou = { EQUIPMENT_SLOT_ID.zhushou, EQUIPMENT_SLOT_ID.fushou }
}
EQUIPMENT_TYPE_TO_SLOT["法剑"] = {
    huofa = { EQUIPMENT_SLOT_ID.zhushou },
    kuangbaozhan = {},
    wuqizhan = {},
    zhandouzei = {},
    shejilieren = {},
    chengjieqi = {},
    huimieshu = { EQUIPMENT_SLOT_ID.zhushou },
    tongkushu = { EQUIPMENT_SLOT_ID.zhushou },
    xingchenfashi = { EQUIPMENT_SLOT_ID.zhushou },
    emolieshou = {}
}
EQUIPMENT_TYPE_TO_SLOT["单手锤"] = {
    huofa = {},
    kuangbaozhan = { EQUIPMENT_SLOT_ID.zhushou, EQUIPMENT_SLOT_ID.fushou },
    wuqizhan = {},
    zhandouzei = { EQUIPMENT_SLOT_ID.zhushou, EQUIPMENT_SLOT_ID.fushou },
    shejilieren = {},
    chengjieqi = {},
    huimieshu = {},
    tongkushu = {},
    xingchenfashi = {},
    emolieshou = { EQUIPMENT_SLOT_ID.zhushou, EQUIPMENT_SLOT_ID.fushou }
}
EQUIPMENT_TYPE_TO_SLOT["单手斧"] = {
    huofa = {},
    kuangbaozhan = { EQUIPMENT_SLOT_ID.zhushou, EQUIPMENT_SLOT_ID.fushou },
    wuqizhan = {},
    zhandouzei = { EQUIPMENT_SLOT_ID.zhushou, EQUIPMENT_SLOT_ID.fushou },
    shejilieren = {},
    chengjieqi = {},
    huimieshu = {},
    tongkushu = {},
    xingchenfashi = {},
    emolieshou = { EQUIPMENT_SLOT_ID.zhushou, EQUIPMENT_SLOT_ID.fushou }
}
EQUIPMENT_TYPE_TO_SLOT["匕首"] = {
    huofa = { EQUIPMENT_SLOT_ID.zhushou },
    kuangbaozhan = { EQUIPMENT_SLOT_ID.zhushou, EQUIPMENT_SLOT_ID.fushou },
    wuqizhan = {},
    zhandouzei = { EQUIPMENT_SLOT_ID.zhushou, EQUIPMENT_SLOT_ID.fushou },
    shejilieren = {},
    chengjieqi = {},
    huimieshu = { EQUIPMENT_SLOT_ID.zhushou },
    tongkushu = { EQUIPMENT_SLOT_ID.zhushou },
    xingchenfashi = {},
    emolieshou = { EQUIPMENT_SLOT_ID.zhushou, EQUIPMENT_SLOT_ID.fushou }
}
EQUIPMENT_TYPE_TO_SLOT["拳套"] = {
    huofa = {},
    kuangbaozhan = { EQUIPMENT_SLOT_ID.zhushou, EQUIPMENT_SLOT_ID.fushou },
    wuqizhan = {},
    zhandouzei = { EQUIPMENT_SLOT_ID.zhushou, EQUIPMENT_SLOT_ID.fushou },
    shejilieren = {},
    chengjieqi = {},
    huimieshu = {},
    tongkushu = {},
    xingchenfashi = {},
    emolieshou = { EQUIPMENT_SLOT_ID.zhushou, EQUIPMENT_SLOT_ID.fushou }
}
EQUIPMENT_TYPE_TO_SLOT["双手剑"] = {
    huofa = {},
    kuangbaozhan = {},
    wuqizhan = { EQUIPMENT_SLOT_ID.zhushou },
    zhandouzei = {},
    shejilieren = {},
    chengjieqi = { EQUIPMENT_SLOT_ID.zhushou },
    huimieshu = {},
    tongkushu = {},
    xingchenfashi = {},
    emolieshou = {}
}
EQUIPMENT_TYPE_TO_SLOT["鱼竿"] = {
    huofa = { EQUIPMENT_SLOT_ID.zhushou },
    kuangbaozhan = { EQUIPMENT_SLOT_ID.zhushou },
    wuqizhan = { EQUIPMENT_SLOT_ID.zhushou },
    zhandouzei = { EQUIPMENT_SLOT_ID.zhushou },
    shejilieren = { EQUIPMENT_SLOT_ID.zhushou },
    chengjieqi = { EQUIPMENT_SLOT_ID.zhushou },
    huimieshu = { EQUIPMENT_SLOT_ID.zhushou },
    tongkushu = { EQUIPMENT_SLOT_ID.zhushou },
    xingchenfashi = { EQUIPMENT_SLOT_ID.zhushou },
    emolieshou = { EQUIPMENT_SLOT_ID.zhushou }
}
EQUIPMENT_TYPE_TO_SLOT["双手斧"] = {
    huofa = {},
    kuangbaozhan = {},
    wuqizhan = { EQUIPMENT_SLOT_ID.zhushou },
    zhandouzei = {},
    shejilieren = {},
    chengjieqi = { EQUIPMENT_SLOT_ID.zhushou },
    huimieshu = {},
    tongkushu = {},
    xingchenfashi = {},
    emolieshou = {}
}
EQUIPMENT_TYPE_TO_SLOT["双手锤"] = {
    huofa = {},
    kuangbaozhan = {},
    wuqizhan = { EQUIPMENT_SLOT_ID.zhushou },
    zhandouzei = {},
    shejilieren = {},
    chengjieqi = { EQUIPMENT_SLOT_ID.zhushou },
    huimieshu = {},
    tongkushu = {},
    xingchenfashi = {},
    emolieshou = {}
}
EQUIPMENT_TYPE_TO_SLOT["法杖"] = {
    huofa = { EQUIPMENT_SLOT_ID.zhushou },
    kuangbaozhan = {},
    wuqizhan = {},
    zhandouzei = {},
    shejilieren = {},
    chengjieqi = {},
    huimieshu = { EQUIPMENT_SLOT_ID.zhushou },
    tongkushu = { EQUIPMENT_SLOT_ID.zhushou },
    xingchenfashi = { EQUIPMENT_SLOT_ID.zhushou },
    emolieshou = {}
}

EQUIPMENT_TYPE_TO_SLOT["弓"] = {
    huofa = {},
    kuangbaozhan = {},
    wuqizhan = {},
    zhandouzei = {},
    shejilieren = { EQUIPMENT_SLOT_ID.zhushou },
    chengjieqi = {},
    huimieshu = {},
    tongkushu = {},
    xingchenfashi = {},
    emolieshou = {}
}
EQUIPMENT_TYPE_TO_SLOT["法器"] = {
    huofa = { EQUIPMENT_SLOT_ID.fushou },
    kuangbaozhan = {},
    wuqizhan = {},
    zhandouzei = {},
    shejilieren = {},
    chengjieqi = {},
    huimieshu = { EQUIPMENT_SLOT_ID.fushou },
    tongkushu = { EQUIPMENT_SLOT_ID.fushou },
    xingchenfashi = { EQUIPMENT_SLOT_ID.fushou },
    emolieshou = {}
}
EQUIPMENT_TYPE_TO_SLOT["圣契"] = {
    huofa = {},
    kuangbaozhan = {},
    wuqizhan = {},
    zhandouzei = {},
    shejilieren = {},
    chengjieqi = { EQUIPMENT_SLOT_ID.fushou },
    huimieshu = {},
    tongkushu = {},
    xingchenfashi = {},
    emolieshou = {}
}
EQUIPMENT_TYPE_TO_SLOT["武器链"] = {
    huofa = {},
    kuangbaozhan = {},
    wuqizhan = { EQUIPMENT_SLOT_ID.fushou },
    zhandouzei = {},
    shejilieren = {},
    chengjieqi = {},
    huimieshu = {},
    tongkushu = {},
    xingchenfashi = {},
    emolieshou = {}
}
EQUIPMENT_TYPE_TO_SLOT["箭袋"] = {
    huofa = {},
    kuangbaozhan = {},
    wuqizhan = {},
    zhandouzei = {},
    shejilieren = { EQUIPMENT_SLOT_ID.fushou },
    chengjieqi = {},
    huimieshu = {},
    tongkushu = {},
    xingchenfashi = {},
    emolieshou = {}
}
EQUIPMENT_TYPE_TO_SLOT["头盔"] = {
    huofa = { EQUIPMENT_SLOT_ID.toukui },
    kuangbaozhan = { EQUIPMENT_SLOT_ID.toukui },
    wuqizhan = { EQUIPMENT_SLOT_ID.toukui },
    zhandouzei = { EQUIPMENT_SLOT_ID.toukui },
    shejilieren = { EQUIPMENT_SLOT_ID.toukui },
    chengjieqi = { EQUIPMENT_SLOT_ID.toukui },
    huimieshu = { EQUIPMENT_SLOT_ID.toukui },
    tongkushu = { EQUIPMENT_SLOT_ID.toukui },
    xingchenfashi = { EQUIPMENT_SLOT_ID.toukui },
    emolieshou = { EQUIPMENT_SLOT_ID.toukui }
}
EQUIPMENT_TYPE_TO_SLOT["衣服"] = {
    huofa = { EQUIPMENT_SLOT_ID.yifu },
    kuangbaozhan = { EQUIPMENT_SLOT_ID.yifu },
    wuqizhan = { EQUIPMENT_SLOT_ID.yifu },
    zhandouzei = { EQUIPMENT_SLOT_ID.yifu },
    shejilieren = { EQUIPMENT_SLOT_ID.yifu },
    chengjieqi = { EQUIPMENT_SLOT_ID.yifu },
    huimieshu = { EQUIPMENT_SLOT_ID.yifu },
    tongkushu = { EQUIPMENT_SLOT_ID.yifu },
    xingchenfashi = { EQUIPMENT_SLOT_ID.yifu },
    emolieshou = { EQUIPMENT_SLOT_ID.yifu }
}
EQUIPMENT_TYPE_TO_SLOT["手套"] = {
    huofa = { EQUIPMENT_SLOT_ID.shoutao },
    kuangbaozhan = { EQUIPMENT_SLOT_ID.shoutao },
    wuqizhan = { EQUIPMENT_SLOT_ID.shoutao },
    zhandouzei = { EQUIPMENT_SLOT_ID.shoutao },
    shejilieren = { EQUIPMENT_SLOT_ID.shoutao },
    chengjieqi = { EQUIPMENT_SLOT_ID.shoutao },
    huimieshu = { EQUIPMENT_SLOT_ID.shoutao },
    tongkushu = { EQUIPMENT_SLOT_ID.shoutao },
    xingchenfashi = { EQUIPMENT_SLOT_ID.shoutao },
    emolieshou = { EQUIPMENT_SLOT_ID.shoutao }
}
EQUIPMENT_TYPE_TO_SLOT["鞋子"] = {
    huofa = { EQUIPMENT_SLOT_ID.xiezi },
    kuangbaozhan = { EQUIPMENT_SLOT_ID.xiezi },
    wuqizhan = { EQUIPMENT_SLOT_ID.xiezi },
    zhandouzei = { EQUIPMENT_SLOT_ID.xiezi },
    shejilieren = { EQUIPMENT_SLOT_ID.xiezi },
    chengjieqi = { EQUIPMENT_SLOT_ID.xiezi },
    huimieshu = { EQUIPMENT_SLOT_ID.xiezi },
    tongkushu = { EQUIPMENT_SLOT_ID.xiezi },
    xingchenfashi = { EQUIPMENT_SLOT_ID.xiezi },
    emolieshou = { EQUIPMENT_SLOT_ID.xiezi }
}
EQUIPMENT_TYPE_TO_SLOT["披风"] = {
    huofa = { EQUIPMENT_SLOT_ID.pifeng },
    kuangbaozhan = { EQUIPMENT_SLOT_ID.pifeng },
    wuqizhan = { EQUIPMENT_SLOT_ID.pifeng },
    zhandouzei = { EQUIPMENT_SLOT_ID.pifeng },
    shejilieren = { EQUIPMENT_SLOT_ID.pifeng },
    chengjieqi = { EQUIPMENT_SLOT_ID.pifeng },
    huimieshu = { EQUIPMENT_SLOT_ID.pifeng },
    tongkushu = { EQUIPMENT_SLOT_ID.pifeng },
    xingchenfashi = { EQUIPMENT_SLOT_ID.pifeng },
    emolieshou = { EQUIPMENT_SLOT_ID.pifeng }
}
EQUIPMENT_TYPE_TO_SLOT["戒指"] = {
    huofa = { EQUIPMENT_SLOT_ID.jiezhi },
    kuangbaozhan = { EQUIPMENT_SLOT_ID.jiezhi },
    wuqizhan = { EQUIPMENT_SLOT_ID.jiezhi },
    zhandouzei = { EQUIPMENT_SLOT_ID.jiezhi },
    shejilieren = { EQUIPMENT_SLOT_ID.jiezhi },
    chengjieqi = { EQUIPMENT_SLOT_ID.jiezhi },
    huimieshu = { EQUIPMENT_SLOT_ID.jiezhi },
    tongkushu = { EQUIPMENT_SLOT_ID.jiezhi },
    xingchenfashi = { EQUIPMENT_SLOT_ID.jiezhi },
    emolieshou = { EQUIPMENT_SLOT_ID.jiezhi }
}
EQUIPMENT_TYPE_TO_SLOT["项链"] = {
    huofa = { EQUIPMENT_SLOT_ID.xianglian },
    kuangbaozhan = { EQUIPMENT_SLOT_ID.xianglian },
    wuqizhan = { EQUIPMENT_SLOT_ID.xianglian },
    zhandouzei = { EQUIPMENT_SLOT_ID.xianglian },
    shejilieren = { EQUIPMENT_SLOT_ID.xianglian },
    chengjieqi = { EQUIPMENT_SLOT_ID.xianglian },
    huimieshu = { EQUIPMENT_SLOT_ID.xianglian },
    tongkushu = { EQUIPMENT_SLOT_ID.xianglian },
    xingchenfashi = { EQUIPMENT_SLOT_ID.xianglian },
    emolieshou = { EQUIPMENT_SLOT_ID.xianglian }
}
EQUIPMENT_TYPE_TO_SLOT["饰品"] = {
    huofa = { EQUIPMENT_SLOT_ID.shipin },
    kuangbaozhan = { EQUIPMENT_SLOT_ID.shipin },
    wuqizhan = { EQUIPMENT_SLOT_ID.shipin },
    zhandouzei = { EQUIPMENT_SLOT_ID.shipin },
    shejilieren = { EQUIPMENT_SLOT_ID.shipin },
    chengjieqi = { EQUIPMENT_SLOT_ID.shipin },
    huimieshu = { EQUIPMENT_SLOT_ID.shipin },
    tongkushu = { EQUIPMENT_SLOT_ID.shipin },
    xingchenfashi = { EQUIPMENT_SLOT_ID.shipin },
    emolieshou = { EQUIPMENT_SLOT_ID.shipin }
}

--- 配置物品词条
EQUIPMENT_TYPE_TO_CITIAO_TYPE = {}
--- 例子如下
--- 设置某装备可能出现的词条
--- 需要在游戏文件定义
---   EQUIPMENT_TYPE_TO_CITIAO_TYPE["单手剑"] = {}

--- 配置该物品基础（必带）属性
--- 该属性由物品等级决定
--- 可以被强化增强
--- 不可以被精炼增强
EQUIPMENT_TYPE_BASIC_ATTR = {}

--- 配置该物品基础属性上限
EQUIPMENT_TYPE_MAX_ATTR = {}

--- 例子如下
--- 需要在游戏文件定义
---   EQUIPMENT_TYPE_TO_CITIAO_TYPE["单手剑"] = {{citiao="life", basic_vlaue=10}}

--- 配置物品等级对装备基础属性影响
--- 需要在游戏文件定义
EQUIPMENT_LEVEL_TO_BASIC_ATTR_MULTI = {}
--- 配置物品等级对装备随机词条属性影响
--- 需要在游戏文件定义
EQUIPMENT_LEVEL_TO_CITIAO_MULTI = {}

--- 配置怪物等级对应掉落装备物品等级
--- 需要在游戏文件定义
MONSTER_LEVEL_TO_ITEM_LEVEL = {}

ZHUANGBEI_PINZHI = {
    PUTONG = 1,
    JINGLIANG = 2,
    SHISHI = 3,
    CHUANQI = 4,
    SHENHUA = 5
}

ZHUANGBEI_PINZHI_CITIAOSHU = {}
ZHUANGBEI_PINZHI_CITIAOSHU[ZHUANGBEI_PINZHI.PUTONG] = 0
ZHUANGBEI_PINZHI_CITIAOSHU[ZHUANGBEI_PINZHI.JINGLIANG] = 1
ZHUANGBEI_PINZHI_CITIAOSHU[ZHUANGBEI_PINZHI.SHISHI] = 2
ZHUANGBEI_PINZHI_CITIAOSHU[ZHUANGBEI_PINZHI.CHUANQI] = 3
ZHUANGBEI_PINZHI_CITIAOSHU[ZHUANGBEI_PINZHI.SHENHUA] = 3

CITIAO_LEVEL_COLOR = {}
CITIAO_LEVEL_COLOR[1] = hcolor.green
CITIAO_LEVEL_COLOR[2] = hcolor.jinglianglan
CITIAO_LEVEL_COLOR[3] = hcolor.shishizi
CITIAO_LEVEL_COLOR[4] = hcolor.orange

CITIAO_VAL_MULTIPLIER = {}
CITIAO_VAL_MULTIPLIER[1] = 1
CITIAO_VAL_MULTIPLIER[2] = 1.1
CITIAO_VAL_MULTIPLIER[3] = 1.2
CITIAO_VAL_MULTIPLIER[4] = 1.3

--- 0 label 1 multiplier
ZHUANGBEI_PINZHI_DATA = {
    { label = "普通", multi = 1, color = hcolor.green, frameArt = "ReplaceableTextures\\xitong\\uikz3.tga", colorLabel = "绿色" },
    { label = "精良", multi = 1.15, color = hcolor.jinglianglan, frameArt = "ReplaceableTextures\\xitong\\uikz5.tga", colorLabel = "蓝色" },
    { label = "史诗", multi = 1.4, color = hcolor.shishizi, frameArt = "ReplaceableTextures\\xitong\\uikz2.tga", colorLabel = "紫色" },
    { label = "传奇", multi = 1.55, color = hcolor.orange, frameArt = "ReplaceableTextures\\xitong\\uikz6.tga", colorLabel = "橙色" },
    { label = "神话", multi = 1.8, color = hcolor.red, frameArt = "ReplaceableTextures\\xitong\\uikz5.tga", colorLabel = "红色" }
}

PINZHI_TAOZHUANG_SHUXING = {}
PINZHI_TAOZHUANG_SHUXING[1] = { quanju_zengshang = "+3" }
PINZHI_TAOZHUANG_SHUXING[2] = { quanju_zengshang = "+6" }
PINZHI_TAOZHUANG_SHUXING[3] = { quanju_zengshang = "+9" }
PINZHI_TAOZHUANG_SHUXING[4] = { quanju_zengshang = "+12" }
PINZHI_TAOZHUANG_SHUXING[5] = { quanju_zengshang = "+15" }

QIANGHUA_TAOZHUANG_SHUXING = {}
QIANGHUA_TAOZHUANG_SHUXING[1] = { shengming_baifenbi = "+2" }
QIANGHUA_TAOZHUANG_SHUXING[2] = { shengming_baifenbi = "+4" }
QIANGHUA_TAOZHUANG_SHUXING[3] = { shengming_baifenbi = "+6" }
QIANGHUA_TAOZHUANG_SHUXING[4] = { shengming_baifenbi = "+8" }
QIANGHUA_TAOZHUANG_SHUXING[5] = { shengming_baifenbi = "+10" }
QIANGHUA_TAOZHUANG_SHUXING[6] = { shengming_baifenbi = "+12" }
QIANGHUA_TAOZHUANG_SHUXING[7] = { shengming_baifenbi = "+14" }
QIANGHUA_TAOZHUANG_SHUXING[8] = { shengming_baifenbi = "+16" }
QIANGHUA_TAOZHUANG_SHUXING[9] = { shengming_baifenbi = "+18" }

JINGLIAN_TAOZHUANG_SHUXING = {}
JINGLIAN_TAOZHUANG_SHUXING[1] = { wu_baoshang = "+2", fa_baoshang = "+2" }
JINGLIAN_TAOZHUANG_SHUXING[2] = { wu_baoshang = "+4", fa_baoshang = "+4" }
JINGLIAN_TAOZHUANG_SHUXING[3] = { wu_baoshang = "+6", fa_baoshang = "+6" }
JINGLIAN_TAOZHUANG_SHUXING[4] = { wu_baoshang = "+9", fa_baoshang = "+9" }
JINGLIAN_TAOZHUANG_SHUXING[5] = { wu_baoshang = "+12", fa_baoshang = "+12" }
JINGLIAN_TAOZHUANG_SHUXING[6] = { wu_baoshang = "+15", fa_baoshang = "+15" }
JINGLIAN_TAOZHUANG_SHUXING[7] = { wu_baoshang = "+18", fa_baoshang = "+18" }
JINGLIAN_TAOZHUANG_SHUXING[8] = { wu_baoshang = "+21", fa_baoshang = "+21" }
JINGLIAN_TAOZHUANG_SHUXING[9] = { wu_baoshang = "+24", fa_baoshang = "+24" }

CUNDANG_FUMO_TO_STR = {
    zhansha = "1",
    maoyou = "2"
}

CUNDANG_STR_TO_FUMO = {}

for k, v --[[validated]] in pairs(CUNDANG_FUMO_TO_STR) do
    CUNDANG_STR_TO_FUMO[v] = k
end

HSHOP_COST_TYPE = {
    gold               = hcolor.gold("金币"),
    experience         = hcolor.purple("经验"),
    gongzhenghuizhang  = hcolor.green("公正徽章"),
    yongqihuizhang     = hcolor.green("勇气徽章"),
    xuesehuizhang      = hcolor.green("血色徽章"),
    rongyudianshu      = hcolor.green("荣誉点数"),
    dianfengjingyan    = hcolor.jinglianglan("巅峰经验"),
    chujixilianshi     = hcolor.purple("初级洗练石"),
    zhongjixilianshi   = hcolor.purple("中级洗练石"),
    maoxianzhehuizhang = hcolor.purple("冒险者徽章"),
    huoyanhuizhang     = hcolor.red("火焰徽章"),
    zhengyihuizhang    = hcolor.green("正义徽章"),
    zhixuhuizhang      = hcolor.green("秩序徽章"),
    daixinjifen        = hcolor.green("带新积分"),
    mifahuizhang       = hcolor.green("秘法徽章"),
    monenghuizhang     = hcolor.green("魔能徽章"),
    xieehuizhang       = hcolor.green("邪恶徽章"),
    emohuizhang        = hcolor.green("恶魔徽章"),
    huihuanghuizhang   = hcolor.green("辉煌徽章"),
    kaixuanhuizhang    = hcolor.green("凯旋徽章")
}

QIANGHUA_MAX = 9
QIANGHUA_DATA = {}
JINGLIAN_MAX = 9
JINGLIAN_DATA = {}

QIANGHUA_DATA[0] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 100 } },
    attrMulti = 1.00,
    upgradeRate = 10000,
    dropRate = 0,
    destroyRate = 0
} --10000 为100成功率
QIANGHUA_DATA[1] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 200 } },
    attrMulti = 1.02,
    upgradeRate = 5000,
    dropRate = 0,
    destroyRate = 0
} --10000 为100成功率
QIANGHUA_DATA[2] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 300 } },
    attrMulti = 1.05,
    upgradeRate = 4000,
    dropRate = 0,
    destroyRate = 0
} --10000 为100成功率
QIANGHUA_DATA[3] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 400 } },
    attrMulti = 1.08,
    upgradeRate = 3000,
    dropRate = 500,
    destroyRate = 0
} --10000 为100成功率
QIANGHUA_DATA[4] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 500 } },
    attrMulti = 1.12,
    upgradeRate = 2000,
    dropRate = 500,
    destroyRate = 0
} --10000 为100成功率
QIANGHUA_DATA[5] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 600 } },
    attrMulti = 1.16,
    upgradeRate = 2000,
    dropRate = 500,
    destroyRate = 0
} --10000 为100成功率
QIANGHUA_DATA[6] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 700 } },
    attrMulti = 1.20,
    upgradeRate = 2000,
    dropRate = 1000,
    destroyRate = 0
} --10000 为100成功率
QIANGHUA_DATA[7] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 800 } },
    attrMulti = 1.25,
    upgradeRate = 2000,
    dropRate = 1000,
    destroyRate = 0
} --10000 为100成功率
QIANGHUA_DATA[8] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 900 } },
    attrMulti = 1.30,
    upgradeRate = 2000,
    dropRate = 1000,
    destroyRate = 200
}                                       --10000 为100成功率
QIANGHUA_DATA[9] = { attrMulti = 1.40 } --10000 为100成功率

JINGLIAN_DATA[0] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 100 } },
    attrMulti = 1.00,
    upgradeRate = 10000,
    dropRate = 0,
    destroyRate = 0
} --10000 为100成功率
JINGLIAN_DATA[1] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 200 } },
    attrMulti = 1.03,
    upgradeRate = 5000,
    dropRate = 0,
    destroyRate = 0
} --10000 为100成功率
JINGLIAN_DATA[2] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 300 } },
    attrMulti = 1.06,
    upgradeRate = 4000,
    dropRate = 0,
    destroyRate = 0
} --10000 为100成功率
JINGLIAN_DATA[3] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 400 } },
    attrMulti = 1.09,
    upgradeRate = 3000,
    dropRate = 500,
    destroyRate = 0
} --10000 为100成功率
JINGLIAN_DATA[4] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 500 } },
    attrMulti = 1.12,
    upgradeRate = 2000,
    dropRate = 500,
    destroyRate = 0
} --10000 为100成功率
JINGLIAN_DATA[5] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 600 } },
    attrMulti = 1.15,
    upgradeRate = 2000,
    dropRate = 500,
    destroyRate = 0
} --10000 为100成功率
JINGLIAN_DATA[6] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 700 } },
    attrMulti = 1.18,
    upgradeRate = 2000,
    dropRate = 1000,
    destroyRate = 0
} --10000 为100成功率
JINGLIAN_DATA[7] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 800 } },
    attrMulti = 1.21,
    upgradeRate = 2000,
    dropRate = 1000,
    destroyRate = 0
} --10000 为100成功率
JINGLIAN_DATA[8] = {
    cost = { { type = HSHOP_COST_TYPE.gold, value = 900 } },
    attrMulti = 1.24,
    upgradeRate = 2000,
    dropRate = 1000,
    destroyRate = 200
}                                      --10000 为100成功率
JINGLIAN_DATA[9] = { attrMulti = 1.3 } --10000 为100成功率

---@class DynamicItem
---@param id string 物品四位id
---@return DynamicItem
function DynamicItem(id)
    ---@class DynamicItem
    local this = {
        ---@private
        _t = "DynamicItem",
        -- 物品四位id
        basic_item_id = id,
        fumo = nil,
        citiao = {
            yi = nil,
            er = nil,
            san = nil
        },
        baoshi = {
            yi = { baoshiName = nil, has_slot = false },
            er = { baoshiName = nil, has_slot = false },
            san = { baoshiName = nil, has_slot = false }
        },
        qianghua = nil,
        jinglian = nil,
        juexing = nil,
        owner = nil,
        pinzhi = ZHUANGBEI_PINZHI.PUTONG,
        stack = 1,
        description = "",
        isEquipped = false,
        level = 1,
        hujiapian = nil,
        cixiu = nil,
        nandu = FUBEN_NANDU.PUTONG
    }

    this.getOwner = function()
        return this.owner
    end

    this.setEquipped = function(isEquipped)
        this.isEquipped = isEquipped
        this.updateDescription()
        return this
    end

    this.setOwner = function(whichPlayer)
        this.owner = whichPlayer
        this.updateDescription()
        return this
    end

    this.updateDescription = function()
        local msg = {}
        local pinzhi = this.pinzhi
        local basicDescription = hcolor.yellow(hslk.i2v(this.basic_item_id, "Description"))
        if hitem.getHitemType(this.basic_item_id) == "装备" then
            local name = hitem.getName(this.basic_item_id)
            local zhuangbeitype = hslk.i2v(this.basic_item_id, "equipment_type")
            if hslk.i2v(this.basic_item_id, "taozhuang") ~= nil then
                name = "[套装]" .. name
            end
            local namewithQHJL = ZHUANGBEI_PINZHI_DATA[pinzhi].color("[" .. zhuangbeitype .. "]" .. name)
            local level = this.level or 1
            if pinzhi == nil or pinzhi < ZHUANGBEI_PINZHI.PUTONG or pinzhi > ZHUANGBEI_PINZHI.SHENHUA then
                pinzhi = ZHUANGBEI_PINZHI.PUTONG
            end
            if this.qianghua ~= nil then
                namewithQHJL = namewithQHJL .. " 强化+" .. tostring(this.qianghua)
            end
            if this.jinglian ~= nil then
                namewithQHJL = namewithQHJL .. " 精炼+" .. tostring(this.jinglian)
            end
            table.insert(msg, namewithQHJL)
            if msg[#msg] ~= "" then
                table.insert(msg, "")
            end
            if this.nandu ~= nil and this.nandu ~= FUBEN_NANDU.PUTONG then
                table.insert(msg, hcolor.green(FUBEN_NANDU_LABEL_WO_COLOR[this.nandu] .. "级别"))
            end
            table.insert(msg, "物品等级: " .. tostring(level))
            if this.owner == nil then
                table.insert(msg, "未绑定")
            else
                table.insert(msg, "已绑定：" .. hplayer.getName(this.owner))
            end
            local equipment_type_str = hslk.i2v(this.basic_item_id, "equipment_type")
            local speed = hslk.i2v(this.basic_item_id, "speed")
            if speed ~= nil then
                equipment_type_str = equipment_type_str .. "(速度" .. tostring(speed) .. "秒)"
            end
            table.insert(msg, equipment_type_str)
            if this.juexing ~= nil then
                table.insert(msg, "已觉醒" .. tostring(this.juexing) .. "层")
            end
            if hslk.i2v(this.basic_item_id, "_weiyi") == true then
                table.insert(msg, hcolor.yellow("装备唯一"))
            end
            if msg[#msg] ~= "" then
                table.insert(msg, "")
            end
            table.insert(msg, description.attribute(hitem.getEquippedBasicAttribute(this)))
            local teyouAttribute =
                hattribute.getAttributeWithMulti(
                    hitem.getEquippedAttribute(this.basic_item_id),
                    FUBEN_NANDU_ITEM_FIXED_ATTR_MULTI[this.nandu]
                )
            if teyouAttribute ~= nil then
                table.insert(msg, hcolor.green(description.attribute(teyouAttribute)))
            end
            if msg[#msg] ~= "" then
                table.insert(msg, "")
            end
            if (this.citiao.yi ~= nil) then
                table.insert(msg, "随机属性:")
            end
            if this.citiao.yi ~= nil then
                table.insert(msg, "★" .. hitem.convertCitiaoToStr(this.citiao.yi, this.jinglian, level))
            end
            if this.citiao.er ~= nil then
                table.insert(msg, "★" .. hitem.convertCitiaoToStr(this.citiao.er, this.jinglian, level))
            end
            if this.citiao.san ~= nil then
                table.insert(msg, "★" .. hitem.convertCitiaoToStr(this.citiao.san, this.jinglian, level))
            end
            if (this.citiao.yi ~= nil) then
                table.insert(msg, "")
            end
            if this.baoshi.yi.has_slot == true then
                if this.baoshi.yi.baoshiName == nil then
                    table.insert(msg, "空的宝石槽")
                else
                    table.insert(
                        msg,
                        hitem.getColoredNameBasedOnPinzhi(this.baoshi.yi.baoshiName) ..
                        hzhuanye.getQHWPEffectDescription(this.baoshi.yi.baoshiName)
                    )
                end
            end
            if this.baoshi.er.has_slot == true then
                if this.baoshi.er.baoshiName == nil then
                    table.insert(msg, "空的宝石槽")
                else
                    table.insert(
                        msg,
                        hitem.getColoredNameBasedOnPinzhi(this.baoshi.er.baoshiName) ..
                        hzhuanye.getQHWPEffectDescription(this.baoshi.er.baoshiName)
                    )
                end
            end
            if this.baoshi.san.has_slot == true then
                if this.baoshi.san.baoshiName == nil then
                    table.insert(msg, "空的宝石槽")
                else
                    table.insert(
                        msg,
                        hitem.getColoredNameBasedOnPinzhi(this.baoshi.san.baoshiName) ..
                        hzhuanye.getQHWPEffectDescription(this.baoshi.san.baoshiName)
                    )
                end
            end
            if this.baoshi.yi.has_slot == true then
                if msg[#msg] ~= "" then
                    table.insert(msg, "")
                end
            end
            local skills = hslk.i2v(this.basic_item_id, "equipped_skill")
            if skills ~= nil then
                for _, skill in ipairs(skills) do
                    local tmpD = skill.description
                    if type(tmpD) == "function" then
                        tmpD = skill.description(level, pinzhi, this.nandu)
                    end
                    table.insert(msg, hcolor.green("特效:" .. tmpD))
                end
                if msg[#msg] ~= "" then
                    table.insert(msg, "")
                end
            end
            local taozhuangNames = hslk.i2v(this.basic_item_id, "taozhuang")
            if taozhuangNames ~= nil then
                local hero = nil
                if this.owner ~= nil then
                    hero = hplayer.getMainHero(this.owner)
                end
                local taozhuangStatus = nil
                local taozhuangItemLevelStatus = nil
                if this.isEquipped == true then
                    taozhuangStatus = hcache.get(hero, "TAOZHUANG_STATUS", nil)
                    taozhuangItemLevelStatus = hcache.get(hero, "TAOZHUANG_ITEM_LEVEL_STATUS", nil)
                end
                for _, taozhuangName in ipairs(taozhuangNames) do
                    table.insert(msg, hcolor.green("★" .. taozhuangName .. "★"))
                    for _, zbName in ipairs(HSLK_TAOZHUANG[taozhuangName]) do
                        if
                            taozhuangItemLevelStatus ~= nil and taozhuangItemLevelStatus[taozhuangName] ~= nil and
                            taozhuangItemLevelStatus[taozhuangName][zbName] ~= nil
                        then
                            table.insert(msg, hcolor.green("- " .. zbName))
                        else
                            table.insert(msg, hcolor.grey("- " .. zbName))
                        end
                    end
                    for _, data in ipairs(
                        table.obj2arr(TAOZHUANG_SHUXING[taozhuangName], { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 })
                    ) do
                        local count = data.key
                        local taozhuangData = data.value
                        local taozhuangDescription = ""
                        if taozhuangData.attr_type == CONST_EVENT.attr then
                            taozhuangDescription = description.attribute(taozhuangData.attr, "，")
                        else
                            taozhuangDescription = taozhuangData.description
                        end
                        if
                            taozhuangStatus ~= nil and taozhuangStatus[taozhuangName] ~= nil and
                            taozhuangStatus[taozhuangName] >= count
                        then
                            table.insert(msg, hcolor.green(tostring(count) .. "件套效果：" .. taozhuangDescription))
                        else
                            table.insert(msg, hcolor.grey(tostring(count) .. "件套效果：" .. taozhuangDescription))
                        end
                    end
                    if msg[#msg] ~= "" then
                        table.insert(msg, "")
                    end
                end
            end

            if this.fumo ~= nil then
                table.insert(
                    msg,
                    hcolor.green("附魔：") ..
                    hitem.getColoredNameBasedOnPinzhi(this.fumo) .. hzhuanye.getQHWPEffectDescription(this.fumo)
                )
            end
            if this.cixiu ~= nil then
                table.insert(
                    msg,
                    hcolor.green("刺绣：") ..
                    hitem.getColoredNameBasedOnPinzhi(this.cixiu) .. hzhuanye.getQHWPEffectDescription(this.cixiu)
                )
            end
            if this.hujiapian ~= nil then
                table.insert(
                    msg,
                    hcolor.green("护甲片：") ..
                    hitem.getColoredNameBasedOnPinzhi(this.hujiapian) ..
                    hzhuanye.getQHWPEffectDescription(this.hujiapian)
                )
            end
            if msg[#msg] ~= "" then
                table.insert(msg, "")
            end
            table.insert(msg, basicDescription)
            table.insert(msg, "")
            table.insert(msg, "穿戴需要人物等级: " .. tostring(math.max(1, level - 5)))
            table.insert(
                msg,
                "穿戴需要地图等级：" ..
                tostring(
                    ITEM_LEVEL_TO_EQUIP_REQ_DITULEVEL[this.level] +
                    ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[this.level][this.nandu]
                )
            )
        else
            local name = hitem.getName(this.basic_item_id)
            local namewithQHJL = ZHUANGBEI_PINZHI_DATA[pinzhi].color(name)
            table.insert(msg, namewithQHJL)
            if msg[#msg] ~= "" then
                table.insert(msg, "")
            end
            table.insert(msg, hitem.getHitemType(this.basic_item_id))
            if msg[#msg] ~= "" then
                table.insert(msg, "")
            end
            if this.owner == nil then
                table.insert(msg, "未绑定")
            else
                table.insert(msg, "已绑定：" .. hplayer.getName(this.owner))
            end
            if msg[#msg] ~= "" then
                table.insert(msg, "")
            end
            local qhwpEffectDesc = hzhuanye.getQHWPEffectDescription(name)
            if qhwpEffectDesc ~= nil and qhwpEffectDesc ~= "" then
                table.insert(msg, qhwpEffectDesc)
            end
            if msg[#msg] ~= "" then
                table.insert(msg, "")
            end
            local qhwpItemDesc = hzhuanye.getQHWPItemDescription(name)
            if qhwpItemDesc ~= nil and qhwpItemDesc ~= "" then
                table.insert(msg, qhwpItemDesc)
            end
            if msg[#msg] ~= "" then
                table.insert(msg, "")
            end

            if this.stack > 1 then
                table.insert(msg, "数量：" .. tostring(this.stack))
                if msg[#msg] ~= "" then
                    table.insert(msg, "")
                end
            else
                table.insert(msg, "数量：1")
            end
            if msg[#msg] ~= "" then
                table.insert(msg, "")
            end
            table.insert(msg, basicDescription)
            if msg[#msg] ~= "" then
                table.insert(msg, "")
            end
            local useLevel = hslk.i2v(this.basic_item_id, "_useLevel")
            local maxLevel = hslk.i2v(this.basic_item_id, "_maxLevel")
            local duration = hslk.i2v(this.basic_item_id, "_duration")
            if duration ~= nil then
                table.insert(msg, "基础持续时间：" .. duration .. "秒")
                if msg[#msg] ~= "" then
                    table.insert(msg, "")
                end
            end

            if hitem.getHitemType(this.basic_item_id) == HITEM_TYPE.Yaoji then
                table.insert(msg, hcolor.yellow("不同的药剂不能叠加，但是可以和其它药水和合剂叠加。"))
            elseif hitem.getHitemType(this.basic_item_id) == HITEM_TYPE.Yaoshui then
                table.insert(msg, hcolor.yellow("不同的药水不能叠加，但是可以和其它药剂和合剂叠加。"))
            elseif hitem.getHitemType(this.basic_item_id) == HITEM_TYPE.Heji then
                table.insert(msg, hcolor.yellow("不同的合剂不能叠加，但是可以和其它药剂和药水叠加。合剂的持续时间可以保存至下一局游戏。"))
            end
            if msg[#msg] ~= "" then
                table.insert(msg, "")
            end
            if useLevel ~= nil then
                table.insert(msg, "使用生效最低等级：" .. useLevel)
                if msg[#msg] ~= "" then
                    table.insert(msg, "")
                end
            end
            if maxLevel ~= nil then
                table.insert(msg, "使用生效最高等级：" .. maxLevel)
                if msg[#msg] ~= "" then
                    table.insert(msg, "")
                end
            end
            if hitem.saveInZhuangbeiBeibao(this.basic_item_id) then
                table.insert(msg, "该物品会存于装备背包，并且不会被共享")
            end
        end
        this.description = string.implode("|n", msg)
    end

    this.getDescription = function()
        return this.description
    end

    this.canUseQHWPForEquipmentType = function(QHWPName, equipmentType)
        local qianghuawupinConfig = hzhuanye.qianghuawupinConfig[QHWPName]
        if qianghuawupinConfig == nil then
            return false
        end
        if qianghuawupinConfig.fitAllTypes == true then
            return true
        end
        local types = qianghuawupinConfig.zhuangbeiTypes
        if types ~= nil then
            for _, v in ipairs(types) do
                if equipmentType == v then
                    return true
                end
            end
        end
        return false
    end

    this.canUseQianghuaWupin = function(qianghuaType)
        if qianghuaType == ZHUANYE_ZHUANGBEI_QIANGHUA_WUPIN_SHIYONG.BAOSHIXIANGQIAN then
            return (this.baoshi.yi.has_slot == true and this.baoshi.yi.baoshiName == nil) or
                (this.baoshi.er.has_slot == true and this.baoshi.er.baoshiName == nil) or
                (this.baoshi.san.has_slot == true and this.baoshi.san.baoshiName == nil)
        elseif qianghuaType == ZHUANYE_ZHUANGBEI_QIANGHUA_WUPIN_SHIYONG.SHIYONGFUMOJUANZHOU then
            return this.fumo == nil
        elseif qianghuaType == ZHUANYE_ZHUANGBEI_QIANGHUA_WUPIN_SHIYONG.SHIYONGCIXIU then
            return this.cixiu == nil
        elseif qianghuaType == ZHUANYE_ZHUANGBEI_QIANGHUA_WUPIN_SHIYONG.SHIYONGHUJIAPIAN then
            return this.hujiapian == nil
        end
        err("错误的qianghuaType" .. qianghuaType)
    end

    this.useQianghuaWupin = function(qianghuaType, wupinName)
        if this.canUseQianghuaWupin(qianghuaType) ~= true then
            return
        end
        if qianghuaType == ZHUANYE_ZHUANGBEI_QIANGHUA_WUPIN_SHIYONG.BAOSHIXIANGQIAN then
            if (this.baoshi.yi.has_slot == true and this.baoshi.yi.baoshiName == nil) then
                this.baoshi.yi.baoshiName = wupinName
            elseif (this.baoshi.er.has_slot == true and this.baoshi.er.baoshiName == nil) then
                this.baoshi.er.baoshiName = wupinName
            elseif (this.baoshi.san.has_slot == true and this.baoshi.san.baoshiName == nil) then
                this.baoshi.san.baoshiName = wupinName
            end
        elseif qianghuaType == ZHUANYE_ZHUANGBEI_QIANGHUA_WUPIN_SHIYONG.SHIYONGFUMOJUANZHOU then
            this.fumo = wupinName
        elseif qianghuaType == ZHUANYE_ZHUANGBEI_QIANGHUA_WUPIN_SHIYONG.SHIYONGCIXIU then
            this.cixiu = wupinName
        elseif qianghuaType == ZHUANYE_ZHUANGBEI_QIANGHUA_WUPIN_SHIYONG.SHIYONGHUJIAPIAN then
            this.hujiapian = wupinName
        end
        this.updateDescription()
    end

    this.initBasedOnPinzhi = function(pinzhi, level, chacao, nandu, units)
        this.pinzhi = pinzhi
        this.pinzhi = this.pinzhi or ZHUANGBEI_PINZHI.PUTONG
        this.level = level
        this.level = this.level or 1
        if hitem.getHitemType(this.basic_item_id) == HITEM_TYPE.Zhuangbei then
            local citiaoShu = ZHUANGBEI_PINZHI_CITIAOSHU[pinzhi]
            local equipment_type = hslk.i2v(this.basic_item_id, "equipment_type")
            if equipment_type == nil then
                return
            end
            local citiao_pool = EQUIPMENT_TYPE_TO_CITIAO_TYPE[equipment_type]
            if citiao_pool == nil then
                err("citiao pool is nil")
            end
            local exclude_index = {}
            if citiaoShu >= 1 then
                this.citiao.yi = hitem.generateCitiao(citiao_pool, exclude_index, level, units)
            end
            if citiaoShu >= 2 then
                this.citiao.er = hitem.generateCitiao(citiao_pool, exclude_index, level, units)
            end
            if citiaoShu >= 3 then
                this.citiao.san = hitem.generateCitiao(citiao_pool, exclude_index, level, units)
            end
            local numChacao = chacao
            if numChacao == nil then
                numChacao = hitem.getJichuChacao(id)
            end
            if numChacao ~= nil then
                if numChacao >= 1 then
                    this.baoshi.yi.has_slot = true
                end
                if numChacao >= 2 then
                    this.baoshi.er.has_slot = true
                end
                if numChacao >= 3 then
                    this.baoshi.san.has_slot = true
                end
            end
        end
        if nandu ~= nil then
            this.nandu = nandu
        end
        this.updateDescription()
    end

    this.refreshCitiao = function(level, units)
        if hitem.getHitemType(this.basic_item_id) == HITEM_TYPE.Zhuangbei then
            local citiaoShu = ZHUANGBEI_PINZHI_CITIAOSHU[this.pinzhi]
            local equipment_type = hslk.i2v(this.basic_item_id, "equipment_type")
            if equipment_type == nil then
                return
            end
            local citiao_pool = EQUIPMENT_TYPE_TO_CITIAO_TYPE[equipment_type]
            if citiao_pool == nil then
                err("citiao pool is nil")
            end
            local exclude_index = {}
            if citiaoShu >= 1 then
                this.citiao.yi = hitem.generateCitiao(citiao_pool, exclude_index, level, units)
            end
            if citiaoShu >= 2 then
                this.citiao.er = hitem.generateCitiao(citiao_pool, exclude_index, level, units)
            end
            if citiaoShu >= 3 then
                this.citiao.san = hitem.generateCitiao(citiao_pool, exclude_index, level, units)
            end
            this.updateDescription()
        end
    end
    -- 6 位物品存档
    this.getShortCunDangString = function()
        local msg = {}
        table.insert(msg, this.basic_item_id)
        if this.stack < 1 then
            table.insert(msg, "01")
        elseif this.stack < 10 then
            table.insert(msg, "0" .. tostring(this.stack))
        elseif this.stack < 100 then
            table.insert(msg, tostring(this.stack))
        else
            table.insert(msg, "99")
        end
        local str = string.implode("", msg)
        return str
    end

    ---turn short cundang into long cundang
    ---@param cundang string 一共6位 1-4 id 5-6 stack
    ---@return void
    this.loadFromShortCunDangString = function(cundang)
        local stack = tonumber(string.sub(cundang, 5, 6))
        if stack == 0 or stack == nil then
            this.stack = 1
        else
            this.stack = stack
        end
        this.pinzhi = hitem.getItemMinPinzhi(this.basic_item_id)
        this.level = 1
        this.updateDescription()
    end

    ---获得这个物品存档对应的参数
    ---@return string 存档参数 31位
    this.getCunDangString = function()
        local msg = {}
        table.insert(msg, this.basic_item_id)
        if this.fumo ~= nil then
            local fmCDSTR = hzhuanye.getCDStrFromQHWP(this.fumo)
            if string.len(fmCDSTR) ~= 1 then
                err("incorrect fumo CDStr " .. fmCDSTR .. " from fumo: " .. this.fumo)
            else
                table.insert(msg, hzhuanye.getCDStrFromQHWP(this.fumo))
            end
        else
            table.insert(msg, "0")
        end
        if this.citiao.yi ~= nil then
            table.insert(msg, CONST_ATTR_CUNDANG_LABEL[this.citiao.yi.attr])
            table.insert(msg, this.citiao.yi.level)
        else
            table.insert(msg, "00")
        end
        if this.citiao.er ~= nil then
            table.insert(msg, CONST_ATTR_CUNDANG_LABEL[this.citiao.er.attr])
            table.insert(msg, this.citiao.er.level)
        else
            table.insert(msg, "00")
        end
        if this.citiao.san ~= nil then
            table.insert(msg, CONST_ATTR_CUNDANG_LABEL[this.citiao.san.attr])
            table.insert(msg, this.citiao.san.level)
        else
            table.insert(msg, "00")
        end
        if this.cixiu ~= nil then
            local fmCDSTR = hzhuanye.getCDStrFromQHWP(this.cixiu)
            if string.len(fmCDSTR) ~= 1 then
                err("incorrect cixiu CDStr " .. fmCDSTR .. " from cixiu: " .. this.cixiu)
            else
                table.insert(msg, hzhuanye.getCDStrFromQHWP(this.cixiu))
            end
        else
            table.insert(msg, "0")
        end
        if this.hujiapian ~= nil then
            local fmCDSTR = hzhuanye.getCDStrFromQHWP(this.hujiapian)
            if string.len(fmCDSTR) ~= 1 then
                err("incorrect hujiapian CDStr " .. fmCDSTR .. " from hujiapian: " .. this.hujiapian)
            else
                table.insert(msg, hzhuanye.getCDStrFromQHWP(this.hujiapian))
            end
        else
            table.insert(msg, "0")
        end
        if this.qianghua ~= nil then
            table.insert(msg, tostring(this.qianghua))
        else
            table.insert(msg, "0")
        end
        if this.jinglian ~= nil then
            table.insert(msg, tostring(this.jinglian))
        else
            table.insert(msg, "0")
        end
        if this.juexing ~= nil then
            table.insert(msg, tostring(this.juexing))
        else
            table.insert(msg, "0")
        end
        if this.stack < 1 then
            table.insert(msg, "01")
        elseif this.stack < 10 then
            table.insert(msg, "0" .. tostring(this.stack))
        elseif this.stack < 100 then
            table.insert(msg, tostring(this.stack))
        else
            table.insert(msg, "99")
        end
        table.insert(msg, tostring(this.pinzhi))
        local cundang_level = this.level or 1
        if cundang_level < 1 then
            table.insert(msg, "01")
        elseif cundang_level < 10 then
            table.insert(msg, "0" .. tostring(cundang_level))
        elseif cundang_level < 100 then
            table.insert(msg, tostring(cundang_level))
        else
            table.insert(msg, "99")
        end
        if this.baoshi.yi.has_slot == true then
            table.insert(msg, "1")
            if this.baoshi.yi.baoshiName == nil then
                table.insert(msg, "00")
            else
                table.insert(msg, hzhuanye.getCDStrFromQHWP(this.baoshi.yi.baoshiName))
            end
        else
            table.insert(msg, "000")
        end
        if this.baoshi.er.has_slot == true then
            table.insert(msg, "1")
            if this.baoshi.er.baoshiName == nil then
                table.insert(msg, "00")
            else
                table.insert(msg, hzhuanye.getCDStrFromQHWP(this.baoshi.er.baoshiName))
            end
        else
            table.insert(msg, "000")
        end
        if this.baoshi.san.has_slot == true then
            table.insert(msg, "1")
            if this.baoshi.san.baoshiName == nil then
                table.insert(msg, "00")
            else
                table.insert(msg, hzhuanye.getCDStrFromQHWP(this.baoshi.san.baoshiName))
            end
        else
            table.insert(msg, "000")
        end
        if this.nandu == nil then
            table.insert(msg, "0")
        else
            table.insert(msg, tostring(this.nandu))
        end
        local str = string.implode("", msg)
        return str
    end
    ---把存档转化成物品
    ---@param cundang string 一共31位 1-4 id 5 fumo 6-11 citiao 12 cixiu 13 hujiapian 14 qianghua 15 jinglian 16 juexing 17/18 stack 19 pinzhi 20-21 level 22 -30 baoshi 31 难度
    ---@return void
    this.loadFromCunDangString = function(cundang)
        local fumo = string.sub(cundang, 5, 5)
        if fumo ~= "0" then
            this.fumo = hzhuanye.getQHWPNameFromCDStr("附魔", fumo)
        end
        local citiaoyiattr = string.sub(cundang, 6, 6)
        if citiaoyiattr ~= "0" then
            this.citiao.yi = {
                attr = CONST_ATTR_CUNDANG_TO_ATTR[citiaoyiattr],
                level = tonumber(string.sub(cundang, 7, 7))
            }
        end
        local citiaoerattr = string.sub(cundang, 8, 8)
        if citiaoerattr ~= "0" then
            this.citiao.er = {
                attr = CONST_ATTR_CUNDANG_TO_ATTR[citiaoerattr],
                level = tonumber(string.sub(cundang, 9, 9))
            }
        end
        local citiaosanattr = string.sub(cundang, 10, 10)
        if citiaosanattr ~= "0" then
            this.citiao.san = {
                attr = CONST_ATTR_CUNDANG_TO_ATTR[citiaosanattr],
                level = tonumber(string.sub(cundang, 11, 11))
            }
        end
        local cixiu = string.sub(cundang, 12, 12)
        if cixiu ~= "0" then
            this.cixiu = hzhuanye.getQHWPNameFromCDStr("裁缝", cixiu)
        end
        local hujiapian = string.sub(cundang, 13, 13)
        if hujiapian ~= "0" then
            this.hujiapian = hzhuanye.getQHWPNameFromCDStr("制皮", hujiapian)
        end
        local qianghua = string.sub(cundang, 14, 14)
        if qianghua ~= "0" then
            this.qianghua = tonumber(qianghua)
        end
        local jinglian = string.sub(cundang, 15, 15)
        if jinglian ~= "0" then
            this.jinglian = tonumber(jinglian)
        end
        local juexing = string.sub(cundang, 16, 16)
        if juexing ~= "0" then
            this.juexing = tonumber(juexing)
        end
        local stack = tonumber(string.sub(cundang, 17, 18))
        if stack == 0 then
            this.stack = 1
        else
            this.stack = stack
        end
        local pinzhi = tonumber(string.sub(cundang, 19, 19))
        if pinzhi > 0 and pinzhi < 6 then
            this.pinzhi = pinzhi
        else
            this.pinzhi = 1
        end
        local level = tonumber(string.sub(cundang, 20, 21))
        if level > 0 and level < 100 then
            this.level = level
        else
            this.level = 1
        end

        local baoshiyislot = string.sub(cundang, 22, 22)
        if baoshiyislot == "1" then
            this.baoshi.yi.has_slot = true
            local baoshiCDStr = string.sub(cundang, 23, 24)
            if baoshiCDStr ~= "00" then
                local baoshiName = hzhuanye.getQHWPNameFromCDStr("珠宝", baoshiCDStr)
                this.baoshi.yi.baoshiName = baoshiName
            end
        else
            this.baoshi.yi.has_slot = false
        end
        local baoshierslot = string.sub(cundang, 25, 25)
        if baoshierslot == "1" then
            this.baoshi.er.has_slot = true
            local baoshiCDStr = string.sub(cundang, 26, 27)
            if baoshiCDStr ~= "00" then
                local baoshiName = hzhuanye.getQHWPNameFromCDStr("珠宝", baoshiCDStr)
                this.baoshi.er.baoshiName = baoshiName
            end
        else
            this.baoshi.er.has_slot = false
        end
        local baoshisanslot = string.sub(cundang, 28, 28)
        if baoshisanslot == "1" then
            this.baoshi.san.has_slot = true
            local baoshiCDStr = string.sub(cundang, 29, 30)
            if baoshiCDStr ~= "00" then
                local baoshiName = hzhuanye.getQHWPNameFromCDStr("珠宝", baoshiCDStr)
                this.baoshi.san.baoshiName = baoshiName
            end
        else
            this.baoshi.san.has_slot = false
        end
        local nandu = tonumber(string.sub(cundang, 31, 31))
        if nandu > 0 and nandu < 5 then
            this.nandu = nandu
        end
        this.updateDescription()
    end
    this.addStack = function(stack)
        this.stack = this.stack + stack
        this.updateDescription()
    end
    this.setStack = function(stack)
        this.stack = stack
        this.updateDescription()
    end
    this.setNandu = function(nandu)
        this.nandu = nandu
        this.updateDescription()
    end
    this.updateDescription()
    return this
end

function hitem.getHitemType(id)
    return hslk.i2v(id, "hitem_type")
end

function hitem.generateCitiao(citiao_pool, exclude_index, level, units)
    local citiaoIndex = math.random(1, #citiao_pool - #exclude_index)
    local indexShift = 0
    for _, v in ipairs(exclude_index) do
        if citiaoIndex + indexShift >= v then
            indexShift = indexShift + 1
        end
    end
    local finalIndex = citiaoIndex + indexShift
    for i, v in ipairs(exclude_index) do
        if v == finalIndex then
            dump(citiaoIndex)
            dump(exclude_index)
            dump(citiao_pool)
            dump(indexShift)
        end
    end
    table.insert(exclude_index, finalIndex)
    table.sort(exclude_index)
    local citiaoLevel = 1

    local lansecitiao_rate = 0
    local zisecitiao_rate = 0
    local chengsecitiao_rate = 0
    if units then
        for _, unit in ipairs(units) do
            lansecitiao_rate = math.max(lansecitiao_rate, hattr.getWithLimit(unit, nil, "lansecitiao_rate", 0))
            zisecitiao_rate = math.max(zisecitiao_rate, hattr.getWithLimit(unit, nil, "zisecitiao_rate", 0))
            chengsecitiao_rate = math.max(chengsecitiao_rate, hattr.getWithLimit(unit, nil, "chengsecitiao_rate", 0))
        end
    end
    if level ~= nil and level > 60 then
        if math.random(1, 100) <= (30 + lansecitiao_rate) then
            citiaoLevel = 2
            if math.random(1, 100) <= (20 + zisecitiao_rate) then
                citiaoLevel = 3
            end
        end
    end
    local citiao = {
        attr = citiao_pool[finalIndex],
        level = citiaoLevel
    }
    return citiao
end

function hitem.changeAttributeToHero(dynamicItem, hero, isAdd)
    if dynamicItem == nil or hero == nil then
        return
    end
    local fixed_attr =
        hattribute.getAttributeWithMulti(
            hitem.getEquippedAttribute(dynamicItem.basic_item_id),
            FUBEN_NANDU_ITEM_FIXED_ATTR_MULTI[dynamicItem.nandu]
        )
    local qianghua = dynamicItem.qianghua
    qianghua = qianghua or 0
    local jinglian = dynamicItem.jinglian
    jinglian = jinglian or 0
    local level = dynamicItem.level or 1
    hattribute.caleAttribute(CONST_DAMAGE_SRC.item, isAdd, hero, fixed_attr, 1)
    hattribute.caleAttribute(CONST_DAMAGE_SRC.item, isAdd, hero, hitem.getEquippedBasicAttribute(dynamicItem), 1)
    if dynamicItem.citiao.yi ~= nil then
        hattribute.caleAttribute(
            CONST_DAMAGE_SRC.item,
            isAdd,
            hero,
            hitem.getAttrFromCitiao(dynamicItem.citiao.yi, jinglian, level),
            1
        )
    end
    if dynamicItem.citiao.er ~= nil then
        hattribute.caleAttribute(
            CONST_DAMAGE_SRC.item,
            isAdd,
            hero,
            hitem.getAttrFromCitiao(dynamicItem.citiao.er, jinglian, level),
            1
        )
    end
    if dynamicItem.citiao.san ~= nil then
        hattribute.caleAttribute(
            CONST_DAMAGE_SRC.item,
            isAdd,
            hero,
            hitem.getAttrFromCitiao(dynamicItem.citiao.san, jinglian, level),
            1
        )
    end
    if dynamicItem.baoshi.yi.has_slot == true and dynamicItem.baoshi.yi.baoshiName ~= nil then
        hattribute.caleAttribute(
            CONST_DAMAGE_SRC.item,
            isAdd,
            hero,
            hzhuanye.getAttrFromQHWP(dynamicItem.baoshi.yi.baoshiName),
            1
        )
    end
    if dynamicItem.baoshi.er.has_slot == true and dynamicItem.baoshi.er.baoshiName ~= nil then
        hattribute.caleAttribute(
            CONST_DAMAGE_SRC.item,
            isAdd,
            hero,
            hzhuanye.getAttrFromQHWP(dynamicItem.baoshi.er.baoshiName),
            1
        )
    end
    if dynamicItem.baoshi.san.has_slot == true and dynamicItem.baoshi.san.baoshiName ~= nil then
        hattribute.caleAttribute(
            CONST_DAMAGE_SRC.item,
            isAdd,
            hero,
            hzhuanye.getAttrFromQHWP(dynamicItem.baoshi.san.baoshiName),
            1
        )
    end
    if dynamicItem.fumo ~= nil then
        hattribute.caleAttribute(CONST_DAMAGE_SRC.item, isAdd, hero, hzhuanye.getAttrFromQHWP(dynamicItem.fumo), 1)
    end
    if dynamicItem.cixiu ~= nil then
        hattribute.caleAttribute(CONST_DAMAGE_SRC.item, isAdd, hero, hzhuanye.getAttrFromQHWP(dynamicItem.cixiu), 1)
    end
    if dynamicItem.hujiapian ~= nil then
        hattribute.caleAttribute(CONST_DAMAGE_SRC.item, isAdd, hero, hzhuanye.getAttrFromQHWP(dynamicItem.hujiapian), 1)
    end
end

function hitem.convertCitiaoToStr(citiao, jinglian, level)
    jinglian = jinglian or 0
    return CITIAO_LEVEL_COLOR[citiao.level](description.attribute(hitem.getAttrFromCitiao(citiao, jinglian, level)))
end

function hitem.getAttrFromCitiao(citiao, jinglian, level)
    local attr = {}
    attr[citiao.attr] =
        "+" ..
        tostring(
            CITIAO_VAL_MULTIPLIER[citiao.level] * CONST_ATTR_CUNDANG_CITIAO_VAL[citiao.attr] *
            JINGLIAN_DATA[jinglian].attrMulti *
            EQUIPMENT_LEVEL_TO_CITIAO_MULTI[level]
        )
    return attr
end

--- 物品是否已被销毁
---@param whichItem userdata
---@return boolean
function hitem.isDestroyed(whichItem)
    return cj.GetItemTypeId(whichItem) == 0
end

TAOZHUANG_SHUXING = {}

function hitem.addTaozhuangShuxing(taozhuangName, data)
    if TAOZHUANG_SHUXING[taozhuangName] ~= nil then
        error("Taozhuangshuxing set twice " .. taozhuangName)
        return
    end
    TAOZHUANG_SHUXING[taozhuangName] = data
end

function hitem.getJichuChacao(id)
    return hslk.i2v(id, "_jichuChaCao")
end

--- refresh taozhuang shuxing
function hitem.refreshTaozhuang(player)
    local hero = hplayer.getMainHero(player)
    local OldSpeed = hattribute.get(hero, "attack_space_main", 0)
    local OldFinalSpeed = hattribute.get(hero, "attack_space_origin", 0)

    local taozhuangStatusBefore = hcache.get(hero, "TAOZHUANG_STATUS", nil)
    local taozhuang = {}
    local taozhuangStatus = {}
    local taozhuangItemLevelStatus = {}
    local pinzhiTaozhuang = {}
    for _, v --[[validated]] in pairs(ZHUANGBEI_PINZHI) do
        pinzhiTaozhuang[v] = 0
    end
    local qianghuaTaozhuang = {}
    for i = 0, QIANGHUA_MAX, 1 do
        qianghuaTaozhuang[i] = 0
    end
    local jinglianTaozhuang = {}
    for i = 0, JINGLIAN_MAX, 1 do
        jinglianTaozhuang[i] = 0
    end
    for v = 1, NUM_EQUIPMENT_SLOT do
        local item = hplayer.dzCunDang[player]["equipments"][v]
        if item ~= nil then
            local taozhuangNames = hslk.i2v(item.basic_item_id, "taozhuang")
            if taozhuangNames ~= nil then
                for _, taozhuangName in ipairs(taozhuangNames) do
                    if taozhuang[taozhuangName] == nil then
                        taozhuang[taozhuangName] = {}
                        taozhuangStatus[taozhuangName] = 0
                        taozhuangItemLevelStatus[taozhuangName] = {}
                    end
                    local itemName = hslk.i2v(item.basic_item_id, "Name")
                    taozhuangItemLevelStatus[taozhuangName][itemName] = 1
                    if taozhuang[taozhuangName][itemName] == nil then
                        taozhuang[taozhuangName][itemName] = 1
                        taozhuangStatus[taozhuangName] = taozhuangStatus[taozhuangName] + 1
                    end
                end
            end
            pinzhiTaozhuang[item.pinzhi] = pinzhiTaozhuang[item.pinzhi] + 1
            local qianghua = item.qianghua
            qianghua = qianghua or 0
            qianghuaTaozhuang[qianghua] = qianghuaTaozhuang[qianghua] + 1
            local jinglian = item.jinglian
            jinglian = jinglian or 0
            jinglianTaozhuang[jinglian] = jinglianTaozhuang[jinglian] + 1
        end
    end
    hcache.set(hero, "TAOZHUANG_STATUS", taozhuangStatus)
    hcache.set(hero, "TAOZHUANG_ITEM_LEVEL_STATUS", taozhuangItemLevelStatus)

    taozhuangStatusBefore = taozhuangStatusBefore or {}
    taozhuangStatus = taozhuangStatus or {}
    local allNames = Array()
    for k, _ --[[validated]] in pairs(taozhuangStatusBefore) do
        allNames.set(k, 1)
    end
    for k, _ --[[validated]] in pairs(taozhuangStatus) do
        allNames.set(k, 1)
    end
    for _, taozhuangName in ipairs(allNames.keys()) do
        local taozhuangNumBefore = taozhuangStatusBefore[taozhuangName]
        taozhuangNumBefore = taozhuangNumBefore or 0
        local taozhuangNumAfter = taozhuangStatus[taozhuangName]
        taozhuangNumAfter = taozhuangNumAfter or 0
        if taozhuangNumBefore > taozhuangNumAfter then
            local data = TAOZHUANG_SHUXING[taozhuangName][taozhuangNumBefore]
            if data ~= nil then
                local taozhuangxiaoguoName = taozhuangName .. "(" .. tostring(taozhuangNumBefore) .. "件)"
                if data.attr_type ~= nil then
                    if data.attr_type == CONST_EVENT.attr then
                        hattribute.caleAttribute(CONST_DAMAGE_SRC.item, false, hero, data["attr"], 1)
                    else
                        hevent.unregister(hero, data.attr_type, taozhuangxiaoguoName)
                    end
                end
                hcache.free(hero, taozhuangxiaoguoName)
                echo("失去套装属性：" .. taozhuangxiaoguoName, player)
            end
        elseif taozhuangNumBefore < taozhuangNumAfter then
            local data = TAOZHUANG_SHUXING[taozhuangName][taozhuangNumAfter]
            if data ~= nil then
                local taozhuangxiaoguoName = taozhuangName .. "(" .. tostring(taozhuangNumAfter) .. "件)"
                if data.attr_type ~= nil then
                    if data.attr_type == CONST_EVENT.attr then
                        hattribute.caleAttribute(CONST_DAMAGE_SRC.item, true, hero, data["attr"], 1)
                    else
                        hevent.register(hero, data.attr_type, taozhuangxiaoguoName, data.attr)
                    end
                end
                hcache.set(hero, taozhuangxiaoguoName, true)
                echo("获得套装属性：" .. taozhuangName .. "(" .. tostring(taozhuangNumAfter) .. "件)", player)
            end
        end
    end

    local pinzhiTaozhuangLevel = 0
    local finalpinzhi = 0
    for i = 5, 1, -1 do
        if pinzhiTaozhuangLevel < 9 then
            pinzhiTaozhuangLevel = pinzhiTaozhuangLevel + pinzhiTaozhuang[i]
            if pinzhiTaozhuangLevel >= 9 and PINZHI_TAOZHUANG_SHUXING[i] ~= nil then
                echo("激活品质套装:" .. ZHUANGBEI_PINZHI_DATA[i].label, player)
                finalpinzhi = i
                hbuff.update(
                    0,
                    hero,
                    "PINZHI_TAOZHUANG_SHUXING",
                    true,
                    function()
                        hattribute.caleAttribute(CONST_DAMAGE_SRC.item, true, hero, PINZHI_TAOZHUANG_SHUXING[i], 1)
                    end,
                    function()
                        hattribute.caleAttribute(CONST_DAMAGE_SRC.item, false, hero, PINZHI_TAOZHUANG_SHUXING[i], 1)
                    end,
                    nil,
                    nil,
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE
                )
            end
        end
    end
    if pinzhiTaozhuangLevel < 9 then
        hbuff.delete(hero, "PINZHI_TAOZHUANG_SHUXING")
    end
    hcache.set(player, "pinzhiTaozhuangLevel", finalpinzhi)

    local qianghuaTaozhuangLevel = 0
    local finalqianghua = 0
    for i = 9, 1, -1 do
        if qianghuaTaozhuangLevel < 9 then
            qianghuaTaozhuangLevel = qianghuaTaozhuangLevel + qianghuaTaozhuang[i]
            if qianghuaTaozhuangLevel >= 9 and QIANGHUA_TAOZHUANG_SHUXING[i] ~= nil then
                echo("激活强化+" .. i .. "套装", player)
                finalqianghua = i
                hbuff.update(
                    0,
                    hero,
                    "QIANGHUA_TAOZHUANG_SHUXING",
                    true,
                    function()
                        hattribute.caleAttribute(CONST_DAMAGE_SRC.item, true, hero, QIANGHUA_TAOZHUANG_SHUXING[i], 1)
                    end,
                    function()
                        hattribute.caleAttribute(CONST_DAMAGE_SRC.item, false, hero, QIANGHUA_TAOZHUANG_SHUXING[i], 1)
                    end,
                    nil,
                    nil,
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE
                )
            end
        end
    end
    if qianghuaTaozhuangLevel < 9 then
        hbuff.delete(hero, "QIANGHUA_TAOZHUANG_SHUXING")
    end
    hcache.set(player, "qianghuaTaozhuangLevel", finalqianghua)

    local jinglianTaozhuangLevel = 0
    local finaljinglian = 0
    for i = 9, 1, -1 do
        if jinglianTaozhuangLevel < 9 then
            jinglianTaozhuangLevel = jinglianTaozhuangLevel + jinglianTaozhuang[i]
            if jinglianTaozhuangLevel >= 9 and JINGLIAN_TAOZHUANG_SHUXING[i] ~= nil then
                echo("激活精炼+" .. i .. "套装", player)
                finaljinglian = i
                hbuff.update(
                    0,
                    hero,
                    "JINGLIAN_TAOZHUANG_SHUXING",
                    true,
                    function()
                        hattribute.caleAttribute(CONST_DAMAGE_SRC.item, true, hero, JINGLIAN_TAOZHUANG_SHUXING[i], 1)
                    end,
                    function()
                        hattribute.caleAttribute(CONST_DAMAGE_SRC.item, false, hero, JINGLIAN_TAOZHUANG_SHUXING[i], 1)
                    end,
                    nil,
                    nil,
                    1,
                    nil,
                    nil,
                    nil,
                    nil,
                    HBUFF_UPDATE_MODE.OVERWRITE
                )
            end
        end
    end
    if jinglianTaozhuangLevel < 9 then
        hbuff.delete(hero, "JINGLIAN_TAOZHUANG_SHUXING")
    end
    hcache.set(player, "jingliangTaozhuangLevel", finaljinglian)

    -- 武器速度
    local zhushou = hplayer.dzCunDang[player]["equipments"][EQUIPMENT_SLOT_ID.zhushou]
    local fushou = hplayer.dzCunDang[player]["equipments"][EQUIPMENT_SLOT_ID.fushou]
    local speed = hunit.getDefaultAttackSpace(hero)
    if zhushou ~= nil and hslk.i2v(zhushou.basic_item_id, "speed") ~= nil then
        speed = hslk.i2v(zhushou.basic_item_id, "speed")
    end
    hattribute.set(hero, 0, { attack_space_main = speed })
    if speed ~= OldSpeed then
        echo("当前主手武器间隔为" .. tostring(speed) .. "秒", player)
    end
    local fushouSpeed = speed
    if fushou ~= nil and hslk.i2v(fushou.basic_item_id, "speed") ~= nil then
        fushouSpeed = hslk.i2v(fushou.basic_item_id, "speed")
    end
    local finalSpeed = (fushouSpeed + speed) / 2
    -- 泰坦之握降低基础攻击间隔0.25 秒
    -- if
    --  hskill.hasActiveAbility(hero, hslk.n2i("泰坦之握")) and hitem.isShuangShouWuqi(zhushou) and
    --      hitem.isShuangShouWuqi(fushou)
    --  then
    --   finalSpeed = finalSpeed - 0.25
    --end
    hattribute.set(hero, 0, { attack_space_origin = finalSpeed })
    if finalSpeed ~= OldFinalSpeed then
        echo("当前基础攻击间隔为" .. tostring(finalSpeed) .. "秒", player)
    end
    for _, item in pairs(hplayer.dzCunDang[player]["equipments"]) do
        item.updateDescription()
    end
    hitem.updateTaoZhuangZhuangTaiStr(player, finalpinzhi, finalqianghua, finaljinglian)
end

function hitem.updateTaoZhuangZhuangTaiStr(whichPlayer, pinzhilevel, qianghualevel, jinglianglevel)
    local msg = {}

    table.insert(msg, "品质套装")
    if pinzhilevel > 0 then
        table.insert(
            msg,
            hcolor.green("穿戴9件") ..
            ZHUANGBEI_PINZHI_DATA[pinzhilevel].color(ZHUANGBEI_PINZHI_DATA[pinzhilevel].label) ..
            hcolor.green(
                "品质的装备获得" .. hcolor.green(description.attribute(PINZHI_TAOZHUANG_SHUXING[pinzhilevel], ","))
            )
        )
    end
    for i = pinzhilevel + 1, 5, 1 do
        table.insert(
            msg,
            hcolor.grey(
                "穿戴9件" ..
                ZHUANGBEI_PINZHI_DATA[i].label ..
                "品质的装备获得" .. description.attribute(PINZHI_TAOZHUANG_SHUXING[i], ",")
            )
        )
    end
    table.insert(msg, "")
    table.insert(msg, "强化套装")
    if qianghualevel > 0 then
        table.insert(
            msg,
            hcolor.green(
                "穿戴9件强化+" ..
                tostring(qianghualevel) ..
                "装备获得" .. description.attribute(QIANGHUA_TAOZHUANG_SHUXING[qianghualevel], ",")
            )
        )
    end
    for i = qianghualevel + 1, 9, 1 do
        table.insert(
            msg,
            hcolor.grey("穿戴9件强化+" .. tostring(i) .. "装备获得" .. description.attribute(QIANGHUA_TAOZHUANG_SHUXING[i], ","))
        )
    end
    table.insert(msg, "")
    table.insert(msg, "精炼套装")
    if jinglianglevel > 0 then
        table.insert(
            msg,
            hcolor.green(
                "穿戴9件精炼+" ..
                tostring(jinglianglevel) ..
                "装备获得" .. description.attribute(JINGLIAN_TAOZHUANG_SHUXING[jinglianglevel], ",")
            )
        )
    end
    for i = jinglianglevel + 1, 9, 1 do
        table.insert(
            msg,
            hcolor.grey("穿戴9件精炼+" .. tostring(i) .. "装备获得" .. description.attribute(JINGLIAN_TAOZHUANG_SHUXING[i], ","))
        )
    end
    table.insert(msg, "")
    local str = string.implode("|n", msg)
    hcache.set(whichPlayer, CONST_CACHE.ZHUANGBEI_TAOZHUANG, str)
end

function hitem.isShuangShouWuqi(dynamicItem)
    if dynamicItem == nil then
        return false
    end
    local eqType = hslk.i2v(dynamicItem.basic_item_id, "equipment_type")
    if eqType == "双手斧" or eqType == "双手剑" or eqType == "双手锤" then
        return true
    else
        return false
    end
end

--- req = {
---   {name = "铁矿"，count = 2},
---   {name = "野蛮锁甲"， count = 1}
--- },
function hitem.hasRequiredItems(requiredItems, whichUnit, printInfo)
    if requiredItems == nil or whichUnit == nil or #requiredItems == 0 then
        return false
    end
    local hasAllItems = true
    for i, singleReq in ipairs(requiredItems) do
        if hitem.hasSingleRequiredItems(singleReq, whichUnit, printInfo) == false then
            hasAllItems = false
        end
    end
    return hasAllItems
end

function hitem.canBypassDynamicItemCheck(itemID)
    return hslk.i2v(itemID, "canBypassDynamicItemCheck") == true
end

--- req = {
---   {name = "铁矿"，count = 2},
---   {name = "野蛮锁甲"， count = 1}
--- },
function hitem.hasSingleRequiredItems(singleReq, whichUnit, printInfo)
    if singleReq == nil or whichUnit == nil then
        return false
    end
    local whichPlayer = hunit.getOwner(whichUnit)
    return hplayer.dzCunDang[whichPlayer].hasEnoughItemInBag(singleReq, printInfo)
end

--- req = {
---   {name = "铁矿"，count = 2},
---   {name = "野蛮锁甲"， count = 1}
--- },
function hitem.getDescriptionForSingleRequiredItem(singleReq, isJiangli)
    local pinzhi = singleReq.pinzhi
    local name = singleReq.name
    local requiredNandu = singleReq.nandu
    local requiredQianghua = singleReq.qianghua
    local requiredJinglian = singleReq.jinglian
    local jiyishangpinzhi = "及以上品质"
    local jiyishangnandu = "及以上难度"
    local jiyishang = "及以上"
    if isJiangli == true then
        jiyishangpinzhi = "品质"
        jiyishangnandu = "难度"
        jiyishang = ""
    end
    local requirePinzhi = true
    if pinzhi == nil then
        requirePinzhi = false
        pinzhi = hitem.getItemMinPinzhi(hslk.n2i(name))
    end
    if pinzhi ~= nil then
        name = ZHUANGBEI_PINZHI_DATA[pinzhi].color(name)
        if hitem.getHitemType(hslk.n2i(singleReq.name)) == HITEM_TYPE.Zhuangbei and requirePinzhi then
            name = name ..
                "（" ..
                ZHUANGBEI_PINZHI_DATA[pinzhi].color(ZHUANGBEI_PINZHI_DATA[pinzhi].colorLabel) .. jiyishangpinzhi .. "）"
        end
    end
    if requiredNandu ~= nil then
        name = name .. "（" .. hcolor.green(FUBEN_NANDU_LABEL_WO_COLOR[requiredNandu] .. jiyishangnandu) .. "）"
    end
    if requiredQianghua ~= nil then
        name = name .. hcolor.green(" 强化+" .. requiredQianghua .. jiyishang)
    end
    if requiredJinglian ~= nil then
        name = name .. hcolor.green(" 精炼+" .. requiredJinglian .. jiyishang)
    end
    return name
end

function hitem.getDescriptionForRequiredItems(requiredItems)
    local tipt = {}
    for _, singleReq in ipairs(requiredItems) do
        table.insert(
            tipt,
            "- " .. hitem.getDescriptionForSingleRequiredItem(singleReq) .. " X " .. singleReq.count .. "个"
        )
    end
    return string.implode("|n", tipt)
end

function hitem.removeSingleItemReqFromBag(singleReq, whichUnit)
    local whichPlayer = hunit.getOwner(whichUnit)
    return hplayer.dzCunDang[whichPlayer].removeItemFromBag(singleReq)
end

function hitem.removeItemFromBag(requiredItems, whichUnit)
    for i, singleReq in ipairs(requiredItems) do
        hitem.removeSingleItemReqFromBag(singleReq, whichUnit)
    end
end

function hitem.createSingleItemFromSingleItemReq(singleReq, whichUnit)
    local whichPlayer = hunit.getOwner(whichUnit)
    return hplayer.dzCunDang[whichPlayer].createItemFromSingleItemReq(singleReq)
end

function hitem.getItemsInBag(whichUnit)
    local itemsInBag = {}
    if whichUnit == nil then
        return itemsInBag
    end
    hitem.forEach(
        whichUnit,
        function(enumItem, _)
            if enumItem == nil then
                return
            end
            local name = hitem.getName(enumItem)
            local dynamicItem = hitem.getDynamicItem(enumItem)
            if dynamicItem == nil then
                return
            end
            if dynamicItem.getOwner() ~= hunit.getOwner(whichUnit) then
                return
            end
            if itemsInBag[name] == nil then
                itemsInBag[name] = dynamicItem.stack
            else
                itemsInBag[name] = itemsInBag[name] + dynamicItem.stack
            end
        end
    )
    return itemsInBag
end

function hitem.getZhushouSpeed(whichPlayer)
    return hattribute.get(hplayer.getMainHero(whichPlayer), "attack_space_main", 0.1)
end

-- 注册物品出处
function hitem.registerItemSource(itemName, source)
    if not ITEM_SOURCE_INFO[itemName] then
        -- 如果该物品尚未注册，初始化一个空表来储存出处
        ITEM_SOURCE_INFO[itemName] = {}
    end
    -- 检查是否已经注册了相同的出处，避免重复
    local alreadyRegistered = false
    for _, existingSource in ipairs(ITEM_SOURCE_INFO[itemName]) do
        if existingSource == source then
            alreadyRegistered = true
            break
        end
    end
    -- 如果出处未注册，添加到物品的出处列表中
    if not alreadyRegistered then
        table.insert(ITEM_SOURCE_INFO[itemName], source)
    end
end

-- 查询物品出处
function hitem.queryItemSource(itemName)
    if not ITEM_SOURCE_INFO[itemName] then
        -- 如果该物品没有注册过出处，返回一个指示信息
        return nil
    else
        -- 如果找到了物品的出处，将所有出处合并成一个字符串返回
        local sources = table.concat(ITEM_SOURCE_INFO[itemName], ", ")
        return sources
    end
end

function hitem.sellItem(whichPlayer, dynamicItem)
    local stack = dynamicItem.stack or 1
    if stack > 99 then
        stack = 99
    end
    if stack < 1 then
        stack = 1
    end
    local gold = (dynamicItem.level + 10) * stack
    hresource.addSingleResource(whichPlayer, HSHOP_COST_TYPE.gold, gold, true)
end

function hitem.init()
    hevent.reaction(
        CONST_EVENT.itemSell,
        "item_duihua",
        function(evtData)
            local whichUnit = evtData.buyingUnit
            local NPC = evtData.triggerUnit
            if hitem.getName(evtData.soldItem) == "强化" then
                hitem.qianghua(whichUnit)
                hplayer.dzCunDang[hunit.getOwner(whichUnit)].saveHeroBagToCundangServer()
            elseif hitem.getName(evtData.soldItem) == "精炼" then
                hitem.jinglian(whichUnit)
                hplayer.dzCunDang[hunit.getOwner(whichUnit)].saveHeroBagToCundangServer()
            elseif hitem.getName(evtData.soldItem) == "洗练" then
                hitem.xilian(whichUnit)
                hplayer.dzCunDang[hunit.getOwner(whichUnit)].saveHeroBagToCundangServer()
            elseif hitem.getName(evtData.soldItem) == "高级洗练" then
                hitem.gaojixilian(whichUnit)
                hplayer.dzCunDang[hunit.getOwner(whichUnit)].saveHeroBagToCundangServer()
            end
        end
    )
    --local itemCleanRemaining = 1800
    --htime.setInterval(
    --    1,
    --    function(curTimer)
    --        if
    --            itemCleanRemaining == 1 or itemCleanRemaining == 2 or itemCleanRemaining == 3 or itemCleanRemaining == 5 or
    --                itemCleanRemaining == 10 or
    --                itemCleanRemaining == 30
    --         then
    --            echo("请注意，" .. itemCleanRemaining .. "秒后将清理地面。")
    --        end
    --        if itemCleanRemaining <= 0 then
    --            echo("清理地面")
    --            hitemPool.freePool(CONST_CACHE.ITEM_POOL_PICK)
    --            echo("清理地面完成")
    --            itemCleanRemaining = 1800
    --        end
    --        itemCleanRemaining = itemCleanRemaining - 1
    --    end
    --)

    hevent.reaction(
        CONST_EVENT.skillEffect,
        "fenjieitem",
        function(evtData)
            if evtData.triggerSkill ~= hslk.n2i("分解物品") then
                return
            end
            local whichUnit = evtData.triggerUnit
            if whichUnit == nil then
                return
            end
            local whichPlayer = hunit.getOwner(whichUnit)
            if whichPlayer == nil then
                return
            end
            local targetItem = evtData.targetItem
            if targetItem == nil then
                return
            end
            if hitem.getHitemType(hitem.getId(targetItem)) ~= HITEM_TYPE.Zhuangbei then
                return
            end
            local dynamicItem = hitem.getDynamicItem(targetItem)
            if dynamicItem == nil then
                return
            end
            if dynamicItem.getOwner() ~= nil and dynamicItem.getOwner() ~= whichPlayer then
                return
            end
            hitem.destroy(targetItem)
            hplayer.dzCunDang[hunit.getOwner(whichUnit)].saveHeroBagToCundangServer()
            hfumo.fenjie(dynamicItem, whichPlayer)
        end
    )
    hevent.reaction(
        CONST_EVENT.skillEffect,
        "fenjiedimian",
        function(evtData)
            if evtData.triggerSkill ~= hslk.n2i("批量分解") then
                return
            end
            local whichUnit = evtData.triggerUnit
            if whichUnit == nil then
                return
            end
            local whichPlayer = hunit.getOwner(whichUnit)
            if whichPlayer == nil then
                return
            end
            local x = evtData.targetX
            local y = evtData.targetY
            local count = 0
            local itemsToFenjie = {}
            hitemPool.forEach(
                CONST_CACHE.ITEM_POOL_PICK,
                function(enumItem)
                    if count >= 10 then
                        return false
                    end
                    if hitem.getHitemType(hitem.getId(enumItem)) ~= HITEM_TYPE.Zhuangbei then
                        return
                    end
                    local xi = cj.GetItemX(enumItem)
                    local yi = cj.GetItemY(enumItem)
                    local d = math.distance(x, y, xi, yi)
                    if (d <= 300) then
                        local dynamicItem = hitem.getDynamicItem(enumItem)
                        if dynamicItem == nil then
                            return
                        end
                        if dynamicItem.getOwner() ~= nil and dynamicItem.getOwner() ~= whichPlayer then
                            return
                        end
                        count = count + 1
                        table.insert(itemsToFenjie, enumItem)
                    end
                end
            )
            for _, item in ipairs(itemsToFenjie) do
                local dynamicItem = hitem.getDynamicItem(item)
                hitem.destroy(item)
                hfumo.fenjie(dynamicItem, whichPlayer)
            end
        end
    )
    hevent.reaction(
        CONST_EVENT.skillEffect,
        "sellItem",
        function(evtData)
            if evtData.triggerSkill ~= hslk.n2i("售卖") then
                return
            end
            local whichUnit = evtData.triggerUnit
            if whichUnit == nil then
                return
            end
            local whichPlayer = hunit.getOwner(whichUnit)
            if whichPlayer == nil then
                return
            end
            local targetItem = evtData.targetItem
            if targetItem == nil then
                return
            end
            local dynamicItem = hitem.getDynamicItem(targetItem)
            if dynamicItem == nil then
                return
            end
            if dynamicItem.getOwner() ~= nil and dynamicItem.getOwner() ~= whichPlayer then
                return
            end
            hitem.destroy(targetItem)
            hplayer.dzCunDang[hunit.getOwner(whichUnit)].saveHeroBagToCundangServer()
            hitem.sellItem(hunit.getOwner(whichUnit), dynamicItem)
        end
    )
    hevent.reaction(
        CONST_EVENT.skillEffect,
        "selldimian",
        function(evtData)
            if evtData.triggerSkill ~= hslk.n2i("批量售卖") then
                return
            end
            local whichUnit = evtData.triggerUnit
            if whichUnit == nil then
                return
            end
            local whichPlayer = hunit.getOwner(whichUnit)
            if whichPlayer == nil then
                return
            end
            local x = evtData.targetX
            local y = evtData.targetY
            local count = 0
            local itemsToSell = {}
            hitemPool.forEach(
                CONST_CACHE.ITEM_POOL_PICK,
                function(enumItem)
                    if count >= 10 then
                        return false
                    end
                    local xi = cj.GetItemX(enumItem)
                    local yi = cj.GetItemY(enumItem)
                    local d = math.distance(x, y, xi, yi)
                    if (d <= 300) then
                        local dynamicItem = hitem.getDynamicItem(enumItem)
                        if dynamicItem == nil then
                            return
                        end
                        if dynamicItem.getOwner() ~= nil and dynamicItem.getOwner() ~= whichPlayer then
                            return
                        end
                        count = count + 1
                        table.insert(itemsToSell, enumItem)
                    end
                end
            )
            for _, item in ipairs(itemsToSell) do
                local dynamicItem = hitem.getDynamicItem(item)
                hitem.destroy(item)
                hitem.sellItem(whichPlayer, dynamicItem)
            end
        end
    )
end

--- refresh zhuangbei jineng shuxing
function hitem.refreshZhuangbeiJineng(player, dynamicItem, isAdd, slot)
    if player == nil or dynamicItem == nil or isAdd == nil or slot == nil then
        return
    end
    local hero = hplayer.getMainHero(player)
    local skills = hslk.i2v(dynamicItem.basic_item_id, "equipped_skill")
    local itemName = hslk.i2v(dynamicItem.basic_item_id, "Name")
    if hero == nil or itemName == nil then
        return
    end
    if skills ~= nil then
        for i, skill in ipairs(skills) do
            if isAdd then
                hevent.register(
                    hero,
                    skill.attr_type,
                    itemName .. "|" .. tostring(i) .. "|" .. tostring(slot),
                    function(evtData)
                        skill.attr(evtData, dynamicItem)
                    end
                )
            else
                hevent.unregister(
                    hero,
                    skill.attr_type,
                    itemName .. "|" .. tostring(i) .. "|" .. tostring(slot),
                    skill.attr
                )
            end
        end
    end

    if dynamicItem.baoshi.yi.has_slot == true and dynamicItem.baoshi.yi.baoshiName ~= nil then
        local baoshiName = dynamicItem.baoshi.yi.baoshiName
        local skills = hzhuanye.getSkillFromQHWP(baoshiName)
        if skills ~= nil then
            for i, skill in ipairs(skills) do
                if isAdd then
                    hevent.register(
                        hero,
                        skill.attr_type,
                        baoshiName .. "|" .. tostring(i) .. "|" .. tostring(slot) .. "",
                        skill.attr
                    )
                else
                    hevent.unregister(hero, skill.attr_type, baoshiName .. "|" .. tostring(i) .. "|" .. tostring(slot))
                end
            end
        end
    end
    if dynamicItem.baoshi.er.has_slot == true and dynamicItem.baoshi.er.baoshiName ~= nil then
        local baoshiName = dynamicItem.baoshi.er.baoshiName
        local skills = hzhuanye.getSkillFromQHWP(baoshiName)
        if skills ~= nil then
            for i, skill in ipairs(skills) do
                if isAdd then
                    hevent.register(
                        hero,
                        skill.attr_type,
                        baoshiName .. "|" .. tostring(i) .. "|" .. tostring(slot) .. "",
                        skill.attr
                    )
                else
                    hevent.unregister(hero, skill.attr_type, baoshiName .. "|" .. tostring(i) .. "|" .. tostring(slot))
                end
            end
        end
    end
    if dynamicItem.baoshi.san.has_slot == true and dynamicItem.baoshi.san.baoshiName ~= nil then
        local baoshiName = dynamicItem.baoshi.san.baoshiName
        local skills = hzhuanye.getSkillFromQHWP(baoshiName)
        if skills ~= nil then
            for i, skill in ipairs(skills) do
                if isAdd then
                    hevent.register(
                        hero,
                        skill.attr_type,
                        baoshiName .. "|" .. tostring(i) .. "|" .. tostring(slot) .. "",
                        skill.attr
                    )
                else
                    hevent.unregister(hero, skill.attr_type, baoshiName .. "|" .. tostring(i) .. "|" .. tostring(slot))
                end
            end
        end
    end
    hitem.updateQianghuawupinSkills(dynamicItem.fumo, hero, slot, isAdd)
    hitem.updateQianghuawupinSkills(dynamicItem.cixiu, hero, slot, isAdd)
    hitem.updateQianghuawupinSkills(dynamicItem.hujiapian, hero, slot, isAdd)
end

function hitem.updateGearScore(whichPlayer)
    local gearScore = hitem.calculateGearScore(whichPlayer)
    hcache.set(whichPlayer, "gearScore", gearScore)
    if hplayer.loc() == whichPlayer then
        hjapi.DzFrameSetText(hjapi.DzFrameFindByName("gearScore_text", 0), "装备评分：" .. gearScore)
    end
end

function hitem.getGearScore(whichPlayer)
    return hcache.get(whichPlayer, "gearScore", 0)
end

function hitem.calculateGearScore(whichPlayer)
    local gearScore = 0
    local hero = hplayer.getMainHero(whichPlayer)
    if hero == nil then
        return gearScore
    end

    for v = 1, NUM_EQUIPMENT_SLOT do
        local item = hplayer.dzCunDang[whichPlayer]["equipments"][v]
        if item ~= nil then
            local tmpGearScore =
                item.level * ZHUANGBEI_PINZHI_DATA[item.pinzhi].multi * FUBEN_NANDU_ITEM_FIXED_ATTR_MULTI[item.nandu]
            if item.baoshi.yi.has_slot == true and item.baoshi.yi.baoshiName ~= nil then
                tmpGearScore = tmpGearScore + 1
            end
            if item.baoshi.er.has_slot == true and item.baoshi.er.baoshiName ~= nil then
                tmpGearScore = tmpGearScore + 1
            end
            if item.baoshi.san.has_slot == true and item.baoshi.san.baoshiName ~= nil then
                tmpGearScore = tmpGearScore + 1
            end
            if item.fumo ~= nil then
                tmpGearScore = tmpGearScore + 1
            end
            if item.cixiu ~= nil then
                tmpGearScore = tmpGearScore + 1
            end
            if item.hujiapian ~= nil then
                tmpGearScore = tmpGearScore + 1
            end
            local qianghua = item.qianghua or 0
            local jinglian = item.jinglian or 0
            tmpGearScore =
                tmpGearScore *
                (1 + (QIANGHUA_DATA[qianghua].attrMulti - 1) * 0.5 + (JINGLIAN_DATA[jinglian].attrMulti - 1) * 0.5)
            gearScore = gearScore + tmpGearScore
        end
    end
    return math.round(gearScore, 0)
end

function hitem.updateQianghuawupinSkills(qianghuawupin, hero, slot, isAdd)
    if qianghuawupin == nil then
        return
    end
    local skills = hzhuanye.getSkillFromQHWP(qianghuawupin)
    if skills ~= nil then
        for i, skill in ipairs(skills) do
            if isAdd then
                hevent.register(
                    hero,
                    skill.attr_type,
                    qianghuawupin .. "|" .. tostring(i) .. "|" .. tostring(slot) .. "",
                    skill.attr
                )
            else
                hevent.unregister(hero, skill.attr_type, qianghuawupin .. "|" .. tostring(i) .. "|" .. tostring(slot))
            end
        end
    end
end

function hitem.qianghua(whichUnit)
    if whichUnit == nil then
        return
    end
    local player = hunit.getOwner(whichUnit)
    if whichUnit ~= hplayer.getMainHero(player) then
        return
    end
    local item = cj.UnitItemInSlot(whichUnit, 0)
    if item == nil then
        echo("物品栏第一格无物品", player)
        return
    end
    local dynamicItem = hitem.getDynamicItem(item)
    local hitem_type = hslk.i2v(dynamicItem.basic_item_id, "hitem_type")
    if hitem_type ~= "装备" then
        echo("第一格物品非装备", player)
        return
    end
    local startQianghua = 0
    if dynamicItem.qianghua ~= nil then
        startQianghua = dynamicItem.qianghua
    end
    if startQianghua >= QIANGHUA_MAX then
        echo("第一格物品已经满强化", player)
        return
    end
    local qianghuaData = QIANGHUA_DATA[startQianghua]
    local cost = table.clone(qianghuaData.cost)
    local pinzhi = dynamicItem.pinzhi or ZHUANGBEI_PINZHI.PUTONG
    for _, singleCost in ipairs(cost) do
        if singleCost.type == HSHOP_COST_TYPE.gold then
            singleCost.value = singleCost.value * pinzhi
            if dynamicItem.level ~= nil and dynamicItem.level > 60 then
                singleCost.value = singleCost.value * 1.5
            end
        end
    end
    if hresource.checkHasAllResource(player, cost, true) == false then
        return
    end
    hresource.changeAllResource(player, cost, true)
    local itemName = hslk.i2v(dynamicItem.basic_item_id, "Name")
    hevent.trigger(whichUnit, CONST_EVENT.qianghua, { triggerUnit = whichUnit, triggerName = itemName })
    local qianghua_rate = hattribute.getWithLimit(whichUnit, nil, "qianghua_rate", 0)
    if math.random(1, 10000) <= qianghuaData.upgradeRate * (100 + qianghua_rate) / 100 then
        dynamicItem.qianghua = startQianghua + 1
        dynamicItem.updateDescription()
        echo("强化" .. itemName .. "+" .. tostring(dynamicItem.qianghua) .. "成功！", player)
        if player == hplayer.loc() then
            local model = hjapi.FrameTag("SPRITE", "test_model", hjapi.DzGetGameUI())
            hjapi.DzFrameSetModel(model, "war3mapImported\\[UI]shengjizhuangbei1.MDX", 0, 0)
            hjapi.DzFrameSetPoint(model, 4, hjapi.DzGetGameUI(), 4, 0, -0.12)
            hjapi.DzFrameSetSize(model, 0.00001, 0.00001)
        end
        hsound.voice2Unit(
            hsound.voiceCreate("resource\\war3mapImported\\sound\\qianghuazhuangbei.mp3", 1000, false),
            100,
            whichUnit
        )
        return
    end
    if player == hplayer.loc() then
        local model = hjapi.FrameTag("SPRITE", "test_model", hjapi.DzGetGameUI())
        hjapi.DzFrameSetModel(model, "war3mapImported\\[UI]shengjizhuangbei2.MDX", 0, 0)
        hjapi.DzFrameSetPoint(model, 4, hjapi.DzGetGameUI(), 4, 0, -0.12)
        hjapi.DzFrameSetSize(model, 0.00001, 0.00001)
    end
    if math.random(1, 10000) <= qianghuaData.dropRate then
        echo("强化" .. itemName .. "+" .. tostring(dynamicItem.qianghua) .. "失败，装备降级", player)
        if startQianghua > 0 then
            dynamicItem.qianghua = startQianghua - 1
            dynamicItem.updateDescription()
        end
        return
    end
    if hditudengji.getDitudengji(hunit.getOwner(whichUnit)) < 40 then
        if math.random(1, 10000) <= qianghuaData.destroyRate then
            echo("强化" .. itemName .. "+" .. tostring(dynamicItem.qianghua) .. "失败，装备强化等级清零", player)
            dynamicItem.qianghua = nil
            dynamicItem.updateDescription()
            return
        end
    end
    echo("强化" .. itemName .. "+" .. tostring(dynamicItem.qianghua) .. "失败，请再接再厉", player)
end

function hitem.jinglian(whichUnit)
    if whichUnit == nil then
        return
    end
    local player = hunit.getOwner(whichUnit)
    if whichUnit ~= hplayer.getMainHero(player) then
        return
    end
    local item = cj.UnitItemInSlot(whichUnit, 0)
    if item == nil then
        echo("物品栏第一格无物品", player)
        return
    end
    local dynamicItem = hitem.getDynamicItem(item)
    local hitem_type = hslk.i2v(dynamicItem.basic_item_id, "hitem_type")
    if hitem_type ~= "装备" then
        echo("第一格物品非装备", player)
        return
    end
    local startJinglian = 0
    if dynamicItem.jinglian ~= nil then
        startJinglian = dynamicItem.jinglian
    end
    if startJinglian >= JINGLIAN_MAX then
        echo("第一格物品已经满精炼", player)
        return
    end
    local jinglianData = JINGLIAN_DATA[startJinglian]
    local cost = table.clone(jinglianData.cost)
    local pinzhi = dynamicItem.pinzhi or ZHUANGBEI_PINZHI.PUTONG
    for _, singleCost in ipairs(cost) do
        if singleCost.type == HSHOP_COST_TYPE.gold then
            singleCost.value = singleCost.value * pinzhi
            if dynamicItem.level ~= nil and dynamicItem.level > 60 then
                singleCost.value = singleCost.value * 1.5
            end
        end
    end
    if hresource.checkHasAllResource(player, cost, true) == false then
        return
    end
    hresource.changeAllResource(player, cost, true)
    local itemName = hslk.i2v(dynamicItem.basic_item_id, "Name")
    hevent.trigger(whichUnit, CONST_EVENT.jinglian, { triggerUnit = whichUnit, triggerName = itemName })
    local jinglian_rate = hattribute.getWithLimit(whichUnit, nil, "jinglian_rate", 0)
    if math.random(1, 10000) <= jinglianData.upgradeRate * (100 + jinglian_rate) / 100 then
        dynamicItem.jinglian = startJinglian + 1
        dynamicItem.updateDescription()
        echo("精炼" .. itemName .. "+" .. tostring(dynamicItem.jinglian) .. "成功！", player)
        if player == hplayer.loc() then
            local model = hjapi.FrameTag("SPRITE", "test_model", hjapi.DzGetGameUI())
            hjapi.DzFrameSetModel(model, "war3mapImported\\[UI]shengjizhuangbei1.MDX", 0, 0)
            hjapi.DzFrameSetPoint(model, 4, hjapi.DzGetGameUI(), 4, 0, -0.12)
            hjapi.DzFrameSetSize(model, 0.00001, 0.00001)
        end
        hsound.voice2Unit(
            hsound.voiceCreate("resource\\war3mapImported\\sound\\qianghuazhuangbei.mp3", 1000, false),
            100,
            whichUnit
        )
        return
    end
    if player == hplayer.loc() then
        local model = hjapi.FrameTag("SPRITE", "test_model", hjapi.DzGetGameUI())
        hjapi.DzFrameSetModel(model, "war3mapImported\\[UI]shengjizhuangbei2.MDX", 0, 0)
        hjapi.DzFrameSetPoint(model, 4, hjapi.DzGetGameUI(), 4, 0, -0.12)
        hjapi.DzFrameSetSize(model, 0.00001, 0.00001)
    end
    if math.random(1, 10000) <= jinglianData.dropRate then
        echo("精炼" .. itemName .. "+" .. tostring(dynamicItem.jinglian) .. "失败，装备降级", player)
        if startJinglian > 0 then
            dynamicItem.jinglian = startJinglian - 1
            dynamicItem.updateDescription()
        end
        return
    end
    if hditudengji.getDitudengji(hunit.getOwner(whichUnit)) < 50 then
        if math.random(1, 10000) <= jinglianData.destroyRate then
            echo("精炼" .. itemName .. "+" .. tostring(dynamicItem.jinglian) .. "失败，装备精炼等级清零", player)
            dynamicItem.jinglian = nil
            dynamicItem.updateDescription()
            return
        end
    end
    echo("精炼" .. itemName .. "+" .. tostring(dynamicItem.jinglian) .. "失败，请再接再厉", player)
end

function hitem.xilian(whichUnit)
    if whichUnit == nil then
        return
    end
    local player = hunit.getOwner(whichUnit)
    if whichUnit ~= hplayer.getMainHero(player) then
        return
    end
    local item = cj.UnitItemInSlot(whichUnit, 0)
    if item == nil then
        echo("物品栏第一格无物品", player)
        return
    end
    local dynamicItem = hitem.getDynamicItem(item)
    local hitem_type = hslk.i2v(dynamicItem.basic_item_id, "hitem_type")
    if hitem_type ~= "装备" then
        echo("第一格物品非装备", player)
        return
    end
    local secondItem = cj.UnitItemInSlot(whichUnit, 1)
    if secondItem == nil then
        echo("物品栏第二格无物品", player)
        return
    end
    local secondDynamicItem = hitem.getDynamicItem(secondItem)
    local secondhitem_type = hslk.i2v(secondDynamicItem.basic_item_id, "hitem_type")
    if secondhitem_type ~= "装备" then
        echo("第二格物品非装备", player)
        return
    end
    if
        dynamicItem.basic_item_id ~= secondDynamicItem.basic_item_id or dynamicItem.nandu ~= secondDynamicItem.nandu or
        dynamicItem.level ~= secondDynamicItem.level or
        dynamicItem.pinzhi ~= secondDynamicItem.pinzhi
    then
        echo("第一格和第二格物品物品等级，品质或者掉落难度级别不一样", player)
        return
    end

    hitem.destroy(secondItem)
    dynamicItem.refreshCitiao(dynamicItem.level, { whichUnit })

    echo("洗练" .. hitem.getName(item) .. "成功！", player)
end

function hitem.gaojixilian(whichUnit)
    if whichUnit == nil then
        return
    end
    local player = hunit.getOwner(whichUnit)
    if whichUnit ~= hplayer.getMainHero(player) then
        return
    end
    local item = cj.UnitItemInSlot(whichUnit, 0)
    if item == nil then
        echo("物品栏第一格无物品", player)
        return
    end
    local dynamicItem = hitem.getDynamicItem(item)
    local hitem_type = hslk.i2v(dynamicItem.basic_item_id, "hitem_type")
    if dynamicItem == nil then
        echo("第一格物品异常", player)
        return
    end
    if dynamicItem.getOwner() ~= player then
        echo("第一格物品并不属于你", player)
        return
    end
    if hitem_type ~= "装备" then
        echo("第一格物品非装备", player)
        return
    end

    if dynamicItem.level > 73 then
        echo("装备等级过高", player)
        return
    elseif dynamicItem.level <= 73 and dynamicItem.level >= 64 then
        if hresource.checkHasSingleResource(player, HSHOP_COST_TYPE.zhongjixilianshi, 1, true) == false then
            echo("洗练失败", player)
            return
        else
            local changeResult = hresource.changeSingleResource(player, HSHOP_COST_TYPE.zhongjixilianshi, 1, true)
            if changeResult == false then
                echo("洗练失败1", player)
                return
            end
        end
    elseif dynamicItem.level <= 63 and dynamicItem.level >= 1 then
        if hresource.checkHasSingleResource(player, HSHOP_COST_TYPE.chujixilianshi, 1, true) == false then
            echo("洗练失败", player)
            return
        else
            local changeResult = hresource.changeSingleResource(player, HSHOP_COST_TYPE.chujixilianshi, 1, true)
            if changeResult == false then
                echo("洗练失败1", player)
                return
            end
        end
    else
        echo("洗练失败，装备等级低于1", player)
        return
    end

    dynamicItem.refreshCitiao(dynamicItem.level, { whichUnit })

    echo("洗练" .. hitem.getName(item) .. "成功！", player)
end

--- 获取物品X坐标
---@param it userdata
---@return number
function hitem.x(it)
    return cj.GetItemX(it)
end

--- 获取物品Y坐标
---@param it userdata
---@return number
function hitem.y(it)
    return cj.GetItemY(it)
end

--- merge two item
---@param from DynamicItem
---@param to DynamicItem
---@return boolean
function hitem.tryMergeItem(from, to)
    if from == nil or to == nil then
        return false
    end
    if from.getOwner() == nil or to.getOwner() == nil or from.getOwner() ~= to.getOwner() then
        return false
    end
    if from.basic_item_id ~= to.basic_item_id then
        return false
    end
    if hslk.i2v(from.basic_item_id, "hitem_type") == "装备" or hslk.i2v(from.basic_item_id, "hitem_type") == "速效治疗石" then
        return false
    end
    if from.stack + to.stack > 99 then
        return false
    end
    to.addStack(from.stack)
    return true
end

--- 获取物品Z坐标
---@param it userdata
---@return number
function hitem.z(it)
    return hjapi.Z(cj.GetItemX(it), cj.GetItemY(it))
end

-- 清理物品缓存数据
---@protected
function hitem.free(whichItem)
    hitemPool.free(whichItem)
    hevent.free(whichItem)
    hcache.free(whichItem)
end

--- match done
---@param whichUnit userdata
---@param whichItem userdata
---@param triggerData table
function hitem.used(whichUnit, whichItem, triggerData)
    triggerData = triggerData or {}
    triggerData.triggerUnit = whichUnit
    triggerData.triggerItem = whichItem
    hevent.trigger(whichUnit, CONST_EVENT.itemUsed, triggerData)
end

--- 删除物品，可延时
---@param it userdata
---@param delay number
function hitem.destroy(it, delay)
    if (hitem.isDestroyed(it)) then
        return
    end
    delay = delay or 0
    if (delay <= 0 and it ~= nil) then
        hitem.free(it)
        cj.SetWidgetLife(it, 1.00)
        cj.RemoveItem(it)
    else
        htime.setTimeout(
            delay,
            function(t)
                t.destroy()
                if (hitem.isDestroyed(it)) then
                    return
                end
                hitem.free(it)
                cj.SetWidgetLife(it, 1.00)
                cj.RemoveItem(it)
            end
        )
    end
end

---@protected
function hitem.destroyFromUnit(whichUnit)
    if (whichUnit ~= nil) then
        hitem.forEach(
            whichUnit,
            function(enumItem)
                if (enumItem ~= nil) then
                    hitem.destroy(enumItem)
                end
            end
        )
    end
end

--- 获取物品ID字符串
---@param itOrId userdata|number|string
---@return string|nil
function hitem.getId(itOrId)
    local id
    if (type(itOrId) == "userdata") then
        id = cj.GetItemTypeId(itOrId)
        if (id == 0) then
            return
        end
        id = i2c(id)
    elseif (type(itOrId) == "number") then
        id = i2c(itOrId)
    elseif (type(itOrId) == "string") then
        id = itOrId
    end
    return id
end

--- 获取物品名称
---@param itOrId userdata|string|number
---@return string
function hitem.getName(itOrId)
    local n = ""
    if (type(itOrId) == "userdata") then
        n = cj.GetItemName(itOrId)
    elseif (type(itOrId) == "string" or type(itOrId) == "number") then
        n = hslk.i2v(itOrId, "slk", "Name")
    end
    return n
end

-- 获取物品的图标路径
---@param itOrId userdata|string|number
---@return string
function hitem.getArt(itOrId)
    return hslk.i2v(hitem.getId(itOrId), "slk", "Art")
end

--- 获取物品的模型路径
---@param itOrId userdata|string|number
---@return string
function hitem.getFile(itOrId)
    return hslk.i2v(hitem.getId(itOrId), "slk", "file")
end

--- 获取物品的分类
---@param itOrId userdata|string|number
---@return string
function hitem.getClass(itOrId)
    return hslk.i2v(hitem.getId(itOrId), "slk", "class")
end

--- 获取物品所需的金币
---@param itOrId userdata|string|number
---@return number
function hitem.getGoldCost(itOrId)
    return math.floor(hslk.i2v(hitem.getId(itOrId), "slk", "goldcost") or 0)
end

--- 获取物品所需的木头
---@param itOrId userdata|string|number
---@return number
function hitem.getLumberCost(itOrId)
    return math.floor(hslk.i2v(hitem.getId(itOrId), "slk", "lumbercost") or 0)
end

--- 获取物品是否可以使用
---@param itOrId userdata|string|number
---@return boolean
function hitem.getIsUsable(itOrId)
    return "1" == hslk.i2v(hitem.getId(itOrId), "slk", "usable")
end

function hitem.getColoredNameBasedOnPinzhi(name)
    if name == nil then
        err("empty name")
        return nil
    end
    local id = hslk.n2i(name)
    local pinzhi = ZHUANGBEI_PINZHI.PUTONG
    if id ~= nil then
        pinzhi = hitem.getItemMinPinzhi(id)
        return ZHUANGBEI_PINZHI_DATA[pinzhi].color(name)
    end
    return name
end

--- 获取物品是否自动使用
---@param itOrId userdata|string|number
---@return boolean
function hitem.getIsPowerUp(itOrId)
    return "1" == hslk.i2v(hitem.getId(itOrId), "slk", "powerup")
end

--- 获取物品是否使用后自动消失
---@param itOrId userdata|string|number
---@return boolean
function hitem.getIsPerishable(itOrId)
    return "1" == hslk.i2v(hitem.getId(itOrId), "slk", "perishable")
end

--- 获取物品是否可卖
---@param itOrId userdata|string|number
---@return boolean
function hitem.getIsSellAble(itOrId)
    return "1" == hslk.i2v(hitem.getId(itOrId), "slk", "sellable")
end

--- 获取物品自带技能abilList
---@param itOrId userdata|string|number
---@return string
function hitem.getAbilList(itOrId)
    return hslk.i2v(hitem.getId(itOrId), "slk", "abilList")
end

--- 获取物品的属性加成
---@param itOrId userdata|string|number
---@return table
function hitem.getAttribute(itOrId)
    return hslk.i2v(hitem.getId(itOrId), "_attr") or {}
end

--- 获取dynamic item
---@param itOrId userdata|string|number
---@return DynamicItem
function hitem.getDynamicItem(it)
    return hcache.get(it, CONST_CACHE.ITEM_POOL_DYNAMIC)
end

--- 获取物品穿戴后特有属性加成
---@param itOrId userdata|string|number
---@return table
function hitem.getEquippedAttribute(it)
    return hslk.i2v(hitem.getId(it), "equipped_attr") or {}
end

--- 获取物品穿戴后基础属性加成
---@param itOrId userdata|string|number
---@return table
function hitem.getEquippedBasicAttribute(dynamicItem)
    local pinzhi = dynamicItem.pinzhi
    local nandu = dynamicItem.nandu or FUBEN_NANDU.PUTONG
    if pinzhi == nil or pinzhi < ZHUANGBEI_PINZHI.PUTONG or pinzhi > ZHUANGBEI_PINZHI.SHENHUA then
        pinzhi = ZHUANGBEI_PINZHI.PUTONG
    end
    local pinzhiMulti = ZHUANGBEI_PINZHI_DATA[pinzhi].multi
    local nanduMulti = FUBEN_NANDU_ITEM_FIXED_ATTR_MULTI[nandu]
    local level = dynamicItem.level or 1
    local levelMulti = EQUIPMENT_LEVEL_TO_BASIC_ATTR_MULTI[level]
    local qianghua = dynamicItem.qianghua or 0
    local qianghuaMulti = QIANGHUA_DATA[qianghua].attrMulti
    local itemType = hslk.i2v(dynamicItem.basic_item_id, "equipment_type")
    local basicAttr = EQUIPMENT_TYPE_BASIC_ATTR[itemType] or {}
    local maxAttr = EQUIPMENT_TYPE_MAX_ATTR[itemType] or {}
    local speedMulti = hslk.i2v(dynamicItem.basic_item_id, "speed")
    if speedMulti == nil then
        speedMulti = 1
    end
    return hattribute.getAttributeWithMultiAndLimit(
        basicAttr,
        pinzhiMulti * levelMulti * qianghuaMulti * speedMulti * nanduMulti,
        maxAttr
    )
end

--- 获取物品装备类型
---@param itOrId userdata|string|number
---@return string|nil
function hitem.getEquipmentType(it)
    return hslk.i2v(hitem.getId(it), "equipment_type")
end

--- 获取物品装备类型
---@param itOrId userdata|string|number
---@return string|nil
function hitem.getEquipmentTypeByID(id)
    return hslk.i2v(id, "equipment_type")
end

--- 获取物品的等级
---@param it userdata
---@return number
function hitem.getLevel(it)
    if (it ~= nil) then
        return cj.GetItemLevel(it)
    end
    return 0
end

function hitem.saveInZhuangbeiBeibao(id)
    return hslk.i2v(id, "_saveInZhuangbeiBeibao") == true
end

function hitem.mergeItem(whichUnit)
    local itemsInBag = hitem.getItemsInBag(whichUnit)
    hitem.forEach(
        whichUnit,
        function(enumItem, _)
            if enumItem == nil then
                return
            end
            if hitem.getClass(enumItem) ~= "Charged" then
                return
            end
            local dynamicItem = hitem.getDynamicItem(enumItem)

            if dynamicItem == nil then
                echo("发现未知物品，物品已被湮灭。")
                hitem.destroy(enumItem)
                return
            end
            if dynamicItem.getOwner() ~= hunit.getOwner(whichUnit) then
                echo("发现不属于该单位的物品，物品已被湮灭。")
                hitem.destroy(enumItem)
            end
            local currentNumber = itemsInBag[hitem.getName(enumItem)]
            if currentNumber == 0 then
                hitem.destroy(enumItem)
                return
            else
                local existingCount = dynamicItem.stack
                local remaining = currentNumber - existingCount
                local addedItem = math.min(99 - existingCount, remaining)
                hitem.setCharges(enumItem, existingCount + addedItem)
                itemsInBag[hitem.getName(enumItem)] = remaining - addedItem
            end
        end
    )
end

--- 获取物品的件数（以物品右下标的使用次数作为“件”）
--- 框架会自动强制最低件数为1
---@param it userdata
---@return number
function hitem.getCharges(it)
    if (it == nil) then
        return 0
    end
    return cj.GetItemCharges(it)
end

--- 设置物品的使用次数
---@param it userdata
---@param charges number
function hitem.setCharges(it, charges)
    if (it ~= nil and charges >= 0) then
        cj.SetItemCharges(it, charges)
        local dynamicitem = hitem.getDynamicItem(it)
        if dynamicitem ~= nil then
            dynamicitem.setStack(charges)
        end
    end
end

--- 获取某单位身上空格物品栏数量
---@param whichUnit userdata
---@return number
function hitem.getEmptySlot(whichUnit)
    local qty = cj.UnitInventorySize(whichUnit)
    local it
    for i = 0, 5, 1 do
        it = cj.UnitItemInSlot(whichUnit, i)
        if (it ~= nil) then
            qty = qty - 1
        end
    end
    return qty
end

--- 获取某单位指定slot的物品
---@param whichUnit userdata
---@return it
function hitem.getItemAtSlot(whichUnit, slot)
    return cj.UnitItemInSlot(whichUnit, slot)
end

--- 循环获取某单位6格物品
--- 遍历过程中返回 false 则中断
---@param whichUnit userdata
---@param action fun(enumItem:userdata,slotIndex:number)
---@return number
function hitem.forEach(whichUnit, action)
    local it
    for i = 0, 5, 1 do
        it = cj.UnitItemInSlot(whichUnit, i)
        local res = action(it, i)
        if (type(res) == "boolean" and res == false) then
            break
        end
    end
end

function hitem.getPinzhi(whichItem)
    local dynamicItem = hitem.getDynamicItem(whichItem)
    if dynamicItem ~= nil then
        return dynamicItem.pinzhi
    end
end

--- 附加单位获得物品后的属性
---@protected
function hitem.addProperty(whichUnit, itId, charges)
    if (whichUnit == nil or itId == nil) then
        return
    end
    hattribute.caleAttribute(CONST_DAMAGE_SRC.item, true, whichUnit, hitem.getAttribute(itId), charges)
end

function hitem.getItemMinPinzhi(id)
    local minpinzhi = hslk.i2v(id, "min_pinzhi")
    minpinzhi = minpinzhi or ZHUANGBEI_PINZHI.PUTONG
    return minpinzhi
end

--- 削减单位获得物品后的属性
---@protected
function hitem.subProperty(whichUnit, itId, charges)
    if (whichUnit == nil or itId == nil) then
        return
    end
    hattribute.caleAttribute(CONST_DAMAGE_SRC.item, false, whichUnit, hitem.getAttribute(itId), charges)
end

function hitem.bagFull(whichUnit)
    if whichUnit == nil then
        return true
    end
    return hitem.getEmptySlot(whichUnit) == 0
end

--[[
    创建物品
    options = {
        id = "I001", --物品ID
        charges = 1, --物品可使用次数（可选，默认为1）
        whichUnit = nil, --哪个单位（可选）
        x = nil, --哪个坐标X（可选）
        y = nil, --哪个坐标Y（可选）
        during = -1, --持续时间（可选，小于0无限制，如果有whichUnit，此项无效）
        dynamicItem = nil, --动态属性属性
    }
]]
---@alias noteItemCreate {id string,charges number,whichUnit userdata,x number,y number,during number,dynamicItem DynamicItem}
---@param options noteItemCreate
---@return userdata|nil
function hitem.create(options)
    if (options.id == nil) then
        err("hitem create -it-id")
        return
    end
    if (options.charges == nil) then
        local slkCharges = hslk.i2v(options.id, "slk", "uses")
        if (slkCharges == "" or slkCharges == nil) then
            slkCharges = nil
        else
            slkCharges = math.floor(slkCharges)
        end
        options.charges = slkCharges or 1
    end
    if
        hitem.getHitemType(options.id) == HITEM_TYPE.Zhuangbei or
        hitem.getHitemType(options.id) == HITEM_TYPE.SUXIAOZHILIAOSHI
    then
        options.charges = 0
    end
    if (options.charges < 0) then
        return
    end
    if options.dynamicItem == nil then
        err("hitem create -dynamicItem")
    end
    local charges = options.charges
    local during = options.during or -1
    -- 优先级 坐标 > 单位
    local x, y
    local id = options.id
    if (options.x ~= nil and options.y ~= nil) then
        x = options.x
        y = options.y
    elseif (options.whichUnit ~= nil) then
        x = hunit.x(options.whichUnit)
        y = hunit.y(options.whichUnit)
    else
        err("hitem create -position")
        return
    end
    if (type(id) == "string") then
        id = c2i(id)
    end
    local it = cj.CreateItem(id, x, y)
    hcache.alloc(it)
    hcache.set(it, CONST_CACHE.ITEM_POOL_DYNAMIC, options.dynamicItem)
    cj.SetItemCharges(it, charges)
    -- 如果不是创建给单位，又或者单位已经不存在了，直接返回
    if
        (options.whichUnit == nil or hunit.isDestroyed(options.whichUnit) or hunit.isDead(options.whichUnit) or
            hitem.bagFull(options.whichUnit))
    then
        -- 掉在地上
        hitemPool.insert(CONST_CACHE.ITEM_POOL_PICK, it)
        if (options.whichUnit ~= nil and during > 0) then
            htime.setTimeout(
                during,
                function(t)
                    t.destroy()
                    hitem.destroy(it, 0)
                end
            )
        end
    else
        cj.UnitAddItem(options.whichUnit, it)
    end
    return it
end

function hitem.copyAndGive(whichUnit, item)
    if whichUnit == nil or item == nil then
        return
    end
    hitem.create(
        {
            id = hitem.getId(item),
            charges = 1,
            whichUnit = whichUnit
        }
    )
end

--- 使一个单位的所有物品给另一个单位
---@param origin userdata
---@param target userdata
function hitem.give(origin, target)
    if (origin == nil or target == nil) then
        return
    end
    for i = 0, 5, 1 do
        local it = cj.UnitItemInSlot(origin, i)
        if (it ~= nil) then
            hitem.create(
                {
                    id = hitem.getId(it),
                    charges = hitem.getCharges(it),
                    whichUnit = target
                }
            )
        end
        hitem.destroy(it, 0)
    end
end

--- 操作物品给一个单位
---@param it userdata
---@param targetUnit userdata
function hitem.pick(it, targetUnit)
    if (it == nil or targetUnit == nil) then
        return
    end
    cj.UnitAddItem(targetUnit, it)
end

--- 复制一个单位的所有物品给另一个单位
---@param origin userdata
---@param target userdata
function hitem.copy(origin, target)
    if (origin == nil or target == nil) then
        return
    end
    for i = 0, 5, 1 do
        local it = cj.UnitItemInSlot(origin, i)
        if (it ~= nil) then
            hitem.create(
                {
                    id = hitem.getId(it),
                    charges = hitem.getCharges(it),
                    whichUnit = target
                }
            )
        end
    end
end

--- 令一个单位把物品扔在地上
---@param origin userdata
---@param slot nil|number 物品位置
function hitem.drop(origin, slot)
    if (origin == nil or hunit.isDestroyed(origin) or hunit.isDead(origin)) then
        return
    end
    if (slot == nil) then
        for i = 0, 5, 1 do
            local it = cj.UnitItemInSlot(origin, i)
            if (it ~= nil) then
                cj.UnitDropItemPoint(origin, it, hunit.x(origin), hunit.y(origin))
            end
        end
    else
        local it = cj.UnitItemInSlot(origin, slot)
        if (it ~= nil) then
            cj.UnitDropItemPoint(origin, it, hunit.x(origin), hunit.y(origin))
        end
    end
end

--- 一键拾取区域(x,y)长宽(w,h)
---@param u userdata
---@param x number
---@param y number
---@param w number
---@param h number
function hitem.pickRect(u, x, y, w, h)
    if (u == nil or hunit.isDestroyed(u) or hunit.isDead(u)) then
        return
    end
    local items = {}
    hitemPool.forEach(
        CONST_CACHE.ITEM_POOL_PICK,
        function(enumItem)
            local xi = cj.GetItemX(enumItem)
            local yi = cj.GetItemY(enumItem)
            local d = math.distance(x, y, xi, yi)
            local deg = math.angle(x, y, xi, yi)
            local distance = math.getMaxDistanceInRect(w, h, deg)
            if (d <= distance) then
                table.insert(items, enumItem)
            end
        end
    )
end

-- 一键拾取圆(x,y)半径(r)
---@param u userdata
---@param x number
---@param y number
---@param r number
function hitem.pickRound(u, x, y, r)
    if (u == nil or hunit.isDestroyed(u) or hunit.isDead(u)) then
        return
    end
    local items = {}
    hitemPool.forEach(
        CONST_CACHE.ITEM_POOL_PICK,
        function(enumItem)
            local xi = cj.GetItemX(enumItem)
            local yi = cj.GetItemY(enumItem)
            local d = math.distance(x, y, xi, yi)
            if (d <= r) then
                table.insert(items, enumItem)
            end
        end
    )
end
