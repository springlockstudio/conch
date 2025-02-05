--[[
Bootstraps some basic functions onto the command line.
]]

local RunService = game:GetService "RunService"

local console = require "./console"
local types = require "./types"

local IS_SERVER = RunService:IsServer()
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
			arguments = {
				{
					kind = "variadic",
					type = "any",
					description = "Arguments to be converted into strings",
				},
			},
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
			arguments = {
				{
					kind = "argument",
					name = "object",
					type = "0",
					description = "The object to be set",
				},
				{
					kind = "argument",
					name = "key",
					type = "1",
					description = "The key to attempt to set on the object",
				},
				{
					kind = "argument",
					name = "value",
					type = "2",
					description = "The value that will be set to",
				},
			},
			callback = set,
		})
	end
end
