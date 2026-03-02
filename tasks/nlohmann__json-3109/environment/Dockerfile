FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake and ninja-build for building C++ tests
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/nlohmann/json.git src && \
    cd src && \
    (git fetch --depth 1 origin 80067d96ffb5ab4f289a36a82c233430e3d362f2 || git fetch --depth 1 origin "+refs/pull/3109/head:refs/remotes/origin/pr/3109") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure the project and tests using CMake
RUN cmake -S . -B build -G Ninja -DJSON_BuildTests=ON

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (only build test-ordered_map, not test-regression2 which has unrelated compilation issues)
RUN cmake --build build --target test-ordered_map

RUN rm -rf /app/src/.git

WORKDIR /app/src
