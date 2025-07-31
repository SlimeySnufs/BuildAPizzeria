local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local replica = require(ReplicatedStorage.Packages.replica)
local ActionPad = require(script.Parent.ActionPad)
--[=[
    @class ActionPad LocationConfiguration
    @tag ActionPadService
    @server
]=]
local self = {}

local function GetDictionaryLength(dict : {any}) : number
    local count = 0
    for _ in pairs(dict) do
        count += 1
    end
    return count
end

--[=[
    @function Init
    Initializes the ActionPadService, setting up necessary configurations and connections.
    @within ActionPad LocationConfiguration
]=]
function self.Init()

    local PickUpSystem = require(ServerScriptService.Server.InteractiveHandlers.PickupSystem.Main)
    local NPCGeneration = require(ServerScriptService.Server.InteractiveHandlers.OrderHandling.NPCGeneration)
    local Moneypad = require(ServerScriptService.Server.Services.MoneypadService.Moneypad)
    local MoneypadCache : {[string] : Moneypad.MoneyPad} = require(ServerScriptService.Server.Services.MoneypadService.MoneypadCache)
    
    self.ReplicaCache = {} :: { [Player] : typeof(replica.New())}

    self.Locations = {
        ["Part3"] = workspace.Part3
    } :: { [string] : BasePart }

    self.FunctionBinds = {
        ["Part3"] = function(player : Player)

            local NextCustomerInfo = NPCGeneration.GetNextCustomer(player)

            if not(NextCustomerInfo) then
                print(`mt line or issue:`,NextCustomerInfo)
                return
            end

            local PlayerPizzaStack = PickUpSystem.PickupStack[player]["Pizza"]

            if (PlayerPizzaStack == nil) then
                return
            end

            if (GetDictionaryLength(PlayerPizzaStack) < 1) then
                return
            end

            local PizzasRequested = NextCustomerInfo[2]
            local TotalMoney = NextCustomerInfo[3]

            if (PizzasRequested > GetDictionaryLength(PlayerPizzaStack)) then
                print(`not enough pizzas in stack, requested: {PizzasRequested}, available: {GetDictionaryLength(PlayerPizzaStack)}`)
                return
            end

            local pizzaRemoved = 0
            for pizzaID , pizzaData in PlayerPizzaStack do 
                if (pizzaRemoved >= PizzasRequested) then
                    break
                end
                PickUpSystem.RemovePizzaAtPosition(player, "Pizza", pizzaData.Position)
                pizzaRemoved += 1
            end

            NPCGeneration.HandleNextCustomer(player)
            MoneypadCache["Part1"]:AddMoneyOnPad(player, TotalMoney)

        end
    }

    self.ActionPads = {} :: { [string] : ActionPad.ActionPad }

    for _ , locationPart in self.Locations do
        local newActionPad : ActionPad.ActionPad = ActionPad.new(locationPart.Name, locationPart.CFrame)   
        self.ActionPads[locationPart.Name] = newActionPad
    end

    local function iterateActiveLists()
        for name: string , actionpad : ActionPad.ActionPad in self.ActionPads do
            local ActiveList : {[number] : {any}} = actionpad:GetActiveActors()
            for plrUserId , IsActive in ActiveList do
                
                local player : Player? = Players:GetPlayerByUserId(plrUserId)
                if not player then
                    continue
                end

                if IsActive.Status and self.FunctionBinds[name] then
                    self.FunctionBinds[name](player)
                end
            end
        end
    end

    self.FunctionLoop = task.spawn(function()
        while task.wait(2) do
            local s: boolean , result = pcall(function()
                iterateActiveLists()
            end)
            if not(s) then
                warn(`Error iterating active lists: {result}`)
            end
        end
    end)

    self.HandleReplicas()

end

--[=[
    @function HandleReplicas
    @within ActionPad LocationConfiguration
]=]
function self.HandleReplicas()
    
    local function OnJoin(player : Player)
        local _ = player.Character or player.CharacterAdded:Wait()

        local plrToken = replica.Token(tostring(player.UserId) .. `ActionPad`)
        local actionPadReplica = replica.New({
            Token = plrToken,
            Data = {}
        })

        actionPadReplica:Replicate()

        -- Store the replica in a cache if needed
        self.ReplicaCache[player] = actionPadReplica

        for _ , actionpad : ActionPad.ActionPad in self.ActionPads do
            actionpad:GiveReplica(player,actionPadReplica)
            actionPadReplica:Set({actionpad.ID}, {
                IsActive = false,
                Actor = nil
            })
        end
    end

    local function OnLeave(player: Player)
        if not self.ReplicaCache[player] then
            warn(`Replica for {player.Name} not found`)
            return
        end

        for _ , actionpad : ActionPad.ActionPad in self.ActionPads do
            actionpad:RemoveReplica(player)
        end

        self.ReplicaCache[player] = nil
    end

    Players.PlayerAdded:Connect(function(player : Player)
        OnJoin(player)
    end)

    Players.PlayerRemoving:Connect(function(player : Player)
        OnLeave(player)
    end)

    for _ , player in Players:GetPlayers() do
        OnJoin(player)
    end

    game:BindToClose(function()
        for _ , player in Players:GetPlayers() do
            OnLeave(player)
        end
    end)

end

return self