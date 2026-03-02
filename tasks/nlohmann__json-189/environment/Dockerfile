FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Generate German locale for tests
RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen

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
    (git fetch --depth 1 origin bd0f3001c6154a8720bd19c06e22956f78ee6db2 || git fetch --depth 1 origin "+refs/pull/189/head:refs/remotes/origin/pr/189") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Patch catch.hpp to fix SIGSTKSZ compilation issue with newer glibc
RUN sed -i 's/static char altStackMem\[SIGSTKSZ\];/static char altStackMem[262144];/' test/catch.hpp && \
    sed -i 's/char FatalConditionHandler::altStackMem\[SIGSTKSZ\]/char FatalConditionHandler::altStackMem[262144]/' test/catch.hpp

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 -f < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
