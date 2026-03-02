FROM ubuntu:24.04

# Set DEBIAN_FRONTEND to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ development tools and dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    g++ \
    clang \
    libasio-dev \
    libssl-dev \
    zlib1g-dev \
    python3 \
    openssl \
    libboost-system-dev \
    libboost-date-time-dev \
    libboost-thread-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/CrowCpp/Crow.git src && \
    cd src && \
    (git fetch --depth 1 origin 73240f1626af016410d2ee9c3d277def254ea2fe || git fetch --depth 1 origin "+refs/pull/93/head:refs/remotes/origin/pr/93") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Fix MINSIGSTKSZ issue in old Catch version for modern glibc
RUN sed -i 's/static constexpr std::size_t sigStackSize = 32768 >= MINSIGSTKSZ ? 32768 : MINSIGSTKSZ;/static const std::size_t sigStackSize = 32768;/' tests/catch.hpp || true

# Build the project with CMake to prepare dependencies (including Catch2)
RUN mkdir -p build && cd build && \
    cmake .. -DCROW_BUILD_TESTS=ON -DCROW_ENABLE_SSL=ON && \
    cmake --build . --target unittest

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Fix MINSIGSTKSZ issue again after bug.patch (in case unittest.cpp changes affected catch.hpp)
RUN sed -i 's/static constexpr std::size_t sigStackSize = 32768 >= MINSIGSTKSZ ? 32768 : MINSIGSTKSZ;/static const std::size_t sigStackSize = 32768;/' tests/catch.hpp || true

# Rebuild after applying bug.patch
RUN cd build && \
    cmake --build . --target unittest

RUN rm -rf /app/src/.git

WORKDIR /app/src
