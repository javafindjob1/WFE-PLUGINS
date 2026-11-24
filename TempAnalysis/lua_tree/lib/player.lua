---@class hplayer
hplayer = {
    --- 用户玩家
    players = {},
    --- 中立敌对
    player_aggressive = cj.Player(PLAYER_NEUTRAL_AGGRESSIVE),
    --- 中立受害
    player_victim = cj.Player(bj_PLAYER_NEUTRAL_VICTIM),
    --- 中立特殊
    player_extra = cj.Player(bj_PLAYER_NEUTRAL_EXTRA),
    --- 中立被动
    player_passive = cj.Player(PLAYER_NEUTRAL_PASSIVE),
    --- 玩家状态
    player_status = {
        none = "无参与",
        gaming = "游戏中",
        leave = "已离开"
    },
    --- 用户玩家最大数量
    qty_max = 12,
    --- 当前玩家数量
    qty_current = 0,
    --- 换算比率，默认：1000000金 -> 1木
    ---@private
    convert_ratio = 1000000,
    -- 所有存档属性都在这里
    dzCunDang = {}
}

--- 是否电脑(如果位置为电脑玩家或无玩家，则为true)
--- 常用来判断电脑AI是否开启
---@param whichPlayer userdata
---@return boolean
function hplayer.isComputer(whichPlayer)
    return cj.GetPlayerController(whichPlayer) == MAP_CONTROL_COMPUTER or
        cj.GetPlayerSlotState(whichPlayer) ~= PLAYER_SLOT_STATE_PLAYING
end

--- 是否玩家位置(如果位置为真实玩家或为空，则为true；而如果选择了电脑玩家补充，则为false)
--- 常用来判断该是否玩家可填补位置
---@param whichPlayer userdata
---@return boolean
function hplayer.isUser(whichPlayer)
    return cj.GetPlayerController(whichPlayer) == MAP_CONTROL_USER
end

--- 是否正在游戏
---@param whichPlayer userdata
---@return boolean
function hplayer.isPlaying(whichPlayer)
    return cj.GetPlayerSlotState(whichPlayer) == PLAYER_SLOT_STATE_PLAYING
end

--- 是否中立玩家（包括中立敌对 中立被动 中立受害 中立特殊）
---@param whichPlayer userdata
---@return boolean
function hplayer.isNeutral(whichPlayer)
    return cj.GetPlayerId(whichPlayer) >= 12
end

--- 玩家是否正在受伤
---@param whichPlayer userdata
---@return boolean
function hplayer.isBeDamaging(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.ATTR_BE_DAMAGING, false)
end

--- 玩家是否正在造成伤害
---@param whichPlayer userdata
---@return boolean
function hplayer.isDamaging(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.ATTR_DAMAGING, false)
end

--- 玩家是否有贴图在展示
---@param whichPlayer userdata
---@return boolean
function hplayer.isMarking(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_MARKING) == true
end

---@private
function hplayer.adjustPlayerState(delta, whichPlayer, whichPlayerState)
    if delta > 0 then
        if whichPlayerState == PLAYER_STATE_RESOURCE_GOLD then
            cj.SetPlayerState(
                whichPlayer,
                PLAYER_STATE_GOLD_GATHERED,
                cj.GetPlayerState(whichPlayer, PLAYER_STATE_GOLD_GATHERED) + delta
            )
        elseif whichPlayerState == PLAYER_STATE_RESOURCE_LUMBER then
            cj.SetPlayerState(
                whichPlayer,
                PLAYER_STATE_LUMBER_GATHERED,
                cj.GetPlayerState(whichPlayer, PLAYER_STATE_LUMBER_GATHERED) + delta
            )
        end
    end
    cj.SetPlayerState(whichPlayer, whichPlayerState, cj.GetPlayerState(whichPlayer, whichPlayerState) + delta)
end

--- 设置科技研究等级
function hplayer.setPlayerTechResearched(whichPlayer, techid, level)
    cj.SetPlayerTechResearched(whichPlayer, techid, level)
end

--- 获取科技研究等级
function hplayer.getPlayerTechResearched(whichPlayer, techid)
    return cj.GetPlayerTechCount(whichPlayer, techid, true)
end

---@private
function hplayer.setPlayerState(whichPlayer, whichPlayerState, value)
    local oldValue = cj.GetPlayerState(whichPlayer, whichPlayerState)
    hplayer.adjustPlayerState(value - oldValue, whichPlayer, whichPlayerState)
end

--- 遍历玩家
--- 遍历过程中返回 false 则中断
---@param action fun(enumPlayer:userdata, idx:number)
function hplayer.forEach(action)
    if (action == nil) then
        return
    end
    if (type(action) == "function") then
        for idx = 1, hplayer.qty_max, 1 do
            local res = action(hplayer.players[idx], idx)
            if (type(res) == "boolean" and res == false) then
                break
            end
        end
    end
end

--- 玩家ID索引
---@protected
hplayer.indexes = {}

--- 获取玩家ID
--- 例如：玩家一等于1，玩家三等于3
---@param whichPlayer userdata
---@return number
function hplayer.index(whichPlayer)
    if whichPlayer == nil then
        return nil
    end
    local idx
    if (hplayer.indexes[whichPlayer] ~= nil) then
        idx = hplayer.indexes[whichPlayer]
    else
        idx = cj.GetPlayerId(whichPlayer) + 1
        hplayer.indexes[whichPlayer] = idx
    end
    return idx
end

--- 获取玩家的主要英雄
---@param whichPlayer userdata
---@return whichUnit userdata
function hplayer.getMainHero(whichPlayer)
    local playerIndex = hplayer.index(whichPlayer)
    if #hhero.player_heroes[playerIndex] > 1 then
        dump("Error, more than one hero returned")
    end
    return hhero.player_heroes[playerIndex][1]
end

--- 获取本地玩家
---@return userdata player
function hplayer.loc()
    return cj.GetLocalPlayer()
end

--- 设置换算比率，多少金换1木
---@param ratio number
function hplayer.setConvertRatio(ratio)
    if (type(ratio) == "number") then
        hplayer.convert_ratio = math.floor(ratio)
    end
end

--- 获取换算比率
---@return number
function hplayer.getConvertRatio()
    return hplayer.convert_ratio
end

--- 获取玩家名称
---@param whichPlayer userdata
---@return string
function hplayer.getName(whichPlayer)
    local n = hcache.get(whichPlayer, CONST_CACHE.PLAYER_NAME)
    if (n == nil) then
        n = cj.GetPlayerName(whichPlayer)
        hcache.set(whichPlayer, CONST_CACHE.PLAYER_NAME, n)
    end
    return n
end

function hplayer.getRexinwanjiadianshu(whichPlayer)
    local rexinJifen = 0
    rexinJifen = rexinJifen + hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCSXNLJJ")
    rexinJifen = rexinJifen + hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCSMNLJJ")
    rexinJifen = rexinJifen + hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCSMHFNLJJ")
    rexinJifen = rexinJifen + hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCGJNLJJ")
    rexinJifen = rexinJifen + hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCHANLJJ") * 2
    rexinJifen = rexinJifen + hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCLMNLJJ") * 2
    rexinJifen = rexinJifen + hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCFYNLJJ") * 2
    local a = hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCHANLJJ")
    local b = hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCLMNLJJ")
    local c = hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCFYNLJJ")
    rexinJifen = rexinJifen + math.ceil((a + b + c) / 3) * 2
    rexinJifen = rexinJifen + hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCJRNLJJ") * 5
    rexinJifen = rexinJifen + hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCSYNLJJ") * 5
    rexinJifen = rexinJifen + hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCJQNLJJ") * 5
    rexinJifen = rexinJifen + hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "SCJZNLJJ") * 5
    if GET_ZHENGYIWANJIA_LEVEL ~= nil and type(GET_ZHENGYIWANJIA_LEVEL) == "function" then
        rexinJifen = rexinJifen + math.min(300, GET_ZHENGYIWANJIA_LEVEL(whichPlayer) * 20)
    end
    if hshangcheng.hasItem(whichPlayer, "青铜VIP") then
        rexinJifen = rexinJifen + 2
    end
    if hshangcheng.hasItem(whichPlayer, "白银VIP") then
        rexinJifen = rexinJifen + 10
    end
    if hshangcheng.hasItem(whichPlayer, "黄金VIP") then
        rexinJifen = rexinJifen + 22
    end
    if hshangcheng.hasItem(whichPlayer, "铂金VIP") then
        rexinJifen = rexinJifen + 42
    end
    if hshangcheng.hasItem(whichPlayer, "钻石VIP") then
        rexinJifen = rexinJifen + 76
    end
    if hshangcheng.hasItem(whichPlayer, "巅峰VIP") then
        rexinJifen = rexinJifen + 165
    end
    if hshangcheng.hasItem(whichPlayer, "小材料包") then
        rexinJifen = rexinJifen + 10
    end
    if hshangcheng.hasItem(whichPlayer, "中材料包") then
        rexinJifen = rexinJifen + 22
    end
    if hshangcheng.hasItem(whichPlayer, "大材料包") then
        rexinJifen = rexinJifen + 32
    end
    if hshangcheng.hasItem(whichPlayer, "巨无霸材料包") then
        rexinJifen = rexinJifen + 60
    end
    if hshangcheng.hasItem(whichPlayer, "荣誉会员") then
        rexinJifen = rexinJifen + 18
    end
    if hshangcheng.hasItem(whichPlayer, "外交天赋") then
        rexinJifen = rexinJifen + 18
    end

    if hshangcheng.hasItem(whichPlayer, "高级制布刀") then
        rexinJifen = rexinJifen + 18
    end
    if hshangcheng.hasItem(whichPlayer, "高级采药手套") then
        rexinJifen = rexinJifen + 18
    end
    if hshangcheng.hasItem(whichPlayer, "高级鱼竿") then
        rexinJifen = rexinJifen + 18
    end
    if hshangcheng.hasItem(whichPlayer, "高级锄") then
        rexinJifen = rexinJifen + 18
    end
    if hshangcheng.hasItem(whichPlayer, "高级剥皮刀") then
        rexinJifen = rexinJifen + 18
    end
    if hshangcheng.hasItem(whichPlayer, "冒险手册") then
        rexinJifen = rexinJifen + 32
    end
    if hshangcheng.hasItem(whichPlayer, "第四存档位") then
        rexinJifen = rexinJifen + 22
    end
    if hshangcheng.hasItem(whichPlayer, "第五存档位") then
        rexinJifen = rexinJifen + 32
    end

    return rexinJifen
end

function hplayer.loadRexinwanjia(whichPlayer)
    local rexinwanjiajiangli = {
        {
            score = 50,
            attr = _attr({ gold_ratio = "+5", exp_ratio = "+5" })
        },
        {
            score = 100,
            attr = _attr({ qianghua_rate = "+10" })
        },
        {
            score = 200,
            attr = _attr({ jinglian_rate = "+10" })
        },
        {
            score = 500,
            attr = _attr({ caiji_speed = "+30", lansecitiao_rate = "+1" }),
            zuoqi = { { pinzhi = ZHUANGBEI_PINZHI.SHISHI, name = "作战科多兽" } }
        },
        {
            score = 800,
            attr = _attr({ tujian_rate = "+20" }),
            zuoqi = { { pinzhi = ZHUANGBEI_PINZHI.SHISHI, name = "魔力扫帚" } }
        },
        {
            score = 1300,
            attr = _attr({ diaoyu_rate = "+10", zhibu_rate = "+10", baopi_rate = "+10" }),
            zuoqi = { { pinzhi = ZHUANGBEI_PINZHI.CHUANQI, name = "夜刃豹" } }
        },
        {
            score = 2000,
            attr = _attr({ fumo_rate = "+10", caikuang_rate = "+10", caiyao_rate = "+10", lansecitiao_rate = "+1" }),
            zuoqi = { { pinzhi = ZHUANGBEI_PINZHI.CHUANQI, name = "战争三角龙" } }
        },
        {
            score = 3200,
            attr = _attr({ zaisheng_speed = "+10", dianfeng_jingyan_ratio = "+5" }),
            huanhua = { { pinzhi = ZHUANGBEI_PINZHI.CHUANQI, name = "神龙之威" } }
        },
        {
            score = 4600,
            attr = _attr({ yaoshui_shijian = "+40", dianfeng_jingyan_ratio = "+5", zisecitiao_rate = "+1" }),
            zuoqi = { { pinzhi = ZHUANGBEI_PINZHI.CHUANQI, name = "踏星" } }
        },
        {
            score = 6000,
            attr = _attr({ caiji_speed = "+100", dianfeng_jingyan_ratio = "+5", lansecitiao_rate = "+2" }),
            huanhua = {
                { pinzhi = ZHUANGBEI_PINZHI.CHUANQI, name = "至日流光之刃（主手）" },
                { pinzhi = ZHUANGBEI_PINZHI.CHUANQI, name = "至日流光之刃（副手）" },
                { pinzhi = ZHUANGBEI_PINZHI.CHUANQI, name = "湮灭之杖" },
                { pinzhi = ZHUANGBEI_PINZHI.CHUANQI, name = "灵魂之羽" },
                { pinzhi = ZHUANGBEI_PINZHI.CHUANQI, name = "金色流光（主手）" },
                { pinzhi = ZHUANGBEI_PINZHI.CHUANQI, name = "金色流光（副手）" }
            }
        },
        {
            score = 8000,
            attr = _attr({ extra_dianfeng = "+1", zaisheng_speed = "+10", zisecitiao_rate = "+1" }),
            zuoqi = { { pinzhi = ZHUANGBEI_PINZHI.CHUANQI, name = "黄金巨龙" } }
        },
        {
            score = 10000,
            attr = _attr({ extra_dianfeng = "+2", zaisheng_speed = "+15", lansecitiao_rate = "+2", zisecitiao_rate = "+2" }),
            huanhua = { { pinzhi = ZHUANGBEI_PINZHI.SHENHUA, name = "永恒之光" } }
        },
        {
            score = 12000,
            attr = _attr({ extra_dianfeng = "+3", zaisheng_speed = "+20", lansecitiao_rate = "+3", zisecitiao_rate = "+3" }),
            zuoqi = { { pinzhi = ZHUANGBEI_PINZHI.SHENHUA, name = "幽灵虎" } }
        },
        {
            score = 15000,
            attr = _attr({
                sqnl_huoqu = "+20",
                lansecitiao_rate = "+3",
                zisecitiao_rate = "+3",
                chengsecitiao_rate = "+3",
                extra_drop_rate = "+20"
            }),
            zuoqi = { { pinzhi = ZHUANGBEI_PINZHI.SHENHUA, name = "光铸机甲" } }
        }
    }

    local score = hplayer.getRexinwanjiadianshu(whichPlayer)
    local mainHero = hplayer.getMainHero(whichPlayer)
    for _, v in ipairs(rexinwanjiajiangli) do
        if score >= v.score then
            if v.attr ~= nil then
                hattr.set(mainHero, 0, v.attr)
            end
            if v.zuoqi ~= nil then
                for _, zuoqi in ipairs(v.zuoqi) do
                    hzuoqi.jihuozuoqi(zuoqi.name, whichPlayer, false)
                end
            end
            if v.huanhua ~= nil then
                for _, huanhua in ipairs(v.huanhua) do
                    hhuanhua.jihuohuanhua(huanhua.name, whichPlayer, false)
                end
            end
        end
    end

    local msg = {}
    table.insert(msg, "根据热心玩家积分奖励那些支持本游戏的玩家。热心玩家积分可以由多种途径获得。目前途径有：")
    table.insert(
        msg,
        "1.从能量水晶转化而来，每颗" ..
        hcolor.green("生命能量结晶") ..
        "，" ..
        hcolor.green("生命恢复能量结晶") ..
        "，" ..
        hcolor.green("攻击能量结晶") ..
        "，" ..
        hcolor.green("属性能量结晶") ..
        "，" ..
        "提供|cff00ff001|r点热心玩家积分，每颗" ..
        hcolor.jinglianglan("灵敏能量结晶") ..
        "，" ..
        hcolor.jinglianglan("坚硬能量结晶") ..
        "，" ..
        hcolor.jinglianglan("灰暗能量结晶") ..
        "，" ..
        hcolor.jinglianglan("防御能量结晶") ..
        "，" ..
        "提供|cff00ff002|r点热心玩家积分，每颗" ..
        hcolor.shishizi("尖锐能量结晶") ..
        "，" ..
        hcolor.shishizi("闪耀能量结晶") ..
        "，" ..
        hcolor.shishizi(
            "技巧能量结晶"
        ) ..
        "，" ..
        hcolor.shishizi(
            "精准能量结晶"
        ) ..
        "可以提供|cff00ff005|r点热心玩家积分，其它商城非积分物品也可以获得对应热心积分。"
    )
    table.insert(msg, "2.正义玩家（举报作弊，汇报bug）也可以获得热心玩家积分。每一层正义玩家等价于20点热心玩家积分。上限15层。")
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("当前积分：") .. hcolor.green(tostring(score)))
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("当前激活效果："))
    for level, v in ipairs(rexinwanjiajiangli) do
        if score >= v.score then
            local astr = hcolor.green(level .. "级（" .. tostring(v.score) .. "点积分）：")
            if v.attr ~= nil then
                astr = astr .. hcolor.green(description.attribute(v.attr, "，"))
            end
            if v.zuoqi ~= nil then
                local str = " 激活坐骑："
                for index, zuoqi in ipairs(v.zuoqi) do
                    if index ~= 1 then
                        str = str .. "，"
                    end
                    str = str .. ZHUANGBEI_PINZHI_DATA[zuoqi.pinzhi].color(zuoqi.name)
                end
                astr = astr .. hcolor.green(str)
            end
            if v.huanhua ~= nil then
                local str = " 激活幻化："
                for index, huanhua in ipairs(v.huanhua) do
                    if index ~= 1 then
                        str = str .. "，"
                    end
                    str = str .. ZHUANGBEI_PINZHI_DATA[huanhua.pinzhi].color(huanhua.name)
                end
                astr = astr .. hcolor.green(str)
            end
            table.insert(msg, astr)
        else
            local astr = hcolor.grey(level .. "级（需要" .. tostring(v.score) .. "点积分）：")
            if v.attr ~= nil then
                astr = astr .. hcolor.grey(description.attribute(v.attr, "，"))
            end
            if v.zuoqi ~= nil then
                local str = " 激活坐骑："
                for index, zuoqi in ipairs(v.zuoqi) do
                    if index ~= 1 then
                        str = str .. "，"
                    end
                    str = str .. ZHUANGBEI_PINZHI_DATA[zuoqi.pinzhi].color(zuoqi.name)
                end
                astr = astr .. hcolor.grey(str)
            end
            if v.huanhua ~= nil then
                local str = " 激活幻化："
                for index, huanhua in ipairs(v.huanhua) do
                    if index ~= 1 then
                        str = str .. "，"
                    end
                    str = str .. ZHUANGBEI_PINZHI_DATA[huanhua.pinzhi].color(huanhua.name)
                end
                astr = astr .. hcolor.grey(str)
            end
            table.insert(msg, astr)
            hcache.set(whichPlayer, "REXINWANJIA_MIAOSHU", string.implode("|n", msg))
            return
        end
    end
    hcache.set(whichPlayer, "REXINWANJIA_MIAOSHU", string.implode("|n", msg))
    htianfu.updateTianfuInstructions(whichPlayer)
end

function hplayer.loadChongwutanxian(whichPlayer)
    local chongwutanxianjiangli = {
        {
            score = 10,
            attr = _attr({ exp_ratio = "+1" })
        },
        {
            score = 20,
            attr = _attr({ gold_ratio = "+1" })
        },
        {
            score = 30,
            attr = _attr({ exp_ratio = "+2" })
        },
        {
            score = 50,
            attr = _attr({ gold_ratio = "+2" }),
        },
        {
            score = 70,
            attr = _attr({ life_back = "+10" }),
        },
        {
            score = 90,
            attr = _attr({ zhushuxing = "+20" }),
        },
        {
            score = 120,
            attr = _attr({ exp_ratio = "+3" }),
        },
        {
            score = 150,
            attr = _attr({ gold_ratio = "+3" }),
        },
        {
            score = 180,
            attr = _attr({ yaoshui_shijian = "+10" }),
        },
        {
            score = 220,
            attr = _attr({ exp_ratio = "+4" }),
        },
        {
            score = 260,
            attr = _attr({ gold_ratio = "+4" }),
        },
        {
            score = 300,
            attr = _attr({ caiji_speed = "+100", dianfeng_jingyan_ratio = "+5", lansecitiao_rate = "+2" }),
            zuoqi = { { pinzhi = ZHUANGBEI_PINZHI.SHISHI, name = "恶魔猎犬" } }
        },
        {
            score = 340,
            attr = _attr({ exp_ratio = "+5" }),
        },
        {
            score = 390,
            attr = _attr({ gold_ratio = "+5" }),

        },
        {
            score = 440,
            attr = _attr({ caiji_speed = "+10" }),

        },
        {
            score = 490,
            attr = _attr({ wu_bao = "+0.2", fa_bao = "+0.2" }),
        },
        {
            score = 550,
            attr = _attr({ zaisheng_speed = "+5" }),
        },
        {
            score = 610,
            attr = _attr({ extra_drop_rate = "+1" }),
            zuoqi = { { pinzhi = ZHUANGBEI_PINZHI.CHUANQI, name = "小戈隆" } }
        },
    }

    local cwtxhz                = hjapi.DzAPI_Map_GetMallItemCount(whichPlayer, "CWTXHZ")
    local mainHero              = hplayer.getMainHero(whichPlayer)
    for _, v in ipairs(chongwutanxianjiangli) do
        if cwtxhz >= v.score then
            if v.attr ~= nil then
                hattr.set(mainHero, 0, v.attr)
            end
            if v.zuoqi ~= nil then
                for _, zuoqi in ipairs(v.zuoqi) do
                    hzuoqi.jihuozuoqi(zuoqi.name, whichPlayer, false)
                end
            end
            if v.huanhua ~= nil then
                for _, huanhua in ipairs(v.huanhua) do
                    hhuanhua.jihuohuanhua(huanhua.name, whichPlayer, false)
                end
            end
        end
    end

    local msg = {}
    table.insert(msg, "通过宠物探险来获得宠物探险徽章：")
    table.insert(msg, hcolor.yellow("当前徽章：") .. hcolor.green(tostring(cwtxhz)))
    table.insert(msg, "")
    table.insert(msg, hcolor.yellow("当前激活效果："))
    for level, v in ipairs(chongwutanxianjiangli) do
        if cwtxhz >= v.score then
            local astr = hcolor.green(tostring(v.score) .. "个徽章：")
            if v.attr ~= nil then
                astr = astr .. hcolor.green(description.attribute(v.attr, "，"))
            end
            if v.zuoqi ~= nil then
                local str = " 激活坐骑："
                for index, zuoqi in ipairs(v.zuoqi) do
                    if index ~= 1 then
                        str = str .. "，"
                    end
                    str = str .. ZHUANGBEI_PINZHI_DATA[zuoqi.pinzhi].color(zuoqi.name)
                end
                astr = astr .. hcolor.green(str)
            end
            if v.huanhua ~= nil then
                local str = " 激活幻化："
                for index, huanhua in ipairs(v.huanhua) do
                    if index ~= 1 then
                        str = str .. "，"
                    end
                    str = str .. ZHUANGBEI_PINZHI_DATA[huanhua.pinzhi].color(huanhua.name)
                end
                astr = astr .. hcolor.green(str)
            end
            table.insert(msg, astr)
        else
            local astr = hcolor.grey(tostring(v.score) .. "个徽章：")
            if v.attr ~= nil then
                astr = astr .. hcolor.grey(description.attribute(v.attr, "，"))
            end
            if v.zuoqi ~= nil then
                local str = " 激活坐骑："
                for index, zuoqi in ipairs(v.zuoqi) do
                    if index ~= 1 then
                        str = str .. "，"
                    end
                    str = str .. ZHUANGBEI_PINZHI_DATA[zuoqi.pinzhi].color(zuoqi.name)
                end
                astr = astr .. hcolor.grey(str)
            end
            if v.huanhua ~= nil then
                local str = " 激活幻化："
                for index, huanhua in ipairs(v.huanhua) do
                    if index ~= 1 then
                        str = str .. "，"
                    end
                    str = str .. ZHUANGBEI_PINZHI_DATA[huanhua.pinzhi].color(huanhua.name)
                end
                astr = astr .. hcolor.grey(str)
            end
            table.insert(msg, astr)
        end
    end
    hcache.set(whichPlayer, "CHONGWUTANXIAN_MIAOSHU", string.implode("|n", msg))
end

--- 设置玩家名称
---@param whichPlayer userdata
---@param name string
function hplayer.setName(whichPlayer, name)
    cj.SetPlayerName(whichPlayer, name)
    hcache.set(whichPlayer, CONST_CACHE.PLAYER_NAME, name)
end

--- 获取玩家当前选中的单位
---@param whichPlayer userdata
---@return userdata unit
function hplayer.getSelection(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_SELECTION, nil)
end

--- 获取玩家当前状态
---@param whichPlayer userdata
---@return string
function hplayer.getStatus(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_STATUS, hplayer.player_status.none)
end

--- 设置玩家当前状态
---@param whichPlayer userdata
---@param status string
function hplayer.setStatus(whichPlayer, status)
    hcache.set(whichPlayer, CONST_CACHE.PLAYER_STATUS, status)
end

--- 获取玩家当前称号
---@param whichPlayer userdata
---@return string
function hplayer.getPrestige(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_PRESTIGE, " - ")
end

--- 设置玩家当前称号
---@param whichPlayer userdata
---@param prestige string
---@return void
function hplayer.setPrestige(whichPlayer, prestige)
    hcache.set(whichPlayer, CONST_CACHE.PLAYER_PRESTIGE, prestige)
end

--- 获取玩家APM
---@param whichPlayer userdata
---@return number
function hplayer.getApm(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_APM, 0)
end

--- 在所有玩家里获取一个随机的英雄
---@return userdata
function hplayer.getRandomHero()
    local pi = {}
    for k, v in ipairs(hplayer.players) do
        if (hplayer.setStatus(v) == hplayer.status.gaming) then
            table.insert(pi, k)
        end
    end
    if (#pi <= 0) then
        return nil
    end
    local ri = math.random(1, #pi)
    return hhero.getPlayerUnit(
        hplayer.players[pi[ri]],
        math.random(1, hhero.getPlayerAllowQty(hplayer.players[pi[ri]]))
    )
end

--- 令玩家单位全部隐藏
---@param whichPlayer userdata
function hplayer.hideUnit(whichPlayer)
    if (whichPlayer == nil) then
        return
    end
    local g =
        hgroup.createByRect(
            hrect.world(),
            function(filterUnit)
                return hunit.getOwner(filterUnit) == whichPlayer
            end
        )
    hgroup.forEach(
        g,
        function(enumUnit)
            cj.ShowUnit(enumUnit, false)
        end
    )
    g = nil
end

--- 令玩家单位全部删除
---@param whichPlayer userdata
function hplayer.clearUnit(whichPlayer)
    if (whichPlayer == nil) then
        return
    end
    local g =
        hgroup.createByRect(
            hrect.world(),
            function(filterUnit)
                return hunit.getOwner(filterUnit) == whichPlayer
            end
        )
    hgroup.clear(g, true)
end

--- 令玩家失败并退出
---@param whichPlayer userdata
---@param tips string
function hplayer.defeat(whichPlayer, tips)
    if (whichPlayer == nil) then
        return
    end
    if (tips == "" or tips == nil) then
        tips = "失败"
    end
    hplayer.clearUnit(whichPlayer)
    cj.RemovePlayer(whichPlayer, PLAYER_GAME_RESULT_DEFEAT)
    if hplayer.qty_current > 1 then
        cj.DisplayTimedTextFromPlayer(whichPlayer, 0, 0, 60, cj.GetLocalizedString("PLAYER_DEFEATED"))
    end
    if (cj.GetPlayerController(whichPlayer) == MAP_CONTROL_USER) then
        hdialog.create(
            whichPlayer,
            {
                title = tips,
                buttons = { { value = "Q", label = cj.GetLocalizedString("GAMEOVER_QUIT_MISSION") } }
            },
            function()
                if (whichPlayer == hplayer.loc()) then
                    cj.EndGame(true)
                end
            end
        )
    end
end

--- 令玩家胜利并退出
---@param whichPlayer userdata
---@param tips string
function hplayer.victory(whichPlayer, tips)
    if (whichPlayer == nil) then
        return
    end
    if (tips == "" or tips == nil) then
        tips = "胜利"
    end
    cj.RemovePlayer(whichPlayer, PLAYER_GAME_RESULT_VICTORY)
    if hplayer.qty_current > 1 then
        cj.DisplayTimedTextFromPlayer(whichPlayer, 0, 0, 60, cj.GetLocalizedString("PLAYER_VICTORIOUS"))
    end
    if (cj.GetPlayerController(whichPlayer) == MAP_CONTROL_USER) then
        JassGlobals.bj_changeLevelShowScores = true
        hdialog.create(
            whichPlayer,
            {
                title = tips,
                buttons = { { value = "Q", label = cj.GetLocalizedString("GAMEOVER_QUIT_MISSION") } }
            },
            function()
                if (whichPlayer == hplayer.loc()) then
                    cj.EndGame(true)
                end
            end
        )
    end
end

--- 设置玩家镜头摇晃判断
---@protected
---@param whichPlayer userdata
---@param b boolean
function hplayer.setCameraShaking(whichPlayer, n)
    local ing = hcache.get(whichPlayer, CONST_CACHE.PLAYER_IS_CAMERA_SHAKING, 0)
    hcache.set(whichPlayer, CONST_CACHE.PLAYER_IS_CAMERA_SHAKING, ing + n)
end

--- 获取玩家镜头是否在摇晃
---@param whichPlayer userdata
---@return boolean
function hplayer.isCameraShaking(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_IS_CAMERA_SHAKING, 0) > 0
end

--- 设置玩家镜头震动判断
---@protected
---@param whichPlayer userdata
---@param b boolean
function hplayer.setCameraQuaking(whichPlayer, n)
    local ing = hcache.get(whichPlayer, CONST_CACHE.PLAYER_IS_CAMERA_QUAKING, 0)
    hcache.set(whichPlayer, CONST_CACHE.PLAYER_IS_CAMERA_QUAKING, ing + n)
end

--- 获取玩家镜头是否在震动
---@param whichPlayer userdata
---@return boolean
function hplayer.isCameraQuaking(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_IS_CAMERA_QUAKING, 0) > 0
end

--- 获取玩家造成的总伤害
---@param whichPlayer userdata
---@return number
function hplayer.getDamage(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_DAMAGE, 0)
end

--- 增加玩家造成的总伤害
---@param whichPlayer userdata
---@param val number
function hplayer.addDamage(whichPlayer, val)
    if (whichPlayer == nil) then
        return
    end
    val = val or 0
    hcache.set(whichPlayer, CONST_CACHE.PLAYER_DAMAGE, hplayer.getDamage(whichPlayer) + val)
end

--- 获取玩家受到的总伤害
---@param whichPlayer userdata
---@return number
function hplayer.getBeDamage(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_BE_DAMAGE, 0)
end

--- 增加玩家受到的总伤害
---@param whichPlayer userdata
---@param val number
function hplayer.addBeDamage(whichPlayer, val)
    if (whichPlayer == nil) then
        return
    end
    val = val or 0
    hcache.set(whichPlayer, CONST_CACHE.PLAYER_BE_DAMAGE, hplayer.getBeDamage(whichPlayer) + val)
end

--- 获取玩家杀敌数
---@param whichPlayer userdata
---@return number
function hplayer.getKill(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_KILL, 0)
end

-- 增加玩家杀敌数
---@param whichPlayer userdata
---@param val number
function hplayer.addKill(whichPlayer, val)
    if (whichPlayer == nil) then
        return
    end
    val = val or 1
    hcache.set(whichPlayer, CONST_CACHE.PLAYER_KILL, hplayer.getKill(whichPlayer) + val)
end

--- 黄金比率
---@private
function hplayer.diffGoldRatio(whichPlayer, diff, during)
    if (diff ~= 0) then
        during = during or 0
        hcache.set(
            whichPlayer,
            CONST_CACHE.PLAYER_GOLD_RATIO,
            hcache.get(whichPlayer, CONST_CACHE.PLAYER_GOLD_RATIO) + diff
        )
        if (during > 0) then
            htime.setTimeout(
                during,
                function(t)
                    t.destroy()
                    hcache.set(
                        whichPlayer,
                        CONST_CACHE.PLAYER_GOLD_RATIO,
                        hcache.get(whichPlayer, CONST_CACHE.PLAYER_GOLD_RATIO) - diff
                    )
                end
            )
        end
    end
end

---@param whichPlayer userdata
---@param val number
---@param during number
function hplayer.setGoldRatio(whichPlayer, val, during)
    hplayer.diffGoldRatio(whichPlayer, val - hcache.get(whichPlayer, CONST_CACHE.PLAYER_GOLD_RATIO), during)
end

---@param whichPlayer userdata
---@param val number
---@param during number
function hplayer.addGoldRatio(whichPlayer, val, during)
    hplayer.diffGoldRatio(whichPlayer, val, during)
end

---@param whichPlayer userdata
---@param val number
---@param during number
function hplayer.subGoldRatio(whichPlayer, val, during)
    hplayer.diffGoldRatio(whichPlayer, -val, during)
end

---@param whichPlayer userdata
---@return number
function hplayer.getGoldRatio(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_GOLD_RATIO) or 100
end

--- 木头比率
---@private
function hplayer.diffLumberRatio(whichPlayer, diff, during)
    if (diff ~= 0) then
        during = during or 0
        hcache.set(
            whichPlayer,
            CONST_CACHE.PLAYER_LUMBER_RATIO,
            hcache.get(whichPlayer, CONST_CACHE.PLAYER_LUMBER_RATIO) + diff
        )
        if (during > 0) then
            htime.setTimeout(
                during,
                function(t)
                    t.destroy()
                    hcache.set(
                        whichPlayer,
                        CONST_CACHE.PLAYER_LUMBER_RATIO,
                        hcache.get(whichPlayer, CONST_CACHE.PLAYER_LUMBER_RATIO) - diff
                    )
                end
            )
        end
    end
end

---@param whichPlayer userdata
---@param val number
---@param during number
function hplayer.setLumberRatio(whichPlayer, val, during)
    hplayer.diffLumberRatio(whichPlayer, val - hcache.get(whichPlayer, CONST_CACHE.PLAYER_LUMBER_RATIO), during)
end

---@param whichPlayer userdata
---@param val number
---@param during number
function hplayer.addLumberRatio(whichPlayer, val, during)
    hplayer.diffLumberRatio(whichPlayer, val, during)
end

---@param whichPlayer userdata
---@param val number
---@param during number
function hplayer.subLumberRatio(whichPlayer, val, during)
    hplayer.diffLumberRatio(whichPlayer, -val, during)
end

---@param whichPlayer userdata
---@return number
function hplayer.getLumberRatio(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_LUMBER_RATIO)
end

--- 经验比率
---@private
function hplayer.diffExpRatio(whichPlayer, diff, during)
    if (diff ~= 0) then
        during = during or 0
        hcache.set(
            whichPlayer,
            CONST_CACHE.PLAYER_EXP_RATIO,
            hcache.get(whichPlayer, CONST_CACHE.PLAYER_EXP_RATIO) + diff
        )
        if (during > 0) then
            htime.setTimeout(
                during,
                function(t)
                    t.destroy()
                    hcache.set(
                        whichPlayer,
                        CONST_CACHE.PLAYER_EXP_RATIO,
                        hcache.get(whichPlayer, CONST_CACHE.PLAYER_EXP_RATIO) - diff
                    )
                end
            )
        end
    end
end

---@param whichPlayer userdata
---@param val number
---@param during number
function hplayer.setExpRatio(whichPlayer, val, during)
    hplayer.diffExpRatio(whichPlayer, val - hcache.get(whichPlayer, CONST_CACHE.PLAYER_EXP_RATIO), during)
end

---@param whichPlayer userdata
---@param val number
---@param during number
function hplayer.addExpRatio(whichPlayer, val, during)
    hplayer.diffExpRatio(whichPlayer, val, during)
end

---@param whichPlayer userdata
---@param val number
---@param during number
function hplayer.subExpRatio(whichPlayer, val, during)
    hplayer.diffExpRatio(whichPlayer, -val, during)
end

---@param whichPlayer userdata
---@return number
function hplayer.getExpRatio(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_EXP_RATIO)
end

--- 售卖比率
---@private
function hplayer.diffSellRatio(whichPlayer, diff, during)
    if (diff ~= 0) then
        hcache.set(
            whichPlayer,
            CONST_CACHE.PLAYER_SELL_RATIO,
            hcache.get(whichPlayer, CONST_CACHE.PLAYER_SELL_RATIO) + diff
        )
        if (during > 0) then
            htime.setTimeout(
                during,
                function(t)
                    t.destroy()
                    hcache.set(
                        whichPlayer,
                        CONST_CACHE.PLAYER_SELL_RATIO,
                        hcache.get(whichPlayer, CONST_CACHE.PLAYER_SELL_RATIO) - diff
                    )
                end
            )
        end
    end
end

---@param whichPlayer userdata
---@param val number
---@param during number
function hplayer.setSellRatio(whichPlayer, val, during)
    hplayer.diffSellRatio(whichPlayer, val - hcache.get(whichPlayer, CONST_CACHE.PLAYER_SELL_RATIO), during)
end

---@param whichPlayer userdata
---@param val number
---@param during number
function hplayer.addSellRatio(whichPlayer, val, during)
    hplayer.diffSellRatio(whichPlayer, val, during)
end

---@param whichPlayer userdata
---@param val number
---@param during number
function hplayer.subSellRatio(whichPlayer, val, during)
    hplayer.diffSellRatio(whichPlayer, -val, during)
end

---@param whichPlayer userdata
---@return number
function hplayer.getSellRatio(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_SELL_RATIO, 50)
end

--- 玩家总获金量
---@param whichPlayer userdata
---@return number
function hplayer.getTotalGold(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_GOLD_TOTAL)
end

---@param whichPlayer userdata
---@param val number
function hplayer.addTotalGold(whichPlayer, val)
    return hcache.set(whichPlayer, CONST_CACHE.PLAYER_GOLD_TOTAL, hplayer.getTotalGold(whichPlayer) + val)
end

--- 玩家总耗金量
---@param whichPlayer userdata
---@return number
function hplayer.getTotalGoldCost(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_GOLD_COST)
end

---@param whichPlayer userdata
---@param val number
function hplayer.addTotalGoldCost(whichPlayer, val)
    return hcache.set(whichPlayer, CONST_CACHE.PLAYER_GOLD_COST, hplayer.getTotalGoldCost(whichPlayer) + val)
end

--- 玩家总获木量
---@param whichPlayer userdata
---@return number
function hplayer.getTotalLumber(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_LUMBER_TOTAL)
end

---@param whichPlayer userdata
---@param val number
function hplayer.addTotalLumber(whichPlayer, val)
    return hcache.set(whichPlayer, CONST_CACHE.PLAYER_LUMBER_TOTAL, hplayer.getTotalLumber(whichPlayer) + val)
end

--- 玩家总耗木量
---@param whichPlayer userdata
---@return number
function hplayer.getTotalLumberCost(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.PLAYER_LUMBER_COST)
end

---@param whichPlayer userdata
---@param val number
function hplayer.addTotalLumberCost(whichPlayer, val)
    return hcache.set(whichPlayer, CONST_CACHE.PLAYER_LUMBER_COST, hplayer.getTotalLumberCost(whichPlayer) + val)
end

--- 核算玩家金钱
---@private
function hplayer.adjustGold(whichPlayer)
    local prvSys = hcache.get(whichPlayer, CONST_CACHE.PLAYER_GOLD_PREV)
    local relSys = cj.GetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_GOLD)
    if (prvSys ~= nil) then
        if (prvSys > relSys) then
            hplayer.addTotalGoldCost(whichPlayer, prvSys - relSys)
        elseif (prvSys < relSys) then
            hplayer.addTotalGold(whichPlayer, relSys - prvSys)
        end
    end
    hcache.set(whichPlayer, CONST_CACHE.PLAYER_GOLD_PREV, relSys)
end

--- 核算玩家木头
---@private
function hplayer.adjustLumber(whichPlayer)
    local prvSys = hcache.get(whichPlayer, CONST_CACHE.PLAYER_LUMBER_PREV)
    local relSys = cj.GetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_LUMBER)
    if (prvSys ~= nil) then
        if (prvSys > relSys) then
            hplayer.addTotalLumberCost(whichPlayer, prvSys - relSys)
        elseif (prvSys < relSys) then
            hplayer.addTotalLumber(whichPlayer, relSys - prvSys)
        end
    end
    hcache.set(whichPlayer, CONST_CACHE.PLAYER_LUMBER_PREV, relSys)
end

--- 获取玩家实时金钱
---@param whichPlayer userdata
---@return number
function hplayer.getGold(whichPlayer)
    return cj.GetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_GOLD)
end

--- 设置玩家实时金钱
---@param whichPlayer userdata
---@param gold number
---@param u userdata|nil 可设置一个单位用于事件回调
---@param showEffect bool 是否显示特效
function hplayer.setGold(whichPlayer, gold, u, showEffect)
    if (whichPlayer == nil) then
        return
    end
    -- 触发英雄资源变动
    hevent.trigger(
        "global",
        CONST_EVENT.playerResourceChange,
        {
            triggerPlayer = whichPlayer,
            triggerUnit = u,
            type = "gold",
            value = gold - hplayer.getGold(whichPlayer),
            showEffect = showEffect
        }
    )
    local max = 1000000
    if (gold > max) then
        gold = max
    end
    hplayer.setPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_GOLD, gold)
    hplayer.adjustGold(whichPlayer)
end

--- 增加玩家金钱
---@param whichPlayer userdata
---@param gold number
---@param u userdata|nil 可设置一个单位用于事件回调
function hplayer.addGold(whichPlayer, gold, u)
    if (whichPlayer == nil) then
        return
    end
    gold = math.ceil(gold * hplayer.getGoldRatio(whichPlayer) / 100)
    hplayer.setGold(whichPlayer, hplayer.getGold(whichPlayer) + gold, u)
end

--- 减少玩家金钱
---@param whichPlayer userdata
---@param gold number
---@param u userdata|nil 可设置一个单位用于事件回调
function hplayer.subGold(whichPlayer, gold, u)
    if (whichPlayer == nil) then
        return
    end
    hplayer.setGold(whichPlayer, hplayer.getGold(whichPlayer) - gold, u)
end

--- 获取玩家实时木头
---@param whichPlayer userdata
---@return number
function hplayer.getLumber(whichPlayer)
    return cj.GetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_LUMBER)
end

--- 设置玩家实时木头
---@param whichPlayer userdata
---@param lumber number
---@param u userdata|nil 可设置一个单位用于事件回调
function hplayer.setLumber(whichPlayer, lumber, u, showEffect)
    if (whichPlayer == nil) then
        return
    end
    -- 触发英雄资源变动
    hevent.trigger(
        "global",
        CONST_EVENT.playerResourceChange,
        {
            triggerPlayer = whichPlayer,
            triggerUnit = u,
            type = "lumber",
            value = lumber - hplayer.getLumber(whichPlayer),
            showEffect = showEffect
        }
    )
    hplayer.setPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_LUMBER, lumber)
    hplayer.adjustLumber(whichPlayer)
end

--- 增加玩家木头
---@param whichPlayer userdata
---@param lumber number
---@param u userdata|nil 可设置一个单位用于事件回调
function hplayer.addLumber(whichPlayer, lumber, u)
    if (whichPlayer == nil) then
        return
    end
    lumber = math.ceil(lumber * hplayer.getLumberRatio(whichPlayer) / 100)
    hplayer.setLumber(whichPlayer, hplayer.getLumber(whichPlayer) + lumber, u)
end

--- 减少玩家木头
---@param whichPlayer userdata
---@param lumber number
---@param u userdata|nil 可设置一个单位用于事件回调
function hplayer.subLumber(whichPlayer, lumber, u)
    if (whichPlayer == nil) then
        return
    end
    hplayer.setLumber(whichPlayer, hplayer.getLumber(whichPlayer) - lumber, u)
end

--- 获取玩家已使用人口数
---@param whichPlayer userdata
---@return number
function hplayer.getFoodUsed(whichPlayer)
    return cj.GetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_FOOD_USED)
end

--- 设置玩家已使用人口数
---@param whichPlayer userdata
---@param value number integer
function hplayer.setFoodUsed(whichPlayer, value)
    hplayer.setPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_FOOD_USED, math.floor(value))
end

--- 获取玩家可用人口数
---@param whichPlayer userdata
---@return number
function hplayer.getFoodCap(whichPlayer)
    return cj.GetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_FOOD_CAP)
end

--- 设置玩家可用人口数
---@param whichPlayer userdata
---@param value number integer
function hplayer.setFoodCap(whichPlayer, value)
    hplayer.setPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_FOOD_CAP, math.floor(value))
end

--- 获取玩家最大人口上限
---@param whichPlayer userdata
---@return number
function hplayer.getFoodCapCeiling(whichPlayer)
    return cj.GetPlayerState(whichPlayer, PLAYER_STATE_FOOD_CAP_CEILING)
end

--- 设置玩家最大人口上限
---@param whichPlayer userdata
---@param value number integer
function hplayer.setFoodCapCeiling(whichPlayer, value)
    hplayer.setPlayerState(whichPlayer, PLAYER_STATE_FOOD_CAP_CEILING, math.floor(value))
end

--- 初始化玩家数据，包括 装备背包等
function hplayer.init_from_cundang(whichPlayer)
    if whichPlayer == nil then
        return
    end
    echo("装载商城...", whichPlayer)
    hshangcheng.initPlayer(whichPlayer)
    echo("装载商城完成", whichPlayer)
    hplayer.loadRexinwanjia(whichPlayer)
    hplayer.loadChongwutanxian(whichPlayer)
    echo("装载日常...", whichPlayer)
    hquestcustom.updateDailyQuest(whichPlayer)
    echo("装载日常完成", whichPlayer)
    echo("装载成就...", whichPlayer)
    hchengjiu.loadcundang(whichPlayer)
    echo("装载成就完成", whichPlayer)
    echo("装载资源...", whichPlayer)
    hresource.loadCunDang(whichPlayer)
    echo("装载资源完毕", whichPlayer)
    echo("装载坐骑...", whichPlayer)
    hzuoqi.initPlayer(whichPlayer)
    echo("装载坐骑完毕", whichPlayer)
    echo("装载装备...", whichPlayer)
    hplayer.dzCunDang[whichPlayer].initEquipmentAttrTrigger()
    for v = 1, NUM_EQUIPMENT_SLOT do
        local dynamicItem = hplayer.dzCunDang[whichPlayer].initAndGetEquipmentForSlot(v)
        if dynamicItem ~= nil then
            --设置UI
            if (whichPlayer == hplayer.loc()) then
                hjapi.DzFrameSetTexture(
                    hjapi.DzFrameFindByName("BGZ" .. v .. "UP", 0),
                    hitem.getArt(dynamicItem.basic_item_id),
                    0
                )
            end
        end
    end
    echo("装载装备完成", whichPlayer)
    echo("装载幻化...", whichPlayer)
    hhuanhua.initPlayer(whichPlayer)
    echo("装载幻化完毕", whichPlayer)
    echo("装载大背包...", whichPlayer)
    hplayer.dzCunDang[whichPlayer].initInventoryCundang()
    echo("装载大背包完成", whichPlayer)
    echo("装载英雄背包...", whichPlayer)
    hplayer.dzCunDang[whichPlayer].initHeroBagFromCundangGetSetupTriggerForBag()
    echo("装载英雄背包完成", whichPlayer)
    echo("装载任务进度...", whichPlayer)
    hquestcustom.loadcundang(whichPlayer)
    echo("装载任务完成", whichPlayer)
    echo("装载图鉴...", whichPlayer)
    htujian.initTujianForUser(whichPlayer)
    echo("装载图鉴完成", whichPlayer)
    echo("装载训练...", whichPlayer)
    hxunlian.loadcundang(whichPlayer)
    echo("装载训练完成", whichPlayer)
    echo("装载专业...", whichPlayer)
    hzhuanye.loadcundang(whichPlayer)
    echo("装载专业完成", whichPlayer)
    echo("装载炼金...", whichPlayer)
    hlianjin.initPlayer(whichPlayer)
    echo("装载炼金完成", whichPlayer)
    echo("装载钓鱼...", whichPlayer)
    hdiaoyu.loadcundang(whichPlayer)
    echo("装载钓鱼完成", whichPlayer)
    echo("装载声望...", whichPlayer)
    hshengwang.loadcundang(whichPlayer)
    echo("装载声望完成", whichPlayer)
    echo("装载地图等级...", whichPlayer)
    hditudengji.init_user(whichPlayer)
    echo("装载地图等级完成", whichPlayer)
    echo("装载铭文...", whichPlayer)
    hmingwen.initPlayer(whichPlayer)
    echo("装载铭文完成", whichPlayer)
    echo("装载装备收集...", whichPlayer)
    hzhuangbeishouji.initShoujiForUser(whichPlayer)
    echo("装载装备收集完成", whichPlayer)
    echo("装载巅峰天赋...", whichPlayer)
    htianfu.initPlayer(whichPlayer)
    echo("装载巅峰天赋完成", whichPlayer)
    echo("装载秘境...", whichPlayer)
    hmijing.initPlayer(whichPlayer)
    echo("装载秘境完成", whichPlayer)
    echo("装载符文...", whichPlayer)
    hfuwen.initPlayer(whichPlayer)
    echo("装载符文完成", whichPlayer)
    echo("装载其它...", whichPlayer)
    hbuchangma.initPlayer(whichPlayer)
    echo("装载其它完成", whichPlayer)
    echo("装载神器之魂...", whichPlayer)
    hartifact.initPlayerArtifact(whichPlayer)
    echo("装载神器之魂完成", whichPlayer)

    --hdzcundang.setup_cundang_validator(whichPlayer)
end

--- 尝试穿装备附加单位装备物品后的属性
---@param whichPlayer userdata
---@param it userdata
---@return void
function hplayer.equipItem(whichPlayer, it)
    if whichPlayer == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if (hero == nil or it == nil) then
        return
    end
    local newDynamicItem = hitem.getDynamicItem(it)
    if newDynamicItem == nil then
        echo("物品装备失败，无法找到目标", whichPlayer)
        return
    end
    if newDynamicItem.getOwner() ~= nil and newDynamicItem.getOwner() ~= whichPlayer then
        echo("该物品不属于你", whichPlayer)
        return
    end
    local equipmentSlot = hhero.checkEquipmentableAndReturnSlot(hero, newDynamicItem)
    if equipmentSlot == nil or equipmentSlot == false then
        echo("该英雄无法穿戴这件装备", whichPlayer)
        return
    end
    local heroLevel = hunit.getLevel(hero)
    local zhuangbeiLevel = newDynamicItem.level
    if zhuangbeiLevel ~= nil and heroLevel ~= nil and zhuangbeiLevel - 5 > heroLevel then
        echo("英雄等级不足以穿戴该装备，需要最低" .. tostring(zhuangbeiLevel - 5) .. "级", whichPlayer)
        return
    end
    local ditudengji = hditudengji.getDitudengji(whichPlayer)
    local requiredLevel =
        ITEM_LEVEL_TO_EQUIP_REQ_DITULEVEL[newDynamicItem.level] +
        ITEM_NANDU_TO_EQUIP_REQ_DITULEVEL[newDynamicItem.level][newDynamicItem.nandu]
    if ditudengji ~= nil and ditudengji < requiredLevel then
        echo("地图等级不足以穿戴该装备，需要最低" .. tostring(requiredLevel) .. "级, 当前：" .. ditudengji .. "级", whichPlayer)
        return
    end
    local equipped_item = hplayer.dzCunDang[whichPlayer].getEquipment(equipmentSlot)
    if equipped_item ~= nil then
        hitem.create(
            {
                id = equipped_item.basic_item_id,
                whichUnit = hero,
                dynamicItem = equipped_item
            }
        )
    end
    newDynamicItem.setOwner(whichPlayer)
    hitem.destroy(it)
    hplayer.dzCunDang[whichPlayer].setEquipment(equipmentSlot, newDynamicItem)
end

--- 去掉装备
function hplayer.unEquipItem(whichPlayer, equipment_type)
    if whichPlayer == nil then
        return
    end
    local hero = hplayer.getMainHero(whichPlayer)
    if (hero == nil) then
        return
    end
    local equipped_item = hplayer.dzCunDang[whichPlayer].getEquipment(equipment_type)
    if equipped_item == nil then
        echo("尝试脱一个不存在的装备")
        return
    end
    hplayer.dzCunDang[whichPlayer].setEquipment(equipment_type, nil)
    hitem.create(
        {
            id = equipped_item.basic_item_id,
            whichUnit = hero,
            dynamicItem = equipped_item
        }
    )
end
