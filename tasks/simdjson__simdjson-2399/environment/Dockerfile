# Stage 1: Build the experimental LLVM compiler with C++26 reflection support
FROM ubuntu:24.04 AS builder

RUN apt-get update && apt-get install -y \
    git \
    cmake \
    ninja-build \
    build-essential \
    python3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone and build clang-p2996 (experimental reflection compiler)
RUN git clone --depth=1 --branch p2996 https://github.com/bloomberg/clang-p2996.git /tmp/clang-source && \
    cmake -S /tmp/clang-source/llvm -B /tmp/clang-source/build-llvm \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_ASSERTIONS=ON \
        -DLLVM_UNREACHABLE_OPTIMIZE=ON \
        -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
        -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
        -DLLVM_ENABLE_PROJECTS=clang \
        -G Ninja && \
    cmake --build /tmp/clang-source/build-llvm -j$(nproc) && \
    cmake --install /tmp/clang-source/build-llvm --prefix /tmp/clang-install

# Stage 2: Create the task environment
FROM ubuntu:24.04

# Base system packages
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    cmake \
    ninja-build \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Copy the experimental LLVM compiler from builder stage
COPY --from=builder /tmp/clang-install/ /usr/local/

# Configure library path for clang++
RUN P=$(/usr/local/bin/clang++ -v 2>&1 | grep Target | cut -d' ' -f2-) && \
    echo /usr/local/lib/$P > /etc/ld.so.conf.d/$P.conf && \
    ldconfig

# Use the experimental Clang as the C++ compiler
ENV CC=/usr/local/bin/clang
ENV CXX=/usr/local/bin/clang++

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/simdjson/simdjson.git src && \
    cd src && \
    (git fetch --depth 1 origin 67072be2872fec7ab889a75c32c112b5b16f3323 || git fetch --depth 1 origin "+refs/pull/2399/head:refs/remotes/origin/pr/2399") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure and build the project with CMake (with static reflection enabled)
RUN cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_STATIC_REFLECTION=ON -B build -G Ninja && \
    cmake --build build -j=2

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (required for C++ compiled language)
RUN cmake --build build -j=2

RUN rm -rf /app/src/.git

WORKDIR /app/src
