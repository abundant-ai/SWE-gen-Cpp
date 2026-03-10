FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler and required libraries for cpp-httplib
RUN apt-get update && apt-get install -y \
    clang \
    libssl-dev \
    libcurl4-openssl-dev \
    zlib1g-dev \
    libbrotli-dev \
    libzstd-dev \
    python3 \
    file \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/yhirose/cpp-httplib.git src && \
    cd src && \
    (git fetch --depth 1 origin 08bf806e927363bc35c7d48895375a3556bd7a05 || git fetch --depth 1 origin "+refs/pull/290/head:refs/remotes/origin/pr/290") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
