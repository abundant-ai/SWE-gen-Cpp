FROM ubuntu:24.04

# Install base system packages
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/uNetworking/uWebSockets.git src && \
    cd src && \
    (git fetch --depth 1 origin 76487df709d7471f04431b7100bde0a008b26a96 || git fetch --depth 1 origin "+refs/pull/1185/head:refs/remotes/origin/pr/1185") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Reset any modified files before applying bug.patch
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
