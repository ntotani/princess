local luaunit = require("test.lib.luaunit")
local us = require("src.lib.moses")

TestGameScene = {}

function TestGameScene:setUp()
    local app = require("test.TestApp"):create()
    app.shogi:commitForm({red = {"193"}, blue = {"113"}})
    self.scene = require("app.views.GameScene"):create(app, "GameScene")
    self.scene:showWithScene()
    cc.Director:getInstance():mainLoop() -- run scene
end

function TestGameScene:testReset()
    luaunit.assertEquals(#self.scene:getChildren(), 25)
end

