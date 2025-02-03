--[[
Bootstraps some basic functions onto the command line.
]]

local RunService = game:GetService("RunService")

local console = require("./console")
local types = require("./types")

local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()

return function()

    local function output(t: types.Log)
        console.console.output(t)
    end

    local function concat(...: string)
        local t = { ... }
        for i, v in t do t[i] = tostring(v) end
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

    local function set(t: any, key: any, value: any)
        t[key] = value
    end

    -- print("registering commands")
    if IS_CLIENT then
        console.register_command("print", print)
        console.register_command("error", error)
        console.register_command("warn", warn)
        console.register_command("info", info)
        console.register_command("vector", vector.create)
        console.register_command("set", set)
    end

end