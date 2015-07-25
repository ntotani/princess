local luaunit = require("test.lib.luaunit")
local us = require("src.lib.moses")

TestGameScene = {}

function TestGameScene:testSample()
    luaunit.assertEquals(1 + 2, 3)
end

