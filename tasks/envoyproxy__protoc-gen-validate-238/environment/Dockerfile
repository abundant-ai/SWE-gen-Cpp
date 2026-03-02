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

# Install Java (OpenJDK 8 for compatibility with Java version 1.8) and Python
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    maven \
    python3 \
    python3-pip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"
ENV GOPATH="/root/go"
ENV PATH="/root/go/bin:${PATH}"
ENV GO111MODULE=off

WORKDIR /root/go/src/github.com/envoyproxy

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/bufbuild/protoc-gen-validate.git protoc-gen-validate && \
    cd protoc-gen-validate && \
    (git fetch --depth 1 origin b2998ac4b9dac87217e88827dc5c9a79720de60f || git fetch --depth 1 origin "+refs/pull/238/head:refs/remotes/origin/pr/238") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /root/go/src/github.com/envoyproxy/protoc-gen-validate

# Install protoc (required for protobuf code generation)
RUN mkdir -p /tmp/protoc && \
    curl -fsSL https://github.com/protocolbuffers/protobuf/releases/download/v22.2/protoc-22.2-linux-x86_64.zip -o /tmp/protoc.zip && \
    unzip -q /tmp/protoc.zip -d /tmp/protoc && \
    mv /tmp/protoc/bin/protoc /usr/local/bin/protoc && \
    mv /tmp/protoc/include/* /usr/local/include/ && \
    rm -rf /tmp/protoc /tmp/protoc.zip

# Install Python dependencies (required for code generation)
RUN pip3 install --break-system-packages --ignore-installed -r requirements.txt

# Install Python package dependencies
RUN pip3 install --break-system-packages setuptools Jinja2>=2.11.1 protobuf==3.20.2 astunparse>=1.6.3 validate_email 2>/dev/null || \
    pip3 install --break-system-packages setuptools Jinja2>=2.11.1 protobuf==3.20.2 astunparse>=1.6.3 py3-validate-email

# Install old protoc-gen-go compatible with this project
RUN GO111MODULE=on go install github.com/golang/protobuf/protoc-gen-go@v1.3.5

# Build the protoc-gen-validate plugin (using GOPATH/vendor mode)
RUN GO111MODULE=off make build

ENV CI=true

# Install Java dependencies and compile the project
RUN cd java && mvn clean install -DskipTests

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild the protoc-gen-validate plugin after applying bug.patch
RUN GO111MODULE=off make build

# Rebuild Java project after applying bug.patch
RUN cd java && mvn clean install -DskipTests

RUN rm -rf .git

WORKDIR /root/go/src/github.com/envoyproxy/protoc-gen-validate
