import std/[
  strutils,
  strformat,
  os
]

import common


let lib* = newDict(0)

template addV(name, doc: string, item: Value) =
  addV(lib, name, doc, item)

template addF(name, doc: string, args: ProcArgs, body: untyped) =
  addF(lib, name, doc, args, body)

template addS(name, doc: string, args: ProcArgs, body: string) =
  addS(lib, "io.pg", name, doc, args, body)


func newPgFile*(f: File, path: string): Value =
  result = newExtitem(cast[pointer](f))
  
  let fname = fmt"File object at '{path}'"

  result.id = "File"
  result.fmtf = func(_: pointer): string = fname


addF("f-open",
"""
'f-open'
P M -> F
Opens a filepath P with the specified mode symbol M and returns its file object F.
The valid modes are:
- /r (read); opens the file for reading, throws an error if the file doesn't exist.
- /w (write); opens the file for writing, throws an error if the file doesn't exist.
- /rw (readwrite); opens the file for reading and writing, throws an error if the file doesn't exist.
- /a (append); opens the file for writing and appends to the end of the file when written to, throws an error if the file doesn't exist.
- /c (create); opens the file for reading and writing, creates the file if it doesn't exist.
""", @[("P", tString), ("M", tSymbol)]):
  let
    modeName = s.pop().strv
    path = s.pop().strv

  var
    mode: FileMode
    f: File

  case modeName
  of "r":
    mode = fmRead
  of "w":
    mode = fmWrite
  else:
    raise newPgError(fmt"Invalid file mode '{modeName}'")

  if not path.fileExists() and mode != fmReadWrite:
    raise newPgError(fmt"File '{path}' does not exist")

  if not f.open(path, mode):
    raise newPgError(fmt"File '{path}' could not be opened")

  s.push(f.newPgFile(path.absolutePath()))

addF("f-close",
"""
'f-close'
F ->
Closes a file object F.
Trying to use a file object after it was closed is undefined behavior.
""", @[("F", tExtitem)]):
  let fobj = s.pop()

  if fobj isnot "File":
    raise newPgError("Given object is not a File object")

  let f = cast[File](fobj.dat)

  f.close()

addF("f-read",
"""
'f-readall'
F -> S
Reads everything from a file object F and returns the contents S.
""", @[("F", tExtitem)]):
  let fobj = s.pop()

  if fobj isnot "File":
    raise newPgError("Given object is not a File object")

  let f = cast[File](fobj.dat)

  var content: string

  try:
    content = f.readAll()
  except IoError as e:
    raise newPgError(e.msg)

  s.push(newString(content))

addF("f-write",
"""
'f-write'
F S -> WS
Writes a string S to a file object F and returns the amount written WS.
""", @[("F", tExtitem), ("S", tString)]):
  let
    str = s.pop().strv
    fobj = s.pop()

  if fobj isnot "File":
    raise newPgError("Given object is not a File object")

  let f = cast[File](fobj.dat)

  try:
    let b = f.writeBuffer(str[0].addr, str.len)
    s.push(newInteger(b))
  except IoError as e:
    raise newPgError(e.msg)
