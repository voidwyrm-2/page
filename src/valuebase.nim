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

proc unsOp*(a: NpsValue, op: string, b: NpsValue) =
  raise newNpsError(fmt"Unsupported types for operation '{op}': {a.kind} and {b.kind}")

func `==`*(a: NpsValue, b: NpsType): bool =
  a.kind == b or b == NpsType.tAny

method copy*(self: NpsValue): NpsValue {.base.} =
  NpsValue(kind: self.kind)

method `+`*(self: NpsValue, other: NpsValue): NpsValue {.base.} =
  unsOp(self, "+", other)

method `-`*(self: NpsValue, other: NpsValue): NpsValue {.base.} =
  unsOp(self, "-", other)

method `*`*(self: NpsValue, other: NpsValue): NpsValue {.base.} =
  unsOp(self, "*", other)

method `/`*(self: NpsValue, other: NpsValue): NpsValue {.base.} =
  unsOp(self, "/", other)

method `==`*(self: NpsValue, other: NpsValue): bool {.base.} =
  false

method `!=`*(self: NpsValue, other: NpsValue): bool {.base.} =
  not (self == other)

method format*(self: NpsValue): string {.base.} =
  "--nostringval--"

method debug*(self: NpsValue): string {.base.} =
  "<base>"

method `$`*(self: NpsValue): string {.base.} =
  self.format()
