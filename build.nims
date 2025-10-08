#! /usr/bin/env nim --hints:off

import std/[
  os,
  strformat,
  macros,
  strutils,
  sets
]

const
  appname = "page"
  bindir = "bin"
  distdir = "dist"
  nimc = "nim c"


proc cmd(str: string) =
  echo "Running `", str, "`"
  exec str

proc getPack(targetpair: string): (string, proc()) =
  let outpath = bindir / targetpair

  return (
    outpath / (if "windows" in targetpair: appname & ".exe" else: appname),
    proc() =
      cmd fmt"cp -R {outpath} ."
      
      cmd fmt"zip -r {targetpair} {targetpair}"
      
      cmd fmt"mv {targetpair}.zip {distdir}"
      
      cmd fmt"rm -rf {targetpair}"
  )


type Cmd = ref object
  buf: string
  defines: HashSet[string]

proc addf(self: Cmd, name: string) =
  self.buf &= " "

  if name.len == 1:
    self.buf &= "-"
  else:
    self.buf &= "--"

  self.buf &= name

proc addf(self: Cmd, name, value: string, quoted: bool = false) =
  self.addf(name)
  self.buf &= ":"
  self.buf &= (if quoted: "\"" & value & "\"" else: value)

macro addd(buf, name: untyped): untyped =
  result = newCall(ident"addf", buf, newLit("define"), name.toStrLit)

proc addp(self: Cmd, pkg: string) =
  self.addf "p", "nimbledeps" / "pkgs2" / pkg, true

proc checkEnv(self: Cmd) =
  if (let def = getEnv("DEF"); def.len > 0):
    self.defines = def.split(' ').toHashSet()

proc addExtras(self: Cmd) =
  if "nohttp" notin self.defines:
    self.addd ssl

  self.addp "nargparse-1.0.0-d77b6d27d997463cb62f2067272cddcc7d82de87"
  self.addp "noise-0.1.10-c0cbecd0917a5c13cab331cb959a5280acd3401e"
  self.addp "regex-0.26.3-4d24e7d7441137cd202e16f2359a5807ddbdc31f"
  self.addp "unicodedb-0.13.2-739102d885d99bb4571b1955f5f12aee423c935b"

proc run(self: Cmd) =
  self.checkEnv()

  for def in self.defines:
    self.addf "define", def, true

  self.addExtras()
  self.buf &= " src" / "page.nim"
  cmd self.buf


let paramc = paramCount() - 2

if not dirExists(distdir):
  mkdir distdir


if paramc == 0:
  let buf = Cmd(buf: nimc)
  buf.addd debug
  buf.addf "out", bindir / "page"

  buf.run()
else:
  let cmd = paramStr(3)

  case cmd
  of "host":
    let buf = Cmd(buf: nimc)
    buf.addd release
    buf.addf "forceBuild", "on"

    let (exepath, _) = getPack("host")

    buf.addf("out", exepath)

    buf.run()
  of "macos":
    let buf = Cmd(buf: nimc)
    buf.addd release
    buf.addf "out", bindir / "host" / "page"
    buf.addf "cc", "clang"
    buf.addf "clang.exe", "clang"
    buf.addf "clang.linkerexe", "clang"
    buf.addf "forceBuild", "on"
    buf.addf "os", "macosx"
    buf.addf "cpu", "arm64"

    let (exepath, pack) = getPack("aarch64-macos")

    buf.addf("out", exepath)

    buf.run()
    pack()
  of "target":
    let buf = Cmd(buf: nimc)
    buf.addd release
    buf.addf "cc", "clang"
    buf.addf "clang.exe", "zigcc"
    buf.addf "clang.linkerexe", "zigcc"
    buf.addf "passC", fmt"-target {paramStr(6)}", true
    buf.addf "passL", fmt"-target {paramStr(6)}", true
    buf.addf "os", paramStr(4)
    buf.addf "cpu", paramStr(5)
    buf.addf "forceBuild", "on"

    buf.addf(
      "out",
      if (let output = getEnv("OUT"); output.len > 0):
        output
      else:
        getPack(fmt"target_{paramStr(4)}_{paramStr(5)}_{paramStr(6)}")[0]
    )

    buf.run()
  of "some":
    let targets = @[
      ("linux", @[
        ("amd64", "x86_64-linux-gnu"),
        ("i386", "x86-linux-gnu"),
        ("arm64", "aarch64-linux-gnu"),
        ("amd64", "x86_64-linux-musl"),
        ("i386", "x86-linux-musl"),
        ("arm64", "aarch64-linux-musl")
      ]),
      ("windows", @[
        ("amd64", "x86_64-windows"),
        ("i386", "x86-windows")
      ])
    ]

    for (os, pairs) in targets:
      for (cpu, triple) in pairs:
        let buf = Cmd(buf: nimc)
        buf.addd release
        buf.addf "cc", "clang"
        buf.addf "clang.exe", "zigcc"
        buf.addf "clang.linkerexe", "zigcc"
        buf.addf "passC", fmt"-target {triple}", true
        buf.addf "passL", fmt"-target {triple}", true
        buf.addf "os", os
        buf.addf "cpu", cpu
        buf.addf "forceBuild", "on"

        let (exepath, pack) = getPack(triple)

        buf.addf("out", exepath)

        buf.run()
        pack()
  of "help":
    echo """
Usage:
  ./build.nims help
  - Shows this message.
  
  ./build.nims native
  - Builds for all non-MacOS and non-WASM targets.
  
  ./build.nims target <os> <cpu> <llvm triple>
  - builds for the specified target.
  
  ./build.nims macos
  - builds for the MacOS target (only works on MacOS systems).
  
  ./build.nims host
  - builds for the host system.
  
  ./build.nims
  - builds in debug mode for the host system.

Vars:
  'DEF'
  - Sets the defines; it should be a list of space-separated symbols.
  
  'OUT'
  - Sets the output for the 'target subcommand'
"""
  else:
    echo fmt"Unknown subcommand '{cmd}'"
    quit 1
