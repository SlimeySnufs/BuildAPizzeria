--[=[
    @class CustomerReplication Main
    @client
    @tag CustomerReplication
]=]
local self = {}

--[=[
    @function Init
    @within CustomerReplication Main
]=]
function self.Init()

    local ReplicaReciever = require(script.Parent.ReplicaReciever).Init()

    return self

end

return self