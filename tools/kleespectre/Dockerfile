FROM ubuntu:18.04
ARG DEBIAN_FRONTEND=noninteractive
# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential curl git cmake python python3 wget unzip \
    ca-certificates software-properties-common pkg-config \
    libboost-all-dev libgmp-dev libncurses5-dev libcap-dev \
    libgoogle-perftools-dev libsqlite3-dev doxygen bison flex \
    && rm -rf /var/lib/apt/lists/*
# Install LLVM / Clang 6.0
RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    add-apt-repository "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-6.0 main" && \
    apt-get update && apt-get install -y \
        clang-6.0 llvm-6.0 llvm-6.0-dev llvm-6.0-tools \
    && rm -rf /var/lib/apt/lists/*
# Create symlinks
RUN ln -s /usr/bin/clang-6.0 /usr/local/bin/clang && \
    ln -s /usr/bin/clang++-6.0 /usr/local/bin/clang++ && \
    ln -s /usr/bin/llvm-config-6.0 /usr/local/bin/llvm-config
# MiniSat (STP dependency)
WORKDIR /opt
RUN git clone https://github.com/stp/minisat.git && \
    cd minisat && mkdir build && cd build && \
    cmake .. && make -j$(nproc) && make install
# STP solver (stable tag 2.3.3, ABC & Python disabled)
WORKDIR /opt
RUN git clone https://github.com/stp/stp.git && \
    cd stp && \
    git checkout tags/2.3.3 && \
    git submodule update --init --recursive && \
    mkdir build && cd build && \
    cmake .. -DENABLE_PYTHON_INTERFACE=OFF -DENABLE_ABC=OFF && \
    make -j$(nproc) && make install
    
# klee-uclibc
WORKDIR /opt
RUN git clone https://github.com/klee/klee-uclibc.git && \
    cd klee-uclibc && \
    ./configure --make-llvm-lib && \
    make -j$(nproc)
# Clone KLEESpectre
WORKDIR /opt
RUN git clone https://github.com/winter2020/kleespectre.git
# Build KLEE
WORKDIR /opt/kleespectre/klee
RUN mkdir build
WORKDIR /opt/kleespectre/klee/build
RUN cmake \
    -DENABLE_SOLVER_STP=ON \
    -DENABLE_POSIX_RUNTIME=ON \
    -DENABLE_KLEE_UCLIBC=ON \
    -DKLEE_UCLIBC_PATH=/opt/klee-uclibc \
    -DLLVM_CONFIG_BINARY=/usr/local/bin/llvm-config \
    -DLLVMCC=/usr/local/bin/clang \
    -DLLVMCXX=/usr/local/bin/clang++ \
    -DENABLE_UNIT_TESTS=OFF \
    -DENABLE_SYSTEM_TESTS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    .. && \
    make -j$(nproc)
ENV PATH="/opt/kleespectre/klee/build/bin:${PATH}"
CMD ["/bin/bash"]
