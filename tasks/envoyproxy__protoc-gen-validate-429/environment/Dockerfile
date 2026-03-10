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

# Install Bazel 5.4.1 (version that has sh_test as built-in)
RUN curl -fsSL https://github.com/bazelbuild/bazel/releases/download/5.4.1/bazel-5.4.1-linux-x86_64 -o /usr/local/bin/bazel && \
    chmod +x /usr/local/bin/bazel

WORKDIR /app

# Clone repo at HEAD commit (with fix applied) - using cd2aecb which is PR #429 merge commit
RUN git clone https://github.com/bufbuild/protoc-gen-validate.git src && \
    cd src && \
    (git fetch --depth 1 origin cd2aecb9e09ce41720398f56fd6a430c5bd4e8ef || git fetch --depth 1 origin "+refs/pull/429/head:refs/remotes/origin/pr/429") && \
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

# Initialize Bazel and fetch all external dependencies
RUN bazel fetch //... 2>/dev/null || true

ENV CI=true

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf .git

WORKDIR /app/src
