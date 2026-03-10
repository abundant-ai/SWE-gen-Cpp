FROM ubuntu:24.04

# Base system packages (common to all languages)
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
    (git fetch --depth 1 origin a2bbfa1db5ef098cc9d65eadb6e4b8ac1fb14c92 || git fetch --depth 1 origin "+refs/pull/14277/head:refs/remotes/origin/pr/14277") && \
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
