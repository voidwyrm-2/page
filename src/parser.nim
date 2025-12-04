import std/[
  strformat,
  sequtils,
  strutils
]

import lexer


type
  NodeType* = enum
    nWord,
    nSymbol,
    nString,
    nInteger,
    nReal,
    nList,
    nProc,
    nDot

  Node* = ref object
    case typ: NodeType
    of nWord, nSymbol, nString, nInteger, nReal:
      tok*: Token
    of nList, nProc:
      anchor*: Token
      nodes*: seq[Node]
    of nDot:
      dot*: Token
      left*, right*: Node

  Parser* = ref object
    toks: seq[Token]
    idx: int

func typ*(self: Node): NodeType =
  self.typ

func tok*(self: Node): Token =
  case self.typ
  of nWord, nSymbol, nString, nInteger, nReal:
    self.tok
  of nList, nProc:
    self.anchor
  of nDot:
    self.left.tok


func dbgLit*(self: Node): string =
  case self.typ
    of nWord, nSymbol, nString, nInteger, nReal:
      self.tok.dbgLit
    of nList:
      "[" & self.nodes.mapIt(it.dbgLit).join(" ") & "]"
    of nProc:
      "{" & self.nodes.mapIt(it.dbgLit).join(" ") & "}"
    of nDot:
      self.left.dbgLit & "." & self.right.dbgLit

func trace*(self: Node): string =
  case self.typ
  of nWord, nSymbol, nString, nInteger, nReal:
    self.tok.trace()
  of nList, nProc:
    self.anchor.trace()
  of nDot:
    if self.left == nil:
      self.dot.trace()
    else:
      self.left.trace()

func copy*(self: Node): Node =
  case self.typ
  of nWord:
    Node(typ: nWord, tok: self.tok)
  of nSymbol:
    Node(typ: nSymbol, tok: self.tok)
  of nString:
    Node(typ: nString, tok: self.tok)
  of nInteger:
    Node(typ: nInteger, tok: self.tok)
  of nReal:
    Node(typ: nReal, tok: self.tok)
  of nList:
    Node(typ: nList, anchor: self.anchor, nodes: self.nodes)
  of nProc:
    Node(typ: nProc, anchor: self.anchor, nodes: self.nodes)
  of nDot:
    Node(typ: nDot, left: self.left, right: self.right)

proc `$`*(self: Node): string =
  result = "(" & $(type(self)) & ": "

  case self.typ
  of nWord, nSymbol, nString, nInteger, nReal:
    result &= $self.tok
  of nList, nProc:
    result &= $self.nodes
  of nDot:
    if self.left != nil:
      result &= $self.left

    result &= "."
    result &= $self.right

  result &= ")"


func newParser*(toks: seq[Token]): Parser =
  Parser(toks: toks)

func isType(self: Parser, tt: TokenType): bool =
  self.idx < self.toks.len and self.toks[self.idx].typ == tt

func nextIsType(self: Parser, tt: TokenType): bool =
  self.idx + 1 < self.toks.len and self.toks[self.idx + 1].typ == tt

proc eat(self: Parser, tt: TokenType): Token =
  if self.idx >= self.toks.len:
    let e = newPgError(fmt"Expected {tt.name}, but found EOF instead")
    e.addTrace(self.toks[^1].trace)
    raise e

  result = self.toks[self.idx]
  
  if result.typ != tt:
    let e = newPgError(fmt"Expected {tt.name}, but found '{result.dbgLit}' instead")
    e.addTrace(result.trace)
    raise e

  inc self.idx

proc parseDot(self: Parser, start: Node): Node =
  result = start

  while self.isType(ttDot):
    result = Node(typ: nDot, dot: self.eat(ttDot), left: result)
    result.right = Node(typ: nWord, tok: self.eat(ttWord))

proc parseInner(self: Parser, startTok: ptr Token, endType: TokenType): seq[Node] =
  while self.idx < self.toks.len:
    let tok = self.toks[self.idx]

    case tok.typ
    of ttWord:
      let n = Node(typ: nWord, tok: tok)
      inc self.idx

      if self.isType(ttDot):
        result.add(self.parseDot(n))
      else:
        result.add(n)
    of ttComma:
      let n = Node(typ: nDot, dot: self.eat(ttComma), left: nil)
      n.right = Node(typ: nWord, tok: self.eat(ttWord))
      result.add(self.parseDot(n))
    of ttSymbol:
      result.add(Node(typ: nSymbol, tok: tok))
      inc self.idx
    of ttString:
      result.add(Node(typ: nString, tok: tok))
      inc self.idx
    of ttInteger:
      result.add(Node(typ: nInteger, tok: tok))
      inc self.idx
    of ttReal:
      result.add(Node(typ: nReal, tok: tok))
      inc self.idx
    of ttBracketOpen:
      inc self.idx
      result.add(Node(typ: nList, anchor: tok, nodes: self.parseInner(addr tok, ttBracketClose)))
      inc self.idx
    of ttBraceOpen:
      inc self.idx
      result.add(Node(typ: nProc, anchor: tok, nodes: self.parseInner(addr tok, ttBraceClose)))
      inc self.idx
    else:
      if tok.typ == endType:
        return

      let e = newPgError(fmt"Unexpected token '{tok.dbgLit}'")
      e.addTrace(tok.trace)
      raise e

  if endType != ttNone:
      let lit =
        case endType
        of ttBracketClose:
          ']'
        of ttBraceClose:
          '}'
        else:
          '\0'

      let e = newPgError(fmt"Expected '{startTok[].lit}' to close '{lit}'")
      e.addTrace(startTok[].trace)
      raise e

proc parse*(self: Parser): seq[Node] =
  self.parseInner(nil, ttNone)
