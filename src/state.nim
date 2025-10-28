import std/[
  tables,
  strutils,
  strformat
]

import
  general,
  value

export
  general,
  value


type
  GlobalState* = ref object
    exe*, file*: string
    args*: seq[string]

  State* = ref object
    g*: GlobalState
    dictMin: int
    dicts: seq[Dict]
    stack: seq[Value]
    deferred*: seq[seq[Value]]
    isLoop*: bool
    codeEval*: proc(g: GlobalState, file, text: string): State
    nodeRunner*: Runner


func newDict*(size: int): Dict =
  newTable[string, Value](size)

func newDict*(pairs: openArray[(string, Value)]): Dict =
  newTable(pairs)

func copy*(dict: Dict): Dict =
  ## Shallowly copies a Dict
  result = newDict(dict.len)

  for (k, v) in dict.pairs:
    result[k] = v


func newGlobalState*(exe, file: string, args: seq[string]): GlobalState =
  new result
  result.exe = exe
  result.file = file
  result.args = args


func newState*(dictMin: int, dicts: varargs[Dict]): State =
  new result
  result.dictMin = dictMin
  result.dicts = newSeqOfCap[Dict](varargsLen(dicts))
  result.deferred = newSeqOfCap[seq[Value]](varargsLen(dicts))
  result.isLoop = false

  for d in dicts:
    result.dicts.add(d)
    result.deferred.add(@[])

  for i in 0 ..< max(-1, dictMin - varargsLen(dicts) - 1):
    result.dicts.add(newDict(0))
    result.deferred.add(@[])

func dicts*(self: State): seq[Dict] =
  self.dicts

func stack*(self: State): seq[Value] =
  self.stack

func dbegin*(self: State, dict: Dict) =
  self.dicts.add(dict)
  self.deferred.add(@[])

func dbegin*(self: State, size: int) =
  self.dbegin(newDict(size))

proc dend*(self: State, ps: ProcState): Dict =
  if self.dicts.len <= self.dictMin:
    raise newPgError("Dict stack underflow")

  result = self.dicts.pop()

  for p in self.deferred.pop():
    p.run(cast[pointer](self), ps)

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


proc evalValues*(s: State, ps: ProcState, values: seq[Value]) =
  for value in values:
    case value.typ
    of tProcedure:
      if value.lit:
        s.push(value)
      elif value.ptype == ptLiteral:
        evalValues(s, ps, value.values)
      else:
        value.run(cast[pointer](s), ps)
    of tList:
      let subs = newState(1)
      
      evalValues(subs, ps, value.listv)

      s.push(newList(subs.stack))
    else:
      s.push(value)
