local us = require("lib.moses")
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
    local shogi = require("lib.shogi").new({random = random, mapId = level.map})
    shogi:setDeck(level.friend.deck)
    shogi.party = {red = {}, blue = {}}
    shogi:commitForm({
        red = level2form_(shogi, level.friend.chara, "red"),
        blue = level2form_(shogi, level.enemy.chara, "blue")
    })
    return shogi
end

return Solver

