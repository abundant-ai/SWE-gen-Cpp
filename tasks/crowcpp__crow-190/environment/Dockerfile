FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler (GCC), CMake, and dependencies for Crow
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    g++ \
    libasio-dev \
    libssl-dev \
    zlib1g-dev \
    python3 \
    libboost-system-dev \
    libboost-date-time-dev \
    libboost-thread-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/CrowCpp/Crow.git src && \
    cd src && \
    (git fetch --depth 1 origin 49b020b9aa0099d20c54509ee7c25662fe034edf || git fetch --depth 1 origin "+refs/pull/190/head:refs/remotes/origin/pr/190") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Fix catch.hpp compatibility with modern glibc (old catch version doesn't support dynamic MINSIGSTKSZ)
# This must be done before any build attempts
RUN sed -i 's/static constexpr std::size_t sigStackSize = 32768 >= MINSIGSTKSZ ? 32768 : MINSIGSTKSZ;/static const std::size_t sigStackSize = 32768;/' tests/catch.hpp && \
    sed -i 's/char FatalConditionHandler::altStackMem\[sigStackSize\] = {};/char FatalConditionHandler::altStackMem[32768] = {};/' tests/catch.hpp

# Configure and build Crow with CMake (enable tests, disable examples)
RUN cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCROW_BUILD_TESTS=ON \
    -DCROW_BUILD_EXAMPLES=OFF \
    -DCROW_ENABLE_SSL=ON \
    -DCROW_ENABLE_COMPRESSION=ON \
    -G Ninja

# Build the test target
RUN cmake --build build --target unittest

# Reset tracked files so bug.patch applies cleanly (also resets catch.hpp patch)
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Fix catch.hpp again after git reset (same fix as before)
RUN sed -i 's/static constexpr std::size_t sigStackSize = 32768 >= MINSIGSTKSZ ? 32768 : MINSIGSTKSZ;/static const std::size_t sigStackSize = 32768;/' tests/catch.hpp && \
    sed -i 's/char FatalConditionHandler::altStackMem\[sigStackSize\] = {};/char FatalConditionHandler::altStackMem[32768] = {};/' tests/catch.hpp

# Reconfigure and rebuild after applying bug.patch
RUN rm -rf build && cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCROW_BUILD_TESTS=ON \
    -DCROW_BUILD_EXAMPLES=OFF \
    -DCROW_ENABLE_SSL=ON \
    -DCROW_ENABLE_COMPRESSION=ON \
    -G Ninja && \
    cmake --build build --target unittest

RUN rm -rf /app/src/.git

WORKDIR /app/src
