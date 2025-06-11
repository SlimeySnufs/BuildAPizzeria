local ServerScriptService = game:GetService("ServerScriptService")

local GetProfile = require(ServerScriptService.Server.DataManipulation.GetProfile)
local GetReplica = require(ServerScriptService.Server.DataManipulation.GetReplica)
local Types = require(ServerScriptService.Server.Types)
--[=[
    @class Resource
    @server
    data manipluation abstraction module for resources n stuff
    @tag DataManipulation
]=]
local self = {}

--[=[
    @function IncrementWheat
    @param player Player
    @param delta number
    @within Resource
]=]
function self.IncrementWheat(player : Player, delta : number)
    
    local profile: Types.Profile = GetProfile.GetProfile(player)
    if not profile then
        error("Player profile not found.")
    end

    local currentWheat : number = profile.Data.Resources["Wheat"]

    profile.Data["Resources"]["Wheat"] = currentWheat + delta
    GetReplica.GetReplica(player):Set({"Resources","Wheat"}, profile.Data["Resources"]["Wheat"])

end

--[=[
    @function IncrementTomato
    @param player Player
    @param delta number
    @within Resource
]=]
function self.IncrementTomato(player : Player, delta : number)
    
    local profile: Types.Profile = GetProfile.GetProfile(player)
    if not profile then
        error("Player profile not found.")
    end

    local currentTomato : number = profile.Data.Resources["Tomato"]

    profile.Data["Resources"]["Tomato"] = currentTomato + delta
    GetReplica.GetReplica(player):Set({"Resources","Tomato"}, profile.Data["Resources"]["Tomato"])

end

--[=[
    @function IncrementPork
    @param player Player
    @param delta number
    @within Resource
]=]
function self.IncrementPork(player : Player, delta : number)
    
    local profile: Types.Profile = GetProfile.GetProfile(player)
    if not profile then
        error("Player profile not found.")
    end

    local currentPork : number = profile.Data.Resources["Pork"]

    profile.Data["Resources"]["Pork"] = currentPork + delta
    GetReplica.GetReplica(player):Set({"Resources","Pork"}, profile.Data["Resources"]["Pork"])

end

return self