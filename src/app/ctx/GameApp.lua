local json = require("json")
local TitleApp = require("app.ctx.TitleApp")

local GameApp = class("GameApp", cc.load("mvc").AppBase)

function GameApp:onCreate()
    randomSeed(self.configs_.seed)
    self.shogi = require("lib.shogi").new({random = random, mapId = 2})
    self.configs_.socket:registerScriptHandler(function(msg)
        msg = json.decode(msg)
        if msg.event == "turn" then
            self.listener(json.decode(msg.data))
        elseif msg.event == "form" then
            self.shogi:commitForm(json.decode(msg.data))
            self:enterScene("GameScene")
        elseif msg.event == "pusher:error" then
            self:backToTitle(true)
        elseif msg.event == "pusher_internal:member_removed" then
            self:backToTitle(true)
        end
    end, cc.WEBSOCKET_MESSAGE)
    self.configs_.socket:registerScriptHandler(function(msg) self:backToTitle(true) end, cc.WEBSOCKET_ERROR)
end

function GameApp:getTeam()
    return self.configs_.team
end

function GameApp:getShogi()
    return self.shogi
end

function GameApp:addListener(listener)
    self.listener = listener
end

function GameApp:commitForm(form)
    local req = {}
    req[self:getTeam()] = form
    self:sendRequest(req)
end

function GameApp:commit(charaId, chipIdx)
    self:sendRequest({acts = {__op = "Add", objects = {charaId .. chipIdx}}})
end

function GameApp:getInitialMessage()
    return nil
end

function GameApp:endTexts(win)
    return {
        message = "YOU " .. (win and "WIN" or "LOSE"),
        ok = "もう一回",
        ng = "やめる"
    }
end

function GameApp:endPositive()
    if self:getTeam() == "red" then
        self:sendRequest({red = {}, blue = {}, acts = {}})
    end
    self.shogi:reset()
    self:enterScene("FormationScene")
end

function GameApp:endNegative()
    self:backToTitle(false)
end

function GameApp:sendRequest(body)
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
            self:backToTitle(true)
        end
    end)
    xhr:send(json.encode(body))
end

function GameApp:backToTitle(networkError)
    self.configs_.socket:close()
    TitleApp:create({networkError = networkError}):enterScene("TitleScene")
end

return GameApp

