local ContextActionService = game:GetService "ContextActionService"
local Players = game:GetService "Players"

local app = require "./app"
local opened = require("./state").opened
local conch = require "../roblox_packages/conch_glue"
local vide = require "../roblox_packages/vide"

return {

	app = app,
	mount = function()
		return vide.mount(app, Players.LocalPlayer:WaitForChild "PlayerGui")
	end,
	opened = opened,

	bind_to = function(input: Enum.KeyCode | Enum.UserInputType)
		ContextActionService:BindAction("Trigger Conch", function(_, state)
			if state == Enum.UserInputState.Begin then opened(not opened()) end
		end, false, input)
	end,

	conch = conch,
}
