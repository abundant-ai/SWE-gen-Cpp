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

# Install Python and unzip (required for protoc and Bazel)
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Bazel (required for building Bazel-based project)
RUN curl -fsSL https://github.com/bazelbuild/bazelisk/releases/download/v1.19.0/bazelisk-linux-amd64 -o /usr/local/bin/bazel && \
    chmod +x /usr/local/bin/bazel

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/bufbuild/protoc-gen-validate.git src && \
    cd src && \
    (git fetch --depth 1 origin 917e2c46da5a3ab9026bc41ccfa7c90afd73aec0 || git fetch --depth 1 origin "+refs/pull/1226/head:refs/remotes/origin/pr/1226") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Install protoc (check .bazelversion or Dockerfile for version)
RUN PROTOC_VERSION=$(grep -oP 'protoc-\K[0-9]+\.[0-9]+\.[0-9]+' Dockerfile 2>/dev/null || echo "28.3") && \
    curl -fsSL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip -o /tmp/protoc.zip && \
    unzip -q /tmp/protoc.zip -d /usr/local && \
    rm /tmp/protoc.zip

# Download Go dependencies
RUN go mod download

ENV CI=true

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf .git

WORKDIR /app/src
