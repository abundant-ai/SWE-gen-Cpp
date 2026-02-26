FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ build tools, CMake, clang, clang-tidy, and LLVM FileCheck for assembly tests
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    clang \
    clang-tidy \
    llvm \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/FileCheck-18 /usr/bin/FileCheck

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/google/benchmark.git src && \
    cd src && \
    (git fetch --depth 1 origin fda4b5f73d0f2fbfbf76a31a8d1c7e2e0369e6d9 || git fetch --depth 1 origin "+refs/pull/1552/head:refs/remotes/origin/pr/1552") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure CMake build with GoogleTest dependencies and assembly tests (use clang for assembly tests)
RUN cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
    -DBENCHMARK_ENABLE_TESTING=ON \
    -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
    -DBENCHMARK_ENABLE_ASSEMBLY_TESTS=ON \
    -DBENCHMARK_ENABLE_WERROR=OFF \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Build the project and tests (limit parallelism to avoid OOM)
RUN cmake --build build --config Debug -j 1

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Clean and rebuild after applying bug.patch to ensure old binaries are removed
RUN rm -rf build && \
    cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
    -DBENCHMARK_ENABLE_TESTING=ON \
    -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
    -DBENCHMARK_ENABLE_ASSEMBLY_TESTS=ON \
    -DBENCHMARK_ENABLE_WERROR=OFF \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && \
    cmake --build build --config Debug -j 1

RUN rm -rf /app/src/.git

WORKDIR /app/src
