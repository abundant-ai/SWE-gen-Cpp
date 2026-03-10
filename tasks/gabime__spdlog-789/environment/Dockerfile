FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake build tool
RUN apt-get update && apt-get install -y \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/gabime/spdlog.git src && \
    cd src && \
    (git fetch --depth 1 origin 4534d5239fe5dac44af1cd6c9b276224ff5379af || git fetch --depth 1 origin "+refs/pull/789/head:refs/remotes/origin/pr/789") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (C++ is a compiled language)
RUN rm -rf build && \
    mkdir -p build && \
    cd build && \
    cmake .. -DSPDLOG_BUILD_TESTS=ON -DSPDLOG_BUILD_EXAMPLES=OFF -DSPDLOG_BUILD_BENCH=OFF && \
    make -j$(nproc)

RUN rm -rf /app/src/.git

WORKDIR /app/src
