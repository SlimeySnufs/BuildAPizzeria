local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
--[=[
    @class PickupSystem
    @server
    @tag PickupSystem
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

    self.UpdateStackConnections = {} :: { [Player] : RBXScriptConnection }

    Players.PlayerAdded:Connect(function(player : Player)
        self.PickupStack[player] = {}
    end)

    Players.PlayerRemoving:Connect(function(player : Player)
        self.PickupStack[player] = nil
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

    return {
        Stop = function()
            if Animtrack then
                Animtrack:Stop()
            end
        end,

        IsPlaying = function()
            return Animtrack and Animtrack.IsPlaying or false
        end
    }
end

--[=[
    @function UpdatePlayerPickupStack
    Updates the player's pickup stack with the current items in physical form
    @param player Player
    @return RBXScriptConnection
    @within PickupSystem
]=]
function self.UpdatePlayerPickupStack(player: Player)

    if not self.PickupStack[player] then
        warn(`Player {player.Name} does not have a pickup stack initialized.`)
        return
    end

    if self.UpdateStackConnections[player] then
        self.UpdateStackConnections[player]:Disconnect()
        self.UpdateStackConnections[player] = nil
    end

    local conn: RBXScriptConnection = RunService.Heartbeat:Connect(function(dt: number)
    
        --[[update the player's pickup stack depending on their hrp and position in the stack]]
        if not self.PickupStack[player] then
            warn(`Player {player.Name} does not have a pickup stack initialized.`)
            return
        end

        local stack: { [string]: { AboveHead: boolean, Item: Instance, Position: number } } = self.PickupStack[player]

        for itemName: string, items: { AboveHead: boolean, Item: Instance, Position: number } in pairs(stack) do
        
            --[[PLACE IN RIGHT SPOT, TWEEN A LITTLE BIT WITH LERP TO MAKE SMOOTH MOVEMENT, MAKE HIGHER THINGS TAKE MORE TIME TO MOVE TO CORRECT POSITION]]

            local itemCount = GetDictionaryLength(items)

            for i = 1, itemCount do
                local itemData = items[i]
                if not itemData then continue end

                local item: Instance = itemData.Item
                if not item or not item:IsA("BasePart") then
                    warn(`Item {itemName} is not a valid BasePart.`)
                    continue
                end

                item.Parent = player.Character 

                local aboveHead: boolean = itemData.AboveHead
                local position: number = itemData.Position

                --[[Update the item's position based on the player's character and stack position]]
                if player.Character and player.Character.PrimaryPart then
                    local targetPosition = player.Character.Head.Position + Vector3.new(0, position * 0.25, 0)
                    if aboveHead then
                        targetPosition += Vector3.new(0, 0.25, 0) -- Adjust for above head
                    end
                    -- higher position items will take longer to move to the correct position 
                    item.Position = (item.Position:Lerp(targetPosition, (dt * 20) * (1/position))) -- Adjust lerp speed as needed
                end
            end

        end

    end)

    self.UpdateStackConnections[player] = conn

    return conn
end

--[=[
    @function CanPickUp
    Checks if a player can pick up an item, the max is 5
    @param player Player
    @return boolean
]=]
function self.CanPickUp(player: Player): boolean
    if not self.PickupStack[player] then
        warn(`Player {player.Name} does not have a pickup stack initialized.`)
        return false
    end

    local itemCount = 0
    for _, items in pairs(self.PickupStack[player]) do
        itemCount += 1
    end

    return itemCount < 3 -- Max 5 items can be picked up
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
    if not self.PickupStack[player] then
        warn(`Player {player.Name} does not have a pickup stack initialized.`)
        return
    end

    local itemName = Item.Name
    Item.CanCollide = false
    if not self.PickupStack[player][itemName] then
        self.PickupStack[player][itemName] = {}
    end

    local itemData = {
        Item = Item,
        AboveHead = AboveHead,
        Position = #self.PickupStack[player][itemName] + 1
    }

    table.insert(self.PickupStack[player][itemName], itemData)

    self.AnimatePlayerPickup(player, "AboveHead")
    self.UpdatePlayerPickupStack(player)

    print(`Player {player.Name} picked up {Item.Name} at position {itemData.Position}.`)
end


return self