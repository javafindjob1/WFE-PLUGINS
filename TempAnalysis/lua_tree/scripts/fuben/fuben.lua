FUBEN_LIST = {}
require "scripts.fuben.conglinshenchu"
require "scripts.fuben.yuelianghu"
require "scripts.fuben.jianyu"
require "scripts.fuben.xuesejundayin"
require "scripts.fuben.shengguangdajiaotang"
require "scripts.fuben.huoyanzhixin"
require "scripts.fuben.banrenmayingdi"
require "scripts.fuben.airendixiacheng"
require "scripts.fuben.aonikexiya"
require "scripts.fuben.geluerchaoxue"
require "scripts.fuben.fashita"
require "scripts.fuben.posuidating"
require "scripts.fuben.fengbaoyaosai"
require "scripts.fuben.heianshendian"
require "scripts.fuben.taiyangzhijin"

FUBEN_OPEN_LIST = {
    "丛林深处",
    "月亮湖",
    "王城监狱",
    "血色军大营",
    "圣光大教堂",
    "半人马营地",
    "矮人地下城",
    "火焰之心",
    "黑龙王子的巢穴",
    "屠龙者的巢穴",
    "法师塔",
    "破碎大厅",
    "风暴要塞",
    "黑暗神殿",
    "太阳之井"
}

XIAOGUAI_BASIC_DIAOLUO = {
    "戒指",
    "项链",
    "披风",
    "手套",
    "衣服",
    "头盔",
    "鞋子",
    "法器"
}

BOSS_BASIC_DIAOLUO = {
    "单手剑",
    "戒指",
    "项链",
    "披风",
    "手套",
    "衣服",
    "头盔",
    "鞋子",
    "法器",
    "单手锤",
    "双手剑",
    "双手斧",
    "双手锤",
    "法杖",
    "饰品",
    "弓"
}

local function setup_nandu_diaoluo()
    local tmpCONFIG = {}
    -- 20% chance lvl up from putong to jingliang
    tmpCONFIG[ZHUANGBEI_PINZHI.PUTONG] = 2000
    DIAOLUO_PINZHI_NANDU_CONFIG[FUBEN_NANDU.PUTONG] = tmpCONFIG

    local tmpCONFIG = {}
    tmpCONFIG[ZHUANGBEI_PINZHI.PUTONG] = 2000
    DIAOLUO_PINZHI_NANDU_CONFIG[FUBEN_NANDU.YINGXIONG] = tmpCONFIG

    local tmpCONFIG = {}
    tmpCONFIG[ZHUANGBEI_PINZHI.PUTONG] = 2000
    DIAOLUO_PINZHI_NANDU_CONFIG[FUBEN_NANDU.SHISHI] = tmpCONFIG

    local tmpCONFIG = {}
    tmpCONFIG[ZHUANGBEI_PINZHI.PUTONG] = 2000
    DIAOLUO_PINZHI_NANDU_CONFIG[FUBEN_NANDU.CHUANQI] = tmpCONFIG
end

function buildFuben()
    setup_nandu_diaoluo()
    for _, v in ipairs(FUBEN_LIST) do
        for _, vv in ipairs(FUBEN_OPEN_LIST) do
            if v.name == vv then
                v.setup()
            end
        end
    end
end
