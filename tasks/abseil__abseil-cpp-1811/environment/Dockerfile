FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ development tools and CMake
RUN apt-get update && apt-get install -y \
    cmake \
    g++ \
    libgtest-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/abseil/abseil-cpp.git src && \
    cd src && \
    (git fetch --depth 1 origin eb12bb08c70a91f082937b40c663cb4ac848c53f || git fetch --depth 1 origin "+refs/pull/1811/head:refs/remotes/origin/pr/1811") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build the project with CMake
RUN mkdir -p build && cd build && \
    cmake .. \
    -DABSL_BUILD_TESTING=ON \
    -DCMAKE_BUILD_TYPE=Debug && \
    make -j$(nproc)

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (C++ is a compiled language)
RUN cd build && make -j$(nproc)

RUN rm -rf /app/src/.git

WORKDIR /app/src
