FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python (required by Bazel build system)
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Java (required for Java tests)
RUN apt-get update && apt-get install -y \
    openjdk-21-jdk \
    && rm -rf /var/lib/apt/lists/*

# Install Bazel for building and testing C++ code
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Bazelisk (Bazel version manager)
RUN wget -O /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v1.19.0/bazelisk-linux-amd64 \
    && chmod +x /usr/local/bin/bazel

# Install Rust (required for Rust tests)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.90.0
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/protocolbuffers/protobuf.git src && \
    cd src && \
    (git fetch --depth 1 origin f69f8d755f9ee2d51c369e23002ce683d450ade6 || git fetch --depth 1 origin "+refs/pull/26179/head:refs/remotes/origin/pr/26179") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set environment variables for Bazel
ENV CI=true
ENV USE_BAZEL_VERSION=8.0.1

# Pre-build the test to cache Bazel compilation (speeds up test execution significantly)
# Build the test target first, then reset any tracked file changes
RUN bazel build //src/google/protobuf:repeated_field_proxy_test || true

# Reset any tracked files that may have been modified during build
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Note: We don't rebuild after applying bug.patch - Bazel will rebuild as needed during test

RUN rm -rf /app/src/.git

WORKDIR /app/src
