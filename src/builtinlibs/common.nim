import std/[
  tables,
  strutils
]

import ../[
  general,
  value,
  state,
  logging
]

export
  general,
  value,
  state,
  logging


template addV*(dict: Dict, name, docstr: static string, item: Value) =
  block:
    let
      val = item
      sdocstr {.compileTime.} = docstr.strip()
    val.doc = sdocstr
    dict[name] = val


template addF*(dict: Dict, name, docstr: static string, args: ProcArgs, body: untyped) =
  addV(dict, name, docstr):
    newProcedure(args, proc(sptr {.inject.}: pointer, r {.inject.}: Runner, deferred {.inject.}: var seq[seq[Value]]) =
      let s {.inject, used.} = cast[State](sptr)
      body
    )

template addS*(dict: Dict, file, name, docstr: static string, args: ProcArgs, body: string) =
  addV(dict, name, docstr):
    newProcedure(args, file, body)
