FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler and Bazel for building and testing
RUN apt-get update && apt-get install -y \
    g++ \
    wget \
    dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Install Bazel (using Bazelisk for version management)
RUN wget -O /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v1.19.0/bazelisk-linux-amd64 && \
    chmod +x /usr/local/bin/bazel

# Pin Bazel version globally
ENV USE_BAZEL_VERSION=6.3.2

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/Neargye/magic_enum.git src && \
    cd src && \
    (git fetch --depth 1 origin b3c751509799793dc736f75feebfe7581f1e9669 || git fetch --depth 1 origin "+refs/pull/312/head:refs/remotes/origin/pr/312") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
# First convert CRLF to LF in test/BUILD.bazel to avoid patch failures
RUN dos2unix test/BUILD.bazel
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch


RUN rm -rf /app/src/.git

WORKDIR /app/src
