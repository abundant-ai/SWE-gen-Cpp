FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler (Clang), CMake, and Python (needed for tests)
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    clang \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Use Clang as the C++ compiler (required for unreachable-code warnings)
ENV CC=clang
ENV CXX=clang++
# Suppress unrelated literal operator warning for Clang 18 compatibility
ENV CXXFLAGS="-Wno-error=deprecated-literal-operator"

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/catchorg/Catch2.git src && \
    cd src && \
    (git fetch --depth 1 origin 2e66a84765f383d88c2abb6b7fd92fe7aff1fc79 || git fetch --depth 1 origin "+refs/pull/2554/head:refs/remotes/origin/pr/2554") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure and build Catch2 with CMake
# Enable development build which treats warnings as errors
# Suppress unrelated literal operator warning for Clang 18 compatibility
# Note: We configure first, then add missing includes, then build
RUN cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -DCMAKE_CXX_FLAGS="-Wno-error=deprecated-literal-operator" \
    -G Ninja

# Fix missing <cstdint> includes that were added in a later commit
# The PR 2554 code uses uint64_t/uint8_t/uint32_t but forgot to include <cstdint>
RUN sed -i '15i #include <cstdint>' src/catch2/internal/catch_string_manip.hpp && \
    sed -i '10i #include <cstdint>' src/catch2/catch_test_case_info.hpp && \
    sed -i '10i #include <cstdint>' src/catch2/internal/catch_xmlwriter.cpp

# Build will fail if there are unreachable-code warnings (development build treats warnings as errors)
RUN cmake --build build

# Reset tracked files so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Fix missing includes again (undone by git reset)
RUN sed -i '15i #include <cstdint>' src/catch2/internal/catch_string_manip.hpp && \
    sed -i '10i #include <cstdint>' src/catch2/catch_test_case_info.hpp && \
    sed -i '10i #include <cstdint>' src/catch2/internal/catch_xmlwriter.cpp

# Rebuild after applying bug.patch (C++ is a compiled language)
RUN cmake --build build

RUN rm -rf /app/src/.git

WORKDIR /app/src
