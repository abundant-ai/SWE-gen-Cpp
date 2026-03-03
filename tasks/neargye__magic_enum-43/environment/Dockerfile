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
    (git fetch --depth 1 origin e2578822edd9da570f577cfdb0a8dc615c135083 || git fetch --depth 1 origin "+refs/pull/43/head:refs/remotes/origin/pr/43") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Patch test/CMakeLists.txt to remove -pedantic-errors (incompatible with emoji lexing)
RUN sed -i 's/-pedantic-errors//g' test/CMakeLists.txt

# Patch Catch2 to fix MINSIGSTKSZ compilation error with modern glibc
RUN sed -i 's/static constexpr std::size_t sigStackSize/static const std::size_t sigStackSize/' test/3rdparty/Catch2/catch.hpp && \
    sed -i 's/char FatalConditionHandler::altStackMem\[sigStackSize\]/char FatalConditionHandler::altStackMem[1024 * 32]/' test/3rdparty/Catch2/catch.hpp

# Configure CMake for building tests
# Note: Extended identifiers and UTF-8 input are required because the test uses non-ASCII enum identifiers
RUN mkdir -p build && cd build && \
    CXXFLAGS="-fextended-identifiers -finput-charset=UTF-8" cmake .. -DMAGIC_ENUM_OPT_BUILD_TESTS=ON -DMAGIC_ENUM_OPT_ENABLE_NONASCII=ON

RUN rm -rf /app/src/.git

WORKDIR /app/src
