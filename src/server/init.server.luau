local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Server: Script = ServerScriptService.Server
local Data = Server.Data
local DataManipulation= Server.DataManipulation
local DataReplication = Server.DataReplication

local DataMain = require(Data.Main)
local DataReplicationMain = require(DataReplication.Main)

local ProfileFetcher = require(DataManipulation.GetProfile)
local Playtime = require(DataManipulation.Playtime)

--[[SERVICES]]
local Services = script.Services

--[[MONEYPAD SERVICE]]
local MoneypadService = Services.MoneypadService
local MoneyPadLocationConfig = require(MoneypadService.LocationConfiguration).init()

--[[PRODUCTIONPAD SERVICE]]
local ProductionPadService = Services.ProductionPadService
local ProducionPadLocationConfig = require(ProductionPadService.LocationConfiguration).init()

local Types = require(ServerScriptService.Server.Types)

local function onPlayerAdded(player: Player)
    -- Initialize player profile when they join
    local profile : Types.Profile = ProfileFetcher.GetProfile(player)
    if not profile then
        error("Failed to initialize profile for player: " .. player.Name)
    end
    Playtime.AttachPlayerToPlaytimeLoop(player)
    DataReplicationMain.HandlePlayer(player)
    print(`Initalized all server things for {player.Name}`)
end

local function onPlayerRemoving(player: Player)
    -- Clean up player profile when they leave
    local profile : Types.Profile = ProfileFetcher.GetProfile(player)
    if profile then
        Playtime.DetachPlayerFromPlaytimeLoop(player)
        DataReplicationMain.UnhandlePlayer(player)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)