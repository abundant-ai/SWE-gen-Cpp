FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake, MinGW cross-compiler, and Wine for building and running Windows binaries
# This PR specifically fixes MinGW support, so we need to build with MinGW and run with Wine
RUN apt-get update && apt-get install -y \
    cmake \
    g++-mingw-w64-x86-64 \
    gcc-mingw-w64-x86-64 \
    wine64 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/fmtlib/fmt.git src && \
    cd src && \
    (git fetch --depth 1 origin 6aace693db9141788ab9311b7b6e8eb3cf3a85b7 || git fetch --depth 1 origin "+refs/pull/44/head:refs/remotes/origin/pr/44") && \
    git checkout --detach FETCH_HEAD

WORKDIR /app/src

# Configure the project with CMake using MinGW cross-compiler
RUN cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=Windows \
    -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
    -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
    -DCMAKE_CXX_STANDARD=14 \
    -DFMT_TEST=ON

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Reconfigure after applying bug.patch using MinGW cross-compiler
RUN cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=Windows \
    -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
    -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
    -DCMAKE_CXX_STANDARD=14 \
    -DFMT_TEST=ON

RUN rm -rf /app/src/.git

WORKDIR /app/src
