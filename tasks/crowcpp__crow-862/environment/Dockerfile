FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler (Clang), CMake, and dependencies for Crow
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    clang \
    libasio-dev \
    libssl-dev \
    zlib1g-dev \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/CrowCpp/Crow.git src && \
    cd src && \
    (git fetch --depth 1 origin 45a10fcfce616545b9df6194379aa3847fa93b70 || git fetch --depth 1 origin "+refs/pull/862/head:refs/remotes/origin/pr/862") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Use Clang as the C++ compiler
ENV CC=clang
ENV CXX=clang++

# Configure and build Crow with CMake (enable tests and sanitizers, disable examples)
RUN cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCROW_BUILD_TESTS=ON \
    -DCROW_BUILD_EXAMPLES=OFF \
    -DCROW_ENABLE_SSL=ON \
    -DCROW_ENABLE_COMPRESSION=ON \
    -DCROW_ENABLE_SANITIZERS=ON \
    -G Ninja

# Build only the test target
RUN cmake --build build --target unittest

# Reset any tracked files modified during build so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (C++ is a compiled language)
RUN cmake --build build --target unittest

RUN rm -rf /app/src/.git

WORKDIR /app/src
