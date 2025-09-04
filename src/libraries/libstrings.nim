import
  std/tables,
  std/strutils

import
  ../values,
  ../state,
  common

let lib* = newDict(0)

template addV(name: string, item: NpsValue) =
  addV(lib, name, item)

template addF(name: string, args: openArray[NpsType], s, r, body: untyped) =
  addF(lib, name, args, s, r, body)


# S -> L
# Separates a string S into a list L of character strings.
addF("chars", @[tString], s, _):
  let str = String(s.pop()).value()

  var chars: seq[NpsValue]

  for ch in str:
    chars.add(newNpsString($ch))

  s.push(newNpsList(chars))

# S D -> L
# Separates a string S by a delimiter D.
addF("split", @[tString, tString], s, _):
  let
    delim = String(s.pop()).value()
    str = String(s.pop()).value()

  var parts: seq[NpsValue]

  for part in str.split(delim):
    parts.add(newNpsString(part))

  s.push(newNpsList(parts))
