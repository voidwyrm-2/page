import
  std/tables,
  std/algorithm

import
  state,
  values,
  libraries/[
    common,
    libstrings]

const langVersion* = "0.5.6"

let builtins* = newDict(0)

template addV(name: string, item: NpsValue) =
  addV(builtins, name, item)

template addF(name: string, args: openArray[NpsType], s, r, body: untyped) =
  addF(builtins, name, args, s, r, body)

template addS(name: string, args: openArray[NpsType], body: string) =
  addS(builtins, "builtins.nps", name, args, body)


# Libraries

# Functions related to string handling and processing.
addV("~strings"):
  newNpsDictionary(libstrings.lib)


# Meta operators

# -> version
# Returns the current version of the language as a string.
addV("langver"):
  newNpsString(langVersion)

# A -> typeof A
# Returns a string that describes the type of A.
addF("type", @[tAny], s, _):
  let tstr = $s.pop().kind

  s.push(newNpsString(tstr))

# ->
# Completely stops the program.
addF("quit", @[], _, _):
  raise NpsQuitError()

# E ->
# Completely stops the program with the exit code E.
addF("quitn", @[tNumber], s, _):
  let code = Number(s.pop()).whole("E")

  raise NpsQuitError(code: code)

# ->
# Exits out of the loop it's called inside of.
addF("exit", @[], _, _):
  raise NpsExitError()

# F ->
# Takes a function F and executes it.
addF("exec", @[tFunction], s, r):
  Function(s.pop()).run(s, r)

# -> false
# Produces the boolean false singleton.
addV("false"):
  newNpsBool(false)

# -> true
# Produces the boolean true singleton.
addV("true"):
  newNpsBool(true)

# Stack operators

# A ->
# Discards the value on the top of the stack.
addF("pop", @[tAny], s, _):
  discard s.pop()

# A -> A A
# Duplicates the value on the top of the stack.
addF("dup", @[tAny], s, _):
  let val = s.pop()
  s.push(val)
  s.push(val.copy())

# A B -> B A
# Exchanges the top and second-from-top values on the stack.
addF("exch", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()

  s.push(b)
  s.push(a)

# ... C R -> ...
# Rotates the top C items on the stack up R times.
addF("roll", @[tNumber, tNumber], s, _):
  let
    roll = Number(s.pop()).whole("R")
    count = Number(s.pop()).whole("C")

  var expe = newSeq[NpsType](count)

  for i in 0..<expe.len():
    expe[i] = tAny

  s.check(expe)

  let st = s.stack()

  var sl = st[st.len() - count ..< st.len()]
  
  sl.rotateLeft(-roll)

  var j = 0

  for i in st.len() - count ..< st.len():
    s[i] = sl[j]
    j += 1


# Arithmetic operators

# A B -> A + B
# Adds A and B together.
addF("add", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(a + b)

# A B -> A - B
# Substracts A from B.
addF("sub", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(a - b)

# A B -> A * B
# Multiplies A with B.
addF("mul", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(a * b)

# A B -> A / B
# Divides A with B.
addF("div", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(a / b)


# IO operators

# A ->
# Takes in a value and prints it in its formatted form.
# This function will print any value as a literal, e.g. '(hello)' becomes hello, '/dog' becomes dog,
# and will not print lists in full.
addF("=", @[tAny], s, _):
  echo s.pop()

# A ->
# Takes in a value and prints it in its debug form.
# This function will print any value as it was in code form except functions,
# and will print lists in full.
addF("==", @[tAny], s, _):
  echo s.pop().debug()

# ->
# Prints the stack without effecting it.
# The topmost item is the top of the stack.
# This function uses the same semantics as '='.
addF("stack", @[], s, _):
  let stack = s.stack()

  for i in countdown(stack.len() - 1, 0):
    echo stack[i]

# ->
# Prints the stack without effecting it.
# The topmost item is the top of the stack.
# This function uses the same semantics as '='.
addF("pstack", @[], s, _):
  let stack = s.stack()

  for i in countdown(stack.len() - 1, 0):
    echo stack[i].debug()


# Conditional operators

# A B -> A == B
# Tests the equality of A and B.
addF("eq", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(newNpsBool(a == b))

# A B -> A != B
# Tests the inequality of A and B.
addF("ne", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(newNpsBool(a != b))

# A B -> A > B
# Compares A and B.
addF("gt", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(newNpsBool(a > b))

# A B -> A > B
# Compares A and B.
addF("ge", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(newNpsBool(a >= b))

# A B -> A > B
# Compares A and B.
addF("lt", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(newNpsBool(a < b))

# A B -> A > B
# Compares A and B.
addF("le", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(newNpsBool(a <= b))

# B F ->
# Executes F if B is true.
addF("if", @[tBool, tFunction], s, r):
  let
    f = Function(s.pop())
    cond = Bool(s.pop()).value()

  if cond:
    f.run(s, r)

# B fA fB ->
# Executes fA if B is true, otherwise executes fB.
addF("ifelse", @[tBool, tFunction, tFunction], s, r):
  let
    fFalse = Function(s.pop())
    fTrue = Function(s.pop())
    cond = Bool(s.pop()).value()

  if cond:
    fTrue.run(s, r)
  else:
    fFalse.run(s, r)

# Loop operators

# F ->
# Executes F until 'exit' or 'quit' is called.
addF("loop", @[tFunction], s, r):
  let f = Function(s.pop())

  s.isLoop = true

  defer:
    s.isLoop = false

  while true:
    try:
      f.run(s, r)
    except NpsExitError:
      break

# S I E F ->
# Steps from S to E while executing F, incrementing by I each iteration.
addF("for", @[tNumber, tNumber, tNumber, tFunction], s, r):
  let
    f = Function(s.pop())
    lend = Number(s.pop()).whole("E")
    step = Number(s.pop()).whole("I")
    start = Number(s.pop()).whole("S")

  s.isLoop = true

  defer:
    s.isLoop = false

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
addF("forall", @[tList, tFunction], s, r):
  let
    f = Function(s.pop())
    l = List(s.pop())

  for item in l.value():
    s.push(item)

    try:
      f.run(s, r)
    except NpsExitError:
      break


# Dict operators

# S A ->
# Binds A to the symbol S.
addF("def", @[tSymbol, tAny], s, _):
  let
    val = s.pop()
    sym = Symbol(s.pop()).value()
  
  s.set(sym, val)

# S -> A
# Pushes the value bound to the symbol S onto the stack.
addF("load", @[tSymbol], s, _):
  let sym = Symbol(s.pop()).value()

  s.push(s.get(sym))

# S -> D
# Creates a dictionary D with the specified size S.
addF("dict", @[tNumber], s, _):
  let
    size = Number(s.pop()).whole("S")
    d = newNpsDictionary(newDict(int(size)))

  s.push(d)

# D ->
# Opens a dictionary D for usage.
addF("begin", @[tDict], s, _):
  let d = Dictionary(s.pop())

  s.dbegin(d.value())

# ->
# Closes the last opened dictionary.
addF("end", @[], s, _):
  discard s.dend()

# D F ->
# Takes a dictionary D, opens D, executes F, then closes D.
addS("scoped", @[tDict, tFunction]):
  "exch begin exec end"

# ->
# Shows the symbols inside the last opened dictionary.
addF("symbols", @[], s, _):
  for symbol in s.symbols():
    echo symbol
