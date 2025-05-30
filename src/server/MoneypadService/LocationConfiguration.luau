local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
--[=[
    @class LocationConfig
    Uses the moneypad class and creates all the money pads in locations
    Acts as a wrapper to add money on pads aswell
    @tag MoneypadService
]=]
local module = {}

local GetReplica = require(ServerScriptService.Server.DataManipulation.GetReplica)
local replica = require(ReplicatedStorage.Packages.replica)
local Moneypad = require(script.Parent.Moneypad)

--[=[
    @function init
    Adds money pads in all locations
    @return LocationConfig
    @within LocationConfig
]=]
function module.init()

    print(`Locations Config started`)

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
        
        task.spawn(function()
            while task.wait(1) do
                for _ , plr: Player in Players:GetPlayers() do
                    newMoneyPAD:SubMoneyOnPad(plr, 5)
                end
            end
        end)

    end

    task.wait()

    module.HandleMoneyPadReplicas()

    return module

end

--[=[
    @function UpdateMoneyPadWithReplica
    Gives every class the new player joined's replica for moneypads
    
    @param Player Player
    @param Moneypad Replica Replica

    @within LocationConfig
]=]
function module.UpdateMoneyPadWithReplica(player : Player, MoneypadReplica)
    for id , moneypad in module.MoneyPadCache do
        moneypad:GiveReplica(player,MoneypadReplica)
    end
end

--[=[
    @function RemoveReplicaFromMoneyPad
    Removes the replica of a specifc player from all moneypads
    
    @param Player Player

    @within LocationConfig
]=]
function module.RemoveReplicaFromMoneyPad(player : Player)
    for id , moneypad in module.MoneyPadCache do
        moneypad:RemoveReplica(player)
    end
end

--[=[
    @function HandleMoneyPadReplicas
    Handles each players replica that stores the money pads
    @within LocationConfig
]=]
function module.HandleMoneyPadReplicas()

    --[=[
        @prop MoneyPadReplicas {[player] : MoneyPadReplica}
        @within LocationConfig
    ]=]
    module.MoneyPadReplicas = {}

    local function onJoin(player : Player)
        local c = player.Character or player.CharacterAdded:Wait()
        print(`Moneypad replica being made for {player.Name}`)
        local Profile = GetReplica.GetReplica(player)

        for moneypadid , data in Profile.Data.MoneyPads do
            if not(module.moneypadLocations[moneypadid]) then
                Profile.Data.MoneyPads[moneypadid] = nil
            end
        end

        local PlrToken = replica.Token(tostring(player.UserId).."MoneyPads")

        local PlayerMoneypadReplica = replica.New({
            Token = PlrToken,
            Data = Profile.Data.MoneyPads
        })

        PlayerMoneypadReplica:Subscribe(player)
        PlayerMoneypadReplica:Replicate()

        module.MoneyPadReplicas[player] = PlayerMoneypadReplica

        module.UpdateMoneyPadWithReplica(player,PlayerMoneypadReplica)
    end

    local function onLeave(player : Player)
        if module.MoneyPadReplicas[player] then
            module.MoneyPadReplicas[player] = nil
        end
        module.RemoveReplicaFromMoneyPad(player)
    end

    Players.PlayerAdded:Connect(function(player : Player)
        onJoin(player)
    end)

    Players.PlayerRemoving:Connect(function(player : Player)
        onLeave(player)
    end)

    for _ , plr in Players:GetPlayers() do
        onJoin(plr)
    end

    game:BindToClose(function()
        for _ , plr in Players:GetPlayers() do
            onLeave(plr)
        end
    end)

end


return module