local luaunit = require("test.lib.luaunit")
local us = require("src.lib.moses")

TestShogi = {
    setUp = function(self)
        local rnds = {0, 0, 0, 0, 1, 1, 2, 2, 3, 3}
        self.shogi = require("lib.shogi").new({random = function()
            table.insert(rnds, table.remove(rnds, 1))
            return rnds[#rnds]
        end, mapId = 1})
    end,
    testReset = function(self)
        luaunit.assertEquals(#self.shogi.party.red, 6)
        luaunit.assertEquals(self.shogi.party.red[1].id, "1")
        luaunit.assertTrue(self.shogi:isHime(self.shogi.party.red[1]))
        luaunit.assertEquals(#self.shogi.party.blue, 6)
        luaunit.assertEquals(self.shogi.party.blue[1].id, "1")
        luaunit.assertTrue(self.shogi:isHime(self.shogi.party.blue[1]))
        for i = 2, 6 do
            luaunit.assertNotEquals(self.shogi.party.red[i].id, "1")
            luaunit.assertNotEquals(self.shogi.party.blue[i].id, "1")
        end
        luaunit.assertEquals(self.shogi:getCharas(), {})
        luaunit.assertEquals(self.shogi.chips, {})
    end,
    testSetParties = function(self)
        self.shogi:setParties({"5", "4"}, {"3", "2"})
        luaunit.assertEquals(self.shogi.party.red[1].id, "5")
        luaunit.assertEquals(self.shogi.party.red[2].id, "4")
        luaunit.assertEquals(self.shogi.party.blue[1].id, "3")
        luaunit.assertEquals(self.shogi.party.blue[2].id, "2")
    end,
    testSetDeck = function(self)
        self.shogi:setDeck("red", {"f", "f", "f", "f", "f"})
        self.shogi:commitForm({red = {"1,9,3", "2,8,2"}, blue = {"1,1,3", "2,2,4"}})
        luaunit.assertEquals(self.shogi.chips.red[1], "f")
        luaunit.assertEquals(self.shogi.chips.red[2], "f")
        luaunit.assertEquals(self.shogi.chips.red[3], "f")
        luaunit.assertEquals(self.shogi.chips.red[4], "f")
    end,
    testCommitForm = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,2"}, blue = {"1,1,3", "2,2,4"}})
        luaunit.assertEquals(#self.shogi:getCharas(), 4)
        luaunit.assertEquals(self.shogi:getCharas()[1], {id = 1, i = 9, j = 3, team = "red", hp = 100, pump = {power = 1.0, defense = 1.0, resist = 1.0}, master = self.shogi.party.red[1]})
        luaunit.assertFalse(self.shogi:isHime(self.shogi:getCharas()[2]))
        luaunit.assertTrue(self.shogi:isHime(self.shogi:getCharas()[3]))
        luaunit.assertFalse(self.shogi:isHime(self.shogi:getCharas()[4]))
        luaunit.assertEquals(#self.shogi.chips.red, 12)
        luaunit.assertEquals(#self.shogi.chips.blue, 12)
    end,
    testCalcDamage = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,2"}, blue = {"1,1,3", "2,2,4"}})
        local atk = self.shogi.charas[2]
        local def = self.shogi.charas[4]
        luaunit.assertEquals(self.shogi:calcDamage(atk, def), 40)
    end,
    testCalcDamageLeast1 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,2"}, blue = {"1,1,3", "2,2,4"}})
        local atk = self.shogi.charas[2]
        local def = self.shogi.charas[4]
        def.pump.defense = 100
        luaunit.assertEquals(self.shogi:calcDamage(atk, def), 1)
    end,
    testMoveOb = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,2"}, blue = {"1,1,3", "2,2,4"}})
        local chara = self.shogi:getCharas()[2]
        luaunit.assertTrue(chara.hp > 0)
        local acts = {}
        local ret = self.shogi:move(chara, {i = 1, j = -1}, acts)
        luaunit.assertTrue(ret)
        luaunit.assertEquals(acts, {{type = "ob", i = 9, j = 1, actor = 2}})
        luaunit.assertEquals(chara.hp, 0)
    end,
    testMoveObHime = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,2"}, blue = {"1,1,3", "2,2,4"}})
        local chara = self.shogi:getCharas()[1]
        local acts = {}
        self.shogi:move(chara, {i = 2, j = 0}, acts)
        luaunit.assertEquals(#acts, 2)
        luaunit.assertEquals(acts[2], {type = "end", lose = "red"})
    end,
    testMoveObAll = function(self)
        self.shogi:commitForm({red = {"2,9,3"}, blue = {"1,1,3", "2,2,4"}})
        local chara = self.shogi:getCharas()[1]
        local acts = {}
        self.shogi:move(chara, {i = 2, j = 0}, acts)
        luaunit.assertEquals(#acts, 2)
        luaunit.assertEquals(acts[2], {type = "end", lose = "red"})
    end,
    testMove = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,2"}, blue = {"1,1,3", "2,2,4"}})
        local chara = self.shogi:getCharas()[2]
        local acts = {}
        local ret = self.shogi:move(chara, {i = -2, j = 0}, acts)
        luaunit.assertFalse(ret)
        luaunit.assertEquals(acts, {{type = "move", fi = 8, fj = 2, actor = 2, i = 6, j = 2}})
        luaunit.assertEquals(chara.i, 6)
        luaunit.assertEquals(chara.j, 2)
    end,
    testMoveHit = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,4,4"}, blue = {"1,1,3", "2,2,4"}})
        local chara = self.shogi:getCharas()[2]
        local hit = self.shogi:getCharas()[4]
        local acts = {}
        local ret = self.shogi:move(chara, {i = -2, j = 0}, acts)
        luaunit.assertTrue(ret)
        luaunit.assertEquals(acts, {{type = "attack", fi = 4, fj = 4, actor = 2, i = 2, j = 4, hp = 100, dmg = 40, target = 4}})
        luaunit.assertEquals(hit.hp, 60)
        luaunit.assertEquals(chara.i, 4)
        luaunit.assertEquals(chara.j, 4)
    end,
    testMoveHitResist = function(self)
        self.shogi:commitForm({red = {"1,9,3", "3,4,4"}, blue = {"1,1,3", "2,2,4"}})
        local chara = self.shogi:getCharas()[2]
        local hit = self.shogi:getCharas()[4]
        local acts = {}
        local ret = self.shogi:move(chara, {i = -2, j = 0}, acts)
        luaunit.assertTrue(ret)
        luaunit.assertEquals(acts, {{type = "attack", fi = 4, fj = 4, actor = 2, i = 2, j = 4, hp = 100, dmg = 93, target = 4}})
        luaunit.assertEquals(hit.hp, 7)
        luaunit.assertEquals(chara.i, 4)
        luaunit.assertEquals(chara.j, 4)
    end,
    testMoveHitHeal = function(self)
        self.shogi:commitForm({red = {"1,4,4", "2,8,4"}, blue = {"1,1,3", "2,2,4"}})
        local chara = self.shogi:getCharas()[1]
        local hit = self.shogi:getCharas()[4]
        hit.hp = 1
        local acts = {}
        local ret = self.shogi:move(chara, {i = -2, j = 0}, acts)
        luaunit.assertTrue(ret)
        luaunit.assertEquals(acts, {{type = "heal", fi = 4, fj = 4, actor = 1, i = 2, j = 4, hp = 1, dmg = 40, target = 4}})
        luaunit.assertEquals(hit.hp, 41)
        luaunit.assertEquals(chara.i, 4)
        luaunit.assertEquals(chara.j, 4)
    end,
    testMoveKill = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,4,4"}, blue = {"1,1,3", "2,2,4"}})
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
        self.shogi:commitForm({red = {"1,9,3", "2,3,3"}, blue = {"1,1,3", "2,2,4"}})
        local chara = self.shogi:getCharas()[2]
        local hit = self.shogi:getCharas()[3]
        hit.hp = 1
        local acts = {}
        self.shogi:move(chara, {i = -2, j = 0}, acts)
        luaunit.assertEquals(#acts, 2)
        luaunit.assertEquals(acts[2], {type = "end", lose = "blue"})
    end,
    testMoveKillAll = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,3,3"}, blue = {"2,1,3"}})
        local chara = self.shogi:getCharas()[2]
        local hit = self.shogi:getCharas()[3]
        hit.hp = 1
        local acts = {}
        self.shogi:move(chara, {i = -2, j = 0}, acts)
        luaunit.assertEquals(#acts, 2)
        luaunit.assertEquals(acts[2], {type = "end", lose = "blue"})
    end,
    testMoveRedHime = function(self)
        self.shogi:commitForm({red = {"1,3,3", "2,8,2"}, blue = {"1,2,2", "2,2,4"}})
        local chara = self.shogi:getCharas()[1]
        local acts = {}
        local ret = self.shogi:move(chara, {i = -2, j = 0}, acts)
        luaunit.assertTrue(ret)
        luaunit.assertEquals(#acts, 2)
        luaunit.assertEquals(acts[2], {type = "end", lose = "blue"})
    end,
    testMoveRedHime_kill = function(self)
        self.shogi:commitForm({red = {"1,3,3", "2,8,2"}, blue = {"1,2,2", "3,1,3"}})
        self.shogi.charas[1].act = 1
        self.shogi.charas[4].hp = 1
        local acts = {}
        local ret = self.shogi:move(self.shogi.charas[1], {i = -2, j = 0}, acts)
        luaunit.assertTrue(ret)
        luaunit.assertEquals(#acts, 3)
        luaunit.assertEquals(acts[3], {type = "end", lose = "blue"})
    end,
    testMoveBlueHime = function(self)
        self.shogi:commitForm({red = {"1,8,4", "2,8,2"}, blue = {"1,7,3", "2,2,4"}})
        local chara = self.shogi:getCharas()[3]
        local acts = {}
        self.shogi:move(chara, {i = -2, j = 0}, acts)
        luaunit.assertEquals(acts[2], {type = "end", lose = "red"})
    end,
    testFarEnemiesRed = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,2"}, blue = {"1,1,3", "2,2,4"}})
        local enemies = self.shogi:farEnemies(self.shogi:getCharas()[2])
        luaunit.assertEquals(#enemies, 2)
        luaunit.assertEquals(enemies[1].id, 4)
        luaunit.assertEquals(enemies[2].id, 3)
    end,
    testFarEnemiesBlue = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,2"}, blue = {"1,1,3", "2,2,4"}})
        local enemies = self.shogi:farEnemies(self.shogi:getCharas()[4])
        luaunit.assertEquals(#enemies, 2)
        luaunit.assertEquals(enemies[1].id, 2)
        luaunit.assertEquals(enemies[2].id, 1)
    end,
    testEvolve = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,4"}, blue = {"1,1,3", "2,2,2"}})
        self.shogi.tiles[6][4] = 6
        local acts = {}
        self.shogi:move(self.shogi.charas[2], {i = -2, j = 0}, acts)
        luaunit.assertEquals(acts[2], {type = "evo", actor = 2, from = "3", to = "4"})
        luaunit.assertEquals(self.shogi.charas[2].master.id, "4")
    end,
    testCalcPathCharaOnGoal = function(self)
        self.shogi:commitForm({red = {"1,9,3"}, blue = {"1,1,3"}})
        luaunit.assertNil(self.shogi:calcPath(self.shogi.charas[1], 1, 3))
    end,
    testCalcPath = function(self)
        self.shogi:commitForm({red = {"1,9,3"}, blue = {"1,1,3"}})
        local path = self.shogi:calcPath(self.shogi.charas[1], 5, 3)
        luaunit.assertEquals(path, {{i = 5, j = 3}, {i = 7, j = 3}})
    end,
    testCalcPathNoPath = function(self)
        self.shogi:commitForm({red = {"1,9,3"}, blue = {"1,3,3", "3,2,2", "5,2,4"}})
        luaunit.assertNil(self.shogi:calcPath(self.shogi.charas[1], 1, 3))
    end,
    testProcessTurn = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,2"}, blue = {"1,1,3", "2,2,4"}})
        self.shogi.chips.red[1] = "flf"
        local acts = self.shogi:processTurn({"11"})
        luaunit.assertEquals(acts[1], {type = "chip", actor = 1, chip = 1})
        luaunit.assertEquals(acts[2].type, "move")
        luaunit.assertEquals(acts[3].type, "move")
        local chara = self.shogi:getCharas()[1]
        luaunit.assertEquals(chara.i, 6)
        luaunit.assertEquals(chara.j, 2)
        luaunit.assertEquals(#self.shogi.chips.red, 11)
    end,
    testProcessTurnTwice = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,2"}, blue = {"1,1,3", "2,2,2"}})
        self.shogi.chips.red[1] = "f"
        self.shogi.chips.blue[1] = "f"
        local acts = self.shogi:processTurn({"41", "21"})
        luaunit.assertEquals(acts[2], {type = "move", actor = 4, fi = 2, fj = 2, i = 4, j = 2})
        luaunit.assertEquals(acts[4], {type = "move", actor = 2, fi = 8, fj = 2, i = 6, j = 2})
    end,
    testProcessTurnDead = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,4,4"}, blue = {"1,1,3", "2,2,4"}})
        self.shogi:getCharas()[4].hp = 1
        self.shogi.chips.red[1] = "f"
        local acts = self.shogi:processTurn({"21", "41"})
        luaunit.assertEquals(#acts, 8)
        luaunit.assertEquals(acts[6], {type = "miss", actor = 4, chip = 1})
    end,
    testProcessTurnSkill1 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,4", "3,7,1"}, blue = {"1,1,3", "2,2,2"}})
        self.shogi:getCharas()[2].hp = 1
        self.shogi:getCharas()[3].hp = 1
        self.shogi:getCharas()[5].hp = 1
        self.shogi.chips.red[1] = "skill"
        local acts = self.shogi:processTurn({"11"})
        luaunit.assertEquals(acts[2], {type = "heal", actor = 1, fi = 9, fj = 3, target = 2, i = 8, j = 4, hp = 1, dmg = 30})
        luaunit.assertEquals(acts[3], {type = "heal", actor = 1, fi = 9, fj = 3, target = 3, i = 7, j = 1, hp = 1, dmg = 30})
        luaunit.assertEquals(self.shogi:getCharas()[2].hp, 37)
        luaunit.assertEquals(self.shogi:getCharas()[3].hp, 31)
        luaunit.assertEquals(self.shogi:getCharas()[5].hp, 7)
    end,
    testProcessTurnSkill1Dead = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,4"}, blue = {"1,1,3"}})
        self.shogi:getCharas()[2].hp = 0
        self.shogi.chips.red[1] = "skill"
        local acts = self.shogi:processTurn({"11"})
        luaunit.assertEquals(#acts, 1)
        luaunit.assertEquals(self.shogi.charas[2].hp, 0)
    end,
    testProcessTurnSkill2 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,6,2"}, blue = {"1,1,3", "2,2,4"}})
        self.shogi:getCharas()[1].askill = "2"
        self.shogi:getCharas()[2].hp = 1
        self.shogi.chips.red[1] = "skill"
        local acts = self.shogi:processTurn({"11"})
        luaunit.assertEquals(acts[2], {type = "heal", actor = 1, fi = 9, fj = 3, target = 2, i = 6, j = 2, hp = 1, dmg = 70})
        luaunit.assertEquals(self.shogi:getCharas()[2].hp, 71)
    end,
    testProcessTurnSkill3 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,2"}, blue = {"1,1,3", "2,8,4"}})
        self.shogi:getCharas()[1].askill = "3"
        local chips = self.shogi.chips.red
        table.insert(chips, 1, table.remove(chips, us.detect(chips, "skill"))) -- pop skill top
        local acts = self.shogi:processTurn({"11"})
        luaunit.assertEquals(acts[2], {type = "move", actor = 1, fi = 9, fj = 3, i = 7, j = 3})
        luaunit.assertEquals(acts[3], {type = "move", actor = 1, fi = 7, fj = 3, i = 5, j = 3})
        luaunit.assertEquals(self.shogi:getCharas()[1].i, 5)
        luaunit.assertEquals(self.shogi:getCharas()[1].j, 3)
    end,
    testProcessTurnSkill3_double = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,4,4"}, blue = {"1,2,2", "2,2,4"}})
        local chara = self.shogi:getCharas()[2]
        local hit = self.shogi:getCharas()[4]
        self.shogi.chips.red[1] = "skill"
        local acts = self.shogi:processTurn({"21"})
        luaunit.assertEquals(acts[2], {type = "attack", actor = 2, fi = 4, fj = 4, target = 4, i = 2, j = 4, hp = 100, dmg = 80})
        luaunit.assertEquals(hit.hp, 20)
        luaunit.assertEquals(chara.i, 4)
        luaunit.assertEquals(chara.j, 4)
    end,
    testProcessTurnSkill4 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,2"}, blue = {"1,1,3", "2,2,4"}})
        self.shogi.charas[1].askill = "4"
        local chips = self.shogi.chips.red
        table.insert(chips, 1, table.remove(chips, us.detect(chips, "skill"))) -- pop skill top
        local acts = self.shogi:processTurn({"11"})
        luaunit.assertEquals(acts[2], {type = "move", fi = 1, fj = 3, actor = 3, i = 3, j = 3})
    end,
    testProcessTurnSkill5 = function(self)
        self.shogi:commitForm({red = {"1,7,3", "2,8,2"}, blue = {"1,1,3", "2,2,4"}})
        self.shogi.charas[1].askill = "5"
        local chips = self.shogi.chips.red
        table.insert(chips, 1, table.remove(chips, us.detect(chips, "skill"))) -- pop skill top
        local acts = self.shogi:processTurn({"11"})
        luaunit.assertEquals(acts[2], {type = "move", fi = 7, fj = 3, actor = 1, i = 9, j = 3})
    end,
    testProcessTurnSkill5_miss = function(self)
        self.shogi:commitForm({red = {"1,7,3", "2,9,3"}, blue = {"1,1,3", "2,2,4"}})
        self.shogi.charas[1].askill = "5"
        local chips = self.shogi.chips.red
        table.insert(chips, 1, table.remove(chips, us.detect(chips, "skill"))) -- pop skill top
        local acts = self.shogi:processTurn({"11"})
        luaunit.assertEquals(acts[1], {type = "miss", actor = 1, chip = 1})
    end,
    testProcessTurnSkill6 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "4,7,5"}, blue = {"1,1,3", "2,2,4"}})
        self.shogi.chips.red[1] = "skill"
        local acts = self.shogi:processTurn({"21"})
        luaunit.assertEquals(#acts, 4)
        luaunit.assertEquals(acts[2], {type = "move", fi = 7, fj = 5, actor = 2, i = 6, j = 4})
        luaunit.assertEquals(acts[3], {type = "move", fi = 6, fj = 4, actor = 2, i = 5, j = 3})
        luaunit.assertEquals(acts[4], {type = "move", fi = 5, fj = 3, actor = 2, i = 4, j = 2})
    end,
    testProcessTurnSkill7_redblue = function(self)
        self.shogi:commitForm({red = {"1,9,3", "5,8,4"}, blue = {"1,1,3", "2,6,4"}})
        self.shogi.chips.red[1] = "skill"
        local acts = self.shogi:processTurn({"21"})
        luaunit.assertEquals(acts[2], {type = "attack", fi = 8, fj = 4, actor = 2, i = 6, j = 4, target = 4, hp = 100, dmg = 30})
        luaunit.assertEquals(acts[3], {type = "move", fi = 6, fj = 4, actor = 4, i = 4, j = 4})
    end,
    testProcessTurnSkill7_redred = function(self)
        self.shogi:commitForm({red = {"1,6,4", "5,8,4"}, blue = {"1,1,3", "2,2,4"}})
        self.shogi.chips.red[1] = "skill"
        local acts = self.shogi:processTurn({"21"})
        luaunit.assertEquals(acts[2], {type = "attack", fi = 8, fj = 4, actor = 2, i = 6, j = 4, target = 1, hp = 100, dmg = 24})
        luaunit.assertEquals(acts[3], {type = "move", fi = 6, fj = 4, actor = 1, i = 4, j = 4})
    end,
    testProcessTurnSkill7_bluered = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,4,4"}, blue = {"1,1,3", "5,2,4"}})
        self.shogi.chips.blue[1] = "skill"
        local acts = self.shogi:processTurn({"41"})
        luaunit.assertEquals(acts[2], {type = "attack", fi = 2, fj = 4, actor = 4, i = 4, j = 4, target = 2, hp = 100, dmg = 30})
        luaunit.assertEquals(acts[3], {type = "move", fi = 4, fj = 4, actor = 2, i = 6, j = 4})
    end,
    testProcessTurnSkill7_blueblue = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,4"}, blue = {"1,4,4", "5,2,4"}})
        self.shogi.chips.blue[1] = "skill"
        local acts = self.shogi:processTurn({"41"})
        luaunit.assertEquals(acts[2], {type = "attack", fi = 2, fj = 4, actor = 4, i = 4, j = 4, target = 3, hp = 100, dmg = 24})
        luaunit.assertEquals(acts[3], {type = "move", fi = 4, fj = 4, actor = 3, i = 6, j = 4})
    end,
    testProcessTurnSkill8_redblue = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,7,3"}, blue = {"1,1,3", "2,6,4", "3,6,2"}})
        self.shogi.charas[2].askill = "8"
        local chips = self.shogi.chips.red
        table.insert(chips, 1, table.remove(chips, us.detect(chips, "skill"))) -- pop skill top
        local acts = self.shogi:processTurn({"21"})
        luaunit.assertEquals(acts[3], {type = "move", fi = 6, fj = 4, actor = 4, i = 5, j = 5})
        luaunit.assertEquals(acts[4], {type = "move", fi = 6, fj = 2, actor = 5, i = 5, j = 1})
    end,
    testProcessTurnSkill8_redred = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,7,3", "3,6,4"}, blue = {"1,1,3", "2,2,2"}})
        self.shogi.charas[2].askill = "8"
        local chips = self.shogi.chips.red
        table.insert(chips, 1, table.remove(chips, us.detect(chips, "skill"))) -- pop skill top
        local acts = self.shogi:processTurn({"21"})
        luaunit.assertEquals(acts[3], {type = "move", fi = 6, fj = 4, actor = 3, i = 5, j = 5})
    end,
    testProcessTurnSkill8_bluered = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,4,2", "3,4,4"}, blue = {"1,1,3", "2,3,3"}})
        self.shogi.charas[5].askill = "8"
        local chips = self.shogi.chips.blue
        table.insert(chips, 1, table.remove(chips, us.detect(chips, "skill"))) -- pop skill top
        local acts = self.shogi:processTurn({"51"})
        luaunit.assertEquals(acts[3], {type = "move", fi = 4, fj = 2, actor = 2, i = 5, j = 1})
        luaunit.assertEquals(acts[4], {type = "move", fi = 4, fj = 4, actor = 3, i = 5, j = 5})
    end,
    testProcessTurnSkill8_blueblue = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,4"}, blue = {"1,1,3", "2,3,3", "3,4,2"}})
        self.shogi.charas[4].askill = "8"
        local chips = self.shogi.chips.blue
        table.insert(chips, 1, table.remove(chips, us.detect(chips, "skill"))) -- pop skill top
        local acts = self.shogi:processTurn({"41"})
        luaunit.assertEquals(acts[3], {type = "move", fi = 4, fj = 2, actor = 5, i = 5, j = 1})
    end,
    testProcessTurnSkill111 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "3,8,2"}, blue = {"1,1,3", "2,2,4"}})
        self.shogi.charas[2].askill = "111"
        local chips = self.shogi.chips.red
        table.insert(chips, 1, table.remove(chips, us.detect(chips, "skill"))) -- pop skill top
        local acts = self.shogi:processTurn({"21"})
        luaunit.assertEquals(#acts, 2)
        luaunit.assertEquals(acts[2], {type = "swap", fi = 8, fj = 2, actor = 2, ti = 2, tj = 4, target = 4})
    end,
    testProcessTurnPskill1 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,2"}, blue = {"1,1,3", "2,2,4"}})
        self.shogi.charas[1].pskill = "1"
        self.shogi.charas[2].hp = 1
        local acts = self.shogi:processTurn({})
        luaunit.assertEquals(#acts, 2)
        luaunit.assertEquals(acts[1], {type = "pskill", actor = 1, id = "1"})
        luaunit.assertEquals(acts[2], {type = "heal", actor = 1, fi = 9, fj = 3, target = 2, i = 8, j = 2, hp = 1, dmg = 6})
        luaunit.assertEquals(self.shogi.charas[2].hp, 7)
    end,
    testProcessTurnPskill2 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,3,3"}, blue = {"1,1,3", "2,2,4"}})
        self.shogi.charas[3].pskill = "2"
        self.shogi.charas[2].hp = 1
        local acts = self.shogi:processTurn({})
        luaunit.assertEquals(#acts, 2)
        luaunit.assertEquals(acts[1], {type = "pskill", actor = 3, id = "2"})
        luaunit.assertEquals(acts[2], {type = "heal", actor = 3, fi = 1, fj = 3, target = 2, i = 3, j = 3, hp = 1, dmg = 12})
        luaunit.assertEquals(self.shogi.charas[2].hp, 13)
    end,
    testProcessTurnPskill3 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,4"}, blue = {"1,1,3", "2,6,4"}})
        self.shogi.charas[4].hp = 1
        local acts = {}
        self.shogi:move(self.shogi.charas[2], {i = -2, j = 0}, acts)
        luaunit.assertEquals(#acts, 4)
        luaunit.assertEquals(acts[2], {type = "pskill", actor = 4, id = "3"})
        luaunit.assertEquals(acts[3], {type = "attack", actor = 4, fi = 6, fj = 4, target = 2, i = 8, j = 4, hp = 100, dmg = 40})
        luaunit.assertEquals(self.shogi.charas[2].hp, 60)
        luaunit.assertEquals(self.shogi.charas[4].hp, 0)
    end,
    testProcessTurnPskill3_offset = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,4"}, blue = {"1,1,3", "2,6,4"}})
        self.shogi.charas[2].hp = 1
        self.shogi.charas[4].hp = 1
        local acts = {}
        self.shogi:move(self.shogi.charas[2], {i = -2, j = 0}, acts)
        luaunit.assertEquals(#acts, 3)
        luaunit.assertEquals(acts[3], {type = "attack", actor = 4, fi = 6, fj = 4, target = 2, i = 8, j = 4, hp = 1, dmg = 40})
        luaunit.assertEquals(self.shogi.charas[2].hp, 0)
        luaunit.assertEquals(self.shogi.charas[4].hp, 0)
    end,
    testProcessTurnPskill4 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,4"}, blue = {"1,1,3", "2,6,4"}})
        self.shogi.charas[2].pskill = "4"
        self.shogi.charas[4].hp = 1
        self.shogi:move(self.shogi.charas[2], {i = -2, j = 0}, {})
        luaunit.assertEquals(self.shogi.charas[2].pump.power, 1.5)
    end,
    testProcessTurnPskill5 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "3,8,4"}, blue = {"1,1,3", "2,4,4"}})
        local acts = {}
        self.shogi:move(self.shogi.charas[2], {i = -2, j = 0}, acts)
        luaunit.assertEquals(acts[1], {type = "pskill", actor = 2, id = "5"})
        luaunit.assertEquals(acts[2], {type = "attack", actor = 2, fi = 8, fj = 4, target = 4, i = 4, j = 4, hp = 100, dmg = 93})
        luaunit.assertEquals(self.shogi.charas[2].i, 8)
        luaunit.assertEquals(self.shogi.charas[2].j, 4)
    end,
    testProcessTurnPskill6 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,5,5"}, blue = {"1,1,3", "3,2,2"}})
        self.shogi.charas[4].pskill = "6"
        local acts = {}
        self.shogi:move(self.shogi.charas[4], {i = -1, j = -1}, acts)
        luaunit.assertEquals(acts[1], {type = "pskill", actor = 4, id = "6"})
        luaunit.assertEquals(acts[2], {type = "attack", actor = 4, fi = 2, fj = 2, target = 2, i = 5, j = 5, hp = 100, dmg = 93})
        luaunit.assertEquals(self.shogi.charas[4].i, 2)
        luaunit.assertEquals(self.shogi.charas[4].j, 2)
    end,
    testProcessTurnPskill7 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,4"}, blue = {"1,1,3", "2,6,4"}})
        self.shogi.charas[4].pskill = "7"
        self.shogi.charas[2].power = 1000
        local acts = {}
        self.shogi:move(self.shogi.charas[2], {i = -2, j = 0}, acts)
        luaunit.assertEquals(acts[1], {type = "pskill", actor = 4, id = "7"})
        luaunit.assertEquals(acts[2], {type = "attack", actor = 2, fi = 8, fj = 4, target = 4, i = 6, j = 4, hp = 100, dmg = 99})
        luaunit.assertEquals(self.shogi.charas[4].hp, 1)
    end,
    testProcessTurnPskill8 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,4"}, blue = {"1,1,3", "2,2,2"}})
        self.shogi.charas[2].pskill = "8"
        self.shogi.chips.red[1] = "f"
        local acts = self.shogi:processTurn({"21"})
        luaunit.assertEquals(acts[2], {type = "pskill", actor = 2, id = "8"})
        luaunit.assertEquals(acts[3], {type = "move", actor = 2, fi = 8, fj = 4, i = 6, j = 4})
        luaunit.assertEquals(acts[4], {type = "move", actor = 2, fi = 6, fj = 4, i = 4, j = 4})
    end,
    testProcessTurnPskill9 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,7,3"}, blue = {"1,1,3", "5,6,2"}})
        local acts = {}
        self.shogi:move(self.shogi.charas[2], {i = -1, j = -1}, acts)
        luaunit.assertEquals(acts[1], {type = "attack", actor = 2, fi = 7, fj = 3, target = 4, i = 6, j = 2, hp = 100, dmg = 16})
        luaunit.assertEquals(acts[2], {type = "pskill", actor = 4, id = "9"})
        luaunit.assertEquals(acts[3], {type = "move", actor = 2, fi = 7, fj = 3, i = 8, j = 4})
    end,
    testProcessTurnPskill10 = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,4"}, blue = {"1,1,3", "2,6,4", "5,4,4"}})
        self.shogi.charas[5].pskill = "10"
        local acts = {}
        self.shogi:move(self.shogi.charas[2], {i = -2, j = 0}, acts)
        luaunit.assertEquals(acts[1], {type = "pskill", actor = 5, id = "10"})
        luaunit.assertEquals(acts[2], {type = "swap", actor = 5, fi = 4, fj = 4, target = 4, ti = 6, tj = 4})
        luaunit.assertEquals(acts[3], {type = "attack", actor = 2, fi = 8, fj = 4, target = 5, i = 6, j = 4, hp = 100, dmg = 16})
        luaunit.assertEquals(self.shogi.charas[4].i, 4)
        luaunit.assertEquals(self.shogi.charas[4].j, 4)
        luaunit.assertEquals(self.shogi.charas[4].hp, 100)
    end,
    testProcessTurnPskill10_friend = function(self)
        self.shogi:commitForm({red = {"1,9,3", "2,8,4", "5,7,5"}, blue = {"1,1,3", "2,6,4"}})
        self.shogi.charas[3].pskill = "10"
        local acts = {}
        self.shogi:move(self.shogi.charas[2], {i = -2, j = 0}, acts)
        luaunit.assertEquals(acts[1], {type = "attack", actor = 2, fi = 8, fj = 4, target = 5, i = 6, j = 4, hp = 100, dmg = 40})
        luaunit.assertEquals(self.shogi.charas[3].i, 7)
        luaunit.assertEquals(self.shogi.charas[3].j, 5)
        luaunit.assertEquals(self.shogi.charas[5].hp, 60)
    end,
    testProcessTurnPskill10_actor = function(self)
        self.shogi:commitForm({red = {"1,9,3", "5,8,4", "2,6,4"}, blue = {"1,1,3"}})
        self.shogi.charas[2].pskill = "10"
        local acts = {}
        self.shogi:move(self.shogi.charas[2], {i = -2, j = 0}, acts)
        luaunit.assertEquals(acts[1], {type = "attack", actor = 2, fi = 8, fj = 4, target = 3, i = 6, j = 4, hp = 100, dmg = 30})
        luaunit.assertEquals(self.shogi.charas[2].i, 8)
        luaunit.assertEquals(self.shogi.charas[2].j, 4)
        luaunit.assertEquals(self.shogi.charas[3].hp, 70)
    end,
    testProcessTurnRefill = function(self)
        self.shogi:commitForm({red = {"1,9,3", "3,8,2"}, blue = {"1,1,3", "2,2,4"}})
        self.shogi.chips.red = {self.shogi.chips.red[1]}
        self.shogi.chips.blue = {self.shogi.chips.blue[1]}
        self.shogi:processTurn({"21", "31"})
        luaunit.assertEquals(#self.shogi.chips.red, 12)
        luaunit.assertEquals(#self.shogi.chips.blue, 12)
    end,
}
