local RunService = game:GetService("RunService")

local vide = require("../roblox_packages/vide")
local ast = require("../luau_packages/ast")

local state = require("./state")
local conch = require("../roblox_packages/conch_glue")
local background = require("./components/background")
local text = require("./components/text")
local flex = require("./components/flex")
local padding = require("./components/padding")
local screen = require("./components/screen")
local corner = require("./components/corner")
local textbox = require("./components/textbox")
local gap = require("./components/gap")
local theme = require("./theme")

local values = vide.values
local source = vide.source
local derive = vide.derive
local effect = vide.effect
local show = vide.show

return function()

    local function output(log)
        local logs = state.logs()
        table.insert(logs, 1, log)
        state.logs(logs)
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
        -- error(text)
    end
    
    local function warn(...)
        local text = concat(...)
        output { kind = "warn", text = text }
    end
    
    local function info(...)
        local text = concat(...)
        output { kind = "info", text = text }
    end

    local i = 0
    local function count()
        i += 1
        return i
    end

    conch.register("print", print)
    conch.register("error", error)
    conch.register("warn", warn)
    conch.register("info", info)
    conch.register("wait", task.wait)
    conch.register("count", count)
    conch.console.output = output
    
    local raw_text = source("")
    local focused = source(true)

    local syntax_error = source(false :: false | string)
    local deferred = false

    effect(function()
        local new = raw_text()
        
        if deferred then return end
        deferred = true
        RunService.RenderStepped:Once(function()
            deferred = false
            local ok, err = pcall(ast, buffer.fromstring(new))
            syntax_error(if ok then false else err)
        end)
    end)

    return screen {
        name = "Command Executor",
        display_order = 100_000,
        enabled = state.opened,

        flex():fill("horizontal"),
        padding { padding = 12 },

        background { 
            height = 50,
            corner(6),

            textbox {
                text = raw_text,
                update_text = raw_text,
                placeholder = "Enter your command",
                focused = focused,
                update_focused = focused,
                text_size = 20,
                xalignment = Enum.TextXAlignment.Left,

                enter = function(value)
                    raw_text("")
                    focused(true)
                    local ok, err = pcall(conch.execute, value)
                    if not ok then error(err) end
                end
            },

            padding { padding = 12 },
            flex():fill():vertical("center"):horizontal("left"),
        },

        show(syntax_error, function()
            return background {
                height = 24,
                layout = layout,
                color = theme.background():Lerp(theme.text_error(), 0.1),
    
                flex():fill():vertical("center"):horizontal("left"),
                padding { padding = 8 },
    
                text {
                    text = syntax_error,
                    text_size = 18,
                    text_style = "error",
                    xalignment = Enum.TextXAlignment.Left,
                }
            }
        end),

        gap { height = 4 },

        values(state.logs, function(log: conch.Log, layout: number)
            return background {
                height = 24,
                layout = layout,
                color = theme.background():Lerp(
                    if log.kind == "normal" then theme.text()
                    elseif log.kind == "info" then theme.text_info()
                    elseif log.kind == "warn" then theme.text_warn()
                    elseif log.kind == "error" then theme.text_error()
                    else theme.text(),
                    0.1
                ),
    
                flex():fill():vertical("center"):horizontal("left"),
                padding { padding = 8 },
    
                text {
                    text = log.text,
                    text_size = 18,
                    text_style = log.kind,
                    xalignment = Enum.TextXAlignment.Left,
                }
            }
        end)
    }
end