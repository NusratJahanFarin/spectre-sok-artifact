#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RUN_TIME=3600
THREADS=1
CCSF="clang-sf"

if [ -z "$HONGG_SRC" ]; then
    echo "[!] HONGG_SRC is not set. Run: export HONGG_SRC=/path/to/honggfuzz/src" >&2
    exit 1
fi

HONGGFUZZ_LDFLAGS="-L${HONGG_SRC}/libhfuzz -L${HONGG_SRC}/libhfcommon -lhfuzz -lhfcommon"
LLVM_SYMBOLIZER=$(llvm-7.0.1-config --bindir)/llvm-symbolizer
SPECFUZZ_LIBDIR=$(llvm-7.0.1-config --libdir)

declare -A SEED_SIZES=(
    ["secretbox"]=80
    ["poly1305"]=64
    ["salsa"]=104
    ["streamxor"]=179
    ["sha512"]=200
    ["ed25519"]=96
)

# =========================
# Source: bench/src/SpecFuzz/<bench>.c (flat, one canonical copy per bench)
# =========================
SRC_ROOT="$ARTIFACT_ROOT/bench/src/SpecFuzz"

SODIUM_ROOT="$ARTIFACT_ROOT/tools/libsodium-1.0.18"
SODIUM_INC="$SODIUM_ROOT/src/libsodium/include"
SODIUM_LIB="$SODIUM_ROOT/src/libsodium/.libs/libsodium.a"

if [ ! -d "$SODIUM_ROOT" ]; then
    echo "[!] libsodium source not found at $SODIUM_ROOT" >&2
    echo "    SpecFuzz needs to rebuild libsodium itself with clang-sf -" >&2
    echo "    it can't reuse the prebuilt .a from binsec/secretbox/libsodium/." >&2
    echo "    Clone it there first: git clone --branch 1.0.18 \\" >&2
    echo "        https://github.com/jedisct1/libsodium $SODIUM_ROOT" >&2
    exit 1
fi


WORK_DIR="$ARTIFACT_ROOT/results/specfuzz/"
mkdir -p "$WORK_DIR"
FUNCTION_LIST="$WORK_DIR/function_list.txt"

# =========================
# Benchmarks to run
# =========================
BENCHMARKS=("sha512" "secretbox" "poly1305" "salsa" "streamxor" "ed25519" "spectrev1" "spectrev1_masked")

SKIP_COLLECT=0

# =========================
# Helper: which canonical source file backs a given benchmark
# =========================
src_file_for() {
    local bench="$1"
    if [ -f "$SRC_ROOT/$bench.c" ]; then
        echo "$SRC_ROOT/$bench.c"
    else
        echo ""
    fi
}

# =========================
# Phase 1: COLLECT
# =========================
if [ "$SKIP_COLLECT" != "1" ]; then
    echo "=============================="
    echo "[*] Phase 1: Collect"
    echo "=============================="

    rm -f "$FUNCTION_LIST"
    touch "$FUNCTION_LIST"

    echo "[*] Collecting libsodium (this rebuilds the whole library, serially --"
    echo "    parallel collect builds corrupt function_list.txt via concurrent"
    echo "    writes from multiple llc processes)."

    cd "$SODIUM_ROOT"
    find . -name "*.o" -delete
    find . -name "*.lo" -delete
    find . -name "*.la" -delete
    rm -rf .libs src/libsodium/.libs
    make distclean >/dev/null 2>&1 || true

    CC="$CCSF" CFLAGS="-O0 -ggdb --collect $FUNCTION_LIST -DNDEBUG" \
        ./configure --disable-shared --disable-ssse3 --disable-avx2 \
                    --disable-avx512f --disable-sse2 --disable-sse3 >/dev/null
    make -j1
    cd "$ARTIFACT_ROOT"

    echo "[*] libsodium collect done. function_list.txt: $(wc -l < "$FUNCTION_LIST") lines"

    echo "[*] Collecting each harness file (this is the step that was missing --"
    echo "    without it, the harness's own call sites into libsodium are treated"
    echo "    as calls to external, non-instrumented functions)."

    for bench in "${BENCHMARKS[@]}"; do
        SRC=$(src_file_for "$bench")
        if [ -z "$SRC" ]; then
            echo "[!] No source file found for $bench at $SRC_ROOT/$bench.c, skipping collect."
            continue
        fi
        echo "    - $SRC"
        "$CCSF" -O0 -ggdb --collect "$FUNCTION_LIST" -DNDEBUG \
            -I"$SODIUM_INC" -c "$SRC" -o /tmp/collect_discard_$bench.o
        rm -f /tmp/collect_discard_$bench.o
    done

    sort -u "$FUNCTION_LIST" -o "$FUNCTION_LIST"
    echo "[*] Collect phase complete. function_list.txt: $(wc -l < "$FUNCTION_LIST") lines"
else
    echo "[*] SKIP_COLLECT=1 -- reusing existing function_list.txt ($(wc -l < "$FUNCTION_LIST") lines)"
fi

# ============================================================================
# Phase 2: INSTRUMENT (rebuild libsodium against the completed function list)
# ============================================================================
echo "=============================="
echo "[*] Phase 2: Instrument (rebuild libsodium)"
echo "=============================="

cd "$SODIUM_ROOT"
find . -name "*.o" -delete
find . -name "*.lo" -delete
find . -name "*.la" -delete
rm -rf .libs src/libsodium/.libs
make distclean >/dev/null 2>&1 || true

CC="$CCSF" CFLAGS="-O0 -ggdb --function-list $FUNCTION_LIST --enable-coverage -DNDEBUG" \
    ./configure --disable-shared --disable-ssse3 --disable-avx2 \
                --disable-avx512f --disable-sse2 --disable-sse3 >/dev/null
make -j"$(nproc)"
cd "$ARTIFACT_ROOT"

CHKP_COUNT=$(nm "$SODIUM_LIB" 2>/dev/null | grep -c "specfuzz_chkp" || true)
if [ "$CHKP_COUNT" -eq 0 ]; then
    echo "[!] libsodium.a has zero specfuzz_chkp references after the instrument" >&2
    echo "    build. Something is wrong -- do not proceed to fuzzing." >&2
    exit 1
fi
echo "[*] libsodium instrumented OK (specfuzz_chkp referenced)."
ls -la "$SODIUM_LIB"

# ====================================
# Phase 3: build + fuzz each benchmark
# ====================================
SUMMARY_CSV="$WORK_DIR/summary.csv"
echo "binary,total_faults,total_branches" > "$SUMMARY_CSV"

for bench in "${BENCHMARKS[@]}"; do
    echo "=============================="
    echo "[*] Processing $bench"
    echo "=============================="

    SRC=$(src_file_for "$bench")
    if [ -z "$SRC" ]; then
        echo "[!] No source file found for $bench, skipping."
        continue
    fi

    BENCH_WORK="$WORK_DIR/$bench"
    rm -rf "$BENCH_WORK"
    mkdir -p "$BENCH_WORK/inputs"
    cd "$BENCH_WORK"

    SEED_SIZE=${SEED_SIZES[$bench]:-64}
    head -c "$SEED_SIZE" /dev/zero > "inputs/seed"
    echo "[*] Seed size for $bench: $SEED_SIZE bytes"


    echo "[*] Compiling $bench with SpecFuzz..."
    SF_CFLAGS="-fsanitize=address -O0 -ggdb --function-list $FUNCTION_LIST --enable-coverage"

    "$CCSF" $SF_CFLAGS -I"$SODIUM_INC" -c "$SRC" -o bench.sf.o
    "$CCSF" $SF_CFLAGS -L"$SPECFUZZ_LIBDIR" bench.sf.o "$SODIUM_LIB" -lpthread \
        $HONGGFUZZ_LDFLAGS -o fuzz

    if [ "$(nm fuzz 2>/dev/null | grep -c specfuzz_chkp)" -eq 0 ]; then
        echo "[!] $bench: fuzz binary has zero specfuzz_chkp references. Skipping." >&2
        cd "$ARTIFACT_ROOT"
        continue
    fi

# -------------------------
# Fuzz + collect
# -------------------------
    echo "[*] Fuzzing $bench..."
    honggfuzz \
        --run_time "$RUN_TIME" \
        -Q \
        -n "$THREADS" \
        -f "inputs" \
        -l fuzzing.log \
        -- ./fuzz ___FILE___ 2>&1 | \
    analyzer collect \
        -r fuzzing.log \
        -o results.json \
        -b ./fuzz

# -------------------------
# Aggregate
# -------------------------
    analyzer aggregate results.json \
        -s "$LLVM_SYMBOLIZER" \
        -b ./fuzz \
        -o aggregated.json

# -------------------------
# CSV summary
# -------------------------
    FAULTS=$(jq '.faults | length' aggregated.json)
    BRANCHES=$(jq '.branches | length' aggregated.json)
    echo "$bench,$FAULTS,$BRANCHES" >> "$SUMMARY_CSV"
    echo "[*] $bench -> faults=$FAULTS branches=$BRANCHES"

    cd "$ARTIFACT_ROOT"
done

echo "=============================="
echo "[*] Done"
echo "[*] Summary:"
cat "$SUMMARY_CSV"
