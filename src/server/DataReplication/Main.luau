--[=[
    @class DataReplication
    @tag DataReplication
    Handles the players data to tell client playerdata
]=]
local module = {}

--[=[
    @prop HandledPlayers {[player] : RBXScriptConnection}
    @within DataReplication
]=]
module.HandledPlayers = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Packages = ReplicatedStorage.Packages
local Types = require(ServerScriptService.Server.Types)

local DataManipulation = ServerScriptService.Server.DataManipulation
local ReplicaFetcher = require(DataManipulation.GetReplica)

local Replica = require(Packages.replica)
local ProfileFetcher = require(DataManipulation.GetProfile)
local ReplicaCache = require(script.Parent.ReplicaCache)

--[=[
    @function HandlePlayer
    Initializes the players data replication to the client
    @within DataReplication
    @param player Player
    @return nil
]=]
function module.HandlePlayer(player: Player)
	local profile = ProfileFetcher.GetProfile(player)
	if not profile then
		warn(`Did not get profile for {player.Name}!`)
		return
	end

    if ReplicaCache[player] then
        warn(`Replica for {player.Name} already exists!`)
        return
    end

    local TokenVal = Replica.Token(tostring(player.UserId))

	local replica : Types.Replica = Replica.New({
    	Token = TokenVal,
        Tags = {
            Player = player
        },
    	Data = profile.Data,
	})

	replica:Replicate()

    ReplicaCache[player] = replica

    print(`Replica for {player.Name} initalized!`)

end

--[=[
    @function UnhandlePlayer
    Cleans up heartbeat and folder for the given player
    @within DataReplication
    @param player Player
    @return nil
]=]
function module.UnhandlePlayer(player: Player)
	local replica = ReplicaFetcher.GetReplica(player)
	if not(replica) then
		warn(`Did not get Replica for {player.Name}!`)
	end
	replica = nil
    if (ReplicaCache[player]) then
        ReplicaCache[player] = nil
    end
end

return module
