import
  std/strformat

import
  general

type
  NpsType* = enum
    tBase,
    tAny,
    tNull,
    tSymbol,
    tString,
    tNumber,
    tList,
    tDict,
    tFunction

  NpsValue* = ref object of RootObj
    kind*: NpsType = tBase

func unsOp*(a: NpsValue, op: string, b: NpsValue): ref NpsError =
  newNpsError(fmt"Unsupported types for operation '{op}': {a.kind} and {b.kind}")

func `==`*(a: NpsValue, b: NpsType): bool =
  a.kind == b or b == NpsType.tAny

method copy*(self: NpsValue): NpsValue {.base.} =
  NpsValue(kind: self.kind)

method `+`*(self: NpsValue, other: NpsValue): NpsValue {.base.} =
  raise unsOp(self, "+", other)

method `-`*(self: NpsValue, other: NpsValue): NpsValue {.base.} =
  raise unsOp(self, "-", other)

method `*`*(self: NpsValue, other: NpsValue): NpsValue {.base.} =
  raise unsOp(self, "*", other)

method `/`*(self: NpsValue, other: NpsValue): NpsValue {.base.} =
  raise unsOp(self, "/", other)

method format*(self: NpsValue): string {.base.} =
  "<nostringval>"

method debug*(self: NpsValue): string {.base.} =
  "<base>"

func `$`*(self: NpsValue): string =
  self.format()
