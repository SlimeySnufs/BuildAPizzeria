local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local replica = require(ReplicatedStorage.Packages.replica)

--[=[
    @class NPCGeneration
    @server
    @tag InteractiveHandler
]=]

local self = {}

local function GetDictionaryLength(dict: {[any] : any}) : number
    local count: number = 0
    for _ in pairs(dict) do
        count += 1
    end
    return count
end

--[=[
    @function Init
    Handles Connections and starting data
    @within NPCGeneration
]=]
function self.Init()

    self.NPCQueues = {}
    self.ReplicaCache = {}
    self.UniqueID = 0

    local function OnJoin(player : Player)
        local _ = player.Character or player.CharacterAdded:Wait()

        local plrToken = replica.Token(tostring(player.UserId)..`Customer`)
        local NPCReplica = replica.New({
            Token = plrToken,
            Data = {}
        })

        NPCReplica:Replicate()

        self.NPCQueues[player.UserId] = {}
        self.ReplicaCache[player] = NPCReplica

    end

    Players.PlayerAdded:Connect(function(player : Player)
        OnJoin(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player : Player)
        if not(self.NPCQueues[player.UserId]) then
            warn(`the players queue isnt even here`)
            return
        end
        if not(self.ReplicaCache[player]) then
            warn(`the replica for {player.Name} was not found`)
            return
        end
        self.ReplicaCache[player] = nil
        self.NPCQueues[player.UserId] = nil
    end)
    
    for _ , plr in Players:GetPlayers() do
        OnJoin(plr)
    end

    self.HandleCustomerLoop()

    return self

end

local function getCustomerType() : string
    
    local rnd: number = Random.new():NextNumber(1,100)

    if (rnd < 10) then
        return "Gold"
    end
    
    return "Normal"

end

type CustomerData = {ID : string, customerType : ("Gold" | "Normal"), RequestAmount : number}

--[=[
    @function GivePlayerCustomer
    @param player Player
    @within NPCGeneration
]=]
function self.GivePlayerCustomer(player : Player)

    local replica = self.ReplicaCache[player]
    if not(replica) then
        warn(`the replica for {player.Name} was not found`)
        return
    end

    if (#self.NPCQueues[player.UserId] >= 10) then
        return
    end

    local id: number = tostring(self.UniqueID + 1)
    local customerTypePull: string = getCustomerType()
    local PizzasRequired: number = math.random(1,3)

    table.insert(self.NPCQueues[player.UserId],{
        ID = tostring(id),
        customerType = customerTypePull,
        RequestAmount = PizzasRequired,
    } :: CustomerData)

    replica:Set({tostring(id)},{
        ID = tostring(id),
        customerType = customerTypePull,
        RequestAmount = PizzasRequired,
    } :: CustomerData)

    table.sort(self.NPCQueues[player.UserId], function(a: CustomerData, b: CustomerData)
        return tonumber(a.ID) < tonumber(b.ID)
    end)

    self.UniqueID += 1

end

--[=[
    @function HandleNextCustomer
    
    @param player Player

    @return string , number , number

    @within NPCGeneration
]=]
function self.HandleNextCustomer(player : Player) : (string , number , number)

    local customerAmount: number = GetDictionaryLength(self.NPCQueues[player.UserId])
    if customerAmount <= 0 then
        warn(`empty customer line`)
        return
    end

    local plrReplica = self.ReplicaCache[player]
    if not(plrReplica) then
        warn(`the replica for {player.Name} was not found`)
        return
    end

    table.sort(self.NPCQueues[player.UserId], function(a: CustomerData, b: CustomerData)
        return tonumber(a.ID) < tonumber(b.ID)
    end)

    local firstCustomerData : CustomerData = table.remove(self.NPCQueues[player.UserId],1)

    plrReplica:Set({firstCustomerData.ID}, nil)

    local values : {[string] : number} = {
        ["Gold"] = 5,
        ["Normal"] = 2,
    }

    return firstCustomerData.customerType , firstCustomerData.RequestAmount , (values[firstCustomerData.customerType] * firstCustomerData.RequestAmount)

end

--[=[
    @function GetNextCustomer
    Gets the next customer for the player without removing them
    @param player Player
    @return string , number , number
    @within NPCGeneration
]=]
function self.GetNextCustomer(player : Player) : (string , number , number)

    if not(self.ReplicaCache[player]) then
        warn(`the replica for {player.Name} was not found`)
        return
    end

    table.sort(self.NPCQueues[player.UserId], function(a: CustomerData, b: CustomerData)
        return tonumber(a.ID) < tonumber(b.ID)
    end)

    local customerAmount: number = GetDictionaryLength(self.NPCQueues[player.UserId])
    if customerAmount <= 0 then
        warn(`empty customer line`)
        return
    end

    local firstCustomerData : CustomerData = self.NPCQueues[player.UserId][1]
    if not(firstCustomerData) then
        warn(`the first customer data was not found`)
        return
    end

    local values : {[string] : number} = {
        ["Gold"] = 5,
        ["Normal"] = 2,
    }

    return {firstCustomerData.customerType , firstCustomerData.RequestAmount , (values[firstCustomerData.customerType] * firstCustomerData.RequestAmount)}

end

--[=[
    @function HandleCustomerLoop
    Handles a loop where players get customers from
    @within NPCGeneration
]=]
function self.HandleCustomerLoop()
    
    task.spawn(function()

        while task.wait(5) do
            for _ , plr: Player in Players:GetPlayers() do
                local s, result = pcall(function()
                    self.GivePlayerCustomer(plr)
                end)
                if not(s) then
                    warn(result)
                end
            end
        end

    end)

end

return self