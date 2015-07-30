
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

require "config"
require "cocos.init"

local TitleApp = class("TitleApp", cc.load("mvc").AppBase)

function TitleApp:createRoom(callback)
    callback(12345)
end

function TitleApp:joinRoom(roomId)
    print("join room " .. roomId)
end

local function main()
    TitleApp:create():run("TitleScene")
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end

