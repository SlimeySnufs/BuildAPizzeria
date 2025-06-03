local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local replica = require(ReplicatedStorage.Packages.replica)
local LocalPlayer = Players.LocalPlayer

--[=[
    @class ActionPadReplication ReplicaReciever
    @client
    @tag ActionPadReplication
]=]
local self = {}

--[=[
    @function Init
    @within ActionPadReplication ReplicaReciever
]=]
function self.Init()
    self.ListenForNew()
end

--[=[
    @function ListenForNew
    @within ActionPadReplication ReplicaReciever
]=]
function self.ListenForNew()
    
    self.Replica = {}

    local Render = require(script.Parent.Render).Init()

    replica.OnNew(LocalPlayer.UserId..`ActionPad`, function(actionPadReplica : typeof(replica.New()))
        
        actionPadReplica:OnChange(function(action : string, path : {string}, newValue : any, oldValue : any)
            print(path, action, newValue, oldValue)
            if (action ~= "Set") then return end
            
            local padID = path[#path]
            local status : boolean = newValue.Status

            if (status) then
                Render.UpdateRender(padID, true)
                return
            end

            Render.UpdateRender(padID, false)

        end)

    end)

end

return self