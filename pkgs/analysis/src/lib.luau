local ast = require "./optional_ast"
local types = require "../luau_packages/types"

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
	commands: { AnalysisCommand },
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

local function generate_analysis_info(
	options: FeedAnalysisOptions
): AnalysisInformation
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

	local function get_span(from: ast.Surrounded<
		{ span: vector }?,
		unknown?,
		unknown?
	>): vector
		local x, y
		if from.left then
			x = from.left.span.x
		elseif from.value then
			x = from.value.span.x
		else
			x = from.right.span.x
		end

		if from.right then
			y = from.right.span.y
		elseif from.value then
			y = from.value.span.y
		else
			y = from.left.span.y
		end

		return vector.create(x, y, 0)
	end

	local function get_text_token<T>(token: ast.Token<T>)
		local span = token.span
		local finish = where - span.x
		return string.sub(token.text, 1, finish)
	end

	local function position_relative(
		span: vector
	): "before" | "after" | "within"
		return if where >= span.x and where <= span.y
			then "within"
			elseif where < span.x then "before"
			else "after"
	end

	local processing = ast(options.code)
	local block

	local function no_suggestions(text: string)
		return {
			at = where,
			text = text,
			logs = LOGS,
			suggestions = {},
			ast = processing
				and processing.status == "finished"
				and processing.value,
		}
	end

	if processing.status == "error" then
		LOG("error", processing.why)
		return no_suggestions ""
	else
		block = processing.value
	end

	local process_if_stat
	local process_assignment
	local process_for
	local process_while
	local process_block
	local process_command
	local process_function
	local process_return
	local process_expression
	local process_expression_or_command
	-- local parse_if
	-- local parse_expression

	function process_command(
		stat: ast.Command,
		expressions_too: boolean?
	): AnalysisInformation
		local pos = position_relative(stat.prefix.span)
		if pos == "within" then
			local var = stat.prefix
			local prefix = var.prefix

			if prefix.kind == "global" then
				local suggestions: { AnalysisSuggestion } = {}
				local text = get_text_token(prefix.token)
				local analyzing

				if expressions_too and string.sub("true", 1, #text) == text then
					table.insert(suggestions, {
						name = "true",
						type = "true",

						replace = var.span,
						with = "true",
					})
				end

				if
					expressions_too
					and string.sub("false", 1, #text) == text
				then
					table.insert(suggestions, {
						name = "false",
						type = "false",

						replace = var.span,
						with = "false",
					})
				end

				if expressions_too and string.sub("nil", 1, #text) == text then
					table.insert(suggestions, {
						name = "nil",
						type = "nil",

						replace = var.span,
						with = "nil",
					})
				end

				if
					not expressions_too
					and string.sub("for", 1, #text) == text
				then
					table.insert(suggestions, {
						name = "for",
						type = "for",

						replace = var.span,
						with = "for",
					})
				end

				if
					not expressions_too
					and string.sub("if", 1, #text) == text
				then
					table.insert(suggestions, {
						name = "if",
						type = "if",

						replace = var.span,
						with = "if",
					})
				end

				if
					not expressions_too
					and string.sub("while", 1, #text) == text
				then
					table.insert(suggestions, {
						name = "while",
						type = "while",

						replace = var.span,
						with = "while",
					})
				end

				if
					not expressions_too
					and string.sub("else", 1, #text) == text
				then
					table.insert(suggestions, {
						name = "else",
						type = "else",

						replace = var.span,
						with = "else",
					})
				end

				for index, command in options.commands do
					if string.sub(command.name, 1, #text) ~= text then
						continue
					end
					if #text == #command.name then analyzing = command end

					table.insert(suggestions, {
						name = command.name,
						description = command.description,
						type = "Command",

						replace = var.span,
						with = command.name,
					})
				end
				return {
					at = where,
					text = text,
					logs = LOGS,
					ast = processing.value,

					analyzing = analyzing,
					suggestions = suggestions,
				}
			else
				return no_suggestions ""
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

			if not command_info then return no_suggestions "" end

			local index = 1
			local span = vector.create(stat.prefix.span.y, 0)

			local arg_analyzed: AnalysisInformation = no_suggestions ""
			for i, argument in stat.arguments do
				if position_relative(argument.span) == "within" then
					if argument.kind == "identifier" then
						span = argument.span
					end
					arg_analyzed =
						process_expression(argument) :: AnalysisInformation
					break
				end
				if position_relative(argument.span) == "after" then
					index += 1
					break
				end
			end
			local arg_info: (types.AnalysisCommandArgument | types.AnalysisCommandVariadic)? =
				command_info.arguments[index]

			if index > #command_info.arguments then
				arg_info = command_info.arguments[#command_info.arguments]

				if arg_info and arg_info.kind ~= "variadic" then
					LOG("warn", `no argument #{index}`)
					return arg_analyzed
				end
			end

			if arg_info and arg_info.suggestion_generator then
				local generator = arg_info.suggestion_generator
				local text = arg_analyzed.text
				local suggestions = generator(text)

				for idx, name in suggestions do
					suggestions[idx] = {
						name = name,
						type = text,

						replace = span,
						with = name,
					}
				end

				table.move(
					suggestions,
					1,
					#suggestions,
					#arg_analyzed.suggestions + 1,
					arg_analyzed.suggestions
				)
			end

			arg_analyzed.analyzing = arg_analyzed.analyzing or arg_info
			return arg_analyzed
		end

		return no_suggestions ""
	end

	function process_if(stat: ast.If)
		local conditional = stat.condition
		local relative = position_relative(get_span(conditional))

		if relative == "within" then
			return process_expression_or_command(conditional.value)
		end

		if stat.block then return process_block(stat.block.value) end
	end

	function parse_if_stat(stat: ast.Stat_If)
		for _, condition in stat.ifs do
			local pos = position_relative(condition.span)
			if pos == "before" then continue end
			if pos == "after" then break end
			return process_if(condition)
		end

		local fallback = stat.fallback
		if fallback and position_relative(get_span(fallback)) == "within" then
			return process_block(fallback.value)
		end
	end

	function process_function(expr: ast.FunctionBody)
		if not expr.block then return no_suggestions "" end
		if position_relative(get_span(expr.block)) == "within" then
			return process_block(expr.block.value)
		else
			return no_suggestions ""
		end
	end

	function process_expression(expr: ast.Expression)
		local expr = expr
		if expr.kind == "lambda" then
			return process_function(expr.body)
		elseif expr.kind == "evaluate" then
			if
				position_relative(get_span(expr.body)) == "within"
				and expr.body.value
			then
				return process_expression_or_command(expr.body.value)
			end
		elseif expr.kind == "vector" then
			for idx, value in expr.contents.value do
				if position_relative(value.span) ~= "before" then
					return process_expression(value)
				end
			end
		elseif expr.kind == "identifier" then
			return no_suggestions(expr.token.text)
		end

		return no_suggestions ""
	end

	function process_return(stat: ast.Last_Return)
		for index, value in stat.values do
			if position_relative(value.span) == "before" then continue end
			return process_expression_or_command(value)
		end
		return no_suggestions ""
	end

	function process_expression_or_command(expr: ast.ExpressionOrCommand)
		if expr.kind == "command" then
			return process_command(expr, true)
		else
			return process_expression(expr)
		end
	end

	function process_assignment(assign: ast.Stat_Assign)
		if not assign.right then return no_suggestions "" end
		if position_relative(assign.operator.span) == "before" then
			return no_suggestions ""
		end
		return process_expression_or_command(assign.right)
	end

	function process_while(stat: ast.Stat_While)
		if position_relative(get_span(stat.expression)) == "within" then
			return process_expression_or_command(stat.expression.value, true)
		end

		local block = stat.block
		if block and position_relative(get_span(block)) == "within" then
			return process_block(block.value)
		end

		return no_suggestions ""
	end

	function process_block(block: ast.Block)
		local statement
		for _, stat in block.body do
			statement = stat
			local pos = position_relative(stat.span)
			if pos == "before" or pos == "after" then continue end

			if statement == nil then return no_suggestions "" end

			return if statement.kind == "if"
				then parse_if_stat(statement)
				elseif statement.kind == "assign" then process_assignment(
					statement
				)
				elseif statement.kind == "command" then process_command(
					statement
				)
				elseif statement.kind == "return" then process_return(
					statement
				) -- parse_return(statement)
				elseif
					statement.kind == "for"
				then no_suggestions "" -- parse_for(statement)
				elseif statement.kind == "while" then process_while(
					statement
				)
				else no_suggestions ""
		end

		return no_suggestions ""
	end

	return process_block(block)
end

return {
	generate_analysis_info = generate_analysis_info,
}
