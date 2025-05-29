--[=[
    @class Main
    Contains one function that just starts all data modules for the client
    @client
    @tag ClientData
]=]
local module = {}

--[=[
    @function Init
    @within Main
    Initializes all data modules within the data folder of the client
    @client
]=]
function module.Init()
    
    local _ReplicaClient = require(script.Parent.ReplicaClient)

end

return module