FROM ubuntu:24.04

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
    (git fetch --depth 1 origin a763d734f2744cfe15003fe3b21afd58658da05e || git fetch --depth 1 origin "+refs/pull/3396/head:refs/remotes/origin/pr/3396") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 --reject-file=- < /tmp/bug.patch || true && rm /tmp/bug.patch

# Build libzmq with ENABLE_DRAFTS=ON and GSSAPI support
RUN mkdir -p build && cd build && \
    cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON && \
    make -j$(nproc)

RUN rm -rf /app/src/.git

WORKDIR /app/src
