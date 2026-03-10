FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Go (required for protoc-gen-validate build)
RUN curl -fsSL https://go.dev/dl/go1.21.13.linux-amd64.tar.gz | tar -C /usr/local -xzf - && \
    ln -s /usr/local/go/bin/go /usr/local/bin/go && \
    ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt

# Install additional system packages (unzip for protoc)
RUN apt-get update && apt-get install -y \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set up Go environment first
ENV GO111MODULE=off
ENV GOPATH=/go
ENV PATH=/go/bin:$PATH

# Clone repo into GOPATH (required for Go build to find vendor dependencies)
# Note: The import path is github.com/envoyproxy/protoc-gen-validate, not bufbuild
RUN mkdir -p /go/src/github.com/envoyproxy && \
    cd /go/src/github.com/envoyproxy && \
    git clone https://github.com/bufbuild/protoc-gen-validate.git && \
    cd protoc-gen-validate && \
    (git fetch --depth 1 origin 9df978dd119da2d9c7f2dc5f3a28859f582d4d6c || git fetch --depth 1 origin "+refs/pull/272/head:refs/remotes/origin/pr/272") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /go/src/github.com/envoyproxy/protoc-gen-validate

ENV CI=true

# Install protoc (required for proto code generation)
RUN PROTOC_VERSION=3.5.1 && \
    curl -fsSL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip -o /tmp/protoc.zip && \
    unzip -q /tmp/protoc.zip -d /usr/local && \
    rm /tmp/protoc.zip

# Build protoc-gen-go from vendor (required for proto code generation)
RUN go build -o /go/bin/protoc-gen-go vendor/github.com/golang/protobuf/protoc-gen-go/main.go

# Build the protoc-gen-validate plugin and generate test cases
RUN make build && make testcases

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild plugin after applying bug.patch
RUN make build

RUN rm -rf .git

WORKDIR /go/src/github.com/envoyproxy/protoc-gen-validate
