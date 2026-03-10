FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ build dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    clang \
    libc++-dev \
    libc++abi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/fmtlib/fmt.git src && \
    cd src && \
    (git fetch --depth 1 origin d32293c442ba4fda1275a808439a6f7f1e70c5c0 || git fetch --depth 1 origin "+refs/pull/4072/head:refs/remotes/origin/pr/4072") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Remove test/format file to avoid header collision with std::format
RUN rm -f test/format

# Add a workaround for CHAR_WIDTH macro conflict in modern glibc
RUN mkdir -p /usr/local/include/workaround && \
    printf '#pragma once\n#include_next <limits.h>\n#ifdef CHAR_WIDTH\n#undef CHAR_WIDTH\n#endif\n' > /usr/local/include/workaround/limits.h

# Configure with Clang and C++23 standard with BUILD_SHARED_LIBS=ON
RUN mkdir -p build && cd build && cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=23 \
    -DFMT_TEST=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DFMT_PEDANTIC=ON \
    -DCMAKE_CXX_FLAGS="-I/usr/local/include/workaround -stdlib=libc++"

# Reset any modified files before applying bug.patch
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Reconfigure CMake after applying patch with BUILD_SHARED_LIBS=ON
RUN cd build && cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=23 \
    -DFMT_TEST=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DFMT_PEDANTIC=ON \
    -DCMAKE_CXX_FLAGS="-I/usr/local/include/workaround -stdlib=libc++"

RUN rm -rf /app/src/.git

WORKDIR /app/src
