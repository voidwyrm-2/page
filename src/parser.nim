import std/strformat

import lexer


type
  NodeType* = enum
    nWord,
    nSymbol,
    nString,
    nNumber,
    nList,
    nFunc

  Node* = object
    case typ*: NodeType
    of nWord, nSymbol, nString, nNumber:
      tok*: Token
    of nList, nFunc:
      anchor*: Token
      nodes*: seq[Node]

  Parser* = ref object
    toks: seq[Token]
    idx: int


func `++`(n: var int) =
  n += 1

proc `$`*(self: Node): string =
  result = "(" & $(type(self)) & ": "

  case self.typ
  of nWord, nSymbol, nString, nNumber:
    result &= $self.tok
  of nList, nFunc:
    result &= $self.nodes

  result &= ")"

func newParser*(toks: seq[Token]): Parser =
  Parser(toks: toks)

func parseInner(self: Parser, endType: TokenType): seq[Node] =
  while self.idx < self.toks.len():
    let tok = self.toks[self.idx]

    case tok.kind()
    of ttWord:
      result.add(Node(typ: nWord, tok: tok))
      ++self.idx
    of ttSymbol:
      result.add(Node(typ: nSymbol, tok: tok))
      ++self.idx
    of ttString:
      result.add(Node(typ: nString, tok: tok))
      ++self.idx
    of ttNumber:
      result.add(Node(typ: nNumber, tok: tok))
      ++self.idx
    of ttBracketOpen:
      ++self.idx
      result.add(Node(typ: nList, anchor: tok, nodes: self.parseInner(ttBracketClose)))
      ++self.idx
    of ttBraceOpen:
      ++self.idx
      result.add(Node(typ: nFunc, anchor: tok, nodes: self.parseInner(ttBraceClose)))
      ++self.idx
    else:
      if tok.kind() == endType:
        return

      raise newNpsError(fmt"Unexpected token {tok.kind()} == {endType}? {tok.kind() == endType} '{tok.dbgLit()}'")

func parse*(self: Parser): seq[Node] =
  self.parseInner(ttNone)
