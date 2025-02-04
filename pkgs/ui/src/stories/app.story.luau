local vide = require("../../roblox_packages/vide")
local conch = require("../../roblox_packages/conch_glue")

local state = require("../state")
local app = require("../app")

return function(target)
    state.opened(true)
    conch.register_default_commands()
    conch._.create_local_user()
    return vide.mount(function()
        return app()
    end, target)
end