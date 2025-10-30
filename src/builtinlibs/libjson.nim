import std/[
  strutils,
  strformat,
  parsejson,
  os,
  streams,
  tables,
  enumerate
]

import
  common,
  libio


let lib* = newDict(0)

template addV(name, doc: string, item: Value) =
  addV(lib, name, doc, item)

template addF(name, doc: string, args: ProcArgs, body: untyped) =
  addF(lib, name, doc, args, body)

template addS(name, doc: string, args: ProcArgs, body: string) =
  addS(lib, "json.pg", name, doc, args, body)



const tokToStr: array[TokKind, string] = [
  "invalid token",
  "EOF",
  "string literal",
  "int literal",
  "float literal",
  "true",
  "false",
  "null",
  "'{'", "'}'", "'['", "']'", "':'", "','"
]


proc check(parse: var JsonParser, tok: TokKind) =
  if parse.tok != tok:
    parse.raiseParseErr(tokToStr[tok])

proc parseValue(parse: var JsonParser): Value

proc parseDict(parse: var JsonParser): Dict =
  result = newDict(0)

  parse.eat(tkCurlyLe)

  while parse.tok != tkCurlyRi:
    let name = parse.a
    parse.eat(tkString)
    parse.eat(tkColon)

    cast[TableRef[string, Value]](result)[name] = parse.parseValue()

    discard parse.getTok()

    if parse.tok != tkCurlyRi:
      parse.eat(tkComma)

  parse.check(tkCurlyRi)

proc parseList(parse: var JsonParser): seq[Value] =
  parse.eat(tkBracketLe)

  while parse.tok != tkBracketRi:
    result.add(parse.parseValue())

    discard parse.getTok()

    if parse.tok != tkBracketRi:
      parse.eat(tkComma)

  parse.check(tkBracketRi)

proc parseValue(parse: var JsonParser): Value =
  let
    tok = parse.tok
    lit = parse.a

  case tok
  of tkNull:
    result = nullSingleton
  of tkTrue, tkFalse:
    result =
      if lit.parseBool():
        trueSingleton
      else:
        falseSingleton
  of tkString:
    result = newString(lit)
  of tkInt:
    result = newInteger(lit.parseInt())
  of tkFloat:
    result = newReal(lit.parseFloat())
  of tkBracketLe:
    result = newList(parse.parseList())
  of tkCurlyLe:
    result = newDictionary(parse.parseDict())
  else:
    raise newPgError(fmt"{parse.getFilename}({parse.getLine}, {parse.getColumn}) Error: Unexpected token {tokToStr[tok]}")

proc decodeJsonToDict(filename: string, stream: Stream): Dict =
  var parse: JsonParser

  defer: parse.close()

  open(parse, stream, filename)

  discard parse.getTok()

  try:
    result = parse.parseDict()
  except JsonParsingError as e:
    if parse.tok == tkError:
      raise newPgError(fmt"{parse.getFilename}({parse.getLine}, {parse.getColumn}) Error: Unexpected token '{parse.buf[parse.bufpos]}'")

    raise newPgError(e.msg)
  except ValueError as e:
    raise newPgError(e.msg)


proc encodeValueToJson(value: Value, writec: proc(c: char) {.closure.}, writes: proc(str: string) {.closure.}) =
  case value.typ
  of tInvalid:
    panic("Invalid while serializing JSON")
  of tNull, tBool, tInteger, tReal:
    writes($value)
  of tSymbol, tString:
    writes(value.strv.escape())
  of tList:
    let items = value.listv

    writec('[')

    for (i, item) in enumerate(items):
      encodeValueToJson(item, writec, writes)
      if i != items.len - 1:
        writec(',')

    writec(']')
  of tDict:
    let d = value.dictv

    writec('{')

    for (i, k, v) in enumerate(d):
      writes(k.escape())
      writec(':')

      encodeValueToJson(v, writec, writes)

      if i != d.len - 1:
        writec(',')

    writec('}')
  else:
    raise newPgError(fmt"Type '{value.typ}' is not encodable into JSON")


addF("decodes",
"""
'decodes'
S -> dictionary
Parses a string S containing JSON into a dictionary.
""", @[("S", tString)]):
  let
    str = s.pop().strv
    stream = newStringStream(str)
    jsonDict = decodeJsonToDict("", stream)

  s.push(newDictionary(jsonDict))

addF("decodef",
"""
'decodef'
FILE -> dictionary
Parses a file containing JSON into a dictionary.
The file is automatically closed after parsing.
""", @[("FILE", tExtitem)]):
  let fobj = s.pop()
  fobj.checkPgFile()

  let
    stream = newFileStream(cast[File](fobj.dat))
    jsonDict = decodeJsonToDict("", stream)

  s.push(newDictionary(jsonDict))

addF("encodes",
"""
'encodes'
D -> str
Encodes a dictionary D as a JSON string.
Symbol values gets encoded as strings;
Procedure and Extitem values are not encodable.
""", @[("D", tDict)]):
  let d = s.pop()

  var str = newStringOfCap(100)

  encodeValueToJson(
    d,
    proc(c: char) = str.add(c),
    proc(s: string) = str.add(s)
  )

  s.push(newString(str))

addF("encodef",
"""
'encodef'
D FILE -> int
Encodes a dictionary D as JSON and writes it to a file, returing the number of bytes written.
Symbol values gets encoded as strings;
Procedure and Extitem values are not encodable.
The file is NOT automatically closed after parsing.
""", @[("D", tDict), ("FILE", tExtitem)]):
  let
    fobj = s.pop()
    d = s.pop()

  fobj.checkPgFile()

  let f = cast[File](fobj.dat)
  
  var written = 0

  encodeValueToJson(
    d,
    proc(c: char) =
      written += f.writeBuffer(c.addr, 1),
    proc(s: string) =
      written += f.writeBuffer(s[0].addr, s.len)
  )

  s.push(newInteger(written))
