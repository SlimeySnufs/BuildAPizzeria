--[=[
    @class OrderHandling Main
    @tag InteractiveHandler
]=]
local self = {}

--[=[
    @function Init
    @within OrderHandling Main
]=]
function self.Init()
    self.NPCGeneration = require(script.Parent.NPCGeneration).Init()
end

return self