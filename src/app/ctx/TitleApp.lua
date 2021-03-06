local json = require("json")
local TitleApp = class("TitleApp", cc.load("mvc").AppBase)

function TitleApp:onCreate()
    self.networkError = self.configs_.networkError and true or false
end

function TitleApp:createRoom(callback)
    self:initWebsocket(true, callback)
end

function TitleApp:joinRoom(roomId)
    self:initWebsocket(false, nil, roomId)
end
 
function TitleApp:initWebsocket(isBuild, onCreateRoom, roomId)
    self.corner = isBuild and "red" or "blue"
    self.ws = cc.WebSocket:create("ws://ws.pusherapp.com/app/753bbbbb0ecb441ce3eb?protocol=7")
    if not self.ws then return end
    self.ws:registerScriptHandler(function(msg)
        msg = json.decode(msg)
        if msg.event == "pusher:connection_established" then
            local data = json.decode(msg.data)
            local channelId = isBuild and "" or roomId
            self:cloudFunc("pusher", {socket_id = data.socket_id, channel_id = channelId}, function(ret)
                self.channelId = "private-" .. ret.channel_id
                self.ws:sendString(json.encode({
                    event = "pusher:subscribe",
                    data = {
                        channel = self.channelId,
                        auth = ret.auth
                    }
                }))
                if isBuild then
                    onCreateRoom(ret.channel_id)
                end
            end)
        elseif msg.event == "pusher_internal:subscription_succeeded" then
            if not isBuild then
                self:cloudFunc("start", {channel_id = roomId}, function()end)
            end
        elseif msg.event == "start" then
            self.ws:unregisterScriptHandler(cc.WEBSOCKET_MESSAGE)
            self.ws:unregisterScriptHandler(cc.WEBSOCKET_ERROR)
            local data = json.decode(msg.data)
            require("app.ctx.GameApp"):create({
                socket = self.ws,
                matchId = data.id,
                team = self.corner,
                seed = data.seed,
                channel = self.channelId,
            }):enterScene("FormationScene")
        elseif msg.event == "pusher:error" then
            self:backToScene()
        elseif msg.event == "pusher_internal:member_removed" then
            self:backToScene()
        end
    end, cc.WEBSOCKET_MESSAGE)
    self.ws:registerScriptHandler(function(msg) self:backToScene() end, cc.WEBSOCKET_ERROR)
end

function TitleApp:cloudFunc(name, params, callback)
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    xhr:setRequestHeader("X-Parse-Application-Id", "so6Tb3E5JowUXObTBdnRJaBWXf8ZQZjAslBlmdoE")
    xhr:setRequestHeader("X-Parse-REST-API-Key", "rkfvd1LPNsIvYV40EfWKZXnYwKrXBDHLJpFj6tj6")
    xhr:setRequestHeader("Content-Type", "application/json")
    xhr:open("POST", "https://api.parse.com/1/functions/" .. name)
    xhr:registerScriptHandler(function()
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            local response = json.decode(xhr.response)
            callback(response.result)
        else
            self:backToScene()
        end
    end)
    xhr:send(json.encode(params))
end

function TitleApp:backToScene()
    if self.ws then self.ws:close() end
    self.networkError = true
    self:enterScene("TitleScene")
end

function TitleApp:isNetworkError()
    self.networkError = not self.networkError
    return not self.networkError
end

return TitleApp

