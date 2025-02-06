local Players = game:GetService "Players"

local context = require "./context"
local types = require "../luau_packages/types"
local arguments = {}

local function noop(...) return ... end

type ArgumentData = {
	convert: (consume: (any) -> ()) -> any,
	analysis: types.AnalysisCommandArgument,
}

function arguments.any(name: string?, description: string?): any
	return {
		convert = noop,

		analysis = {
			kind = "argument",
			name = name or "any",
			description = description,
			type = "any",
		},
	} :: any
end

function arguments.string(name: string?, description: string?): string
	return {
		convert = noop,

		analysis = {
			kind = "argument",
			name = name or "string",
			description = description,
			type = "string",
		},
	} :: any
end

function arguments.number(name: string?, description: string?): number
	return {
		convert = noop,

		analysis = {
			kind = "argument",
			name = name or "number",
			description = description,
			type = "number",
		},
	} :: any
end

function arguments.boolean(name: string?, description: string?): boolean
	return {
		convert = noop,

		analysis = {
			kind = "argument",
			name = name or "boolean",
			description = description,
			type = "boolean",

			suggestion_generator = function(text: string)
				local suggestions = {}

				if string.sub("true", 1, #text) == text then
					table.insert(suggestions, "true")
				end

				if string.sub("false", 1, #text) == text then
					table.insert(suggestions, "false")
				end

				return suggestions
			end,
		},
	} :: any
end

function arguments.table(name: string?, description: string?): {}
	return {
		convert = noop,

		analysis = {
			kind = "argument",
			name = name or "table",
			description = description,
			type = "table",
		},
	}
end

function arguments.enum<T>(options: { T }, name: string?, description: string?): T
	local map = {}

	for _, value in options do
		map[tostring(value)] = value
	end

	return {
		convert = function(...)
			local values = {}
			for i = 1, select("#", ...) do
				local key = tostring((select(i, ...)))
				if map[key] == nil then error(`{key} is not valid`, 0) end
				values[i] = map[key]
			end
			return unpack(values)
		end,

		analysis = {
			kind = "argument",
			name = name or "enum",
			description = description,
			type = "enum",
			suggestion_generator = function(text: string)
				local suggestions = {}
				for key in map do
					if string.sub(key, 1, #text) ~= text then continue end
					table.insert(suggestions, key)
				end
				return suggestions
			end,
		},
	} :: any
end

local function convert_arg_to_player(arg: string | number | "@s"): Player
	local ctx = context.get_command_context()
	if arg == "@s" then
		return ctx and ctx.executor.player or error "not executed by a player"
	elseif typeof(arg) == "number" then
		return assert(
			Players:GetPlayerByUserId(arg),
			`player with id {arg} is not in this server`
		)
	elseif typeof(arg) == "string" then
		return assert(
			Players:FindFirstChild(arg) :: Player,
			`player "{arg}" is not valid`
		)
	else
		error(`unknown arg {arg}`)
	end
end

local function convert_arg_to_players(
	arg: string | number | "@s" | "@a" | { any }
)
	if arg == "@a" then
		return Players:GetPlayers()
	elseif typeof(arg) == "table" then
		local copy = table.clone(arg)

		for idx, plr in copy do
			copy[idx] = convert_arg_to_player(plr)
		end

		return copy
	else
		return { convert_arg_to_player(arg) }
	end
end

function arguments.player<T>(name: string?, description: string?): Player
	return {
		convert = function(...)
			local values = { ... }

			for i, v in values do
				values[i] = convert_arg_to_player(v)
			end

			return unpack(values)
		end,

		analysis = {
			kind = "argument",
			name = name or "player",
			description = description,
			type = "Player",
			suggestion_generator = function(text: string)
				local suggestions = {}

				if string.sub("@s", 1, #text) == text then
					table.insert(suggestions, "@s")
				end

				for _, player in Players:GetPlayers() do
					if
						string.sub(player.Name, 1, #text) == text
						or string.sub(player.DisplayName, 1, #text) == text
					then
						table.insert(suggestions, player.Name)
					end
				end

				return suggestions
			end,
		},
	} :: any
end

function arguments.players<T>(name: string?, description: string?): { Player }
	return {
		convert = function(...)
			local values = { ... }

			for i, v in values do
				values[i] = convert_arg_to_players(v)
			end

			print(values)
			return unpack(values)
		end,

		analysis = {
			kind = "argument",
			name = name or "players",
			description = description,
			type = "{ Player }",
			suggestion_generator = function(text: string)
				local suggestions = {}

				if string.sub("@s", 1, #text) == text then
					table.insert(suggestions, "@s")
				end
				if string.sub("@a", 1, #text) == text then
					table.insert(suggestions, "@a")
				end

				for _, player in Players:GetPlayers() do
					if
						string.sub(player.Name, 1, #text) == text
						or string.sub(player.DisplayName, 1, #text) == text
					then
						table.insert(suggestions, player.Name)
					end
				end

				return suggestions
			end,
		},
	} :: any
end

function arguments.variadic<T>(argument: T): ...T
	local a: ArgumentData = argument :: any
	return {
		variadic = true,
		convert = a.convert,
		analysis = {
			kind = "variadic",
			description = a.analysis.description,
			type = a.analysis.type,
			suggestion_generator = a.analysis.suggestion_generator,
		},
	}
end

return arguments
