local vide = require("../../roblox_packages/vide")
local theme = require("../theme")

local create = vide.create
local read = vide.read :: (<T>(() -> T) -> T) & (<T>(T) -> T)

type Can<T> = T | () -> T
type Background = {
    read width: Can<number>?,
    read height: Can<number>?,

    read text: Can<string>,
    read text_size: Can<number>?,
    read text_style: Can<"normal" | "info" | "warn" | "error">?,
    read xalignment: Can<Enum.TextXAlignment>?,
    
    [number]: unknown
}

return function(props: Background)

    return create "TextLabel" {
        Size = function()
            return UDim2.fromOffset(read(props.width) or 0, read(props.height) or 0)
        end,
        AutomaticSize = Enum.AutomaticSize.XY,

        Text = props.text,
        TextSize = props.text_size,
        TextColor3 = function()
            local style = props.text_style
            return if read(style) == "normal" then theme.text()
                elseif read(style) == "warn" then theme.text_warn()
                elseif read(style) == "error" then theme.text_error()
                elseif read(style) == "info" then theme.text_info()
                else theme.text()
        end,
        FontFace = theme.font,
        TextXAlignment = props.xalignment,

        BackgroundTransparency = 1,

        unpack(props)
    }

end