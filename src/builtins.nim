import
  std/tables

import
  state,
  values

const langVersion* = "0.3.0"

var builtins = newDict(0)

proc getBuiltins*(): Dict =
  builtins

template addF(name: string, args: openArray[NpsType], item: NpsNativeProc) =
  builtins[name] = newNpsFunction(args, item)

template addV(name: string, args: openArray[NpsType], item: NpsValue) =
  builtins[name] = item

# IO operators

addV("langver", @[], newNpsString(langVersion))

addF("=", @[tAny],
  proc(s: State) =
    echo s.pop()
)

addF("==", @[tAny],
  proc(s: State) =
    echo s.pop().debug()
)
