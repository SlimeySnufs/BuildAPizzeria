--[=[
    @class PizzaPickupReplication Main
    @tag PizzaPickupReplication
    @client
]=]
local self = {}

--[=[
    @function Init
    Starts the replication for pizza pickup
    @within PizzaPickupReplication Main
]=]
function self.Init()
    
    local ReplicaReciever = require(script.Parent.ReplicaReciever).Init()

    return self

end

return self