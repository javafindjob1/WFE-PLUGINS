-- 魔线 防具
-- 法系护甲

hcaifeng = {}

hcaifeng.init = function(config, cixiuConfig)
    hzhuanye.initSingleZhuanye(
        config,
        "制作",
        "裁缝",
        CONST_EVENT.caifeng,
        nil,
        nil,
        nil,
        ZHUANYE_ZHUANGBEI_QIANGHUA_WUPIN_SHIYONG.SHIYONGCIXIU,
        cixiuConfig
    )
end
