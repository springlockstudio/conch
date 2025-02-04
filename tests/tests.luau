local ast = require("../pkgs/analysis/src/optional_ast")
local analyze = require("../pkgs/analysis/src/lib")
local compiler = require("../pkgs/compiler/src/lib")
local vm = require("../pkgs/vm/src/lib")
local testkit = require("./testkit")

local block


testkit.print(analyze.generate_analysis_info({
    code = "print  ",
    where = 6,

    variables = {},
    commands = {
        {
            kind = "command",
            name = "print",
            description = "Outputs some text to stdout",
            arguments = {
                {
                    kind = "argument",
                    name = "Text",
                    description = "The text to print",
                    type = "any"
                }
            }
        }
    },
}))

-- if status.status == "finished" then
--     local block = status.value
--     testkit.print(block)
--     -- local instructions = compiler(block, { instructions = {}, locals = {}, upvalues = {} })
--     -- testkit.print(instructions)
--     -- local virtual_machine = vm()
--     -- virtual_machine.commands.sub = function(a, b)
--     --     return a - b
--     -- end
--     -- virtual_machine.commands.mul = function(a, b)
--     --     return a * b
--     -- end
--     -- virtual_machine.commands.print = print
--     -- virtual_machine.commands["os-clock"] = os.clock


--     -- virtual_machine.run(instructions)

-- end