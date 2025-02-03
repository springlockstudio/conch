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

    return {
        at = options.where,
        text = "",
        logs = {},
        analyzing = {
            kind = "command",
            name = "string",
            description = "string | false",
        },
        suggestions = { {
            name = "example-suggestion",

            replace = vector.create(0, 5, 0),
            with = "mraow"
        } }
    }

    -- local LOGS = {}
    -- local where = options.where

    -- local function LOG(kind: LogKind, text: string)
    --     table.insert(LOGS, { kind = kind, text = text })
    -- end

    -- local function no_suggestions(text: string)
    --     return {
    --         at = where,
    --         text = text,
    --         logs = LOGS,
    --         suggestions = {}

    --     }
    -- end

    -- local processing = options.block

    -- local parse_if
    -- local parse_assignment
    -- local parse_command
    -- local parse_return
    -- local parse_for
    -- local parse_while
    -- local parse_block

    -- function parse_if(stat: ast.Stat_If)
        
    -- end

    -- function parse_block(block: ast.Block)
    --     for _, statement in block.body do
    --         if statement.span.y > where then continue end
    
    --         return if statement.kind == "if" then
    --             parse_if(statement)
    --         elseif statement.kind == "assignment" then
    --             parse_assignment(statement)
    --         elseif statement.kind == "command" then
    --             parse_command(statement)
    --         elseif statement.kind == "return" then
    --             parse_return(statement)
    --         elseif statement.kind == "for" then
    --             parse_for(statement)
    --         elseif statement.kind == "while" then
    --             parse_while(statement)
    --         else no_suggestions("")
    --     end
    -- end

    -- return process_block(options.block)
end

return {
    generate_analysis_info = generate_analysis_info
}