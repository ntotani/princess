local luaunit = require("test.lib.luaunit")
local us = require("src.lib.moses")

TestGameScene = {}

function TestGameScene:setUp()
    self.app = require("test.TestApp"):create()
    self.app.shogi:commitForm({red = {"1,13,4"}, blue = {"1,1,4"}})
    self.scene = require("app.views.GameScene"):create(self.app, "GameScene")
    self.scene:showWithScene()
    cc.Director:getInstance():mainLoop() -- run scene
end

function TestGameScene:testOnCreate()
    luaunit.assertIs(self.scene.enemies:getParent(), self.scene)
    luaunit.assertIs(self.scene.friends:getParent(), self.scene)
    luaunit.assertIs(self.scene.chips:getParent(), self.scene)
    luaunit.assertIs(self.scene.enemyChips:getParent(), self.scene)
    luaunit.assertNotNil(self.app.listener)
    luaunit.assertIs(self.scene.touchLayer:getParent(), self.scene)

    -- charas
    luaunit.assertEquals(#self.scene.friends:getChildren(), 1)
    luaunit.assertEquals(#self.scene.enemies:getChildren(), 1)
    local redHime = self.scene.friends:getChildren()[1]
    luaunit.assertIs(redHime.sprite:getParent(), redHime)
    luaunit.assertIs(redHime.gauge:getParent(), redHime)
    luaunit.assertIs(redHime.planet:getParent(), redHime)
    luaunit.assertNotNil(redHime.model)

    -- chips
    luaunit.assertEquals(#self.scene.chips:getChildren(), 4)
    luaunit.assertEquals(#self.scene.enemyChips:getChildren(), 4)
end

function TestGameScene:testCreateHpGauge()
    local gauge = self.scene:createHpGauge()
    luaunit.assertNotNil(gauge)
    luaunit.assertIsFunction(gauge.setValue)
end

function TestGameScene:testIdx2pt()
    luaunit.assertEquals(self.scene:idx2pt(1, 1), {x = 54, y = 464})
    self.app.getTeam = function(self) return "blue" end
    luaunit.assertEquals(self.scene:idx2pt(1, 1), {x = 306, y = 176})
end

function TestGameScene:testGetChipX()
    luaunit.assertEquals(self.scene:getChipX(1), 51)
end

function TestGameScene:testOnTouch_hold()
    local ret = self.scene:onTouch({name = "began", x = 51, y = 80})
    luaunit.assertTrue(ret)
    luaunit.assertNotNil(self.scene.holdChip)
    luaunit.assertNotNil(self.scene.holdChip.backPt)
end

function TestGameScene:testOnTouch_notHold()
    local ret = self.scene:onTouch({name = "began", x = 0, y = 0})
    luaunit.assertFalse(ret)
    luaunit.assertNil(self.scene.holdChip)
end

function TestGameScene:testOnTouch_move()
    self.scene:onTouch({name = "began", x = 51, y = 80})
    self.scene:onTouch({name = "moved", x = 0, y = 0})
    luaunit.assertEquals(cc.p(self.scene.holdChip:getPosition()), cc.p(0, 0))
end

function TestGameScene:testOnTouch_drop()
    self.scene:onTouch({name = "began", x = 51, y = 80})
    self.scene:onTouch({name = "moved", x = 0, y = 0})
    self.scene:onTouch({name = "end", x = 0, y = 0})
    luaunit.assertNil(self.scene.holdChip)
end

function TestGameScene:testOnTouch_commit()
    local called = false
    self.app.commit = function(self, chara, chip)
        luaunit.assertEquals(chara, 1)
        luaunit.assertEquals(chip, 1)
        called = true
    end
    self.scene:onTouch({name = "began", x = 51, y = 80})
    self.scene:onTouch({name = "moved", x = 180, y = 188})
    self.scene:onTouch({name = "end", x = 180, y = 188})
    luaunit.assertNil(self.scene.holdChip)
    luaunit.assertTrue(called)
end

