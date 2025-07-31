--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local self: { [string]: any } = {}

self["Slots"] = {
    [1]  = ReplicatedStorage.StoreItems.Pork,
} :: {[number] : Instance}

return self