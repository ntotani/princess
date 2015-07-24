local luaunit = require("test.lib.luaunit")
local us = require("src.lib.moses")

function testSample()
    local scene = cc.Scene:create()
    display.runScene(scene)
    cc.Director:getInstance():mainLoop() -- run scene

    local node = cc.Node:create()
    scene:addChild(node)
    node:runAction(cc.MoveTo:create(5, cc.p(10, 0)))
    cc.Director:getInstance():mainLoop() -- first tick

    setDeltaTime(5)
    cc.Director:getInstance():mainLoop() -- animation
    luaunit.assertEquals(node:getPositionX(), 10)
end

TestShogi = {
    setUp = function(self)
        local rnds = us.range(0, 9)
        self.shogi = require("lib.shogi").new({random = function()
            table.insert(rnds, table.remove(rnds, 1))
            return rnds[#rnds]
        end})
    end,
    testReset = function(self)
        luaunit.assertEquals(#self.shogi.party.red, 6)
        luaunit.assertEquals(self.shogi.party.red[1].job, "hime")
        luaunit.assertEquals(#self.shogi.party.blue, 6)
        luaunit.assertEquals(self.shogi.party.blue[1].job, "hime")
        for i = 2, 6 do
            luaunit.assertNotEquals(self.shogi.party.red[i].job, "hime")
            luaunit.assertNotEquals(self.shogi.party.blue[i].job, "hime")
        end
        luaunit.assertEquals(self.shogi:getCharas(), {})
        luaunit.assertEquals(self.shogi.chips, {})
    end,
    testCommitForm = function(self)
        self.shogi:commitForm({red = {"193", "282"}, blue = {"113", "224"}})
        luaunit.assertEquals(#self.shogi:getCharas(), 4)
        luaunit.assertEquals(self.shogi:getCharas()[1], {id = 1, i = 9, j = 3, team = "red", hp = 100, job = "hime"})
        luaunit.assertNotEquals(self.shogi:getCharas()[2].job, "hime")
        luaunit.assertEquals(self.shogi:getCharas()[3].job, "hime")
        luaunit.assertNotEquals(self.shogi:getCharas()[4].job, "hime")
        luaunit.assertEquals(#self.shogi.chips.red, 12)
        luaunit.assertEquals(#self.shogi.chips.blue, 12)
    end,
}

cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

require "config"
require "cocos.init"

os.exit(luaunit.LuaUnit.run('-v'))

