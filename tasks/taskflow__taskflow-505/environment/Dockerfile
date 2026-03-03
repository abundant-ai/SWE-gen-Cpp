FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler, CMake, and Ninja (C++20 modules require Ninja and Clang 18+)
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    wget \
    lsb-release \
    software-properties-common \
    gnupg \
    && wget https://apt.llvm.org/llvm.sh \
    && chmod +x llvm.sh \
    && ./llvm.sh 18 \
    && apt-get install -y clang-tools-18 libc++-18-dev libc++abi-18-dev \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100 \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-18 100 \
    && update-alternatives --install /usr/bin/clang-scan-deps clang-scan-deps /usr/bin/clang-scan-deps-18 100 \
    && rm -rf /var/lib/apt/lists/* llvm.sh

# Set CMake to use libc++ with Clang for C++20 module support
ENV CMAKE_CXX_FLAGS="-stdlib=libc++"

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/taskflow/taskflow.git src && \
    cd src && \
    (git fetch --depth 1 origin 31bcc08dd413bf2bba8710d9a679b33338140a55 || git fetch --depth 1 origin "+refs/pull/505/head:refs/remotes/origin/pr/505") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build the project with CMake (use Ninja generator for potential C++20 module support in tests)
RUN cmake -S . -B build -GNinja -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build --parallel $(nproc)

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after patching (required for C++ compiled project)
RUN cmake --build build --parallel $(nproc)

RUN rm -rf /app/src/.git

WORKDIR /app/src
