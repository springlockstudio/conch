--!strict
local Players = game:GetService("Players")

local user = require("./user")
local state = require("./state")
local types = require("./types")
local virtual_machine = require("./virtual_machine")
local zap = require("./network/zap")

local LOCALPLAYER = Players.LocalPlayer

local invocation_id = 0

local function create_local_user(
    data: { name: string, id: string }
)
    local self = user.create_user { name = data.name, player = LOCALPLAYER :: Player | false }
    state.local_user = self
end

local function update_user_roles(
    data: { id: string, roles: { string } }
)   
    local user = state.users[data.id]
    assert(user, "local user does not exist")

    user.roles = data.roles
end

local function update_role_permissions(
    data: { role: string, permissions: { string } }
)
    state.roles[data.role] = data.permissions
end

local function register_command(
    data: { name: string, permissions: { string } }
)
    virtual_machine.register_command(data.name, function(...)
        local thread = coroutine.running()
        invocation_id += 1
        state.continuations[invocation_id] = thread

        zap.invoke_server_command.fire {
            name = data.name,
            invocation_id = invocation_id,
            arguments = { ... }
        }
        
        local data = coroutine.yield()

        if data.type == "ok" then
            return unpack(data.results)
        else
            error("something went wrong on the server")
        end
    end, unpack(data.permissions))
end

local function receive_server_results(
    data: { invocation_id: number, results: types.Result }
)
    local thread = state.continuations[data.invocation_id]
    if not thread then return end
    coroutine.resume(thread, data.results)
    state.continuations[data.invocation_id] = nil
end

return {
    create_local_user = create_local_user,
    update_user_roles = update_user_roles,
    update_role_permissions = update_role_permissions,
    register_command = register_command,
    receive_server_results = receive_server_results
}