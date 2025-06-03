local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
--[=[
    @class CustomerReplication Render
    @tag CustomerReplication
    @client
]=]
local self = {}

local Lib = ReplicatedStorage.Lib
local RandomNPC = require(Lib.RandomNPC)

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

--[=[
    @function Init
    @within CustomerReplication Render
]=]
function self.Init()

    self.CurrentCustomers = {}
    self.CustomerCount = 0

    self.LineStart = workspace:WaitForChild("LineStart")

    Players.PlayerAdded:Connect(function(player)
        local char = player.Character or player.CharacterAdded:Wait()
        for _ , basepart in char:GetDescendants() do
            if basepart:IsA("BasePart") then
                basepart.CollisionGroup = "Player"
            end
        end
    end)

    return self
end

--[=[
    @function PizzaOrderPopup
    @param id number
    @within CustomerReplication Render
]=]
function self.PizzaOrderPopup(id: number)

    local PhysicalNPC = nil
    local customerData= nil
    for _, customer in (self.CurrentCustomers) do
        if customer.Id == id then
            PhysicalNPC = customer.Model
            customerData = customer.CustomerData
            break
        end
    end
    
    local BillboardUi = PlayerGui.BillboardUI
    local PizzaPopup : BillboardGui = BillboardUi:WaitForChild("PizzaPopup"):Clone()
    PizzaPopup.Parent = BillboardUi
    PizzaPopup.Adornee = PhysicalNPC.Head
    PizzaPopup.Name = `customer_{id}_popup`
    PizzaPopup.Bubble.Amount.Text = `x{customerData.RequestAmount}`

end

--[=[
    @function AnimateCustomer

    @param PhysicalNPC Model
    @param animationType ("Idle" | "Walk" | "Sit")

    @within CustomerReplication Render
]=]
function self.AnimateCustomer(PhysicalNPC : Model, animationType: string) : {Stop: () -> (), IsPlaying: () -> boolean}
    
    local Humanoid : Humanoid = PhysicalNPC:FindFirstChildOfClass("Humanoid")
    local Animatior : Animator = Humanoid:FindFirstChild("Animator")

    local Anims : {[string] : string} = {
        Idle = "rbxassetid://180435571", -- Replace with actual animation ID
        Walk = "rbxassetid://180426354", -- Replace with actual animation ID
        Sit = "rbxassetid://178130996" -- Replace with actual animation ID
    }

    if not(Anims[animationType]) then
        warn("Invalid animation type: " .. animationType)
        return
    end

    local anim: Animation = Instance.new("Animation")
    anim.AnimationId = Anims[animationType]

    local loadedAnim: AnimationTrack = Animatior:LoadAnimation(anim)
    loadedAnim:Play()

    return {
        Stop = function()
            loadedAnim:Stop()
        end,

        IsPlaying = function()
            return loadedAnim.IsPlaying
        end
    }

end

--[=[
    @function SpecialCustomerHighlight
    @param id number
    @param highlightColor Color3
    @within CustomerReplication Render
]=]
function self.SpecialCustomerHighlight(id: number, highlightColor: Color3)

    local PhysicalNPC = nil
    for _, customer in (self.CurrentCustomers) do
        if customer.Id == id then
            PhysicalNPC = customer.Model
            break
        end
    end

    if not PhysicalNPC then
        warn(`Customer with ID {id} not found`)
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Adornee = PhysicalNPC
    highlight.FillColor = highlightColor
    highlight.FillTransparency = 0.5
    highlight.Parent = PhysicalNPC

end

--[=[
    @function NewCustomer

    @param id number
    @param customerData CustomerData

    @within CustomerReplication Render
]=]
function self.NewCustomer(id : string , customerData)

    local physicalNPC = RandomNPC.NewNPC()
    physicalNPC.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    physicalNPC.Humanoid.NameDisplayDistance = 0
    physicalNPC.Humanoid.HealthDisplayDistance = 0
    physicalNPC.Humanoid.MaxHealth = math.huge
    physicalNPC.Name = `Customer_{id}`
    physicalNPC:SetAttribute("CustomerID", id)
    
    table.insert(self.CurrentCustomers, {
        Id = id,
        CustomerData = customerData,
        Model = physicalNPC,
        Position = self.LineStart.Position + Vector3.new(0, 0, (self.CustomerCount +1) * 3)
    })

    self.CustomerCount += 1

    if (customerData.customerType == "Gold") then
        self.SpecialCustomerHighlight(id, Color3.fromRGB(233, 194, 23))
    end

    for _ , child in physicalNPC:GetDescendants() do
        if child:IsA("BasePart") then
            child.CollisionGroup = "Customer"
        end
    end

    --[[INITIAL POSITION]]
    physicalNPC.Parent = workspace
    physicalNPC:SetPrimaryPartCFrame(CFrame.new(self.LineStart.Position + Vector3.new(-(id * 3) - 9, 2.25, 0)))

    self.PizzaOrderPopup(id)

    local anim = self.AnimateCustomer(physicalNPC, "Walk")

    local Humanoid = physicalNPC:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        Humanoid:MoveTo(self.LineStart.Position + Vector3.new(-(id * 3) + 8, 0, 0))
        Humanoid.MoveToFinished:Once(function(reached: boolean)
            anim:Stop()
            self.AnimateCustomer(physicalNPC, "Idle")
        end)
    end

end

--[=[
    @function LeaveCustomer
    @param id number
    @within CustomerReplication Render
]=]
function self.LeaveCustomer(id)



end

--[=[
    @function RemovedCustomer

    @within CustomerReplication Render

    @param id number
]=]
function self.RemovedCustomer(id)

    for i, customer in ipairs(self.CurrentCustomers) do
        if customer.Id == id then
            table.remove(self.CurrentCustomers, i)
            break
        end
    end
    
end

return self
