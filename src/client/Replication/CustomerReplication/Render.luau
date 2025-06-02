local ReplicatedStorage = game:GetService("ReplicatedStorage")
--[=[
    @class CustomerReplication Render
    @tag CustomerReplication
    @client
]=]
local self = {}

local Lib = ReplicatedStorage.Lib
local RandomNPC = require(Lib.RandomNPC)

--[=[
    @function Init
    @within CustomerReplication Render
]=]
function self.Init()

    self.CurrentCustomers = {}
    self.CustomerCount = 0

    self.LineStart = workspace.LineStart

end

--[=[
    @function NewCustomer

    @param id number
    @param customerData CustomerData

    @within CustomerReplication Render
]=]
function self.NewCustomer()
    
end

--[=[
    @function RemovedCustomer

    @within CustomerReplication Render

    @param id number
]=]
function self.RemovedCustomer()
    
end

return self
