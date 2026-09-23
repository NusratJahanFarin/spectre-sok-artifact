# SpecFuzz

Fuzzing-based Spectre-v1 detector (OleksiiOleksenko/SpecFuzz, built on a
patched LLVM 7.0.1 + honggfuzz). No longer maintained upstream, which is
why this artifact pins an exact Docker build rather than "clone latest".

Upstream: https://github.com/OleksiiOleksenko/SpecFuzz

## Build the image

```bash
cd tools/specfuzz
docker build -t specfuzz .
```

## One-time setup inside the container

Run this once per container (or bake it into the image as extra
`RUN`/`ENV` lines if you want a fully self-contained image):

```bash
docker run --rm -it -v "$(pwd)/../..":/artifact specfuzz bash
```

```bash
# 1. Build + install SpecFuzz itself (per upstream README)
cd /specfuzz
export HONGG_SRC=/root/honggfuzz/src
make
make install          # installs clang-sf / clang-sf++ to /usr/bin
make install_tools     # installs analyzer to /usr/bin, patches + rebuilds
                        # honggfuzz in-place at $HONGG_SRC

# 2. make install_tools rebuilds honggfuzz IN PLACE at $HONGG_SRC — it
# does not reinstall the binary to /usr/bin. Point PATH at it (or symlink):
export PATH="/root/honggfuzz:$PATH"
# or: ln -sf /root/honggfuzz/honggfuzz /usr/local/bin/honggfuzz
which honggfuzz && honggfuzz --version   # sanity check it's the patched build

# 3. scripts/run_specfuzz.sh calls `llvm-7.0.1-config`, but this
# Dockerfile's from-source LLVM install only produces `llvm-config`
# (no version suffix). Symlink it so the script finds it:
ln -sf /usr/local/bin/llvm-config /usr/local/bin/llvm-7.0.1-config

clang-sf --version
analyzer --help
llvm-7.0.1-config --version
```

## Run

From inside the container, from the artifact root:

```bash
cd /artifact
./scripts/run_specfuzz.sh
```
