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

# Install Java 8 (as specified in pom.xml) and Maven
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    maven \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Set up Go environment first
ENV GO111MODULE=off
ENV GOPATH=/go

# Clone repo into GOPATH (required for Go build to find vendor dependencies)
# Note: The import path is github.com/envoyproxy/protoc-gen-validate, not bufbuild
RUN mkdir -p /go/src/github.com/envoyproxy && \
    cd /go/src/github.com/envoyproxy && \
    git clone https://github.com/bufbuild/protoc-gen-validate.git && \
    cd protoc-gen-validate && \
    (git fetch --depth 1 origin e3c9e97fa445cda28ff1f1db6b3f374061bf7c2e || git fetch --depth 1 origin "+refs/pull/317/head:refs/remotes/origin/pr/317") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /go/src/github.com/envoyproxy/protoc-gen-validate

ENV CI=true

# Install protoc (required for Java code generation)
RUN PROTOC_VERSION=3.5.1 && \
    curl -fsSL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip -o /tmp/protoc.zip && \
    unzip -q /tmp/protoc.zip -d /usr/local && \
    rm /tmp/protoc.zip

# Install Maven dependencies and compile Java modules
RUN cd java && mvn clean install -DskipTests

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild Java modules after applying bug.patch
RUN cd java && mvn clean install -DskipTests

RUN rm -rf .git

WORKDIR /go/src/github.com/envoyproxy/protoc-gen-validate
