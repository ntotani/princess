local json = require("json")
local GameApp = class("GameApp", cc.load("mvc").AppBase)

function GameApp:onCreate()
    self.configs_.socket:registerScriptHandler(function(msg)
        msg = json.decode(msg)
        if msg.event == "turn" then
            self:onTurn(msg)
        end
    end, cc.WEBSOCKET_MESSAGE)
end

function GameApp:getTeam()
    return self.configs_.team
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
    self.listener(json.decode(msg.data))
end

return GameApp

