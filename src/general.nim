import
  std/strutils

type
  NpsError* = ref object of CatchableError
    hasPos: bool = false
    stackTrace: seq[string]

func newNpsError*(msg: string): NpsError =
  NpsError(msg: msg)

func addTrace*(self: NpsError, trace: string) =
  self.stackTrace.add(trace)

func `$`*(self: NpsError): string =
  self.msg & "\nStacktrace:\n" & self.stackTrace.join("\n")
