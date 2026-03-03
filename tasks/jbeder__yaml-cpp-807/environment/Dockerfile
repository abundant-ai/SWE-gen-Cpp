FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install additional system packages needed for yaml-cpp
RUN apt-get update && apt-get install -y \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/jbeder/yaml-cpp.git src && \
    cd src && \
    (git fetch --depth 1 origin dbd5ac094622ef3b3951e71c31f59e02c930dc4b || git fetch --depth 1 origin "+refs/pull/807/head:refs/remotes/origin/pr/807") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure the build
RUN cmake -B build \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=17 \
    -DYAML_CPP_BUILD_TESTS=ON \
    -DYAML_BUILD_SHARED_LIBS=OFF \
    -DCMAKE_CXX_FLAGS="-Wno-error=maybe-uninitialized"

# Fix compilation issue: add const to less comparator
RUN sed -i 's/bool operator ()(const node\* l, const node\* r) {return l->m_index < r->m_index;}/bool operator ()(const node* l, const node* r) const {return l->m_index < r->m_index;}/' include/yaml-cpp/node/detail/node.h

# Build the project initially
RUN cmake --build build --config Debug

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
