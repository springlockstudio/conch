local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ast = require("../roblox_packages/ast")
local compiler = require("../roblox_packages/compiler")
local vm = require("../roblox_packages/vm")
local types = require("./types")
local state = require("./state")
local user = require("./user")
local intel = require("../roblox_packages/intel")
local ctypes = require("../roblox_packages/types")
local net = require("./net")

local IS_SERVER = RunService:IsServer()

local vm_state = { locals = {}, upvalues = {}, instructions = {} }
local vm = vm()
local commands: { [string]: types.CommandRepresentation } = {}

local console: types.Console = {
    vm = vm,
    commands = commands,
    output = print,
}

local function replicate_to_player(player: Player, representation: types.CommandRepresentation)
    local key = user.obtain_user_key(player)
    local player_user = state.users[key]

    if not player_user then return end
    if not user.has_permissions(player_user, unpack(representation.permissions)) then return end

	net.server.fire_register_command(player, { name = representation.name, permissions = representation.permissions })
end

local busy = false

local function execute(ast: ast.Result)
    assert(ast.status ~= "pending", "unfinished block")
    assert(not busy, "already executing!")
    console.output({ kind = "info", text = `> {ast.src}` })
    if ast.status == "error" then
        return console.output({ kind = "error", text = ast.why })
    end
    busy = true

    local instructions = compiler(ast.value, vm_state)
    vm_state.instructions = {}

    local function on_complete(ok: boolean, result: number | string, ...: unknown)
        if not ok then
            console.output({ kind = "error", text = tostring(result) })
        end
    end

    on_complete(pcall(vm.run, instructions))
    busy = false
end

local function register_command(name: string, info: {
    permissions: { types.Permission },
    description: string?,
    arguments: { ctypes.AnalysisCommandArgument | ctypes.AnalysisCommandVariadic }?,
    callback: (...any) -> (...any)
})
    local representation: types.CommandRepresentation = {
        name = name or debug.info(fn, "n"),
        from_server = IS_SERVER,
        permissions = info.permissions or {},
        type_info = {
            kind = "command",
            name = name,
            description = info.description or false,
            arguments = info.arguments or { { kind = "variadic", type = "any", enum = false, description = false } }
        },

        callback = info.callback,
        dirty_replicate = true
    }

    commands[name] = representation
    vm.commands[name] = representation.callback

    if IS_SERVER then
        for _, player in Players:GetPlayers() do
            -- print("replicating to player", player)
            replicate_to_player(player, representation)
        end
    end

    return representation
end

local function register(name: string, fn: (...any) -> (...any), ...: string)
    register_command(name, {
        name = name,
        callback = fn,
        permissions = { ... }
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

    

    return intel.generate_analysis_info({
        code = src,
        where = where,

        variables = combined_variables,
        commands = analyze_commands
    })
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