--[=[
    @class ResourceNodeReplication Main
    @tag ResourceNodeReplication
    @client
]=]
local self = {}

--[=[
    @function Init
    @within ResourceNodeReplica Main
]=]
function self.Init()
    
    local ReplicaReciever = require(script.Parent.ReplicaReciever).Init()

    return self

end

return self