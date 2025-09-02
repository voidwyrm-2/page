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
    npslist,
    npsfunction
  ]
