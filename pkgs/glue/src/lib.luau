local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local user = require("./user")
local state = require("./state")
local types = require("./types")
local client = require("./client")
local virtual_machine = require("./virtual_machine")
local zap = require("./network/zap")

export type Log = types.Log
export type CommandContext = types.CommandContext

local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()

local create_user = user.create_user
local disconnect_user = user.disconnect_user
local has_permissions = user.has_permissions

local function FOREACH<K, V>(t: { [K]: V }, fn: (value: V, key: K) -> ())
    for key, value in t do
        fn(value, key)
    end
end

local function set_role(role: types.Role, ...: types.Permission)
    state.roles[role] = { ... }
    
    if IS_SERVER then 
        zap.update_role_permissions.fire_all({ role = role, permissions = { ... } })
    end
end

local function create_command_context(user: types.User, invocation_id: number | false)
    assert(not state.command_context[coroutine.running()], "there is already a command context for this thread")
    state.command_context[coroutine.running()] = {
        executor = user,
        invocation_id = invocation_id
    }

    return function()
        state.command_context[coroutine.running()] = nil
    end
end

local function initiate_user_replication(user: types.UserPublic)
    for _, command in virtual_machine.console.commands do
        if not has_permissions(user, unpack(command.permissions)) then continue end

        zap.register_command.fire(
            user.player, { name = command.name, permissions = command.permissions }
        )
    end
end

local function get_user(key: Player | string)
    if typeof(key) == "string" then
        local user_key = user.obtain_user_key(false, key)
        local self = state.users[user_key]
    
        return if not self then
            create_user({ name = user_key, player = false })
        else self
    else
        local user_key = user.obtain_user_key(key, key.DisplayName)
        local self = state.users[user_key]
    
        if not self then
            local user = create_user { name = key.DisplayName, player = key }
            initiate_user_replication(user)
            return user
        else
            return self
        end
    end
end

local function disconnect_user_for_player(player: Player)
    local key = user.obtain_user_key(player, player.DisplayName)
    local self = state.users[key]

    if not self then return end

    disconnect_user(self)
end

local function invoke_server_command(
    player: Player,
    data: {
        name: string,
        invocation_id: number,
        arguments: { unknown }
    }
)
    local user = get_user(user.obtain_user_key(player))
    local command = virtual_machine.console.commands[data.name]

    local function fail(): never
        zap.receive_server_results.fire(
            player, { invocation_id = data.invocation_id, results = { type = "err" } }
        )
    end

    if not command or not user then return fail() end
    if not has_permissions(user, unpack(command.permissions)) then return fail() end

    local pop = create_command_context()

    local function handle(ok: boolean, ...: any)
        pop()
        if not ok then warn(...); return fail() end
        return zap.receive_server_results.fire(
            player,
            { invocation_id = data.invocation_id, results = { type = "ok", results = { ... } }}
        )
    end

    return handle(pcall(command.callback, unpack(data.arguments)))

end

local function initiate_default_lifecycle()
    
    Players.PlayerAdded:Connect(get_user)
    Players.PlayerRemoving:Connect(disconnect_user_for_player)
    FOREACH(Players:GetPlayers(), create_user_for_player)

    if IS_CLIENT then
        zap.create_user.set_callback(client.create_local_user)
        zap.receive_server_results.set_callback(client.receive_server_results)
        zap.register_command.set_callback(client.register_command)
        zap.update_role_permissions.set_callback(client.update_role_permissions)
        zap.update_user_roles.set_callback(client.update_user_roles)
    elseif IS_SERVER then
        zap.invoke_server_command.set_callback(invoke_server_command)
    end
end

return {

    execute = function(src: string)
        local local_user = state.local_user
        assert(IS_CLIENT, "cannot run commands outside of the client")
        assert(local_user, "unable to run commands without a local user")

        local pop = create_command_context(user, invocation_id)
        virtual_machine.execute(src)
        pop()
    end,

    register = function(name: string, fn: (...any) -> (...any), ...: string)
        virtual_machine.register_command(name, fn, ...)
    end,

    initiate_default_lifecycle = initiate_default_lifecycle,
    has_permissions = user.has_permissions,
    set_role = set_role,

    console = virtual_machine.console,

    _ = {
        create_user = user.create_user,
        get_user = user.get_user,
        disconnect_user = user.disconnect_user,
        create_local_user = function()
            local user = get_user("local")
            state.local_user = user
            return user
        end
    },
}