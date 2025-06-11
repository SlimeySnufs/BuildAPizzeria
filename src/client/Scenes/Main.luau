--[=[
    @class Scenes Main
    @tag UserInterface
]=]
local self = {}

--[=[
    @function Init
    @within Scenes Main
]=]
function self.Init()
    
    local ComputerStore = script.Parent.ComputerStore
    local Scene1 = require(ComputerStore.Main).Init()

    return self

end

return self