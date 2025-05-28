--[=[
    @class Playtime
    @server
    A module for managing player playtime data.

    @tag DataManipulation
]=]
local Playtime = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local ProfileFetcher = require(script.Parent.GetProfile)

--[=[
    @function GetPlaytime
    Fetchs the players profile and returns the playtime in seconds unrounded.
    @within Playtime
    @param player Player
    @return Playtime: Number
]=]

function Playtime.GetPlaytime(player: Player) : number
    local profile: Types.Profile = ProfileFetcher.GetProfile(self, player)(player)
    if not profile then
        error("Player profile not found.")
    end

    local playtime: number = profile.Data.Playtime or 0
    return playtime
end

return Playtime