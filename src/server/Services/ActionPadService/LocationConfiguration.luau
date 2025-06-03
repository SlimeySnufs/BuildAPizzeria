local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replica = require(ReplicatedStorage.Packages.replica)
local ActionPad = require(script.Parent.ActionPad)
--[=[
    @class ActionPad LocationConfiguration
    @tag ActionPadService
    @server
]=]
local self = {}

--[=[
    @function Init
    Initializes the ActionPadService, setting up necessary configurations and connections.
    @within ActionPad LocationConfiguration
]=]
function self.Init()
    
    self.ReplicaCache = {} :: { [Player] : typeof(replica.New())}

    self.Locations = {
        ["PizzaOrder"] = workspace.Part3
    } :: { [string] : BasePart }

    self.ActionPads = {} :: { [string] : ActionPad.ActionPad }

    for _ , locationPart in self.Locations do
        local newActionPad : ActionPad.ActionPad = ActionPad.new(locationPart.Name, locationPart.CFrame)   
        self.ActionPads[locationPart.Name] = newActionPad
    
        newActionPad.PlayerEntered:Connect(function(plr : Player)
            print(`start attempting order fill here`)
        end)

        newActionPad.PlayerExited:Connect(function(plr : Player)
            print(`end order fill here`)
        end)

    end

    self.HandleReplicas()

end

--[=[
    @function HandleReplicas
    @within ActionPad LocationConfiguration
]=]
function self.HandleReplicas()
    
    Players.PlayerAdded:Connect(function(player : Player)
        
        local _ = player.Character or player.CharacterAdded:Wait()

        local plrToken = replica.Token(tostring(player.UserId) .. `ActionPad`)
        local actionPadReplica = replica.New({
            Token = plrToken,
            Data = {}
        })

        actionPadReplica:Subscribe(player)
        actionPadReplica:Replicate()

        -- Store the replica in a cache if needed
        self.ReplicaCache[player] = actionPadReplica

        for _ , actionpad : ActionPad.ActionPad in self.ActionPads do
            actionpad:GiveReplica(player,actionPadReplica)
            actionPadReplica:Set({actionpad.ID}, {
                IsActive = false,
                Actor = nil
            })
        end

    end)

    Players.PlayerRemoving:Connect(function(player : Player)
        if not self.ReplicaCache[player] then
            warn(`Replica for {player.Name} not found`)
            return
        end

        for _ , actionpad : ActionPad.ActionPad in self.ActionPads do
            actionpad:RemoveReplica(player,actionPadReplica)
        end

        self.ReplicaCache[player] = nil
    end)

end

return self