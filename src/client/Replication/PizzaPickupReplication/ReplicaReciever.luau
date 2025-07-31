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

            local playerName : string = path[#path - 2]
            local pizzaID = path[#path - 1]
            local pizzaData = newValue

            if not(playerName) then
                warn("Player name not found in path:", path)
                return
            end

            Render.UpdatePlayerStack(playerName, pizzaStackReplica.Data[playerName] or {})

        end)
        self.Replica = pizzaStackReplica
    end)

    replica.RequestData()

end

return self