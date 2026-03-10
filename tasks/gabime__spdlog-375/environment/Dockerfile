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
    (git fetch --depth 1 origin fd8df5b8202b02be8e10c9055da4e99ea87460a6 || git fetch --depth 1 origin "+refs/pull/375/head:refs/remotes/origin/pr/375") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Convert line endings to Unix format before applying patch
RUN apt-get update && apt-get install -y dos2unix && rm -rf /var/lib/apt/lists/* && \
    dos2unix tests/CMakeLists.txt 2>/dev/null || true

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (C++ is a compiled language)
RUN rm -rf build && \
    mkdir -p build && \
    cd build && \
    cmake .. -DSPDLOG_BUILD_TESTS=ON -DSPDLOG_BUILD_EXAMPLES=OFF -DSPDLOG_BUILD_BENCH=OFF -DCMAKE_CXX_FLAGS="-DSPDLOG_FMT_PRINTF" && \
    make -j$(nproc)

RUN rm -rf /app/src/.git

WORKDIR /app/src
