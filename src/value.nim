import std/[
  strutils,
  algorithm,
  math,
  tables,
  strformat,
  sequtils,
  macros,
  enumerate
]

import
  general,
  lexer,
  parser

export general


type
  Type* {.size: 1.} = enum
    tNull     = 0,
    tBool     = 0b1,
    tSymbol   = 0b10,
    tString   = 0b100,
    tInteger  = 0b1000,
    tReal     = 0b10000,
    tList     = 0b100000,
    tDict     = 0b1000000,
    tProcedure = 0b10000000

  Runner* = proc(nodes: seq[Node])
  NativeProc* = proc(s: pointer, r: Runner)
  ProcArgs* = seq[tuple[name: string, typ: Type]]

  Dict* = TableRef[string, Value]

  ProcType* = enum
    ptNative,
    ptComposite,
    ptLiteral

  Value* = ref object
    doc*: string
    case typ: Type
    of tNull:
      discard
    of tBool:
      boolVal: bool
    of tSymbol, tString:
      strVal: string
    of tInteger:
      intVal: int
    of tReal:
      realVal: float
    of tList:
      listVal: seq[Value]
    of tDict:
      dictVal: Dict
    of tProcedure:
      args*: ProcArgs
      case ptype: ProcType
      of ptNative:
        native: NativeProc
      of ptComposite:
        nodes: seq[Node]
      of ptLiteral:
        values: seq[Value]


const tAny* = Type(255)


func `or`*(a, b: Type): Type =
  Type(uint8(a) or uint8(b))

func `and`*(a, b: Type): Type =
  Type(uint8(a) and uint8(b))

func `is`*(a: Value, b: Type): bool =
  (a.typ and b) != tNull or (a.typ == tNull and b == tNull)

func `isnot`*(a: Value, b: Type): bool =
  not (a is b)

func toType*(str: string): Type =
  case str
  of "Null":
    tNull
  of "Bool":
    tBool
  of "Symbol":
    tSymbol
  of "String":
    tString
  of "Integer":
    tInteger
  of "Real":
    tReal
  of "List":
    tList
  of "Dict":
    tDict
  of "Procedure":
    tProcedure
  of "Any":
    tAny
  else:
    raise newPgError(fmt"Invalid type '{str}'")

func `$`*(self: Type): string =
  case self
  of tNull:
    "Null"
  of tBool:
    "Bool"
  of tSymbol:
    "Symbol"
  of tString:
    "String"
  of tInteger:
    "Integer"
  of tReal:
    "Real"
  of tList:
    "List"
  of tDict:
    "Dict"
  of tProcedure:
    "Procedure"
  else: # To account for type unions
    let n = uint8(self)
    case n
    of 255:
      "Any"
    else:
      ""


const tNumber* = tInteger or tReal


func newProcArgs*(size: Natural): ProcArgs =
  newSeq[tuple[name: string, typ: Type]]()


func newNull*(): Value =
  Value(typ: tNull)

func newBool*(value: bool): Value =
  Value(typ: tBool, boolVal: value)

func newSymbol*(value: string): Value =
  Value(typ: tSymbol, strVal: value)

func newString*(value: string): Value =
  Value(typ: tString, strVal: value)

func newInteger*(value: int): Value =
  Value(typ: tInteger, intVal: value)

func newReal*(value: float): Value =
  Value(typ: tReal, realVal: value)

func newList*(values: seq[Value]): Value =
  Value(typ: tList, listVal: values)

func newList*(values: varargs[Value]): Value =
  Value(typ: tList, listVal: values.toSeq)

func newList*(len: Natural): Value =
  var items = newSeq[Value](len)

  for i in 0..<len:
    items[i] = newNull()
  
  result = newList(items)

func newDictionary*(value: Dict): Value =
  Value(typ: tDict, dictVal: value)

proc newProcedure*(args: ProcArgs, native: NativeProc): Value =
  Value(typ: tProcedure, args: args.reversed(), ptype: ptNative, native: native)

proc newProcedure*(args: ProcArgs, nodes: seq[Node]): Value =
  Value(typ: tProcedure, args: args.reversed(), ptype: ptComposite, nodes: nodes)

proc newProcedure*(nodes: seq[Node]): Value =
  newProcedure(@[], nodes)

proc newProcedure*(args: ProcArgs, file, text: string): Value =
  var
    lexer = newLexer(file, text)
    parser = newParser(lexer.lex())

  newProcedure(args, parser.parse())

proc newProcedure*(original: Value, values: seq[Value]): Value =
  Value(typ: tProcedure, args: original.args, ptype: ptLiteral, values: values)


func typ*(self: Value): Type =
  self.typ

func boolv*(self: Value): bool =
  self.boolVal

func strv*(self: Value): string =
  self.strVal

func intv*(self: Value): int =
  self.intVal

func realv*(self: Value): float =
  self.realVal

func listv*(self: Value): seq[Value] =
  self.listVal

func dictv*(self: Value): Dict =
  self.dictVal

func nodes*(self: Value): seq[Node] =
  self.nodes

func values*(self: Value): seq[Value] =
  self.values


func checklen(self: Value, ind: Natural) =
  if self.listVal.len < ind:
    raise newPgError(fmt"Index '{ind}' not in range for the list of length {self.listVal.len}")
  elif ind < 0:
    raise newPgError(fmt"List indexes cannot be negative")

func `[]`*(self: Value, ind: int): Value =
  self.checklen(ind)
  self.listVal[ind]

func `[]=`*(self: Value, ind: int, val: Value) =
  self.checklen(ind)
  self.listVal[ind] = val


proc ptype*(self: Value): ProcType =
  self.ptype

proc run*(self: Value, s: pointer, r: Runner) =
  if self.ptype == ptNative:
    self.native(s, r)
  elif self.ptype == ptComposite:
    if self.nodes.len > 0:
      r(self.nodes)
  elif self.ptype == ptLiteral:
    panic(fmt"Literal procedures cannot be executed via 'run'")
  else:
    panic("Unreachable with '" & $self.ptype & "', literal of " & $uint8(self.ptype))


proc unsOp*(a: Value, op: string, b: Value) {.noReturn.} =
  raise newPgError(fmt"Unsupported types for operation '{op}': {a.typ} and {b.typ}")

template valueNumOp(name: string, op: untyped): untyped =
  select (self.typ, other.typ):
    maybe (tInteger, tInteger):
      return newInteger(op(self.intVal, other.intVal))
    maybe (tReal, tReal):
      return newReal(op(self.realVal, other.realVal))
    maybe (tInteger, tReal):
      return newReal(op(float(self.intVal), other.realVal))
    maybe (tReal, tInteger):
      return newReal(op(self.realVal, float(other.intVal)))
    maybe (_, _):
      unsOp(self, name, other)

proc `+`*(self: Value, other: Value): Value =
  valueNumOp("add", `+`)

proc `-`*(self: Value, other: Value): Value =
  valueNumOp("add", `-`)
  unsOp(self, "sub", other)

proc `*`*(self: Value, other: Value): Value =
  valueNumOp("mul", `*`)

proc `/`*(self: Value, other: Value): Value =
  func `/`(a, b: int): int = a div b
  valueNumOp("div", `/`)

proc `//`*(self: Value, other: Value): Value =
  select (self.typ, other.typ):
    maybe (tInteger, tInteger):
      return newInteger(int(self.intVal div other.intVal))
    maybe (tReal, tReal):
      return newInteger(int(self.realVal / other.realVal))
    maybe (tInteger, tReal):
      return newInteger(int(float(self.intVal) / other.realVal))
    maybe (tReal, tInteger):
      return newInteger(int(self.realVal / float(other.intVal)))
    maybe (_, _):
      unsOp(self, "idiv", other)

proc `%`*(self: Value, other: Value): Value =
  valueNumOp("mod", `mod`)

proc `^`*(self: Value, other: Value): Value =
  valueNumOp("exp", `^`)

func `==`*(self: Value, other: Value): bool =
  select (self.typ, other.typ):
    maybe (tNull, tNull):
      return true
    maybe (tBool, tBool):
      return self.boolVal == other.boolVal
    maybe (tSymbol, tSymbol):
      return self.strVal == other.strVal
    maybe (tString, tString):
      return self.strVal == other.strVal
    maybe (tInteger, tInteger):
      return self.intVal == other.intVal
    maybe (tReal, tReal):
      return self.realVal == other.realVal
    maybe (tInteger, tReal):
      return float(self.intVal) == other.realVal
    maybe (tReal, tInteger):
      return self.realVal == float(other.intVal)
    maybe (_, _):
      return cast[pointer](self) == cast[pointer](other)

func `!=`*(self: Value, other: Value): bool =
  not (self == other)

proc `>`*(self: Value, other: Value): bool =
  select (self.typ, other.typ):
    maybe (tInteger, tInteger):
      return self.intVal > other.intVal
    maybe (tReal, tReal):
      return self.realVal > other.realVal
    maybe (tInteger, tReal):
      return float(self.intVal) > other.realVal
    maybe (tReal, tInteger):
      return self.realVal > float(other.intVal)
    maybe (_, _):
      unsOp(self, "gt", other)

proc `>=`*(self: Value, other: Value): bool =
  self > other or self == other

proc `<`*(self: Value, other: Value): bool =
  select (self.typ, other.typ):
    maybe (tInteger, tInteger):
      return self.intVal < other.intVal
    maybe (tReal, tReal):
      return self.realVal < other.realVal
    maybe (tInteger, tReal):
      return float(self.intVal) < other.realVal
    maybe (tReal, tInteger):
      return self.realVal < float(other.intVal)
    maybe (_, _):
      unsOp(self, "lt", other)

proc `<=`*(self: Value, other: Value): bool =
  self < other or self == other

func len*(self: Value): int =
  case self.typ
  of tString:
    self.strVal.len
  of tList:
    self.listVal.len
  of tDict:
    self.dictVal.len
  else:
    raise newPgError(fmt"operator 'length' cannot be used on {self.typ}")

func format*(self: Value): string =
  case self.typ
  of tNull:
    "null"
  of tBool:
    $self.boolVal
  of tSymbol, tString:
    self.strVal
  of tInteger:
    $self.intVal
  of tReal:
    var s = $self.realVal
    s.trimZeros('.')
    s
  else:
    "--nostringval--"

func debug*(self: Value): string =
  case self.typ
  of tSymbol:
    "/" & self.strVal
  of tString:
    "(" & self.strVal & ")"
  of tList:
    "[" & self.listVal.mapIt(it.debug()).join(" ") & "]"
  of tDict:
    "-dict-"
  of tProcedure:
    case self.ptype:
    of ptNative:
      "<native function>"
    of ptComposite:
      "{" & self.nodes.mapIt(it.dbgLit).join(" ") & "}"
    of ptLiteral:
      "{" & self.values.mapIt(it.debug()).join(" ") & "}"
  else:
    self.format()

func `$`*(self: Value): string =
  self.format()
