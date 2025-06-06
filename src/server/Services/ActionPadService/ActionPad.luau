local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Signal = require(ReplicatedStorage.Lib.Signal)
local replica = require(ReplicatedStorage.Packages.replica)
local zoneplus = require(ReplicatedStorage.Packages.zoneplus)
--[=[
    @class ActionPad
    @server
    @tag ActionPadService
]=]
local ActionPad = {}
ActionPad.__index = ActionPad

local Assets = ReplicatedStorage.Assets
local ActionPadModel : BasePart = Assets.Pads.PlayerInteractive:Clone()

export type ActionPad = typeof(ActionPad.new(...))

--[=[
    @function new
    Constructor function for ActionPad, holds actions and stores how much every player has on that pad

    @param ID String | number
    @param cframe CFrame

    @return ActionPad

    @within ActionPad
]=]
function ActionPad.new(id : string | number, cframe : CFrame) : ActionPad

    local self = setmetatable({}, ActionPad)

    --[=[
        @prop Position CFrame
        @within ActionPad
    ]=]
    self.Position = cframe

    --[=[
        @prop ID string | number
        @within ActionPad
    ]=]
    self.ID = id

    --[=[
        @prop ActionPadPhysical Model? | BasePart? | nil
        @within ActionPad
    ]=]
    self.ActionPadPhysical = ActionPadModel:Clone()
    self.ActionPadPhysical.Name = tostring(id)
    self.ActionPadPhysical.Parent = workspace.ActionPads
    self.ActionPadPhysical:PivotTo(self.Position)

    self.Hitbox = self:CreateHitbox() :: BasePart
    self.Hitbox.Parent = self.ActionPadPhysical

    self.IsActive = {} :: {
        [number] : {Status : boolean, Actor : ("Player" | "Worker" | nil)}
    }

    self.Zone = zoneplus.new(self.Hitbox)
    self.PlayerEntered = Signal.new()
    self.PlayerExited = Signal.new()

    self.Zone.playerEntered:Connect(function(player : Player)
        self.PlayerEntered:Fire(player)
    end)
    
    self.Zone.playerExited:Connect(function(player : Player)
        self.PlayerExited:Fire(player)
    end)

    self.PlayerEntered:Connect(function(player : Player)
        if not self.ReplicaCache[player] then
            warn(`Replica for {player.Name} not found in ActionPad.`)
            return
        end

        if self.IsActive[player.UserId] and self.IsActive[player.UserId].Status == true and self.IsActive.Actor ~= "Player" then
            return
        end

        self.IsActive[player.UserId] = {
            Status = true,
            Actor = "Player"
        }

        -- Set the action pad state for the player
        self.ReplicaCache[player]:Set({self.ID}, {
            Status = true,
            Actor = "Player"
        })
    end)

    self.PlayerExited:Connect(function(player : Player)
        if not self.ReplicaCache[player] then
            warn(`Replica for {player.Name} not found in ActionPad.`)
            return
        end

        if not self.IsActive[player.UserId] or self.IsActive[player.UserId].Status == false then
            return
        end

        self.IsActive[player.UserId] = {
            Status = false,
            Actor = nil
        }

        -- Reset the action pad state for the player
        self.ReplicaCache[player]:Set({self.ID}, {
            Status = false,
            Actor = nil
        })
    end)

    self.ReplicaCache = {} :: { [Player] : typeof(replica.New()) }

    return self
end

--[=[
    @method CreateHitbox
    Creates a hitbox for the ActionPadPhysical to detect player interactions
    @return BasePart
    @within ActionPad
]=]
function ActionPad:CreateHitbox() : BasePart
    local hitbox = Instance.new("Part")
    hitbox.Name = "Hitbox"
    hitbox.Size = Vector3.new(self.ActionPadPhysical.Size.X + 0.5,10,self.ActionPadPhysical.Size.Z + 0.5) -- Adjust size as needed
    hitbox.Transparency = 1 -- Make it invisible
    hitbox.CanCollide = false -- Disable collisions
    hitbox.Anchored = true -- Anchor it in place
    hitbox.CFrame = self.ActionPadPhysical.CFrame
    hitbox.Parent = self.ActionPadPhysical

    return hitbox
end

--[=[
    @method GetActiveActors
    Returns a table of active actors on the ActionPad
    @return { [number] : {Status : boolean, Actor : ("Player" | "Worker" | nil)} }
    @within ActionPad
]=]
function ActionPad:GetActiveActors() : { [number] : {Status : boolean, Actor : ("Player" | "Worker" | nil)} }
    return self.IsActive
end

--[=[
    @method GiveReplica
    Gives a replica to the ActionPad, allowing it to interact with the player

    @param replica Replica

    @within ActionPad
]=]
function ActionPad:GiveReplica(plr : Player,replica : typeof(replica.New()))
    if self.ReplicaCache[plr] then
        warn(`Replica for {plr.Name} already exists in ActionPad.`)
        return
    end

    -- Store the replica in a cache if needed
    self.ReplicaCache[plr] = replica

    if not(replica.Data[self.ID]) then
        replica:Set({self.ID}, {
            Status = false,
            Actor = nil
        })
    end

    self.IsActive[plr.UserId] = {
        Status = false,
        Actor = nil
    }
end

--[=[
    @method RemoveReplica
    Removes a replica from the ActionPad, cleaning up any references
    @param replica Replica
    @within ActionPad
]=]
function ActionPad:RemoveReplica(plr : Player)
    if not self.ReplicaCache[plr] then
        warn(`Replica for {plr.Name} not found in ActionPad.`)
        return
    end

    -- Clean up the replica reference
    self.ReplicaCache[plr] = nil
    self.IsActive[plr.UserId] = nil
end

return ActionPad