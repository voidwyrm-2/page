import std/strutils

import
  state,
  value,
  parser,
  logging

from lexer import
  lit,
  trace,
  newLexer,
  lex

from builtins import nil

export value


type Interpreter* = ref object
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
    self.state.push(newSymbol(n.tok.lit))
  of nString:
    self.state.push(newString(n.tok.lit))
  of nInteger:
    let num = parseInt(n.tok.lit)
    self.state.push(newInteger(num))
  of nReal:
    let num = parseFloat(n.tok.lit)
    self.state.push(newReal(num))
  of nList:
    var i = newInterpreter(self.state.dicts())
    i.exec(n.nodes)
    self.state.push(newList(i.state().stack()))
  of nProc:
    self.state.push(newProcedure(n.nodes))
  of nWord:
    logger.logdv("Found word with value '" & n.tok.lit & "'")
    let v = self.state.get(n.tok.lit)

    if v.typ == tProcedure:
      logger.logdv("Word is a function")

      logger.logdv("Checking function arguments")
      self.state.check(v.args)

      logger.logdv("Executing function")

      let runner = proc(nodes: seq[Node]) = self.exec(nodes)

      if v.ptype == ptLiteral:
        evalValues(self.state, runner, v.values)
      else:
        v.run(cast[pointer](self.state), runner)
    else:
      logger.logdv("Word is not a function")
      self.state.push(v)

proc exec*(self: Interpreter, nodes: openArray[Node]) =
  for n in nodes:
    try:
      self.exec(n)
    except PgExitError:
      logger.logdv("An ExitError was caught")
      if not self.state.isLoop:
        logger.logdv("But the ExitError wasn't thrown inside of a loop")
        let e = newPgError("'exit' cannot be used outside of a loop")
        
        case n.typ
        of nWord, nSymbol, nString, nInteger, nReal:
          e.addTrace(n.tok.trace())
        of nList, nProc:
          e.addTrace(n.anchor.trace())
        
        raise e

      raise PgExitError()
    except PgError as e:
      logger.logdv("A Error was caught")

      case n.typ
      of nWord, nSymbol, nString, nInteger, nReal:
        e.addTrace(n.tok.trace())
      of nList, nProc:
        e.addTrace(n.anchor.trace())

      raise e


proc codeEvaler(file, text: string): State =
  result = newState(1, builtins.builtins)
  
  let
    l = newLexer(file, text)
    p = newParser(l.lex())
    i = newInterpreter(result)

  i.exec(p.parse())
