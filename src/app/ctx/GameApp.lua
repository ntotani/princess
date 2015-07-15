local json = require("json")
local us = require("lib.moses")
local GameApp = class("GameApp", cc.load("mvc").AppBase)

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

function GameApp:onCreate()
    self.chars = {
        {id = 1, i = 9, j = 3, job = "hime",  team = "red"},
        {id = 2, i = 8, j = 2, job = "witch", team = "red"},
        {id = 3, i = 7, j = 5, job = "ninja", team = "red"},
        {id = 4, i = 1, j = 3, job = "hime",  team = "blue"},
        {id = 5, i = 2, j = 4, job = "witch", team = "blue"},
        {id = 6, i = 3, j = 1, job = "ninja", team = "blue"},
    }
    self.chips = {"f", "flf", "b", "ff"}
    self.configs_.socket:registerScriptHandler(function(msg)
        msg = json.decode(msg)
        if msg.event == "turn" then
            self:onTurn(msg)
        end
    end, cc.WEBSOCKET_MESSAGE)
end

function GameApp:getTiles()
    return TILES
end

function GameApp:getTeam()
    return self.configs_.team
end

function GameApp:getChars()
    return self.chars
end

function GameApp:getChips()
    return self.chips
end

function GameApp:addListener(listener)
    self.listener = listener
end

function GameApp:commit(charaId, chipIdx)
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    xhr:setRequestHeader("X-Parse-Application-Id", "so6Tb3E5JowUXObTBdnRJaBWXf8ZQZjAslBlmdoE")
    xhr:setRequestHeader("X-Parse-REST-API-Key", "rkfvd1LPNsIvYV40EfWKZXnYwKrXBDHLJpFj6tj6")
    xhr:setRequestHeader("Content-Type", "application/json")
    xhr:open("PUT", "https://api.parse.com/1/classes/Match/" .. self.configs_.matchId)
    xhr:registerScriptHandler(function()
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            --print(xhr.response)
        else
            print("xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
        end
    end)
    xhr:send(json.encode({acts = {__op = "Add", objects = {charaId .. chipIdx}}}))
end

function GameApp:onTurn(msg)
    local data = json.decode(msg.data)
    local acts = {}
    for i, e in ipairs(data) do
        local charaId = tonumber(e:sub(1, 1))
        local chipIdx = tonumber(e:sub(2, 2))
        local friend = us.findWhere(self.chars, {id = charaId})
        for _, dir in ipairs(CHIPS[self.chips[chipIdx]]) do
            local ni = friend.i + dir.i * (friend.team == "red" and 1 or -1)
            local nj = friend.j + dir.j * (friend.team == "red" and 1 or -1)
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
    end
    self.listener(acts)
end

return GameApp

