local conch = require "../roblox_packages/conch_glue"
local vide = require "../roblox_packages/vide"

local source = vide.source

return {
	opened = source(false),

	logs = source({} :: { conch.Log }),
}
