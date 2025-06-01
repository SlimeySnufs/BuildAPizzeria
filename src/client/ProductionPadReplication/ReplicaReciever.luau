local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replica = require(ReplicatedStorage.Packages.replica)
--[=[
    @class ProductionPad ReplicaReciever
    @tag ProdPadRep
    @client
]=]
local self = {}

--[=[
    @function Init
    @within ProductionPad ReplicaReciever
]=]
function self.Init()

    --[=[
        @prop Replica Replica?
        @within ProductionPad ReplicaReciever
    ]=]
    self.Replica = nil

    local Render = require(script.Parent.Render).init()
    
    replica.OnNew(tostring(Players.LocalPlayer.UserId).."ProductionPad", function(productionpadReplica)
    
        if (self.Replica) then
            warn(`The player already has their replica for productionpads?`)
            return
        end

        for pad , data in productionpadReplica.Data do
            Render.InitialRenderFromData(pad, data)
        end

        productionpadReplica:OnChange(function(action , path , newvalue, OldValue)
            if (action ~= "Set") then return end

            print(`is newvalue nil`, newvalue == nil)
            print(`is oldvalue nil`,OldValue == nil)
            
            if (newvalue ~= nil) and (OldValue == nil) then
            
                --[[ADDED]]

                local padKey = path[#path - 1]
                local key = path[#path]

                print(`added {key} to {padKey}`)

                local asset = ReplicatedStorage.Assets:FindFirstChild(newvalue.Item)
                if not(asset) then
                    print(`couldnt find asset for {newvalue.Item}`)
                end

                Render.AddFromProduction(padKey, key, asset)

            end

            if (newvalue == nil) then
                
                --[[REMOVING]]
                local padKey = path[#path - 1]
                local key = path[#path]
                print(`removed {key} from {padKey}`)

                Render.RemoveFromProduction(padKey, key)

            end

        end)

    end)

end

return self