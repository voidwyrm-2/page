import std/[
  tables,
  strutils
]

import
  ../values,
  ../state,
  common


let lib* = newDict(0)

template addV(name, doc: string, item: NpsValue) =
  addV(lib, name, doc, item)

template addF(name, doc: string, args: FuncArgs, body: untyped) =
  addF(lib, name, doc, args, body)

template addS(name, doc: string, args: FuncArgs, body: string) =
  addS(lib, "strings.nps", name, doc, args, body)


addF("chars", """
'chars'
S -> L
Separates a string S into a list L of character strings.
""", @[("S", tString)]):
  let str = String(s.pop()).value

  var chars: seq[NpsValue]

  for ch in str:
    chars.add(newNpsString($ch))

  s.push(newNpsList(chars))

addF("split", """
'split'
S D -> L
Separates a string S into a list L of parts by a delimiter D.
""", @[("S", tString), ("D", tString)]):
  let
    delim = String(s.pop()).value
    str = String(s.pop()).value

  var parts: seq[NpsValue]

  for part in str.split(delim):
    parts.add(newNpsString(part))

  s.push(newNpsList(parts))

addF("replace", """
'replace'
S Old New -> S'
Replaces all occurences of Old with New in a string S.
""", @[("S", tString), ("Old", tString), ("New", tString)]):
  let
    new = String(s.pop()).value
    old = String(s.pop()).value
    str = String(s.pop()).value

  s.push(newNpsString(str.replaceWord(old, new)))

addF("joins", """
'joins'
L D -> S
Combines a list of strings L into a single string S, separated by delimiter D.
""", @[("L", tList), ("D", tString)]):
  let
    delim = String(s.pop()).value
    l = List(s.pop()).value

  var strs = newSeqOfCap[string](l.len)

  for v in l:
    if v.kind != tString:
      raise newNpsError("List argument for 'joins' must be only strings")
    
    strs.add(String(v).value)

  s.push(newNpsString(strs.join(delim)))

addS("join", """
L -> S
""", @[("L", tList)]):
  "() joins"
