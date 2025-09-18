BINDIR="out"

tryq() {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

compwasi() {
    targetpair="wasm32-wasi"
    outpath="$BINDIR/$targetpair"
    result="$outpath/npscript.wasm"

    nim c \
        -d:release \
        --cc:clang \
        --clang.exe:emcc \
        --clang.linkerexe:emcc \
        --clang.cpp.exe:emcc \
        --clang.cpp.linkerexe:emcc \
        --passC:"-sPURE_WASI=1" \
        --passL:"-sPURE_WASI=1" \
        -d:wasi \
        --mm:arc \
        -d:useMalloc \
        -d:noSignalHandler \
        --threads:off \
        --noMain \
        --os:any \
        --cpu:wasm32 \
        --forceBuild:on \
        -o:"$result" \
        src/npscript.nim
    tryq
    
    cp -R "$outpath" .
    tryq
    
    zip -r "$targetpair" "$targetpair"
    tryq
    
    mv "$targetpair.zip" out/
    tryq
    
    rm -rf "$targetpair"
    tryq

    echo "built '$targetpair' (any+wasm32)"
}

compmacos() {
    targetpair="macosx-arm64"
    outpath="$BINDIR/$targetpair"
    result="$outpath/npscript"
    
    nim c \
        -d:release \
        --cc:clang \
        --clang.exe:"clang" \
        --clang.linkerexe:"clang" \
        --forceBuild:on \
        --os:"macosx" \
        --cpu:"arm64" \
        -o:"$result" \
        src/npscript.nim
    tryq
    
    cp -R "$outpath" .
    tryq
    
    zip -r "$targetpair" "$targetpair"
    tryq

    mv "$targetpair.zip" "$BINDIR/"
    tryq

    rm -rf "$targetpair"
    tryq

    echo "built '$targetpair' (macosx+arm64)"
}

# zcomp(os, arch, llvmTriple)
zcomp() {
    ext=""

    if [ "$1" = "windows" ]; then
        ext=".exe"
    fi

    llvmTriple="$3"

    outpath="$BINDIR/$llvmTriple"
    result="$outpath/npscript$ext"
    
    nim c \
        -d:release \
        --cc:clang \
        --clang.exe:"zigcc" \
        --clang.linkerexe:"zigcc" \
        --passC:"-target $llvmTriple $4" \
        --passL:"-target $llvmTriple $5" \
        --os:"$1" \
        --cpu:"$2" \
        --forceBuild:on \
        -o:"$result" \
        src/npscript.nim
    tryq
    
    cp -R "$outpath" .
    tryq
    
    zip -r "$llvmTriple" "$llvmTriple"
    tryq

    mv "$llvmTriple.zip" "$BINDIR/"
    tryq

    rm -rf "$llvmTriple"
    tryq

    echo "built '$1/$2' with LLVM triple '$llvmTriple'"
}

if [ ! -d "$BINDIR/" ]; then
    mkdir "$BINDIR/"
fi


if [ "$1" = "native" ]; then
    rm -rf "$BINDIR/*"
    zcomp "linux" "amd64" "x86_64-linux-gnu"
    zcomp "linux" "i386" "x86-linux-gnu"
    zcomp "linux" "arm64" "aarch64-linux-gnu"

    zcomp "linux" "amd64" "x86_64-linux-musl"
    zcomp "linux" "i386" "x86-linux-musl"
    zcomp "linux" "arm64" "aarch64-linux-musl"

    zcomp "windows" "amd64" "x86_64-windows"
    zcomp "windows" "i386" "x86-windows"
elif [ "$1" = "targ" ]; then
    zcomp "$2" "$3" "$4" "$5" "$6"
elif [ "$1" = "wasi" ]; then
    compwasi
elif [ "$1" = "macos" ]; then
    compmacos
elif [ "$1" = "host" ]; then
    rm -rf "$BINDIR/host/"
    nim c \
    -d:release \
    --forceBuild:on \
    -o:"$BINDIR/host/npscript" \
    src/npscript.nim
elif [ "$1" = "" ]; then
    nim c \
    -o:"$BINDIR/npscript" \
    src/npscript.nim
elif [ "$1" = "help" ]; then
    echo "Usage:"
    echo "./build.sh help"
    echo "- Shows a list of subcommands\n"

    echo "./build.sh native"
    echo "- Builds for all non-MacOS and non-WASM targets.\n"

    echo "./build.sh targ <os> <cpu> <llvm triple> [compiler flags] [linker flags]"
    echo "- builds for the specified target.\n"

    echo "./build.sh wasi"
    echo "- builds for the WASM/WASI target.\n"

    echo "./build.sh macos"
    echo "- builds for the MacOS target (only works on MacOS systems).\n"

    echo "./build.sh host"
    echo "- builds for the host system.\n"

    echo "./build.sh"
    echo "- builds in debug mode for the host system."
else
    echo "Unknown build target '$1'"
    echo "Run './build.sh help' for a list of subcommands"
    exit 1
fi
