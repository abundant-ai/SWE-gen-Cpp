FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ development tools and dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    g++ \
    clang \
    libasio-dev \
    libssl-dev \
    zlib1g-dev \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/CrowCpp/Crow.git src && \
    cd src && \
    (git fetch --depth 1 origin b90a739422118babdd153bdf3112eee26698ef56 || git fetch --depth 1 origin "+refs/pull/923/head:refs/remotes/origin/pr/923") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Note: This PR tests mustache templates which are header-only and compiled separately in test.sh
# No initial build needed since we'll compile the specific test file during test execution

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
