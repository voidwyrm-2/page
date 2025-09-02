#nim c \
#    --cc:clang \
#    --clang.exe:"emcc" \
#    --clang.linkerexe:"emcc" \
#    --passC:"-static" \
#    --passL:"-static" \
#    --os:linux \
#    --cpu:wasm32 \
#    --forceBuild:on \
#    --opt:speed \
#    --o:npscript_exe \
#    src/npscript.nim

# -D_WASI_EMULATED_SIGNAL -lwasi-emulated-signal
# -D_WASI_EMULATED_SIGNAL -lwasi-emulated-signal

# zcomp(os, arch, llvmTriple)
zcomp() {
    ext=""

    if [ "$1" = "windows" ]; then
        ext=".exe"
    fi
    
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
        -o:"out/$1-$2/npscript$ext" \
        src/npscript.nim
}

if [ "$1" = "all" ]; then
    zcomp "macosx" "arm64" "aarch64-macos"
    zcomp "linux" "arm64" "aarch64-linux"
    zcomp "linux" "amd64" "x86_64-linux"
    zcomp "windows" "amd64" "x86_64-windows"
else
    mkdir -p "out/"

    nim c \
    -o:out/npscript \
    src/npscript.nim
fi

#-d:prompt_no_completion \
#-d:prompt_no_word_editing \
#-d:prompt_no_preload_buffer \
