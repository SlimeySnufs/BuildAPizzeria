--[=[
    @class MoneyPadReplication Main
    Initialization of client procession of money pad data from the server
    @client
    @tag MoneyPadReplication
]=]
local module = {}

--[=[
    @function Init
    Starts the process
    @within MoneyPadReplication Main
]=]
function module.Init()

    print(`ReplicaReciever for moneypad was initted!`)
    
    local ReplicaReciever = require(script.Parent.ReplicaReciever)
    ReplicaReciever.Init()

end

return module