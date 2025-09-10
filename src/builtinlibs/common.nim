import ../[
  values,
  state
]


template addV*(dict: Dict, name: string, item: NpsValue) =
  dict[name] = item

template addF*(dict: Dict, name: string, args: openArray[NpsType], body: untyped) =
  addV(dict, name):
    newNpsFunction(args,
      proc(s {.inject.}: State, r {.inject.}: Runner) =
        body
    )

template addS*(dict: Dict, file, name: string, args: openArray[NpsType], body: string) =
  dict[name] = newNpsFunction(args, file, body)

func whole*(n: Number, name: static string): int =
  result = int(n.value())
  
  if float(result) != n.value():
    raise newNpsError("Argument " & name & " must be a whole number")
