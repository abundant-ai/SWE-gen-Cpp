FROM ubuntu:24.04

# Base system packages
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    cmake \
    wget \
    && rm -rf /var/lib/apt/lists/*

# No additional language runtime needed - pugixml is a C++ header-only library

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/zeux/pugixml.git src && \
    cd src && \
    (git fetch --depth 1 origin 9c3825d3b711d4267e741380be8a0349e20d8f67 || git fetch --depth 1 origin "+refs/pull/244/head:refs/remotes/origin/pr/244") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build the test suite using cmake
RUN cmake . -DBUILD_TESTS=ON && \
    make -j$(nproc)

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN git apply --whitespace=fix /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch since this is compiled C++
RUN rm -rf CMakeCache.txt CMakeFiles && \
    cmake . -DBUILD_TESTS=ON && \
    make -j$(nproc)

RUN rm -rf /app/src/.git

WORKDIR /app/src
