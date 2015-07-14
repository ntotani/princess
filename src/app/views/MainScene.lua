local us = require("lib.moses")
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

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
end

function MainScene:idx2pt(i, j)
    return cc.p(display.cx + 38 * (j - 3) * 1.5, display.cy + 33 * (5 - i))
end

return MainScene

