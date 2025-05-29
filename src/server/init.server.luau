local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Server: Script = ServerScriptService.Server
local Data = Server.Data
local DataManipulation: any= Server.DataManipulation


local ProfileFetcher = require(DataManipulation.GetProfile)
local Playtime = require(DataManipulation.Playtime)

local Types = require(ServerScriptService.Server.Types)

local function onPlayerAdded(player: Player)
    -- Initialize player profile when they join
    local profile : Types.Profile = ProfileFetcher.GetProfile(player)
    if not profile then
        error("Failed to initialize profile for player: " .. player.Name)
    end
    Playtime.AttachPlayerToPlaytimeLoop(player)
end

local function onPlayerRemoving(player: Player)
    -- Clean up player profile when they leave
    local profile : Types.Profile = ProfileFetcher.GetProfile(player)
    if profile then
        Playtime.DetachPlayerFromPlaytimeLoop(player)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)