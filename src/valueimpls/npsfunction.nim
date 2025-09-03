type
  Runner* = proc(nodes: seq[Node])
  NpsNativeProc* = proc(s: State, r: Runner)

  Function* = ref object of NpsValue
    args: seq[NpsType]

    case isNative: bool
    of true:
      native: NpsNativeProc
    of false:
    nodes: seq[Node]


proc newNpsFunction*(args: seq[NpsType], native: NpsNativeProc): Function =
  Function(kind: tFunction, native: native, args: args.reversed(), isNative: true)

proc newNpsFunction*(args: seq[NpsType], nodes: seq[Node]): Function =
  Function(kind: tFunction, nodes: nodes, args: args.reversed(), isNative: false)

proc newNpsFunction*(nodes: seq[Node]): Function =
  newNpsFunction(@[], nodes)

proc newNpsFunction*(args: seq[NpsType], file, text: string): Function =
  var
    lexer = newLexer(file, text)
    parser = initParser(lexer.lex())

  newNpsFunction(args, parser.parse())

method copy*(self: Function): NpsValue =
  self

func getArgs*(self: Function): seq[NpsType] =
  self.args

proc run*(self: Function, s: State, r: Runner) =
  case self.isNative
  of true:
    self.native(s, r)
  of false:
    r(self.nodes)

method debug*(self: Function): string =
  if self.isNative:
    "<native function>"
  else:
    "<composite function>"
