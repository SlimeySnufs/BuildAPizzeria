--!strict

local module = {}

--[=[
    @class ButtonAnimations
    @tag UserInterface
    @client
]=]

local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local function ScaleUDim2(udim2: UDim2, scale: number): UDim2
    assert(type(scale) == "number", "Scale must be a number")
    assert(scale > 0, "Scale must be greater than 0")
    return UDim2.new(udim2.X.Scale * scale, udim2.X.Offset * scale, udim2.Y.Scale * scale, udim2.Y.Offset * scale)
end

local function BindConnections(button : TextButton | ImageButton)

    assert(button:IsA("TextButton") or button:IsA("ImageButton"), "BindConnections expects a TextButton or ImageButton")
    
    local OriginalSize: UDim2 = button.Size

    local TweenedInSize: UDim2 = ScaleUDim2(OriginalSize, 0.9)
    local TweenedOutSize: UDim2 = ScaleUDim2(OriginalSize, 1.1)

    local info: TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut,0,false)

    button.MouseEnter:Connect(function()
        TweenService:Create(button, info, {Size = TweenedOutSize}):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, info, {Size = OriginalSize}):Play()
    end)

    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, info, {Size = TweenedInSize}):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, info, {Size = OriginalSize}):Play()
    end)
    
end

--[=[
    @function Init
    Initializes the button animations for all buttons tagged with "UIButton"
    @within ButtonAnimations
]=]

function module.Init()
    -- Initialize button animations here
    for _, button: Instance in ipairs(CollectionService:GetTagged("UIButton")) do
        if not(button:IsA("TextButton") or button:IsA("ImageButton")) then
            warn(`UIButton tag is applied to a non-button instance: {button.Name}`)
            continue
        end
        BindConnections(button)
    end
end

return module