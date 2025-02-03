--[[
Bootstraps some basic functions onto the command line.
]]

local virtual_machine = require("./virtual_machine")
local types = require("./types")

return function()

    local function output(t: types.Log)
        virtual_machine.console.output(t)
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

    virtual_machine.register_command("print", print)
    virtual_machine.register_command("error", error)
    virtual_machine.register_command("warn", warn)
    virtual_machine.register_command("info", info)
    virtual_machine.register_command("vector", vector.create)
    virtual_machine.register_command("set", set)

end