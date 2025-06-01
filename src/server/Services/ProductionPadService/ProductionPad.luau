local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Signal = require(ReplicatedStorage.Lib.Signal)
local zoneplus = require(ReplicatedStorage.Packages.zoneplus)
local GetProfile = require(ServerScriptService.Server.DataManipulation.GetProfile)

--[=[
    @class ProductionPad
    @tag ProductionPadService
    @server
]=]
local ProductionPad = {}
ProductionPad.__index = ProductionPad

local Assets = ReplicatedStorage.Assets
local ProductionPadAsset: Model = Assets.Pads.ProductionPad:Clone()

type ProductionPadClass = typeof(ProductionPad.new(...))
export type ProductionPad = ProductionPadClass

function ProductionPad.new(id : string | number, cframe : CFrame, productionOutput : BasePart) : ProductionPadClass
    local self : ProductionPadClass = setmetatable({}, ProductionPad)

    self.ID = id
    self.Position = cframe
    self.PhysicalModel = ProductionPadAsset:Clone()
    self.PhysicalModel.Name = self.ID
    self.PhysicalModel.Parent = workspace.ProductionPads
    self.PhysicalModel:PivotTo(cframe)

    self.ProductionOutput = productionOutput
    self.PlayerEntered = Signal.new()
    self.PlayerExited = Signal.new()
    self.ItemStack = {} :: { [Player] : { { Position: number, Item: string, Key: string } } }
    self.Hitbox = self:CreateHitbox()
    self.ProductionPadZone = zoneplus.new(self.Hitbox)

    self.ProductionPadZone.playerEntered:Connect(function(plr : Player)
        self.PlayerEntered:Fire(plr)
    end)

    self.ProductionPadZone.playerExited:Connect(function(plr : Player)
        self.PlayerExited:Fire(plr)
    end)

    self.ReplicaCache = {} :: { [Player] : any }

    return self
end

function ProductionPad:CreateHitbox() : BasePart
    local hitbox : BasePart = Instance.new("Part")
    hitbox.Name = "Hitbox"
    hitbox.Transparency = 1
    hitbox.CFrame = self.PhysicalModel.pad.CFrame
    hitbox.Size = Vector3.new(self.PhysicalModel.pad.Size.X, 15, self.PhysicalModel.pad.Size.Z)
    hitbox.Anchored = true 
    hitbox.CanCollide = false
    hitbox.Parent = self.PhysicalModel
    self.PhysicalModel.PrimaryPart = hitbox
    return hitbox
end

function ProductionPad:GiveReplica(player : Player, replica)
    if (self.ReplicaCache[player]) then
        error(`The replica is already stored for {player.Name}`)
        return
    end

    self.ReplicaCache[player] = replica

    local profile = GetProfile.GetProfile(player)

    if not(profile.Data["ProductionPads"][self.ID]) then
        profile.Data["ProductionPads"][self.ID] = {}
    end

    self.ItemStack[player.UserId] = profile.Data["ProductionPads"][self.ID]
end

function ProductionPad:RemoveReplica(player : Player, replica)
    if not(self.ReplicaCache[player]) then
        error(`The replica is not stored for {player.Name}`)
        return
    end

    self.ItemStack[player.UserId] = nil
    self.ReplicaCache[player] = nil
end

function ProductionPad:Produce(player : Player, Item : Model | BasePart)
    local replica = self.ReplicaCache[player]
    if not replica then return end

    local stack = self.ItemStack[player.UserId]
    if not stack then return end
    if #stack >= 8 then return end

    local profile = GetProfile.GetProfile(player)
    local ItemsGenerated : number = profile.Data["ItemsGenerated"]

    local id : string = tostring(player.UserId) .. tostring(ItemsGenerated + 1)
    local currentAmount = #stack

    local itemData = {
        Position = currentAmount + 1,
        Item = Item.Name,
        Key = id,
    }

    replica:Set({self.ID, id}, itemData)
    profile.Data["ItemsGenerated"] += 1
    profile.Data["ProductionPads"][self.ID][id] = itemData
    table.insert(stack, itemData)
end

function ProductionPad:PickUp(player : Player)
    local stack = self.ItemStack[player.UserId]
    if not stack or #stack <= 0 then
        warn(`nothing is in the players item stack`)
        return
    end

    local replica = self.ReplicaCache[player]
    if not replica then
        error(`The replica for {player.Name} wasn't found`)
        return
    end

    local profile = GetProfile.GetProfile(player)
    local TopOfStack = table.remove(stack, #stack)
    local key = TopOfStack.Key

    print(`removed :`, TopOfStack)
    print(`using key: {key}`)

    replica:Set({self.ID, key}, nil)
    profile.Data["ProductionPads"][self.ID][key] = nil
end

return ProductionPad
