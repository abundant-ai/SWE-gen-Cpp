FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/opencv/opencv.git src && \
    cd src && \
    (git fetch --depth 1 origin 183c0fcab199b32774d1e4f1261f8b3a4d12777f || git fetch --depth 1 origin "+refs/pull/13774/head:refs/remotes/origin/pr/13774") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Test validation checks source code state without building the full project
# to avoid extremely long build times (OpenCV takes 30+ minutes to compile)

RUN rm -rf /app/src/.git

WORKDIR /app/src
