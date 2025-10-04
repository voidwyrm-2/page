import std/[
  strformat,
  strutils
]

import general

export general


func `&&=`(a: var bool, b: bool) =
  a = a and b


type
  TokenType* = enum
    ttNone,
    ttWord,
    ttSymbol,
    ttString,
    ttInteger,
    ttReal,
    ttBracketOpen,
    ttBracketClose,
    ttBraceOpen,
    ttBraceClose

  Token* = object
    ty: TokenType
    file, lit: string
    col, ln: int

  Lexer* = ref object
    file, text: string
    idx, col, ln: int
    ch: char
    eof: bool


func toTokenType(ch: char, tt: var TokenType): bool =
  case ch
  of '[':
    tt = ttBracketOpen
  of ']':
    tt = ttBracketClose
  of '{':
    tt = ttBraceOpen
  of '}':
    tt = ttBraceClose
  else:
    return false

  true

func initToken*(typ: TokenType, file, lit: string, col, ln: int): Token =
  Token(ty: typ, file: file, lit: lit, col: col, ln: ln)

func kind*(tok: Token): TokenType =
  tok.ty

func lit*(tok: Token): string =
  tok.lit

func line*(tok: Token): int =
  tok.ln

func trace*(tok: Token): string =
  fmt"{tok.file}:{tok.ln}:{tok.col}"

func `==`*(a: Token, b: TokenType): bool =
  a.kind == b

func `==`*(a: Token, b: string): bool =
  a.lit == b

func dbgLit*(tok: Token): string =
  case tok.kind
  of ttString:
    "(" & tok.lit & ")"
  of ttSymbol:
    "/" & tok.lit
  else:
    tok.lit

func `$`*(tok: Token): string =
  "{" & fmt"{tok.kind} `{tok.lit}` {tok.col} {tok.ln} '{tok.file}'" & "}"


func next(self: Lexer) # Nim, you're a modern (ish) compiled language, how is this an issue

func newLexer*(file, text: string): Lexer =
  new result
  result.file = file
  result.text = text
  result.idx = -1
  result.ln = 1
  result.next()

func error(self: Lexer, msg: string) =
  let e = newPgError(msg)

  e.addTrace(fmt"{self.file}:{self.ln}:{self.col}")

  raise e

func next(self: Lexer) =
  self.idx += 1
  self.col += 1

  self.eof = self.idx >= self.text.len()

  self.ch = if self.eof: '\0' else: self.text[self.idx]

  if self.ch == '\n':
    self.ln += 1
    self.col = 0

#func peek(self: Lexer): Option[char] =
# if self.idx + 1 < self.text.len(): some(self.text[self.idx + 1]) else: options.none[char]()

const nonWordChars = {'%', '/', '(', ')', '[', ']', '{', '}'}

func isWordChar*(ch: char): bool =
  result = int(ch) > 32
  result &&= int(ch) < 127
  result &&= not ch.isSpaceAscii()
  result &&= ch notin nonWordChars

func collectString(self: Lexer): Token =
  result.ty = ttString
  result.col = self.col
  result.ln = self.ln
  result.file = self.file

  var escaped = false

  self.next()

  while not self.eof:
    let ch = self.ch

    if escaped:
      case ch
      of '\\', '(', ')':
        result.lit &= ch
      of 'n':
        result.lit &= '\n'
      of 'r':
        result.lit &= '\r'
      of 't':
        result.lit &= '\t'
      of 'v':
        result.lit &= '\v'
      of 'a':
        result.lit &= '\a'
      else:
        self.error(fmt"Invalid escaped charater '{ch}'")

      escaped = false
    elif ch == '\\':
      escaped = true
    elif ch == '(':
      self.error("'(' should be escaped inside of strings")
    elif ch == ')':
      break
    else:
      result.lit &= ch

    self.next()

  if self.ch != ')':
    self.error("Unterminated string literal")

  self.next()

func collectWord(self: Lexer, kind: TokenType = ttWord, skip: bool = false): Token =
  result.ty = kind
  result.col = self.col
  result.ln = self.ln
  result.file = self.file

  if skip:
    self.next()

  let startIdx = self.idx

  while self.ch.isWordChar():
    self.next()

  result.lit = self.text[startIdx .. self.idx - 1]

  if kind == ttWord:
    try:
      discard parseInt(result.lit)
      result.ty = ttInteger
      return
    except ValueError:
      discard

    try:
      discard parseFloat(result.lit)

      case result.lit.toLower()
      of "nan", "inf", "-inf":
        if result.lit.toLower() != result.lit:
          raise newException(ValueError, fmt"Value '{result.lit}' is an invalid number")
      of ".":
        raise newException(ValueError, fmt"Value '{result.lit}' is an invalid number")
      else:
        discard

      result.ty = ttReal
    except ValueError:
      discard

proc lex*(self: Lexer): seq[Token] =
  while not self.eof:
    let ch = self.ch

    if not self.eof and ch.isSpaceAscii():
      while self.ch.isSpaceAscii():
        self.next()
    elif ch == '%':
      while not self.eof and self.ch != '\n':
        self.next()
    elif ch == '(':
      result.add(self.collectString())
    elif (var tt: TokenType; ch.toTokenType(tt)):
      result.add(initToken(tt, self.file, $ch, self.col, self.ln))
      self.next()
    elif ch == '/':
      result.add(self.collectWord(TokenType.ttSymbol, true))
    elif self.ch.isWordChar():
      result.add(self.collectWord())
    else:
      self.error(fmt"Illegal character '{ch}'")
