#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


SRC="$SCRIPT_DIR"
COMMON_SRC="${COMMON_SRC:-$SCRIPT_DIR}"
BIN="${BIN:-$SCRIPT_DIR/bin}"

SODIUM_ROOT="${SODIUM_ROOT:-$SCRIPT_DIR/libsodium-1.0.18}"
SODIUM_INC="$SODIUM_ROOT/src/libsodium/include"
SODIUM_LIB="$SODIUM_ROOT/src/libsodium/.libs/libsodium.a"


KLEE_INC="${KLEE_INC:-$SCRIPT_DIR/../../klee/include}"

CLANG=clang-6.0
LLVM_LINK=llvm-link-6.0

OBJ="$BIN/obj"      
mkdir -p "$BIN" "$OBJ"

for tool in "$CLANG" "$LLVM_LINK"; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "[-] $tool not found (KleeSpectre needs the LLVM 6.0 toolchain)"
        exit 1
    }
done

if [ ! -f "$KLEE_INC/klee/klee.h" ]; then
    echo "[!] klee/klee.h not found under $KLEE_INC" >&2
    echo "    set KLEE_INC=/path/to/klee/include and re-run" >&2
    exit 1
fi

VERSION_HEADER="$SODIUM_INC/sodium/version.h"

if [ ! -d "$SODIUM_ROOT/src/libsodium" ] || [ ! -f "$VERSION_HEADER" ]; then
    echo "[!] libsodium source not found at $SODIUM_ROOT" >&2
    echo "    clone it there first:" >&2
    echo "        git clone --branch 1.0.18 https://github.com/jedisct1/libsodium $SODIUM_ROOT" >&2
    exit 1
fi

if ! grep -q 'SODIUM_VERSION_STRING "1.0.18"' "$VERSION_HEADER"; then
    FOUND_VERSION="$(grep -o 'SODIUM_VERSION_STRING "[^"]*"' "$VERSION_HEADER" || echo "unknown")"
    echo "[!] $SODIUM_ROOT is not libsodium 1.0.18 (found: $FOUND_VERSION)" >&2
    echo "    this build script's per-file dependency lists were traced" >&2
    echo "    against 1.0.18 specifically -- a different version may not" >&2
    echo "    have the same file layout/dispatch pattern" >&2
    exit 1
fi

TARGETS=(
    "spectrev1:$COMMON_SRC/spectrev1.c"
    "poly1305:$SRC/poly1305_wrapper.c"
    "secretbox:$SRC/secretbox_wrapper.c"
    "tea:$SRC/tea_encrypt_wrapper.c"
)

echo "=== Part 1: single-file KleeSpectre bitcode ==="
for entry in "${TARGETS[@]}"; do
    name="${entry%%:*}"
    src="${entry#*:}"
    echo "[+] $name.bc  <-  $src"
    $CLANG -emit-llvm -g -c -I"$SODIUM_INC" -I"$SODIUM_INC/sodium" -I"$KLEE_INC" "$src" -o "$BIN/$name.bc"
done

declare -A SODIUM_DEPS
declare -A DRIVER_SRC
SODIUM_DEPS[sha512]="
    crypto_hash/sha512/cp/hash_sha512_cp.c
"
SODIUM_DEPS[ed25519]="
    crypto_sign/ed25519/ref10/sign.c
    crypto_sign/crypto_sign.c
"
SODIUM_DEPS[salsa]="
    crypto_stream/salsa20/stream_salsa20.c
    crypto_stream/salsa20/ref/salsa20_ref.c
    crypto_core/salsa/ref/core_salsa_ref.c
"
SODIUM_DEPS[xor]="
    crypto_stream/crypto_stream.c
    crypto_stream/xsalsa20/stream_xsalsa20.c
    crypto_stream/salsa20/stream_salsa20.c
    crypto_stream/salsa20/ref/salsa20_ref.c
    crypto_core/salsa/ref/core_salsa_ref.c
    crypto_core/hsalsa20/core_hsalsa20.c
    crypto_core/hsalsa20/ref2/core_hsalsa20_ref2.c
"

DRIVER_SRC[sha512]="$COMMON_SRC/sha512.c"
DRIVER_SRC[ed25519]="$COMMON_SRC/ed25519.c"
DRIVER_SRC[salsa]="$COMMON_SRC/salsa.c"
DRIVER_SRC[xor]="$COMMON_SRC/streamxor.c"

for name in sha512 ed25519 salsa xor; do
    echo ""
    echo "[+] ${name}_linked.bc"
    driver_bc="$OBJ/${name}_driver.bc"
    $CLANG -emit-llvm -g -c -I"$SODIUM_INC" -I"$SODIUM_INC/sodium" -I"$KLEE_INC" "${DRIVER_SRC[$name]}" -o "$driver_bc"

    dep_bcs=("$driver_bc")
    for relsrc in ${SODIUM_DEPS[$name]}; do
        cfile="$SODIUM_ROOT/src/libsodium/$relsrc"
        [ -f "$cfile" ] || { echo "[-] missing $cfile"; exit 1; }
        flat="$(echo "$relsrc" | sed 's/\//__/g; s/\.c$/.bc/')"
        outbc="$OBJ/sodium__$flat"
        echo "    <- $relsrc"
        $CLANG -emit-llvm -g -c -I"$SODIUM_INC" -I"$SODIUM_INC/sodium" -I"$KLEE_INC" "$cfile" -o "$outbc"
        dep_bcs+=("$outbc")
    done

    $LLVM_LINK "${dep_bcs[@]}" -o "$BIN/${name}_linked.bc"
done

echo ""
echo "KleeSpectre bitcode built successfully."
