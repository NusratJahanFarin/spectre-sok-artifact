#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

SRC="$ROOT/bench/src/common"
BIN="$ROOT/bench/binaries"
BINSEC="$ROOT/scripts/binsec"

SODIUM32="$SRC/libsodium32"
SODIUM64="$SRC/libsodium64"

CLANG=clang
GCC=gcc

CFLAGS32="-O0 -m32 -march=i386 -static -g -fno-stack-protector"
CFLAGS64="-O0 -m64 -static -g -fno-stack-protector -fno-pie -fno-pic"

mkdir -p "$BIN"


echo "[*] Checking dependencies..."

command -v "$CLANG" >/dev/null 2>&1 || {
    echo "[-] clang not found"
    exit 1
}

command -v "$GCC" >/dev/null 2>&1 || {
    echo "[-] gcc not found"
    exit 1
}

if [ ! -f "$SODIUM32/lib/libsodium.a" ]; then
    echo "[-] 32-bit libsodium not found:"
    echo "    $SODIUM32/lib/libsodium.a"
    exit 1
fi

if [ ! -f "$SODIUM64/lib/libsodium.a" ]; then
    echo "[-] 64-bit libsodium not found:"
    echo "    $SODIUM64/lib/libsodium.a"
    exit 1
fi

echo "[OK] Dependencies found"


echo "=== Building BINSEC/Haunted 32-bit binaries ==="

echo "[+] spectrev1_32"

$CLANG $CFLAGS32 \
    "$BINSEC/litmus-pht/programs/spectrev1.c" \
    -o "$BIN/spectrev1_32"

ln -sf "$BIN/spectrev1_32" \
    "$BINSEC/litmus-pht/programs/spectrev1"


echo "[+] spectrev4_32"

$GCC $CFLAGS32 -no-pie -fno-pic \
    "$BINSEC/litmus-stl/programs/spectrev4.c" \
    -o "$BIN/spectrev4_32"

ln -sf "$BIN/spectrev4_32" \
    "$BINSEC/litmus-stl/programs/spectrev4"


echo "[+] tea_32"

$CLANG $CFLAGS32 \
    "$BINSEC/tea/programs/tea_encrypt_wrapper.c" \
    -o "$BIN/tea_32"

ln -sf "$BIN/tea_32" \
    "$BINSEC/tea/programs/tea"


echo "[+] spectrev1_masking_32"

$GCC $CFLAGS32 \
    "$BINSEC/litmus-pht-masked/programs/spectrev1_masking.c" \
    -o "$BIN/spectrev1_masking_32"

ln -sf "$BIN/spectrev1_masking_32" \
    "$BINSEC/litmus-pht-masked/programs/spectrev1_masking"


for name in secretbox poly1305 sha512 ed25519 salsa streamxor
do
    echo "[+] ${name}_32"

    $CLANG $CFLAGS32 \
        -I"$SODIUM32/include" \
        "$BINSEC/$name/programs/"*.c \
        "$SODIUM32/lib/libsodium.a" \
        -lpthread \
        -o "$BIN/${name}_32"

    ln -sf "$BIN/${name}_32" \
        "$BINSEC/$name/programs/$name"
done

echo "[OK] 32-bit binaries built"


echo ""
echo "=== Building plain 64-bit binaries ==="

echo "[+] spectrev1"

$CLANG $CFLAGS64 \
    "$SRC/spectrev1.c" \
    -o "$BIN/spectrev1"


echo "[+] spectrev4"

$CLANG $CFLAGS64 \
    "$SRC/spectrev4.c" \
    -o "$BIN/spectrev4"


echo "[+] tea"

$CLANG $CFLAGS64 \
    "$SRC/tea_encrypt_wrapper.c" \
    -o "$BIN/tea"


for name in secretbox poly1305 salsa ed25519 sha512 streamxor
do
    echo "[+] $name"

    $CLANG $CFLAGS64 \
        -I"$SODIUM64/include" \
        "$SRC/$name.c" \
        "$SODIUM64/lib/libsodium.a" \
        -lpthread \
        -o "$BIN/$name"
done


echo "[+] spectrev1_masked"

$CLANG $CFLAGS64 \
    "$SRC/spectrev1_masked.c" \
    -o "$BIN/spectrev1_masked"

echo "[OK] 64-bit binaries built"

echo ""
echo "=== Build complete ==="
echo "Generated binaries:"
ls -lh "$BIN"
