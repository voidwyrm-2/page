import
  std/sugar,
  std/strutils,
  std/algorithm

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
    npsbool,
    npssymbol,
    npsstring,
    npsnumber,
    npslist,
    npsdict,
    npsfunction
  ]
