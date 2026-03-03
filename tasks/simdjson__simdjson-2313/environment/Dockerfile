FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake and C++ compiler (use clang for C++20 ranges support)
RUN apt-get update && apt-get install -y \
    cmake \
    clang \
    && rm -rf /var/lib/apt/lists/*

# Use Clang as the C++ compiler (required for ranges_test which needs Clang >= 15)
ENV CC=clang
ENV CXX=clang++

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/simdjson/simdjson.git src && \
    cd src && \
    (git fetch --depth 1 origin 726678a4ee6065e95ea656c4d29cc03eb9f3e719 || git fetch --depth 1 origin "+refs/pull/2313/head:refs/remotes/origin/pr/2313") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure and build the project with CMake (with C++20 for concepts support)
# Enable SIMDJSON_MINUS_ZERO_AS_FLOAT to test the -0 as -0.0 feature
RUN cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build && \
    cmake --build build -j=2

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (required for C++ compiled language)
RUN cmake --build build -j=2

RUN rm -rf /app/src/.git

WORKDIR /app/src
