local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
--[=[
    @class LocationConfig MoneyPad
    Uses the moneypad class and creates all the money pads in locations
    Acts as a wrapper to add money on pads aswell
    @tag MoneypadService
]=]
local module = {}

local GetProfile = require(ServerScriptService.Server.DataManipulation.GetProfile)
local GetReplica = require(ServerScriptService.Server.DataManipulation.GetReplica)
local replica = require(ReplicatedStorage.Packages.replica)
local Moneypad = require(script.Parent.Moneypad)

local DataManipulation = ServerScriptService.Server.DataManipulation
local Currency = require(DataManipulation.Currency)

--[=[
    @function init
    Adds money pads in all locations
    @return LocationConfig
    @within LocationConfig MoneyPad
]=]
function module.init()

    print(`Locations Config started`)

    --[=[
        @prop moneypadLocations {[string] : Part | CFrame}
        @within LocationConfig MoneyPad
    ]=]
    module.moneypadLocations = {
        ["Part1"] = workspace.Part1.CFrame
    } :: {[string] : CFrame}

    --[=[
        @prop MoneyPadCache {[string] : MoneyPad}
        @within LocationConfig MoneyPad
    ]=]
    module.MoneyPadCache = {} :: {[string] : Moneypad.MoneyPad}

    for id : string | number , pos : CFrame in pairs(module.moneypadLocations) do
        local newMoneyPAD: Moneypad.MoneyPad = Moneypad.new(id,pos)
        module.MoneyPadCache[id] = newMoneyPAD

        local PlayersInPad = {}

        newMoneyPAD.PlayerEntered:Connect(function(player : Player)
            table.insert(PlayersInPad,player)
        end)

        newMoneyPAD.PlayerExited:Connect(function(player : Player)
            local playerInTableIndex : number? = table.find(PlayersInPad, player)
            if not(playerInTableIndex) then 
                print(`not in table`)
                return
            end
            table.remove(PlayersInPad,playerInTableIndex)
        end)
        
        local SUB_RATE = 5

        task.spawn(function()
            while task.wait(0.25) do
                for _ , plr in Players:GetPlayers() do
                    if not plr then continue end
                    newMoneyPAD:AddMoneyOnPad(plr, 3)
                end

                for _ , player in PlayersInPad do
                    if not player then continue end
                    local amountOfMoneyInPad: number? = newMoneyPAD:GetMoneyOnPad(player)
                    if amountOfMoneyInPad <= 0 then
                        warn(`Nothing in pad`)
                        continue
                    end
                    if amountOfMoneyInPad < SUB_RATE then
                        newMoneyPAD:SubMoneyOnPad(player,amountOfMoneyInPad)
                        Currency.ChangeCurrency(player, "Cash", amountOfMoneyInPad)
                        continue
                    end
                    newMoneyPAD:SubMoneyOnPad(player,SUB_RATE)
                    Currency.ChangeCurrency(player, "Cash", SUB_RATE)
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

    @within LocationConfig MoneyPad
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

    @within LocationConfig MoneyPad
]=]
function module.RemoveReplicaFromMoneyPad(player : Player)
    for id , moneypad in module.MoneyPadCache do
        moneypad:RemoveReplica(player)
    end
end

--[=[
    @function HandleMoneyPadReplicas
    Handles each players replica that stores the money pads
    @within LocationConfig MoneyPad
]=]
function module.HandleMoneyPadReplicas()

    --[=[
        @prop MoneyPadReplicas {[player] : MoneyPadReplica}
        @within LocationConfig MoneyPad
    ]=]
    module.MoneyPadReplicas = {}

    local function onJoin(player : Player)
        local _ = player.Character or player.CharacterAdded:Wait()
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
    
        local profile = GetProfile.GetProfile(player)

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