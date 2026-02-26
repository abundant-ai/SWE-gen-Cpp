FROM ubuntu:24.04

# Install base system packages and C++ build dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/jbeder/yaml-cpp.git src && \
    cd src && \
    (git fetch --depth 1 origin 9aac21aa0dd5b9e22062e74d5aa5a66675c82492 || git fetch --depth 1 origin "+refs/pull/1318/head:refs/remotes/origin/pr/1318") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure and build the project with tests enabled
RUN cmake -B build \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=17 \
    -DYAML_CPP_BUILD_TESTS=ON \
    -DYAML_BUILD_SHARED_LIBS=OFF

RUN cmake --build build --config Debug --parallel

# Reset tracked files so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch
RUN cmake --build build --config Debug --parallel

RUN rm -rf /app/src/.git

WORKDIR /app/src
