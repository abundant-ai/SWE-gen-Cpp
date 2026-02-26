FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler, CMake, and Python (needed for tests)
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    g++ \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/catchorg/Catch2.git src && \
    cd src && \
    (git fetch --depth 1 origin 6f4573b214f58af503ba47beaa2057e7ba68f32c || git fetch --depth 1 origin "+refs/pull/1843/head:refs/remotes/origin/pr/1843") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Fix MINSIGSTKSZ issue - MINSIGSTKSZ is no longer a compile-time constant in newer glibc
RUN sed -i 's/static constexpr std::size_t sigStackSize = 32768 >= MINSIGSTKSZ ? 32768 : MINSIGSTKSZ;/static const std::size_t sigStackSize = 32768;/' src/catch2/catch_fatal_condition.cpp

# Configure and build Catch2 with CMake
RUN cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -G Ninja

RUN cmake --build build

# Reset tracked files so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Re-apply MINSIGSTKSZ fix after git reset removed it
RUN sed -i 's/static constexpr std::size_t sigStackSize = 32768 >= MINSIGSTKSZ ? 32768 : MINSIGSTKSZ;/static const std::size_t sigStackSize = 32768;/' src/catch2/catch_fatal_condition.cpp

# Rebuild after applying bug.patch (C++ is a compiled language)
RUN cmake --build build

RUN rm -rf /app/src/.git

WORKDIR /app/src
