import std/[
  tables,
  strutils,
  strformat,
  sequtils
]


type
  ArgparseError* = object of CatchableError

  Flag = ref object
    names: seq[string]
    help: string
    needsValue: bool

  FlagResult* = ref object
    exists*: bool
    value*: string

  ParseResult* = object
    inner: Table[string, FlagResult]
    leftover*: seq[string]
  
  Argparser* = ref object
    name: string
    flags: seq[Flag]
    flagMap: OrderedTable[string, Flag]


func get*(self: ParseResult, name: string): FlagResult =
  if not self.inner.hasKey(name):
    raise newException(ArgparseError, fmt"Flag '{name}' does not exist")

  self.inner[name]

func newArgparser*(name: string): Argparser =
  Argparser(name: name)

func addFlag(self: Argparser, names: openArray[string], help: string, needsValue: bool) =
  if varargsLen(name) == 0:
    raise newException(ValueError, "Flags must have at least one name")

  let f = Flag(names: names.toSeq(), help: help, needsValue: needsValue)

  self.flags.add(f)

  for name in names:
    if name.startsWith("-"):
      raise newException(ValueError, fmt"Flag names cannot start hyphens (referring to '{name}')")
    elif self.flagMap.hasKey(name):
      raise newException(ValueError, fmt"Flag '{name}' already exists")

    self.flagMap[name] = f

func flag*(self: Argparser, names: static varargs[string], help: string = "") =
  ## Creates a flag without an argument.
  self.addFlag(names, help = help, needsValue = false)

func opt*(self: Argparser, names: static varargs[string], help: string = "") =
  ## Creates a flag with an argument.
  self.addFlag(names, help = help, needsValue = true)

proc parse*(self: Argparser, args: openArray[string]): ParseResult =
  result.inner = initTable[string, FlagResult](0)

  var lastFlag: tuple[n: string, f: FlagResult]

  for arg in args:
    var hyphens = 0

    while hyphens < arg.len() and arg[hyphens] == '-':
      hyphens += 1

    if hyphens == 0:
      if lastFlag.f != nil:
        lastFlag = ("", nil)
      else:
        result.leftover.add(arg)
    elif hyphens == 1 or hyphens == 2:
      if lastFlag.f != nil:
        raise newException(ArgparseError, fmt"Expected argument for flag '{lastFlag.n}'")

      let arg = arg.strip(trailing=false, chars={'-'})

      if not self.flagMap.hasKey(arg):
        raise newException(ArgparseError, fmt"Unknown flag '{arg}'")

      let
        flag = self.flagMap[arg]
        res = FlagResult(exists: true)

      if flag.needsValue:
        lastFlag = (arg, res)

      result.inner[flag.names[0]] = res
    else:
      raise newException(ArgparseError, fmt"Invalid flag '{arg}'")
  
  for flag in self.flags:
    if not result.inner.hasKey(flag.names[0]):
      result.inner[flag.names[0]] = FlagResult(exists: false)

func `<`(a, b: tuple[n, h: string]): bool {.used.} =
  a.n.len() < b.n.len()

proc `$`*(self: Argparser): string =
  result = self.name

  for flag in self.flags:
    result &= " [-" & flag.names.join(" -") & "]"

  var flags: seq[tuple[n, h: string]]
  
  for flag in self.flags:
    var str = "-"

    str &= flag.names.join(", -")

    if flag.needsValue:
      str &= " <value>"

    flags.add((str, flag.help))

  let maxlen = max(flags).n.len()

  for flag in flags:
    let spaces = maxlen - flag.n.len() + 2

    result &= "\n"
    result &= flag.n
    
    for _ in 0..<spaces:
      result &= " "

    result &= flag.h
