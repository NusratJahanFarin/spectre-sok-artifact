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
# ============================================================
RUN git clone https://github.com/google/honggfuzz.git && \
    cd honggfuzz && \
    make && make install
# ============================================================
# Clone SpecFuzz
# ============================================================
RUN git clone https://github.com/OleksiiOleksenko/SpecFuzz.git /specfuzz
WORKDIR /specfuzz
# User builds SpecFuzz after container starts:
#   mkdir build && cd build
#   cmake .. -DLLVM_DIR=/usr/local/lib/cmake/llvm
#   make -j$(nproc)
CMD ["/bin/bash"]
