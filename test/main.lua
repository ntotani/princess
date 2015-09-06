local luaunit = require("test.lib.luaunit")

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

require "test.cases.TestShogi"
require "test.cases.TestGameScene"
require "test.cases.TestTitleScene"

cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

require "config"
DEBUG = 1
require "cocos.init"
__G__TRACKBACK__ = function(msg)
    print(debug.traceback(msg, 3))
    os.exit(1)
end

os.exit(luaunit.LuaUnit.run('-v'))

