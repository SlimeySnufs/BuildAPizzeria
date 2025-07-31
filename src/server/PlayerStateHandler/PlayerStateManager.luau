--[=[
    @class PlayerStateManager
    @tag PlayerStateHandler
]=]

local self = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--[=[
    @type States "HoldingPizza" | "None" | "Farming"
    @within PlayerStateManager
]=]

export type States =
    | "HoldingPizza"
    | "None"
    | "Farming"

local cancellableStates : {[States] : boolean} = {
    HoldingPizza = true,
}

local StateCollidables = {
    HoldingPizza = {"None"},
    None = {"HoldingPizza","Farming"},
    Farming = {"None"}
}

--[=[
    @function Init
    @within PlayerStateManager
]=]
function self.Init()
    
    --[=[
        @prop PlayerStates {[Player] : {string}}
        @within PlayerStateManager
    ]=]
    self.PlayerStates = {}

    --[=[
        @prop Listeners {plr : Player, state : States, callback : () -> (States), once : boolean}
        @within PlayerStateManager
    ]=]
    self.Listeners = {}

    local function OnJoin(player : Player)
        if not self.PlayerStates[player] then
            self.PlayerStates[player] = {"None"}
        end

        -- Set initial state for the player
        local initialState = self.PlayerStates[player][1]
        print(`Player {player.Name} joined with initial state: {initialState}`)
    end

    local function OnLeave(player : Player)
        if self.PlayerStates[player] then
            print(`Player {player.Name} left with state: {self.PlayerStates[player][1]}`)
            self.PlayerStates[player] = nil -- Clear the player's state on leave
        end
    end

    Players.PlayerAdded:Connect(function(player : Player)
        OnJoin(player)
    end)

    Players.PlayerRemoving:Connect(function(player: Player)
        OnLeave(player)
    end)

    for _ , plr in Players:GetPlayers() do
        OnJoin(plr)
    end
    
    game:BindToClose(function()
        for player, states in pairs(self.PlayerStates) do
            print(`Player {player.Name} state on game close: {states[1]}`)
        end
    end)

end

local cached_cancellableStates = {}
local CooldownService = require(script.Parent.Parent.Services.CooldownService)
local GetReplica = require(ServerScriptService.Server.DataManipulation.GetReplica)
local blink = require(ReplicatedStorage.Packets.roblox_events.path.to.server)

--[=[
    @prop CooldownReg Registry
    @within PlayerStateManager 
]=]
self.CooldownReg = CooldownService.new(3) :: CooldownService.Registry  -- 3 seconds cooldown

blink.CancelState.On(function(player, _)
    print(`called`)
    local currentState = self.GetPlayerState(player)[1]

    if (self.CooldownReg:IsOnCooldown(player.Name)) then
        warn(`Player {player.Name} tried to cancel state {currentState} but is on cooldown.`)
        return
    end

    if not cancellableStates[currentState] then
        warn(`Player {player.Name} tried to cancel state {currentState} but it is not cancellable.`)
        return
    end

    if (cached_cancellableStates[player]) then
        self.CooldownReg:StartCooldown(player.Name)
        local success, issue = pcall(function()
            print(cached_cancellableStates)
            cached_cancellableStates[player]()
            cached_cancellableStates[player] = nil
        end)

        if not success then
            warn(`Failed to cancel state for player {player.Name}, issue:`,issue)
            return
        end

        print(`Player {player.Name} cancelled state {currentState}!`)
    else
        print(`Player {player.Name} cancelled state {currentState} without a previous state.`)
        self.CooldownReg:StartCooldown(player.Name)
        self.AttemptStateChange(player, `None`, `Cancelled`, nil)
    end
end)

--[=[
    @function AttemptStateChange
    @param player Player
    @param newState string
    @param source string? -- The source of the state change, can be used for logging or debugging
    @param cancel () -> ()? -- A function to call if the state change is cancellable
    @return boolean
    @error NO_CANCEL_FUNCTION - If the new state is cancellable, a cancel function must be provided.
    @within PlayerStateManager
]=]
function self.AttemptStateChange(player: Player, newState: States, source : string? , cancel : () -> ()?): boolean

    if cached_cancellableStates[player] then
        cached_cancellableStates[player]()
        cached_cancellableStates[player] = nil
        self.AttemptStateChange(player, `None`,`Cancelled`, nil)
    end

    if cancellableStates[newState] and not(cancel) then
        error(`State {newState} is cancellable, but no cancel function provided.`)
        return false
    elseif cancellableStates[newState] and cancel then
        cached_cancellableStates[player] = cancel
    end

    if not self.PlayerStates[player] then
        self.PlayerStates[player] = {"None"}
    end

    local currentStates = self.PlayerStates[player]
    if currentStates == nil then
        self.PlayerStates[player] = {"None"}
    end
    
    if newState == "None" and source ~= currentStates[1] then
        return
    end

    for _, state : string in currentStates do
        if not table.find(StateCollidables[newState], state) then
            return false
        end
    end

    self.PlayerStates[player] = {newState}

    local plrReplica = GetReplica.GetReplica(player)
    plrReplica:Set({`State`}, newState)

    for i , listenerData in self.Listeners do
        if listenerData.plr.UserId ~= player.UserId then continue end
        if listenerData.state == newState then
            task.spawn(listenerData.callback,newState)
            if listenerData.once then 
                table.remove(self.Listeners,i)
            end
        end
    end

    return true , currentStates[1]
end

--[=[
    @function GetPlayerState
    @param player Player
    @return {string} -- Returns the current state of the player
    @within PlayerStateManager
]=]
function self.GetPlayerState(player: Player): {States}
    if not self.PlayerStates[player] then
        return {"None"} -- Default state if player has no state set
    end
    return self.PlayerStates[player]
end

--[=[
    @function ListenForPlayerStateChange
    @param player Player
    @param state States
    @param ({States}) -> ({string})
    @within PlayerStateManager
]=]
function self.ListenForPlayerStateChange(player : Player, state : States, callback : () -> ({States}), Once : boolean) : {Disconnect : () -> ()}

    if not self.PlayerStates[player] then
        self.PlayerStates[player] = {"None"}
    end

    table.insert(self.Listeners,{
        plr = player,
        state = state,
        callback = callback,
        once = Once,
    })

    return {
        Disconnect = function()
            for i , listenerData in self.Listeners do
                if listenerData.plr ~= player then continue end
                if listenerData.state ~= state then continue end
                if listenerData.callback ~= callback then continue end
                table.remove(self.Listeners,i)
            end
        end
    }

end

return self