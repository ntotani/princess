local luaunit = require("test.lib.luaunit")
local us = require("src.lib.moses")

TestSolver = {}

function TestSolver:setUp()
    self.solver = require("lib.solver")
    self.shogi = self.solver.level2shogi(function() return 0 end, {
        message = "チップで駒を動かそう",
        map = 1,
        friend = {
            chara = {{id = "1", i = 9, j = 3}, {id = "3", i = 8, j = 2}},
            deck = {"f", "f"}
        },
        enemy = {
            chara = {{id = "1", i = 1, j = 3}, {id = "3", i = 2, j = 4}},
            deck = {"f", "f"}
        }
    })
end

function TestSolver:testSolve()
    local act = self.solver.solve(self.shogi, 1, 1)
    luaunit.assertEquals(act, "42")
end

function TestSolver:testScoreIsEnd()
    local scoreMax = 432000000
    local redHime = self.shogi.charas[1]
    local blueHime = self.shogi.charas[3]
    redHime.i = 7
    blueHime.i = 9
    luaunit.assertEquals(self.solver.evalScore(self.shogi), scoreMax)
    redHime.i = 1
    blueHime.i = 3
    luaunit.assertEquals(self.solver.evalScore(self.shogi), -scoreMax)
    redHime.i = 7
    redHime.hp = 0
    luaunit.assertEquals(self.solver.evalScore(self.shogi), scoreMax)
    redHime.hp = 1
    blueHime.hp = 0
    luaunit.assertEquals(self.solver.evalScore(self.shogi), -scoreMax)
end

