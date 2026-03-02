FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake, ninja-build, and Clang for building C++ tests
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    clang-14 \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-14 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-14 100 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/nlohmann/json.git src && \
    cd src && \
    (git fetch --depth 1 origin 8711ec603445698f0a02eb78c053625bc48facbe || git fetch --depth 1 origin "+refs/pull/986/head:refs/remotes/origin/pr/986") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Patch catch.hpp to fix SIGSTKSZ compilation issue with newer glibc
RUN sed -i 's/static char altStackMem\[SIGSTKSZ\];/static char altStackMem[262144];/' test/thirdparty/catch/catch.hpp && \
    sed -i 's/char FatalConditionHandler::altStackMem\[SIGSTKSZ\]/char FatalConditionHandler::altStackMem[262144]/' test/thirdparty/catch/catch.hpp

# Patch test/CMakeLists.txt to use C++17 instead of C++11
RUN sed -i 's/CXX_STANDARD 11/CXX_STANDARD 17/g' test/CMakeLists.txt

# Configure the project and tests using CMake with C++17 and Clang
RUN cmake -S . -B build -G Ninja -DJSON_BuildTests=ON -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_C_COMPILER=clang-14 -DCMAKE_CXX_COMPILER=clang++-14

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 -f < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
