FROM ubuntu:18.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install GCC-8 (available by default in Ubuntu 18.04 for testing filesystem library detection)
RUN apt-get update && apt-get install -y \
    g++-8 \
    gcc-8 \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Set GCC-8 as the default compiler
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 100 && \
    update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-8 100 && \
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-8 100

# Install CMake for building the C++ project
RUN apt-get update && apt-get install -y \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/fmtlib/fmt.git src && \
    cd src && \
    (git fetch --depth 1 origin 9dba14f3e64c048bb007b362f8e7c0528a40b80a || git fetch --depth 1 origin "+refs/pull/2951/head:refs/remotes/origin/pr/2951") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure the project with CMake (use GCC-8 to test filesystem library detection)
RUN mkdir -p build && cd build && cmake .. \
    -DCMAKE_C_COMPILER=gcc-8 \
    -DCMAKE_CXX_COMPILER=g++-8 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DFMT_TEST=ON

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Reconfigure after applying bug.patch (use GCC-8 to test filesystem library detection)
RUN cd build && cmake .. \
    -DCMAKE_C_COMPILER=gcc-8 \
    -DCMAKE_CXX_COMPILER=g++-8 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DFMT_TEST=ON

RUN rm -rf /app/src/.git

WORKDIR /app/src
