local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Resource = require(ServerScriptService.Server.DataManipulation.Resource)
local Signal = require(ReplicatedStorage.Lib.Signal)
local zoneplus = require(ReplicatedStorage.Packages.zoneplus)

--[=[
    @class ResourceNode
    @tag ResourceNodeService
    @__index ResourceNode
    @server
]=]
local ResourceNode = {}
ResourceNode.__index = ResourceNode

export type ResourceNode = typeof(ResourceNode.new(...))

type ResourceEnum =
    | "Wheat"
    | "Tomato"

local Assets = ReplicatedStorage.Assets
local ResourceAssets: Folder = Assets.Resources:Clone()

local UNIQUE_ID = 0

--[=[
    @function new
    @within ResourceNode
    @param resourceType string
    @param locationPart BasePart
    @return ResourceNode
]=]
function ResourceNode.new(resourceType: ResourceEnum, locationPart: BasePart): ResourceNode
    local self: ResourceNode = setmetatable({} :: any, ResourceNode)

    self.ID = UNIQUE_ID + 1
    UNIQUE_ID+=1
    self.ResourceType = resourceType :: string
    self.Location = locationPart
    self.ReplicaCache = {}

    if not ResourceAssets:FindFirstChild(resourceType) then
        error("Resource type " .. resourceType .. " does not exist in ResourceAssets")
    end

    self.ResourceModel = ResourceAssets:FindFirstChild(resourceType):Clone() :: Model
    self.ResourceModel.Parent = workspace.ResourceNodes
    local targetPos = Vector3.new(locationPart.Position.X, 0.5, locationPart.Position.Z)
    self.ResourceModel:PivotTo(CFrame.new(targetPos))
    self.ResourceModel.Name = resourceType .. "Node"

    self.Hitbox = self:CreateHitbox()

    self.PlayerEntered = Signal.new()
    self.PlayerExited = Signal.new()

    self.Zone = zoneplus.new(self.Hitbox)
    self.Zone.playerEntered:Connect(function(player: Player)
        self.PlayerEntered:Fire(player)
    end)
    self.Zone.playerExited:Connect(function(player: Player)
        self.PlayerExited:Fire(player)
    end)

    return self
end

--[=[
    @method GiveReplica
    @within ResourceNode
    @param player Player
    @param replica Replica
]=]
function ResourceNode:GiveReplica(player: Player, replica)
    if not self.ReplicaCache[player] then
        self.ReplicaCache[player] = replica
        replica:Set({self.ID}, {
            ResourceType = self.ResourceType,
            GrowthStage = 4,
            Regrowing = false,
            Physical = self.ResourceModel
        })
    else
        warn("Replica for player " .. player.Name .. " already exists in ResourceNode: " .. self.ResourceType)
    end
end

--[=[
    @method RemoveReplica
    @within ResourceNode
    @param player Player
]=]
function ResourceNode:RemoveReplica(player: Player)
    if self.ReplicaCache[player] then
        self.ReplicaCache[player] = nil
    else
        warn("No replica found for player " .. player.Name .. " in ResourceNode: " .. self.ResourceType)
    end
end

local GROWTH_TIMES = {
    ["Wheat"] = {3,5,3},
    ["Tomato"] = {5,4,5}
}

--[=[
    @method Harvest
    @param player Player
    @within ResourceNode
]=]
function ResourceNode:Harvest(player : Player)
    
    local PlayerReplica = self.ReplicaCache[player]
    if not(PlayerReplica) then
        warn(`{player.Name}'s replica wasnt found in the resource node`)
        return
    end

    print(PlayerReplica)

    if not(PlayerReplica.Data[self.ID]) then
        PlayerReplica:Set({self.ID},{
            ResourceType = self.ResourceType,
            GrowthStage = 4,
            Regrowing = false,
            Physical = self.ResourceModel
        })
    end

    local CropData = PlayerReplica.Data[self.ID]

    local isRegrowing : boolean = CropData.Regrowing
    local CurrentGrowthStage : number = CropData.GrowthStage

    if isRegrowing then return end

    if (CurrentGrowthStage <= 1) then
        return
    end

    PlayerReplica:Set({self.ID, "GrowthStage"},CurrentGrowthStage-1)
    
    if self.ResourceType == "Wheat" then
        Resource.IncrementWheat(player, 
            math.random(1,4)
        )
    end

    if self.ResourceType == "Tomato" then
        Resource.IncrementTomato(player, 
            math.random(1,2)
        )
    end

    if (CurrentGrowthStage-1) <= 1 then
        PlayerReplica:Set({self.ID, "Regrowing"},true)
        self:StartRegrowForPlayer(player)
    end

end

--[=[
    @method StartRegrowForPlayer
    @param player Player
    @param growthTime number
    @within ResourceNode
]=]
function ResourceNode:StartRegrowForPlayer(player : Player)
    
    local PlayerReplica = self.ReplicaCache[player]
    if not(PlayerReplica) then
        warn(`{player.Name}'s replica wasnt found in the resource node`)
        return
    end

    task.spawn(function()
        for stage : number, timeDelay : number in GROWTH_TIMES[self.ResourceType] do
            if not (player:IsDescendantOf(Players)) then
                return
            end

            task.wait(timeDelay)

            PlayerReplica:Set({self.ID,"GrowthStage"},stage+1)

        end
        PlayerReplica:Set({self.ID,"Regrowing"},false)
    end)

end

--[=[
    @method CreateHitbox
    Creates a hitbox for the resource node and optionally unions nearby untagged parts
    @within ResourceNode
    @return BasePart
]=]
function ResourceNode:CreateHitbox(): BasePart
    local hitbox: BasePart = Instance.new("Part")
    hitbox.Name = self.ResourceType .. "Hitbox"
    hitbox.Transparency = 1
    hitbox.CFrame = self.ResourceModel.PrimaryPart and self.ResourceModel.PrimaryPart.CFrame or self.ResourceModel:GetModelCFrame()
    hitbox.Size = Vector3.new(self.ResourceModel:GetExtentsSize().X * 0.5, 10, self.ResourceModel:GetExtentsSize().Z * 0.5)
    hitbox.Anchored = true
    hitbox.CanCollide = false
    hitbox.Parent = self.ResourceModel
    self.ResourceModel.PrimaryPart = hitbox

    return hitbox
end

return ResourceNode
