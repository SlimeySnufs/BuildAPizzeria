--[=[
    @class StateRender Main
    @tag UserInterface
]=]
local self = {}

function self.Init()
    local CancellableStateHandler = require(script.Parent.CancellableStateHandler)
    CancellableStateHandler.Init()
end

return self