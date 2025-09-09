import std/[
  strformat,
  strutils
]

import general

export general


#[
func newNpsError*(tok: Token, msg: string): NpsError =
  result = newNpsError(msg)
  result.addTrace(tok)

func addTrace*(self: NpsError, tok: Token) =
  self.addTrace(tok.trace())
]#

type
  TokenType* = enum
    ttNone,
    ttWord,
    ttSymbol,
    ttString,
    ttNumber,
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


func charToTokenType(ch: char, tt: var TokenType): bool =
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

func initToken*(kind: TokenType, file, lit: string, col, ln: int): Token =
  Token(ty: kind, file: file, lit: lit, col: col, ln: ln)

func kind*(self: Token): TokenType =
  self.ty

func lit*(self: Token): string =
  self.lit

func line*(self: Token): int =
  self.ln

func trace*(self: Token): string =
  fmt"{self.file}:{self.ln}:{self.col}"

func `==`*(a: Token, b: TokenType): bool =
  a.kind == b

func `==`*(a: Token, b: string): bool =
  a.lit == b

func dbgLit*(self: Token): string =
  case self.kind
  of ttString:
    "(" & self.lit & ")"
  of ttSymbol:
    "/" & self.lit
  else:
    self.lit

func `$`*(self: Token): string =
  "{" & fmt"{self.kind} `{self.lit}` {self.col} {self.ln} '{self.file}'" & "}"

func next(self: Lexer) # Nim, you're a modern (ish) compiled language, how is this an issue

func newLexer*(file, text: string): Lexer =
  new result
  result.file = file
  result.text = text
  result.idx = -1
  result.ln = 1
  result.next()

func error(self: Lexer, msg: string) =
  let e = newNpsError(msg)

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

func `&&=`(a: var bool, b: bool) =
  a = a and b

const nonWordChars = {'%', '/', '(', ')', '[', ']', '{', '}'}

func isWordChar(self: Lexer): bool =
  result = int(self.ch) > 32
  result &&= int(self.ch) < 127
  result &&= not self.ch.isSpaceAscii()
  result &&= self.ch notin nonWordChars

func collectString(self: Lexer): Token =
  let
    startCol = self.col
    startLn = self.ln

  var
    escaped = false
    lit = ""

  self.next()

  while not self.eof:
    let ch = self.ch

    if escaped:
      case ch
      of '\\', '(', ')':
        lit &= ch
      of 'n':
        lit &= '\n'
      of 'r':
        lit &= '\r'
      of 't':
        lit &= '\t'
      of 'v':
        lit &= '\v'
      of 'a':
        lit &= '\a'
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
      lit &= ch

    self.next()

  if self.ch != ')':
    self.error("Unterminated string literal")

  self.next()

  initToken(TokenType.ttString, self.file, lit, startCol, startLn)

func collectWord(self: Lexer, kind: TokenType = ttWord, skip: bool = false): Token =
  let
    startCol = self.col
    startLn = self.ln

  var k = kind

  if skip:
    self.next()

  let startIdx = self.idx

  while self.isWordChar():
    self.next()

  let lit = self.text[startIdx .. self.idx - 1]

  if kind == ttWord:
    try:
      discard parseFloat(lit)

      case lit.toLower()
      of "nan", "inf", "-inf":
        if lit.toLower() != lit:
          raise newException(ValueError, fmt"Value '{lit}' is an invalid number")
      of ".":
        raise newException(ValueError, fmt"Value '{lit}' is an invalid number")
      else:
        discard

      k = ttNumber
    except ValueError:
      discard

  initToken(k, self.file, lit, startCol, startLn)

proc lex*(self: Lexer): seq[Token] =
  while not self.eof:
    let ch = self.ch

    var tt = ttNone

    if not self.eof and ch.isSpaceAscii():
      while self.ch.isSpaceAscii():
        self.next()
    elif ch == '%':
      while not self.eof and self.ch != '\n':
        self.next()
    elif ch == '(':
      result.add(self.collectString())
    elif charToTokenType(ch, tt):
      result.add(initToken(tt, self.file, $ch, self.col, self.ln))
      self.next()
    elif ch == '/':
      result.add(self.collectWord(TokenType.ttSymbol, true))
    elif self.isWordChar():
      result.add(self.collectWord())
    else:
      self.error(fmt"Illegal character '{ch}'")
