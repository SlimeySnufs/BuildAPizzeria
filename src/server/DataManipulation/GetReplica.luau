--[=[
    @class GetReplica
    @server
    @tag DataManipulation
    A module for fetching the players replica class
]=]
local module = {}
local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService.Server

local DataReplication = Server.DataReplication

local Types = require(ServerScriptService.Server.Types)

local ReplicaCache = require(DataReplication.ReplicaCache)

--[=[
    @function GetReplica
    @server
    @within GetReplica
    Returns the Replica of the given player.
    If the player is not found or invalid, an error is raised.
    
    @param Player Player
    @return Profile

    @error NotFound -- "Couldn't find Replica after 15 seconds"

    @yields
    @tag DataManipulation
]=]
function module.GetReplica(player: Player) : Types.Replica

    local waitTime = 0

    if (ReplicaCache[player]) then
        return ReplicaCache[player]
    end

    repeat 
        task.wait(0.1)
        waitTime += 0.1
    until ReplicaCache[player] or waitTime >= 15

    if not(ReplicaCache[player]) then
        error("Couldnt find Profile after 15 seconds")
        return nil
    end

    return ReplicaCache[player]
end

return module