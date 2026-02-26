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
    python3 \
    python3-pip \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Generate locales for testing (de_DE uses comma as decimal separator)
RUN locale-gen de_DE.UTF-8

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/jbeder/yaml-cpp.git src && \
    cd src && \
    (git fetch --depth 1 origin 3213df1ac69ecdd1a12f191c567c33df88c0284a || git fetch --depth 1 origin "+refs/pull/386/head:refs/remotes/origin/pr/386") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

ENV LANG=de_DE.UTF-8
ENV LC_ALL=de_DE.UTF-8

# Configure the build
RUN cmake -B build \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=17 \
    -DYAML_CPP_BUILD_TESTS=ON \
    -DYAML_BUILD_SHARED_LIBS=OFF

# Build the project initially
RUN cmake --build build --config Debug

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
