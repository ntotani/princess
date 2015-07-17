local us = require("lib.moses")
local Shogi = {}

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
    {0, 0, 3, 0, 0},
    {0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0},
    {0, 0, 2, 0, 0},
}
local RED_CAMP = 2
local BLUE_CAMP = 3

function Shogi:ctor()
    self:reset()
end

function Shogi:reset()
    self.chars = {
        {id = 1, i = 9, j = 3, job = "hime",  team = "red"},
        {id = 2, i = 8, j = 2, job = "witch", team = "red"},
        {id = 3, i = 7, j = 5, job = "ninja", team = "red"},
        {id = 4, i = 1, j = 3, job = "hime",  team = "blue"},
        {id = 5, i = 2, j = 4, job = "witch", team = "blue"},
        {id = 6, i = 3, j = 1, job = "ninja", team = "blue"},
    }
    self.chips = {
        red = us.keys(CHIPS),
        blue = us.keys(CHIPS),
    }
end

function Shogi:getTiles()
    return TILES
end

function Shogi:getChars()
    return self.chars
end

function Shogi:getChips(team)
    return us.first(self.chips[team], 4)
end

function Shogi:processTurn(commands)
    local acts = {}
    for i, e in ipairs(commands) do
        local charaId = tonumber(e:sub(1, 1))
        local chipIdx = tonumber(e:sub(2, 2))
        local friend = us.findWhere(self.chars, {id = charaId})
        if friend.dead then
            acts[#acts + 1] = {type = "dead", actor = charaId, chip = chipIdx}
        else
            for _, dir in ipairs(CHIPS[table.remove(self.chips[friend.team], chipIdx)]) do
                local ni = friend.i + dir.i * (friend.team == "red" and 1 or -1)
                local nj = friend.j + dir.j * (friend.team == "red" and 1 or -1)
                if ni < 1 or ni > #TILES or nj < 1 or nj > #TILES[1] or TILES[ni][nj] == 0 then
                    -- out of bounds
                    acts[#acts + 1] = {type = "ob", i = ni, j = nj, actor = charaId, chip = chipIdx}
                    friend.dead = true
                    break
                end
                local hit = us.detect(self.chars, function(e)
                    return e.i == ni and e.j == nj and not e.dead
                end)
                friend.i = ni
                friend.j = nj
                acts[#acts + 1] = {type = "move", i = ni, j = nj, actor = charaId, chip = chipIdx}
                if hit then
                    -- kill other chara
                    acts[#acts].type = "kill"
                    acts[#acts].target = self.chars[hit].id
                    self.chars[hit].dead = true
                    if self.chars[hit].job == "hime" then
                        acts[#acts + 1] = {type = "end", win = friend.team}
                    end
                    break
                end
                if friend.job == "hime" then
                    if TILES[ni][nj] == BLUE_CAMP and friend.team == "red" or TILES[ni][nj] == RED_CAMP and friend.team == "blue" then
                        acts[#acts + 1] = {type = "end", win = friend.team}
                    end
                end
            end
        end
    end
    if #self.chips.red < 1 then self.chips.red = us.keys(CHIPS) end
    if #self.chips.blue < 1 then self.chips.blue = us.keys(CHIPS) end
    return acts
end

function Shogi.new(...)
    local obj = {}
    setmetatable(obj, {__index = Shogi})
    obj:ctor(...)
    return obj
end

return Shogi
