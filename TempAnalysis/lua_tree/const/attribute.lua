-- 属性系统
-- fmt key,label,init
-- 格式 键值,名字,初始值
-- primary,life,mana,move,defend_white,attack_range,attack_range_acquire这些值会在初始化时强行覆盖为slk数据，初始值写了没用
CONST_ATTR_CONF = {}

--- 键值归档
CONST_ATTR_KEYS = {}

--- key=>label
CONST_ATTR_LABEL = {}

--- key=>cundang label
CONST_ATTR_CUNDANG_LABEL = {}
--- key=>cundang label
CONST_ATTR_CUNDANG_TO_ATTR = {}
--- 存档词条基础数值
CONST_ATTR_CUNDANG_CITIAO_VAL = {}
--- 属性限制
CONST_ATTR_MIN = {}
CONST_ATTR_MAX = {}
CONST_ATTR_SHOW_USER = {}
CONST_ATTR_SHOW_TYPE = {
    NONE = "不显示",
    WULI = "物理",
    MOFA = "魔法",
    TONGYONG = "通用",
    FANGYU = "防御",
    ZHUANYE = "专业",
    QITA = "其它"
}
--- key=>defaultValue
CONST_ATTR_VALUE = {}
CITIAO_POOL = {}

---@type fun(conf:table[])
ATTR_CONFIGURATOR = function(conf)
    for _, v in ipairs(conf) do
        if (CONST_ATTR_LABEL[v[1]] == nil) then
            table.insert(CONST_ATTR_CONF, v)
            table.insert(CONST_ATTR_KEYS, v[1])
        end
        CONST_ATTR_LABEL[v[1]] = v[2]
        CONST_ATTR_VALUE[v[1]] = v[3]
        CONST_ATTR_MIN[v[1]] = v[6]
        CONST_ATTR_MAX[v[1]] = v[7]
        CONST_ATTR_SHOW_USER[v[1]] = v[8]
        if v[4] ~= nil and v[4] ~= "" then
            table.insert(CITIAO_POOL, v[1])
            CONST_ATTR_CUNDANG_LABEL[v[1]] = v[4]
            CONST_ATTR_CUNDANG_TO_ATTR[v[4]] = v[1]
            CONST_ATTR_CUNDANG_CITIAO_VAL[v[1]] = v[5]
        end
    end
end

--- 属性配置器
--- 属性标识 中文名 默认值 词条存档 词条基础数值 下限 上限 是否显示给用户
ATTR_CONFIGURATOR(
    {
        { "life", "生命", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "mana", "魔法", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "defend", "护甲", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "mojia", "魔法护甲", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.FANGYU },
        { "level", "等级", 1, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "defend_white", "基础护甲", 0, "A", 8, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "defend_green", "附加护甲", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "attack_space", "攻击间隔", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "attack_space_main", "主手武器间隔", 2.0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.WULI },
        { "attack_space_origin", "基础攻击间隔", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.WULI },
        { "attack", "攻击", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "attack_white", "基础攻击", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "attack_green", "附加攻击", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "attack_range", "攻击范围", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.TONGYONG },
        { "attack_range_acquire", "主动攻击范围", 0, "", -1, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "zhushuxing", "主属性", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "str", "力量", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "agi", "敏捷", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "int", "智力", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "str_green", "附加力量", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "agi_green", "附加敏捷", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "int_green", "附加智力", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "str_white", "基础力量", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "agi_white", "基础敏捷", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "int_white", "基础智力", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "life_back", "生命恢复", 0, "1", 5, nil, nil, CONST_ATTR_SHOW_TYPE.FANGYU },
        { "mana_back", "基础能量恢复", 0, "2", 0.5, nil, nil, CONST_ATTR_SHOW_TYPE.TONGYONG },
        { "reborn", "复活时间", -999, "", nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "rebornX", "复活坐标X", nil, "", nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "rebornY", "复活坐标Y", nil, "", nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "gedang", "格挡概率", 0, "3", 1, 0, 60, CONST_ATTR_SHOW_TYPE.FANGYU },
        { "gedang_jianshang", "格挡减伤", 30, "4", 3, 0, 75, CONST_ATTR_SHOW_TYPE.FANGYU },
        { "shanbi", "闪避概率", 0, "5", 1, 0, 40, CONST_ATTR_SHOW_TYPE.FANGYU },
        { "zhaojia", "招架概率", 0, "6", 2, 0, 60, CONST_ATTR_SHOW_TYPE.FANGYU },
        { "jianshang", "减伤", 0, "7", 0.5, -500, 70, CONST_ATTR_SHOW_TYPE.FANGYU },
        { "mokang", "魔抗", 0, "8", 0.5, 0, 60, CONST_ATTR_SHOW_TYPE.FANGYU },
        { "wu_bao", "物理暴击概率", 0, "9", 1, nil, nil, CONST_ATTR_SHOW_TYPE.WULI },
        { "wu_baoshang", "物理暴伤", 150, "a", 3, 100, 500, CONST_ATTR_SHOW_TYPE.WULI },
        { "fa_bao", "法术暴击概率", 0, "c", 1, nil, nil, CONST_ATTR_SHOW_TYPE.MOFA },
        { "fa_baoshang", "法术暴伤", 150, "b", 3, 100, 500, CONST_ATTR_SHOW_TYPE.MOFA },
        { "wu_chuan", "物理穿透百分比", 0, "d", 2, 0, 100, CONST_ATTR_SHOW_TYPE.WULI },
        { "fa_chuan", "法术穿透百分比", 0, "e", 2, 0, 100, CONST_ATTR_SHOW_TYPE.MOFA },
        { "wu_wushi", "物理无视护甲概率", 0, "f", 1, 0, 100, CONST_ATTR_SHOW_TYPE.NONE },
        { "fa_wushi", "法术无视护甲概率", 0, "g", 1, 0, 100, CONST_ATTR_SHOW_TYPE.NONE },
        { "wu_zengshang", "物理增伤", 0, "h", 0.8, 0, 200, CONST_ATTR_SHOW_TYPE.WULI },
        { "fa_zengshang", "法术增伤", 0, "i", 0.8, 0, 200, CONST_ATTR_SHOW_TYPE.MOFA },
        { "quanju_zengshang", "增伤", 0, "j", 0.5, 0, 200, CONST_ATTR_SHOW_TYPE.TONGYONG },
        { "str_baifenbi", "力量百分比", 0, "k", 1.0, 0, 200, CONST_ATTR_SHOW_TYPE.TONGYONG },
        { "agi_baifenbi", "敏捷百分比", 0, "l", 1.0, 0, 200, CONST_ATTR_SHOW_TYPE.TONGYONG },
        { "int_baifenbi", "智力百分比", 0, "m", 1.0, 0, 200, CONST_ATTR_SHOW_TYPE.TONGYONG },
        { "zhushuxing_baifenbi", "主属性百分比", 0, "z", 1.5, 0, 200, CONST_ATTR_SHOW_TYPE.TONGYONG },
        { "shengming_baifenbi", "生命百分比", 0, "n", 1.5, 0, 200, CONST_ATTR_SHOW_TYPE.FANGYU },
        { "gongji_baifenbi", "攻击力百分比", 0, "o", 1.5, -90, 200, CONST_ATTR_SHOW_TYPE.WULI },
        { "mojia_baifenbi", "魔甲百分比", 0, nil, 1.5, -90, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "defend_baifenbi", "护甲百分比", 0, nil, 1.5, -90, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "pojia", "物理破甲", 0, "p", 5, 0, nil, CONST_ATTR_SHOW_TYPE.WULI },
        { "pomo", "魔法破甲", 0, "", 5, 0, nil, CONST_ATTR_SHOW_TYPE.MOFA },
        { "master", "精通等级", 0, "q", 10, 0, 1000, CONST_ATTR_SHOW_TYPE.TONGYONG },
        { "energy_back", "能量获取", 0, "r", 5, 0, 1000, CONST_ATTR_SHOW_TYPE.TONGYONG },
        { "pugong_shanghai", "普攻伤害增强", 0, "", 5, -90, 100, CONST_ATTR_SHOW_TYPE.TONGYONG },
        { "attack_speed", "攻击加速", 0, "s", 2, 0, 200, CONST_ATTR_SHOW_TYPE.WULI },
        { "skill_speed", "技能加速", 0, "t", 1, 0, 100, CONST_ATTR_SHOW_TYPE.MOFA },
        { "cd_speed", "冷却加速", 0, "u", 1, 0, 40, CONST_ATTR_SHOW_TYPE.NONE },
        { "move", "移动速度", 0, "v", 20, 0, 522, CONST_ATTR_SHOW_TYPE.TONGYONG },
        { "healer_zengqiang", "治疗增强", 0, "w", 5, -100, 100, CONST_ATTR_SHOW_TYPE.FANGYU },
        { "healee_zengqiang", "被治疗增强", 0, "x", 5, -100, 100, CONST_ATTR_SHOW_TYPE.FANGYU },
        { "hit", "命中", 95, "y", 1, 0, 200, CONST_ATTR_SHOW_TYPE.TONGYONG },
        { "final_damage_reduction", "最终伤害降低", 0, "", 5, 0, 1000, CONST_ATTR_SHOW_TYPE.FANGYU },
        { "fire_enhance", "火元素增幅", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "water_enhance", "水元素增幅", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "light_enhance", "光元素增幅", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "dark_enhance", "暗影元素增幅", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "metal_enhance", "金元素增幅", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "wood_enhance", "自然元素增幅", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "earth_enhance", "大地元素增幅", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "hunluan_enhance", "混乱元素增幅", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "fire_yishang", "受到火元素伤害增加", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "water_yishang", "受到水元素伤害增加", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "light_yishang", "受到光元素伤害增加", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "dark_yishang", "受到暗元素伤害增加", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "metal_yishang", "受到金元素伤害增加", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "wood_yishang", "受到木元素伤害增加", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "earth_yishang", "受到土元素伤害增加", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "hunluan_yishang", "受到混乱元素伤害增加", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "jinu_zengshang", "激怒增伤", 0, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.NONE },
        { "yaoshui_shijian", "药水持续时间增加", nil, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.ZHUANYE },
        { "qianghua_rate", "强化成功率", nil, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.ZHUANYE },
        { "jinglian_rate", "精炼成功率", nil, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.ZHUANYE },
        { "diaoyu_rate", "钓鱼成功率", nil, "", -1, 0, 500, CONST_ATTR_SHOW_TYPE.ZHUANYE },
        { "zhibu_rate", "收集布料成功率", nil, "", -1, 0, 500, CONST_ATTR_SHOW_TYPE.ZHUANYE },
        { "baopi_rate", "剥皮成功率", nil, "", -1, 0, 500, CONST_ATTR_SHOW_TYPE.ZHUANYE },
        { "tujian_rate", "图鉴获得率", nil, "", -1, 0, 500, CONST_ATTR_SHOW_TYPE.QITA },
        { "ziyuan_max_count", "可采集资源最大值", nil, "", -1, 0, 10, CONST_ATTR_SHOW_TYPE.NONE },
        { "ziyuan_refresh_count", "资源刷新剩余时间", nil, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "caiyao_rate", "采药收获率", nil, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.ZHUANYE },
        { "fumo_rate", "附魔收获率", nil, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.ZHUANYE },
        { "caikuang_rate", "采矿收获率", nil, "", -1, 0, 200, CONST_ATTR_SHOW_TYPE.ZHUANYE },
        { "extra_dianfeng", "巅峰天赋点", 0, "", -1, 0, 10, CONST_ATTR_SHOW_TYPE.NONE },
        { "extra_ditudengji", "地图等级", 0, "", -1, 0, 20, CONST_ATTR_SHOW_TYPE.NONE },
        { "gold_ratio", "黄金获得率", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.QITA },
        { "exp_ratio", "经验获得率", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.QITA },
        { "shengwang_rate", "声望获得率", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.QITA },
        { "caiji_speed", "采集加速", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.ZHUANYE },
        { "zaisheng_speed", "资源再生加速", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.ZHUANYE },
        { "dianfeng_jingyan_ratio", "巅峰经验获取", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.QITA },
        { "fuwen_diaolv", "符文掉落概率", 0, "", -1, 0, 100, CONST_ATTR_SHOW_TYPE.QITA },
        { "lansecitiao_rate", "绿色词条升级基础概率", 0, "", -1, 0, 20, CONST_ATTR_SHOW_TYPE.QITA },
        { "zisecitiao_rate", "蓝色词条升级基础概率", 0, "", -1, 0, 20, CONST_ATTR_SHOW_TYPE.QITA },
        { "chengsecitiao_rate", "紫色词条升级基础概率（暂未开放）", 0, "", -1, 0, 20, CONST_ATTR_SHOW_TYPE.NONE },
        { "sqnl_huoqu", "神器能量获取率", 0, "", -1, 0, 100, CONST_ATTR_SHOW_TYPE.QITA },
        { "extra_drop_rate", "怪物额外掉落率", 0, "", -1, 0, 100, CONST_ATTR_SHOW_TYPE.QITA },
        { "fuben_refresh_reduction", "副本刷新间隔秒数降低", 0, "", -1, 0, 300, CONST_ATTR_SHOW_TYPE.QITA },
        -- 本身是在player实现
        { "player_gold_ratio", "旧的黄金获得率", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "lumber_ratio", "木头获得率", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "player_exp_ratio", "旧的经验获得率", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "sell_ratio", "售卖比率", 0, "", -1, nil, nil, CONST_ATTR_SHOW_TYPE.NONE },
        { "xuanyun_kangxing", "眩晕抗性", 0, "", nil, -100, 99, CONST_ATTR_SHOW_TYPE.NONE }
    }
)
