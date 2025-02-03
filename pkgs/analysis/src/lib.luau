local ast = require("../luau_packages/conch_ast")
local types = require("../luau_packages/conch_types")

local state: types.VirtualMachine

type ASTState = 
    | "none"
    | "stat"
    | "expr"
    | "expr-cmd"
    | "cmd"

local function obtain_function_information(fn: (...any) -> ...any)

end
local LOGS = {}
local state: { ASTState } = {}
local state_n = 0

local function LOG(kind: "normal" | "warn" | "error" | "info", text: string)
    table.insert(LOGS, { kind = kind, text = text })
end

local function PUSH(state: ASTState)
    state_n += 1
    state[state_n] = state
end

local function POP(state: ASTState)
    state_n -= 1
end

local function within(token: types.Token)
    return pos >= token.span.x and pos <= token.span.y
end

local function process_expression(expr: types.ExpressionOrCommand)
    if expr.kind == "boolean" then

    elseif expr.kind == "command" then

    elseif expr.kind == "evaluate" then
        
    elseif expr.kind == "lambda" then

    elseif expr.kind == "nil" then

    elseif expr.kind == "number" then

    elseif expr.kind == "string" then

    elseif expr.kind == "table" then

    elseif expr.kind == "var" then

    end
end

local function process_assignment(stat: types.Stat_Assign)
    if within(stat.left) then return stat end
    PUSH "expr-cmd"
    local value = process_assignment(stat.right)
    POP ()
    return value
end

local function process_block(block: types.Block)
    PUSH "stat"

    for _, stat in block.body do
        local value = if stat.kind == "assignment" then
            process_assignment(stat)
        else error("unrecognized")
        
        if value ~= false then return value end
    end

    POP ()
    return false
end

