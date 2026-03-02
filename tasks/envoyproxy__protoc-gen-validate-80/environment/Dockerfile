FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Go
RUN curl -fsSL https://go.dev/dl/go1.19.13.linux-amd64.tar.gz | tar -C /usr/local -xzf - && \
    ln -s /usr/local/go/bin/go /usr/local/bin/go && \
    ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt

# Install Python and unzip (required for protoc)
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

ENV GOPATH="/root/go"
ENV PATH="/root/go/bin:${PATH}"
ENV GO111MODULE=off

WORKDIR /root/go/src/github.com/lyft

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/bufbuild/protoc-gen-validate.git protoc-gen-validate && \
    cd protoc-gen-validate && \
    (git fetch --depth 1 origin db44ed538a238bcd0f790a7515d58117d19dead3 || git fetch --depth 1 origin "+refs/pull/80/head:refs/remotes/origin/pr/80") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /root/go/src/github.com/lyft/protoc-gen-validate

# Install protoc (required for protobuf code generation) - version 3.6.1 as per project Dockerfile
RUN mkdir -p /tmp/protoc && \
    curl -fsSL https://github.com/protocolbuffers/protobuf/releases/download/v3.6.1/protoc-3.6.1-linux-x86_64.zip -o /tmp/protoc.zip && \
    unzip -q /tmp/protoc.zip -d /tmp/protoc && \
    mv /tmp/protoc/bin/protoc /usr/local/bin/protoc && \
    mv /tmp/protoc/include/* /usr/local/include/ && \
    rm -rf /tmp/protoc /tmp/protoc.zip

# Install Python dependencies (required for code generation)
RUN if [ -f requirements.txt ]; then pip3 install --break-system-packages --ignore-installed -r requirements.txt; fi

# Install Python package dependencies
RUN pip3 install --break-system-packages setuptools Jinja2>=2.11.1 protobuf==3.20.2 astunparse>=1.6.3 validate_email 2>/dev/null || \
    pip3 install --break-system-packages setuptools Jinja2>=2.11.1 protobuf==3.20.2 astunparse>=1.6.3 py3-validate-email

# Install protoc-gen-go v1.2.0 compatible with this project
RUN GO111MODULE=on go install github.com/golang/protobuf/protoc-gen-go@v1.2.0

# Build the protoc-gen-validate plugin (using GOPATH/vendor mode)
RUN GO111MODULE=off make build

ENV CI=true

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild the protoc-gen-validate plugin after applying bug.patch
RUN GO111MODULE=off make build

RUN rm -rf .git

WORKDIR /root/go/src/github.com/lyft/protoc-gen-validate
