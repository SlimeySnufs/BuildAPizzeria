--[[COMMAND BAR]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local conch = require(ReplicatedStorage.Packages.conch)
local ui = require(ReplicatedStorage.Packages.conch_ui)

conch.initiate_default_lifecycle()
ui.bind_to(Enum.KeyCode.F4)

return {}