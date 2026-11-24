CONST_BASIC_DABEIBAO = 100
CONST_MAX_DABEIBAO_PER_PAGE = 50
CONST_BASIC_ZHUANGBEIDABEIBAO = 50
CONST_MAX_ZHUANGBEIDABEIBAO_PER_PAGE = 40
KEYS_LOADED_HERO = {}
KEYS_LOADED_ALL = {}
CUNDANG_JIAMI = true

CUNDANG_KEY_ALLOW_LIST = {}

local blackListItem = {}
blackListItem["影之哀伤"] = true
blackListItem["群星之怒"] = true

local cundangKeyAllowList = {
    "richangquest",
    "juese1zhuangbei2",
    "juese2zhuangbei2",
    "juese3zhuangbei2",
    "juese4zhuangbei2",
    "juese5zhuangbei2",
    "juese1zhuangbeidabeibao3",
    "juese2zhuangbeidabeibao3",
    "juese3zhuangbeidabeibao3",
    "juese4zhuangbeidabeibao3",
    "juese5zhuangbeidabeibao3",
    "juese1beibao3",
    "juese2beibao3",
    "juese3beibao3",
    "juese4beibao3",
    "juese5beibao3",
    "juese1zhuangbeidabeibao9",
    "juese2zhuangbeidabeibao9",
    "juese3zhuangbeidabeibao9",
    "juese4zhuangbeidabeibao9",
    "juese5zhuangbeidabeibao9",
    "juese1zhuangbeidabeibao10",
    "juese2zhuangbeidabeibao10",
    "juese3zhuangbeidabeibao10",
    "juese4zhuangbeidabeibao10",
    "juese5zhuangbeidabeibao10",
    "chuanqi-leitingzhinu",
    "dabeibao11",
    "chengjiu",
    "zuoqi",
    "dabeibao10",
    "chuanqi-aitiyeshi",
    "dabeibao7",
    "juese1zhuangbeidabeibao6",
    "juese2zhuangbeidabeibao6",
    "juese3zhuangbeidabeibao6",
    "juese4zhuangbeidabeibao6",
    "juese5zhuangbeidabeibao6",
    "dabeibao3",
    "juese1zhuangbeidabeibao8",
    "juese2zhuangbeidabeibao8",
    "juese3zhuangbeidabeibao8",
    "juese4zhuangbeidabeibao8",
    "juese5zhuangbeidabeibao8",
    "dianfengjingyan",
    "dabeibao8",
    "dabeibao6",
    "activatedZuoqi",
    "juese1beibao1",
    "juese2beibao1",
    "juese3beibao1",
    "juese4beibao1",
    "juese5beibao1",
    "juese1beibao2",
    "juese2beibao2",
    "juese3beibao2",
    "juese4beibao2",
    "juese5beibao2",
    "juese1zhuangbeidabeibao4",
    "juese2zhuangbeidabeibao4",
    "juese3zhuangbeidabeibao4",
    "juese4zhuangbeidabeibao4",
    "juese5zhuangbeidabeibao4",
    "lastgameyday",
    "juese1zhuangbeidabeibao5",
    "juese2zhuangbeidabeibao5",
    "juese3zhuangbeidabeibao5",
    "juese4zhuangbeidabeibao5",
    "juese5zhuangbeidabeibao5",
    "chuanji-zhenlinxiongjia",
    "dabeibao0",
    "richangquest-zhuorexiagu",
    "dabeibao5",
    "mingwen",
    "juese1gongzhenghuizhang",
    "juese2gongzhenghuizhang",
    "juese3gongzhenghuizhang",
    "juese4gongzhenghuizhang",
    "juese5gongzhenghuizhang",
    "tujian1",
    "juese1zhuangbei0",
    "juese2zhuangbei0",
    "juese3zhuangbei0",
    "juese4zhuangbei0",
    "juese5zhuangbei0",
    "juese1zhuangbeidabeibao0",
    "juese2zhuangbeidabeibao0",
    "juese3zhuangbeidabeibao0",
    "juese4zhuangbeidabeibao0",
    "juese5zhuangbeidabeibao0",
    "tujian2",
    "juese1zhuangbeidabeibao11",
    "juese2zhuangbeidabeibao11",
    "juese3zhuangbeidabeibao11",
    "juese4zhuangbeidabeibao11",
    "juese5zhuangbeidabeibao11",
    "juese1zhuxian",
    "juese2zhuxian",
    "juese3zhuxian",
    "juese4zhuxian",
    "juese5zhuxian",
    "juese1fuzhutianfu",
    "juese2fuzhutianfu",
    "juese3fuzhutianfu",
    "juese4fuzhutianfu",
    "juese5fuzhutianfu",
    "juese1zhuanjingtianfu",
    "juese2zhuanjingtianfu",
    "juese3zhuanjingtianfu",
    "juese4zhuanjingtianfu",
    "juese5zhuanjingtianfu",
    "juese1shuchutianfu",
    "juese2shuchutianfu",
    "juese3shuchutianfu",
    "juese4shuchutianfu",
    "juese5shuchutianfu",
    "juese1fangyutianfu",
    "juese2fangyutianfu",
    "juese3fangyutianfu",
    "juese4fangyutianfu",
    "juese5fangyutianfu",
    "juese1fuzhutianfu2",
    "juese2fuzhutianfu2",
    "juese3fuzhutianfu2",
    "juese4fuzhutianfu2",
    "juese5fuzhutianfu2",
    "juese1zhuanjingtianfu2",
    "juese2zhuanjingtianfu2",
    "juese3zhuanjingtianfu2",
    "juese4zhuanjingtianfu2",
    "juese5zhuanjingtianfu2",
    "juese1shuchutianfu2",
    "juese2shuchutianfu2",
    "juese3shuchutianfu2",
    "juese4shuchutianfu2",
    "juese5shuchutianfu2",
    "juese1fangyutianfu2",
    "juese2fangyutianfu2",
    "juese3fangyutianfu2",
    "juese4fangyutianfu2",
    "juese5fangyutianfu2",
    "zhuangbeishouji",
    "cundangherostr",
    "juese1zhuangbei1",
    "juese2zhuangbei1",
    "juese3zhuangbei1",
    "juese4zhuangbei1",
    "juese5zhuangbei1",
    "dabeibao9",
    "juese1shengwang",
    "juese2shengwang",
    "juese3shengwang",
    "juese4shengwang",
    "juese5shengwang",
    "juese1yongqihuizhang",
    "juese2yongqihuizhang",
    "juese3yongqihuizhang",
    "juese4yongqihuizhang",
    "juese5yongqihuizhang",
    "juese1zhuangbei3",
    "juese2zhuangbei3",
    "juese3zhuangbei3",
    "juese4zhuangbei3",
    "juese5zhuangbei3",
    "chujixilianshi",
    "diaoyuTujian0",
    "zhuanye",
    "juese1zhuangbeidabeibao2",
    "juese2zhuangbeidabeibao2",
    "juese3zhuangbeidabeibao2",
    "juese4zhuangbeidabeibao2",
    "juese5zhuangbeidabeibao2",
    "juese1xunlian",
    "juese2xunlian",
    "juese3xunlian",
    "juese4xunlian",
    "juese5xunlian",
    "juese1jingyan",
    "juese2jingyan",
    "juese3jingyan",
    "juese4jingyan",
    "juese5jingyan",
    "dabeibao4",
    "dabeibao1",
    "diaoyuTujian1",
    "diaoyuTujian2",
    "dabeibao2",
    "tujian",
    "chuanji-huijinzhili",
    "richangquest-tiaozhan",
    "juese1zhuangbeidabeibao1",
    "juese2zhuangbeidabeibao1",
    "juese3zhuangbeidabeibao1",
    "juese4zhuangbeidabeibao1",
    "juese5zhuangbeidabeibao1",
    "chuanqi-yanmozhishou",
    "juese1lilian",
    "juese2lilian",
    "juese3lilian",
    "juese4lilian",
    "juese5lilian",
    "juese1zhuangbei4",
    "juese2zhuangbei4",
    "juese3zhuangbei4",
    "juese4zhuangbei4",
    "juese5zhuangbei4",
    "jinbi",
    "juese1zhuangbeidabeibao7",
    "juese2zhuangbeidabeibao7",
    "juese3zhuangbeidabeibao7",
    "juese4zhuangbeidabeibao7",
    "juese5zhuangbeidabeibao7",
    "richang",
    "juese1zhuangbeidabeibao12",
    "juese2zhuangbeidabeibao12",
    "juese3zhuangbeidabeibao12",
    "juese4zhuangbeidabeibao12",
    "juese5zhuangbeidabeibao12",
    "juese1zhuangbeidabeibao13",
    "juese2zhuangbeidabeibao13",
    "juese3zhuangbeidabeibao13",
    "juese4zhuangbeidabeibao13",
    "juese5zhuangbeidabeibao13",
    "juese1zhuangbeidabeibao14",
    "juese2zhuangbeidabeibao14",
    "juese3zhuangbeidabeibao14",
    "juese4zhuangbeidabeibao14",
    "juese5zhuangbeidabeibao14",
    "juese1zhuangbeidabeibao15",
    "juese2zhuangbeidabeibao15",
    "juese3zhuangbeidabeibao15",
    "juese4zhuangbeidabeibao15",
    "juese5zhuangbeidabeibao15",
    "juese1zhuangbeidabeibao16",
    "juese2zhuangbeidabeibao16",
    "juese3zhuangbeidabeibao16",
    "juese4zhuangbeidabeibao16",
    "juese5zhuangbeidabeibao16",
    "juese1zhuangbeidabeibao17",
    "juese2zhuangbeidabeibao17",
    "juese3zhuangbeidabeibao17",
    "juese4zhuangbeidabeibao17",
    "juese5zhuangbeidabeibao17",
    "juese1zhuangbeidabeibao18",
    "juese2zhuangbeidabeibao18",
    "juese3zhuangbeidabeibao18",
    "juese4zhuangbeidabeibao18",
    "juese5zhuangbeidabeibao18",
    "juese1zhuangbeidabeibao19",
    "juese2zhuangbeidabeibao19",
    "juese3zhuangbeidabeibao19",
    "juese4zhuangbeidabeibao19",
    "juese5zhuangbeidabeibao19",
    "juese1zhuangbeidabeibao20",
    "juese2zhuangbeidabeibao20",
    "juese3zhuangbeidabeibao20",
    "juese4zhuangbeidabeibao20",
    "juese5zhuangbeidabeibao20",
    "juese1zhuangbeidabeibao21",
    "juese2zhuangbeidabeibao21",
    "juese3zhuangbeidabeibao21",
    "juese4zhuangbeidabeibao21",
    "juese5zhuangbeidabeibao21",
    "juese1zhuangbeidabeibao22",
    "juese2zhuangbeidabeibao22",
    "juese3zhuangbeidabeibao22",
    "juese4zhuangbeidabeibao22",
    "juese5zhuangbeidabeibao22",
    "juese1zhuangbeidabeibao23",
    "juese2zhuangbeidabeibao23",
    "juese3zhuangbeidabeibao23",
    "juese4zhuangbeidabeibao23",
    "juese5zhuangbeidabeibao23",
    "juese1zhuangbeidabeibao24",
    "juese2zhuangbeidabeibao24",
    "juese3zhuangbeidabeibao24",
    "juese4zhuangbeidabeibao24",
    "juese5zhuangbeidabeibao24",
    "juese1zhuangbeidabeibao25",
    "juese2zhuangbeidabeibao25",
    "juese3zhuangbeidabeibao25",
    "juese4zhuangbeidabeibao25",
    "juese5zhuangbeidabeibao25",
    "juese1zhuangbeidabeibao26",
    "juese2zhuangbeidabeibao26",
    "juese3zhuangbeidabeibao26",
    "juese4zhuangbeidabeibao26",
    "juese5zhuangbeidabeibao26",
    "juese1zhuangbeidabeibao27",
    "juese2zhuangbeidabeibao27",
    "juese3zhuangbeidabeibao27",
    "juese4zhuangbeidabeibao27",
    "juese5zhuangbeidabeibao27",
    "juese1zhuangbeidabeibao28",
    "juese2zhuangbeidabeibao28",
    "juese3zhuangbeidabeibao28",
    "juese4zhuangbeidabeibao28",
    "juese5zhuangbeidabeibao28",
    "juese1zhuangbeidabeibao29",
    "juese2zhuangbeidabeibao29",
    "juese3zhuangbeidabeibao29",
    "juese4zhuangbeidabeibao29",
    "juese5zhuangbeidabeibao29",
    "juese1zhuangbeidabeibao30",
    "juese2zhuangbeidabeibao30",
    "juese3zhuangbeidabeibao30",
    "juese4zhuangbeidabeibao30",
    "juese5zhuangbeidabeibao30",
    "juese1zhuangbeidabeibao31",
    "juese2zhuangbeidabeibao31",
    "juese3zhuangbeidabeibao31",
    "juese4zhuangbeidabeibao31",
    "juese5zhuangbeidabeibao31",
    "juese1zhuangbeidabeibao32",
    "juese2zhuangbeidabeibao32",
    "juese3zhuangbeidabeibao32",
    "juese4zhuangbeidabeibao32",
    "juese5zhuangbeidabeibao32",
    "juese1zhuangbeidabeibao33",
    "juese2zhuangbeidabeibao33",
    "juese3zhuangbeidabeibao33",
    "juese4zhuangbeidabeibao33",
    "juese5zhuangbeidabeibao33",
    "juese1zhuangbeidabeibao34",
    "juese2zhuangbeidabeibao34",
    "juese3zhuangbeidabeibao34",
    "juese4zhuangbeidabeibao34",
    "juese5zhuangbeidabeibao34",
    "juese1zhuangbeidabeibao35",
    "juese2zhuangbeidabeibao35",
    "juese3zhuangbeidabeibao35",
    "juese4zhuangbeidabeibao35",
    "juese5zhuangbeidabeibao35",
    "juese1zhuangbeidabeibao36",
    "juese2zhuangbeidabeibao36",
    "juese3zhuangbeidabeibao36",
    "juese4zhuangbeidabeibao36",
    "juese5zhuangbeidabeibao36",
    "juese1zhuangbeidabeibao37",
    "juese2zhuangbeidabeibao37",
    "juese3zhuangbeidabeibao37",
    "juese4zhuangbeidabeibao37",
    "juese5zhuangbeidabeibao37",
    "juese1zhuangbeidabeibao38",
    "juese2zhuangbeidabeibao38",
    "juese3zhuangbeidabeibao38",
    "juese4zhuangbeidabeibao38",
    "juese5zhuangbeidabeibao38",
    "juese1zhuangbeidabeibao39",
    "juese2zhuangbeidabeibao39",
    "juese3zhuangbeidabeibao39",
    "juese4zhuangbeidabeibao39",
    "juese5zhuangbeidabeibao39",
    "huanhua",
    "juese1currenthuanhua",
    "juese2currenthuanhua",
    "juese3currenthuanhua",
    "juese4currenthuanhua",
    "juese5currenthuanhua",
    "buchangma",
    "lastjuese",
    "dfdengji",
    "gearscore",
    "zuobicount",
    "gslevelone",
    "gsleveltwo",
    "zuobicountkeshanchu",
    "juese1heji",
    "juese2heji",
    "juese3heji",
    "juese4heji",
    "juese5heji",
    "mingwen1",
    "huoyanhuizhang",
    "damijingcur",
    "damijingmax",
    "richangquest-mijing",
    "dabeibao12",
    "dabeibao13",
    "dabeibao14",
    "dabeibao15",
    "chuanqi-xuehou",
    "zhengyihuizhang",
    "zhixuhuizhang",
    "tujian3",
    "dabeibao16",
    "dabeibao17",
    "dabeibao18",
    "dabeibao19",
    "dabeibao20",
    "dabeibao21",
    "dabeibao22",
    "dabeibao23",
    "richangquest-fenzhengzhidi",
    "daixinjifensum",
    "daixinjifenused",
    "richangquest-fzzdtuandui",
    "mjexphyxf",
    "mjfwhyxf",
    "mjexpsszd",
    "mjfwsszd",
    "mjexpwszj",
    "mjfwwszj",
    "mjexpxczd",
    "mjfwxczd",
    "mjexpsdmj",
    "mjfwsdmj",
    "mjexpcgjq",
    "mjfwcgjq",
    "chuanqi-lieyanjiji",
    "chuanqi-diaoyu",
    "mifahuizhang",
    "monenghuizhang",
    "artifacthjzl",
    "arthjzlexp",
    "zhuangbeishouji0",
    "zhuangbeishouji1",
    "zhuangbeishouji2",
    "zhuangbeishouji3",
    "zhuangbeishouji4",
    "zhuangbeishouji5",
    "zhuangbeishouji6",
    "zhuangbeishouji7",
    "artifactatys",
    "artatysexp",
    "artifactltzn",
    "artltznexp",
    "chuanqi-emzr",
    "artifactemzr",
    "artemzrexp",
    "tujian4",
    "xieehuizhang",
    "emohuizhang",
    "artifactymzs",
    "artymzsexp",
    "huihuanghuizhang",
    "kaixuanhuizhang",
    "chuanqi-qunxingzhinu",
    "artifactqxzn",
    "artqxzaexp",
    "zhuangbeishouji8",
    "zhuangbeishouji9",
    "zhuangbeishouji10",
    "zhuangbeishouji11",
}

for _, v in ipairs(cundangKeyAllowList) do
    CUNDANG_KEY_ALLOW_LIST[v] = true
end

hdzcundang = {}
hdzcundang.cache = {}
hdzcundang.cacheAll = {}

hdzcundang.getMaxCailiaoBeibaoCount = function(whichPlayer)
    local extraCountPerPlayer = 0
    if hshangcheng.hasItem(whichPlayer, "巅峰VIP") then
        extraCountPerPlayer = extraCountPerPlayer + 40
    end
    if hshangcheng.hasItem(whichPlayer, "小材料包") then
        extraCountPerPlayer = extraCountPerPlayer + 8
    end
    if hshangcheng.hasItem(whichPlayer, "中材料包") then
        extraCountPerPlayer = extraCountPerPlayer + 16
    end
    if hshangcheng.hasItem(whichPlayer, "大材料包") then
        extraCountPerPlayer = extraCountPerPlayer + 24
    end
    if hshangcheng.hasItem(whichPlayer, "巨无霸材料包") then
        extraCountPerPlayer = extraCountPerPlayer + 32
    end
    if hshangcheng.hasItem(whichPlayer, "我超能装") then
        extraCountPerPlayer = extraCountPerPlayer + 20
    end

    return CONST_BASIC_DABEIBAO + extraCountPerPlayer
end

hdzcundang.getMaxZhuangbeiBeibaoCount = function(whichPlayer)
    local extraCountPerPlayer = 0

    if hshangcheng.hasItem(whichPlayer, "我超能装") then
        extraCountPerPlayer = extraCountPerPlayer + 15
    end
    if hshangcheng.hasItem(whichPlayer, "巅峰VIP") then
        extraCountPerPlayer = extraCountPerPlayer + 15
    end
    return CONST_BASIC_ZHUANGBEIDABEIBAO + extraCountPerPlayer
end

hdzcundang.setup_cundang_validator = function(whichPlayer)
    htime.setInterval(
        1,
        function(t)
            hdzcundang.validateCundang(whichPlayer)
        end
    )
end

hdzcundang.validateCundang = function(whichPlayer)
    for _, key in ipairs(cundangKeyAllowList) do
        local loadedValue = hjapi.DzAPI_Map_GetServerValue(whichPlayer, key)
        if
            loadedValue ~= nil and loadedValue ~= "" and hdzcundang.cache[whichPlayer] ~= nil and
            hdzcundang.cacheAll[whichPlayer][key] ~= nil
        then
            if hdzcundang.cacheAll[whichPlayer][key][loadedValue] == nil then
                --hdzcundang.addZuobiCount(whichPlayer)
                --hplayer.defeat(whichPlayer, "存档验证失败，可能存在作弊行为。")
                echo(hcolor.red("如果你没有作弊但是看到这个信息，请联系管理"), whichPlayer)
            end
        end
    end
end

hdzcundang.clear_all_cundang_and_defeat = function(whichPlayer)
    for k, v in pairs(CUNDANG_KEY_ALLOW_LIST) do
        htime.setTimeout(
            0.01 * math.random(1, 300),
            function(t)
                if string.find(k, "mjexp") or k == "arthjzlexp" or k == "artatysexp" then
                    hdzcundang.save_to_server_direct(whichPlayer, k, "0")
                else
                    hdzcundang.save_to_server(
                        whichPlayer,
                        k,
                        "000000000000000000000000000000000000000000000000000000000000000"
                    )
                end
            end
        )
    end
    htime.setTimeout(
        4,
        function(t)
            hplayer.defeat(whichPlayer, "该账号已被封禁，所有存档已经清除。有问题请加群找管理（仅限申诉和疑问）。")
        end
    )
end

hdzcundang.save_to_server = function(whichPlayer, key, value, skipWriteToCache, skipEncryption)
    if CUNDANG_KEY_ALLOW_LIST[key] == nil then
        echo("存档key不在允许列表中: " .. key, whichPlayer)
        return
    end
    if whichPlayer == nil or key == nil then
        error("bad user or key when save")
    end
    local finalvalue = value
    if CUNDANG_JIAMI and skipEncryption ~= true then
        finalvalue = bit32.encrypt(hjapi.KKApiPlayerGUID(whichPlayer), value)
    end
    if skipWriteToCache ~= true then
        if hdzcundang.cache[whichPlayer] == nil then
            hdzcundang.cache[whichPlayer] = {}
        end
        --if hdzcundang.cacheAll[whichPlayer] == nil then
        --hdzcundang.cacheAll[whichPlayer] = {}
        --end
        if finalvalue ~= hdzcundang.cache[whichPlayer][key] then
            hdzcundang.cache[whichPlayer][key] = finalvalue
            --if hdzcundang.cacheAll[whichPlayer][key] == nil then
            --    hdzcundang.cacheAll[whichPlayer][key] = {}
            --end
            --hdzcundang.cacheAll[whichPlayer][key][finalvalue] = true
            return hjapi.DzAPI_Map_SaveServerValue(whichPlayer, key, finalvalue)
        end
    else
        return hjapi.DzAPI_Map_SaveServerValue(whichPlayer, key, finalvalue)
    end
end

hdzcundang.save_to_server_direct = function(whichPlayer, key, value)
    if CUNDANG_KEY_ALLOW_LIST[key] == nil then
        echo("存档key不在允许列表中: " .. key, whichPlayer)
        return
    end
    if whichPlayer == nil or key == nil then
        error("bad user or key when save")
    end
    hjapi.DzAPI_Map_SaveServerValue(whichPlayer, key, value)
end

hdzcundang.load_from_server = function(whichPlayer, key, alwaysReadFromServer, skipEncryption)
    if CUNDANG_KEY_ALLOW_LIST[key] == nil then
        echo("存档key不在允许列表中: " .. key, whichPlayer)
        return
    end
    if whichPlayer == nil or key == nil then
        error("bad user or key when load")
    end
    if hdzcundang.cache[whichPlayer] == nil then
        hdzcundang.cache[whichPlayer] = {}
    end
    --if hdzcundang.cacheAll[whichPlayer] == nil then
    --hdzcundang.cacheAll[whichPlayer] = {}
    --end
    local data
    if alwaysReadFromServer == true or hdzcundang.cache[whichPlayer][key] == nil then
        data = hjapi.DzAPI_Map_GetServerValue(whichPlayer, key)
        if data == nil or data == "" then
            data = "000000000000000000000000000000000000000000000000000000000000000"
            if CUNDANG_JIAMI then
                data = bit32.encrypt(hjapi.KKApiPlayerGUID(whichPlayer), data)
            end
        end
        --if hdzcundang.cacheAll[whichPlayer][key] == nil then
        --hdzcundang.cacheAll[whichPlayer][key] = {}
        --end
        --hdzcundang.cacheAll[whichPlayer][key][data] = true
        hdzcundang.cache[whichPlayer][key] = data
    else
        data = hdzcundang.cache[whichPlayer][key]
    end
    if CUNDANG_JIAMI and skipEncryption ~= true then
        local data = bit32.decrypt(hjapi.KKApiPlayerGUID(whichPlayer), data)
        if string.is_valid_string(data) then
            return data
        else
            data = "000000000000000000000000000000000000000000000000000000000000000"
            hdzcundang.save_to_server(whichPlayer, key, data)
            return data
        end
    else
        return data
    end
end

hdzcundang.addZuobiCount = function(whichPlayer)
    local count = hdzcundang.getZuobiCount(whichPlayer)
    count = count + 1
    hdzcundang.save_to_server_direct(whichPlayer, "zuobicount", count)

    local count = hdzcundang.getZuobiCountKeshanchu(whichPlayer)
    count = count + 1
    hdzcundang.save_to_server_direct(whichPlayer, "zuobicountkeshanchu", count)
end

hdzcundang.clearZuobiCountKeshanchu = function(whichPlayer)
    hdzcundang.save_to_server_direct(whichPlayer, "zuobicountkeshanchu", 0)
end

hdzcundang.save_gear_score_level = function(whichPlayer, gearScore)
    if gearScore >= 800 then
        hjapi.DzAPI_Map_Statistics(whichPlayer, "gslevelone", nil, 1)
    end
    if gearScore >= 1000 then
        hjapi.DzAPI_Map_Statistics(whichPlayer, "gsleveltwo", nil, 1)
    end
end

hdzcundang.getZuobiCount = function(whichPlayer)
    return math.ceil(tonumber(hdzcundang.load_from_server_direct(whichPlayer, "zuobicount")) or 0)
end

hdzcundang.getZuobiCountKeshanchu = function(whichPlayer)
    return math.ceil(tonumber(hdzcundang.load_from_server_direct(whichPlayer, "zuobicountkeshanchu")) or 0)
end

hdzcundang.load_from_server_direct = function(whichPlayer, key)
    if CUNDANG_KEY_ALLOW_LIST[key] == nil then
        echo("存档key不在允许列表中: " .. key, whichPlayer)
        return
    end
    if whichPlayer == nil or key == nil then
        error("bad user or key when load")
    end
    local data = hjapi.DzAPI_Map_GetServerValue(whichPlayer, key)
    if hdzcundang.cacheAll[whichPlayer] == nil then
        hdzcundang.cacheAll[whichPlayer] = {}
    end
    if hdzcundang.cacheAll[whichPlayer][key] == nil then
        hdzcundang.cacheAll[whichPlayer][key] = {}
    end
    hdzcundang.cacheAll[whichPlayer][key][data] = true
    return data
end

--- 清空角色存档
hdzcundang.clearJueseCunDang = function(whichPlayer)
    local cundangwei = hplayer.dzCunDang[whichPlayer]._cundangwei
    if cundangwei == nil then
        return
    end
    for k, v in pairs(CUNDANG_KEY_ALLOW_LIST) do
        if string.sub(k, 1, 6) == "juese" .. cundangwei then
            htime.setTimeout(
                0.01 * math.random(1, 100),
                function(t)
                    hdzcundang.save_to_server(
                        whichPlayer,
                        k,
                        "000000000000000000000000000000000000000000000000000000000000000"
                    )
                end
            )
        end
    end
    htime.setTimeout(
        1,
        function(t)
            hplayer.dzCunDang[whichPlayer].saveCundang("cundangherostr", false, cundangwei, cundangwei, "0")
        end
    )
    htime.setTimeout(
        2,
        function()
            hplayer.defeat(whichPlayer, "存档已经清除，请重新开始游戏。")
        end
    )
end
--- 清空所有存档
hdzcundang.clearNonJueseCunDang = function(whichPlayer)
    for k, v in pairs(CUNDANG_KEY_ALLOW_LIST) do
        htime.setTimeout(
            0.01 * math.random(1, 300),
            function(t)
                hdzcundang.save_to_server(
                    whichPlayer,
                    k,
                    "000000000000000000000000000000000000000000000000000000000000000"
                )
            end
        )
    end
    htime.setTimeout(
        4,
        function(t)
            hplayer.defeat(whichPlayer, "所有存档已经清除。请重新开始游戏。")
        end
    )
end

---@return DZCunDang
DZCunDang = function(player)
    ---@class DZCunDang
    local this = {
        player = nil,
        gold = nil,
        lumbor = nil,
        experience = nil,
        equipments = {},        -- 装备
        inventory = {},         -- 大背包
        zhuangbeiIventory = {}, -- 装备大背包
        bag = {},               --背包
        pet_bag = {},           --- 宠物背包
        achievements = {},      -- 成就
        dabaobeiIndexToUIIndex = {},
        UiIndexToDabeibaoIndex = {},
        zhuangbeiDabaobeiIndexToUIIndex = {},
        UiIndexToZhuangbeiDabeibaoIndex = {},
        ---@private
        _cundang = {
            juese = {
                huofa = {
                    jinbi = "",
                    jingyan = "",
                    zhuangbei1 = "",
                    zhuangbei2 = "",
                    zhuangbei3 = "",
                    zhuangbei4 = "",
                    zhuangbei0 = "",
                    zhuxian = "",
                    lilian = "",
                    beibao1 = "",
                    beibao2 = "",
                    beibao3 = "",
                    tujian = "",
                    zhuanye = "",
                    xunlian = ""
                },
                kuangbaozhan = {
                    jinbi = "",
                    jingyan = "",
                    zhuangbei1 = "",
                    zhuangbei2 = "",
                    zhuangbei3 = "",
                    zhuangbei4 = "",
                    zhuangbei0 = "",
                    zhuxian = "",
                    lilian = "",
                    beibao1 = "",
                    beibao2 = "",
                    beibao3 = "",
                    tujian = "",
                    zhuanye = "",
                    xunlian = ""
                },
                huimieshu = {
                    jinbi = "",
                    jingyan = "",
                    zhuangbei1 = "",
                    zhuangbei2 = "",
                    zhuangbei3 = "",
                    zhuangbei4 = "",
                    zhuangbei0 = "",
                    zhuxian = "",
                    lilian = "",
                    beibao1 = "",
                    beibao2 = "",
                    beibao3 = "",
                    tujian = "",
                    zhuanye = "",
                    xunlian = ""
                },
                tongkushu = {
                    jinbi = "",
                    jingyan = "",
                    zhuangbei1 = "",
                    zhuangbei2 = "",
                    zhuangbei3 = "",
                    zhuangbei4 = "",
                    zhuangbei0 = "",
                    zhuxian = "",
                    lilian = "",
                    beibao1 = "",
                    beibao2 = "",
                    beibao3 = "",
                    tujian = "",
                    zhuanye = "",
                    xunlian = ""
                },
                emolieshou = {
                    jinbi = "",
                    jingyan = "",
                    zhuangbei1 = "",
                    zhuangbei2 = "",
                    zhuangbei3 = "",
                    zhuangbei4 = "",
                    zhuangbei0 = "",
                    zhuxian = "",
                    lilian = "",
                    beibao1 = "",
                    beibao2 = "",
                    beibao3 = "",
                    tujian = "",
                    zhuanye = "",
                    xunlian = ""
                },
                chengjieqi = {
                    jinbi = "",
                    jingyan = "",
                    zhuangbei1 = "",
                    zhuangbei2 = "",
                    zhuangbei3 = "",
                    zhuangbei4 = "",
                    zhuangbei0 = "",
                    zhuxian = "",
                    lilian = "",
                    beibao1 = "",
                    beibao2 = "",
                    beibao3 = "",
                    tujian = "",
                    zhuanye = "",
                    xunlian = ""
                },
                wuqizhan = {
                    jinbi = "",
                    jingyan = "",
                    zhuangbei1 = "",
                    zhuangbei2 = "",
                    zhuangbei3 = "",
                    zhuangbei4 = "",
                    zhuangbei0 = "",
                    zhuxian = "",
                    lilian = "",
                    beibao1 = "",
                    beibao2 = "",
                    beibao3 = "",
                    tujian = "",
                    zhuanye = "",
                    xunlian = ""
                },
                zhandouzei = {
                    jinbi = "",
                    jingyan = "",
                    zhuangbei1 = "",
                    zhuangbei2 = "",
                    zhuangbei3 = "",
                    zhuangbei4 = "",
                    zhuangbei0 = "",
                    zhuxian = "",
                    lilian = "",
                    beibao1 = "",
                    beibao2 = "",
                    beibao3 = "",
                    tujian = "",
                    zhuanye = "",
                    xunlian = ""
                },
                shejilieren = {
                    jinbi = "",
                    jingyan = "",
                    zhuangbei1 = "",
                    zhuangbei2 = "",
                    zhuangbei3 = "",
                    zhuangbei4 = "",
                    zhuangbei0 = "",
                    zhuxian = "",
                    lilian = "",
                    beibao1 = "",
                    beibao2 = "",
                    beibao3 = "",
                    tujian = "",
                    zhuanye = "",
                    xunlian = ""
                },
                xingchenfashi = {
                    jinbi = "",
                    jingyan = "",
                    zhuangbei1 = "",
                    zhuangbei2 = "",
                    zhuangbei3 = "",
                    zhuangbei4 = "",
                    zhuangbei0 = "",
                    zhuxian = "",
                    lilian = "",
                    beibao1 = "",
                    beibao2 = "",
                    beibao3 = "",
                    tujian = "",
                    zhuanye = "",
                    xunlian = ""
                }
            },
            dabeibao0 = "",
            dabeibao1 = "",
            dabeibao2 = "",
            dabeibao3 = "",
            dabeibao4 = "",
            dabeibao5 = "",
            dabeibao6 = "",
            dabeibao7 = "",
            dabeibao8 = "",
            dabeibao9 = "",
            dabeibao10 = "",
            dabeibao11 = "",
            dabeibao12 = "",
            dabeibao13 = "",
            dabeibao14 = "",
            dabeibao15 = "",
            dabeibao16 = "",
            dabeibao17 = "",
            dabeibao18 = "",
            dabeibao19 = "",
            dabeibao20 = "",
            dabeibao21 = "",
            dabeibao22 = "",
            dabeibao23 = "",
            dabeibao24 = "",
            dabeibao25 = "",
            dabeibao26 = "",
            dabeibao27 = "",
            dabeibao28 = "",
            dabeibao29 = "",
            dabeibao30 = "",
            dabeibao31 = "",
            dabeibao32 = "",
            dabeibao33 = "",
            dabeibao34 = "",
            dabeibao35 = "",
            dabeibao36 = "",
            dabeibao37 = "",
            dabeibao38 = "",
            dabeibao39 = "",
            dabeibao40 = "",
            dabeibao41 = "",
            dabeibao42 = "",
            dabeibao43 = "",
            dabeibao44 = "",
            dabeibao45 = "",
            dabeibao46 = "",
            dabeibao47 = "",
            chengjiu = "",
            diaoyuTujian = ""
        }
    }
    this._cundang["chuanji-zhenlinxiongjia"] = ""
    this._cundang["chuanji-huijinzhili"] = ""
    this._cundangCache = {}
    this.setcundangwei = function(cundangwei)
        this._cundangwei = cundangwei
    end
    this.loadKeyFromCunDang = function(key, isHeroLevel, isNumber, skipEncryption)
        local cundangkey = key
        if isHeroLevel == true then
            if this._cundangwei == nil then
                err("存档错误: _cundangwei is nil")
                return
            end
            cundangkey = "juese" .. this._cundangwei .. cundangkey
        end
        local loadedValue = hdzcundang.load_from_server(this.player, cundangkey, false, skipEncryption)
        -- 金币和经验初始化为0
        if isNumber == true then
            if loadedValue == nil or loadedValue == "" then
                loadedValue = 0
            end
        elseif loadedValue == nil or loadedValue == "" or string.len(loadedValue) ~= 63 then
            -- 其它存档初始化为63个0
            loadedValue = "000000000000000000000000000000000000000000000000000000000000000"
        end
        return loadedValue
    end
    this.loadDailyLimitKey = function(key, isHeroLevel)
        local cundangkey = key
        if isHeroLevel == true then
            if this._cundangwei == nil then
                err("存档错误: _cundangwei is nil")
                return 0
            end
            cundangkey = "juese" .. this._cundangwei .. cundangkey
        end
        return hjapi.KKApiGetServerValueLimitLeft(this.player, cundangkey)
    end
    --- 从平台读取数据
    this.loadCunDang = function()
        if hjapi.GetPlayerServerValueSuccess(this.player) == false then
            hplayer.defeat(this.player, "存档读取失败,大侠请重新来过")
            return
        end
    end

    this.initEquipmentAttrTrigger = function()
        local hero = hplayer.getMainHero(this.player)
        hevent.register(
            hero,
            CONST_EVENT.equipmentChange,
            "attr_change",
            function(evtData)
                local dynamicItem = evtData.dynamicItem
                local equipmentSlot = evtData.equipmentSlot
                local player = evtData.whichPlayer
                if dynamicItem == nil then
                    return
                end
                if evtData.isAdd then
                    this.equipments[equipmentSlot] = dynamicItem
                    dynamicItem.setEquipped(true)
                    hitem.changeAttributeToHero(dynamicItem, hplayer.getMainHero(player), true)
                    hitem.refreshZhuangbeiJineng(player, dynamicItem, true, equipmentSlot)
                    local art = nil
                    if EQUIPMENT_SLOT_TO_HUANHUA_POSITION[equipmentSlot] ~= nil then
                        if hslk.i2v(dynamicItem.basic_item_id, "TargetArt") ~= nil then
                            art = hslk.i2v(dynamicItem.basic_item_id, "TargetArt")
                        elseif
                            EQUIPMENT_TYPE_DEFAULT_EFFECT[hslk.i2v(dynamicItem.basic_item_id, "equipment_type")] ~= nil
                        then
                            art = EQUIPMENT_TYPE_DEFAULT_EFFECT[hslk.i2v(dynamicItem.basic_item_id, "equipment_type")]
                        end
                    end
                    if art ~= nil and EQUIPMENT_SLOT_TO_HUANHUA_POSITION[equipmentSlot] ~= nil then
                        hhuanhua.setUnitHuanhuaStatus(hero, EQUIPMENT_SLOT_TO_HUANHUA_POSITION[equipmentSlot], art)
                    end
                else
                    this.equipments[equipmentSlot] = nil
                    if EQUIPMENT_SLOT_TO_HUANHUA_POSITION[equipmentSlot] ~= nil then
                        hhuanhua.setUnitHuanhuaStatus(hero, EQUIPMENT_SLOT_TO_HUANHUA_POSITION[equipmentSlot], nil)
                    end
                    dynamicItem.setEquipped(false)
                    hitem.changeAttributeToHero(dynamicItem, hero, false)
                    hitem.refreshZhuangbeiJineng(player, dynamicItem, false, equipmentSlot)
                    dynamicItem.updateDescription()
                end
                hitem.refreshTaozhuang(player)
                hitem.updateGearScore(player)
            end
        )
    end
    ---@param equipmentSlot number
    ---@return DynamicItem
    this.initAndGetEquipmentForSlot = function(equipmentSlot)
        if this._cundangwei == nil then
            err("存档错误: _cundangwei is nil")
            return
        end
        local hero = hplayer.getMainHero(this.player)
        local cundangstartidx = (equipmentSlot - 1) % 2 * 31
        local cundangendidx = cundangstartidx + 31
        local cundangkey = "zhuangbei" .. tostring(math.floor((equipmentSlot - 1) / 2))
        local fullKey = "juese" .. this._cundangwei .. cundangkey
        local cdstr = string.sub(hdzcundang.load_from_server(this.player, fullKey), cundangstartidx + 1, cundangendidx)
        local dynamicItem = this.createDynamicItemFromCundangStr(cdstr)
        if dynamicItem == nil then
            return nil
        end
        if hhero.checkEquipmentableToSlot(hero, dynamicItem, equipmentSlot) == false then
            echo("装备物品失败", this.player)
            return nil
        end
        hevent.trigger(
            hero,
            CONST_EVENT.equipmentChange,
            { equipmentSlot = equipmentSlot, dynamicItem = dynamicItem, isAdd = true, whichPlayer = this.player }
        )
        return dynamicItem
    end

    this.hasEnoughItemInBag = function(singleReq, printInfo)
        local itemNumber = singleReq.count or singleReq.number or 999
        local currentCount = singleReq.currentCount or 0
        itemNumber = itemNumber - currentCount
        local name = singleReq.name
        local requiredPinzhi = singleReq.pinzhi
        local requiredNandu = singleReq.nandu
        local requiredQianghua = singleReq.qianghua
        local requiredJinglian = singleReq.jinglian
        local remainingCount = itemNumber
        local coloredName = hitem.getColoredNameBasedOnPinzhi(name)
        if requiredPinzhi ~= nil then
            coloredName = ZHUANGBEI_PINZHI_DATA[requiredPinzhi].color(name)
        end
        if requiredNandu ~= nil then
            coloredName = coloredName .. hcolor.green("（" .. FUBEN_NANDU_LABEL_WO_COLOR[requiredNandu] .. "难度）")
        end
        if requiredQianghua ~= nil then
            coloredName = coloredName .. " " .. hcolor.green("强化+" .. requiredQianghua)
        end
        if requiredJinglian ~= nil then
            coloredName = coloredName .. " " .. hcolor.green("精炼+" .. requiredJinglian)
        end

        for i = 1, hdzcundang.getMaxZhuangbeiBeibaoCount(this.player) do
            local dynamicItem = this.zhuangbeiIventory[i]
            if
                dynamicItem ~= nil and hitem.getName(dynamicItem.basic_item_id) == name and
                (requiredJinglian == nil or
                    (dynamicItem.jinglian ~= nil and dynamicItem.jinglian >= requiredJinglian)) and
                (requiredPinzhi == nil or (dynamicItem.pinzhi ~= nil and dynamicItem.pinzhi >= requiredPinzhi)) and
                (requiredNandu == nil or (dynamicItem.nandu ~= nil and dynamicItem.nandu >= requiredNandu)) and
                (requiredQianghua == nil or
                    (dynamicItem.qianghua ~= nil and dynamicItem.qianghua >= requiredQianghua))
            then
                remainingCount = remainingCount - dynamicItem.stack
            end
        end
        for i = 1, hdzcundang.getMaxCailiaoBeibaoCount(this.player) do
            local dynamicItem = this.inventory[i]
            if
                dynamicItem ~= nil and hitem.getName(dynamicItem.basic_item_id) == name and
                (requiredJinglian == nil or
                    (dynamicItem.jinglian ~= nil and dynamicItem.jinglian >= requiredJinglian)) and
                (requiredPinzhi == nil or (dynamicItem.pinzhi ~= nil and dynamicItem.pinzh >= requiredPinzhi)) and
                (requiredNandu == nil or (dynamicItem.nandu ~= nil and dynamicItem.nandu >= requiredNandu)) and
                (requiredQianghua == nil or
                    (dynamicItem.qianghua ~= nil and dynamicItem.qianghua >= requiredQianghua))
            then
                remainingCount = remainingCount - dynamicItem.stack
            end
        end
        if printInfo and remainingCount > 0 then
            echo(
                hcolor.yellow("大背包缺少：") ..
                hitem.getDescriptionForSingleRequiredItem(singleReq) .. " X " .. remainingCount,
                this.player
            )
        end
        return remainingCount <= 0
    end

    this.createItemFromSingleItemReq = function(singleReq)
        local itemNumber = singleReq.count or singleReq.number or 1
        local name = singleReq.name
        local itemId = hslk.n2i(name)
        local requiredPinzhi = singleReq.pinzhi or hitem.getItemMinPinzhi(itemId)
        local requiredNandu = singleReq.nandu or FUBEN_NANDU.PUTONG
        local requiredQianghua = singleReq.qianghua
        local requiredJinglian = singleReq.jinglian
        local itemLevel = singleReq.itemLevel or 1
        local hero = hplayer.getMainHero(this.player)

        for i = 1, itemNumber do
            local dynamicItem = DynamicItem(hslk.n2i(name))
            dynamicItem.setOwner(this.player)
            dynamicItem.qianghua = requiredQianghua
            dynamicItem.jinglian = requiredJinglian
            dynamicItem.initBasedOnPinzhi(requiredPinzhi, itemLevel, nil, requiredNandu,
                { hplayer.getMainHero(this.player) })
            hitem.create({ id = itemId, whichUnit = hero, dynamicItem = dynamicItem })
        end
    end

    this.removeItemFromBag = function(singleReq)
        local itemNumber = singleReq.count or singleReq.number or 999
        local name = singleReq.name
        local requiredPinzhi = singleReq.pinzhi
        local requiredNandu = singleReq.nandu
        local requiredQianghua = singleReq.qianghua
        local requiredJinglian = singleReq.jinglian
        local remainingCount = itemNumber

        for i = 1, hdzcundang.getMaxZhuangbeiBeibaoCount(this.player) do
            if remainingCount <= 0 then
                return
            end
            local dynamicItem = this.zhuangbeiIventory[i]
            if
                dynamicItem ~= nil and hitem.getName(dynamicItem.basic_item_id) == name and
                (requiredJinglian == nil or
                    (dynamicItem.jinglian ~= nil and dynamicItem.jinglian >= requiredJinglian)) and
                (requiredPinzhi == nil or (dynamicItem.pinzhi ~= nil and dynamicItem.pinzhi >= requiredPinzhi)) and
                (requiredNandu == nil or (dynamicItem.nandu ~= nil and dynamicItem.nandu >= requiredNandu)) and
                (requiredQianghua == nil or
                    (dynamicItem.qianghua ~= nil and dynamicItem.qianghua >= requiredQianghua))
            then
                if dynamicItem.stack > remainingCount then
                    local consumedCount = remainingCount
                    dynamicItem.setStack(dynamicItem.stack - remainingCount)
                    remainingCount = 0
                    this.saveZhuangbeiInCundangServer(i)
                    local coloredName = ZHUANGBEI_PINZHI_DATA[dynamicItem.pinzhi].color(name)
                    hevent.trigger(this.player, CONST_EVENT.zhuangbeidabeibao, { index = i })
                    echo("消耗物品：" .. coloredName .. " X " .. consumedCount, this.player)
                else
                    local consumedCount = dynamicItem.stack
                    remainingCount = remainingCount - dynamicItem.stack
                    this.zhuangbeiIventory[i] = nil
                    this.saveZhuangbeiInCundangServer(i)
                    local coloredName = ZHUANGBEI_PINZHI_DATA[dynamicItem.pinzhi].color(name)
                    hevent.trigger(this.player, CONST_EVENT.zhuangbeidabeibao, { index = i })
                    echo("消耗物品：" .. coloredName .. " X " .. consumedCount, this.player)
                end
            end
        end
        for i = 1, hdzcundang.getMaxCailiaoBeibaoCount(this.player) do
            if remainingCount <= 0 then
                return
            end
            local dynamicItem = this.inventory[i]
            if
                dynamicItem ~= nil and hitem.getName(dynamicItem.basic_item_id) == name and
                (requiredJinglian == nil or
                    (dynamicItem.jinglian ~= nil and dynamicItem.jinglian >= requiredJinglian)) and
                (requiredPinzhi == nil or (dynamicItem.pinzhi ~= nil and dynamicItem.pinzhi >= requiredPinzhi)) and
                (requiredNandu == nil or (dynamicItem.nandu ~= nil and dynamicItem.nandu >= requiredNandu)) and
                (requiredQianghua == nil or
                    (dynamicItem.qianghua ~= nil and dynamicItem.qianghua >= requiredQianghua))
            then
                if dynamicItem.stack > remainingCount then
                    local consumedCount = remainingCount
                    dynamicItem.setStack(dynamicItem.stack - remainingCount)
                    remainingCount = 0
                    this.saveItemInCundangServer(i)
                    local coloredName = ZHUANGBEI_PINZHI_DATA[dynamicItem.pinzhi].color(name)
                    hevent.trigger(this.player, CONST_EVENT.dabeibao, { index = i })
                    echo("消耗物品：" .. coloredName .. " X " .. consumedCount, this.player)
                else
                    local consumedCount = dynamicItem.stack
                    remainingCount = remainingCount - dynamicItem.stack
                    this.inventory[i] = nil
                    this.saveItemInCundangServer(i)
                    local coloredName = ZHUANGBEI_PINZHI_DATA[dynamicItem.pinzhi].color(name)
                    hevent.trigger(this.player, CONST_EVENT.dabeibao, { index = i })
                    echo("消耗物品：" .. coloredName .. " X " .. consumedCount, this.player)
                end
            end
        end

        if remainingCount > 0 then
            echo("换成物品出错，请联系作者：" .. hcolor.yellow("缺少：") .. name .. " X " .. remainingCount, this.player)
        end
    end

    this.shoujiAvailableItemFromBag = function(singleReq)
        local requiredPoints = singleReq.count or singleReq.number or 999
        local currentPoints = singleReq.currentCount or 0
        local remainingPoints = requiredPoints - currentPoints
        local name = singleReq.name
        local requiredPinzhi = singleReq.pinzhi
        local requiredNandu = singleReq.nandu
        local requiredQianghua = singleReq.qianghua
        local requiredJinglian = singleReq.jinglian
        local totalConsumedItems = 0
        local totalCollectedPoints = 0

        if remainingPoints <= 0 then
            return 0, 0
        end

        local sjss = hcache.get(this.player, "sjss", false)

        local function processItem(dynamicItem, index, isZhuangbei)
            if remainingPoints <= 0 then
                return false
            end
            -- 添加对sjss的检查，只有当sjss为true时才处理史诗难度的装备
            if dynamicItem ~= nil and hitem.getName(dynamicItem.basic_item_id) == name and
                (requiredJinglian == nil or (dynamicItem.jinglian ~= nil and dynamicItem.jinglian >= requiredJinglian)) and
                (requiredPinzhi == nil or (dynamicItem.pinzhi ~= nil and dynamicItem.pinzhi >= requiredPinzhi)) and
                (requiredNandu == nil or (dynamicItem.nandu ~= nil and dynamicItem.nandu >= requiredNandu)) and
                (requiredQianghua == nil or (dynamicItem.qianghua ~= nil and dynamicItem.qianghua >= requiredQianghua)) and
                (dynamicItem.nandu ~= FUBEN_NANDU.SHISHI or sjss) then
                local itemsToConsume = math.min(dynamicItem.stack, math.ceil(remainingPoints))
                local pointsCollected = 0
                local bonusMessage = ""

                for i = 1, itemsToConsume do
                    local bonusPoints = 0
                    if dynamicItem.nandu == FUBEN_NANDU.PUTONG then
                        bonusPoints = 1
                    elseif dynamicItem.nandu == FUBEN_NANDU.YINGXIONG then
                        if math.random(1, 100) <= 30 then
                            bonusPoints = 2
                            bonusMessage = "，收集英雄难度的装备并运气爆棚"
                        else
                            bonusPoints = 1
                        end
                    elseif dynamicItem.nandu == FUBEN_NANDU.SHISHI then
                        if math.random(1, 100) <= 50 then
                            bonusPoints = 2
                            bonusMessage = "，收集史诗难度的装备并运气爆棚"
                        else
                            bonusPoints = 1
                        end
                    end

                    pointsCollected = pointsCollected + bonusPoints
                    if pointsCollected >= remainingPoints then
                        itemsToConsume = i
                        break
                    end
                end

                if dynamicItem.stack > itemsToConsume then
                    dynamicItem.setStack(dynamicItem.stack - itemsToConsume)
                    if isZhuangbei then
                        this.saveZhuangbeiInCundangServer(index)
                    else
                        this.saveItemInCundangServer(index)
                    end
                else
                    if isZhuangbei then
                        this.zhuangbeiIventory[index] = nil
                        this.saveZhuangbeiInCundangServer(index)
                    else
                        this.inventory[index] = nil
                        this.saveItemInCundangServer(index)
                    end
                end

                local coloredName = ZHUANGBEI_PINZHI_DATA[dynamicItem.pinzhi].color(name)
                local eventType = isZhuangbei and CONST_EVENT.zhuangbeidabeibao or CONST_EVENT.dabeibao
                hevent.trigger(this.player, eventType, { index = index })

                echo(
                    "消耗物品：" ..
                    coloredName ..
                    " X " .. itemsToConsume .. bonusMessage .. " ，装备收集进度加" .. hcolor.green(tostring(pointsCollected)),
                    this.player)

                totalConsumedItems = totalConsumedItems + itemsToConsume
                totalCollectedPoints = totalCollectedPoints + pointsCollected
                remainingPoints = remainingPoints - pointsCollected

                return remainingPoints <= 0
            end
            return false
        end

        for i = 1, hdzcundang.getMaxZhuangbeiBeibaoCount(this.player) do
            if processItem(this.zhuangbeiIventory[i], i, true) then break end
        end

        if remainingPoints > 0 then
            for i = 1, hdzcundang.getMaxCailiaoBeibaoCount(this.player) do
                if processItem(this.inventory[i], i, false) then break end
            end
        end

        return totalConsumedItems, totalCollectedPoints
    end

    this.removeAvailableItemFromBag = function(singleReq)
        local itemNumber = singleReq.count or singleReq.number or 999
        local currentCount = singleReq.currentCount or 0
        itemNumber = itemNumber - currentCount
        local name = singleReq.name
        local requiredPinzhi = singleReq.pinzhi
        local requiredNandu = singleReq.nandu
        local requiredQianghua = singleReq.qianghua
        local requiredJinglian = singleReq.jinglian
        local remainingCount = itemNumber
        local removedItems = {}
        if itemNumber <= 0 then
            return 0
        end

        for i = 1, hdzcundang.getMaxZhuangbeiBeibaoCount(this.player) do
            if remainingCount <= 0 then
                return itemNumber
            end
            local dynamicItem = this.zhuangbeiIventory[i]
            if
                dynamicItem ~= nil and hitem.getName(dynamicItem.basic_item_id) == name and
                (requiredJinglian == nil or
                    (dynamicItem.jinglian ~= nil and dynamicItem.jinglian >= requiredJinglian)) and
                (requiredPinzhi == nil or (dynamicItem.pinzhi ~= nil and dynamicItem.pinzhi >= requiredPinzhi)) and
                (requiredNandu == nil or (dynamicItem.nandu ~= nil and dynamicItem.nandu >= requiredNandu)) and
                (requiredQianghua == nil or
                    (dynamicItem.qianghua ~= nil and dynamicItem.qianghua >= requiredQianghua))
            then
                if dynamicItem.stack > remainingCount then
                    local consumedCount = remainingCount
                    dynamicItem.setStack(dynamicItem.stack - remainingCount)
                    remainingCount = 0
                    this.saveZhuangbeiInCundangServer(i)
                    local coloredName = ZHUANGBEI_PINZHI_DATA[dynamicItem.pinzhi].color(name)
                    hevent.trigger(this.player, CONST_EVENT.zhuangbeidabeibao, { index = i })
                    echo("消耗物品：" .. coloredName .. " X " .. consumedCount, this.player)
                else
                    local consumedCount = dynamicItem.stack
                    remainingCount = remainingCount - dynamicItem.stack
                    this.zhuangbeiIventory[i] = nil
                    this.saveZhuangbeiInCundangServer(i)
                    local coloredName = ZHUANGBEI_PINZHI_DATA[dynamicItem.pinzhi].color(name)
                    hevent.trigger(this.player, CONST_EVENT.zhuangbeidabeibao, { index = i })
                    echo("消耗物品：" .. coloredName .. " X " .. consumedCount, this.player)
                end
            end
        end
        for i = 1, hdzcundang.getMaxCailiaoBeibaoCount(this.player) do
            if remainingCount <= 0 then
                return itemNumber
            end
            local dynamicItem = this.inventory[i]
            if
                dynamicItem ~= nil and hitem.getName(dynamicItem.basic_item_id) == name and
                (requiredJinglian == nil or
                    (dynamicItem.jinglian ~= nil and dynamicItem.jinglian >= requiredJinglian)) and
                (requiredPinzhi == nil or (dynamicItem.pinzhi ~= nil and dynamicItem.pinzhi >= requiredPinzhi)) and
                (requiredNandu == nil or (dynamicItem.nandu ~= nil and dynamicItem.nandu >= requiredNandu)) and
                (requiredQianghua == nil or
                    (dynamicItem.qianghua ~= nil and dynamicItem.qianghua >= requiredQianghua))
            then
                if dynamicItem.stack > remainingCount then
                    local consumedCount = remainingCount
                    dynamicItem.setStack(dynamicItem.stack - remainingCount)
                    remainingCount = 0
                    this.saveItemInCundangServer(i)
                    local coloredName = ZHUANGBEI_PINZHI_DATA[dynamicItem.pinzhi].color(name)
                    hevent.trigger(this.player, CONST_EVENT.dabeibao, { index = i })
                    echo("消耗物品：" .. coloredName .. " X " .. consumedCount, this.player)
                else
                    local consumedCount = dynamicItem.stack
                    remainingCount = remainingCount - dynamicItem.stack
                    this.inventory[i] = nil
                    this.saveItemInCundangServer(i)
                    local coloredName = ZHUANGBEI_PINZHI_DATA[dynamicItem.pinzhi].color(name)
                    hevent.trigger(this.player, CONST_EVENT.dabeibao, { index = i })
                    echo("消耗物品：" .. coloredName .. " X " .. consumedCount, this.player)
                end
            end
        end
        return itemNumber - remainingCount
    end

    this.createDynamicItemFromCundangStr = function(cdStr)
        if cdStr == nil or cdStr == "" then
            return nil
        end
        local id = string.sub(cdStr, 1, 4)
        if id == "0000" then
            return nil
        end
        if #cdStr ~= 31 and #cdStr ~= 6 then
            stack("Bad cundang string size: " .. cdStr .. " size:" .. #cdStr)
            return nil
        end
        if hslk.i2v(id, "Name") == nil then
            stack("item not exist: " .. cdStr)
            return nil
        end
        if #cdStr ~= 31 and hitem.getHitemType(id) == "装备" then
            stack("Bad cundang string size for zhuangbei: " .. cdStr .. " size:" .. #cdStr)
            return nil
        end
        local dynamicItem = DynamicItem(id)
        if #cdStr == 31 then
            dynamicItem.loadFromCunDangString(cdStr)
        elseif #cdStr == 6 then
            dynamicItem.loadFromShortCunDangString(cdStr)
        else
            err("Bad cundang string size: " .. cdStr .. " size:" .. #cdStr)
            return nil
        end
        dynamicItem.setOwner(player)
        if dynamicItem.pinzhi == ZHUANGBEI_PINZHI.SHENHUA then
            hdzcundang.addZuobiCount(player)
            hplayer.defeat(player, "请爱护账号，不要作弊1")
        end
        local name = hitem.getName(dynamicItem.basic_item_id)
        if DEBUGGING == false and blackListItem[name] then
            hdzcundang.addZuobiCount(player)
            hplayer.defeat(player, "请爱护账号，不要作弊2")
        end
        return dynamicItem
    end

    ---setup trigger for item change in bag
    this.initHeroBagFromCundangGetSetupTriggerForBag = function()
        if this._cundangwei == nil then
            err("存档错误: _cundangwei is nil")
            return
        end
        local hero = hplayer.getMainHero(this.player)
        local dynamicItems = {}
        dynamicItems[1] =
            this.createDynamicItemFromCundangStr(
                string.sub(hdzcundang.load_from_server(this.player, "juese" .. this._cundangwei .. "beibao1"), 1, 31)
            )
        dynamicItems[2] =
            this.createDynamicItemFromCundangStr(
                string.sub(hdzcundang.load_from_server(this.player, "juese" .. this._cundangwei .. "beibao1"), 32, 62)
            )
        dynamicItems[3] =
            this.createDynamicItemFromCundangStr(
                string.sub(hdzcundang.load_from_server(this.player, "juese" .. this._cundangwei .. "beibao2"), 1, 31)
            )
        dynamicItems[4] =
            this.createDynamicItemFromCundangStr(
                string.sub(hdzcundang.load_from_server(this.player, "juese" .. this._cundangwei .. "beibao2"), 32, 62)
            )
        dynamicItems[5] =
            this.createDynamicItemFromCundangStr(
                string.sub(hdzcundang.load_from_server(this.player, "juese" .. this._cundangwei .. "beibao3"), 1, 31)
            )
        dynamicItems[6] =
            this.createDynamicItemFromCundangStr(
                string.sub(hdzcundang.load_from_server(this.player, "juese" .. this._cundangwei .. "beibao3"), 32, 62)
            )
        for i = 1, 6, 1 do
            if dynamicItems[i] ~= nil then
                local stack = dynamicItems[i].stack
                if hitem.getHitemType(dynamicItems[i].basic_item_id) == "装备" then
                    stack = nil
                end
                hitem.create(
                    {
                        id = dynamicItems[i].basic_item_id,
                        charges = stack,
                        whichUnit = hero,
                        dynamicItem = dynamicItems[i]
                    }
                )
            end
        end

        -- setup trigger for hero bag
        hevent.register(
            hero,
            CONST_EVENT.itemGet,
            "cundang",
            function(evtData)
                -- 购买的物品没有初始化dynamic item
                if hitem.getDynamicItem(evtData.triggerItem) == nil then
                    if hitem.canBypassDynamicItemCheck(hitem.getId(evtData.triggerItem)) then
                        hdzcundang.addZuobiCount(this.player)
                        hplayer.defeat(this.player, "发现作弊物品，退出游戏")
                        return
                    end
                    return
                end
                if hitem.getIsPowerUp(evtData.triggerItem) then
                    return
                end
                local dynamicItem = hitem.getDynamicItem(evtData.triggerItem)
                if dynamicItem.getOwner() ~= nil and dynamicItem.getOwner() ~= hunit.getOwner(hero) then
                    echo("该物品不属于你", hunit.getOwner(hero))
                    for i = 0, 5, 1 do
                        if cj.UnitItemInSlot(hero, i) == evtData.triggerItem then
                            hitem.drop(hero, i)
                            return
                        end
                    end
                end
                hitem.mergeItem(hero)
                this.saveHeroBagToCundangServer()
            end
        )
        hevent.register(
            hero,
            CONST_EVENT.itemDrop,
            "cundang",
            function(_)
                this.saveHeroBagToCundangServer()
            end
        )
        hevent.register(
            hero,
            CONST_EVENT.itemUsed,
            "cundang",
            function(evtData)
                this.saveHeroBagToCundangServer()
            end
        )

        htime.setInterval(
            0.03,
            function(curTimer)
                if hplayer.isPlaying(this.player) == false then
                    curTimer.destroy()
                    return
                end
                if hcache.get(this.player, "disablebeibaosave", false) then
                    return
                end
                hitem.forEach(
                    hero,
                    function(enumItem, slotIndex)
                        if
                            enumItem ~= nil and hitem.getDynamicItem(enumItem) ~= nil and
                            hitem.getDynamicItem(enumItem).getOwner() ~= this.player
                        then
                            hitem.drop(hero, slotIndex)
                        end
                    end
                )
                this.saveHeroBagToCundangServer()
            end
        )
    end

    ---setup trigger for item change in bag
    this.initInventoryCundang = function()
        for i = 1, hdzcundang.getMaxCailiaoBeibaoCount(this.player), 1 do
            local keyi = (i - 1) / 10
            local cdKey = "dabeibao" .. tostring(math.floor(keyi))
            local starti = (i - 1) % 10 * 6 + 1
            local endi = starti + 5
            local cdStr = string.sub(hdzcundang.load_from_server(this.player, cdKey), starti, endi)
            this.inventory[i] = this.createDynamicItemFromCundangStr(cdStr)
        end
        this.updateSortedInventoryIdx()
        for i = 1, hdzcundang.getMaxCailiaoBeibaoCount(this.player), 1 do
            hevent.trigger(this.player, CONST_EVENT.dabeibao, { index = i })
        end

        if this._cundangwei == nil then
            err("存档错误: _cundangwei is nil")
            return
        end
        for i = 1, hdzcundang.getMaxZhuangbeiBeibaoCount(this.player), 1 do
            local keyi = (i - 1) / 2
            local cdKey = "juese" .. this._cundangwei .. "zhuangbeidabeibao" .. tostring(math.floor(keyi))
            local starti = (i - 1) % 2 * 31 + 1
            local endi = starti + 30
            local cdStr = string.sub(hdzcundang.load_from_server(this.player, cdKey), starti, endi)
            this.zhuangbeiIventory[i] = this.createDynamicItemFromCundangStr(cdStr)
        end
        this.updateSortedZhuangbeiInventoryIdx()
        for i = 1, hdzcundang.getMaxZhuangbeiBeibaoCount(this.player), 1 do
            hevent.trigger(this.player, CONST_EVENT.zhuangbeidabeibao, { index = i })
        end
    end

    ---@param equipmentSlot number 从小到大依次为为1主手，2副手，3头盔，4衣服，5手套，6鞋子，7披风，8戒指，9项链，10饰品
    ---@return DynamicItem|nil
    this.getEquipment = function(equipmentSlot)
        return this.equipments[equipmentSlot]
    end
    ---@param equipmentSlot number 从小到大依次为为1主手，2副手，3头盔，4衣服，5手套，6鞋子，7披风，8戒指，9项链，10饰品
    ---@param dynamicItem DynamicItem
    ---@return void
    this.setEquipment = function(equipmentSlot, dynamicItem)
        if this._cundangwei == nil then
            err("存档错误: _cundangwei is nil")
            return
        end
        local hero = hplayer.getMainHero(this.player)

        hevent.trigger(
            hero,
            CONST_EVENT.equipmentChange,
            {
                equipmentSlot = equipmentSlot,
                dynamicItem = this.equipments[equipmentSlot],
                isAdd = false,
                whichPlayer = this.player
            }
        )
        hevent.trigger(
            hero,
            CONST_EVENT.equipmentChange,
            { equipmentSlot = equipmentSlot, dynamicItem = dynamicItem, isAdd = true, whichPlayer = this.player }
        )
        -- 装备存档
        local cundangstr
        if dynamicItem ~= nil then
            cundangstr = dynamicItem.getCunDangString()
        else
            cundangstr = "0000000000000000000000000000000"
        end
        if string.len(cundangstr) ~= 31 then
            stack("Bad zhuangbei cundang: " .. cundangstr)
            return
        end
        local cundangstartidx = (equipmentSlot - 1) % 2 * 31
        local cundangendidx = cundangstartidx + 31
        local cundangkey = "zhuangbei" .. tostring(math.floor((equipmentSlot - 1) / 2))
        local fullKey = "juese" .. this._cundangwei .. cundangkey
        local new_cundang =
            string.sub(hdzcundang.load_from_server(this.player, fullKey), 1, cundangstartidx) ..
            cundangstr .. string.sub(hdzcundang.load_from_server(this.player, fullKey), cundangendidx + 1)
        hdzcundang.save_to_server(this.player, fullKey, new_cundang)
    end

    --- moveItemFromBagToInventory
    ---@param whichUnit userdata
    ---@param slotid int
    ---@return nil
    this.moveItemFromBagToInventory = function(whichUnit, slotId)
        local it = cj.UnitItemInSlot(whichUnit, slotId)
        if it ~= nil then
            local dynamicItem = hitem.getDynamicItem(it)
            if dynamicItem == nil or dynamicItem.getOwner() ~= hunit.getOwner(whichUnit) then
                return
            end
            if this.saveItemInInventory(dynamicItem) then
                hitem.destroy(it)
                this.saveHeroBagToCundangServer()
            end
        end
    end

    this.getDynamicItemFromDaBeibaobyUIIndex = function(index)
        local sortedIndex = this.UiIndexToDabeibaoIndex[index]
        return this.inventory[sortedIndex]
    end

    this.getDaBeibaoIndexbyUIIndex = function(index)
        return this.UiIndexToDabeibaoIndex[index]
    end

    this.getUIIndexbyDabeibaoIndex = function(index)
        return this.dabaobeiIndexToUIIndex[index]
    end

    this.getDynamicItemFromZhuangbeiDaBeibaobyUIIndex = function(index)
        local sortedIndex = this.UiIndexToZhuangbeiDabeibaoIndex[index]
        return this.zhuangbeiIventory[sortedIndex]
    end

    this.getZhuangbeiDaBeibaoIndexbyUIIndex = function(index)
        return this.UiIndexToZhuangbeiDabeibaoIndex[index]
    end

    this.getUIIndexbyZhuangbeiDabeibaoIndex = function(index)
        return this.zhuangbeiDabaobeiIndexToUIIndex[index]
    end

    this.updateSortedInventoryIdx = function()
        local sortedItems = {}
        local reverseIndex = {}
        local emptyIndex = {}
        this.UiIndexToDabeibaoIndex = {}
        this.dabaobeiIndexToUIIndex = {}
        -- 将背包物品添加到一个新表中
        for i = 1, hdzcundang.getMaxCailiaoBeibaoCount(this.player) do
            if this.inventory[i] ~= nil then
                table.insert(sortedItems, this.inventory[i])
                reverseIndex[this.inventory[i]] = i
            else
                table.insert(emptyIndex, i)
            end
        end
        -- 按照品质排序
        table.sort(
            sortedItems,
            function(item1, item2)
                if item1 == nil and item2 == nil then
                    return false
                elseif item1 == nil then
                    return false
                elseif item2 == nil then
                    return true
                elseif
                    hitem.getHitemType(item1.basic_item_id) ~= nil and hitem.getHitemType(item2.basic_item_id) ~= nil and
                    hitem.getHitemType(item1.basic_item_id) ~= hitem.getHitemType(item2.basic_item_id)
                then
                    return hitem.getHitemType(item1.basic_item_id) > hitem.getHitemType(item2.basic_item_id)
                elseif
                    hitem.getEquipmentTypeByID(item1.basic_item_id) ~= nil and
                    hitem.getEquipmentTypeByID(item2.basic_item_id) ~= nil and
                    hitem.getEquipmentTypeByID(item1.basic_item_id) ~=
                    hitem.getEquipmentTypeByID(item2.basic_item_id)
                then
                    return hitem.getEquipmentTypeByID(item1.basic_item_id) >
                        hitem.getEquipmentTypeByID(item2.basic_item_id)
                elseif item1.level ~= nil and item2.level ~= nil and item1.level ~= item2.level then
                    return item1.level > item2.level
                elseif item1.pinzhi ~= nil and item2.pinzhi ~= nil and item1.pinzhi ~= item2.pinzhi then
                    return item1.pinzhi > item2.pinzhi
                elseif item1.nandu ~= nil and item2.nandu ~= nil and item1.nandu ~= item2.nandu then
                    return item1.nandu > item2.nandu
                else
                    return item1.basic_item_id > item2.basic_item_id
                end
            end
        )
        -- 保存排序后物品的原索引
        for i, item in ipairs(sortedItems) do
            this.UiIndexToDabeibaoIndex[i] = reverseIndex[item]
            this.dabaobeiIndexToUIIndex[reverseIndex[item]] = i
        end
        for i, index in ipairs(emptyIndex) do
            local ui_index = i + #sortedItems
            this.UiIndexToDabeibaoIndex[ui_index] = index
            this.dabaobeiIndexToUIIndex[index] = ui_index
        end
        for i = 1, hdzcundang.getMaxCailiaoBeibaoCount(this.player) do
            if this.UiIndexToDabeibaoIndex[i] == nil then
                err("UiIndexToDabeibaoIndex 缺失" .. i)
            end
            if this.dabaobeiIndexToUIIndex[i] == nil then
                err("dabaobeiIndexToUIIndex 缺失" .. i)
            end
        end
    end

    this.updateSortedZhuangbeiInventoryIdx = function()
        local sortedItems = {}
        local reverseIndex = {}
        local emptyIndex = {}
        this.UiIndexToZhuangbeiDabeibaoIndex = {}
        this.zhuangbeiDabaobeiIndexToUIIndex = {}
        -- 将背包物品添加到一个新表中
        for i = 1, hdzcundang.getMaxZhuangbeiBeibaoCount(this.player) do
            if this.zhuangbeiIventory[i] ~= nil then
                table.insert(sortedItems, this.zhuangbeiIventory[i])
                reverseIndex[this.zhuangbeiIventory[i]] = i
            else
                table.insert(emptyIndex, i)
            end
        end
        -- 按照品质排序
        table.sort(
            sortedItems,
            function(item1, item2)
                if item1 == nil and item2 == nil then
                    return false
                elseif item1 == nil then
                    return false
                elseif item2 == nil then
                    return true
                elseif
                    hitem.getHitemType(item1.basic_item_id) ~= nil and hitem.getHitemType(item2.basic_item_id) ~= nil and
                    hitem.getHitemType(item1.basic_item_id) ~= hitem.getHitemType(item2.basic_item_id)
                then
                    return hitem.getHitemType(item1.basic_item_id) > hitem.getHitemType(item2.basic_item_id)
                elseif
                    hitem.getEquipmentTypeByID(item1.basic_item_id) ~= nil and
                    hitem.getEquipmentTypeByID(item2.basic_item_id) ~= nil and
                    hitem.getEquipmentTypeByID(item1.basic_item_id) ~=
                    hitem.getEquipmentTypeByID(item2.basic_item_id)
                then
                    return hitem.getEquipmentTypeByID(item1.basic_item_id) >
                        hitem.getEquipmentTypeByID(item2.basic_item_id)
                elseif item1.level ~= nil and item2.level ~= nil and item1.level ~= item2.level then
                    return item1.level > item2.level
                elseif item1.pinzhi ~= nil and item2.pinzhi ~= nil and item1.pinzhi ~= item2.pinzhi then
                    return item1.pinzhi > item2.pinzhi
                elseif item1.nandu ~= nil and item2.nandu ~= nil and item1.nandu ~= item2.nandu then
                    return item1.nandu > item2.nandu
                else
                    return item1.basic_item_id > item2.basic_item_id
                end
            end
        )
        -- 保存排序后物品的原索引
        for i, item in ipairs(sortedItems) do
            this.UiIndexToZhuangbeiDabeibaoIndex[i] = reverseIndex[item]
            this.zhuangbeiDabaobeiIndexToUIIndex[reverseIndex[item]] = i
        end
        for i, index in ipairs(emptyIndex) do
            local ui_index = i + #sortedItems
            this.UiIndexToZhuangbeiDabeibaoIndex[ui_index] = index
            this.zhuangbeiDabaobeiIndexToUIIndex[index] = ui_index
        end
        for i = 1, hdzcundang.getMaxZhuangbeiBeibaoCount(this.player) do
            if this.UiIndexToZhuangbeiDabeibaoIndex[i] == nil then
                err("UiIndexToZhuangbeiDabeibaoIndex 缺失" .. i)
            end
            if this.zhuangbeiDabaobeiIndexToUIIndex[i] == nil then
                err("zhuangbeiDabaobeiIndexToUIIndex 缺失" .. i)
            end
        end
    end

    --- this function try to save item in inventory
    --- it will return true when succeed, else return false
    ---@param dynamicItem DynamicItem item to save
    ---@return bool
    this.saveItemInInventory = function(dynamicItem)
        if dynamicItem == nil then
            return false
        end
        if
            hitem.getHitemType(dynamicItem.basic_item_id) == "装备" or
            hitem.saveInZhuangbeiBeibao(dynamicItem.basic_item_id) == true
        then
            local pinzhi = dynamicItem.pinzhi or ZHUANGBEI_PINZHI.PUTONG
            local color = ZHUANGBEI_PINZHI_DATA[pinzhi].color
            local count = dynamicItem.stack
            -- 检查是否有堆叠
            for uiIndex = 1, hdzcundang.getMaxZhuangbeiBeibaoCount(this.player), 1 do
                local i = this.UiIndexToZhuangbeiDabeibaoIndex[uiIndex]
                if hitem.tryMergeItem(dynamicItem, this.zhuangbeiIventory[i]) then
                    this.saveZhuangbeiInCundangServer(i)
                    hevent.trigger(this.player, CONST_EVENT.zhuangbeidabeibao, { index = i })
                    echo(
                        "物品：" .. color(hitem.getName(dynamicItem.basic_item_id)) .. " X " .. count .. " 存入装备背包",
                        this.player
                    )
                    return true
                end
            end
            -- 检查是否有空位
            for uiIndex = 1, hdzcundang.getMaxZhuangbeiBeibaoCount(this.player), 1 do
                local i = this.UiIndexToZhuangbeiDabeibaoIndex[uiIndex]
                if this.zhuangbeiIventory[i] == nil then
                    this.zhuangbeiIventory[i] = dynamicItem
                    this.saveZhuangbeiInCundangServer(i)
                    hevent.trigger(this.player, CONST_EVENT.zhuangbeidabeibao, { index = i })
                    echo(
                        "物品：" ..
                        color(hitem.getName(dynamicItem.basic_item_id)) .. " X " .. dynamicItem.stack .. " 存入装备背包",
                        this.player
                    )
                    return true
                end
            end

            echo("装备背包已满。", this.player)
            return false
        else
            local pinzhi = dynamicItem.pinzhi or ZHUANGBEI_PINZHI.PUTONG
            local color = ZHUANGBEI_PINZHI_DATA[pinzhi].color
            -- 检查是否有空位 以及堆叠
            for uiIndex = 1, hdzcundang.getMaxCailiaoBeibaoCount(this.player), 1 do
                local i = this.UiIndexToDabeibaoIndex[uiIndex]
                if hitem.tryMergeItem(dynamicItem, this.inventory[i]) then
                    this.saveItemInCundangServer(i)
                    hevent.trigger(this.player, CONST_EVENT.dabeibao, { index = i })
                    echo(
                        "物品：" ..
                        color(hitem.getName(dynamicItem.basic_item_id)) .. " X " .. dynamicItem.stack .. " 存入材料背包",
                        this.player
                    )
                    return true
                end
            end
            for uiIndex = 1, hdzcundang.getMaxCailiaoBeibaoCount(this.player), 1 do
                local i = this.UiIndexToDabeibaoIndex[uiIndex]
                if this.inventory[i] == nil then
                    this.inventory[i] = dynamicItem
                    this.saveItemInCundangServer(i)
                    hevent.trigger(this.player, CONST_EVENT.dabeibao, { index = i })
                    echo(
                        "物品：" ..
                        color(hitem.getName(dynamicItem.basic_item_id)) .. " X " .. dynamicItem.stack .. " 存入材料背包",
                        this.player
                    )
                    return true
                end
            end

            echo("材料背包已满。", this.player)
            return false
        end
    end

    this.saveItemInCundangServer = function(index)
        local dynamicItem = this.inventory[index]
        local cundangstr = "000000"
        if dynamicItem ~= nil then
            cundangstr = dynamicItem.getShortCunDangString()
        end
        if string.len(cundangstr) ~= 6 then
            stack("Bad item cundang: " .. cundangstr)
            return
        end
        local cundangstartidx = (index - 1) % 10 * 6
        local cundangendidx = cundangstartidx + 6
        local cundangkey = "dabeibao" .. tostring(math.floor((index - 1) / 10))
        local new_cundang =
            string.sub(hdzcundang.load_from_server(this.player, cundangkey), 1, cundangstartidx) ..
            cundangstr .. string.sub(hdzcundang.load_from_server(this.player, cundangkey), cundangendidx + 1)
        hdzcundang.save_to_server(this.player, cundangkey, new_cundang)
    end

    this.saveZhuangbeiInCundangServer = function(index)
        local dynamicItem = this.zhuangbeiIventory[index]
        local cundangstr = "0000000000000000000000000000000"
        if dynamicItem ~= nil then
            cundangstr = dynamicItem.getCunDangString()
        end
        if string.len(cundangstr) ~= 31 then
            stack("Bad item cundang: " .. cundangstr)
            return
        end
        if this._cundangwei == nil then
            err("存档错误: _cundangwei is nil")
            return
        end
        local hero = hplayer.getMainHero(this.player)
        local cundangstartidx = (index - 1) % 2 * 31
        local cundangendidx = cundangstartidx + 31
        local cundangkey = "juese" .. this._cundangwei .. "zhuangbeidabeibao" .. tostring(math.floor((index - 1) / 2))
        local new_cundang =
            string.sub(hdzcundang.load_from_server(this.player, cundangkey), 1, cundangstartidx) ..
            cundangstr .. string.sub(hdzcundang.load_from_server(this.player, cundangkey), cundangendidx + 1)
        hdzcundang.save_to_server(this.player, cundangkey, new_cundang)
    end

    this.getItemFromZhuangbeiInventoryToBag = function(index)
        if type(index) ~= "number" then
            return
        end
        local dynamicItem = this.zhuangbeiIventory[index]
        if dynamicItem == nil then
            return
        end
        this.zhuangbeiIventory[index] = nil
        this.saveZhuangbeiInCundangServer(index)
        hevent.trigger(this.player, CONST_EVENT.zhuangbeidabeibao, { index = index })
        hitem.create(
            {
                id = dynamicItem.basic_item_id,
                charges = dynamicItem.stack,
                whichUnit = hplayer.getMainHero(this.player),
                dynamicItem = dynamicItem
            }
        )
    end

    this.getItemFromInventoryToBag = function(index)
        if type(index) ~= "number" then
            return
        end
        local dynamicItem = this.inventory[index]
        if dynamicItem == nil then
            return
        end
        this.inventory[index] = nil
        this.saveItemInCundangServer(index)
        hevent.trigger(this.player, CONST_EVENT.dabeibao, { index = index })
        hitem.create(
            {
                id = dynamicItem.basic_item_id,
                charges = dynamicItem.stack,
                whichUnit = hplayer.getMainHero(this.player),
                dynamicItem = dynamicItem
            }
        )
    end

    this.saveHeroBagToCundangServer = function()
        if this._cundangwei == nil then
            err("存档错误: _cundangwei is nil")
            return
        end
        local cundangs = {}
        hitem.forEach(
            hplayer.getMainHero(this.player),
            function(it, slotId)
                if
                    it ~= nil and hitem.getDynamicItem(it) ~= nil and hitem.getDynamicItem(it).stack ~= nil and
                    hitem.getDynamicItem(it).stack > 0 and
                    hitem.getDynamicItem(it).getOwner() == this.player
                then
                    cundangs[slotId] = hitem.getDynamicItem(it).getCunDangString()
                else
                    cundangs[slotId] = "0000000000000000000000000000000"
                end
            end
        )
        hdzcundang.save_to_server(
            this.player,
            "juese" .. this._cundangwei .. "beibao1",
            cundangs[0] .. cundangs[1] .. "0"
        )
        hdzcundang.save_to_server(
            this.player,
            "juese" .. this._cundangwei .. "beibao2",
            cundangs[2] .. cundangs[3] .. "0"
        )
        hdzcundang.save_to_server(
            this.player,
            "juese" .. this._cundangwei .. "beibao3",
            cundangs[4] .. cundangs[5] .. "0"
        )
    end

    this.saveCundang = function(key, isHeroLevel, startIndex, endIndex, val)
        if key == nil or endIndex - startIndex + 1 ~= string.len(val) or endIndex > 63 or startIndex < 1 then
            err("存档错误: key is nil or startIndex:" .. startIndex .. " endIndex: " .. endIndex .. " val: " .. val)
            return
        end
        local cundangkey = key
        if isHeroLevel == true then
            if this._cundangwei == nil then
                err("存档错误: _cundangwei is nil")
                return
            end
            cundangkey = "juese" .. this._cundangwei .. cundangkey
        end
        local cundangValue = hdzcundang.load_from_server(this.player, cundangkey)
        local cdStr = string.sub(cundangValue, 1, startIndex - 1) .. val .. string.sub(cundangValue, endIndex + 1, 63)
        return hdzcundang.save_to_server(this.player, cundangkey, cdStr)
    end

    this.saveCundangWihtoutIndx = function(key, isHeroLevel, val, skipEncryption)
        if key == nil then
            err("存档错误: key is nil")
            return
        end
        local cundangkey = key
        if isHeroLevel == true then
            if this._cundangwei == nil then
                err("存档错误: _cundangwei is nil")
                return
            end
            cundangkey = "juese" .. this._cundangwei .. cundangkey
        end
        return hdzcundang.save_to_server(this.player, cundangkey, tostring(val), false, skipEncryption)
    end

    this.player = player
    this.loadCunDang()
    return this
end
