local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local janitor = require(ReplicatedStorage.Packages.janitor)
local AnimationHandler = require(ServerScriptService.Server.PlayerStateHandler.AnimationHandler)
local replica = require(ReplicatedStorage.Packages.replica)

--[=[
    @class PickupSystem
    @server
    @tag InteractiveHandler
]=]
local self = {}
local PlayerStateManager = require(ServerScriptService.Server.PlayerStateHandler.PlayerStateManager)

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

    local function onJoin(player : Player)
        self.PickupStack[player] = {}
        self.PizzaStackReplica:Set({player.UserId}, {})
        self.PizzaStackReplica:Set({player.UserId,"Pizza"},{})
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

local function GetDictionaryLength(dict : {[any] : any}) : number
    local count = 0
    for _ in pairs(dict) do
        count += 1
    end
    return count
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
    @function CancelPickup
    Cancels the current pickup action for a player and resets their state as well as animation + wipes the pickup stack
    @param player Player
    @within PickupSystem
]=]
function self.CancelPickup(player: Player)
    if not self.PickupStack[player.UserId] then
        return
    end

    print(`called here`)

    if self.CurrentAnimations[player] then
        self.CurrentAnimations[player].Stop()
        self.CurrentAnimations[player] = nil
    end

    self.PickupStack[player.UserId] = {}
    self.PizzaStackReplica:Set({player.UserId}, {})
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

    self._janitor = janitor.new()

    local CurrentPlayerState: {string} = PlayerStateManager.GetPlayerState(player)
    if not table.find(CurrentPlayerState, "HoldingPizza") then

        local ChangedState : boolean, PreviousState : {string} = PlayerStateManager.AttemptStateChange(player, "HoldingPizza", `None`, self._janitor:Add(function()
            print(`cancelled pickup for {player.Name}`)
            self.CancelPickup(player)
            PlayerStateManager.AttemptStateChange(player, `None`,`HoldingPizza`)
            self._janitor:Cleanup()
        end))

        if not(ChangedState) then
            warn(`cant change state from:`, PreviousState)
            return
        end

    end

    self.CurrentAnimations[player] = AnimationHandler.AnimatePlayer(player, "PickingUp", true)

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

    local itemData = {
        ID = itemID,
        Item = Item.Name,
        AboveHead = AboveHead,
        Position = GetDictionaryLength(self.PickupStack[player.UserId][itemName]) + 1
    }

    self.PickupStack[player.UserId][itemName][itemID] = itemData
    self.PizzaStackReplica:Set({player.UserId, itemName, itemID}, itemData)

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
        self.CurrentAnimations[player]:Stop()
        self.CurrentAnimations[player] = AnimationHandler.AnimatePlayer(player,"Idle",true)
        PlayerStateManager.AttemptStateChange(player, "None", "HoldingPizza")
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