FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler, CMake, and Python (needed for tests)
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    g++ \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/catchorg/Catch2.git src && \
    cd src && \
    (git fetch --depth 1 origin fe44137b70bedf459c1362ce8325f4a444bdf6bf || git fetch --depth 1 origin "+refs/pull/2408/head:refs/remotes/origin/pr/2408") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Fix GCC 13 build issue (missing cstdint includes) - needed for this commit to compile
RUN sed -i '/#include <catch2\/internal\/catch_stringref.hpp>/a \\n#include <cstdint>' src/catch2/internal/catch_string_manip.hpp && \
    sed -i '/#include <catch2\/internal\/catch_unique_ptr.hpp>/a \\n#include <cstdint>' src/catch2/catch_test_case_info.hpp && \
    sed -i '/#include <catch2\/internal\/catch_xmlwriter.hpp>/a \\n#include <cstdint>' src/catch2/internal/catch_xmlwriter.cpp

# Configure and build Catch2 with CMake
# Disable -Wdangling-reference warning which causes false positives in GCC 13+
RUN cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -DCMAKE_CXX_FLAGS="-Wno-error=dangling-reference" \
    -G Ninja

RUN cmake --build build

# Reset tracked files so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Re-apply GCC 13 build fixes after git reset removed them
RUN sed -i '/#include <catch2\/internal\/catch_stringref.hpp>/a \\n#include <cstdint>' src/catch2/internal/catch_string_manip.hpp && \
    sed -i '/#include <catch2\/internal\/catch_unique_ptr.hpp>/a \\n#include <cstdint>' src/catch2/catch_test_case_info.hpp && \
    sed -i '/#include <catch2\/internal\/catch_xmlwriter.hpp>/a \\n#include <cstdint>' src/catch2/internal/catch_xmlwriter.cpp

# Rebuild after applying bug.patch (C++ is a compiled language)
RUN cmake --build build

RUN rm -rf /app/src/.git

WORKDIR /app/src
