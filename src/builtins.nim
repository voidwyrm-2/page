import std/[
  tables,
  algorithm,
  strutils,
  strformat,
  random,
  os,
  sequtils,
  math
]

from system/nimscript import nil

import
  npsenv,
  general,
  state,
  values,
  lexer,
  logging,
  builtinlibs/[
    common,
    libstrings,
    libhttp
  ]

when defined(release):
  const buildMode = "release"
elif defined(danger):
  const buildMode = "danger"
else:
  const buildMode = "debug"

const langVersion* = staticRead("../npscript.nimble")
  .split("\n")
  .filterIt(it.startsWith("version"))[0]
  .split("=")[^1]
  .strip()[1..^2] & (if buildMode != "release": "+" & buildMode else: "")

static:
  echo "Compiling NPScript ", langVersion, " on ", nimscript.buildOS, "/", nimscript.buildCPU, " for ", hostOS, "/", hostCPU, " in ", buildMode, " mode"

let builtins* = newDict(0)

template addV(name, doc: static string, item: NpsValue) =
  addV(builtins, name, doc, item)

template addF(name: static string, args: FuncArgs, body: untyped) =
  addF(builtins, name, "", args, body)

template addS(name, doc: static string, args: FuncArgs, body: string) =
  addS(builtins, "builtins.nps", name, doc, args, body)


template addMathOp(name: string, op: untyped) =
  addF(name, @[("X", tAny), ("Y", tAny)]):
    let
      b = s.pop()
      a = s.pop()
    
    s.push(op(a, b))

template addBoolOp(name: string, op: untyped) =
  addF(name, @[("X", tAny), ("Y", tAny)]):
    let
      b = s.pop()
      a = s.pop()
    
    s.push(newNpsBool(op(a, b)))


func `$`[T: CatchableError](e: ref T): string =
  e.msg


let defaultSearchPaths = [
  npsStd,
  ".pkg",
  npsPkg,
]

let internalPackageRegistry = newTable[string, (Dict, string)]([
  ("strings", (libstrings.lib, "'strings'\nFunctions related to string handling and processing.")),
  ("http", (libhttp.lib, "'http'\nFunctions for creating HTTP requests."))
])

proc importFile*(s: State, path: string): NpsValue =
  var p = path

  if p.find('\\') != -1:
    raise newNpsError("Invalid import path, import paths cannot contain back-slashes")

  p = p.replace('/', DirSep)

  if not p.endsWith(".nps"):
    if internalPackageRegistry.hasKey(p):
      let
        (d, doc) = internalPackageRegistry[p]
        val = newNpsDictionary(d)

      val.doc = doc

      return val

    let packageSearchPaths = defaultSearchPaths.toSeq()

    var found = false

    for srpath in packageSearchPaths:
      let testPath = joinPath(srpath, p) & ".nps"

      if testPath.fileExists():
        p = testPath
        found = true
        break

    if not found:
      raise newNpsError(fmt"'{p}' could not be found in any search path:" & "\n Internal package registry\n " & packageSearchPaths.join("\n "))

  var content: string

  try:
    content = readFile p
  except IOError as e:
    raise newNpsError(fmt"Could not read from '{p}':" & "\n  " & e.msg)

  let substate = s.codeEval(p, content)

  if not substate.has("export"):
    raise newNpsError("Symbol 'export' must be defined in imported modules")

  return substate.get("export")


# Meta operators

addV("langver",
"""
'langver'
-> version
Returns the current version of the language as a string.
"""):
  newNpsString(langVersion)

const
  helpMessage = staticRead("data/helpmsg.txt")
    .strip()
    .colorize()

  helpMessageExtended = staticRead("data/helpmsgext.txt")
    .strip()
    .colorize()

# ->
# Prints a help message to assist people with writing the language.
addF("help", @[]):
  echo fmt"Welcome to NPScript {langVersion}", "\n\n", helpMessage

# ->
# Prints an extended help message to assist people with writing the language.
addF("exthelp", @[]):
  echo fmt"Welcome to NPScript {langVersion}", "\n\n", helpMessageExtended

# X -> doc of X
# Returns the docstring attached to a value X.
# The returned docstring may be empty.
addF("docof", @[("X", tAny)]):
  let val = s.pop()
  
  s.push(newNpsString(val.doc))

# X S -> X'
# Sets the docstring of a value X to a string S.
addF("setdoc", @[("X", tAny), ("S", tString)]):
  let
    str = String(s.pop()).value
    val = s.peek(^1)

  val.doc = str

addS("huhl?",
"""
'huhl?'
S -> doc of X from S
Returns the docstring attached to the value bound to a symbol S.
The returned docstring may be empty.
""", @[("S", tSymbol)]):
  "load docof"

addS("huhp?",
"""
'huhp?'
X ->
Prints the docstring of a value X.
The returned docstring may be empty.
""", @[("X", tAny)]):
  "docof ="

addS("huh?",
"""
'huh?'
S ->
Prints the docstring attached to the value bound to a symbol S.
The returned docstring may be empty.
""", @[("S", tSymbol)]):
  "huhl? ="

# X -> typeof X
# Returns a symbol that describes the type of a value X.
addF("type", @[("X", tAny)]):
  let tstr = $s.pop().kind

  s.push(newNpsSymbol(tstr))

# P -> D
# Evaluates a path P as a NPScript file and returns the value D of the 'export' symbol inside of it.
#
# If P ends with the .nps extension, P will be searched for in the current working directory,
# and an error will be thrown if it doesn't exist.
#
# If P doesn't end with the .nps extension, P will be searched for in these directories in descending order.
# - The internal package registry, which is what holds libraries like 'strings'
# - ~/.npscript/std/ (or %USERPROFILE%\.npscript\std\ on Windows)
# - ./.pkg/
# - ~/.npscript/pkg/ (or %USERPROFILE%\.npscript\pkg\ on Windows)
#
# If P can't be found in any of those paths, an error will be thrown.
#
# Back-slashes aren't allowed in P, but on DOS-like systems (e.g. Windows), forward-slashes will be replaced with back-slashes.
addF("import", @[("P", tString)]):
  let
    path = String(s.pop()).value
    val = importFile(s, path)

  s.push(val)

# P -> D
# Like 'import', but it automatically creates a symbol in the current dictionary with the name '~' + the base path of P with the extension removed.
addF("importdef", @[("P", tString)]):
  let
    path = String(s.pop()).value
    val = importFile(s, path)

  s.set("~" & path.lastPathPart().changeFileExt(""), val)

addS("quit",
"""
'quit'
->
Completely stops the program.
""", @[]):
  "0 quitn"

# E ->
# Completely stops the program with an exit code E.
addF("quitn", @[("E", tNumber)]):
  let code = Number(s.pop()).whole("E")

  raise NpsQuitError(code: code)

# ->
# Exits out of the loop it's called inside of.
addF("exit", @[]):
  raise NpsExitError()

# F ->
# Takes a function F and executes it.
addF("exec", @[("F", tFunction)]):
  let f = Function(s.pop())

  s.check(f.getArgs)
    
  f.run(s, r)

# Stack operators

# X ->
# Discards a value X.
addF("pop", @[("X", tAny)]):
  discard s.pop()

# X -> X X
# Duplicates a value X.
# This is not a deep copy.
addF("dup", @[("X", tAny)]):
  let val = s.pop()
  s.push(val)
  s.push(val.copy())

addS("exch",
"""
X Y -> Y X
Exchanges the positions of values X and Y.
""", @[("X", tAny), ("Y", tAny)]):
  "2 1 roll"

# ... C R -> ...
# Rotates the top C items on the stack up by R times.
addF("roll", @[("C", tNumber), ("R", tNumber)]):
  let
    roll = Number(s.pop()).whole("R")
    count = Number(s.pop()).whole("C")

  var expe = newFuncArgs(count)

  for i in 0..<expe.len():
    expe[i] = ("I" & $(i + 1), tAny)

  s.check(expe)

  let st = s.stack()

  var sl = st[st.len() - count ..< st.len()]
  
  sl.rotateLeft(-roll)

  var j = 0

  for i in st.len() - count ..< st.len():
    s[i] = sl[j]
    j += 1


# Arithmetic operators

# X Y -> X + Y
# Computes the sum of X and Y.
addMathOp("add", `+`)

# X Y -> X - Y
# Computes the difference of X and Y.
addMathOp("sub", `-`)

# X Y -> X * Y
# Computes the product of X and Y.
addMathOp("mul", `*`)

# X Y -> X / Y
# Computes the quotient of X and Y.
addMathOp("div", `/`)

# X Y -> X // Y
# Divides X with Y and returns the integral.
addMathOp("idiv", `//`)

# X Y -> X % Y
# Computes the modulo of X and Y.
addMathOp("mod", `%`)

# X Y -> X % Y
# Computes the power of X and Y.
addMathOp("exp", `^`)

addV("pi", """
-> pi
Returns the value of Pi.
"""):
  newNpsNumber(float32(PI))

addF("rand", @[]):
  var r = initRand()
  s.push(newNpsNumber(r.rand(1.0)))


# IO operators

# X ->
# Takes in a value X and prints it in its formatted form.
# This function will print any value as a literal, e.g. '(hello)' becomes hello, '/dog' becomes dog,
# and will not print lists in full.
addF("=", @[("X", tAny)]):
  echo s.pop()

# X ->
# Takes in a value X and prints it in its debug form.
# This function will print any value as it was in code form except functions,
# and will print lists in full.
addF("==", @[("X", tAny)]):
  echo s.pop().debug()

# X ->
# Takes in a value X and prints it in its formatted form without a newline.
addF("print", @[("X", tAny)]):
  stdout.write $s.pop()
  stdout.flushFile()

# ... S ->
# Formats a string S and an amount of values akin to the sprintf of C.
# The only format specifiers are '%f' and '%d',
# which format a value in its formatted and debug forms, respectively.
addF("sprintf", @[("S", tString)]):
  let fmt = String(s.pop()).value

  var
    parts: seq[tuple[s: string, f: bool]]
    formatters = 0
    formatting = false

  for ch in fmt:
    if formatting:
      case ch
      of '%':
        parts.add(($ch, false))
      of 'f', 'd':
        parts.add(($ch, true))
      else:
        raise newNpsError(fmt"Invalid format specifier '{ch}'")

      formatters += 1

      formatting = false
    elif ch == '%':
      formatting = true
    else:
      parts.add(($ch, false))

  var
    values = newSeqOfCap[NpsValue](formatters)
    i = 0
    formatted = newStringOfCap(fmt.len() + formatters * 3)

  for _ in 0..<formatters:
    values.add(s.pop())

  values.reverse()

  for p in parts:
    if p.f:
      case p.s
      of "f":
        formatted &= values[i].format()
      of "d":
        formatted &= values[i].debug()
      else:
        formatted &= p.s
      
      i += 1
    else:
      formatted &= p.s
  
  s.push(newNpsString(formatted))

addS("printf",
"""
'printf'
S ->
Formats with 'sprintf', then prints the result to stdout.
Shorthand for 'sprintf print'
""", @[("S", tString)]):
  "sprintf print"

# ->
# Prints the stack without effecting it.
# The topmost item is the top of the stack.
# This function uses the same semantics as '='.
addF("stack", @[]):
  let stack = s.stack()

  for i in countdown(stack.len() - 1, 0):
    echo stack[i]

# ->
# Prints the stack without effecting it.
# The topmost item is the top of the stack.
# This function uses the same semantics as '=='.
addF("pstack", @[]):
  let stack = s.stack()

  for i in countdown(stack.len() - 1, 0):
    echo stack[i].debug()

# P -> S
# Reads a path P and returns the resulting string S.
addF("readf", @[("P", tString)]):
  let path = String(s.pop()).value
  
  var content: string

  try:
    content = readFile path
  except IOError as e:
    raise newNpsError(fmt"Could not read from '{path}':" & "\n" & $e)

  s.push(newNpsString(content))

# S P ->
# Writes a string S to a path P.
addF("writef", @[("S", tString), ("P", tString)]):
  let
    path = String(s.pop()).value
    content = String(s.pop()).value

  try:
    writeFile(path, content)
  except IOError as e:
    raise newNpsError(fmt"Could not write to '{path}':" & "\n" & $e)


# Conditional operators

# X Y -> X == Y
# Tests the equality of X and Y.
addBoolOp("eq", `==`)

# X Y -> X != Y
# Tests the inequality of X and Y.
addBoolOp("ne", `!=`)

# X Y -> X > Y
# Compares X and Y.
addBoolOp("gt", `>`)

# X Y -> X >= Y
# Compares X and Y.
addBoolOp("gt", `>=`)

# X Y -> X < Y
# Compares X and Y.
addBoolOp("lt", `<`)

# X Y -> X <= Y
# Compares X and Y.
addBoolOp("le", `<=`)

# X Y -> X and Y
# Returns true if bools X and Y are true, otherwise false.
addF("and", @[("X", tBool), ("Y", tBool)]):
  let
    b = Bool(s.pop()).value
    a = Bool(s.pop()).value

  s.push(newNpsBool(a and b))

# X Y -> X or Y
# Returns true if bools X or Y are true, otherwise false.
addF("or", @[("X", tBool), ("Y", tBool)]):
  let
    b = Bool(s.pop()).value
    a = Bool(s.pop()).value

  s.push(newNpsBool(a or b))

# B F ->
# Executes F if B is true.
addF("if", @[("B", tBool), ("F", tFunction)]):
  let
    f = Function(s.pop())
    cond = Bool(s.pop()).value

  if cond:
    f.run(s, r)

# B F F' ->
# Executes F if B is true, otherwise executes F'.
addF("ifelse", @[("B", tBool), ("F", tFunction), ("F'", tFunction)]):
  let
    fFalse = Function(s.pop())
    fTrue = Function(s.pop())
    cond = Bool(s.pop()).value

  if cond:
    fTrue.run(s, r)
  else:
    fFalse.run(s, r)

# Loop operators

# F ->
# Executes F until 'exit' or 'quit' is called.
addF("loop", @[("F", tFunction)]):
  let
    f = Function(s.pop())
    prevLoopState = s.isLoop

  s.isLoop = true

  defer:
    s.isLoop = prevLoopState

  while true:
    try:
      f.run(s, r)
    except NpsExitError:
      break

# S I E F ->
# Steps from S to E while executing F, incrementing by I each iteration.
addF("for", @[("S", tNumber), ("I", tNumber), ("E", tNumber), ("F", tFunction)]):
  let
    f = Function(s.pop())
    lend = Number(s.pop()).whole("E")
    step = Number(s.pop()).whole("I")
    start = Number(s.pop()).whole("S")
    prevLoopState = s.isLoop

  s.isLoop = true

  defer:
    s.isLoop = prevLoopState

  var i = start

  while i != lend + step:
    s.push(newNpsNumber(float(i)))

    try:
      f.run(s, r)
    except NpsExitError:
      break

    i += step

# L F ->
# Iterates over L, putting each item on the stack then executing F.
addF("forall", @[("L", tList), ("F", tFunction)]):
  let
    f = Function(s.pop())
    l = List(s.pop())
    prevLoopState = s.isLoop

  s.isLoop = true

  defer:
    s.isLoop = prevLoopState

  for item in l.value:
    s.push(item)

    try:
      f.run(s, r)
    except NpsExitError:
      break


# List operators

# S -> L
# Creates a list D with a specified size S.
addF("array", @[("S", tNumber)]):
  let length = Number(s.pop()).whole("S")

  s.push(newNpsList(length))

# L I -> L[I]
# Gets the value at an index I of a list L.
addF("get", @[("L", tList), ("I", tNumber)]):
  let
    ind = Number(s.pop()).whole("I")
    arr = List(s.pop())

  s.push(arr[ind])

# L I X -> L[I] = X
# Sets an index I of a list L to a value X.
addF("put", @[("L", tList), ("I", tNumber), ("X", tAny)]):
  let
    val = s.pop()
    ind = Number(s.pop()).whole("I")
    arr = List(s.pop())

  arr[ind] = val


# Dict operators

# S X ->
# Binds X to the symbol S inside the current dictionary.
addF("def", @[("S", tSymbol), ("X", tAny)]):
  let
    val = s.pop()
    sym = Symbol(s.pop()).value
  
  s.set(sym, val)

# S -> X
# Pushes the value bound to the symbol S onto the stack.
addF("load", @[("S", tSymbol)]):
  let name = Symbol(s.pop()).value

  s.push(s.get(name))

# S -> D
# Creates a dictionary D with an initial size S.
addF("dict", @[("S", tNumber)]):
  logger.logdv("'dict' was called")
  logger.logdv("The stack is currently: " & $s.stack())

  logger.logdv("Popping dictionary size (param S)...")
  let size = Number(s.pop()).whole("S")

  logger.logdv(fmt"Dictionary size is {size}, initializing dictionary...")
  let d = newNpsDictionary(newDict(int(size)))

  logger.logdv("Dictionary initialized, pushing...")
  s.push(d)
  logger.logdv("Dictionary pushed")

# D ->
# Opens a dictionary D for usage.
addF("begin", @[("D", tDict)]):
  let d = Dictionary(s.pop())

  s.dbegin(d.value)

# ->
# Closes the last opened dictionary.
addF("end", @[]):
  discard s.dend()

# D S ->
# Adds a symbol S from a dictionary D into the current dictionary.
# If S already exists in it current dictionary, it will be overwritten.
addF("from", @[("D", tDict), ("S", tSymbol)]):
  let
    name = Symbol(s.pop()).value
    d = Dictionary(s.pop()).value

  if not d.hasKey(name):
    raise newNpsError(fmt"Symbol '{name}' does not exist")

  s.set(name, d[name])

# D ->
# Adds the symbols from a dictionary D into the current dictionary.
# Already existing symbols will be overwritten.
addF("allfrom", @[("D", tDict)]):
  let d = Dictionary(s.pop()).value
  
  for k, v in d.pairs:
    s.set(k, v)


addS("scoped",
"""
'scoped'
D F ->
Takes a dictionary D, opens D, executes F, then closes D.
Acts as shorthand for 'begin ... end'.
""", @[("D", tDict), ("F", tFunction)]):
  "exch begin exec end"

addS(".",
"""
'.' (dot)
D S -> V
Gets a symbol S from a dict D, analogous to D.S; if the bound value is a function, then it'll be executed.
""", @[("D", tDict), ("S", tSymbol)]):
  """
exch
begin
  load
  dup type
  /Function eq
  {exec} 
  if
end"""

# ->
# Shows the symbols inside the last opened dictionary.
addF("symbols", @[]):
  for symbol in s.symbols():
    echo symbol


# Misc operators

let
  trueSingleton = newNpsBool(true)
  falseSingleton = newNpsBool(false)
  nullSingleton = newNpsNull()

addV("null", """
'null'
-> null
Produces the value of null."""):
  nullSingleton

addV("true", """
'true'
-> true
Produces the boolean true value."""):
  trueSingleton

addV("false", """
'false'
-> false
Produces the boolean false value."""):
  falseSingleton

# X -> len of X
# Gets the length of a value X
addF("length", @[("X", tAny)]):
  let length = s.pop().len()

  s.push(newNpsNumber(float32(length)))

# S -> N
# "String To Number"
# Converts a string S into a number N.
addF("stn", @[("S", tString)]):
  let str = String(s.pop()).value

  var n: float
  try:
    n = parseFloat(str)
  except ValueError:
    raise newNpsError(fmt"Cannot convert '{str}' into a number")

  s.push(newNpsNumber(n))

# S -> S'
# "String To Symbol"
# Converts a string S into a symbol S'.
# The allowed characters are unrestricted.
addF("sts", @[("S", tString)]):
  let str = String(s.pop()).value

  s.push(newNpsSymbol(str))
