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
    cc.TMXTiledMap:create("tmx/forest.tmx"):addTo(self)
    for i, line in ipairs(self:getApp():getTiles()) do
        for j, e in ipairs(line) do
            if e > 0 then
                display.newSprite("img/tile.png"):move(self:idx2pt(i, j)):addTo(self)
            end
        end
    end
    self.enemies = display.newLayer():addTo(self)
    self.friends = display.newLayer():addTo(self)
    self.chips = display.newLayer():addTo(self)
    self:getApp():addListener(us.bind(self.onTurn, self))
    self.touchLayer = display.newLayer():addTo(self)
    self:reset()
end

function GameScene:reset()
    for _, e in ipairs(self.enemies:getChildren()) do e:removeSelf() end
    for _, e in ipairs(self.friends:getChildren()) do e:removeSelf() end
    for _, e in ipairs(self.chips:getChildren()) do e:removeSelf() end
    for _, e in ipairs(self:getApp():getChars()) do
        self:initChara(e)
    end
    for i, e in ipairs(self:getApp():getChips()) do
        local chip = display.newSprite("chip/" .. e .. ".png"):move(self:getChipX(i), 80):addTo(self.chips)
        chip.idx = i
    end
    self.touchLayer:onTouch(us.bind(self.onTouch, self))
end

function GameScene:initChara(chara)
    local node = cc.Node:create():move(self:idx2pt(chara.i, chara.j))
    node.sprite = jam.sprite("img/" .. chara.job .. ".png", 32):addTo(node)
    if chara.team == self:getApp():getTeam() then
        node.sprite:frameIdx(9, 10, 11, 10)
        node:addTo(self.friends)
    else
        node.sprite:frameIdx(0, 1, 2, 1)
        node:addTo(self.enemies)
    end
    node.model = chara
end

function GameScene:idx2pt(i, j)
    if self:getApp():getTeam() == "blue" then
        i = #self:getApp():getTiles() - i + 1
        j = #self:getApp():getTiles()[1] - j + 1
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

function GameScene:onTurn(actions)
    local DEF_TIME = 0.3
    local time = 0
    for _, action in ipairs(actions) do
        if action.type == "end" then
            self:runAction(cc.Sequence:create(cc.DelayTime:create(time), cc.CallFunc:create(function()
                local message = display.newSprite("img/" .. (action.win == self:getApp():getTeam() and "win" or "lose") .. ".png"):move(display.center):addTo(self)
                self.touchLayer:onTouch(function()
                    message:removeSelf()
                    self:getApp():reset()
                    self:reset()
                end)
            end)))
            return
        end
        local charas = us.flatten({self.friends:getChildren(), self.enemies:getChildren()})
        local actor = charas[us.detect(charas, function(e)
            return e.model.id == action.actor
        end)]
        if action.type == "dead" then
            us.findWhere(self.chips:getChildren(), {idx = action.chip}):moveTo({
                delay = time,
                time = DEF_TIME,
                y = -36,
                removeSelf = true,
            })
        elseif actor.model.team == self:getApp():getTeam() then
            us.findWhere(self.chips:getChildren(), {idx = action.chip}):moveTo({
                delay = time,
                time = DEF_TIME,
                x = actor:getPositionX(),
                y = actor:getPositionY(),
                removeSelf = true,
            })
        end
        time = time + DEF_TIME
        if action.type == "move" then
            actor:moveTo({
                delay = time,
                time = DEF_TIME,
                x = self:idx2pt(action.i, action.j).x,
                y = self:idx2pt(action.i, action.j).y,
            })
            time = time + DEF_TIME
        elseif action.type == "kill" then
            actor:moveTo({
                delay = time,
                time = DEF_TIME,
                x = self:idx2pt(action.i, action.j).x,
                y = self:idx2pt(action.i, action.j).y,
                onComplete = function()
                    local charas = us.flatten({self.friends:getChildren(), self.enemies:getChildren()})
                    charas[us.detect(charas, function(e)
                        return e.model.id == action.target
                    end)]:removeSelf()
                end,
            })
            time = time + DEF_TIME
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
    self:runAction(cc.Sequence:create(cc.DelayTime:create(time), cc.CallFunc:create(function()
        for i, e in ipairs(self:getApp():getChips()) do
            local chips = self.chips:getChildren()
            if i > #chips then
                local chip = display.newSprite("chip/" .. e .. ".png"):addTo(self.chips)
                chip:move(display.width + chip:getContentSize().width, 80):moveTo({
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
    end), cc.DelayTime:create(DEF_TIME), cc.CallFunc:create(function()
        self.touchLayer:onTouch(us.bind(self.onTouch, self))
    end)))
end

return GameScene

