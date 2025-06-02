--[=[
    @class ProductionPad Replication Main
    @tag ProdPadRep
    @client
]=]
local module = {}

--[=[
    @function Init
    Starts the replication for production pads
    @within ProductionPad Replication Main
]=]
function module.Init()

    local ReplicaReciever = require(script.Parent.ReplicaReciever).Init()

end

return module