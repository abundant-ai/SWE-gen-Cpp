FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ build dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/fmtlib/fmt.git src && \
    cd src && \
    (git fetch --depth 1 origin 8b79716987f120890489e7240f8fa361cbd58538 || git fetch --depth 1 origin "+refs/pull/3205/head:refs/remotes/origin/pr/3205") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure with G++ and default C++ standard
RUN mkdir -p build && cd build && cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DFMT_TEST=ON \
    -DBUILD_SHARED_LIBS=ON

# Reset any modified files before applying bug.patch
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Reconfigure CMake after applying patch
RUN cd build && cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DFMT_TEST=ON \
    -DBUILD_SHARED_LIBS=ON

RUN rm -rf /app/src/.git

WORKDIR /app/src
