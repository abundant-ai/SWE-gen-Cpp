FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler and autotools
RUN apt-get update && apt-get install -y \
    g++ \
    autoconf \
    automake \
    libtool \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/google/googletest.git src && \
    cd src && \
    (git fetch --depth 1 origin 39062f4e3005cac0b919d3dbe83b3d1e6b61a8ae || git fetch --depth 1 origin "+refs/pull/589/head:refs/remotes/origin/pr/589") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build Google Mock using autotools
RUN cd googlemock && \
    autoreconf -fvi && \
    ./configure && \
    make -j4

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Note: We don't rebuild after applying bug.patch because the bug breaks the autotools build.
# The test.sh will attempt to rebuild and should fail for NOP (buggy) and succeed for Oracle (fixed).

RUN rm -rf /app/src/.git

WORKDIR /app/src
