FROM ubuntu:24.04

# Base system packages
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# No additional language runtime needed - pugixml is a C++ header-only library

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/zeux/pugixml.git src && \
    cd src && \
    (git fetch --depth 1 origin 4f3be7616729cbf0c8768caf861331d710d457a8 || git fetch --depth 1 origin "+refs/pull/79/head:refs/remotes/origin/pr/79") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build the test suite using Makefile (not CMake, this is an older commit)
# Disable some warnings as errors (newer gcc version issues)
RUN sed -i 's/CXXFLAGS=-g -Wall -Wextra -Werror/CXXFLAGS=-g -Wall -Wextra -Werror -Wno-error=implicit-fallthrough -Wno-error=expansion-to-defined -Wno-error=self-move/' Makefile && \
    make -j$(nproc)

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN git apply --whitespace=fix /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch since this is compiled C++
# Re-apply the compiler warning fixes
RUN sed -i 's/CXXFLAGS=-g -Wall -Wextra -Werror/CXXFLAGS=-g -Wall -Wextra -Werror -Wno-error=implicit-fallthrough -Wno-error=expansion-to-defined -Wno-error=self-move/' Makefile && \
    make clean && make -j$(nproc)

RUN rm -rf /app/src/.git

WORKDIR /app/src
