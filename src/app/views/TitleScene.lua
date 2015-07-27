local TitleScene = class("TitleScene", cc.load("mvc").ViewBase)

function TitleScene:onCreate()
    cc.TMXTiledMap:create("tmx/forest.tmx"):addTo(self)
    display.newSprite("img/logo.png"):move(display.cx, display.height * 3 / 5):addTo(self)
    local roomButton = cc.MenuItemImage:create("img/button_room.png", "img/button_room.png")
        :move(display.cx, display.height * 0.25)
        :onClicked(function() print("room") end)
    local joinButton = cc.MenuItemImage:create("img/button_join.png", "img/button_join.png")
        :move(display.cx, display.height * 0.15)
        :onClicked(function() print("join") end)
    cc.Menu:create(roomButton, joinButton):move(0, 0):addTo(self)
end

return TitleScene

