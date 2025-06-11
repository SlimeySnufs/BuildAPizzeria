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

--[[PLAYER STATE MANANGER]]
local PlayerStateManager = script.PlayerStateHandler
local PlayerStateManagerMain = require(PlayerStateManager.PlayerStateManager).Init()

--[[ANIMATION HANDLER]]
local AnimationHandlerMain = require(PlayerStateManager.AnimationHandler).Init()

--[[MONEYPAD SERVICE]]
local MoneypadService = Services.MoneypadService
local MoneyPadLocationConfig = require(MoneypadService.LocationConfiguration).init()

--[[PRODUCTIONPAD SERVICE]]
local ProductionPadService = Services.ProductionPadService
local ProducionPadLocationConfig = require(ProductionPadService.LocationConfiguration).init()

--[[ACTIONPAD SERVICE]]
local ActionPadService = Services.ActionPadService
local ActionPadLocationConfig = require(ActionPadService.LocationConfiguration).Init()

--[[CUSTOMER HANDLING]]
local OrderHandling = script.InteractiveHandlers.OrderHandling
local OrderHandlingMain = require(OrderHandling.Main).Init()

--[[RESOURCE NODE SERVICE]]
local ResourceNodeService = Services.ResourceNodeService
local ResourceNodeLocationConfig = require(ResourceNodeService.LocationConfiguration).Init()

--[[NODE HARVESTING]]
local NodeHarvesting = script.InteractiveHandlers.NodeHarvesting
local NodeHarvestingMain = require(NodeHarvesting.Main).Init()

--[[PICKUP SYSTEM]]
local PickupSystem = script.InteractiveHandlers.PickupSystem
local PickupSystemMain = require(PickupSystem.Main).Init()

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