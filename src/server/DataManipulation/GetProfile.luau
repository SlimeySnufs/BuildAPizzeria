--[=[
    @class GetProfile
    @server
    A module for manipulating player data profiles.
]=]
local module = {}
local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService.Server

local Types = require(ServerScriptService.Server.Types)

local Data = Server.Data
local ProfileCache = require(Data.ProfileCache)
local Players = game:GetService("Players")

--[=[
    @function GetProfile
    @server
    @within GetProfile
    Returns the profile of the given player.
    If the player is not found or invalid, an error is raised.
    
    @param Player Player
    @return Profile?
    
    @error "Invalid player provided or player not found in the game."

    @tag DataManipulation
]=]
function module.GetProfile(player: Player) : Types.Profile?
    if player and player:IsA("Player") and Players:FindFirstChild(player.Name) then
        return ProfileCache[player]
    else
        error("Invalid player provided or player not found in the game.")
    end
end

return module.new()