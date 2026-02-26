FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler (clang for better C++20 conformance) and CMake
RUN apt-get update && apt-get install -y \
    cmake \
    clang \
    && rm -rf /var/lib/apt/lists/*

# Use clang as the default C++ compiler with strict conformance flags
ENV CXX="clang++ -pedantic-errors"
ENV CC="clang"

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/nlohmann/json.git src && \
    cd src && \
    (git fetch --depth 1 origin cd1f291d1507ba62a3b57132fb0d280c10e6cf2a || git fetch --depth 1 origin "+refs/pull/5052/head:refs/remotes/origin/pr/5052") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build the project with CMake
# This is a header-only library but we need to configure and build tests
RUN cmake -S . -B build -DJSON_BuildTests=ON -DJSON_MultipleHeaders=ON && \
    cmake --build build --parallel $(nproc)

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (C++ compiled language)
# Clean build to ensure header changes are picked up
RUN rm -rf build && \
    cmake -S . -B build -DJSON_BuildTests=ON -DJSON_MultipleHeaders=ON && \
    cmake --build build --parallel $(nproc)

RUN rm -rf /app/src/.git

WORKDIR /app/src
