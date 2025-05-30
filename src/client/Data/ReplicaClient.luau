local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
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

local LocalPlayer: Player = Players.LocalPlayer
local UserId: number = LocalPlayer.UserId

export type Replica = typeof(module.Init(...))

--[=[
    @function Init
    @within ReplicaClient
    Starts the replica and recieves initial data
    @client
]=]
function module.Init()

    local startTime = tick()
    print(`Waiting for client replica!`)

    --[=[
        @prop ChangedListeners {Path : {string}, Callback : (newValue : any, oldValue : any) -> (any,any)}
        @within ReplicaClient
    ]=]
    --[=[
        @prop InsertionListeners {Path : {string}, Callback : (newKey : string, newValue : any) -> (string,any)}
        @within ReplicaClient
    ]=]
    --[=[
        @prop DeletionListeners {Path : {string}, Callback : (deletedKey : string, oldValue : any) -> (string,any)}
        @within ReplicaClient
    ]=]
    --[=[
        @prop Ready Boolean
        Becomes true when client gets initial data
        @within ReplicaClient
    ]=]
    --[=[
        @prop QueuedListeners {any}
        Waiting for replica to be ready
        @within ReplicaClient
    ]=]
    module.Ready = false
    module.QueuedListeners = {}
    module.ChangedListeners = {}
    module.InsertionListeners = {}
    module.DeletionListeners = {}

    --[=[
        @prop Replica Replica
        @within ReplicaClient
    ]=]
    module.Replica = nil

    Replica.OnNew(tostring(UserId), function(replica)
        module.Replica = replica
        print(`Client recieved intial data in {tick() - startTime}ms!`)
        print(`Data: `, replica.Data)
        module.Ready = true

        module.Replica:OnChange(function(method : string , path: {string}, newValue: any, oldValue : any)
            if (method ~= "Set") then return end

            local function searchForPath(path: {string}, newValue : any , oldValue : any)
                for _ , data in module.ChangedListeners do
                    if CompareTable.IsTableSame(data.Path, path) then
                        task.spawn(data.Callback,newValue,oldValue)
                    end
                end
            end

            local function searchForInsertion(path : {string}, newValue : any)
                local SearchingKey : string = table.remove(path,#path)
                for _ , data in module.InsertionListeners do
                    if CompareTable.IsTableSame(data.Path, path) then
                        task.spawn(data.Callback,SearchingKey,newValue)
                    end
                end
            end

            local function searchForDeletion(path : {string}, oldValue : any)
                local DeletedKey : string = table.remove(path,#path)
                for _ , data in module.DeletionListeners do
                    if CompareTable.IsTableSame(data.Path, path) then
                        task.spawn(data.Callback,DeletedKey,newValue)
                    end
                end
            end

            if (newValue ~= nil) then
                searchForPath(path,newValue,oldValue)
            end

            if (newValue ~= nil) and (oldValue == nil) then
                searchForInsertion(path,newValue,oldValue)
            end

            if (newValue == nil) and (oldValue ~= nil) then
                searchForDeletion(path,oldValue)
            end
            
        end)

        for _, listener in module.QueuedListeners do
            if listener.ListenerType == "Change" then
                table.insert(module.ChangedListeners, listener)
            elseif listener.ListenerType == "Insertion" then
                table.insert(module.InsertionListeners, listener)
            elseif listener.ListenerType == "Deletion" then
                table.insert(module.DeletionListeners, listener)
            end
        end

        module.QueuedListeners = nil

    end)

    Replica.RequestData()

    return module
    
end

--[=[
    @function QueueListener
    @param path {string}
    @param callback (NewValue : any, OldValue : any) -> (any,any)
    @param type string
    @within ReplicaClient
]=]
function module.QueueListener(path : {string}, callback : (any) -> (), typeOfListener : string)
    
    if not(module.QueuedListeners) then
        module.QueuedListeners = {}
    end

    table.insert(module.QueuedListeners,{
        Path = path,
        Callback = callback,
        ListenerType = typeOfListener,
    })

end

--[=[
    @function ListenForChange
    Use this as a .changed event for things in the player's data
    @param path {string}
    @param callback (NewValue : any, OldValue : any) -> (any,any)
    @return {Cancel : () -> ()}
    @within ReplicaClient
]=]
local count = 0
function module.ListenForChange(path : {string}, callback : (any) -> ())

    local listenID: number = count + 1
    count += 1

    local cancelData = {
        Cancel = function()
            for i , data in module.ChangedListeners do
                if data.ID == listenID then
                    module.ChangedListeners[i] = nil
                end
            end
        end
    }
    
    if not(module.ChangedListeners) then
        module.QueueListener(path, callback, "Change")
        return cancelData
    end
    
    table.insert(module.ChangedListeners,{
        ID = listenID,
        Path = path,
        Callback = callback
    })

    return cancelData

end

--[=[
    @function ListenForInsertion
    Use this as a .childadded event for things in the player's data
    @param path {string}
    @param callback (newKey : string, newValue : any) -> (string,any)
    @return {Cancel : (any) -> ()}
    @within ReplicaClient
]=]
function module.ListenForInsertion(path : {string}, callback : (any) -> ())

    local listenID: number = count + 1
    count += 1

    local cancelData = {
        Cancel = function()
            for i : number , data : {any} in module.InsertionListeners do
                if data.ID == listenID then
                    module.InsertionListeners[i] = nil
                end
            end
        end
    }

    if not(module.InsertionListeners) then
        module.QueueListener(path, callback, "Insertion")
        return cancelData
    end
    
    table.insert(module.InsertionListeners,{
        ID = listenID,
        Path = path,
        Callback = callback
    })

    return cancelData

end

--[=[
    @function ListenForDeletion
    Use this as a .childremoved event for things in the player's data
    @param path {string}
    @param callback (deletedKey : string, oldValue : any) -> (string,any)
    @return {Cancel : (any) -> ()}
    @within ReplicaClient
]=]
function module.ListenForDeletion(path : {string}, callback : (any) -> ())
    
    local listenID: number = count + 1
    count += 1
    
    local cancelData = {
        Cancel = function()
            for i : number , data : {any} in module.DeletionListeners do
                if data.ID == listenID then
                    module.DeletionListeners[i] = nil
                end
            end
        end
    }

    if not(module.DeletionListeners) then
        module.QueueListener(path, callback, "Deletion")
        return cancelData
    end

    table.insert(module.DeletionListeners,{
        ID = listenID,
        Path = path,
        Callback = callback
    })

    return cancelData

end

return module