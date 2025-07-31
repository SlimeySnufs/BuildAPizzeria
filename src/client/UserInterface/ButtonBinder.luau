--[=[
    @class ButtonBinder
    @tag UserInterface
]=]
local self = {}
local cooldown_buttons : {[string] : number?} = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPLayer = Players.LocalPlayer
local PlayerGui = LocalPLayer.PlayerGui

local MainGui = PlayerGui.MainGui

function self.BindButtonToCallback(button: TextButton | ImageButton, callback: () -> (), cooldown : number?)
    assert(button:IsA("TextButton") or button:IsA("ImageButton"), "BindButtonToCallback expects a TextButton or ImageButton")
    assert(type(callback) == "function", "BindButtonToCallback expects a function as the second argument")
    
    if cooldown_buttons[button.Name] then
        local remaining_cooldown = cooldown_buttons[button.Name] - tick()
        if remaining_cooldown > 0 then
            return
        end
    end

    button.MouseButton1Click:Connect(callback)

    if cooldown then
        cooldown_buttons[button.Name] = tick() + cooldown
    end
end

local Blink = require(ReplicatedStorage.Packets.roblox_events.path.to.client)

self.BindButtonToCallback(MainGui.ActionLine.CancelAction, function()
    Blink.CancelState.Fire(`Cancel`)
end, 0.5)

return self