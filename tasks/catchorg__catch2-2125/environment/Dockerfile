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
    (git fetch --depth 1 origin 46d0fe82a6608c233580f0e40ae7d8c1a243f699 || git fetch --depth 1 origin "+refs/pull/2125/head:refs/remotes/origin/pr/2125") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Fix GCC 13 build issue (missing cstdint includes) - needed for this commit to compile
RUN sed -i '/#include <catch2\/internal\/catch_stringref.hpp>/a \\n#include <cstdint>' src/catch2/internal/catch_string_manip.hpp && \
    sed -i '/#include <catch2\/internal\/catch_unique_ptr.hpp>/a \\n#include <cstdint>' src/catch2/catch_test_case_info.hpp && \
    sed -i '/#include <catch2\/internal\/catch_xmlwriter.hpp>/a \\n#include <cstdint>' src/catch2/internal/catch_xmlwriter.cpp

# Fix MINSIGSTKSZ issue - MINSIGSTKSZ is no longer a compile-time constant in newer glibc
RUN sed -i 's/static constexpr std::size_t sigStackSize = 32768 >= MINSIGSTKSZ ? 32768 : MINSIGSTKSZ;/static const std::size_t sigStackSize = 32768;/' src/catch2/internal/catch_fatal_condition_handler.cpp

# Configure and build Catch2 with CMake (disable extra tests to avoid MINSIGSTKSZ issues)
# Disable -Wdangling-reference warning which causes false positives in GCC 13+
RUN cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -DCATCH_BUILD_EXTRA_TESTS=OFF \
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
    sed -i '/#include <catch2\/internal\/catch_xmlwriter.hpp>/a \\n#include <cstdint>' src/catch2/internal/catch_xmlwriter.cpp && \
    sed -i 's/static constexpr std::size_t sigStackSize = 32768 >= MINSIGSTKSZ ? 32768 : MINSIGSTKSZ;/static const std::size_t sigStackSize = 32768;/' src/catch2/internal/catch_fatal_condition_handler.cpp

# Rebuild after applying bug.patch (C++ is a compiled language)
RUN cmake --build build

RUN rm -rf /app/src/.git

WORKDIR /app/src
