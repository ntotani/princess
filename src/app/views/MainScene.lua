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
    jam.sprite("img/hime.png", 32):frameIdx(9, 10, 11):addTo(cc.Node:create():move(self:idx2pt(9, 3)):addTo(self))
    jam.sprite("img/witch.png", 32):frameIdx(9, 10, 11):addTo(cc.Node:create():move(self:idx2pt(8, 2)):addTo(self))
    jam.sprite("img/ninja.png", 32):frameIdx(9, 10, 11):addTo(cc.Node:create():move(self:idx2pt(7, 5)):addTo(self))
    jam.sprite("img/hime.png", 32):frameIdx(0, 1, 2):addTo(cc.Node:create():move(self:idx2pt(1, 3)):addTo(self))
    jam.sprite("img/witch.png", 32):frameIdx(0, 1, 2):addTo(cc.Node:create():move(self:idx2pt(2, 4)):addTo(self))
    jam.sprite("img/ninja.png", 32):frameIdx(0, 1, 2):addTo(cc.Node:create():move(self:idx2pt(3, 1)):addTo(self))
    local names = us.keys(CHIPS)
    for i = 1, 4 do
        local chip = names[math.random(1, #names)]
        display.newSprite("chip/" .. chip .. ".png"):move((72 + 14) * (i - 1) + 15 + 36, 80):addTo(self)
    end
end

function MainScene:idx2pt(i, j)
    return cc.p(display.cx + 38 * (j - 3) * 1.5, display.cy + 33 * (5 - i))
end

return MainScene

