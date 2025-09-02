import
  std/strutils

type
  NpsError* = ref object of CatchableError
    stackTrace: seq[string]

  NpsMetaError = ref object of CatchableError

  NpsQuitError* = ref object of NpsMetaError

  NpsExitError* = ref object of NpsMetaError

func newNpsError*(msg: string): NpsError =
  NpsError(msg: msg)

func addTrace*(self: NpsError, trace: string) =
  self.stackTrace.add(trace)

func `$`*(self: NpsError): string =
  self.msg & "\nStacktrace:\n" & self.stackTrace.join("\n")
