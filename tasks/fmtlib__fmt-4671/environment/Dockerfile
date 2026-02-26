FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake for building C++ project
RUN apt-get update && apt-get install -y \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/fmtlib/fmt.git src && \
    cd src && \
    (git fetch --depth 1 origin 87a41ef943e2d7712c3a681e2090b7160be0e9b1 || git fetch --depth 1 origin "+refs/pull/4671/head:refs/remotes/origin/pr/4671") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure and build the project with CMake
RUN cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DFMT_TEST=ON \
    && cmake --build build --parallel $(nproc)

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Clean and rebuild after applying bug.patch (removes C API from CMakeLists.txt)
RUN rm -rf build && \
    cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DFMT_TEST=ON \
    && cmake --build build --parallel $(nproc)

RUN rm -rf /app/src/.git

WORKDIR /app/src
