FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake and ninja-build for building C++ tests
# Install Clang to catch the specific warnings this PR fixes (-Wsign-conversion, -Wshorten-64-to-32)
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
    (git fetch --depth 1 origin 35b47c2793d1b005993d965cf7ca11d0867aae98 || git fetch --depth 1 origin "+refs/pull/1797/head:refs/remotes/origin/pr/1797") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Patch doctest.h to fix SIGSTKSZ compilation issue with newer glibc
RUN sed -i 's/static char             altStackMem\[4 \* SIGSTKSZ\];/static char             altStackMem[65536];/' test/thirdparty/doctest/doctest.h

# Configure the project and tests using CMake with C++17 and Clang with strict warning flags
# Add -Wsign-conversion and -Wshorten-64-to-32 to catch the warnings this PR fixes, and -Werror to treat warnings as errors
RUN cmake -S . -B build -G Ninja -DJSON_BuildTests=ON -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_C_COMPILER=clang-14 -DCMAKE_CXX_COMPILER=clang++-14 \
    -DCMAKE_CXX_FLAGS="-Wsign-conversion -Wshorten-64-to-32 -Werror"

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
