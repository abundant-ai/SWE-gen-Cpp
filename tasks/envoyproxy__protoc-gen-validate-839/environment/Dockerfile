FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Go 1.19 (from go.mod)
RUN curl -fsSL https://go.dev/dl/go1.19.13.linux-amd64.tar.gz | tar -C /usr/local -xzf - && \
    ln -s /usr/local/go/bin/go /usr/local/bin/go && \
    ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt

# Install Bazel 6.1.1 (from .bazelversion)
RUN curl -fsSL https://github.com/bazelbuild/bazelisk/releases/download/v1.19.0/bazelisk-linux-amd64 -o /usr/local/bin/bazel && \
    chmod +x /usr/local/bin/bazel

# Install Python 3.8 and protoc (required by CI workflow)
RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/bufbuild/protoc-gen-validate.git src && \
    cd src && \
    (git fetch --depth 1 origin db18d42f2da12a9d8bec5403e74996b4de3bfc50 || git fetch --depth 1 origin "+refs/pull/839/head:refs/remotes/origin/pr/839") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Download protoc (required for code generation)
RUN mkdir -p /tmp/protoc && \
    curl -fsSL https://github.com/protocolbuffers/protobuf/releases/download/v22.2/protoc-22.2-linux-x86_64.zip -o /tmp/protoc.zip && \
    unzip -q /tmp/protoc.zip -d /tmp/protoc && \
    mv /tmp/protoc/bin/protoc /usr/local/bin/protoc && \
    mv /tmp/protoc/include/* /usr/local/include/ && \
    rm -rf /tmp/protoc /tmp/protoc.zip

# Install Go dependencies
RUN go mod download

# Install Python dependencies (for linting tools)
RUN pip3 install --break-system-packages --ignore-installed -r requirements.txt

# Install protoc-gen-go
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.30.0
ENV PATH="/root/go/bin:${PATH}"

# Build the protoc-gen-validate plugin
RUN make build

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (Go is a compiled language)
RUN make build

RUN rm -rf /app/src/.git

WORKDIR /app/src
