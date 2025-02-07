local Players = game:GetService "Players"

local console = require "./console"
local context = require "./context"
local types = require "./types"

local function noop(v) return v end

local function wrap_if_not(value)
	return if type(value) == "table" then value else { value }
end

local anyT = {
	convert = noop,

	analysis = {
		kind = "argument",
		name = "any",
		type = "any",
	},
}

local stringT = {
	convert = noop,

	analysis = {
		kind = "argument",
		name = "string",
		type = "string",
	},
}

local stringsT = {
	convert = wrap_if_not,

	analysis = {
		kind = "argument",
		name = "strings",
		type = "{ string }",
	},
}

local numberT = {
	convert = noop,

	analysis = {
		kind = "argument",
		name = "number",
		type = "number",
	},
}

local numbersT = {
	convert = wrap_if_not,

	analysis = {
		kind = "argument",
		name = "numbers",
		type = "{ number }",
	},
}

local booleanT = {
	convert = noop,

	analysis = {
		kind = "argument",
		name = "boolean",
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
}

local booleansT = {
	convert = wrap_if_not,

	analysis = {
		kind = "argument",
		name = "boolean",
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
}

local tableT = {
	convert = noop,

	analysis = {
		kind = "argument",
		name = "table",
		type = "table",
	},
}

local function into_vector(value: vector | Vector3 | { number })
	if type(value) == "vector" then
		return value
	elseif typeof(value) == "table" then
		return vector.create(value[1] or 0, value[2] or 0, value[3] or 0)
	else
		error(`{value} is not valid`, 0)
	end
end

local vectorT = {
	convert = into_vector,

	analysis = {
		kind = "argument",
		name = "vector",
		type = "vector",
	},
}
local vectorsT = {
	convert = function(
		value: vector | Vector3 | { vector | Vector3 | { number } }
	)
		if type(value) == "vector" then
			return { value }
		elseif typeof(value) == "table" then
			local t = {}
			for i, v in value do
				t[i] = into_vector(v)
			end
			return t
		else
			error(`{value} is not valid`, 0)
		end
	end,

	analysis = {
		kind = "argument",
		name = "vector",
		type = "vector",
	},
}

local function map_enum<V>(
	map: { [string]: V },
	name: string?,
	description: string?
)
	return {
		convert = function(value)
			local key = tostring(value)
			if map[key] == nil then error(`{key} is not valid`, 0) end
			return map[key]
		end,

		analysis = {
			kind = "argument",
			name = name or "enum",
			description = description,
			type = "enum",
			suggestion_generator = function(text: string)
				text = text:lower()
				local suggestions = {}
				for key in map do
					if string.sub(key:lower(), 1, #text) ~= text then
						continue
					end
					table.insert(suggestions, key)
				end
				return suggestions
			end,
		},
	}
end

local function create_enum<T>(
	options: { T },
	name: string?,
	description: string?
): T
	local map = {}

	for _, value in options do
		map[tostring(value)] = value
	end

	return map_enum(map, name, description)
end

local function convert_arg_to_player(arg: string | number | "@s"): Player
	local ctx = context.get_command_context()
	if arg == "@s" then
		return ctx and ctx.executor.player or error "not executed by a player"
	elseif typeof(arg) == "number" then
		local player = assert(
			Players:GetPlayerByUserId(arg),
			`player with id {arg} is not in this server`
		)
		return player
	elseif typeof(arg) == "string" then
		local player = assert(
			Players:FindFirstChild(arg) :: Player,
			`player "{arg}" is not valid`
		)
		return player
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

local playerT = {
	convert = function(...)
		local values = { ... }

		for i, v in values do
			values[i] = convert_arg_to_player(v)
		end

		return unpack(values)
	end,

	analysis = {
		kind = "argument",
		name = "player",
		type = "Player",
		suggestion_generator = function(text: string)
			text = text:lower()
			local suggestions = {}

			if string.sub("@s", 1, #text) == text then
				table.insert(suggestions, "@s")
			end

			for _, player in Players:GetPlayers() do
				if
					string.sub(player.Name:lower(), 1, #text) == text
					or string.sub(player.DisplayName:lower(), 1, #text)
						== text
				then
					table.insert(suggestions, player.Name)
				end
			end

			return suggestions
		end,
	},
}

local playersT = {
	kind = "any",
	convert = function(...)
		local values = { ... }

		for i, v in values do
			values[i] = convert_arg_to_players(v)
		end

		return unpack(values)
	end,

	analysis = {
		kind = "argument",
		name = "players",
		type = "{ Player }",
		suggestion_generator = function(text: string)
			text = text:lower()
			local suggestions = {}

			if string.sub("@s", 1, #text) == text then
				table.insert(suggestions, "@s")
			end
			if string.sub("@a", 1, #text) == text then
				table.insert(suggestions, "@a")
			end

			for _, player in Players:GetPlayers() do
				if
					string.sub(player.Name:lower(), 1, #text) == text
					or string.sub(player.DisplayName:lower(), 1, #text)
						== text
				then
					table.insert(suggestions, player.Name)
				end
			end

			return suggestions
		end,
	},
}

local function generate_names_for_enum(enum: Enum)
	local map = {}

	for _, item: EnumItem in enum:GetEnumItems() do
		map[item.Name] = item
	end

	return map_enum(map, tostring(enum))
end

console.register_type("any", anyT)
console.register_type("string", stringT)
console.register_type("strings", stringsT)
console.register_type("number", numberT)
console.register_type("numbers", numbersT)
console.register_type("boolean", booleanT)
console.register_type("booleans", booleansT)
console.register_type("table", tableT)
console.register_type("vector", vectorT)
console.register_type("vectors", vectorsT)
console.register_type("player", playerT)
console.register_type("players", playersT)
console.register_type("userinput", generate_names_for_enum(Enum.UserInputType))

type G<T> = (name: string?, description: string?) -> T

local function generator(type: string): any
	return function(name: string?, description: string?)
		return {
			name = name,
			description = description,
			kind = "arg",
			type = type,
		}
	end
end

local function variadic<T>(argument: T): ...T
	local a: types.Type = argument :: any
	a.kind = "varargs"
	return a
end

return {

	any = generator "any" :: G<any>,
	string = generator "string" :: G<string>,
	strings = generator "strings" :: G<{ string }>,
	number = generator "number" :: G<number>,
	numbers = generator "numbers" :: G<{ number }>,
	boolean = generator "boolean" :: G<boolean>,
	booleans = generator "booleans" :: G<{ boolean }>,
	table = generator "table" :: G<{}>,
	vector = generator "vector" :: G<vector>,
	vectors = generator "vectors" :: G<{ vector }>,
	player = generator "player" :: G<Player>,
	players = generator "players" :: G<{ Player }>,

	userinput = generator "userinput" :: G<Enum.UserInputType>,

	variadic = variadic,
	enum_new = create_enum,
	enum_map = map_enum,
}
