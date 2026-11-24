require 'h-lua-console'
require 'const.abilityTarget'
require 'const.attribute'
require 'const.cache'
require 'const.damageSource'
require 'const.event'
require 'const.hero'
require 'const.hotKey'
require 'const.item'
require 'const.keyboard'
require 'const.monitor'
require 'const.orderStr'
require 'const.target'
require 'const.unit'
require 'foundation.array'
require 'foundation.cache'
require 'foundation.color'
require 'foundation.damaging'
require 'foundation.description'
require 'foundation.math'
require 'foundation.mbstring'
require 'foundation.string'
require 'foundation.table'
require 'h-lua-slk.pilot'
require 'h-lua-slk.setter'
require 'h-lua-slk.slk'
require 'h-lua-slk.system'
require 'project-slk.aofa'
require 'project-slk.chengjieqi'
require 'project-slk.emolieshou'
require 'project-slk.fashi'
require 'project-slk.huimieshu'
require 'project-slk.items'
require 'project-slk.kuangbaozhan'
require 'project-slk.lichking'
require 'project-slk.npc'
require 'project-slk.shejilie'
require 'project-slk.skill'
require 'project-slk.tongkushu'
require 'project-slk.units'
require 'project-slk.wuqizhan'
require 'project-slk.xingchenfashi'
require 'project-slk.yewai'
require 'project-slk.zhandouzei'
require 'main'
if (cj ~= nil) then
    local t = cj.CreateTrigger()
    cj.TriggerRegisterTimerEvent(t, 0.1, false)
    cj.TriggerAddAction(t, function()
        cj.DisableTrigger(t)
        cj.DestroyTrigger(t)
        t = nil
        if (type(main) == "function") then
            main()
        end
    end)
else
    if (type(main) == "function") then
        main()
    end
end
