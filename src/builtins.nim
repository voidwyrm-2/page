import
  std/tables

import
  state,
  values

const langVersion* = "0.3.4"

let builtins* = newDict(0)

template addF(name: string, args: openArray[NpsType], s, r, body: untyped) =
  builtins[name] = newNpsFunction(args,
    proc(s: State, r: Runner) =
      body
  )

template addSF(name, body: string) =
  builtins[name] = newNpsFunction(args, body)

template addV(name: string, args: openArray[NpsType], item: NpsValue) =
  builtins[name] = item

# Meta operators

addV("langver", @[]):
  newNpsString(langVersion)

addF("exec", @[tFunction], s, r):
  let f = Function(s.pop())

  if f.native():
    f.getNative()(s, r)
  else:
    r(f.getNodes())

# IO operators

addF("=", @[tAny], s, _):
  echo s.pop()

addF("==", @[tAny], s, _):
  echo s.pop().debug()
