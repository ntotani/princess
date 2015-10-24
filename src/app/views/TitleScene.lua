local us = require("lib.moses")
local PuzzleApp = require("app.ctx.PuzzleApp")

local TitleScene = class("TitleScene", cc.load("mvc").ViewBase)

function TitleScene:onCreate()
    cc.TMXTiledMap:create("tmx/forest.tmx"):addTo(self)
    self.smoke = display.newLayer(display.COLOR_BLACK):addTo(self)
    self.smoke:setOpacity(0)
    self:initPuzzle_()
    self.titles = cc.Node:create():addTo(self)
    display.newSprite("img/logo.png"):move(display.cx, display.height * 4 / 6):addTo(self.titles)
    local applyText = function(btn, text)
        local cs = btn:getContentSize()
        cc.Label:createWithTTF(text, "font/PixelMplus12-Regular.ttf", 24):move(cs.width / 2, cs.height / 2):addTo(btn):setColor(display.COLOR_BLACK)
    end
    local puzzleButton = cc.MenuItemImage:create("img/button/long.png", "img/button/long.png")
        :move(display.cx, display.height * 0.35)
        :onClicked(us.bind(self.onPuzzle, self))
    applyText(puzzleButton, "ひとりで遊ぶ")
    local roomButton = cc.MenuItemImage:create("img/button/long.png", "img/button/long.png")
        :move(display.cx, display.height * 0.25)
        :onClicked(us.bind(self.onRoom, self))
    applyText(roomButton, "部屋を作る")
    local joinButton = cc.MenuItemImage:create("img/button/long.png", "img/button/long.png")
        :move(display.cx, display.height * 0.15)
        :onClicked(us.bind(self.onJoin, self))
    applyText(joinButton, "部屋に入る")
    cc.Menu:create(puzzleButton, roomButton, joinButton):move(0, 0):addTo(self.titles)
end

function TitleScene:initPuzzle_()
    local tileLen = display.newSprite("img/button/chip.png"):getContentSize().width
    local margin = (display.width - tileLen * 4) / 5
    self.puzzle = ccui.ListView:create():addTo(self):setVisible(false)
    self.puzzle:setContentSize(display.size)
    self.puzzle:setItemsMargin(margin)
    self.puzzle:pushBackCustomItem(ccui.VBox:create(cc.size(display.width, margin / 2)))
    for i = 1, 100 do
        if not PuzzleApp.existLevel(i) then break end
        local layout
        if (i - 1) % 4 == 0 then
            layout = ccui.Layout:create()
            layout:setContentSize(display.width, tileLen)
            self.puzzle:pushBackCustomItem(layout)
        else
            local items = self.puzzle:getItems()
            layout = items[#items]
        end
        local x = ((i - 1) % 4) * (tileLen + margin) + margin + tileLen / 2
        local y = tileLen / 2
        ccui.Button:create("img/button/chip.png", "img/button/chip.png"):move(x, y):addTo(layout):addTouchEventListener(function(sender, event)
            if event ~= ccui.TouchEventType.ended then return end
            PuzzleApp:create({level = i}):run("GameScene")
        end)
        cc.Label:createWithTTF(i, "font/PixelMplus12-Regular.ttf", 24):move(x, y):addTo(layout):setColor(display.COLOR_BLACK)
    end
    self.puzzle:pushBackCustomItem(ccui.VBox:create(cc.size(display.width, margin / 2)))
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

