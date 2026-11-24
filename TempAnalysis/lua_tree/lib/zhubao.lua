-- 消耗矿石获得原石
-- 打磨原石获得可镶嵌宝石
-- 制作项链和戒指

hzhubao = {}

hzhubao.init = function(config, zhubaoConfig)
    hzhuanye.initSingleZhuanye(
        config,
        "制作",
        "珠宝",
        CONST_EVENT.zhubao,
        nil,
        nil,
        nil,
        ZHUANYE_ZHUANGBEI_QIANGHUA_WUPIN_SHIYONG.BAOSHIXIANGQIAN,
        zhubaoConfig
    )
end
