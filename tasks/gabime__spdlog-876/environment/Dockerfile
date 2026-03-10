FROM ubuntu:24.04

# Install base system packages
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake build tool
RUN apt-get update && apt-get install -y \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/gabime/spdlog.git src && \
    cd src && \
    (git fetch --depth 1 origin cb71fea0f6c9bb5722ca59e9b7917328217cfe5d || git fetch --depth 1 origin "+refs/pull/876/head:refs/remotes/origin/pr/876") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build the project with CMake
RUN mkdir -p build && \
    cd build && \
    cmake .. -DSPDLOG_BUILD_TESTS=ON -DSPDLOG_BUILD_BENCH=OFF && \
    make -j$(nproc)

# Reset any changes from build steps before applying bug.patch
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
# First normalize line endings to unix format
RUN apt-get update && apt-get install -y dos2unix && rm -rf /var/lib/apt/lists/*
RUN find . -type f \( -name "*.txt" -o -name "*.cmake" -o -name ".gitignore" -o -name ".gitattributes" \) -exec dos2unix {} \;

COPY bug.patch /tmp/bug.patch
RUN patch -p1 --no-backup-if-mismatch --reject-file=- < /tmp/bug.patch || [ $? -eq 1 ] && rm /tmp/bug.patch

# Rebuild after applying bug.patch (C++ is a compiled language)
RUN rm -rf build && \
    mkdir -p build && \
    cd build && \
    cmake .. -DSPDLOG_BUILD_TESTS=ON -DSPDLOG_BUILD_EXAMPLES=OFF -DSPDLOG_BUILD_BENCH=OFF && \
    make -j$(nproc)

RUN rm -rf /app/src/.git

WORKDIR /app/src
