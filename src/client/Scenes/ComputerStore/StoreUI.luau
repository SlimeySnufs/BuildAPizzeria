--[=[
    @class ComputerStore ShopUI
    @client
    @tag Scenes
]=]
local self = {}

--[=[
    @function CloseAllOtherUI
    @within ComputerStore ShopUI
]=]
function self.CloseAllOtherUI()
    
    self.Laptop = workspace:WaitForChild("Laptop")

    local TapToView = self.Laptop:WaitForChild("ScreenPart").TapToView
    TapToView.SurfaceGui.Enabled = false

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

--[=[
    @function OpenMainUI
    @within ComputerStore ShopUI
]=]
function self.OpenMainUI()

    self.CloseAllOtherUI()
    self.CurrentBuyingAmount = 1 :: string | number

    self.UpdateCurrentBuyingAmountUI(self.CurrentBuyingAmount)

    self.Laptop.ScreenPart.Choices.SurfaceGui.Enabled = true
    self.Laptop.ScreenPart.AmountPurchasing.SurfaceGui.Enabled = true

end

return self