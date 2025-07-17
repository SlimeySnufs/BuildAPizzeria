local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Signal = require(ReplicatedStorage.Lib.Signal)
local StoreData = require(ReplicatedStorage.Shared.StoreData)
--[=[
    @class ComputerStore ShopUI
    @client
    @tag Scenes
]=]
local self = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

--[=[
    @function CloseAllOtherUI
    @within ComputerStore ShopUI
]=]
function self.CloseAllOtherUI()
    
    self.Laptop = workspace:WaitForChild("Laptop")

    local TapToView = self.Laptop:WaitForChild("ScreenPart").TapToView
    TapToView.SurfaceGui.Enabled = false
    TapToView.CanQuery = false

end

--[=[
    @function SwapPositions
    @param p1 BasePart
    @param p2 BasePart
    @within ComputerStore ShopUI
]=]
function self.SwapPositions(p1 : BasePart,p2 : BasePart)
    local temp: Vector3 = p2.Position
    p2.Position = p1.Position
    p1.Position = temp
end

--[=[
    @function UpdateCurrentBuyingAmountUI
    @param amount number
    @within ComputerStore ShopUI
]=]
function self.UpdateCurrentBuyingAmountUI(amount : number | string)
    
    self.Laptop = workspace:WaitForChild("Laptop")
    
    local AmountPurchasing = self.Laptop:WaitForChild("ScreenPart"):FindFirstChild("AmountPurchasing")
    local SurfaceGui : SurfaceGui = AmountPurchasing.SurfaceGui
    local CurrentAmountLabel = SurfaceGui.Current

    CurrentAmountLabel.Text = `BUY: {amount}`

end

--[[
    @property ListeningParts {[BasePart]: (any) -> ()}
    @within ComputerStore ShopUI
]]
self.ListeningParts = {} :: {[BasePart]: (any) -> ()}

--[[
    @function ListenForMouseClick
    @param part BasePart
    @within ComputerStore ShopUI
]]
function self.ListenForMouseClick(part : BasePart)
    if self.ListeningParts[part] then
        self.ListeningParts[part] = nil
    end
    
    self.ListeningParts[part] = function()
        local Viewport: ViewportFrame = self.StoreViewport
        local Camera : Camera = Viewport.CurrentCamera
        
        -- Check if camera exists
        if not Camera then
            warn("No camera found in viewport")
            return
        end
        
        local absPos = Viewport.AbsolutePosition
        local absSize = Viewport.AbsoluteSize
        local mousePos = UserInputService:GetMouseLocation()
        
        -- Calculate mouse position relative to viewport
        local localX = mousePos.X - absPos.X
        local localY = mousePos.Y - absPos.Y
        
        -- Check if mouse is within viewport bounds
        if localX < 0 or localX > absSize.X or localY < 0 or localY > absSize.Y then
            return -- Mouse is outside viewport
        end
        
        print(`Mouse in viewport: ({localX}, {localY}) in viewport size ({absSize.X}, {absSize.Y})`)
        
        -- Get the ray from the viewport camera through the mouse position
        local ray = Camera:ViewportPointToRay(localX, localY)
        
        print(`Ray origin: {ray.Origin}, direction: {ray.Direction}`)
        
        -- Create raycast params - we want to check ALL parts in the viewport, not filter to viewport itself
        local raycastParams = RaycastParams.new()
        -- Get all descendants of the viewport that are BaseParts
        local viewportParts = {}
        for _, descendant in pairs(Viewport:GetDescendants()) do
            if descendant:IsA("BasePart") and descendant.Transparency < 1 then
                table.insert(viewportParts, descendant)
                print(`Found part in viewport: {descendant.Name} at {descendant.Position}`)
            end
        end
        
        if #viewportParts == 0 then
            print("No visible parts found in viewport for raycasting")
            return -- No parts to raycast against
        end
        
        print(`Raycasting against {#viewportParts} parts`)
        
        raycastParams.FilterDescendantsInstances = viewportParts
        raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
        
        -- For ViewportFrames, we need to raycast in the viewport's coordinate space
        -- The ray from ViewportPointToRay is already in the correct coordinate space
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
        
        if result then
            print(`Raycast hit: {result.Instance.Name} at {result.Position}`)
            if result.Instance == part then
                print(`Hit target part: {part.Name}`)
                -- Handle the click on this part
                if self.CurrentItem ~= part then
                    self.CurrentItem = part
                    -- Get the index for this part
                    local itemIndex = self.PartToIndex and self.PartToIndex[part]
                    if itemIndex then
                        print(`Selected item at index {itemIndex}: {part.Name}`)
                        -- You can add additional logic here for item selection
                    else
                        print(`Selected item: {part.Name}`)
                    end
                end
            else
                print(`Hit wrong part: {result.Instance.Name} (expected {part.Name})`)
            end
        else
            print("Raycast missed all parts")
        end
    end
end

UserInputService.InputBegan:Connect(function(input: InputObject,gameProcessed: boolean)
    if (Enum.UserInputType.MouseButton1 ~= input.UserInputType) then return end 
    if (gameProcessed) then return end

    for part: BasePart,func: (any) -> () in self.ListeningParts do
        func()
    end

end)

--[=[
    @function RegisterPurchaseChoice
    @param index number
    @param part BasePart
    @within ComputerStore ShopUI
]=]
function self.RegisterPurchaseChoice(index : number, part : BasePart)

    --[[
        part is in viewport, detect hit through raycasting from viewport camera to part
    ]]

    print(`Registering purchase choice for index {index}: {part.Name}`)

    -- Store the index with the part for later reference
    if not self.PartToIndex then
        self.PartToIndex = {}
    end
    self.PartToIndex[part] = index

    do
        self.ListenForMouseClick(part)
    end

end

--[=[
    @function OpenMainUI
    @within ComputerStore ShopUI
]=]
function self.OpenMainUI()

    if not(self.Closed) then
        self.Closed = Signal.new()
    end

    if (self.ClosedListener) then
        self.ClosedListener:Disconnect()
    end

    self.ClosedListener = self.Closed:Connect(function()

        if (self.BuyingConn) then
            self.BuyingConn:Disconnect()
        end
        if (self.AmountPurchasingGui) then
            self.AmountPurchasingGui.Enabled = false
            self.ChoicesGui.Enabled = false
        end

        self.Laptop.ScreenPart.AmountPurchasing.CanQuery = false
        self.Laptop.ScreenPart.Choices.CanQuery = false
        if (self.StoreHolder) then
            self.StoreHolder.Visible = false
        end
        PlayerGui.MainGui.Bottom.Visible = true

    end)

    if not(self.Laptop) then
        self.Laptop = workspace.Laptop
    end

    self.CamPart = self.Laptop.Camera

    self.CloseAllOtherUI()
    self.CurrentBuyingAmount = 1 :: string | number
    self.CurrentItem = nil

    self.UpdateCurrentBuyingAmountUI(self.CurrentBuyingAmount)

    self.AmountPurchasingGui = self.Laptop.ScreenPart.AmountPurchasing.SurfaceGui
    self.ChoicesGui = self.Laptop.ScreenPart.Choices.SurfaceGui
    self.Laptop.ScreenPart.AmountPurchasing.CanQuery = true
    self.Laptop.ScreenPart.Choices.CanQuery = true

    self.AmountPurchasingGui.Enabled = true
    self.ChoicesGui.Enabled = true

    self.ChoicesGui.Exit.Activated:Once(function()
        self.Closed:Fire()
    end)

    self["BuyingConn"] = self.ChoicesGui.Buy.Activated:Connect(function()
        if not(self.CurrentItem) then return end
        local CurrentItem = self.CurrentItem
    end)

    self.StoreHolder = PlayerGui.MainGui.StoreHolder
    self.StoreHolder.Visible = true
    self.StoreViewport = self.StoreHolder.ViewportFrame

    PlayerGui.MainGui.Bottom.Visible = false

    self.PurchaseChoices = {}

    if not(self.PreviousStoreItems) then
        self.PreviousStoreItems = {}
    end

    if (self.PreviousStoreItems) then
        for i , child : BasePart in self.PreviousStoreItems do
            child:Destroy()
            self.PreviousStoreItems[i] = nil
        end
    end

    for i , part in self.StoreViewport:GetChildren() do
        if part:IsA("BasePart") then
            part.CFrame = CFrame.new(part.Position,self.CamPart.Position)
        end
        
        if (StoreData.Slots[i]) then
            self.PurchaseChoices[i] = part
            local item = StoreData.Slots[i]:Clone()
            item.Parent = self.StoreViewport
            table.insert(self.PreviousStoreItems,item)
            item.CFrame = part.CFrame
            -- Register the cloned item for raycasting, not the placeholder part
            self.RegisterPurchaseChoice(i, item)
            -- Hide the placeholder part since we're using the cloned item
            part.Transparency = 1
            part.CanCollide = false
        end

    end

    return self

end

return self