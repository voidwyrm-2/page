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
    nProc

  Node* = object
    case typ*: NodeType
    of nWord, nSymbol, nString, nInteger, nReal:
      tok*: Token
    of nList, nProc:
      anchor*: Token
      nodes*: seq[Node]

  Parser* = ref object
    toks: seq[Token]
    idx: int

func dbgLit*(node: Node): string =
  case node.typ
    of nWord, nSymbol, nString, nInteger, nReal:
      node.tok.dbgLit
    of nList:
      "[" & node.nodes.mapIt(it.dbgLit).join(" ") & "]"
    of nProc:
      "{" & node.nodes.mapIt(it.dbgLit).join(" ") & "}"

func trace*(node: Node): string =
  case node.typ
  of nWord, nSymbol, nString, nInteger, nReal:
    node.tok.trace()
  of nList, nProc:
    node.anchor.trace()

proc `$`*(node: Node): string =
  result = "(" & $(type(node)) & ": "

  case node.typ
  of nWord, nSymbol, nString, nInteger, nReal:
    result &= $node.tok
  of nList, nProc:
    result &= $node.nodes

  result &= ")"


func newParser*(toks: seq[Token]): Parser =
  Parser(toks: toks)

func parseInner(self: Parser, endType: TokenType): seq[Node] =
  while self.idx < self.toks.len():
    let tok = self.toks[self.idx]

    case tok.kind()
    of ttWord:
      result.add(Node(typ: nWord, tok: tok))
      inc self.idx
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
      result.add(Node(typ: nList, anchor: tok, nodes: self.parseInner(ttBracketClose)))
      inc self.idx
    of ttBraceOpen:
      inc self.idx
      result.add(Node(typ: nProc, anchor: tok, nodes: self.parseInner(ttBraceClose)))
      inc self.idx
    else:
      if tok.kind == endType:
        return

      raise newPgError(fmt"Unexpected token {tok.kind} == {endType}? {tok.kind == endType} '{tok.dbgLit}'")

func parse*(self: Parser): seq[Node] =
  self.parseInner(ttNone)
