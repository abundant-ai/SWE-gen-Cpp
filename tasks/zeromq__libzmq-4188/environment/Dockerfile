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
    (git fetch --depth 1 origin f10cf239a78ebcc35d950dd0ad0a4021dc707765 || git fetch --depth 1 origin "+refs/pull/4188/head:refs/remotes/origin/pr/4188") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build libzmq with ENABLE_DRAFTS=ON and GSSAPI support
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

RUN rm -rf /app/src/.git

WORKDIR /app/src
