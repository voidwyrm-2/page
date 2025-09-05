# NPScript

A PostScript implementation with a focus on console applications.

## Installation

### Prebuilt binaries

Prebuilt binaries are found in the [releases](https://github.com/voidwyrm-2/npscript/releases/latest).

### Compiling locally

**Prerequisites** 
- Unix system or similar (compiling on Windows is not currently supported)
- Git, which should be on your system already
- Nim, which can be downloaded from https://nim-lang.org/install.html
- Nimble, which should have come bundled with Nim

```sh
git clone https://github.com/voidwyrm-2/npscript
cd npscript
nimble install noise
chmod +x build.sh
./build.sh
./out/npscript -v
./out/npscript --repl
```

Addtionally, if you want to cross-compile, you'll need
- Zig, which can be downloaded from https://ziglang.org/download

```sh
git clone https://github.com/voidwyrm-2/npscript
cd npscript
nimble install zigcc
chmod +x build.sh
./build.sh native
```

For building for WASM, you'll need
- Emscripten, which can be downloaded from https://emscripten.org/docs/getting_started/downloads.html

```sh
git clone https://github.com/voidwyrm-2/npscript
cd npscript
chmod +x build.sh
./build.sh wasi
```
