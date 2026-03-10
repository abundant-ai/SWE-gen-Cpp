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
    file \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/yhirose/cpp-httplib.git src && \
    cd src && \
    (git fetch --depth 1 origin 9c8169380161c5095c7036bde4a16453ad173b66 || git fetch --depth 1 origin "+refs/pull/295/head:refs/remotes/origin/pr/295") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
# Note: .travis.yml may fail due to line ending issues, but that's OK for testing
COPY bug.patch /tmp/bug.patch
RUN (patch -p1 < /tmp/bug.patch || echo "Some patches failed but continuing...") && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
