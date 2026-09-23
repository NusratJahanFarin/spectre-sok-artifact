#!/bin/bash
# sync_sources.sh — run from the artifact/ root.
#
# bench/src/{KleeSpectre,SpecFuzz,common}/ are the three canonical source
# variants. KleeSpectre and SpecFuzz's own build scripts read straight from
# bench/src/KleeSpectre/ and bench/src/SpecFuzz/ - nothing to symlink there.
#
# BINSEC still keeps its own per-module programs/ copies under scripts/binsec/
# (because expes.py's Executable class looks for the binary/source relative
# to that module's own directory), so those are what get replaced with
# symlinks back to bench/src/common/.
#
# Safe to re-run: skips a target if it's already a symlink.

set -e

ROOTDIR="$(pwd)"
COMMON="$ROOTDIR/bench/src/common"
BINSEC="$ROOTDIR/scripts/binsec"

link_source () {
    local name="$1"
    local target="$2"
    local canonical="$COMMON/$name"

    if [ ! -f "$canonical" ]; then
        echo "[!] $canonical does not exist — skipping $target"
        return
    fi

    if [ -L "$target" ]; then
        echo "[=] $target already a symlink, leaving as-is"
        return
    fi

    if [ -f "$target" ]; then
        echo "[*] Replacing $target with a symlink to bench/src/common/$name"
        rm -f "$target"
    else
        mkdir -p "$(dirname "$target")"
    fi

    ln -s "$canonical" "$target"
    echo "[+] $target -> $canonical"
}

link_source "ed25519.c"            "$BINSEC/ed25519/programs/ed25519.c"
link_source "spectrev1.c"          "$BINSEC/litmus-pht/programs/spectrev1.c"
link_source "spectrev1_masked.c"   "$BINSEC/litmus-pht-masked/programs/spectrev1_masking.c"
link_source "spectrev4.c"          "$BINSEC/litmus-stl/programs/spectrev4.c"
link_source "poly1305.c"           "$BINSEC/poly1305/programs/poly1305.c"
link_source "salsa.c"              "$BINSEC/salsa/programs/salsa.c"
link_source "secretbox.c"          "$BINSEC/secretbox/programs/secretbox.c"
link_source "sha512.c"             "$BINSEC/sha512/programs/sha512.c"
link_source "streamxor.c"          "$BINSEC/streamxor/programs/streamxor.c"
link_source "tea.c"                "$BINSEC/tea/programs/tea.c"
link_source "tea_encrypt_wrapper.c" "$BINSEC/tea/programs/tea_encrypt_wrapper.c"
link_source "tea_decrypt_wrapper.c" "$BINSEC/tea/programs/tea_decrypt_wrapper.c"

echo
echo "[✓] Sync complete."
echo "    Edit bench/src/common/<name>.c — binsec picks it up automatically via symlink."
echo "    Edit bench/src/KleeSpectre/<name>.c and bench/src/SpecFuzz/<name>.c directly"
echo "    (those tools' build scripts already read from bench/src/ - no symlink needed)."
