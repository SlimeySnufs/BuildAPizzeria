local startTime = tick()
debug.profilebegin("ClientLoading")
debug.setmemorycategory("Client")

--[[DATA]]
local Data = script.Data
local DataMain = require(Data.Main).Init()

--[[MONEYPAD REPLICATION / NETWORKING]]
local MoneyPadReplication = script.MoneyPadReplication
local ReplicationMain = require(MoneyPadReplication.Main).Init()

--[[PRODUCTIONPAD REPLICATION / NETWORKING]]
local ProductionPadReplication= script.ProductionPadReplication
local ReplicationMain_2 = require(ProductionPadReplication.Main).Init()

--[[USERINTERFACE]]
local UserInterface = script.UserInterface
local UserInterfaceMain = require(UserInterface.Main).Init()

debug.profileend("Client Loading")
print(`Client initialized in {tick()-startTime}ms`)