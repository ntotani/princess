local json = require("json")
local us = require("lib.moses")
local Solver = require("lib.solver")

local PuzzleApp = class("PuzzleApp", cc.load("mvc").AppBase)

local function level2path(level)
    return string.format("puzzle/%03d.json", level)
end

function PuzzleApp.existLevel(level)
    return cc.FileUtils:getInstance():isFileExist(level2path(level))
end

function PuzzleApp:onCreate()
    self.level = cc.FileUtils:getInstance():getStringFromFile(level2path(self.configs_.level))
    self.level = json.decode(self.level)
    self.shogi = Solver.level2shogi(random, self.level)
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

function PuzzleApp:getInitialMessage()
    return self.level.message
end

function PuzzleApp:endTexts(win)
    cc.UserDefault:getInstance():setIntegerForKey("progress", self.configs_.level)
    cc.UserDefault:getInstance():flush()
    local hasNext = PuzzleApp.existLevel(self.configs_.level + 1)
    return {
        message = win and "正解" or "不正解",
        ok = win and (hasNext and "次へ" or "戻る") or "もう一回",
        ng = "やめる"
    }
end

function PuzzleApp:endPositive(win)
    if win and not PuzzleApp.existLevel(self.configs_.level + 1) then
        self:enterScene("TitleScene")
    else
        PuzzleApp:create({level = self.configs_.level + (win and 1 or 0)}):run("GameScene")
    end
end

function PuzzleApp:endNegative()
    self:enterScene("TitleScene")
end

return PuzzleApp

