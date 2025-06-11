--[=[
    @class PlayerStateManager
    @tag PlayerStateHandler
]=]

local self = {}
local Players = game:GetService("Players")

--[=[
    @type States "HoldingPizza" | "None" | "Farming"
    @within PlayerStateManager
]=]

export type States =
    | "HoldingPizza"
    | "None"
    | "Farming"

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

--[=[
    @function AttemptStateChange
    @param player Player
    @param newState string
    @return boolean
    @within PlayerStateManager
]=]
function self.AttemptStateChange(player: Player, newState: States, source : string?): boolean
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