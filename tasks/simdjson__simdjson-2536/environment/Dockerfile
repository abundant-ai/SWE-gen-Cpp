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
    (git fetch --depth 1 origin 0ab681cc90168c514bd8bd23e35caebd0d62cdda || git fetch --depth 1 origin "+refs/pull/2536/head:refs/remotes/origin/pr/2536") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Create minimal stub headers for experimental C++23/C++26 features
# <print> is C++23 but not yet in libc++-19
# <meta> is experimental C++26 reflection
RUN mkdir -p /usr/lib/llvm-19/include/c++/v1 && \
    echo "// Stub print header for C++23" > /usr/lib/llvm-19/include/c++/v1/print && \
    echo "#pragma once" >> /usr/lib/llvm-19/include/c++/v1/print && \
    echo "namespace std {" >> /usr/lib/llvm-19/include/c++/v1/print && \
    echo "  template<typename... Args> void print(Args&&...) {}" >> /usr/lib/llvm-19/include/c++/v1/print && \
    echo "  template<typename... Args> void println(Args&&...) {}" >> /usr/lib/llvm-19/include/c++/v1/print && \
    echo "}" >> /usr/lib/llvm-19/include/c++/v1/print && \
    echo "// Stub meta header for C++26 experimental reflection" > /usr/lib/llvm-19/include/c++/v1/meta && \
    echo "#pragma once" >> /usr/lib/llvm-19/include/c++/v1/meta && \
    echo "namespace std { namespace meta { } }" >> /usr/lib/llvm-19/include/c++/v1/meta

# Configure and build the project with CMake (with C++20 for concepts support)
# Note: We do NOT enable SIMDJSON_STATIC_REFLECTION=ON here because it requires experimental
# C++26 compiler features. The compile_time tests will be built differently.
RUN cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_CXX_STANDARD=20 -B build && \
    cmake --build build -j=2

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (required for C++ compiled language)
RUN cmake --build build -j=2

RUN rm -rf /app/src/.git

WORKDIR /app/src
