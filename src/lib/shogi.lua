local us = require("lib.moses")
local Shogi = {}

local PLANET_RATE = {
    sun = {sun = 1.0, mon = 1.0, mar = 1.0, mer = 1.0, jup = 1.0, ven = 1.0, sat = 1.0},
    mon = {sun = 1.0, mon = 1.0, mar = 1.0, mer = 1.0, jup = 1.0, ven = 1.0, sat = 1.0},
    mar = {sun = 2.0, mon = 1.0, mar = 1.0, mer = 0.5, jup = 2.0, ven = 1.0, sat = 0.5},
    mer = {sun = 2.0, mon = 1.0, mar = 2.0, mer = 0.5, jup = 0.5, ven = 1.0, sat = 0.5},
    jup = {sun = 2.0, mon = 1.0, mar = 0.5, mer = 2.0, jup = 1.0, ven = 1.0, sat = 0.5},
    ven = {sun = 1.0, mon = 1.0, mar = 1.0, mer = 1.0, jup = 1.0, ven = 1.0, sat = 1.0},
    sat = {sun = 0.5, mon = 1.0, mar = 1.0, mer = 1.0, jup = 1.0, ven = 1.0, sat = 1.0},
}

local CHARAS = {
    {id = "1", name = "姫", planet = "sun", pskill = "1", askill = "1", act = 2, power = 60, defense = 50, resist = 80, evo = "2"},
    {id = "2", name = "姫将", planet = "sun", pskill = "2", askill = "2", act = 2, power = 100, defense = 60, resist = 100},
    {id = "3", name = "浪人", planet = "mar", pskill = "3", askill = "3", act = 0, power = 80, defense = 80, resist = 60, evo = "4"},
    {id = "4", name = "侍", planet = "mar", pskill = "4", askill = "3", act = 0, power = 130, defense = 100, resist = 70},
    {id = "5", name = "占い師", planet = "mer", pskill = "5", askill = "4", act = 1, power = 70, defense = 60, resist = 90, evo = "6"},
    {id = "6", name = "陰陽師", planet = "mer", pskill = "6", askill = "5", act = 1, power = 100, defense = 70, resist = 110},
    {id = "7", name = "足軽", planet = "jup", pskill = "7", askill = "6", act = 0, power = 70, defense = 50, resist = 50, evo = "8"},
    {id = "8", name = "忍者", planet = "jup", pskill = "8", askill = "5", act = 0, power = 120, defense = 60, resist = 60},
    {id = "9", name = "鎧", planet = "sat", pskill = "9", askill = "7", act = 0, power = 60, defense = 100, resist = 80, evo = "10"},
    {id = "10", name = "大鎧", planet = "sat", pskill = "10", askill = "8", act = 0, power = 70, defense = 120, resist = 100},
}

local PSKILL = {
    {id = "1", name = "癒やし", desc = "周りの駒が毎ターン@ずつ回復する", at = 6},
    {id = "2", name = "癒やし", desc = "周りの駒が毎ターン@ずつ回復する", at = 12},
    {id = "3", name = "一矢", desc = "この駒を倒した相手に攻撃する"},
    {id = "4", name = "兜の緒", desc = "駒を倒したら能力が上がる"},
    {id = "5", name = "射手", desc = "@マス先まで攻撃できる", at = 1},
    {id = "6", name = "射手", desc = "@マス先まで攻撃できる", at = 2},
    {id = "7", name = "保険", desc = "体力満タンから倒されても生き残る"},
    {id = "8", name = "倍速", desc = "二回ずつ行動できる"},
    {id = "9", name = "反動", desc = "この駒を攻撃した駒を弾き返す"},
    {id = "10", name = "仁王", desc = "周囲の攻撃を自分に向ける"},
}

local ASKILL = {
    {id = "1", name = "全体回復", desc = "味方全員を@回復する", at = 30},
    {id = "2", name = "全体回復", desc = "味方全員を@回復する", at = 70},
    {id = "3", name = "突撃", desc = "攻撃力2倍で2マス前進"},
    {id = "4", name = "姫寄せ", desc = "敵の姫は前進する"},
    {id = "5", name = "帰還", desc = "自分の本陣に移動する"},
    {id = "6", name = "横断", desc = "左前に3マス進む"},
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
    {0, 1, 0, 1, 0, 6, 0},
    {1, 0, 1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1, 0, 1},
    {0, 5, 0, 1, 0, 1, 0},
    {0, 0, 1, 0, 1, 0, 0},
    {0, 0, 0, 2, 0, 0, 0},
}
}
Shogi.RED_CAMP = 2
Shogi.BLUE_CAMP = 3
Shogi.RED_EVO = 5
Shogi.BLUE_EVO = 6

function Shogi.getAskill()
    return ASKILL
end

function Shogi.getPskill()
    return PSKILL
end

function Shogi.getCharaMaster()
    return CHARAS
end

function Shogi.getPlanetRate()
    return PLANET_RATE
end

function Shogi:ctor(ctx)
    self.ctx = ctx
    self.tiles = us.clone(TILES[ctx.mapId])
    self.deck = {red = us.keys(CHIPS), blue = us.keys(CHIPS)}
    self:reset()
end

function Shogi:reset()
    local himes = us.select(CHARAS, function(_, e) return self:isHime(e) and e.evo end)
    local others = us.select(CHARAS, function(_, e) return not self:isHime(e) and e.evo end)
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

function Shogi:setParties(red, blue)
    self.party = {
        red = us.map(red, function(_, e) return us.findWhere(CHARAS, {id = e}) end),
        blue = us.map(blue, function(_, e) return us.findWhere(CHARAS, {id = e}) end),
    }
end

function Shogi:setDeck(team, deck)
    self.deck[team] = deck
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
                pump = {power = 1.0, defense = 1.0, resist = 1.0},
            }
            setmetatable(chara, {__index = master})
            self.charas[#self.charas + 1] = chara
            charaId = charaId + 1
        end
    end
    apply("red")
    apply("blue")
    self.chips = {
        red = self:drawChips("red"),
        blue = self:drawChips("blue"),
    }
end

function Shogi:drawChips(team)
    return us(self.deck[team]):map(function(_, e)
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

function Shogi:findTile(tile)
    for i = 1, #self.tiles do
        for j = 1, #self.tiles[i] do
            if self.tiles[i][j] == tile then
                return i, j
            end
        end
    end
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
                local dirs = CHIPS[chip]
                if friend.pskill == "8" then
                    table.insert(acts, {type = "pskill", actor = friend.id, id = "8"})
                    dirs = {}
                    for _, e in ipairs(CHIPS[chip]) do
                        table.insert(dirs, e)
                        table.insert(dirs, e)
                    end
                end
                for _, dir in ipairs(dirs) do
                    if self:move(friend, dir, acts) then break end
                end
            end
        end
    end
    for _, e in ipairs(self.charas) do
        if e.pskill == "1" or e.pskill == "2" then
            local dmg = us.findWhere(PSKILL, {id = e.pskill}).at
            local actInsert = false
            for _, dir in ipairs(self:getDirs(e.team)) do
                local target = self:findChara(e.i + dir.i, e.j + dir.j)
                if target and target.hp < 100 then
                    if not actInsert then
                        actInsert = true
                        table.insert(acts, {type = "pskill", actor = e.id, id = e.pskill})
                    end
                    self:heal(e, target, dmg, acts)
                end
            end
        end
    end
    if #self.chips.red < 1 then self.chips.red = self:drawChips("red") end
    if #self.chips.blue < 1 then self.chips.blue = self:drawChips("blue") end
    return acts
end

function Shogi:move(friend, dir, acts)
    local di = dir.i * (friend.team == "red" and 1 or -1)
    local dj = dir.j * (friend.team == "red" and 1 or -1)
    local ni = friend.i + di
    local nj = friend.j + dj
    local hit = self:findChara(ni, nj)
    if (friend.pskill == "5" or friend.pskill == "6") and not hit then
        for i = 1, us.findWhere(PSKILL, {id = friend.pskill}).at do
            hit = self:findChara(ni + di * i, nj + dj * i)
            if hit then
                table.insert(acts, {type = "pskill", actor = friend.id, id = friend.pskill})
                break
            end
        end
    end
    if hit then
        if friend.act == 2 then
            self:heal(friend, hit, nil, acts)
        else
            self:attack(friend, hit, nil, acts)
        end
        return true
    end
    return self:moveTo(friend, ni, nj, acts)
end

function Shogi:moveTo(actor, di, dj, acts)
    if di < 1 or di > #self.tiles or dj < 1 or dj > #self.tiles[1] or self.tiles[di][dj] == 0 then
        -- out of bounds
        acts[#acts + 1] = {type = "ob", actor = actor.id, i = di, j = dj}
        actor.hp = 0
        if self:isHime(actor) or not us.any(self.charas, function(e) return e.team == actor.team and e.hp > 0 end) then
            acts[#acts + 1] = {type = "end", lose = actor.team}
        end
        return true
    end
    if self:findChara(di, dj) then
        return true
    end
    table.insert(acts, {type = "move", actor = actor.id, fi = actor.i, fj = actor.j, i = di, j = dj})
    return self:commitMove(actor, di, dj, acts)
end

function Shogi:commitMove(actor, di, dj, acts)
    actor.i = di
    actor.j = dj
    if self:isHime(actor) then
        if self.tiles[di][dj] == Shogi.BLUE_CAMP and actor.team == "red" then
            acts[#acts + 1] = {type = "end", lose = "blue"}
            return true
        elseif self.tiles[di][dj] == Shogi.RED_CAMP and actor.team == "blue" then
            acts[#acts + 1] = {type = "end", lose = "red"}
            return true
        end
    end
    if (self.tiles[di][dj] == Shogi.BLUE_EVO and actor.team == "red" or
        self.tiles[di][dj] == Shogi.RED_EVO and actor.team == "blue") and actor.evo then
        local evo = us.findWhere(CHARAS, {id = actor.evo})
        table.insert(acts, {type = "evo", actor = actor.id, from = actor.master.id, to = evo.id})
        setmetatable(actor, {__index = evo})
        actor.master = evo
    end
    return false
end

function Shogi:calcDamage(actor, target)
    local attack = actor.power * actor.pump.power
    local defense = actor.act == 0 and target.defense * target.pump.defense or target.resist * target.pump.resist
    return math.max(math.floor(40 * attack / defense * PLANET_RATE[actor.planet][target.planet]), 1)
end

function Shogi:attack(actor, target, dmg, acts)
    for _, e in ipairs(self:getDirs(target.team)) do
        local c = self:findChara(target.i + e.i, target.j + e.j)
        if c and c.pskill == "10" and c.team == target.team and c.id ~= actor.id then
            table.insert(acts, {type = "pskill", actor = c.id, id = "10"})
            table.insert(acts, {
                type = "swap",
                actor = c.id,
                target = target.id,
                fi = c.i,
                fj = c.j,
                ti = target.i,
                tj = target.j,
            })
            local ti, tj = target.i, target.j
            if self:commitMove(target, c.i, c.j, acts) then return end
            if self:commitMove(c, ti, tj, acts) then return end
            target = c
            break
        end
    end
    if dmg == nil then
        dmg = self:calcDamage(actor, target)
    end
    if target.pskill == "7" and target.hp >= 100 and dmg > target.hp then
        table.insert(acts, {type = "pskill", actor = target.id, id = "7"})
        dmg = 99
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
        if self:isHime(target) or not us.any(self.charas, function(e) return e.team == target.team and e.hp > 0 end) then
            table.insert(acts, {type = "end", lose = target.team})
        elseif self:isNextTo(actor, target) then
            if target.pskill == "3" and actor.hp > 0 then
                table.insert(acts, {type = "pskill", actor = target.id, id = "3"})
                self:attack(target, actor, nil, acts)
            end
            if actor.pskill == "4" and actor.hp > 0 then
                table.insert(acts, {type = "pskill", actor = actor.id, id = "4"})
                actor.pump.power = actor.pump.power * 1.5
            end
            if actor.hp > 0 then
                self:moveTo(actor, target.i, target.j, acts)
            end
        end
    elseif target.pskill == "9" and self:isNextTo(target, actor) then
        table.insert(acts, {type = "pskill", actor = target.id, id = "9"})
        self:moveTo(actor, actor.i + (actor.i - target.i), actor.j + (actor.j - target.j), acts)
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

function Shogi:calcDist(who)
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
    return dist
end

function Shogi:calcPath(who, gi, gj)
    if self:findChara(gi, gj) then return nil end
    local dirs = self:getDirs(who.team)
    local memo = us.map(self.tiles, function(_, e)
        return us.rep({dist = -1, fi = -1, fj = -1}, #e)
    end)
    local currentDist = 0
    memo[who.i][who.j].dist = 0
    local queue = {{i = who.i, j = who.j}}
    while #queue > 0 do
        local c = table.remove(queue, 1)
        for _, dir in ipairs(dirs) do
            local ni, nj = c.i + dir.i, c.j + dir.j
            if ni > 0 and ni <= #memo and nj > 0 and nj <= #memo[ni] and memo[ni][nj].dist == -1 and not self:findChara(ni, nj) then
                currentDist = currentDist + 1
                memo[ni][nj] = {dist = currentDist, fi = c.i, fj = c.j}
                table.insert(queue, {i = ni, j = nj})
            end
        end
    end
    if memo[gi][gj].dist == -1 then return nil end
    local path, ci, cj = {}, gi, gj
    while ci ~= who.i or cj ~= who.j do
        table.insert(path, {i = ci, j = cj})
        ci, cj = memo[ci][cj].fi, memo[ci][cj].fj
    end
    return path
end

function Shogi:farEnemies(who)
    local dist = self:calcDist(who)
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

function Shogi:isNextTo(a, b)
    for _, e in ipairs(self:getDirs(a.team)) do
        if a.i + e.i == b.i and a.j + e.j == b.j then
            return true
        end
    end
    return false
end

function Shogi:processAskillTeamHeal(actor, acts, askillId) -- 全体回復
    local dmg = us.findWhere(ASKILL, {id = askillId}).at
    for _, e in ipairs(self.charas) do
        if e.team == actor.team and 0 < e.hp and e.hp < 100 then
            self:heal(actor, e, dmg, acts)
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
    actor.pump.power = actor.pump.power * 2
    for _, dir in ipairs({{i = -2, j = 0}, {i = -2, j = 0}}) do
        if self:move(actor, dir, acts) then break end
    end
    actor.pump.power = actor.pump.power / 2
end

function Shogi:processAskill_4(actor, acts) -- 姫寄せ
    local target = us.detect(self.charas, function(e)
        return self:isHime(e) and e.team ~= actor.team
    end)
    self:move(self.charas[target], {i = -2, j = 0}, acts)
end

function Shogi:processAskill_5(actor, acts) -- 帰還
    local camp = actor.team == "red" and Shogi.RED_CAMP or Shogi.BLUE_CAMP
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
                    local vi = actor.team == "red" and -2 or 2
                    self:moveTo(target, target.i + vi, target.j, acts)
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
                    local vi = actor.team == "red" and -2 or 2
                    self:moveTo(target, target.i + vi, target.j, acts)
                end
            end
        end
        local sign = actor.team == "red" and 1 or -1
        for _, side in ipairs({{i = -sign, j = sign}, {i = -sign, j = -sign}}) do
            local target = self:findChara(prevI + side.i, prevJ + side.j)
            if target then
                self:moveTo(target, target.i + side.i, target.j + side.j, acts)
                if acts[#acts].type == "end" then
                    stop = true
                    break
                end
            end
        end
        if stop then break end
    end
end

function Shogi:processAskill_111(actor, acts) -- 入れ替え
    local target = self:farEnemies(actor)[1]
    acts[#acts + 1] = {
        type = "swap",
        actor = actor.id,
        target = target.id,
        fi = actor.i,
        fj = actor.j,
        ti = target.i,
        tj = target.j,
    }
    local ti, tj = target.i, target.j
    if not self:commitMove(target, actor.i, actor.j, acts) then
        self:commitMove(actor, ti, tj, acts)
    end
end

function Shogi.new(...)
    local obj = {}
    setmetatable(obj, {__index = Shogi})
    obj:ctor(...)
    return obj
end

return Shogi

