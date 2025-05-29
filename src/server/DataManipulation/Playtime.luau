--!strict

--[=[
    @class Playtime
    @server
    A module for managing player playtime data.

    @tag DataManipulation
]=]

--[=[
    @prop PlayersAttached {Player}
    A list of players whose playtime is being updated.
    @within Playtime
]=]

--[=[
    @prop Heartbeat RBXScriptSignal
    The heartbeat connection that updates player playtime.
    @within Playtime
]=]

local Playtime = {
    Heartbeat = nil,
    PlayersAttached = {}
}

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local ProfileFetcher = require(script.Parent.GetProfile)

--[=[
    @function GetPlaytime
    Fetchs the players profile and returns the playtime in seconds unrounded.
    @within Playtime
    @error NotFound -- Player profile not found.
    @param player Player
    @return Playtime: Number
]=]

function Playtime.GetPlaytime(player: Player) : number
    local profile: Types.Profile = ProfileFetcher.GetProfile(player)
    if not profile then
        error("Player profile not found.")
    end

    local playtime: number = profile.Data.Playtime or 0
    return playtime
end

--[=[
    @function SetPlaytime
    Sets the playtime of the player to the given value.
    @within Playtime
    
    @param player Player
    @param playtime Number

    @error NotFound -- Player profile not found.
    @error TypeError -- Playtime must be a number.
]=]
function Playtime.SetPlaytime(player: Player, playtime: number)
    local profile: Types.Profile = ProfileFetcher.GetProfile(player)
    if not profile then
        error("Player profile not found.")
    end

    if type(playtime) ~= "number" then
        error("Playtime must be a number.")
    end

    profile.Data.Playtime = playtime
end

--[=[
    @function AddPlaytime
    Adds the given amount of playtime to the player's profile.
    @within Playtime
    @param player Player
    @param playtime Number
    @error NotFound -- Player profile not found.
    @error TypeError -- Playtime must be a number.
]=]
function Playtime.AddPlaytime(player: Player, playtime: number)
    local profile: Types.Profile = ProfileFetcher.GetProfile(player)
    if not profile then
        error("Player profile not found.")
    end

    if type(playtime) ~= "number" then
        error("Playtime must be a number.")
    end

    profile.Data.Playtime = (profile.Data.Playtime or 0) + playtime
end

--[=[
    @function AttachPlayerToPlaytimeLoop
    Adds the player to one heartbeat where all players playtime is updated.
    @within Playtime
    @param player Player
    @error NotFound -- Player profile not found.
]=]
function Playtime.AttachPlayerToPlaytimeLoop(player : Player)
    local profile: Types.Profile = ProfileFetcher.GetProfile(player)
    if not profile then
        error("Player profile not found.")
    end
    table.insert(Playtime.PlayersAttached, player)
end

--[=[
    @function DetachPlayerFromPlaytimeLoop
    Removes the player from the heartbeat loop.
    @within Playtime
    @param player Player
    @error NotFound -- Player not found in the attached players list.
]=]
function Playtime.DetachPlayerFromPlaytimeLoop(player : Player)
    for i, attachedPlayer in ipairs(Playtime.PlayersAttached) do
        if attachedPlayer == player then
            table.remove(Playtime.PlayersAttached, i)
            return nil
        end
    end
    error("Player not found in the attached players list.")
end

--[=[
    @function InitHeartbeatLoop
    Initializes the heartbeat loop that updates player playtime.
    This should be called once when the server starts.
    @within Playtime
    @error CallOnce -- This function should only be called once.
]=]
function Playtime.InitHeartbeatLoop()
    
    if Playtime.Heartbeat then
        error("This function should only be called once.")
    end

    Playtime.Heartbeat = RunService.Heartbeat:Connect(function(deltaTime: number)
        for _ , player : Player in ipairs(Playtime.PlayersAttached) do
            Playtime.AddPlaytime(player, deltaTime)
        end
    end)

end

Playtime.InitHeartbeatLoop()

return Playtime