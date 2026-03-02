FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake (required for building spdlog)
RUN apt-get update && apt-get install -y \
    cmake \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at buggy commit (922f9163 - intermediate state with broken #ifdef logic)
# This is the buggy state that will be used as BASE
RUN git clone https://github.com/gabime/spdlog.git src && \
    cd src && \
    git fetch --depth 1 origin 922f9163cff4cf441e04ed83c5c56282caad6909 && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build spdlog initially without SPDLOG_USE_STD_FORMAT (which works even in buggy state)
# The actual bug testing with SPDLOG_USE_STD_FORMAT happens in test.sh
RUN mkdir -p build && cd build && \
    cmake .. \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_CXX_STANDARD=11 \
        -DSPDLOG_BUILD_TESTS=ON \
        -DSPDLOG_BUILD_TESTS_HO=OFF \
        -DSPDLOG_BUILD_EXAMPLE=OFF \
        -DSPDLOG_BUILD_WARNINGS=ON && \
    make -j$(nproc)

# If install/build steps touched tracked files, reset them
RUN git reset --hard

RUN rm -rf /app/src/.git

WORKDIR /app/src
