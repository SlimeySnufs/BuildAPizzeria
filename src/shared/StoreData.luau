local ReplicatedStorage = game:GetService("ReplicatedStorage")
local self = {}
self["Slots"] = {
    [1]  = ReplicatedStorage.StoreItems.Pork
} :: {[number] : Instance}

return self