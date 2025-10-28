import std/[
  strutils,
  algorithm,
  math,
  tables,
  strformat,
  sequtils,
  macros,
  random
]

import
  general,
  lexer,
  parser

export
  general,
  random


type
  Type* {.size: 2.} = enum
    tInvalid    = 0b0,
    tNull      = 0b1,
    tBool      = 0b10,
    tSymbol    = 0b100,
    tString    = 0b1000,
    tInteger   = 0b10000,
    tReal      = 0b100000,
    tList      = 0b1000000,
    tDict      = 0b10000000,
    tProcedure = 0b100000000,
    tExtitem   = 0b1000000000

  Runner* = proc(nodes: seq[Node])

  ProcState* = ref object
    r*: Runner
    rand*: Rand
    deferred*: seq[seq[Value]]

  NativeProc* = proc(s: pointer, ps: ProcState)
  ProcArgs* = seq[tuple[name: string, typ: Type]]

  Dict* = TableRef[string, Value]

  ProcType* = enum
    ptNative,
    ptComposite,
    ptLiteral

  Value* = ref object
    doc*: string
    case typ: Type
    of tInvalid:
      discard
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
      lit*: bool
      case ptype: ProcType
      of ptNative:
        native: NativeProc
      of ptComposite:
        nodes: seq[Node]
      of ptLiteral:
        values: seq[Value]
    of tExtitem:
      id*: string
      dat*: pointer
      fmtf*: proc(dat: pointer): string {.noSideEffect.}

func `or`*(a, b: Type): Type =
  cast[Type](cast[uint16](a) or cast[uint16](b))

func `and`*(a, b: Type): Type =
  cast[Type](cast[uint16](a) and cast[uint16](b))

func `is`*(a: Value, b: Type): bool =
  (a.typ and b) != tInvalid

func `isnot`*(a: Value, b: Type): bool =
  not (a is b)

func `is`*(a: Value, id: string): bool =
  a.id == id

func `isnot`*(a: Value, id: string): bool =
  not (a is id)

const
  tAny* = tNull or tBool or tSymbol or tString or tInteger or tReal or tList or tDict or tProcedure or tExtitem
  tNumber* = tInteger or tReal

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
  of "Extitem":
    tExtitem
  of "Any":
    tAny
  else:
    raise newPgError(fmt"Invalid type '{str}'")

func `$`*(typ: Type): string =
  case typ
  of tNull:
    result = "Null"
  of tBool:
    result = "Bool"
  of tSymbol:
    result = "Symbol"
  of tString:
    result = "String"
  of tInteger:
    result = "Integer"
  of tReal:
    result = "Real"
  of tList:
    result = "List"
  of tDict:
    result = "Dict"
  of tProcedure:
    result = "Procedure"
  of tExtitem:
    result = "Extitem"
  else:
    var types = newSeqOfCap[Type](11)

    for i in 0..<11:
      let t = typ and cast[Type](1 shl i)
      if t != tInvalid:
        types.add(t)

    if types.len == 2:
      result = fmt"{types[0]} or {types[1]}"
    else:
      result = types[0..^2].map(`$`).join(", ")
      result &= ", or "
      result &= $types[^1]


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

proc newExtitem*(dat: pointer): Value =
  Value(typ: tExtitem, dat: dat)


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

proc run*(self: Value, s: pointer, ps: ProcState) =
  if self.ptype == ptNative:
    self.native(s, ps)
  elif self.ptype == ptComposite:
    if self.nodes.len > 0:
      ps.r(self.nodes)
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
  of tExtitem:
    if self.fmtf != nil:
      self.fmtf(self.dat)
    else:
      fmt"Ext@{cast[uint64](self.dat).toHex()}"
  else:
    self.format()

func `$`*(self: Value): string =
  self.format()
