local ReplicatedStorage = game:GetService("ReplicatedStorage")
local replica = require(ReplicatedStorage.Packages.replica)
local Players = game:GetService("Players")

local LocalPlayer: Player = Players.LocalPlayer

--[=[
    @class ResourceNode ReplicaReciever
    @client
    @tag ResourceNodeReplication
]=]
local self = {}

--[=[
    @function Init
    @within ResourceNode ReplicaReciever
]=]
function self.Init()
    self.ListenForNew()
    return self
end

--[=[
    @function ListenForNew
    @within ResourceNode ReplicaReciever
]=]
function self.ListenForNew()
    
    --[=[
        @prop Replica Replica
        @within ResourceNode ReplicaReciever
    ]=]
    self.Replica = nil

    local Render = require(script.Parent.Render).Init()

    replica.OnNew(LocalPlayer.UserId..`ResourceNodes`, function(resourceReplica)
        
        self.Replica = resourceReplica

        resourceReplica:OnChange(function(changeMethod, path : {string}, newValue , oldValue)
            if changeMethod ~= "Set" then return end

            local PlantKey : number = path[1]
            local changedProp : string = path[#path]

            local Physical = self.Replica.Data[PlantKey].Physical
            local NodeType = self.Replica.Data[PlantKey].ResourceType

            if changedProp == "GrowthStage" then
                Render.UpdateGrowthState(Physical,newValue,oldValue,NodeType) 
            end

        end)

    end)

    replica.RequestData()

end

return self