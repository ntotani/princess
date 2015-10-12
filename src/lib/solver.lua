local us = require("lib.moses")
local Shogi = require("lib.shogi")
local Solver = {}

local function level2form_(shogi, chara, team)
    local form = {}
    local master2party = {}
    for _, e in ipairs(chara) do
        if not master2party[e.id] then
            table.insert(shogi.party[team], us.findWhere(shogi.getCharaMaster(), {id = e.id}))
            master2party[e.id] = #shogi.party[team]
        end
        table.insert(form, string.format("%d,%d,%d", master2party[e.id], e.i, e.j))
    end
    return form
end

function Solver.level2shogi(random, level)
    local shogi = Shogi.new({random = random, mapId = level.map})
    shogi:setDeck(level.friend.deck)
    shogi.party = {red = {}, blue = {}}
    shogi:commitForm({
        red = level2form_(shogi, level.friend.chara, "red"),
        blue = level2form_(shogi, level.enemy.chara, "blue")
    })
    return shogi
end

function Solver.solve(shogi, charaId, chipIdx)
    local enemies = us.select(shogi.charas, function(_, e) return e.team == "blue" end)
    local chips = shogi:getChips("blue")
    local scores = {}
    for i, chara in ipairs(enemies) do
        for j, chip in ipairs(chips) do
            local act = chara.id .. j
            local copy = us.clone(shogi)
            setmetatable(copy, {__index = Shogi})
            for _, e in ipairs(copy.charas) do
                setmetatable(e, {__index = e.master})
            end
            copy:processTurn({charaId .. chipIdx, act})
            table.insert(scores, {act = act, score = Solver.evalScore(copy)})
        end
    end
    table.sort(scores, function(a, b) return a.score > b.score end)
    return scores[1].act
end

function Solver.evalScore(shogi)
    -- そもそも詰んでる
    local charas = shogi:getCharas()
    local redHime = us.detect(charas, function(e)
        return e.team == "red" and shogi:isHime(e)
    end)
    if redHime then
        redHime = charas[redHime]
        if redHime.hp <= 0 then
            return 4294967295
        end
        if shogi:getTiles()[redHime.i][redHime.j] == Shogi.BLUE_CAMP then
            return 0
        end
    end
    local blueHime = us.detect(charas, function(e)
        return e.team == "blue" and shogi:isHime(e)
    end)
    if blueHime then
        blueHime = charas[blueHime]
        if blueHime.hp <= 0 then
            return 0
        end
        if shogi:getTiles()[blueHime.i][blueHime.j] == Shogi.RED_CAMP then
            return 4294967295
        end
    end
    local score = 0

    -- 姫の体力差
    if blueHime and redHime then
        score = score + (blueHime.hp - redHime.hp)
    end

    -- 敵味方の姫からゴールまでの距離で加減点
    if redHime then
        local dist = Solver.dist2camp(shogi, redHime, Shogi.BLUE_CAMP)
        score = score - dist
    end
    if blueHime then
        local dist = Solver.dist2camp(shogi, blueHime, Shogi.RED_CAMP)
        score = score + dist
    end

    -- コマ数の差
    -- 体力の差
    -- 駒同士の相性と距離
    return score
end

function Solver.dist2camp(shogi, hime, camp)
    local dist = shogi:calcDist(hime)
    for i = 1, #dist do
        for j = 1, #dist[i] do
            if dist[i][j] == camp then
                return dist[i][j]
            end
        end
    end
end

return Solver

