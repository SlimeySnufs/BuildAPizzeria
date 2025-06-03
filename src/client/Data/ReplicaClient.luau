local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[=[
    @class ReplicaClient
    Handles the replica of the player and establishes connection functions to listen for value changes.
    @client
    @tag ClientData
]=]
local module = {}

local Packages = ReplicatedStorage.Packages
local ReplicaLib = require(Packages.replica)

local Lib = ReplicatedStorage.Lib
local CompareTable = require(Lib.CompareTable)

local LocalPlayer: Player = Players.LocalPlayer
local UserId: number = LocalPlayer.UserId

type ReplicaType = typeof(ReplicaLib.OnNew(...))
export type Replica = ReplicaType

--[=[
    @prop Replica Replica?
    The current Replica instance for the local player.
    @within ReplicaClient
]=]
module.Replica = nil :: ReplicaType?

--[=[
    @prop Ready boolean
    Indicates whether the Replica has finished initializing and is ready.
    @within ReplicaClient
]=]
module.Ready = false

--[=[
    @prop QueuedListeners {Path: {string}, Callback: (any, any) -> (), ListenerType: string}[]?
    Listeners that are queued before the replica is ready.
    @within ReplicaClient
]=]
module.QueuedListeners = {} :: {
    { Path: {string}, Callback: (any, any) -> (), ListenerType: string }
}?

--[=[
    @prop ChangedListeners {ID: number, Path: {string}, Callback: (any, any) -> ()}[]
    Listeners for value changes in the Replica.
    @within ReplicaClient
]=]
module.ChangedListeners = {}

--[=[
    @prop InsertionListeners {ID: number, Path: {string}, Callback: (string, any) -> ()}[]
    Listeners for key insertions in replica tables.
    @within ReplicaClient
]=]
module.InsertionListeners = {}

--[=[
    @prop DeletionListeners {ID: number, Path: {string}, Callback: (string, any) -> ()}[]
    Listeners for key deletions in replica tables.
    @within ReplicaClient
]=]
module.DeletionListeners = {}

local count = 0

--[=[
    @function Init
    @within ReplicaClient
    Starts the replica and receives initial data.
    @client
    @return ReplicaClient
]=]
function module.Init()
    local startTime = tick()
    module.Data = {}

    ReplicaLib.OnNew(tostring(UserId), function(replica: ReplicaType)

        if module.Replica then
            warn("[ReplicaClient] Replica already initialized, ignoring new replica.")
            return
        end

        module.Replica = replica
        module.Ready = true
        module.Data = replica.Data

        print(`[ReplicaClient] Client received initial data in {tick() - startTime}s`)
        print("[ReplicaClient] Data:", replica.Data)

        replica:OnChange(function(method: string, path: {string}, newValue: any, oldValue: any)
            if method ~= "Set" then return end

            local function searchForPath()
                for _, data in module.ChangedListeners do
                    if CompareTable.IsTableSame(data.Path, path) then
                        task.spawn(data.Callback, newValue, oldValue)
                    end
                end
            end

            local function searchForInsertion()
                local key = table.remove(path)
                for _, data in module.InsertionListeners do
                    if CompareTable.IsTableSame(data.Path, path) then
                        task.spawn(data.Callback, key, newValue)
                    end
                end
            end

            local function searchForDeletion()
                local key = table.remove(path)
                for _, data in module.DeletionListeners do
                    if CompareTable.IsTableSame(data.Path, path) then
                        task.spawn(data.Callback, key, oldValue)
                    end
                end
            end

            if newValue ~= nil then
                searchForPath()
            end
            if newValue ~= nil and oldValue == nil then
                searchForInsertion()
            end
            if newValue == nil and oldValue ~= nil then
                searchForDeletion()
            end
        end)

        if module.QueuedListeners then
            for _, listener in module.QueuedListeners do
                if listener.ListenerType == "Change" then
                    table.insert(module.ChangedListeners, listener)
                elseif listener.ListenerType == "Insertion" then
                    table.insert(module.InsertionListeners, listener)
                elseif listener.ListenerType == "Deletion" then
                    table.insert(module.DeletionListeners, listener)
                end
            end
        end

        module.Data = replica.Data

        module.QueuedListeners = nil
    end)

    ReplicaLib.RequestData()
    return module
end

--[=[
    @function QueueListener
    @within ReplicaClient
    Queues a listener until the replica is ready.

    @param path {string} -- Path to listen on.
    @param callback (newValue: any, oldValue: any) -> () -- Function to call when the value changes.
    @param typeOfListener string -- "Change", "Insertion", or "Deletion".
]=]
function module.QueueListener(path: {string}, callback: (any, any) -> (), typeOfListener: string)
    if not module.QueuedListeners then
        module.QueuedListeners = {}
    end

    table.insert(module.QueuedListeners, {
        Path = path,
        Callback = callback,
        ListenerType = typeOfListener,
    })
end

--[=[
    @function ListenForChange
    @within ReplicaClient
    Use this as a `.Changed` event for values in the replica.

    @param path {string}
    @param callback (newValue: any, oldValue: any) -> ()
    @return {Cancel: () -> ()} -- A table with a `Cancel` method to disconnect the listener.
]=]
function module.ListenForChange(path: {string}, callback: (any, any) -> ())
    local listenID = count + 1
    count += 1

    local cancelData = {
        Cancel = function()
            for i, data in module.ChangedListeners do
                if data.ID == listenID then
                    module.ChangedListeners[i] = nil
                end
            end
        end
    }

    if not module.ChangedListeners then
        module.QueueListener(path, callback, "Change")
        return cancelData
    end

    table.insert(module.ChangedListeners, {
        ID = listenID,
        Path = path,
        Callback = callback,
    })

    return cancelData
end

--[=[
    @function ListenForInsertion
    @within ReplicaClient
    Use this as a `.ChildAdded` equivalent for tables in the replica.

    @param path {string}
    @param callback (newKey: string, newValue: any) -> ()
    @return {Cancel: () -> ()} -- A table with a `Cancel` method to disconnect the listener.
]=]
function module.ListenForInsertion(path: {string}, callback: (string, any) -> ())
    local listenID = count + 1
    count += 1

    local cancelData = {
        Cancel = function()
            for i, data in module.InsertionListeners do
                if data.ID == listenID then
                    module.InsertionListeners[i] = nil
                end
            end
        end
    }

    if not module.InsertionListeners then
        module.QueueListener(path, callback, "Insertion")
        return cancelData
    end

    table.insert(module.InsertionListeners, {
        ID = listenID,
        Path = path,
        Callback = callback,
    })

    return cancelData
end

--[=[
    @function ListenForDeletion
    @within ReplicaClient
    Use this as a `.ChildRemoved` equivalent for tables in the replica.

    @param path {string}
    @param callback (deletedKey: string, oldValue: any) -> ()
    @return {Cancel: () -> ()} -- A table with a `Cancel` method to disconnect the listener.
]=]
function module.ListenForDeletion(path: {string}, callback: (string, any) -> ())
    local listenID = count + 1
    count += 1

    local cancelData = {
        Cancel = function()
            for i, data in module.DeletionListeners do
                if data.ID == listenID then
                    module.DeletionListeners[i] = nil
                end
            end
        end
    }

    if not module.DeletionListeners then
        module.QueueListener(path, callback, "Deletion")
        return cancelData
    end

    table.insert(module.DeletionListeners, {
        ID = listenID,
        Path = path,
        Callback = callback,
    })

    return cancelData
end

return module
