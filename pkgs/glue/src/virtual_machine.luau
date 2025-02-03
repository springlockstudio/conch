local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ast = require("../luau_packages/ast")
local compiler = require("../luau_packages/compiler")
local vm = require("../luau_packages/vm")
local types = require("./types")
local state = require("./state")
local zap = require("./network/zap")
local user = require("./user")

local IS_SERVER = RunService:IsServer()

local vm_state = { locals = {}, upvalues = {}, instructions = {} }
local vm = vm()
local commands: { [string]: types.CommandRepresentation } = {}

local console: types.Console = {
    vm = vm,
    commands = commands,
    output = print
}

local function replicate_to_player(player: Player, representation: types.CommandRepresentation)
    local key = user.obtain_user_key(player)
    local player_user = state.users[key]

    if not player_user then return end
    if user.has_permissions(player_user, unpack(representation.permissions)) then return end

    zap.register_command.fire(player, { name = representation.name, permissions = representation.permissions })
end

local function execute(src: string)
    local user = state.local_user
    assert(user, "No local user")

    local source = buffer.fromstring(src)
    print("starting")
    local ok, result = pcall(ast, source)
    print("ast", result)

    if not ok then console.output({ kind = "error", text = tostring(result) }); return end
    
    print("compiling")
    local instructions = compiler(result, vm_state)
    print(instructions)
    vm_state.instructions = {}

    local ok, err = pcall(vm.run, instructions)

    if not ok then
        console.output({ kind = "error", text = tostring(err) })
    end
end

local function register_command(name: string, fn: (...any) -> (...any), ...: string)
    local representation: types.CommandRepresentation = {
        name = name or debug.info(fn, "n"),
        from_server = IS_SERVER,
        permissions = { ... },

        callback = fn,
        dirty_replicate = true
    }

    commands[name] = representation
    vm.commands[name] = representation.callback

    if IS_SERVER then
        for _, player in Players:GetPlayers() do
            replicate_to_player(player, representation)
        end
    end

    return representation
end

register_command("print", print)

return {
    console = console,
    register_command = register_command,
    execute = execute
}