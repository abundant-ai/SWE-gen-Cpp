FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler and CMake for building and testing
RUN apt-get update && apt-get install -y \
    g++ \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/Neargye/magic_enum.git src && \
    cd src && \
    (git fetch --depth 1 origin e2578822edd9da570f577cfdb0a8dc615c135083 || git fetch --depth 1 origin "+refs/pull/43/head:refs/remotes/origin/pr/43") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Create build directory (tests will be built in test.sh after copying specific test files)
RUN mkdir build

RUN rm -rf /app/src/.git

WORKDIR /app/src
