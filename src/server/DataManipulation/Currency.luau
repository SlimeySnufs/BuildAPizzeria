--!strict

--[=[
    @class Currency
    @server
    A module for managing player currency data.

    @tag DataManipulation
]=]
local self = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local ProfileFetcher = require(script.Parent.GetProfile)
local ReplicaFetcher = require(script.Parent.GetReplica)

--[=[
    @function GetCurrency
    @param player Player
    @param currencyName string

    @return number?

    @error NoProfile -- Couldnt get the profile for the player
    @error InvalidCurrency -- A currency that doesnt exist in the player's data was indexed

    @within Currency
]=]
function self.GetCurrency(player : Player, currencyName : string) : number?
    
    local profile= ProfileFetcher.GetProfile(player) 
    if not(profile) then
        warn(`Couldn't fetch profile?`)
        return nil
    end

    local currentAmount : number | boolean = profile.Data[currencyName] or false

    if not(currentAmount) then
        warn(`Invalid Currency Name indexed? {currencyName}`)
        return nil
    end

    return currentAmount :: number

end

--[=[
    @function ChangeCurrency
    This is a change method that can sub or add, it uses a 3rd arg that acts as a delta that can be negative

    @param player Player
    @param currenyName string
    @param delta number

    @error NoProfile -- Couldnt get the profile for the player
    @error InvalidCurrency -- A currency that doesnt exist in the player's data was indexed
    @error NoReplica -- Couldnt get the replica for the player

    @within Currency
]=]
function self.ChangeCurrency(player : Player, currencyName : string, delta : number)
    
    local profile= ProfileFetcher.GetProfile(player) 
    if not(profile) then
        warn(`Couldn't fetch profile?`)
        return
    end

    local Replica = ReplicaFetcher.GetReplica(player)
    if not(Replica) then
        warn(`Couldn't fetch replica?`)
        return
    end

    local currentAmount : number | boolean = profile.Data[currencyName] or false

    if not(currentAmount) then
        warn(`Invalid Currency Name indexed? {currencyName}`)
        return
    end

    profile.Data[currencyName] = currentAmount :: number + delta
    Replica:Set({currencyName},profile.Data[currencyName])

end

return self