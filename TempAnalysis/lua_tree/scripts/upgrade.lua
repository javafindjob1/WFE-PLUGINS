LEVEL_TO_TECH = {
    {5, 2},
    {10, 3},
    {15, 4},
    {20, 5},
    {25, 6},
    {30, 7},
    {35, 8},
    {40, 9},
    {45, 10},
    {50, 11},
    {53, 12},
    {56, 13},
    {58, 14},
    {60, 15},
    {70, 16}
}

hevent.reaction(
    CONST_EVENT.levelUp,
    "jineng",
    function(evtData)
        local whichUnit = evtData.triggerUnit
        local owner = hunit.getOwner(whichUnit)
        local lvl = hhero.getCurLevel(whichUnit)
        local maxTech = 0
        for _, v in ipairs(LEVEL_TO_TECH) do
            if lvl >= v[1] and maxTech < v[2] then
                maxTech = v[2]
            end
        end
        hplayer.setPlayerTechResearched(owner, c2i("R000"), maxTech)

        -- 技能常驻属性及光环
        if SKILL_ON_LEVEL_UP[hunit.getName(whichUnit)] ~= nil then
            SKILL_ON_LEVEL_UP[hunit.getName(whichUnit)](whichUnit)
        end
    end
)
