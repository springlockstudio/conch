local Players = game:GetService "Players"
local RunService = game:GetService "RunService"

local ast = require "../luau_packages/ast"
local compiler = require "../luau_packages/compiler"
local create_vm = require "../luau_packages/vm"
local ctypes = require "../luau_packages/types"
local intel = require "../luau_packages/intel"
local net = require "./net"
local state = require "./state"
local types = require "./types"
local user = require "./user"

local IS_SERVER = RunService:IsServer()

local vm_state = { locals = {}, upvalues = {}, instructions = {} }
local vm = create_vm() :: ctypes.VirtualMachine
local commands: { [string]: types.CommandRepresentation } = {}

local console: types.Console = {
	vm = vm,
	commands = commands,
	output = print,
}

local function replicate_to_player(
	player: Player,
	representation: types.CommandRepresentation
)
	local key = user.obtain_user_key(player)
	local player_user = state.users[key]

	if not player_user then return end
	if
		not user.has_permissions(
			player_user,
			unpack(representation.permissions)
		)
	then
		return
	end

	net.server.fire_register_command(
		player,
		{ name = representation.name, permissions = representation.permissions }
	)
end

local busy = false

local function execute(text: string)
	local ast = ast(text, false)

	assert(ast.status ~= "pending", "unfinished block")
	assert(not busy, "already executing!")

	console.output { kind = "info", text = `> {ast.src}` }
	if ast.status == "error" then
		return console.output { kind = "error", text = ast.why }
	end
	busy = true

	local instructions = compiler(ast.value, vm_state)
	vm_state.instructions = {}

	local function on_complete(
		ok: boolean,
		result: number | string,
		...: unknown
	)
		if not ok then
			console.output { kind = "error", text = tostring(result) }
		end
	end

	on_complete(pcall(vm.run, instructions))
	busy = false
end

local function register_command<T...>(
	name: string,
	info: {
		permissions: { types.Permission },
		description: string?,
		arguments: () -> T...,
		callback: (T...) -> ...any,
	}
)
	local arguments: {
		{
			variadic: true?,
			convert: (...any) -> any,
			analysis: ctypes.AnalysisCommandArgument,
		}
	} =
		{ info.arguments() } :: { any }

	local analysis_arguments =
		{
			{ kind = "variadic" } :: ctypes.AnalysisCommandVariadic,
		} :: { ctypes.AnalysisCommandArgument | ctypes.AnalysisCommandVariadic }

	for index, argument in arguments do
		analysis_arguments[index] = argument.analysis
	end

	local representation: types.CommandRepresentation = {
		name = name,
		permissions = info.permissions,
		type_info = {
			kind = "command",
			name = name,
			description = info.description,
			arguments = analysis_arguments,
		},

		callback = info.callback,
		dirty_replicate = true,
	}

	commands[name] = representation
	vm.commands[name] = function(...)
		local custom = { ... }

		local function move(from: number, ...)
			for i = 0, select("#", ...) - 1 do
				custom[i + from] = select(i + 1, ...)
			end
		end

		for idx, argument in arguments do
			if argument.variadic then
				move(idx, argument.convert(select(idx, ...)))
				break
			else
				custom[idx] = argument.convert((select(idx, ...)))
			end
		end

		return info.callback(unpack(custom))
	end

	if IS_SERVER then
		for _, player in Players:GetPlayers() do
			-- print("replicating to player", player)
			replicate_to_player(player, representation)
		end
	end

	return representation
end

local function register(name: string, fn: (...any) -> ...any, ...: string)
	register_command(name, {
		name = name,
		callback = fn,
		arguments = function() end :: any,
		permissions = { ... },
	})
end

local function analyze(src: string, where: number): ctypes.AnalysisInformation
	local combined_variables = {}
	local analyze_commands = {}

	local index = 1
	for name, command in commands do
		analyze_commands[index] = command.type_info

		index += 1
	end

	for global, value in vm.globals do
		combined_variables[global] = value
	end

	for index, key in vm_state.locals do
		combined_variables[key] = vm.locals[index]
	end

	return intel.generate_analysis_info {
		code = src,
		where = where,

		variables = combined_variables,
		commands = analyze_commands,
	}
end

return {
	console = console,
	register_quick = register,
	register_command = register_command,
	replicate_to_player = replicate_to_player,
	execute = execute,
	analyze = analyze,

	ast = ast,
}
