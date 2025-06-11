--[=[
    @class UserInterface Main
    @tag UserInterface
    @client
]=]
local self = {}

--[=[
    @function Init
    Starts all of the userinterface modules
    @within UserInterface Main
]=]
function self.Init()
    
    local CurrencyLabelBinder = require(script.Parent.CurrencyLabelBinder).Init()
    local Hider = require(script.Parent.Hider).Init()
    local CustomerProxPrompts = require(script.Parent.CustomPrompts).Init()

end

return self