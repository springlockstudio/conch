local vide = require("../../roblox_packages/vide")
local theme = require("../theme")

local create = vide.create
local read = vide.read

type Can<T> = T | () -> T
type Background = {
    read width: Can<number>?,
    read height: Can<number>?,
    read auto: Can<Enum.AutomaticSize>?,
    read color: Can<Color3>?,
    read layout: Can<number>?,
    
    [number]: unknown
}

return function(props: Background)

    return create "Frame" {
        Size = function()
            return UDim2.fromOffset(read(props.width) or 0, read(props.height) or 0)
        end,
        AutomaticSize = props.auto,
        LayoutOrder = props.layout,

        BackgroundColor3 = props.color or theme.background,
        BackgroundTransparency = theme.background_transparency,

        unpack(props)
    }

end