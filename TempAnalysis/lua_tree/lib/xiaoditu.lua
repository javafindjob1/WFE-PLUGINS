hxiaoditu = {}

hsync.onSend(
    "xiaoditumove",
    function(syncData)
        local hero = hplayer.getMainHero(syncData.triggerPlayer)
        if hero == nil then
            return
        end
        local x = tonumber(syncData.triggerData[1])
        local y = tonumber(syncData.triggerData[2])
        echo("自动寻路")
        cj.IssuePointOrder(hero, "move", x, y)
    end
)

hxiaoditu.addDitu = function(rect, blp, enterTitleTextBlp, enterTitleBackgroudBlp)
    if hxiaoditu.enterTitleTextFrame == nil or hxiaoditu.enterTitleBackgroud == nil then
        local bgFrame = hjapi.FrameTag("BACKDROP", "enterTitleBackgroud", hjapi.DzGetGameUI(), "")
        hjapi.DzFrameSetPoint(bgFrame, 4, hjapi.DzGetGameUI(), 4, 0, 0.22)
        hjapi.DzFrameSetSize(bgFrame, 0.20, 0.05)
        hjapi.DzFrameShow(bgFrame, false)
        hxiaoditu.enterTitleBackgroud = bgFrame

        local textFrame = hjapi.FrameTag("BACKDROP", "enterTitleTextFrame", hjapi.DzGetGameUI(), "")
        hjapi.DzFrameSetPoint(textFrame, 4, bgFrame, 4, 0, 0)
        hjapi.DzFrameSetSize(textFrame, 0.18, 0.05)
        hjapi.DzFrameShow(textFrame, false)
        hxiaoditu.enterTitleTextFrame = textFrame
    end

    if hxiaoditu[rect] == nil then
        local minX = hrect.getMinX(rect)
        local minY = hrect.getMinY(rect)
        local width = hrect.getWidth(rect)
        local height = hrect.getHeight(rect)
        local xstart, ystart, xcale, yscale, xiaodituWidth, xiaodituHeight
        local minMapWidth = 0.138
        local minMapHeight = 0.138
        if width > height then
            xstart = 0
            ystart = (width - height) / 2 / width * minMapHeight
            xcale = minMapWidth / width
            yscale = minMapHeight / width
            xiaodituWidth = minMapWidth
            xiaodituHeight = minMapHeight * (height / width)
        else
            xstart = (height - width) / 2 / height * minMapWidth
            ystart = 0
            xcale = minMapWidth / height
            yscale = minMapHeight / height
            xiaodituWidth = minMapWidth * (width / height)
            xiaodituHeight = minMapHeight
        end

        hxiaoditu[rect] = {
            infos = {},
            blp = blp,
            minX = minX,
            minY = minY,
            xstart = xstart,
            ystart = ystart,
            xscale = xcale,
            yscale = yscale,
            enterTitleTextBlp = enterTitleTextBlp,
            enterTitleBackgroudBlp = enterTitleBackgroudBlp,
            xiaodituWidth = xiaodituWidth,
            xiaodituHeight = xiaodituHeight
        }
    else
        err("hxiaoditu.addDitu: rect already exists")
    end
end

hxiaoditu.addInfoToDitu = function(tag, x, y, blp)
    local miniMap = hjapi.DzFrameGetMinimap()
    if hxiaoditu.infos == nil then
        hxiaoditu.infos = {}
    end

    local backdrop = hjapi.FrameTag("BACKDROP", "xiaoditu" .. #(hxiaoditu.infos), miniMap, "")
    hjapi.DzFrameSetPoint(backdrop, 4, miniMap, 0, 0, 0)
    hjapi.DzFrameSetSize(backdrop, 0.012, 0.016)
    hjapi.DzFrameSetTexture(backdrop, blp)
    hjapi.DzFrameShow(backdrop, false)

    --[[local button = hjapi.FrameTag("BUTTON", "xiaoditu_botton" .. #(hxiaoditu.infos), backdrop)
    hjapi.DzFrameSetPoint(button, 4, backdrop, 4, 0, 0)
    hjapi.DzFrameSetSize(button, 0.012, 0.016)
    hjapi.DzFrameShow(button, true)
    hjapi.DzFrameSetScriptByCode(
        button,
        MOUSE_ORDER_CLICK,
        function()
            hsync.send("xiaoditumove", {x, y})
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        button,
        MOUSE_ORDER_ENTER,
        function()
            local tip = tag
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            local tipsText = hjapi.DzFrameFindByName("ALL_Tips_Desc", 0)
            hjapi.DzFrameClearAllPoints(tipsText)
            hjapi.DzFrameSetSize(tipsText, 0.0800, 0)
            hjapi.DzFrameSetPoint(tipsText, 6, button, 2, 0, 0)
            hjapi.DzFrameSetText(tipsText, tip)
            hjapi.DzFrameShow(tipsBack, true)
        end,
        false
    )
    hjapi.DzFrameSetScriptByCode(
        button,
        MOUSE_ORDER_LEAVE,
        function()
            local tipsBack = hjapi.DzFrameFindByName("ALL_Tips", 0)
            hjapi.DzFrameShow(tipsBack, false)
        end,
        false
    )
    ]]
    table.insert(hxiaoditu.infos, {tag = tag, x = x, y = y, backdrop = backdrop})
end

hxiaoditu.showXiaoditu = function(rect, whichPlayer)
    if hxiaoditu[rect] == nil then
        err("hxiaoditu.addInfoToDitu: rect not exists")
        return
    end
    local miniMap = hjapi.DzFrameGetMinimap()
    local rectCofig = hxiaoditu[rect]

    htime.setTimeout(
        0.1,
        function()
            if whichPlayer == hplayer.loc() then
                hjapi.DzSetWar3MapMap(rectCofig.blp)
            end
        end
    )

    for _, info in ipairs(hxiaoditu.infos) do
        if whichPlayer == hplayer.loc() then
            if hrect.isInner(rect, info.x, info.y) then
                local x = info.x
                local y = info.y
                local finalX = rectCofig.xstart + (x - rectCofig.minX) * rectCofig.xscale
                local finalY = rectCofig.ystart + (y - rectCofig.minY) * rectCofig.yscale
                hjapi.DzFrameClearAllPoints(info.backdrop)
                hjapi.DzFrameSetPoint(info.backdrop, 4, miniMap, 6, finalX, finalY)
                hjapi.DzFrameShow(info.backdrop, true)
            else
                hjapi.DzFrameShow(info.backdrop, false)
            end
        end
    end

    local timer = hcache.get(whichPlayer, "xiaoditutitler")
    if timer ~= nil then
        timer.destroy()
    end
    if rectCofig.enterTitleBackgroudBlp == nil then
        return
    end
    hjapi.DzFrameSetTexture(hxiaoditu.enterTitleBackgroud, rectCofig.enterTitleBackgroudBlp)
    hjapi.DzFrameSetTexture(hxiaoditu.enterTitleTextFrame, rectCofig.enterTitleTextBlp)
    hjapi.DzFrameShow(hxiaoditu.enterTitleBackgroud, true)
    hjapi.DzFrameShow(hxiaoditu.enterTitleTextFrame, true)
    hcache.set(
        whichPlayer,
        "xiaoditutitler",
        htime.setInterval(
            0.02,
            function(curTimer)
                local tp = curTimer.passedSec()
                if tp > 6.5 then
                    if whichPlayer == hplayer.loc() then
                        hjapi.DzFrameShow(hxiaoditu.enterTitleBackgroud, false)
                        hjapi.DzFrameShow(hxiaoditu.enterTitleTextFrame, false)
                    end
                    curTimer.destroy()
                elseif tp <= 0.5 then
                    if whichPlayer == hplayer.loc() then
                        hjapi.DzFrameSetAlpha(hxiaoditu.enterTitleBackgroud, tp * 500)
                        hjapi.DzFrameSetAlpha(hxiaoditu.enterTitleTextFrame, tp * 500)
                    end
                elseif tp <= 3.5 then
                    if whichPlayer == hplayer.loc() then
                        hjapi.DzFrameSetAlpha(hxiaoditu.enterTitleBackgroud, 255)
                        hjapi.DzFrameSetAlpha(hxiaoditu.enterTitleTextFrame, 255)
                    end
                elseif tp <= 6.5 then
                    if whichPlayer == hplayer.loc() then
                        hjapi.DzFrameSetAlpha(hxiaoditu.enterTitleBackgroud, 255 - (tp - 3.5) * 85)
                        hjapi.DzFrameSetAlpha(hxiaoditu.enterTitleTextFrame, 255 - (tp - 3.5) * 85)
                    end
                end
            end
        )
    )
end
