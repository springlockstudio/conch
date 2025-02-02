--!strict
local types = require("../luau_packages/types")


export type TokenKindText = types.TokenKindText
export type TokenKindRest = types.TokenKindRest
export type Token<T=TokenKindRest|TokenKindText> = types.Token<T>

local function char(c: string): number
    return string.byte(c) :: number
end

--[=[
    Lexes the given input into tokens
]=]
local function parse(input: buffer)

	local pos = 0
    local line = 0
    local len = buffer.len(input)
    local parse_line_endings: boolean = false

    local function peek(): number
        if pos == len then return 0 end
		return buffer.readu8(input, pos) :: any
	end
        
    local function bump()
        pos = math.min((pos + 1) :: any, len)
    end

    local function bump_any()
        if peek() == char("\n") then
            line += 1
        end

        bump()
        return peek()
    end

    local function bump_peek()
        bump()
        return peek()
    end

    local function is_whitespace(c: number): boolean
		return c == char(" ") or c == char("\t") or c == char("\r")
	end

	local function is_digit(c: number): boolean
		return char("0") <= c and c <= char("9")
	end

	local function is_alpha(c: number): boolean
		return (char("a") <= c and c <= char("z")) or (char("A") <= c and c <= char("Z")) or c == char("_")
	end

    local function string_backslash()
		local c = peek()

		if c == char("\r") then
			c = bump_peek()

			if c == char("\n") then
				bump()
				line += 1
			end
		elseif c == char("z") then
			bump()

			while is_whitespace(peek()) do
				bump_any()
			end
		else
			bump_any()
		end
	end

    local function quoted_string(): "string" | "error"
		local delim = peek()
		local c = bump_peek()

		while c ~= delim do
			if c == 0 or c == char("\n") or c == char("\r") then
				return "error"
			elseif c == char("\\") then
				bump()
				string_backslash()
			else
				bump()
			end

			c = peek()
		end

		bump()
		return "string"
	end

    local function number(): "number" | "error"
		local start = pos
		local base = 10

		local c: number = peek()

		if c == char("0") then
			c = bump_peek()

			if c == char("x") or c == char("X") then
				c = bump_peek()
				base = 16
			elseif c == char("b") or c == char("B") then
				c = bump_peek()
				base = 2
			end
		end

		while is_digit(c) or c == char(".") or c == char("_") do
			c = bump_peek()
		end

		if c == char("e") or c == char("E") then
			c = bump_peek()

			if c == char("+") or c == char("-") then
				c = bump_peek()
			end
		end

		while is_digit(c) or is_alpha(c :: any) or c == char("_") do
			c = bump_peek()
		end

		local text: string
		if base == 10 then
			text = buffer.readstring(input, start, pos - start) :: string
		else
			text = buffer.readstring(input, start + 2, pos - start - 2) :: string
		end

        text = string.gsub(text, "_", "")

		if tonumber(text, base) then
			return "number"
		else
			return "error"
		end
	end

    local function read_kind(): TokenKindRest | TokenKindText
        local c: number = peek()
        
        if c == 0 then
            return "eof"
        end

        if c == char("#") then
            while c ~= char("\n") do
                bump_any()
            end
            return "comment"
        elseif is_whitespace(c) then
            bump()
            return "whitespace"
        elseif is_alpha(c) then
            local start = pos

            repeat
                c = bump_peek()
            until not (is_alpha(c :: number) or is_digit(c :: number) or c == char("-"))

            local value = buffer.readstring(input, start, pos - start)

            if value == "true" then
                return "true"
            elseif value == "false" then
                return "false"
            elseif value == "nil" then
                return "nil"
            elseif value == "return" then
                return "return"
            elseif value == "for" then
                return "for"
            elseif value == "while" then
                return "while"
            elseif value == "if" then
                return "if"
            elseif value == "else" then
                return "else"
            elseif value == "break" then
                return "break"
            elseif value == "continue" then
                return "continue"
            end
            
            return "identifier"
        elseif is_digit(c :: number) then
            return number()
        elseif c == char("\"") then
            return quoted_string()
        elseif c == char("\'") then
            return quoted_string()
        elseif c == char(".") then
            c = peek()

			if is_digit(c) then
				pos -= 1
				return number()
			else
                bump()
				return "."
			end
        elseif c == char("=") then
            bump()

            if peek() == char("=") then
                return "=="
            else
                return "="
            end
        elseif c == char("~") then
            bump()

            if peek() == char("=") then
                return "~="
            else
                return "error"
            end
        elseif c == char(">") then
            bump()

            if peek() == char("=") then
                return ">="
            else
                return ">"
            end
        elseif c == char("<") then
            bump()

            if peek() == char("=") then
                return "<="
            else
                return "<"
            end
        elseif c == char("$") then
            bump()
            return "$"
        elseif c == char("(") then
            bump()
            return "("
        elseif c == char(")") then
            bump()
            return ")"
        elseif c == char("{") then
            bump()
            return "{"
        elseif c == char("}") then
            bump()
            return "}"
        elseif c == char("[") then
            bump()
            return "["
        elseif c == char("]") then
            bump()
            return "]"
        elseif c == char("|") then
            bump()
            return "|"
        elseif c == char("\n") then
            bump()
            return "\n"
        elseif c == char(";") then
            bump()
            return ";"
        elseif c == char(",") then
            bump()
            return ","
        elseif is_whitespace(c) then
            bump()
            return read_kind()
        end

        error(`no symbol matching {string.char(c)}`)
        return "error"
    end

    local function next_token()
        local start = pos
        local kind = read_kind()
        
        while kind == "whitespace" or kind == "comment" or parse_line_endings == false and (kind == "\n" or kind == ";") do
            start = pos
            kind = read_kind()
        end

        return {
            kind = kind,
            text = buffer.readstring(input, start, pos - start),
            span = vector.create(start, pos, 0),
        }
    end

    local current_token = next_token()
    local current_kind = current_token.kind
    local lookahead_token = next_token()
    local lookahead_kind = lookahead_token.kind

    local function consume()
        local old_token, old_kind = current_token, current_kind
        current_token, current_kind = lookahead_token, lookahead_kind
        lookahead_token = next_token()
        lookahead_kind = lookahead_token.kind
        return old_token, old_kind
    end

    local function display(token: Token): string
        local kind = token.kind
    
        if 
            kind == "identifier"
            or kind == "number"
            or kind == "string"
        then
            return kind
        elseif token.kind == "error" then
            return "error '" .. token.text .. "'"
        else
            return "'" .. kind .. "'"
        end
    end

    local function report(message: string, span: vector?): never
        local report = {
            message = message,
            span = span or current_token.span,
        }
    
        error(`{report.message} {report.span}`)
    end

    local function expect_failure(kind: TokenKindText | TokenKindRest): never
        return report(`expected {display({ kind = kind } :: any)}, but got {display(current_token)} of {current_kind} instead`)
    end

    local function expect<T>(kind: T & (TokenKindText | TokenKindRest)): Token<T>
        if current_kind == kind :: any then
            return consume() :: any
        else
            return expect_failure(kind)
        end
    end

    local parse_expression: () -> types.Expression
    local parse_command: () -> types.Command
    local parse_block: () -> types.Block
    local parse_lambda: () -> types.Expression_Lambda
    local parse_expression_or_command: () -> types.ExpressionOrCommand
    local parse_var: () -> types.Var
    local parse_var_root: () -> types.VarRoot
    local parse_var_suffix: () -> types.VarSuffix
    local parse_var_suffixes: () -> { types.VarSuffix }
    local parse_function_body: () -> types.FunctionBody
    local parse_if: () -> types.Stat_If
    local parse_while: () -> types.Stat_While
    local parse_for: () -> types.Stat_For
    local parse_return: () -> types.Last_Return

    function parse_var_root(): types.VarRoot
        print("root:", current_kind, current_token.text)
        if current_kind == "identifier" then
            print("global")
            return { kind = "global", token = expect("identifier") }
        elseif current_kind == "$" and lookahead_kind == "identifier" then
            expect("$")
            return { kind = "name", name = expect("identifier") }
        elseif current_kind == "$" and lookahead_kind == "(" then
            expect("$")
            expect("(")
            local expr = parse_expression_or_command()
            expect(")")
            return { kind = "paren", expr = expr }
        else
            return report(`invalid root {display(current_token)}`)
        end
    end

    function parse_var_suffix(): types.VarSuffix
        if current_kind == "." then
            expect(".")
            local identifier = expect("identifier")
            return { kind = "nameindex", name = identifier }
        elseif current_kind == "[" then
            expect("[")
            local expr = parse_expression_or_command()
            expect("]")
            return { kind = "exprindex", expr = expr }
        else
            return report("invalid")
        end
    end

    function parse_var_suffixes(): { types.VarSuffix }
        local suffixes: { types.VarSuffix } = {}
        while current_kind == "." or current_kind == "[" do
            local suffix = parse_var_suffix()
            table.insert(suffixes, suffix)
        end
        print("finished")
        return suffixes
    end

    function parse_var(): types.Var
        local root = parse_var_root()
        local suffixes = parse_var_suffixes()
        return {
            prefix = root,
            suffixes = suffixes,
        }
    end

    function parse_expression_or_command(): types.ExpressionOrCommand
        if current_kind == "identifier" then
            return parse_command()
        else
            return parse_expression()
        end
    end

    function parse_function_body(): types.FunctionBody
        expect("|")

        local arguments = {}
        local first = true

        while current_kind ~= "|" do
            if not first then expect(",") end
            table.insert(arguments, expect("identifier"))
            first = false
        end
        
        expect("|")
        expect("{")

        local block = parse_block()

        expect("}")
        return {
            arguments = arguments,
            block = block
        }
    end

    function parse_lambda(): types.Expression_Lambda
        return {
            kind = "lambda",
            body = parse_function_body()
        }
    end

    function parse_table(): types.Table
        expect("{")
        
        local parsing_newlines = parse_line_endings
        parse_line_endings = false

        local fields: { types.TableField } = {}
        local first = true

        while current_kind ~= "}" do
            if not first then expect(",") end
            print("token", current_token.text)
            first = false
            
            if current_kind == "identifier" and lookahead_kind == "=" then
                print("ident")
                local key = expect("identifier")
                expect("=")
                local value = parse_expression()
                table.insert(fields, { kind = "namekey", name = key, value = value })
            elseif current_kind == "[" then
                expect("[")
                local key = parse_expression()
                expect("]")
                expect("=")
                local value = parse_expression()
                table.insert(fields, { kind = "exprkey", key = key, value = value })
            else
                local expr = parse_expression()

                table.insert(fields, { kind = "nokey", value = expr })
            end

            print(current_kind)
        end

        parse_line_endings = parsing_newlines
        expect("}")
        return { fields = fields }
    end

    function parse_expression(): types.Expression
        if current_kind == "$" and lookahead_kind == "(" then
            -- nested call
            expect("$")
            local expr
            if lookahead_kind == "$" or lookahead_kind == "identifier" then
                parse_line_endings = true
                expect("(")
                expr = parse_command()
                parse_line_endings = false
            else
                expect("(")
                expr = parse_expression()
            end
            expect(")")
            return { kind = "evaluate", body = expr }
        elseif current_kind == "$" and lookahead_kind == "identifier" then
            -- variable
            return { kind = "var", var = parse_var() }
        elseif current_kind == "string" then
            -- string
            return {
                kind = "string" :: "string",
                token = expect("string")
            }
        elseif current_kind == "number" then
            -- number
            return {
                kind = "number" :: "number",
                token = expect("number")
            }
        elseif current_kind == "true" then
            -- boolean
            return {
                kind = "boolean" :: "boolean",
                token = expect("true")
            }
        elseif current_kind == "false" then
            return {
                kind = "boolean" :: "boolean",
                token = expect("false")
            }
        elseif current_kind == "identifier" then
            local token = expect("identifier")
            return {
                kind = "string",
                token = { kind = "string", text = `"{token.text}"`, span = token.span } :: Token<"string">
            }
        elseif current_kind == "|" then
            -- lambda
            return parse_lambda()
        elseif current_kind == "{" then
            return { kind = "table", table = parse_table() }
        else
            report(`expected something, got {current_kind}`)
        end
    end

    function parse_command(): types.Command
        parse_line_endings = true
        print("starting command", current_kind, lookahead_kind, current_token.text, lookahead_token.text)
        local var = parse_var()
        local arguments: { types.Expression } = {}

        while
            current_kind == "$" or
            current_kind == "string" or
            current_kind == "number" or
            current_kind == "true" or
            current_kind == "false" or
            current_kind == "identifier" or
            current_kind == "{" or
            current_kind == "|"
        do
            parse_line_endings = false
            local expression = parse_expression()
            parse_line_endings = true
            table.insert(arguments, expression)
        end

        parse_line_endings = false

        while current_kind == "\n" or current_kind == ";" do consume() end

        return {
            kind = "command",
            prefix = var,
            arguments = arguments
        }
    end

    function parse_if(): types.Stat_If
        expect("if")
        local conditionals: { types.If } = {}
        local else_block: types.Block?
        local first = true

        while true do
            if first then
                expect("(")
                local expression = if current_kind == "identifier" then parse_command() else parse_expression()
                expect(")")
                expect("{")
                local block = parse_block()
                expect("}")

                table.insert(conditionals, { condition = expression, block = block })

                first = false
            elseif current_kind == "else" and lookahead_kind == "if" then
                expect("else")
                expect("if")

                expect("(")
                local expression = if current_kind == "identifier" then parse_command() else parse_expression()
                expect(")")
                expect("{")
                local block = parse_block()
                expect("}")

                table.insert(conditionals, { condition = expression, block = block })
            elseif current_kind == "else" then
                expect("else")
                expect("{")
                else_block = parse_block()
                expect("}")
                break
            else
                break
            end
        end

        return {
            kind = "if",
            ifs = conditionals,
            fallback = else_block
        }
    end

    function parse_while(): types.Stat_While
        expect("while")
        expect("(")
        local expression = if current_kind == "identifier" then parse_command() else parse_expression()
        expect(")")

        expect("{")
        print("currently", current_kind, current_token.text, "next", lookahead_kind)
        local block = parse_block()
        expect("}")

        return {
            kind = "while",
            expression = expression,
            block = block
        }
    end

    function parse_for(): types.Stat_For
        expect("for")
        expect("(")
        local expression = parse_expression_or_command()
        expect(")")
        local block = parse_function_body()

        return {
            kind = "for",
            expression = expression,
            call = block
        }
    end

    function parse_return(): types.Last_Return
        expect("return")

        local values = {}

        while
            current_kind ~= "}" and
            current_kind ~= "eof"
        do
            if #values > 0 then expect(",") end
            table.insert(values, parse_expression())
        end

        return { kind = "return", values = values }
    end

    function parse_block(): types.Block
        local statements: { types.Statement } = {}
        local last_statement: types.LastStatement?
        print("starting with", current_kind, current_token.text, "next", lookahead_kind, lookahead_token.text)
        print("getting next")
        while
            current_kind ~= "eof" and
            current_kind ~= "}"
        do
            print("getting next", current_kind)
            print(current_kind, lookahead_kind)
            if last_statement then report("expected to finish after last statement") end

            if current_kind == "identifier" and lookahead_kind == "=" then
                print("assign")
                local key = expect("identifier")
                expect("=")
                local value = parse_expression_or_command()
                local statement = { kind = "assign", left = key, right = value }
                table.insert(statements, statement)
            elseif current_kind == "if" then
                table.insert(statements, parse_if())
            elseif current_kind == "while" then
                table.insert(statements, parse_while())      
            elseif current_kind == "for" then
                table.insert(statements, parse_for())
            elseif current_kind == "return" then
                last_statement = parse_return()
            elseif current_kind == "break" then
                expect("break")
                last_statement = { kind = "break" :: "break" }
            elseif current_kind == "continue" then
                expect("continue")
                last_statement = { kind = "continue" :: "continue" }
            else
                table.insert(statements, parse_command())
            end
            print(current_kind)
        end

        return {
            body = statements,
            last_statement = last_statement
        }
    end

    return parse_block()
end

return parse