local StarterGui = game:GetService("StarterGui")
--[=[
    @class Hider
    Hides the backpack and other coregui
    @tag UserInterface
]=]
local self = {}

--[=[
    @function Init
    @within Hider
]=]
function self.Init()
    
    local s : boolean, result

    repeat
        s , result = pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Captures, false)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.SelfView, false)
        end)
        print(not s and result or s)
    until s

end

return self