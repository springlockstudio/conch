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
    ast: ast.Block,

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
    local where = options.where

    local function LOG(kind: LogKind, text: string)
        table.insert(LOGS, { kind = kind, text = text })
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

    local function get_text_token<T>(token: ast.Token<T>)
        local span = token.span
        local finish = span.x - where
        return string.sub(token.text, 1, finish)
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

    local function no_suggestions(text: string)
        return {
            at = where,
            text = text,
            logs = LOGS,
            suggestions = {},
            ast = processing.value
        }
    end

    function parse_command(stat: ast.Command): AnalysisInformation
        local pos = position_relative(stat.prefix.span)
        print(pos)
        if pos == "within" then
            local var = stat.prefix
            local prefix = var.prefix

            if prefix.kind == "global" then
                local suggestions: { AnalysisSuggestion } = {}
                local text = get_text_token(prefix.token)
                
                for index, command in options.commands do
                    if string.sub(command.name, 1, #text) ~= text then continue end
                    suggestions[index] = {
                        name = command.name,
                        description = command.description,
                        type = "Command",

                        replace = var.span,
                        with = command.name,
                    }
                end

                return {
                    at = where,
                    text = text,
                    logs = LOGS,
                    ast = processing.value,

                    analyzing = nil,
                    suggestions = suggestions
                }
            else
                return no_suggestions("")
            end
        elseif pos == "after" then
            -- obtain the prefix
            local var = stat.prefix
            local prefix = var.prefix
            local command_info: AnalysisCommand

            if prefix.kind == "global" then
                for index, command in options.commands do
                    if command.name ~= prefix.token.text then continue end
                    command_info = command
                    break
                end
            end

            if not command_info then return no_suggestions("") end

            local index = 1
            for i in stat.arguments do
                index = i
                if position_relative(argument.span) == "within" then break end
            end
            local arg_info = command_info.arguments[index]

            if not arg_info then
                LOG("warn", `no argument #{index}`)
                return no_suggestions("")
            end

            return {
                at = where,
                text = text,
                logs = LOGS,
                ast = processing.value,

                analyzing = arg_info,
                suggestions = {}
            }
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
        local statement
        for _, stat in block.body do
            statement = stat
            local pos = position_relative(stat.span)
            if pos == "before" then continue end
            break
        end
    
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

    return process_block(block)
end

return {
    generate_analysis_info = generate_analysis_info
}