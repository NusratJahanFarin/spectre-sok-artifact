#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BC_DIR="$ARTIFACT_ROOT/bench/binaries/kleespectre"

KLEE_FLAGS="-check-div-zero=false -check-overshift=false --search=randomsp -enable-speculative -max-sew=200"

echo "=== salsa ==="
klee $KLEE_FLAGS "$BC_DIR/salsa_linked.bc"

echo "=== sha512 ==="
klee $KLEE_FLAGS "$BC_DIR/sha512_linked.bc"

echo "=== ed25519 ==="
klee $KLEE_FLAGS "$BC_DIR/ed25519_linked.bc"

echo "=== streamxor ==="
klee $KLEE_FLAGS "$BC_DIR/xor_linked.bc"

echo "=== secretbox ==="
klee $KLEE_FLAGS "$BC_DIR/secretbox_linked.bc"

echo "=== poly1305 ==="
klee $KLEE_FLAGS "$BC_DIR/poly1305_linked.bc"

echo "=== spectrev1 ==="
klee $KLEE_FLAGS "$BC_DIR/spectrev1.bc"

echo "=== tea ==="
klee $KLEE_FLAGS "$BC_DIR/tea.bc"

echo "=== Done. Check klee-out-N/messages.txt for 'Spectre found: N' ==="
