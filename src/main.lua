
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")
cc.FileUtils:getInstance():addSearchPath("res/ccbi")

require "config"
require "cocos.init"

local function main()
    math.newrandomseed()
    require("app.ctx.TitleApp"):create():run("TitleScene")
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
