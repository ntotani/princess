local us = require("lib.moses")
local TitleScene = class("TitleScene", cc.load("mvc").ViewBase)

function TitleScene:onCreate()
    cc.TMXTiledMap:create("tmx/forest.tmx"):addTo(self)
    self.smoke = display.newLayer(display.COLOR_BLACK):addTo(self)
    self.smoke:setOpacity(0)
    self.titles = cc.Node:create():addTo(self)
    display.newSprite("img/logo.png"):move(display.cx, display.height * 3 / 5):addTo(self.titles)
    local roomButton = cc.MenuItemImage:create("img/button_room.png", "img/button_room.png")
        :move(display.cx, display.height * 0.25)
        :onClicked(us.bind(self.onRoom, self))
    local joinButton = cc.MenuItemImage:create("img/button_join.png", "img/button_join.png")
        :move(display.cx, display.height * 0.15)
        :onClicked(us.bind(self.onJoin, self))
    cc.Menu:create(roomButton, joinButton):move(0, 0):addTo(self.titles)
end

function TitleScene:onRoom()
    self.titles:moveBy({time = 0.2, x = -display.width})
    self.smoke:fadeTo({time = 0.2, opacity = 127, onComplete = function()
        local message = cc.Label:createWithTTF("connecting...", "font/PixelMplus12-Regular.ttf", 24):move(display.center):addTo(self)
        self:getApp():createRoom(function(roomId)
            cc.Label:createWithTTF("部屋番号\n" .. roomId, "font/PixelMplus12-Regular.ttf", 48):move(display.cx, display.height * 0.8):addTo(self)
            message:setString("相手の画面で\n部屋番号を入力して下さい")
        end)
    end})
end

function TitleScene:onJoin()
    self.titles:moveBy({time = 0.2, x = -display.width})
    self.smoke:fadeTo({time = 0.2, opacity = 127, onComplete = function()
        local message = cc.Label:createWithTTF("部屋番号を入力して下さい", "font/PixelMplus12-Regular.ttf", 24):move(display.cx, display.height * 0.8):addTo(self)
        local menu = cc.Menu:create():move(0, 0):addTo(self)
        local nums = cc.Node:create():addTo(self)
        local roomId = ""
        for i = 0, 9 do
            local x = display.cx + (i % 3 - 1) * 80
            local y = display.cy + (1 - math.floor(i / 3)) * 80
            local num = i + 1
            if i == 9 then
                x = display.cx
                num = 0
            end
            cc.MenuItemImage:create("img/btn.png", "img/btn.png"):move(x, y):addTo(menu):onClicked(function()
                roomId = roomId .. num
                message:setString(roomId)
            end)
            cc.Label:createWithTTF(num, "font/PixelMplus12-Regular.ttf", 24):move(x, y):addTo(nums):setColor(display.COLOR_BLACK)
        end
        cc.MenuItemImage:create("img/button_ok.png", "img/button_ok.png"):move(display.cx, 72):addTo(menu):onClicked(function()
            if roomId == "" then return end
            menu:removeSelf()
            nums:removeSelf()
            self:getApp():joinRoom(roomId)
        end)
    end})
end

return TitleScene

