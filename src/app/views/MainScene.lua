
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

function MainScene:onCreate()
    cc.TMXTiledMap:create("tmx/forest.tmx"):addTo(self)
end

return MainScene

