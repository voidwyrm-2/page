import std/[
  strutils,
  strformat
]

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
  rand: Rand
  state: State


proc codeEvaler(g: GlobalState, file, text: string): State

proc newInterpreter*(state: State): Interpreter =
  new result
  result.rand = initRand()
  result.state = state

proc newInterpreter*(dicts: seq[Dict]): Interpreter =
  newInterpreter(newState(1, dicts))

proc newInterpreter*(): Interpreter =
  result = newInterpreter(@[builtins.builtins.copy()])
  result.state.codeEval = codeEvaler

func state*(self: Interpreter): State =
  self.state

func pstate(self: Interpreter): ProcState =
  new result
  result.r = self.state.nodeRunner
  result.rand = self.rand
  result.deferred = self.state.deferred

proc exec*(self: Interpreter, nodes: openArray[Node])

proc runDeferred*(self: Interpreter) =
  self.state.deferred.add(@[])
  defer: discard self.state.deferred.pop()

  for p in self.state.deferred[^2]:
    p.run(cast[pointer](self.state), self.pstate)

proc exec(self: Interpreter, n: Node) =
  logger.logd("DEFERRED: " & $self.state.deferred)

  #logger.log(fmt"NODE: {n}", llInternDebug)

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
    var i = newInterpreter(self.state.dicts)
    i.state.g = self.state.g
    i.exec(n.nodes)
    self.state.push(newList(i.state.stack))
  of nProc:
    self.state.push(newProcedure(n.nodes))
  of nWord:
    logger.logdv("Found word with value '" & n.tok.lit & "'")
    let v = self.state.get(n.tok.lit)

    if v.typ == tProcedure:
      logger.logdv("Word is a function")
      logger.logdv(fmt"As debug: `{v.debug()}`")

      logger.logdv("Checking function arguments")
      self.state.check(v.args)

      logger.logdv("Executing function")

      let ps = self.pstate

      if v.ptype == ptLiteral:
        evalValues(self.state, ps, v.values)
      else:
        v.run(cast[pointer](self.state), ps)
    else:
      logger.logdv("Word is not a function")
      self.state.push(v)
  of nDot:
    let (literal, scopes, v) = self.state.nestedGet(n)

    for d in scopes:
      self.state.dbegin(d)

    defer:
      for _ in 0..<scopes.len:
        discard self.state.dend(self.pstate)

    if v.typ == tProcedure and not literal:
      self.state.check(v.args)

      let ps = self.pstate

      if v.ptype == ptLiteral:
        evalValues(self.state, ps, v.values)
      else:
        v.run(cast[pointer](self.state), ps)
    else:
      self.state.push(v)

proc exec*(self: Interpreter, nodes: openArray[Node]) =
  if self.state.nodeRunner == nil:
    self.state.nodeRunner = proc(nodes: seq[Node]) = self.exec(nodes)

  for n in nodes:
    try:
      self.exec(n)
    except PgExitError:
      logger.logdv("An ExitError was caught")
      if not self.state.isLoop:
        logger.logdv("But the ExitError wasn't thrown inside of a loop")
        let e = newPgError("'exit' cannot be used outside of a loop")

        e.addTrace(n.trace())

        self.runDeferred()

        raise e

      raise PgExitError()
    except PgError as e:
      logger.logdv("A Error was caught")

      e.addTrace(n.trace())

      self.runDeferred()

      raise e


proc codeEvaler(g: GlobalState, file, text: string): State =
  result = newState(1, builtins.builtins.copy())
  result.g = g

  let
    l = newLexer(file, text)
    p = newParser(l.lex())
    i = newInterpreter(result)

  i.exec(p.parse())
