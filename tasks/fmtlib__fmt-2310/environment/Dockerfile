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
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/fmtlib/fmt.git src && \
    cd src && \
    (git fetch --depth 1 origin b92319da6faa4eedb89f6c7cfd64931df8761dfa || git fetch --depth 1 origin "+refs/pull/2310/head:refs/remotes/origin/pr/2310") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure with G++ and C++20
RUN mkdir -p build && cd build && cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DFMT_TEST=ON \
    -DFMT_PEDANTIC=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_CXX_STANDARD=20

# Reset any modified files before applying bug.patch
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Reconfigure CMake after applying patch
RUN cd build && cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DFMT_TEST=ON \
    -DFMT_PEDANTIC=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_CXX_STANDARD=20

RUN rm -rf /app/src/.git

WORKDIR /app/src
