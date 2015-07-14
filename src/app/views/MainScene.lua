local us = require("lib.moses")
local jam = require("lib.jam")
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

local CHIPS = {
    f    = {{i = -2, j =  0}},
    rf   = {{i = -1, j =  1}},
    lf   = {{i = -1, j = -1}},
    rb   = {{i =  1, j =  1}},
    lb   = {{i =  1, j = -1}},
    b    = {{i =  2, j =  0}},
    ff   = {{i = -2, j =  0}, {i = -2, j =  0}},
    rfrf = {{i = -1, j =  1}, {i = -1, j =  1}},
    lflf = {{i = -1, j = -1}, {i = -1, j = -1}},
    frf  = {{i = -2, j =  0}, {i = -1, j =  1}},
    flf  = {{i = -2, j =  0}, {i = -1, j = -1}},
}

function MainScene:onCreate()
    --[[
    local TILES_PER_SIDE = 3
    local tiles = us.map(us.range(1, TILES_PER_SIDE * 2 - 1 + (TILES_PER_SIDE - 1) * 2), function(e)
        return us.rep(0, TILES_PER_SIDE * 2 - 1)
    end)
    ]]
    local tiles = {
        {0, 0, 1, 0, 0},
        {0, 1, 0, 1, 0},
        {1, 0, 1, 0, 1},
        {0, 1, 0, 1, 0},
        {1, 0, 1, 0, 1},
        {0, 1, 0, 1, 0},
        {1, 0, 1, 0, 1},
        {0, 1, 0, 1, 0},
        {0, 0, 1, 0, 0},
    }
    cc.TMXTiledMap:create("tmx/forest.tmx"):addTo(self)
    for i, line in ipairs(tiles) do
        for j, e in ipairs(line) do
            if e == 1 then
                display.newSprite("img/tile.png"):move(self:idx2pt(i, j)):addTo(self)
            end
        end
    end
    self.friends = display.newLayer():addTo(self)
    self:initChara(9, 3, "hime", true)
    self:initChara(8, 2, "witch", true)
    self:initChara(7, 5, "ninja", true)
    self:initChara(1, 3, "hime")
    self:initChara(2, 4, "witch")
    self:initChara(3, 1, "ninja")
    self.chips = display.newLayer():addTo(self)
    local names = us.keys(CHIPS)
    for i = 1, 4 do
        local name = names[math.random(1, #names)]
        local chip = display.newSprite("chip/" .. name .. ".png"):move((72 + 14) * (i - 1) + 15 + 36, 80):addTo(self.chips)
        chip.name = name
    end
    display.newLayer():addTo(self):onTouch(us.bind(self.onTouch, self))
end

function MainScene:initChara(i, j, job, isFriend)
    local node = cc.Node:create():move(self:idx2pt(i, j))
    node.sprite = jam.sprite("img/" .. job .. ".png", 32):addTo(node)
    if isFriend then
        node.sprite:frameIdx(9, 10, 11)
        node:addTo(self.friends)
    else
        node.sprite:frameIdx(0, 1, 2)
        node:addTo(self)
    end
    node.idx = {i = i, j = j}
end

function MainScene:idx2pt(i, j)
    return cc.p(display.cx + 38 * (j - 3) * 1.5, display.cy + 33 * (5 - i))
end

function MainScene:onTouch(e)
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
                for _, dir in ipairs(CHIPS[self.holdChip.name]) do
                    friend.idx.i = friend.idx.i + dir.i
                    friend.idx.j = friend.idx.j + dir.j
                    friend:move(self:idx2pt(friend.idx.i, friend.idx.j))
                end
                break
            end
        end
        self.holdChip:move(self.holdChip.backPt)
        self.holdChip = nil
    end
end

return MainScene

