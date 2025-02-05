local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ui = require(ReplicatedStorage.packages.ui)
local vide = require(ReplicatedStorage.packages.vide)
local conch = require(ReplicatedStorage.packages.conch)

ui.opened(true)
conch.register_default_commands()
conch.initiate_default_lifecycle()

vide.mount(ui.app, game.Players.LocalPlayer.PlayerGui)
print("mounted")