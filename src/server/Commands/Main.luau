local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Conch = require(ReplicatedStorage.Packages.conch)
Conch.initiate_default_lifecycle()

local function onJoin(player : Player)
	local user = Conch.get_user(player)

	if (player:IsInGroup(16588224)) and (player:GetRankInGroup(16588224) >= 250) then
		Conch.give_roles(user, "super-user")
	end
end

Conch.register("kick", {
	description = "Kicks the given player from the server",
	permissions = { "kick-player" },
	arguments = function()
		return
			Conch.args.player("player", "The player that should be kicked from the server"),
			Conch.args.string("reason", "The reason why the player has been kicked from the user.")
	end,

	callback = function(player : Player, reason : string) -- typechecked!
		player:Kick(reason)
	end
})

local GetProfile = require(script.Parent.Parent.DataManipulation.GetProfile)
local HttpService = game:GetService("HttpService")

Conch.register("displaydata", {
	description = "Displays data for the given player",
	permissions = { "view-player-data" },
	arguments = function()
		return
			Conch.args.player("player", "The player whose data should be displayed")
	end,

	callback = function(player : Player) -- typechecked!
		Conch.log("info", "Displaying data for player: " .. player.Name)
		local data = GetProfile.GetProfile(player).Data
		Conch.log("info", HttpService:JSONEncode(data))
	end
})

Conch.register("displaystats", {
	description = "Displays statistics for the given player",
	permissions = { "view-player-specific-stat" },
	arguments = function()
		return
			Conch.args.player("player", "The player whose data should be displayed"),
			Conch.args.string("stat", "The statistics to display")
	end,

	callback = function(player : Player, stat : string) -- typechecked!
		Conch.log("info", "Displaying data for player: " .. player.Name)
		local data: any = GetProfile.GetProfile(player).Data[stat]
		Conch.log("info", HttpService:JSONEncode(data))
	end
})


Players.PlayerAdded:Connect(onJoin)

return {}