import std/[
  sugar,
  strutils,
  algorithm,
  math,
  tables,
  strformat,
  sequtils,
  macros
]

import
  general,
  lexer,
  parser,
  logging

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

  Value* = ref object
    doc*: string
    case kind: Type
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
      args: ProcArgs
      case isNative: bool
      of true:
        native: NativeProc
      of false:
        nodes: seq[Node]


const tAny* = Type(255)


func `or`*(a, b: Type): Type =
  Type(uint8(a) or uint8(b))

func `and`*(a, b: Type): Type =
  Type(uint8(a) and uint8(b))

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
    "Dictionary"
  of tProcedure:
    "Procedure"
  else:
    let n = uint8(self)
    case n
    of 255:
      "Any"
    else:
      raise newException(ValueError, fmt"Type value '{n}' is not formatable")


func newProcArgs*(size: Natural): ProcArgs =
  newSeq[tuple[name: string, typ: Type]]()


func newNull*(): Value =
  Value(kind: tNull)

func newBool*(value: bool): Value =
  Value(kind: tBool, boolVal: value)

func newSymbol*(value: string): Value =
  Value(kind: tSymbol, strVal: value)

func newString*(value: string): Value =
  Value(kind: tString, strVal: value)

func newInteger*(value: int): Value =
  Value(kind: tInteger, intVal: value)

func newReal*(value: float): Value =
  Value(kind: tReal, realVal: value)

func newList*(values: seq[Value]): Value =
  Value(kind: tList, listVal: values)

func newList*(values: varargs[Value]): Value =
  Value(kind: tList, listVal: values.toSeq)

func newList*(len: Natural): Value =
  var items = newSeq[Value](len)
  result = newList(items)

  for i in 0..<len:
    items[i] = newNull()

func newDictionary*(value: Dict): Value =
  Value(kind: tDict, dictVal: value)

proc newProcedure*(args: ProcArgs, native: NativeProc): Value =
  Value(kind: tProcedure, args: args.reversed(), isNative: true, native: native)

proc newProcedure*(args: ProcArgs, nodes: seq[Node]): Value =
  Value(kind: tProcedure, args: args.reversed(), isNative: false, nodes: nodes)

proc newProcedure*(nodes: seq[Node]): Value =
  newProcedure(@[], nodes)

proc newProcedure*(args: ProcArgs, file, text: string): Value =
  var
    lexer = newLexer(file, text)
    parser = newParser(lexer.lex())

  newProcedure(args, parser.parse())


func `is`*(a: Value, b: Type): bool =
  (a.kind and b) != tNull or (a.kind == tNull and b == tNull)

func `isnot`*(a: Value, b: Type): bool =
  not (a is b)


func kind*(self: Value): Type =
  self.kind

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

func checkInd(self: Value, ind: Natural) =
  if self.listVal.len < ind:
    raise newNpsError(fmt"Index '{ind}' not in range for the list of length {self.listVal.len}")

func `[]`*(self: Value, ind: int): Value =
  self.checkInd(ind)
  self.listVal[ind]

func `[]=`*(self: Value, ind: int, val: Value) =
  self.checkInd(ind)
  self.listVal[ind] = val


func args*(self: Value): ProcArgs =
  self.args

proc run*(self: Value, s: pointer, r: Runner) =
  if self.isNative:
    self.native(s, r)
  elif self.nodes.len > 0:
    r(self.nodes)


proc unsOp*(a: Value, op: string, b: Value) {.noReturn.} =
  raise newNpsError(fmt"Unsupported types for operation '{op}': {a.kind} and {b.kind}")

template valueNumOp(name: string, op: untyped): untyped =
  select (self.kind, other.kind):
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
  select (self.kind, other.kind):
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
  select (self.kind, other.kind):
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
  select (self.kind, other.kind):
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
  select (self.kind, other.kind):
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
  case self.kind
  of tString:
    self.strVal.len
  of tList:
    self.listVal.len
  of tDict:
    self.dictVal.len
  else:
    raise newNpsError(fmt"operator 'length' cannot be used on {self.kind}")

func format*(self: Value): string =
  case self.kind
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
  case self.kind
  of tSymbol:
    "/" & self.strVal
  of tString:
    "(" & self.strVal & ")"
  of tList:
    "[" & self.listVal.mapIt(it.debug()).join(" ") & "]"
  of tDict:
    "-dict-"
  of tProcedure:
    if self.isNative:
      "<native function>"
    else:
      "{" & self.nodes.mapIt(it.dbgLit).join(" ") & "}"
  else:
    self.format()

func `$`*(self: Value): string =
  self.format()
