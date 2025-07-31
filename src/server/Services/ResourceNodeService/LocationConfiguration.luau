--[=[
    @class ResourceNodeService LocationConfiguration
    @tag ResourceNodeService
    @server
]=]
local self = {}

local ResourceNodeService = require(script.Parent.ResourceNode)
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerStateManager = require(ServerScriptService.Server.PlayerStateHandler.PlayerStateManager)

local replica = require(ReplicatedStorage.Packages.replica)
local zoneplus = require(ReplicatedStorage.Packages.zoneplus)
local ResourceNodeCache = require(ServerScriptService.Server.Services.ResourceNodeService.ResouceNodeCache)

--[=[
    @function Init
    Initializes the resource node service with location configurations
    @within ResourceNodeService LocationConfiguration
]=]
function self.Init()

    local NodeLocations: {Instance} = CollectionService:GetTagged("ResourceNodeLocation")

    self.NodeCache = {}

    self.ReplicaCache = {} :: {Player : any}

    self.ChangeZones = {
        ["FarmZone1"] = {
            Part = workspace.ChangeZones.FarmZone1,
            State = "Farming"
        },
        ["FarmZone2"] = {
            Part = workspace.ChangeZones.FarmZone2,
            State = "Farming"
        } 
    }

    for i, locationPart : BasePart in NodeLocations do
        local resource = locationPart:GetAttribute("ResourceType")
        
        if resource then
            local node = ResourceNodeService.new(resource, locationPart)
            node.ID = i
            self.NodeCache[i] = node
            ResourceNodeCache[node.ResourceModel] = node
        else
            warn("ResourceType attribute not found on part: " .. locationPart:GetFullName())
        end
    end

    for changezone , data : {Part : BasePart, State : PlayerStateManager.States} in self.ChangeZones do
        
        local newZone = zoneplus.new(data.Part)
        newZone.playerEntered:Connect(function(player : Player)
            PlayerStateManager.AttemptStateChange(player, data["State"])
        end)
        newZone.playerExited:Connect(function(player : Player)
            PlayerStateManager.AttemptStateChange(player, "None", data["State"])
        end)

    end

    self.HandleReplicas()

    return self

end

--[=[
    @function HandleReplicas
    Handles the replicas for resource nodes
    @within ResourceNodeService LocationConfiguration
]=]
function self.HandleReplicas()
    
    local function OnJoin(player : Player)
        
        local _ = player.Character or player.CharacterAdded:Wait()

        local PlrToken = replica.Token(player.UserId..`ResourceNodes`)
        local ResourceReplica = replica.New({
            Token = PlrToken,
            Data = {},
        })

        ResourceReplica:Replicate()

        self.ReplicaCache[player] = ResourceReplica

        for _ , node in self.NodeCache do
            if not node.ReplicaCache[player] then
                node:GiveReplica(player, ResourceReplica)
            end
        end

    end

    local function OnLeave(player : Player)

        if not self.ReplicaCache[player] then
            warn("No replica found for player: " .. player.Name)
            return
        end

        local resourceReplica = self.ReplicaCache[player]

        for _ , node in self.NodeCache do
            node:RemoveReplica(player)
        end

        self.ReplicaCache[player] = nil
        
    end

    Players.PlayerAdded:Connect(function(player)
        OnJoin(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        OnLeave(player)
    end)

    for _ , plr in Players:GetPlayers() do
        OnJoin(plr)
    end

    game:BindToClose(function()
        for _ , plr in Players:GetPlayers() do
            OnLeave(plr)
        end
    end)

end

return self