local us = require("lib.moses")
local jam = require("lib.jam")
local GameScene = class("GameScene", cc.load("mvc").ViewBase)

local ACT_DEF_SEC = 0.3

function GameScene:onCreate()
    self.shogi = self:getApp():getShogi()
    cc.TMXTiledMap:create("tmx/forest.tmx"):addTo(self)
    for i, line in ipairs(self.shogi:getTiles()) do
        for j, e in ipairs(line) do
            if e > 0 then
                local path = self:isSideFour() and "img/tile_4.png" or "img/tile.png"
                display.newSprite(path):move(self:idx2pt(i, j)):addTo(self)
            end
        end
    end
    self.enemies = display.newLayer():addTo(self)
    self.friends = display.newLayer():addTo(self)
    self.chips = display.newLayer():addTo(self)
    self.enemyChips = display.newLayer():addTo(self)
    self:getApp():addListener(us.bind(self.onTurn, self))
    self.touchLayer = display.newLayer():addTo(self)
    self:reset()
end

function GameScene:reset()
    for _, e in ipairs(self.enemies:getChildren()) do e:removeSelf() end
    for _, e in ipairs(self.friends:getChildren()) do e:removeSelf() end
    for _, e in ipairs(self.chips:getChildren()) do e:removeSelf() end
    for _, e in ipairs(self.enemyChips:getChildren()) do e:removeSelf() end
    for _, e in ipairs(self.shogi:getCharas()) do
        self:initChara(e)
    end
    local friendTeam = self:getApp():getTeam()
    local enemyTeam = friendTeam == "red" and "blue" or "red"
    for i, e in ipairs(self.shogi:getChips(friendTeam)) do
        local chip = display.newSprite("chip/" .. e .. ".png"):move(self:getChipX(i), 80):addTo(self.chips)
        chip.idx = i
    end
    for i, e in ipairs(self.shogi:getChips(enemyTeam)) do
        local chip = display.newSprite("chip/" .. e .. ".png"):move(self:getChipX(i), display.height - 80):addTo(self.enemyChips)
        chip:setScale(-1)
        chip.idx = i
    end
    self.touchLayer:onTouch(us.bind(self.onTouch, self))
end

function GameScene:initChara(chara)
    local node = cc.Node:create():move(self:idx2pt(chara.i, chara.j))
    node.sprite = jam.sprite("img/chara/" .. chara.master.id .. ".png", 32):addTo(node)
    node.gauge = self:createHpGauge():move(-16, 16):addTo(node)
    node.planet = display.newSprite("icon/" .. chara.planet .. ".png"):move(16, -16):addTo(node)
    if chara.team == self:getApp():getTeam() then
        node.sprite:frameIdx(9, 10, 11, 10)
        node:addTo(self.friends)
    else
        node.sprite:frameIdx(0, 1, 2, 1)
        node:addTo(self.enemies)
    end
    node.model = chara
end

function GameScene:createHpGauge()
    local gauge = cc.DrawNode:create()
    local wid = 32
    local hei = 8
    gauge.setValue = function(value)
        gauge:clear()
        gauge:drawSolidRect(cc.p(0, 0), cc.p(wid, hei), cc.c4f(1, 1, 1, 1))
        gauge:drawSolidRect(cc.p(2, 2), cc.p(wid - 2, hei - 2), cc.c4f(0, 0, 0, 1))
        if value > 0 then
            gauge:drawSolidRect(cc.p(2, 2), cc.p((wid - 4) * value / 100 + 2, hei - 2), cc.c4f(0, 1, 0, 1))
        end
    end
    gauge.setValue(100)
    return gauge
end

function GameScene:getChipX(idx)
    return (72 + 14) * (idx - 1) + 15 + 36
end

function GameScene:onTouch(e)
    if e.name == "began" and not self.holdChip then
        for _, chip in ipairs(self.chips:getChildren()) do
            local bb = chip:getBoundingBox()
            if cc.rectContainsPoint(bb, e) then
                self.holdChip = chip
                self.holdChip.backPt = cc.p(chip:getPosition())
                return true
            end
        end
        return false
    end
    if e.name == "moved" and self.holdChip then
        self.holdChip:move(e)
    elseif self.holdChip then
        local len = 48
        for _, friend in ipairs(self.friends:getChildren()) do
            local x, y = friend:getPosition()
            if cc.rectContainsPoint(cc.rect(x - len / 2, y - len / 2, len, len), e) then
                self.touchLayer:removeTouch()
                self:getApp():commit(friend.model.id, self.holdChip.idx)
                break
            end
        end
        self.holdChip:move(self.holdChip.backPt)
        self.holdChip = nil
    end
end

function GameScene:onTurn(commands)
    local actions = self.shogi:processTurn(commands)
    local parse = nil
    parse = function()
        if #actions > 0 then
            local act = table.remove(actions, 1)
            local ccacts = self["act2ccacts_" .. act.type](self, act)
            if act.type ~= "end" then
                table.insert(ccacts, cc.CallFunc:create(parse))
            end
            self:runAction(cc.Sequence:create(ccacts))
        else
            self:runAction(cc.Sequence:create(self:drawChip(), cc.CallFunc:create(function()
                self.touchLayer:onTouch(us.bind(self.onTouch, self))
            end)))
        end
    end
    parse()
end

function GameScene:act2ccacts_end(action)
    local name = action.lose == self:getApp():getTeam() and "lose" or "win"
    return {
        cc.CallFunc:create(function()
            display.newSprite("img/" .. name  .. ".png"):move(display.center):addTo(self)
            self.touchLayer:onTouch(function()
                self:getApp():reset()
            end)
        end)
    }
end

function GameScene:act2ccacts_miss(action)
    local isMyTeam = us.findWhere(self.shogi:getCharas(), {id = action.actor}).team == self:getApp():getTeam()
    local chip = us.findWhere(self[(isMyTeam and "chips" or "enemyChips")]:getChildren(), {idx = action.chip})
    local moveTo = cc.MoveTo:create(ACT_DEF_SEC, cc.p(chip:getPositionX(), isMyTeam and -36 or display.height + 36))
    return {
        cc.TargetedAction:create(chip, moveTo),
        cc.TargetedAction:create(chip, cc.RemoveSelf:create()),
    }
end

function GameScene:act2ccacts_chip(action)
    local isMyTeam = us.findWhere(self.shogi:getCharas(), {id = action.actor}).team == self:getApp():getTeam()
    local chip = us.findWhere(self[(isMyTeam and "chips" or "enemyChips")]:getChildren(), {idx = action.chip})
    local actor = self:act2actor(action)
    local moveTo = cc.MoveTo:create(ACT_DEF_SEC, cc.p(actor:getPosition()))
    return {
        cc.TargetedAction:create(chip, moveTo),
        cc.TargetedAction:create(chip, cc.RemoveSelf:create()),
    }
end

function GameScene:act2ccacts_move(action)
    local actor = self:act2actor(action)
    local pt = self:idx2pt(action.i, action.j)
    return {
        cc.TargetedAction:create(actor, cc.MoveTo:create(ACT_DEF_SEC, pt))
    }
end

function GameScene:act2ccacts_swap(action)
    local actor = self:act2actor(action)
    local moveToA = cc.MoveTo:create(ACT_DEF_SEC, self:idx2pt(action.ti, action.tj))
    local target = self:act2actor(action, "target")
    local moveToT = cc.MoveTo:create(ACT_DEF_SEC, self:idx2pt(action.fi, action.fj))
    return {
        cc.Spawn:create(
            cc.TargetedAction:create(actor, moveToA),
            cc.TargetedAction:create(target, moveToT)
        )
    }
end

function GameScene:act2ccacts_attack(action)
    local actor = self:act2actor(action)
    local target = self:act2actor(action, "target")
    local ccacts = {
        cc.TargetedAction:create(actor, cc.MoveTo:create(ACT_DEF_SEC / 2, self:idx2pt(action.i, action.j))),
        cc.CallFunc:create(function()
            target.gauge.setValue(action.hp - action.dmg)
            if action.dmg >= action.hp then
                target:removeSelf()
            end
        end),
        cc.TargetedAction:create(actor, cc.MoveTo:create(ACT_DEF_SEC / 2, self:idx2pt(action.fi, action.fj))),
    }
    return ccacts
end

function GameScene:act2ccacts_heal(action)
    local actor = self:act2actor(action)
    local target = self:act2actor(action, "target")
    local ccacts = {
        cc.TargetedAction:create(actor, cc.MoveTo:create(ACT_DEF_SEC / 2, self:idx2pt(action.i, action.j))),
        cc.CallFunc:create(function()
            target.gauge.setValue(math.min(action.hp + action.dmg, 100))
            local par = cc.ParticleSystemQuad:create("particle/heal.plist")
            par:setAutoRemoveOnFinish(true)
            par:setBlendAdditive(false)
            par:move(target:getPosition())
            self:addChild(par)
        end),
        cc.TargetedAction:create(actor, cc.MoveTo:create(ACT_DEF_SEC / 2, self:idx2pt(action.fi, action.fj))),
    }
    return ccacts
end

function GameScene:act2ccacts_ob(action)
    local actor = self:act2actor(action)
    return {
        cc.TargetedAction:create(actor, cc.MoveTo:create(ACT_DEF_SEC, self:idx2pt(action.i, action.j))),
        cc.TargetedAction:create(actor, cc.RemoveSelf:create()),
    }
end

function GameScene:act2actor(action, key)
    local charas = us.flatten({self.friends:getChildren(), self.enemies:getChildren()})
    key = key or "actor"
    return charas[us.detect(charas, function(e)
        return e.model.id == action[key]
    end)]
end

function GameScene:drawChip()
    local chipActions = {}
    local moveChip = function(chip, i)
        local x = self:getChipX(i)
        local y = chip:getPositionY()
        local moveTo = cc.MoveTo:create(ACT_DEF_SEC, cc.p(x, y))
        table.insert(chipActions, cc.TargetedAction:create(chip, moveTo))
    end
    for _, team in ipairs({"red", "blue"}) do
        local isMyTeam = team == self:getApp():getTeam()
        local model = self.shogi:getChips(team)
        local view = isMyTeam and self.chips or self.enemyChips
        for i, e in ipairs(model) do
            local chips = view:getChildren()
            if i > #chips then
                local chip = display.newSprite("chip/" .. e .. ".png"):addTo(view)
                local chipY = isMyTeam and 80 or display.height - 80
                chip:move(display.width + chip:getContentSize().width, chipY)
                chip:setScale(isMyTeam and 1 or -1)
                chip.idx = i
                moveChip(chip, i)
            elseif chips[i].idx ~= i then
                chips[i].idx = i
                moveChip(chips[i], i)
            end
        end
    end
    return cc.Spawn:create(chipActions)
end

return GameScene

