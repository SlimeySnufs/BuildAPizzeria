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

--[[MONEYPAD REPLICATION / NETWORKING]]
local MoneyPadReplication = Replication.MoneyPadReplication
local ReplicationMain = require(MoneyPadReplication.Main).Init()

--[[PRODUCTIONPAD REPLICATION / NETWORKING]]
local ProductionPadReplication= Replication.ProductionPadReplication
local ReplicationMain_2 = require(ProductionPadReplication.Main).Init()

--[[CUSTOMER REPLICATION / NETWORKING]]
local CustomerReplication = Replication.CustomerReplication
local Replication_3 = require(CustomerReplication.Main).Init()

--[[ACTIONPAD REPLICATION / NETWORKING]]
local ActionPadReplication = Replication.ActionPadReplication
local Replication_4 = require(ActionPadReplication.Main).Init()

--[[PIZZA REPLICATION / NETWORKING]]
local PizzaPickUpReplication = Replication.PizzaPickupReplication
local Replication_5 = require(PizzaPickUpReplication.Main).Init()

--[[RESOURCE NODE REPLICATION]]
local ResourceNodeReplication = Replication.ResourceNodeReplication
local Replication_6 = require(ResourceNodeReplication.Main).Init()

print(`Replication initialized in {tick()-ReplicationStartTime}ms`)

--[[USERINTERFACE]]
local UserInterface = script.UserInterface
local s, UserInterfaceMain = pcall(function()
    task.spawn(function()
        require(UserInterface.Main).Init()
    end)
end)

debug.profileend()
print(`Client initialized in {tick()-startTime}ms`)