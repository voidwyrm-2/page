type
  Runner* = proc(nodes: seq[Node])
  NpsNativeProc* = proc(s: State, r: Runner)

  Function* = ref object of NpsValue
    args: seq[NpsType]

    case isNative: bool
    of true:
      native: NpsNativeProc
    of false:
    tokens: seq[Node]


proc newNpsFunction*(args: seq[NpsType], native: NpsNativeProc): Function =
  Function(kind: tFunction, native: native, args: args.reversed(), isNative: true)

proc newNpsFunction*(args: seq[NpsType], tokens: seq[Node]): Function =
  Function(kind: tFunction, tokens: tokens, args: args.reversed(), isNative: false)

proc newNpsFunction*(tokens: seq[Node]): Function =
  newNpsFunction(@[], tokens)

proc newNpsFunction*(args: seq[NpsType], file, text: string): Function =
  var
    lexer = newLexer(file, text)
    parser = initParser(lexer.lex())

  newNpsFunction(args, parser.parse())

method copy*(self: Function): NpsValue =
  self

func native*(self: Function): bool =
  self.isNative

func getArgs*(self: Function): seq[NpsType] =
  self.args

func getNodes*(self: Function): seq[Node] =
  self.tokens

func getNative*(self: Function): NpsNativeProc =
  self.native

method debug*(self: Function): string =
  if self.isNative:
    "<native function>"
  else:
    "<composite function>"
