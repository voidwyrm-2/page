import std/strutils

import
  state,
  values,
  parser

from lexer import
  lit,
  trace,
  newLexer,
  lex

from builtins import nil

export
  values


type
  Interpreter* = ref object
    state: State


proc codeEvaler(file, text: string): State;

proc newInterpreter*(): Interpreter =
  new result
  result.state = newState(1, builtins.builtins.copy())
  result.state.codeEval = codeEvaler

proc newInterpreter*(state: State): Interpreter =
  new result
  result.state = state

proc newInterpreter*(dicts: seq[Dict]): Interpreter =
  new result
  result.state = newState(min(2, dicts.len()), dicts)

func state*(self: Interpreter): State =
  self.state

proc exec*(self: Interpreter, nodes: openArray[Node])

proc exec(self: Interpreter, n: Node) =
  case n.typ
  of nSymbol:
    self.state.push(newNpsSymbol(n.tok.lit()))
  of nString:
    self.state.push(newNpsString(n.tok.lit()))
  of nNumber:
    let num = parseFloat(n.tok.lit())
    self.state.push(newNpsNumber(num))
  of nList:
    var i = newInterpreter(self.state.dicts())
    i.exec(n.nodes)
    self.state.push(newNpsList(i.state().stack()))
  of nFunc:
    self.state.push(newNpsFunction(n.nodes))
  of nWord:
    let v = self.state.get(n.tok.lit())

    if v.kind == tFunction:
      let f = Function(v)

      self.state.check(f.getArgs())

      f.run(self.state, proc(nodes: seq[Node]) = self.exec(nodes))
    else:
      self.state.push(v)

proc exec*(self: Interpreter, nodes: openArray[Node]) =
  for n in nodes:
    try:
      self.exec(n)
    except NpsExitError:
      if not self.state.isLoop:
        let e = newNpsError("'exit' cannot be used outside of a loop")
        
        case n.typ
        of nWord, nSymbol, nString, nNumber:
          e.addTrace(n.tok.trace())
        of nList, nFunc:
          e.addTrace(n.anchor.trace())
        
        raise e

      raise NpsExitError()
    except NpsError as e:
      case n.typ
      of nWord, nSymbol, nString, nNumber:
        e.addTrace(n.tok.trace())
      of nList, nFunc:
        e.addTrace(n.anchor.trace())

      raise e


proc codeEvaler(file, text: string): State =
  result = newState(1, builtins.builtins)
  
  let
    l = newLexer(file, text)
    p = newParser(l.lex())
    i = newInterpreter(result)

  i.exec(p.parse())
