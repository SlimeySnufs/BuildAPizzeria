local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[=[
    @class MoneyPadRender
    Renders the money and updates the amount of cash bills on the moneypad
    @client
    @tag MoneyPadReplication
]=]
local self = {}

-- Constants
local BILLS_PER_LAYER = 32 -- 4 x 8
local BILLS_PER_AMOUNT = 3 -- 1 bill per 2 dollars
local GRID_WIDTH = 4
local GRID_DEPTH = 8

--[=[
    @prop CurrentRenders {[string] : {
        Bills: {Instance},
        MergedLayers: {BasePart}
    }}
    @within MoneyPadRender
]=]
self.CurrentRenders = {}

--[=[
    @function Init
    Initializes the cache for render tracking.
    @within MoneyPadRender
]=]
function self.Init()
    print("[MoneyPadRender] Initialized")
    self.CurrentRenders = {}
    return self
end

--[=[
    @function GetPad
    Gets the correct pad model from workspace.
    @param padName string
    @return Model
    @error NotFound -- If pad is not found or does not meet requirements.
    @within MoneyPadRender
]=]
function self.GetPad(padName: string): Model
    local pad = workspace:WaitForChild("MoneyPads"):FindFirstChild(padName)
    if not pad then
        error(`Could not find MoneyPad: {padName}`)
    end
    if not pad:IsA("Model") or not pad.PrimaryPart then
        error(`MoneyPad {padName} must be a Model with a PrimaryPart set`)
    end
    return pad
end

--[=[
    @function FadeTransparency
    Smoothly changes transparency of a model or part.
    @param instance Instance
    @param target number
    @param step number
    @within MoneyPadRender
]=]
function self.FadeTransparency(instance: Instance, target: number, step: number)
    task.spawn(function()
        local function setTransparency(obj: Instance, value: number)
            if obj:IsA("BasePart") then
                obj.Transparency = value
            end
        end

        local current = instance:IsA("Model") and instance.PrimaryPart and instance.PrimaryPart.Transparency or (instance :: BasePart).Transparency
        local direction = target > current and 1 or -1

        while math.abs(current - target) > 0.05 do
            current += direction * step
            current = math.clamp(current, 0, 1)

            if instance:IsA("Model") then
                for _, part in ipairs(instance:GetDescendants()) do
                    setTransparency(part, current)
                end
            else
                setTransparency(instance, current)
            end

            task.wait(0.01)
        end
    end)
end

--[=[
    @function CreateLayerPart
    Creates a flattened part that represents one layer of cash.
    @param baseCFrame CFrame
    @param y number
    @param size Vector3
    @param color Color3
    @param material Enum.Material
    @return Part
    @within MoneyPadRender
]=]
function self.CreateLayerPart(baseCFrame: CFrame, y: number, size: Vector3, color: Color3, material: Enum.Material): Part
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Color = color
    part.Material = material
    part.Size = size
    part.CFrame = baseCFrame * CFrame.new(0, y, 0)
    part.Transparency = 1
    return part
end

--[=[
    @function UpdateRender
    Updates the render stack on a MoneyPad.
    @param padName string
    @param amount number
    @error NotFound -- If the pad or asset references are missing.
    @within MoneyPadRender
]=]
function self.UpdateRender(padName: string, amount: number)
    local pad = self.GetPad(padName)
    local originCFrame = pad.PrimaryPart.CFrame
    local targetBillCount = math.floor(amount / BILLS_PER_AMOUNT)

    self.CurrentRenders[padName] = self.CurrentRenders[padName] or { Bills = {}, MergedLayers = {} }
    local render = self.CurrentRenders[padName]

    local sample = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Cash"):Clone()
    local refPart = sample:IsA("Model") and sample.PrimaryPart or sample
    if not refPart then error("Cash model must have a PrimaryPart.") end

    local size = refPart.Size
    local color = refPart.Color
    local material = refPart.Material

    local function placeBill(index: number)
        local layer = math.floor(index / BILLS_PER_LAYER)
        local posInLayer = index % BILLS_PER_LAYER
        local x = posInLayer % GRID_WIDTH
        local z = math.floor(posInLayer / GRID_WIDTH)

        local bill = ReplicatedStorage.Assets.Cash:Clone()
        local offset = CFrame.new(
            (x - GRID_WIDTH / 2 + 0.5) * size.X,
            layer * size.Y,
            (z - GRID_DEPTH / 2 + 0.5) * size.Z
        )

        if bill:IsA("Model") then
            bill:SetPrimaryPartCFrame(originCFrame * offset)
        else
            bill.CFrame = originCFrame * offset
        end

        bill.Parent = pad
        self.FadeTransparency(bill, 0, 0.1)
        table.insert(render.Bills, bill)
    end

    local totalCurrent = #render.Bills + #render.MergedLayers * BILLS_PER_LAYER

    while totalCurrent < targetBillCount do
        placeBill(totalCurrent)
        totalCurrent += 1

        if #render.Bills == BILLS_PER_LAYER then
            local layerY = (totalCurrent / BILLS_PER_LAYER - 1) * size.Y
            local layer = self.CreateLayerPart(originCFrame, layerY, Vector3.new(GRID_WIDTH * size.X, size.Y, GRID_DEPTH * size.Z), color, material)
            layer.Parent = pad
            self.FadeTransparency(layer, 0, 0.1)
            table.insert(render.MergedLayers, layer)

            for _, b in ipairs(render.Bills) do
                self.FadeTransparency(b, 1, 0.1)
                task.delay(0.2, function() if b then b:Destroy() end end)
            end
            table.clear(render.Bills)
        end
    end

    while totalCurrent > targetBillCount do
        if #render.Bills > 0 then
            local b = table.remove(render.Bills)
            self.FadeTransparency(b, 1, 0.1)
            task.delay(0.2, function() if b then b:Destroy() end end)
            totalCurrent -= 1
        elseif #render.MergedLayers > 0 then
            local layer = table.remove(render.MergedLayers)
            self.FadeTransparency(layer, 1, 0.1)
            task.delay(0.2, function() if layer then layer:Destroy() end end)
            totalCurrent -= BILLS_PER_LAYER
        end
    end
end

return self
