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
        self.PizzaStackReplica:Set({player.Name}, {})
        self.PizzaStackReplica:Set({player.Name,"Pizza"},{})
    end

    Players.PlayerAdded:Connect(function(player : Player)
        onJoin(player)
    end)

    for _, player in Players:GetPlayers() do
        onJoin(player)
    end

    Players.PlayerRemoving:Connect(function(player : Player)
        self.PickupStack[player] = nil
        self.PizzaStackReplica:Set({player.Name}, nil)
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
    if not self.PickupStack[player] then
        self.PickupStack[player] = {}
        self.PizzaStackReplica:Set({player.Name}, {})
    end

    if not self.PickupStack[player][itemName] then
        self.PickupStack[player][itemName] = {}
        self.PizzaStackReplica:Set({player.Name, itemName}, {})
    end

    return GetDictionaryLength(self.PickupStack[player][itemName]) < 15
end

--[=[
    @type PizzaData { ID: string, Item: string, AboveHead: boolean, Position: number }
    @within PickupSystem
]=]
export type PizzaData = { ID: string, Item: string, AboveHead: boolean, Position: number }

--[=[
    @function CancelPickup
    Cancels the current pickup action for a player and resets their state as well as animation + wipes the pickup stack
    @param player Player
    @within PickupSystem
]=]
function self.CancelPickup(player: Player,itemName: string)
    if not self.PickupStack[player] then
        print(`no pickup stack`)
        return
    end

    print(self.PickupStack[player],`is the players stack`)
    for delName, items : {[string] : PizzaData} in pairs(self.PickupStack[player]) do
        if (delName ~= itemName) then
            continue
        end
        for key , itemdata : PizzaData in items do
            self.RemovePizzaAtPosition(player, itemdata.Item, itemdata.Position)
        end
        print(items)
    end

    if self.CurrentAnimations[player] then
        self.CurrentAnimations[player].Stop()
        self.CurrentAnimations[player] = nil
    end
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
    if not(player) then return end

    print(player,AboveHead,Item)

    if not self.PickupStack[player] then
        self.PickupStack[player] = {}
    end

    self._janitor = janitor.new()

    print(`picked up item:`, Item.Name)

    local CurrentPlayerState: {PlayerStateManager.States} = PlayerStateManager.GetPlayerState(player)
    if not table.find(CurrentPlayerState, "HoldingPizza") then

        PlayerStateManager.AttemptStateChange(player, "HoldingPizza", `None`, self._janitor:Add(function()
            self.CancelPickup(player,`Pizza`)
            self._janitor:Cleanup()
        end))

    end

    self.CurrentAnimations[player] = AnimationHandler.AnimatePlayer(player, "PickingUp", true)

    local itemName = Item.Name
    local itemID = (itemName..tick()/10)
    Item.CanCollide = false

    if not(self.PickupStack[player]) then
        self.PickupStack[player] = {}
        self.PizzaStackReplica:Set({player.Name}, {})
    end

    if not self.PickupStack[player][itemName] then
        self.PickupStack[player][itemName] = {}
        self.PizzaStackReplica:Set({player.Name, itemName}, {})
    end

    local itemData = {
        ID = itemID,
        Item = Item.Name,
        AboveHead = AboveHead,
        Position = GetDictionaryLength(self.PickupStack[player][itemName]) + 1
    }

    self.PickupStack[player][itemName][itemID] = itemData
    self.PizzaStackReplica:Set({player.Name, itemName, itemID}, itemData)

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
    if not self.PickupStack[player] or not self.PickupStack[player][itemName] then
        warn(`Player {player.Name} does not have item {itemName} in their pickup stack.`)
        return
    end

    local itemData = table.remove(self.PickupStack[player][itemName], GetDictionaryLength(self.PickupStack[player][itemName]))
    if not itemData then
        warn(`No items found for {itemName} in player {player.Name}'s pickup stack.`)
        return
    end

    self.PizzaStackReplica:Set({player.Name, itemName, itemData.ID}, nil)

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
    if not self.PickupStack[player] or not self.PickupStack[player][itemName] then
        warn(`Player {player.Name} does not have item {itemName} in their pickup stack.`)
        return
    end

    local itemData = nil
    for id, data in self.PickupStack[player][itemName] do
        if data.Position == position then
            itemData = data
            break
        end
    end

    if not itemData then
        return
    end

    self.PickupStack[player][itemName][itemData.ID] = nil
    self.PizzaStackReplica:Set({player.Name, itemName, itemData.ID}, nil)

    local currentPosition = 1
    for id, data in self.PickupStack[player][itemName] do
        data.Position = currentPosition
        self.PizzaStackReplica:Set({player.Name, itemName, id}, data)
        currentPosition += 1
    end

    if GetDictionaryLength(self.PickupStack[player][itemName]) == 0 then
        self.CurrentAnimations[player].Stop()
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
    if not self.PickupStack[player] or not self.PickupStack[player][itemName] then
        warn(`Player {player.Name} does not have item {itemName} in their pickup stack.`)
        return nil
    end

    local highest = 0
    local item = nil
    for id , itemData in self.PickupStack[player][itemName] do
        if itemData.Position > highest then
            highest = itemData.Position
            item = itemData
        end
    end

    return item
end

return self