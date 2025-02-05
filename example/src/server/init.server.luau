local conch = require(game.ReplicatedStorage.packages.conch)

conch.initiate_default_lifecycle()

conch.register_quick("meow", function()
	conch.log("normal", "mraooow")
	return true
end)

local function playeradded(player: Player)
	local user = conch.get_user(player)
	
	conch.give_roles(user, "super-user")
	
end

game.Players.PlayerAdded:Connect(playeradded)
for _, player in game.Players:GetPlayers() do
	playeradded(player)
end