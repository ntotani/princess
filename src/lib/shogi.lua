local us = require("lib.moses")
local Shogi = {}

local PLANET_RATE = {
    sun = {sun = 1.0, mon = 1.0, mar = 1.0, mer = 1.0, jup = 1.0, ven = 1.0, sat = 1.0},
    mon = {sun = 1.0, mon = 1.0, mar = 1.0, mer = 1.0, jup = 1.0, ven = 1.0, sat = 1.0},
    mar = {sun = 1.0, mon = 1.0, mar = 1.0, mer = 0.5, jup = 2.0, ven = 1.0, sat = 1.0},
    mer = {sun = 1.0, mon = 1.0, mar = 2.0, mer = 0.5, jup = 0.5, ven = 1.0, sat = 1.0},
    jup = {sun = 1.0, mon = 1.0, mar = 0.5, mer = 2.0, jup = 1.0, ven = 1.0, sat = 1.0},
    ven = {sun = 1.0, mon = 1.0, mar = 1.0, mer = 1.0, jup = 1.0, ven = 1.0, sat = 1.0},
    sat = {sun = 1.0, mon = 1.0, mar = 1.0, mer = 1.0, jup = 1.0, ven = 1.0, sat = 1.0},
}

local CHARAS = {
    {id = "1", name = "姫", planet = "sun", pskill = "1", askill = "1", act = 2, power = 60, defense = 50, resist = 80},
    {id = "3", name = "浪人", planet = "mar", pskill = "3", askill = "3", act = 0, power = 80, defense = 80, resist = 60},
}

local PSKILL = {
    {id = "1", name = "癒やし", desc = "周りの駒が毎ターン@ずつ回復する", at = 6},
    {id = "2", name = "癒やし", desc = "周りの駒が毎ターン@ずつ回復する", at = 12},
    {id = "3", name = "一矢", desc = "この駒を倒した相手に攻撃する"},
}

local ASKILL = {
    {id = "1", name = "全体回復", desc = "味方全員を@回復する", at = 30},
    {id = "2", name = "全体回復", desc = "味方全員を@回復する", at = 70},
    {id = "3", name = "突撃", desc = "攻撃力2倍で2マス前進"},
    {id = "4", name = "姫寄せ", desc = "敵の姫は前進する"},
    {id = "5", name = "帰還", desc = "自分の本陣に移動する"},
    {id = "6", name = "横断", desc = "↖に3マス進む"},
    {id = "7", name = "突進", desc = "目の前の駒を後退させながら2マス前進"},
    {id = "8", name = "猛進", desc = "前方の駒を後退させながら2マス前進"},
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
    local himes = us.select(CHARAS, function(_, e) return self:isHime(e) end)
    local others = us.select(CHARAS, function(_, e) return not self:isHime(e) end)
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

function Shogi:isHime(chara)
    return chara.name == "姫" or chara.name == "姫将"
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
                master = master,
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

function Shogi:findChara(i, j)
    local hit = us.detect(self.charas, function(e)
        return e.i == i and e.j == j and e.hp > 0
    end)
    if hit then
        return self.charas[hit]
    end
    return nil
end

function Shogi:processTurn(commands)
    local acts = {}
    for i, e in ipairs(commands) do
        local charaId = tonumber(e:sub(1, 1))
        local chipIdx = tonumber(e:sub(2, 2))
        local friend = us.findWhere(self.charas, {id = charaId})
        local chip = table.remove(self.chips[friend.team], chipIdx)
        if friend.hp <= 0 then
            acts[#acts + 1] = {type = "miss", actor = charaId, chip = chipIdx}
        else
            acts[#acts + 1] = {type = "chip", actor = charaId, chip = chipIdx}
            if chip == "skill" then
                local method = "processAskill_" .. friend.askill
                self[method](self, friend, acts)
            else
                for _, dir in ipairs(CHIPS[chip]) do
                    if self:move(friend, dir, acts) then break end
                end
            end
        end
    end
    for _, e in ipairs(self.charas) do
        if e.pskill == "1" or e.pskill == "2" then
            local dmg = us.findWhere(PSKILL, {id = e.pskill}).at
            for _, dir in ipairs(self:getDirs(e.team)) do
                local target = self:findChara(e.i + dir.i, e.j + dir.j)
                if target and target.hp < 100 then
                    self:heal(e, target, dmg, acts)
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
        if self:isHime(friend) then
            acts[#acts + 1] = {type = "end", lose = friend.team}
        end
        return true
    end
    local hit = self:findChara(ni, nj)
    if hit then
        if friend.act == 2 then
            self:heal(friend, hit, nil, acts)
        else
            self:attack(friend, hit, nil, acts)
        end
        return true
    end
    acts[#acts + 1] = {type = "move", fi = friend.i, fj = friend.j, actor = friend.id}
    acts[#acts].i = ni
    acts[#acts].j = nj
    return self:moveTo(friend, ni, nj, acts)
end

function Shogi:moveTo(actor, di, dj, acts)
    actor.i = di
    actor.j = dj
    if self:isHime(actor) then
        if self.tiles[di][dj] == BLUE_CAMP and actor.team == "red" then
            acts[#acts + 1] = {type = "end", lose = "blue"}
            return true
        elseif self.tiles[di][dj] == RED_CAMP and actor.team == "blue" then
            acts[#acts + 1] = {type = "end", lose = "red"}
            return true
        end
    end
    return false
end

function Shogi:calcDamage(actor, target)
    local defense = actor.act == 0 and target.defense or target.resist
    return math.floor(40 * actor.power / defense * PLANET_RATE[actor.planet][target.planet])
end

function Shogi:attack(actor, target, dmg, acts)
    if dmg == nil then
        dmg = self:calcDamage(actor, target)
    end
    table.insert(acts, {
        type = "attack",
        actor = actor.id,
        fi = actor.i,
        fj = actor.j,
        target = target.id,
        i = target.i,
        j = target.j,
        hp = target.hp,
        dmg = dmg,
    })
    target.hp = math.max(target.hp - dmg, 0)
    if target.hp <= 0 then
        if self:isHime(target) then
            table.insert(acts, {type = "end", lose = target.team})
        else
            local fin = self:moveTo(actor, target.i, target.j, acts)
            if not fin and target.pskill == "3" and actor.hp > 0 then
                self:attack(target, actor, nil, acts)
            end
        end
    end
end

function Shogi:heal(actor, target, dmg, acts)
    if dmg == nil then
        dmg = self:calcDamage(actor, target)
    end
    table.insert(acts, {
        type = "heal",
        actor = actor.id,
        fi = actor.i,
        fj = actor.j,
        target = target.id,
        i = target.i,
        j = target.j,
        hp = target.hp,
        dmg = dmg
    })
    target.hp = math.min(target.hp + dmg, 100)
end

function Shogi:farEnemies(who)
    local dirs = self:getDirs(who.team)
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

function Shogi:getDirs(team)
    local dirs = {
        {i = -2, j =  0},
        {i = -1, j =  1},
        {i = -1, j = -1},
        {i =  1, j =  1},
        {i =  1, j = -1},
        {i =  2, j =  0},
    }
    if team == "blue" then
        dirs = us.reverse(dirs)
    end
    return dirs
end

function Shogi:processAskillTeamHeal(actor, acts, askillId) -- 全体回復
    for _, e in ipairs(self:getDirs(actor.team)) do
        local ci, cj = actor.i + e.i, actor.j + e.j
        local target = us.findWhere(self.charas, {i = ci, j = cj})
        if target then
            local dmg = us.findWhere(ASKILL, {id = askillId}).at
            self:heal(actor, target, dmg, acts)
        end
    end
end

function Shogi:processAskill_1(actor, acts)
    self:processAskillTeamHeal(actor, acts, "1")
end

function Shogi:processAskill_2(actor, acts)
    self:processAskillTeamHeal(actor, acts, "2")
end

function Shogi:processAskill_3(actor, acts) -- 突撃
    local prevPower = actor.power
    actor.power = prevPower * 2
    for _, dir in ipairs({{i = -2, j = 0}, {i = -2, j = 0}}) do
        if self:move(actor, dir, acts) then break end
    end
    actor.power = prevPower
end

function Shogi:processAskill_4(actor, acts) -- 姫寄せ
    local target = us.detect(self.charas, function(e)
        return self:isHime(e) and e.team ~= actor.team
    end)
    self:move(self.charas[target], {i = -2, j = 0}, acts)
end

function Shogi:processAskill_5(actor, acts) -- 帰還
    local camp = actor.team == "red" and RED_CAMP or BLUE_CAMP
    local ci, cj
    for i = 1, #self.tiles do
        for j = 1, #self.tiles[i] do
            if self.tiles[i][j] == camp then
                ci = i
                cj = j
                break
            end
        end
    end
    if self:findChara(ci, cj) then
        acts[#acts].type = "miss"
    else
        acts[#acts + 1] = {type = "move", actor = actor.id, fi = actor.i, fj = actor.j, i = ci, j = cj}
        actor.i = ci
        actor.j = cj
    end
end

function Shogi:processAskill_6(actor, acts) -- 横断
    for _, dir in ipairs({{i = -1, j = -1}, {i = -1, j = -1}, {i = -1, j = -1}}) do
        if self:move(actor, dir, acts) then break end
    end
end

function Shogi:processAskill_7(actor, acts) -- 突進
    for _, dir in ipairs({{i = -2, j = 0}, {i = -2, j = 0}}) do
        if self:move(actor, dir, acts) then
            local tail = acts[#acts]
            if tail.type == "attack" then
                local target = us.findWhere(self.charas, {id = tail.target})
                if target.hp > 0 then
                    local vi = actor.team == target.team and -2 or 2
                    self:move(target, {i = vi, j = 0}, acts)
                end
            end
            break
        end
    end
end

function Shogi:processAskill_8(actor, acts) -- 猛進
    for _, dir in ipairs({{i = -2, j = 0}, {i = -2, j = 0}}) do
        local prevI, prevJ = actor.i, actor.j
        local stop = self:move(actor, dir, acts)
        if stop then
            local tail = acts[#acts]
            if tail.type == "attack" then
                local target = us.findWhere(self.charas, {id = tail.target})
                if target.hp > 0 then
                    local vi = actor.team == target.team and -2 or 2
                    self:move(target, {i = vi, j = 0}, acts)
                end
            end
        end
        local sign = actor.team == "red" and 1 or -1
        for _, side in ipairs({{i = -sign, j = sign}, {i = -sign, j = -sign}}) do
            local target = self:findChara(prevI + side.i, prevJ + side.j)
            if target then
                local v = target.team == "red" and side or {i = -side.i, j = -side.j}
                self:move(target, v, acts)
            end
        end
        if stop then break end
    end
end

function Shogi:processAskill_111(actor, acts) -- 入れ替え
    local target = self:farEnemies(actor)[1]
    actor.i, actor.j, target.i, target.j = target.i, target.j, actor.i, actor.j
    acts[#acts + 1] = {
        type = "swap",
        actor = actor.id,
        target = target.id,
        fi = target.i,
        fj = target.j,
        ti = actor.i,
        tj = actor.j,
    }
end

function Shogi.new(...)
    local obj = {}
    setmetatable(obj, {__index = Shogi})
    obj:ctor(...)
    return obj
end

return Shogi

