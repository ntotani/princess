local us = require("lib.moses")
local jam = require("lib.jam")
local GameScene = class("GameScene", cc.load("mvc").ViewBase)

function GameScene:onCreate()
    --[[
    local TILES_PER_SIDE = 3
    local tiles = us.map(us.range(1, TILES_PER_SIDE * 2 - 1 + (TILES_PER_SIDE - 1) * 2), function(e)
        return us.rep(0, TILES_PER_SIDE * 2 - 1)
    end)
    ]]
    cc.TMXTiledMap:create("tmx/forest.tmx"):addTo(self)
    for i, line in ipairs(self:getApp():getTiles()) do
        for j, e in ipairs(line) do
            if e == 1 then
                display.newSprite("img/tile.png"):move(self:idx2pt(i, j)):addTo(self)
            end
        end
    end
    self.enemies = display.newLayer():addTo(self)
    self.friends = display.newLayer():addTo(self)
    for _, e in ipairs(self:getApp():getChars()) do
        self:initChara(e)
    end
    self.chips = display.newLayer():addTo(self)
    for i, e in ipairs(self:getApp():getChips()) do
        local chip = display.newSprite("chip/" .. e .. ".png"):move((72 + 14) * (i - 1) + 15 + 36, 80):addTo(self.chips)
        chip.idx = i
    end
    self:getApp():addListener(us.bind(self.onAction, self))
    self.touchLayer = display.newLayer():addTo(self):onTouch(us.bind(self.onTouch, self))
end

function GameScene:initChara(chara)
    local node = cc.Node:create():move(self:idx2pt(chara.i, chara.j))
    node.sprite = jam.sprite("img/" .. chara.job .. ".png", 32):addTo(node)
    if chara.team == self:getApp():getTeam() then
        node.sprite:frameIdx(9, 10, 11, 10)
        node:addTo(self.friends)
    else
        node.sprite:frameIdx(0, 1, 2, 1)
        node:addTo(self.enemies)
    end
    node.model = chara
end

function GameScene:idx2pt(i, j)
    if self:getApp():getTeam() == "blue" then
        i = #self:getApp():getTiles() - i + 1
        j = #self:getApp():getTiles()[1] - j + 1
    end
    return cc.p(display.cx + 38 * (j - 3) * 1.5, display.cy + 33 * (5 - i))
end

function GameScene:onTouch(e)
    if e.name == "began" and not self.holdChip then
        for _, chip in ipairs(self.chips:getChildren()) do
            local bb = chip:getBoundingBox()
            if cc.rectContainsPoint(bb, e) then
                self.holdChip = chip
                self.holdChip.backPt = cc.p(chip:getPosition())
                return true
            end
        end
        return false
    end
    if e.name == "moved" and self.holdChip then
        self.holdChip:move(e)
    elseif self.holdChip then
        local len = 48
        for _, friend in ipairs(self.friends:getChildren()) do
            local x, y = friend:getPosition()
            if cc.rectContainsPoint(cc.rect(x - len / 2, y - len / 2, len, len), e) then
                self.touchLayer:removeTouch()
                self:getApp():commit(friend.model.id, self.holdChip.idx)
                break
            end
        end
        self.holdChip:move(self.holdChip.backPt)
        self.holdChip = nil
    end
end

function GameScene:onAction(acts)
    for _, act in ipairs(acts) do
        local charas = us.flatten({self.friends:getChildren(), self.enemies:getChildren()})
        local actor = charas[us.detect(charas, function(e)
            return e.model.id == act.who
        end)]
        if act.type == "move" then
            actor:move(self:idx2pt(act.i, act.j))
        elseif act.type == "kill" then
            actor:move(self:idx2pt(act.i, act.j))
            charas[us.detect(charas, function(e)
                return e.model.id == act.target
            end)]:removeSelf()
        elseif act.type == "ob" then
            actor:removeSelf()
        end
    end
    -- TODO next turn
end

return GameScene

