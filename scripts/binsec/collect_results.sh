#!/bin/bash
# Run this AFTER run_binsec.sh. Copies each module's results CSV into
# results/binsec/<module>.csv.
#
# Deliberately NOT done by redirecting each module's STAT_FILE in its own
# expes.py: that would mean editing 10 files with relative paths of
# varying depth, for no real benefit over collecting after the fact.
#
# The actual output location is NOT the same for every module -- checked
# directly against each module's expes.py (STAT_FILE = ...), it's a mix
# of a stats/ subdirectory and a bare CSV at the module root:
#
#   litmus-pht         stats/results.csv
#   litmus-stl         stats/results1.csv
#   litmus-pht-masked  stats/results.csv
#   tea                stats/results.csv
#   secretbox          results.csv
#   poly1305           results.csv
#   salsa              salsa.csv
#   sha512             sha512.csv
#   streamxor          streamxor.csv
#   ed25519            ed25519.csv
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_DIR="$ARTIFACT_ROOT/results/binsec"
mkdir -p "$RESULTS_DIR"

declare -A STAT_FILES=(
    ["litmus-pht"]="stats/results.csv"
    ["litmus-stl"]="stats/results1.csv"
    ["litmus-pht-masked"]="stats/results.csv"
    ["tea"]="stats/results.csv"
    ["secretbox"]="results.csv"
    ["poly1305"]="results.csv"
    ["salsa"]="salsa.csv"
    ["sha512"]="sha512.csv"
    ["streamxor"]="streamxor.csv"
    ["ed25519"]="ed25519.csv"
)

for module in "${!STAT_FILES[@]}"; do
    src="$SCRIPT_DIR/$module/${STAT_FILES[$module]}"
    dst="$RESULTS_DIR/$module.csv"
    if [ -f "$src" ]; then
        cp "$src" "$dst"
        echo "[+] $module -> $dst"
    else
        echo "[!] $module: expected output not found at $src (did run_binsec.sh run for it?)" >&2
    fi
done

echo
echo "[✓] Collected into $RESULTS_DIR"
