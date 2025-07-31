local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Server: Script = ServerScriptService.Server
local Data: Folder = Server.Data
local Packages: Folder = ReplicatedStorage.Packages

--[[SERVICES]]
local Replica = require(Packages.replica)

export type Profile = typeof(require(Data.ProfileStore):StartSessionAsync())
export type Replica = typeof(Replica.New(...))

return {}