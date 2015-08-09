local us = require("lib.moses")
local Shogi = {}

local COLOR_RATE = {
    tue = {tue = 1.0, wed = 0.5, thu = 2.0},
    wed = {tue = 2.0, wed = 1.0, thu = 0.5},
    thu = {tue = 0.5, wed = 2.0, thu = 1.0},
}

local CHARAS = {
    {id = "1", job = "hime",  attack = 100, block = 100, color = "tue"},
    {id = "2", job = "hime",  attack = 100, block = 100, color = "wed"},
    {id = "3", job = "hime",  attack = 100, block = 100, color = "thu"},
    {id = "4", job = "ninja", attack = 100, block = 100, color = "tue"},
    {id = "5", job = "ninja", attack = 100, block = 100, color = "wed"},
    {id = "6", job = "ninja", attack = 100, block = 100, color = "thu"},
    {id = "7", job = "witch", attack = 100, block = 100, color = "tue"},
    {id = "8", job = "witch", attack = 100, block = 100, color = "wed"},
    {id = "9", job = "witch", attack = 100, block = 100, color = "thu"},
}

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
    skill = {},
}

local TILES = {
{
    {0, 0, 3, 0, 0},
    {0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0},
    {0, 0, 2, 0, 0},
},
{
    {0, 0, 0, 3, 0, 0, 0},
    {0, 0, 1, 0, 1, 0, 0},
    {0, 1, 0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0, 1, 0},
    {0, 0, 1, 0, 1, 0, 0},
    {0, 0, 0, 2, 0, 0, 0},
}
}
local RED_CAMP = 2
local BLUE_CAMP = 3

function Shogi:ctor(ctx)
    self.ctx = ctx
    self.tiles = TILES[ctx.mapId]
    self:reset()
end

function Shogi:reset()
    --[[
    self.charas = {
        {id = 1, i = 9, j = 3, team = "red",  hp = 100},
        {id = 2, i = 8, j = 2, team = "red",  hp = 100},
        {id = 3, i = 7, j = 5, team = "red",  hp = 100},
        {id = 4, i = 1, j = 3, team = "blue", hp = 100},
        {id = 5, i = 2, j = 4, team = "blue", hp = 100},
        {id = 6, i = 3, j = 1, team = "blue", hp = 100},
    }
    ]]
    local himes = us.select(CHARAS, function(_, e) return e.job == "hime" end)
    local others = us.select(CHARAS, function(_, e) return e.job ~= "hime" end)
    self.party = {
        red  = {himes[(self.ctx.random() % #himes) + 1]},
        blue = {himes[(self.ctx.random() % #himes) + 1]}
    }
    for _ = 1, 5 do
        self.party.red[#self.party.red + 1] = others[(self.ctx.random() % #others) + 1]
        self.party.blue[#self.party.blue + 1] = others[(self.ctx.random() % #others) + 1]
    end
    self.charas = {}
    self.chips = {}
end

function Shogi:getParty()
    return self.party
end

function Shogi:commitForm(form)
    local charaId = 1
    local apply = function(team)
        for _, e in ipairs(form[team]) do
            e = string.split(e, ",")
            local master = self.party[team][tonumber(e[1])]
            local chara = {
                id = charaId,
                i = tonumber(e[2]),
                j = tonumber(e[3]),
                team = team,
                hp = 100,
            }
            setmetatable(chara, {__index = master})
            self.charas[#self.charas + 1] = chara
            charaId = charaId + 1
        end
    end
    apply("red")
    apply("blue")
    self.chips = {
        red = self:drawChips(),
        blue = self:drawChips(),
    }
end

function Shogi:drawChips()
    return us(CHIPS):keys():map(function(_, e)
        return {val = e, w = self.ctx.random()}
    end):sort(function(a, b)
        return a.w < b.w
    end):map(function(_, e)
        return e.val
    end):value()
end

function Shogi:getTiles()
    return self.tiles
end

function Shogi:getCharas()
    return self.charas
end

function Shogi:getChips(team)
    return us.first(self.chips[team], 4)
end

function Shogi:processTurn(commands)
    local acts = {}
    for i, e in ipairs(commands) do
        local charaId = tonumber(e:sub(1, 1))
        local chipIdx = tonumber(e:sub(2, 2))
        local friend = us.findWhere(self.charas, {id = charaId})
        local chip = table.remove(self.chips[friend.team], chipIdx)
        if friend.hp <= 0 then
            acts[#acts + 1] = {type = "dead", actor = charaId, chip = chipIdx}
        else
            acts[#acts + 1] = {type = "chip", actor = charaId, chip = chipIdx}
            if chip == "skill" then
                if friend.job == "hime" then
                    self:move(us.findWhere(self.charas, {job = "hime", team = (friend.team == "red" and "blue" or "red")}), {i = -2, j = 0}, acts)
                elseif friend.job == "ninja" then
                    for _, dir in ipairs({{i = -1, j = -1}, {i = -1, j = -1}, {i = -1, j = -1}}) do
                        if self:move(friend, dir, acts) then break end
                    end
                elseif friend.job == "witch" then
                    local target = self:farEnemies(friend)[1]
                    friend.i, friend.j, target.i, target.j = target.i, target.j, friend.i, friend.j
                    acts[#acts + 1] = {
                        type = "swap",
                        actor = friend.id,
                        target = target.id,
                        fi = target.i,
                        fj = target.j,
                        ti = friend.i,
                        tj = friend.j,
                    }
                end
            else
                for _, dir in ipairs(CHIPS[chip]) do
                    if self:move(friend, dir, acts) then break end
                end
            end
        end
    end
    if #self.chips.red < 1 then self.chips.red = self:drawChips() end
    if #self.chips.blue < 1 then self.chips.blue = self:drawChips() end
    return acts
end

function Shogi:move(friend, dir, acts)
    local ni = friend.i + dir.i * (friend.team == "red" and 1 or -1)
    local nj = friend.j + dir.j * (friend.team == "red" and 1 or -1)
    if ni < 1 or ni > #self.tiles or nj < 1 or nj > #self.tiles[1] or self.tiles[ni][nj] == 0 then
        -- out of bounds
        acts[#acts + 1] = {type = "ob", i = ni, j = nj, actor = friend.id}
        friend.hp = 0
        if friend.job == "hime" then
            acts[#acts + 1] = {type = "end", lose = friend.team}
        end
        return true
    end
    local hit = us.detect(self.charas, function(e)
        return e.i == ni and e.j == nj and e.hp > 0
    end)
    acts[#acts + 1] = {type = "move", fi = friend.i, fj = friend.j, actor = friend.id}
    acts[#acts].i = ni
    acts[#acts].j = nj
    if hit then
        local target = self.charas[hit]
        local dmg = 40 * friend.attack / target.block * COLOR_RATE[friend.color][target.color]
        acts[#acts].hp = target.hp
        acts[#acts].dmg = dmg
        target.hp = math.max(target.hp - dmg, 0)
        if target.hp <= 0 then
            friend.i = ni
            friend.j = nj
        end
        acts[#acts].type = "attack"
        acts[#acts].target = target.id
        if target.job == "hime" and target.hp <= 0 then
            acts[#acts + 1] = {type = "end", lose = target.team}
        end
        return true
    end
    friend.i = ni
    friend.j = nj
    if friend.job == "hime" then
        if self.tiles[ni][nj] == BLUE_CAMP and friend.team == "red" then
            acts[#acts + 1] = {type = "end", lose = "blue"}
            return true
        elseif self.tiles[ni][nj] == RED_CAMP and friend.team == "blue" then
            acts[#acts + 1] = {type = "end", lose = "red"}
            return true
        end
    end
    return false
end

function Shogi:farEnemies(who)
    local dirs = {
        {i = -2, j =  0},
        {i = -1, j =  1},
        {i = -1, j = -1},
        {i =  1, j =  1},
        {i =  1, j = -1},
        {i =  2, j =  0},
    }
    if who.team == "blue" then
        dirs = us.reverse(dirs)
    end
    local dist = us.map(self.tiles, function(_, e)
        return us.rep(-1, #e)
    end)
    local currentDist = 0
    dist[who.i][who.j] = 0
    local queue = {{i = who.i, j = who.j}}
    while #queue > 0 do
        local c = table.remove(queue, 1)
        for _, dir in ipairs(dirs) do
            local ni, nj = c.i + dir.i, c.j + dir.j
            if ni > 0 and ni <= #dist and nj > 0 and nj <= #dist[1] and dist[ni][nj] == -1 then
                currentDist = currentDist + 1
                dist[ni][nj] = currentDist
                table.insert(queue, {i = ni, j = nj})
            end
        end
    end
    return us(self.charas):select(function(i, e)
        return e.team ~= who.team
    end):sort(function(a, b)
        return dist[a.i][a.j] > dist[b.i][b.j]
    end):value()
end

function Shogi.new(...)
    local obj = {}
    setmetatable(obj, {__index = Shogi})
    obj:ctor(...)
    return obj
end

return Shogi

