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
    (git fetch --depth 1 origin d68127d8adc1111c49b372ba12f7c3e4f053a2f0 || git fetch --depth 1 origin "+refs/pull/90/head:refs/remotes/origin/pr/90") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Configure CMake build (but don't build yet - will do after patching)
RUN cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=11 \
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

# Clean and reconfigure CMake after applying bug.patch and compatibility fix
RUN rm -rf build && \
    cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=11 \
    -DBENCHMARK_ENABLE_TESTING=ON

RUN rm -rf /app/src/.git

WORKDIR /app/src
