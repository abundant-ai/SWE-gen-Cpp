FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler (Clang) and CMake
# Use Clang because the deprecated warnings are specific to Clang
RUN apt-get update && apt-get install -y \
    cmake \
    clang \
    && rm -rf /var/lib/apt/lists/*

# Set Clang as the default compiler
ENV CC=clang
ENV CXX=clang++

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/google/googletest.git src && \
    cd src && \
    (git fetch --depth 1 origin f7098a2a4dc2e3233251c4f8e8001ee773cd5a61 || git fetch --depth 1 origin "+refs/pull/1545/head:refs/remotes/origin/pr/1545") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build Google Test/Mock with CMake
# Use CFI (Control Flow Integrity) to catch undefined behavior in constructor
RUN mkdir -p build && cd build && \
    cmake -Dgtest_build_samples=ON \
          -Dgtest_build_tests=ON \
          -Dgmock_build_tests=ON \
          -DCMAKE_CXX_FLAGS="-flto -fsanitize=cfi -fvisibility=hidden" \
          -DCMAKE_EXE_LINKER_FLAGS="-flto -fsanitize=cfi" \
          .. && \
    make -j4 gtest gtest_main

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (C++ is a compiled language)
# The buggy code with CRTP base classes will have UB caught by CFI
RUN cd build && make -j4 gtest gtest_main

RUN rm -rf /app/src/.git

WORKDIR /app/src
