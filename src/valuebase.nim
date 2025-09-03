import
  std/strformat

import
  general

type
  NpsType* = enum
    tBase,
    tAny,
    tBool,
    tSymbol,
    tString,
    tNumber,
    tList,
    tDict,
    tFunction

  NpsValue* = ref object of RootObj
    kind*: NpsType = tBase

func `$`*(self: NpsType): string =
  case self
  of tBase:
    raise newException(Exception, "tBase should not be formatted")
  of tAny:
    "Any"
  of tBool:
    "Bool"
  of tSymbol:
    "Symbol"
  of tString:
    "String"
  of tNumber:
    "Number"
  of tList:
    "List"
  of tDict:
    "Dict"
  of tFunction:
    "Function"

proc unsOp*(a: NpsValue, op: string, b: NpsValue) {.noReturn.} =
  raise newNpsError(fmt"Unsupported types for operation '{op}': {a.kind} and {b.kind}")

func `==`*(a: NpsValue, b: NpsType): bool =
  a.kind == b or b == NpsType.tAny

method copy*(self: NpsValue): NpsValue {.base.} =
  NpsValue(kind: self.kind)

method `+`*(self: NpsValue, other: NpsValue): NpsValue {.base.} =
  unsOp(self, "add", other)

method `-`*(self: NpsValue, other: NpsValue): NpsValue {.base.} =
  unsOp(self, "sub", other)

method `*`*(self: NpsValue, other: NpsValue): NpsValue {.base.} =
  unsOp(self, "mul", other)

method `/`*(self: NpsValue, other: NpsValue): NpsValue {.base.} =
  unsOp(self, "div", other)

method `==`*(self: NpsValue, other: NpsValue): bool {.base.} =
  false

method `!=`*(self: NpsValue, other: NpsValue): bool {.base.} =
  not (self == other)

method `>`*(self: NpsValue, other: NpsValue): bool {.base.} =
  unsOp(self, "gt", other)

method `>=`*(self: NpsValue, other: NpsValue): bool {.base.} =
  self > other or self == other

method `<`*(self: NpsValue, other: NpsValue): bool {.base.} =
  unsOp(self, "lt", other)

method `<=`*(self: NpsValue, other: NpsValue): bool {.base.} =
  self < other or self == other

method format*(self: NpsValue): string {.base.} =
  "--nostringval--"

method debug*(self: NpsValue): string {.base.} =
  "<base>"

method `$`*(self: NpsValue): string {.base.} =
  self.format()
