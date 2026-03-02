FROM ubuntu:24.04

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
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/CrowCpp/Crow.git src && \
    cd src && \
    (git fetch --depth 1 origin 7a532b8daa5ffe84d9062e6f2dab0703d55eb06a || git fetch --depth 1 origin "+refs/pull/854/head:refs/remotes/origin/pr/854") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build the project with CMake to prepare dependencies (including Catch2)
RUN mkdir -p build && cd build && \
    cmake .. -DCROW_BUILD_TESTS=ON && \
    cmake --build . --target unittest && \
    cmake --build . --target test_external_definition

# If build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch
RUN cd build && \
    cmake --build . --target unittest && \
    cmake --build . --target test_external_definition

RUN rm -rf /app/src/.git

WORKDIR /app/src
