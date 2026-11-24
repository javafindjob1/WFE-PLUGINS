htips = {}

htips.init = function(tips)
    htips.tips = tips or {}
end

htips.showNextTip = function()
    if #(htips.tips) > 0 then
        echo(hcolor.yellow("游戏提示：") .. htips.tips[math.random(1, #(htips.tips))], nil, 20)
    end
end

htips.showTips = function(interval)
    local finalInterval = interval or 300
    htime.setInterval(
        finalInterval,
        function(curTimer)
            htips.showNextTip()
        end
    )
end
