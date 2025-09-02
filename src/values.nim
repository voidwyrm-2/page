import
  std/sugar,
  std/strutils

import
  valuebase,
  state,
  lexer,
  parser

export
  general,
  valuebase

include
  valueimpls / [
    npssymbol,
    npsstring,
    npsnumber,
    npsfunction
  ]

type
  Null* = ref object of NpsValue

func newNpsNull*(): Null =
  Null(kind: tNull)

method debug*(self: Null): string =
   "null"

func `$`*(self: Null): string =
  self.format()
