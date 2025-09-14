local module = {}

--[=[
    @class ComputerStoreButtons
    @tag Scenes
    @client
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local MainGui = PlayerGui:WaitForChild(`MainGui`)
local StoreHolder = MainGui:WaitForChild(`StoreHolder`)

local Signal = require(ReplicatedStorage.Lib.Signal)
local StoreData = require(ReplicatedStorage.Shared.StoreData)

export type Signal = typeof(Signal.new(...))

local Buttons : Frame = StoreHolder.Buttons

--[=[
    @prop Events {ActionButtonClicked: Signal, NextButtonClicked: Signal, PreviousButtonClicked: Signal}
    @within ComputerStoreButtons
]=]

module.Events = {
    ActionButtonClicked = Signal.new(),
    NextButtonClicked = Signal.new(),
    PreviousButtonClicked = Signal.new(),
} :: {
    ActionButtonClicked: Signal,
    NextButtonClicked: Signal,
    PreviousButtonClicked: Signal,
}

--[=[
    @function ShowButtons
    Shows the buttons in the store UI.
    @within ComputerStoreButtons
]=]
function module.ShowButtons()
    Buttons.Action.Parent.Visible = true
end

--[=[
    @function UpdateBuyButton
    Updates the buy button's state or appearance.
    @param item Instance
    @within ComputerStoreButtons
]=]
function module.UpdateBuyButton(item : Instance)
    -- Update the buy button's state or appearance here
    Buttons.Action.ActionText.Text = `buy {StoreData.Slots[tonumber(item.Name)].Name}`
    Buttons.Action.SubText.Text = "price: ?"
end

--[=[
    @function HideButtons
    Hides the buttons in the store UI.
    @within ComputerStoreButtons
]=]
function module.HideButtons()
    Buttons.Action.Parent.Visible = false
end

Buttons.Action.Activated:Connect(function()
    module.Events.ActionButtonClicked:Fire()
end)

Buttons.Next.Activated:Connect(function()
    module.Events.NextButtonClicked:Fire()
end)

Buttons.Previous.Activated:Connect(function()
    module.Events.PreviousButtonClicked:Fire()
end)

return module 