import std/[
  tables,
  strutils,
  strformat
]

import
  general,
  value,
  logging

export
  general,
  value


type
  State* = ref object
    dictMin: int
    dicts: seq[Dict]
    stack: seq[Value]
    isLoop*: bool
    codeEval*: proc(file, text: string): State


func newDict*(size: int): Dict =
  newTable[string, Value](size)

func newDict*(pairs: openArray[(string, Value)]): Dict =
  newTable(pairs)

func copy*(dict: Dict): Dict =
  ## Shallowly copies a Dict
  result = newDict(dict.len)

  for (k, v) in dict.pairs:
    result[k] = v

func newState*(dictMin: int, dicts: varargs[Dict]): State =
  new result
  result.dictMin = dictMin
  result.dicts = newSeqOfCap[Dict](varargsLen(dicts))
  result.isLoop = false

  for d in dicts:
    result.dicts.add(d)

  for i in 0 ..< max(-1, dictMin - varargsLen(dicts) - 1):
    result.dicts.add(newDict(0))

func dicts*(self: State): seq[Dict] =
  self.dicts

func stack*(self: State): seq[Value] =
  self.stack

func dbegin*(self: State, dict: Dict) =
  self.dicts.add(dict)

func dbegin*(self: State, size: int) =
  self.dbegin(newDict(size))

func dend*(self: State): Dict =
  if self.dicts.len <= self.dictMin:
    raise newPgError("Dict stack underflow")

  self.dicts.pop()

func has*(self: State, name: string): bool =
  result = false

  for d in self.dicts:
    if d.hasKey(name):
      return true

func set*(self: State, name: string, val: Value) =
  self.dicts[^1][name] = val

func get*(self: State, name: string): Value =
  for d in self.dicts.rev:
    if d.hasKey(name):
      return d[name]

  raise newPgError(fmt"Undefined symbol '{name}'")

proc push*(self: State, val: Value) =
  self.stack.add(val)

func pop*(self: State): Value =
  if self.stack.len == 0:
    raise newPgError("stack underflow")

  self.stack.pop()

func peek*(self: State, ind: int): Value =
  if ind < 0 or self.stack.len - 1 < ind:
    raise newPgError("stack underflow")

  self.stack[ind]

func peek*(self: State, ind: BackwardsIndex): Value =
  self.peek(self.stack.len - int(ind))

proc check*(self: State, args: ProcArgs) =
  if self.stack.len < args.len:
    raise newPgError(fmt"Expected {args.len} items on the stack but found {self.stack.len} items instead")

  var i = self.stack.len - 1

  for pst in args:
    if self.stack[i] isnot pst.typ:
      raise newPgError(fmt"Expected type {pst.typ} for argument {pst.name} at stack position {i + 1}, but found type {self.stack[i].typ} instead")

    dec i

func symbols*(self: State): seq[string] =
  result = newSeqOfCap[string](self.dicts[^1].len)

  for key in self.dicts[^1].keys:
    result.add(key)

proc `[]=`*(self: State, key: int, val: sink Value) =
  self.stack[key] = val

proc `$`*(self: State): string =
  var items: seq[string]

  for item in self.stack:
    items.add($item)

  items.join("\n")


proc evalValues*(s: State, r: Runner, values: seq[Value]) =
  for value in values:
    case value.typ
    of tProcedure:
      if value.ptype == ptLiteral:
        evalValues(s, r, value.values)
      else:
        value.run(cast[pointer](s), r)
    of tList:
      let subs = newState(1)
      
      evalValues(subs, r, value.listv)

      s.push(newList(subs.stack))
    else:
      s.push(value)
