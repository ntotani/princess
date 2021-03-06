local TestApp = class("TestApp", cc.load("mvc").AppBase)

function TestApp:onCreate()
    self.shogi = require("lib.shogi").new({random = function()
        return math.random(65535)
    end, mapId = 2})
end

function TestApp:getTeam()
    return "red"
end

function TestApp:getShogi()
    return self.shogi
end

function TestApp:addListener(listener)
    self.listener = listener
end

function TestApp:commitForm(form)
    self.shogi:commitForm({
        red = form,
        blue = {"1,1,4", "2,2,5", "3,3,2"},
    })
    self:enterScene("GameScene")
end

function TestApp:commit(charaId, chipIdx)
    self.listener({charaId .. chipIdx})
end

function TestApp:getInitialMessage()
    return nil
end

function TestApp:endTexts(win)
    return {
        message = "YOU " .. (win and "WIN" or "LOSE"),
        ok = "もう一回",
        ng = "やめる"
    }
end

function TestApp:endPositive()
    self.shogi:reset()
    self:enterScene("FormationScene")
end

function TestApp:endNegative()
    print("endNegative")
end

return TestApp

