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
    (git fetch --depth 1 origin 563992672fbe56c20149915d67638c31d0376f66 || git fetch --depth 1 origin "+refs/pull/95/head:refs/remotes/origin/pr/95") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Patch test/CMakeLists.txt to remove -pedantic-errors (incompatible with emoji lexing)
RUN sed -i 's/-pedantic-errors//g' test/CMakeLists.txt

# Configure CMake for building tests
# Note: Extended identifiers and UTF-8 input are required because the test uses non-ASCII enum identifiers
RUN mkdir -p build && cd build && \
    CXXFLAGS="-fextended-identifiers -finput-charset=UTF-8" cmake .. -DMAGIC_ENUM_OPT_BUILD_TESTS=ON -DMAGIC_ENUM_OPT_ENABLE_NONASCII=ON

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
