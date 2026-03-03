FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake and C++ compiler
RUN apt-get update && apt-get install -y \
    cmake \
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/simdjson/simdjson.git src && \
    cd src && \
    (git fetch --depth 1 origin 43442c29a234a252ec447c7665a45c5892addd6d || git fetch --depth 1 origin "+refs/pull/469/head:refs/remotes/origin/pr/469") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Apply bug.patch to revert to buggy API state
# Note: HEAD has the fixed JsonStream API but also has a throw new bug
# bug.patch reverts the API changes
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Fix the "throw new" compilation bug that persists in both base and fix states
# This bug is separate from the JsonStream API issue that PR #469 fixes
RUN sed -i 's/throw new std::runtime_error/throw std::runtime_error/g' src/jsonstream.cpp singleheader/simdjson.cpp && \
    sed -i '5i #include <stdexcept>' src/jsonstream.cpp

RUN rm -rf /app/src/.git

WORKDIR /app/src
