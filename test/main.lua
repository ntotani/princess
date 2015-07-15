
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

require "config"
require "cocos.init"

local us = require("lib.moses")
local TestApp = class("TestApp", cc.load("mvc").AppBase)

local CHIPS = {
    f    = {{i = -2, j =  0}},
    rf   = {{i = -1, j =  1}},
    lf   = {{i = -1, j = -1}},
    rb   = {{i =  1, j =  1}},
    lb   = {{i =  1, j = -1}},
    b    = {{i =  2, j =  0}},
    ff   = {{i = -2, j =  0}, {i = -2, j =  0}},
    rfrf = {{i = -1, j =  1}, {i = -1, j =  1}},
    lflf = {{i = -1, j = -1}, {i = -1, j = -1}},
    frf  = {{i = -2, j =  0}, {i = -1, j =  1}},
    flf  = {{i = -2, j =  0}, {i = -1, j = -1}},
}

local TILES = {
    {0, 0, 1, 0, 0},
    {0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0},
    {1, 0, 1, 0, 1},
    {0, 1, 0, 1, 0},
    {0, 0, 1, 0, 0},
}

function TestApp:onCreate()
    self.chars = {
        {id = 1, i = 9, j = 3, job = "hime",  team = "red"},
        {id = 2, i = 8, j = 2, job = "witch", team = "red"},
        {id = 3, i = 7, j = 5, job = "ninja", team = "red"},
        {id = 4, i = 1, j = 3, job = "hime",  team = "blue"},
        {id = 5, i = 2, j = 4, job = "witch", team = "blue"},
        {id = 6, i = 3, j = 1, job = "ninja", team = "blue"},
    }
    self.chips = {"f", "flf", "b", "ff"}
end

function TestApp:getTiles()
    return TILES
end

function TestApp:getTeam()
    return "red"
end

function TestApp:getChars()
    return self.chars
end

function TestApp:getChips()
    return self.chips
end

function TestApp:addListener(listener)
    self.listener = listener
end

function TestApp:commit(charaId, chipIdx)
    local friend = us.findWhere(self.chars, {id = charaId})
    local acts = {}
    for _, dir in ipairs(CHIPS[self.chips[chipIdx]]) do
        local ni = friend.i + dir.i
        local nj = friend.j + dir.j
        if ni < 1 or ni > #TILES or nj < 1 or nj > #TILES[1] or TILES[ni][nj] == 0 then
            -- out of bounds
            acts[#acts + 1] = {type = "ob", who = charaId}
            break
        end
        local hit = us.detect(self.chars, function(e)
            return e.i == ni and e.j == nj
        end)
        friend.i = ni
        friend.j = nj
        acts[#acts + 1] = {type = "move", who = charaId, i = ni, j = nj}
        if hit then
            -- kill other chara
            acts[#acts].type = "kill"
            acts[#acts].target = self.chars[hit].id
            break
        end
    end
    self.listener(acts)
end

local function main()
    TestApp:create():run("GameScene")
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end

