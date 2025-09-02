import
  std/tables

import
  state,
  values

const langVersion* = "0.3.3"

var builtins = newDict(0)

proc getBuiltins*(): Dict =
  builtins

template addF(name: string, args: openArray[NpsType], item: NpsNativeProc) =
  builtins[name] = newNpsFunction(args, item)

template addV(name: string, args: openArray[NpsType], item: NpsValue) =
  builtins[name] = item

# Meta operators

addV("langver", @[], newNpsString(langVersion))

addF("exec", @[tFunction],
  proc(s: State, runner: Runner) =
    let f = Function(s.pop())

    if f.native():
      f.getNative()(s, runner)
    else:
      runner(f.getNodes())
)

# IO operators

addF("=", @[tAny],
  proc(s: State, runner: Runner) =
    echo s.pop()
)

addF("==", @[tAny],
  proc(s: State, runner: Runner) =
    echo s.pop().debug()
)
