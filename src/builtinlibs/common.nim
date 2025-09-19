import std/strutils

import ../[
  values,
  state,
  logging
]


template addV*(dict: Dict, name, docstr: static string, item: NpsValue) =
  block:
    let
      val = item
      sdocstr {.compileTime.} = docstr.strip()
    val.doc = sdocstr
    dict[name] = val


template addF*(dict: Dict, name, docstr: static string, args: FuncArgs, body: untyped) =
  addV(dict, name, docstr):
    newNpsFunction(args, proc(s {.inject.}: State, r {.inject.}: Runner) =
      body
    )

template addS*(dict: Dict, file, name, docstr: static string, args: FuncArgs, body: string) =
  addV(dict, name, docstr):
    newNpsFunction(args, file, body)

proc whole*(n: Number, name: static string): int =
  logger.logdv("Converting param '" & name & "' into an integer")
  result = int(n.value)
  logger.logdv("Converted, value is " & $result)
  
  logger.logdv("Converting back to float for comparison")
  let fresult = float(result)

  logger.logdv("Converted, comparing")
  if fresult != n.value:
    logger.logdv("Param '" & name & "' is not whole")
    raise newNpsError("Argument " & name & " must be a whole number")

  logger.logdv("Param '" & name & "' is whole")
