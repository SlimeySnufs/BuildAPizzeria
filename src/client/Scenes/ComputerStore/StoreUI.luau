local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ComputerStoreButtons = require(script.Parent.Parent.Parent.UserInterface.SceneUI.ComputerStoreButtons)

local Signal = require(ReplicatedStorage.Lib.Signal)
local Janitor = require(ReplicatedStorage.Packages.janitor)

export type Signal = typeof(Signal.new(...))
local StoreData: { [string]: any } = require(ReplicatedStorage.Shared.StoreData)

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
    @param amount number | string
    @within ComputerStore ShopUI
]=]
function self.UpdateCurrentBuyingAmountUI(amount : number | string)
    
    self.Laptop = workspace:WaitForChild("Laptop")
    
    local AmountPurchasing = self.Laptop:WaitForChild("ScreenPart"):FindFirstChild("AmountPurchasing")
    local SurfaceGui : SurfaceGui = AmountPurchasing.SurfaceGui
    local CurrentAmountLabel = SurfaceGui.Current

    print(self.CurrentItem,StoreData)

    CurrentAmountLabel.Text = `BUY: {amount}`
    ComputerStoreButtons.UpdateBuyButton(StoreData.Slots[tonumber(self.CurrentItem.Name or 1)])

end

--[=[
    @prop ListeningParts {[BasePart]: (any) -> ()}
    @within ComputerStore ShopUI
]=]

self.ListeningParts = {} :: {[BasePart]: (any) -> ()}

--[=[
    @function OpenMainUI
    @within ComputerStore Main
]=]

function self.OpenMainUI()

    self._janitor = Janitor.new()

    if not(self.Closed) then
        self.Closed = self._janitor:AddObject(Signal.new(),`Disconnect`)
    end

    if (self.ClosedListener) then
        self.ClosedListener:Disconnect()
        self.ClosedListener = nil
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
        ComputerStoreButtons.HideButtons()

    end)

    if not(self.Laptop) then
        self.Laptop = workspace.Laptop
    end

    self.CamPart = self.Laptop.Camera

    self.CloseAllOtherUI()
    self.CurrentBuyingAmount = 1 :: string | number
    self.CurrentItem = nil

    self.AmountPurchasingGui = self.Laptop.ScreenPart.AmountPurchasing.SurfaceGui
    self.ChoicesGui = self.Laptop.ScreenPart.Choices.SurfaceGui
    self.Laptop.ScreenPart.AmountPurchasing.CanQuery = true
    self.Laptop.ScreenPart.Choices.CanQuery = true

    self.AmountPurchasingGui.Enabled = true
    self.ChoicesGui.Enabled = true

    self.ChoicesGui.Exit.Activated:Once(function()
        self.Closed:Fire()
        self._janitor:Cleanup()
    end)

    self.StoreHolder = PlayerGui.MainGui.StoreHolder
    self.StoreHolder.Visible = true
    self.StoreViewport = self.StoreHolder.ViewportFrame
    self.WorldModel = self.StoreViewport:FindFirstChildOfClass("WorldModel")

    PlayerGui.MainGui.Bottom.Visible = false

    self.PurchaseChoices = {} :: {[number]: BasePart | Model}

    if not(self.PreviousStoreItems) then
        self.PreviousStoreItems = {} :: {[number]: BasePart | Model}
    end

    for i : number, part : BasePart in self.WorldModel:GetChildren() do
        if part:IsA("BasePart") then
            part.CFrame = CFrame.new(part.Position,self.CamPart.Position)
        end
        
        if (StoreData.Slots[i]) then
            self.PurchaseChoices[i] = part
            local item = StoreData.Slots[i]:Clone()
            self._janitor:Add(item,`Destroy`)
            item.Parent = self.WorldModel[tostring(i)]
            table.insert(self.PreviousStoreItems,item)
            item.CFrame = part.CFrame
        end

    end

    if not(self.CurrentItem) then
        self.CurrentItem = self.PurchaseChoices[1]
    end

    self._janitor:Add(ComputerStoreButtons.Events.ActionButtonClicked:Connect(function()
        print(self.CurrentItem)
    end), `Disconnect`)

    self._janitor:Add(ComputerStoreButtons.Events.NextButtonClicked:Connect(function()
        local currentIndex = table.find(self.PurchaseChoices, self.CurrentItem)
        if currentIndex and currentIndex < #self.PurchaseChoices then
            self.CurrentItem = self.PurchaseChoices[currentIndex + 1]
        else
            self.CurrentItem = self.PurchaseChoices[1]
        end
        self.UpdateCurrentBuyingAmountUI(self.CurrentBuyingAmount)
    end), `Disconnect`)

    self._janitor:Add(ComputerStoreButtons.Events.PreviousButtonClicked:Connect(function()
        local currentIndex = table.find(self.PurchaseChoices, self.CurrentItem)
        if currentIndex and currentIndex > 1 then
            self.CurrentItem = self.PurchaseChoices[currentIndex - 1]
        else
            self.CurrentItem = self.PurchaseChoices[#self.PurchaseChoices]
        end
        self.UpdateCurrentBuyingAmountUI(self.CurrentBuyingAmount)
    end), `Disconnect`)

    ComputerStoreButtons.ShowButtons()
    self.UpdateCurrentBuyingAmountUI(self.CurrentBuyingAmount)

    return self

end

return self