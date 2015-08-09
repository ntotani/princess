local us = require("lib.moses")
local jam = require("lib.jam")
local FormationScene = class("FormationScene", cc.load("mvc").ViewBase)

function FormationScene:onCreate()
    self.MY_AREA = self:isSideFour() and {
        {i = 11, j = 2},
        {i = 11, j = 4},
        {i = 11, j = 6},
        {i = 12, j = 3},
        {i = 12, j = 5},
    } or {
        {i = 7, j = 3},
        {i = 7, j = 5},
        {i = 8, j = 2},
        {i = 8, j = 4},
    }
    self.shogi = self:getApp():getShogi()
    cc.TMXTiledMap:create("tmx/forest.tmx"):addTo(self)
    for i, line in ipairs(self.shogi:getTiles()) do
        for j, e in ipairs(line) do
            if e > 0 then
                local path = self:isSideFour() and "img/tile_4.png" or "img/tile.png"
                display.newSprite(path):move(self:idx2pt(i, j)):addTo(self)
            end
        end
    end
    for _, e in ipairs(self.MY_AREA) do
        if self:getApp():getTeam() == "blue" then
            e.i = #self.shogi:getTiles() - e.i + 1
            e.j = #self.shogi:getTiles()[1] - e.j + 1
        end
        local path = self:isSideFour() and "img/tile_red_4.png" or "img/tile_red.png"
        display.newSprite(path):move(self:idx2pt(e.i, e.j)):addTo(self)
    end
    self.friends = display.newLayer():addTo(self)
    local party = self.shogi:getParty()
    local myTeam = self:getApp():getTeam()
    for i, e in ipairs(party[myTeam]) do
        if e.job == "hime" then
            local ii, jj = self:searchTileIdx(myTeam == "red" and 2 or 3)
            self.hime = self:initChara(e):move(self:idx2pt(ii, jj)):addTo(self)
            self.hime.pos = {i = ii, j = jj}
            self.hime.partyIdx = i
        else
            local chara = self:initChara(e):move(i * 48, 80):addTo(self.friends)
            chara.pos = nil
            chara.partyIdx = i
            chara.backPt = cc.p(chara:getPosition())
        end
    end
    for i, e in ipairs(party[myTeam == "red" and "blue" or "red"]) do
        if e.job == "hime" then
            self:initChara(e):move(self:idx2pt(self:searchTileIdx(myTeam == "red" and 3 or 2))):addTo(self)
        else
            self:initChara(e):move(i * 48, display.height - 80):addTo(self)
        end
    end
    local notice = cc.Node:create():addTo(self)
    display.newSprite("img/window.png"):move(display.center):addTo(notice)
    cc.Label:createWithTTF("味方を2体まで赤いマスに配置して下さい", "font/PixelMplus12-Regular.ttf", 18):move(display.center):addTo(notice):setDimensions(200, 0)
    self.touchLayer = display.newLayer():addTo(self):onTouch(function()
        notice:removeSelf()
        self.touchLayer:onTouch(us.bind(self.onTouch, self))
    end)
end

function FormationScene:searchTileIdx(tile)
    for i, row in ipairs(self.shogi:getTiles()) do
        for j, e in ipairs(row) do
            if e == tile then
                return i, j
            end
        end
    end
    return -1, -1
end

function FormationScene:initChara(chara)
    local node = cc.Node:create()
    node.sprite = jam.sprite("img/" .. chara.job .. "_" .. chara.color .. ".png", 32):addTo(node)
    node.sprite:frameIdx(0, 1, 2, 1)
    node.color = display.newSprite("icon/" .. chara.color .. ".png"):move(16, -16):addTo(node)
    return node
end

function FormationScene:onTouch(e)
    if e.name == "began" and not self.holdChara then
        for _, friend in ipairs(self.friends:getChildren()) do
            local x, y = friend:getPosition()
            local len = 32
            if cc.rectContainsPoint(cc.rect(x - len / 2, y - len / 2, len, len), e) and not friend.pos then
                self.holdChara = friend
                return true
            end
        end
        return false
    end
    if e.name == "moved" and self.holdChara then
        self.holdChara:move(e)
    elseif self.holdChara then
        local len = 40
        for _, tile in ipairs(self.MY_AREA) do
            local pt = self:idx2pt(tile.i, tile.j)
            if cc.pDistanceSQ(pt, e) < len * len and not us.findWhere(self.friends:getChildren(), {pos = tile}) then
                self.holdChara:move(pt)
                self.holdChara.pos = tile
                self.holdChara = nil
                local form = us.select(self.friends:getChildren(), function(_, friend)
                    return friend.pos
                end)
                if #form >= 2 then
                    self.touchLayer:removeTouch()
                    local confirm = cc.Node:create():addTo(self)
                    display.newSprite("img/window.png"):move(display.center):addTo(confirm)
                    cc.Label:createWithTTF("この配置でいいですか？", "font/PixelMplus12-Regular.ttf", 18):move(display.center):addTo(confirm)
                    local ok = cc.MenuItemImage:create("img/button.png", "img/button.png"):onClicked(function()
                        confirm:removeSelf()
                        local form = {self.hime.partyIdx .. self.hime.pos.i .. self.hime.pos.j}
                        for _, friend in ipairs(self.friends:getChildren()) do
                            if friend.pos then
                                form[#form + 1] = friend.partyIdx .. friend.pos.i .. friend.pos.j
                            end
                        end
                        self:getApp():commitForm(form)
                        display.newSprite("img/window.png"):move(display.center):addTo(self)
                        cc.Label:createWithTTF("相手を待っています...", "font/PixelMplus12-Regular.ttf", 18):move(display.center):addTo(self)
                    end):move(50, 0):addChild(cc.Label:createWithTTF("はい", "font/PixelMplus12-Regular.ttf", 18):move(39, 21))
                    local ng = cc.MenuItemImage:create("img/button.png", "img/button.png"):onClicked(function()
                        for _, friend in ipairs(self.friends:getChildren()) do
                            friend:move(friend.backPt)
                            friend.pos = nil
                        end
                        confirm:removeSelf()
                        self.touchLayer:onTouch(us.bind(self.onTouch, self))
                    end):move(-50, 0):addChild(cc.Label:createWithTTF("いいえ", "font/PixelMplus12-Regular.ttf", 18):move(39, 21))
                    cc.Menu:create(ok, ng):move(display.cx, display.cy - 70):addTo(confirm)
                end
                return
            end
        end
        self.holdChara:move(self.holdChara.backPt)
        self.holdChara = nil
    end
end

return FormationScene

