opt remote_scope = "conch"
opt casing = "snake_case"
opt server_output = "./network/server.luau"
opt client_output = "./network/client.luau"


--[[
This event gives the player a user.

]]
event create_user = {
    from: Server,
    type: Reliable,
    call: SingleSync,
    data: struct {
        name: string,
        id: string,
    }
}

--[[
This event is fired by the server whenever a user has their roles updated. Conch
would automatically based on this information, figure out any data that needs to
be removed.

]]
event update_user_roles = {
    from: Server,
    type: Reliable,
    call: SingleSync,
    data: struct {
        id: string,
        roles: string[],
    }
}


--[[
This event is fired by the server whenever the permissions a role gives has been
updated.
]]
event update_role_permissions = {
    from: Server,
    type: Reliable,
    call: SingleSync,
    data: struct {
        role: string,
        permissions: string[] 
    }
}

--[[
The server registers a new command that requires certain permissions to run.
Clients would be able to invoke the command and receive results back from it.
]]
event register_command = {
    from: Server,
    type: Reliable,
    call: SingleSync,
    data: struct {
        name: string,
        permissions: string[],   
    }
}

--[[
Invokes a server command and returns an invocation_id which will be listened to
in order to receive a result.
]]
event invoke_server_command = {
    from: Client,
    type: Reliable,
    call: ManyAsync,
    data: struct {
        name: string,
        invocation_id: u32,
        arguments: unknown[]
    }
}

--[[
Receives a result from the server for a specific invocation id.
]]
event receive_server_results = {
    from: Server,
    type: Reliable,
    call: SingleSync,
    data: struct {
        invocation_id: u32,
        results: enum "type" {
            ok { results: unknown },
            err {}
        }
    }
}

--[[
Sends a server log to the player.
]]
event log = {
    from: Server,
    type: Reliable,
    call: SingleSync,
    data: struct {
        kind: enum { normal, info, warn, error },
        text: string
    }
}