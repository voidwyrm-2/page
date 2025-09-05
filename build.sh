tryq() {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

compwasi() {
    targetpair="wasm32-wasi"
    outpath="out/$targetpair"
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

# zcomp(os, arch, llvmTriple)
zcomp() {
    ext=""

    if [ "$1" = "windows" ]; then
        ext=".exe"
    fi

    targetpair="$1-$2"
    outpath="out/$targetpair"
    result="$outpath/npscript$ext"
    
    nim c \
        -d:release \
        --cc:clang \
        --clang.exe:"zigcc" \
        --clang.linkerexe:"zigcc" \
        --passC:"-target $3" \
        --passL:"-target $3" \
        --os:"$1" \
        --cpu:"$2" \
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

    echo "built '$targetpair' with LLVM triple '$3'"
}

if [ "$1" = "native" ]; then
    zcomp "macosx" "arm64" "aarch64-macos"
    zcomp "linux" "arm64" "aarch64-linux"
    zcomp "linux" "amd64" "x86_64-linux"
    zcomp "windows" "amd64" "x86_64-windows"
elif [ "$1" = "wasi" ]; then
    compwasi
else
    mkdir -p "out/"

    nim c \
    -o:out/npscript \
    src/npscript.nim
fi

#-d:prompt_no_completion \
#-d:prompt_no_word_editing \
#-d:prompt_no_preload_buffer \
