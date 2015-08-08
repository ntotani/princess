local luaunit = require("test.lib.luaunit")
local us = require("src.lib.moses")

TestShogi = {
    setUp = function(self)
        local rnds = us.range(0, 9)
        self.shogi = require("lib.shogi").new({random = function()
            table.insert(rnds, table.remove(rnds, 1))
            return rnds[#rnds]
        end, mapId = 1})
    end,
    testReset = function(self)
        luaunit.assertEquals(#self.shogi.party.red, 6)
        luaunit.assertEquals(self.shogi.party.red[1].job, "hime")
        luaunit.assertEquals(#self.shogi.party.blue, 6)
        luaunit.assertEquals(self.shogi.party.blue[1].job, "hime")
        for i = 2, 6 do
            luaunit.assertNotEquals(self.shogi.party.red[i].job, "hime")
            luaunit.assertNotEquals(self.shogi.party.blue[i].job, "hime")
        end
        luaunit.assertEquals(self.shogi:getCharas(), {})
        luaunit.assertEquals(self.shogi.chips, {})
    end,
    testCommitForm = function(self)
        self.shogi:commitForm({red = {"193", "282"}, blue = {"113", "224"}})
        luaunit.assertEquals(#self.shogi:getCharas(), 4)
        luaunit.assertEquals(self.shogi:getCharas()[1], {id = 1, i = 9, j = 3, team = "red", hp = 100, job = "hime"})
        luaunit.assertNotEquals(self.shogi:getCharas()[2].job, "hime")
        luaunit.assertEquals(self.shogi:getCharas()[3].job, "hime")
        luaunit.assertNotEquals(self.shogi:getCharas()[4].job, "hime")
        luaunit.assertEquals(#self.shogi.chips.red, 12)
        luaunit.assertEquals(#self.shogi.chips.blue, 12)
    end,
    testMoveOb = function(self)
        self.shogi:commitForm({red = {"193", "282"}, blue = {"113", "224"}})
        local chara = self.shogi:getCharas()[2]
        luaunit.assertTrue(chara.hp > 0)
        local acts = {}
        local ret = self.shogi:move(chara, {i = 1, j = -1}, acts)
        luaunit.assertTrue(ret)
        luaunit.assertEquals(acts, {{type = "ob", i = 9, j = 1, actor = 2}})
        luaunit.assertEquals(chara.hp, 0)
    end,
    testMoveObHime = function(self)
        self.shogi:commitForm({red = {"193", "282"}, blue = {"113", "224"}})
        local chara = self.shogi:getCharas()[1]
        local acts = {}
        self.shogi:move(chara, {i = 2, j = 0}, acts)
        luaunit.assertEquals(#acts, 2)
        luaunit.assertEquals(acts[2], {type = "end", lose = "red"})
    end,
    testMove = function(self)
        self.shogi:commitForm({red = {"193", "282"}, blue = {"113", "224"}})
        local chara = self.shogi:getCharas()[2]
        local acts = {}
        local ret = self.shogi:move(chara, {i = -2, j = 0}, acts)
        luaunit.assertFalse(ret)
        luaunit.assertEquals(acts, {{type = "move", fi = 8, fj = 2, actor = 2, i = 6, j = 2}})
        luaunit.assertEquals(chara.i, 6)
        luaunit.assertEquals(chara.j, 2)
    end,
    testMoveHit = function(self)
        self.shogi:commitForm({red = {"193", "244"}, blue = {"113", "224"}})
        local chara = self.shogi:getCharas()[2]
        local hit = self.shogi:getCharas()[4]
        local acts = {}
        local ret = self.shogi:move(chara, {i = -2, j = 0}, acts)
        luaunit.assertTrue(ret)
        luaunit.assertEquals(acts, {{type = "attack", fi = 4, fj = 4, actor = 2, i = 2, j = 4, hp = 100, dmg = 20, target = 4}})
        luaunit.assertEquals(hit.hp, 80)
        luaunit.assertEquals(chara.i, 4)
        luaunit.assertEquals(chara.j, 4)
    end,
    testMoveKill = function(self)
        self.shogi:commitForm({red = {"193", "244"}, blue = {"113", "224"}})
        local chara = self.shogi:getCharas()[2]
        local hit = self.shogi:getCharas()[4]
        hit.hp = 1
        local acts = {}
        self.shogi:move(chara, {i = -2, j = 0}, acts)
        luaunit.assertEquals(hit.hp, 0)
        luaunit.assertEquals(chara.i, 2)
        luaunit.assertEquals(chara.j, 4)
    end,
    testMoveKillHime = function(self)
        self.shogi:commitForm({red = {"193", "233"}, blue = {"113", "224"}})
        local chara = self.shogi:getCharas()[2]
        local hit = self.shogi:getCharas()[3]
        hit.hp = 1
        local acts = {}
        self.shogi:move(chara, {i = -2, j = 0}, acts)
        luaunit.assertEquals(#acts, 2)
        luaunit.assertEquals(acts[2], {type = "end", lose = "blue"})
    end,
    testMoveRedHime = function(self)
        self.shogi:commitForm({red = {"133", "282"}, blue = {"122", "224"}})
        local chara = self.shogi:getCharas()[1]
        local acts = {}
        local ret = self.shogi:move(chara, {i = -2, j = 0}, acts)
        luaunit.assertTrue(ret)
        luaunit.assertEquals(#acts, 2)
        luaunit.assertEquals(acts[2], {type = "end", lose = "blue"})
    end,
    testMoveBlueHime = function(self)
        self.shogi:commitForm({red = {"184", "282"}, blue = {"173", "224"}})
        local chara = self.shogi:getCharas()[3]
        local acts = {}
        self.shogi:move(chara, {i = -2, j = 0}, acts)
        luaunit.assertEquals(acts[2], {type = "end", lose = "red"})
    end,
    testFarEnemiesRed = function(self)
        self.shogi:commitForm({red = {"193", "282"}, blue = {"113", "224"}})
        local enemies = self.shogi:farEnemies(self.shogi:getCharas()[2])
        luaunit.assertEquals(#enemies, 2)
        luaunit.assertEquals(enemies[1].id, 4)
        luaunit.assertEquals(enemies[2].id, 3)
    end,
    testFarEnemiesBlue = function(self)
        self.shogi:commitForm({red = {"193", "282"}, blue = {"113", "224"}})
        local enemies = self.shogi:farEnemies(self.shogi:getCharas()[4])
        luaunit.assertEquals(#enemies, 2)
        luaunit.assertEquals(enemies[1].id, 2)
        luaunit.assertEquals(enemies[2].id, 1)
    end,
    testProcessTurn = function(self)
        self.shogi:commitForm({red = {"193", "282"}, blue = {"113", "224"}})
        local acts = self.shogi:processTurn({"11"})
        luaunit.assertEquals(#acts, 3)
        luaunit.assertEquals(acts[1], {type = "chip", actor = 1, chip = 1})
        luaunit.assertEquals(acts[2].type, "move")
        luaunit.assertEquals(acts[3].type, "move")
        local chara = self.shogi:getCharas()[1]
        luaunit.assertEquals(chara.i, 6)
        luaunit.assertEquals(chara.j, 2)
        luaunit.assertEquals(#self.shogi.chips.red, 11)
    end,
    testProcessTurnDead = function(self)
        self.shogi:commitForm({red = {"144", "282"}, blue = {"113", "224"}})
        self.shogi:getCharas()[4].hp = 1
        local acts = self.shogi:processTurn({"11", "41"})
        luaunit.assertEquals(#acts, 3)
        luaunit.assertEquals(acts[3], {type = "dead", actor = 4, chip = 1})
    end,
    testProcessTurnSkillHime = function(self)
        self.shogi:commitForm({red = {"193", "282"}, blue = {"113", "224"}})
        local chips = self.shogi.chips.red
        table.insert(chips, 1, table.remove(chips, us.detect(chips, "skill"))) -- pop skill top
        local acts = self.shogi:processTurn({"11"})
        luaunit.assertEquals(acts[2], {type = "move", fi = 1, fj = 3, actor = 3, i = 3, j = 3})
    end,
    testProcessTurnSkillNinja = function(self)
        self.shogi:commitForm({red = {"193", "275"}, blue = {"113", "224"}})
        local chips = self.shogi.chips.red
        table.insert(chips, 1, table.remove(chips, us.detect(chips, "skill"))) -- pop skill top
        local acts = self.shogi:processTurn({"21"})
        luaunit.assertEquals(#acts, 4)
        luaunit.assertEquals(acts[2], {type = "move", fi = 7, fj = 5, actor = 2, i = 6, j = 4})
        luaunit.assertEquals(acts[3], {type = "move", fi = 6, fj = 4, actor = 2, i = 5, j = 3})
        luaunit.assertEquals(acts[4], {type = "move", fi = 5, fj = 3, actor = 2, i = 4, j = 2})
    end,
    testProcessTurnSkillWitch = function(self)
        self.shogi:commitForm({red = {"193", "382"}, blue = {"113", "224"}})
        local chips = self.shogi.chips.red
        table.insert(chips, 1, table.remove(chips, us.detect(chips, "skill"))) -- pop skill top
        local acts = self.shogi:processTurn({"21"})
        luaunit.assertEquals(#acts, 2)
        luaunit.assertEquals(acts[2], {type = "swap", fi = 8, fj = 2, actor = 2, ti = 2, tj = 4, target = 4})
    end,
    testProcessTurnRefill = function(self)
        self.shogi:commitForm({red = {"193", "382"}, blue = {"113", "224"}})
        self.shogi.chips.red = {self.shogi.chips.red[1]}
        self.shogi.chips.blue = {self.shogi.chips.blue[1]}
        self.shogi:processTurn({"21", "31"})
        luaunit.assertEquals(#self.shogi.chips.red, 12)
        luaunit.assertEquals(#self.shogi.chips.blue, 12)
    end,
}
