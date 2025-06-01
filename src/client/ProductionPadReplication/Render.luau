local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--[=[
    @class ProductionPad Render
    @tag ProdPadRep
    @client
]=]
local self = {}

local Assets = ReplicatedStorage.Assets
local ItemPhysicals = {
    ['Pizza'] = Assets.Pizza
}

local StackHeights = {
    Pizza = 0.25
}

local function GetStackHeight(itemName: string, part: BasePart)
    return StackHeights[itemName] or part.Size.Y
end

--[=[
    @function init
    @within ProductionPad Render
]=]
function self.init()
    self.ProductionStacks = {}
    return self
end

--[=[
    @function GetPad
    @param padName string
    @return Instance?
    @within ProductionPad Render
]=]
function self.GetPad(padName : string) : Instance?
    local productionPadsFolder = workspace.ProductionPads
    local pad: Instance? = productionPadsFolder:FindFirstChild(padName)
    if not pad then
        warn(`could not find pad name under {padName}`)
        return
    end
    return pad
end

--[=[
    @function AddFromProduction
    @param pad string
    @param key string
    @param item Instance
    @within ProductionPad Render
]=]
function self.AddFromProduction(pad : string, key : string, item : Instance)
    if not self.ProductionStacks[pad] then
        self.ProductionStacks[pad] = {}
        self.ProductionStacks[pad].Items = 0
        self.ProductionStacks[pad].Stack = {}
    end

    if self.ProductionStacks[pad][key] then
        warn("this key is already being rendered?")
        return
    end

    local asset = ItemPhysicals[item.Name]
    if not asset then
        warn(`No asset found for {item.Name} in ItemPhysicals`)
        return
    end

    local clone = asset:Clone()
    clone.Anchored = true
    clone.CanCollide = false
    clone.Transparency = 1

    if item.Name == "Pizza" then
        clone.Orientation = Vector3.new(0, 0, -90)
    end

    local padInstance = self.GetPad(pad)
    if not padInstance or not padInstance:IsA("Model") or not padInstance.PrimaryPart then
        warn(`Invalid pad model or PrimaryPart for pad {pad}`)
        return
    end

    local index = self.ProductionStacks[pad].Items
    local height = GetStackHeight(item.Name, clone)
    local basePos = padInstance.PrimaryPart.Position
    clone.Position = basePos + Vector3.new(0, height * index, 0)
    clone.Parent = padInstance

    TweenService:Create(clone, TweenInfo.new(0.3), { Transparency = 0 }):Play()

    self.ProductionStacks[pad][key] = clone
    table.insert(self.ProductionStacks[pad].Stack, clone)
    self.ProductionStacks[pad].Items += 1
end

--[=[
    @function RemoveFromProduction
    @param pad string
    @param key string
    @within ProductionPad Render
]=]
function self.RemoveFromProduction(pad : string, key : string)
    local stackData = self.ProductionStacks[pad]
    if not stackData then
        warn(`Pad {pad} has no stack data`)
        return
    end

    local instance = stackData[key]
    if not instance then
        warn(`this key was never rendered!`)
        return
    end

    stackData[key] = nil
    stackData.Items -= 1

    for i = #stackData.Stack, 1, -1 do
        if stackData.Stack[i] == instance then
            table.remove(stackData.Stack, i)
            break
        end
    end

    TweenService:Create(instance, TweenInfo.new(0.3), { Transparency = 1 }):Play()
    task.delay(0.3, function()
        instance:Destroy()
    end)
end

--[=[
    @function InitialRenderFromData
    Renders saved production pad items based on replica data
    @param pad string -- Pad ID (string, e.g. "Pad1")
    @param entries { [string]: { Position: number, Item: string } } -- Replica data from Replica.Data.ProductionPads[pad]
    @within ProductionPad Render
]=]
function self.InitialRenderFromData(pad: string, entries: { [string]: { Position: number, Item: string } })
    if not self.ProductionStacks[pad] then
        self.ProductionStacks[pad] = {}
        self.ProductionStacks[pad].Items = 0
        self.ProductionStacks[pad].Stack = {}
    end

    local padInstance = self.GetPad(pad)
    if not padInstance or not padInstance:IsA("Model") or not padInstance.PrimaryPart then
        warn(`Invalid pad model or PrimaryPart for pad {pad}`)
        return
    end

    -- Sort items by Position
    local sorted = {}
    for key, value in pairs(entries) do
        if value and typeof(value) == "table" and typeof(value.Position) == "number" then
            table.insert(sorted, { key = key, data = value })
        else
            warn(`Invalid entry in pad data: {key} -> {value}`)
        end
    end

    table.sort(sorted, function(a, b)
        return a.data.Position < b.data.Position
    end)

    for _, entry in ipairs(sorted) do
        local key = entry.key
        local itemName = entry.data.Item
        local asset = ItemPhysicals[itemName]
        if not asset then
            warn(`Missing asset for {itemName} in ItemPhysicals`)
            continue
        end

        local clone = asset:Clone()
        clone.Anchored = true
        clone.CanCollide = false
        clone.Transparency = 1

        if itemName == "Pizza" then
            clone.Orientation = Vector3.new(0, 0, -90)
        end

        local height = GetStackHeight(itemName, clone)
        local basePos = padInstance.PrimaryPart.Position
        clone.Position = basePos + Vector3.new(0, height * (entry.data.Position - 1), 0)
        clone.Parent = padInstance

        TweenService:Create(clone, TweenInfo.new(0.3), { Transparency = 0 }):Play()

        self.ProductionStacks[pad][key] = clone
        table.insert(self.ProductionStacks[pad].Stack, clone)
    end

    self.ProductionStacks[pad].Items = #sorted
end

return self
