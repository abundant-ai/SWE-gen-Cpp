FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake and GCC for building C++ project
RUN apt-get update && apt-get install -y \
    cmake \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/fmtlib/fmt.git src && \
    cd src && \
    (git fetch --depth 1 origin 4d65be44d2cfab9c4057467c56407584f30d2a12 || git fetch --depth 1 origin "+refs/pull/1650/head:refs/remotes/origin/pr/1650") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure the project with CMake
RUN cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_STANDARD=20 \
    -DFMT_TEST=ON

# Reset any changes from build to ensure bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Reconfigure after applying bug.patch
RUN cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_STANDARD=20 \
    -DFMT_TEST=ON

RUN rm -rf /app/src/.git

WORKDIR /app/src
