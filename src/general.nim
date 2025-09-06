import std/[
  strutils,
  os,
  random,
  strformat
]

randomize()

let
  npsFolder* = getHomeDir() / ".npscript"
  npsStd* = npsFolder / "std"
  npsCache* = npsFolder / "cache"
  npsReplHistory* = npsFolder / "repl_history"

type
  NpsError* = ref object of CatchableError
    stackTrace: seq[string]

  NpsMetaError* = ref object of CatchableError

  NpsQuitError* = ref object of NpsMetaError
    code*: int = 0

  NpsExitError* = ref object of NpsMetaError

  CacheError* = object of CatchableError

  Cache* = ref object
    r: Rand
    path: string

func newNpsError*(msg: string): NpsError =
  NpsError(msg: msg)

func addTrace*(self: NpsError, trace: string) =
  self.stackTrace.add(trace)

func `$`*(self: NpsError): string =
  self.msg & "\nStacktrace:\n" & self.stackTrace.join("\n")

proc verifyNps*() =
  discard npsFolder.existsOrCreateDir()
  discard npsStd.existsOrCreateDir()
  discard npsCache.existsOrCreateDir()

proc newCache*(): Cache =
  new result
  result.r = initRand()
  result.path = npsCache / "cache-"

  result.path &= $result.r.rand(0..9)
  result.path &= $result.r.rand(0..9)
  result.path &= $rand(0..9)
  result.path &= $rand(0..9)
  result.path &= $rand(0..9)
  result.path &= $rand(0..9)
  result.path &= $rand(0..9)

  result.path.createDir() 

proc open*(self: Cache, path: string, mode: FileMode): File =
  if not open(result, self.path / path):
    raise newException(CacheError, fmt"Could not open '{path}'")

proc openTemp*(self: Cache, mode: FileMode = fmWrite): File =
  var path = "temp-"
  path &= $self.r.rand(0..9)
  path &= $self.r.rand(0..9)
  path &= $self.r.rand(0..9)
  path &= $self.r.rand(0..9)

  self.open(path, mode)
    
proc openRead*(self: Cache, path: string): File =
  self.open(path, fmRead)

proc openWrite*(self: Cache, path: string): File =
  self.open(path, fmWrite)

proc openReadWrite*(self: Cache, path: string): File =
  self.open(path, fmReadWrite)

proc readFile*(self: Cache, path: string): string =
  let f = self.openRead(path)

  try:
    result = f.readAll()
  finally:
    f.close()

proc writeFile*(self: Cache, path, text: string) =
  let f = self.openWrite(path)

  try:
    f.write(text)
  finally:
    f.close()
