local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[=[
    @class MoneyPad
    @__index moneyPad
    @server
    This creates a money pad and its methods to add money or subtract into a players wallet
    @tag MoneypadService
]=]
local moneyPad = {}
moneyPad.__index = moneyPad

local AssetsFolder = ReplicatedStorage.Assets
local Lib = ReplicatedStorage.Lib
local Pads = AssetsFolder.Pads

local Signal = require(Lib.Signal)

local Packages = ReplicatedStorage.Packages
local Zone = require(Packages.zoneplus)

local MoneyPad = Pads.Moneypad:Clone()


export type MoneyPad = typeof(setmetatable({}, moneyPad))

--[=[
    @function new
    Constructor function for moneypads, holds money and stores how much every player has on that pad

    @param ID String | number
    @param cframe CFrame

    @return MoneyPad

    @within MoneyPad
]=]
function moneyPad.new(id : string | number, cframe : CFrame) : MoneyPad
    
    local self = setmetatable({}, moneyPad)

    --[=[
        @prop Position CFrame
        @within MoneyPad
    ]=]

    --[=[
        @prop ID string | number
        @within MoneyPad
    ]=]

    --[=[
        @prop MoneyPadPhysical Model? | BasePart? | nil
        @within MoneyPad
    ]=]

    --[=[
        @prop PlayerMoney {[Player] : {Money : number}}
        @within MoneyPad
    ]=]

    --[=[
        @prop PlayerEntered Signal
        @within MoneyPad
    ]=]

    --[=[
        @prop PlayerExited Signal
        @within MoneyPad
    ]=]

    self.Position = cframe
    self.ID = id
    self.MoneyPadPhysical = MoneyPad:Clone() :: Model
    self.MoneyPadPhysical.Parent = workspace
    self.MoneyPadPhysical.Name = "MoneyPad"..tostring(id)
    self.MoneyPadPhysical:PivotTo(self.Position)

    --[=[
        @prop hitbox BasePart?
        @within MoneyPad
    ]=]
    self.hitbox = self:CreateHitbox() :: BasePart
    print(`hit box returns: `, self.hitbox)

    self.MoneyPadZone = Zone.new(self.hitbox)
    self.MoneyPadZone.playerEntered:Connect(self.PlayerEntered)
    self.MoneyPadZone.playerExited:Connect(self.PlayerExited)

    self.PlayerEntered = Signal.new() :: typeof(Signal.new())
    self.PlayerExited = Signal.new() :: typeof(Signal.new())

    self.PlayerMoney = {} :: {
        [Player] : {
            Money : number,
        }
    }

    return self

end

--[=[
    @method GetMoneyOnPad
    Gets money that the player has on this specific pad
    @param player Player
    @return Money number?
    @within MoneyPad
]=]
function moneyPad:GetMoneyOnPad(player : Player) : number?
    
    if not(self.PlayerMoney[player]) or not(self.PlayerMoney[player].Money) then
        warn(`Didn't find any money on this pad for {player.Name}!`)
        return nil
    end

    return self.PlayerMoney[player].Money or 0 

end

--[=[
    @method AddMoneyOnPad
    Adds money that the player has on this pad
    
    @param player Player
    @param amount Number

    @return nil
    @within MoneyPad
]=]
function moneyPad:AddMoneyOnPad(player : Player, amount : number) : nil
    
    if not(self.PlayerMoney[player]) then
        self.PlayerMoney[player] = {
            Money = 0
        }
    end

    self.PlayerMoney[player].Money += amount

    return nil

end

--[=[
    @method CreateHitbox
    Gets a hitbox for the money pad
    @within MoneyPad
    @return BasePart
]=]
function moneyPad:CreateHitbox() : BasePart
    
    local hitbox : BasePart =  Instance.new("Part")
    hitbox.Name = "Hitbox"
    hitbox.Transparency = 1
    hitbox.CFrame = self.MoneyPadPhysical.pad.CFrame
    hitbox.Size = Vector3.new(self.MoneyPadPhysical.pad.Size.X,15,self.MoneyPadPhysical.pad.Size.Z)
    hitbox.Anchored = true 
    hitbox.CanCollide = false
    hitbox.Parent = self.MoneyPadPhysical
    self.MoneyPadPhysical.PrimaryPart = hitbox

    return hitbox

end

--[=[
    @method Destroy
    Removes all refrences and instances related to this class
    @within MoneyPad
]=]
function moneyPad:Destroy()
    
    if (self.MoneyPadPhysical) then
        self.MoneyPadPhysical:Destroy()
    end

    self.MoneyPadZone:Destroy()

    self.PlayerEntered:Destroy()
    self.PlayerExited:Destroy()

    setmetatable(self, nil)

end

return moneyPad