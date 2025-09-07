import std/[
  sequtils,
  sugar,
  strutils,
  strformat,
  os
]


const
  npscriptHeader* = staticRead("data/npscript.h")

proc remotePathHead(path: string): string =
  path.split("/")[1..^1].join("/")

proc getFilesWithEnding(folder: string, fileEnding: string): seq[string] {.compileTime.} =
  result = collect:
    for path in walkDir(folder):
      let p = path.path.replace('\\', '/')
      if p.endswith(fmt".{fileEnding}"): path.path.remotePathHead()

proc readFilesWithEnding(folder: string, fileEnding: string): seq[tuple[path, data: string]] {.compileTime.} =
  result = getFilesWithEnding(folder, fileEnding).mapIt((it.remotePathHead(), staticRead(it)))

const
  stdFiles* = readFilesWithEnding("src/std", "nps")
