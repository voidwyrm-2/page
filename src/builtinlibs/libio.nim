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


const ObjectIdFile = "FILE"


func newPgFile*(f: File, path: string): Value =
  result = newExtitem(cast[pointer](f))
  
  let fname = fmt"File object at '{path}'"

  result.id = ObjectIdFile
  result.fmtf = func(_: pointer): string = fname

func checkPgFile*(val: Value) =
  if val.typ != tExtitem:
    panic("'val' is not an Extitem")

  if val isnot ObjectIdFile:
    raise newPgError("Given object is not a File object")


addF("f-open",
"""
'f-open'
P M -> FILE
Opens a filepath P with the specified mode symbol M and returns its file object F.
The valid modes are:
- /r (read); opens the file for reading, throws an error if the file doesn't exist.
- /w (write); opens the file for writing, throws an error if the file doesn't exist.
- /rw (readwrite); opens the file for reading and writing, throws an error if the file doesn't exist.
- /a (append); opens the file for writing and appends to the end of the file when written to, throws an error if the file doesn't exist.
- /c (create); opens the file for reading and writing, creates the file if it doesn't exist.
""", @[("P", tString), ("M", tSymbol)]):
  let modeName = s.pop().strv

  var
    path = s.pop().strv

    mode: FileMode
    f: File

  if path.len > 0 and path[0] != '/':
    path = s.g.cwd / path

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
FILE ->
Closes a file object.
Trying to use a file object after it was closed is undefined behavior.
""", @[("FILE", tExtitem)]):
  let fobj = s.pop()

  fobj.checkPgFile()

  let f = cast[File](fobj.dat)

  f.close()

addF("f-eof?",
"""
'f-eof?'
FILE -> bool
Returns true if a file has reached EOF; false otherwise.
""", @[("FILE", tExtitem)]):
  let fobj = s.pop()

  fobj.checkPgFile()

  let f = cast[File](fobj.dat)

  s.push(if f.endOfFile(): trueSingleton else: falseSingleton)

addF("f-readbyte",
"""
'f-readbyte'
FILE -> int
Reads a byte from a file and returns it as an integer.
""", @[("FILE", tExtitem)]):
  let fobj = s.pop()

  fobj.checkPgFile()

  let f = cast[File](fobj.dat)

  var b: byte
  try:
    b = f.readChar().byte
  except IoError as e:
    raise newPgError(e.msg)

  s.push(newInteger(b.int))

addF("f-readall",
"""
'f-readall'
FILE -> str
Reads everything from a file object and returns the contents as a string.
""", @[("FILE", tExtitem)]):
  let fobj = s.pop()

  fobj.checkPgFile()

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
FILE S -> int
Writes a string S to a file object and returns the amount written.
""", @[("FILE", tExtitem), ("S", tString)]):
  let
    str = s.pop().strv
    fobj = s.pop()

  fobj.checkPgFile()

  let f = cast[File](fobj.dat)

  try:
    let b = f.writeBuffer(str[0].addr, str.len)
    s.push(newInteger(b))
  except IoError as e:
    raise newPgError(e.msg)
