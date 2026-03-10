FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Go (version 1.21+ as required by go.mod)
RUN curl -fsSL https://go.dev/dl/go1.21.13.linux-amd64.tar.gz | tar -C /usr/local -xzf - && \
    ln -s /usr/local/go/bin/go /usr/local/bin/go && \
    ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt

# Install Python 3.9 (older version compatible with old Bazel rules_python) and Java
RUN apt-get update && apt-get install -y \
    software-properties-common \
    unzip \
    openjdk-11-jdk \
    && add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y \
    python3.9 \
    python3.9-distutils \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/python3.9 /usr/bin/python \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3.9

# Install Bazel 1.2.1 (compatible with both bug and fix states for PR #327)
RUN curl -fsSL https://github.com/bazelbuild/bazel/releases/download/1.2.1/bazel-1.2.1-linux-x86_64 -o /usr/local/bin/bazel && \
    chmod +x /usr/local/bin/bazel

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/bufbuild/protoc-gen-validate.git src && \
    cd src && \
    (git fetch --depth 1 origin 6fe1c2620e101fd707537526199498c4e5caf06a || git fetch --depth 1 origin "+refs/pull/327/head:refs/remotes/origin/pr/327") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Install protoc
RUN PROTOC_VERSION=$(grep -oP 'protoc-\K[0-9]+\.[0-9]+\.[0-9]+' Dockerfile 2>/dev/null || echo "28.3") && \
    curl -fsSL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip -o /tmp/protoc.zip && \
    unzip -q /tmp/protoc.zip -d /usr/local && \
    rm /tmp/protoc.zip

# Initialize Bazel and fetch all external dependencies
RUN bazel fetch //... 2>/dev/null || true

ENV CI=true

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Fix broken zlib URL (zlib.net returns 404) - must be after bug.patch
RUN sed -i 's|https://zlib.net/zlib-1.2.11.tar.gz|https://github.com/madler/zlib/archive/v1.2.11.tar.gz|g' bazel/repositories.bzl && \
    sed -i 's|c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1|629380c90a77b964d896ed37163f5c3a34f6e6d897311f1df2a7016355c45eff|g' bazel/repositories.bzl

RUN rm -rf .git

WORKDIR /app/src
