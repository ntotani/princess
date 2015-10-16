local json = require("json")
local us = require("lib.moses")
local PuzzleApp = class("PuzzleApp", cc.load("mvc").AppBase)
local Solver = require("lib.solver")

function PuzzleApp:onCreate()
    local file = string.format("puzzle/%03d.json", self.configs_.level)
    local level = cc.FileUtils:getInstance():getStringFromFile(file)
    level = json.decode(level)
    self.shogi = Solver.level2shogi(random, level)
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
    self.listener({charaId .. chipIdx, Solver.solve(self.shogi, charaId, chipIdx)})
end

function PuzzleApp:reset()
    self.shogi:reset()
end

return PuzzleApp

