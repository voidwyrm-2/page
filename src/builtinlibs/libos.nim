import std/[
  os,
  sequtils
]

import
  common,
  libio


let lib* = newDict(0)

template addV(name, doc: string, item: Value) =
  addV(lib, name, doc, item)

template addF(name, doc: string, args: ProcArgs, body: untyped) =
  addF(lib, name, doc, args, body)

template addS(name, doc: string, args: ProcArgs, body: string) =
  addS(lib, "os.pg", name, doc, args, body)


let
  pgStdin* = stdin.newPgFile("stdin")
  pgStdout* = stdout.newPgFile("stdout")
  pgStderr* = stderr.newPgFile("stderr")


addV("stdin",
"""
'stdin'
-> F
Returns the file object for STDIN.
"""):
  pgStdin

addV("stdout",
"""
'stdout'
-> F
Returns the file object for STDOUT.
"""):
  pgStdout

addV("stderr",
"""
'stderr'
-> F
Returns the file object for STDERR.
"""):
  pgStderr

addF("exe",
"""
'exe'
-> S
Returns the path to the interpreter executable.
""", @[]):
  s.push(newString(s.g.exe))

addF("file",
"""
'file'
-> S
Returns the path to the current file.
""", @[]):
  s.push(newString(s.g.file))

addF("argv",
"""
'argv'
-> L
Returns the program arguments.
""", @[]):
  s.push(newList(s.g.args.map(newString)))

addF("env>",
"""
'env>'
S -> V
Returns the value of an enviroment variable specified by a string S.
If the enviroment variable doesn't exist, an empty string is returned;
use 'env?>' to check if the enviroment is empty or doesn't exist.
""", @[("S", tString)]):
  let
    k = s.pop().strv
    ev = getEnv(k)

  s.push(newString(ev))

addF("env?>",
"""
'env?>'
S -> V?
Returns the value of an enviroment variable specified by a string S.
If the enviroment variable doesn't exist, null is returned.
""", @[("S", tString)]):
  let
    k = s.pop().strv
    ev =
      if existsEnv(k):
        newString(getEnv(k))
      else:
        nullSingleton

  s.push(ev)

addF(">env",
"""
'>env'
S V ->
Sets an enviroment variable specified by a string S to a string value V.
""", @[("S", tString), ("V", tString)]):
  let
    v = s.pop().strv
    k = s.pop().strv

  try:
    putEnv(k, v)
  except OSError as e:
    raise newPgError(e.msg)
