FROM ubuntu:24.04

# Base system packages (common to all languages)
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
    (git fetch --depth 1 origin dd2f293f339afa0a5a3637c7c4c890b43a76e12b || git fetch --depth 1 origin "+refs/pull/1082/head:refs/remotes/origin/pr/1082") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build the project with CMake
RUN mkdir -p build && \
    cd build && \
    cmake .. -DSPDLOG_BUILD_TESTS=ON && \
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
# Need to clean build directory since project structure changed
# Disable examples since they expect spdlog to be installed
RUN rm -rf build && \
    mkdir -p build && \
    cd build && \
    cmake .. -DSPDLOG_BUILD_TESTS=ON -DSPDLOG_BUILD_EXAMPLES=OFF && \
    make -j$(nproc)

RUN rm -rf /app/src/.git

WORKDIR /app/src
