# NPScript

A PostScript implementation with a focus on console applications.

## Installation

### Prebuilt binaries

Prebuilt binaries can be downloaded from the [releases](https://github.com/voidwyrm-2/npscript/releases/latest).

If you aren't sure which to pick, go with `windows-amd64`, `linux-amd64`, or `macosx-arm64`, depending on your system.

### Compiling locally

**Prerequisites** 
- A Unix system or similar (compiling on Windows is not currently supported)
- Git, which should be on your system already
- Nim, which can be downloaded from https://nim-lang.org/install.html
- Nimble, which should have come bundled with Nim

```sh
git clone https://github.com/voidwyrm-2/npscript
cd npscript
nimble install noise
nimble install https://github.com/voidwyrm-2/nargparse
chmod +x build.sh
./build.sh host
./out/host/npscript -v
./out/host/npscript --repl
```

Addtionally, if you want to cross-compile or build in release mode, you'll need
- Zig, which can be downloaded from https://ziglang.org/download

```sh
git clone https://github.com/voidwyrm-2/npscript
cd npscript
nimble install noise
nimble install https://github.com/voidwyrm-2/nargparse
nimble install zigcc
chmod +x build.sh
./build.sh native
```

For building for Mac, you'll need
- A MacOS system, because of library issues

```sh
git clone https://github.com/voidwyrm-2/npscript
cd npscript
xcode-select --install
nimble install noise
nimble install https://github.com/voidwyrm-2/nargparse
chmod +x build.sh
./build.sh macos
```

For building for WASM, you'll need
- Emscripten, which can be downloaded from https://emscripten.org/docs/getting_started/downloads.html

**NOTICE: while NPScript can be compiled to WASM, functionality is very limited**

```sh
git clone https://github.com/voidwyrm-2/npscript
cd npscript
nimble install noise
nimble install https://github.com/voidwyrm-2/nargparse
chmod +x build.sh
./build.sh wasi
```
