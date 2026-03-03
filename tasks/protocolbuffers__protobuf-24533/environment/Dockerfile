FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3 (required for Python protobuf bindings)
RUN apt-get update && apt-get install -y \
    python3 \
    python3-dev \
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
    (git fetch --depth 1 origin 192cd6631aba683489ae720c5e87f551412d6a9b || git fetch --depth 1 origin "+refs/pull/24533/head:refs/remotes/origin/pr/24533") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Pin Bazel version to 7.6.1 (version used by protobuf CI)
RUN echo "7.6.1" > .bazelversion

# Bazel needs these env vars for reproducible builds
ENV CI=true

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
