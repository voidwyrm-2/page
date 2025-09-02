import
  std/strutils,
  std/enumerate

type
  NpsError* = object of CatchableError
    hasPos: bool = false
    ctxStack: seq[string]

func newNpsError*(parent: ref NpsError, pos, ctx: string): ref NpsError =
  if not parent.hasPos:
    parent.msg = pos & "\n " & parent.msg
    parent.hasPos = true
  parent.ctxStack.add(ctx)
  parent

func newNpsError*(msg: string): ref NpsError =
  (ref NpsError)(msg: msg)

func `$`*(self: NpsError): string =
  var strs: seq[string]

  for i, ctx in enumerate(self.ctxStack):
    strs.add(indent(ctx, i + 1))

  self.msg & "\nStacktrace:\n" & strs.join("\n")

func `$`*(self: ref NpsError): string =
  $(self[])
