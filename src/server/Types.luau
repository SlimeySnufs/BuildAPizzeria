local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService.Server
local Data = Server.Data

export type Profile = typeof(require(Data.ProfileStore):StartSessionAsync())

return {}