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
    (git fetch --depth 1 origin 71c0e165e185fe4160c6f2b63bf852b3ed76064c || git fetch --depth 1 origin "+refs/pull/4963/head:refs/remotes/origin/pr/4963") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure CMake and build tests
RUN cmake -S . -B build -DJSON_BuildTests=ON

# Build the specific test executables for unit-deserialization and unit-json_pointer (C++20 for char8_t support)
RUN cmake --build build --target test-deserialization_cpp20
RUN cmake --build build --target test-json_pointer_cpp20

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch
RUN cmake --build build --target test-deserialization_cpp20
RUN cmake --build build --target test-json_pointer_cpp20

RUN rm -rf /app/src/.git

WORKDIR /app/src
