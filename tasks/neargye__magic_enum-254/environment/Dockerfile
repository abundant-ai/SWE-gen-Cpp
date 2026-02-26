FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler and Bazelisk (automatically uses correct Bazel version)
RUN apt-get update && apt-get install -y \
    g++ \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Bazelisk which will auto-select the right Bazel version
RUN wget -O /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v1.19.0/bazelisk-linux-amd64 && \
    chmod +x /usr/local/bin/bazel

WORKDIR /app

# Clone repo at HEAD commit (with fix applied - PR #254)
RUN git clone https://github.com/Neargye/magic_enum.git src && \
    cd src && \
    (git fetch --depth 1 origin 48054f64abcfc83f58d9aa2efbbd21604f93aca4 || git fetch --depth 1 origin "+refs/pull/254/head:refs/remotes/origin/pr/254") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set Bazel version for Bazelisk
ENV USE_BAZEL_VERSION=6.1.2

# Apply bug.patch to revert to buggy state (BASE - no Bazel support)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
