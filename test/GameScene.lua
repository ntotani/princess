
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

require "config"
require "cocos.init"

local function main()
    local app = require("test.TestApp"):create()
    app:commitForm({"193", "282", "375"})
    app:run("GameScene")
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end

