FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler and required libraries for cpp-httplib
RUN apt-get update && apt-get install -y \
    clang \
    libssl-dev \
    libcurl4-openssl-dev \
    zlib1g-dev \
    libbrotli-dev \
    libzstd-dev \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/yhirose/cpp-httplib.git src && \
    cd src && \
    (git fetch --depth 1 origin e1c4e909f3f60dff8a8d649d496f65c5e38cec3c || git fetch --depth 1 origin "+refs/pull/1525/head:refs/remotes/origin/pr/1525") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Generate SSL certificates needed by tests
RUN cd test && \
    openssl genrsa 2048 > key.pem && \
    openssl req -new -batch -config test.conf -key key.pem | openssl x509 -days 3650 -req -signkey key.pem > cert.pem && \
    openssl req -x509 -config test.conf -key key.pem -sha256 -days 3650 -nodes -out cert2.pem -extensions SAN && \
    openssl genrsa 2048 > rootCA.key.pem && \
    openssl req -x509 -new -batch -config test.rootCA.conf -key rootCA.key.pem -days 1024 > rootCA.cert.pem && \
    openssl genrsa 2048 > client.key.pem && \
    openssl req -new -batch -config test.conf -key client.key.pem | openssl x509 -days 370 -req -CA rootCA.cert.pem -CAkey rootCA.key.pem -CAcreateserial > client.cert.pem && \
    openssl genrsa -passout pass:test123! 2048 > key_encrypted.pem && \
    openssl req -new -batch -config test.conf -key key_encrypted.pem | openssl x509 -days 3650 -req -signkey key_encrypted.pem > cert_encrypted.pem

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
