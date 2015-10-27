local luaunit = require("test.lib.luaunit")
local us = require("src.lib.moses")

TestTitleScene = {}

function TestTitleScene:setUp()
    self.app = {isNetworkError = function() return false end}
    self.scene = require("app.views.TitleScene"):create(self.app, "TitleScene")
    self.scene:showWithScene()
    cc.Director:getInstance():mainLoop() -- run scene
end

function TestTitleScene:testOnCreate()
    luaunit.assertIs(self.scene.smoke:getParent(), self.scene)
    luaunit.assertIs(self.scene.titles:getParent(), self.scene)
end

function TestTitleScene:testOnRoom()
    local called = false
    self.app.createRoom = function(self, callback)
        luaunit.assertIsFunction(callback)
        called = true
    end
    self.scene:onRoom()
    cc.Director:getInstance():mainLoop()
    setDeltaTime(0.2)
    cc.Director:getInstance():mainLoop()
    luaunit.assertTrue(called)
end

