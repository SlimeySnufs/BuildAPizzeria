local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replica = require(ReplicatedStorage.Packages.replica)
--[=[
    @class CustomerReplication ReplicaReciever
    @client
    @tag CustomerReplication
]=]
local self = {}

--[=[
    @function init
    @within CustomerReplication ReplicaReciever
]=]
function self.Init()
    self.Replica = nil
    self.ListenForNew()
    return self
end

--[=[
    @function ListenForNew
    @within CustomerReplication ReplicaReciever
]=]
function self.ListenForNew()

    print(`listening for replica`)

    local Render = require(script.Parent.Render).Init()
    
    replica.OnNew(tostring(Players.LocalPlayer.UserId) .. `Customer`, function(customerReplica)

        print(`replica recieved for {Players.LocalPlayer.Name}`)
        
        self.Replica = customerReplica

        customerReplica:OnChange(function(action , path , newValue, oldValue)
            if (action ~= "Set") then return end

            if (newValue ~= nil) and (oldValue == nil) then
                --[[NEW CUSTOMER]]
                local customerID : string = path[#path]
                local customerData : {ID : string, RequestAmount : number, customerType : ("Gold" | "Normal")} = newValue

                Render.NewCustomer(customerID,customerData)

            end

            if (newValue == nil) then
                --[REMOVED CUSTOMER]
                local customerID : string = path[#path]
                Render.RemovedCustomer(customerID)
            end

        end)

    end)

end

return self