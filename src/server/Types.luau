local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService.Server
local Data = Server.Data

local Packages = ReplicatedStorage.Packages

--[[SERVICES]]
local Replica = require(Packages.replica)
local MoneypadService = require(Server.MoneypadService.Moneypad)

export type Profile = typeof(require(Data.ProfileStore):StartSessionAsync())
export type MoneyPad = MoneypadService.MoneyPad
export type Replica = typeof(Replica.New(...))

return {}