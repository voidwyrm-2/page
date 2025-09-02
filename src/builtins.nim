import
  std/tables

import
  state,
  values

const langVersion* = "0.5.2"

let builtins* = newDict(0)

template addV(name: string, item: NpsValue) =
  builtins[name] = item

template addF(name: string, args: openArray[NpsType], s, r, body: untyped) =
  addV(name):
    newNpsFunction(args,
      proc(s: State, r: Runner) =
        body
    )

template addSF(name, body: string) =
  addV(name):
    newNpsFunction(args, body)

# Meta operators

# -> str
# Returns the current version of the language as a string.
addV("langver"):
  newNpsString(langVersion)

# ->
# Completely exits the current program.
addF("quit", @[], _, _):
  raise NpsQuitError()

# ->
# Exits out of the current loop.
addF("exit", @[], _, _):
  raise NpsExitError()

# fun ->
# Takes a function and executes it.
addF("exec", @[tFunction], s, r):
  let f = Function(s.pop())

  if f.native():
    f.getNative()(s, r)
  else:
    r(f.getNodes())

# -> bool
# Produces the boolean false singleton.
addV("false"):
  newNpsBool(false)

# -> bool
# Produces the boolean true singleton.
addV("true"):
  newNpsBool(true)

# Stack operators

# any ->
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

# Arithmetic operators

# A B -> A == B
# Tests the equality of two items
addF("eq", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(newNpsBool(a == b))

# A B -> A != B
# Tests the inequality of two items
addF("ne", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(newNpsBool(a != b))

# A B -> A + B
# Adds two values together.
addF("add", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(a + b)

# A B -> A - B
# Substracts a value from another.
addF("sub", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(a - b)

# A B -> A * B
# Multiplies two values together.
addF("mul", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(a * b)

# A B -> A / B
# Divides a value with another.
addF("div", @[tAny, tAny], s, _):
  let
    b = s.pop()
    a = s.pop()
  
  s.push(a / b)

# IO operators

# any ->
# Takes in a value and prints it in its formatted form.
# This function will print any value as a literal, e.g. (hello) -> hello, /dog -> dog,
# and will not print lists in full.
addF("=", @[tAny], s, _):
  echo s.pop()

# any ->
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

addF("if", @[tBool, tFunction], s, r):
  let
    f = Function(s.pop())
    cond = Bool(s.pop()).value()

  if cond:
    if f.native():
      f.getNative()(s, r)
    else:
      r(f.getNodes())

# Loop operators

# fun ->
# Executes fun repeatedly until 'exit' or 'quit' is called.
addF("loop", @[tFunction], s, r):
  let f = Function(s.pop())

  s.isLoop = true

  defer:
    s.isLoop = false

  while true:
    try:
      if f.native():
        f.getNative()(s, r)
      else:
        r(f.getNodes())
    except NpsExitError:
      break

# Dict operators

# sym any ->
# Binds the value any to the symbol sym.
addF("def", @[tSymbol, tAny], s, _):
  let
    val = s.pop()
    sym = Symbol(s.pop()).value()
  
  s.set(sym, val)

# sym -> any
# Pushes the value bound to sym onto the stack.
addF("load", @[tSymbol], s, _):
  let sym = Symbol(s.pop()).value()

  s.push(s.get(sym))

# num -> dict
# Creates a dictionary with the specified size.
addF("dict", @[tNumber], s, _):
  let
    size = Number(s.pop()).value()
    isize = int(size)

  if float(isize) != size:
    raise newNpsError("Argument must be a whole number")

  let d = newNpsDictionary(newDict(isize))

  s.push(d)

# dict ->
# Opens a dictionary for usage.
addF("begin", @[tDict], s, _):
  let d = Dictionary(s.pop())

  s.dbegin(d.value())

# ->
# Closes the last opened dictionary.
addF("end", @[], s, _):
  discard s.dend()
