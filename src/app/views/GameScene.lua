local us = require("lib.moses")
local jam = require("lib.jam")
local GameScene = class("GameScene", cc.load("mvc").ViewBase)

function GameScene:onCreate()
    --[[
    local TILES_PER_SIDE = 3
    local tiles = us.map(us.range(1, TILES_PER_SIDE * 2 - 1 + (TILES_PER_SIDE - 1) * 2), function(e)
        return us.rep(0, TILES_PER_SIDE * 2 - 1)
    end)
    ]]
    self.shogi = require("lib.shogi").new(self:getApp():getSeed())
    cc.TMXTiledMap:create("tmx/forest.tmx"):addTo(self)
    for i, line in ipairs(self.shogi:getTiles()) do
        for j, e in ipairs(line) do
            if e > 0 then
                display.newSprite("img/tile.png"):move(self:idx2pt(i, j)):addTo(self)
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
    for _, e in ipairs(self.shogi:getChars()) do
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
    node.sprite = jam.sprite("img/" .. chara.job .. ".png", 32):addTo(node)
    node.gauge = self:createHpGauge():move(-16, 16):addTo(node)
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

function GameScene:idx2pt(i, j)
    if self:getApp():getTeam() == "blue" then
        i = #self.shogi:getTiles() - i + 1
        j = #self.shogi:getTiles()[1] - j + 1
    end
    return cc.p(display.cx + 38 * (j - 3) * 1.5, display.cy + 33 * (5 - i))
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
    local DEF_TIME = 0.3
    local time = 0
    for _, action in ipairs(self.shogi:processTurn(commands)) do
        if action.type == "end" then
            self:runAction(cc.Sequence:create(cc.DelayTime:create(time), cc.CallFunc:create(function()
                local message = display.newSprite("img/" .. (action.lose == self:getApp():getTeam() and "lose" or "win") .. ".png"):move(display.center):addTo(self)
                self.touchLayer:onTouch(function()
                    message:removeSelf()
                    self.shogi:reset()
                    self:reset()
                end)
            end)))
            return
        end
        local charas = us.flatten({self.friends:getChildren(), self.enemies:getChildren()})
        local actor = charas[us.detect(charas, function(e)
            return e.model.id == action.actor
        end)]
        local isMyTeam = us.findWhere(self.shogi:getChars(), {id = action.actor}).team == self:getApp():getTeam()
        if action.type == "dead" then
            us.findWhere(self[(isMyTeam and "chips" or "enemyChips")]:getChildren(), {idx = action.chip}):moveTo({
                delay = time,
                time = DEF_TIME,
                y = isMyTeam and -36 or display.height + 36,
                removeSelf = true,
            })
            time = time + DEF_TIME
        elseif action.type == "chip" then
            us.findWhere(self[(isMyTeam and "chips" or "enemyChips")]:getChildren(), {idx = action.chip}):moveTo({
                delay = time,
                time = DEF_TIME,
                x = actor:getPositionX(),
                y = actor:getPositionY(),
                removeSelf = true,
            })
            time = time + DEF_TIME
        end
        if action.type == "move" then
            actor:moveTo({
                delay = time,
                time = DEF_TIME,
                x = self:idx2pt(action.i, action.j).x,
                y = self:idx2pt(action.i, action.j).y,
            })
            time = time + DEF_TIME
        elseif action.type == "swap" then
            actor:moveTo({
                delay = time,
                time = DEF_TIME,
                x = self:idx2pt(action.ti, action.tj).x,
                y = self:idx2pt(action.ti, action.tj).y,
            })
            charas[us.detect(charas, function(e)
                return e.model.id == action.target
            end)]:moveTo({
                delay = time,
                time = DEF_TIME,
                x = self:idx2pt(action.fi, action.fj).x,
                y = self:idx2pt(action.fi, action.fj).y,
            })
            time = time + DEF_TIME
        elseif action.type == "attack" then
            actor:runAction(cc.Sequence:create(
                cc.DelayTime:create(time),
                cc.MoveTo:create(DEF_TIME / 2, self:idx2pt(action.i, action.j)),
                cc.CallFunc:create(function()
                    local charas = us.flatten({self.friends:getChildren(), self.enemies:getChildren()})
                    local chara = charas[us.detect(charas, function(e)
                        return e.model.id == action.target
                    end)]
                    chara.gauge.setValue(action.hp - action.dmg)
                    if action.dmg >= action.hp then
                        chara:removeSelf()
                    end
                end),
                cc.MoveTo:create(DEF_TIME / 2, self:idx2pt(action.fi, action.fj))
            ))
            time = time + DEF_TIME
            if action.dmg >= action.hp then
                actor:moveTo({
                    delay = time,
                    time = DEF_TIME,
                    x = self:idx2pt(action.i, action.j).x,
                    y = self:idx2pt(action.i, action.j).y,
                })
                time = time + DEF_TIME
            end
        elseif action.type == "ob" then
            actor:moveTo({
                delay = time,
                time = DEF_TIME,
                x = self:idx2pt(action.i, action.j).x,
                y = self:idx2pt(action.i, action.j).y,
                removeSelf = true,
            })
            time = time + DEF_TIME
        end
    end
    local drawChip = function(team)
        local isMyTeam = team == self:getApp():getTeam()
        local model = self.shogi:getChips(team)
        local view = isMyTeam and self.chips or self.enemyChips
        for i, e in ipairs(model) do
            local chips = view:getChildren()
            if i > #chips then
                local chip = display.newSprite("chip/" .. e .. ".png"):addTo(view)
                chip:setScale(isMyTeam and 1 or -1)
                chip:move(display.width + chip:getContentSize().width, isMyTeam and 80 or display.height - 80):moveTo({
                    time = DEF_TIME,
                    x = self:getChipX(i),
                })
                chip.idx = i
            elseif chips[i].idx ~= i then
                chips[i]:moveTo({
                    time = DEF_TIME,
                    x = self:getChipX(i),
                })
                chips[i].idx = i
            end
        end
    end
    self:runAction(cc.Sequence:create(cc.DelayTime:create(time), cc.CallFunc:create(function()
        drawChip("red")
        drawChip("blue")
    end), cc.DelayTime:create(DEF_TIME), cc.CallFunc:create(function()
        self.touchLayer:onTouch(us.bind(self.onTouch, self))
    end)))
end

return GameScene

