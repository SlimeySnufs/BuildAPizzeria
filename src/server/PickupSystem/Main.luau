local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local replica = require(ReplicatedStorage.Packages.replica)
--[=[
    @class PickupSystem
    @server
    @tag InteractiveHandler
]=]
local self = {}

--[=[
    @function Init
    Initializes the pickup system
    @within PickupSystem
]=]
function self.Init()
    self.PickupStack = {} :: {
        [Player] : {[string] : {Item : Instance, AboveHead : boolean, Position : number}}
    }

    local PlacePizzaStackToken= replica.Token("PizzaStack")

    self.PizzaStackReplica = replica.New({
        Token = PlacePizzaStackToken,
        Data = {} :: { [Player] : { [string] : {Item : Instance, AboveHead : boolean, Position : number} } }
    })

    self.PizzaStackReplica:Replicate()

    self.UpdateStackConnections = {} :: { [Player] : RBXScriptConnection }

    self.CurrentAnimations = {} :: { [Player] : string}
    self.CurrentAnimationMethods = {} :: { [Player] : { Stop: () -> (), IsPlaying: () -> boolean } }

    local function onJoin(player : Player)
        self.PickupStack[player] = {}
        self.PizzaStackReplica:Set({player.UserId}, {})
        self.PizzaStackReplica:Set({player.UserId,"Pizza"},{})
        self.CurrentAnimations[player] = "Idle"
    end

    Players.PlayerAdded:Connect(function(player : Player)
        onJoin(player)
    end)

    for _, player in Players:GetPlayers() do
        onJoin(player)
    end

    Players.PlayerRemoving:Connect(function(player : Player)
        self.PickupStack[player] = nil
        self.PizzaStackReplica:Set({player}, nil)
        self.CurrentAnimations[player] = nil
    end)

    return self
end

local Animations = {
    AboveHead = "rbxassetid://85253249744129" -- Replace with actual animation ID
}

local function GetDictionaryLength(dict : {[any] : any}) : number
    local count = 0
    for _ in pairs(dict) do
        count += 1
    end
    return count
end

--[=[
    @function AnimatePlayerPickup
    Animates the pickup of an item by a player
    @param player Player
    @param animationType ("AboveHead")
    @within PickupSystem
]=]
function self.AnimatePlayerPickup(player: Player, animationType: string)
    if not(Animations[animationType]) then
        warn(`Animation type {animationType} is not defined correct.`)
        return
    end

    if self.CurrentAnimations[player] == animationType then
        return
    end

    local Humanoid: Humanoid? = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local Animator : Animator = Humanoid and Humanoid:FindFirstChild("Animator")

    local Animation = Instance.new("Animation")
    Animation.AnimationId = Animations[animationType]
    if not Animator then
        warn(`Animator not found for player {player.Name}.`)
        return
    end

    local Animtrack = Animator:LoadAnimation(Animation)
    Animtrack.Looped = true
    Animtrack.Priority = Enum.AnimationPriority.Action2
    Animtrack:Play()

    self.CurrentAnimations[player] = animationType

    local methods = {
        Stop = function()
            if Animtrack then
                Animtrack:Stop()
            end
        end,

        IsPlaying = function()
            return Animtrack and Animtrack.IsPlaying or false
        end
    }

    self.CurrentAnimationMethods[player] = methods

    return methods
end

--[=[
    @function CanPickUp
    Checks if a player can pick up an item, the max is 5
    @param player Player
    @return boolean
    @within PickupSystem
]=]
function self.CanPickUp(player: Player, itemName : string): boolean
    if not self.PickupStack[player.UserId] then
        self.PickupStack[player.UserId] = {}
        self.PizzaStackReplica:Set({player.UserId}, {})
    end

    if not self.PickupStack[player.UserId][itemName] then
        self.PickupStack[player.UserId][itemName] = {}
        self.PizzaStackReplica:Set({player.UserId, itemName}, {})
    end

    return GetDictionaryLength(self.PickupStack[player.UserId][itemName]) < 15
end

--[=[
    @function PickUp
    Handles the pickup of an item by a player
    @param player Player
    @param AboveHead boolean
    @param Item Instance
    @return nil
    @within PickupSystem
]=]
function self.PickUp(player: Player, AboveHead: boolean, Item: Instance)
    if not self.PickupStack[player.UserId] then
        self.PickupStack[player.UserId] = {}
    end

    self.AnimatePlayerPickup(player, "AboveHead")

    local itemName = Item.Name
    local itemID = (itemName..tick()/10)
    Item.CanCollide = false

    if not(self.PickupStack[player.UserId]) then
        self.PickupStack[player.UserId] = {}
        self.PizzaStackReplica:Set({player.UserId}, {})
    end

    if not self.PickupStack[player.UserId][itemName] then
        self.PickupStack[player.UserId][itemName] = {}
        self.PizzaStackReplica:Set({player.UserId, itemName}, {})
    end

    print(`before:`,self.PizzaStackReplica.Data)

    local itemData = {
        ID = itemID,
        Item = Item.Name,
        AboveHead = AboveHead,
        Position = GetDictionaryLength(self.PickupStack[player.UserId][itemName]) + 1
    }

    self.PickupStack[player.UserId][itemName][itemID] = itemData
    self.PizzaStackReplica:Set({player.UserId, itemName, itemID}, itemData)

    print(self.PizzaStackReplica.Data)

    print(`Player {player.Name} picked up {Item.Name} at position {itemData.Position}.`)
end

--[=[
    @function RemoveTopItem
    Removes an item from the player's pickup stack
    @param player Player
    @param itemName string
    @return nil
    @within PickupSystem
]=]
function self.RemoveTopItem(player: Player, itemName: string)
    if not self.PickupStack[player.UserId] or not self.PickupStack[player.UserId][itemName] then
        warn(`Player {player.Name} does not have item {itemName} in their pickup stack.`)
        return
    end

    local itemData = table.remove(self.PickupStack[player][itemName], GetDictionaryLength(self.PickupStack[player][itemName]))
    if not itemData then
        warn(`No items found for {itemName} in player {player.Name}'s pickup stack.`)
        return
    end

    self.PizzaStackReplica:Set({player.UserId, itemName, itemData.ID}, nil)

    print(`Player {player.Name} removed {itemName} from their pickup stack.`)
end

--[=[
    @function RemovePizzaAtPosition
    Removes a pizza item at a specific position from the player's pickup stack
    @param player Player
    @param itemName string
    @param position number
    @return nil
    @within PickupSystem
]=]
function self.RemovePizzaAtPosition(player: Player, itemName: string, position: number)
    if not self.PickupStack[player.UserId] or not self.PickupStack[player.UserId][itemName] then
        warn(`Player {player.Name} does not have item {itemName} in their pickup stack.`)
        return
    end

    local itemData = nil
    for id, data in self.PickupStack[player.UserId][itemName] do
        if data.Position == position then
            itemData = data
            break
        end
    end

    if not itemData then
        return
    end

    self.PickupStack[player.UserId][itemName][itemData.ID] = nil
    self.PizzaStackReplica:Set({player.UserId, itemName, itemData.ID}, nil)

    local currentPosition = 1
    for id, data in self.PickupStack[player.UserId][itemName] do
        data.Position = currentPosition
        self.PizzaStackReplica:Set({player.UserId, itemName, id}, data)
        currentPosition += 1
    end

    if GetDictionaryLength(self.PickupStack[player.UserId][itemName]) == 0 then
        self.CurrentAnimationMethods[player]:Stop()
        self.CurrentAnimations[player] = "Idle"
    end
end

--[=[
    @function GetTopItem
    Gets the top item from the player's pickup stack
    @param player Player
    @param itemName string
    @within PickupSystem
]=]
function self.GetTopItem(player: Player, itemName: string)
    if not self.PickupStack[player.UserId] or not self.PickupStack[player.UserId][itemName] then
        warn(`Player {player.Name} does not have item {itemName} in their pickup stack.`)
        return nil
    end

    local highest = 0
    local item = nil
    for id , itemData in self.PickupStack[player.UserId][itemName] do
        if itemData.Position > highest then
            highest = itemData.Position
            item = itemData
        end
    end

    return item
end

return self