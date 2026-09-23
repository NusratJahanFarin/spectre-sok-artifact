#!/bin/bash
# Clones hw-sw-contracts/leakage-model-testing (LMTEST) and sets up a venv
# with its Python dependencies. Does NOT install the system toolchain
# (gcc/clang/gmp/cargo/jasminc) -- see README.md for that; those aren't
# pip-installable and mostly need version-pinned system packages.
# Safe to re-run: skips steps whose target already exists.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -d leakage-model-testing ]; then
    echo "[*] Cloning hw-sw-contracts/leakage-model-testing..."
    git clone https://github.com/hw-sw-contracts/leakage-model-testing
else
    echo "[=] leakage-model-testing already cloned, skipping."
fi

if [ ! -d venv ]; then
    echo "[*] Creating venv..."
    python3 -m venv venv
else
    echo "[=] venv already exists, skipping creation."
fi

# shellcheck disable=SC1091
source venv/bin/activate

echo "[*] Installing Python requirements..."
pip install -r leakage-model-testing/requirements.txt

echo "[✓] Python environment ready."
echo
echo "Still needed before running anything (see README.md for details):"
echo "  - gcc 11.4.0, clang 14.0.0-1ubuntu1.1, gmp 6.2.1, zstd, cargo 1.73.0-nightly"
echo "  - jasminc (Jasmin Compiler 2023.06.0) -- see the Jasmin wiki"
echo "  - then: cd leakage-model-testing/targets && ./build.sh"
