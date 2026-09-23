# ============================================================
# Base system
# ============================================================
FROM ubuntu:18.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    wget \
    curl \
    xz-utils \
    cmake \
    ninja-build \
    python3 \
    binutils-dev \
    libunwind-dev \
    libblocksruntime-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /root
# ============================================================
# Install LLVM 7.0.1 + Clang 7.0.1 from source
# ============================================================
RUN mkdir /root/llvm-src && cd /root/llvm-src && \
    wget http://releases.llvm.org/7.0.1/llvm-7.0.1.src.tar.xz && \
    wget http://releases.llvm.org/7.0.1/cfe-7.0.1.src.tar.xz && \
    wget http://releases.llvm.org/7.0.1/compiler-rt-7.0.1.src.tar.xz && \
    \
    tar -xf llvm-7.0.1.src.tar.xz && \
    tar -xf cfe-7.0.1.src.tar.xz && \
    tar -xf compiler-rt-7.0.1.src.tar.xz && \
    \
    mv cfe-7.0.1.src llvm-7.0.1.src/tools/clang && \
    mv compiler-rt-7.0.1.src llvm-7.0.1.src/projects/compiler-rt && \
    \
    mkdir llvm-7.0.1.src/build && cd llvm-7.0.1.src/build && \
    cmake -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DLLVM_TARGETS_TO_BUILD="host" \
        -DLLVM_ENABLE_RTTI=ON \
        .. && \
    ninja && \
    ninja install
# Add LLVM to PATH
ENV PATH="/usr/local/bin:${PATH}"
RUN llvm-config --version && clang --version
# ============================================================
# Install honggfuzz
#
# Cloned into a `src/` subdirectory specifically -- SpecFuzz's own
# Makefile (install_tools -> patch_hongg) copies patched files into
# $(HONGG_SRC)/libhfuzz/..., $(HONGG_SRC)/linux/..., etc., and its
# own docs use HONGG_SRC=.../src/ for exactly this reason. Cloning
# straight to /root/honggfuzz (repo root, no src/ subfolder) would
# make HONGG_SRC point at a path that doesn't contain those files.
# ============================================================
RUN git clone https://github.com/google/honggfuzz.git /root/honggfuzz/src && \
    cd /root/honggfuzz/src && \
    make && make install
# ============================================================
# Clone SpecFuzz
# ============================================================
RUN git clone https://github.com/OleksiiOleksenko/SpecFuzz.git /specfuzz
WORKDIR /specfuzz
# ============================================================
# Build + install SpecFuzz itself, baked into the image so no
# manual setup is needed after `docker run` (matches the
# "One-time setup inside the container" steps documented in
# tools/specfuzz/README.md -- kept here as the source of truth
# for what a fresh container needs).
# ============================================================
ENV HONGG_SRC=/root/honggfuzz/src
RUN make && \
    make install && \
    make install_tools
# make install_tools patches + rebuilds honggfuzz IN PLACE at
# $HONGG_SRC rather than reinstalling the binary elsewhere -- the
# patched build (not whatever `make install` above put on PATH) is
# the one SpecFuzz's fuzzing loop actually needs, so put it first:
ENV PATH="/root/honggfuzz/src:${PATH}"
RUN which honggfuzz && honggfuzz --version
# scripts/run_specfuzz.sh calls `llvm-7.0.1-config`, but this
# from-source LLVM install only produces unsuffixed `llvm-config`:
RUN ln -sf /usr/local/bin/llvm-config /usr/local/bin/llvm-7.0.1-config
# Sanity checks -- fail the build here rather than at `docker run` time
# if any of the above didn't actually work:
RUN clang-sf --version && analyzer --help && llvm-7.0.1-config --version
WORKDIR /artifact
CMD ["/bin/bash"]
