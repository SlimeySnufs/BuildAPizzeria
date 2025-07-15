local Players = game:GetService("Players")
local PhysiscsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local Server: Script = ServerScriptService.Server
local Data = Server.Data
local DataManipulation= Server.DataManipulation
local DataReplication = Server.DataReplication

local DataMain = require(Data.Main)
local DataReplicationMain = require(DataReplication.Main)

local ProfileFetcher = require(DataManipulation.GetProfile)
local Playtime = require(DataManipulation.Playtime)

--[[PHYSICS REGISTERED]]
PhysiscsService:RegisterCollisionGroup("Player")
PhysiscsService:RegisterCollisionGroup("Customer")
PhysiscsService:CollisionGroupSetCollidable("Player", "Customer", false)
PhysiscsService:CollisionGroupSetCollidable("Player", "Player", false)
PhysiscsService:CollisionGroupSetCollidable("Customer", "Customer", false)

--[[SERVICES]]
local Services = script.Services

--[[PARALLEL SERVICES INITIALIZATION]]
-- Parallelize services for faster server startup
task.spawn(function()
    --[[PLAYER STATE MANANGER]]
    local PlayerStateManager = script.PlayerStateHandler
    require(PlayerStateManager.PlayerStateManager).Init()
end)

task.spawn(function()
    --[[ANIMATION HANDLER]]
    local PlayerStateManager = script.PlayerStateHandler
    require(PlayerStateManager.AnimationHandler).Init()
end)

task.spawn(function()
    --[[MONEYPAD SERVICE]]
    local MoneypadService = Services.MoneypadService
    require(MoneypadService.LocationConfiguration).init()
end)

task.spawn(function()
    --[[PRODUCTIONPAD SERVICE]]
    local ProductionPadService = Services.ProductionPadService
    require(ProductionPadService.LocationConfiguration).init()
end)

task.spawn(function()
    --[[ACTIONPAD SERVICE]]
    local ActionPadService = Services.ActionPadService
    require(ActionPadService.LocationConfiguration).Init()
end)

task.spawn(function()
    --[[CUSTOMER HANDLING]]
    local OrderHandling = script.InteractiveHandlers.OrderHandling
    require(OrderHandling.Main).Init()
end)

task.spawn(function()
    --[[RESOURCE NODE SERVICE]]
    local ResourceNodeService = Services.ResourceNodeService
    require(ResourceNodeService.LocationConfiguration).Init()
end)

task.spawn(function()
    --[[NODE HARVESTING]]
    local NodeHarvesting = script.InteractiveHandlers.NodeHarvesting
    require(NodeHarvesting.Main).Init()
end)

task.spawn(function()
    --[[PICKUP SYSTEM]]
    local PickupSystem = script.InteractiveHandlers.PickupSystem
    require(PickupSystem.Main).Init()
end)

local Types = require(ServerScriptService.Server.Types)

local function setCollisionGroupForCharacter(character: Model, groupName: string)
    for _, basePart in character:GetDescendants() do
        if basePart:IsA("BasePart") then
            basePart.CollisionGroup = groupName
        end
    end
end

local function onPlayerAdded(player: Player)
    -- Initialize player profile when they join
    local profile : Types.Profile = ProfileFetcher.GetProfile(player)
    if not profile then
        error("Failed to initialize profile for player: " .. player.Name)
    end
    Playtime.AttachPlayerToPlaytimeLoop(player)
    DataReplicationMain.HandlePlayer(player)
    print(`Initalized all server things for {player.Name}`)
    setCollisionGroupForCharacter(player.Character or player.CharacterAdded:Wait(), "Player")
end

local function onPlayerRemoving(player: Player)
    -- Clean up player profile when they leave
    local profile : Types.Profile = ProfileFetcher.GetProfile(player)
    if profile then
        Playtime.DetachPlayerFromPlaytimeLoop(player)
        DataReplicationMain.UnhandlePlayer(player)
    end
end

for _ , plr in Players:GetPlayers() do
    onPlayerAdded(plr)
end

game:BindToClose(function()
    for _, player in Players:GetPlayers() do
        onPlayerRemoving(player)
    end
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)