local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[=[
    @class PizzaPickupReplication Render
    @client
    @tag PizzaPickupReplication
]=]
local self = {}

--[=[
    @function Init
    Starts the replication for pizza pickup
    @within PizzaPickupReplication Render
]=]
function self.Init()
    self.PlayerStacks = {}
    self.PreExistingPizzas = {}

    return self
end

--[=[
    @function WeldPizzaToPlayer
    Welds a pizza item to a player's character
    @within PizzaPickupReplication Render
    @param player Player -- The player to weld the pizza to
    @param pizzaItem Instance -- The pizza instance to weld
]=]
function self.WeldPizzaToPlayer(player: Player, pizzaItem: Instance)
    local character = player.Character or player.CharacterAdded:Wait()

    if not character then
        warn("Character for player with UserId", player.UserId, "not found.")
        return
    end

    pizzaItem.Parent = character

    -- Create a weld to attach the pizza item to the player's humanoid root part
    local weld: WeldConstraint = Instance.new("WeldConstraint")
    weld.Part0 = character.PrimaryPart
    weld.Part1 = pizzaItem
    weld.Parent = pizzaItem
end

local ITEM_SPACING = 0.25

--[=[
    @function UpdatePlayerStack
    Updates the pizza stack for a player
    @within PizzaPickupReplication Render
    @param playerUserId number -- The UserId of the player whose stack is updating
    @param stackData {[string]: {any}} -- Stack data for rendering
]=]
function self.UpdatePlayerStack(playerName: string, stackData: {[string]: {any}})

    local player = Players:FindFirstChild(playerName)

    if not player then
        return warn("Player with Name", playerName, "not found.")
    end

    local character = player.Character or player.CharacterAdded:Wait()

    if not self.PlayerStacks[player] then
        self.PlayerStacks[player] = {}
    end

    self.PlayerStacks[player] = stackData

    -- Clean up existing pizza parts
    for _, child in character:GetChildren() do
        if child.Name == "Pizza" then
            child:Destroy()
        end
    end

    local pizzaStack = stackData["Pizza"]
    if not pizzaStack then return end

    -- Use sorted array to ensure consistent stacking even with sparse keys
    local sortedEntries = {}
    for _, pizzaInfo in pairs(pizzaStack) do
        table.insert(sortedEntries, pizzaInfo)
    end

    table.sort(sortedEntries, function(a, b)
        return (a.Position or 0) < (b.Position or 0)
    end)

    for renderIndex, pizzaInfo in ipairs(sortedEntries) do
        local pizzaItemName: string = pizzaInfo.Item
        if not pizzaItemName then
            warn("Pizza item not found for stack entry", renderIndex)
            continue
        end

        local physicalPizzaItem: Instance? = ReplicatedStorage.Assets:FindFirstChild(pizzaItemName)
        if not physicalPizzaItem then
            warn("Physical pizza item not found in Assets:", pizzaItemName)
            continue
        end

        physicalPizzaItem = physicalPizzaItem:Clone()
        physicalPizzaItem.CanCollide = false
        physicalPizzaItem.Name = "Pizza"

        local aboveHead = pizzaInfo.AboveHead or false
        local offsetY = ITEM_SPACING * (renderIndex - 1)

        if aboveHead then
            physicalPizzaItem.Position = character.Head.Position + Vector3.new(0, 0.5 + offsetY, 0)
        else
            physicalPizzaItem.Position = character.HumanoidRootPart.Position + Vector3.new(0, offsetY, 0)
        end

        physicalPizzaItem.Parent = character
        self.WeldPizzaToPlayer(player, physicalPizzaItem)
        physicalPizzaItem.Anchored = false
    end

    return nil
end

return self
