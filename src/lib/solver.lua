local us = require("lib.moses")
local Shogi = require("lib.shogi")
local Solver = {}

local function level2form_(shogi, chara, team)
    local form = {}
    local master2party = {}
    for _, e in ipairs(chara) do
        if not master2party[e.id] then
            table.insert(shogi.party[team], us.findWhere(shogi.getCharaMaster(), {id = e.id}))
            master2party[e.id] = #shogi.party[team]
        end
        table.insert(form, string.format("%d,%d,%d", master2party[e.id], e.i, e.j))
    end
    return form
end

function Solver.level2shogi(random, level)
    local shogi = Shogi.new({random = random, mapId = level.map})
    shogi:setDeck(level.friend.deck)
    shogi.party = {red = {}, blue = {}}
    shogi:commitForm({
        red = level2form_(shogi, level.friend.chara, "red"),
        blue = level2form_(shogi, level.enemy.chara, "blue")
    })
    return shogi
end

function Solver.solve(shogi, charaId, chipIdx)
    local enemies = us.select(shogi.charas, function(_, e) return e.team == "blue" end)
    local chips = shogi:getChips("blue")
    local act2score = {}
    for i, chara in ipairs(enemies) do
        for j, chip in ipairs(chips) do
            local act = chara.id .. j
            local copy = us.clone(shogi)
            setmetatable(copy, {__index = Shogi})
            copy:processTurn({charaId .. chipIdx, act})
            act2score[act] = Solver.evalScore(copy)
        end
    end
    return act2score
end

function Solver.evalScore(shogi)
    return 1
end

return Solver

