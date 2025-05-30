--[=[
    @class DataMain
    Contains one function that just starts all data modules for the client
    @client
    @tag ClientData
]=]
local module = {}

--[=[
    @function Init
    @within DataMain
    Initializes all data modules within the data folder of the client
    @client
]=]
function module.Init()
    
    local ReplicaClient = require(script.Parent.ReplicaClient).Init()

end

return module