import
  std/tables,
  std/strutils

import
  ../values,
  ../state,
  common

let lib* = newDict(0)

template addV(name: string, item: NpsValue, doc = "") =
  addV(lib, name, doc, item)

template addF(name: string, args: openArray[NpsType], body: untyped, doc = "") =
  addF(lib, name, doc, args, body)

template addS(name: string, args: openArray[NpsType], body: string, doc = "") =
  addS(lib, "strings.nps", name, doc, args, body)


# S -> L
# Separates a string S into a list L of character strings.
addF("chars", @[tString]):
  let str = String(s.pop()).value()

  var chars: seq[NpsValue]

  for ch in str:
    chars.add(newNpsString($ch))

  s.push(newNpsList(chars))

# S D -> L
# Separates a string S into a list L of parts by a delimiter D.
addF("split", @[tString, tString]):
  let
    delim = String(s.pop()).value()
    str = String(s.pop()).value()

  var parts: seq[NpsValue]

  for part in str.split(delim):
    parts.add(newNpsString(part))

  s.push(newNpsList(parts))

# L D -> S
# Combines a list of strings L into a single string S, separated by delimiter D.
addF("joins", @[tList, tString]):
  let
    delim = String(s.pop()).value()
    l = List(s.pop()).value()

  var strs = newSeqOfCap[string](l.len())

  for v in l:
    if v.kind != tString:
      raise newNpsError("List argument for 'joins' must be only strings")
    
    strs.add(String(v).value())

  s.push(newNpsString(strs.join(delim)))

addS("join", @[tList], "() joins")
