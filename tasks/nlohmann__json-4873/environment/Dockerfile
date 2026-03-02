FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake (required for building C++ tests)
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/nlohmann/json.git src && \
    cd src && \
    (git fetch --depth 1 origin 14988150d0f52e05f8d549bba9ef8b52e5feeb42 || git fetch --depth 1 origin "+refs/pull/4873/head:refs/remotes/origin/pr/4873") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure CMake and build tests
RUN cmake -S . -B build -DJSON_BuildTests=ON

# Build the specific test executable for unit-class_parser
RUN cmake --build build --target test-class_parser_cpp11

# Reset tracked files so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch
RUN cmake --build build --target test-class_parser_cpp11

RUN rm -rf /app/src/.git

WORKDIR /app/src
