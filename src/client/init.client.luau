local startTime = tick()
debug.profilebegin("ClientLoading")
debug.setmemorycategory("Client")

--[[DATA]]
local Data = script.Data
local DataMain = require(Data.Main).Init()

--[[SCENES]]
local Scenes = script.Scenes
local SceneMain = require(Scenes.Main).Init()

local ReplicationStartTime = tick()

--[[REPLICATION DIRECTORY]]
local Replication = script.Replication

--[[PARALLEL REPLICATION INITIALIZATION]]
-- Parallelize all replication modules for faster loading
task.spawn(function()
    --[[MONEYPAD REPLICATION / NETWORKING]]
    local MoneyPadReplication = Replication.MoneyPadReplication
    require(MoneyPadReplication.Main).Init()
end)

task.spawn(function()
    --[[PRODUCTIONPAD REPLICATION / NETWORKING]]
    local ProductionPadReplication= Replication.ProductionPadReplication
    require(ProductionPadReplication.Main).Init()
end)

task.spawn(function()
    --[[CUSTOMER REPLICATION / NETWORKING]]
    local CustomerReplication = Replication.CustomerReplication
    require(CustomerReplication.Main).Init()
end)

task.spawn(function()
    --[[ACTIONPAD REPLICATION / NETWORKING]]
    local ActionPadReplication = Replication.ActionPadReplication
    require(ActionPadReplication.Main).Init()
end)

task.spawn(function()
    --[[PIZZA REPLICATION / NETWORKING]]
    local PizzaPickUpReplication = Replication.PizzaPickupReplication
    require(PizzaPickUpReplication.Main).Init()
end)

task.spawn(function()
    --[[RESOURCE NODE REPLICATION]]
    local ResourceNodeReplication = Replication.ResourceNodeReplication
    require(ResourceNodeReplication.Main).Init()
end)

print(`Replication modules started in parallel in {tick()-ReplicationStartTime}ms`)

--[[USERINTERFACE]]
local UserInterface = script.UserInterface
local s, UserInterfaceMain = pcall(function()
    task.spawn(function()
        require(UserInterface.Main).Init()
    end)
end)

debug.profileend()
print(`Client initialized in {tick()-startTime}ms`)