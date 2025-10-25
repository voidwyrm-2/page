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
  pgStdout* = stdin.newPgFile("stdout")
  pgStderr* = stdin.newPgFile("stderr")


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
