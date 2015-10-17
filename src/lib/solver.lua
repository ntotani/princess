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
    shogi:setDeck("red", level.friend.deck)
    shogi:setDeck("blue", level.enemy.deck)
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
        local ci, cj = shogi:findTile(Shogi.BLUE_CAMP)
        local path = shogi:calcPath(redHime, ci, cj)
        if path then
            -- ToDo 距離3までのみを考慮すべきなのとキャンプに他の駒がいるか
            score = score - #path
        end
    end
    if blueHime then
        local ci, cj = shogi:findTile(Shogi.RED_CAMP)
        local path = shogi:calcPath(blueHime, ci, cj)
        if path then
            score = score + #path
        end
    end

    -- コマ数の差
    local reds = us.select(charas, function(_, e) return e.team == "red" and e.hp > 0 end)
    local blues = us.select(charas, function(_, e) return e.team == "blue" and e.hp > 0 end)
    score = score + (#blues - #reds)

    -- 体力の差
    score = score + (us.reduce(blues, function(p, e) return p + e.hp end, 0) - us.reduce(reds, function(p, e) return p + e.hp end, 0))

    -- 駒同士の相性と距離
    return score
end

return Solver

