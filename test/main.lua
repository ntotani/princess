
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

require "config"
require "cocos.init"

local TestApp = class("TestApp", cc.load("mvc").AppBase)

function TestApp:onCreate()
end

function TestApp:getTeam()
    return "red"
end

function TestApp:getSeed()
    return 0
end

function TestApp:addListener(listener)
    self.listener = listener
end

function TestApp:commit(charaId, chipIdx)
    self.listener({charaId .. chipIdx})
end

local function main()
    TestApp:create():run("GameScene")
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end

