#! /usr/bin/env nim r

import std/[
  sequtils,
  strutils,
  tables,
  osproc,
  re,
  strformat,
  json,
  os
]


const
  version* = staticRead("npscript.nimble")
    .split("\n")
    .filterIt(it.startsWith("version"))[0]
    .split("=")[^1]
    .strip()[1..^2]

  releaseFile = "relmsg.txt"

proc runCmd(cmd: string): string =
  let res = execCmdEx(cmd)
  
  if res.exitCode != 0:
    var n = 0

    while cmd[n] != ' ':
      n += 1
    
    let name = cmd[0 .. n - 1]

    echo fmt"Process '{name}' failed with code {res.exitCode}"
    quit 1

  res.output

func parseVersion(version: string): tuple[major, minor, patch: uint] =
  let parts = version.split(".").mapIt(parseUInt(it))
  (parts[0], parts[1], parts[2])

func `>`(a, b: tuple[major, minor, patch: uint]): bool =
  if a.major == b.major:
    if a.minor == b.minor:
      a.patch > b.patch
    else:
      a.minor > b.minor
  else:
    a.major > b.major

func `$`(t: tuple[major, minor, patch: uint]): string =
  fmt"{t.major}.{t.minor}.{t.patch}"

let
  changelogFinder = re"NPScript [0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}"
  
  commits = runCmd("git --no-pager log --oneline --all")
    .strip()
    .split("\n")

  latestRelease = runCmd("gh release list --json name -L 1")
    .parseJson()[0]
    .getFields()["name"]
    .getStr()[9..^1]
    .parseVersion()

echo "Generating release for version ", version
echo "The latest release is: ", latestRelease

var changelogs: seq[string]

for commit in commits:
  let hash = commit[0..7]
  var c = commit[8..^1].strip()

  let ind = c.findBounds(changelogFinder)

  if ind.first != 0:
    continue

  c = c[9..^1]

  var n = 0

  while c[n] != ' ':
    n += 1

  let ver = c[0..n - 1].parseVersion()

  if ver > latestRelease:
    changelogs.add("https://github.com/voidwyrm-2/npscript/commit/" & hash)
  else:
    break

try:
  releaseFile.writeFile("Changelog" & (if changelogs.len() == 1: "s" else: "") & ":\n" & changelogs.join("\n"))

  let relCmd = fmt"gh release create -t 'NPScript {version}' -F {releaseFile} {version} out/*.zip"
  echo runCmd(relCmd)
finally:
  discard releaseFile.tryRemoveFile()
