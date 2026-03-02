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
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/nlohmann/json.git src && \
    cd src && \
    (git fetch --depth 1 origin 9abcdae53abff0e669fa46b81705f9d412851dd9 || git fetch --depth 1 origin "+refs/pull/3121/head:refs/remotes/origin/pr/3121") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure the project and tests using CMake
RUN cmake -S . -B build -G Ninja -DJSON_BuildTests=ON
# Build only the specific test target for this PR
RUN cmake --build build --target test-hash

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch
RUN cmake --build build --target test-hash

RUN rm -rf /app/src/.git

WORKDIR /app/src
