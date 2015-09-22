local json = require("json")
local us = require("lib.moses")
local PuzzleApp = class("PuzzleApp", cc.load("mvc").AppBase)

function PuzzleApp:onCreate()
    local file = string.format("puzzle/%03d.json", self.configs_.level)
    local level = cc.FileUtils:getInstance():getStringFromFile(file)
    level = json.decode(level)
    self.shogi = require("lib.shogi").new({random = random, mapId = level.map})
    self.shogi:setDeck(level.friend.deck)
    self.shogi.party = {red = {}, blue = {}}
    self.shogi:commitForm({
        red = self:level2form_(level.friend.chara, "red"),
        blue = self:level2form_(level.enemy.chara, "blue")
    })
end

function PuzzleApp:level2form_(chara, team)
    local form = {}
    local master2party = {}
    for _, e in ipairs(chara) do
        if not master2party[e.id] then
            table.insert(self.shogi.party[team], us.findWhere(self.shogi.getCharaMaster(), {id = e.id}))
            master2party[e.id] = #self.shogi.party[team]
        end
        table.insert(form, string.format("%d,%d,%d", master2party[e.id], e.i, e.j))
    end
    return form
end

function PuzzleApp:getTeam()
    return "red"
end

function PuzzleApp:getShogi()
    return self.shogi
end

function PuzzleApp:addListener(listener)
    self.listener = listener
end

function PuzzleApp:commit(charaId, chipIdx)
    local enemies = us.select(self.shogi.charas, function(_, e) return e.team == "blue" end)
    self.listener({charaId .. chipIdx, enemies[1].id .. "1"})
end

function PuzzleApp:reset()
    self.shogi:reset()
end

return PuzzleApp

