--[=[
    @class FetchReplica
    @client
    @tag ClientData
]=]
local module = {}
local Replica = require(script.Parent.ReplicaClient) 

--[=[
    @function Fetch
    @within FetchReplica
    Gets the replica and returns it, waits for it to be ready!
    @yields
]=]

function module.Fetch() : Replica.Replica
    
    local waitedTime = 0
    repeat
        waitedTime += 0.1
        task.wait(0.1)
    until Replica.Ready or waitedTime >= 15

    if not(Replica.Ready) then
        warn(`Timeout exhausted! Replica has not loaded in 15 seconds!`)
        return
    end

    return Replica

end

return module
