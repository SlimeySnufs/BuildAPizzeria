local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replica = require(ReplicatedStorage.Packages.replica)
--[=[
    @class PizzaPickupReplication ReplicaReciever
    @client
    @tag PizzaPickupReplication
]=]
local self = {}

--[=[
    @function Init
    Starts the replication for pizza pickup
    @within PizzaPickupReplication ReplicaReciever
]=]
function self.Init()
    self.ListenForNew()
end

function self.ListenForNew()

    self.Replica = nil

    local Render = require(script.Parent.Render).Init()

    replica.OnNew("PizzaStack", function(pizzaStackReplica : typeof(replica.New()))
        pizzaStackReplica:OnChange(function(action : string, path : {string}, newValue : any, oldValue : any)
            if (action ~= "Set") then return end
            
            local PlayerUserID : number = path[#path - 2]
            local pizzaID = path[#path - 1]
            local pizzaData = newValue

            Render.UpdatePlayerStack(PlayerUserID, pizzaStackReplica.Data[PlayerUserID] or {})

        end)
        self.Replica = pizzaStackReplica
    end)

    replica.RequestData()

end

return self