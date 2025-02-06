--[[
Bootstraps some basic functions onto the command line.
]]

local RunService = game:GetService "RunService"

local arg = require "./arguments"
local console = require "./console"
local types = require "./types"

local IS_CLIENT = RunService:IsClient()

return function()
	local function output(t: types.Log) console.console.output(t) end

	local function concat(...: string)
		local t = { ... }
		for i, v in t do
			t[i] = tostring(v)
		end
		return table.concat(t, " ")
	end

	local function print(...)
		local text = concat(...)
		output { kind = "normal", text = text }
	end

	local function error(...)
		local text = concat(...)
		output { kind = "error", text = text }
		error(text, 0)
	end

	local function warn(...)
		local text = concat(...)
		output { kind = "warn", text = text }
	end

	local function info(...)
		local text = concat(...)
		output { kind = "info", text = text }
	end

	local function set(t: any, key: any, value: any) t[key] = value end

	-- print("registering commands")
	if IS_CLIENT then
		console.register_command("print", {
			permissions = {},
			description = "Converts the given arguments into a string and sends it to the output",
			arguments = function()
				--
				return arg.variadic(arg.any("any", "arguments"))
			end,
			callback = print,
		})
		console.register_quick("error", error)
		console.register_quick("warn", warn)
		console.register_quick("info", info)
		console.register_quick("vector", vector.create)
		console.register_quick("set", set)
		console.register_command("set", {
			permissions = {},
			description = "Attempts to set the given key and value onto the given object",
			arguments = function()
				return arg.any("object", "the object to set"),
					arg.any("key", "key of the object"),
					arg.any("value", "the value to set it to")
			end,
			callback = set,
		})
	end
end
