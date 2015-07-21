local TestApp = class("TestApp", cc.load("mvc").AppBase)

function TestApp:onCreate()
end

function TestApp:getTeam()
    return "red"
end

function TestApp:getSeed()
    return 0
end

function TestApp:addListener(listener)
    self.listener = listener
end

function TestApp:commit(charaId, chipIdx)
    self.listener({charaId .. chipIdx})
end

return TestApp

