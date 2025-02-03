-- [[ LEX ]]

export type Span = vector

export type Separated<Node> = { Node }

export type TokenKindText =
    | "identifier"
    | "number"
    | "string"
    | "error"

export type TokenKindRest =
    -- OPERATORS
    | "."
    | "="
    | "=="
    | "~="
    | ">"
    | "<"
    | ">="
    | "<="
    | "$"
    | ","

    -- BRACKETS
    | "("
    | ")"
    | "{"
    | "}"
    | "["
    | "]"
    | "|"

    -- KEYWORDS
    | "true"
    | "false"
    | "nil"
    | "if"
    | "else"
    | "while"
    | "for"
    | "return"
    | "break"
    | "continue"

    -- LINE ENDINGS
    | "\n"
    | ";"

    -- WHITESPACE
    | "eof"
    | "whitespace"
    | "comment"

export type TokenKind = TokenKindText | TokenKindRest

export type Token<T=TokenKind> = {
    kind: T,
    text: string,
    span: Span
}

---


export type Expression_Nil = {
    read kind: "nil",
    read token: Token<"nil">
}

export type Expression_Boolean = {
    read kind: "boolean",
    read token: Token<"true"> | Token<"false">
}

export type Expression_Number = {
    read kind: "number",
    read token: Token<"number">
}

export type Expression_String = {
    read kind: "string",
    read token: Token<"string">
}

export type Expression_Table = {
    read kind: "table",
    read table: Table
}

export type Expression_Lambda = {
    read kind: "lambda",
    read body: FunctionBody
}

export type Expression_Evaluate = {
    read kind: "evaluate",
    read body: ExpressionOrCommand
}

export type Expression_Var = {
	read kind: "var",
	read var: Var,
}

export type Expression =
	| Expression_Nil
	| Expression_Boolean
	| Expression_Number
	| Expression_String
	| Expression_Table
	| Expression_Lambda
    | Expression_Evaluate
	| Expression_Var

export type VarRoot_Global = {
    read kind: "global",
    read token: Token<"identifier">
}

export type VarRoot_Name = {
	read kind: "name",
    read name: Token<"identifier">,
}

export type VarRoot_Paren = {
	read kind: "paren",
	read expr: ExpressionOrCommand,
}

export type VarRoot = 
    | VarRoot_Global
    | VarRoot_Name
    | VarRoot_Paren

export type VarSuffix_NameIndex = {
    read kind: "nameindex",
    read name: Token<"identifier">,
}

export type VarSuffix_ExprIndex = {
    read kind: "exprindex",
    read expr: ExpressionOrCommand,
}

export type VarSuffix =
	| VarSuffix_NameIndex
	| VarSuffix_ExprIndex
    
export type Var = {
    read prefix: VarRoot,
    read suffixes: { VarSuffix }
}

export type Command = {
    read kind: "command",
    read prefix: Var,
    read arguments: { Expression }
}

export type ExpressionOrCommand =
    | Command
    | Expression

export type TableField_NameKey = {
    read kind: "namekey",
    read name: Token<"identifier">,
    read value: Expression
}

export type TableField_ExprKey = {
    read kind: "exprkey",
    read key: Expression,
    read value: Expression
}

export type TableField_NoKey = {
    read kind: "nokey",
    read value: Expression
}

export type TableField = 
    | TableField_ExprKey
    | TableField_NameKey
    | TableField_NoKey  

export type Table = {
    read fields: { TableField }
}

export type Stat_Assign = {
    read kind: "assignment",
    read left: Token<"identifier">,
    read right: ExpressionOrCommand
}

export type FunctionBody = {
    read arguments: { Token<"identifier"> },
    read block: Block
}

export type Last_Return = {
    read kind: "return",
    values: { ExpressionOrCommand }
}

export type Last_Continue = {
    read kind: "continue"
}

export type Last_Break = {
    read kind: "break"
}

export type LastStatement =
    | Last_Return
    | Last_Continue
    | Last_Break

export type If = {
    condition: ExpressionOrCommand,
    block: Block
}

export type Stat_If = {
    read kind: "if",
    read ifs: { If },
    read fallback: Block?
}

export type Stat_While = {
    read kind: "while",
    read expression: ExpressionOrCommand,
    read block: Block
}

export type Stat_For = {
    read kind: "for",
    read expression: ExpressionOrCommand,
    read call: FunctionBody
}

export type Statement =
    | Stat_If
    | Stat_While
    | Stat_For
    | Stat_Assign
    | Command

export type Block = {
    read body: { Statement },
    read last_statement: LastStatement?
}

-- Compiler / VM

-- Pushes a number onto the stack
export type Instruction_PushNumber = {
    kind: "push_number",
    n: number
}

-- Pushes a boolean onto the stack
export type Instruction_PushBoolean = {
    kind: "push_boolean",
    b: boolean
}

-- Pushes a string onto the stack
export type Instruction_PushString = {
    kind: "push_string",
    s: string
}

-- Pushes a table onto the stack
export type Instruction_PushTable = {
    kind: "push_table",
    alloc: number
}

-- Pushes a function with the given body onto the stack
export type Instruction_PushFunction = {
    kind: "push_function",
    arguments: number,
    body: { Instruction }
}

-- Pushes nil onto the stack
export type Instruction_PushNil = {
    kind: "push_nil"
}

-- Pushes a global onto the stack
export type Instruction_PushGlobal = {
    kind: "push_global",
    name: string
}

-- Pushes a cmd onto the stack
export type Instruction_PushCommand = {
    kind: "push_cmd",
    name: string
}

-- Pushes a local onto the stack
export type Instruction_PushLocal = {
    kind: "push_local",
    index: number
}

-- Consumes n arguments and consumes the function and calls it with the function.
-- If the function returns values, it pushes them onto the stack without limit or
-- when results is reached.
export type Instruction_Call = {
    kind: "call",
    arguments: number,
    results: number,
}

-- Consumes key and table and pushes the value onto the stack.
export type Instruction_Index = {
    kind: "index"
}

-- Does t[k] = v where t is at index, v = at the top and k is below the top.
-- Pops k and v.
export type Instruction_SetTable = {
    kind: "set_table",
}

-- Pops a value from the stack and sets it as the new value of name.
export type Instruction_SetGlobal = {
    kind: "set_global",
    name: string
}

-- Pops a value from the stack and sets it as the new value of index
export type Instruction_SetLocal = {
    kind: "set_local",
    index: number
}

-- If the previous value is not truthy jumps to fail and clears the stack.
export type Instruction_If = {
    kind: "jump_if",
    to: number
}

-- If a value at index is not nil, jumps to ok, otherwise jumps to fail.
-- When jumping to fail, pops all values from the stack.
export type Instruction_IfNotNil = {
    kind: "jump_if_not_nil",
    index: number,
    to: number
}

-- Pops a function. Runs the given conditions until it returns false.
-- Simliar to for ... in condition() do lambda()
export type Instruction_Goto = {
    kind: "goto",
    to: number,
}

export type Instruction_GotoTemp = {
    kind: "goto-pending",
    type: "break" | "next-if" | "if-end"
}

export type Instruction_Return = {
    kind: "return"
}

export type Instruction =
    | Instruction_PushNumber
    | Instruction_PushBoolean
    | Instruction_PushString
    | Instruction_PushTable
    | Instruction_PushFunction
    | Instruction_PushNil
    | Instruction_PushGlobal
    | Instruction_PushLocal
    | Instruction_PushCommand
    | Instruction_Call
    | Instruction_SetTable
    | Instruction_SetGlobal
    | Instruction_SetLocal
    | Instruction_Goto
    | Instruction_If
    | Instruction_Index
    | Instruction_IfNotNil
    | Instruction_GotoTemp
    | Instruction_Return

-- VM

export type VirtualMachine = {
    globals: { [string]: unknown },
    locals: { [number]: unknown },
    stack: { [number]: unknown },
    commands: { [string]: unknown },
}

-- Analysis

export type Type_General<T=string> = {
    kind: "misc",
    type: T,
}

export type Type_Enum = {
    kind: "enum",
    options: { string },
    name: string?,
    description: string?
}

export type Type_Argument<T> = {
    name: string,
    description: string?,
    type: T
}
export type Type_Function = {
    kind: "function",
    name: string,
    description: string?,
    arguments: { Type_Argument<Type> },
    returns: { Type_General }
}

export type Type = 
    | Type_General
    | Type_Enum

return {}