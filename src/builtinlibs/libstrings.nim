import std/[
  strutils,
  enumerate
]

import common


let lib* = newDict(0)

template addV(name, doc: string, item: Value) =
  addV(lib, name, doc, item)

template addF(name, doc: string, args: ProcArgs, body: untyped) =
  addF(lib, name, doc, args, body)

template addS(name, doc: string, args: ProcArgs, body: string) =
  addS(lib, "strings.nps", name, doc, args, body)


addF("chars", """
'chars'
S -> L
Separates a string S into a list L of character strings.
""", @[("S", tString)]):
  let str = s.pop().strv

  var chars = newSeq[Value](str.len)

  for (i, ch) in enumerate(str):
    chars[i] = newString($ch)

  s.push(newList(chars))

addF("split", """
'split'
S D -> L
Separates a string S into a list L of parts by a delimiter D.
""", @[("S", tString), ("D", tString)]):
  let
    delim = s.pop().strv
    str = s.pop().strv

  var parts: seq[Value]

  for part in str.split(delim):
    parts.add(newString(part))

  s.push(newList(parts))

addF("replace", """
'replace'
S Old New -> S'
Replaces all occurences of Old with New in a string S.
""", @[("S", tString), ("Old", tString), ("New", tString)]):
  let
    new = s.pop().strv
    old = s.pop().strv
    str = s.pop().strv

  s.push(newString(str.replaceWord(old, new)))

addF("joins", """
'joins'
L D -> S
Combines a list of strings L into a single string S, separated by delimiter D.
""", @[("L", tList), ("D", tString)]):
  let
    delim = s.pop().strv
    l = s.pop().listv

  var strs = newSeqOfCap[string](l.len)

  for v in l:
    if v.typ != tString:
      raise newNpsError("List argument for 'joins' must be only strings")
    
    strs.add(v.strv)

  s.push(newString(strs.join(delim)))

addS("join", """
L -> S
""", @[("L", tList)]):
  "() joins"
