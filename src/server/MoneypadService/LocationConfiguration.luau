--!strict
local ServerScriptService = game:GetService("ServerScriptService")
--[=[
    @class LocationConfig
    Uses the moneypad class and creates all the money pads in locations
    Acts as a wrapper to add money on pads aswell
    @tag MoneypadService
]=]
local module = {}

local Server = ServerScriptService.Server

local Moneypad = require(script.Parent.Moneypad)

--[=[
    @function init
    Adds money pads in all locations
    @return LocationConfig
    @within LocationConfig
]=]
function module.init()

    --[=[
        @prop moneypadLocations {[string] : Part | CFrame}
        @within LocationConfig
    ]=]
    module.moneypadLocations = {
        ["Part1"] = workspace.Part1.CFrame
    } :: {[string] : CFrame}

    --[=[
        @prop MoneyPadCache {[string] : MoneyPad}
        @within LocationConfig
    ]=]
    module.MoneyPadCache = {} :: {[string] : Moneypad.MoneyPad}

    for id : string | number , pos : CFrame in pairs(module.moneypadLocations) do
        local newMoneyPAD: Moneypad.MoneyPad = Moneypad.new(id,pos)
        module.MoneyPadCache[id] = newMoneyPAD
    end

    return module

end

return module