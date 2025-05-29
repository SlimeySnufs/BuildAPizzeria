local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--[=[
    @class ReplicaClient
    Handles the replica of the player and establishes connection functions to listen for value changes
    @client
    @tag ClientData
]=]
local module = {}
local Packages = ReplicatedStorage.Packages
local Replica = require(Packages.replica)  

local Lib = ReplicatedStorage.Lib
local CompareTable = require(Lib.CompareTable)

local LocalPlayer = Players.LocalPlayer
local UserId = LocalPlayer.UserId

--[=[
    @function Init
    @within ReplicaClient
    Starts the replica and recieves initial data
    @client
]=]
function module.Init()

    --[=[
        @prop ChangedListeners {Path : {string},Callback : (any) -> ()}
        @within ReplicaClient
    ]=]
    module.ChangedListeners = {}

    --[=[
        @prop Replica Replica
        @within ReplicaClient
    ]=]
    module.Replica = nil

    Replica.OnNew(tostring(UserId), function(replica)
        module.Replica = replica
    end)

    module.Replica:OnChange(function(method : string , path: {string}, newValue: any, oldValue : any)
        if (method ~= "Set") then return end

        local function searchForPath()
            


        end
        
    end)

    Replica.RequestData()
    
end

--[=[
    @function ListenForChange
    Use this as a .changed event for things in the player's data
    @return {Cancel = (any) -> ()}
    @within ReplicaClient
]=]
local count = 0
function module.ListenForChange(path : {string}, callback : (any) -> ())
    
    local listenID: number = count + 1
    
    table.insert(module.ChangedListeners,{
        ID = listenID,
        Path = path,
        Callback = callback
    })

    return {
        Cancel = function()
            for i , data in module.ChangedListeners do
                if data.Count == listenID then
                    module.ChangedListeners[i] = nil
                end
            end
        end
    }

end

return module