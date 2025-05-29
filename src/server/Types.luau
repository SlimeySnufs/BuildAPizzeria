local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService.Server
local Data = Server.Data

--[[SERVICES]]
local MoneypadService = require(Server.MoneypadService.Moneypad)

export type Profile = typeof(require(Data.ProfileStore):StartSessionAsync())
export type MoneyPad = MoneypadService.MoneyPad

return {}