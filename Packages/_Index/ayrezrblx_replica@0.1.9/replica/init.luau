local RunService = game:GetService("RunService")

local ReplicaServer = script:FindFirstChild("Server")
local ExperimentalReplicaServer = script:FindFirstChild("Experimental")

if RunService:IsServer() then
    if ExperimentalReplicaServer and _G.UseExperimentalReplica == true then
        return require(ExperimentalReplicaServer)
    end
    return require(ReplicaServer)
else
    if ReplicaServer then
        ReplicaServer:Destroy()
    end
    if ExperimentalReplicaServer then
        ExperimentalReplicaServer:Destroy()
    end
    return require(script.Client)
end
