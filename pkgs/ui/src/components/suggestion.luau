
local vide = require("../../roblox_packages/vide")
local background = require("./background")
local text = require("./text")
local flex = require("./flex")
local container = require("./container")
local padding = require("./padding")
local screen = require("./screen")
local corner = require("./corner")
local textbox = require("./textbox")
local gap = require("./gap")
local theme = require("../theme")

local show = vide.show
local values = vide.values

export type AnalysisSuggestion = {
    name: string,
    type: string,

    replace: vector,
    with: string,
}

export type AnalysisCommandArgument = {
    kind: "argument",
    name: string,
    description: string | false,
    type: string | false,
    enum: { string } | false
}

export type AnalysisCommand = {
    kind: "command",
    name: string,
    description: string | false,
    arguments: { AnalysisCommandArgument },
}

type Can<T> = T | () -> T
type Suggestion = {
    x: Can<number>?,
    y: Can<number>?,

    analyzing: () -> AnalysisCommand | AnalysisCommandArgument?,
    suggestions: () -> { AnalysisSuggestion },
    selected: () -> number,
}

return function(props: Suggestion)

    return container {
        x = props.x, y = props.y,
        width = 300, auto = "Y",
        anchor = {0, 1},
        zindex = 10000,

        flex():column():gap(4):vertical("bottom"),

        show(props.analyzing, function()
            local suggestion = function()
                return props.analyzing() or { name = "", description = "" }
            end

            return background {
                width = 300,
                auto = Enum.AutomaticSize.Y,

                { BackgroundTransparency = 0 },

                flex(),

                background {
                    height = 24,
                    width = 300,
                    flex():column():between("horizontal"):vertical("center"),
                    padding {x = 4},
    
                    text {
                        text = function()
                            return suggestion().name
                        end,
                        text_size = 20,
                        weight = Enum.FontWeight.Bold,
                    },
    
                    text {
                        text = function()
                            return suggestion().type or ""
                        end,
                        text_size = 18,
                        weight = Enum.FontWeight.Light,
                    }
    
                },

                text {
                    padding { padding = 4},
                    width = 300,
                    wrapped = true,
                    text_size = 16,
                    xalignment = Enum.TextXAlignment.Left,
                    text = function()
                        return suggestion().description
                    end,
                }

            }
        end),

        background {
            ys = 1,
            width = 200, height = 0,
            anchor = {0, 1},

            auto = Enum.AutomaticSize.Y,

            { BackgroundTransparency = 0, },

            flex():vertical("bottom"),

            values(props.suggestions, function(suggestion)
                return text {
                    width = 200,
                    height = 20,
                    
                    text_size = 16,
                    xalignment = Enum.TextXAlignment.Left,
                    text = suggestion.name,

                    padding { left = 4 }
                }
            end)
        }
    }

end