--[=[
    @class GetProfile
    @server
    @tag DataManipulation
    A module for getting the players data profile
]=]
local module = {}
local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService.Server

local Types = require(ServerScriptService.Server.Types)

local Data = Server.Data
local ProfileCache = require(Data.ProfileCache)
local _Players = game:GetService("Players")

--[=[
    @function GetProfile
    @server
    @within GetProfile
    Returns the profile of the given player.
    If the player is not found or invalid, an error is raised.
    
    @param Player Player
    @return Profile

    @error NotFound -- "Couldn't find Profile after 15 seconds"

    @yields
    @tag DataManipulation
]=]
function module.GetProfile(player: Player) : Types.Profile

    local waitTime = 0

    if (ProfileCache[player]) then
        return ProfileCache[player]
    end

    repeat 
        task.wait(0.1)
        waitTime += 0.1
    until ProfileCache[player] or waitTime >= 15

    if not(ProfileCache[player]) then
        error("Couldnt find Profile after 15 seconds")
        return nil
    end

    return ProfileCache[player]
end

return module