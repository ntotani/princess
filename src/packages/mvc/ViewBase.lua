local us = require("lib.moses")
local jam = require("lib.jam")

local ViewBase = class("ViewBase", cc.Node)

function ViewBase:ctor(app, name)
    self:enableNodeEvents()
    self.app_ = app
    self.name_ = name

    -- check CSB resource file
    local res = rawget(self.class, "RESOURCE_FILENAME")
    if res then
        self:createResoueceNode(res)
    end

    local binding = rawget(self.class, "RESOURCE_BINDING")
    if res and binding then
        self:createResoueceBinding(binding)
    end

    if self.onCreate then self:onCreate() end
end

function ViewBase:getApp()
    return self.app_
end

function ViewBase:getName()
    return self.name_
end

function ViewBase:getResourceNode()
    return self.resourceNode_
end

function ViewBase:createResoueceNode(resourceFilename)
    if self.resourceNode_ then
        self.resourceNode_:removeSelf()
        self.resourceNode_ = nil
    end
    self.resourceNode_ = cc.CSLoader:createNode(resourceFilename)
    assert(self.resourceNode_, string.format("ViewBase:createResoueceNode() - load resouce node from file \"%s\" failed", resourceFilename))
    self:addChild(self.resourceNode_)
end

function ViewBase:createResoueceBinding(binding)
    assert(self.resourceNode_, "ViewBase:createResoueceBinding() - not load resource node")
    for nodeName, nodeBinding in pairs(binding) do
        local node = self.resourceNode_:getChildByName(nodeName)
        if nodeBinding.varname then
            self[nodeBinding.varname] = node
        end
        for _, event in ipairs(nodeBinding.events or {}) do
            if event.event == "touch" then
                node:onTouch(handler(self, self[event.method]))
            end
        end
    end
end

function ViewBase:showWithScene(transition, time, more)
    self:setVisible(true)
    local scene = display.newScene(self.name_)
    scene:addChild(self)
    display.runScene(scene, transition, time, more)
    return self
end

local TILE_SIDE_FOUR = true

local tileMarginX = TILE_SIDE_FOUR and 28 or 38
local tileMarginY = TILE_SIDE_FOUR and 24 or 33

function ViewBase:isSideFour() return TILE_SIDE_FOUR end

function ViewBase:idx2pt(i, j)
    local row = #self.shogi:getTiles()
    local col = #self.shogi:getTiles()[1]
    if self:getApp():getTeam() == "blue" then
        i = row - i + 1
        j = col - j + 1
    end
    return cc.p(display.cx + tileMarginX * (j - math.ceil(col / 2)) * 1.5, display.cy + tileMarginY * (math.ceil(row / 2) - i))
end

function ViewBase:createSpec(model)
    local spec = display.newSprite("img/spec.png")
    local size = spec:getContentSize()
    local font = "font/PixelMplus12-Regular.ttf"
    cc.Label:createWithTTF(model.name, font, 36):align(cc.p(0, 1), 10, size.height - 10):addTo(spec)
    jam.sprite("img/chara/" .. model.id .. ".png", 32):align(cc.p(1, 1), size.width - 10, size.height - 10):addTo(spec)
    display.newSprite("icon/" .. model.planet .. ".png"):align(cc.p(1, 0.5), size.width - 42, size.height - 26):addTo(spec)
    local rate = self.shogi.getPlanetRate()
    local good, bad = {}, {}
    for _, e in ipairs(us.keys(rate)) do
        if rate[model.planet][e] > 1.0 or rate[e][model.planet] < 1.0 then
            table.insert(good, e)
            elseif rate[e][model.planet] > 1.0 or rate[model.planet][e] < 1.0 then
                table.insert(bad, e)
            end
    end
    local lab = cc.Label:createWithTTF("得意", font, 18):align(cc.p(0, 1), 20, size.height - 70):addTo(spec)
    for i, e in ipairs(good) do
        display.newSprite("icon/" .. e .. ".png"):align(cc.p(0, 0.5), size.width / 2 + (i - 1) * 32, lab:getPositionY() - lab:getContentSize().height / 2):addTo(spec)
    end
    lab = cc.Label:createWithTTF("苦手", font, 18):align(cc.p(0, 1), 20, lab:getPositionY() - 32):addTo(spec)
    for i, e in ipairs(bad) do
        display.newSprite("icon/" .. e .. ".png"):align(cc.p(0, 0.5), size.width / 2 + (i - 1) * 32, lab:getPositionY() - lab:getContentSize().height / 2):addTo(spec)
    end
    lab = cc.Label:createWithTTF("行動", font, 18):align(cc.p(0, 1), 20, lab:getPositionY() - 42):addTo(spec)
    cc.Label:createWithTTF(({"物理攻撃", "魔法攻撃", "回復"})[model.act + 1], font, 18):align(cc.p(0, 1), size.width / 2, lab:getPositionY()):addTo(spec)
    lab = cc.Label:createWithTTF(({"攻撃力", "魔力", "回復力"})[model.act + 1], font, 18):align(cc.p(0, 1), 20, lab:getPositionY() - 24):addTo(spec)
    cc.Label:createWithTTF(model.power, font, 18):align(cc.p(0, 1), size.width / 2, lab:getPositionY()):addTo(spec)
    lab = cc.Label:createWithTTF("物理防御", font, 18):align(cc.p(0, 1), 20, lab:getPositionY() - 24):addTo(spec)
    cc.Label:createWithTTF(model.defense, font, 18):align(cc.p(0, 1), size.width / 2, lab:getPositionY()):addTo(spec)
    lab = cc.Label:createWithTTF("魔法防御", font, 18):align(cc.p(0, 1), 20, lab:getPositionY() - 24):addTo(spec)
    cc.Label:createWithTTF(model.resist, font, 18):align(cc.p(0, 1), size.width / 2, lab:getPositionY()):addTo(spec)
    local askill = us.findWhere(self.shogi.getAskill(), {id = model.askill})
    lab = cc.Label:createWithTTF("特技「" .. askill.name .. "」", font, 18):align(cc.p(0, 1), 20, lab:getPositionY() - 42):addTo(spec)
    lab = cc.Label:createWithTTF(askill.at and string.gsub(askill.desc, "@", askill.at) or askill.desc, font, 12):align(cc.p(0, 1), 20, lab:getPositionY() - 24):addTo(spec)
    lab:setDimensions(size.width - 40, 0)
    local pskill = us.findWhere(self.shogi.getPskill(), {id = model.pskill})
    lab = cc.Label:createWithTTF("特性「" .. pskill.name .. "」", font, 18):align(cc.p(0, 1), 20, lab:getPositionY() - 32):addTo(spec)
    lab = cc.Label:createWithTTF(pskill.at and string.gsub(pskill.desc, "@", pskill.at) or pskill.desc, font, 12):align(cc.p(0, 1), 20, lab:getPositionY() - 24):addTo(spec)
    lab:setDimensions(size.width - 40, 0)
    return spec
end

function ViewBase:showSpec(chara)
    local smoke = display.newLayer(cc.c4f(0, 0, 0, 0.7), display.size):addTo(self)
    local dots = cc.DrawNode:create():addTo(smoke)
    local draw = function(i, opacity)
        local color = cc.c4f(1, 1, 1, opacity)
        dots:drawDot(cc.p(display.cx + (i - 1.5) * 16, 90), 4, color)
    end
    draw(1, 1)
    draw(2, 0.5)
    local pv = ccui.PageView:create():addTo(self)
    pv:setContentSize(display.size)
    local evo = us.findWhere(self.shogi.getCharaMaster(), {id = chara.evo})
    for _, e in ipairs({chara, evo}) do
        local spec = self:createSpec(e)
        spec:move(display.center)
        local page = ccui.Layout:create()
        page:addChild(spec)
        pv:addPage(page)
    end
    local moved = false
    pv:addEventListener(function(sender, event)
        if event ~= ccui.PageViewEventType.turning then return end
        dots:clear()
        for i = 1, 2 do
            draw(i, i == sender:getCurPageIndex() + 1 and 1 or 0.5)
        end
    end)
    pv:addTouchEventListener(function(sender, event)
        if event == ccui.TouchEventType.began then
            moved = false
        elseif event == ccui.TouchEventType.moved then
            moved = true
        elseif not moved then
            smoke:removeSelf()
            pv:runAction(cc.RemoveSelf:create())
            self.touchLayer:onTouch(us.bind(self.onTouch, self))
        end
    end)
    self.touchLayer:onTouch(function()end)
end

function ViewBase:showPrompt(parent, message, ok, onOk, ng, onNg)
    display.newSprite("img/window.png"):move(display.center):addTo(parent)
    cc.Label:createWithTTF(message, "font/PixelMplus12-Regular.ttf", 18):move(display.center):addTo(parent)
    local item = function(cb, x, lab)
        return cc.MenuItemImage:create("img/button.png", "img/button.png"):onClicked(cb):move(x, 0):addChild(cc.Label:createWithTTF(lab, "font/PixelMplus12-Regular.ttf", 18):move(39, 21))
    end
    cc.Menu:create(item(onOk, 50, ok), item(onNg, -50, ng)):move(display.cx, display.cy - 70):addTo(parent)
end

return ViewBase

