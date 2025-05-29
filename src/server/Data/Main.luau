--[=[
    @class ProfileService Main
    None of the functions in this module should be called directly, this is just required to initialize the profile service.
    @server
]=]
local module = {}

local Players = game:GetService("Players")

local ProfileStore = require(script.Parent.ProfileStore)
local PROFILE_TEMPLATE = require(script.Parent.Template)

export type Profile = typeof(ProfileStore:StartSessionAsync())

local PlayerStore = ProfileStore.New("PlayerData(5/28/2025)", PROFILE_TEMPLATE)
local Profiles : {[Player] : Profile} = require(script.Parent.ProfileCache)

--[=[
    @function PlayerAdded
    Initializes a player profile when they join the game.
    @within ProfileService Main
    @server
]=]
local function PlayerAdded(player)

    local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
        Cancel = function()
            return player.Parent ~= Players
        end
    })

    if profile ~= nil then

        profile:AddUserId(player.UserId)
        profile:Reconcile()

        profile.OnSessionEnd:Connect(function()
            Profiles[player] = nil
            player:Kick(`Profile session end - Please rejoin`)
        end)

        if player.Parent == Players then
            Profiles[player] = profile
            print(`Profile loaded for {player.DisplayName}!`)
        else
            profile:EndSession()
        end

    else
        player:Kick(`Profile load fail - Please rejoin`)
    end

end

local function PlayerRemoving(player)
    local profile = Profiles[player]
    if profile ~= nil then
        profile:EndSession()
    end
end

local function onServerStart()
    for _, player in Players:GetPlayers() do
        PlayerAdded(player)
    end
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)

onServerStart()

return module