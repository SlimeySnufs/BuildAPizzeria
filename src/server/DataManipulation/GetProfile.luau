--[=[
    @class GetProfile
    @server
    @tag DataManipulation
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
    @return Profile
    
    @error "Invalid player provided or player not found in the game."

    @yields
    @tag DataManipulation
]=]
function module.GetProfile(player: Player) : Types.Profile
    if player and player:IsA("Player") and Players:FindFirstChild(player.Name) then
        return ProfileCache[player]
    else
        repeat 
            task.wait(0.1) -- Wait for a short time before retrying
        until ProfileCache[player] -- Retry until the player is found

        return ProfileCache[player]
    end
end

return module