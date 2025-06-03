--[=[
    @class ActionPadReplication Main
    @client
    @tag ActionPadReplication
]=]

local self = {}

--[=[
    @function Init
    @within ActionPadReplication Main
]=]
function self.Init()
    
    local ReplicaReciever = require(script.Parent.ReplicaReciever).Init()

    return self

end

return self