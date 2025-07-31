--[=[
    @class CancellableStateHandler
    @tag UserInterface
]=]
local self = {}

export type States =
    | "HoldingPizza"
    | "None"
    | "Farming"

local CancellableStates : {States} = {
    "HoldingPizza"
}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer.PlayerGui
local ActionLine= PlayerGui.MainGui.ActionLine

local replica = require(script.Parent.Parent.Parent.Data.ReplicaClient) 

local OriginalSize = ActionLine.CancelAction.Size

--[=[
    @function TweenButtonSizeBasedOnEnabled
    this is a priv function lowk but yeah, prob dont use it
    @param button TextButton | ImageButton
    @param enabled boolean
    @return Tween
    @within CancellableStateHandler
]=]
function self.TweenButtonSizeBasedOnEnabled(button: TextButton | ImageButton, enabled: boolean) : Tween
    local goalSize = enabled and OriginalSize or UDim2.new(0.0, 0, 0.0, 0)
    local tween = TweenService:Create(button, TweenInfo.new(0.2), {Size = goalSize})
    tween:Play()
    return tween
end

--[=[
    @function Init
    @within CancellableStateHandler
]=]
function self.Init()
    ActionLine.CancelAction.Visible = false
    ActionLine.CancelAction.Size = OriginalSize
    self.TweenButtonSizeBasedOnEnabled(ActionLine.CancelAction, false)

    replica.ListenForChange({`State`}, function(state : string)
        print(state,`is the new state of the player!`)
        if table.find(CancellableStates,state) then
            print(`is cancellable state:`, state)
            ActionLine.CancelAction.Visible = true
            self.TweenButtonSizeBasedOnEnabled(ActionLine.CancelAction, true)
        else
            print(`hiding`)
            local t = self.TweenButtonSizeBasedOnEnabled(ActionLine.CancelAction, false)
            t.Completed:Wait()
            ActionLine.CancelAction.Visible = false
        end
    end)
end

return self