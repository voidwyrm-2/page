import
  std/strformat,
  std/enumerate,
  std/strutils

import
  state,
  values,
  parser

from lexer import lit

from builtins import nil

export
  values

type
  Interpreter* = object
    state: State
    inList, inFunc: bool

proc initInterpreter*(): Interpreter =
  Interpreter(state: newState(2, builtins.getBuiltins(), newDict(0)))

proc initInterpreter*(dicts: seq[Dict]): Interpreter =
  Interpreter(state: newState(min(2, dicts.len()), dicts))

func getState*(self: Interpreter): State =
  self.state

proc exec*(self: var Interpreter, nodes: openArray[Node]) =
  for i, n in enumerate(nodes):
    case n.typ
    of nSymbol:
      self.state.push(newNpsSymbol(n.tok.lit()))
    of nString:
      self.state.push(newNpsString(n.tok.lit()))
    of nNumber:
      let num = parseFloat(n.tok.lit())
      self.state.push(newNpsNumber(num))
    of nWord:
      let v = self.state.get(n.tok.lit())

      if v.kind == tFunction:
        let f = Function(v)

        self.state.check(f.getArgs())

        if f.native():
          f.getNative()(self.state)
        else:
          self.exec(f.getNodes())
      else:
        self.state.push(v)
    else:
      raise newNpsError(fmt"Unexpected node {n}")
