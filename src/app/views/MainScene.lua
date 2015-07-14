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

local TILES = {
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

function MainScene:onCreate()
    --[[
    local TILES_PER_SIDE = 3
    local tiles = us.map(us.range(1, TILES_PER_SIDE * 2 - 1 + (TILES_PER_SIDE - 1) * 2), function(e)
        return us.rep(0, TILES_PER_SIDE * 2 - 1)
    end)
    ]]
    cc.TMXTiledMap:create("tmx/forest.tmx"):addTo(self)
    for i, line in ipairs(TILES) do
        for j, e in ipairs(line) do
            if e == 1 then
                display.newSprite("img/tile.png"):move(self:idx2pt(i, j)):addTo(self)
            end
        end
    end
    self.enemies = display.newLayer():addTo(self)
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
        node.sprite:frameIdx(9, 10, 11, 10)
        node:addTo(self.friends)
    else
        node.sprite:frameIdx(0, 1, 2, 1)
        node:addTo(self.enemies)
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
                    local ni = friend.idx.i + dir.i
                    local nj = friend.idx.j + dir.j
                    if ni < 1 or ni > #TILES or nj < 1 or nj > #TILES[1] or TILES[ni][nj] == 0 then
                        -- out of bounds
                        friend:removeSelf()
                        break
                    end
                    local charas = us.flatten({self.friends:getChildren(), self.enemies:getChildren()})
                    local hit = us.detect(charas, function(e)
                        return us.isEqual(e.idx, {i = ni, j = nj})
                    end)
                    friend.idx.i = ni
                    friend.idx.j = nj
                    friend:move(self:idx2pt(ni, nj))
                    if hit then
                        -- kill other chara
                        charas[hit]:removeSelf()
                        break
                    end
                end
                break -- TODO draw chip here
            end
        end
        self.holdChip:move(self.holdChip.backPt)
        self.holdChip = nil
    end
end

return MainScene

