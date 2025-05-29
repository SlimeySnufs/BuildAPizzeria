--[=[
    @class DataReplication
    @tag DataReplication
    Handles the players data to tell client playerdata
]=]
local module = {
    HandledPlayers = {}
}

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Server = ServerScriptService.Server
local Types = require(Server.Types)

local DataManipulation = ServerScriptService.Server.DataManipulation
local ProfileFetcher = require(DataManipulation.GetProfile)

local UPDATE_INTERVAL = 0.5 -- Update delay in seconds

--[=[
    Recursively replicates a Lua table into folders/values under a parent
    @param dataTable table
    @param parent Instance
]=]
local function replicateToInstance(dataTable: {}, parent: Instance)
	for key, value in pairs(dataTable) do
		if typeof(key) ~= "string" then continue end

		local existing = parent:FindFirstChild(key)

		if typeof(value) == "table" then
			local folder = existing or Instance.new("Folder")
			folder.Name = key
			folder.Parent = parent
			replicateToInstance(value, folder)
		elseif typeof(value) == "number" or typeof(value) == "string" or typeof(value) == "boolean" then
			local val = existing or Instance.new("StringValue")
			val.Name = key
			val.Parent = parent
			local str = tostring(value)
			if val.Value ~= str then
				val.Value = str
			end
		end
	end
end

--[=[
    @function HandlePlayer
    Initializes the players data replication to the client

    @param player Player
    @return nil
]=]
function module.HandlePlayer(player: Player)
	local profile = ProfileFetcher.GetProfile(player)
	if not profile then
		warn(`Did not get profile for {player.Name}!`)
		return
	end

	local statsFolder = Instance.new("Folder")
	statsFolder.Name = "PlayerStats"
	statsFolder.Parent = player

	local lastUpdate = 0

	local connection = RunService.Heartbeat:Connect(function(dt)
		lastUpdate += dt
		if lastUpdate < UPDATE_INTERVAL then return end
		lastUpdate = 0

		if not player or not player:IsDescendantOf(game) then return end

		local success, err = pcall(function()
			replicateToInstance(profile.Data, statsFolder)
		end)

		if not success then
			warn(`Replication error for {player.Name}: {err}`)
		end
	end)

	module.HandledPlayers[player] = {
		Connection = connection,
		StatsFolder = statsFolder
	}
end

--[=[
    @function UnhandlePlayer
    Cleans up heartbeat and folder for the given player

    @param player Player
    @return nil
]=]
function module.UnhandlePlayer(player: Player)
	local data = module.HandledPlayers[player]
	if data then
		if data.Connection then
			data.Connection:Disconnect()
		end
		if data.StatsFolder and data.StatsFolder.Parent then
			data.StatsFolder:Destroy()
		end
		module.HandledPlayers[player] = nil
	end
end

return module
