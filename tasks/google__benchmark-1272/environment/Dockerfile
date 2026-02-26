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

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/google/benchmark.git src && \
    cd src && \
    (git fetch --depth 1 origin 49f110ed3401504dfb19fdeb70ab03078910802e || git fetch --depth 1 origin "+refs/pull/1272/head:refs/remotes/origin/pr/1272") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Fix GoogleTest download (master branch was renamed to main, use a specific release tag)
RUN sed -i 's/GIT_TAG           master/GIT_TAG           "release-1.11.0"/' cmake/GoogleTest.cmake.in

# Configure CMake build with GoogleTest dependencies
RUN cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Debug \
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

# Fix GoogleTest download again after patch (in case patch affected it)
RUN sed -i 's/GIT_TAG           master/GIT_TAG           "release-1.11.0"/' cmake/GoogleTest.cmake.in

# Clean and rebuild after applying bug.patch to ensure old binaries are removed
RUN rm -rf build && \
    cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
    -DBENCHMARK_ENABLE_TESTING=ON \
    -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
    -DBENCHMARK_ENABLE_WERROR=OFF \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && \
    cmake --build build --config Debug -j 1

RUN rm -rf /app/src/.git

WORKDIR /app/src
