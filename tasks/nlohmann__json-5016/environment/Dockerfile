FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake (required for building C++ tests)
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/nlohmann/json.git src && \
    cd src && \
    (git fetch --depth 1 origin a583225da2ec3e18d090ee5851406599616087a1 || git fetch --depth 1 origin "+refs/pull/5016/head:refs/remotes/origin/pr/5016") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure CMake and build tests
RUN cmake -S . -B build -DJSON_BuildTests=ON

# Build the specific test executable for unit-constructor1
RUN cmake --build build --target test-constructor1_cpp11

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch
RUN cmake --build build --target test-constructor1_cpp11

RUN rm -rf /app/src/.git

WORKDIR /app/src
