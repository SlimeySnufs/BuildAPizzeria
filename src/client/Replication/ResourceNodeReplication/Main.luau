--[=[
    @class ResourceNodeReplication Main
    @tag ResourceNodeReplication
    @client
]=]
local self = {}

--[=[
    @function Init
    @within ResourceNodeReplication Main
]=]
function self.Init()
    
    local _ReplicaReciever = require(script.Parent.ReplicaReciever).Init()

    return self

end

return self