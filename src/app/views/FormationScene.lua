local us = require("lib.moses")
local jam = require("lib.jam")
local FormationScene = class("FormationScene", cc.load("mvc").ViewBase)

function FormationScene:onCreate()
    self.shogi = self:getApp():getShogi()
    cc.TMXTiledMap:create("tmx/forest.tmx"):addTo(self)
    for i, line in ipairs(self.shogi:getTiles()) do
        for j, e in ipairs(line) do
            if e > 0 then
                display.newSprite("img/tile.png"):move(self:idx2pt(i, j)):addTo(self)
            end
        end
    end
    local party = self.shogi:getParty()
    for i, e in ipairs(party.red) do
        self:initChara(e):move(i * 48, 80):addTo(self)
    end
    for i, e in ipairs(party.blue) do
        self:initChara(e):move(i * 48, display.height - 80):addTo(self)
    end
end

function FormationScene:idx2pt(i, j)
    if self:getApp():getTeam() == "blue" then
        i = #self.shogi:getTiles() - i + 1
        j = #self.shogi:getTiles()[1] - j + 1
    end
    return cc.p(display.cx + 38 * (j - 3) * 1.5, display.cy + 33 * (5 - i))
end

function FormationScene:initChara(chara)
    local node = cc.Node:create()
    node.sprite = jam.sprite("img/" .. chara.job .. "_" .. chara.color .. ".png", 32):addTo(node)
    node.sprite:frameIdx(0, 1, 2, 1)
    node.color = display.newSprite("icon/" .. chara.color .. ".png"):move(16, -16):addTo(node)
    return node
end

return FormationScene

