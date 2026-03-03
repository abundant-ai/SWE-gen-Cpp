FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python3 for build scripts and create python symlink
RUN apt-get update && apt-get install -y \
    python3 \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/python3 /usr/bin/python

# Install C++ build tools, CMake, ninja, LLVM FileCheck for assembly tests
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    clang \
    clang-tidy \
    llvm \
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
    (git fetch --depth 1 origin 250d0a335062296434590e1166047459c5705011 || git fetch --depth 1 origin "+refs/pull/548/head:refs/remotes/origin/pr/548") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Fix missing #include <limits> in benchmark_register.h (if it exists)
RUN if [ -f src/benchmark_register.h ]; then \
    sed -i '/#include <vector>/a #include <limits>' src/benchmark_register.h; \
    fi

# Fix GoogleTest download (use release-1.12.1 which is compatible with C++11)
RUN sed -i 's/GIT_TAG master/GIT_TAG "release-1.12.1"/' cmake/HandleGTest.cmake

# Fix GoogleTest library naming - release-1.12.1 doesn't use debug suffix
RUN sed -i 's/set(LIB_SUFFIX "d${CMAKE_STATIC_LIBRARY_SUFFIX}")/set(LIB_SUFFIX "${CMAKE_STATIC_LIBRARY_SUFFIX}")/' cmake/HandleGTest.cmake

# Configure CMake build with GoogleTest dependencies
RUN cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=11 \
    -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
    -DBENCHMARK_ENABLE_TESTING=ON \
    -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
    -DBENCHMARK_ENABLE_WERROR=OFF

# Build the project and tests (limit parallelism to avoid OOM)
# First build googletest dependency explicitly to ensure it's downloaded
RUN cmake --build build --config Debug --target googletest -j 1 || true
RUN cmake --build build --config Debug -j 1

# Reset tracked files so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
# Use git apply instead of patch to properly handle file deletions
COPY bug.patch /tmp/bug.patch
RUN git apply /tmp/bug.patch && rm /tmp/bug.patch

# Fix GoogleTest download again after patch
RUN sed -i 's/GIT_TAG master/GIT_TAG "release-1.12.1"/' cmake/HandleGTest.cmake

# Fix GoogleTest library naming again after patch
RUN sed -i 's/set(LIB_SUFFIX "d${CMAKE_STATIC_LIBRARY_SUFFIX}")/set(LIB_SUFFIX "${CMAKE_STATIC_LIBRARY_SUFFIX}")/' cmake/HandleGTest.cmake

# Clean and rebuild after applying bug.patch to ensure old binaries are removed
RUN rm -rf build && \
    cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=11 \
    -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
    -DBENCHMARK_ENABLE_TESTING=ON \
    -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
    -DBENCHMARK_ENABLE_WERROR=OFF && \
    cmake --build build --config Debug --target googletest -j 1 || true && \
    cmake --build build --config Debug -j 1

RUN rm -rf /app/src/.git

WORKDIR /app/src
