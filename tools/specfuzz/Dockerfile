# ============================================================
# This Dockerfile mirrors the exact, proven install recipe from
# the Teapot paper's published artifact (Lin, Wang, Sasaki, CGO
# 2025 -- https://doi.org/10.5281/zenodo.14507732), which builds
# SpecFuzz as a baseline comparison. It replaces an earlier
# hand-rolled reimplementation that hit several real compatibility
# bugs (honggfuzz's linux/bfd.c failing to compile against Ubuntu
# 18.04's binutils, LLVM/clang directory-layout mismatches with
# SpecFuzz's own Makefile). The key fix: install/honggfuzz.sh pins
# an exact old commit (589a9fb92) rather than today's master --
# that commit predates the newer honggfuzz code that caused the
# bfd.c errors, so no source patching is needed at all here.
# ============================================================
FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    libbfd-dev libunwind8-dev binutils-dev libblocksruntime-dev git \
    wget curl gcc g++ cmake make \
    xz-utils build-essential gdb vim \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# LLVM 7.0.1 + Clang + compiler-rt, and HonggFuzz (pinned commit)
# -- installed via SpecFuzz's own scripts, not reimplemented.
# install/llvm.sh creates /usr/bin/llvm-7.0.1-config and symlinks
# clang/clang++ onto PATH itself; no manual symlinking needed here.
# ============================================================
COPY ./install /tmp/install
RUN INSTALL_DIR=/llvm /tmp/install/llvm.sh
RUN INSTALL_DIR=/honggfuzz /tmp/install/honggfuzz.sh

# install/honggfuzz.sh clones into .../honggfuzz-<commit>/src/ --
# flatten that up so HONGG_SRC below (used by SpecFuzz's own
# Makefile) points at a directly-usable honggfuzz source tree.
RUN cp -r /honggfuzz/honggfuzz-*/src/* /honggfuzz

# ============================================================
# SpecFuzz itself
# ============================================================
RUN git clone https://github.com/OleksiiOleksenko/SpecFuzz.git /specfuzz

ENV HONGG_SRC=/honggfuzz
WORKDIR /specfuzz
RUN make -j8
RUN make install && make install_tools

ENV SF_CFLAGS="--enable-coverage -DNDEBUG -L/honggfuzz/libhfuzz -L/honggfuzz/libhfcommon -lhfuzz -lhfcommon"

# Sanity checks -- fail the build here rather than at `docker run` time:
RUN clang-sf --version && analyzer --help && llvm-7.0.1-config --version && honggfuzz --version

WORKDIR /artifact
CMD ["/bin/bash"]
