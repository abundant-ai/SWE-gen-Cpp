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
    libgtest-dev \
    libgmock-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/jbeder/yaml-cpp.git src && \
    cd src && \
    (git fetch --depth 1 origin 9e09d8b08250aa3edff9d80ac4f3d356e8c23537 || git fetch --depth 1 origin "+refs/pull/1312/head:refs/remotes/origin/pr/1312") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build the project with CMake (use C++17 for std::string_view support)
RUN mkdir -p build && cd build && \
    cmake .. \
    -DYAML_CPP_BUILD_TESTS=ON \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=17 && \
    make -j2

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (C++ is a compiled language)
RUN cd build && make -j2

RUN rm -rf /app/src/.git

WORKDIR /app/src
