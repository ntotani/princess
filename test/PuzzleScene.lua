
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

require "config"
require "cocos.init"

local function main()
    local app = require("app.ctx.PuzzleApp"):create({level = 1})
    app:run("GameScene")
end

xpcall(main, __G__TRACKBACK__)

