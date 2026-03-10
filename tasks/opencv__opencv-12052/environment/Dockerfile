FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Test validation checks source code state without building the full project
# to avoid extremely long build times (OpenCV takes 30+ minutes to compile)

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/opencv/opencv.git src && \
    cd src && \
    (git fetch --depth 1 origin faa6c4e1e16ebfcf1415168acb159f2fc723bc36 || git fetch --depth 1 origin "+refs/pull/12052/head:refs/remotes/origin/pr/12052") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN git apply --reject --whitespace=fix /tmp/bug.patch || true && \
    rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
