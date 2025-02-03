local ast = require("../pkgs/ast/src/lib")
local compiler = require("../pkgs/compiler/src/lib")
local vm = require("../pkgs/vm/src/lib")
local testkit = require("./testkit")

local block
local status = ast("if (true) {\n}", true)

if status.status == "pending" then
    status = status.append("| { print Hello World }")
end

print(status.status, status.why)

if status.status == "finished" then
    local block = status.value
    testkit.print(block)
    local instructions = compiler(block, { instructions = {}, locals = {}, upvalues = {} })
    testkit.print(instructions)
    local virtual_machine = vm()
    virtual_machine.commands.sub = function(a, b)
        return a - b
    end
    virtual_machine.commands.mul = function(a, b)
        return a * b
    end
    virtual_machine.commands.print = print
    virtual_machine.commands["os-clock"] = os.clock


    virtual_machine.run(instructions)

end