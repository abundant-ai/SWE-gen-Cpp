FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake (required for building spdlog)
RUN apt-get update && apt-get install -y \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/gabime/spdlog.git src && \
    cd src && \
    (git fetch --depth 1 origin 2b008efb0696e7cdd5271f28824e9652b80a28d6 || git fetch --depth 1 origin "+refs/pull/441/head:refs/remotes/origin/pr/441") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Reset any tracked files before applying bug.patch
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 --no-backup-if-mismatch --reject-file=- < /tmp/bug.patch || [ $? -eq 1 ] && rm /tmp/bug.patch

# Enable the discarded message counting feature for testing
RUN sed -i 's/^CXXFLAGS\s*=/CXXFLAGS = -DSPDLOG_ASYNC_COUNT_DISCARDED_MSG /' tests/Makefile

RUN rm -rf /app/src/.git

WORKDIR /app/src
