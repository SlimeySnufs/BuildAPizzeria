local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TillAction = require(ServerScriptService.Server.InteractiveHandlers.NodeHarvesting.SubHandlers.TillAction)
local AnimationHandler = require(ServerScriptService.Server.PlayerStateHandler.AnimationHandler)
local PlayerStateManager = require(ServerScriptService.Server.PlayerStateHandler.PlayerStateManager)
local ResourceNodeCache = require(ServerScriptService.Server.Services.ResourceNodeService.ResouceNodeCache)
--[=[
    @class NodeHarvesting Main
    @tag InteractiveHandler
]=]
local self = {}

--[=[
    @function Init
    @within NodeHarvesting Main
]=]
function self.Init()
    self.ListenForStateChanges()
    return self
end

--[=[
    @function ListenForStateChanges
    @within NodeHarvesting Main
]=]
function self.ListenForStateChanges()
    
    --[=[
        @prop ListenerConnections {[Player] : {Disconnect : () -> ()}}
        @within NodeHarvesting Main
    ]=]
    self.ListenerConnections = {}

    --[=[
        @prop CooldownList {[Player] : number}
        @within NodeHarvesting Main
    ]=]
    self.CooldownList = {}

    local function OnJoin(player : Player)

        --[[FARMING HANDLING]]
        self.ListenerConnections[player] = PlayerStateManager.ListenForPlayerStateChange(player,"Farming", function(...)

            local Till = ReplicatedStorage.Till:Clone()
            local Character = player.Character or player.CharacterAdded:Wait()
            local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

            Till.Parent = Character
            Humanoid:EquipTool(Till)

            local toolIdleAnimationMethods = AnimationHandler.AnimatePlayer(player, "ToolIdle", true)

            local activatedConnection : RBXScriptConnection? = Till.Activated:Connect(function()

                if self.CooldownList[player] then 
                    if tick() - self.CooldownList[player] < 1 then return end
                end
                self.CooldownList[player] = tick()

                AnimationHandler.AnimatePlayer(player,"Harvesting", false)

                local crop : boolean = TillAction.SwingAttempt(player)
                if not crop then return end

                local hitNode = ResourceNodeCache[crop]

                hitNode:Harvest(player)

            end)

            local exited = PlayerStateManager.ListenForPlayerStateChange(player, "None", function()
                toolIdleAnimationMethods:Stop()
                toolIdleAnimationMethods = nil
                activatedConnection:Disconnect()
                Till:Destroy()
            end,true)

        end,false)


        ---[[OTHER HANDLING]]

    end

    local function OnLeave(player : Player)
        if self.ListenerConnections[player] then
            self.ListenerConnections[player].Disconnect()
            self.ListenerConnections[player] = nil
            if (self.CooldownList[player]) then
                self.CooldownList[player] = nil
            end
        end
    end

    Players.PlayerAdded:Connect(function(player : Player)
        OnJoin(player)
    end)

    Players.PlayerRemoving:Connect(function(player : Player)
        OnLeave(player)
    end)

    for _ , player in Players:GetPlayers() do
        OnJoin(player)
    end

end

return self