local background = require "./components/background"
local conch = require "../roblox_packages/conch_glue"
local corner = require "./components/corner"
local flex = require "./components/flex"
local gap = require "./components/gap"
local loading = require "./components/loading"
local padding = require "./components/padding"
local screen = require "./components/screen"
local state = require "./state"
local suggestion = require "./components/suggestion"
local text = require "./components/text"
local textbox = require "./components/textbox"
local theme = require "./theme"
local vide = require "../roblox_packages/vide"

local values = vide.values
local source = vide.source
local derive = vide.derive
local show = vide.show
local changed = vide.changed

local STARTUP_TEXT = [[
Conch	indev release.
This work is made available under the MIT license. You can view the license by running `license`.]]

return function()
	local function output(log)
		local logs = state.logs()
		table.insert(logs, 1, log)
		table.remove(logs, 100)
		state.logs(logs)
	end

	conch.console.output = output

	for _, s in string.split(STARTUP_TEXT, "\n") do
		output { kind = "normal", text = s }
	end

	conch.register("clear", {
		description = "Clears the console.",
		permissions = {},
		arguments = function() end,
		callback = function() state.logs {} end,
	})

	local raw_text = source ""
	local working = source(false)
	local focused = source(true)
	local cursor_position = source(0)
	local absolute_position = source(Vector2.zero)
	local pending = source()

	local input = derive(function()
		if pending() then
			return pending().src .. raw_text()
		else
			return raw_text()
		end
	end)

	local syntax_error = derive(function()
		local status = conch.parse(input())
		return if status.status == "error" then status.why else nil
	end)

	local analysis = derive(function()
		local result = conch.analyze(input(), cursor_position() - 1)

		return result
	end)

	return screen {
		name = "Command Executor",
		display_order = 100_000,
		enabled = state.opened,

		flex():fill("horizontal"):vertical "bottom",
		padding { padding = 12 },

		background {
			height = 50,
			auto = Enum.AutomaticSize.Y,
			layout = 1,
			corner(6),

			show(
				working,
				function()
					return loading {
						speed = 6,
						text_size = 20,
						xalignment = Enum.TextXAlignment.Left,
					}
				end,
				function()
					return textbox {
						text = raw_text,
						update_text = raw_text,
						placeholder = "Enter your command",
						text_size = 20,
						xalignment = Enum.TextXAlignment.Left,
						multiline = function()
							if pending() then
								local status = conch.parse(
									pending().src .. raw_text(),
									"yield"
								)
								return status.status == "pending"
							else
								local status = conch.parse(raw_text(), "yield")
								return status.status == "pending"
							end
						end,

						enter = function(value)
							raw_text ""
							focused(true)

							if pending() then
								pending(pending().append(value))
							else
								pending(conch.parse(value, true))
							end

							if pending().status ~= "pending" then
								local tree = pending()
								working(true)
								pending(nil)
								conch.execute(value)
								working(false)
							end
						end,

						focused = focused,
						update_focused = focused,

						{
							CursorPosition = cursor_position,
							changed("CursorPosition", cursor_position),
						},
					}
				end
			),

			padding { padding = 12 },
			flex():fill():vertical("center"):horizontal "left",

			changed("AbsolutePosition", absolute_position),
		},

		show(analysis, function()
			return vide.create "Folder" {
				suggestion {
					x = function()
						return cursor_position() * 10 + absolute_position().X
					end,
					y = function() return absolute_position().Y - 4 end,

					analyzing = function() return analysis().analyzing end,
					suggestions = function() return analysis().suggestions end,
				},
			}
		end),

		values(function()
			local err = syntax_error()
			local result = table.clone(analysis() and analysis().logs or {})
			if err then table.insert(result, { kind = "error", text = err }) end
			return result
		end, function(log, layout)
			return background {
				height = 24,
				auto = Enum.AutomaticSize.Y,
				layout = function() return -layout() - 1 end,
				color = theme.background():Lerp(
					if log.kind == "normal"
						then theme.text()
						elseif log.kind == "info" then theme.text_info()
						elseif log.kind == "warn" then theme.text_warn()
						elseif log.kind == "error" then theme.text_error()
						else theme.text(),
					0.1
				),

				flex():fill():vertical("center"):horizontal "left",
				padding { x = 8, y = 3 },

				text {
					text = log.text,
					text_size = 18,
					text_style = log.kind,
					xalignment = Enum.TextXAlignment.Left,
				},
			}
		end),

		gap { height = 4 },

		values(state.logs, function(log: conch.Log, layout: () -> number)
			return background {
				height = 24,
				auto = Enum.AutomaticSize.Y,
				layout = function() return -layout() - 1 end,
				color = theme.background():Lerp(
					if log.kind == "normal"
						then theme.text()
						elseif log.kind == "info" then theme.text_info()
						elseif log.kind == "warn" then theme.text_warn()
						elseif log.kind == "error" then theme.text_error()
						else theme.text(),
					0.1
				),

				flex():fill():vertical("center"):horizontal "left",
				padding { x = 8, y = 3 },

				text {
					text = log.text,
					text_size = 18,
					text_style = log.kind,
					xalignment = Enum.TextXAlignment.Left,
				},
			}
		end),
	}
end
