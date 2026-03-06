FROM ubuntu:22.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ build tools, CMake, and GSSAPI library
RUN apt-get update && apt-get install -y \
    cmake \
    g++ \
    pkg-config \
    libkrb5-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/zeromq/libzmq.git src && \
    cd src && \
    (git fetch --depth 1 origin 2d23b599f2939beff3ad5254fd4e426ad35048d9 || git fetch --depth 1 origin "+refs/pull/3921/head:refs/remotes/origin/pr/3921") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build libzmq with ENABLE_DRAFTS=ON and GSSAPI support
# Keep .git until after build so ENABLE_DRAFTS defaults to ON
RUN mkdir -p build && cd build && \
    cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON && \
    make -j$(nproc)

# Reset any build artifacts before applying bug.patch
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 --reject-file=- < /tmp/bug.patch || true && rm /tmp/bug.patch

# Rebuild after applying bug.patch
RUN cd build && make -j$(nproc)

# Keep .git so that ENABLE_DRAFTS defaults to ON in test.sh

WORKDIR /app/src
