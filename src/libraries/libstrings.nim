import
  std/tables

import
  ../values,
  ../state,
  common

let lib* = newDict(0)

template addV(name: string, item: NpsValue) =
  addV(lib, name, item)

template addF(name: string, args: openArray[NpsType], s, r, body: untyped) =
  addF(lib, name, args, s, r, body)


addF("chars", @[tString], s, _):
  let str = String(s.pop()).value()

  var chars: seq[NpsValue]

  for ch in str:
    chars.add(newNpsString($ch))

  s.push(newNpsList(chars))
