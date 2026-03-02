FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake (required for building spdlog)
RUN apt-get update && apt-get install -y \
    cmake \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/gabime/spdlog.git src && \
    cd src && \
    (git fetch --depth 1 origin f8c0420e0e942e07cd634d54f4913859bab4d5f7 || git fetch --depth 1 origin "+refs/pull/3327/head:refs/remotes/origin/pr/3327") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build spdlog initially
RUN mkdir -p build && cd build && \
    cmake .. \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_CXX_STANDARD=11 \
        -DSPDLOG_BUILD_TESTS=ON \
        -DSPDLOG_BUILD_TESTS_HO=OFF \
        -DSPDLOG_BUILD_EXAMPLE=OFF && \
    make -j$(nproc)

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
# Note: README.md may fail due to line ending differences, but that's OK since it's just documentation
COPY bug.patch /tmp/bug.patch
RUN (patch -p1 < /tmp/bug.patch || true) && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
