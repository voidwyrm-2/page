import std/[
  strutils,
  enumerate,
  strformat,
  sequtils
]

import common


let lib* = newDict(0)

template addV(name, doc: string, item: Value) =
  addV(lib, name, doc, item)

template addF(name, doc: string, args: ProcArgs, body: untyped) =
  addF(lib, name, doc, args, body)

template addS(name, doc: string, args: ProcArgs, body: string) =
  addS(lib, "strings.pg", name, doc, args, body)


addF("chars",
"""
'chars'
S -> list(str)
Separates a string S into a list L of character strings.
""", @[("S", tString)]):
  let str = s.pop().strv

  var chars = newSeq[Value](str.len)

  for (i, ch) in enumerate(str):
    chars[i] = newString($ch)

  s.push(newList(chars))

addF("split",
"""
'split'
S D -> list(str)
Separates a string S into a list L of parts by a delimiter D.
""", @[("S", tString), ("D", tString)]):
  let
    delim = s.pop().strv
    str = s.pop().strv

  var parts: seq[Value]

  for part in str.split(delim):
    parts.add(newString(part))

  s.push(newList(parts))

addF("replace",
"""
'replace'
S Old New -> S'
Replaces all occurences of Old with New in a string S.
""", @[("S", tString), ("Old", tString), ("New", tString)]):
  let
    new = s.pop().strv
    old = s.pop().strv
    str = s.pop().strv

  s.push(newString(str.replaceWord(old, new)))

addF("joins",
"""
'joins'
L D -> str
Combines a list of strings L into a single string S, separated by delimiter D.
""", @[("L", tList), ("D", tString)]):
  let
    delim = s.pop().strv
    l = s.pop().listv

  var strs = newSeqOfCap[string](l.len)

  for v in l:
    if v isnot tString:
      raise newPgError("List argument for 'joins' must be only strings")
    
    strs.add(v.strv)

  s.push(newString(strs.join(delim)))

addS("join",
"""
L -> str
Joins a list of strings end to end.
""", @[("L", tList)]):
  "() joins"

addF("lower",
"""
S -> S'
Sets all the ASCII letters of a string to lowercase and returns the resulting string.
""", @[("S", tString)]):
  let str = s.pop().strv

  s.push(newString(str.toLowerAscii()))

addF("upper",
"""
S -> S'
Sets all the ASCII letters of a string to uppercase and returns the resulting string.
""", @[("S", tString)]):
  let str = s.pop().strv

  s.push(newString(str.toUpperAscii()))

addF("alpha?",
"""
S -> bool
Returns true if a string only contains characters a-z and A-Z.
""", @[("S", tString)]):
  let str = s.pop().strv

  s.push(newBool(str.all(isAlphaAscii)))

addF("digit?",
"""
S -> bool
Returns true if a string only contains characters 0-9.
""", @[("S", tString)]):
  let str = s.pop().strv

  s.push(newBool(str.all(isDigit)))

addS("alphadigit?",
"""
S -> bool
Returns true if a string only contains characters a-z, A-Z, and 0-9.
""", @[("S", tString)]):
  "dup alpha? exch digit? or"


# string builder operators

const objectIdStringBuilder = "StringBuilder"

func checkStringBuilder*(val: Value) =
  if val.typ != tExtitem:
    panic("'val' is not an Extitem")

  if val isnot objectIdStringBuilder:
    raise newPgError("Given object is not a StringBuilder object")

addF("sb-init",
"""
'sb-init'
S -> SB
Returns a new StringBuilder with a specified size S.
""", @[("S", tInteger)]):
  let
    size = s.pop().intv

    sbPtr = allocZ(seq[char])
    sbobj = newExtitem(cast[uint64](sbPtr))

  s.g.cleanup.add(proc() = dealloc(sbPtr))

  sbPtr[] = newSeqOfCap[char](size)

  sbobj.id = objectIdStringBuilder
  sbobj.fmtf = func(obj: uint64): string =
    let sb = cast[ptr seq[char]](sbobj.dat)
    fmt"StringBuilder of cap {sb[].capacity} and length {sb[].len}"
  
  s.push(sbobj)

addF("sb-addstr",
"""
'sb-addstr'
S SB ->
Appends a string S to the buffer of a StringBuilder SB.
""", @[("S", tString), ("SB", tExtitem)]):
  let
    sbobj = s.pop()
    str = s.pop().strv

  sbobj.checkStringBuilder()

  let sb = cast[ptr seq[char]](sbobj.dat)

  sb[].add(str)

addF("sb-addbyte",
"""
'sb-addbyte'
B SB ->
Appends an integer B as a byte to the buffer of a StringBuilder SB.
An error is thrown if B is not representable by a byte.
""", @[("S", tInteger), ("SB", tExtitem)]):
  let
    sbobj = s.pop()
    b = s.pop().intv

  sbobj.checkStringBuilder()

  if b > high(char).int or b < 0:
    raise newPgError(fmt"'{b}' is not representable by a byte")

  let sb = cast[ptr seq[char]](sbobj.dat)

  sb[].add(b.char)

addF("sb-build",
"""
'sb-build'
SB -> str
Builds a string from a StringBuilder SB.
""", @[("SB", tExtitem)]):
  let sbobj = s.pop()

  sbobj.checkStringBuilder()

  let sb = cast[ptr seq[char]](sbobj.dat)

  s.push(newString(cast[string](sb[])))
