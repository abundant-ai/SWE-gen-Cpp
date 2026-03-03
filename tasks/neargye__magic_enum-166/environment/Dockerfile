FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler and CMake for building and testing
RUN apt-get update && apt-get install -y \
    g++ \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/Neargye/magic_enum.git src && \
    cd src && \
    (git fetch --depth 1 origin 133ffa192ab78c099b0b06bc884780fbdd1a1815 || git fetch --depth 1 origin "+refs/pull/166/head:refs/remotes/origin/pr/166") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Patch test/CMakeLists.txt to remove -pedantic-errors (incompatible with emoji lexing)
RUN sed -i 's/-pedantic-errors//g' test/CMakeLists.txt

# Configure CMake for building tests
# Note: Extended identifiers and UTF-8 input are required even with NONASCII=OFF
# because the test file contains emojis in #ifdef blocks and the lexer must process them
RUN mkdir -p build && cd build && \
    CXXFLAGS="-fextended-identifiers -finput-charset=UTF-8" cmake .. -DMAGIC_ENUM_OPT_BUILD_TESTS=ON -DMAGIC_ENUM_OPT_ENABLE_NONASCII=OFF

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
