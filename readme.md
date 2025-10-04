# Page

A PostScript-inspired stack-based scripting language.

Unlike PostScript, Page is intended for general scripting, like Python or Lua.

## Installation

### Prebuilt binaries

Prebuilt binaries can be downloaded from the [releases](https://github.com/voidwyrm-2/page/releases/latest).
<!--If you aren't sure which to pick, go with `windows-amd64`, `linux-amd64`, or `macosx-arm64`, depending on your system.-->

### Compiling locally

**Prerequisites**  
- A Unix system or similar (compiling on Windows is not currently supported)
- Git, which should be on your system already
- Nim, which can be downloaded from https://nim-lang.org/install.html
- Nimble, which should have come bundled with Nim

```sh
git clone https://github.com/voidwyrm-2/page
cd page
chmod +x build.nims
./build.nims host
./out/host/page -v
./out/host/page --repl
```

Addtionally, if you want to cross-compile or build in release mode, you'll need
- Zig, which can be downloaded from https://ziglang.org/download

```sh
git clone https://github.com/voidwyrm-2/page
cd page
sudo sh -c "printf '#! /bin/sh\nzig cc \\\$@' > /usr/local/bin/zigcc"
sudo chmod +x /usr/local/bin/zigcc
chmod +x build.nims
./build.nims some
```

For building for MacOS, you'll need
- A MacOS system, because of library issues

```sh
git clone https://github.com/voidwyrm-2/page
cd page
xcode-select --install
chmod +x build.nims
./build.nims macos
```

## Contributing

See [contrib.md](/contrib.md).
