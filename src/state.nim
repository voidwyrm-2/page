import
  std/tables,
  std/strutils,
  std/strformat

import
  general,
  valuebase

export
  general

type
  Dict* = TableRef[string, NpsValue]

  State* = ref object
    dictMin: int
    dicts: seq[Dict]
    stack: seq[NpsValue]
    isLoop*: bool

func newDict*(size: int): Dict =
  newTable[string, NpsValue](size)

func newState*(dictMin: int, dicts: varargs[Dict]): State =
  new result
  result.dictMin = dictMin
  result.dicts = newSeqOfCap[Dict](varargsLen(dicts))
  result.isLoop = false

  for d in dicts:
    result.dicts.add(d)

  for _ in 0 .. max(0, dictMin - varargsLen(dicts)):
    result.dicts.add(newDict(0))

func dicts*(self: State): seq[Dict] =
  self.dicts

func stack*(self: State): seq[NpsValue] =
  self.stack

func dbegin*(self: State, size: int) =
  self.dicts.add(newDict(size))

func dend*(self: State): Dict =
  if self.dicts.len() <= self.dictMin:
    raise newNpsError("Dict stack underflow")
  
  self.dicts.pop()

func has*(self: State, name: string): bool =
  result = false

  for d in self.dicts: 
    if d.hasKey(name):
      return true

func set*(self: State, name: string, val: NpsValue) =
  self.dicts[^1][name] = val

func get*(self: State, name: string): NpsValue =
  for d in self.dicts: 
    if d.hasKey(name):
      return d[name]

  raise newNpsError(fmt"Undefined symbol '{name}'")

proc push*(self: State, val: NpsValue) =
  self.stack.add(val.copy())

func pop*(self: State): NpsValue =
  if self.stack.len() == 0:
    raise newNpsError("stack underflow")

  self.stack.pop()

proc check*(self: State, items: openArray[NpsType]) =
  if self.stack.len() < items.len():
    raise newNpsError(fmt"Expected {items.len()} items on the stack but found {self.stack.len()} items instead")

  var i = self.stack.len() - 1

  for pst in items:
    if self.stack[i] != pst:
      raise newNpsError(fmt"Expected type {pst} for stack position {i}, but found type {self.stack[i].kind} instead")

    i -= 1

proc `$`*(self: State): string =
  var items: seq[string]

  for item in self.stack:
    items.add($item)

  items.join("\n")
