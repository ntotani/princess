local us = require("lib.moses")
local TitleScene = class("TitleScene", cc.load("mvc").ViewBase)

function TitleScene:onCreate()
    cc.TMXTiledMap:create("tmx/forest.tmx"):addTo(self)
    self.smoke = display.newLayer(display.COLOR_BLACK):addTo(self)
    self.smoke:setOpacity(0)
    self.puzzle = cc.Menu:create():move(0, 0):addTo(self):setVisible(false)
    for i = 1, 10 do
        local margin = (360 - 73 * 4) / 5
        local x = ((i - 1) % 4) * (73 + margin) + margin + 73 / 2
        local y = display.height - (math.floor((i - 1) / 4) * (73 + margin) + margin + 73 / 2)
        local mii = cc.MenuItemImage:create("img/btn.png", "img/btn.png"):move(x, y):onClicked(function()
            local app = require("app.ctx.PuzzleApp"):create({level = i})
            app:run("GameScene")
        end):addTo(self.puzzle)
        cc.Label:createWithTTF(i, "font/PixelMplus12-Regular.ttf", 24):move(73 / 2, 73 / 2):addTo(mii):setColor(display.COLOR_BLACK)
    end
    self.titles = cc.Node:create():addTo(self)
    display.newSprite("img/logo.png"):move(display.cx, display.height * 3 / 5):addTo(self.titles)
    local puzzleButton = cc.MenuItemImage:create("img/button_puzzle.png", "img/button_puzzle.png")
        :move(display.cx, display.height * 0.35)
        :onClicked(us.bind(self.onPuzzle, self))
    local roomButton = cc.MenuItemImage:create("img/button_room.png", "img/button_room.png")
        :move(display.cx, display.height * 0.25)
        :onClicked(us.bind(self.onRoom, self))
    local joinButton = cc.MenuItemImage:create("img/button_join.png", "img/button_join.png")
        :move(display.cx, display.height * 0.15)
        :onClicked(us.bind(self.onJoin, self))
    cc.Menu:create(puzzleButton, roomButton, joinButton):move(0, 0):addTo(self.titles)
end

function TitleScene:onPuzzle()
    self.titles:moveBy({time = 0.2, x = -display.width})
    self.smoke:fadeTo({time = 0.2, opacity = 127, onComplete = function()
        self.puzzle:setVisible(true)
    end})
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
        local EMPTY_MESSAGE = "部屋番号を入力して下さい"
        local message = cc.Label:createWithTTF(EMPTY_MESSAGE, "font/PixelMplus12-Regular.ttf", 24):move(display.cx, display.height * 0.8):addTo(self)
        local menu = cc.Menu:create():move(0, 0):addTo(self)
        local nums = cc.Node:create():addTo(self)
        local roomId = ""
        local commit = cc.MenuItemImage:create("img/button_ok.png", "img/button_ok.png"):move(display.cx, 72):hide():addTo(menu):onClicked(function()
            if roomId == "" then return end
            menu:removeSelf()
            nums:removeSelf()
            self:getApp():joinRoom(roomId)
        end)
        local backspace = nil
        backspace = cc.MenuItemImage:create("img/button_bs.png", "img/button_bs.png"):move(display.width * 0.8, display.height * 0.8):hide():addTo(menu):onClicked(function()
            roomId = string.sub(roomId, 1, -2)
            if roomId == "" then
                message:setString(EMPTY_MESSAGE)
                commit:hide()
                backspace:hide()
            else
                message:setString(roomId)
            end
        end)
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
                commit:show()
                backspace:show()
            end)
            cc.Label:createWithTTF(num, "font/PixelMplus12-Regular.ttf", 24):move(x, y):addTo(nums):setColor(display.COLOR_BLACK)
        end
    end})
end

return TitleScene

