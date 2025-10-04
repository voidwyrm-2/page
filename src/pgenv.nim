import std/[
  os,
  random,
  strformat
]

import
  pgdata,
  logging


randomize()


let
  pgFolder* = getHomeDir() / ".page"
  pgInclude* = pgFolder / "include"
  pgStd* = pgFolder / "std"
  pgPkg* = pgFolder / "pkg"
  pgCache* = pgFolder / "cache"
  pgReplHistory* = pgFolder / "repl_history"

proc verifypg*() =
  discard pgFolder.existsOrCreateDir()
  discard pgPkg.existsOrCreateDir()
  discard pgCache.existsOrCreateDir()

proc writeFfiHeader*() =
  let exists = pgInclude.existsOrCreateDir()
  if exists:
    return
  
  writeFile(pgInclude / "page.h", pageHeader)


proc writeStdlib*(force: bool) =
  let exists = pgStd.existsOrCreateDir()
  if exists and not force:
    return

  if force:
     logger.log "Writing stdlib because --fstd/--force-std was passed..."
  else:
    logger.log "Writing stdlib for the first time..."

  logger.log "Writing to " & pgStd

  for item in stdFiles:
    logger.log fmt"Writing '{item.path}'..."

    try:
      let path = (pgStd / item.path)
      path.writeFile(item.data)
      logger.log "Written to " & path
    except IOError as e:
      logger.log fmt"Could not write '{item.path}' to {pgStd}:"
      logger.log " " & e.msg

  logger.log ""


type
  CacheError* = object of CatchableError

  Cache* = ref object
    r: Rand


proc newCache*(): Cache =
  new result
  result.r = initRand()

proc open*(self: Cache, path: string, mode: FileMode): File =
  if not open(result, pgCache / path):
    raise newException(CacheError, fmt"Could not open '{path}'")

proc openTemp*(self: Cache, mode: FileMode = fmWrite): File =
  var path = "temp-"
  path &= $self.r.rand(0..9)
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
