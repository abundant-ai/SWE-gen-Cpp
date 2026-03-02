FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake and bleeding-edge Clang for C++26 reflection support
RUN apt-get update && apt-get install -y \
    cmake \
    wget \
    lsb-release \
    software-properties-common \
    gnupg \
    && wget https://apt.llvm.org/llvm.sh \
    && chmod +x llvm.sh \
    && ./llvm.sh 19 \
    && apt-get install -y libc++-19-dev libc++abi-19-dev \
    && rm -rf /var/lib/apt/lists/*

# Set clang-19 as the default compiler
ENV CC=clang-19
ENV CXX=clang++-19

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/simdjson/simdjson.git src && \
    cd src && \
    (git fetch --depth 1 origin c72954eade9fbb9d651cbcca0db9da594d6f4204 || git fetch --depth 1 origin "+refs/pull/2471/head:refs/remotes/origin/pr/2471") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure and build the project with CMake (with C++20 for concepts support)
RUN cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_CXX_STANDARD=20 -B build && \
    cmake --build build -j=2

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Clean and rebuild after applying bug.patch (required for C++ compiled language)
# We clean first to ensure all object files are regenerated
RUN rm -rf build && cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_CXX_STANDARD=20 -B build && \
    cmake --build build -j=2

RUN rm -rf /app/src/.git

WORKDIR /app/src
