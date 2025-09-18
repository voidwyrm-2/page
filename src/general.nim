import std/[
  strutils,
  strformat,
  sequtils,
  sugar
]

import pkg/regex


type
  NpsError* = ref object of CatchableError
    stackTrace: seq[string]

  NpsMetaError* = ref object of CatchableError

  NpsQuitError* = ref object of NpsMetaError
    code*: int = 0

  NpsExitError* = ref object of NpsMetaError


func newNpsError*(msg: string): NpsError =
  NpsError(msg: msg)

func addTrace*(self: NpsError, trace: string) =
  self.stackTrace.add(trace)

func `$`*(self: NpsError): string =
  self.msg & "\nStacktrace:\n" & self.stackTrace.join("\n")

const
  bgTag = r"(bg\-)?"
  brTag = r"(br\-)?"
  nameSpecifier = bgTag & brTag & r"[a-zA-Z]+"
  rgbSpecifier = bgTag & r"[0-9]{1,3},[0-9]{1,3},[0-9]{1,3}"
  colorFinderSpec = fmt"\(\.({nameSpecifier}|{rgbSpecifier})\)"
  
  colorFinder = re2 colorFinderSpec

func getStyleForRGB(r, g, b: uint, background: bool): string =
  if r > 255 or g > 255 or b > 255:
      raise newException(ValueError, "All values in an RGB specifier must be in the range 0-255")

  result = if background: "\e[48;2;" else: "\e[38;2;"
  result &= $r & ";"
  result &= $g & ";"
  result &= $b & "m"

func getAttributeForName(name: string): string =
  var code: uint
  
  case name
  of "bold":
    code = 1
  else:
    raise newException(ValueError, fmt"'{name}' is not a valid style name")

  "\e[" & $code & "m"
    

func getStyleForName(name: string): string =
  var
    mName = name.strip().toLower()
    background = false
    bright = false
    code: uint
  
  if mName.startsWith("bg-"):
    background = true
    mName = mName[3..^1]

  if mName.startsWith("br-"):
    bright = true
    mName = mName[3..^1]

  if ',' in mName:
    let
      rgb = mName.split(",").mapIt(it.parseUInt())
      r = rgb[0]
      g = rgb[1]
      b = rgb[2]

    return getStyleForRGB(r, g, b, background)

  case mName
  of "reset", "r", "stop":
    return "\e[0m"
  of "colreset", "colr", "colstop":
    code = 9
  of "black":
    code = 0
  of "red":
    code = 1
  of "green":
    code = 2
  of "yellow":
    code = 3
  of "blue":
    code = 4
  of "magenta":
    code = 5
  of "cyan":
    code = 6
  of "white":
    code = 7
  of "orange":
    return getStyleForRGB(255, 199, 6, background)
  of "brown":
    return getStyleForRGB(0x96, 0x4B, 0x00, background)
  of "sage":
    return getStyleForRGB(130, 210, 130, background)
  of "comment":
    return getStyleForRGB(140, 140, 140, background)
  of "header":
    return getStyleForRGB(0, 180, 0, background)
  else:
    return mName.getAttributeForName()

  code += 30

  if bright and code != 9:
    code += 60

  if background:
    code += 10

  result = "\e[" & $code & "m"

proc colorize*(str: string): string =
  str.replace(colorFinder, (m, s) => s[m.group(0)].getStyleForName())
