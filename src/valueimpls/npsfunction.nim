type
  Runner* = proc(nodes: seq[Node])
  NpsNativeProc* = proc(s: State, r: Runner)

  Function* = ref object of NpsValue
    args: FuncArgs
    case isNative: bool
    of true:
      native: NpsNativeProc
    of false:
      nodes: seq[Node]


proc newNpsFunction*(args: FuncArgs, native: NpsNativeProc): Function =
  Function(kind: tFunction, args: args.reversed(), isNative: true, native: native)

proc newNpsFunction*(args: FuncArgs, nodes: seq[Node]): Function =
  Function(kind: tFunction, args: args.reversed(), isNative: false, nodes: nodes)

proc newNpsFunction*(nodes: seq[Node]): Function =
  newNpsFunction(@[], nodes)

proc newNpsFunction*(args: FuncArgs, file, text: string): Function =
  var
    lexer = newLexer(file, text)
    parser = newParser(lexer.lex())

  newNpsFunction(args, parser.parse())

method copy*(self: Function): NpsValue =
  self

func getArgs*(self: Function): FuncArgs =
  self.args

proc run*(self: Function, s: State, r: Runner) =
  if self.isNative:
    self.native(s, r)
  elif self.nodes.len() > 0:
    r(self.nodes)

method debug*(self: Function): string =
  if self.isNative:
    "<native function>"
  else:
    "<composite function>"
