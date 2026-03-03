FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python3 for build scripts and create python symlink
RUN apt-get update && apt-get install -y \
    python3 \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/python3 /usr/bin/python

# Install C++ build tools, CMake, ninja, LLVM FileCheck for assembly tests
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    clang \
    clang-tidy \
    llvm \
    libgtest-dev \
    zip \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/FileCheck-18 /usr/local/bin/FileCheck

# Install locale support for locale_impermeability_test
RUN apt-get update && apt-get install -y \
    locales \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/google/benchmark.git src && \
    cd src && \
    (git fetch --depth 1 origin 9f27edbb1650c297f511c4b52e563ee3f0619348 || git fetch --depth 1 origin "+refs/pull/18/head:refs/remotes/origin/pr/18") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Build and install system gtest (libgtest-dev only provides sources)
RUN cd /usr/src/gtest && \
    cmake . && \
    make && \
    cp lib/*.a /usr/lib/

# Disable gtest download in CMakeLists.txt since we're using system gtest
# Comment out the ExternalProject_Add section that downloads gtest-1.7.0
RUN sed -i '/^# Import and build Google Test/,/^link_directories.*binary_dir.*)/d' CMakeLists.txt

# Update C++ standard from c++0x to c++14 for system gtest compatibility
RUN sed -i 's/--std=c++0x/--std=c++14/g' CMakeLists.txt

# Configure CMake build (but don't build yet - will do after patching)
RUN cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=14 \
    -DBENCHMARK_ENABLE_TESTING=ON

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Fix sys/sysctl.h compatibility issue with modern glibc (after patching)
# This header was removed from Linux glibc but is needed on FreeBSD/macOS
RUN sed -i '/#include <sys\/sysctl.h>/d' src/sysinfo.cc && \
    sed -i '/#include <sys\/types.h>/a #if defined(__FreeBSD__) || defined(__APPLE__)\n#include <sys/sysctl.h>\n#endif' src/sysinfo.cc

# Fix deprecated-copy warning in buggy state (GCC 13 is stricter)
# The buggy code has user-provided copy assignment but no copy constructor
RUN sed -i 's/-Werror/-Werror -Wno-error=deprecated-copy/g' CMakeLists.txt

# Disable gtest download again (bug.patch restored it)
RUN sed -i '/^# Import and build Google Test/,/^link_directories.*binary_dir.*)/d' CMakeLists.txt || true

# Update C++ standard from c++0x to c++14 for system gtest compatibility
RUN sed -i 's/--std=c++0x/--std=c++14/g' CMakeLists.txt

# Clean and reconfigure CMake after applying bug.patch and compatibility fix
RUN rm -rf build && \
    cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=14 \
    -DBENCHMARK_ENABLE_TESTING=ON

RUN rm -rf /app/src/.git

WORKDIR /app/src
