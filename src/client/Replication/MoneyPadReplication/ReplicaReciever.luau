--[=[
    @class MoneyPad ReplicaReciever
    Recieves the replicas created on the server to see the data of the money in the moneypad and how to render it
    @client
    @tag MoneyPadReplication
]=]
local self = {}

--[=[
    @prop OnNewConnection RBXScriptConnection?
    @within MoneyPad ReplicaReciever
]=]
self.OnNewConnection = nil

--[=[
    @prop MoneyPadCache {[string] : MoneyPadReplica}
    @within MoneyPad ReplicaReciever
]=]
self.MoneyPadCache = {} :: {[string] : any}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local replica = require(ReplicatedStorage.Packages.replica)

local LocalPlayer = Players.LocalPlayer

local Render = require(script.Parent.Render).Init()

export type ReplicaRecieverClass = typeof(self)

--[=[
    @function Init
    @within MoneyPad ReplicaReciever
]=]
function self.Init()
    self.ListenForNew()
end

--[=[
    @function ListenForNew
    
    @error CallOnce -- Should only be called once!
    @error NoID -- This pad had no ID when sent to the client
    
    @within MoneyPad ReplicaReciever
]=]
function self.ListenForNew()

    if (self.OnNewConnection) then
        error("The OnNewConnection is already applied to!")
        return
    end

    --[=[
        @prop MoneyPadReplica Replica?
        @within MoneyPad ReplicaReciever
    ]=]
    self.MoneyPadReplica = nil

    local function updaterender(pad : string, amount : number)
        Render.UpdateRender(pad,amount)
    end

    self.OnNewConnection = replica.OnNew(tostring(LocalPlayer.UserId).."MoneyPads", function(moneyPadReplica)
        self.MoneyPadReplica = moneyPadReplica
        
        for pad , data : {Money : number} in moneyPadReplica.Data do
            updaterender(pad, data.Money)
        end

        moneyPadReplica:OnChange(function(action, path : {string}, newValue: any, oldValue : any)
            if (action ~= "Set") then return end
            local lastKey = table.remove(path,#path)
            if (lastKey == "Money") then
                updaterender(path[#path], newValue)
            end
        end)

    end)

    replica.RequestData()

end

return self