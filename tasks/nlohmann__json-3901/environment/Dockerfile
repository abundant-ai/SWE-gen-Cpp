FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake and compilers (using gcc-12 for compatibility with test code at this commit)
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    software-properties-common \
    gcc-12 \
    g++-12 \
    clang-14 \
    locales \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100 \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-12 100 \
    && locale-gen de_DE \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/nlohmann/json.git src && \
    cd src && \
    (git fetch --depth 1 origin 79bae8a96ab6061dfdcb388a3b7fe90c3f874b9d || git fetch --depth 1 origin "+refs/pull/3901/head:refs/remotes/origin/pr/3901") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure CMake and build tests
RUN cmake -S . -B build -DJSON_BuildTests=ON

# Download test data (needed for some tests)
RUN cmake --build build --target download_test_data

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Remove any pre-built test artifacts that depend on patched files
RUN rm -f build/tests/test-*msgpack* build/tests/test-*benchmarks* build/tests/CMakeFiles/test-*/src/unit-*.cpp.o build/benchmarks/benchmarks

RUN rm -rf /app/src/.git

WORKDIR /app/src
