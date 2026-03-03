FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python3 for build scripts
RUN apt-get update && apt-get install -y \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install C++ build tools, CMake, ninja, and GoogleTest dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    clang \
    clang-tidy \
    && rm -rf /var/lib/apt/lists/*

# Install locale support for locale_impermeability_test
RUN apt-get update && apt-get install -y \
    locales \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/google/benchmark.git src && \
    cd src && \
    (git fetch --depth 1 origin d17786a07f3ac9da3e6acae64237472249291d35 || git fetch --depth 1 origin "+refs/pull/1809/head:refs/remotes/origin/pr/1809") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Fix missing include in benchmark_register.h
RUN sed -i '4i#include <limits>' src/benchmark_register.h

# Fix GoogleTest download (use release-1.12.1 which is compatible with C++11)
RUN sed -i 's/GIT_TAG           master/GIT_TAG           "release-1.12.1"/' cmake/GoogleTest.cmake.in

# Configure CMake build with GoogleTest dependencies
RUN cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=14 \
    -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
    -DBENCHMARK_ENABLE_TESTING=ON \
    -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
    -DBENCHMARK_ENABLE_WERROR=OFF \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Build the project and tests (limit parallelism to avoid OOM)
RUN cmake --build build --config Debug -j 1

# Reset tracked files so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Fix missing include in benchmark_register.h (after patch)
RUN sed -i '4i#include <limits>' src/benchmark_register.h

# Fix GoogleTest download again after patch (in case patch affected it)
RUN sed -i 's/GIT_TAG           master/GIT_TAG           "release-1.12.1"/' cmake/GoogleTest.cmake.in

# Clean and rebuild after applying bug.patch to ensure old binaries are removed
RUN rm -rf build && \
    cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=14 \
    -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
    -DBENCHMARK_ENABLE_TESTING=ON \
    -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
    -DBENCHMARK_ENABLE_WERROR=OFF \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && \
    cmake --build build --config Debug -j 1

RUN rm -rf /app/src/.git

WORKDIR /app/src
