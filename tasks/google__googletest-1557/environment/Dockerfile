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
    (git fetch --depth 1 origin 1324e2d706d739217cceae361259a5cc01d1ff41 || git fetch --depth 1 origin "+refs/pull/1557/head:refs/remotes/origin/pr/1557") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build Google Test/Mock with CMake (with UBSan to catch the undefined behavior)
RUN mkdir -p build && cd build && \
    cmake -Dgtest_build_samples=ON \
          -Dgtest_build_tests=ON \
          -Dgmock_build_tests=ON \
          -DCMAKE_CXX_FLAGS="-fsanitize=undefined -fno-sanitize-recover=undefined -w" \
          -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=undefined" \
          .. && \
    make -j4 gmock-nice-strict_test

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (C++ is a compiled language)
RUN cd build && make -j4 gmock-nice-strict_test

RUN rm -rf /app/src/.git

WORKDIR /app/src
