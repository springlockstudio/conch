local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local user = require("./user")
local state = require("./state")
local types = require("./types")
local client = require("./client")
local bootstrap = require("./bootstrap")
local console = require("./console")
local ast = require("../luau_packages/ast")
local net = require("./net")

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
		net.server.fire_update_role_perms(role, { ... })
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

local function get_command_context(): CommandContext?
    return state.command_context[coroutine.running()]
end

local function initiate_user_replication(user: types.UserPublic)
    for _, command in console.console.commands do
        if not has_permissions(user, unpack(command.permissions)) then continue end

		net.server.fire_register_command(user.player, {
			name = command.name,
			permissions = command.permissions
		})
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
    data: net.InvokeCommandPacket
)
    local user = get_user(player)
    local command = console.console.commands[data.name]

    local function fail()
		net.server.fire_failed_invoke_reply(player, data.invoke_id)
    end

    if not command or not user then return fail() end
    if not has_permissions(user, unpack(command.permissions)) then return fail() end

    local pop = create_command_context(user, data.invoke_id)

    local function handle(ok: boolean, ...: any)
        pop()
        if not ok then warn(...); return fail() end
		
		return net.server.fire_successful_invoke_reply(player, data.invoke_id, { ... })
    end

    return handle(pcall(command.callback, unpack(data.args)))
end

local function resend_new_commands(user: types.User)
    if not user.dirty then return end

    for _, cmd in console.console.commands do
        console.replicate_to_player(user.player, cmd)
    end

    user.dirty = false
end

local function initiate_default_lifecycle()

    if IS_CLIENT then
        -- print("connected events")
		net.client.init()
		
		net.client.on_command_registered(client.register_command)
		net.client.on_invoke_reply(client.receive_server_results)
		net.client.on_log_received(client.log)
		net.client.on_user_info_received(client.create_local_user)
		net.client.on_role_info_received(client.update_role_permissions)
		net.client.on_user_roles_update(client.update_user_roles)

        -- RunService.Heartbeat:Connect(zap.send_events)
    elseif IS_SERVER then
		net.server.init()
		
        -- print("initiated lifecycle")
        Players.PlayerAdded:Connect(get_user)
        Players.PlayerRemoving:Connect(disconnect_user_for_player)
        FOREACH(Players:GetPlayers(), get_user)
        FOREACH(Players:GetPlayers(), function(player)
            resend_new_commands(get_user(player))
        end)
		
		net.server.on_command_invoke(invoke_server_command)
		
        -- RunService.Heartbeat:Connect(zap.send_events)
        RunService.Heartbeat:Connect(function()
            for _, user in state.users do
                resend_new_commands(user)
            end
        end)

    end
end

return {

    parse = ast,
    execute = function(ast: ast.Result)
        local local_user = state.local_user
        assert(IS_CLIENT, "cannot run commands outside of the client")
        assert(local_user, "unable to run commands without a local user")

        local fn = console.execute(ast)

        return function()
            local pop = create_command_context(user, invocation_id)
            fn()
            pop()
        end
    end,

    register = function(name: string, fn: (...any) -> (...any), ...: string)
        console.register_command(name, fn, ...)
    end,

    initiate_default_lifecycle = initiate_default_lifecycle,
    has_permissions = user.has_permissions,
    set_role_permissions = set_role,

    give_roles = user.give_roles,
    remove_roles = user.remove_roles,
    get_user = get_user,

    get_command_context = get_command_context,

    log = function(kind: "warn" | "info" | "error" | "normal", text: string)
        if IS_SERVER then
            local context = state.command_context[coroutine.running()]
            if not context then return end
            local player = context.executor.player
            if not player then return end
            zap.log.fire(player, { kind = kind, text = text })
        else
            console.console.output({ kind = kind, text = text })
        end
    end,

    register_default_commands = bootstrap,

    console = console.console,
    analyze = console.analyze,

    _ = {

        obtain_intellisense = function()

        end,

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