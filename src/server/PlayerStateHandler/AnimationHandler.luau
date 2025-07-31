--[=[
    @class AnimationHandler
    @tag PlayerStateHandler
    @server
]=]

local self = {}
local Players = game:GetService("Players")

export type Animations = 
    | "Idle"
    | "Walking"
    | "PickingUp"
    | "Harvesting"
    | "ToolIdle" 

local AnimationIDs : { [string] : string | {string | number} } = {
    Idle = "rbxassetid://180435571",
    Walking = "rbxassetid://180426354",
    PickingUp = "rbxassetid://85253249744129",
    Harvesting = {
        {"rbxassetid://101558194922699",0.2},
        {"rbxassetid://136505071629868",1},
    },
    ToolIdle = "rbxassetid://109823180904833",
}

function self.Init()
    --[=[
        @prop CurrentAnimations {[Player] : string}
        @within AnimationHandler
    ]=]
    self.CurrentAnimations = {} :: { [Player] : string }

    --[=[
        @prop CurrentAnimationMethods {[Player] : { Stop: () -> (), IsPlaying: () -> boolean }}
        @within AnimationHandler
    ]=]
    self.CurrentAnimationMethods = {} :: { [Player] : { Stop: () -> (), IsPlaying: () -> boolean } }

    local function onJoin(player: Player)
        self.CurrentAnimations[player] = "Idle"
        self.CurrentAnimationMethods[player] = {
            Stop = function() end,
            IsPlaying = function() return false end
        }
    end

    Players.PlayerAdded:Connect(function(player: Player)
        onJoin(player)
    end)

    for _, player in Players:GetPlayers() do
        onJoin(player)
    end

    Players.PlayerRemoving:Connect(function(player: Player)
        self.CurrentAnimations[player] = nil
        self.CurrentAnimationMethods[player] = nil
    end)

end

local ANIM_SPEED = {
    Harvesting = 2.5
}

--[=[
    @function AnimatePlayer
    @param player Player
    @param animationType string
    @within AnimationHandler
]=]
function self.AnimatePlayer(player: Player, animationType: Animations, looped : boolean) : { Stop: () -> (), IsPlaying: () -> boolean }
    if not self.CurrentAnimations[player] then
        warn(`Player {player.Name} does not have an animation set up.`)
        return
    end

    if self.CurrentAnimations[player] == animationType then
        return self.CurrentAnimationMethods[player]
    end

    local Character = player.Character or player.CharacterAdded:Wait()
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Animator : Animator = Humanoid:FindFirstChild("Animator")

    local Animation = Instance.new("Animation")
    
    local id = AnimationIDs[animationType]

    if (type(id) == "table") then
        local rnd: number = Random.new():NextNumber()
        for i: number , data : {string | number} in id do
            if rnd <= data[2] then
                id = data[1]
                break
            end
        end
    end

    if not id then
        warn(`Animation type {animationType} is not defined.`)
        return
    end

    Animation.AnimationId = id

    local LoadedAnimation: AnimationTrack = Animator:LoadAnimation(Animation)
    LoadedAnimation.Looped = looped
    LoadedAnimation.Priority = Enum.AnimationPriority.Action
    LoadedAnimation:Play(nil,nil,ANIM_SPEED[animationType] or 1)

    self.CurrentAnimations[player :: Player] = animationType

    self.CurrentAnimations[player :: Player] = animationType
    self.CurrentAnimationMethods[player :: Player] = {
        Stop = function()
            LoadedAnimation:Stop()
            self.CurrentAnimations[player :: Player] = "Idle" :: {[Player] : string}
            self.AnimatePlayer(player, "Idle")
        end,
        IsPlaying = function()
            return self.CurrentAnimations[player] ~= "Idle"
        end,
    }

    task.spawn(function()
        if not(looped) then
            LoadedAnimation.Ended:Wait()
            self.CurrentAnimationMethods[player]:Stop()
        end
    end)

    return self.CurrentAnimationMethods[player]
end

return self
