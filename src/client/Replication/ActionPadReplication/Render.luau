local RunService = game:GetService("RunService")
--[=[
    @class ActionPadReplication Render
    @client
    @tag ActionPadReplication
]=]
local self = {}

--[=[
    @function Init
    @within ActionPadReplication Render
]=]
function self.Init()

    self.SpinningParts = {} :: { [string]: BasePart }

    self.SpinHeartBeat = RunService.Heartbeat:Connect(function(dt: number)
        for _ , spinpart : BasePart in pairs(self.SpinningParts) do
            spinpart.CFrame = spinpart.CFrame * CFrame.Angles(0, (dt * 2), 0) -- Spin the part
        end
    end)

    return self
end

local ActionPads = workspace.ActionPads

--[=[
    @function UpdateRender
    @within ActionPadReplication Render
    @param padID string
    @param isActive boolean
]=]
function self.UpdateRender(padID : string, isActive : boolean)
    
    local ActionPad = self.GetActionPad(padID)
    local Decal : Decal = ActionPad.Decal

    if (isActive) then
        Decal.Color3 = Color3.fromRGB(12, 255, 105) -- Active color
        return
    end

    Decal.Color3 = Color3.fromRGB(255, 255, 255) -- Inactive color

end

--[=[
    @function AddToSpinHeartBeat
    @param padID string
    @within ActionPadReplication Render
]=]
function self.AddToSpinHeartBeat(padID : string)
    
    local ActionPad = self.GetActionPad(padID)
    if not ActionPad then return end

    self.SpinningParts[padID] = ActionPad

end

--[=[
    @function GetActionPad
    @within ActionPadReplication Render
    @param padID string
    @return Instance?
]=]
function self.GetActionPad(padID : string) : Instance?
    return ActionPads:FindFirstChild(padID)
end

return self