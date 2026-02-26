FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Java 11 (required by Bazel and rules_jvm_external)
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    unzip \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Install Bazelisk (manages Bazel versions automatically)
RUN curl -fsSL https://github.com/bazelbuild/bazelisk/releases/download/v1.24.1/bazelisk-linux-amd64 -o /usr/local/bin/bazel && \
    chmod +x /usr/local/bin/bazel

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/protocolbuffers/protobuf.git src && \
    cd src && \
    (git fetch --depth 1 origin f9f32d28007ae692a494e70d6a5e808069938843 || git fetch --depth 1 origin "+refs/pull/25778/head:refs/remotes/origin/pr/25778") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Bazel needs these env vars for reproducible builds
ENV CI=true

# Clean Bazel cache before applying patches
RUN bazel clean --expunge || true

# Reset git to ensure clean state for patching
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Clean Bazel cache again after applying bug patch
RUN bazel clean --expunge || true

RUN rm -rf /app/src/.git

WORKDIR /app/src
