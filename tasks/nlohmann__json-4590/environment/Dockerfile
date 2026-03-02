FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake and compilers
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    software-properties-common \
    clang-18 \
    clang-tools-18 \
    libc++-18-dev \
    libc++abi-18-dev \
    && add-apt-repository ppa:ubuntu-toolchain-r/test -y \
    && apt-get update \
    && apt-get install -y gcc-15 g++-15 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-15 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-15 100 \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-15 100 \
    && ln -s /usr/lib/llvm-18/bin/clang-scan-deps /usr/bin/clang-scan-deps || true \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/nlohmann/json.git src && \
    cd src && \
    (git fetch --depth 1 origin f13c4aecc3e6be71dda91e0238347218d7d6d09d || git fetch --depth 1 origin "+refs/pull/4590/head:refs/remotes/origin/pr/4590") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure CMake and build tests
RUN cmake -S . -B build -DJSON_BuildTests=ON

# Download test data (needed for some tests)
RUN cmake --build build --target download_test_data

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
