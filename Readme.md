# SoK:Evaluation of Automated Detection Tools for Speculative Constant-Time Vulnerabilities Artifact

This repository benchmarks five Spectre detection tools —
**SpecFuzz**, **KleeSpectre**, **BinSec/Haunted**, **Pitchfork**, and
**LMTest** — against a shared suite of binaries covering Spectre v1
(PHT) and Spectre v4 (STL) gadgets, a compiler/optimization-level
sweep, and constant-time crypto primitives (libsodium's secretbox,
poly1305, salsa, ed25519, sha512, streamxor) and tea.

Each tool is run independently through its own script, and every run's
raw output is collected under `results/`, one subfolder per tool, so
the numbers in the paper can be reproduced or re-checked directly
against the files in this repo.

## Repository layout

```
.
├── bench/                benchmark sources and compiled binaries
│   ├── src/              canonical .c sources (common/, plus per-tool
│   │                     variants for SpecFuzz and KleeSpectre)
│   └── binaries/         compiled targets: spectrev1/v4 (+ masked,
│                         compiler x -O0 sweep), crypto primitives, tea
|
├── tools/                one subdirectory per detector: README with
│   │                     setup/run steps, and a Dockerfile or setup.sh
│   │                     where applicable. Tool binaries/images are
│   │                     NOT vendored here — see tools/README.md
│   ├── specfuzz/
│   ├── kleespectre/
│   ├── binsec/
│   ├── pitchfork/
│   └── lmtest/
├── scripts/              one run_<tool> script per tool, plus
│   │                     scripts/binsec/ (per-module Binsec/Haunted drivers)
│   ├── run_specfuzz.sh
│   ├── run_kleespectre.sh
│   ├── run_pitchfork.py
│   ├── run_lmtest.sh
│   └── binsec/
├── results/              raw output per tool
│   ├── specfuzz/
│   ├── kleespectre/
│   ├── binsec/
│   ├── pitchfork/
│   └── lmtest/
└── sync_sources.sh       symlinks bench/src/common/*.c into binsec's
                          per-module scripts/binsec/*/programs/ dirs
```

## Tools benchmarked

| Tool | Technique | Obtained via | Docs |
|------|-----------|--------------|------|
| SpecFuzz | Fuzzing (honggfuzz) | Docker, build locally | (tools/specfuzz/README.md) |
| KleeSpectre | Symbolic execution | Docker, build locally | (tools/kleespectre/README.md) |
| Binsec/Haunted | Relational symbolic execution | Prebuilt Docker images | (tools/binsec/README.md) |
| Pitchfork | Symbolic execution | pypy3 virtualenv | (tools/pitchfork/README.md) |
| LMTest | Leakage-model testing (LMSPEC) | Python virtualenv | (tools/lmtest/README.md) |

## Requirements

- **Docker** (SpecFuzz, KleeSpectre, Binsec/Haunted)
- **Python 3** + **pypy3** on `PATH` (Pitchfork, LMTest)

## Quickstart

```bash
# 0. From the artifact root, wire the shared benchmark sources into
#    Binsec's per-module directories (safe to re-run).
./sync_sources.sh

# 1. Build/set up each tool — see the per-tool README linked above
#    for details. In short:
cd tools/specfuzz    && docker build -t specfuzz .        && cd ../..
cd tools/kleespectre && docker build -t kleespectre .      && cd ../..
cd tools/binsec      && ./download.sh && docker load -i binsec-haunted.tar && cd ../..
cd tools/pitchfork   && ./setup.sh                          && cd ../..
cd tools/lmtest      && ./setup.sh                          && cd ../..
```

**2. Run each tool.** The three Docker-based tools do NOT run their
scripts from your normal host shell — `run_specfuzz.sh` /
`run_kleespectre.sh` / `run_binsec.sh` only work from *inside* the
container's own shell, since that's the only place the tool binary
(`klee`, SpecFuzz's `clang-sf`, BinSec) actually exists. Running them
directly on the host (e.g. `./scripts/run_kleespectre.sh` typed into
your normal terminal) will fail with `command not found` — that is
not a bug, it means you're in the wrong shell. Each command below
gets you into the right one first:

```bash
# --- SpecFuzz (Docker) ---
docker run --rm -it -v "$(pwd)":/artifact specfuzz bash
#   ^ now inside the container. Build+install SpecFuzz itself once
#   per tools/specfuzz/README.md, then, still inside the container:
/artifact/scripts/run_specfuzz.sh

# --- KleeSpectre (Docker) ---
# This one is a single command from the HOST -- no manual shell needed:
docker run --rm -it -v "$(pwd)":/artifact -w /artifact kleespectre \
    ./scripts/run_kleespectre.sh

# --- BinSec/Haunted (Docker) ---
docker run --rm -it -v "$(pwd)":/artifact -w /artifact/scripts/binsec \
    <image-name-from-docker-images> bash
#   ^ now inside the container, in scripts/binsec/:
./run_binsec.sh
exit
# back on the host:
./scripts/binsec/collect_results.sh

# --- Pitchfork (host, pypy3 venv -- NOT Docker) ---
source tools/pitchfork/pitchfork/venv/bin/activate
PYTHONPATH=tools/pitchfork/pitchfork pypy3 scripts/run_pitchfork.py --auto

# --- LMTest (host, python venv -- NOT Docker, NOT run from artifact root) ---
cd tools/lmtest/leakage-model-testing
source ../venv/bin/activate
../../../scripts/run_lmtest.sh
cd ../../..
```

See each `tools/<name>/README.md` for full detail — the above is the
exact, tested invocation for each tool, not a simplified version.
