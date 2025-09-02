import
  std/parseopt,
  std/strformat,
  std/strutils

#import
#  noise

import 
  general,
  lexer,
  parser,
  interpreter

#[
proc repl() =
  var noise = Noise.init()
  
  echo "NPScript REPL; type '-exit' to exit"

  while true:
    let ok = noise.readLine()
    if not ok:
      break

    let line = noise.getLine()
    case line
    of "-exit":
      break
    else:
      discard

    if line.len > 0 and (not errored or line.endsWith("\\")):
      noise.historyAdd(if line.endsWith("\\"): line[0..^1] else: line)
]#

var
  optRepl: bool = false
  optTokens: bool = false
  optNodes: bool = false

template q1(v: untyped) =
  echo v
  quit 1

proc getBoolF(name, val: string): bool =
  case val.toLower()
  of "true", "":
    result = true
  of "false":
    result = false
  else:
    q1 fmt"Unexpected value for '{name}': '{val}'"

proc processArgs(): seq[string] =
  for kind, key, val in getopt():
    case kind
    of cmdLongOption, cmdShortOption:
      case key:
      of "repl":
        optRepl = getBoolF(key, val)
      of "tokens", "t":
        optTokens = getBoolF(key, val)
      of "nodes", "n":
        optNodes = getBoolF(key, val)
      else:
        q1 fmt"Unknown option '{key}'"
    of cmdArgument:
      result.add(key)
    of cmdEnd:
      discard


proc main() =
  let args = processArgs()

  #if optRepl:
  #  repl()
  #  return

  if args.len() == 0:
    q1 "Expected 'npscript [--repl] [-t|--tokens] [-n|--nodes] <files>'"

  var tokens: seq[Token]

  for arg in args:
    var l = newLexer(arg, readFile(arg))

    try:
      tokens.add(l.lex())
    except NpsError as e:
      q1 e

  if optTokens:
    for t in tokens:
      echo t

  var
    p = initParser(tokens)
    nodes: seq[Node]

  try:
    nodes = p.parse()
  except NpsError as e:
    q1 e

  if optNodes:
    for n in nodes:
      echo n

  var i = newInterpreter()

  try:
    i.exec(nodes)
  except NpsQuitError:
    discard
  except NpsError as e:
    q1 e

when isMainModule:
  main()
