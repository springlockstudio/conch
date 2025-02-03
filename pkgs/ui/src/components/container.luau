local vide = require("../../roblox_packages/vide")
local theme = require("../theme")

local create = vide.create
local read = vide.read

type Can<T> = T | () -> T
type Container = {
    read width: Can<number>?,
    read height: Can<number>?,
    read x: Can<number>?,
    read y: Can<number>?,
    read auto: Can<Enum.AutomaticSize>?,
    read layout: Can<number>?,
    
    [number]: unknown
}

return function(props: Container)

    return create "Frame" {
        Size = function()
            return UDim2.fromOffset(read(props.width) or 0, read(props.height) or 0)
        end,
        Position = function()
            return UDim2.fromOffset(read(props.x) or 0, read(props.y) or 0)
        end,
        AutomaticSize = props.auto,
        LayoutOrder = props.layout,

        BackgroundTransparency = 1,

        unpack(props)
    }

end