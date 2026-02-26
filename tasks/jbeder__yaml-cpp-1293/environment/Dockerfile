FROM ubuntu:24.04

# Install base system packages and C++ build dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    cmake \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Generate locales for testing (de_DE uses comma as decimal separator)
RUN locale-gen de_DE.UTF-8

ENV LANG=de_DE.UTF-8
ENV LC_ALL=de_DE.UTF-8

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/jbeder/yaml-cpp.git src && \
    cd src && \
    (git fetch --depth 1 origin a5c162f37fed249550db13f9d905900dba0e6710 || git fetch --depth 1 origin "+refs/pull/1293/head:refs/remotes/origin/pr/1293") && \
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
