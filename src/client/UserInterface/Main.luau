--[=[
    @class UserInterface Main
    @tag UserInterface
    @client
]=]
local self = {}

--[=[
    @function Init
    Starts all of the userinterface modules in parallel for faster loading
    @within UserInterface Main
]=]
function self.Init()
    
    -- Parallelize UI component initialization for faster loading
    task.spawn(function()
        require(script.Parent.CurrencyLabelBinder).Init()
    end)
    
    task.spawn(function()
        require(script.Parent.Hider).Init()
    end)
    
    task.spawn(function()
        require(script.Parent.CustomPrompts).Init()
    end)

end

return self