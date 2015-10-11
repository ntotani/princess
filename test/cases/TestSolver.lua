local luaunit = require("test.lib.luaunit")
local us = require("src.lib.moses")

TestSolver = {}

function TestSolver:setUp()
    self.solver = require("lib.solver")
    self.shogi = self.solver.level2shogi(function() return 0 end, {
        message = "チップで駒を動かそう",
        map = 1,
        friend = {
            chara = {{id = "3", i = 9, j = 3}},
            deck = {"f", "f"}
        },
        enemy = {
            chara = {{id = "1", i = 3, j = 3}},
            deck = {"f", "f"}
        }
    })
end

function TestSolver:testSolve()
    local act = self.solver.solve(self.shogi, 1, 1)
    local expected = {}
    expected["21"] = 1
    expected["22"] = 1
    luaunit.assertEquals(act, expected)
end

