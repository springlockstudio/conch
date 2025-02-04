local ast = require("./optional_ast")
local types = require("../luau_packages/conch_types")

local state: types.VirtualMachine

type LogKind = types.LogKind
type AnalysisSuggestion = types.AnalysisSuggestion
type AnalysisInformation = types.AnalysisInformation

type AnalysisCommandArgument = types.AnalysisCommandArgument
type AnalysisCommand = types.AnalysisCommand

export type FeedAnalysisOptions = {
    code: string,
    where: number,

    variables: { [string]: any },
    commands: { AnalysisCommand }
}

type Node =
    | ast.Command
    | ast.Expression_Boolean
    | ast.Expression_Evaluate
    | ast.Expression_Identifier
    | ast.Expression_Lambda
    | ast.Expression_Lambda
    | ast.Expression_Nil
    | ast.Expression_Number
    | ast.Expression_String
    | ast.Expression_Table
    | ast.Expression_Var

local function generate_analysis_info(options: FeedAnalysisOptions): AnalysisInformation

    -- return {
    --     at = options.where,
    --     text = "",
    --     logs = {},
    --     analyzing = {
    --         kind = "command",
    --         name = "string",
    --         description = "string | false",
    --     },
    --     suggestions = { {
    --         name = "example-suggestion",

    --         replace = vector.create(0, 5, 0),
    --         with = "mraow"
    --     } }
    -- }

    local LOGS = {}
    local where = options.where - 1

    local function LOG(kind: LogKind, text: string)
        table.insert(LOGS, { kind = kind, text = text })
    end

    local function no_suggestions(text: string)
        return {
            at = where,
            text = text,
            logs = LOGS,
            suggestions = {}

        }
    end

    local function get_span(from: ast.Surrounded<{span: vector}?, unknown?, unknown?>): vector
        local x, y
        if from.left then
            x = from.left.span.x
        elseif from.value then
            x = from.value.span.x
        elseif from.right then
            x = from.right.span.x
        end

        if from.right then
            y = from.left.span.y
        elseif from.value then
            y = from.value.span.y
        elseif from.left then
            y = from.right.span.y
        end
        
        return vector.create(x, y, 0)
    end

    local function position_relative(span: vector): "before" | "after" | "within"
        return if where >= span.x and where <= span.y then "within"
            elseif where < span.x then "before"
            else "after"
    end

    local processing = ast(options.code)
    local block

    if processing.status == "error" then
        LOG("error", processing.why)
        return no_suggestions("")
    else
        block = processing.value
    end

    -- local parse_if_stat
    -- local parse_assignment
    -- local parse_command
    -- local parse_return
    -- local parse_for
    -- local parse_while
    local process_block
    local parse_command
    -- local parse_if
    -- local parse_expression

    function parse_command(stat: ast.Command): AnalysisInformation
        if position_relative(stat.prefix.span) == "within" then
            local var = stat.prefix

            if var.prefix.kind == "global" and position_relative(var.prefix.span) == "within" then
                local suggestions: { AnalysisSuggestion } = {}
                
                for index, command in options.commands do
                    suggestions[index] = {
                        name = command.name,
                        description = command.description,
                        type = "Command",

                        replace = var.span,
                        with = command.name
                    }
                end

                print("please")
                return {
                    at = where,
                    text = "",
                    logs = LOGS,

                    analyzing = nil,
                    suggestions = suggestions
                }
            else
                return no_suggestions("")
            end
        end

        return no_suggestions("")
    end

    -- function parse_if(stat: ast.If)
    --     local conditional = stat.condition
    --     local relative = position_relative(get_span(from))
        
    --     if relative == "within" then
    --         return parse_expression(conditional.value)
    --     end

    -- end

    -- function parse_if_stat(stat: ast.Stat_If)
    --     for _, condition in stat.ifs do
    --         local pos = position_relative(condition.span)
    --         if pos == "before" then continue end
    --         if pos == "after" then break end
            
    --     end
    -- end

    function process_block(block: ast.Block)
        for _, statement in block.body do
            if statement.span.y > where then continue end
    
            return if statement.kind == "if" then
                no_suggestions("") -- parse_if_stat(statement)
                elseif statement.kind == "assignment" then
                no_suggestions("") -- parse_assignment(statement)
                elseif statement.kind == "command" then
                parse_command(statement)
                elseif statement.kind == "return" then
                no_suggestions("") -- parse_return(statement)
                elseif statement.kind == "for" then
                no_suggestions("") -- parse_for(statement)
                elseif statement.kind == "while" then
                no_suggestions("") -- parse_while(statement)
                else no_suggestions("")
        end

        return no_suggestions("")
    end

    return process_block(block)
end

return {
    generate_analysis_info = generate_analysis_info
}