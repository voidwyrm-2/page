import std/[
  tables,
  algorithm,
  strutils,
  strformat,
  os,
  sequtils,
  math,
  enumerate
]

from system/nimscript import nil

import pkg/checksums/md5

import
  pgenv,
  lexer,
  parser,
  builtinlibs/[
    common,
    libstrings,
    libio,
    libos,
    libjson
  ]

when not defined(nohttp):
  import builtinlibs/libhttp


when defined(release):
  const buildMode = "release"
elif defined(danger):
  const buildMode = "danger"
else:
  const buildMode = "debug"

const
  langVersion* = staticRead("../page.nimble")
    .split("\n")
    .filterIt(it.startsWith("version"))[0]
    .split("=")[^1]
    .strip()[1..^2] & (if buildMode != "release": "+" & buildMode else: "")

  product = "Page"

  helpMessage = staticRead("data/helpmsg.txt")
    .strip()
    .colorize()

  helpMessageExtended = staticRead("data/helpmsgext.txt")
    .strip()
    .colorize()


static:
  echo "Compiling ", product, " ", langVersion, " on ", nimscript.buildOS, "/", nimscript.buildCPU, " for ", hostOS, "/", hostCPU, " in ", buildMode, " mode"

  when defined(nohttp):
    echo "Compiling without HTTP"


let builtins* = newDict(0)

template addV(name, doc: static string, item: Value) =
  addV(builtins, name, doc, item)

template addF(name, doc: static string, args: ProcArgs, body: untyped) =
  addF(builtins, name, doc, args, body)

template addS(name, doc: static string, args: ProcArgs, body: string) =
  addS(builtins, "builtins.pg", name, doc, args, body)


template addMathOp(name, doc: static string, op: untyped) =
  addF(name, doc, @[("X", tAny), ("Y", tAny)]):
    let
      b = s.pop()
      a = s.pop()
    
    s.push(op(a, b))

template addBitOp(name, doc: static string, op: untyped) =
  addF(name, doc, @[("X", tInteger), ("Y", tInteger)]):
    let
      b = s.pop().intv
      a = s.pop().intv
    
    s.push(newInteger(op(a, b)))

template addBoolOp(name, doc: static string, op: untyped) =
  addF(name, doc, @[("X", tAny), ("Y", tAny)]):
    let
      b = s.pop()
      a = s.pop()
    
    s.push(newBool(op(a, b)))


func `$`[T: CatchableError](e: ref T): string =
  e.msg


let defaultSearchPaths = [
  pgStd,
  ".pkg",
  pgPkg,
]

let internalPackageRegistry = newTable[string, (Dict, string)]([
  ("strings", (libstrings.lib, "'strings'\nOperators related to string handling and processing.")),
  ("io", (libio.lib, "'io'\nOperators related to input and output.")),
  ("os", (libos.lib, "'os'\nOperators for interacting with the operating system.")),
  ("json", (libjson.lib, "'json'\nOperators for decoding and encoding JSON."))
])

when not defined(nohttp):
  internalPackageRegistry["http"] = (libhttp.lib, "'http'\nProcedures for creating HTTP requests.")

proc importFile*(s: State, path: string): Value =
  var p = path

  if '\\' in p:
    raise newPgError("Invalid import path, import paths cannot contain slashes")

  p = p.replace('/', DirSep)

  if not p.endsWith(".pg"):
    if internalPackageRegistry.hasKey(p):
      let
        (d, doc) = internalPackageRegistry[p]
        val = newDictionary(d.copy())

      val.doc = doc

      return val

    let packageSearchPaths = defaultSearchPaths.toSeq()

    var found = false

    for srpath in packageSearchPaths:
      let testPath = joinPath(srpath, p) & ".pg"

      if testPath.fileExists():
        p = testPath
        found = true
        break

    if not found:
      raise newPgError(fmt"'{p}' could not be found in any search path:" & "\n Internal package registry\n " & packageSearchPaths.join("\n "))

  if p.len > 0 and p[0] != '/':
    p = s.g.cwd / p

  let content =
    try:
      p.readFile()
    except IOError as e:
      raise newPgError(fmt"Could not read from '{p}':" & "\n  " & e.msg)

  let 
    cache = s.g.importCache
    hash = toMD5(content)

  if cache.hasKey(p) and cache[p].hash == hash:
    return newDictionary(cache[p].val.dictv.copy())

  let substate = s.codeEval(newGlobalState(s.g.exe, p, @[]), p, content)

  if not substate.has("export"):
    raise newPgError("Symbol 'export' must be defined in imported modules")

  let expo = substate.get("export")

  cache[p] = (hash, expo)

  return expo


# Meta operators

addV("version",
"""
'version'
-> str
Returns the current version of the language as a string.
"""):
  newString(langVersion)

addV("product",
"""
'product'
-> str
Returns the product name.
This is included for compatibility with PostScript implementations.
"""):
  newString(product)

addF("help",
"""
'help'
->
Prints a help message to assist people with writing the language.
""", @[]):
  echo fmt"Welcome to Page {langVersion}", "\n\n", helpMessage

addF("exthelp",
"""
->
Prints an extended help message to assist people with writing the language.
""", @[]):
  echo fmt"Welcome to Page {langVersion}", "\n\n", helpMessageExtended

addF("docof",
"""
'docof'
V -> doc from V
Returns the docstring attached to a value V.
The returned docstring may be empty.
""", @[("V", tAny)]):
  let val = s.pop()
  
  s.push(newString(val.doc))

addF("setdoc",
"""
'setdoc'
V S -> V'
Sets the docstring of a value V to a string S.
""", @[("V", tAny), ("S", tString)]):
  let
    str = s.pop().strv
    val = s.peek(^1)

  val.doc = str

addS("docofs",
"""
'doc'
S -> doc from V from S
Returns the docstring attached to the value V bound to a symbol S.
The returned docstring may be empty.
""", @[("S", tSymbol)]):
  "load docof"

addS("doc",
"""
'doc'
S ->
Prints the docstring attached to the value bound to a symbol S.
The returned docstring may be empty.
""", @[("S", tSymbol)]):
  "docofs ="

addF("type",
"""
'type'
V -> type of V
Returns a symbol that describes the type of a value V.
""", @[("V", tAny)]):
  let tstr = $s.pop().typ

  s.push(newSymbol(tstr))

addF("import",
"""
'import'
P -> value of /export in P
Evaluates a path P as a Page file and returns the value of the 'export' symbol inside of it.

If P ends with the .pg extension, P will be searched for in the current working directory,
and an error will be thrown if it doesn't exist.

If P doesn't end with the .pg extension, P will be searched for in these directories in descending order.
- The internal package registry, which is what holds libraries like 'strings'
- ~/.page/std/ (or %USERPROFILE%\.page\std\ on Windows)
- ./.pkg/
- ~/.page/pkg/ (or %USERPROFILE%\.page\pkg\ on Windows)

If P can't be found in any of those paths, an error will be thrown.

Back-slashes aren't allowed in P, but on DOS-like systems (e.g. Windows), forward-slashes will be replaced with back-slashes.
""", @[("P", tString)]):
  let
    path = s.pop().strv
    val = importFile(s, path)

  s.push(val)

addF("importdef",
"""
'importdef'
P -> D
Like 'import', but it automatically creates a symbol in the current dictionary with the name '~' + the base path of P with the extension removed.
""", @[("P", tString)]):
  let
    path = s.pop().strv
    val = importFile(s, path)

  s.set("~" & path.lastPathPart().changeFileExt(""), val)

addF("quitn",
"""
'quitn'
E ->
Completely stops the program with an exit code E.
""", @[("E", tInteger)]):
  let code = s.pop().intv

  raise PgQuitError(code: code)

addS("quit",
"""
'quit'
->
Completely stops the program.
""", @[]):
  "0 quitn"

addF("exit",
"""
'exit'
->
Exits out of the loop it's called inside of.
""", @[]):
  raise PgExitError()

addF("bind",
"""
'bind'
P -> P'
Replaces operator names in a procedure P with operator values.
""", @[("P", tProcedure)]):
  let f = s.pop()

  s.push(newProcedure(f, literalize(s, f.nodes)))

addF("exec",
"""
'exec'
P ->
Takes a function P and executes it.
""", @[("F", tProcedure)]):
  let f = s.pop()

  s.check(f.args)

  if f.ptype == ptLiteral:
    evalValues(s, ps, f.values)
  else:
    f.run(sptr, ps)

# Stack operators

addF("item?",
"""
'item?'
-> bool
Returns true if the stack has at least one item on it, false otherwise.
""", @[]):
  s.push(if s.stack.len > 0: trueSingleton else: falseSingleton)

addF("2item?",
"""
'item?'
-> bool
Returns true if the stack has at least two items on it, false otherwise.
""", @[]):
  s.push(if s.stack.len > 1: trueSingleton else: falseSingleton)

addF("pop",
"""
'pop'
V ->
Discards a value V.
""", @[("V", tAny)]):
  discard s.pop()

addF("dup",
"""
'dup'
V -> V V
Duplicates a value V.
This does not create a deep copy.
""", @[("V", tAny)]):
  let val = s.peek(^1)
  s.push(val)

addF("roll",
"""
'roll'
... C R -> ...
Rotates the top C items on the stack up by R times.
Positive R rotates to the right, negative R rotates to the left.
""", @[("C", tInteger), ("R", tInteger)]):
  let
    roll = s.pop().intv
    count = s.pop().intv

  if count == 0 or roll == 0:
    return

  var expe = newProcArgs(count)

  for i in 0..<expe.len():
    expe[i] = ("I" & $(i + 1), tAny)

  s.check(expe)

  let st = s.stack()

  var sl = st[st.len() - count .. ^1]
  
  sl.rotateLeft(-roll)

  var j = 0

  for i in st.len() - count ..< st.len():
    s[i] = sl[j]
    inc j

addS("exch",
"""
'exch'
X Y -> Y X
Exchanges the positions of values X and Y.
""", @[("X", tAny), ("Y", tAny)]):
  "2 1 roll"

addS("rot",
"""
'rot'
X Y Z -> Y Z X
Rotates the top three values on the stack to the left.
""", @[("X", tAny), ("Y", tAny), ("Z", tAny)]):
  "3 1 roll"

addS("-rot",
"""
'-rot'
X Y Z -> Z X Y
Rotates the top three values on the stack to the right.
""", @[("X", tAny), ("Y", tAny), ("Z", tAny)]):
  "3 -1 roll"


# Arithmetic operators

addMathOp("add",
"""
'add'
X Y -> X + Y
Computes the sum of X and Y.
""", `+`)

addMathOp("sub",
"""
'sub'
X Y -> X - Y
Computes the difference of X and Y.
""", `-`)

addMathOp("mul",
"""
'mul'
X Y -> X * Y
Computes the product of X and Y.
""", `*`)

addMathOp("div",
"""
'div'
X Y -> X / Y
Computes the quotient of X and Y.
""", `/`)

addMathOp("idiv",
"""
'idiv'
X Y -> X // Y
Divides X with Y and returns the integral part.
""", `//`)

addMathOp("mod",
"""
'mod'
X Y -> X % Y
Computes the modulo of X and Y.
""", `%`)

addMathOp("exp",
"""
'exp'
X Y -> X % Y
Computes the power of X and Y.
""", `^`)

addBitOp("band",
"""
'band'
X Y -> X & Y
Computes the bitwise AND of X and Y.
""", `and`)

addBitOp("bor",
"""
'bor'
X Y -> X | Y
Computes the bitwise OR of X and Y.
""", `or`)

addBitOp("xor",
"""
'xor'
X Y -> X ^ Y
Computes the bitwise XOR of X and Y.
""", `xor`)

addF("bnot",
"""
'bnot'
X -> ~X
Computes the bitwise NOT of X.
""", @[("X", tInteger)]):
  let a = s.pop().intv
  
  s.push(newInteger(not a))

addV("pi",
"""
'pi'
-> pi
Returns the value of Pi.
"""):
  newReal(float32(PI))

addV("inf",
"""
'inf'
-> inf
Returns the value of infinity.
"""):
  newReal(float32(Inf))

addV("-inf",
"""
'-inf'
-> -inf
Returns the value of negative infinity.
"""):
  newReal(float32(NegInf))

addF("round",
"""
'round'
R -> R'
Rounds a real R half away from zero.
""", @[("N", tReal)]):
  s.push(newReal(s.pop().realv.round()))

addF("floor",
"""
'floor'
R -> R'
Rounds a real R towards negative infinity.
""", @[("R", tReal)]):
  s.push(newReal(s.pop().realv.floor()))

addF("ceil",
"""
'ceil'
R -> R'
Rounds a real R towards infinity.
""", @[("R", tReal)]):
  s.push(newReal(s.pop().realv.ceil()))

addF("rand",
"""
'rand'
-> real
Generates a pseudo-random real.
""", @[]):
  s.push(newReal(ps.rand.rand(1.0)))


# IO operators

addF("=",
"""
'=' (format)
V ->
Takes in a value V and prints it in its formatted form.
This function will print any value as a literal, e.g. '(hello)' becomes hello, '/dog' becomes dog,
and will not print lists in full.
""", @[("V", tAny)]):
  echo s.pop()

addF("==",
"""
'==' (debug)
V ->
Takes in a value V and prints it in its debug form.
This function will print any value as it roughly was in the original source code.
""", @[("V", tAny)]):
  let v = s.pop()

  echo v.debug()

addF("print",
"""
'print'
V ->
Takes in a value V and prints it in its formatted form without a newline.
""", @[("V", tAny)]):
  stdout.write $s.pop()
  stdout.flushFile()

addF("sprintf",
"""
'sprintf'
... S -> str
Formats a string S and an amount of values akin to the sprintf of C.
The only format specifiers are '%f' and '%d',
which format a value in its formatted and debug forms, respectively.
""", @[("S", tString)]):
  let fmt = s.pop().strv

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
        raise newPgError(fmt"Invalid format specifier '{ch}'")

      formatters += 1

      formatting = false
    elif ch == '%':
      formatting = true
    else:
      parts.add(($ch, false))

  var
    values = newSeqOfCap[Value](formatters)
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
  
  s.push(newString(formatted))

addS("printf",
"""
'printf'
... S ->
Formats with 'sprintf', then prints the result to stdout.
Shorthand for 'sprintf print'
""", @[("S", tString)]):
  "sprintf print"

addF("stack",
"""
'stack'
->
Prints the stack without effecting it.
The topmost item is the top of the stack.
This function uses the same semantics as '='.
""", @[]):
  let stack = s.stack()

  for i in countdown(stack.len() - 1, 0):
    echo stack[i]

addF("pstack",
"""
'pstack'
->
Prints the stack without effecting it.
The topmost item is the top of the stack.
This function uses the same semantics as '=='.
""", @[]):
  let stack = s.stack()

  for i in countdown(stack.len() - 1, 0):
    echo stack[i].debug()

addF("readf",
"""
'readf'
P -> str
Reads a path P and returns the resulting string S.
""", @[("P", tString)]):
  let path = s.pop().strv.fixPath(s.g)
  
  var content: string

  try:
    content = readFile path
  except IOError as e:
    raise newPgError(fmt"Could not read from '{path}':" & "\n" & $e)

  s.push(newString(content))

addF("writef",
"""
'writef'
S P ->
Writes a string S to a path P.
""", @[("S", tString), ("P", tString)]):
  let
    path = s.pop().strv.fixPath(s.g)
    content = s.pop().strv

  try:
    writeFile(path, content)
  except IOError as e:
    raise newPgError(fmt"Could not write to '{path}':" & "\n" & $e)


# Conditional operators

addBoolOp("eq",
"""
'eq'
X Y -> X == Y
Tests the equality of X and Y.
""", `==`)

addBoolOp("ne",
"""
'ne'
X Y -> X != Y
Tests the inequality of X and Y.
""", `!=`)

addBoolOp("gt",
"""
'gt'
X Y -> X > Y
Compares X and Y.
""", `>`)

addBoolOp("gt",
"""
'gt'
X Y -> X >= Y
Compares X and Y.
""", `>=`)

addBoolOp("lt",
"""
'lt'
X Y -> X < Y
Compares X and Y.
""", `<`)

addBoolOp("le",
"""
'le'
X Y -> X <= Y
Compares X and Y.
""", `<=`)

addF("and",
"""
'and'
X Y -> X and Y
Returns true if bools X and Y are true, otherwise false.
""", @[("X", tBool), ("Y", tBool)]):
  let
    b = s.pop().boolv
    a = s.pop().boolv

  s.push(newBool(a and b))

addF("or",
"""
'or'
X Y -> X or Y
Returns true if bools X or Y are true, otherwise false.
""", @[("X", tBool), ("Y", tBool)]):
  let
    b = s.pop().boolv
    a = s.pop().boolv

  s.push(newBool(a or b))

addF("not",
"""
'not'
B -> !B
Negates a bool B.
""", @[("B", tBool)]):
  s.push(newBool(not s.pop().boolv))

addF("if",
"""
'if'
B P ->
Executes P if B is true.
""", @[("B", tBool), ("P", tProcedure)]):
  let
    f = s.pop()
    cond = s.pop().boolv

  if cond:
    f.run(sptr, ps)

addF("ifelse",
"""
'ifelse'
B P P' ->
Executes P if B is true, otherwise executes P'.
""", @[("B", tBool), ("P", tProcedure), ("P'", tProcedure)]):
  let
    fFalse = s.pop()
    fTrue = s.pop()
    cond = s.pop().boolv

  if cond:
    fTrue.run(sptr, ps)
  else:
    fFalse.run(sptr, ps)

addS("null?",
"""
'null?'
V -> V == null
Duplicates a value V, then returns true if X is null, and false otherwise.
""", @[("V", tAny)]):
  "dup null eq"


# Loop operators

addF("loop",
"""
'loop'
F ->
Executes a procedure F until 'exit' or 'quit' is called.
""", @[("F", tProcedure)]):
  let
    f = s.pop()
    prevLoopState = s.isLoop

  s.isLoop = true

  defer:
    s.isLoop = prevLoopState

  while true:
    try:
      f.run(sptr, ps)
    except PgExitError:
      break

addF("for",
"""
'for'
S I E F ->
Steps from S to E while executing a procedure F, incrementing by I each iteration.
""", @[("S", tInteger), ("I", tInteger), ("E", tInteger), ("F", tProcedure)]):
  let
    f = s.pop()
    lend = s.pop().intv
    step = s.pop().intv
    start = s.pop().intv
    prevLoopState = s.isLoop

  s.isLoop = true

  defer:
    s.isLoop = prevLoopState

  var i = start

  while i != lend + step:
    s.push(newInteger(i))

    try:
      f.run(sptr, ps)
    except PgExitError:
      break

    i += step

addF("forall",
"""
'forall'
L F ->
Iterates over a list L, putting each item on the stack then executing a procedure F.
""", @[("L", tList), ("F", tProcedure)]):
  let
    f = s.pop()
    l = s.pop().listv
    prevLoopState = s.isLoop

  s.isLoop = true

  defer:
    s.isLoop = prevLoopState

  for item in l:
    s.push(item)

    try:
      f.run(sptr, ps)
    except PgExitError:
      break


# List operators

addF("list",
"""
'list'
S -> list[S]
Creates a list L with a specified size S.
""", @[("S", tInteger)]):
  let length = s.pop().intv

  s.push(newList(length))

addF("get",
"""
'get'
L I -> L[I]
Gets the value at an index I of a list L.
Negative indexes will index from the back of the list
""", @[("L", tList), ("I", tInteger)]):
  let
    i = s.pop().intv
    arr = s.pop()

  let ind = if i < 0: arr.len - -i else: i

  s.push(arr[ind])

addF("put",
"""
'put'
L I V -> L[I] = V
Sets an index I of a list L to a value X.
Negative indexes will index from the back of the list
""", @[("L", tList), ("I", tInteger), ("V", tAny)]):
  let
    val = s.pop()
    i = s.pop().intv
    arr = s.pop()

  let ind = if i < 0: arr.len - -i else: i

  arr[ind] = val


# Dict operators

addV("<<",
"""
'<<'
-> '<<' mark
Begins a dictionary literal.
"""):
  newSymbol("/<</")

addS(">>",
"""
'>>'
<< ... S V -> dictionary
Collects key/value pairs until '<<', then returns resulting dictionary.
""", @[]):
  """
1 dict begin
  /kverr {(Expected a symbol to complete the key value pair) throw} def
5 dict begin
  {
    item? not
    {(Expected '<<' to close dictionary literal) throw}
    if

    dup << eq
    {pop exit}
    if

    2item? not
    /kverr load
    if

    exch
    dup << eq
    exch dup type /Symbol ne
    exch rot or
    /kverr load
    if

    exch
    def
  } loop

  this
end
end"""

addF("def",
"""
'def'
S V ->
Binds a value V to a symbol S inside the current dictionary.
""", @[("S", tSymbol), ("V", tAny)]):
  let
    val = s.pop()
    name = s.pop().strv
  
  s.set(name, val)

addF("undef",
"""
'undef'
S ->
Binds symbol S inside the current dictionary.
""", @[("S", tSymbol)]):
  let name = s.pop().strv
  discard s.unset(name)

addS("undef",
"""
'undef'
S ->
Binds symbol S inside the current dictionary.
""", @[("S", tSymbol)]):
  ""

addF("load",
"""
'load'
S -> V
Retrieves the value bound to a symbol S.
""", @[("S", tSymbol)]):
  let name = s.pop().strv
  s.push(s.get(name))

addS("load?",
"""
'load?'
S -> V?
Retrieves the value bound to a symbol S.
If that symbol doesn't have a bound value, null is returned.
""", @[("S", tSymbol)]):
  "{load} {pop pop null} trycatch"

addF("dict",
"""
'dict'
S -> dictionary[S]
Creates a dictionary D with an initial size S.
""", @[("S", tInteger)]):
  let
    size = s.pop().intv
    d = newDictionary(newDict(int(size)))

  s.push(d)

addF("dcopy",
"""
'dcopy'
D -> D'
Creates a shallow copy of a dictionary D.
""", @[("D", tDict)]):
  let d = s.pop().dictv
  s.push(newDictionary(d.copy()))

addF("begin",
"""
'begin'
D ->
Opens a dictionary D for usage.
""", @[("D", tDict)]):
  s.dbegin(s.pop().dictv)

addF("end",
"""
'end'
->
Closes the last opened dictionary.
""", @[]):
  discard s.dend(ps)

addF("this",
"""
'this'
-> dictionary
Returns the last opened dictionary.
""", @[]):
  s.push(newDictionary(s.dicts[^1]))

addF("from",
"""
'from'
D S ->
Adds a symbol S from a dictionary D into the current dictionary.
If S already exists in the current dictionary, it will be overwritten.
""", @[("D", tDict), ("S", tSymbol)]):
  let
    name = s.pop().strv
    d = s.pop().dictv

  if not d.hasKey(name):
    raise newPgError(fmt"Symbol '{name}' does not exist")

  s.set(name, d[name])

addF("somefrom",
"""
'somefrom'
D SL ->
Adds a list of symbols SL from a dictionary D into the current dictionary.
If a symbol from SL already exists in the current dictionary, it will be overwritten.
""", @[("D", tDict), ("SL", tList)]):
  let
    names = s.pop().listv
    d = s.pop().dictv

  for sym in names:
    let name = sym.strv

    if not d.hasKey(name):
      raise newPgError(fmt"Symbol '{name}' does not exist")

    s.set(name, d[name])

addF("allfrom",
"""
'allfrom'
D ->
Adds the symbols from a dictionary D into the current dictionary.
Already existing symbols will be overwritten.
""", @[("D", tDict)]):
  let d = s.pop().dictv
  
  for k, v in d.pairs:
    s.set(k, v)

addS("scoped",
"""
'scoped'
D P ->
Takes a dictionary D, opens D, executes P, then closes D.
Acts as shorthand for 'begin ... end'.
""", @[("D", tDict), ("P", tProcedure)]):
  "exch begin exec end"

#[
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
  /Procedure eq
  {exec}
  if
end"""
]#

addF("symbols",
"""
'symbols'
-> list<symbol>
Returns a list of the symbols inside the last opened dictionary.
""", @[]):
  let symbols = s.symbols
  var l = newSeq[Value](symbols.len)

  for (i, symbol) in enumerate(symbols):
    l[i] = newSymbol(symbol)

  s.push(newList(l))

addF("rsymbols",
"""
'rsymbols'
-> list<list<symbol>>
Returns a list of lists of the symbols in each dictionary.
""", @[]):
  let dicts = s.dicts
  var l = newSeq[Value](dicts.len)

  for (i, dict) in enumerate(dicts):
    var
      subl = newSeq[Value](dict.len)
      j = 0

    for symbol in dict.keys:
      subl[j] = newSymbol(symbol)
      inc j

    l[i] = newList(subl)

  s.push(newList(l))

addS("psymbols",
"""
'psymbols'
->
Shows the symbols inside the last opened dictionary.
""", @[]):
  "symbols {=} forall"

addS("prsymbols",
"""
'prsymbols'
->
Shows the symbols in each dictionary.
""", @[]):
  """
1 rsymbols 
{
  exch dup
  (%f:\n) printf
  exch

  {( ) printf =} forall
  1 add
} forall
pop"""


# Misc operators

addV("null",
"""
'null'
-> null
Produces the value of null.
"""):
  nullSingleton

addV("true",
"""
'true'
-> true
Produces the boolean true value.
"""):
  trueSingleton

addV("false",
"""
'false'
-> false
Produces the boolean false value.
"""):
  falseSingleton

addF("defer",
"""
'defer'
P ->
Pushes a procedure P onto the defer stack,
which is executed when the 'end' operator is used,
when an error is thrown, or at the end of the program.
""", @[("P", tProcedure)]):
  let p = s.pop()

  ps.deferred[^1].add(p)

addF("throw",
"""
Msg ->
Throws an error with a string message Msg.
""", @[("Msg", tString)]):
  let str = s.pop().strv

  raise newPgError(str)

addF("try",
"""
'try'
P -> str?
Calls a procedure P and returns null if the procedure exited successfully,
or a string if the procedure threw an error.
""", @[("P", tProcedure)]):
  let p = s.pop()

  try:
    p.run(sptr, ps)
    s.push(nullSingleton)
  except PgError as e:
    s.push(newString(e.msg))

addS("trycatch",
"""
'trycatch'
P P' ->
Calls a procedure P; P' is called if P threw an error.
""", @[("P", tProcedure), ("P'", tProcedure)]):
  """
exch try
null?
{pop pop}
{exch exec}
ifelse"""

addF("length",
"""
'length'
X -> integer
Gets the length of a value X
""", @[("X", tString or tList or tDict)]):
  let length = s.pop().len

  s.push(newInteger(length))

addF("cvi",
"""
'cvi'
S -> integer
"Convert to Integer"
Converts a string S into an integer I.
An error is thrown if S is not representable as an integer.
""", @[("S", tString)]):
  let str = s.pop().strv

  var n: int
  try:
    n = parseInt(str)
  except ValueError:
    raise newPgError(fmt"Cannot convert '{str}' into an integer")

  s.push(newInteger(n))

addF("cvr",
"""
'cvr'
S -> real
"Convert to Real"
Converts a string S into a real R.
An error is thrown if S is not representable as a real.
""", @[("S", tString)]):
  let str = s.pop().strv

  var n: float
  try:
    n = parseFloat(str)
  except ValueError:
    raise newPgError(fmt"Cannot convert '{str}' into a real")

  s.push(newReal(n))

addF("cvs",
"""
'cvs'
S -> symbol
"Convert to Symbol"
Converts a string S into a symbol S'.
The allowed characters are unrestricted.
""", @[("S", tString)]):
  let str = s.pop().strv

  s.push(newSymbol(str))
