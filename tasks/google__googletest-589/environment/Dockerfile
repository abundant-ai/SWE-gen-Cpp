FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler and autotools build dependencies
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

# Build Google Test first using autotools
RUN cd googletest && \
    autoreconf -fvi && \
    ./configure && \
    make -j4

# Build Google Mock using autotools (this works in the fixed/HEAD state)
RUN cd googlemock && \
    autoreconf -fvi && \
    ./configure && \
    make -j4

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
