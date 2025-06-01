local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
--[=[
    @class LocationConfig ProductionPad 
    @tag ProductionPadService
    @server
]=]
local module = {}

local GetProfile = require(ServerScriptService.Server.DataManipulation.GetProfile)
local replica = require(ReplicatedStorage.Packages.replica)
local ProductionPad = require(script.Parent.ProductionPad)

--[=[
    @function init
    @within LocationConfig ProductionPad 
]=]
function module.init()
    
    --[=[
        @prop Locations {[string] : {EndLocation : BasePart, ProductionPart : BasePart}}
        @within LocationConfig ProductionPad
    ]=]
    module.Locations = {
        ["Pizza1"] = {
            EndLocation = workspace.Part2,
        }
    } :: {[string] : {any}}

    --[=[
        @prop ProductionPadCache {[string] : ProductionPad}
        @within LocationConfig ProductionPad
    ]=]
    module.ProductionPadCache = {} :: {
        [string] : ProductionPad.ProductionPad
    }

    for locationID : string | number , locationData  in module.Locations do

        local newProductionPad = ProductionPad.new(locationID,locationData.EndLocation.CFrame,locationData.ProductionPart)
        module.ProductionPadCache[locationID] = newProductionPad

        local playersInPad = {}

        newProductionPad.PlayerEntered:Connect(function(plr : Player)
            table.insert(playersInPad,plr)
        end)
        
        newProductionPad.PlayerExited:Connect(function(plr : Player)
            local index: number? = table.find(playersInPad,plr)
            if not(index) then
                return
            end
            table.remove(playersInPad,index)
        end)

        task.spawn(function()

            while task.wait(0.3) do
                for _ , plr in Players:GetPlayers() do
                    newProductionPad:Produce(plr, ReplicatedStorage.Assets.Pizza)
                end

                for _ , plr : Player in playersInPad do
                    newProductionPad:PickUp(plr)
                end

            end

        end)

    end

    task.wait()

    module.HandleProductionPadReplicas()

end

--[=[
    @function HandleProductionPadReplicas
    @within LocationConfig ProductionPad
]=]
function module.HandleProductionPadReplicas()
    
    local function onJoin(plr : Player)

        repeat
            task.wait()
            print(`waiting for plr`)
        until plr

        print(`constructing replica`)

        local _ = plr.Character or plr.CharacterAdded:Wait()

        print(`after load`)

        local profile = GetProfile.GetProfile(plr)
        local ProductionPadData = profile.Data["ProductionPads"]
        
        local plrToken = replica.Token(tostring(plr.UserId).."ProductionPad")

        local ProductionPadReplica = replica.New({
            Token = plrToken,
            Data = ProductionPadData
        })

        print(`after .new`)

        ProductionPadReplica:Subscribe(plr)
        ProductionPadReplica:Replicate()

        print(`replicated to plr`)
        print(module)

        for _ , productionPad : ProductionPad.ProductionPad in module.ProductionPadCache do
            print(`gave replica`)
            productionPad:GiveReplica(plr,ProductionPadReplica)
        end

    end

    local function onLeave(plr : Player)
        for _ , productionPad : ProductionPad.ProductionPad in module.ProductionPadCache do
            productionPad:RemoveReplica(plr)
        end
    end

    Players.PlayerAdded:Connect(onJoin)
    Players.PlayerRemoving:Connect(onLeave)

    for _ , plr: Player in Players:GetPlayers() do
        onJoin(player)
    end

    game:BindToClose(function()
        for _ , plr: Player in Players:GetPlayers() do 
            onLeave(player)
        end
    end)

end

return module