import std/[
  tables,
  strutils,
  enumerate
]

import ../[
  general,
  value,
  state,
  logging,
  lexer,
  parser
]

export
  general,
  value,
  state,
  logging,
  random


template addV*(dict: Dict, name, docstr: static string, item: Value) =
  block:
    let
      val = item
      sdocstr {.compileTime.} = docstr.strip()
    val.doc = sdocstr
    dict[name] = val


template addF*(dict: Dict, name, docstr: static string, args: ProcArgs, body: untyped) =
  addV(dict, name, docstr):
    newProcedure(args, proc(sptr {.inject.}: pointer, ps {.inject.}: ProcState) =
      let s {.inject, used.} = cast[State](sptr)
      body
    )

template addS*(dict: Dict, file, name, docstr: static string, args: ProcArgs, body: string) =
  addV(dict, name, docstr):
    newProcedure(args, file, body)


let
  trueSingleton* = newBool(true)
  falseSingleton* = newBool(false)
  nullSingleton* = newNull()


proc literalize*(s: State, nodes: seq[Node]): seq[Value] =
  result = newSeq[Value](nodes.len)

  for (i, node) in enumerate(nodes):
    case node.typ
    of nSymbol:
      result[i] = newSymbol(node.tok.lit)
    of nString:
      result[i] = newString(node.tok.lit)
    of nInteger:
      let num = parseInt(node.tok.lit)
      result[i] = newInteger(num)
    of nReal:
      let num = parseFloat(node.tok.lit)
      result[i] = newReal(num)
    of nList:
      result[i] = newList(literalize(s, node.nodes))
    of nProc:
      result[i] = newProcedure(node.nodes)
      result[i].lit = true
    of nWord:
      result[i] = s.get(node.tok.lit)
    of nDot:
      let n = node.copy()

      result[i] = newProcedure(@[], proc(sptr: pointer, ps: ProcState) = 
        let
          s = cast[State](sptr)
          (literal, _, v) = s.nestedGet(n)

        if v.typ == tProcedure and not literal:
          s.check(v.args)

          if v.ptype == ptLiteral:
            evalValues(s, ps, v.values)
          else:
            v.run(sptr, ps)
        else:
          s.push(v)
      )
