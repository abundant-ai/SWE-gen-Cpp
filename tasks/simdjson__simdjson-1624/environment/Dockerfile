FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake and C++ compiler
RUN apt-get update && apt-get install -y \
    cmake \
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/simdjson/simdjson.git src && \
    cd src && \
    (git fetch --depth 1 origin 099491c48001e572e314cd15695cd2125ab46309 || git fetch --depth 1 origin "+refs/pull/1624/head:refs/remotes/origin/pr/1624") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure and build the project with CMake (with C++20 for concepts support)
# Build test targets to prepare for testing
RUN mkdir -p dependencies/.cache && \
    cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build && \
    cmake --build build --target simdjson -j=2

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard && \
    rm -rf build dependencies/.cache

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild library after applying bug.patch (don't build tests - they were removed by patch)
RUN cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build && \
    cmake --build build --target simdjson -j=2

RUN rm -rf /app/src/.git

WORKDIR /app/src
