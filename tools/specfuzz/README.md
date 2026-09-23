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

Building SpecFuzz itself (`make && make install && make install_tools`),
patching honggfuzz, and the `llvm-7.0.1-config` symlink are all baked
into this Dockerfile now, so the image is self-contained — no manual
setup step after `docker build` (unlike earlier versions of this
artifact, which needed the steps below run by hand every time).

## Run

Single command from the host, same pattern as KleeSpectre:

```bash
docker run --rm -it -v "$(pwd)/../..":/artifact -w /artifact specfuzz \
    ./scripts/run_specfuzz.sh
```

## Rebuilding the image / troubleshooting

If you need to rebuild SpecFuzz by hand inside a running container
(e.g. after changing something in `/specfuzz`), these are the exact
steps baked into the Dockerfile — run them from `docker run --rm -it
-v "$(pwd)/../.." :/artifact specfuzz bash`:

```bash
cd /specfuzz
export HONGG_SRC=/root/honggfuzz/src
make
make install          # installs clang-sf / clang-sf++ to /usr/bin
make install_tools     # installs analyzer to /usr/bin, patches + rebuilds
                        # honggfuzz in-place at $HONGG_SRC

# make install_tools rebuilds honggfuzz IN PLACE at $HONGG_SRC — it
# does not reinstall the binary to /usr/bin. Point PATH at it:
export PATH="/root/honggfuzz/src:$PATH"
which honggfuzz && honggfuzz --version   # sanity check it's the patched build

# scripts/run_specfuzz.sh calls `llvm-7.0.1-config`, but this
# Dockerfile's from-source LLVM install only produces `llvm-config`
# (no version suffix). Symlink it so the script finds it:
ln -sf /usr/local/bin/llvm-config /usr/local/bin/llvm-7.0.1-config

# sanity checks
clang-sf --version
analyzer --help
llvm-7.0.1-config --version
```
