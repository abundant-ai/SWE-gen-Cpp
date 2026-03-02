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
    (git fetch --depth 1 origin 1a49b67aebe9e5178d5614ff1359bbbca04d2eed || git fetch --depth 1 origin "+refs/pull/2388/head:refs/remotes/origin/pr/2388") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build Google Test/Mock with CMake
# Disable all warnings being treated as errors (old codebase with newer compiler)
RUN mkdir -p build && cd build && \
    cmake -Dgtest_build_samples=ON \
          -Dgtest_build_tests=ON \
          -Dgmock_build_tests=ON \
          -DCMAKE_CXX_FLAGS="-w" \
          .. && \
    make -j4

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (C++ is a compiled language)
RUN cd build && make -j4

RUN rm -rf /app/src/.git

WORKDIR /app/src
