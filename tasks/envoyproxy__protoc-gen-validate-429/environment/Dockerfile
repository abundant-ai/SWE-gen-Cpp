FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Go 1.19
RUN curl -fsSL https://go.dev/dl/go1.19.13.linux-amd64.tar.gz | tar -C /usr/local -xzf - && \
    ln -s /usr/local/go/bin/go /usr/local/bin/go && \
    ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt

# Install Bazel
RUN curl -fsSL https://github.com/bazelbuild/bazelisk/releases/download/v1.19.0/bazelisk-linux-amd64 -o /usr/local/bin/bazel && \
    chmod +x /usr/local/bin/bazel

# Install Python and unzip
RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/bufbuild/protoc-gen-validate.git src && \
    cd src && \
    (git fetch --depth 1 origin a087d35ba9984dcb5476ea90eacc1cecf466c5cf || git fetch --depth 1 origin "+refs/pull/429/head:refs/remotes/origin/pr/429") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Download protoc
RUN mkdir -p /tmp/protoc && \
    curl -fsSL https://github.com/protocolbuffers/protobuf/releases/download/v22.2/protoc-22.2-linux-x86_64.zip -o /tmp/protoc.zip && \
    unzip -q /tmp/protoc.zip -d /tmp/protoc && \
    mv /tmp/protoc/bin/protoc /usr/local/bin/protoc && \
    mv /tmp/protoc/include/* /usr/local/include/ && \
    rm -rf /tmp/protoc /tmp/protoc.zip

# Install Go dependencies
RUN go mod download

# Install Python dependencies
RUN pip3 install --break-system-packages --ignore-installed -r requirements.txt

# Install Python package dependencies (with fallback for validate_email)
RUN pip3 install --break-system-packages setuptools Jinja2>=2.11.1 protobuf==3.20.2 astunparse>=1.6.3 validate_email 2>/dev/null || \
    pip3 install --break-system-packages setuptools Jinja2>=2.11.1 protobuf==3.20.2 astunparse>=1.6.3 py3-validate-email

# Install protoc-gen-go
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.30.0
ENV PATH="/root/go/bin:${PATH}"
ENV GOPATH="/root/go"

# Build the protoc-gen-validate plugin
RUN make build

# Reset to clean state before applying bug.patch
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild with buggy templates
RUN make build

RUN rm -rf /app/src/.git

WORKDIR /app/src
