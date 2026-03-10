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
    (git fetch --depth 1 origin e7d5596c5a49f637a57bbd98a7b4549425375dc8 || git fetch --depth 1 origin "+refs/pull/529/head:refs/remotes/origin/pr/529") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Install protoc
RUN PROTOC_VERSION=$(grep -oP 'protoc-\K[0-9]+\.[0-9]+\.[0-9]+' Dockerfile 2>/dev/null || echo "28.3") && \
    curl -fsSL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip -o /tmp/protoc.zip && \
    unzip -q /tmp/protoc.zip -d /usr/local && \
    rm /tmp/protoc.zip

# Download Go dependencies
RUN go mod download

# Create .bazelrc to disable bzlmod (Bazel 9.0 uses MODULE.bazel by default)
RUN echo "common --enable_bzlmod=false" > .bazelrc

# Initialize Bazel and fetch all external dependencies (including rules_proto and rules_cc)
# This ensures dependencies are available even if not used in the current build
RUN bazel fetch @rules_proto//... @rules_cc//... 2>/dev/null || bazel fetch //... 2>/dev/null || true

ENV CI=true

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf .git

WORKDIR /app/src
