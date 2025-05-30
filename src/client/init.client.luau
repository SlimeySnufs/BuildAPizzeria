local startTime = tick()
debug.profilebegin("Client Loading")

--[[DATA]]
local Data = script.Data
local DataMain = require(Data.Main).Init()

--[[MONEYPAD REPLICATION / NETWORKING]]
local MoneyPadReplicaion = script.MoneyPadReplication
local ReplicationMain = require(MoneyPadReplicaion.Main).Init()

debug.profileend()
print(`Client initialized in {tick()-startTime}ms`)