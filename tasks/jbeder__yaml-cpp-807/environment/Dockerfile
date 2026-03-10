FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install additional packages for yaml-cpp (C++ project)
RUN apt-get update && apt-get install -y \
    cmake \
    libgtest-dev \
    libgmock-dev \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Generate locales for proper character encoding in tests
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    sed -i '/de_DE.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/jbeder/yaml-cpp.git src && \
    cd src && \
    (git fetch --depth 1 origin dbd5ac094622ef3b3951e71c31f59e02c930dc4b || git fetch --depth 1 origin "+refs/pull/807/head:refs/remotes/origin/pr/807") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build the project with CMake
RUN mkdir -p build && cd build && \
    cmake .. \
    -DYAML_CPP_BUILD_TESTS=ON \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=11 \
    -DCMAKE_CXX_FLAGS="-Wno-error=maybe-uninitialized" && \
    make -j2

# Reset git state so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Note: Bug removes depth guard and test cases, so we cannot rebuild and test here
# The test.sh will copy the fixed test file and rebuild before running tests

RUN rm -rf /app/src/.git

WORKDIR /app/src
